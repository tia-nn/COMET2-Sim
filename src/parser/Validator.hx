package parser;

import extype.Nullable;
import parser.Instruction.AssemblerInstruction;
import parser.Instruction.MachineInstruction;
import parser.Parser.ParseResult;

class Validator {
    public static function validate(src:Array<ParseResult<Nullable<Instruction>>>) {
        var instructions:Array<ValidateResult> = [];
        switch (validateStart(src)) {
            case Success:
                instructions = instructions.concat(validateDuplicateStart(src));
            case Error(message, line, col):
                instructions.push(Error(message, line, col));
        }
        switch (validateEnd(src)) {
            case Success:
                instructions = instructions.concat(validateDuplicateEnd(src));
            case Error(message, line, col):
                instructions.push(Error(message, line, col));
        }
        for (line in 0...src.length) {
            switch (src[line]) {
                case Success(r):
                    if (r.isEmpty()) {
                        continue;
                    } else {
                        instructions.push(switch (validateInstruction(r.get(), line)) {
                            case Success:
                                Success(r.get());
                            case Error(message, line, col):
                                Error(message, line, col);
                        });
                    }
                case Unmatched(message):
                    instructions.push(Error(message, line));
            }
        }
        return instructions;
    }

    static function validateStart(src:Array<ParseResult<Nullable<Instruction>>>):ValidateResultWithoutValue {
        for (line in 0...src.length) {
            switch (src[line]) {
                case Success(r):
                    if (r.isEmpty())
                        continue;
                    else
                        switch (r.get()) {
                            case Assembler(inst):
                                switch (inst.mnemonic) {
                                    case START(label):
                                        return Success;
                                    case _:
                                }
                            case Machine(inst):
                        }
                case Unmatched(message):
            }
            return Error("START が必要です.", line);
        }
        return Error("START が必要です.", 0);
    }

    static function validateDuplicateStart(src:Array<ParseResult<Nullable<Instruction>>>):Array<ValidateResult> {
        var started = false;
        final errors:Array<ValidateResult> = [];
        for (line in 0...src.length) {
            switch (src[line]) {
                case Success(r):
                    if (r.isEmpty())
                        continue;
                    else
                        switch (r.get()) {
                            case Assembler(inst):
                                switch (inst.mnemonic) {
                                    case START(label):
                                        if (started) {
                                            errors.push(Error("START は一度しか使用できません.", line));
                                        } else {
                                            started = true;
                                        }
                                    case _:
                                }
                            case Machine(inst):
                        }
                case Unmatched(message):
            }
        }
        return errors;
    }

    static function validateEnd(src:Array<ParseResult<Nullable<Instruction>>>):ValidateResultWithoutValue {
        final range = [for (i in 0...src.length) i];
        range.reverse();
        for (line in range) {
            switch (src[line]) {
                case Success(r):
                    if (r.isEmpty())
                        continue;
                    else
                        switch (r.get()) {
                            case Assembler(inst):
                                switch (inst.mnemonic) {
                                    case END:
                                        return Success;
                                    case _:
                                }
                            case Machine(inst):
                        }
                case Unmatched(message):
            }
            return Error("END が必要です.", line);
        }
        return Error("END が必要です.", src.length);
    }

    static function validateDuplicateEnd(src:Array<ParseResult<Nullable<Instruction>>>):Array<ValidateResult> {
        var ended = false;
        final errors:Array<ValidateResult> = [];
        final range = [for (i in 0...src.length) i];
        range.reverse();
        for (line in range) {
            switch (src[line]) {
                case Success(r):
                    if (r.isEmpty())
                        continue;
                    else
                        switch (r.get()) {
                            case Assembler(inst):
                                switch (inst.mnemonic) {
                                    case END:
                                        if (ended) {
                                            errors.push(Error("END は一度しか使用できません.", line));
                                        } else {
                                            ended = true;
                                        }
                                    case _:
                                }
                            case Machine(inst):
                        }
                case Unmatched(message):
            }
        }
        return errors;
    }

    static function validateInstruction(inst:Instruction, line:Int):ValidateResultWithoutValue {
        return switch (inst) {
            case Machine(inst):
                validateMachineInstruction(inst, line);
            case Assembler(inst):
                validateAssemblerInstruction(inst, line);
        }
    }

    static function validateMachineInstruction(inst:MachineInstruction, line:Int):ValidateResultWithoutValue {
        return switch (inst.mnemonic) {
            case LD, ADDA, ADDL, SUBA, SUBL, AND, OR, XOR, CPA, CPL: // R,I
                switch (inst.operand) {
                    case R(_), I(_):
                        Success;
                    case _:
                        Error("オペランドの形式が間違っています.", line);
                }
            case ST, LAD, SLA, SRA, SLL, SRL: // I
                switch (inst.operand) {
                    case I(_):
                        Success;
                    case _:
                        Error("オペランドの形式が間違っています.", line);
                }
            case JPL, JMI, JNZ, JZE, JOV, JUMP, PUSH, CALL, SVC: // J
                switch (inst.operand) {
                    case J(_):
                        Success;
                    case _:
                        Error("オペランドの形式が間違っています.", line);
                }
            case POP: // P
                switch (inst.operand) {
                    case P(_):
                        Success;
                    case _:
                        Error("オペランドの形式が間違っています.", line);
                }
            case RET, NOP: // N
                switch (inst.operand) {
                    case N:
                        Success;
                    case _:
                        Error("RET, NOP はオペランドを指定できません.", line);
                }
        }
    }

    static function validateAssemblerInstruction(inst:AssemblerInstruction, line:Int):ValidateResultWithoutValue {
        return switch (inst.mnemonic) {
            case START(label):
                inst.label.fold(() -> Error("START にはラベルが必要です.", line), _ -> Success);
            case END:
                inst.label.fold(() -> Success, _ -> Error("END にはラベルを指定できません.", line));
            case _:
                Success;
        }
    }
}

enum ValidateResult {
    Success(inst:Instruction);
    Error(message:String, line:Int, ?col:Int);
}

enum ValidateResultWithoutValue {
    Success;
    Error(message:String, line:Int, ?col:Int);
}
