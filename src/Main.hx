package;

import parser.Parser;
import sys.io.File;
import tokenizer.Tokenizer;

class Main {
    static function main() {
        final bytes = File.read("error.casl").readAll();
        final src = bytes.getString(0, bytes.length, UTF8);

        final tokens = Tokenizer.tokenize(src);
        final node = Parser.parse(tokens);

        switch (node) {
            case Success(r, w):
                trace(r.join("\n"));
                trace(w.join("\n"));
            case Failed(e, w):
                trace(e.join("\n"));
                trace(w.join("\n"));
        }

        // final validated = Validator.validate(node);
        // final instructions:Array<VInstruction> = validated.filter(v -> v.match(Success(_))).map(v -> v.getParameters()[0]);
        // final instructions = Preprocessor.preprocess(instructions);

        // File.write("dump.casl", false).write(Bytes.ofString(PInstOrDataTraceTools.toString(instructions.instructions, instructions.startLabel)));

        // final assembly = assembler.Assembler.assembleAll(instructions.instructions);
        // trace(assembly.map(a -> a.toString("")));

        // final machine = new Comet2(assembly, 0);
        // while (!machine.step()) {
        // }

        // trace(machine.state);
    }
}
