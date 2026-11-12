"use strict"

const { test, before, beforeEach } = require("node:test")
const assert = require("node:assert/strict")
const { HOST, connect, prepare, clear } = require("./support")

const runner = connect()

before(() => prepare(runner))
beforeEach(() => clear(runner))

const read = script => runner.evaluate(script)
const type = (keys, selector) => selector ? runner.evaluate(`document.querySelector("${selector}").focus()`).then(() => runner.run({ command: "send_keys", keys })) : runner.run({ command: "send_keys", keys })
const text = value => ({ text: value })
const key = (name, modifiers) => modifiers ? { key: name, modifiers } : { key: name }

test("send_keys by handle focuses the element first", async () => {
  await runner.load(`<input id="a">`)
  const [field] = await runner.run({ command: "query", strategy: "css", locator: "#a", scope: [] })
  await runner.run({ command: "element", handle: field.handle, action: "send_keys", keys: [text("hi")] })

  assert.equal(await read("a.value"), "hi")
})

test("characters dispatch keydown, keypress, input and keyup with their key and code", async () => {
  await runner.load(`<input id="a"><script>window.events = []; for (const type of ["keydown", "keypress", "input", "keyup"]) a.addEventListener(type, e => events.push([type, e.key ?? e.data, e.code ?? e.inputType].join(" ")))</script>`)
  await type([text("a7 ")], "#a")

  assert.deepEqual(await read("events"), [
    "keydown a KeyA", "keypress a KeyA", "input a insertText", "keyup a KeyA",
    "keydown 7 Digit7", "keypress 7 Digit7", "input 7 insertText", "keyup 7 Digit7",
    "keydown   Space", "keypress   Space", "input   insertText", "keyup   Space"
  ])
})

test("modifiers are set on the key events and a held control key types nothing", async () => {
  await runner.load(`<input id="a" onkeydown="window.seen = [event.shiftKey, event.ctrlKey, event.altKey, event.metaKey]">`)
  await type([{ text: "a", modifiers: ["shift", "ctrl", "alt", "command"] }], "#a")

  assert.deepEqual(await read("[seen, a.value]"), [[true, true, true, true], ""])
})

test("a prevented keydown or keypress stops the character", async () => {
  await runner.load(`<input id="a" onkeydown="if (event.key === 'x') event.preventDefault()" onkeypress="if (event.key === 'y') event.preventDefault()">`)
  await type([text("axyb")], "#a")

  assert.equal(await read("a.value"), "ab")
})

test("backspace deletes the last character, and does nothing in an empty field", async () => {
  await runner.load(`<input id="a" value="ab"><input id="e" oninput="window.fired = true">`)
  await type([key("backspace")], "#a")
  await type([key("backspace")], "#e")

  assert.deepEqual(await read("[a.value, window.fired]"), ["a", null])
})

test("keys do not edit a disabled or read-only field", async () => {
  await runner.load(`<input id="r" readonly value="r">`)
  await type([text("x"), key("backspace")], "#r")

  assert.equal(await read("r.value"), "r")
})

test("enter in a textarea adds a new line", async () => {
  await runner.load(`<textarea id="t">a</textarea>`)
  await type([key("enter"), text("b")], "#t")

  assert.equal(await read("t.value"), "a\nb")
})

test("enter clicks a focused link or button", async () => {
  await runner.load(`<button id="b" onclick="window.pressed = 'button'">B</button><a id="l" href="#x" onclick="window.followed = true">L</a>`)
  await type([key("enter")], "#b")
  await type([key("enter")], "#l")

  assert.deepEqual(await read("[pressed, followed]"), ["button", true])
})

test("enter in a field submits its form through the first submit button", async () => {
  await runner.load(`<form action="/a"><input id="q" name="q" value="x"><button type="button">No</button><button name="via" value="go">Go</button></form>`)
  await type([key("enter")], "#q")

  assert.equal(runner.requests[0].url, `${HOST}/a?q=x&via=go`)
})

test("enter in a field of a form without a submit button submits the form", async () => {
  await runner.load(`<form action="/b"><input id="q" name="q" value="y"></form>`)
  await type([key("enter")], "#q")

  assert.equal(runner.requests[0].url, `${HOST}/b?q=y`)
})

test("enter outside a form, or on a field that is not text, does nothing", async () => {
  await runner.load(`<input id="loose"><form action="/c"><input type="checkbox" id="c"></form>`)
  await type([key("enter")], "#loose")
  await type([key("enter")], "#c")

  assert.equal(runner.requests.length, 0)
})

test("space presses a focused button or checkbox", async () => {
  await runner.load(`<button id="b" onclick="window.pressed = true">B</button><input type="checkbox" id="c">`)
  await type([key("space")], "#b")
  await type([key("space")], "#c")

  assert.deepEqual(await read("[pressed, c.checked]"), [true, true])
})

