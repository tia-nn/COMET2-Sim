package parser;

import Word.I0to7;
import Word.I1to7;
import extype.Nullable;

@:using(parser.Instruction.PreprocessedTools)
enum Preprocessed {
    Inst(inst:PreprocessedInstruction);
    Data(data:DataWord);
}

class PreprocessedTools {
    public static function getLabel(inst:Preprocessed) {
        return switch (inst) {
            case Inst(inst):
                inst.label;
            case Data(data):
                data.label;
        }
    }
}

enum Instruction {
    Machine(inst:MachineInstruction);
    Assembler(inst:AssemblerInstruction);
}

typedef DataWord = {
    final label:Array<String>;
    final value:Word;
}

typedef PreprocessedInstruction = {
    final label:Array<String>;
    final mnemonic:MachineMnemonic;
    final operand:PreprocessedOperand;
}

typedef MachineInstruction = {
    final ?label:Nullable<String>;
    final mnemonic:MachineMnemonic;
    final operand:Operand;
}

typedef AssemblerInstruction = {
    final ?label:Nullable<String>;
    final mnemonic:AssemblerMnemonic;
}

enum Operand {
    R(operand:ROperand);
    I(operand:IOperand);
    J(operand:JOperand);
    P(operand:POperand);
    N;
}

typedef ROperand = {
    final r1:I0to7;
    final r2:I0to7;
}

typedef IOperand = {
    final r:I0to7;
    final addr:AssemblerAddr;
    final ?x:Nullable<I1to7>;
}

typedef JOperand = {
    final addr:AssemblerAddr;
    final ?x:Nullable<I1to7>;
}

typedef POperand = {
    final r:I0to7;
}

enum PreprocessedOperand {
    R(operand:ROperand);
    I(operand:PreprocessedIOperand);
    J(operand:PreprocessedJOperand);
    P(operand:POperand);
    N;
}

typedef PreprocessedIOperand = {
    final r:I0to7;
    final addr:PreprocessedAddr;
    final ?x:Nullable<I1to7>;
}

typedef PreprocessedJOperand = {
    final addr:PreprocessedAddr;
    final ?x:Nullable<I1to7>;
}

enum PreprocessedAddr {
    Label(label:String);
    Constant(value:Word);
}

enum AssemblerAddr {
    Label(label:String);
    Constant(value:Word);
    Literal(values:Array<Word>);
}

enum MachineMnemonic {
    LD;
    ST;
    LAD;
    ADDA;
    SUBA;
    ADDL;
    SUBL;
    AND;
    OR;
    XOR;
    CPA;
    CPL;
    SLA;
    SRA;
    SLL;
    SRL;
    JPL;
    JMI;
    JNZ;
    JZE;
    JOV;
    JUMP;
    PUSH;
    POP;
    CALL;
    RET;
    SVC;
    NOP;
}

enum AssemblerMnemonic {
    START(?label:Nullable<String>);
    END;
    DS(words:Int);
    DC(values:Array<Word>);
    IN(dataBuf:String, lengthBuf:String);
    OUT(dataBuf:String, lengthBuf:String);
    RPUSH;
    RPOP;
}
