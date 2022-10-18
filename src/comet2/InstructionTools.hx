package comet2;

import extype.Result;
import types.Word;

class InstructionTools {
    public static function toInstruction(firstWord:Word, secondWord:Word):Result<Instruction, Word> {
        final r_r1 = new I0to7((firstWord & 0x0070) >> 4);
        final r2 = new I0to7(firstWord & 0x0007);
        final x = r2.toNullI1to7();
        final addr = secondWord;

        return Success(switch (firstWord >> 8) {
            case 0x00:
                N({mnemonic: NOP});
            case 0x10:
                I({
                    mnemonic: LD,
                    r: r_r1,
                    addr: addr,
                    x: x
                });
            case 0x11:
                I({
                    mnemonic: ST,
                    r: r_r1,
                    addr: addr,
                    x: x
                });
            case 0x12:
                I({
                    mnemonic: LAD,
                    r: r_r1,
                    addr: addr,
                    x: x
                });
            case 0x14:
                R({mnemonic: LD, r1: r_r1, r2: r2});
            case 0x20:
                I({
                    mnemonic: ADDA,
                    r: r_r1,
                    addr: addr,
                    x: x
                });
            case 0x21:
                I({
                    mnemonic: SUBA,
                    r: r_r1,
                    addr: addr,
                    x: x
                });
            case 0x22:
                I({
                    mnemonic: ADDL,
                    r: r_r1,
                    addr: addr,
                    x: x
                });
            case 0x23:
                I({
                    mnemonic: SUBL,
                    r: r_r1,
                    addr: addr,
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
                    addr: addr,
                    x: x
                });
            case 0x31:
                I({
                    mnemonic: OR,
                    r: r_r1,
                    addr: addr,
                    x: x
                });
            case 0x32:
                I({
                    mnemonic: XOR,
                    r: r_r1,
                    addr: addr,
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
                    addr: addr,
                    x: x
                });
            case 0x41:
                I({
                    mnemonic: CPL,
                    r: r_r1,
                    addr: addr,
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
                    addr: addr,
                    x: x
                });
            case 0x51:
                I({
                    mnemonic: SRA,
                    r: r_r1,
                    addr: addr,
                    x: x
                });
            case 0x52:
                I({
                    mnemonic: SLL,
                    r: r_r1,
                    addr: addr,
                    x: x
                });
            case 0x53:
                I({
                    mnemonic: SRL,
                    r: r_r1,
                    addr: addr,
                    x: x
                });
            case 0x61:
                J({mnemonic: JMI, addr: addr, x: x,});
            case 0x62:
                J({mnemonic: JNZ, addr: addr, x: x,});
            case 0x63:
                J({mnemonic: JZE, addr: addr, x: x,});
            case 0x64:
                J({mnemonic: JUMP, addr: addr, x: x,});
            case 0x65:
                J({mnemonic: JPL, addr: addr, x: x,});
            case 0x66:
                J({mnemonic: JOV, addr: addr, x: x,});
            case 0x70:
                J({mnemonic: PUSH, addr: addr, x: x,});
            case 0x71:
                P({mnemonic: POP, r: r_r1});
            case 0x80:
                J({mnemonic: CALL, addr: addr, x: x,});
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
                J({mnemonic: SVC, addr: addr, x: x,});
            case 0xf1:
                J({mnemonic: INT, addr: addr, x: x,});
            case 0xf4:
                N({mnemonic: IRET});

            case _:
                return Failure(firstWord);
        });
    }

    public static function isPrivilegeInstruction(inst:Instruction) {
        return switch (inst) {
            case P(i):
                switch (i.mnemonic) {
                    case LD_SP, LD_PTR, LD_IW, LD_CAUSE, LD_STATUS, LD_TVAL, LD_TVEC, LD_EPR, LD_SCRATCH, ST_SP, ST_PTR, ST_IE, ST_STATUS, ST_TVEC, ST_SCRATCH:

                        true;
                    default:
                        false;
                }
            case N(i):
                switch (i.mnemonic) {
                    case IRET:
                        true;
                    default:
                        false;
                }
            default:
                false;
        }
    }

    public static function getInstructionSize(inst:Instruction):Int {
        return switch (inst) {
            case R(_), P(_), N(_):
                1;
            case I(_), J(_):
                2;
        }
    }

    public static function toString(inst:Instruction) {
        return switch (inst) {
            case R(i):
                final mnemonic = i.mnemonic.getName();
                final r1 = 'GR${i.r1}';
                final r2 = 'GR${i.r2}';
                '${mnemonic}\t${r1}, ${r2}';
            case I(i):
                final mnemonic = i.mnemonic.getName();
                final r = 'GR${i.r}';
                final adr = i.addr.toString();
                switch (i.x.toMaybe()) {
                    case Some(x):
                        '${mnemonic}\t${r}, ${adr}, GR${x}';
                    case None:
                        '${mnemonic}\t${r}, ${adr}';
                }
            case J(i):
                final mnemonic = i.mnemonic.getName();
                final adr = i.addr.toString();
                switch (i.x.toMaybe()) {
                    case Some(x):
                        '${mnemonic}\t${adr}, GR${x}';
                    case None:
                        '${mnemonic}\t${adr}';
                }
            case P(i):
                final mnemonic = i.mnemonic.getName();
                final r = 'GR${i.r}';
                '${mnemonic}\t${r}';
            case N(i):
                final mnemonic = i.mnemonic.getName();
                '${mnemonic}';
        }
    }
}
