#import "@preview/drafting:0.2.2": set-margin-note-defaults, set-page-properties, margin-note, rule-grid
#import "@preview/codly:1.3.0": *
#import "../lib/book.typ": is-page-empty, quote, toc, s, t, e, f
#import "../lib/environments.typ": note
#import "../lib/fonts.typ": serif, sans, mathfont, monospace, small, normal, script, codefont, large
#import "../lib/colors.typ": colour
#import "../lib/util.typ": illustration

#import "preamble/titlepage.typ": titlepage

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
        [
          #metadata(none) <chapter-start>
          #counter(figure.where(kind: illustration.algorithm)).update(0)
          #counter(figure.where(kind: illustration.code)).update(0)
          #counter(figure.where(kind: illustration.figure)).update(0)
          #counter(figure.where(kind: illustration.table)).update(0)
        ]
    }

    //#show ref.where(
    //  form: "normal"
    //): set ref(supplement: it => {
    //  if (it.func() == heading) and (it.supplement != "Appendix") and it.level == 1 {
    //    "Chapter"
    //  } else {
    //    it.supplement
    //  }
    //})


    // section titles
    #set heading(numbering: "1.1")

    #show heading.where(level: 1): set heading(supplement: [Chapter])

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
      _Chapter #number._ #h(0.5em) #body // \[Chap. #number\]
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
                        #h(1fr)#last_heading.body //#h(1fr) #counter(page).display()
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
                    //#counter(page).display()
                    #runningheader(counter(heading.where(level: 1)).display(), headings.last().body) #h(1fr)
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
            //if query(selector.or(<chapter-start>)).any(it => (it.location().page() == here().page())) {
            if calc.odd(here().page()) {
                align(right)[#counter(page).display()]
            } else {
                //none
                align(left)[#counter(page).display()]
            }
        }
    )

    //// style figures
    #set figure(placement: top, kind: illustration.figure, supplement: [Figure])
    #show figure.where(kind: "algorithm"): set figure(placement: none)  // top placement for algorithms breaks line labels

    #set figure.caption(separator: ". ")
    #show figure.caption: set text(size: normal)
    #show figure.caption: it => context {
        align(left)[*#it.supplement~#it.counter.display()#it.separator*#it.body]
    }

    // captions
    #set figure(numbering: (..num) =>
        numbering("1-1", counter(heading).get().first(), num.pos().first())
    )

    #show figure.caption: set block(below: 5em)

    // style code snippets
    #show: codly-init.with()
    #set raw(syntaxes: "../lib/wast.sublime-syntax")
    #show raw: set text(size: codefont)
    #show figure.caption: set text(size: normal)
    #show raw.where(block: true): set text(size: script)
    #show raw.where(block: true): set par(leading: 0.55em)

    #show link: set text(fill: colour.links)

#[
    #set page(numbering: none, footer: none)

    #titlepage(maintitle, subtitle: subtitle)

#pagebreak(to: "odd")
// French title page

#counter(page).update(1)

#[
  #set align(center)
  #set page(
    numbering: none
  )

  #v(30%)
  #text(size: large, maintitle)
  #v(0.4em)
  #text(style: "italic", subtitle)

  #v(1fr)

  #text("Universiteit Gent")
  #v(0em)
  #text("MMXXV")

  #pagebreak()
]

// Inside cover

#[
    #set page(
      margin: (
        right: 42%
      ),
      numbering: none
    )

    #text(font: serif, ligatures: true, discretionary-ligatures: false, size: small, weight: "regular")[

    #v(1fr)

    Dissertation submitted in partial fulfillment of the requirements for the degree of Doctor of Computer Science at Ghent University. \
    August, 2025

    #v(.4em)
    _Advisor:_ prof. dr. Christophe Scholliers \
    _Second advisor:_ prof. dr. Peter Dawyndt

    #v(.4em)
    _Jury:_ prof. dr. Robert Hirschfeld,  prof. dr. Quentin Stiévenart,  prof. dr. Bart Coppens, prof. dr. Yvan Saeys, and prof. dr. Chris Cornelis.

    //#v(.4em)
    //No LLMs were used to write this dissertation, with the exception of the dutch summary where LLMs were used to speedup the translation process, and for the conversion from LaTeX to Typst.

    #v(.4em)
    Ghent University \
    Faculty of Sciences \
    Department of Mathematics, Computer Science and Statistics \
    Theory and Operations of Programming Languages Lab

    #v(.4em)
    This dissertation was typeset using Typst. \
    Cover art #sym.copyright Fien Lauwaerts and Tom Lauwaerts
    ]
    #pagebreak()
]

    #v(30%)
    #align(center)[
        #text(style: "italic")[for my darling cabbage] //[for the apple of my eye]  // TODO end dedication with a period?
    ]

    #pagebreak() //(to: "odd")

]

// Preamble
#[

#set page(
    fill: none,
    header: [
        #set text(normal)
    ],
    numbering: "i",
    )

#set par(justify: true)
#set text(
        font: serif,
        ligatures: true,
        discretionary-ligatures: false,
        size: normal,
        lang: "en",
        weight: 400)

#show heading.where(level: 1): it => [
  #set align(left)
  #set text(weight: 600)
  #block(text(style: "italic", it.body))
  #v(2.00em)
]

#show heading.where(level: 2): it => [
  #set text(weight: 800, size: normal)
  #it
]

#set heading(numbering: none)

#toc()

#pagebreak(to: "odd")
#include "preamble/declaration.typ"

