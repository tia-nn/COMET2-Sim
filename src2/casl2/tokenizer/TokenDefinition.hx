package casl2.tokenizer;

import extype.ReadOnlyArray;
import types.FilePosition;

typedef TokenList = ReadOnlyArray<InstTokenList>;
typedef InstTokenList = ReadOnlyArray<TokenInfo>;

typedef TokenInfo = {
    final token:Token;
    final src:String;
    final position:FilePosition;
}

enum Token {
    // NewLine;
    LeadSpace;
    Comma;
    Mnemonic(mnemonic:MnemonicToken);
    GR;
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
    // additional
    INT;
    IRET;
    NOP;
    // macro
    START;
    END;
    DS;
    DC;
    IN;
    OUT;
    RPUSH;
    RPOP;
}
