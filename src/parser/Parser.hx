package parser;

import Word.I0to7;
import Word.I1to7;
import extype.Exception;
import extype.Nullable;
import extype.Tuple.Tuple2;
import haxe.iterators.StringKeyValueIteratorUnicode;
import parser.InstructionDefinition.AInstruction;
import parser.InstructionDefinition.IMnemonic;
import parser.InstructionDefinition.JMnemonic;
import parser.InstructionDefinition.NMnemonic;
import parser.InstructionDefinition.PMnemonic;
import parser.InstructionDefinition.ParseReport;
import parser.InstructionDefinition.ParsedAddr;
import parser.InstructionDefinition.ParsedIOperand;
import parser.InstructionDefinition.ParsedInstruction;
import parser.InstructionDefinition.ParsedInstructionWithLabel;
import parser.InstructionDefinition.ParsedInstructionWithLine;
import parser.InstructionDefinition.ParsedJOperand;
import parser.InstructionDefinition.ParsedPOperand;
import parser.InstructionDefinition.ParsedROperand;
import parser.InstructionDefinition.RMnemonic;
import parser.InstructionDefinition.WithCol;
import parser.InstructionDefinition.WithPos;
import tokenizer.TokenDefinition.Token;
import tokenizer.TokenDefinition.TokenInfo;

using Lambda;
using StringTools;

@:allow(Main)
class Parser {
    var tokens:Array<TokenInfo>;
    var lineWarnings:Array<WithCol<String>>;
    var lineErrors:Array<WithCol<String>>;

    function new(tokens:Array<TokenInfo>) {
        this.tokens = tokens;
        this.lineWarnings = [];
        this.lineErrors = [];
    }

    public static function parse(tokens:Array<Array<TokenInfo>>):ParseReport {
        final instructions:Array<ParsedInstructionWithLine> = [];
        final errors:Array<WithPos<String>> = [];
        final warnings:Array<WithPos<String>> = [];
        for (i => instTokens in tokens) {
            final parser = new Parser(instTokens);

            switch (parser.parseRow()) {
                case Success(r):
                    parser.lineWarnings.iter(e -> warnings.push({value: e.value, pos: {line: i, col: e.col}}));
                    parser.lineErrors.iter(e -> errors.push({value: e.value, pos: {line: i, col: e.col}}));
                    r.iter(r -> instructions.push({value: r, line: i}));
                case Unmatched(message):
                    parser.lineWarnings.iter(e -> warnings.push({value: e.value, pos: {line: i, col: e.col}}));
                    parser.lineErrors.iter(e -> errors.push({value: e.value, pos: {line: i, col: e.col}}));
                    errors.push({value: message, pos: {line: i, col: 0}});
            }
        }

        return if (errors.length == 0) {
            Success(instructions, warnings);
        } else {
            Failed(errors, warnings);
        }
    }

