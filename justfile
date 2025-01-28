default:
    just watch pdf

print command:
    typst {{command}} --input print=true --root . src/main.typ build/main.print.pdf

pdf command:
    typst {{command}} --root . src/main.typ build/main.pdf

watch type:
    just {{type}} watch

compile type:
    just {{type}} compile

all command:
    just print compile
    just pdf compile

