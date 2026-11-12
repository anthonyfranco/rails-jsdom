"use strict"

const DOCUMENTED = new Set(["FunctionDeclaration", "ClassDeclaration", "MethodDefinition", "PropertyDefinition", "VariableDeclaration", "ExportNamedDeclaration", "ExportDefaultDeclaration"])

function documentedNode(sourceCode, comment) {
  const token = sourceCode.getTokenAfter(comment)
  let node = token && sourceCode.getNodeByRangeIndex(token.range[0])
  while (node && !DOCUMENTED.has(node.type) && node.range[0] === token.range[0]) node = node.parent
  return node && DOCUMENTED.has(node.type) && node.range[0] === token.range[0] ? node : null
}

function isInterfaceDoc(sourceCode, comment) {
  const node = comment.type === "Block" && comment.value.startsWith("*") ? documentedNode(sourceCode, comment) : null
  return Boolean(node) && node.loc.start.line === comment.loc.end.line + 1
}

module.exports = {
  meta: {
    type: "suggestion",
    docs: { description: "Allow only /** */ interface and type docs directly above a declaration" },
    schema: [],
    messages: { comment: "Do not write comments. Put the meaning into a name, a function or a test. Only /** */ docs directly above a declaration are allowed." }
  },
  create(context) {
    const sourceCode = context.sourceCode
    return {
      Program() {
        for (const comment of sourceCode.getAllComments()) {
          if (!isInterfaceDoc(sourceCode, comment)) context.report({ loc: comment.loc, messageId: "comment" })
        }
      }
    }
  }
}
