package client;

import extype.ReadOnlyArray;
import react.ReactComponent.ReactComponentOf;
import react.ReactComponent.ReactFragment;
import react.ReactMacro.jsx;
import types.Word;

class IntegrationConsole extends ReactComponentOf<{}, IntegrationConsoleState> {
    public function new(props) {
        super(props);
        state = {
            program: {text: [], entry: 0},
        };
    }

    override function render():ReactFragment {
        return jsx('<main className="container mx-auto">
            <h1 className="text-3xl">Comet-II Core Simulator</h1>

            <div className="flex">
            <section className="flex-1 p-2"> assembler section
                <$Casl2Console onCompile=${_ -> {}} onSendButtonClick=${p -> setState({program: p})} />
            </section>
            <section className="flex-1 p-2"> machine section
                <$Comet2Display program=${state.program} />
            </section>
            </div>
        </main>');

    }
}

typedef IntegrationConsoleState = {
    final program:{text:ReadOnlyArray<Word>, entry:Int};
};
