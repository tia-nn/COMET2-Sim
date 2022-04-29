package assembler;

import assembler.Instruction.PIOperand;
import assembler.Instruction.PInstOrData;
import assembler.Instruction.PJOperand;
import assembler.Instruction.PMnemonic;
import extype.Map;
import extype.Nullable;

using Lambda;

class Assembler {
    public static function assembleAll(insts:Array<PInstOrData>):Array<Word> {
        final labelTable = new Map();
        final usingLableTable = new Map();
        final text = insts.fold((item, result:Array<Word>) -> {
            return result.concat(switch (item) {
                case Inst(inst):
                    final r = assemble(inst.mnemonic);
                    inst.label.iter(label -> labelTable.set(label, result.length));
                    if (r.useLabel != null)
                        usingLableTable.set(r.useLabel, result.length + 1);
                    r.text;
                case Data(data):
                    data.label.iter(label -> labelTable.set(label, result.length));
                    [data.value];
            });
        }, []);
        for (label => i in usingLableTable) {
            text[i] = new Word(labelTable.get(label));
        }
        return text;
    }

    static function assemble(inst:PMnemonic):{text:Array<Word>, ?useLabel:String} {
        return switch (inst) {
            case NOPn:
                {text: [new Word(0)]};
            case LDi(o):
                assembleIOperand(0x10, o);
            case STi(o):
                assembleIOperand(0x11, o);
            case LADi(o):
                assembleIOperand(0x12, o);
            case LDr(o):
                {text: [new Word(0x1400 | o.r1 << 4 | o.r2)]}
            case ADDAi(o):
                assembleIOperand(0x20, o);
            case SUBAi(o):
                assembleIOperand(0x21, o);
            case ADDLi(o):
                assembleIOperand(0x22, o);
            case SUBLi(o):
                assembleIOperand(0x23, o);
            case ADDAr(o):
                {text: [new Word(0x2400 | o.r1 << 4 | o.r2)]}
            case SUBAr(o):
                {text: [new Word(0x2500 | o.r1 << 4 | o.r2)]}
            case ADDLr(o):
                {text: [new Word(0x2600 | o.r1 << 4 | o.r2)]}
            case SUBLr(o):
                {text: [new Word(0x2700 | o.r1 << 4 | o.r2)]}
            case ANDi(o):
                assembleIOperand(0x30, o);
            case ORi(o):
                assembleIOperand(0x31, o);
            case XORi(o):
                assembleIOperand(0x32, o);
            case ANDr(o):
                {text: [new Word(0x3400 | o.r1 << 4 | o.r2)]}
            case ORr(o):
                {text: [new Word(0x3500 | o.r1 << 4 | o.r2)]}
            case XORr(o):
                {text: [new Word(0x3600 | o.r1 << 4 | o.r2)]}
            case CPAi(o):
                assembleIOperand(0x40, o);
            case CPLi(o):
                assembleIOperand(0x41, o);
            case CPAr(o):
                {text: [new Word(0x4400 | o.r1 << 4 | o.r2)]}
            case CPLr(o):
                {text: [new Word(0x4500 | o.r1 << 4 | o.r2)]}
            case SLAi(o):
                assembleIOperand(0x50, o);
            case SRAi(o):
                assembleIOperand(0x51, o);
            case SLLi(o):
                assembleIOperand(0x52, o);
            case SRLi(o):
                assembleIOperand(0x53, o);
            case JMIj(o):
                assembleJOperand(0x61, o);
            case JNZj(o):
                assembleJOperand(0x62, o);
            case JZEj(o):
                assembleJOperand(0x63, o);
            case JUMPj(o):
                assembleJOperand(0x64, o);
            case JPLj(o):
                assembleJOperand(0x65, o);
            case JOVj(o):
                assembleJOperand(0x66, o);
            case PUSHj(o):
                assembleJOperand(0x70, o);
            case POPp(o):
                {text: [new Word(0x3400 | o.r << 4)]}
            case CALLj(o):
                assembleJOperand(0x80, o);
            case RETn:
                {text: [new Word(0x8100)]};
            case SVCj(o):
                assembleJOperand(0xf0, o);
        }
    }

    static function assembleIOperand(opcode:Int, o:PIOperand) {
        final firstWord = new Word(opcode << 8 | (o.r : Int) << 4 | (o.x : Nullable<Int>).getOrElse(0));

        return switch (o.addr) {
            case Label(label):
                {
                    text: [firstWord, new Word(0)],
                    useLabel: label,
                }
            case Constant(value):
                {
                    text: [firstWord, value],
                    useLabel: null,
                }
        }
    }

    static function assembleJOperand(opcode:Int, o:PJOperand) {
        final firstWord = new Word(opcode << 8 | (o.x : Nullable<Int>).getOrElse(0));

        return switch (o.addr) {
            case Label(label):
                {
                    text: [firstWord, new Word(0)],
                    useLabel: label,
                }
            case Constant(value):
                {
                    text: [firstWord, value],
                    useLabel: null,
                }
        }
    }
}

typedef AssembleResult = {
    final text:Array<Word>;
    final labelTable:Map<String, Word>;
    final undefinedLabelTable:Map<String, Word>;
}
