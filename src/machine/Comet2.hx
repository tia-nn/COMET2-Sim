package machine;

import Word.I0to7;
import Word.I1to7;
import extype.Exception;
import extype.Nullable;
import extype.ReadOnlyArray;
import parser.InstructionDefinition.LinkedInstruction;

@:allow(Main)
class Comet2 {
    var state:Comet2State;

    public function new(insts:ReadOnlyArray<Word>, entry:Int = 0, offest:Int = 0) {
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

        state.pr = new Word(entry);

        load(insts, offest);
    }

    function load(insts:ReadOnlyArray<Word>, addr:Int = 0) {
        var to = addr;
        for (inst in insts) {
            if (to >= state.memory.length) {
                throw new Exception("too large.");
            }

            state.memory[to] = inst;

            to++;
        }
    }

    function fetch():LinkedInstruction {
        final firstWord = state.memory[state.pr++];
        final r_r1 = new I0to7((firstWord & 0x0070) >> 4);
        final r2 = new I0to7(firstWord & 0x0007);
        final x = r2.toNullI1to7();
        final addr = () -> state.memory[state.pr++];
        return switch (firstWord >> 8) {
            case 0x00: N({mnemonic: NOP});
            case 0x10: I({
                    mnemonic: LD,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x11: I({
                    mnemonic: ST,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x12: I({
                    mnemonic: LAD,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x14: R({mnemonic: LD, r1: r_r1, r2: r2});
            case 0x20: I({
                    mnemonic: ADDA,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x21: I({
                    mnemonic: SUBA,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x22: I({
                    mnemonic: ADDL,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x23: I({
                    mnemonic: SUBL,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x24: R({mnemonic: ADDA, r1: r_r1, r2: r2});
            case 0x25: R({mnemonic: SUBA, r1: r_r1, r2: r2});
            case 0x26: R({mnemonic: ADDL, r1: r_r1, r2: r2});
            case 0x27: R({mnemonic: SUBL, r1: r_r1, r2: r2});
            case 0x30: I({
                    mnemonic: AND,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x31: I({
                    mnemonic: OR,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x32: I({
                    mnemonic: XOR,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x34: R({mnemonic: AND, r1: r_r1, r2: r2});
            case 0x35: R({mnemonic: OR, r1: r_r1, r2: r2});
            case 0x36: R({mnemonic: XOR, r1: r_r1, r2: r2});
            case 0x40: I({
                    mnemonic: CPA,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x41: I({
                    mnemonic: CPL,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x44: R({mnemonic: CPA, r1: r_r1, r2: r2});
            case 0x45: R({mnemonic: CPL, r1: r_r1, r2: r2});
            case 0x50: I({
                    mnemonic: SLA,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x51: I({
                    mnemonic: SRA,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x52: I({
                    mnemonic: SLA,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x53: I({
                    mnemonic: SLL,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x61: J({mnemonic: JMI, addr: addr(), x: x,});
            case 0x62: J({mnemonic: JNZ, addr: addr(), x: x,});
            case 0x63: J({mnemonic: JZE, addr: addr(), x: x,});
            case 0x64: J({mnemonic: JUMP, addr: addr(), x: x,});
            case 0x65: J({mnemonic: JPL, addr: addr(), x: x,});
            case 0x66: J({mnemonic: JOV, addr: addr(), x: x,});
            case 0x70: J({mnemonic: PUSH, addr: addr(), x: x,});
            case 0x71: P({mnemonic: POP, r: r_r1});
            case 0x80: J({mnemonic: CALL, addr: addr(), x: x,});
            case 0x81: N({mnemonic: RET});
            case 0xf0: J({mnemonic: SVC, addr: addr(), x: x,});

            case _:
                throw new Exception("invalid instruction.");
        }
    }

    public function step():Bool {
        final mnemonic = fetch();

        // TODO: FR 変更
        switch (mnemonic) {
            case R(i):
                switch (i.mnemonic) {
                    case LD:
                        state.gr[i.r1] = state.memory[state.gr[i.r2]];
                    case ADDA, ADDL:
                        state.gr[i.r1] = new Word((state.gr[i.r1] : Int) + state.gr[i.r2]);
                    case SUBA, SUBL:
                        state.gr[i.r1] = new Word((state.gr[i.r1] : Int) - state.gr[i.r2]);
                    case AND:
                        state.gr[i.r1] = new Word((state.gr[i.r1] : Int) & state.gr[i.r2]);
                    case OR:
                        state.gr[i.r1] = new Word((state.gr[i.r1] : Int) | state.gr[i.r2]);
                    case XOR:
                        state.gr[i.r1] = new Word((state.gr[i.r1] : Int) ^ state.gr[i.r2]);
                    case CPA:
                        state.fr.zf = state.gr[i.r1].toSigned() == state.gr[i.r2].toSigned();
                        state.fr.sf = state.gr[i.r1].toSigned() < state.gr[i.r2].toSigned();
                    case CPL:
                        state.fr.zf = state.gr[i.r1].toUnsigned() == state.gr[i.r2].toUnsigned();
                        state.fr.sf = state.gr[i.r1].toUnsigned() < state.gr[i.r2].toUnsigned();
                }
            case I(i):
                switch (i.mnemonic) {
                    case LD:
                        state.gr[i.r] = state.memory[calcAddr(i.addr, i.x)];
                    case ST:
                        state.memory[calcAddr(i.addr, i.x)] = state.gr[i.r];
                    case LAD:
                        state.gr[i.r] = new Word(calcAddr(i.addr, i.x));
                    case ADDA, ADDL:
                        state.gr[i.r] = new Word((state.gr[i.r] : Int) + state.memory[calcAddr(i.addr, i.x)]);
                    case SUBA, SUBL:
                        state.gr[i.r] = new Word((state.gr[i.r] : Int) - state.memory[calcAddr(i.addr, i.x)]);
                    case AND:
                        state.gr[i.r] = new Word((state.gr[i.r] : Int) & state.memory[calcAddr(i.addr, i.x)]);
                    case OR:
                        state.gr[i.r] = new Word((state.gr[i.r] : Int) | state.memory[calcAddr(i.addr, i.x)]);
                    case XOR:
                        state.gr[i.r] = new Word((state.gr[i.r] : Int) ^ state.memory[calcAddr(i.addr, i.x)]);
                    case CPA:
                        state.fr.zf = state.gr[i.r].toSigned() == new Word(calcAddr(i.addr, i.x)).toSigned();
                        state.fr.sf = state.gr[i.r].toSigned() < new Word(calcAddr(i.addr, i.x)).toSigned();
                    case CPL:
                        state.fr.zf = state.gr[i.r].toUnsigned() == calcAddr(i.addr, i.x).toUnsigned();
                        state.fr.sf = state.gr[i.r].toUnsigned() < calcAddr(i.addr, i.x).toUnsigned();
                    case SLA:
                        state.gr[i.r] = state.gr[i.r].sla(calcAddr(i.addr, i.x));
                    case SRA:
                        state.gr[i.r] = state.gr[i.r] >> calcAddr(i.addr, i.x);
                    case SLL:
                        state.gr[i.r] = state.gr[i.r] << calcAddr(i.addr, i.x);
                    case SRL:
                        state.gr[i.r] = state.gr[i.r] >>> calcAddr(i.addr, i.x);
                }
            case J(i):
                switch (i.mnemonic) {
                    case JPL:
                        if (!state.fr.sf && !state.fr.zf) {
                            state.pr = calcAddr(i.addr, i.x);
                            return false;
                        }
                    case JMI:
                        if (state.fr.sf) {
                            state.pr = calcAddr(i.addr, i.x);
                            return false;
                        }
                    case JNZ:
                        if (!state.fr.zf) {
                            state.pr = calcAddr(i.addr, i.x);
                            return false;
                        }
                    case JZE:
                        if (state.fr.zf) {
                            state.pr = calcAddr(i.addr, i.x);
                            return false;
                        }
                    case JOV:
                        if (state.fr.of) {
                            state.pr = calcAddr(i.addr, i.x);
                            return false;
                        }
                    case JUMP:
                        state.pr = calcAddr(i.addr, i.x);
                        return false;
                    case PUSH:
                        push(calcAddr(i.addr, i.x));
                    case CALL:
                        push(state.pr);
                        state.pr = calcAddr(i.addr, i.x);
                        return false;
                    case SVC:
                        throw new Exception("not implemeted...");
                }
            case P(i):
                switch (i.mnemonic) {
                    case POP:
                        state.gr[i.r] = pop();
                }
            case N(i):
                switch (i.mnemonic) {
                    case NOP:
                    case RET:
                        final addr = pop();
                        if (addr == 0xffff) {
                            return true;
                        } else {
                            state.pr = addr;
                            return false;
                        }
                }
        }
        return false;
    }

    function pop() {
        return state.memory[state.sp++];
    }

    function push(v:Word) {
        state.memory[--state.sp] = v;
    }

    function calcAddr(addr:Word, x:Nullable<I1to7>) {
        return new Word((addr : Int) + state.gr[(x : Nullable<Int>).getOrElse(0)]);
    }

    public function getState():FrozenComet2State {
        return cast state;
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
