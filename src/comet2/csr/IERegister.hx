package comet2.csr;

import types.Word;

using comet2.BoolTools;

@:publicFields
class IERegister {
    var external:Bool;
    var timer:Bool;
    var software:Bool;

    public function new(e:Bool = false, t:Bool = false, s:Bool = false) {
        external = e;
        timer = t;
        software = s;
    }

    public static function fromWord(n:Word):IERegister {
        return new IERegister((n & 0x0020) != 0, (n & 0x0008) != 0, (n & 0x0002) != 0);
    }

    public function toWord():Word {
        return new Word(external.toInt() << 5 | timer.toInt() << 3 | software.toInt() << 1);
    }

    public function frozen():FrozenIERegister {
        return {
            external: external,
            timer: timer,
            software: software,
        };
    }
}

@:using(comet2.csr.IERegister.FrozenIERegisterTools)
typedef FrozenIERegister = {
    final external:Bool;
    final timer:Bool;
    final software:Bool;
};

class FrozenIERegisterTools {
    public static function toWord(ie:FrozenIERegister):Word {
        return new Word(ie.external.toInt() << 5 | ie.timer.toInt() << 3 | ie.software.toInt() << 1);
    }
}
