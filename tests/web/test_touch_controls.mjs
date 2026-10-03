import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';

function production() {
  const html = readFileSync(new URL('../../web/shell.html', import.meta.url), 'utf8');
  const script = html.match(/<script id="touch-input">([\s\S]*?)<\/script>/);
  assert.ok(script, 'the export shell must contain its touch input implementation');
  const context = vm.createContext({});
  vm.runInContext(script[1], context);
  return context.YesterselfMobile;
}

class Button extends EventTarget {
  disabled = false;
  textContent = '';
  classList = { toggle() {} };
  setPointerCapture() {}
}

function controls() {
  const { TouchControls } = production();
  const buttons = Object.fromEntries(['move_left', 'move_right', 'jump', 'commit', 'retry', 'undo', 'pause'].map(action => [action, new Button()]));
  const dock = { hidden: true };
  const caption = { textContent: '' };
  const events = [];
  const input = new TouchControls(buttons, dock, caption);
  input.bind_input((action, pressed) => events.push([action, pressed]));
  input.set_touch_enabled(true);
  input.set_mode('play');
  return { input, buttons, dock, caption, events };
}

function pointer(button, type, pointerId) {
  const event = new Event(type, { cancelable: true });
  event.pointerId = pointerId;
  event.button = 0;
  button.dispatchEvent(event);
}

test('two fingers can hold movement and jump independently', () => {
  const { buttons, events } = controls();
  pointer(buttons.move_right, 'pointerdown', 1);
  pointer(buttons.jump, 'pointerdown', 2);
  pointer(buttons.jump, 'pointerup', 2);
  assert.deepEqual(events, [['move_right', true], ['jump', true], ['jump', false]]);
  pointer(buttons.move_right, 'pointerup', 1);
  assert.deepEqual(events.at(-1), ['move_right', false]);
});

test('a cancelled or lost pointer cannot leave a movement held', () => {
  const { buttons, events } = controls();
  pointer(buttons.move_left, 'pointerdown', 3);
  pointer(buttons.move_left, 'pointercancel', 3);
  pointer(buttons.move_left, 'lostpointercapture', 3);
  assert.deepEqual(events, [['move_left', true], ['move_left', false]]);
});

test('two fingers on the same action require both to release', () => {
  const { buttons, events } = controls();
  pointer(buttons.move_left, 'pointerdown', 1);
  pointer(buttons.move_left, 'pointerdown', 2);
  pointer(buttons.move_left, 'pointerup', 1);
  assert.deepEqual(events, [['move_left', true]]);
  pointer(buttons.move_left, 'pointerup', 2);
  assert.deepEqual(events.at(-1), ['move_left', false]);
});

test('pause releases held actions and keeps a touch resume available', () => {
  const { input, buttons, events, dock } = controls();
  pointer(buttons.jump, 'pointerdown', 1);
  input.set_mode('pause');
  assert.deepEqual(events.at(-1), ['jump', false]);
  assert.equal(buttons.jump.disabled, true);
  assert.equal(buttons.pause.disabled, false);
  assert.equal(buttons.pause.textContent, 'Resume');
  assert.equal(dock.hidden, false);
  pointer(buttons.jump, 'pointerdown', 2);
  pointer(buttons.pause, 'pointerdown', 3);
  assert.deepEqual(events.at(-1), ['pause', true]);
});

test('menu navigation and focus loss release all held actions', () => {
  const { input, buttons, events, dock } = controls();
  pointer(buttons.move_right, 'pointerdown', 1);
  pointer(buttons.jump, 'pointerdown', 2);
  input.release_all();
  assert.deepEqual(events.slice(-2), [['move_right', false], ['jump', false]]);
  pointer(buttons.move_left, 'pointerdown', 3);
  input.set_mode('menu');
  assert.deepEqual(events.at(-1), ['move_left', false]);
  assert.equal(dock.hidden, true);
});

test('a layout or orientation change clears a held direction', () => {
  const { input, buttons, events } = controls();
  pointer(buttons.move_right, 'pointerdown', 1);
  input.set_touch_enabled(true);
  assert.deepEqual(events.at(-1), ['move_right', false]);
});

test('phone and landscape canvas sizes preserve the entire game aspect', () => {
  const { fitCanvas } = production();
  for (const [width, height] of [[390, 640], [320, 520], [844, 268], [667, 245]]) {
    const fit = fitCanvas(width, height, true);
    assert.ok(fit.width <= width && fit.height <= height);
    assert.ok(Math.abs(fit.width / fit.height - 16 / 9) < 0.01);
  }
  const desktop = fitCanvas(1440, 800, false);
  assert.equal(desktop.width % 480, 0);
  assert.equal(desktop.height % 270, 0);
});

test('new game packages get different asset URLs while the engine sees a plain pack filename', () => {
  const { packAssetUrl } = production();
  assert.equal(packAssetUrl('index.pck', 'abc123'), 'index.pck?v=abc123');
  assert.notEqual(packAssetUrl('index.pck', 'abc123'), packAssetUrl('index.pck', 'def456'));
});
