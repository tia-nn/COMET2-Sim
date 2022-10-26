package comet2;

class BoolTools {
    public static function toInt(a:Bool) {
        return a ? 1 : 0;
    }

    public static function toBool(a:Int) {
        return a != 0;
    }
}
