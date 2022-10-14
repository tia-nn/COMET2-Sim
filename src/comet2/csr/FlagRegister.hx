package comet2.csr;

import types.Word;

using comet2.BoolTools;

@:publicFields
class FlagRegister {
    var OF:Bool;
    var SF:Bool;
    var ZF:Bool;

    public function new(of:Bool = false, sf:Bool = false, zf:Bool = false) {
        OF = of;
        SF = sf;
        ZF = zf;
    }

    public function toWord():Word {
        return new Word(ZF.toInt() << 2 | SF.toInt() << 1 | OF.toInt());
    }

    public function frozen():FrozenFlagRegister {
        return {
            OF: OF,
            SF: SF,
            ZF: ZF
        };
    }
}

@:using(comet2.csr.FlagRegister.FrozenFlagRegisterTools)
typedef FrozenFlagRegister = {
    final OF:Bool;
    final SF:Bool;
    final ZF:Bool;
};

class FrozenFlagRegisterTools {
    public static function toWord(fr:FrozenFlagRegister):Word {
        return new Word(fr.ZF.toInt() << 2 | fr.SF.toInt() << 1 | fr.OF.toInt());
    }
}
