// Own comment system

#let comment(name, body) = {
    box(fill: rgb("#1E64C8"), baseline: 0.2em)[#pad(x: 0.3em, y: 0.2em)[#text(white)[#name]]]
    h(0.4em)
    text(rgb("#1E64C8"))[#body]
}


