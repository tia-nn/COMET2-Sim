package tokenizer;

typedef TokenInfo = {
    final token:Token;
    final src:String;
    final line:Int;
    final col:Int;
}

enum Token {
    // NewLine;
    LeadSpace;
    Comma;
    Mnemonic(mnemonic:MnemonicToken);
    R;
    Label;
    Dec;
    Hex;
    String;
    DecLiteral;
    HexLiteral;
    StringLiteral;
    Comment;
}

enum MnemonicToken {
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
    JMI;
    JNZ;
    JZE;
    JUMP;
    JPL;
    JOV;
    PUSH;
    POP;
    CALL;
    RET;
    LD_SP;
    LD_PTR;
    LD_IE;
    LD_IW;
    LD_CAUSE;
    LD_STATUS;
    LD_TVAL;
    LD_TVEC;
    LD_EPR;
    LD_SCRATCH;
    ST_SP;
    ST_PTR;
    ST_IE;
    ST_STATUS;
    ST_TVEC;
    ST_SCRATCH;
    SVC;
    INT;
    IRET;
    NOP;
    IN;
    OUT;

    START;
    END;
    DS;
    DC;
    RPUSH;
    RPOP;
    JEQ;
    JNE;
    JGT;
    JLT;
}
