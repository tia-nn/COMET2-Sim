package machine;

import extype.Exception;
import types.Instruction;
import types.Word;

class WordTools {
    public static function toInstruction(firstWord:Word, fetchSecondWord:() -> Word):LinkedInstruction {
        final r_r1 = new I0to7((firstWord & 0x0070) >> 4);
        final r2 = new I0to7(firstWord & 0x0007);
        final x = r2.toNullI1to7();
        final addr = fetchSecondWord;

        return switch (firstWord >> 8) {
            case 0x00:
                N({mnemonic: NOP});
            case 0x10:
                I({
                    mnemonic: LD,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x11:
                I({
                    mnemonic: ST,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x12:
                I({
                    mnemonic: LAD,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x14:
                R({mnemonic: LD, r1: r_r1, r2: r2});
            case 0x20:
                I({
                    mnemonic: ADDA,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x21:
                I({
                    mnemonic: SUBA,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x22:
                I({
                    mnemonic: ADDL,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x23:
                I({
                    mnemonic: SUBL,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x24:
                R({mnemonic: ADDA, r1: r_r1, r2: r2});
            case 0x25:
                R({mnemonic: SUBA, r1: r_r1, r2: r2});
            case 0x26:
                R({mnemonic: ADDL, r1: r_r1, r2: r2});
            case 0x27:
                R({mnemonic: SUBL, r1: r_r1, r2: r2});
            case 0x30:
                I({
                    mnemonic: AND,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x31:
                I({
                    mnemonic: OR,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x32:
                I({
                    mnemonic: XOR,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x34:
                R({mnemonic: AND, r1: r_r1, r2: r2});
            case 0x35:
                R({mnemonic: OR, r1: r_r1, r2: r2});
            case 0x36:
                R({mnemonic: XOR, r1: r_r1, r2: r2});
            case 0x40:
                I({
                    mnemonic: CPA,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x41:
                I({
                    mnemonic: CPL,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x44:
                R({mnemonic: CPA, r1: r_r1, r2: r2});
            case 0x45:
                R({mnemonic: CPL, r1: r_r1, r2: r2});
            case 0x50:
                I({
                    mnemonic: SLA,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x51:
                I({
                    mnemonic: SRA,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x52:
                I({
                    mnemonic: SLL,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x53:
                I({
                    mnemonic: SRL,
                    r: r_r1,
                    addr: addr(),
                    x: x
                });
            case 0x61:
                J({mnemonic: JMI, addr: addr(), x: x,});
            case 0x62:
                J({mnemonic: JNZ, addr: addr(), x: x,});
            case 0x63:
                J({mnemonic: JZE, addr: addr(), x: x,});
            case 0x64:
                J({mnemonic: JUMP, addr: addr(), x: x,});
            case 0x65:
                J({mnemonic: JPL, addr: addr(), x: x,});
            case 0x66:
                J({mnemonic: JOV, addr: addr(), x: x,});
            case 0x70:
                J({mnemonic: PUSH, addr: addr(), x: x,});
            case 0x71:
                P({mnemonic: POP, r: r_r1});
            case 0x80:
                J({mnemonic: CALL, addr: addr(), x: x,});
            case 0x81:
                N({mnemonic: RET});
            case 0xd0:
                P({mnemonic: LD_SP, r: r_r1});
            case 0xd1:
                P({mnemonic: LD_PTR, r: r_r1});
            case 0xd2:
                P({mnemonic: LD_IE, r: r_r1});
            case 0xd3:
                P({mnemonic: LD_IW, r: r_r1});
            case 0xd4:
                P({mnemonic: LD_CAUSE, r: r_r1});
            case 0xd5:
                P({mnemonic: LD_STATUS, r: r_r1});
            case 0xd6:
                P({mnemonic: LD_TVAL, r: r_r1});
            case 0xd7:
                P({mnemonic: LD_TVEC, r: r_r1});
            case 0xd8:
                P({mnemonic: LD_EPR, r: r_r1});
            case 0xd9:
                P({mnemonic: LD_SCRATCH, r: r_r1});
            case 0xe0:
                P({mnemonic: ST_SP, r: r_r1});
            case 0xe1:
                P({mnemonic: ST_PTR, r: r_r1});
            case 0xe2:
                P({mnemonic: ST_IE, r: r_r1});
            case 0xe5:
                P({mnemonic: ST_STATUS, r: r_r1});
            case 0xe7:
                P({mnemonic: ST_TVEC, r: r_r1});
            case 0xe9:
                P({mnemonic: ST_SCRATCH, r: r_r1});
            case 0xf0:
                J({mnemonic: SVC, addr: addr(), x: x,});
            case 0xf1:
                J({mnemonic: INT, addr: addr(), x: x,});
            case 0xf4:
                N({mnemonic: IRET});

            case _:
                throw new Exception("invalid instruction.");
        }
    }
}
