package casl2.parser;

import casl2.parser.AstDefinition.Addr;
import casl2.parser.AstDefinition.IOperand;
import casl2.parser.AstDefinition.InstructionType;
import casl2.parser.AstDefinition.LabeledInstruction;
import casl2.parser.AstDefinition.ROperand;
import casl2.tokenizer.TokenDefinition.InstTokenList;
import casl2.tokenizer.TokenDefinition.MnemonicToken;
import casl2.tokenizer.TokenDefinition.Token;
import casl2.tokenizer.TokenDefinition.TokenInfo;
import casl2.tokenizer.TokenDefinition.TokenList;
import extype.Maybe;
import extype.Nullable;
import extype.ReadOnlyArray;
import extype.Result;
import haxe.display.Position;
import haxe.io.Error;
import haxe.iterators.StringKeyValueIteratorUnicode;
import haxe.macro.Context.Message;
import haxe.macro.Expr.Case;
import types.FilePosition;
import types.Integer.GRIndex;
import types.Integer.IRIndex;
import types.Integer.Word;

using StringTools;
using tools.ArrayTools;

class Parser {
    final tokens:Array<TokenInfo>;
    var p:Int;
    final line:Int;
    final lineEndPosition:FilePosition;

    public function new(lineTokens:InstTokenList) {
        this.tokens = lineTokens.copy();
        this.p = 0;
        this.line = (tokens[0] : Nullable<TokenInfo>).fold(() -> 0, t -> t.position.line);
        lineEndPosition = {
            line: line,
            col: -1,
        }
    }

    public static function parse(tokens:TokenList) {
        final parsedRows:Array<ParseResult<LabeledInstruction>> = [];

        for (instTokens in tokens) {
            final parser = new Parser(instTokens);
            parser.parseRow().iter(parsedRows.push);
        }

        return parsedRows;
    }

    function parseRow():Nullable<ParseResult<LabeledInstruction>> {
        return if (tokens.length == 0 || isComment(tokens[0]) || (isLeadSpace(tokens[0]) && isComment(tokens[0]))) {
            // 空行 || コメント行
            null;
        } else {
            parseInstructionWithLabel();
        }
    }

    function parseInstructionWithLabel():ParseResult<LabeledInstruction> {
        final label = parseLableOrLeadSpace();
        final inst = parseInstruction();

        // return ParseResultTools.merge(label, inst, (label, inst) -> {
        //     return ({
        //         label: label.getUnsafe(),
        //         inst: inst,
        //     } : LabeledInstruction);
        // });
    }

    function parseLableOrLeadSpace():ParseResult<Nullable<String>> {
        return switch (next()) {
            case Some(x):
                if (x.token.match(Label)) {
                    Success(x.src, x.position);
                } else if (isLeadSpace(x)) {
                    Success(null, x.position);
                } else {
                    p--;
                    final position:FilePosition = {
                        line: line,
                        col: 0,
                    };
                    Warning(null, position, "先頭はインデントかラベルが必要です.");
                }
            case None:
                throw 'unreachable';
        }
    }

    function parseInstruction():ParseResult<InstructionType> {
        return switch (next()) {
            case Some(x):
                switch (x.token) {
                    case Mnemonic(mnemonic):
                        return _parseInstruction(mnemonic);
                    default:
                        Error(x.position, "命令が必要です.");
                }
            case None:
                Error(lineEndPosition, "命令が必要です.");
        }
    }

    function _parseInstruction(mnemonic:MnemonicToken):ParseResult<InstructionType> {
        switch (mnemonic) {
            // R/I
            case LD, ADDA, ADDL, SUBA, SUBL, AND, OR, XOR, CPA, CPL:

            // I
            case ST, LAD, SLA, SRA, SLL, SRL:
            // J
            case JPL, JMI, JNZ, JZE, JOV, JUMP, PUSH, CALL, SVC, INT:
            // P
            case POP:
            // N
            case RET, NOP, IRET:
            // ASM
            case START, END, DS, DC, IN, OUT, RPUSH, RPOP:
        }
    }

    function parseROperand():ParseResult<ROperand> {
        var position;
        final r1 = switch (next()) {
            case Some(x):
                switch (x.token) {
                    case GR:
                        position = x.position;
                        new GRIndex(Std.parseInt(x.src));
                    default:
                        return Error(x.position, "オペランドが間違っています. (R命令 r1, r2)");
                }
            case None:
                return Error(lineEndPosition, "オペランドが必要です. (R命令 r1, r2)");
        }

        switch (consumeToken(Comma, "コンマが必要です. (R命令 r1, r2)")) {
            case Success(value):
            case Failure(err):
                return err;
        }

        final r2 = switch (next()) {
            case Some(x):
                switch (x.token) {
                    case GR:
                        position = {
                            line: position.line,
                            col: position.col,
                            len: x.position.col + x.position.len.getOrElse(0) - position.col
                        }
                        new GRIndex(Std.parseInt(x.src));
                    default:
                        return Error(x.position, "オペランドが間違っています. (R命令 r1, r2)");
                }
            case None:
                return Error(lineEndPosition, "オペランドが必要です. (R命令 r1, r2)");
        }

        return Success({r1: r1, r2: r2}, position);
    }

