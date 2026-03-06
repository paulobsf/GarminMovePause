import Toybox.Activity;
import Toybox.Lang;
import Toybox.System;

class MovePauseTimingEngine {
    private const DRIFT_CORRECTION_THRESHOLD_MS = 1250;

    private var _currentPauseMs as Number = 0;
    private var _hasStarted as Boolean = false;
    private var _lastTickMs as Number?;
    private var _segmentMovingMs as Number = 0;
    private var _segmentPausedMs as Number = 0;
    private var _timerState as Number = Activity.TIMER_STATE_OFF;
    private var _totalMovingMs as Number = 0;
    private var _totalPausedMs as Number = 0;

    function initialize() {
        reset();
    }

    function reset() as Void {
        _currentPauseMs = 0;
        _hasStarted = false;
        _lastTickMs = null;
        _segmentMovingMs = 0;
        _segmentPausedMs = 0;
        _timerState = Activity.TIMER_STATE_OFF;
        _totalMovingMs = 0;
        _totalPausedMs = 0;
        MovePauseLogger.debug("Timing engine reset.");
    }

    function seedFromInfo(info as Activity.Info?) as Void {
        _lastTickMs = System.getTimer();

        if (info == null) {
            _timerState = Activity.TIMER_STATE_OFF;
            return;
        }

        var expectedMoving = getExpectedMovingMs(info);
        var expectedPaused = getExpectedPausedMs(info);

        _totalMovingMs = expectedMoving;
        _totalPausedMs = expectedPaused;
        _segmentMovingMs = expectedMoving;
        _segmentPausedMs = expectedPaused;
        _timerState = getObservedState(info);
        _hasStarted = didActivityStart(info, expectedMoving, expectedPaused);

        if (!_hasStarted) {
            _segmentMovingMs = 0;
            _segmentPausedMs = 0;
            _timerState = Activity.TIMER_STATE_OFF;
            _currentPauseMs = 0;
        } else if (!isPausedLike(_timerState)) {
            _currentPauseMs = 0;
        }
    }

    function sync(info as Activity.Info) as Void {
        if (_lastTickMs == null) {
            seedFromInfo(info);
            return;
        }

        var now = System.getTimer();
        accumulateDelta(now);
        _lastTickMs = now;

        applyState(getObservedState(info), "compute");
        reconcile(info);
    }

    function handleTimerPause() as Void {
        handleTimerEvent(Activity.TIMER_STATE_PAUSED, "onTimerPause");
    }

    function handleTimerLap() as Void {
        var now = System.getTimer();

        if (_lastTickMs == null) {
            _lastTickMs = now;
        }

        accumulateDelta(now);
        _lastTickMs = now;
        resetSegmentTotals();
        MovePauseLogger.debug("Segment reset via onTimerLap.");
    }

    function handleTimerReset() as Void {
        reset();
    }

    function handleTimerResume() as Void {
        handleTimerEvent(Activity.TIMER_STATE_ON, "onTimerResume");
    }

    function handleTimerStart() as Void {
        handleTimerEvent(Activity.TIMER_STATE_ON, "onTimerStart");
    }

    function handleTimerStop() as Void {
        handleTimerEvent(Activity.TIMER_STATE_STOPPED, "onTimerStop");
    }

    function getCurrentPauseMs() as Number {
        return _currentPauseMs;
    }

    function getSegmentMovingMs() as Number {
        return _segmentMovingMs;
    }

    function getSegmentPausedMs() as Number {
        return _segmentPausedMs;
    }

    function getTotalMovingMs() as Number {
        return _totalMovingMs;
    }

    function getTotalPausedMs() as Number {
        return _totalPausedMs;
    }

    function hasStarted() as Boolean {
        return _hasStarted;
    }

    function isMoving() as Boolean {
        return _hasStarted && (_timerState == Activity.TIMER_STATE_ON);
    }

    function isPaused() as Boolean {
        return _hasStarted && isPausedLike(_timerState);
    }

    private function handleTimerEvent(nextState as Number, source as String) as Void {
        var now = System.getTimer();

        if (_lastTickMs == null) {
            _lastTickMs = now;
        }

        accumulateDelta(now);
        _lastTickMs = now;
        applyState(nextState, source);
    }

