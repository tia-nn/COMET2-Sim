package comet2.csr;

import types.Word;

using comet2.BoolTools;

@:publicFields
class IWRegister {
    var external:Bool;
    var timer:Bool;
    var software:Bool;

    public function new(e:Bool = false, t:Bool = false, s:Bool = false) {
        external = e;
        timer = t;
        software = s;
    }

    public function toWord():Word {
        return new Word(external.toInt() << 5 | timer.toInt() << 3 | software.toInt() << 1);
    }

    public static function fromWord(n:Word):IWRegister {
        return new IWRegister((n & 0x0020) != 0, (n & 0x0008) != 0, (n & 0x0002) != 0);
    }

    public function frozen():FrozenIWRegister {
        return {
            external: external,
            timer: timer,
            software: software,
        };
    }
}

@:using(comet2.csr.IWRegister.FrozenIWRegisterTools)
typedef FrozenIWRegister = {
    final external:Bool;
    final timer:Bool;
    final software:Bool;
};

class FrozenIWRegisterTools {
    public static function toWord(iw:FrozenIWRegister):Word {
        return new Word(iw.external.toInt() << 5 | iw.timer.toInt() << 3 | iw.software.toInt() << 1);
    }
}
