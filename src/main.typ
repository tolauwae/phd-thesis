// Main manuscript setup
//
// typst: v0.12.0

#import "../lib/book.typ": book, quote, is-page-empty, toc
#import "../lib/comment.typ": comment
#import "../lib/fonts.typ": serif, mass, normal, small

// code snippets
#import "@preview/codly:1.2.0": *
#show: codly-init.with()
#set raw(syntaxes: "../lib/wast.sublime-syntax")

#let maintitle = [Foundations for Constrained Debugging Techniques]
#let subtitle = [Finding software faults in constrained environments with out-of-place and multiverse debugging techniques]
#let title =  maintitle + ": " + subtitle

#let print = false
#if "print" in sys.inputs.keys() {
    print = true // sys.inputs.print
}

#let theme = "modern"

#show: book.with(
    title: title,
    theme: theme,
    print: print
)

#set page(width: 170mm, height: 240mm)

// General styling rules


// Cover

#set page(numbering: none)

#[
#align(center)[
    #text(font: "UGent Panno Text", 2em, weight: 700, "Cover")
]

//// conform to golden ratio (just like penguin classics covers)

#pagebreak(to: "odd")

]

// Title page

#[
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
        left: auto
      )
    )

    #set text(
      fill: white,
      font: "UGent Panno Text",
      weight: 700
    )
    
    #align(center)[
        #text(2.4em, maintitle)
    
        #text(1.2em, subtitle) // TODO heterogenous environments?
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
      align(center)[#image("topl.png", width: 5cm)],
      grid.vline(stroke: white),
      align(center)[#image("ugent.png", width: 5cm)]
    )
]

// Inside cover

#[
    #set page(
      margin: (
        right: 40%
      )
    )

    #pagebreak()

    #text(font: serif, ligatures: true, discretionary-ligatures: false, size: small, weight: "regular")[

    #v(1fr)

    Dissertation submitted in partial fulfillment of the requirements for the degree of Doctor of Computer Science at Ghent University \
    May, 2025
    #v(.4em)
    Advisor: Prof Dr. Christophe Scholliers \
    Second advisor: Prof Dr. Peter Dawyndt

    #v(.4em)
    Ghent University \
    Faculty of Sciences \
    Department of Mathematics, Computer Science and Statistics \
    Theory and Operations of Programming Languages Lab

    #v(.4em)
    This dissertation was typeset using Typst. \
    Cover art #sym.copyright Tom Lauwaerts

    ]
]
// Preamble
#[

#counter(page).update(1)

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
        weight: mass)

#show heading: it => [
  #set align(center)
  #set text(weight: 600)
  #block(smallcaps(it.body))
  #v(1.25em)
]

= Acknowledgements

// Christophe

// Stefan

// Elisa

// Robbert

// Carlos

// Matteo

// Maarten
// the new topl lab :)

// (Peter)

// The jury

// Collega's: Jonathan, Charlotte, Niko, Steven, Jorg en anderen

// de vakgroep (ook alle lesgevers van de opleiding)

// Vrienden: Jorg, Max, Wout, Kieran, Jasper, Michiel, the maestro Tibo, Alex, Nicole, Christine

// Internationale contacten: Octave Larose and Sophie Kaleba

// Zussen en mama

// Xiaoyu

// TODO send email with thank you to Baudouin with pdf

#lorem(64)

#lorem(125)

#lorem(45)

#pagebreak()
= Lay summary

#lorem(340)

#pagebreak()
= Samenvatting

#lorem(140)

#lorem(128)

#pagebreak()
= Declaration <declaration>

// Daniel hillerström has this kind of declaration in his thesis:
// I declare that this thesis is composed by myself, that the work contained herein is my own except where explicitely stated otherwise in the text, and that this work has not been submitted for any other degree or professional qualification except as specified. This thesis was written in the period from 2021 to 2025.

The following previously published work features prominently within this dissertation.

