#!/bin/bash

# ======================================
# test2 is a very basic test for SPAN... 
# --------------------------------------

echo '::::: <>{width=50%}
   this is centered
:::
[xyz]{class="<>{width=50%}"}' | pandoc -t native   --lua-filter=debug-ast.lua   --lua-filter=../div-shortcuts.lua --lua-filter=debug-ast.lua 2> test2.out

# check this against test2.out.expected, or fail!

if diff -q test2.out test2.out.expected > /dev/null 2>&1; then
  echo "PASS"
else
  echo "FAIL"
  diff test2.out test2.out.expected
  exit 1
fi
 
