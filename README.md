# pandoc-ext-div-shortcuts

`div-shortcuts` is a Pandoc Lua filter that replaces verbose English class names in [fenced divs](https://pandoc.org/MANUAL.html#extension-fenced_divs)
with concise and intuitive shortcuts: keeping your Pandoc source documents
simple and language-neutral. In short:

> div-shortcuts is a Lua pandoc filter for useful Div shortcuts: ">" is flushright, "<>" is center, "||" is columns, etc.

It *tries* to solve the decade-old centering syntax issue in Pandoc (see [jcm/pandoc Issue 719](https://github.com/jgm/pandoc/issues/719)) with the following extended *fenced_div* syntax:

```
::: <>
            This text is centered
:::

```

which is equivalent to (in the *fenced_div* syntax from filter *fonts-and-alignment*):

``` 
::: {.center}
            This text is centered
:::

```

Span is also supported, example to make a tiny phrase, use `----` (or `+++` to make it large):

```
[This text is tiny]{class="----"}
```

**Important:** for simplicity, this filter DEPENDS on the other filter [pandoc-ext/fonts-and-alignment](https://github.com/pandoc-ext/fonts-and-alignment) to correctly generate the PDF or HTML/JS output on pandoc. 
This also covers other common/useful stuff, like: increasing and decreasing font size, centering and manipulating text columns.

---

## Overview

Pandoc's fenced div syntax requires English class names like `.column`,
`.flushright`, or `.xxlarge`.
It is even more complex to remember, since these names may be related to LaTeX or
even to useful third-party extensions, like *fonts-and-alignment*.

**Memorizing strange names should not be a common task in Markdown or Pandoc!!!**

This filter lets you use intuitive alternatives
that are shorter, visually meaningful, and free of any natural language:

```markdown
::::: <>
This text is centered.
:::::

::::: |{60%}
This is a column with 60% width.
:::::

::::: +++
This text is extra-extra large.
:::::
```

The filter rewrites the AST before any other processing, so all downstream
filters and output formats receive the canonical class names they expect.

---

## Prerequisites

- [Pandoc](https://pandoc.org/) 2.17 or later (Lua filter support required)
- For LaTeX/PDF output, the
  [fonts-and-alignment](https://github.com/pandoc-ext/fonts-and-alignment)
  filter is necessary as a downstream processor for alignment and font-size
  classes.

---

## Installation

Download the filter:

```bash
wget https://raw.githubusercontent.com/igormcoelho/pandoc-ext-div-shortcuts/main/div-shortcuts.lua
```

Just place it in a directory recognized by Pandoc, or reference it directly on the
command line.

---

## Usage

Pass the filter with `--lua-filter` **before** any other filters that depend
on the canonical class names:

```bash
pandoc input.md -o output.pdf \
  --pdf-engine=xelatex \
  --lua-filter=div-shortcuts.lua \
  --lua-filter=fonts-and-alignment.lua
```

In a Pandoc defaults file:

```yaml
filters:
  - div-shortcuts.lua
  - fonts-and-alignment.lua
```

---

## Shortcuts Reference

### Text Alignment

Alignment shortcuts use arrow-like symbols. The visual direction of the symbol
matches the direction of the text.

| Shortcut | Class | Description |
|---|---|---|
| `<` | `flushleft` | Align text to the left |
| `>` | `flushright` | Align text to the right |
| `<>` | `center` | Center text |
| `><` | `center` | Center text (alternative) |

```markdown
::::: >
       This text is aligned to 
                     the right.
:::::

::::: <>
          This text 
              is 
           centered.
:::::
```

> **Note:** we do not support `justify` here...
> the reason is that we assume that justify is the REGULAR behavior
> of the document, specially in LaTeX! Make sure you configure this in your `headers.tex` file!
> Maybe in other formats this is
> not so common. A possibly reserved shortcut for this could be the `=` symbol (if REALLY necessary in the future!)

### Font Sizes

Font size shortcuts use `+` to grow and `-` to shrink, stacked to indicate
degree. The more symbols, the more extreme the size.

| Shortcut | Class | LaTeX equivalent | Size (12pt doc) |
|---|---|---|---|
| `----` | `tiny` | `\tiny` | 6pt |
| `---` | `xxsmall` | `\scriptsize` | 8pt |
| `--` | `xsmall` | `\footnotesize` | 10pt |
| `-` | `small` | `\small` | 10.95pt |
| *(no shortcut)* | normal | `\normalsize` | 12pt |
| `+` | `large` | `\large` | 14.4pt |
| `++` | `xlarge` | `\Large` | 17.28pt |
| `+++` | `xxlarge` | `\LARGE` | 20.74pt |
| `++++` | `huge` | `\huge` | 24.88pt |

```markdown
::::: -
Small text.
:::::

::::: ++++
Huge text.
:::::

```

> **Note:** `normalsize` have no shortcut by design, so closing
> the enclosing block restores to the default automatically (same for `justify`)!
> For the future, a possible shortcut for `normalsize` could be `+-` (or even `-+`)

### Columns

Column shortcuts use pipe symbols. A single `|` is one column; `||` is the
columns container.
The shortcut also accepts attributes `{...}`, *as long as they have no spaces*!

| Shortcut | Class | Default attribute |
|---|---|---|
| `\|{width}` | `column` | `width` |

The first positional value inside `{...}` is interpreted as the default
attribute for that class (`width` for `column`).
Additional attributes use `key=value` pairs separated by `;`.

```markdown
:::::::::::::: ||

::::: |{60%}
Left column content.
:::::

::::: |{width=40%}
Right column content.
:::::

::::::::::::::
```

Example of multiple attributes:

```markdown
::::: |{width=40%;valign=top}
Narrow column with explicit key.
:::::
```

> **Note:** this strange attribute syntax with semicolon is quite terrible!
> However, the pandoc parser only accepts class names with strange symbols,
> as long as they do not contain any spaces! 
> A better solution could be to change Pandoc parser to allow such syntax,
> but personally, I think this is not so good for Pandoc on general, so
> better to just keep this as a filter!

---

## Important: Attribute Syntax Inside `{...}`

Since the shortcut token must have no spaces (to be parsed as a single class
by Pandoc), attributes inside the braces use `;` as a separator instead of
the space used in native Pandoc attribute syntax.

| Native Pandoc | Shortcut equivalent |
|---|---|
| `{.column width=50%}` | `\|{50%}` |
| `{.column width=50%}` | `\|{width=50%}` |
| `{.columns align=center totalwidth=8em}` | `\|\|{align=center;totalwidth=8em}` |

### Limitations

The shortcut attribute syntax supports simple `key=value` pairs with
no spaces and no `=` inside values. For complex cases like quoted strings,
multiple classes, or `#id`, just use native Pandoc syntax directly:

```markdown
::::: {.column width=50% title="My section"}
Content here.
:::::
```

Mixing both approaches in the same document is fully supported.

---

## How It Works

The filter intercepts `Div` elements in the Pandoc AST. When a class matches
a known symbol (with or without a `{...}` attribute block), it:

1. Replaces the symbolic class with the canonical English class name
2. Parses any `key=value;key=value` pairs and injects them as proper AST
   attributes
3. Returns the modified `Div` unchanged in all other respects

The AST produced is identical to what Pandoc would generate from the native
`{.class key=val}` syntax, thus making it transparent to all downstream filters!

So, it is expected that a user will want to use interesting filters like fonts-and-alignment after this one, but it's not mandatory (as long as there's another similar solution!).

---

## Design Philosophy

This filter exists because source documents should read naturally in the
author's language. So, from Pandoc philosophy, the advantage of Markdown
over LaTeX is that a document written in Portuguese stays entirely in Portuguese.
English class names like `.center`, `.flushright` or `.xxlarge` break that property,
and not only because the names are in another language, but also because they refer to
*programming* keywords that may be native LaTeX, HTML/JS/CSS, or something else!

The symbolic shortcuts are chosen to be:

- **Visually intuitive**: `<>` looks like centering; `++++` looks large
- **Easy to remember**: no English, no documentation needed after the first read
- **Minimal**: only shortcuts that save real effort are included (`normalsize`
  and `justify` are intentionally absent since closing a block restores them)

And finally, as a Lua filter, this is *very easy* to change with few lines of code, so if you think something else should be included or removed, just do it!

### Support for SPAN

Span is also supported, example to make a tiny phrase:

```
[This text is tiny]{class="----"}
```

This works because Pandoc automatically converts `"class="` statements into class names for Spans.

---

## Compatibility

The filter produces standard Pandoc AST output and is compatible with any
downstream filter or output format that accepts the canonical class names,
including [fonts-and-alignment](https://github.com/pandoc-ext/fonts-and-alignment).
This is tested for PDF output in LaTeX or HTML output with custom CSS (see tests folder!).

### Support for DIV and SPAN

Please take a look at the generated PDF and HTML examples (based on specimen example by Nandakumar Chandrasekhar):

- [specimens/specimen_small.pdf](specimens/specimen_small.pdf) from [tests/input_small.md](tests/input_small.md)
- [specimens/specimen.pdf](specimens/specimen.pdf) from [tests/input.md](tests/input_small.md)
- [specimens/specimen.html](specimens/specimen.html) from [tests/input.md](tests/input_small.md) and style [specimens/specimen.sass](specimens/specimen.sass)


Good luck!

---

## License

MIT license — see `LICENSE` for details.
