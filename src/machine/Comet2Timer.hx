package machine;

import extype.ReadOnlyArray;
import machine.external.Timer;
import sys.thread.Thread;
import types.Word;

class Comet2Timer extends Comet2Bios {
    final timer:Thread;

    override public function new(insts:ReadOnlyArray<Word>, entry:Int = 0, offest:Int = 0) {
        super(insts, entry, offest);
        timer = Thread.create(Timer.create(() -> intRequire(4)));
    }

    override function onExit() {
        super.onExit();
        timer.sendMessage(true);
    }
}
