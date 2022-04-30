package parser;

import Word.I0to7;
import Word.I1to7;
import extype.Nullable;

/**
    parse phase:
    - Linked
    - Object
    - Parsed
**/
// Linked
enum LinkedInstruction {
    R(i:LinkedRInstruction);
    I(i:LinkedIInstruction);
    J(i:LinkedJInstruction);
    P(i:LinkedPInstruction);
    N(i:LinkedNInstruction);
}

typedef LinkedROperand = {
    final r1:I0to7;
    final r2:I0to7;
}

typedef LinkedIOperand = {
    final r:I0to7;
    final addr:Word;
    final ?x:Nullable<I1to7>;
}

typedef LinkedJOperand = {
    final addr:Word;
    final ?x:Nullable<I1to7>;
}

typedef LinkedPOperand = {
    final r:I0to7;
}

typedef LinkedNOperand = {};

typedef LinkedRInstruction = {
    final mnemonic:RMnemonic;
} &
    LinkedROperand;

typedef LinkedIInstruction = {
    final mnemonic:IMnemonic;
} &
    LinkedIOperand;

typedef LinkedJInstruction = {
    final mnemonic:JMnemonic;
} &
    LinkedJOperand;

typedef LinkedPInstruction = {
    final mnemonic:PMnemonic;
} &
    LinkedPOperand;

typedef LinkedNInstruction = {
    final mnemonic:NMnemonic;
} &
    LinkedNOperand;

// Object

typedef ObjectInstructionWithLabel = {
    final label:Array<String>;
    final inst:ObjectInstruction;
}

enum ObjectInstruction {
    R(i:ObjectRInstruction);
    I(i:ObjectIInstruction);
    J(i:ObjectJInstruction);
    P(i:ObjectPInstruction);
    N(i:ObjectNInstruction);
    Data(d:Word);
}

typedef ObjectROperand = LinkedROperand;

typedef ObjectIOperand = {
    final r:I0to7;
    final addr:ObjectAddr;
    final ?x:Nullable<I1to7>;
}

typedef ObjectJOperand = {
    final addr:ObjectAddr;
    final ?x:Nullable<I1to7>;
}

typedef ObjectPOperand = LinkedPOperand;
typedef ObjectNOperand = LinkedNOperand;
typedef ObjectRInstruction = LinkedRInstruction;

typedef ObjectIInstruction = {
    final mnemonic:IMnemonic;
} &
    ObjectIOperand;

typedef ObjectJInstruction = {
    final mnemonic:JMnemonic;
} &
    ObjectJOperand;

typedef ObjectPInstruction = LinkedPInstruction;
typedef ObjectNInstruction = LinkedNInstruction;

enum ObjectAddr {
    Label(l:String);
    Const(v:Word);
}

// Parsed

enum ParseReport {
    Success(r:Array<ParsedInstructionWithLine>, warnings:Array<WithPos<String>>);
    Failed(e:Array<WithPos<String>>, w:Array<WithPos<String>>);
}

typedef WithPos<T> = {
    final value:T;
    final pos:Position;
}

typedef WithCol<T> = {
    final value:T;
    final col:Int;
}

typedef Position = {
    final line:Int;
    final col:Int;
};

typedef ParsedInstructionWithLine = {
    final value:ParsedInstructionWithLabel;
    final line:Int;
};

typedef ParsedInstructionWithLabel = {
    final ?label:Nullable<String>;
    final inst:ParsedInstruction;
}

enum ParsedInstruction {
    A(i:AInstruction);
    R(i:ParsedRInstruction);
    I(i:ParsedIInstruction);
    J(i:ParsedJInstruction);
    P(i:ParsedPInstruction);
    N(i:ParsedNInstruction);
}

typedef ParsedROperand = ObjectROperand;
typedef ParsedRInstruction = ObjectRInstruction;

typedef ParsedIOperand = {
    final r:I0to7;
    final addr:ParsedAddr;
    final ?x:Nullable<I1to7>;
};

typedef ParsedIInstruction = {
    final mnemonic:IMnemonic;
} &
    ParsedIOperand;

typedef ParsedJOperand = {
    final addr:ParsedAddr;
    final ?x:Nullable<I1to7>;
}

typedef ParsedJInstruction = {
    final mnemonic:JMnemonic;
} &
    ParsedJOperand;

typedef ParsedPOperand = ObjectPOperand;
typedef ParsedPInstruction = ObjectPInstruction;
typedef ParsedNOperand = ObjectNOperand;
typedef ParsedNInstruction = ObjectNInstruction;

enum ParsedAddr {
    Label(l:String);
    Const(v:Word);
    Literal(v:Array<Word>);
}

enum AInstruction {
    START(?label:Nullable<String>);
    END;
    DS(words:Int);
    DC(values:Array<Word>);
    IN(dataBuf:String, lengthBuf:String);
    OUT(dataBuf:String, lengthBuf:String);
    RPUSH;
    RPOP;
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
}

enum PMnemonic {
    POP;
}

enum NMnemonic {
    RET;
    NOP;
}
