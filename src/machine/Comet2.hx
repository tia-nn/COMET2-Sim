package machine;

import Word.I1to7;
import assembler.Instruction.PAddr;
import assembler.Instruction.PInstOrData;
import assembler.Instruction.PInstruction;
import extype.Exception;
import extype.Map;
import extype.Nullable;

@:allow(Main)
class Comet2 {
    var state:Comet2State;

    public function new(insts:Array<PInstOrData>, addr:Int = 0) {
        state = {
            gr: [
                new Word(0),
                new Word(0),
                new Word(0),
                new Word(0),
                new Word(0),
                new Word(0),
                new Word(0),
                new Word(0)
            ],
            sp: new Word(0xffff),
            pr: new Word(0),
            fr: {
                of: false,
                sf: false,
                zf: false,
            },
            memory: [for (i in 0...65536) Data(new Word(0))],
            labelTable: new Map(),
        };

        state.memory[0xffff] = ExitAddr;

        load(insts, addr);
    }

    function load(insts:Array<PInstOrData>, addr:Int = 0) {
        var to = addr;
        for (inst in insts) {
            if (to >= state.memory.length) {
                throw new Exception("too large.");
            }

            inst.getLabel().map(label -> {
                if (state.labelTable.exists(label)) {
                    throw new Exception("duplicate label definition.");
                }
                state.labelTable.set(label, to);
                true;
            });

            switch (inst) {
                case Inst(inst):
                    state.memory[to] = Inst(inst);
                case Data(data):
                    state.memory[to] = Data(data.value);
            }

            to++;
        }
    }

