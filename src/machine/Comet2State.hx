package machine;

import extype.ReadOnlyArray;
import types.Word;

typedef Comet2State = {
    var gr:Array<Word>;
    var sp:Word;
    var pr:Word;
    var fr:Comet2FR;
    var memory:Array<Word>;
}

typedef Comet2FR = {
    var of:Bool;
    var sf:Bool;
    var zf:Bool;
}

typedef FrozenComet2State = {
    final gr:ReadOnlyArray<Word>;
    final sp:Word;
    final pr:Word;
    final fr:FrozenComet2FR;
    final memory:ReadOnlyArray<Word>;
}

typedef FrozenComet2FR = {
    final of:Bool;
    final sf:Bool;
    final zf:Bool;
}