    private function accumulateDelta(now as Number) as Void {
        var lastTickMs = _lastTickMs;

        if (lastTickMs == null) {
            return;
        }

        var delta = now - lastTickMs;

        if (delta <= 0) {
            if (delta < 0) {
                MovePauseLogger.debug("System timer moved backwards; skipped delta.");
            }
            return;
        }

        if (_timerState == Activity.TIMER_STATE_ON) {
            _hasStarted = true;
            _segmentMovingMs += delta;
            _totalMovingMs += delta;
            _currentPauseMs = 0;
            return;
        }

        if (_hasStarted && isPausedLike(_timerState)) {
            _segmentPausedMs += delta;
            _totalPausedMs += delta;
            _currentPauseMs += delta;
            return;
        }

        _currentPauseMs = 0;
    }

    private function applyState(nextState as Number, source as String) as Void {
        var previousState = _timerState;
        _timerState = nextState;

        if (_timerState == Activity.TIMER_STATE_ON) {
            _hasStarted = true;
            _currentPauseMs = 0;
        } else if (!_hasStarted) {
            _currentPauseMs = 0;
        } else if (isPausedLike(_timerState)) {
            if (!isPausedLike(previousState)) {
                _currentPauseMs = 0;
            }
        } else {
            _currentPauseMs = 0;
        }

        if (previousState != nextState) {
            MovePauseLogger.debug("Timer state changed via " + source + ".");
        }
    }

    private function didActivityStart(info as Activity.Info, expectedMoving as Number, expectedPaused as Number) as Boolean {
        if (expectedMoving > 0 || expectedPaused > 0) {
            return true;
        }

        return getObservedState(info) == Activity.TIMER_STATE_ON;
    }

    private function getExpectedMovingMs(info as Activity.Info) as Number {
        var timerTime = info.timerTime;

        if (timerTime == null || timerTime < 0) {
            return 0;
        }

        return timerTime;
    }

    private function getExpectedPausedMs(info as Activity.Info) as Number {
        var elapsedTime = info.elapsedTime;
        var timerTime = info.timerTime;

        if (elapsedTime == null || timerTime == null) {
            return 0;
        }

        var pausedTime = elapsedTime - timerTime;

        if (pausedTime < 0) {
            return 0;
        }

        return pausedTime;
    }

    private function getObservedState(info as Activity.Info) as Number {
        var timerState = info.timerState;
        return normalizeState(timerState);
    }

    private function isPausedLike(state as Number) as Boolean {
        return (state == Activity.TIMER_STATE_PAUSED) || (state == Activity.TIMER_STATE_STOPPED);
    }

    private function normalizeState(state as Number?) as Number {
        if (state == null) {
            return Activity.TIMER_STATE_OFF;
        }

        return state;
    }

    private function reconcile(info as Activity.Info) as Void {
        var expectedMoving = getExpectedMovingMs(info);
        var expectedPaused = getExpectedPausedMs(info);

        if (!_hasStarted && didActivityStart(info, expectedMoving, expectedPaused)) {
            _hasStarted = true;
        }

        if (numberDistance(_totalMovingMs, expectedMoving) > DRIFT_CORRECTION_THRESHOLD_MS) {
            var movingCorrection = expectedMoving - _totalMovingMs;
            _totalMovingMs = expectedMoving;
            _segmentMovingMs = correctedSegmentValue(_segmentMovingMs, movingCorrection);
            MovePauseLogger.debug("Corrected moving total from Activity.Info.");
        }

        if (numberDistance(_totalPausedMs, expectedPaused) > DRIFT_CORRECTION_THRESHOLD_MS) {
            var pausedCorrection = expectedPaused - _totalPausedMs;
            _totalPausedMs = expectedPaused;
            _segmentPausedMs = correctedSegmentValue(_segmentPausedMs, pausedCorrection);
            MovePauseLogger.debug("Corrected paused total from Activity.Info.");
        }

        if (!_hasStarted) {
            _currentPauseMs = 0;
        }
    }

    private function numberDistance(left as Number, right as Number) as Number {
        if (left >= right) {
            return left - right;
        }

        return right - left;
    }

    private function correctedSegmentValue(segmentValue as Number, correction as Number) as Number {
        var correctedValue = segmentValue + correction;

        if (correctedValue < 0) {
            return 0;
        }

        return correctedValue;
    }

    private function resetSegmentTotals() as Void {
        _segmentMovingMs = 0;
        _segmentPausedMs = 0;
    }
}
