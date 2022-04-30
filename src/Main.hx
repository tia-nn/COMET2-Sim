package;

import assembler.Assembler;
import machine.Comet2;
import parser.Parser;
import preprocessor.Preprocessor;
import preprocessor.StartEndChecker;
import sys.io.File;
import tokenizer.Tokenizer;

class Main {
    static function main() {
        final bytes = File.read("test.casl").readAll();
        final src = bytes.getString(0, bytes.length, UTF8);

        final tokens = Tokenizer.tokenize(src);
        final node = Parser.parse(tokens);

        final node = switch (node) {
            case Success(r, w):
                trace(r.join("\n"));
                trace(w.join("\n"));
                r;
            case Failed(e, w):
                trace(e.join("\n"));
                trace(w.join("\n"));
                return;
        }

        final errors = StartEndChecker.check(node);
        switch (errors) {
            case []:
            case _:
                trace(errors.join("\n"));
                return;
        }

        final object = Preprocessor.preprocess(node);

        trace("start at ", object.startLabel);
        trace(object.instructions.join("\n"));

        // final validated = Validator.validate(node);
        // final instructions:Array<VInstruction> = validated.filter(v -> v.match(Success(_))).map(v -> v.getParameters()[0]);
        // final instructions = Preprocessor.preprocess(instructions);

        // File.write("dump.casl", false).write(Bytes.ofString(PInstOrDataTraceTools.toString(instructions.instructions, instructions.startLabel)));

        final offset = 5;
        final assembly = Assembler.assembleAll(object.instructions, object.startLabel, 5);
        trace(assembly.text.map(a -> a.toString("")));

        final machine = new Comet2(assembly.text, assembly.entry, 5);
        while (!machine.step()) {
        }

        trace(machine.state);
    }
}
