#import "@preview/codly:1.2.0": codly
#import "@preview/lovelace:0.3.0": pseudocode

//#let circled(body) = {
//circle(radius: 0.5em, stroke: 0.2mm)[
//        #set align(center + horizon)
//        #set text(size: 8pt)
//        #body]
//}
#let circled(body) = {
    strong([(#body)])
}

#let code(offset: 0, body) = {
    set text(size: 8pt)
    codly(zebra-fill: none, offset: offset, display-name: false, radius: 0pt, fill: none, stroke: none, number-align: right + top, reference-sep: "", breakable: true)
    body
}

#let snippet(tag, caption, columns: 1, offset: 0, continuous: true, content) = {
    show figure: set block(breakable: true)

    show raw: set text(size: 6pt)

    set figure(placement: none)
    [
        #let cursor = 0
        #let snippets = ()
        #for (index, el) in content.enumerate() {
            let subtag = tag + "." + str(index)
            snippets.push([#figure[#code(offset: cursor)[#el]]#label(subtag)])
            if continuous {
                cursor += el.at("text").split("\n").len()
            }
        }

        #figure(caption: caption, supplement: [Listing], kind: "code", placement: top)[
            #grid(
                columns: columns,
                column-gutter: 1mm,
                inset: (x: 0pt, y: 2mm),
                grid.hline(stroke: 0.5pt),
                ..snippets,
                grid.hline(stroke: 0.5pt))
        ]#label(tag)
    ]
}

#let algorithm(caption, core, tag) = {
    [
        #set text(8pt)
        #align(left)[
        #figure(
            kind: "algorithm",
            caption: caption,
            supplement: [Algorithm])[
                #grid(
                columns: 1,
                column-gutter: 1mm,
                inset: (x: 0pt, y: 2mm),
                grid.hline(stroke: 0.5pt),
                block(width: 100%, align(left, core)),
                grid.hline(stroke: 0.5pt))
            ]#label(tag)
        ]
        
    ]
}