test("arrow keys, home and end step range and number fields", async () => {
  await runner.load(`<input type="range" id="r" min="2" max="8" value="5"><input type="range" id="d" value="50"><input type="number" id="n" value="1">`)
  await type([key("right"), key("up"), key("left")], "#r")
  const stepped = await read("r.value")
  await type([key("home")], "#r")
  const lowest = await read("r.value")
  await type([key("end")], "#r")
  const highest = await read("r.value")
  await type([key("home")], "#d")
  const defaultLowest = await read("d.value")
  await type([key("end")], "#d")
  await type([key("down")], "#n")

  assert.deepEqual([stepped, lowest, highest, defaultLowest, await read("d.value"), await read("n.value")], ["6", "2", "8", "0", "100", "0"])
})

test("keys without a default action, or on an element they do not affect, only dispatch events", async () => {
  await runner.load(`<input type="range" id="r" value="5"><p id="p" tabindex="0">P</p><script>window.keys = []; document.addEventListener("keydown", e => keys.push(e.key))</script>`)
  await type([key("escape"), key("delete"), key("page_up"), key("page_down")], "#r")
  await type([text("x")], "#p")

  assert.deepEqual(await read("[keys, r.value]"), [["Escape", "Delete", "PageUp", "PageDown", "x"], "5"])
})

test("tab moves focus in tab order, positive tabindex first, skipping disabled, hidden and negative tabindex", async () => {
  await runner.load(`<input id="a"><input id="off" disabled><input id="gone" hidden><input id="skip" tabindex="-1"><input id="b"><input id="two" tabindex="2"><input id="one" tabindex="1">`)
  const order = []
  await type([key("tab")])
  for (let index = 0; index < 4; index += 1) {
    order.push(await read("document.activeElement.id"))
    await type([key("tab")])
  }

  assert.deepEqual(order, ["one", "two", "a", "b"])
  assert.equal(await read("document.activeElement.id"), "one")
})

test("shift+tab moves focus back, and from the page to the last element", async () => {
  await runner.load(`<input id="a"><input id="b">`)
  await type([key("tab", ["shift"])])
  const fromPage = await read("document.activeElement.id")
  await type([key("tab", ["shift"])])

  assert.deepEqual([fromPage, await read("document.activeElement.id")], ["b", "a"])
})

test("tab fires change on a field whose typed value changed", async () => {
  await runner.load(`<input id="a" onchange="window.changes = (window.changes || 0) + 1"><input id="b">`)
  await type([text("x"), key("backspace"), key("tab")], "#a")
  const unchanged = await read("window.changes")
  await type([text("y"), key("tab")], "#a")

  assert.deepEqual([unchanged, await read("window.changes")], [null, 1])
})

test("tab on a page with nothing to focus keeps the focus where it is", async () => {
  await runner.load(`<p>Nothing to focus</p>`)
  await type([key("tab")])

  assert.equal(await read("document.activeElement.localName"), "body")
})

test("an unknown key or modifier fails", async () => {
  await runner.load(`<input id="a">`)

  await assert.rejects(type([key("launch")], "#a"), /unknown key launch/)
  await assert.rejects(type([{ text: "a", modifiers: ["hyper"] }], "#a"), /unknown modifier key hyper/)
})

test("escape cancels and closes the last modal dialog opened, leaving other dialogs open", async () => {
  await runner.load(`<dialog id="info"></dialog><dialog id="outer"></dialog><dialog id="inner"><input id="a"></dialog><script>
    window.events = []
    for (const dialog of document.querySelectorAll("dialog")) for (const type of ["cancel", "close"]) dialog.addEventListener(type, () => events.push(\`\${dialog.id} \${type}\`))
    info.show(); outer.showModal(); inner.showModal()
  </script>`)
  await type([key("escape")], "#a")
  await type([key("escape")], "#a")

  assert.deepEqual(await read("[events, info.open, outer.open, inner.open]"), [["inner cancel", "inner close", "outer cancel", "outer close"], true, false, false])
})

test("escape leaves a modal dialog open when its cancel event or the key is prevented", async () => {
  await runner.load(`<dialog id="d" oncancel="event.preventDefault()"><input id="a"><input id="b" onkeydown="event.preventDefault()"></dialog><dialog id="e"><input id="c"></dialog><script>d.showModal(); e.showModal()</script>`)
  await type([key("escape")], "#a")
  await type([key("escape")], "#b")
  await read("e.close()")
  await type([key("escape")], "#a")

  assert.deepEqual(await read("[d.open, e.open]"), [true, false])
})

test("escape with no modal dialog open does nothing", async () => {
  await runner.load(`<dialog id="d"><input id="a"></dialog><script>d.show()</script>`)
  await type([key("escape")], "#a")

  assert.equal(await read("d.open"), true)
})
