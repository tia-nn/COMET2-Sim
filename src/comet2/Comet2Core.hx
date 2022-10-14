package comet2;

import comet2.csr.FlagRegister;
import comet2.csr.IERegister;
import comet2.csr.IWRegister;
import comet2.csr.StatusRegister;
import extype.Exception;
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
        final firstWord = memory[PR];
        final secondWord = memory[PR + 1];
        return firstWord.toInstruction(secondWord);
    }

    function excecution(inst:Instruction) {
        trace(inst.toString());
    }
}