- Tom Lauwaerts, Carlos Rojas Castillo, Robbert Gurdeep Singh, Matteo Marra, Christophe Scholliers, and Elisa Gonzalez Boix. Event-Based Out-of-Place Debugging. In MPLR, pages 85–97. ACM, 2022.
- Tom Lauwaerts, Robbert Gurdeep Singh, Christophe Scholliers. WARDuino: An embedded WebAssembly virtual machine. In Journal of Computer Languages, Volume 79. Elsevier, 2024.
- Tom Lauwaerts, Stefan Marr, Christophe Scholliers. Latch: Enabling large-scale automated testing on constrained systems. In Science of Computer Programming, Volume 238. Elsevier, 2024.

At the time of writing, the following works were submitted at peer reviewed conferences or journals, and are still under review.

- Tom Lauwaerts, Maarten Steevens, Christophe Scholliers. MIO: Multiverse Debugging in the face of Input/Output.

The software developed as part of this dissertation is available publicly on the Theory and Operations of Programming Languages Lab's #link("https://github.com/TOPLLab")[GitHub page]. The following software was developed as part of this dissertation:

// TODO make/use zenodo doi links

- The WARDuino virtual machine. Available at #link("https://github.com/TOPLLab/WARDuino")[topllab/warduino]
- WARDuino VSCode plugin. Available at #link("https://github.com/TOPLLab/WARDuino-VSCode")[topllab/warduino-vscode]
- The Latch testing framework. Available at #link("https://github.com/TOPLLab/latch")[topllab/latch]

#pagebreak()

= Preface <preface>

At the start of this dissertation, are the words, "An unexamined program is not worth running".
After the famous words Socrates supposedly spoke at his trial, "And unexamined live is not worth living".
Rather less philosophically impressive, our version is a reminder that debugging is a unavoidable part of programming.
No matter how good testing, automated fault detection, or formal verification become, mistakes with unknown causes will always exist, making debugging inescapable.
Even those developers who refuse to use debuggers, instead rely on print statements to examine their program's behaviour, which is in essense an inefficient and outdated form of debugging.
You really cannot run from it.

// TODO short passionate defense of debuggers with clear arguments

#pagebreak(to: "odd")

#v(30%)
#align(center)[
An unexamined program is not worth running.  // TODO in preface explain this quote comes from Socrates -- or maybe find a better quote and use this one at the start of a chapter
]

#pagebreak(to: "odd")

#toc()]

#set par(justify: true)
#set text(
        font: serif,
        ligatures: true,
        discretionary-ligatures: false,
        size: normal,
        lang: "en",
        weight: mass)

#set page(numbering: "1")
#counter(page).update(1)