    function parseRow():ParseResult<Nullable<ParsedInstructionWithLabel>> {
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

    function parseInstructionWithLabel():ParseResult<ParsedInstructionWithLabel> {
        final beforeTokens = tokens.copy();

        final label:Nullable<String> = switch (parseLabel()) {
            case Success(r):
                r;
            case Unmatched(message):
                if (consumeLeadSpace()) {
                    null;
                } else {
                    analyzeErrorAtParseLabel();
                    null; // ラベル無しとしてパースを続ける.
                }
        }

        final inst = switch (parseInstruction()) {
            case Success(r):
                r;
            case Unmatched(message):
                tokens = beforeTokens;
                return Unmatched(message);
        }

        return Success({
            label: label,
            inst: inst,
        });
    }

    function analyzeErrorAtParseLabel():Bool {
        final tokenTypeUsingAsLabel = switch (tokens[0].token) {
            case Mnemonic(mnemonic):
                '命令名 (${mnemonic.getName()}) ';
            case Comma:
                'コンマ';
            case R:
                'レジスタ名 (${tokens[0].src}) ';
            case Dec, Hex:
                '整数';
            case String:
                '文字列';
            case DecLiteral, HexLiteral, StringLiteral:
                'リテラル';
            case _:
                throw new Exception("unreachable.");
        }

        if (tokens.length == 1) {
            lineErrors.push({value: '${tokenTypeUsingAsLabel}はラベルとして使えません.', col: 0});
            return false;
        }

        switch (tokens[1].token) {
            case Mnemonic(mnemonic):
                lineErrors.push({value: '${tokenTypeUsingAsLabel}はラベルとして使えません.', col: 0});
                tokens = tokens.slice(1);
                return true;
            case _:
                lineWarnings.push({value: "先頭にラベルかスペースが必要です", col: 0});
                return true;
        }
    }

    function parseInstruction():ParseResult<ParsedInstruction> {
        for (fn in [
            parseRInstruction,
            parseIInstruction,
            parseJInstruction,
            parsePInstruction,
            parseNInstruction,
            parseAInstruction,
        ]) {
            switch (fn()) {
                case Success(r):
                    return Success(r);
                case Unmatched(message):
            }
        }
        return Unmatched("命令が必要です.");
    }

    function parseRInstruction():ParseResult<ParsedInstruction> {
        final beforeTokens = tokens.copy();

        final mnemonic = switch (parseRMnemonic()) {
            case Success(r):
                r;
            case Unmatched(message):
                return Unmatched("命令が必要です.");
        }

        final operand = switch (parseROperand()) {
            case Success(r):
                r;
            case Unmatched(message):
                tokens = beforeTokens;
                return Unmatched(message);
        }

        return Success(R({
            mnemonic: mnemonic,
            r1: operand.r1,
            r2: operand.r2,
        }));
    }

    function parseIInstruction():ParseResult<ParsedInstruction> {
        final beforeTokens = tokens.copy();

        final mnemonic = switch (parseIMnemonic()) {
            case Success(r):
                r;
            case Unmatched(message):
                return Unmatched("命令が必要です.");
        }

        final operand = switch (parseIOperand()) {
            case Success(r):
                r;
            case Unmatched(message):
                tokens = beforeTokens;
                return Unmatched(message);
        }

        return Success(I({
            mnemonic: mnemonic,
            r: operand.r,
            addr: operand.addr,
            x: operand.x
        }));
    }

    function parseJInstruction():ParseResult<ParsedInstruction> {
        final beforeTokens = tokens.copy();

        final mnemonic = switch (parseJMnemonic()) {
            case Success(r):
                r;
            case Unmatched(message):
                return Unmatched("命令が必要です.");
        }

        final operand = switch (parseJOperand()) {
            case Success(r):
                r;
            case Unmatched(message):
                tokens = beforeTokens;
                return Unmatched(message);
        }

        return Success(J({
            mnemonic: mnemonic,
            addr: operand.addr,
            x: operand.x
        }));
    }

    function parsePInstruction():ParseResult<ParsedInstruction> {
        final beforeTokens = tokens.copy();

        final mnemonic = switch (parsePMnemonic()) {
            case Success(r):
                r;
            case Unmatched(message):
                return Unmatched("命令が必要です.");
        }

        final operand = switch (parsePOperand()) {
            case Success(r):
                r;
            case Unmatched(message):
                tokens = beforeTokens;
                return Unmatched(message);
        }

        return Success(P({
            mnemonic: mnemonic,
            r: operand.r,
        }));
    }

    function parseNInstruction():ParseResult<ParsedInstruction> {
        final beforeTokens = tokens.copy();

        final mnemonic = switch (parseNMnemonic()) {
            case Success(r):
                r;
            case Unmatched(message):
                return Unmatched("命令が必要です.");
        }

        return Success(N({
            mnemonic: mnemonic,
        }));
    }

    function parseAInstruction():ParseResult<ParsedInstruction> {
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
                    return Success(A(r));
                case Unmatched(message):
            }
        }
        return Unmatched("");
    }

    function parseStartInstruction():ParseResult<AInstruction> {
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

    function parseEndInstruction():ParseResult<AInstruction> {
        return if (consumeEndMnemonic()) {
            Success(END);
        } else {
            Unmatched("");
        }
    }

    function parseDSInstruction():ParseResult<AInstruction> {
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

    function parseDCInstruction():ParseResult<AInstruction> {
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

    function parseInOutInstruction():ParseResult<AInstruction> {
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

    function parseRStackInstruction():ParseResult<AInstruction> {
        if (consumeRPushMnemonic()) {
            return Success(RPUSH);
        }
        if (consumeRPopMnemonic()) {
            return Success(RPOP);
        }
        return Unmatched("");
    }

    function parseROperand():ParseResult<ParsedROperand> {
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

    function parseIOperand():ParseResult<ParsedIOperand> {
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

    function parseJOperand():ParseResult<ParsedJOperand> {
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

    function parsePOperand():ParseResult<ParsedPOperand> {
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

    function parseAddr():ParseResult<ParsedAddr> {
        switch (parseLabel()) {
            case Success(r):
                return Success(Label(r));
            case Unmatched(message):
        }
        switch (parseNumberConstant()) {
            case Success(r):
                return Success(Const(r));
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
                final words = strToWords(getStringLiteralValue(token.src));
                words.warnings.iter(e -> lineWarnings.push({value: e.value, col: e.col + token.col + 1 /* "stringConstant" の " の +1 */}));
                return Success(words.value.map(i -> new Word(i)));
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
                final words = strToWords(getStringLiteralValue(token.src));
                words.warnings.iter(e -> lineWarnings.push({value: e.value, col: e.col + token.col + 2 /* ="stringLiteral" の =" の +2 */}));
                return Success(words.value.map(i -> new Word(i)));
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

    function parseRMnemonic():ParseResult<RMnemonic> {
        final token:Nullable<TokenInfo> = tokens[0];

        final result = token.fold(() -> Unmatched(""), token -> switch (token.token) {
            case Mnemonic(mnemonic):
                switch (mnemonic) {
                    case LD:
                        Success(LD);
                    case ADDA:
                        Success(ADDA);
                    case SUBA:
                        Success(SUBA);
                    case ADDL:
                        Success(ADDL);
                    case SUBL:
                        Success(SUBL);
                    case AND:
                        Success(AND);
                    case OR:
                        Success(OR);
                    case XOR:
                        Success(XOR);
                    case CPA:
                        Success(CPA);
                    case CPL:
                        Success(CPL);
                    case _:
                        Unmatched("");
                }
            case _:
                Unmatched("");
        });

        switch (result) {
            case Success(r):
                tokens = tokens.slice(1);
            case Unmatched(message):
        }

        return result;
    }

    function parseIMnemonic():ParseResult<IMnemonic> {
        final token:Nullable<TokenInfo> = tokens[0];

        final result = token.fold(() -> Unmatched(""), token -> switch (token.token) {
            case Mnemonic(mnemonic):
                switch (mnemonic) {
                    case LD:
                        Success(IMnemonic.LD);
                    case ST:
                        Success(ST);
                    case LAD:
                        Success(LAD);
                    case ADDA:
                        Success(ADDA);
                    case SUBA:
                        Success(SUBA);
                    case ADDL:
                        Success(ADDL);
                    case SUBL:
                        Success(SUBL);
                    case AND:
                        Success(AND);
                    case OR:
                        Success(OR);
                    case XOR:
                        Success(XOR);
                    case CPA:
                        Success(CPA);
                    case CPL:
                        Success(CPL);
                    case SLA:
                        Success(SLA);
                    case SRA:
                        Success(SRA);
                    case SLL:
                        Success(SLL);
                    case SRL:
                        Success(SRL);
                    case _:
                        Unmatched("");
                }
            case _:
                Unmatched("");
        });

        switch (result) {
            case Success(r):
                tokens = tokens.slice(1);
            case Unmatched(message):
        }

        return result;
    }

    function parseJMnemonic():ParseResult<JMnemonic> {
        final token:Nullable<TokenInfo> = tokens[0];

        final result = token.fold(() -> Unmatched(""), token -> switch (token.token) {
            case Mnemonic(mnemonic):
                switch (mnemonic) {
                    case JMI:
                        Success(JMI);
                    case JNZ:
                        Success(JNZ);
                    case JZE:
                        Success(JZE);
                    case JUMP:
                        Success(JUMP);
                    case JPL:
                        Success(JPL);
                    case JOV:
                        Success(JOV);
                    case PUSH:
                        Success(PUSH);
                    case CALL:
                        Success(CALL);
                    case SVC:
                        Success(SVC);
                    case _:
                        Unmatched("");
                }
            case _:
                Unmatched("");
        });

        switch (result) {
            case Success(r):
                tokens = tokens.slice(1);
            case Unmatched(message):
        }

        return result;
    }

    function parsePMnemonic():ParseResult<PMnemonic> {
        final token:Nullable<TokenInfo> = tokens[0];

        final result = token.fold(() -> Unmatched(""), token -> switch (token.token) {
            case Mnemonic(mnemonic):
                switch (mnemonic) {
                    case POP:
                        Success(POP);
                    case _:
                        Unmatched("");
                }
            case _:
                Unmatched("");
        });

        switch (result) {
            case Success(r):
                tokens = tokens.slice(1);
            case Unmatched(message):
        }

        return result;
    }

    function parseNMnemonic():ParseResult<NMnemonic> {
        final token:Nullable<TokenInfo> = tokens[0];

        final result = token.fold(() -> Unmatched(""), token -> switch (token.token) {
            case Mnemonic(mnemonic):
                switch (mnemonic) {
                    case RET:
                        Success(RET);
                    case NOP:
                        Success(NOP);
                    case _:
                        Unmatched("");
                }
            case _:
                Unmatched("");
        });

        switch (result) {
            case Success(r):
                tokens = tokens.slice(1);
            case Unmatched(message):
        }

        return result;
    }

    static function getStringValue(s:String) {
        return s.substring(1, s.length - 1);
    }

    static function getStringLiteralValue(s:String) {
        return s.substring(2, s.length - 1);
    }

    static function strToWords(s:String) {
        final sjis = [];
        final warnings:Array<WithCol<String>> = [];
        for (i => c in new StringKeyValueIteratorUnicode(s)) {
            final sjisChar = Nullable.of(SjisUnicodeTable.unicodeToSjis.get(c));
            switch (sjisChar.toMaybe()) {
                case Some(x):
                    sjis.push(x);
                case None:
                    warnings.push({col: i, value: '使用できない文字です (${std.String.fromCharCode(c)}). \\0 として扱います.'});
                    sjis.push(sjisChar.getOrElse(0));
            }
        }
        return {value: sjis, warnings: warnings};
    }
}

enum ParseResult<T> {
    Success(r:T);
    Unmatched(message:String);
}
