    #import "@preview/drafting:0.2.2": set-margin-note-defaults, set-page-properties, margin-note, rule-grid
    #import "@preview/ctheorems:1.1.3": *

    #let normal = 10pt
    #let small = 8pt


    #let note-padding = 11.78mm
    #let note-gutter = 3.93mm

    #let t = 21.98mm
    #let f = 35.40mm
    #let s = 19.08mm
    #let e = 38.16mm // outside margin

    #let note(body) = {
        let opposite(side) = if side == left { right } else { left }

        context {
            let side = if calc.odd(here().position().page) { right } else { left }
            let padding = if side == left { (left: note-padding, right: note-gutter) } else { (right: note-padding, left: note-gutter) }
            let rectangle = rect.with(inset: padding)
            margin-note(side: side, dy: -1.52em, rect: rectangle, [
                #set par(justify: false)
                #set align(opposite(side))
                #set text(size: small, hyphenate: true)
                #body
            ])
        }
    }

#let theorem = thmbox("theorem", "Theorem", inset: 0em, base_level: 1, titlefmt: body => strong[#body.], namefmt: body => strong[(#body)], separator: h(0.6em, weak: true)).with(numbering: "1-1")
#let lemma = thmbox("lemma", "Lemma", inset: 0em, base_level: 1, titlefmt: body => strong[#body.], namefmt: body => strong[(#body)], separator: h(0.6em, weak: true)).with(numbering: "1-1")
#let proof = thmproof("proof", "Proof", inset: (left: 0em, top: 0em, right: 0em, bottom: 1.2em), titlefmt: body => strong[#body.], namefmt: body => strong[(#body)], separator: h(0.6em, weak: true))
#let proofsketch = thmproof("proof sketch", "Proof Sketch", inset: (left: 0em, top: 0em, right: 0em, bottom: 1.2em), titlefmt: body => strong[#body.], namefmt: body => strong[(#body)], separator: h(0.6em, weak: true))

#let example = thmbox("example", "Example", inset: 0em, base_level: 1, titlefmt: body => strong[#body.], namefmt: body => strong[(#body)], separator: h(0.6em, weak: true)).with(numbering: "1-1")
