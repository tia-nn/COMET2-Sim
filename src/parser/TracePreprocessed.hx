package parser;

import parser.Instruction.Preprocessed;
import parser.Instruction.PreprocessedAddr;
import parser.Instruction.PreprocessedOperand;

using parser.TracePreprocessed.PreprocessedTools;

class PreprocessedTools {
    public static function toString(instructions:Array<Preprocessed>, startLabel:String) {
        final rows = [' ; START ${startLabel}'];

        for (inst in instructions) {
            switch (inst) {
                case Inst(inst):
                    rows.push('${inst.label.join("\n")}    ${inst.mnemonic.getName()} ${inst.operand.operandToString()}');
                case Data(data):
                    rows.push('${data.label.join("\n")}    DC #${data.value.toString("")}');
            }
        }

        return rows.join("\n");
    }

    static function operandToString(operand:PreprocessedOperand) {
        return switch (operand) {
            case R(operand):
                'GR${operand.r1}, GR${operand.r2}';
            case I(operand):
                final x = operand.x.fold(() -> "", r -> ', GR${r}');
                'GR${operand.r}, ${operand.addr.addrToString()}${x}';
            case J(operand):
                final x = operand.x.fold(() -> "", r -> ', GR${r}');
                '${operand.addr.addrToString()}${x}';
            case P(operand):
                'GR${operand.r}';
            case N:
                "";
        }
    }

    static function addrToString(addr:PreprocessedAddr) {
        return switch (addr) {
            case Label(label):
                label;
            case Constant(value):
                '#${value.toString("")}';
        }
    }
}
