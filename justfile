default: watch

print:
    typst compile --input print=true --root . src/main.typ build/main.print.pdf

pdf:
    typst compile --root . src/main.typ build/main.pdf

watch:
    typst watch --input print=true --root . src/main.typ build/main.print.pdf &
    typst watch --root . src/main.typ build/main.pdf 


