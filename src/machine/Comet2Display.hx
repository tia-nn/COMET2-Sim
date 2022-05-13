package machine;

import extype.ReadOnlyArray;
import haxe.io.Bytes;
import sys.io.FileOutput;
import types.Word;

class Comet2Display extends Comet2Timer {
    final displayFile:FileOutput;
    var bufferCache:String = '';

    static final FRAME_BUF = 0x2010;

    override public function new(insts:ReadOnlyArray<Word>, entry:Int = 0, offest:Int = 0, display:FileOutput) {
        super(insts, entry, offest);
        this.displayFile = display;
    }

    override function step():Bool {
        final result = super.step();

        final frameBuf = state.memory.slice(FRAME_BUF, FRAME_BUF + 400);
        var buffer = '';

        for (i in 0...20) {
            for (j in 0...20) {
                final word = frameBuf[i * 20 + j];

                final char1 = word.toUnsigned() >> 8;
                final char2 = word.toUnsigned() & 0x00ff;

                final char1 = SjisUnicodeTable.sjisToUnicode.get(char1);
                final char2 = SjisUnicodeTable.sjisToUnicode.get(char2);
                final char1 = char1 < 32 ? 32 : char1;
                final char2 = char2 < 32 ? 32 : char2;

                final char1 = String.fromCharCode(char1);
                final char2 = String.fromCharCode(char2);

                buffer = buffer + char1 + char2;
            }
            buffer = buffer + '\n';
        }

        if (buffer != bufferCache) {
            displayFile.seek(0, SeekBegin);
            displayFile.write(Bytes.ofString(buffer));
            displayFile.flush();
            bufferCache = buffer;
        }

        return result;
    }
}
