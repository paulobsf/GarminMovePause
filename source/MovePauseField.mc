import Toybox.Activity;
import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class MovePauseField extends WatchUi.DataField {
    private const BASE_HORIZONTAL_PADDING = 6;
    private const BASE_VERTICAL_PADDING = 4;
    private const DARK_PROGRESS_TRACK_COLOR = 0x27302C;
    private const DARK_SECONDARY_TEXT_COLOR = 0xA8B4AD;
    private const LIGHT_PROGRESS_TRACK_COLOR = 0xD7DCD8;
    private const LIGHT_SECONDARY_TEXT_COLOR = 0x5B625E;
    private const MOVING_COLOR = 0x4EDB79;
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
        drawMetricLayout(
            dc,
            MovePauseFormatter.formatDuration(_engine.getCurrentMoveMs()),
            MOVING_COLOR,
            getMoveProgressRatio(),
            _engine.hasPreviousMove()
        );
    }

    private function drawPausedLayout(dc as Dc) as Void {
        drawMetricLayout(
            dc,
            MovePauseFormatter.formatDuration(_engine.getCurrentPauseMs()),
            PAUSED_COLOR,
            getPauseProgressRatio(),
            _engine.hasPreviousPause()
        );
    }

    private function drawMetricLayout(dc as Dc, primaryText as String, primaryColor as Number, progressRatio as Float, progressVisible as Boolean) as Void {
        var frame = getContentFrame(dc);
        var contentLeft = frame[0];
        var contentTop = frame[1];
        var contentWidth = frame[2];
        var contentHeight = frame[3];
        var secondaryVisible = _engine.hasPreviousMove();
        var secondaryText = secondaryVisible ? MovePauseFormatter.formatDuration(_engine.getPreviousMoveMs()) : "";
        var gap = (secondaryVisible || progressVisible) ? getSectionGap(contentHeight) : 0;
        var progressHeight = progressVisible ? getProgressBarHeight(contentHeight) : 0;
        var secondaryFont = Graphics.FONT_XTINY;
        var secondaryHeight = 0;
        var secondaryY = 0;
        var progressY = 0;
        var availableBottom = contentTop + contentHeight;

        if (secondaryVisible) {
            secondaryFont = pickMetricFont(dc, secondaryText, contentWidth, getSecondaryHeightBudget(contentHeight), [Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY]);
            secondaryHeight = Graphics.getFontHeight(secondaryFont);
            secondaryY = availableBottom - secondaryHeight;
            availableBottom = secondaryY - (progressVisible ? gap : 0);
        }

        if (progressVisible) {
            progressY = availableBottom - progressHeight;
            availableBottom = progressY - gap;
        }

        var primaryZoneHeight = availableBottom - contentTop;
        var primaryFont = pickMetricFont(dc, primaryText, contentWidth, primaryZoneHeight, [Graphics.FONT_NUMBER_HOT, Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_LARGE, Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY]);
        var primaryHeight = Graphics.getFontHeight(primaryFont);
        var primaryY = contentTop + maxNumber((primaryZoneHeight - primaryHeight) / 2, 0);

        dc.setColor(primaryColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(contentLeft + (contentWidth / 2), primaryY, primaryFont, primaryText, Graphics.TEXT_JUSTIFY_CENTER);

        if (progressVisible) {
            drawProgressBar(dc, contentLeft, progressY, contentWidth, progressHeight, progressRatio, _progressTrackColor, primaryColor);
        }

        if (secondaryVisible) {
            dc.setColor(_secondaryTextColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(contentLeft + (contentWidth / 2), secondaryY, secondaryFont, secondaryText, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    private function drawProgressBar(dc as Dc, x as Number, y as Number, width as Number, height as Number, progressRatio as Float or Number, trackColor as Number, fillColor as Number) as Void {
        var clampedRatio = clampRatio(progressRatio);
        var radius = maxNumber(height / 2, 1);

        dc.setColor(trackColor, trackColor);
        dc.fillRoundedRectangle(x, y, width, height, radius);

        if (clampedRatio <= 0.0) {
            return;
        }

        var fillWidth = width * clampedRatio;
        if (fillWidth > width) {
            fillWidth = width;
        }

        dc.setColor(fillColor, fillColor);
        dc.fillRoundedRectangle(x, y, fillWidth, height, radius);
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
            _progressTrackColor = LIGHT_PROGRESS_TRACK_COLOR;
        } else {
            _primaryTextColor = Graphics.COLOR_WHITE;
            _secondaryTextColor = DARK_SECONDARY_TEXT_COLOR;
            _progressTrackColor = DARK_PROGRESS_TRACK_COLOR;
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
        var leftPadding = clampNumber(width / 24, 0, 10) + BASE_HORIZONTAL_PADDING;
        var rightPadding = clampNumber(width / 24, 0, 10) + BASE_HORIZONTAL_PADDING;
        var topPadding = clampNumber(height / 18, 0, 8) + BASE_VERTICAL_PADDING;
        var bottomPadding = clampNumber(height / 18, 0, 8) + BASE_VERTICAL_PADDING;

        if ((obscurityFlags & OBSCURE_LEFT) != 0) {
            leftPadding += clampNumber(width / 18, 2, 10);
        }

        if ((obscurityFlags & OBSCURE_RIGHT) != 0) {
            rightPadding += clampNumber(width / 18, 2, 10);
        }

        if ((obscurityFlags & OBSCURE_TOP) != 0) {
            topPadding += clampNumber(height / 18, 2, 8);
        }

        if ((obscurityFlags & OBSCURE_BOTTOM) != 0) {
            bottomPadding += clampNumber(height / 18, 2, 8);
        }

        var contentWidth = width - leftPadding - rightPadding;
        var contentHeight = height - topPadding - bottomPadding;

        if (contentWidth < 20) {
            contentWidth = 20;
            leftPadding = (width - contentWidth) / 2;
        }

        if (contentHeight < 16) {
            contentHeight = 16;
            topPadding = (height - contentHeight) / 2;
        }

        return [leftPadding, topPadding, contentWidth, contentHeight];
    }

    private function getProgressBarHeight(contentHeight as Number) as Number {
        return clampNumber(contentHeight / 16, 2, 4);
    }

    private function getSecondaryHeightBudget(contentHeight as Number) as Number {
        return clampNumber(contentHeight / 6, 8, 16);
    }

    private function getSectionGap(contentHeight as Number) as Number {
        return clampNumber(contentHeight / 18, 2, 6);
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
