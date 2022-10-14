package comet2;

import comet2.csr.FlagRegister;
import comet2.csr.IERegister;
import comet2.csr.IWRegister;
import comet2.csr.StatusRegister;
import extype.Exception;
import extype.Maybe;
import extype.Nullable;
import extype.ReadOnlyArray;
import extype.Result;
import types.Word;

using comet2.BoolTools;
using comet2.InstructionTools;
using comet2.IntTools;

@:allow(comet2.FrozenComet2Core)
class Comet2Core {
    var GR:Array<Word>;
    var SP:Word;
    var PR:Word;
    var FR:FlagRegister;

    var memory:Array<Word>;

    var PTR:Word;

    var IE:IERegister;
    var IW:IWRegister;
    var CAUSE:Word;
    var STATUS:StatusRegister;
    var TVAL:Word;
    var TVEC:Word;
    var EPR:Word;
    var SCRATCH:Word;

    var nextPR:Word;
    var inTrap:Bool;
    var isEnded:Bool;

    public function new(program:ReadOnlyArray<Word>, offset:Int = 0, entry:Int = 0) {
        GR = [for (i in 0...8) new Word(0)];
        SP = new Word(0xffff);
        PR = new Word(entry);
        FR = new FlagRegister();
        memory = [for (i in 0...65536) new Word(0)];

        PTR = new Word(0);

        IE = new IERegister();
        IW = new IWRegister();
        CAUSE = new Word(0);
        STATUS = new StatusRegister();
        TVAL = new Word(0);
        TVEC = new Word(0);
        EPR = new Word(0);
        SCRATCH = new Word(0);

        isEnded = false;
        inTrap = false;

        load(program, offset);
    }

    public function frozen():FrozenComet2Core {
        return new FrozenComet2Core(this);
    }

    function load(program:ReadOnlyArray<Word>, offset:Int = 0) {
        var to = offset;
        for (inst in program) {
            if (to >= memory.length) {
                throw new Exception("program too large.");
            }
            memory[to++] = inst;
        }
    }

    public function step() {
        final fetched = fetchAndDecode();
        switch (fetched) {
            case Success(inst):
                nextPR = PR + inst.getInstructionSize().toWord();
                excecution(inst);
            case Failure(word):
                if (inTrap)
                    throw new Exception("Invalid Instruction Exception during Trap Handling.");
                CAUSE = new Word(0x0001);
                TVAL = word;
                EPR = PR;
                STATUS.PIE = STATUS.IE;
                STATUS.IE = false;
                STATUS.PPL = STATUS.PL;
                STATUS.PL = false;
                nextPR = new Word(TVEC & 0xfffe); // TODO: Mode選択
                inTrap = true;
        }

        PR = nextPR;
    }

    function fetchAndDecode():Result<Instruction, Word> {
        final firstWord = memAccess(PR, Exec);
        final secondWord = memAccess(PR + new Word(1), Exec);
        return firstWord.toInstruction(secondWord);
    }

