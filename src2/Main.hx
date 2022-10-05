package;

import casl2.parser.Parser;
import casl2.tokenizer.Tokenizer;
import sys.io.File;

class Main {
    static function main() {
        final options = {
            srcFile: null,
            outPath: null,
            dump: false,
        }
        var i = 0;
        while (i < Sys.args().length) {
            final arg = Sys.args()[i];
            switch (arg) {
                case "-s", "--src":
                    options.srcFile = Sys.args()[++i];
                case "-o", "--out":
                    options.outPath = Sys.args()[++i];
                case "-d", "--dump":
                    options.dump = true;
                    i++;
                case _:
                    i++;
            }
        }

        if (options.srcFile == null || options.outPath == null) {
            trace("usage: assembler -s [source file path] -o [output file] {-d}");
            return;
        }

        assemble(options.srcFile, options.outPath, options.dump);
    }

    static function assemble(src:String, out:String, dump:Bool) {
        final bytes = File.read(src).readAll();
        final src = bytes.getString(0, bytes.length, UTF8);

        final outFile = File.write(out);

        final tokens = Tokenizer.tokenize(src);
        // final node =
        Parser.parse(tokens);

        // final node = switch (node) {
        //     case Success(r, w):
        //         if (w.length != 0)
        //             trace(w.join("\n"));
        //         r;
        //     case Failed(e, w):
        //         trace(e.join("\n"));
        //         trace(w.join("\n"));
        //         trace("コンパイル失敗");
        //         return;
        // }

        // final errors = StartEndChecker.check(node);
        // switch (errors) {
        //     case []:
        //     case _:
        //         trace(errors.join("\n"));
        //         trace("コンパイル失敗");
        //         return;
        // }
    }
}
