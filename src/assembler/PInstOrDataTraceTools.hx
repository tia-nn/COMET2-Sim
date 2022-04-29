package assembler;

import assembler.Instruction.PAddr;
import assembler.Instruction.PIOperand;
import assembler.Instruction.PInstOrData;
import assembler.Instruction.PJOperand;
import assembler.Instruction.PMnemonic;
import assembler.Instruction.POperand;
import assembler.Instruction.ROperand;

using assembler.PInstOrDataTraceTools;

class PInstOrDataTraceTools {
    public static function toString(instructions:Array<PInstOrData>, startLabel:String) {
        final rows = [' ; START ${startLabel}'];

        for (inst in instructions) {
            switch (inst) {
                case Inst(inst):
                    inst.mnemonic.getName().substring(0, -1);
                    rows.push('${inst.label.join("\n")}    ${inst.mnemonic.mnemonicToString()}');
                case Data(data):
                    rows.push('${data.label.join("\n")}    DC #${data.value.toString("")}');
            }
        }

        return rows.join("\n");
        return "";
    }

    static function rOperandToString(o:ROperand) {
        return 'GR${o.r1}, GR${o.r2}';
    }

    static function iOperandToString(o:PIOperand) {
        final x = o.x.fold(() -> "", r -> ', GR${r}');
        return 'GR${o.r}, ${o.addr.addrToString()}${x}';
    }

    static function jOperandToString(o:PJOperand) {
        final x = o.x.fold(() -> "", r -> ', GR${r}');
        return '${o.addr.addrToString()}${x}';
    }

    static function pOperandToString(o:POperand) {
        return 'GR${o.r}';
    }

    static function mnemonicToString(m:PMnemonic) {
        return switch (m) {
            case LDi(o), ADDAi(o), ADDLi(o), SUBAi(o), SUBLi(o), ANDi(o), ORi(o), XORi(o), CPAi(o), CPLi(o), STi(o), SRLi(o), SLLi(o), SRAi(o), SLAi(o),
                LADi(o):
                final name = m.getName();
                name.substring(0, name.length - 1)
                + " "
                + iOperandToString(o);

            case JPLj(o), JMIj(o), JNZj(o), JZEj(o), JOVj(o), JUMPj(o), PUSHj(o), CALLj(o), SVCj(o):
                final name = m.getName();
                name.substring(0, name.length - 1) + " " + jOperandToString(o);

            case LDr(o), ADDAr(o), ADDLr(o), SUBAr(o), SUBLr(o), ANDr(o), ORr(o), XORr(o), CPAr(o), CPLr(o):
                final name = m.getName();
                name.substring(0, name.length - 1) + " " + rOperandToString(o);

            case POPp(o):
                final name = m.getName();
                name.substring(0, name.length - 1) + " " + pOperandToString(o);

            case RETn:
                "RET";
            case NOPn:
                "NOP";
        }
    }

    static function addrToString(addr:PAddr) {
        return switch (addr) {
            case Label(label):
                label;
            case Constant(value):
                '#${value.toString("")}';
        }
    }
}
