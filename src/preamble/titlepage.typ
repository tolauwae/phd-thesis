// Title page

#let titlepage(maintitle, subtitle: []) = [

    #set rect(
      width: 100%,
      height: 100%,
      inset: 4pt,
    )
    
    #set page(
      fill: rgb("#1E64C8"),
      margin: (
        top: 5cm,
        right: auto,
        left: auto,
        bottom: 2.5cm
      ),
      numbering: none,
      footer: none
    )

    #set text(
      fill: white,
      font: "UGent Panno Text",
      weight: 700
    )
    
    #align(center)[
        #text(2.4em, maintitle)
    
        #text(1.2em, hyphenate: false, subtitle) // TODO heterogenous environments?
    ]

    #v(4cm)

    #align(center)[
        #text(1.2em, weight: 700, "Tom Lauwaerts") \
        #v(1em)
        #text(1.0em)[
            Doctor of Computer Science \
            Theory and Operations of Programming Languages Lab \
            Faculty of Sciences \
            Ghent University \
        ]
        #v(.20em)
        #text(font: "UGent Panno Text", fill: white, 1.0em, weight: 700, "2025") 
    ]
    
    #v(0.25fr)
    
    #grid(
      columns: (1fr, 1fr),
      align(center)[#image("../ugent.png", width: 5cm)],
      grid.vline(stroke: white),
      align(center)[#image("../topl.png", width: 5cm)]
    )
]