    function parseIOperand():ParseResult<IOperand> {
        var position;
        final r = switch (next()) {
            case Some(x):
                switch (x.token) {
                    case GR:
                        position = x.position;
                        new GRIndex(Std.parseInt(x.src));
                    default:
                        return Error(x.position, "オペランドが間違っています. (I命令 r, addr [, x])");
                }
            case None:
                return Error(lineEndPosition, "オペランドが必要です. (I命令 r, addr [, x])");
        }

        switch (consumeToken(Comma, "コンマが必要です. (I命令 r, addr [, x])")) {
            case Success(value):
            case Failure(err):
                return err;
        }

        final addr = switch (parseAddr()) {
            case Success(result, position):
            case Error(position, message):
            case Warning(tmpResult, position, message):
        }

        final r2 = switch (next()) {
            case Some(x):
                switch (x.token) {
                    case GR:
                        position = {
                            line: position.line,
                            col: position.col,
                            len: x.position.col + x.position.len.getOrElse(0) - position.col
                        }
                        new GRIndex(Std.parseInt(x.src));
                    default:
                        return Error(x.position, "オペランドが間違っています. (R命令 r1, r2)");
                }
            case None:
                return Error(lineEndPosition, "オペランドが必要です. (R命令 r1, r2)");
        }

        return Success({r1: r1, r2: r2}, position);
    }

    static function isComment(token:Null<TokenInfo>) {
        return token != null && token.token.match(Comment);
    }

    static function isLeadSpace(token:Null<TokenInfo>) {
        return token != null && token.token.match(LeadSpace);
    }

    function parseGR():Result<GRIndex, Maybe<FilePosition>> {
        return switch (next()) {
            case Some(x):
                switch (x.token) {
                    case GR:
                        Success(new GRIndex(Std.parseInt(x.src)));
                    default:
                        p--;
                        Failure(Some(x.position));
                }
            case None:
                Failure(None);
        }
    }

    function parseIR():Maybe<Result<IRIndex, String>> {
        return switch (next()) {
            case Some(x):
                switch (x.token) {
                    case GR:
                        if (x.src == '0') {
                            Some(Failure("指標レジスタに GR0 を指定できません."));
                        } else {
                            Some(Success(new IRIndex(Std.parseInt(x.src))));
                        }
                    default:
                        p--;
                        None;
                }
            case None:
                None;
        }
    }

    function parseAddr(?errMessage:String = "アドレスが必要です."):ParseResult<Addr> {
        return select([
            wrapResult.bind(parseLabel.bind(), a -> Addr.Label(a)),
            wrapResult.bind(parseNumberConstant.bind(), a -> Addr.Const(a)),
            wrapResult.bind(parseLiteral.bind(), a -> Addr.Literal(a)),
        ], errMessage);
    }

    function parseLabel(?errMessage:String = ""):ParseResult<String> {
        return switch (next()) {
            case Some(x):
                switch (x.token) {
                    case Label:
                        Success(x.src, x.position);
                    default:
                        Error(x.position, errMessage);
                }
            case None:
                Error(lineEndPosition, errMessage);
        }
    }

    function parseNumberAddr(?errMessage:String = ""):ParseResult<Addr> {
        return switch (parseLabel(errMessage)) {
            case Success(result, position):
                Success(Label(result), position);
            case Error(position, message):
                return Error(position, message);
            case Warning(tmpResult, position, message):
                Warning(Label(tmpResult), position, message);
        }
    }

    function parseNumberConstant(?errMessage:String = "数値が必要です.") {
        return select([parseDec.bind(errMessage), parseHex.bind(errMessage)], errMessage);
    }

    function parseDec(?errMessage:String = "数値が必要です."):ParseResult<Word> {
        return switch (next()) {
            case Some(x):
                switch (x.token) {
                    case Dec:
                        Success(new Word(Std.parseInt(x.src)), x.position);
                    default:
                        Error(x.position, errMessage);
                }
            case None:
                Error(lineEndPosition, errMessage);
        }
    }

