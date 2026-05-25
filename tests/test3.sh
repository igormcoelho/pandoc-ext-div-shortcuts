#!/bin/bash

# ==========================================
# test3 is integration test for SPAN and DIV
# requires thirdparty filter fonts & align. 
# ------------------------------------------

echo '::::: <>{width=50%}
   this is centered
:::
[xyz]{class="----"}' | pandoc -t native   --lua-filter=debug-ast.lua   --lua-filter=../div-shortcuts.lua --lua-filter=../thirdparty/fonts-and-alignment.lua --lua-filter=debug-ast.lua 2> test3.out

# check this against test3.out.expected, or fail!

if diff -q test3.out test3.out.expected > /dev/null 2>&1; then
  echo "PASS"
else
  echo "FAIL"
  diff test3.out test3.out.expected
  exit 1
fi
 