#[
    // Page mark up
    // TODO fix page numbering mark up

    // Headers mark up
    #set heading(outlined: true)

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

    #show heading.where(level: 4): it => {
        set text(style: "italic", weight: 400)
        it
    }

    #show heading.where(level: 5): it => {
        set text(style: "italic", weight: 400)
        it
    }

    // section titles
    #set heading(numbering: "1.1")
    #counter(heading).update(0)

    // page headers
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
            let headings = query(heading.where(level: 1).before(here()))

            // Find the last heading before or on the current page
            if calc.odd(here().page()) {
                // Odd: a.b.c section title
                if headings.len() > 0 {
                    align(right)[#text(style: "italic")[#headings.last().body] #h(2mm) #counter(page).display()]
                } else {
                    // If no heading is found, return a default header or none
                    none
                }
            } else {
                // Even pages : Chapter a. title
                // Retrieve all level 1 headings before the current position

                // Check if there are any such headings
                if headings.len() > 0 {
                  [#counter(page).display() #h(2mm) #text(style: "italic")[Chapter #counter(heading.where(level: 1)).display()]]
                } else {
                  // Fallback content if no level 1 heading is found
                  none
                }
            }
        },
    ) if theme == "classic" or theme == "standard"

    // page headers
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
                    [#last_heading.body #h(1fr) #counter(page).display()]
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
                  [#counter(page).display() #h(1fr) #headings.last().body \[Chap. #counter(heading.where(level: 1)).display()\]]
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

= Introduction

//#quote("Bertie Wooster", source: "Right Ho, Jeeves")[I don’t know if you have had the same experience, but the snag I always come up against when I’m telling a story is this dashed difficult problem of where to begin it.]
#quote("Edsger W. Dijkstra", theme: theme)[If debugging is the process of removing software bugs,\ then programming must be the process of putting them in.]

// todo the very first sentence should say something about bugs

The modern world is becoming more and more saturated by computers, digital solutions, and smart devices.

As computational costs have continued to decrease, so increased the opportunities to extend any part of our world with computational capabilities.
Pushed by the self-fulfilling prophecy postulated in 1965 by George Moore @moore65, 

With the fast rise of artificial intelligence solutions in industry and daily life, solutions for edge devices and AI-powered smart devices are also surely to rise quickly.

== The nature of programming mistakes

#lorem(140)

== The history of debugging

#lorem(126)

== The challenges of resource-constraints

#lorem(130)

== The challenges of non-determinism

#lorem(115)

== The promise of universal bytecode interpreters

#lorem(1293)

= Foundations for Debugging Techniques

#quote("Donald Knuth", theme: theme)[Beware of bugs in the above code;\ I have only proved it correct, not tried it.]

#lorem(128)

== Semantics of debuggers

#lorem(512)

== A debugger for $lambda^arrow.r$

#lorem(1024)

== Debugger correctness

#lorem(256)

== Proof of correctness for the $lambda^arrow.r$ debugger

#lorem(512)

= A Remote Debugger for WebAssembly  // An embedded WebAssembly virtual machine

#quote([#text(style: "italic", [after]) George Orwell], theme: theme)[Those who abjure debugging can only do so by others debugging on their behalf.]
// no single language is perfect, we want to enable any language on microcontrollers

#include "remote/remote.typ"

//== Developing embedded programs with WARDuino
//
//== Virtual machine architecture
//
//== Support for high-level languages
//
//== Extending the virtual machine
//
//#comment("Note")[Replace paper section with the small language developed for primitives]
//
//== Formal specification
//
//
//== Tool support for WARDuino
//
//== Evaluation
//

= Out-of-place debugging

#include "oop/oop.typ"

= Multiverse debugging on microcontrollers

#quote("Karl Popper", source: "Knowledge without Authority", theme: theme)[Our knowledge can only be finite, while our ignorance must necessarily be infinite.]

#comment("Note")[PLDI paper chapter]

#lorem(120)

== Defining multiverse debuggers

#comment("Note")[In this section we give definitions for multiverse debugging and also explain what a multiverse graph is, show how it is a rooted tree, and provide a proof for it (useful for later proofs)]

== Challenges in the face of input/output

=== Output: Inconsistent external state during backwards exploration

=== Input: Exploring non-deterministic input in multiverse debuggers

When a program's execution path is determined by the input from the external environment, the possible execution paths are often too many to explore.

=== Performance: Snapshot explosion in multiverse debuggers

// Checkpointing strategies in multiverse debuggers

= Managed testing

//#quote("Laozi", theme: theme)[Anticipate the difficult by managing the easy.]

#quote("Miyamoto Musashi", theme: theme)[If you know the way broadly, you will see it in everything.] // TODO find a better quote

#comment("Note")[Latch paper]

= Validation

#quote([Attributed to Rutherford B. Hayes#footnote[It is often reported that the 19#super[th] president of the United states Rutherford B. Hayes spoke these words upon seeing a telephone for the first time, however, this is almost definitely not true. In fact, Hayes was a technology buff who had the first telephone installed in the White House @kessler12.]], theme: theme)[An amazing invention#box(sym.dash.em)but who would ever want to use one?] // TODO add a reference to the footnote

#lorem(70)

= Conclusions and future work

#quote("P.G. Wodehouse", source: "Jeeves Takes Charge", theme: theme)[I pressed down the mental accelerator. The old lemon throbbed fiercely. I got an idea.]

#lorem(57)

]

#pagebreak()
#metadata(none) <appendix>

#bibliography("references.bib")<bibliography>

#counter(heading).update(0)
#set heading(numbering: "A.1")

#include "appendices/webassembly.typ"

#include "appendices/primitives.typ"

#include "appendices/updates.typ"

#include "appendices/benchmarks.typ"

