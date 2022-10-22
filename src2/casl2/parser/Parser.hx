package casl2.parser;

import casl2.parser.AstDefinition.InstructionType;
import casl2.parser.AstDefinition.LabeledInstruction;
import casl2.parser.AstDefinition.ROperand;
import casl2.parser.ParseResult.ParseError;
import casl2.parser.ParseResult.ParseResultTools;
import casl2.tokenizer.TokenDefinition.InstTokenList;
import casl2.tokenizer.TokenDefinition.MnemonicToken;
import casl2.tokenizer.TokenDefinition.TokenInfo;
import casl2.tokenizer.TokenDefinition.TokenList;
import extype.Error;
import extype.Maybe;
import extype.Nullable;
import extype.ReadOnlyArray;
import extype.Result;
import haxe.iterators.StringKeyValueIteratorUnicode;
import types.FilePosition;
import types.Integer.GRIndex;
import types.Integer.IRIndex;
import types.Integer.Word;

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
        final errors:Array<ParseError> = [];

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

        return ParseResultTools.merge(label, inst, (label, inst) -> {
            return ({
                label: label.getUnsafe(),
                inst: inst,
            } : LabeledInstruction);
        });
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
                        line: x.position.line,
                        col: 0,
                    };
                    Error(null, x.position, [Fail(position, "先頭はインデントかラベルが必要です.")]);
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
                        final pos:FilePosition = {
                            line: x.position.line,
                            col: x.position.col,
                        }
                        Error(null, pos, [Fail(pos, "命令が必要です.")]);
                }
            case None:
                Error(null, lineEndPosition, [Fail(lineEndPosition, "命令が必要です.")]);
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
        final errors:Array<ParseError> = [];
        switch (next()) {
            case Some(x):
            case None:
                return Error(null, lineEndPosition, [Fail(lineEndPosition, "オペランドが必要です. (R命令 r1, r2)")]);
        }
    }

    static function isComment(token:Null<TokenInfo>) {
        return token != null && token.token.match(Comment);
    }

    static function isLeadSpace(token:Null<TokenInfo>) {
        return token != null && token.token.match(LeadSpace);
    }

    function parseGR():Maybe<GRIndex> {
        return switch (next()) {
            case Some(x):
                switch (x.token) {
                    case GR:
                        Some(new GRIndex(Std.parseInt(x.src)));
                    default:
                        p--;
                        None;
                }
            case None:
                None;
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
        final warnings:Array<ParseError> = [];

        for (i => c in new StringKeyValueIteratorUnicode(s)) {
            final sjisChar = Nullable.of(SjisUnicodeTable.unicodeToSjis.get(c));
            switch (sjisChar.toMaybe()) {
                case Some(x):
                    sjis.push(new Word(x));
                case None:
                    warnings.push(Warning({col: pos.col + i, line: pos.line, len: 1}, '使用できない文字です (${std.String.fromCharCode(c)}) .'));
                    sjis.push(new Word(0));
            }
        }

        return if (warnings.length == 0) {
            Success(sjis, pos);
        } else {
            Error(sjis, pos, warnings);
        }
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
}
