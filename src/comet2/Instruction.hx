package comet2;

import extype.Nullable;
import types.Word;

enum Instruction {
    R(i:RInstruction);
    I(i:IInstruction);
    J(i:JInstruction);
    P(i:PInstruction);
    N(i:NInstruction);
}

typedef ROperand = {
    final r1:I0to7;
    final r2:I0to7;
}

typedef IOperand = {
    final r:I0to7;
    final addr:Word;
    final ?x:Nullable<I1to7>;
}

typedef JOperand = {
    final addr:Word;
    final ?x:Nullable<I1to7>;
}

typedef POperand = {
    final r:I0to7;
}

typedef NOperand = {};

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

    INT;
}

enum PMnemonic {
    POP;

    LD_SP;
    LD_PTR;
    LD_IE;
    LD_IW;
    LD_CAUSE;
    LD_STATUS;
    ST_SP;
    ST_PTR;
    ST_IE;
    ST_STATUS;
}

enum NMnemonic {
    RET;
    NOP;

    IRET;
}
