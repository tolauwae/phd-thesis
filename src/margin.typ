#import "@preview/drafting:0.2.2": set-margin-note-defaults, set-page-properties, margin-note, rule-grid
#import "@preview/codly:1.3.0": *
#import "../lib/book.typ": is-page-empty, quote
#import "../lib/class.typ": s, t, e, f, note-padding, note-gutter, note, small, normal
#import "../lib/fonts.typ": serif, sans, mathfont, monospace

#import "@preview/ctheorems:1.1.3": *
#show: thmrules.with(qed-symbol: text(size: small, $space square$))

#let maintitle = [Foundations for Constrained Debugging Techniques]
#let subtitle = [Finding software faults in constrained environments with sound out-of-place and multiverse debugging techniques]
#let title =  maintitle + ": " + subtitle

#set document(title: maintitle)

#let theme = "modern" // "classic" "standard" "modern"

//#show: book.with(
//    title: title,
//    theme: theme,
//    print: false
//)

    //#let inside-margin = 18.88mm
    //#let outside-margin = 37.76mm // this breaks it somehow in combination with justification

    // paragraph styling
    #set par(justify: true, leading: 0.55em)  // should come before page setup (or it breaks margin notes)

    // setup page

    #set page(
        fill: none,
        numbering: "1",
        width: 170mm, height: 240mm,
        margin: (inside: s, top: t, outside: e, bottom: f)
    )

    // set font
    #set text(
        font: serif,
        ligatures: true,
        discretionary-ligatures: false,
        size: normal,
        lang: "en")

    #show math.equation: set text(font: mathfont)

    // setup margin notes

    #set-margin-note-defaults(margin-outside: e, stroke: none, side: auto)

    // Section headings styling

    #let heading-font = serif
    #if theme == "modern" {
        heading-font = sans
    }

    #let big = 1.000em
    #let mid = 0.494em
    #let sml = 0.305em
    #if theme == "modern" {
        big = 1.294em
        mid = 0.800em
        sml = 0.494em
    }

    // Headers mark up

    // make page breaks detectable
    #show pagebreak: it => {
      [#metadata(none) <empty-page-start>]
      it
      [#metadata(none) <empty-page-end>]
    }

    // check whether this is an empty page
    // chapter titles
    #show heading.where(level: 1): it => {
        // start on odd page
        pagebreak(to: "odd")
        if theme == "classic" {
            set align(center)
                        text(size: 16pt, weight: 600, [#counter(heading).display()])
            v(0.15em)
            text(weight: 600, style: "normal", size: 16pt, [#it.body])
            v(1.25em)
        } else {
            text(size: 16pt, weight: 400, [Chapter #counter(heading).display()])
            v(0em)
            text(weight: 600, style: "normal", size: 18pt, [#it.body])
            v(0.10em)
        }
        [#metadata(none) <chapter-start>]
    }

    #show ref.where(
      form: "normal"
    ): set ref(supplement: it => {
      if it.func() == heading {
        "Chapter"
      } else {
        it.supplement
      }
    })


    // section titles
    #set heading(numbering: "1.1")

    #show heading: set text(font: heading-font, hyphenate: false)
    #show heading: set par(justify: false)
    #show heading.where(level: 2): it => {
        v(big)
        it
        v(mid)
    }

    #show heading.where(level: 3): it => {
        v(mid)
        it
        v(sml)
    }

    #show heading.where(level: 4).or(heading.where(level: 5)): it => {
        set text(style: "italic", weight: 400, size: normal) if theme != "modern"
        v(mid)
        it
        v(sml)
    }

    // running headers
    #let runningheader(number, body) = [
      #body \[Chap. #number\]
    ]
    #set page(
        header: context {
            if is-page-empty() {
                return
            }
    
            let i = here().page()
            if query(selector.or(<chapter-start>)).any(it => (it.location().page() == i)) {
                return
            }
    
            // Retrieve all headings in the document
            let headings = query(heading);
    
            // Find the last heading before or on the current page
            if headings.filter(h => h.level == 2).filter(h => h.location().page() <= here().page()).len() == 0 {
                return
            }

            let last_heading = headings.filter(h => h.level == 2).filter(h => h.location().page() <= here().page()).last();
    
            if calc.odd(here().page()) {
                // Odd: a.b.c section title
                if last_heading != none {
                    [
                        #last_heading.body #h(1fr) #counter(page).display()
                        #v(0.5em)
                    ]
                } else {
                    // If no heading is found, return a default header or none
                    none
                }
            } else {
                // Even pages : Chapter a. title
                // Retrieve all level 1 headings before the current position
                let headings = query(heading.where(level: 1).before(here()))
    
                // Check if there are any such headings
                if headings.len() > 0 {
                  [
                    #counter(page).display() #h(1fr) #runningheader(counter(heading.where(level: 1)).display(), headings.last().body)
                    #v(0.5em)
                  ]
                } else {
                  // Fallback content if no level 1 heading is found
                  none
                }
            }
        }
    ) if theme == "modern"

    // page footers
    #set page(
        footer: context {
            if query(selector.or(<chapter-start>)).any(it => (it.location().page() == here().page())) {
                align(right)[#counter(page).display()]
            } else {
                none
            }
        }
    )

    //// style figures
    #set figure(placement: top)
    #show figure.where(kind: "algorithm"): set figure(placement: none)  // top placement for algorithms breaks line labels

    #set figure.caption(separator: ". ")
    #show figure.caption: set text(small)
    #show figure.caption: it => context {
        align(left)[*#it.supplement~#it.counter.display()#it.separator*#it.body]
    }

    // captions
    #set figure(numbering: (..num) =>
        numbering("1-1", counter(heading).get().first(), num.pos().first())
    )

    // style code snippets
    #show: codly-init.with()
    #set raw(syntaxes: "../lib/wast.sublime-syntax")



// Chapters

// Chapter 1
= Introduction

#quote("Edsger W. Dijkstra", theme: theme)[If debugging is the process of removing software bugs,\ then programming must be the process of putting them in.]

#include "introduction/introduction.typ"

// Chapter 2
= Foundations for Debugging Techniques<chapter:foundations>

#quote("Donald Knuth", theme: theme)[Beware of bugs in the above code;\ I have only proved it correct, not tried it.]

#include "foundations/foundations.typ"

// Chapter 3
= A Remote Debugger for WebAssembly  // An embedded WebAssembly virtual machine

#quote([#text(style: "italic", [adapted from]) George Orwell], theme: theme)[Those who abjure debugging can only do so by others debugging on their behalf.]

#include "remote/remote.typ"

// Chapter 4
= Out-of-place debugging // todo make title more specific?

#quote("Tony Hoare")[Some problems are better evaded than solved.]

#include "oop/oop.typ"

// Chapter 5

= Multiverse debugging on microcontrollers<chap:multiverse>

#quote("Karl Popper", source: "Knowledge without Authority", theme: theme)[Our knowledge can only be finite, while our ignorance must necessarily be infinite.]

// Chapter 6

= Managed Testing

#quote("Miyamoto Musashi", theme: theme)[If you know the way broadly, you will see it in everything.] // TODO find a better quote

//#include "testing/testing.typ"

// Appendices and references

#[
#counter(heading).update(1)
#set heading(numbering: "A.1", supplement: [Appendix])

#show heading: it => [
  #set align(center)
  #set text(weight: 600)
  #pagebreak()
  #block(smallcaps(it.body))
  #v(1.25em)
]

    #let runningheader(number, body) = [
      #body
    ]
#set figure(placement: none)

#metadata(none) <appendix>

#bibliography("references.bib", style: "elsevier-harvard")<bibliography>

#show heading: it => [
  #set align(center)
  #set text(weight: 600)
  #pagebreak()
  #block(smallcaps[#counter(heading).display(). #it.body])
  #v(1.25em)
]


#include "foundations/appendix.typ"

#include "remote/appendix.typ"
]
