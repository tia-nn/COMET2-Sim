package;

import haxe.io.Bytes;
import parser.Instruction;
import parser.Parser;
import parser.Preprocessor;
import parser.Tokenizer;
import parser.TracePreprocessed.PreprocessedTools;
import parser.Validator;
import sys.io.File;

class Main {
    static function main() {
        final bytes = File.read("all.casl").readAll();
        final src = bytes.getString(0, bytes.length, UTF8);

        final tokens = Tokenizer.tokenize(src);
        final node = Parser.parse(tokens);
        final validated = Validator.validate(node);
        trace(validated.filter(v -> v.match(Error(_))));
        trace(validated.filter(v -> v.match(Success(_))));
        final instructions:Array<Instruction> = validated.filter(v -> v.match(Success(_))).map(v -> v.getParameters()[0]);
        final instructions = Preprocessor.preprocess(instructions);
        trace(instructions);

        File.write("dump.casl", false).write(Bytes.ofString(PreprocessedTools.toString(instructions.instructions, instructions.startLabel)));
    }
}
