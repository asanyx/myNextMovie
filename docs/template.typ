// Style for the lab PDFs, made to look like a LaTeX article.
// scripts/build-docs.sh turns docs/labN.md into Typst with pandoc,
// using docs/pandoc.typ, which applies this template.
//
// Fonts: New Computer Modern ships with Typst, the mono variant is in
// docs/fonts. DejaVu Sans Mono, also built in, only fills in symbols
// Computer Modern lacks, like the keyboard shortcuts ⌘ ⇧ ⌥.

#let course = "Zaawansowane programowanie na platformę iOS"

#let lab(title: none, body) = {
  // No creation date in the PDF: the same source always gives the same file,
  // so git sees a change only when the content changes.
  set document(date: none)
  set document(title: title)
  set page(
    paper: "a4",
    margin: (x: 3cm, top: 3cm, bottom: 3.2cm),
    numbering: "1",
  )
  set text(
    font: ("New Computer Modern", "DejaVu Sans Mono"),
    lang: "pl",
    size: 11pt,
    // No widows or orphans: a paragraph never leaves a single line at the bottom
    // or the top of a page. A last line with one short word (a runt) costs extra too.
    costs: (widow: 10000%, orphan: 10000%, runt: 300%),
  )
  set par(
    justify: true,
    leading: 0.55em,
    spacing: 0.55em,
    first-line-indent: 1.5em,
  )

  // Sections unnumbered, like \section* and \subsection*.
  show heading: set text(weight: "bold")
  show heading: set block(above: 1.8em, below: 1em)
  show heading.where(level: 1): set text(size: 14.4pt)
  show heading.where(level: 2): set text(size: 12pt)
  show heading.where(level: 3): set text(size: 11pt)
  show heading.where(level: 3): set block(above: 1.4em, below: 0.8em)

  set list(indent: 1em, marker: ([•], [--]))
  set enum(indent: 1em)
  // Lists here are short, so a list stays on one page: no lone item at the top.
  show list: set block(above: 0.9em, below: 0.9em, breakable: false)
  show enum: set block(above: 0.9em, below: 0.9em, breakable: false)

  // Code in Computer Modern typewriter, blocks indented like verbatim.
  // Typst shrinks raw text to 0.8em, 1.25em brings it back to the body size, like \texttt.
  show raw: set text(font: ("New Computer Modern Mono", "DejaVu Sans Mono"), size: 1.25em)
  show raw.where(block: true): set text(size: 0.9em)
  // A code block is never split between pages.
  show raw.where(block: true): it => block(
    width: 100%,
    breakable: false,
    above: 1em,
    below: 1em,
    inset: (left: 1.5em),
    it,
  )

  // Tables like booktabs: rules only above, below and under the header.
  set table(stroke: none, inset: (x: 6pt, y: 4pt))
  set table.hline(stroke: 0.5pt)
  show table: set align(left)
  show table: set par(justify: false, first-line-indent: 0em)
  show table.cell.where(y: 0): strong
  show table: it => block(stroke: (top: 0.8pt, bottom: 0.8pt), it)
  // A long table may continue on the next page, with its header repeated,
  // instead of leaving half a page empty.
  show figure: set block(above: 1.2em, below: 1.2em, breakable: true)

  show link: set text(fill: rgb("#1f3b8f"))

  // Title like \maketitle.
  align(center, block(above: 0.5em, below: 2.2em)[
    #text(size: 17.28pt, title)
    #v(0.8em)
    #text(size: 12pt, course)
  ])

  body
}
