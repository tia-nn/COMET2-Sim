package machine;

class Comet2Bios extends Comet2 {
    override function bios():Bool {
        final f = state.gr[7];
        if (f == 0xf000) {
            return true;
        } else {
            priorityIntRequire(1);
            return false;
        }
    }
}
