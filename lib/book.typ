#import "fonts.typ": serif, sans, normal, small

#let book(
    title: [Book title],

    theme: "standard",

    paper-size: none,

    paper-width: 148mm,
    paper-height: 210mm,

    print: true,

    body
) = {
    let themes = ("modern", "standard", "classic")

    if not theme in themes {
        panic("Unknown theme: " + theme)
    }

    if paper-size == none {
        set page(width: paper-width, height: paper-height)
    } else {
        set page(paper: paper-size)
    }

    set page(
        fill: none,
        header: [
            #set text(normal)
        ],
        numbering: "i",
        margin: (inside: 15.5cm, outside: 2cm)
    )

    // color scheme
    let ugent-blue = rgb("#1E64C8")
    let sky = rgb(4, 165, 229)

    let links = sky

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
            show regex("\d+"): set text(fill: links)
            it
        } else {
            it
        }
    }

    // Page setup

    set page(
        fill: none,
        header: [
            #set text(normal)
        ],
        numbering: "i",
        margin: (inside: 2.5cm, outside: 2cm)
    )

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
        suffix = ", " + source
    }
    align(alignment)[
        #block(width: 70%)[
            #text(style: "italic", hyphenate: false, [#body]) \
            #text([— #author])#text(style: "italic", [#suffix])
            #v(spacing)
        ]
    ]
    if theme == "modern" or theme == "standard" {
        line(length: 100%, stroke: 0.5pt)
    }
}

#let toc() = {
    [
        #set page(numbering: none)
        #set heading(outlined: false)
        = Contents <toc>

        #[
            #show outline.entry.where(
              level: 1
            ): it => {
              emph(it)
            }

            #outline(title: none,
                fill: none,
                target: selector(heading).before(selector(label("toc")), inclusive: false),
            )
        ]

        #v(1em)
        #outline(
            title: none,
            fill: none,
            indent: auto,
            depth: 2,
            target: selector(heading).after(selector(label("toc")), inclusive: false).before(selector(label("appendix")), inclusive: false),
        )

        #v(1em)

        #[
            #show outline.entry.where(
              level: 1
            ): it => {
              emph(it)
            }

            #outline(title: none,
                fill: none,
                depth: 1,
                target: selector(heading).after(selector(label("appendix")), inclusive: true),
            )
        ]
    ]
}
