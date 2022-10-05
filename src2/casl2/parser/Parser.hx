package casl2.parser;

import casl2.parser.AstDefinition.InstructionType;
import casl2.parser.AstDefinition.LabeledInstruction;
import casl2.parser.ParseResult.ParseError;
import casl2.parser.ParseResult.ParseResultTools;
import casl2.tokenizer.TokenDefinition.TokenInfo;
import casl2.tokenizer.TokenDefinition.TokenList;
import extype.Maybe;
import extype.Nullable;
import extype.ReadOnlyArray;
import haxe.iterators.StringKeyValueIteratorUnicode;
import types.FilePosition;
import types.Integer.Word;

using tools.ArrayTools;

class Parser {
    final tokens:Array<TokenInfo>;
    var p:Int;

    public function new(lineTokens:ReadOnlyArray<TokenInfo>) {
        this.tokens = lineTokens.copy();
        this.p = 0;
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
                        len: 1
                    };
                    Error(null, x.position, [Fail(position, "先頭はインデントかラベルが必要です.")]);
                }
            case None:
                throw 'unreachable';
        }
    }

    function parseInstruction():ParseResult<InstructionType> {
    }

    // function parseNMnemonic():ParseResult<NMnemonic> {
    //     final
    // }

    static function isComment(token:Null<TokenInfo>) {
        return token != null && token.token.match(Comment);
    }

    static function isLeadSpace(token:Null<TokenInfo>) {
        return token != null && token.token.match(LeadSpace);
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
            Some(tokens[p++]);
        } else {
            None;
        }
    }

    function remainLength() {
        return tokens.length - p;
    }
}
