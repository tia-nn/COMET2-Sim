package client;

import casl2macro.Casl2MacroExpand;
import casl2macro.StartEndChecker;
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

        }
    }

    override function render():ReactFragment {
        return jsx('<div>
            <textarea value=${state.source} onChange=${onTextAreaChange} rows="20" cols="120"></textarea>
            <div>
                <button onClick=${compile}>compile</button>
                <button>send</button>
            </div>
        </div>');
    }

    function onTextAreaChange(ev) {
        setState({
            source: ev.target.value
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
                return;
        }

        final errors = StartEndChecker.check(node);
        switch (errors) {
            case []:
            case _:
                trace(errors.join("\n"));
                trace("コンパイル失敗");
                return;
        }

        final object = Casl2MacroExpand.macroExpand(node);

        final offset = 0;
        final assembly = casl2.Casl2.assembleAll(object.instructions, object.startLabel, offset);

        props.onCompile(assembly);
    }
}

typedef Casl2ConsoleProps = {
    final onCompile:({text:ReadOnlyArray<Word>, entry:Int}) -> Void;
}

typedef Casl2ConsoleState = {
    final source:String;
};
