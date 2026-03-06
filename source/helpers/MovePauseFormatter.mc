import Toybox.Lang;

module MovePauseFormatter {
    function formatDuration(milliseconds as Number) as String {
        var safeMilliseconds = milliseconds;

        if (safeMilliseconds < 0) {
            safeMilliseconds = 0;
        }

        var totalSeconds = safeMilliseconds / 1000;
        var hours = totalSeconds / 3600;
        var minutes = (totalSeconds % 3600) / 60;
        var seconds = totalSeconds % 60;

        if (hours > 0) {
            return hours.format("%d") + ":" + twoDigits(minutes) + ":" + twoDigits(seconds);
        }

        return minutes.format("%d") + ":" + twoDigits(seconds);
    }

    function formatStateLabel(hasStarted as Boolean, isMoving as Boolean, isPaused as Boolean) as String {
        if (!hasStarted) {
            return "READY";
        }

        if (isMoving) {
            return "MOVING";
        }

        if (isPaused) {
            return "PAUSED";
        }

        return "READY";
    }

    function twoDigits(value as Number) as String {
        return value.format("%02d");
    }
}
