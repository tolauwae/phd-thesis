#import "fonts.typ": serif, sans, monospace, normal, small, script
#import "colors.typ": colour
#import "@preview/drafting:0.2.2": set-margin-note-defaults, set-page-properties, margin-note

//#let inside-margin = 16.5mm
//#let outside-margin = 49.5mm
//#let note-padding = 49.5mm
#let note-padding = 9.54mm

#let t = 21.98mm
#let f = 35.40mm
#let s = 19.08mm
#let e = 38.16mm ;; outside margin

#let inside-margin = s
#let outside-margin = e

#let book(
    title: [Book title],

    theme: "standard",

    paper-width: 148mm,
    paper-height: 210mm,

    print: true,

    body
) = {
    let themes = ("modern", "standard", "classic")

    if not theme in themes {
        panic("Unknown theme: " + theme)
    }

    // page setup

    set page(width: paper-width, height: paper-height)

    set page(
        fill: none,
        header: [
            #set text(normal)
        ],
        numbering: "1",
        margin: (inside: 16.5mm, top: 16.5mm, outside: outside-margin, bottom: outside-margin)
    )

    // margin notes
    set-margin-note-defaults(margin-outside: outside-margin, stroke: none, side: auto)
    //set-page-properties(margin-outside: note-padding)

    let links = color.links

    // general styling

    //// code snippets
    set raw(tab-size: 2)
    set raw(theme: "printable.thTheme") if print

    //// style figures
    set figure(placement: top)
    show figure.where(kind: "algorithm"): set figure(placement: none)  // top placement for algorithms breaks line labels

    show figure.caption: set text(small)
    show figure.caption: it => {
        align(left)[#it]
    }

    //// style footnote
    show footnote.entry: set text(small)

    //// style links

    let bold(it) = {
        text(weight: 700)[#it]
    }

    show link: it => {
        if not print {
            text(fill: links, it)
        } else {
            it
        }
    }

    show footnote: it => {
        if not print {
            text(fill: links, it)
        } else {
            it
        }
    }

    show ref: it => {
        if not print and it.element != none {
            text(fill: links, it)
        } else {
            it
        }
    }

    show cite: it => {
        if not print {
            show regex("[^()]+"): set text(fill: links)
            it
        } else {
            it
        }
    }

    // Section headings styling
    let heading-font = serif
    if theme == "modern" {
        heading-font = sans
    }

    let big = 1.000em
    let mid = 0.494em
    let sml = 0.305em
    if theme == "modern" {
        big = 1.294em
        mid = 0.800em
        sml = 0.494em
    }

    show heading: set text(font: heading-font, hyphenate: false)
    show heading: set par(justify: false)
    show heading.where(level: 2): it => {
        v(big)
        it
        v(mid)
    }

    show heading.where(level: 3): it => {
        v(mid)
        it
        v(sml)
    }

    show heading.where(level: 4).or(heading.where(level: 5)): it => {
        set text(style: "italic", weight: 400, size: normal) if theme != "modern"
        v(mid)
        it
        v(sml)
    }

    // paragraph styling
    set par(justify: true)
    //show margin-note: set par(justify: false)

    [
        //#add-headers()[#body]
        #body
    ]
}

#let is-page-empty() = {
  let page-num = here().page()
  query(selector.or(<empty-page-start>, <empty-page-end>)).chunks(2).any(((start, end)) => {
    start.location().page() < page-num and page-num < end.location().page()
  })
}

//// Chapter quotes

#let quote(author, source: none, theme: "modern", body) = {
    let alignment = left
    let spacing = 0.75em
    if theme == "classic" {
        alignment = center
        spacing = 1.25em
    } else if theme == "standard" {
        alignment = right
    }

    let suffix = ""
    if source != none {
        suffix = text[, #text(style: "italic", source)] //#underline(text(style: "italic", weight: "bold", source))]
    }
    align(alignment)[
        #block(width: 75%)[
            #table(
              stroke: none,
              /*table.vline(stroke: colour.primary + 1.2pt),*/
              table.cell(inset: (left: 0.0em))[
                #text(style: "italic", hyphenate: false, [#body]) \
                //#v(0.1em)
                #text([— #author])#suffix
              ])
            #v(spacing)
        ]
    ]
    if theme == "modern" or theme == "standard" {
        line(length: 100%, stroke: 0.5pt)
    }
}

#let toc() = {
    [
        #set heading(outlined: false)
        = Contents <toc>

        #set outline.entry(fill: none)

        #[
            #show outline.entry.where(
              level: 1
            ): it => {
              emph(it)
            }

            #outline(title: none, depth: 1,
              target: selector(heading).after(selector(label("toc")), inclusive: false).before(selector(label("chapter:introduction")), inclusive: false),
            )
        ]

        #v(1em)

        #[
            #show outline.entry.where(level: 1): set block(above: 1.0em)
            #outline(
                title: none,
                indent: auto,
                depth: 2,
                target: selector(heading).after(selector(label("chapter:introduction")), inclusive: true).before(selector(label("bibliography")), inclusive: false),
            )
        ]

        #v(1em)

        #[
            #show outline.entry.where(
              level: 1
            ): it => {
              emph(it)
            }

            
            #outline(title: none,
                depth: 1,
                target: selector(heading).after(selector(label("bibliography")), inclusive: true).before(selector(label("appendix")), inclusive: false),
            )

            #v(1em)


            #outline(title: none,
                depth: 1,
                target: selector(heading).after(selector(label("appendix")), inclusive: true),
            )
        ]
    ]
}
