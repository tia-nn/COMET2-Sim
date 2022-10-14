package comet2;

import comet2.csr.FlagRegister;
import comet2.csr.IERegister;
import comet2.csr.IWRegister;
import comet2.csr.StatusRegister;
import extype.ReadOnlyArray;
import types.Word;

@:publicFields
class FrozenComet2Core {
    final GR:ReadOnlyArray<Word>;
    final SP:Word;
    final PR:Word;
    final FR:FrozenFlagRegister;

    final memory:ReadOnlyArray<Word>;

    final PTR:Word;

    final IE:FrozenIERegister;
    final IW:FrozenIWRegister;
    final CAUSE:Word;
    final STATUS:FrozenStatusRegister;
    final TVAL:Word;
    final TVEC:Word;
    final EPR:Word;
    final SCRATCH:Word;

    final isEnded:Bool;

    public function new(state:Comet2Core) {
        GR = state.GR;
        SP = state.SP;
        PR = state.PR;
        FR = state.FR.frozen();

        memory = state.memory;

        PTR = state.PTR;

        IE = state.IE.frozen();
        IW = state.IW.frozen();
        CAUSE = state.CAUSE;
        STATUS = state.STATUS.frozen();
        TVAL = state.TVAL;
        TVEC = state.TVEC;
        EPR = state.EPR;
        SCRATCH = state.SCRATCH;

        isEnded = state.isEnded;
    }
}
