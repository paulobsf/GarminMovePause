import Toybox.Activity;
import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class MovePauseField extends WatchUi.DataField {
    private const EDGE_PADDING = 10;
    private const OVERTIME_COLOR = 0xD94B4B;
    private const PAUSED_COLOR = 0xF5A13B;
    private const PRIMARY_MARKER_GAP = 10;
    private const PROGRESS_BAR_HEIGHT = 4;
    private const PROGRESS_HEAD_SIZE = 8;
    private const ROUND_SAFE_MARGIN = 4;
    private const SAFE_BOTTOM_PADDING = 14;
    private const SECONDARY_ICON_GAP = 6;
    private const SECONDARY_ICON_SIZE = 10;
    private const SECTION_GAP = 10;
    private const MOVING_COLOR = 0x4EDB79;
    private const DARK_PROGRESS_TRACK_COLOR = 0x27302C;
    private const DARK_SECONDARY_TEXT_COLOR = 0xA8B4AD;
    private const LIGHT_PROGRESS_TRACK_COLOR = 0xD7DCD8;
    private const LIGHT_SECONDARY_TEXT_COLOR = 0x5B625E;

    private var _backgroundColor as Number = Graphics.COLOR_BLACK;
    private var _buzzOnTarget as Boolean = true;
    private var _engine as MovePauseTimingEngine;
    private var _primaryTextColor as Number = Graphics.COLOR_WHITE;
    private var _progressTrackColor as Number = DARK_PROGRESS_TRACK_COLOR;
    private var _recoveryTargetMs as Number = 0;
    private var _secondaryTextColor as Number = DARK_SECONDARY_TEXT_COLOR;

    function initialize() {
        DataField.initialize();
        _engine = new MovePauseTimingEngine();
        _engine.seedFromInfo(Activity.getActivityInfo());
        loadSettings();
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
        loadSettings();
        _engine.sync(info);
        triggerRecoveryAlertIfNeeded();
    }

    function onUpdate(dc as Dc) as Void {
        loadSettings();

        dc.setColor(_primaryTextColor, _backgroundColor);
        dc.clear();
        dc.setColor(_primaryTextColor, Graphics.COLOR_TRANSPARENT);

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

    function loadSettings() as Void {
        _recoveryTargetMs = MovePauseSettings.getRecoveryTargetMs();
        _buzzOnTarget = MovePauseSettings.shouldBuzzOnTarget();

        if (MovePauseSettings.useLightBackground()) {
            _backgroundColor = Graphics.COLOR_WHITE;
            _primaryTextColor = Graphics.COLOR_BLACK;
            _secondaryTextColor = LIGHT_SECONDARY_TEXT_COLOR;
            _progressTrackColor = LIGHT_PROGRESS_TRACK_COLOR;
        } else {
            _backgroundColor = Graphics.COLOR_BLACK;
            _primaryTextColor = Graphics.COLOR_WHITE;
            _secondaryTextColor = DARK_SECONDARY_TEXT_COLOR;
            _progressTrackColor = DARK_PROGRESS_TRACK_COLOR;
        }
    }

    private function triggerRecoveryAlertIfNeeded() as Void {
        if (!_buzzOnTarget || !_engine.shouldTriggerRecoveryAlert(_recoveryTargetMs)) {
            return;
        }

        if (!(Attention has :vibrate) || !(Attention has :VibeProfile)) {
            return;
        }

        Attention.vibrate([
            new Attention.VibeProfile(70, 120),
            new Attention.VibeProfile(0, 80),
            new Attention.VibeProfile(90, 140)
        ]);
    }

    private function drawReadyLayout(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var primaryZoneTop = EDGE_PADDING;
        var primaryZoneHeight = height - (2 * EDGE_PADDING);
        var text = "Start activity to begin";
        var textWidth = getSampleBandWidth(width, height, primaryZoneTop, primaryZoneHeight, 56, EDGE_PADDING + 6);
        var font = pickMetricFont(dc, text, textWidth, [Graphics.FONT_LARGE, Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY]);
        var textHeight = Graphics.getFontHeight(font);
        var textY = primaryZoneTop + ((primaryZoneHeight - textHeight) / 2);

        dc.setColor(_primaryTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, textY, font, text, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawMovingLayout(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var secondaryVisible = _engine.hasPreviousMove();
        var secondaryHeight = secondaryVisible ? Graphics.getFontHeight(Graphics.FONT_MEDIUM) : 0;
        var secondaryY = secondaryVisible ? (height - SAFE_BOTTOM_PADDING - secondaryHeight) : 0;
        var progressVisible = secondaryVisible;
        var progressY = progressVisible ? (secondaryY - SECTION_GAP - PROGRESS_BAR_HEIGHT) : 0;
        var primaryZoneTop = EDGE_PADDING;
        var primaryZoneBottom = progressVisible ? (progressY - 12) : (height - SAFE_BOTTOM_PADDING - 6);
        var primaryText = MovePauseFormatter.formatDuration(_engine.getCurrentMoveMs());
        var primaryWidth = getSampleBandWidth(width, height, primaryZoneTop, primaryZoneBottom - primaryZoneTop, 64, EDGE_PADDING + 6);
        var primaryFont = pickMetricFont(dc, primaryText, primaryWidth, [Graphics.FONT_NUMBER_HOT, Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_LARGE, Graphics.FONT_MEDIUM]);
        var primaryHeight = Graphics.getFontHeight(primaryFont);
        var primaryY = primaryZoneTop + (((primaryZoneBottom - primaryZoneTop) - primaryHeight) / 2);

        drawPrimaryMetric(dc, width / 2, primaryY, primaryFont, primaryText, MOVING_COLOR, false);

        if (secondaryVisible) {
            var progressBounds = getSafeBandRect(width, height, progressY, PROGRESS_BAR_HEIGHT, EDGE_PADDING + 8);
            var progressTrackColor = isMovingPastReference() ? PAUSED_COLOR : _progressTrackColor;
            var progressFillColor = isMovingPastReference() ? PAUSED_COLOR : MOVING_COLOR;
            drawProgressBar(dc, progressBounds[0], progressY, progressBounds[1], PROGRESS_BAR_HEIGHT, getMovingProgressRatio(), progressTrackColor, progressFillColor, false);

            var secondaryText = MovePauseFormatter.formatDuration(_engine.getPreviousMoveMs());
            var secondaryWidth = getSampleBandWidth(width, height, height - 34, 28, 28, EDGE_PADDING + 6) - SECONDARY_ICON_SIZE - SECONDARY_ICON_GAP;
            var secondaryFont = pickMetricFont(dc, secondaryText, secondaryWidth, [Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY]);
            secondaryHeight = Graphics.getFontHeight(secondaryFont);
            secondaryY = height - SAFE_BOTTOM_PADDING - secondaryHeight;
            drawSecondaryMetric(dc, width / 2, secondaryY, secondaryFont, secondaryText);
        }
    }

    private function drawPausedLayout(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var secondaryVisible = _engine.hasPreviousMove();
        var secondaryHeight = secondaryVisible ? Graphics.getFontHeight(Graphics.FONT_MEDIUM) : 0;
        var secondaryY = secondaryVisible ? (height - SAFE_BOTTOM_PADDING - secondaryHeight) : 0;
        var progressVisible = (_recoveryTargetMs > 0);
        var progressY = secondaryVisible ? (secondaryY - SECTION_GAP - PROGRESS_BAR_HEIGHT) : (height - SAFE_BOTTOM_PADDING - PROGRESS_BAR_HEIGHT);
        var primaryZoneTop = EDGE_PADDING;
        var primaryZoneBottom = progressVisible ? (progressY - 12) : (secondaryVisible ? (secondaryY - 10) : (height - SAFE_BOTTOM_PADDING - 6));
        var primaryText = getPausedPrimaryText();
        var primaryWidth = getSampleBandWidth(width, height, primaryZoneTop, primaryZoneBottom - primaryZoneTop, 64, EDGE_PADDING + 6);
        var primaryFont = pickMetricFont(dc, primaryText, primaryWidth, [Graphics.FONT_NUMBER_HOT, Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_LARGE, Graphics.FONT_MEDIUM]);
        var primaryHeight = Graphics.getFontHeight(primaryFont);
        var primaryY = primaryZoneTop + (((primaryZoneBottom - primaryZoneTop) - primaryHeight) / 2);

        drawPrimaryMetric(dc, width / 2, primaryY, primaryFont, primaryText, PAUSED_COLOR, true);

        if (progressVisible) {
            var progressBounds = getSafeBandRect(width, height, progressY, PROGRESS_BAR_HEIGHT, EDGE_PADDING + 8);
            var progressTrackColor = isPausedOvertime() ? OVERTIME_COLOR : _progressTrackColor;
            var progressFillColor = isPausedOvertime() ? OVERTIME_COLOR : PAUSED_COLOR;
            drawProgressBar(dc, progressBounds[0], progressY, progressBounds[1], PROGRESS_BAR_HEIGHT, getPausedProgressRatio(), progressTrackColor, progressFillColor, true);
        }

        if (secondaryVisible) {
            var secondaryText = MovePauseFormatter.formatDuration(_engine.getPreviousMoveMs());
            var secondaryWidth = getSampleBandWidth(width, height, height - 34, 28, 28, EDGE_PADDING + 6) - SECONDARY_ICON_SIZE - SECONDARY_ICON_GAP;
            var secondaryFont = pickMetricFont(dc, secondaryText, secondaryWidth, [Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY]);
            secondaryHeight = Graphics.getFontHeight(secondaryFont);
            secondaryY = height - SAFE_BOTTOM_PADDING - secondaryHeight;
            drawSecondaryMetric(dc, width / 2, secondaryY, secondaryFont, secondaryText);
        }
    }

    private function drawProgressBar(dc as Dc, x as Number, y as Number, width as Number, height as Number, progressRatio as Float or Number, trackColor as Number, fillColor as Number, alignRight as Boolean) as Void {
        var clampedRatio = clampRatio(progressRatio);
        var radius = height / 2;

        dc.setColor(trackColor, trackColor);
        dc.fillRoundedRectangle(x, y, width, height, radius);

        if (clampedRatio <= 0) {
            return;
        }

        var fillWidth = width * clampedRatio;
        if (fillWidth > width) {
            fillWidth = width;
        }

        var fillX = alignRight ? (x + width - fillWidth) : x;
        dc.setColor(fillColor, fillColor);
        dc.fillRoundedRectangle(fillX, y, fillWidth, height, radius);

        if ((clampedRatio < 1.0) && (fillWidth >= height)) {
            var headSize = PROGRESS_HEAD_SIZE;
            if (headSize < height) {
                headSize = height;
            }

            var headY = y - ((headSize - height) / 2);
            var headX = alignRight ? (fillX - (headSize / 2)) : (fillX + fillWidth - (headSize / 2));

            if (headX < x) {
                headX = x;
            }

            if ((headX + headSize) > (x + width)) {
                headX = x + width - headSize;
            }

            dc.fillRoundedRectangle(headX, headY, headSize, headSize, headSize / 2);
        }
    }

    private function drawPrimaryMetric(dc as Dc, centerX as Number, y as Number, font as Graphics.FontType, text as String, markerColor as Number, isPaused as Boolean) as Void {
        var fontHeight = Graphics.getFontHeight(font);
        var markerSize = fontHeight / 4;
        var textWidth = dc.getTextWidthInPixels(text, font);

        if (markerSize < 8) {
            markerSize = 8;
        }

        if (markerSize > 18) {
            markerSize = 18;
        }

        var groupWidth = markerSize + PRIMARY_MARKER_GAP + textWidth;
        var markerX = centerX - (groupWidth / 2);
        var markerY = y + ((fontHeight - markerSize) / 2);
        var textX = markerX + markerSize + PRIMARY_MARKER_GAP;

        dc.setColor(markerColor, markerColor);
        if (isPaused) {
            drawPausedPrimaryIcon(dc, markerX, markerY, markerSize);
        } else {
            drawMovingPrimaryIcon(dc, markerX, markerY, markerSize);
        }

        dc.setColor(_primaryTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(textX, y, font, text, Graphics.TEXT_JUSTIFY_LEFT);
    }

    private function drawMovingPrimaryIcon(dc as Dc, x as Number, y as Number, size as Number) as Void {
        var triangleWidth = size;
        var triangleHeight = size;
        var column = 0;

        while (column < triangleWidth) {
            var progress = column.toFloat() / triangleWidth.toFloat();
            var startY = y + ((triangleHeight * progress) / 2);
            var drawHeight = triangleHeight - (triangleHeight * progress);

            if (drawHeight < 1) {
                drawHeight = 1;
            }

            dc.fillRectangle(x + column, startY, 1, drawHeight);
            column += 1;
        }
    }

    private function drawPausedPrimaryIcon(dc as Dc, x as Number, y as Number, size as Number) as Void {
        var barWidth = size / 4;
        var gap = size / 4;
        var barHeight = size;

        if (barWidth < 2) {
            barWidth = 2;
        }

        if (gap < 2) {
            gap = 2;
        }

        var totalWidth = (2 * barWidth) + gap;
        var startX = x + ((size - totalWidth) / 2);

        dc.fillRectangle(startX, y, barWidth, barHeight);
        dc.fillRectangle(startX + barWidth + gap, y, barWidth, barHeight);
    }

    private function drawSecondaryMetric(dc as Dc, centerX as Number, y as Number, font as Graphics.FontType, text as String) as Void {
        var fontHeight = Graphics.getFontHeight(font);
        var textWidth = dc.getTextWidthInPixels(text, font);
        var groupWidth = SECONDARY_ICON_SIZE + SECONDARY_ICON_GAP + textWidth;
        var iconX = centerX - (groupWidth / 2);
        var iconY = y + ((fontHeight - SECONDARY_ICON_SIZE) / 2);
        var textX = iconX + SECONDARY_ICON_SIZE + SECONDARY_ICON_GAP;

        dc.setColor(_secondaryTextColor, _secondaryTextColor);
        drawPreviousIcon(dc, iconX, iconY, SECONDARY_ICON_SIZE);

        dc.setColor(_secondaryTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(textX, y, font, text, Graphics.TEXT_JUSTIFY_LEFT);
    }

    private function drawPreviousIcon(dc as Dc, x as Number, y as Number, size as Number) as Void {
        var column = 0;

        while (column < size) {
            var progress = column.toFloat() / size.toFloat();
            var startY = y + ((size * progress) / 2);
            var drawHeight = size - (size * progress);

            if (drawHeight < 1) {
                drawHeight = 1;
            }

            dc.fillRectangle(x + (size - 1 - column), startY, 1, drawHeight);
            column += 1;
        }
    }

    private function getPausedPrimaryText() as String {
        if (_recoveryTargetMs <= 0) {
            return MovePauseFormatter.formatDuration(_engine.getCurrentPauseMs());
        }

        if (isPausedOvertime()) {
            return MovePauseFormatter.formatOvertime(_engine.getCurrentPauseMs() - _recoveryTargetMs);
        }

        return MovePauseFormatter.formatCountdown(_engine.getRemainingRecoveryMs(_recoveryTargetMs));
    }

    private function isPausedOvertime() as Boolean {
        return (_recoveryTargetMs > 0) && _engine.isRecoveryTargetReached(_recoveryTargetMs);
    }

    private function getPausedProgressRatio() as Float {
        if (_recoveryTargetMs <= 0) {
            return 0.0;
        }

        if (isPausedOvertime()) {
            return 1.0;
        }

        return _engine.getRemainingRecoveryMs(_recoveryTargetMs).toFloat() / _recoveryTargetMs.toFloat();
    }

    private function getMovingProgressRatio() as Float {
        if (!_engine.hasPreviousMove()) {
            return 0.0;
        }

        var previousMoveMs = _engine.getPreviousMoveMs();
        if (previousMoveMs <= 0) {
            return 0.0;
        }

        return _engine.getCurrentMoveMs().toFloat() / previousMoveMs.toFloat();
    }

    private function isMovingPastReference() as Boolean {
        return _engine.hasPreviousMove() && (_engine.getCurrentMoveMs() >= _engine.getPreviousMoveMs());
    }

    private function getSampleBandWidth(totalWidth as Number, totalHeight as Number, zoneTop as Number, zoneHeight as Number, sampleHeight as Number, padding as Number) as Number {
        if (zoneHeight < sampleHeight) {
            sampleHeight = zoneHeight;
        }

        if (sampleHeight < 20) {
            sampleHeight = 20;
        }

        var y = zoneTop + ((zoneHeight - sampleHeight) / 2);
        return getSafeBandRect(totalWidth, totalHeight, y, sampleHeight, padding)[1];
    }

    private function pickMetricFont(dc as Dc, text as String, maxWidth as Number, fonts as Array<Graphics.FontType>) as Graphics.FontType {
        var index = 0;

        while (index < fonts.size()) {
            var font = fonts[index];
            if (dc.getTextWidthInPixels(text, font) <= maxWidth) {
                return font;
            }
            index += 1;
        }

        return fonts[fonts.size() - 1];
    }

    private function clampRatio(value as Float or Number) as Float {
        var ratio = value.toFloat();

        if (ratio < 0) {
            return 0.0;
        }

        if (ratio > 1.0) {
            return 1.0;
        }

        return ratio;
    }

    private function getSafeBandRect(totalWidth as Number, totalHeight as Number, yTop as Number, bandHeight as Number, padding as Number) as Array<Number> {
        var inset = getSafeBandInset(totalWidth, totalHeight, yTop, bandHeight) + padding;
        var safeWidth = totalWidth - (2 * inset);

        if (safeWidth < 40) {
            safeWidth = 40;
            inset = (totalWidth - safeWidth) / 2;
        }

        return [inset, safeWidth];
    }

    private function getSafeBandInset(totalWidth as Number, totalHeight as Number, yTop as Number, bandHeight as Number) as Number {
        var insetTop = getEllipseInsetAtY(totalWidth, totalHeight, yTop);
        var insetMid = getEllipseInsetAtY(totalWidth, totalHeight, yTop + (bandHeight / 2));
        var insetBottom = getEllipseInsetAtY(totalWidth, totalHeight, yTop + bandHeight);
        return maxNumber(maxNumber(insetTop, insetMid), insetBottom) + ROUND_SAFE_MARGIN;
    }

    private function getEllipseInsetAtY(totalWidth as Number, totalHeight as Number, y as Number) as Number {
        var radiusX = totalWidth / 2;
        var radiusY = totalHeight / 2;
        var centerY = radiusY;
        var dy = y - centerY;

        if (dy < 0) {
            dy = 0 - dy;
        }

        if (dy >= radiusY) {
            return radiusX;
        }

        var widthSquared = (radiusX * radiusX * ((radiusY * radiusY) - (dy * dy))) / (radiusY * radiusY);
        var halfWidth = integerSqrt(widthSquared);
        return radiusX - halfWidth;
    }

    private function maxNumber(left as Number, right as Number) as Number {
        if (left >= right) {
            return left;
        }

        return right;
    }

    private function integerSqrt(value as Number) as Number {
        if (value <= 0) {
            return 0;
        }

        var low = 0;
        var high = value;
        var result = 0;

        while (low <= high) {
            var mid = (low + high) / 2;
            var square = mid * mid;

            if (square == value) {
                return mid;
            }

            if (square < value) {
                result = mid;
                low = mid + 1;
            } else {
                high = mid - 1;
            }
        }

        return result;
    }
}
