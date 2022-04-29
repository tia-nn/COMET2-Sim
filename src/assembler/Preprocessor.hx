package assembler;

import Word.I0to7;
import Word.I1to7;
import assembler.Instruction.AAddr;
import assembler.Instruction.DataWord;
import assembler.Instruction.IOperand;
import assembler.Instruction.JOperand;
import assembler.Instruction.PAddr;
import assembler.Instruction.PIOperand;
import assembler.Instruction.PInstOrData;
import assembler.Instruction.PJOperand;
import assembler.Instruction.PMnemonic;
import assembler.Instruction.VInstruction;
import assembler.Instruction.VMMnemonic;
import extype.Exception;
import extype.Nullable;
import extype.Tuple.Tuple2;

class Preprocessor {
    var literalLabelNumber = 0;
    var literals:Array<DataWord> = [];
    var startLabel:Null<String> = null;
    var pendingLabel:Array<String> = [];
    final instructions:Array<PInstOrData>;

    function genLiteralLabel() {
        return '__LITERAL_${literalLabelNumber++}';
    };

    function new() {
        instructions = [];
    }

    public static function preprocess(src:Array<VInstruction>) {
        final preprocessor = new Preprocessor();
        preprocessor.run(src);

        return {
            instructions: preprocessor.instructions.concat(preprocessor.literals.map(d -> Data(d))),
            startLabel: (preprocessor.startLabel : Nullable<String>).getOrThrow()
        };
    }

    function run(src:Array<VInstruction>) {
        for (inst in src) {
            switch (inst.mnemonic) {
                case Machine(mnemonic):
                    instructions.push(Inst({
                        label: inst.label.map(l -> [l]).getOrElse([]).concat(pendingLabel),
                        mnemonic: vmtop(mnemonic),
                    }));
                    pendingLabel = [];

                case Assembler(mnemonic):
                    switch (mnemonic) {
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
                                mnemonic: PUSHj({
                                    addr: Constant(new Word(0)),
                                    x: new I1to7(1)
                                }),
                            }));
                            pendingLabel = [];
                            for (i in 2...8) {
                                instructions.push(Inst({
                                    label: [],
                                    mnemonic: PUSHj({
                                        addr: Constant(new Word(0)),
                                        x: new I1to7(i)
                                    }),
                                }));
                            }
                        case RPOP:
                            instructions.push(Inst({
                                label: inst.label.map(l -> [l]).getOrElse([]).concat(pendingLabel),
                                mnemonic: POPp({
                                    r: new I0to7(7),
                                }),
                            }));
                            pendingLabel = [];
                            final iter = [for (i in 1...7) i];
                            iter.reverse();
                            for (i in iter) {
                                instructions.push(Inst({
                                    label: [],
                                    mnemonic: POPp({
                                        r: new I0to7(i)
                                    }),
                                }));
                            }
                    }
            }
        }
    }

    static function preprocessLiteral(addr:AAddr, genLiteralLabel:() -> String):Tuple2<PAddr, Array<DataWord>> {
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

    function processIOperand(o:IOperand):PIOperand {
        final addr = preprocessLiteral(o.addr, genLiteralLabel);
        literals = literals.concat(addr.value2);
        return {
            r: o.r,
            x: o.x,
            addr: addr.value1,
        };
    }

    function processJOperand(o:JOperand):PJOperand {
        final addr = preprocessLiteral(o.addr, genLiteralLabel);
        literals = literals.concat(addr.value2);
        return {
            x: o.x,
            addr: addr.value1,
        };
    }

    function vmtop(v:VMMnemonic):PMnemonic {
        return switch (v) {
            case LDi(o):
                LDi(processIOperand(o));
            case ADDAi(o):
                ADDAi(processIOperand(o));
            case ADDLi(o):
                ADDLi(processIOperand(o));
            case SUBAi(o):
                SUBAi(processIOperand(o));
            case SUBLi(o):
                SUBLi(processIOperand(o));
            case ANDi(o):
                ANDi(processIOperand(o));
            case ORi(o):
                ORi(processIOperand(o));
            case XORi(o):
                XORi(processIOperand(o));
            case CPAi(o):
                CPAi(processIOperand(o));
            case CPLi(o):
                CPLi(processIOperand(o));

            case JPLj(o):
                JPLj(processJOperand(o));
            case JMIj(o):
                JMIj(processJOperand(o));
            case JNZj(o):
                JNZj(processJOperand(o));
            case JZEj(o):
                JZEj(processJOperand(o));
            case JOVj(o):
                JOVj(processJOperand(o));
            case JUMPj(o):
                JUMPj(processJOperand(o));
            case PUSHj(o):
                PUSHj(processJOperand(o));
            case CALLj(o):
                CALLj(processJOperand(o));
            case SVCj(o):
                SVCj(processJOperand(o));

            case STi(o):
                STi(processIOperand(o));
            case LADi(o):
                LADi(processIOperand(o));
            case SLAi(o):
                SLAi(processIOperand(o));
            case SRAi(o):
                SRAi(processIOperand(o));
            case SLLi(o):
                SLLi(processIOperand(o));
            case SRLi(o):
                SRLi(processIOperand(o));

            case LDr(o):
                LDr(o);
            case ADDAr(o):
                ADDAr(o);
            case ADDLr(o):
                ADDLr(o);
            case SUBAr(o):
                SUBAr(o);
            case SUBLr(o):
                SUBLr(o);
            case ANDr(o):
                ANDr(o);
            case ORr(o):
                ORr(o);
            case XORr(o):
                XORr(o);
            case CPAr(o):
                CPAr(o);
            case CPLr(o):
                CPLr(o);
            case POPp(o):
                POPp(o);
            case RETn:
                RETn;
            case NOPn:
                NOPn;
        }
    }
}
