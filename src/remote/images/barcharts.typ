#import "@preview/cetz:0.3.4": canvas, draw
#import "@preview/cetz-plot:0.1.1": chart

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
//#let benchmarks = (("set one", 1, 2, 3), ("set two", 3, 4, 5))


// todo log scale does not work properly, see issue #109 cetz-package/cetz-plot
#let espruino = canvas({
  draw.set-style(legend: (fill: white))
    // barchart: 
    chart.columnchart(benchmarks, size: (auto, 5), labelkey: 0, mode: "clustered", value-key: (1,2),
      //y-mode: "log", y-format: "sci", 
      y-min: 0, y-max: 1000, y-tick-step: none, y-ticks: (10, 100, 1000), y-base: 10)
})

