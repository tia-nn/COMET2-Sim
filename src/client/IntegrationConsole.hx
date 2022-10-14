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
        return jsx('<div>
            <$Casl2Console onCompile=${(p) -> setState({program: p})} />
            <hr />
            <$Comet2Display program=${state.program} />
        </div>');
    }
}

typedef IntegrationConsoleState = {
    final program:{text:ReadOnlyArray<Word>, entry:Int};
};
