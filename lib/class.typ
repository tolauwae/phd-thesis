    #import "@preview/drafting:0.2.2": set-margin-note-defaults, set-page-properties, margin-note, rule-grid

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