#pagebreak()
#include "preamble/acknowledgements.typ"

#pagebreak()
#include "preamble/samenvatting.typ"

#pagebreak()
#include "preamble/summary.typ"

#pagebreak(to: "even")

#v(30%)
#align(left)[
  #text(style: "italic")[
    I don’t know if you have had the same experience, \
    but the snag I always come up against when I’m telling a story \
    is this dashed difficult problem of where to begin it.
    #v(0.5em)
    #text(style: "normal")[Bertie Wooster], Right Ho, Jeeves
  ]

  // #text(style: "italic")[
  //   If you can fill the unforgiving minute \
  //   With sixty seconds' worth of distance run, \
  //   Yours is the Earth and everything that's in it
  //   #v(0.5em)
  //   #text(style: "normal")[Rudyard Kipling], If—
  // ]
]

//#pagebreak()
]

#counter(page).update(1)
#counter(heading).update(0)


// Chapters

// Chapter 1
= Introduction<chapter:introduction>

#quote("Edsger W. Dijkstra", theme: theme)[If debugging is the process of removing software bugs,\ then programming must be the process of putting them in.]

#include "introduction/introduction.typ"

// Chapter 2
= Foundations for Debugging Techniques<chapter:foundations>

#quote("Donald Knuth", source: "personal communication c. 1970", theme: theme)[Beware of bugs in the above code;\ I have only proved it correct, not tried it.]

#include "foundations/foundations.typ"

// Chapter 3
= A Remote Debugger for WebAssembly<chapter:remote>  // An embedded WebAssembly virtual machine

#quote([#text(style: "italic", [adapted from]) George Orwell], theme: theme)[Those who abjure debugging can only do so by others debugging on their behalf.]

#include "remote/remote.typ"

// Chapter 4
= Stateful Out-of-place debugging<chapter:oop> // todo make title more specific?

#quote("Tony Hoare")[Some problems are better evaded than solved.]

#include "oop/oop.typ"

// Chapter 5

= Multiverse debugging on microcontrollers<chap:multiverse>

#quote("Karl Popper", source: "Knowledge without Authority", theme: theme)[Our knowledge can only be finite, while our ignorance must necessarily be infinite.]

#link("https://doi.org/10.5281/zenodo.15838624", text(style: "italic", size: small, top-edge: 1em)[
  #set box(baseline: 15%)
  #box(image("../static/artifacts_available.jpg", height: 1.1em))#h(0.5em)#box(image("../static/artifacts_evaluated_reusable.jpg", height: 1.1em))#h(0.5em)Artifact Available, and Reusable.])
#v(0.2cm)

#include "multiverse/multiverse.typ"

// Chapter 6

= Managed Testing<chapter:testing>

#quote("Miyamoto Musashi", source: "The Book of Five Rings", theme: theme)[If you know the way broadly, you will see it in everything.] // TODO find a better quote

#include "latch/latch.typ"

// Chapter 7

= Conclusion<chapter:conclusion>

#quote("Terry Pratchet", source: "A Hat Full of Sky", theme: theme)[Why do you go away? So that you can come back. So that you can see the place you came from with new eyes and extra colors. And the people there see you differently, too. Coming back to where you started is not the same as never leaving.]
//#quote("P.G. Wodehouse", source: "Jeeves Takes Charge", theme: theme)[I pressed down the mental accelerator. The old lemon throbbed fiercely. I got an idea.]

#include "conclusion/conclusion.typ"

// Appendices and references

#[
#set heading(numbering: "A.1", supplement: [Appendix])
#show heading.where(level: 1): set heading(supplement: [Appendix])

#show heading.where(level: 1): it => [
  #set align(left)
  #set text(weight: 600)
  #pagebreak()
  #block(text(style: "italic", it.body))
  #v(2.00em)
]

    #let runningheader(number, body) = [
      _Appendix #number._ #h(0.5em) #body // \[Chap. #number\]
    ]

#set figure(placement: none, numbering: (..num) =>
        numbering("A-1", counter(heading).get().first(), num.pos().first())
    )


#[
  // no running header for bibliography
  #set page(header: context {
    if calc.even(here().page()) [
      _Bibliography_ #h(1fr)
      #v(0.5em)
    ]
  })

  #bibliography("references.bib", style: "elsevier-harvard")<bibliography>
]

#metadata(none) <appendix>

#set heading(numbering: "A.1", supplement: [Appendix])
#show heading.where(level: 1): it => [
  #set align(left)
  #set text(weight: 600)
  #pagebreak()
  #block(text(style: "italic", [#counter(heading).display(). #it.body]))
  #v(2.00em)
  #[#metadata(none) <chapter-start>]
]

#show heading.where(level: 2): it => [
  #set align(left)
  #set text(weight: 800, size: normal)
  #it
]

#counter(heading).update(0)

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
    
            if calc.even(here().page()) {
                // Even pages : Chapter a. title
                // Retrieve all level 1 headings before the current position
                let headings = query(heading.where(level: 1).before(here()))
    
                // Check if there are any such headings
                if headings.len() > 0 {
                  [
                    //#counter(page).display()
                    #runningheader(counter(heading).display(), headings.last().body) #h(1fr)
                    #v(0.5em)
                  ]
                } else {
                  // Fallback content if no level 1 heading is found
                  none
                }
            }
        }
    ) if theme == "modern"

#include "foundations/appendix.typ"

#include "remote/appendix.typ"

#include "oop/appendix.typ"

#include "multiverse/appendix.typ"

]
