package machine;

import extype.ReadOnlyArray;
import types.Word;

typedef Comet2State = {
    var gr:Array<Word>;
    var sp:Word;
    var pr:Word;
    var fr:Comet2FR;
    var memory:Array<Word>;
    var intQueue:Array<Int>;
    var intVecMask:Word;
    var isExited:Bool;
}

@:using(machine.Comet2State.Comet2FRTools)
typedef Comet2FR = {
    /** overflow **/
    var of:Bool;

    /** sign **/
    var sf:Bool;

    /** zero **/
    var zf:Bool;

    /** interrupt enabled **/
    var ie:Bool;
}

class Comet2FRTools {
    public static function toWord(fr:Comet2FR) {
        return new Word(boolToInt(fr.of) << 15 | boolToInt(fr.sf) << 14 | boolToInt(fr.zf) << 13 | boolToInt(fr.ie) << 12);
    }

    static function boolToInt(a:Bool) {
        return a ? 1 : 0;
    }
}

typedef FrozenComet2State = {
    final gr:ReadOnlyArray<Word>;
    final sp:Word;
    final pr:Word;
    final fr:FrozenComet2FR;
    final memory:ReadOnlyArray<Word>;
    final intQueue:Array<Int>;
    final intVecMask:Word;
    final isExited:Bool;
}

typedef FrozenComet2FR = {
    final of:Bool;
    final sf:Bool;
    final zf:Bool;
    final ie:Bool;
}
