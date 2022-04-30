package preprocessor;

import parser.InstructionDefinition;

class StartEndChecker {
    public static function check(src:Array<ParsedInstructionWithLine>):Array<{message:String, line:Int}> {
        final errors:Array<{message:String, line:Int}> = [];
        final shouldBeStart = src[0];
        final shouldBeEnd = src[src.length - 1];
        final shouldNotExistStartEnd = src.slice(1, src.length - 1);

        switch (shouldBeStart.value.inst) {
            case A(START(label)):
            case _:
                errors.push({message: '最初に START 命令が必要です.', line: shouldBeStart.line});
        }

        switch (shouldBeEnd.value.inst) {
            case A(END):
            case _:
                errors.push({message: '最後に END 命令が必要です.', line: shouldBeEnd.line});
        }

        for (inst in shouldNotExistStartEnd) {
            switch (inst.value.inst) {
                case A(START(label)):
                    errors.push({message: 'START 命令は最初しか使えません.', line: inst.line});
                case A(END):
                    errors.push({message: 'END 命令は最後しか使えません.', line: inst.line});
                case _:
            }
        }

        final starts = src.filter(inst -> inst.value.inst.match(A(START(_))));
        final ends = src.filter(inst -> inst.value.inst.match(A(END)));

        for (inst in starts) {
            if (inst.value.label.isEmpty()) {
                errors.push({message: 'START 命令にはラベルが必要です.', line: inst.line});
            }
        }

        for (inst in ends) {
            if (inst.value.label.nonEmpty()) {
                errors.push({message: 'END 命令にはラベルを付けられません.', line: inst.line});
            }
        }

        return errors;
    }
}
