import Toybox.Activity;
import Toybox.Lang;
import Toybox.System;

class MovePauseTimingEngine {
    private var _currentMoveMs as Number = 0;
    private var _currentPauseMs as Number = 0;
    private var _hasStarted as Boolean = false;
    private var _lastTickMs as Number?;
    private var _previousMoveMs as Number = 0;
    private var _targetAlertFiredForPause as Boolean = false;
    private var _timerState as Number = Activity.TIMER_STATE_OFF;

    function initialize() {
        reset();
    }

    function reset() as Void {
        _currentMoveMs = 0;
        _currentPauseMs = 0;
        _hasStarted = false;
        _lastTickMs = null;
        _previousMoveMs = 0;
        _targetAlertFiredForPause = false;
        _timerState = Activity.TIMER_STATE_OFF;
        MovePauseLogger.debug("Timing engine reset.");
    }

    function seedFromInfo(info as Activity.Info?) as Void {
        _lastTickMs = System.getTimer();

        if (info == null) {
            _timerState = Activity.TIMER_STATE_OFF;
            return;
        }

        var observedState = getObservedState(info);
        var expectedMoving = getExpectedMovingMs(info);
        var expectedPaused = getExpectedPausedMs(info);

        _currentMoveMs = 0;
        _currentPauseMs = 0;
        _previousMoveMs = 0;
        _targetAlertFiredForPause = false;
        _timerState = observedState;
        _hasStarted = didActivityStart(observedState, expectedMoving, expectedPaused);

        if (!_hasStarted) {
            _timerState = Activity.TIMER_STATE_OFF;
            return;
        }

        // Best-effort seeding only when move/pause boundaries are unambiguous.
        if ((observedState == Activity.TIMER_STATE_ON) && (expectedPaused <= 0)) {
            _currentMoveMs = expectedMoving;
        } else if (isPausedLike(observedState) && (expectedMoving > 0)) {
            _previousMoveMs = expectedMoving;
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
    }

    function handleTimerLap() as Void {
        MovePauseLogger.debug("Ignored onTimerLap; field tracks move/pause periods only.");
    }

    function handleTimerPause() as Void {
        handleTimerEvent(Activity.TIMER_STATE_PAUSED, "onTimerPause");
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

    function getCurrentMoveMs() as Number {
        return _currentMoveMs;
    }

    function getCurrentPauseMs() as Number {
        return _currentPauseMs;
    }

    function getPreviousMoveMs() as Number {
        return _previousMoveMs;
    }

    function getRemainingRecoveryMs(targetMs as Number) as Number {
        if (targetMs <= 0) {
            return 0;
        }

        var remainingMs = targetMs - _currentPauseMs;
        if (remainingMs < 0) {
            return 0;
        }

        return remainingMs;
    }

    function hasPreviousMove() as Boolean {
        return _previousMoveMs > 0;
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

    function isRecoveryTargetReached(targetMs as Number) as Boolean {
        return (targetMs > 0) && isPaused() && (_currentPauseMs >= targetMs);
    }

    function shouldTriggerRecoveryAlert(targetMs as Number) as Boolean {
        if ((targetMs <= 0) || _targetAlertFiredForPause || !isRecoveryTargetReached(targetMs)) {
            return false;
        }

        _targetAlertFiredForPause = true;
        return true;
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
            _currentMoveMs += delta;
            _currentPauseMs = 0;
            return;
        }

        if (_hasStarted && isPausedLike(_timerState)) {
            _currentPauseMs += delta;
            return;
        }

        _currentPauseMs = 0;
    }

    private function applyState(nextState as Number, source as String) as Void {
        var previousState = _timerState;

        if ((previousState == Activity.TIMER_STATE_ON) && isPausedLike(nextState)) {
            _previousMoveMs = _currentMoveMs;
            _currentMoveMs = 0;
            _currentPauseMs = 0;
            _targetAlertFiredForPause = false;
        } else if (isPausedLike(previousState) && (nextState == Activity.TIMER_STATE_ON)) {
            _currentMoveMs = 0;
            _currentPauseMs = 0;
            _targetAlertFiredForPause = false;
        } else if (!_hasStarted && (nextState == Activity.TIMER_STATE_ON)) {
            _currentMoveMs = 0;
            _currentPauseMs = 0;
            _targetAlertFiredForPause = false;
        } else if (!isPausedLike(nextState)) {
            _currentPauseMs = 0;
        }

        _timerState = nextState;

        if (_timerState == Activity.TIMER_STATE_ON) {
            _hasStarted = true;
        } else if (_timerState == Activity.TIMER_STATE_OFF) {
            _currentPauseMs = 0;
        }

        if (previousState != nextState) {
            MovePauseLogger.debug("Timer state changed via " + source + ".");
        }
    }

    private function didActivityStart(observedState as Number, expectedMoving as Number, expectedPaused as Number) as Boolean {
        if ((expectedMoving > 0) || (expectedPaused > 0)) {
            return true;
        }

        return observedState == Activity.TIMER_STATE_ON;
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
        return normalizeState(info.timerState);
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
}
