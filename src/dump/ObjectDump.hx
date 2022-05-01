package dump;

import casl2macro.Casl2MacroExpand.ObjectFile;
import haxe.io.Bytes;
import sys.io.File;
import sys.io.FileOutput;

class ObjectDump {
    public static function dump(object:ObjectFile, ?file:FileOutput) {
        if (file == null) {
            file = File.write("dump.casl", false);
        }

        final start = '; ${object.programLabel} START ${object.startLabel}\n';
        final text = [];
        for (inst in object.instructions) {
            final label = inst.label.join("\n") + "    ";
            final instruction = switch (inst.inst) {
                case R(i):
                    '${i.mnemonic.getName()} GR${i.r1} GR${i.r2}';
                case I(i):
                    final adr = switch (i.addr) {
                        case Label(l):
                            l;
                        case Const(v):
                            '#${v.toString()} (${v.toSigned()})';
                    }
                    final x = switch (i.x.toMaybe()) {
                        case Some(x):
                            ', GR${x}';
                        case None:
                            '';
                    }
                    '${i.mnemonic.getName()} GR${i.r}, ${adr}${x}';
                case J(i):
                    final adr = switch (i.addr) {
                        case Label(l):
                            l;
                        case Const(v):
                            '#${v.toString()} (${v.toSigned()})';
                    }
                    final x = switch (i.x.toMaybe()) {
                        case Some(x):
                            ', GR${x}';
                        case None:
                            '';
                    }
                    '${i.mnemonic.getName()} ${adr}${x}';
                case P(i):
                    '${i.mnemonic.getName()} GR${i.r}';
                case N(i):
                    '${i.mnemonic.getName()}';
                case Data(d):
                    'DC #${d.toString()} (${d.toSigned()})';
            }
            text.push(label + " " + instruction);
        }

        final text = text.join("\n");

        final r = start + text + "\n" + object.withEndLabel.join("\n");
        file.write(Bytes.ofString(r));
    }
}