    function parseHex(?errMessage:String = "数値が必要です."):ParseResult<Word> {
        return switch (next()) {
            case Some(x):
                switch (x.token) {
                    case Dec:
                        Success(new Word(Std.parseInt(x.src.replace("#", "0x"))), x.position);
                    default:
                        Error(x.position, errMessage);
                }
            case None:
                Error(lineEndPosition, errMessage);
        }
    }

    function parseLiteral(?errMessage:String = "リテラルが必要です."):ParseResult<ReadOnlyArray<Word>> {
        return select([parseDecLiteral.bind(), parseHexLiteral.bind(), parseStringLiteral.bind()], errMessage);
    }

    function parseDecLiteral(?errMessage:String = "リテラルが必要です."):ParseResult<ReadOnlyArray<Word>> {
        return switch (next()) {
            case Some(x):
                switch (x.token) {
                    case DecLiteral:
                        return Success([new Word(Std.parseInt(x.src.substr(1)))], x.position);
                    default:
                        Error(x.position, errMessage);
                }
            case None:
                Error(lineEndPosition, errMessage);
        }
    }

    function parseHexLiteral(?errMessage:String = "リテラルが必要です."):ParseResult<ReadOnlyArray<Word>> {
        return switch (next()) {
            case Some(x):
                switch (x.token) {
                    case DecLiteral:
                        return Success([new Word(Std.parseInt(x.src.replace("=#", "0x")))], x.position);
                    default:
                        Error(x.position, errMessage);
                }
            case None:
                Error(lineEndPosition, errMessage);
        }
    }

    function parseStringLiteral(?errMessage:String = "リテラルが必要です."):ParseResult<ReadOnlyArray<Word>> {
        return switch (next()) {
            case Some(x):
                switch (x.token) {
                    case DecLiteral:
                        str2words(getStringLiteralValue(x.src), x.position);
                    default:
                        Error(x.position, errMessage);
                }
            case None:
                Error(lineEndPosition, errMessage);
        }
    }

    /**
        文字列('hogehoge')の中身(hogehoge)を取り出す
    **/
    static function getStringValue(s:String) {
        return s.substring(1, s.length - 1);
    }

    /**
        文字列リテラル(='hogehoge')の中身(hogehoge)を取り出す
    **/
    static function getStringLiteralValue(s:String) {
        return s.substring(2, s.length - 1);
    }

    /**
        ソースファイル上の文字列(UTF-8)をSift-JIS文字コード配列に変換する
    **/
    static function str2words(s:String, pos:FilePosition):ParseResult<ReadOnlyArray<Word>> {
        final sjis:Array<Word> = [];
        final warnings:Array<String> = [];

        for (i => c in new StringKeyValueIteratorUnicode(s)) {
            final sjisChar = Nullable.of(SjisUnicodeTable.unicodeToSjis.get(c));
            switch (sjisChar.toMaybe()) {
                case Some(x):
                    sjis.push(new Word(x));
                case None:
                    warnings.push(std.String.fromCharCode(c));
                    sjis.push(new Word(0));
            }
        }

        return if (warnings.length == 0) {
            Success(sjis, pos);
        } else {
            Warning(sjis, pos, '使用できない文字が含まれています. (${warnings.join(",")})');
        }
    }

    function consumeToken<A>(match:Token, errMessage:String):Result<TokenInfo, ParseResult<A>> {
        return switch (next()) {
            case Some(x):
                if (x.token.equals(match)) {
                    Success(x);
                } else {
                    p--;
                    Failure(Error(x.position, errMessage));
                }
            default:
                Failure(Error(lineEndPosition, errMessage));
        }
    }

    function select<A>(fnArr:Array<() -> ParseResult<A>>, errMessage:String) {
        final lastP = p;
        var lastErrPosition = null;
        for (fn in fnArr) {
            final res = fn();
            switch (res) {
                case Success(_), Warning(_):
                    return res;
                case Error(position, message):
                    lastErrPosition = position;
                    p = lastP;
            }
        }
        return Error(lastErrPosition, errMessage);
    }

    function next():Maybe<TokenInfo> {
        return if (tokens[p] != null) {
            if (tokens[p].position.line != line) {
                throw "違う行のトークンが混在しています.";
            }
            Some(tokens[p++]);
        } else {
            None;
        }
    }

    function remainLength() {
        return tokens.length - p;
    }

    static function wrapResult<A, B>(fn:() -> ParseResult<A>, wrapper:A->B):ParseResult<B> {
        return switch (fn()) {
            case Success(result, position):
                Success(wrapper(result), position);
            case Error(position, message):
                return Error(position, message);
            case Warning(tmpResult, position, message):
                Warning(wrapper(tmpResult), position, message);
        }
    }
}
