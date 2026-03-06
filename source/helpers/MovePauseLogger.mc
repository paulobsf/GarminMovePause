import Toybox.Lang;
import Toybox.System;

module MovePauseLogger {
    const DEBUG_ENABLED = false;

    function debug(message as String) as Void {
        if (DEBUG_ENABLED) {
            System.println("[MovePause] " + message);
        }
    }
}
