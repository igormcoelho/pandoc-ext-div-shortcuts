-- debug-ast.lua (Helper for tests!)
function Pandoc(doc)
  io.stderr:write("=== BEGIN AST ===\n")
  io.stderr:write(pandoc.write(doc, 'native'))
  -- io.stderr:write("\n")
  io.stderr:write("\n=== END AST ===\n")
  return doc
end

