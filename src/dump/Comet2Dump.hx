package dump;

import haxe.io.Bytes;
import machine.Comet2State;
import sys.io.File;
import sys.io.FileOutput;

using Lambda;
using StringTools;

class Comet2Dump {
    public static function dump(state:FrozenComet2State, ?file:FileOutput) {
        if (file == null) {
            file = File.write("dump.comet.txt", false);
        }

        final gr = 'GR0: ${state.gr[0].toString()} GR1: ${state.gr[1].toString()} GR2: ${state.gr[2].toString()} GR3: ${state.gr[3].toString()}\n'
            + 'GR4: ${state.gr[4].toString()} GR5: ${state.gr[5].toString()} GR6: ${state.gr[6].toString()} GR7: ${state.gr[7].toString()}\n';

        final sp = 'SP: ${state.sp.toString()}\n';
        final pr = 'PR: ${state.pr.toString()}\n';
        final fr = 'FR: OF: ${state.fr.of ? 1 : 0} SF: ${state.fr.sf ? 1 : 0} ZF: ${state.fr.zf ? 1 : 0}\n';

        final memory = [];
        for (i in 0...Std.int(0x10000 / 8)) {
            final a = state.memory.slice(i * 8, (i + 1) * 8);
            final c = [for (b in a) b.toString()].join(" ");
            memory.push(c);
        }

        final memory = memory.mapi((i, s) -> '0x${(i * 8).hex(4)} ${s}').join("\n");

        file.write(Bytes.ofString(gr + sp + pr + fr + memory + "\n"));
    }
}
