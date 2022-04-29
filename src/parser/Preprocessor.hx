package parser;

import Word.I0to7;
import Word.I1to7;
import extype.Nullable;
import extype.Tuple.Tuple2;
import parser.Instruction.AssemblerAddr;
import parser.Instruction.DataWord;
import parser.Instruction.Preprocessed;
import parser.Instruction.PreprocessedAddr;
import parser.Instruction.PreprocessedOperand;

class Preprocessor {
    public static function preprocess(src:Array<Instruction>) {
        var literalLabelNumber = 0;
        final genLiteralLabel = () -> '__LITERAL_${literalLabelNumber++}';
        final instructions:Array<Preprocessed> = [];
        var literals:Array<DataWord> = [];
        var startLabel:Null<String> = null;

        var pendingLabel:Array<String> = [];
        for (inst in src) {
            switch (inst) {
                case Machine(inst):
                    final operand:PreprocessedOperand = switch (inst.operand) {
                        case I(operand):
                            final addr = preprocessLiteral(operand.addr, genLiteralLabel);
                            literals = literals.concat(addr.value2);
                            I({
                                r: operand.r,
                                x: operand.x,
                                addr: addr.value1,
                            });
                        case J(operand):
                            final addr = preprocessLiteral(operand.addr, genLiteralLabel);
                            literals = literals.concat(addr.value2);
                            J({
                                x: operand.x,
                                addr: addr.value1,
                            });
                        case R(operand):
                            R(operand);
                        case P(operand):
                            P(operand);
                        case N:
                            N;
                    }
                    instructions.push(Inst({
                        label: inst.label.map(l -> [l]).getOrElse([]).concat(pendingLabel),
                        mnemonic: inst.mnemonic,
                        operand: operand,
                    }));
                    pendingLabel = [];

                case Assembler(inst):
                    switch (inst.mnemonic) {
                        case START(label):
                            startLabel = label.getOrElse(inst.label.getOrThrow());
                            pendingLabel = [inst.label.getOrThrow()];
                        case END:
                        case DS(words):
                            if (words == 0) {
                                inst.label.iter(label -> pendingLabel.push(label));
                            } else {
                                instructions.push(Data({
                                    label: inst.label.map(l -> [l]).getOrElse([]).concat(pendingLabel),
                                    value: new Word(0),
                                }));
                                pendingLabel = [];
                                for (i in 1...words) {
                                    instructions.push(Data({
                                        label: [],
                                        value: new Word(0),
                                    }));
                                }
                            }
                        case DC(values):
                            if (values.length == 0) {
                                trace("DCは1つ以上定数を指定してください. DC 0 として扱います.");
                                values = [new Word(0)];
                            }
                            instructions.push(Data({
                                label: inst.label.map(l -> [l]).getOrElse([]).concat(pendingLabel),
                                value: values[0],
                            }));
                            pendingLabel = [];
                            for (i in 1...values.length) {
                                instructions.push(Data({
                                    label: [],
                                    value: values[i],
                                }));
                            }
                        case IN(dataBuf, lengthBuf):
                            trace("not implemeted...");
                        case OUT(dataBuf, lengthBuf):
                            trace("not implemeted...");
                        case RPUSH:
                            instructions.push(Inst({
                                label: inst.label.map(l -> [l]).getOrElse([]).concat(pendingLabel),
                                mnemonic: PUSH,
                                operand: J({
                                    addr: Constant(new Word(0)),
                                    x: new I1to7(1)
                                })
                            }));
                            pendingLabel = [];
                            for (i in 2...8) {
                                instructions.push(Inst({
                                    label: [],
                                    mnemonic: PUSH,
                                    operand: J({
                                        addr: Constant(new Word(0)),
                                        x: new I1to7(i)
                                    })
                                }));
                            }
                        case RPOP:
                            instructions.push(Inst({
                                label: inst.label.map(l -> [l]).getOrElse([]).concat(pendingLabel),
                                mnemonic: POP,
                                operand: P({
                                    r: new I0to7(7),
                                })
                            }));
                            pendingLabel = [];
                            final iter = [for (i in 1...7) i];
                            iter.reverse();
                            for (i in iter) {
                                instructions.push(Inst({
                                    label: [],
                                    mnemonic: POP,
                                    operand: P({
                                        r: new I0to7(i)
                                    })
                                }));
                            }
                    }
            }
        }

        return {
            instructions: instructions.concat(literals.map(d -> Data(d))),
            startLabel: (startLabel : Nullable<String>).getOrThrow()
        };
    }

    static function preprocessLiteral(addr:AssemblerAddr, genLiteralLabel:() -> String):Tuple2<PreprocessedAddr, Array<DataWord>> {
        return switch (addr) {
            case Label(label):
                new Tuple2(Label(label), []);
            case Constant(value):
                new Tuple2(Constant(value), []);
            case Literal(values):
                if (values.length == 0) {
                    trace("文字列は一文字以上必要です. '\\0' として扱います.");
                    values = [new Word(0)];
                }
                final label = genLiteralLabel();
                final data = ([{label: [label], value: values[0]}] : Array<DataWord>).concat(values.slice(1).map(v -> {label: [], value: v}));
                new Tuple2(Label(label), data);
        }
    }
}
