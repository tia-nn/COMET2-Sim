package machine;

import extype.Exception;
import extype.Nullable;
import extype.ReadOnlyArray;
import machine.Comet2State;
import sys.thread.Lock;
import types.Instruction;
import types.Word;

using machine.WordTools;

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
                ie: false,
            },
            memory: [for (i in 0...65536) new Word(0)],
            intQueue: [],
            intVecMask: new Word(0xffff),
            isExited: false,
        };
        state.pr = new Word(entry);

        intQueueLock = new Lock();
        intQueueLock.release();

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

    function fetchDecode():Nullable<LinkedInstruction> {
        final firstWord = state.memory[state.pr++];
        final fetchSecondWord = () -> state.memory[state.pr++];
        try {
            trace('[${state.pr - 1}] -> ${firstWord}');
            return firstWord.toInstruction(fetchSecondWord);
        } catch (e:Exception) {
            return null;
        }
    }

    public function step():Bool {
        final mnemonic = fetchDecode();

        trace(mnemonic);
        final mnemonic = if (mnemonic.nonEmpty()) {
            mnemonic.getUnsafe();
        } else {
            priorityIntRequire(1);
            N({mnemonic: NOP});
        }

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
                        if (cause.toUnsigned() > 15) {
                            priorityIntRequire(1);
                        } else {
                            intRequire(cause);
                        }
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
                    case IRET:
                        state.pr = pop();
                        state.sp = pop();
                        state.fr = pop().toFR();
                        for (i in [7, 6, 5, 4, 3, 2, 1, 0])
                            state.gr[i] = pop();
                    case EI:
                        state.fr.ie = true;
                    case DI:
                        state.fr.ie = false;
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
                onExit();
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
        if (cause > 15) {
            throw new Exception("int cause over range");
        } else if (cause == 3) {
            if (bios())
                return true;
        } else {
            final routine = state.memory[INT_VEC_ADDR + cause];
            for (i in 0...8)
                push(state.gr[i]);
            push(state.fr.toWord());
            state.fr.ie = false;
            push(state.sp);
            push(state.pr);
            state.pr = new Word(routine);
        }
        return false;
    }

    function bios() {
        state.intQueue.push(1);
        return false;
    }

    /**
        割り込み要求 (マスク可能)
    **/
    function intRequireWithMask(cause:Int) {
        if (cause > 15) {
            throw new Exception('invalid int cause (${cause})');
        } else if (state.fr.ie) {
            if (state.intVecMask & (1 << cause) == 0) {
                intQueueLock.wait();
                state.intQueue.push(cause);
                intQueueLock.release();
            }
        }
    }

    /**
        割り込み要求 (マスク不可)
    **/
    function intRequire(cause:Int) {
        if (cause > 15) {
            throw new Exception('invalid int cause (${cause})');
        } else {
            intQueueLock.wait();
            state.intQueue.push(cause);
            intQueueLock.release();
        }
    }

    /**
        割り込み要求 (マスク不可, 優先)
    **/
    function priorityIntRequire(cause:Int) {
        if (cause > 15) {
            throw new Exception('invalid int cause (${cause})');
        } else {
            intQueueLock.wait();
            state.intQueue.insert(0, cause);
            intQueueLock.release();
        }
    }

    function calcAddr(addr:Word, x:Nullable<I1to7>) {
        return new Word((addr : Int) + x.fold(() -> 0, gr -> state.gr[gr]));
    }

    public function getState():FrozenComet2State {
        return cast state;
    }

    function onExit() {
    }
}
