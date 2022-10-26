package types;

import extype.Nullable;
import extype.ReadOnlyArray;
import haxe.Exception;

using Lambda;
using StringTools;

abstract I0to7(Int) to Int {
    public function new(n:Int) {
        if (0 <= n && n < 8) {
            this = n;
        } else {
            throw new Exception('Over GR number range. (${n})');
        }
    }

    public function toNullI1to7():Nullable<I1to7> {
        return if (this == 0) {
            Nullable.empty();
        } else {
            new I1to7(this);
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

    public function toString(prefix:String = "0x", bytesep:String = "") {
        return prefix + ((this & 0xff00) >> 8).hex(2) + bytesep + (this & 0x00ff).hex(2);
    }

    public function toSigned():Int {
        return if (this & 0x8000 == 0) {
            (this : Int);
        } else {
            -((this ^ 0xffff) + 1);
        }
    }

    public function toBitArray():Array<Int> {
        return [
            (this & 0x8000 == 0) ? 0 : 1,
            (this & 0x4000 == 0) ? 0 : 1,
            (this & 0x2000 == 0) ? 0 : 1,
            (this & 0x1000 == 0) ? 0 : 1,
            (this & 0x0800 == 0) ? 0 : 1,
            (this & 0x0400 == 0) ? 0 : 1,
            (this & 0x0200 == 0) ? 0 : 1,
            (this & 0x0100 == 0) ? 0 : 1,
            (this & 0x0080 == 0) ? 0 : 1,
            (this & 0x0040 == 0) ? 0 : 1,
            (this & 0x0020 == 0) ? 0 : 1,
            (this & 0x0010 == 0) ? 0 : 1,
            (this & 0x0008 == 0) ? 0 : 1,
            (this & 0x0004 == 0) ? 0 : 1,
            (this & 0x0002 == 0) ? 0 : 1,
            (this & 0x0001 == 0) ? 0 : 1,
        ];
    }

    public static function fromBitArray(arr:ReadOnlyArray<Int>):Word {
        if (arr.length != 16)
            throw new Exception("array length must be 16");
        return new Word(arr.foldi((item, result, index) -> {
            return if (item != 0) {
                result | (1 << (15 - index));
            } else {
                result;
            }
        }, 0));
    }

    @:to
    public function toUnsigned():Int {
        return this;
    }

    @:op(A + B)
    public function add(rhs:Word) {
        return new Word(toUnsigned() + rhs);
    }

    @:op(A - B)
    public function sub(rhs:Word) {
        return new Word(toUnsigned() - rhs);
    }

    @:op(A & B)
    public function and(rhs:Word) {
        return new Word(toUnsigned() & rhs);
    }

    @:op(A | B)
    public function or(rhs:Word) {
        return new Word(toUnsigned() | rhs);
    }

    @:op(A ^ B)
    public function xor(rhs:Word) {
        return new Word(toUnsigned() ^ rhs);
    }

    public function sla(rhs:Word):Word {
        return if ((rhs : Int) > 14) {
            new Word(this & 0x8000);
        } else {
            final arr = toBitArray();
            final sign = arr[0];
            final abs = arr.slice(1);
            final abs = abs.slice(rhs).concat([for (_ in 0...rhs) 0]);
            fromBitArray([sign].concat(abs));
        }
    }

    @:op(A << B)
    public function sll(rhs:Word):Word {
        return if ((rhs : Int) > 15) {
            return new Word(0);
        } else {
            final arr = toBitArray();
            final arr = arr.slice(rhs).concat([for (_ in 0...rhs) 0]);
            fromBitArray(arr);
        }
    }

    @:op(A >> B)
    public function sra(rhs:Word) {
        final arr = toBitArray();
        final sign = arr[0];

        return if ((rhs : Int) > 14) {
            fromBitArray([for (_ in 0...16) sign]);
        } else {
            final abs = arr.slice(1);
            final abs = [for (_ in 0...rhs) sign].concat(abs.slice(0, 15 - rhs));
            return fromBitArray([sign].concat(abs));
        }
    }

    @:op(A >>> B)
    public function srl(rhs:Word):Word {
        return if ((rhs : Int) > 15) {
            return new Word(0);
        } else {
            final arr = toBitArray();
            final arr = [for (_ in 0...rhs) 0].concat(arr.slice(0, 16 - rhs));
            fromBitArray(arr);
        }
    }

    @:op(A < B)
    public function lt(rhs:Word):Bool {
        return this < (rhs : Int);
    }

    @:op(A > B)
    public function gt(rhs:Word):Bool {
        return this > (rhs : Int);
    }
}
