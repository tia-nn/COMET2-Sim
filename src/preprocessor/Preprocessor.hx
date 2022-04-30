package preprocessor;

import Word.I0to7;
import Word.I1to7;
import extype.Exception;
import extype.Nullable;
import extype.Tuple.Tuple2;
import parser.InstructionDefinition.ObjectAddr;
import parser.InstructionDefinition.ObjectIInstruction;
import parser.InstructionDefinition.ObjectInstructionWithLabel;
import parser.InstructionDefinition.ObjectJInstruction;
import parser.InstructionDefinition.ParsedAddr;
import parser.InstructionDefinition.ParsedIInstruction;
import parser.InstructionDefinition.ParsedInstructionWithLine;
import parser.InstructionDefinition.ParsedJInstruction;

class Preprocessor {
    var literalLabelNumber = 0;
    var literals:Array<ObjectInstructionWithLabel> = [];
    var startLabel:Null<String> = null;
    var pendingLabel:Array<String> = [];
    final instructions:Array<ObjectInstructionWithLabel>;

    function genLiteralLabel() {
        return '__LITERAL_${literalLabelNumber++}';
    };

    function new() {
        instructions = [];
    }

    public static function preprocess(src:Array<ParsedInstructionWithLine>) {
        final preprocessor = new Preprocessor();
        preprocessor.run(src);

        final literals = if (preprocessor.literals.length != 0) [
            // リテラルに最後に余ったラベルをつける
            ({
                label: preprocessor.literals[0].label.concat(preprocessor.pendingLabel),
                inst: preprocessor.literals[0].inst
            } : ObjectInstructionWithLabel)
        ].concat(preprocessor.literals.slice(1)) else [];

        return {
            instructions: preprocessor.instructions.concat(literals),
            startLabel: (preprocessor.startLabel : Nullable<String>).getOrThrow(),
            withEndLabel: preprocessor.pendingLabel,
        };
    }

    function run(src:Array<ParsedInstructionWithLine>) {
        // TODO: warning は Parser に移す
        for (inst in src) {
            switch (inst.value.inst) {
                case A(i):
                    switch (i) {
                        case START(label):
                            startLabel = label.getOrElse(inst.value.label.getOrThrow());
                            pendingLabel = [inst.value.label.getOrThrow(() -> new Exception("StartEndChecker を通してください."))];
                        case END:
                        case DS(words):
                            if (words == 0) {
                                inst.value.label.iter(label -> pendingLabel.push(label));
                            } else {
                                instructions.push({
                                    label: inst.value.label.map(l -> [l]).getOrElse([]).concat(pendingLabel),
                                    inst: Data(new Word(0)),
                                });
                                pendingLabel = [];
                                for (i in 1...words) {
                                    instructions.push({
                                        label: [],
                                        inst: Data(new Word(0)),
                                    });
                                }
                            }
                        case DC(values):
                            if (values.length == 0) {
                                trace("DCは1つ以上定数を指定してください. DC 0 として扱います.");
                                values = [new Word(0)];
                            }
                            instructions.push({
                                label: inst.value.label.map(l -> [l]).getOrElse([]).concat(pendingLabel),
                                inst: Data(values[0]),
                            });
                            pendingLabel = [];
                            for (i in 1...values.length) {
                                instructions.push({
                                    label: [],
                                    inst: Data(values[i]),
                                });
                            }
                        case IN(dataBuf, lengthBuf):
                            trace("not implemeted...");
                        case OUT(dataBuf, lengthBuf):
                            trace("not implemeted...");
                        case RPUSH:
                            instructions.push({
                                label: inst.value.label.map(l -> [l]).getOrElse([]).concat(pendingLabel),
                                inst: J({
                                    mnemonic: PUSH,
                                    addr: Const(new Word(0)),
                                    x: new I1to7(1)
                                }),
                            });
                            pendingLabel = [];
                            for (i in 2...8) {
                                instructions.push({
                                    label: [],
                                    inst: J({
                                        mnemonic: PUSH,
                                        addr: Const(new Word(0)),
                                        x: new I1to7(1)
                                    }),
                                });
                            }
                        case RPOP:
                            instructions.push({
                                label: inst.value.label.map(l -> [l]).getOrElse([]).concat(pendingLabel),
                                inst: P({
                                    mnemonic: POP,
                                    r: new I0to7(7),
                                }),
                            });
                            pendingLabel = [];
                            final iter = [for (i in 1...7) i];
                            iter.reverse();
                            for (i in iter) {
                                instructions.push({
                                    label: [],
                                    inst: P({
                                        mnemonic: POP,
                                        r: new I0to7(7),
                                    }),
                                });
                            }
                    }
                case I(i):
                    instructions.push({
                        label: inst.value.label.map(l -> [l]).getOrElse([]).concat(pendingLabel),
                        inst: I(processIOperand(i)),
                    });
                    pendingLabel = [];
                case J(i):
                    instructions.push({
                        label: inst.value.label.map(l -> [l]).getOrElse([]).concat(pendingLabel),
                        inst: J(processJOperand(i)),
                    });
                    pendingLabel = [];
                case R(i):
                    instructions.push({
                        label: inst.value.label.map(l -> [l]).getOrElse([]).concat(pendingLabel),
                        inst: R(i),
                    });
                    pendingLabel = [];
                case P(i):
                    instructions.push({
                        label: inst.value.label.map(l -> [l]).getOrElse([]).concat(pendingLabel),
                        inst: P(i),
                    });
                    pendingLabel = [];
                case N(i):
                    instructions.push({
                        label: inst.value.label.map(l -> [l]).getOrElse([]).concat(pendingLabel),
                        inst: N(i),
                    });
                    pendingLabel = [];
            }
        }
    }

    static function preprocessLiteral(addr:ParsedAddr, genLiteralLabel:() -> String):Tuple2<ObjectAddr, Array<ObjectInstructionWithLabel>> {
        return switch (addr) {
            case Label(label):
                new Tuple2(ObjectAddr.Label(label), []);
            case Const(value):
                new Tuple2(ObjectAddr.Const(value), []);
            case Literal(values):
                if (values.length == 0) {
                    trace("文字列は一文字以上必要です. '\\0' として扱います.");
                    values = [new Word(0)];
                }
                final label = genLiteralLabel();
                final data = ([{label: [label], inst: Data(values[0])}] : Array<ObjectInstructionWithLabel>);
                final data = data.concat([for (v in values.slice(1)) {label: [], inst: Data(v)}]);
                new Tuple2(ObjectAddr.Label(label), data);
        }
    }

    function processIOperand(o:ParsedIInstruction):ObjectIInstruction {
        final addr = preprocessLiteral(o.addr, genLiteralLabel);
        literals = literals.concat(addr.value2);
        return {
            mnemonic: o.mnemonic,
            r: o.r,
            x: o.x,
            addr: addr.value1,
        };
    }

    function processJOperand(o:ParsedJInstruction):ObjectJInstruction {
        final addr = preprocessLiteral(o.addr, genLiteralLabel);
        literals = literals.concat(addr.value2);
        return {
            mnemonic: o.mnemonic,
            x: o.x,
            addr: addr.value1,
        };
    }
}
