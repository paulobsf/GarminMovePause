import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class MovePauseField extends WatchUi.DataField {
    private const LINE_SPACING = 4;

    private var _compact as Boolean = false;
    private var _engine as MovePauseTimingEngine;
    private var _moveY as Number = 0;
    private var _pauseY as Number = 0;
    private var _stateFont as Graphics.FontType = Graphics.FONT_TINY;
    private var _stateY as Number = 0;
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

        if (height < 72) {
            _stateFont = Graphics.FONT_XTINY;
            _valueFont = Graphics.FONT_TINY;
        } else if (_compact) {
            _stateFont = Graphics.FONT_TINY;
            _valueFont = Graphics.FONT_SMALL;
        } else {
            _stateFont = Graphics.FONT_SMALL;
            _valueFont = Graphics.FONT_MEDIUM;
        }

        var stateHeight = Graphics.getFontHeight(_stateFont);
        var valueHeight = Graphics.getFontHeight(_valueFont);
        var blockHeight = stateHeight + (2 * valueHeight) + (2 * LINE_SPACING);
        var top = (height - blockHeight) / 2;

        if (top < 0) {
            top = 0;
        }

        _stateY = top;
        _moveY = _stateY + stateHeight + LINE_SPACING;
        _pauseY = _moveY + valueHeight + LINE_SPACING;
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
        var movingText = (_compact ? "M " : "Move ") + MovePauseFormatter.formatDuration(_engine.getTotalMovingMs());
        var pausedText = (_compact ? "P " : "Pause ") + MovePauseFormatter.formatDuration(_engine.getTotalPausedMs());

        dc.drawText(centerX, _stateY, _stateFont, stateText, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, _moveY, _valueFont, movingText, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, _pauseY, _valueFont, pausedText, Graphics.TEXT_JUSTIFY_CENTER);
    }
}