    public function step():Bool {
        trace(state.pr);

        final inst = switch (state.memory[state.pr]) {
            case Data(_), ExitAddr:
                throw new Exception('executing data at pr=#${state.pr.toString("")}');
            case Inst(inst):
                inst;
        }

        // TODO: FR 変更
        switch (inst.mnemonic) {
            case LDr(o):
                state.gr[o.r1] = state.memory[state.gr[o.r2]].toWord();
            case LDi(o):
                state.gr[o.r] = state.memory[calcAddr(o.addr, o.x)].toWord();
            case STi(o):
                state.memory[calcAddr(o.addr, o.x)] = Data(state.gr[o.r]);
            case LADi(o):
                state.gr[o.r] = new Word(calcAddr(o.addr, o.x));
            case ADDAr(o), ADDLr(o):
                state.gr[o.r1] = new Word((state.gr[o.r1] : Int) + state.gr[o.r2]);
            case ADDAi(o), ADDLi(o):
                state.gr[o.r] = new Word((state.gr[o.r] : Int) + state.memory[calcAddr(o.addr, o.x)].toWord());
            case SUBAr(o), SUBLr(o):
                state.gr[o.r1] = new Word((state.gr[o.r1] : Int) - state.gr[o.r2]);
            case SUBAi(o), SUBLi(o):
                state.gr[o.r] = new Word((state.gr[o.r] : Int) - state.memory[calcAddr(o.addr, o.x)].toWord());
            case ANDr(o):
                state.gr[o.r1] = new Word((state.gr[o.r1] : Int) & state.gr[o.r2]);
            case ANDi(o):
                state.gr[o.r] = new Word((state.gr[o.r] : Int) & state.memory[calcAddr(o.addr, o.x)].toWord());
            case ORr(o):
                state.gr[o.r1] = new Word((state.gr[o.r1] : Int) | state.gr[o.r2]);
            case ORi(o):
                state.gr[o.r] = new Word((state.gr[o.r] : Int) | state.memory[calcAddr(o.addr, o.x)].toWord());
            case XORr(o):
                state.gr[o.r1] = new Word((state.gr[o.r1] : Int) ^ state.gr[o.r2]);
            case XORi(o):
                state.gr[o.r] = new Word((state.gr[o.r] : Int) ^ state.memory[calcAddr(o.addr, o.x)].toWord());

            case CPAr(o):
                state.fr.zf = state.gr[o.r1].toSigned() == state.gr[o.r2].toSigned();
                state.fr.sf = state.gr[o.r1].toSigned() < state.gr[o.r2].toSigned();
            case CPAi(o):
                state.fr.zf = state.gr[o.r].toSigned() == new Word(calcAddr(o.addr, o.x)).toSigned();
                state.fr.sf = state.gr[o.r].toSigned() < new Word(calcAddr(o.addr, o.x)).toSigned();
            case CPLr(o):
                state.fr.zf = state.gr[o.r1].toUnsigned() == state.gr[o.r2].toUnsigned();
                state.fr.sf = state.gr[o.r1].toUnsigned() < state.gr[o.r2].toUnsigned();
            case CPLi(o):
                state.fr.zf = state.gr[o.r].toUnsigned() == calcAddr(o.addr, o.x).toUnsigned();
                state.fr.sf = state.gr[o.r].toUnsigned() < calcAddr(o.addr, o.x).toUnsigned();

            case SLAi(o):
                state.gr[o.r] = state.gr[o.r].sla(calcAddr(o.addr, o.x));
            case SRAi(o):
                state.gr[o.r] = state.gr[o.r] >> calcAddr(o.addr, o.x);
            case SLLi(o):
                state.gr[o.r] = state.gr[o.r] << calcAddr(o.addr, o.x);
            case SRLi(o):
                state.gr[o.r] = state.gr[o.r] >>> calcAddr(o.addr, o.x);

            case JPLj(o):
                if (!state.fr.sf && !state.fr.zf) {
                    state.pr = calcAddr(o.addr, o.x);
                    return false;
                }
            case JMIj(o):
                if (state.fr.sf) {
                    state.pr = calcAddr(o.addr, o.x);
                    return false;
                }
            case JNZj(o):
                if (!state.fr.zf) {
                    state.pr = calcAddr(o.addr, o.x);
                    return false;
                }
            case JZEj(o):
                if (state.fr.zf) {
                    state.pr = calcAddr(o.addr, o.x);
                    return false;
                }
            case JOVj(o):
                if (state.fr.of) {
                    state.pr = calcAddr(o.addr, o.x);
                    return false;
                }
            case JUMPj(o):
                state.pr = calcAddr(o.addr, o.x);
                return false;

            case PUSHj(o):
                push(calcAddr(o.addr, o.x));
            case POPp(o):
                state.gr[o.r] = pop().toWord();

            case CALLj(o):
                push(state.pr + new Word(1));
                state.pr = calcAddr(o.addr, o.x);
                return false;
            case RETn:
                final addr = pop();
                switch (addr) {
                    case ExitAddr:
                        return true;
                    case Data(_), Inst(_):
                        state.pr = addr.toWord();
                        return false;
                }
            case NOPn:
            case _:
                throw new Exception("not implemeted mnemonic.");
        }

        state.pr++;
        return false;
    }

    function pop() {
        return state.memory[state.sp++];
    }

    function push(v:Word) {
        state.memory[--state.sp] = Data(v);
    }

    function calcAddr(addr:PAddr, x:Nullable<I1to7>) {
        return switch (addr) {
            case Label(label):
                final value = Nullable.of(state.labelTable.get(label)).getOrThrow(() -> new Exception("label not found."));
                return new Word(value + state.gr[(x : Nullable<Int>).getOrElse(0)]);
            case Constant(value):
                return new Word((value : Int) + state.gr[(x : Nullable<Int>).getOrElse(0)]);
        }
    }
}

typedef Comet2State = {
    var gr:Array<Word>;
    var sp:Word;
    var pr:Word;
    var fr:Comet2FR;
    var memory:Array<Comet2MemoryType>;
    var labelTable:Map<String, Int>;
}

typedef Comet2FR = {
    var of:Bool;
    var sf:Bool;
    var zf:Bool;
}

@:using(machine.Comet2.Comet2MemoryTypeTools)
enum Comet2MemoryType {
    Data(d:Word);
    Inst(inst:PInstruction);
    ExitAddr;
}

class Comet2MemoryTypeTools {
    public static function toWord(m:Comet2MemoryType) {
        return switch (m) {
            case Data(d):
                d;
            case Inst(inst):
                new Word(0x0000);
            case ExitAddr:
                new Word(0xffff);
        }
    }
}
