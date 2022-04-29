package assembler;

import assembler.Instruction.AInstruction;
import assembler.Instruction.IOperand;
import assembler.Instruction.JOperand;
import assembler.Instruction.MInstruction;
import assembler.Instruction.MMnemonic;
import assembler.Instruction.POperand;
import assembler.Instruction.ROperand;
import assembler.Instruction.VInstruction;
import assembler.Instruction.VMMnemonic;
import assembler.Parser.ParseResult;
import extype.Exception;
import extype.Nullable;

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
                        instructions.push(validateInstruction(r.get(), line));
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

    static function validateInstruction(inst:Instruction, line:Int):ValidateResult {
        return switch (inst) {
            case Machine(inst):
                validateMInstruction(inst, line);
            case Assembler(inst):
                validateAInstruction(inst, line);
        }
    }

    static function validateMInstruction(inst:MInstruction, line:Int):ValidateResult {
        return switch (inst.mnemonic) {
            case LD, ADDA, ADDL, SUBA, SUBL, AND, OR, XOR, CPA, CPL: // R,I
                switch (inst.operand) {
                    case R(o):
                        Success({
                            label: inst.label,
                            mnemonic: Machine(mtovmR(inst.mnemonic, o)),
                        });
                    case I(o):
                        Success({
                            label: inst.label,
                            mnemonic: Machine(mtovmI(inst.mnemonic, o)),
                        });
                    case _:
                        Error("オペランドの形式が間違っています.", line);
                }
            case ST, LAD, SLA, SRA, SLL, SRL: // I
                switch (inst.operand) {
                    case I(o):
                        Success({
                            label: inst.label,
                            mnemonic: Machine(mtovmI(inst.mnemonic, o)),
                        });
                    case _:
                        Error("オペランドの形式が間違っています.", line);
                }
            case JPL, JMI, JNZ, JZE, JOV, JUMP, PUSH, CALL, SVC: // J
                switch (inst.operand) {
                    case J(o):
                        Success({
                            label: inst.label,
                            mnemonic: Machine(mtovmJ(inst.mnemonic, o)),
                        });
                    case _:
                        Error("オペランドの形式が間違っています.", line);
                }
            case POP: // P
                switch (inst.operand) {
                    case P(o):
                        Success({
                            label: inst.label,
                            mnemonic: Machine(mtovmP(inst.mnemonic, o)),
                        });
                    case _:
                        Error("オペランドの形式が間違っています.", line);
                }
            case RET, NOP: // N
                switch (inst.operand) {
                    case N:
                        Success({
                            label: inst.label,
                            mnemonic: Machine(mtovmN(inst.mnemonic)),
                        });
                    case _:
                        Error("RET, NOP はオペランドを指定できません.", line);
                }
        }
    }

    static function validateAInstruction(inst:AInstruction, line:Int):ValidateResult {
        return switch (inst.mnemonic) {
            case START(label):
                inst.label.fold(() -> ValidateResult.Error("START にはラベルが必要です.", line), _ -> Success({
                    label: inst.label,
                    mnemonic: Assembler(inst.mnemonic),
                }));
            case END:
                inst.label.fold(() -> ValidateResult.Success({
                    mnemonic: Assembler(inst.mnemonic),
                }), _ -> Error("END にはラベルを指定できません.", line));
            case _:
                Success({
                    label: inst.label,
                    mnemonic: Assembler(inst.mnemonic),
                });
        }
    }

    static function mtovmR(m:MMnemonic, o:ROperand):VMMnemonic {
        return switch (m) {
            case LD:
                LDr(o);
            case ADDA:
                ADDAr(o);
            case ADDL:
                ADDLr(o);
            case SUBA:
                SUBAr(o);
            case SUBL:
                SUBLr(o);
            case AND:
                ANDr(o);
            case OR:
                ORr(o);
            case XOR:
                XORr(o);
            case CPA:
                CPAr(o);
            case CPL:
                CPLr(o);
            case _:
                throw new Exception("");
        }
    }

    static function mtovmI(m:MMnemonic, o:IOperand):VMMnemonic {
        return switch (m) {
            case LD:
                LDi(o);
            case ADDA:
                ADDAi(o);
            case ADDL:
                ADDLi(o);
            case SUBA:
                SUBAi(o);
            case SUBL:
                SUBLi(o);
            case AND:
                ANDi(o);
            case OR:
                ORi(o);
            case XOR:
                XORi(o);
            case CPA:
                CPAi(o);
            case CPL:
                CPLi(o);

            case ST:
                STi(o);
            case LAD:
                LADi(o);
            case SLA:
                SLAi(o);
            case SRA:
                SRAi(o);
            case SLL:
                SLLi(o);
            case SRL:
                SRLi(o);

            case _:
                throw new Exception("");
        }
    }

    static function mtovmJ(m:MMnemonic, o:JOperand):VMMnemonic {
        return switch (m) {
            case JPL:
                JPLj(o);
            case JMI:
                JMIj(o);
            case JNZ:
                JNZj(o);
            case JZE:
                JZEj(o);
            case JOV:
                JOVj(o);
            case JUMP:
                JUMPj(o);
            case PUSH:
                PUSHj(o);
            case CALL:
                CALLj(o);
            case SVC:
                SVCj(o);
            case _:
                throw new Exception("");
        }
    }

    static function mtovmP(m:MMnemonic, o:POperand):VMMnemonic {
        return switch (m) {
            case POP:
                POPp(o);
            case _:
                throw new Exception("");
        }
    }

    static function mtovmN(m:MMnemonic):VMMnemonic {
        return switch (m) {
            case RET:
                RETn;
            case NOP:
                NOPn;
            case _:
                throw new Exception("");
        }
    }
}

enum ValidateResult {
    Success(inst:VInstruction);
    Error(message:String, line:Int, ?col:Int);
}

enum ValidateResultWithoutValue {
    Success;
    Error(message:String, line:Int, ?col:Int);
}
