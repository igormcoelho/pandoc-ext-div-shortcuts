#!/bin/bash

FILTER_DEBUG="./debug-ast.lua"
FILTER_MAIN="../div-shortcuts.lua"
PASS=0
FAIL=0
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

run_test() {
  local description="$1"
  local input="$2"
  local expected_before="$3"
  local expected_after="$4"

  local stderr_output
  stderr_output=$(echo "$input" | pandoc -t native \
    --lua-filter="$FILTER_DEBUG" \
    --lua-filter="$FILTER_MAIN" \
    --lua-filter="$FILTER_DEBUG" 2>&1 >/dev/null)

  local before after
  before=$(echo "$stderr_output" | awk '/=== BEGIN AST ==/{found=1;next} /=== END AST ==/{if(found==1)exit} found==1{print}')
  after=$(echo  "$stderr_output" | awk '/=== BEGIN AST ==/{found++;next} /=== END AST ==/{next} found==2{print}')

  local normalize='tr -s " \t\n" " "'

  local diff_before diff_after
  diff_before=$(diff <(echo "$expected_before" | tr -s ' \t\n' ' ') <(echo "$before" | tr -s ' \t\n' ' '))
  diff_after=$(diff  <(echo "$expected_after"  | tr -s ' \t\n' ' ') <(echo "$after"  | tr -s ' \t\n' ' '))

  if [ -z "$diff_before" ] && [ -z "$diff_after" ]; then
    echo -e "${GREEN}PASS${NC}  $description"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  $description"
    if [ -n "$diff_before" ]; then
      echo "  [BEFORE] diff (expected vs got):"
      echo "$diff_before" | sed 's/^/    /'
    fi
    if [ -n "$diff_after" ]; then
      echo "  [AFTER] diff (expected vs got):"
      echo "$diff_after" | sed 's/^/    /'
    fi
    FAIL=$((FAIL + 1))
  fi
}

# ─────────────────────────────────────────────
# TESTS
# ─────────────────────────────────────────────

run_test "center: <>" \
'::: <>
this is centered
:::' \
'[ Div
    ( "" , [ "<>" ] , [] )
    [ Para
        [ Str "this" , Space , Str "is" , Space , Str "centered" ]
    ]
]' \
'[ Div
    ( "" , [ "center" ] , [] )
    [ Para
        [ Str "this" , Space , Str "is" , Space , Str "centered" ]
    ]
]'

run_test "center: ><" \
'::: ><
this is centered
:::' \
'[ Div
    ( "" , [ "><" ] , [] )
    [ Para
        [ Str "this" , Space , Str "is" , Space , Str "centered" ]
    ]
]' \
'[ Div
    ( "" , [ "center" ] , [] )
    [ Para
        [ Str "this" , Space , Str "is" , Space , Str "centered" ]
    ]
]'

run_test "flushleft: <" \
'::: <
this is left
:::' \
'[ Div
    ( "" , [ "<" ] , [] )
    [ Para
        [ Str "this" , Space , Str "is" , Space , Str "left" ]
    ]
]' \
'[ Div
    ( "" , [ "flushleft" ] , [] )
    [ Para
        [ Str "this" , Space , Str "is" , Space , Str "left" ]
    ]
]'

run_test "flushright: >" \
'::: >
this is right
:::' \
'[ Div
    ( "" , [ ">" ] , [] )
    [ Para
        [ Str "this" , Space , Str "is" , Space , Str "right" ]
    ]
]' \
'[ Div
    ( "" , [ "flushright" ] , [] )
    [ Para
        [ Str "this" , Space , Str "is" , Space , Str "right" ]
    ]
]'

run_test "column: | positional width" \
'::::: |{50%}
content
:::::' \
'[ Div ( "" , [ "|{50%}" ] , [] ) [ Para [ Str "content" ] ]
]' \
'[ Div
    ( "" , [ "column" ] , [ ( "width" , "50%" ) ] )
    [ Para [ Str "content" ] ]
]'

run_test "column: | explicit key" \
'::::: |{width=40%}
content
:::::' \
'[ Div
    ( "" , [ "|{width=40%}" ] , [] ) [ Para [ Str "content" ] ]
]' \
'[ Div
    ( "" , [ "column" ] , [ ( "width" , "40%" ) ] )
    [ Para [ Str "content" ] ]
]'

run_test "columns: || explicit key" \
'::::: ||{totalwidth=80%}
content
:::::' \
'[ Div
    ( "" , [ "||{totalwidth=80%}" ] , [] )
    [ Para [ Str "content" ] ]
]' \
'[ Div
    ( "" , [ "columns" ] , [ ( "totalwidth" , "80%" ) ] )
    [ Para [ Str "content" ] ]
]'

run_test "columns: || multi attrs (SOMETIMES FAILS, NON-DET ATTR ORDER!!)" \
'::::: ||{align=center;totalwidth=8em}
content
:::::' \
'[ Div
    ( "" , [ "||{align=center;totalwidth=8em}" ] , [] )
    [ Para [ Str "content" ] ]
]' \
'[ Div
    ( ""
    , [ "columns" ]
    , [ ( "align" , "center" ) , ( "totalwidth" , "8em" ) ]
    )
    [ Para [ Str "content" ] ]
]'

run_test "font: - small" \
'::: -
small text
:::' \
'[ Div
    ( "" , [ "-" ] , [] )
    [ Para [ Str "small" , Space , Str "text" ] ]
]' \
'[ Div
    ( "" , [ "small" ] , [] )
    [ Para [ Str "small" , Space , Str "text" ] ]
]'

run_test "font: ---- tiny" \
'::: ----
tiny text
:::' \
'[ Div
    ( "" , [ "----" ] , [] )
    [ Para [ Str "tiny" , Space , Str "text" ] ]
]' \
'[ Div
    ( "" , [ "tiny" ] , [] )
    [ Para [ Str "tiny" , Space , Str "text" ] ]
]'

run_test "font: ++++ huge" \
'::: ++++
huge text
:::' \
'[ Div
    ( "" , [ "++++" ] , [] )
    [ Para [ Str "huge" , Space , Str "text" ] ]
]' \
'[ Div
    ( "" , [ "huge" ] , [] )
    [ Para [ Str "huge" , Space , Str "text" ] ]
]'

run_test "passthrough: unknown class" \
'::: myclass
content
:::' \
'[ Div ( "" , [ "myclass" ] , [] ) [ Para [ Str "content" ] ]
]' \
'[ Div ( "" , [ "myclass" ] , [] ) [ Para [ Str "content" ] ]
]'

run_test "SPAN center: ><" \
'[testing]{class="><"}' \
'[ Para [ Span ( "" , [ "><" ] , [] ) [ Str "testing" ] ] ]
' \
'[ Para [ Span ( "" , [ "center" ] , [] ) [ Str "testing" ] ] ]
'

run_test "SPAN center >< with args" \
'[testing]{class="><"}' \
'[ Para [ Span ( "" , [ "><" ] , [] ) [ Str "testing" ] ] ]
' \
'[ Para [ Span ( "" , [ "center" ] , [] ) [ Str "testing" ] ] ]
'

# ─────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────
echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1