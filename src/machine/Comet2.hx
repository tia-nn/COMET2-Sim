package machine;

import extype.Exception;
import extype.Nullable;
import extype.ReadOnlyArray;
import machine.Comet2State;
import sys.thread.Lock;
import types.Instruction;
import types.Word;

using machine.WordTools;

@:allow(Main)
class Comet2 {
    var state:Comet2State;
    final intQueueLock:Lock;

    static final INT_VEC_ADDR = 0x2000;

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
            intQueue: [],
            memory: [for (i in 0...65536) new Word(0)],
            isExited: false,
        };
        state.pr = new Word(entry);

        intQueueLock = new Lock();

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

    function fetchDecode():LinkedInstruction {
        final firstWord = state.memory[state.pr++];
        final fetchSecondWord = () -> state.memory[state.pr++];
        return firstWord.toInstruction(fetchSecondWord);
    }

    public function step():Bool {
        final mnemonic = fetchDecode();

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
                        state.fr.zf = state.gr[i.r].toSigned() == state.memory[calcAddr(i.addr, i.x)].toSigned();
                        state.fr.sf = state.gr[i.r].toSigned() < state.memory[calcAddr(i.addr, i.x)].toSigned();
                    case CPL:
                        state.fr.zf = state.gr[i.r].toUnsigned() == state.memory[calcAddr(i.addr, i.x)].toUnsigned();
                        state.fr.sf = state.gr[i.r].toUnsigned() < state.memory[calcAddr(i.addr, i.x)].toUnsigned();
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
                        }
                    case JMI:
                        if (state.fr.sf) {
                            state.pr = calcAddr(i.addr, i.x);
                        }
                    case JNZ:
                        if (!state.fr.zf) {
                            state.pr = calcAddr(i.addr, i.x);
                        }
                    case JZE:
                        if (state.fr.zf) {
                            state.pr = calcAddr(i.addr, i.x);
                        }
                    case JOV:
                        if (state.fr.of) {
                            state.pr = calcAddr(i.addr, i.x);
                        }
                    case JUMP:
                        state.pr = calcAddr(i.addr, i.x);
                    case PUSH:
                        push(calcAddr(i.addr, i.x));
                    case CALL:
                        push(state.pr);
                        state.pr = calcAddr(i.addr, i.x);
                    case SVC:
                        throw new Exception("not implemeted...");
                    case INT:
                        final cause = calcAddr(i.addr, i.x);
                        intQueueLock.wait();
                        state.intQueue.push(cause);
                        intQueueLock.release();
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
                        state.pr = addr;
                }
        }

        while (true) {
            intQueueLock.wait();
            if (state.intQueue.length == 0) {
                intQueueLock.release();
                break;
            }

            final cause = state.intQueue[0];
            state.intQueue = state.intQueue.slice(1);
            intQueueLock.release();

            if (int(cause)) {
                state.isExited = true;
                return true;
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

    function int(cause:Int):Bool {
        // 割り込み禁止なら無視する.
        if (cause > 15) {
            throw new Exception("int cause over range");
            state.intQueue.push(1);
        } else if (cause == 8) {
            if (bios())
                return true;
        } else {
            final routine = INT_VEC_ADDR + cause;
            // TODO: 割り込み禁止
            // TODO: RPUSH
            push(state.pr);
            state.pr = new Word(routine);
        }
        return false;
    }

    function bios() {
        state.intQueue.push(1);
        return false;
    }

    function calcAddr(addr:Word, x:Nullable<I1to7>) {
        return new Word((addr : Int) + x.fold(() -> 0, gr -> state.gr[gr]));
    }

    public function getState():FrozenComet2State {
        return cast state;
    }
}
