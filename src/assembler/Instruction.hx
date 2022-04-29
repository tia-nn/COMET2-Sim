package assembler;

/**
    prefix:
        P: Preprocessed
        V: Validated
        M: Machine
        A: Assembler (macro)
**/
import Word.I0to7;
import Word.I1to7;
import extype.Nullable;

enum MorA<M, A> {
    Machine(v:M);
    Assembler(v:A);
}

// TODO: V と同じように label を共通化する
typedef Instruction = MorA<MInstruction, AInstruction>;

typedef MInstruction = {
    final ?label:Nullable<String>;
    final mnemonic:MMnemonic;
    final operand:Operand;
}

typedef AInstruction = {
    final ?label:Nullable<String>;
    final mnemonic:AMnemonic;
}

typedef VInstruction = {
    final ?label:Nullable<String>;
    final mnemonic:MorA<VMMnemonic, AMnemonic>;
}

@:using(assembler.Instruction.PInstOrDataTools)
enum PInstOrData {
    Inst(inst:PInstruction);
    Data(data:DataWord);
}

class PInstOrDataTools {
    public static function getLabel(inst:PInstOrData) {
        return switch (inst) {
            case Inst(inst):
                inst.label;
            case Data(data):
                data.label;
        }
    }
}

typedef DataWord = {
    final label:Array<String>;
    final value:Word;
}

typedef PInstruction = {
    final label:Array<String>;
    final mnemonic:PMnemonic;
}

// -------------------

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
    final addr:AAddr;
    final ?x:Nullable<I1to7>;
}

typedef JOperand = {
    final addr:AAddr;
    final ?x:Nullable<I1to7>;
}

typedef POperand = {
    final r:I0to7;
}

enum PreOperand {
    R(operand:ROperand);
    I(operand:PIOperand);
    J(operand:PJOperand);
    P(operand:POperand);
    N;
}

typedef PIOperand = {
    final r:I0to7;
    final addr:PAddr;
    final ?x:Nullable<I1to7>;
}

typedef PJOperand = {
    final addr:PAddr;
    final ?x:Nullable<I1to7>;
}

enum PAddr {
    Label(label:String);
    Constant(value:Word);
}

enum AAddr {
    Label(label:String);
    Constant(value:Word);
    Literal(values:Array<Word>);
}

enum MMnemonic {
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

enum AMnemonic {
    START(?label:Nullable<String>);
    END;
    DS(words:Int);
    DC(values:Array<Word>);
    IN(dataBuf:String, lengthBuf:String);
    OUT(dataBuf:String, lengthBuf:String);
    RPUSH;
    RPOP;
}

enum VMMnemonic {
    LDr(o:ROperand);
    LDi(o:IOperand);
    STi(o:IOperand);
    LADi(o:IOperand);
    ADDAr(o:ROperand);
    ADDAi(o:IOperand);
    SUBAr(o:ROperand);
    SUBAi(o:IOperand);
    ADDLr(o:ROperand);
    ADDLi(o:IOperand);
    SUBLr(o:ROperand);
    SUBLi(o:IOperand);
    ANDr(o:ROperand);
    ANDi(o:IOperand);
    ORr(o:ROperand);
    ORi(o:IOperand);
    XORr(o:ROperand);
    XORi(o:IOperand);
    CPAr(o:ROperand);
    CPAi(o:IOperand);
    CPLr(o:ROperand);
    CPLi(o:IOperand);
    SLAi(o:IOperand);
    SRAi(o:IOperand);
    SLLi(o:IOperand);
    SRLi(o:IOperand);
    JPLj(o:JOperand);
    JMIj(o:JOperand);
    JNZj(o:JOperand);
    JZEj(o:JOperand);
    JOVj(o:JOperand);
    JUMPj(o:JOperand);
    PUSHj(o:JOperand);
    POPp(o:POperand);
    CALLj(o:JOperand);
    RETn();
    SVCj(o:JOperand);
    NOPn();
}

enum PMnemonic {
    LDr(o:ROperand);
    LDi(o:PIOperand);
    STi(o:PIOperand);
    LADi(o:PIOperand);
    ADDAr(o:ROperand);
    ADDAi(o:PIOperand);
    SUBAr(o:ROperand);
    SUBAi(o:PIOperand);
    ADDLr(o:ROperand);
    ADDLi(o:PIOperand);
    SUBLr(o:ROperand);
    SUBLi(o:PIOperand);
    ANDr(o:ROperand);
    ANDi(o:PIOperand);
    ORr(o:ROperand);
    ORi(o:PIOperand);
    XORr(o:ROperand);
    XORi(o:PIOperand);
    CPAr(o:ROperand);
    CPAi(o:PIOperand);
    CPLr(o:ROperand);
    CPLi(o:PIOperand);
    SLAi(o:PIOperand);
    SRAi(o:PIOperand);
    SLLi(o:PIOperand);
    SRLi(o:PIOperand);
    JPLj(o:PJOperand);
    JMIj(o:PJOperand);
    JNZj(o:PJOperand);
    JZEj(o:PJOperand);
    JOVj(o:PJOperand);
    JUMPj(o:PJOperand);
    PUSHj(o:PJOperand);
    POPp(o:POperand);
    CALLj(o:PJOperand);
    RETn();
    SVCj(o:PJOperand);
    NOPn();
}
