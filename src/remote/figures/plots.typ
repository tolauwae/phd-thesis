#import "@preview/cetz:0.3.4": canvas, draw
#import "@preview/cetz-plot:0.1.1": chart

#set page(width: auto, height: auto, margin: .5cm)

#let data2 = (
  ([15-24], 18.0, 20.1, 23.0, 17.0),
  ([25-29], 16.3, 17.6, 19.4, 15.3),
  ([30-34], 14.0, 15.3, 13.9, 18.7),
  ([35-44], 35.5, 26.5, 29.4, 25.8),
  ([45-54], 25.0, 20.6, 22.4, 22.0),
  ([55+],   19.9, 18.2, 19.2, 16.4),
)

#let benchmarks = csv("../benchmark.csv", delimiter: " ").enumerate().filter((entry) => {
  let (j, l) = entry
  j > 0
}).map(entry => {
  let (_, l) = entry
    l.enumerate().map(( (p) => {
      let (i, v) = p
      if i > 0 {(i, float(v))} else {p}
    })).map(p => {
      let (i, v) = p
      if i > 0 and v.is-nan() {0} else {v}
    })
  })

//#let espruino = rect[#benchmarks]
#let espruino = canvas({
  draw.set-style(axes: (stroke: .5pt, tick: (stroke: .5pt)),
            legend: (stroke: none, orientation: ttb, item: (spacing: .3), scale: 80%))

  chart.columnchart(mode: "clustered",
                 size: (auto, 5),
                 label-key: 0,
                 value-key: (..range(1, 3)),
                 //x-tick-step: 2.5,
                 benchmarks,
                 labels: ([Espruino], [WARDuino]),
                 legend: "inner-north-east",)
})
