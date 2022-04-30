package;

import machine.Comet2Dump;
import sys.io.File;

class Comet2 {
    static function main() {
        final options = {
            rootPath: "comet2",
            displayPath: "comet2.txt",
        }
        var i = 0;
        while (i < Sys.args().length) {
            final arg = Sys.args()[i];
            switch (arg) {
                case "-r", "--root-path":
                    options.rootPath = Sys.args()[++i];
                case "-d", "--display-file":
                    options.displayPath = Sys.args()[++i];
                case _:
                    i++;
            }
        }

        if (options.rootPath == null || options.displayPath == null) {
            trace("usage: assembler -r [root directory]");
            return;
        }

        run(options.rootPath, options.displayPath);
    }

    static function run(rootPath:String, displayPath:String) {
        rootPath = ~/\/$/.replace(rootPath, "");
        final kernelPath = rootPath + "/kernel.bin";

        final bytes = File.read(kernelPath).readAll();
        final words = [];

        for (i in 0...Std.int(bytes.length / 2)) {
            words.push(new Word(bytes.getUInt16(i * 2)));
        }

        final comet2 = new machine.Comet2(words, 0, 0);
        final dump = File.write("comet2dump.txt");

        while (!comet2.step()) {
            dump.seek(0, SeekBegin);
            Comet2Dump.dump(comet2.getState(), dump);
        }
        dump.seek(0, SeekBegin);
        Comet2Dump.dump(comet2.getState(), dump);
    }
}
