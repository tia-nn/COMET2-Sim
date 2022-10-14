package client;

import js.Browser;
import react.ReactComponent;
import react.ReactDOM;
import react.ReactMacro.jsx;

class App extends ReactComponent {
    override function render():ReactFragment {
        return jsx('<main className="container mx-auto">
            <h1 className="text-3xl">Comet-II Core Simulator</h1>
            <$Comet2Display/>
        </main>');
    }

    static function main() {
        ReactDOM.render(jsx('<App />'), Browser.document.getElementById("app"));
    }
}
