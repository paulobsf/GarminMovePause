import Toybox.Application.Properties;
import Toybox.Lang;

module MovePauseSettings {
    const BACKGROUND_STYLE_BLACK = 0;
    const BACKGROUND_STYLE_WHITE = 1;
    const DEFAULT_BUZZ_ON_TARGET = true;
    const DEFAULT_FIELD_BACKGROUND_STYLE = BACKGROUND_STYLE_BLACK;
    const DEFAULT_RECOVERY_TARGET_SECONDS = 90;

    const KEY_FIELD_BACKGROUND_STYLE = "field_background_style";
    const KEY_BUZZ_ON_TARGET = "buzz_on_target";
    const KEY_RECOVERY_TARGET_SECONDS = "recovery_target_seconds";

    function useLightBackground() as Boolean {
        return readNumber(KEY_FIELD_BACKGROUND_STYLE, DEFAULT_FIELD_BACKGROUND_STYLE) == BACKGROUND_STYLE_WHITE;
    }

    function getRecoveryTargetMs() as Number {
        return sanitizeTargetSeconds(readNumber(KEY_RECOVERY_TARGET_SECONDS, DEFAULT_RECOVERY_TARGET_SECONDS)) * 1000;
    }

    function shouldBuzzOnTarget() as Boolean {
        return readBoolean(KEY_BUZZ_ON_TARGET, DEFAULT_BUZZ_ON_TARGET);
    }

    function readBoolean(key as String, defaultValue as Boolean) as Boolean {
        var value = Properties.getValue(key);

        if (value instanceof Boolean) {
            return value;
        }

        return defaultValue;
    }

    function readNumber(key as String, defaultValue as Number) as Number {
        var value = Properties.getValue(key);

        if (value instanceof Number) {
            return value;
        }

        return defaultValue;
    }

    function sanitizeTargetSeconds(value as Number) as Number {
        if (value <= 0) {
            return 0;
        }

        if ((value == 60) || (value == 90) || (value == 120)) {
            return value;
        }

        return DEFAULT_RECOVERY_TARGET_SECONDS;
    }
}
