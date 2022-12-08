package client.external;

import types.Word;

using comet2.IntTools;

class RTC {
    public static function getSeconds():Word {
        return Date.now().getSeconds().toWord();
    }

    public static function getMinutes():Word {
        return Date.now().getMinutes().toWord();
    }

    public static function getHours():Word {
        return Date.now().getHours().toWord();
    }

    public static function getDay():Word {
        return Date.now().getDay().toWord();
    }

    public static function getMonth():Word {
        return Date.now().getMonth().toWord();
    }

    public static function getYear():Word {
        return Date.now().getFullYear().toWord();
    }
}
