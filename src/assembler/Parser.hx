package assembler;

import Word.I0to7;
import Word.I1to7;
import assembler.Instruction;
import assembler.Tokenizer.MnemonicToken;
import assembler.Tokenizer.Token;
import assembler.Tokenizer.TokenInfo;
import extype.Nullable;
import extype.Tuple.Tuple2;
import haxe.Exception;
import haxe.iterators.StringIteratorUnicode;

using StringTools;

@:allow(Main)
class Parser {
    var tokens:Array<TokenInfo>;

    function new(tokens:Array<TokenInfo>) {
        this.tokens = tokens;
    }

    public static function parse(tokens:Array<Array<TokenInfo>>):Array<ParseResult<Nullable<Instruction>>> {
        final instructions = [];
        for (instTokens in tokens) {
            final parser = new Parser(instTokens);
            instructions.push(parser.parseRow());
        }

        return instructions;
    }

    function parseRow():ParseResult<Nullable<Instruction>> {
        if (tokens.length <= 2) {
            final beforeTokens = tokens.copy();
            consumeLeadSpace();
            consumeComment();
            if (tokens.length == 0) // 空行
                return Success(null);
            else {
                tokens = beforeTokens;
            }
        }

        switch (parseInstructionWithLabel()) {
            case Success(r):
                consumeComment();
                return Success(r);
            case Unmatched(message):
                return Unmatched(message);
        }
    }

    function parseInstructionWithLabel():ParseResult<Instruction> {
        final beforeTokens = tokens.copy();

        final label:Nullable<String> = switch (parseLabel()) {
            case Success(r):
                r;
            case Unmatched(message):
                if (consumeLeadSpace()) {
                    null;
                } else {
                    return Unmatched("先頭にラベルかスペースが必要です.");
                }
        }
        return parseInstruction(label);
    }

    function parseInstruction(label:Nullable<String>):ParseResult<Instruction> {
        final beforeTokens = tokens.copy();

        final mnemonic = switch (parseMMnemonic()) {
            case Success(r):
                r;
            case Unmatched(message):
                switch (parseAInstruction()) {
                    case Success(r):
                        return Success(Assembler({
                            label: label,
                            mnemonic: r,
                        }));
                    case Unmatched(message):
                        return Unmatched(message);
                }
        }
        final operand:Operand = switch (parseOpreand()) {
            case Success(r):
                r;
            case Unmatched(message):
                tokens = beforeTokens;
                return Unmatched("最後にはNオペランドとして降ってくるので到達しないはず.");
        }
        return Success(Machine({
            label: label,
            mnemonic: mnemonic,
            operand: operand,
        }));
    }

    function parseAInstruction() {
        for (fn in [
            parseStartInstruction,
            parseEndInstruction,
            parseDSInstruction,
            parseDCInstruction,
            parseInOutInstruction,
            parseRStackInstruction
        ]) {
            switch (fn()) {
                case Success(r):
                    return Success(r);
                case Unmatched(message):
            }
        }
        return Unmatched("");
    }

    function parseStartInstruction():ParseResult<AMnemonic> {
        if (!consumeStartMnemonic()) {
            return Unmatched("");
        }

        return switch (parseStartOperand()) {
            case Success(r):
                Success(START(r));
            case Unmatched(message):
                Success(START());
        }
    }

    function parseEndInstruction():ParseResult<AMnemonic> {
        return if (consumeEndMnemonic()) {
            Success(END);
        } else {
            Unmatched("");
        }
    }

    function parseDSInstruction():ParseResult<AMnemonic> {
        if (!consumeDSMnemonic()) {
            return Unmatched("");
        }

        return switch (parseDSOperand()) {
            case Success(r):
                Success(DS(r));
            case Unmatched(message):
                Unmatched(message);
        }
    }

    function parseDCInstruction():ParseResult<AMnemonic> {
        if (!consumeDCMnemonic()) {
            return Unmatched("");
        }

        return switch (parseDCOperand()) {
            case Success(r):
                Success(DC(r));
            case Unmatched(message):
                Unmatched(message);
        }
    }

    function parseInOutInstruction():ParseResult<AMnemonic> {
        final inout = if (consumeInMnemonic()) {
            "in";
        } else if (consumeOutMnemonic()) {
            "out";
        } else return Unmatched("");

        return switch (parseInOutOperand()) {
            case Success(r):
                if (inout == "in") {
                    Success(IN(r.value1, r.value2));
                } else if (inout == "out") {
                    Success(OUT(r.value1, r.value2));
                } else {
                    Unmatched("到達しないはず.");
                }
            case Unmatched(message):
                Unmatched(message);
        }
    }

