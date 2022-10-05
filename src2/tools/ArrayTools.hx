package tools;

import extype.Maybe;

class ArrayTools {
    public static function getAsMaybe<T>(array:Array<T>, index:Int):Maybe<T> {
        return if (array[index] != null) {
            Some(array[index]);
        } else {
            None;
        }
    }
}
