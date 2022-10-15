package casl2;

import extype.Map;
import extype.Nullable;
import extype.Pair;
import extype.ReadOnlyArray;
import types.Instruction;
import types.Word;

using Lambda;

class Casl2 {
    public static function assembleAll(insts:ReadOnlyArray<ObjectInstructionWithLabel>, startLabel:String, offset:Int) {
        final labelTable = new Map();
        final usingLableTable:Array<Pair<String, Int>> = [];
        final text = insts.fold((item, result:ReadOnlyArray<Word>) -> {
            final r = assemble(item.inst);
            item.label.iter(label -> labelTable.set(label, result.length + offset));
            if (r.useLabel != null)
                usingLableTable.push(new Pair(r.useLabel, result.length + 1));
            return result.concat(r.text);
        }, []);

        for (p in usingLableTable) {
            text[p.value2] = new Word(labelTable.get(p.value1));
        }

        return {text: (text : ReadOnlyArray<Word>), entry: labelTable.get(startLabel)};
    }

    static function assemble(inst:ObjectInstruction):{text:ReadOnlyArray<Word>, ?useLabel:String} {
        return switch (inst) {
            case R(i):
                switch (i.mnemonic) {
                    case LD:
                        {text: [new Word(0x1400 | i.r1 << 4 | i.r2)]}
                    case ADDA:
                        {text: [new Word(0x2400 | i.r1 << 4 | i.r2)]}
                    case SUBA:
                        {text: [new Word(0x2500 | i.r1 << 4 | i.r2)]}
                    case ADDL:
                        {text: [new Word(0x2600 | i.r1 << 4 | i.r2)]}
                    case SUBL:
                        {text: [new Word(0x2700 | i.r1 << 4 | i.r2)]}
                    case AND:
                        {text: [new Word(0x3400 | i.r1 << 4 | i.r2)]}
                    case OR:
                        {text: [new Word(0x3500 | i.r1 << 4 | i.r2)]}
                    case XOR:
                        {text: [new Word(0x3600 | i.r1 << 4 | i.r2)]}
                    case CPA:
                        {text: [new Word(0x4400 | i.r1 << 4 | i.r2)]}
                    case CPL:
                        {text: [new Word(0x4500 | i.r1 << 4 | i.r2)]}
                }
            case I(i):
                switch (i.mnemonic) {
                    case LD:
                        assembleIOperand(0x10, i);
                    case ST:
                        assembleIOperand(0x11, i);
                    case LAD:
                        assembleIOperand(0x12, i);
                    case ADDA:
                        assembleIOperand(0x20, i);
                    case SUBA:
                        assembleIOperand(0x21, i);
                    case ADDL:
                        assembleIOperand(0x22, i);
                    case SUBL:
                        assembleIOperand(0x23, i);
                    case AND:
                        assembleIOperand(0x30, i);
                    case OR:
                        assembleIOperand(0x31, i);
                    case XOR:
                        assembleIOperand(0x32, i);
                    case CPA:
                        assembleIOperand(0x40, i);
                    case CPL:
                        assembleIOperand(0x41, i);
                    case SLA:
                        assembleIOperand(0x50, i);
                    case SRA:
                        assembleIOperand(0x51, i);
                    case SLL:
                        assembleIOperand(0x52, i);
                    case SRL:
                        assembleIOperand(0x53, i);
                }
            case J(i):
                switch (i.mnemonic) {
                    case JMI:
                        assembleJOperand(0x61, i);
                    case JNZ:
                        assembleJOperand(0x62, i);
                    case JZE:
                        assembleJOperand(0x63, i);
                    case JUMP:
                        assembleJOperand(0x64, i);
                    case JPL:
                        assembleJOperand(0x65, i);
                    case JOV:
                        assembleJOperand(0x66, i);
                    case PUSH:
                        assembleJOperand(0x70, i);
                    case CALL:
                        assembleJOperand(0x80, i);
                    case SVC:
                        assembleJOperand(0xf0, i);
                    case INT:
                        assembleJOperand(0xf1, i);
                }
            case P(i):
                switch (i.mnemonic) {
                    case POP:
                        {text: [new Word(0x7100 | i.r << 4)]}
                    case LD_SP:
                        {text: [new Word(0xd000 | i.r << 4)]}
                    case LD_PTR:
                        {text: [new Word(0xd100 | i.r << 4)]}
                    case LD_IE:
                        {text: [new Word(0xd200 | i.r << 4)]}
                    case LD_IW:
                        {text: [new Word(0xd300 | i.r << 4)]}
                    case LD_CAUSE:
                        {text: [new Word(0xd400 | i.r << 4)]}
                    case LD_STATUS:
                        {text: [new Word(0xd500 | i.r << 4)]}
                    case ST_SP:
                        {text: [new Word(0xe000 | i.r << 4)]}
                    case ST_PTR:
                        {text: [new Word(0xe100 | i.r << 4)]}
                    case ST_IE:
                        {text: [new Word(0xe200 | i.r << 4)]}
                    case ST_STATUS:
                        {text: [new Word(0xe500 | i.r << 4)]}
                }
            case N(i):
                switch (i.mnemonic) {
                    case NOP:
                        {text: [new Word(0)]};
                    case RET:
                        {text: [new Word(0x8100)]};
                    case IRET:
                        {text: [new Word(0xf400)]};
                }
            case Data(d):
                {text: [d]};
        }
    }

    static function assembleIOperand(opcode:Int, o:ObjectIInstruction) {
        final firstWord = new Word(opcode << 8 | (o.r : Int) << 4 | (o.x : Nullable<Int>).getOrElse(0));

        return switch (o.addr) {
            case Label(label):
                {
                    text: [firstWord, new Word(0)],
                    useLabel: label,
                }
            case Const(value):
                {
                    text: [firstWord, value],
                    useLabel: null,
                }
        }
    }

    static function assembleJOperand(opcode:Int, o:ObjectJOperand) {
        final firstWord = new Word(opcode << 8 | (o.x : Nullable<Int>).getOrElse(0));

        return switch (o.addr) {
            case Label(label):
                {
                    text: [firstWord, new Word(0)],
                    useLabel: label,
                }
            case Const(value):
                {
                    text: [firstWord, value],
                    useLabel: null,
                }
        }
    }
}