    function parseRStackInstruction():ParseResult<AMnemonic> {
        if (consumeRPushMnemonic()) {
            return Success(RPUSH);
        }
        if (consumeRPopMnemonic()) {
            return Success(RPOP);
        }
        return Unmatched("");
    }

    function parseMMnemonic():ParseResult<MMnemonic> {
        final token:Nullable<TokenInfo> = tokens[0];

        return token.fold(() -> Unmatched(""), token -> {
            switch (token.token) {
                case Mnemonic(mnemonic):
                    final mnemonic = try {
                        mnemonicTokenToMMnemonic(mnemonic);
                    } catch (e:Exception) {
                        return Unmatched("");
                    }
                    tokens = tokens.slice(1);
                    return Success(mnemonic);
                case _:
                    return Unmatched("");
            }
        });
    }

    function parseOpreand():ParseResult<Operand> {
        switch (parseROperand()) {
            case Success(r):
                return Success(R(r));
            case Unmatched(message):
        }
        switch (parseIOperand()) {
            case Success(r):
                return Success(I(r));
            case Unmatched(message):
        }
        switch (parseJOperand()) {
            case Success(r):
                return Success(J(r));
            case Unmatched(message):
        }
        switch (parsePOperand()) {
            case Success(r):
                return Success(P(r));
            case Unmatched(message):
        }
        return Success(N);
    }

    function parseROperand():ParseResult<ROperand> {
        final beforeTokens = tokens.copy();
        final r1 = switch (parseR()) {
            case Success(r):
                r;
            case Unmatched(message):
                return Unmatched(message);
        }
        if (!consumeComma()) {
            tokens = beforeTokens;
            return Unmatched(", が必要です.");
        }
        final r2 = switch (parseR()) {
            case Success(r):
                r;
            case Unmatched(message):
                tokens = beforeTokens;
                return Unmatched("レジスタを指定してください.");
        }
        return Success({
            r1: r1,
            r2: r2
        });
    }

    function parseIOperand():ParseResult<IOperand> {
        final beforeTokens = tokens.copy();
        final r1 = switch (parseR()) {
            case Success(r):
                r;
            case Unmatched(message):
                return Unmatched(message);
        }
        if (!consumeComma()) {
            tokens = beforeTokens;
            return Unmatched(", が必要です.");
        }
        final addr = switch (parseAddr()) {
            case Success(r):
                r;
            case Unmatched(message):
                tokens = beforeTokens;
                return Unmatched("アドレスを指定してください.");
        }
        if (consumeComma()) {
            switch (parseR()) {
                case Success(r):
                    if (r == 0) {
                        tokens = beforeTokens;
                        return Unmatched("GR0をインデックスレジスタとして指定できません.");
                    } else {
                        return Success({
                            r: r1,
                            addr: addr,
                            x: new I1to7(r)
                        });
                    }
                case Unmatched(message):
                    tokens = beforeTokens;
                    return Unmatched("レジスタを指定してください.");
            }
        } else {
            return Success({
                r: r1,
                addr: addr,
            });
        }
    }

    function parseJOperand():ParseResult<JOperand> {
        final beforeTokens = tokens.copy();

        final addr = switch (parseAddr()) {
            case Success(r):
                r;
            case Unmatched(message):
                tokens = beforeTokens;
                return Unmatched("アドレスを指定してください.");
        }
        if (consumeComma()) {
            switch (parseR()) {
                case Success(r):
                    if (r == 0) {
                        tokens = beforeTokens;
                        return Unmatched("GR0をインデックスレジスタとして指定できません.");
                    } else {
                        return Success({
                            addr: addr,
                            x: new I1to7(r)
                        });
                    }
                case Unmatched(message):
                    tokens = beforeTokens;
                    return Unmatched("レジスタを指定してください.");
            }
        } else {
            return Success({
                addr: addr,
            });
        }
    }

    function parsePOperand():ParseResult<POperand> {
        final beforeTokens = tokens.copy();
        final r1 = switch (parseR()) {
            case Success(r):
                r;
            case Unmatched(message):
                return Unmatched(message);
        }
        return Success({
            r: r1,
        });
    }

    function parseStartOperand():ParseResult<String> {
        return parseLabel();
    }

