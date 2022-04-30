package machine;

import extype.ReadOnlyArray;
import haxe.io.Bytes;
import sys.io.FileOutput;

class Comet2Display extends Comet2Bios {
    final displayFile:FileOutput;

    static final FRAME_BUF = 0x2010;

    override public function new(insts:ReadOnlyArray<Word>, entry:Int = 0, offest:Int = 0, display:FileOutput) {
        super(insts, entry, offest);
        this.displayFile = display;
    }

    override function step():Bool {
        final result = super.step();

        displayFile.seek(0, SeekBegin);
        for (i in 0...20) {
            for (j in 0...20) {
                final word = state.memory[FRAME_BUF + (i * 20 + j)];
                final char1 = word.toUnsigned() >> 8;
                final char2 = word.toUnsigned() & 0x00ff;

                final char1 = SjisUnicodeTable.sjisToUnicode.get(char1);
                final char2 = SjisUnicodeTable.sjisToUnicode.get(char2);
                final char1 = char1 < 32 ? 32 : char1;
                final char2 = char2 < 32 ? 32 : char2;

                final char1 = String.fromCharCode(char1);
                final char2 = String.fromCharCode(char2);

                displayFile.write(Bytes.ofString(char1 + char2));
            }
            displayFile.write(Bytes.ofString("\n"));
        }

        return result;
    }
}
