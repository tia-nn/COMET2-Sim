package machine;

import Word.I0to7;
import Word.I1to7;
import assembler.Instruction.PAddr;
import assembler.Instruction.PMnemonic;
import extype.Exception;
import extype.Map;
import extype.Nullable;

@:allow(Main)
class Comet2 {
    var state:Comet2State;

    public function new(insts:Array<Word>, addr:Int = 0) {
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
            memory: [for (i in 0...65536) new Word(0)],
        };

        state.memory[0xffff] = new Word(0xffff);

        load(insts, addr);
    }

    function load(insts:Array<Word>, addr:Int = 0) {
        var to = addr;
        for (inst in insts) {
            if (to >= state.memory.length) {
                throw new Exception("too large.");
            }

            state.memory[to] = inst;

            to++;
        }
    }

    function fetch():PMnemonic {
        final firstWord = state.memory[state.pr++];
        final r_r1 = new I0to7((firstWord & 0x0070) >> 4);
        trace(firstWord & 0x0007);
        final r2 = new I0to7(firstWord & 0x0007);
        final x = r2.toNullI1to7();
        final addr = () -> Constant(state.memory[state.pr++]);
        return switch (firstWord >> 8) {
            case 0x00:
                NOPn;
            case 0x10:
                LDi({r: new I0to7(r_r1), addr: addr(), x: x});
            case 0x11:
                STi({r: new I0to7(r_r1), addr: addr(), x: x});
            case 0x12:
                LADi({r: new I0to7(r_r1), addr: addr(), x: x});
            case 0x14:
                LDr({r1: r_r1, r2: r2});
            case 0x20:
                ADDAi({r: new I0to7(r_r1), addr: addr(), x: x});
            case 0x21:
                SUBAi({r: new I0to7(r_r1), addr: addr(), x: x});
            case 0x22:
                ADDLi({r: new I0to7(r_r1), addr: addr(), x: x});
            case 0x23:
                SUBLi({r: new I0to7(r_r1), addr: addr(), x: x});
            case 0x24:
                ADDAr({r1: r_r1, r2: r2});
            case 0x25:
                SUBAr({r1: r_r1, r2: r2});
            case 0x26:
                ADDLr({r1: r_r1, r2: r2});
            case 0x27:
                SUBLr({r1: r_r1, r2: r2});
            case 0x30:
                ANDi({r: new I0to7(r_r1), addr: addr(), x: x});
            case 0x31:
                ORi({r: new I0to7(r_r1), addr: addr(), x: x});
            case 0x32:
                XORi({r: new I0to7(r_r1), addr: addr(), x: x});
            case 0x34:
                ANDr({r1: r_r1, r2: r2});
            case 0x35:
                ORr({r1: r_r1, r2: r2});
            case 0x36:
                XORr({r1: r_r1, r2: r2});
            case 0x40:
                CPAi({r: new I0to7(r_r1), addr: addr(), x: x});
            case 0x41:
                CPLi({r: new I0to7(r_r1), addr: addr(), x: x});
            case 0x44:
                CPAr({r1: r_r1, r2: r2});
            case 0x45:
                CPLr({r1: r_r1, r2: r2});
            case 0x50:
                SLAi({r: new I0to7(r_r1), addr: addr(), x: x});
            case 0x51:
                SRAi({r: new I0to7(r_r1), addr: addr(), x: x});
            case 0x52:
                SLAi({r: new I0to7(r_r1), addr: addr(), x: x});
            case 0x53:
                SLLi({r: new I0to7(r_r1), addr: addr(), x: x});
            case 0x61:
                JMIj({addr: addr(), x: x});
            case 0x62:
                JNZj({addr: addr(), x: x});
            case 0x63:
                JZEj({addr: addr(), x: x});
            case 0x64:
                JUMPj({addr: addr(), x: x});
            case 0x65:
                JPLj({addr: addr(), x: x});
            case 0x66:
                JOVj({addr: addr(), x: x});
            case 0x70:
                PUSHj({addr: addr(), x: x});
            case 0x71:
                POPp({r: r_r1});
            case 0x80:
                CALLj({addr: addr(), x: x});
            case 0x81:
                RETn;
            case 0xf0:
                SVCj({addr: addr(), x: x});

            case _:
                throw new Exception("invalid instruction.");
        }
    }

    public function step():Bool {
        final mnemonic = fetch();

        trace(mnemonic);
        // TODO: FR 変更
        switch (mnemonic) {
            case LDr(o):
                state.gr[o.r1] = state.memory[state.gr[o.r2]];
            case LDi(o):
                state.gr[o.r] = state.memory[calcAddr(o.addr, o.x)];
            case STi(o):
                state.memory[calcAddr(o.addr, o.x)] = state.gr[o.r];
            case LADi(o):
                state.gr[o.r] = new Word(calcAddr(o.addr, o.x));
            case ADDAr(o), ADDLr(o):
                state.gr[o.r1] = new Word((state.gr[o.r1] : Int) + state.gr[o.r2]);
            case ADDAi(o), ADDLi(o):
                state.gr[o.r] = new Word((state.gr[o.r] : Int) + state.memory[calcAddr(o.addr, o.x)]);
            case SUBAr(o), SUBLr(o):
                state.gr[o.r1] = new Word((state.gr[o.r1] : Int) - state.gr[o.r2]);
            case SUBAi(o), SUBLi(o):
                state.gr[o.r] = new Word((state.gr[o.r] : Int) - state.memory[calcAddr(o.addr, o.x)]);
            case ANDr(o):
                state.gr[o.r1] = new Word((state.gr[o.r1] : Int) & state.gr[o.r2]);
            case ANDi(o):
                state.gr[o.r] = new Word((state.gr[o.r] : Int) & state.memory[calcAddr(o.addr, o.x)]);
            case ORr(o):
                state.gr[o.r1] = new Word((state.gr[o.r1] : Int) | state.gr[o.r2]);
            case ORi(o):
                state.gr[o.r] = new Word((state.gr[o.r] : Int) | state.memory[calcAddr(o.addr, o.x)]);
            case XORr(o):
                state.gr[o.r1] = new Word((state.gr[o.r1] : Int) ^ state.gr[o.r2]);
            case XORi(o):
                state.gr[o.r] = new Word((state.gr[o.r] : Int) ^ state.memory[calcAddr(o.addr, o.x)]);

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
                state.gr[o.r] = pop();

            case CALLj(o):
                push(state.pr);
                state.pr = calcAddr(o.addr, o.x);
                return false;
            case RETn:
                final addr = pop();
                if (addr == 0xffff) {
                    return true;
                } else {
                    state.pr = addr;
                    return false;
                }
            case NOPn:
            case _:
                throw new Exception("not implemeted mnemonic.");
        }
        return false;
    }

    function pop() {
        return state.memory[state.sp++];
    }

    function push(v:Word) {
        state.memory[--state.sp] = v;
    }

    function calcAddr(addr:PAddr, x:Nullable<I1to7>) {
        return switch (addr) {
            case Label(label):
                throw new Exception("unreachable.");
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
    var memory:Array<Word>;
}

typedef Comet2FR = {
    var of:Bool;
    var sf:Bool;
    var zf:Bool;
}