    function parseDSOperand():ParseResult<Word> {
        return parseDec();
    }

    function parseDCOperand():ParseResult<Array<Word>> {
        final beforeTokens = tokens.copy();

        var operands = [];
        while (true) {
            switch (parseConstant()) {
                case Success(r):
                    operands = operands.concat(r);
                case Unmatched(message):
                    tokens = beforeTokens;
                    Unmatched("定数を指定してください.");
            }
            if (consumeComma()) {
                continue;
            } else {
                break;
            }
        }

        return if (operands.length == 0) {
            Unmatched("");
        } else {
            Success(operands);
        }
    }

    function parseInOutOperand():ParseResult<Tuple2<String, String>> {
        final beforeTokens = tokens.copy();
        final bufferLabel = switch (parseLabel()) {
            case Success(r):
                r;
            case Unmatched(message):
                return Unmatched(message);
        }
        if (!consumeComma()) {
            tokens = beforeTokens;
            return Unmatched(", が必要です.");
        }
        final lengthBufferLabel = switch (parseLabel()) {
            case Success(r):
                r;
            case Unmatched(message):
                return Unmatched("ラベルを指定してください.");
        }
        return Success(new Tuple2(bufferLabel, lengthBufferLabel));
    }

    function parseR():ParseResult<I0to7> {
        final token:Nullable<TokenInfo> = tokens[0];

        return token.fold(() -> Unmatched(""), token -> {
            if (token.token.match(R)) {
                tokens = tokens.slice(1);
                return Success(new I0to7(Std.parseInt(token.src.charAt(2))));
            }
            return Unmatched("");
        });
    }

    function parseAddr():ParseResult<AAddr> {
        switch (parseLabel()) {
            case Success(r):
                return Success(Label(r));
            case Unmatched(message):
        }
        switch (parseNumberConstant()) {
            case Success(r):
                return Success(Constant(r));
            case Unmatched(message):
        }
        switch (parseLiteral()) {
            case Success(r):
                return Success(Literal(r));
            case Unmatched(message):
        }
        return Unmatched("");
    }

    function parseLabel():ParseResult<String> {
        final token:Nullable<TokenInfo> = tokens[0];

        return token.fold(() -> Unmatched(""), token -> {
            if (token.token.match(Label)) {
                tokens = tokens.slice(1);
                return Success(token.src);
            }
            return Unmatched("");
        });
    }

    function parseConstant():ParseResult<Array<Word>> {
        return switch (parseNumberConstant()) {
            case Success(r):
                Success([r]);
            case Unmatched(message):
                switch (parseString()) {
                    case Success(r):
                        Success(r);
                    case Unmatched(message):
                        Unmatched("");
                }
        }
    }

    function parseNumberConstant():ParseResult<Word> {
        return switch (parseDec()) {
            case Success(r):
                Success(r);
            case Unmatched(message):
                switch (parseHex()) {
                    case Success(r):
                        Success(r);
                    case Unmatched(message):
                        Unmatched("");
                }
        }
    }

    function parseDec():ParseResult<Word> {
        final token:Nullable<TokenInfo> = tokens[0];

        return token.fold(() -> Unmatched(""), token -> {
            if (token.token.match(Dec)) {
                tokens = tokens.slice(1);
                return Success(new Word(Std.parseInt(token.src)));
            }
            return Unmatched("");
        });
    }

    function parseHex():ParseResult<Word> {
        final token:Nullable<TokenInfo> = tokens[0];

        return token.fold(() -> Unmatched(""), token -> {
            if (token.token.match(Hex)) {
                tokens = tokens.slice(1);
                return Success(new Word(Std.parseInt(token.src.replace("#", "0x"))));
            }
            return Unmatched("");
        });
    }

    function parseString():ParseResult<Array<Word>> {
        final token:Nullable<TokenInfo> = tokens[0];

        return token.fold(() -> Unmatched(""), token -> {
            if (token.token.match(String)) {
                tokens = tokens.slice(1);
                return Success(strToWords(getStringValue(token.src)).map(i -> new Word(i)));
            }
            return Unmatched("");
        });
    }

    function parseLiteral():ParseResult<Array<Word>> {
        for (fn in [parseDecLiteral, parseHexLiteral, parseStringLiteral]) {
            switch (fn()) {
                case Success(r):
                    return Success(r);
                case Unmatched(message):
            }
        }
        return Unmatched("");
    }

