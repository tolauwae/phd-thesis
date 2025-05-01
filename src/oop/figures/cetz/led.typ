#import "@preview/cetz:0.3.4"

#let primary = rgb(50, 50, 255, 100)
#let secondary = rgb(50, 50, 255, 50)

#let ledcetz = [
    #cetz.canvas({
        import cetz.draw: *

        rect((0,0), (1, 1), fill: none, stroke: primary)
  })
]
