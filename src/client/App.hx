package client;

import js.Browser;
import react.ReactComponent;
import react.ReactDOM;
import react.ReactMacro.jsx;
import react.StrictMode;

class App extends ReactComponent {
    override function render():ReactFragment {
        return jsx('<$StrictMode>
            <main className="container mx-auto">
                <$IntegrationConsole />
            </main>
        </$StrictMode>');
    }

    static function main() {
        ReactDOM.render(jsx('<App />'), Browser.document.getElementById("app"));
    }
}
