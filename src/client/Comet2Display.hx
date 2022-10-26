package client;

import comet2.Comet2Core;
import comet2.FrozenComet2Core;
import comet2.Instruction;
import extype.Nullable;
import extype.ReadOnlyArray;
import extype.Result;
import js.html.CanvasElement;
import js.html.ImageData;
import react.ReactComponent;
import react.ReactMacro.jsx;
import types.Word;

using StringTools;
using comet2.BoolTools;
using comet2.InstructionTools;

class Comet2Display extends ReactComponentOf<Comet2DisplayProps, Comet2DisplayState> {
    var machine:Comet2Core;
    var canvasEl:CanvasElement;

    public function new(props) {
        super(props);
        machine = new Comet2Core([]);
        final frozen = machine.frozen();
        state = {
            machine: frozen,
            memoryRenderAddr: "000",
            lastPR: 0,
            lastInst: Success(N({mnemonic: NOP})),
            canvasHeight: 160,
            canvasWidth: 320,
            framebuffer: 0x1000,
            imageData: createImageData(frozen.memory, 0, 320, 160),
            displayAllMemory: false,
            stepN: 100
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

        return jsx('<div className="flex gap-2 flex-col">

            <div className="flex gap-2">

                <button onClick=${onStepButtonClick} className="rounded-full px-2 py-1 bg-red-100 text-gray-900">step</button>
                <button onClick=${onNStepButtonClick} className="rounded-full px-2 py-1 bg-red-100 text-gray-900">
                    <input onChange=${e -> setState({stepN: e.target.value})} onClick=${e -> e.stopPropagation()} value=${state.stepN} type="Number" className="p-1 w-20 text-sm" />
                    step
                </button>
                <button onClick=${onIntButtonClick} className="rounded-full px-2 py-1 bg-green-100 text-gray-900" >INT</button>

            </div>

            <div className="flex flex-wrap gap-x-4 gap-y-2">
                <label>GR0: <input value=${state.machine.GR[0]} readOnly className="w-14 p-1 bg-gray-100" /> (0x${state.machine.GR[0].hex(4)}) </label>
                <label>GR1: <input value=${state.machine.GR[1]} readOnly className="w-14 p-1 bg-gray-100" /> (0x${state.machine.GR[1].hex(4)}) </label>
                <label>GR2: <input value=${state.machine.GR[2]} readOnly className="w-14 p-1 bg-gray-100" /> (0x${state.machine.GR[2].hex(4)}) </label>
                <label>GR3: <input value=${state.machine.GR[3]} readOnly className="w-14 p-1 bg-gray-100" /> (0x${state.machine.GR[3].hex(4)}) </label>
                <label>GR4: <input value=${state.machine.GR[4]} readOnly className="w-14 p-1 bg-gray-100" /> (0x${state.machine.GR[4].hex(4)}) </label>
                <label>GR5: <input value=${state.machine.GR[5]} readOnly className="w-14 p-1 bg-gray-100" /> (0x${state.machine.GR[5].hex(4)}) </label>
                <label>GR6: <input value=${state.machine.GR[6]} readOnly className="w-14 p-1 bg-gray-100" /> (0x${state.machine.GR[6].hex(4)}) </label>
                <label>GR7: <input value=${state.machine.GR[7]} readOnly className="w-14 p-1 bg-gray-100" /> (0x${state.machine.GR[7].hex(4)}) </label>
            </div>

            <div className="flex flex-wrap gap-x-4 gap-y-2">
                <label>SP: <input value=${state.machine.SP} readOnly className="w-14 p-1 bg-gray-100" /> (0x${state.machine.SP.hex(4)}) </label>
                <label>PR: <input value=${state.machine.PR} readOnly className="w-14 p-1 bg-gray-100" /> (0x${state.machine.PR.hex(4)}) </label>
            </div>

            <div className="flex flex-wrap gap-x-4 gap-y-2">
                <span className="mr-3">FR:</span>
                <label>ZF: <input value=${state.machine.FR.ZF.toInt()} readOnly className="w-5 p-1 bg-gray-100" /></label>
                <label>SF: <input value=${state.machine.FR.SF.toInt()} readOnly className="w-5 p-1 bg-gray-100" /></label>
                <label>OF: <input value=${state.machine.FR.OF.toInt()} readOnly className="w-5 p-1 bg-gray-100" /></label>
            </div>

            <p>last: ${lastInstStr}</p>
            <p>next: ${nextInstStr}</p>

            <hr/>

            <h4>Display</h4>

            <canvas ref=${r -> {canvasEl = r;}} height=${state.canvasHeight} width=${state.canvasWidth}></canvas>

            <hr/>

            <h4>CSR</h4>

            <div>
                <label>PTR: <input value=${state.machine.PTR} readOnly className="w-14 p-1 bg-gray-100" /> (0x${state.machine.PTR.hex(4)}) </label>
            </div>

            <div className="flex flex-wrap gap-x-4 gap-y-2">
                IE:
                <label>E: <input value=${state.machine.IE.external.toInt()} readOnly className="w-5 p-1 bg-gray-100" /></label>
                <label>T: <input value=${state.machine.IE.timer.toInt()} readOnly className="w-5 p-1 bg-gray-100" /></label>
                <label>S: <input value=${state.machine.IE.software.toInt()} readOnly className="w-5 p-1 bg-gray-100" /></label>
            </div>

            <div className="flex flex-wrap gap-x-4 gap-y-2">
                IW:
                <label>E: <input value=${state.machine.IW.external.toInt()} readOnly className="w-5 p-1 bg-gray-100" /></label>
                <label>T: <input value=${state.machine.IW.timer.toInt()} readOnly className="w-5 p-1 bg-gray-100" /></label>
                <label>S: <input value=${state.machine.IW.software.toInt()} readOnly className="w-5 p-1 bg-gray-100" /></label>
            </div>

            <div>
                <label>TVEC: <input value=${state.machine.TVEC} readOnly className="w-14 p-1 bg-gray-100" /> (0x${state.machine.TVEC.hex(4)}) </label>
            </div>

            <div className="flex flex-wrap gap-x-4 gap-y-2">
                <label>EPR: <input value=${state.machine.EPR} readOnly className="w-14 p-1 bg-gray-100" /> (0x${state.machine.EPR.hex(4)}) </label>
                <label>CAUSE: <input value=${state.machine.CAUSE} readOnly className="w-14 p-1 bg-gray-100" /> (0x${state.machine.CAUSE.hex(4)}) </label>
                <label>TVAL: <input value=${state.machine.TVAL} readOnly className="w-14 p-1 bg-gray-100" /> (0x${state.machine.TVAL.hex(4)}) </label>
                <label>SCRATCH: <input value=${state.machine.SCRATCH} readOnly className="w-14 p-1 bg-gray-100" /> (0x${state.machine.SCRATCH.hex(4)}) </label>
            </div>

            <div className="flex flex-wrap gap-x-4 gap-y-2">
                STATUS:
                <label>PPL: <input value=${state.machine.STATUS.PPL.toInt()} readOnly className="w-5 p-1 bg-gray-100" /></label>
                <label>PL: <input value=${state.machine.STATUS.PL.toInt()} readOnly className="w-5 p-1 bg-gray-100" /></label>
                <label>PIE: <input value=${state.machine.STATUS.PIE.toInt()} readOnly className="w-5 p-1 bg-gray-100" /></label>
                <label>IE: <input value=${state.machine.STATUS.IE.toInt()} readOnly className="w-5 p-1 bg-gray-100" /></label>
            </div>

            <hr/>

            <h4>Memory</h4>

            <div>
                <button onClick=${() -> setState({displayAllMemory: !state.displayAllMemory})} className="rounded-full px-2 py-1 bg-red-100">all</button>
            </div>
            <div>
                0x<input onChange=${onRenderAddrChange} value=${state.memoryRenderAddr} className="w-10 p-1 bg-gray-100" />0
            </div>

            ${renderMemoryTable()}

        </div>');

    }

    function renderMemoryTable() {
        final addr = if (state.displayAllMemory) 0 else Nullable.of(Std.parseInt('0x' + state.memoryRenderAddr)).getOrElse(0) & 0xfff;
        final trArr = [];
        final len = if (state.displayAllMemory) Std.int(0x10000 / 16) else 16;
        for (row in addr...addr + len) {
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
        final frozen = machine.frozen();
        final imageData = createImageData(frozen.memory, state.framebuffer, state.canvasWidth, state.canvasHeight);
        setState({
            machine: frozen,
            lastPR: lastPR,
            lastInst: lastInst,
            imageData: imageData,
        });
    }

    function onNStepButtonClick(ev) {
        var lastMachine = machine.frozen();
        var lastPR = lastMachine.PR;
        var lastInst = lastMachine.memory[lastPR].toInstruction(lastMachine.memory[lastPR + 1]);
        for (i in 0...state.stepN) {
            lastMachine = machine.frozen();
            lastPR = lastMachine.PR;
            lastInst = lastMachine.memory[lastPR].toInstruction(lastMachine.memory[lastPR + 1]);
            machine.step();
        }
        final frozen = machine.frozen();
        final imageData = createImageData(frozen.memory, state.framebuffer, state.canvasWidth, state.canvasHeight);
        setState({
            machine: frozen,
            lastPR: lastPR,
            lastInst: lastInst,
            imageData: imageData,
        });
    }

    function onIntButtonClick(ev) {
        machine.externalInterrupt();
        setState({
            machine: machine.frozen(),
        });
    }

    static function createImageData(mem:ReadOnlyArray<Word>, offset, sw:Int, sh:Int) {
        final imageData = new ImageData(sw, sh);
        for (i in 0...Std.int(sw * sh)) {
            final adr = offset + Std.int(i / 16);
            final byte = mem[adr];
            final bit = byte.toBitArray()[i % 16];
            imageData.data[i * 4] = bit * 255;
            imageData.data[i * 4 + 1] = bit * 255;
            imageData.data[i * 4 + 2] = bit * 255;
            imageData.data[i * 4 + 3] = 255;
        }
        return imageData;
    }

    function onRenderAddrChange(ev) {
        setState({memoryRenderAddr: ev.target.value});
    }

    override function componentDidUpdate(prevProps:Comet2DisplayProps, prevState:Comet2DisplayState) {
        if (prevProps.program != props.program) {
            machine = new Comet2Core(props.program.text, props.program.entry);
            final frozen = machine.frozen();
            final imageData = createImageData(frozen.memory, state.framebuffer, state.canvasWidth, state.canvasHeight);
            setState({machine: frozen, imageData: imageData});
        } else {
            final ctx = canvasEl.getContext2d();
            ctx.putImageData(state.imageData, 0, 0);
        }
    }

    override function componentDidMount() {
        final ctx = canvasEl.getContext2d();
        ctx.putImageData(state.imageData, 0, 0);
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
    final canvasHeight:Int;
    final canvasWidth:Int;
    final framebuffer:Int;
    final imageData:ImageData;
    final displayAllMemory:Bool;
    final stepN:Int;
}