    function parseDecLiteral():ParseResult<Array<Word>> {
        final token:Nullable<TokenInfo> = tokens[0];

        return token.fold(() -> Unmatched(""), token -> {
            if (token.token.match(DecLiteral)) {
                tokens = tokens.slice(1);
                return Success([new Word(Std.parseInt(token.src.substr(1)))]);
            }
            return Unmatched("");
        });
    }

    function parseHexLiteral():ParseResult<Array<Word>> {
        final token:Nullable<TokenInfo> = tokens[0];

        return token.fold(() -> Unmatched(""), token -> {
            if (token.token.match(HexLiteral)) {
                tokens = tokens.slice(1);
                return Success([new Word(Std.parseInt(token.src.replace("=#", "0x")))]);
            }
            return Unmatched("");
        });
    }

    function parseStringLiteral():ParseResult<Array<Word>> {
        final token:Nullable<TokenInfo> = tokens[0];

        return token.fold(() -> Unmatched(""), token -> {
            if (token.token.match(StringLiteral)) {
                tokens = tokens.slice(1);
                return Success(strToWords(getStringLiteralValue(token.src)).map(i -> new Word(i)));
            }
            return Unmatched("");
        });
    }

    function consumeToken(match:Token) {
        final token:Nullable<TokenInfo> = tokens[0];

        return token.fold(() -> false, token -> {
            if (token.token.equals(match)) {
                tokens = tokens.slice(1);
                return true;
            }
            return false;
        });
    }

    function consumeStartMnemonic():Bool {
        return consumeToken(Mnemonic(START));
    }

    function consumeEndMnemonic():Bool {
        return consumeToken(Mnemonic(END));
    }

    function consumeDSMnemonic():Bool {
        return consumeToken(Mnemonic(DS));
    }

    function consumeDCMnemonic():Bool {
        return consumeToken(Mnemonic(DC));
    }

    function consumeInMnemonic():Bool {
        return consumeToken(Mnemonic(IN));
    }

    function consumeOutMnemonic():Bool {
        return consumeToken(Mnemonic(OUT));
    }

    function consumeRPushMnemonic():Bool {
        return consumeToken(Mnemonic(RPUSH));
    }

    function consumeRPopMnemonic():Bool {
        return consumeToken(Mnemonic(RPOP));
    }

    function consumeComment():Bool {
        return consumeToken(Comment);
    }

    function consumeComma():Bool {
        return consumeToken(Comma);
    }

    function consumeLeadSpace():Bool {
        return consumeToken(LeadSpace);
    }

    static function mnemonicTokenToMMnemonic(token:MnemonicToken):MMnemonic {
        return switch (token) {
            case LD:
                LD;
            case ST:
                ST;
            case LAD:
                LAD;
            case ADDA:
                ADDA;
            case ADDL:
                ADDL;
            case SUBA:
                SUBA;
            case SUBL:
                SUBL;
            case AND:
                AND;
            case OR:
                OR;
            case XOR:
                XOR;
            case CPA:
                CPA;
            case CPL:
                CPL;
            case SLA:
                SLA;
            case SRA:
                SRA;
            case SLL:
                SLL;
            case SRL:
                SRL;
            case JPL:
                JPL;
            case JMI:
                JMI;
            case JNZ:
                JNZ;
            case JZE:
                JZE;
            case JUMP:
                JUMP;
            case JOV:
                JOV;
            case PUSH:
                PUSH;
            case POP:
                POP;
            case CALL:
                CALL;
            case RET:
                RET;
            case SVC:
                SVC;
            case NOP:
                NOP;
            case _:
                throw new Exception("");
        }
    }

    static function getStringValue(s:String) {
        return s.substring(1, s.length - 1);
    }

    static function getStringLiteralValue(s:String) {
        return s.substring(2, s.length - 1);
    }

    static function strToWords(s:String) {
        final sjis = [];
        for (c in new StringIteratorUnicode(s)) {
            final sjisChar = Nullable.of(SjisUnicodeTable.unicodeToSjis.get(c));
            // TODO: error なり warning を上げる
            // sjis.push(sjisChar.getOrThrow(() -> new Exception('使用できない文字です. U+${c.hex()}')));
            sjis.push(sjisChar.getOrElse(32));
        }
        return sjis;
    }
}

enum ParseResult<T> { // TODO: src内での位置も持つ
    Success(r:T);
    Unmatched(message:String);
}
