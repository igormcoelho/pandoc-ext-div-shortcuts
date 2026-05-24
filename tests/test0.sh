#!/bin/bash

# ============================================
# test0 is a very basic test... just to begin!
# --------------------------------------------

echo '::: ><{x=1}
   this is centered
:::' | pandoc -t native   --lua-filter=debug-ast.lua   --lua-filter=../div-shortcuts.lua --lua-filter=debug-ast.lua 2> test0.out

# check this against test0.out.expected, or fail!

if diff -q test0.out test0.out.expected > /dev/null 2>&1; then
  echo "PASS"
else
  echo "FAIL"
  diff test0.out test0.out.expected
  exit 1
fi
 
