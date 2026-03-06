import Toybox.Activity;
import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class MovePauseField extends WatchUi.DataField {
    private const BASE_HORIZONTAL_PADDING = 2;
    private const BASE_VERTICAL_PADDING = 0;
    private const DARK_PROGRESS_TRACK_COLOR = 0x27302C;
    private const DARK_SECONDARY_TEXT_COLOR = 0xA8B4AD;
    private const GAUGE_MAX_SEGMENTS = 20;
    private const GAUGE_MIN_SEGMENTS = 8;
    private const GAUGE_SEGMENT_GAP = 1;
    private const GAUGE_TARGET_SEGMENTS = 18;
    private const GAUGE_MIN_SEGMENT_WIDTH = 2;
    private const LIGHT_SECONDARY_TEXT_COLOR = 0x5B625E;
    private const MOVING_COLOR = 0x4EDB79;
    private const OVERRUN_COLOR = 0xD94B45;
    private const PAUSE_PACE_INTERVAL_MS = 30000;
    private const PAUSED_COLOR = 0xF5A13B;

    private var _backgroundColor as Number = Graphics.COLOR_BLACK;
    private var _engine as MovePauseTimingEngine;
    private var _primaryTextColor as Number = Graphics.COLOR_WHITE;
    private var _progressTrackColor as Number = DARK_PROGRESS_TRACK_COLOR;
    private var _secondaryTextColor as Number = DARK_SECONDARY_TEXT_COLOR;

    function initialize() {
        DataField.initialize();
        _engine = new MovePauseTimingEngine();
        _engine.seedFromInfo(Activity.getActivityInfo());
    }

    function onTimerLap() as Void {
        _engine.handleTimerLap();
    }

    function onTimerPause() as Void {
        _engine.handleTimerPause();
    }

    function onTimerReset() as Void {
        _engine.handleTimerReset();
    }

    function onTimerResume() as Void {
        _engine.handleTimerResume();
    }

    function onTimerStart() as Void {
        _engine.handleTimerStart();
    }

    function onTimerStop() as Void {
        _engine.handleTimerStop();
    }

    function compute(info as Activity.Info) as Void {
        _engine.sync(info);
        triggerAlertsIfNeeded();
    }

    function onUpdate(dc as Dc) as Void {
        updateTheme();

        dc.setColor(_primaryTextColor, _backgroundColor);
        dc.clear();

        if (!_engine.hasStarted()) {
            drawReadyLayout(dc);
            return;
        }

        if (_engine.isPaused()) {
            drawPausedLayout(dc);
            return;
        }

        drawMovingLayout(dc);
    }

    private function drawReadyLayout(dc as Dc) as Void {
        var frame = getContentFrame(dc);
        var text = "READY";
        var font = pickMetricFont(dc, text, frame[2], frame[3], [Graphics.FONT_LARGE, Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY]);
        var textY = frame[1] + maxNumber((frame[3] - Graphics.getFontHeight(font)) / 2, 0);

        dc.setColor(_secondaryTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(frame[0] + (frame[2] / 2), textY, font, text, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawMovingLayout(dc as Dc) as Void {
        var referenceText = _engine.hasPreviousMove() ? MovePauseFormatter.formatDuration(_engine.getPreviousMoveMs()) : "";

        drawStackedLayout(
            dc,
            MovePauseFormatter.formatDuration(_engine.getCurrentMoveMs()),
            MOVING_COLOR,
            referenceText,
            _secondaryTextColor,
            MOVING_COLOR,
            true,
            getMoveProgressRatio()
        );
    }

    private function drawPausedLayout(dc as Dc) as Void {
        var referenceText = _engine.hasPreviousMove() ? MovePauseFormatter.formatDuration(_engine.getPreviousMoveMs()) : "";

        drawStackedLayout(
            dc,
            referenceText,
            _secondaryTextColor,
            MovePauseFormatter.formatDuration(_engine.getCurrentPauseMs()),
            PAUSED_COLOR,
            PAUSED_COLOR,
            false,
            getPauseProgressRatio()
        );
    }

    private function drawStackedLayout(dc as Dc, topText as String, topColor as Number, bottomText as String, bottomColor as Number, gaugeFillColor as Number, activeOnTop as Boolean, progressRatio as Float) as Void {
        var frame = getContentFrame(dc);
        var contentLeft = frame[0];
        var contentTop = frame[1];
        var contentWidth = frame[2];
        var contentHeight = frame[3];
        var gaugeHeight = getGaugeHeight(contentHeight);
        var gaugeGap = getGaugeGap(contentHeight);
        var timerZoneHeight = contentHeight - gaugeHeight - (gaugeGap * 2);

        if (timerZoneHeight <= 0) {
            timerZoneHeight = contentHeight - gaugeHeight;
            gaugeGap = 0;
        }

        var activeZoneHeight = getActiveTimerZoneHeight(timerZoneHeight);
        var referenceZoneHeight = timerZoneHeight - activeZoneHeight;
        var topZoneHeight = activeOnTop ? activeZoneHeight : referenceZoneHeight;
        var bottomZoneHeight = timerZoneHeight - topZoneHeight;
        var gaugeY = contentTop + topZoneHeight + gaugeGap;
        var bottomZoneTop = gaugeY + gaugeHeight + gaugeGap;

        drawTimerText(dc, contentLeft, contentTop, contentWidth, topZoneHeight, topText, topColor);
        drawSegmentedGauge(dc, contentLeft, gaugeY, contentWidth, gaugeHeight, progressRatio, gaugeFillColor);
        drawTimerText(dc, contentLeft, bottomZoneTop, contentWidth, bottomZoneHeight, bottomText, bottomColor);
    }

    private function drawTimerText(dc as Dc, x as Number, y as Number, width as Number, height as Number, text as String, color as Number) as Void {
        if ((text == "") || (height <= 0)) {
            return;
        }

        var font = pickMetricFont(dc, text, width, height, [Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_LARGE, Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY]);
        var textY = y + maxNumber((height - Graphics.getFontHeight(font)) / 2, 0);

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + (width / 2), textY, font, text, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawSegmentedGauge(dc as Dc, x as Number, y as Number, width as Number, height as Number, progressRatio as Float or Number, fillColor as Number) as Void {
        var segmentCount = getGaugeSegmentCount(width);
        var segmentWidth = maxNumber((width - ((segmentCount - 1) * GAUGE_SEGMENT_GAP)) / segmentCount, GAUGE_MIN_SEGMENT_WIDTH);
        var usedWidth = (segmentWidth * segmentCount) + ((segmentCount - 1) * GAUGE_SEGMENT_GAP);
        var startX = x + maxNumber((width - usedWidth) / 2, 0);
        var clampedRatio = clampRatio(progressRatio);
        var fillBoundary = clampedRatio * segmentCount.toFloat();
        var activeColor = (progressRatio.toFloat() >= 1.0) ? OVERRUN_COLOR : fillColor;
        var index = 0;

        while (index < segmentCount) {
            var segmentX = startX + (index * (segmentWidth + GAUGE_SEGMENT_GAP));
            var segmentColor = _progressTrackColor;

            if (index.toFloat() < fillBoundary) {
                segmentColor = activeColor;
            }

            dc.setColor(segmentColor, segmentColor);
            dc.fillRectangle(segmentX, y, segmentWidth, height);
            index += 1;
        }
    }

    private function triggerAlertsIfNeeded() as Void {
        if (_engine.shouldTriggerMoveReferenceAlert() || _engine.shouldTriggerPauseReferenceAlert()) {
            triggerReferenceCue();
            return;
        }

        if (_engine.shouldTriggerPausePaceAlert(PAUSE_PACE_INTERVAL_MS)) {
            triggerPausePaceCue();
        }
    }

    private function triggerReferenceCue() as Void {
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_LOUD_BEEP);
        }

        if (!(Attention has :vibrate) || !(Attention has :VibeProfile)) {
            return;
        }

        Attention.vibrate([
            new Attention.VibeProfile(80, 120),
            new Attention.VibeProfile(0, 60),
            new Attention.VibeProfile(100, 140)
        ]);
    }

    private function triggerPausePaceCue() as Void {
        if (!(Attention has :vibrate) || !(Attention has :VibeProfile)) {
            return;
        }

        Attention.vibrate([
            new Attention.VibeProfile(60, 140)
        ]);
    }

    private function updateTheme() as Void {
        _backgroundColor = getBackgroundColor();

        if (isLightBackground(_backgroundColor)) {
            _primaryTextColor = Graphics.COLOR_BLACK;
            _secondaryTextColor = LIGHT_SECONDARY_TEXT_COLOR;
        } else {
            _primaryTextColor = Graphics.COLOR_WHITE;
            _secondaryTextColor = DARK_SECONDARY_TEXT_COLOR;
        }
    }

    private function getMoveProgressRatio() as Float {
        if (!_engine.hasPreviousMove()) {
            return 0.0;
        }

        var previousMoveMs = _engine.getPreviousMoveMs();
        if (previousMoveMs <= 0) {
            return 0.0;
        }

        return _engine.getCurrentMoveMs().toFloat() / previousMoveMs.toFloat();
    }

    private function getPauseProgressRatio() as Float {
        if (!_engine.hasPreviousPause()) {
            return 0.0;
        }

        var previousPauseMs = _engine.getPreviousPauseMs();
        if (previousPauseMs <= 0) {
            return 0.0;
        }

        return _engine.getCurrentPauseMs().toFloat() / previousPauseMs.toFloat();
    }

    private function getContentFrame(dc as Dc) as Array<Number> {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var obscurityFlags = DataField.getObscurityFlags();
        var leftPadding = clampNumber(width / 60, 0, 3) + BASE_HORIZONTAL_PADDING;
        var rightPadding = clampNumber(width / 60, 0, 3) + BASE_HORIZONTAL_PADDING;
        var topPadding = clampNumber(height / 60, 0, 1) + BASE_VERTICAL_PADDING;
        var bottomPadding = clampNumber(height / 60, 0, 1) + BASE_VERTICAL_PADDING;

        if ((obscurityFlags & OBSCURE_LEFT) != 0) {
            leftPadding += clampNumber(width / 28, 1, 6);
        }

        if ((obscurityFlags & OBSCURE_RIGHT) != 0) {
            rightPadding += clampNumber(width / 28, 1, 6);
        }

        if ((obscurityFlags & OBSCURE_TOP) != 0) {
            topPadding += clampNumber(height / 28, 1, 4);
        }

        if ((obscurityFlags & OBSCURE_BOTTOM) != 0) {
            bottomPadding += clampNumber(height / 28, 1, 4);
        }

        var contentWidth = width - leftPadding - rightPadding;
        var contentHeight = height - topPadding - bottomPadding;

        var minimumGaugeWidth = (GAUGE_MIN_SEGMENTS * GAUGE_MIN_SEGMENT_WIDTH) + ((GAUGE_MIN_SEGMENTS - 1) * GAUGE_SEGMENT_GAP);
        if (contentWidth < minimumGaugeWidth) {
            contentWidth = minimumGaugeWidth;
            leftPadding = maxNumber((width - contentWidth) / 2, 0);
        }

        if (contentHeight < 16) {
            contentHeight = 16;
            topPadding = (height - contentHeight) / 2;
        }

        return [leftPadding, topPadding, contentWidth, contentHeight];
    }

    private function getGaugeHeight(contentHeight as Number) as Number {
        return clampNumber(contentHeight / 7, 4, 10);
    }

    private function getGaugeGap(contentHeight as Number) as Number {
        return clampNumber(contentHeight / 20, 0, 2);
    }

    private function getActiveTimerZoneHeight(timerZoneHeight as Number) as Number {
        if (timerZoneHeight <= 0) {
            return 0;
        }

        if (timerZoneHeight < 14) {
            return (timerZoneHeight + 1) / 2;
        }

        return clampNumber((timerZoneHeight * 6) / 11, 7, timerZoneHeight - 6);
    }

    private function getGaugeSegmentCount(width as Number) as Number {
        if (canFitGaugeSegments(width, GAUGE_TARGET_SEGMENTS)) {
            return GAUGE_TARGET_SEGMENTS;
        }

        var count = GAUGE_MAX_SEGMENTS;

        while (count >= GAUGE_MIN_SEGMENTS) {
            if (canFitGaugeSegments(width, count)) {
                return count;
            }

            count -= 1;
        }

        return GAUGE_MIN_SEGMENTS;
    }

    private function canFitGaugeSegments(width as Number, count as Number) as Boolean {
        return (width - ((count - 1) * GAUGE_SEGMENT_GAP)) >= (count * GAUGE_MIN_SEGMENT_WIDTH);
    }

    private function pickMetricFont(dc as Dc, text as String, maxWidth as Number, maxHeight as Number, fonts as Array<Graphics.FontType>) as Graphics.FontType {
        var index = 0;

        while (index < fonts.size()) {
            var font = fonts[index];
            if ((dc.getTextWidthInPixels(text, font) <= maxWidth) && (Graphics.getFontHeight(font) <= maxHeight)) {
                return font;
            }
            index += 1;
        }

        return fonts[fonts.size() - 1];
    }

    private function isLightBackground(color as Number) as Boolean {
        return (color == Graphics.COLOR_WHITE) || (color == Graphics.COLOR_LT_GRAY);
    }

    private function clampRatio(value as Float or Number) as Float {
        var ratio = value.toFloat();

        if (ratio < 0.0) {
            return 0.0;
        }

        if (ratio > 1.0) {
            return 1.0;
        }

        return ratio;
    }

    private function clampNumber(value as Number, minimum as Number, maximum as Number) as Number {
        if (value < minimum) {
            return minimum;
        }

        if (value > maximum) {
            return maximum;
        }

        return value;
    }

    private function maxNumber(left as Number, right as Number) as Number {
        if (left >= right) {
            return left;
        }

        return right;
    }
}
