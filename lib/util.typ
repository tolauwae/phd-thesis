#import "@preview/codly:1.2.0": codly

#let code(offset: 0, body) = {
    set text(size: 8pt)
    codly(zebra-fill: none, offset: offset, display-name: false, radius: 0pt, fill: none, stroke: none, number-align: right + top, reference-sep: "")
    // TODO smaller font for line numbers
    body
}

