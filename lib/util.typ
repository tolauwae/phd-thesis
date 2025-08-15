#import "@preview/codly:1.3.0": codly
#import "@preview/lovelace:0.3.0": pseudocode
#import "fonts.typ": serif, monospace, normal, script, tiny
#import "colors.typ": colour

#let illustration = (
    algorithm: "algorithm",
    code: "code",
    figure: "image",
    table: "table",
    hidden: "unlist",
    codly: "codly",
)

#let circled(body) = box(baseline: 0.24em, height: 1em, circle(stroke: 0.2mm)[
        #set align(center + horizon)
        #set text(size: 8pt)
        #body])

// hack line references with codly
#let line(tag, supplement: "Line") = {
    let prefix = supplement
    if prefix != none {
      prefix = prefix + " "
    }
    let sp = tag.split(regex("[:]"))
    [#text(fill: red, link(label(sp.at(0)), [#prefix#sp.at(sp.len() - 1)]))#label(tag)]
}

#let range(start, end, separator: " to ") = {
    [#line(start, supplement: "Lines")#separator#line(end, supplement: none)]
}

#let code(offset: 0, body) = {
    //set raw(theme: "printable.thTheme")
    set text(font: monospace, weight: "regular")
    codly(zebra-fill: none, offset: offset, display-name: false, radius: 0pt, fill: none, stroke: none, number-align: right + top, reference-sep: "", breakable: true,
        number-format: (n) => text(size: tiny, baseline: 1pt, fill: colour.subtext)[#str(n)])
    body
}

#let snippet(tag, caption, columns: 1, offset: 0, continuous: true, headless: false, content) = {
    show figure: set block(breakable: true)

    set figure(placement: none)

    [
        #let cursor = offset
        #let snippets = ()
        #for (index, el) in content.enumerate() {
            let subtag = tag + "." + str(index)
            snippets.push([#figure(kind: illustration.codly, supplement: [])[#code(offset: cursor)[#el]]#label(subtag)])
            if continuous {
                cursor += el.at("text").split("\n").len()
            }
        }

        #if (headless) [
            #figure(kind: illustration.hidden, supplement: [], placement: top)[
            #grid(
                columns: columns,
                column-gutter: 0.5mm,
                inset: (x: 0pt, y: 2mm),
                ..snippets)
            ]#label(tag)
        ] else [
          #figure(caption: caption, supplement: [Listing], kind: illustration.code, placement: top)[
            #grid(
                columns: columns,
                column-gutter: 0.5mm,
                inset: (x: 0pt, y: 2mm),
                grid.hline(stroke: 0.5pt),
                ..snippets,
                grid.hline(stroke: 0.5pt))
          ]#label(tag)
        ]
    ]
}

#let algorithm(caption, core, tag) = {
    [
        #set text(8pt)
        #align(left)[
        #figure(
            kind: illustration.algorithm,
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

#let boxed(it) = $it$

#let semantics(caption, content, tag) = {
    [
        #set text(8pt)
        #figure(
            caption: caption,
            kind: illustration.figure,
            supplement: [Figure]
        )[
                #grid(
                columns: 1,
                column-gutter: 1mm,
                inset: (x: 0pt, y: 2mm),
                content)
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

#let lineWidth = 0.4pt
#let headHeight = 1.3em

#let tablehead(content) = align(left, rect(height: headHeight, stroke: none, text(style: "italic", content)))

#let highlight(fill, content, inset: (left: 1mm, top: 2mm, bottom: 2mm , right: 1mm), outset: 0mm) = rect(fill: fill, stroke: none, outset: outset, inset: inset, content)

#let scale-to-width(width, body) = layout(page-size => {
  let size = measure(body, ..page-size)
  let target-width = if type(width) == ratio {
    page-size.width * width
  } else if type(width) == relative {
    page-size.width * width.ratio + width.length
  } else {
    width
  }
  let multiplier = target-width.to-absolute()
  if (size.width > 0mm) {
    multiplier = multiplier / size.width

  }
  scale(reflow: true, multiplier * 100%, body)
})
