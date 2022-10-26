package client;

import casl2macro.Casl2MacroExpand;
import casl2macro.StartEndChecker;
import extype.Nullable;
import extype.ReadOnlyArray;
import parser.Parser;
import react.ReactComponent;
import react.ReactMacro.jsx;
import tokenizer.Tokenizer;
import types.Word;

class Casl2Console extends ReactComponentOf<Casl2ConsoleProps, Casl2ConsoleState> {
    public function new(props) {
        super(props);
        state = {
            source: "MAIN START

    lad gr0, 16
    lad gr1, 17

    lad gr4, 0, gr1
    adda gr4, gr0

    lad gr5, 16, gr1

    END
",

            errors: [],
            compiled: null,
        }
    }

    override function render():ReactFragment {
        final errorMessage = state.errors.map(e -> '${e.line + 1} 行目にエラーがあります.').join('\n');

        return jsx('<div>
            <code>
                <textarea value=${state.source} onChange=${onTextAreaChange} className="w-full h-96 p-2 bg-gray-50 rounded" ></textarea>
            </code>
            <div>
                <button onClick=${compile} className="rounded-full px-2 py-1 bg-blue-200 text-gray-900" >compile</button>
                <button disabled=${state.compiled.isEmpty()} onClick=${send} className="disabled:opacity-50 disabled:cursor-not-allowed rounded-full px-2 py-1 bg-green-200 text-gray-900">send</button>
            </div>
            <textarea value=${errorMessage} readOnly className="focus-visible:outline-0 w-full h-40 bg-gray-50 rounded" />
        </div>');
    }

    function onTextAreaChange(ev) {
        setState({
            source: ev.target.value,
            compiled: null
        });
    }

    function compile() {
        final tokens = Tokenizer.tokenize(state.source);
        final node = Parser.parse(tokens);

        final node = switch (node) {
            case Success(r, w):
                if (w.length != 0)
                    trace(w.join("\n"));
                r;
            case Failed(e, w):
                trace(e.join("\n"));
                trace(w.join("\n"));
                trace("コンパイル失敗");

                setState({
                    errors: e.map(e -> {line: e.pos.line, message: e.value}).concat(w.map(w -> {line: w.pos.line, message: w.value}))
                });

                return;
        }

        final errors = StartEndChecker.check(node);
        switch (errors) {
            case []:
            case _:
                trace(errors.join("\n"));
                trace("コンパイル失敗");

                setState({errors: errors.map(a -> a)});

                return;
        }

        final object = Casl2MacroExpand.macroExpand(node);

        final offset = 0;
        final assembly = casl2.Casl2.assembleAll(object.instructions, object.startLabel, offset);

        setState({compiled: assembly});
        props.onCompile(assembly);
    }

    function send() {
        state.compiled.iter(props.onSendButtonClick);
    }
}

typedef Casl2ConsoleProps = {
    final onCompile:({text:ReadOnlyArray<Word>, entry:Int}) -> Void;
    final onSendButtonClick:({text:ReadOnlyArray<Word>, entry:Int}) -> Void;
}

typedef Casl2ConsoleState = {
    final source:String;
    final errors:Array<{line:Int, message:String}>;
    final compiled:Nullable<{text:ReadOnlyArray<Word>, entry:Int}>;
};
