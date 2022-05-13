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
    SVC;
    INT;
    IRET;
    EI;
    DI;
    NOP;

    START;
    END;
    DS;
    DC;
    IN;
    OUT;
    RPUSH;
    RPOP;
}
