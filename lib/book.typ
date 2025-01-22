#let book(
    title: [Book title],

    paper-size: none,

    paper-width: 148mm,
    paper-height: 210mm,

    print: true,

    body
) = {
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

    // general styling

    //// Code snippets
    set raw(tab-size: 2)
    set raw(theme: "printable.thTheme") if print

    //// style figures
    set figure(placement: top)

    show figure.caption: set text(8pt)
    show figure.caption: it => {
        align(left)[#it]
    }

    show figure.where(kind: "algorithm"): set figure.caption(position: bottom)

    //// style links

    let bold(it) = {
        text(weight: 700)[#it]
    }

    if not print {
        show link: bold // TODO only for online version not print
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

#let quote(source, body) = {
    align(center)[
        #block(width: 70%)[
            #text(style: "italic", hyphenate: false, [#body]) \
            #text([— #source])
            #v(1.25em)
        ]
    ]
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
