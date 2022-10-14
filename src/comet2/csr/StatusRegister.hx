package comet2.csr;

import comet2.csr.IWRegister.FrozenIWRegister;
import types.Word;

using comet2.BoolTools;

@:publicFields
class StatusRegister {
    var PPL:Bool;
    var PL:Bool;
    var PIE:Bool;
    var IE:Bool;

    public function new(ppl:Bool = false, pl:Bool = false, pie:Bool = false, ie:Bool = false) {
        PPL = ppl;
        PL = pl;
        PIE = pie;
        IE = ie;
    }

    public function toWord() {
        return new Word(PPL.toInt() << 6 | PL.toInt() << 5 | PIE.toInt() << 3 | IE.toInt() << 1);
    }

    public static function fromWord(n:Word):StatusRegister {
        return new StatusRegister((n & 0x0040) != 0, (n & 0x0020) != 0, (n & 0x0008) != 0, (n & 0x0002) != 0);
    }

    public function frozen():FrozenStatusRegister {
        return {
            PPL: PPL,
            PL: PL,
            PIE: PIE,
            IE: IE
        };
    }
}

@:using(comet2.csr.StatusRegister.FrozenStatusRegisterTools)
typedef FrozenStatusRegister = {
    var PPL:Bool;
    var PL:Bool;
    var PIE:Bool;
    var IE:Bool;
};

class FrozenStatusRegisterTools {
    public static function toWord(s:FrozenStatusRegister) {
        return new Word(s.PPL.toInt() << 6 | s.PL.toInt() << 5 | s.PIE.toInt() << 3 | s.IE.toInt() << 1);
    }
}
