package casl2.parser;

import extype.Nullable;
import extype.ReadOnlyArray;
import types.Integer.GRIndex;
import types.Integer.IRIndex;
import types.Integer.Word;

typedef LabeledInstruction = {
    final label:Nullable<String>;
    final inst:Nullable<InstructionType>;
}

enum InstructionType {
    R(i:RInstruction);
    I(i:IInstruction);
    J(i:JInstruction);
    P(i:PInstruction);
    N(i:NInstruction);
    M(i:MacroInstruction);
}

//

typedef ROperand = {
    final r1:GRIndex;
    final r2:GRIndex;
};

typedef IOperand = {
    final r:GRIndex;
    final addr:Addr;
    final ?x:Nullable<IRIndex>;
};

typedef JOperand = {
    final addr:Addr;
    final ?x:Nullable<IRIndex>;
};

typedef POperand = {
    final r:GRIndex;
};

typedef NOperand = {};

//

typedef RInstruction = {
    final mnemonic:RMnemonic;
} &
    ROperand;

typedef IInstruction = {
    final mnemonic:IMnemonic;
} &
    IOperand;

typedef JInstruction = {
    final mnemonic:JMnemonic;
} &
    JOperand;

typedef PInstruction = {
    final mnemonic:PMnemonic;
} &
    POperand;

typedef NInstruction = {
    final mnemonic:NMnemonic;
} &
    NOperand;

enum MacroInstruction {
    START(?label:Nullable<String>);
    END;
    DS(words:Int);
    DC(values:ReadOnlyArray<Word>);
    IN(dataBuf:String, lengthBuf:String);
    OUT(dataBuf:String, lengthBuf:String);
    RPUSH;
    RPOP;
}

//

enum Addr {
    Label(l:String);
    Const(v:Word);
    Literal(v:ReadOnlyArray<Word>);
}

enum RMnemonic {
    LD;
    ADDA;
    SUBA;
    ADDL;
    SUBL;
    AND;
    OR;
    XOR;
    CPA;
    CPL;
}

enum IMnemonic {
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
}

enum JMnemonic {
    JMI;
    JNZ;
    JZE;
    JUMP;
    JPL;
    JOV;
    PUSH;
    CALL;
    SVC;
    #if extension_instructions
    INT;
    #end
}

enum PMnemonic {
    POP;
}

enum NMnemonic {
    RET;
    #if extension_instructions
    NOP;
    IRET;
    #end
}
