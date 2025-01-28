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
            #set text(10pt)
        ],
        numbering: "i",
        margin: (inside: 2.5cm, outside: 2cm)
    )

    // color scheme
    let ugent-blue = rgb("#1E64C8")
    let sky = rgb(4, 165, 229)

    let links = sky

    // general styling

    //// Code snippets
    set raw(tab-size: 2)
    set raw(theme: "printable.thTheme") if print

    //// style figures
    set figure(placement: top)
    show figure.where(kind: "algorithm"): set figure(placement: none)  // top placement for algorithms breaks line labels

    show figure.caption: set text(8pt)
    show figure.caption: it => {
        align(left)[#it]
    }

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
            #set text(10pt)
        ],
        numbering: "i",
        margin: (inside: 2.5cm, outside: 2cm)
    )

    // Style section headings
    let heading-font = "Libertinus Serif"
    if theme == "modern" {
        heading-font = "Libertinus Sans"
    }

    show heading: set text(font: heading-font)

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
