package;

import haxe.Exception;

using StringTools;

abstract I0to7(Int) to Int {
    public function new(n:Int) {
        if (0 <= n && n < 8) {
            this = n;
        } else {
            throw new Exception('Over GR number range. (${n})');
        }
    }
}

abstract I1to7(Int) to Int {
    public function new(n:Int) {
        if (1 <= n && n < 8) {
            this = n;
        } else {
            throw new Exception('Over GR number range. (${n})');
        }
    }
}

abstract HalfByte(Int) to Int {
    public function new(v:Int) {
        this = v & 0xf;
    }

    public function toString() {
        return this.hex(1);
    }
}

abstract Byte(Int) to Int {
    public function new(v:Int) {
        this = v & 0xff;
    }

    public function toString() {
        return this.hex(2);
    }
}

abstract Word(Int) to Int {
    public function new(v:Int) {
        this = v & 0xffff;
    }

    public function toString(?bytesep:String = " ") {
        return ((this & 0xff00) >> 8).hex(2) + bytesep + (this & 0x00ff).hex(2);
    }
}
