import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class MovePauseField extends WatchUi.DataField {
    private const LAYOUT_FULL = 2;
    private const LAYOUT_LAP_WITH_TOTAL_PAUSE = 1;
    private const LAYOUT_LAP_ONLY = 0;
    private const LINE_SPACING = 4;

    private var _compact as Boolean = false;
    private var _engine as MovePauseTimingEngine;
    private var _layoutMode as Number = LAYOUT_LAP_ONLY;
    private var _stateFont as Graphics.FontType = Graphics.FONT_TINY;
    private var _stateY as Number = 0;
    private var _valueYs as Array<Number> = [];
    private var _valueFont as Graphics.FontType = Graphics.FONT_SMALL;

    function initialize() {
        DataField.initialize();
        _engine = new MovePauseTimingEngine();
        _engine.seedFromInfo(Activity.getActivityInfo());
    }

    function onLayout(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();

        _compact = (height < 96) || (width < 120);

        if (canFit(height, Graphics.FONT_TINY, Graphics.FONT_SMALL, 4) && (width >= 130)) {
            configureLayout(height, LAYOUT_FULL, Graphics.FONT_TINY, Graphics.FONT_SMALL, 4);
        } else if (canFit(height, Graphics.FONT_XTINY, Graphics.FONT_TINY, 4) && (width >= 110)) {
            configureLayout(height, LAYOUT_FULL, Graphics.FONT_XTINY, Graphics.FONT_TINY, 4);
        } else if (canFit(height, Graphics.FONT_XTINY, Graphics.FONT_TINY, 3)) {
            configureLayout(height, LAYOUT_LAP_WITH_TOTAL_PAUSE, Graphics.FONT_XTINY, Graphics.FONT_TINY, 3);
        } else {
            configureLayout(height, LAYOUT_LAP_ONLY, Graphics.FONT_XTINY, Graphics.FONT_TINY, 2);
        }
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
    }

    function onUpdate(dc as Dc) as Void {
        var backgroundColor = getBackgroundColor();
        var foregroundColor = Graphics.COLOR_WHITE;

        if (backgroundColor == Graphics.COLOR_WHITE) {
            foregroundColor = Graphics.COLOR_BLACK;
        }

        dc.setColor(foregroundColor, backgroundColor);
        dc.clear();
        dc.setColor(foregroundColor, Graphics.COLOR_TRANSPARENT);

        var centerX = dc.getWidth() / 2;
        var stateText = MovePauseFormatter.formatStateLabel(_engine.hasStarted(), _engine.isMoving(), _engine.isPaused());
        var lapMovingText = (_compact ? "LM " : "Lap M ") + MovePauseFormatter.formatDuration(_engine.getLapMovingMs());
        var lapPausedText = (_compact ? "LP " : "Lap P ") + MovePauseFormatter.formatDuration(_engine.getLapPausedMs());
        var valueLines = [lapMovingText, lapPausedText];

        dc.drawText(centerX, _stateY, _stateFont, stateText, Graphics.TEXT_JUSTIFY_CENTER);

        if (_layoutMode == LAYOUT_FULL) {
            valueLines.add((_compact ? "TM " : "Tot M ") + MovePauseFormatter.formatDuration(_engine.getTotalMovingMs()));
            valueLines.add((_compact ? "TP " : "Tot P ") + MovePauseFormatter.formatDuration(_engine.getTotalPausedMs()));
        } else if (_layoutMode == LAYOUT_LAP_WITH_TOTAL_PAUSE) {
            valueLines.add((_compact ? "TP " : "Tot P ") + MovePauseFormatter.formatDuration(_engine.getTotalPausedMs()));
        }

        var lineCount = valueLines.size();
        var index = 0;
        while (index < lineCount) {
            dc.drawText(centerX, _valueYs[index], _valueFont, valueLines[index], Graphics.TEXT_JUSTIFY_CENTER);
            index += 1;
        }
    }

    private function canFit(height as Number, stateFont as Graphics.FontType, valueFont as Graphics.FontType, valueLineCount as Number) as Boolean {
        var stateHeight = Graphics.getFontHeight(stateFont);
        var valueHeight = Graphics.getFontHeight(valueFont);
        var blockHeight = stateHeight + (valueLineCount * valueHeight) + (valueLineCount * LINE_SPACING);

        return blockHeight <= height;
    }

    private function configureLayout(height as Number, layoutMode as Number, stateFont as Graphics.FontType, valueFont as Graphics.FontType, valueLineCount as Number) as Void {
        _layoutMode = layoutMode;
        _stateFont = stateFont;
        _valueFont = valueFont;

        var stateHeight = Graphics.getFontHeight(_stateFont);
        var valueHeight = Graphics.getFontHeight(_valueFont);
        var blockHeight = stateHeight + (valueLineCount * valueHeight) + (valueLineCount * LINE_SPACING);
        var top = (height - blockHeight) / 2;

        if (top < 0) {
            top = 0;
        }

        _stateY = top;
        _valueYs = [];

        var nextY = _stateY + stateHeight + LINE_SPACING;
        var index = 0;
        while (index < valueLineCount) {
            _valueYs.add(nextY);
            nextY += valueHeight + LINE_SPACING;
            index += 1;
        }

    }
}