    function excecution(inst:Instruction) {
        trace(inst.toString());

        var result4FR:Maybe<Word> = None; // Some() なら FR.SR,FR.ZF セット

        switch (inst) {
            case R(i):
                final before = GR[i.r1];
                switch (i.mnemonic) {
                    case LD:
                        GR[i.r1] = GR[i.r2];
                        FR.OF = false;
                        result4FR = Some(GR[i.r1]);
                    case ADDA:
                        GR[i.r1] = GR[i.r1] + GR[i.r2];
                        FR.OF = if (GR[i.r2].toSigned() >= 0) {
                            FR.OF = GR[i.r1] < before;
                        } else {
                            FR.OF = GR[i.r1] > before;
                        }
                        result4FR = Some(GR[i.r1]);
                    case ADDL:
                        GR[i.r1] = GR[i.r1] + GR[i.r2];
                        FR.OF = GR[i.r1] < before;
                        result4FR = Some(GR[i.r1]);
                    case SUBA:
                        GR[i.r1] = GR[i.r1] + GR[i.r2];
                        FR.OF = if (GR[i.r2].toSigned() >= 0) {
                            FR.OF = GR[i.r1] > before;
                        } else {
                            FR.OF = GR[i.r1] < before;
                        }
                        result4FR = Some(GR[i.r1]);
                    case SUBL:
                        GR[i.r1] = GR[i.r1] - GR[i.r2];
                        FR.OF = GR[i.r1] > GR[i.r2];
                        result4FR = Some(GR[i.r1]);
                    case AND:
                        GR[i.r1] = GR[i.r1] & GR[i.r2];
                        FR.OF = false;
                        result4FR = Some(GR[i.r1]);
                    case OR:
                        GR[i.r1] = GR[i.r1] | GR[i.r2];
                        FR.OF = false;
                        result4FR = Some(GR[i.r1]);
                    case XOR:
                        GR[i.r1] = GR[i.r1] ^ GR[i.r2];
                        FR.OF = false;
                        result4FR = Some(GR[i.r1]);
                    case CPA:
                        FR.OF = false;
                        final r1 = GR[i.r1].toSigned();
                        final r2 = GR[i.r2].toSigned();
                        result4FR = if (r1 > r2) {
                            Some(new Word(0x0001)); // SF = 0; ZF = 0;
                        } else if (r1 == r2) {
                            Some(new Word(0x0000)); // SF = 0; ZF = 1;
                        } else /* r1 < r2 */ {
                            Some(new Word(0x8000)); // SF = 1; ZF = 0;
                        }
                    case CPL:
                        FR.OF = false;
                        result4FR = if (GR[i.r1] > GR[i.r2]) {
                            Some(new Word(0x0001)); // SF = 0; ZF = 0;
                        } else if (GR[i.r1] == GR[i.r2]) {
                            Some(new Word(0x0000)); // SF = 0; ZF = 1;
                        } else /* GR[i.r1] < GR[i.r2] */ {
                            Some(new Word(0x8000)); // SF = 1; ZF = 0;
                        }
                }
            case I(i):
                final before = GR[i.r];
                final eAddr = calcAddr(i.addr, i.x);
                switch (i.mnemonic) {
                    case LD:
                        GR[i.r] = memAccess(eAddr);
                        FR.OF = false;
                        result4FR = Some(GR[i.r]);
                    case ST:
                        memAccess(eAddr, Write(GR[i.r]));
                    case LAD:
                        GR[i.r] = eAddr;
                    case ADDA:
                        final memVal = memAccess(eAddr);
                        GR[i.r] = GR[i.r] + memVal;
                        FR.OF = if (memVal.toSigned() >= 0) {
                            FR.OF = GR[i.r] < before;
                        } else {
                            FR.OF = GR[i.r] > before;
                        }
                        result4FR = Some(GR[i.r]);
                    case ADDL:
                        GR[i.r] = GR[i.r] + memAccess(eAddr);
                        FR.OF = GR[i.r] < before;
                        result4FR = Some(GR[i.r]);
                    case SUBA:
                        final memVal = memAccess(eAddr);
                        GR[i.r] = GR[i.r] - memVal;
                        FR.OF = if (memVal.toSigned() >= 0) {
                            FR.OF = GR[i.r] > before;
                        } else {
                            FR.OF = GR[i.r] < before;
                        }
                        result4FR = Some(GR[i.r]);
                    case SUBL:
                        GR[i.r] = GR[i.r] - memAccess(eAddr);
                        FR.OF = GR[i.r] > before;
                        result4FR = Some(GR[i.r]);
                    case AND:
                        GR[i.r] = GR[i.r] & memAccess(eAddr);
                        FR.OF = false;
                        result4FR = Some(GR[i.r]);
                    case OR:
                        GR[i.r] = GR[i.r] | memAccess(eAddr);
                        FR.OF = false;
                        result4FR = Some(GR[i.r]);
                    case XOR:
                        GR[i.r] = GR[i.r] ^ memAccess(eAddr);
                        FR.OF = false;
                        result4FR = Some(GR[i.r]);
                    case CPA:
                        FR.OF = false;
                        final r = GR[i.r].toSigned();
                        final adr = eAddr.toSigned();
                        result4FR = if (r > adr) {
                            Some(new Word(0x0001)); // SF = 0; ZF = 0;
                        } else if (r == adr) {
                            Some(new Word(0x0000)); // SF = 0; ZF = 1;
                        } else /* r < adr */ {
                            Some(new Word(0x8000)); // SF = 1; ZF = 0;
                        }
                    case CPL:
                        FR.OF = false;
                        result4FR = if (GR[i.r] > eAddr) {
                            Some(new Word(0x0001)); // SF = 0; ZF = 0;
                        } else if (GR[i.r] == eAddr) {
                            Some(new Word(0x0000)); // SF = 0; ZF = 1;
                        } else /* GR[i.r] < eAddr */ {
                            Some(new Word(0x8000)); // SF = 1; ZF = 0;
                        }
                    case SLA:
                        if (eAddr.toUnsigned() > 15) {
                            FR.OF = false;
                            GR[i.r] = GR[i.r] & 0x8000.toWord();
                        } else if (eAddr == 0) {
                        } else {
                            FR.OF = GR[i.r].toBitArray()[eAddr].toBool();
                            GR[i.r] = GR[i.r].sla(eAddr);
                        }
                        result4FR = Some(GR[i.r]);
                    case SRA:
                        if (eAddr.toUnsigned() > 15) {
                            FR.OF = (GR[i.r] & 0x8000).toBool();
                            GR[i.r] = GR[i.r] >> eAddr;
                        } else if (eAddr == 0) {
                        } else {
                            FR.OF = GR[i.r].toBitArray()[16 - eAddr].toBool();
                            GR[i.r] = GR[i.r] >> eAddr;
                        }
                        result4FR = Some(GR[i.r]);
                    case SLL:
                        if (eAddr.toUnsigned() > 16) {
                            FR.OF = false;
                            GR[i.r] = GR[i.r] << eAddr;
                        } else if (eAddr == 0) {
                        } else {
                            FR.OF = GR[i.r].toBitArray()[eAddr - 1].toBool();
                            GR[i.r] = GR[i.r] << eAddr;
                        }
                        result4FR = Some(GR[i.r]);
                    case SRL:
                        if (eAddr.toUnsigned() > 16) {
                            FR.OF = false;
                            GR[i.r] = GR[i.r] >>> eAddr;
                        } else if (eAddr == 0) {
                        } else {
                            FR.OF = GR[i.r].toBitArray()[16 - eAddr - 1].toBool();
                            GR[i.r] = GR[i.r] >>> eAddr;
                        }
                        result4FR = Some(GR[i.r]);
                }
            default:
                trace('Not Implemented. (${inst.toString()})');
        }

        switch (result4FR) {
            case Some(result):
                FR.SF = result & 0x8000 != 0;
                FR.ZF = result == 0;
            case None:
        }
    }

    function memAccess(addr:Word, mode:MemoryAccessMode = Read):Word {
        // TODO: 仮想メモリアドレス解決
        // TODO: 権限チェック
        return switch (mode) {
            case Read:
                memory[addr];
            case Write(w):
                memory[addr] = w;
            case Exec:
                memory[addr];
        }
    }

    function calcAddr(addr:Word, x:Nullable<I1to7>):Word {
        return addr + x.fold(() -> new Word(0), r -> GR[r]);
    }
}

enum MemoryAccessMode {
    Read;
    Write(w:Word);
    Exec;
}
