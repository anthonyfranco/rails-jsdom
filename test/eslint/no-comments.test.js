"use strict"

const { describe, it } = require("node:test")
const { RuleTester } = require("eslint")
const noComments = require("../../eslint/no-comments")

RuleTester.describe = describe
RuleTester.it = it
RuleTester.itOnly = it.only

const tester = new RuleTester({ languageOptions: { ecmaVersion: 2022, sourceType: "module" } })
const comment = { messageId: "comment" }

tester.run("no-comments", noComments, {
  valid: [
    "/** Starts the runner. */\nfunction start() {}",
    "/** A page. */\nclass Page {}",
    "class Page {\n  /** Loads it. */\n  load() {}\n  /** Its title. */\n  title = \"\"\n}",
    "/** The horizon in milliseconds. */\nconst HORIZON = 1000",
    "/** The runner. */\nexport function start() {}",
    "/** The default page. */\nexport default class {}",
    "const value = 1"
  ],
  invalid: [
    { code: "// explains\nconst value = 1", errors: [comment] },
    { code: "/* explains */\nconst value = 1", errors: [comment] },
    { code: "const value = 1 // explains", errors: [comment] },
    { code: "/** Floating. */\n\nconst value = 1", errors: [comment] },
    { code: "/** Inside an expression. */\nvalue = 1", errors: [comment] },
    { code: "function start() {\n  /** Not a declaration. */\n  return 1\n}", errors: [comment] },
    { code: "const value = 1\n/** At the end. */", errors: [comment] }
  ]
})
