package client;

import comet2.Comet2Core;
import comet2.FrozenComet2Core;
import comet2.Instruction;
import extype.Nullable;
import extype.ReadOnlyArray;
import extype.Result;
import react.ReactComponent;
import react.ReactMacro.jsx;
import types.Word;

using StringTools;
using comet2.InstructionTools;

class Comet2Display extends ReactComponentOf<Comet2DisplayProps, Comet2DisplayState> {
    var machine:Comet2Core;

    public function new(props) {
        super(props);
        machine = new Comet2Core([]);
        state = {
            machine: machine.frozen(),
            memoryRenderAddr: "000",
            lastPR: 0,
            lastInst: Success(N({mnemonic: NOP})),
        };
    }

    override function render():ReactFragment {
        final lastInstStr = switch (state.lastInst) {
            case Success(value):
                value.toString();
            case Failure(error):
                'Invalid Instruction (0x${error.hex(4)})';
        }
        final maybeNextInst = state.machine.memory[state.machine.PR].toInstruction(state.machine.memory[state.machine.PR + 1]);
        final nextInstStr = switch (maybeNextInst) {
            case Success(value):
                value.toString();
            case Failure(error):
                'Invalid Instruction (0x${error.hex(4)})';
        }

        return jsx('<div>

            <button onClick=${onStepButtonClick}>step</button>

            <div>
                <span>GR0: <input value=${state.machine.GR[0]} readOnly /></span>
                <span>GR1: <input value=${state.machine.GR[1]} readOnly /></span>
                <span>GR2: <input value=${state.machine.GR[2]} readOnly /></span>
                <span>GR3: <input value=${state.machine.GR[3]} readOnly /></span>
            </div>
            <div>
                <span>GR4: <input value=${state.machine.GR[4]} readOnly /></span>
                <span>GR5: <input value=${state.machine.GR[5]} readOnly /></span>
                <span>GR6: <input value=${state.machine.GR[6]} readOnly /></span>
                <span>GR7: <input value=${state.machine.GR[7]} readOnly /></span>
            </div>

            <div>
                <span>SP: <input value=${state.machine.SP} readOnly /></span>
                <span>PR: <input value=${state.machine.PR} readOnly /></span>
            </div>

            <div>
                FR:
                <span>ZF: <input value=${state.machine.FR.ZF} readOnly /></span>
                <span>SF: <input value=${state.machine.FR.SF} readOnly /></span>
                <span>OF: <input value=${state.machine.FR.OF} readOnly /></span>
            </div>

            <p>last: ${lastInstStr}</p>
            <p>next: ${nextInstStr}</p>

            <hr/>
            <h4>CSR</h4>

            <div>
                <span>PTR: <input value=${state.machine.PTR} readOnly /></span>
            </div>

            <div>
                IE:
                <span>E: <input value=${state.machine.IE.external} readOnly /></span>
                <span>T: <input value=${state.machine.IE.timer} readOnly /></span>
                <span>S: <input value=${state.machine.IE.software} readOnly /></span>
            </div>

            <div>
                IW:
                <span>E: <input value=${state.machine.IW.external} readOnly /></span>
                <span>T: <input value=${state.machine.IW.timer} readOnly /></span>
                <span>S: <input value=${state.machine.IW.software} readOnly /></span>
            </div>

            <div>
                <span>TVEC: <input value=${state.machine.TVEC} readOnly /></span>
            </div>

            <div>
                <span>EPR: <input value=${state.machine.EPR} readOnly /></span>
                <span>CAUSE: <input value=${state.machine.CAUSE} readOnly /></span>
                <span>TVAL: <input value=${state.machine.TVAL} readOnly /></span>
                <span>SCRATCH: <input value=${state.machine.SCRATCH} readOnly /></span>
            </div>

            <div>
                STATUS:
                <span>PPL: <input value=${state.machine.STATUS.PPL} readOnly /></span>
                <span>PL: <input value=${state.machine.STATUS.PL} readOnly /></span>
                <span>PIE: <input value=${state.machine.STATUS.PIE} readOnly /></span>
                <span>IE: <input value=${state.machine.STATUS.IE} readOnly /></span>
            </div>

            <hr/>

            0x<input onChange=${onRenderAddrChange} value=${state.memoryRenderAddr} />0

            ${renderMemoryTable()}

        </div>');

    }

    function renderMemoryTable() {
        final addr = Nullable.of(Std.parseInt('0x' + state.memoryRenderAddr)).getOrElse(0) & 0xfff;
        final trArr = [];
        for (row in addr...addr + 16) {
            final i = row * 16;
            final tdArr = [jsx('<td key=${'h-${i.hex(4)}'}>0x${i.hex(4)}</td>')];
            for (col in 0...16) {
                tdArr.push(jsx('<td key=${(i + col).hex()}>${state.machine.memory[i + col].toString("")}</td>'));
            }
            trArr.push(jsx('<tr>${tdArr}</tr>'));
        }
        return jsx('<table>
            <thead>
                <tr>
                    <th></th>
                    <th>0</th>
                    <th>1</th>
                    <th>2</th>
                    <th>3</th>
                    <th>4</th>
                    <th>5</th>
                    <th>6</th>
                    <th>7</th>
                    <th>8</th>
                    <th>9</th>
                    <th>a</th>
                    <th>b</th>
                    <th>c</th>
                    <th>d</th>
                    <th>e</th>
                    <th>f</th>
                </tr>
            </thead>
            <tbody>
                ${trArr}
            </tbody>
        </table>');
    }

    function onStepButtonClick(ev) {
        final lastMachine = machine.frozen();
        final lastPR = lastMachine.PR;
        final lastInst = lastMachine.memory[lastPR].toInstruction(lastMachine.memory[lastPR + 1]);
        machine.step();
        setState({
            machine: machine.frozen(),
            lastPR: lastPR,
            lastInst: lastInst,
        });
    }

    function onRenderAddrChange(ev) {
        setState({memoryRenderAddr: ev.target.value});
    }

    override function componentDidUpdate(prevProps:Comet2DisplayProps, prevState:Comet2DisplayState) {
        if (prevProps.program != props.program) {
            machine = new Comet2Core(props.program.text, props.program.entry);
            setState({machine: machine.frozen()});
        }
    }
}

typedef Comet2DisplayProps = {
    final program:{text:ReadOnlyArray<Word>, entry:Int};
}

typedef Comet2DisplayState = {
    final machine:FrozenComet2Core;
    final memoryRenderAddr:String;
    final lastPR:Int;
    final lastInst:Result<Instruction, Int>;
}
