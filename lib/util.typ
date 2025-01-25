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

// hack line references with codly
#let line(tag, supplement: "Line") = {
    let prefix = supplement
    if prefix != none {
      prefix = prefix + " "
    }
    show ref: it => {
      let el = it.element
      if el != none and el.has("kind") and el.kind == "codly-line" {
        link(el.location(), [#prefix#numbering(
          el.numbering,
          ..counter(figure).at(el.location())
        )])
      } else {
        none
      }
    }
    ref(label(tag))
}

#let range(start, end, separator: " to ") = {
    [#line(start, supplement: "Lines")#separator#line(end, supplement: none)]
}

#let code(offset: 0, body) = {
    set text(size: 8pt)
    codly(zebra-fill: none, offset: offset, display-name: false, radius: 0pt, fill: none, stroke: none, number-align: right + top, reference-sep: "", breakable: true,
        number-format: (n) => text(size: 5pt)[#str(n)])
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

#let semantics(caption, content) = {
    [
        #set text(8pt)
        #figure(
            caption: caption)[
                #grid(
                columns: 1,
                column-gutter: 1mm,
                inset: (x: 0pt, y: 2mm),
                grid.hline(stroke: 0.5pt),
                content,
                grid.hline(stroke: 0.5pt))
            ]#label(tag)
    ]
}

//#figure([
//    #let r = curryst.rule(
//  name: "callback", 
//  $s;v^*;e^* arrow.r.hook_i s';v^*; bold("callback") {e^*} (s_("evt")(0)_("payload")) (s_("cbs")(s_("evt")(0)_("topic"))) (bold("call_indirect") italic("tf")) bold("end")$
//  )
//#curryst.proof-tree(r)],
//  caption: [Selected rules.],
//    // todo more space between figure and caption. captions number bold
//) <rules>

