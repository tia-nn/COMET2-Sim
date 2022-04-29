package machine;

import Word.I1to7;
import extype.Exception;
import extype.Map;
import extype.Nullable;
import parser.Instruction.Preprocessed;
import parser.Instruction.PreprocessedAddr;
import parser.Instruction.PreprocessedInstruction;

class Comet2 {
    var state:Comet2State;

    public function new(insts:Array<Preprocessed>, addr:Int = 0) {
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
            sp: new Word(0),
            pr: new Word(0),
            fr: {
                of: false,
                sf: false,
                zf: false,
            },
            memory: [for (i in 0...65536) Data(new Word(0))],
            labelTable: new Map(),
        };

        state.memory[65536] = ExitAddr;

        load(insts, addr);
    }

    function load(insts:Array<Preprocessed>, addr:Int = 0) {
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
        final inst = switch (state.memory[state.pr]) {
            case Data(_), ExitAddr:
                throw new Exception("executing data");
            case Inst(inst):
                inst;
        }

        switch (inst.mnemonic) {
            case LD:
                switch (inst.operand) {
                    case R(operand):
                        state.gr[operand.r1] = state.memory[state.gr[operand.r2]].toWord();
                    case I(operand):
                        state.gr[operand.r] = state.memory[addrToWord(operand.addr, operand.x)].toWord();
                    case _:
                        throw new Exception("");
                }
            case RET:
                switch (inst.operand) {
                    case N:
                        switch (state.memory[state.sp]) {
                            case ExitAddr:
                                pop();
                                return true;
                            case Data(_), Inst(_):
                                state.pr = pop();
                        }
                    case _:
                        throw new Exception("");
                }
            case POP:
                switch (inst.operand) {
                    case P(operand):
                        state.gr[operand.r] = pop();
                    case _:
                        throw new Exception("");
                }
            case _:
                throw new Exception("not implemeted mnemonic.");
        }
        return false;
    }

    function pop() {
        final val = state.memory[state.sp].toWord();
        state.sp++;
        return val;
    }

    function addrToWord(addr:PreprocessedAddr, x:Nullable<I1to7>) {
        return switch (addr) {
            case Label(label):
                final value = Nullable.of(state.labelTable.get(label)).getOrThrow(() -> new Exception("label not found."));
                return value + state.gr[(x : Nullable<Int>).getOrElse(0)];
            case Constant(value):
                return (value : Int) + state.gr[(x : Nullable<Int>).getOrElse(0)];
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
    Inst(inst:PreprocessedInstruction);
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
