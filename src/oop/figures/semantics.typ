#import "../../../lib/util.typ": code, snippet, algorithm, semantics, lineWidth, headHeight, tablehead, boxed, highlight
#import "../../../lib/class.typ": lemma
#import "../../semantics/arrows.typ": *

#import "@preview/curryst:0.5.0": rule, prooftree


#let func = $"func"$

#let cl = $"cl"$
#let transfer = $"transfer"$
#let call = $"call"$
#let code = $"code"$


#let dbg = $"dbg"$

#let bp = $"bp"$
#let es = $"es"$
#let msg = $"msg"$
#let Cbs = $"Cbs"$
#let evt = $"evt"$
#let invoked(payload) = [$"invoked"angle.l payload angle.r$]
#let invoke(payload) = [$"invoke"angle.l payload angle.r$]
#let sync(payload) = [$"sync"angle.l payload angle.r$]
#let invoking(payload) = [$"invoking"angle.l payload angle.r$]
#let halted = $"halted"$
#let running = $"running"$

#let im = $m_"in"$

#let update = $"update"$

#let brackets = (l: $($, r: $)$)
#let separator = $space ; space$

#let callbacks = $sans("callbacks")$
#let callback = $"callback"$
#let events = $"events"$
#let topic = $sans("topic")$
#let memslice = $"memslice"$
#let payload = $sans("payload")$
#let start = $"start"$
#let length = $"length"$

#let inst = $sans("inst")$
#let tab = $sans("tab")$
#let tabinst = $"tabinst"$
#let mem = $sans("mem")$
#let meminst = $"meminst"$
#let prim = $sans("prim")$
#let ret = $sans("ret")$
#let cps = $sans("cps")$

#let i32 = $"i32"$

#let wasm = [
  #table(columns: (2.0fr, 1fr), stroke: none, gutter: 1.0em,
      tablehead("WebAssembly syntax"), "",
      table.cell(colspan: 2,
    $

        &"(WebAssembly program state)"& K & colon.double.eq { s, v^*, e^* } \
        &"(Global store)"& s & colon.double.eq {inst "inst"^ast, tab tabinst^ast, mem meminst^ast} \
    $),
                tablehead("WebAssembly evaluation"), rect(stroke: lineWidth, inset: (left: 0.4em, right: 0.4em, top: 0.6em, bottom: 0.4em), $\{ s, v^*, e^* \} wasmarrow \{ s', v'^*, e'^* \}$),
            table.cell(colspan: 2, table(columns: (1fr, 1fr), stroke: none,
                prooftree(rule($\{ s, v^*, L^k [e^*] \} wasmarrow \{ s', v'^*, L^k [e'^*] \}$, $\{ s, v^*, e^* \} wasmarrow \{ s', v'^*, e'^* \}$, name: smallcaps("Label"))),
            )),
  )
]

#let act = $sans("act")$

#let actions = [
#table(columns: (2.0fr, 1fr), stroke: none, gutter: 1.0em,
      tablehead("New WebAssembly syntax"), "",
      table.cell(colspan: 2,
    $
        &"(Global store)"& s & colon.double.eq {inst "inst"^ast, tab tabinst^ast, mem meminst^ast, highlight(#silver, act A}) \
        &"(Action table)"& highlight(#silver, A)              & colon.double.eq highlight(#silver, a^*) \
        &"(Action)"& highlight(#silver, a)                    & colon.double.eq highlight(#silver, {code cl, transfer t, transfer^(-1) space r}) \
        &"(Backward transfer)"& highlight(#silver, t)         & colon.double.eq highlight(#silver, (v^* times s arrow.r s', "where" s' subset.eq s)) \
        &"(Forward transfer)"& highlight(#silver, r)          & colon.double.eq highlight(#silver, (s arrow.r s', "where" s' subset.eq s)) \
    $))
]

#let invokeconfig = [#table(columns: (2.0fr, 1fr), stroke: none, gutter: 1.0em,
            tablehead("New WebAssembly evaluation"), rect(stroke: lineWidth, inset: (left: 0.4em, right: 0.4em, top: 0.6em, bottom: 0.4em), $\{ s, v^*, e^* \} wasmarrow \{ s', v'^*, e'^* \}$),
            table.cell(colspan: 2,
                prooftree(rule($\{s, v^*, call j\} wasmarrow \{s,v^*, v\}$, $s_(func)(i,j) eq.not cl$, $s_(act)(j) = a$, $\{s, v^*, call a_(code) \} multi(wasmarrow) \{s', v'^*, v\}$, name: smallcaps("Action"))),
            ),
            )]


#let configuration = table(columns: (1fr), stroke: none,
    tablehead("Global syntax rules"),
    $
    &"(Global configuration)"& D & colon.double.eq brackets.l S | C brackets.r  \
    $,
    tablehead("Client syntax rules"),
    $
    &"(Client configuration)"& S & colon.double.eq es, boxed(im) separator K separator boxed(m)\
    &"(Execution state)"& es & colon.double.eq running ∣ halted ∣ invoked(es) \
    &"(Debug commands)"& m & colon.double.eq "play" ∣ "pause" ∣ "step" \
    &"(Internal messages)"& im & colon.double.eq nothing | sync(s comma v) \
  // todo add breakpoints
    $,
        tablehead("Server syntax rules"),
    $
    &"(Server configuration)"& C & colon.double.eq overline(es), boxed(overline(im)) separator K \
    &"(Execution state)"& overline(es) & colon.double.eq running ∣ halted \
    &"(Internal messages)"& overline(im) & colon.double.eq nothing | invoke(s comma e^ast) \
    $
  )

#let stepping = [
    #table(columns: (2.0fr, 1fr), stroke: none, gutter: 1.0em,
      tablehead("Client evaluation rules"), "",
      table.cell(colspan: 2, table(columns: (1fr), stroke: none,
        prooftree(rule(
          $
          brackets.l halted, boxed(nothing) separator K separator boxed("step") bar.v S brackets.r
          dbgarrow
          brackets.l halted, boxed(nothing) separator K' separator boxed(nothing) bar.v S brackets.r
          $,
          $not ( K = \{s; v^*; L^k [call i]\} ∧ a = A(i) )$,
          $K wasmarrow K'$,
          name: "step-client"
        )),
        prooftree(rule(
          $
          brackets.l #smallcaps("play"), bp , (halted, boxed(nothing) separator K separator boxed("play") ) bar.v S brackets.r 
          dbgarrow
          brackets.l (running, boxed(nothing), K ) bar.v S brackets.r
          $,
          name: "play"
        )),
        prooftree(rule(
          $
          brackets.l #smallcaps("pause"), bp , (running, nothing, K ) bar.v S brackets.r 
          dbgarrow
          brackets.l (halted, boxed(nothing) separator K ) bar.v S brackets.r
          $,
          name: "pause"
        )),
        prooftree(rule(
          $
          brackets.l running, nothing, K bar.v S brackets.r 
          dbgarrow
          brackets.l running, nothing, K' bar.v S brackets.r
          $,
          $
          not ( K = \{s; v^*; L^k [call i]\} ∧ a = A(i) )$, 
          $K wasmarrow K'
          $,
          name: "run-client"
        )),
        prooftree(rule(
          $
          brackets.l halted, boxed(nothing) separator K separator boxed("step") bar.v halted, boxed(nothing) separator K^c brackets.r 
          dbgarrow \
          brackets.l invoked(halted), boxed(nothing), K separator boxed(nothing) bar.v halted, boxed(invoke(s' comma v^n call i)) separator K^c brackets.r
          $,
          $K = \{s; v^*; L^k [v^n call i]\}$, 
          $a = A(i)$,
          $a_transfer(v^n, s) = s'$,
          name: "step-transfer"
        )),
        prooftree(rule(
          $
          brackets.l halted, boxed(nothing) separator K separator boxed("step") bar.v halted, boxed(nothing) separator K^c brackets.r 
          dbgarrow \
          brackets.l invoked(running), boxed(nothing), K separator boxed(nothing) bar.v halted, boxed(invoke(s' comma v^n call i)) separator K^c brackets.r
          $,
          $K = \{s; v^*; L^k [v^n call i]\}$, 
          $a = A(i)$,
          $a_transfer(v^n, s) = s'$,
          name: "run-transfer"
        )),
              prooftree(rule(
          $
          brackets.l invoked(es), boxed(sync(Δ comma v)) separator K separator boxed(m) bar.v S brackets.r
          dbgarrow
          brackets.l halted, boxed(nothing) separator K' bar.v S brackets.r
          $,
          $
          K = {s; v^*; L^k [v^n call cl]}$,
          $update(s, Δ) = s'$,
          $K' = {s'; v^*; L^k [v]}
          $,
          name: "sync"
        )),
      )),
    )
  ]

#let invokingrules = [
    #table(columns: (2.0fr, 1fr), stroke: none, gutter: 1.0em,
      tablehead("Server evaluation rules"), "",
      table.cell(colspan: 2, table(columns: (1fr), stroke: none,
        prooftree(rule(
          $
          brackets.l invoked(a), boxed(nothing) separator K bar.v halted, boxed(invoke(s' comma v^n call i)) separator {s; epsilon; epsilon} brackets.r \
          dbgarrow
          brackets.l invoked(a), boxed(sync(Delta comma v)) separator K bar.v halted, boxed(nothing) separator {s; epsilon; epsilon} brackets.r
          $,
          $
          s'' = update(s, s')
          $, ${s''; epsilon; v^n call i} wasmarrow  {s; epsilon; v}$,
          $Delta = a_(transfer^(-1))(s)$,
          name: "invoke"
        )),
      )),
    )
  ]

#let trigger(payload) = [$"trigger"angle.l #payload angle.r$]

#let eventsrules = [
    #table(columns: (1fr, 1fr), stroke: none, gutter: 1.0em,
      tablehead("Adjusted syntax rules"), "",
      table.cell(colspan: 2,$    &"(Debug commands)"& m & colon.double.eq "play" ∣ "pause" ∣ "step" | trigger(j) $),
      tablehead("New valuation rules"), rect(stroke: lineWidth, inset: (left: 0.4em, right: 0.4em, top: 0.4em, bottom: 0.4em), prooftree(rule(
          $dbg dbgarrow dbg'$, $(wasmarrow) eq.not "interrupt"$, name: ""))),
        table.cell(colspan: 2, prooftree(rule(
          $
          brackets.l halted, boxed(nothing) separator {s; v^*; e^*} separator boxed(trigger(j)) bar.v S brackets.r dbgarrow brackets.l halted, boxed(nothing) separator K' separator boxed(nothing) bar.v S brackets.r
          $,
          $
          xi = s_events(j)$,$
          s'_events = "remove"(s_events, j)$,$
          e'^* = "construct"\_call(s, xi)$,$
          K' = {s', v^*, "Clb"[e'^*] e^*}
          $,
          name: "trigger"
        ))),
        table.cell(colspan: 2, prooftree(rule(
          $
          brackets.l halted, boxed(nothing) separator {s; v^*; e^*} separator boxed(trigger(j)) bar.v S brackets.r dbgarrow \
              brackets.l halted, boxed(nothing) separator {s; v^*; e^*} separator boxed(nothing) bar.v S brackets.r
          $,
          $
          "length"(s_events) ≤ j or exists evt space : space evt lt s_{events}(j)
          $,
          name: "trigger-invalid"
        ))),
        table.cell(colspan: 2, prooftree(rule(
          $
          brackets.l es, boxed(nothing) separator K separator boxed(nothing) bar.v overline(es), nothing separator K' brackets.r dbgarrow brackets.l es, boxed(sync(s)) separator K separator boxed(nothing) bar.v overline(es)', nothing, K'' brackets.r
          $,
          $
          K'_events ≠ nothing$, $
          K''_events = nothing$, $
          s = { events K'_events, "memory" memslice^* }
          $,
          name: "transfer-events"
        ))),
        table.cell(colspan: 2, prooftree(rule(
          $
          brackets.l es, boxed(sync(Delta)) separator K separator bar.v S brackets.r dbgarrow brackets.l Q, bp , (es, nothing, K' ) bar.v S brackets.r
          $,
          $
          K = \{s; v^*; e^*\}$,$
          update(s, Delta) = s'$,$
          K' = \{s'; v^*; e^*\}
          $,
          name: "sync-events"
        ))),
    )
  ]

#let Clb = $"Clb"$

#let cconfig = [
    $
    &"(Extended WebAssembly store)"& s & colon.double.eq { dots, callbacks Cbs, events evt^* } \
    &"(Callback environment)"& Cbs & colon.double.eq nothing \
    && &#h(1.3em) Cbs, memslice arrow.r.bar i \
    &"(Callback context)"& Clb & colon.double.eq L^0 \
    &"(Event)"& evt & colon.double.eq { topic memslice, payload memslice } \
    &"(Memory slice)"& memslice & colon.double.eq { start i32, length i32 } \
    &"(Extended instructions)"& e & colon.double.eq dots ∣ callback."set" ∣ callback."drop" \
    $
  ]

#let crules = [
    #table(columns: (1.0fr, 1.0fr), stroke: none, gutter: 1.0em,
      tablehead("New WebAssembly evaluation rules"), "",
      table.cell(colspan: 2, 
        prooftree(rule(
          $
          {s; v^*; (callback."drop" topic)} dbgarrow {s'; v^*; epsilon}
          $,
          $
          s_(callbacks)[topic arrow.r.bar #smallcaps("nil")] = s'_(callbacks)
          $,
          name: "deregister"
        ))),
      table.cell(colspan: 2, 
        prooftree(rule(
          $
          {s; v^*; (i32."const" j)(callback."set" topic)} dbgarrow {s'; v^*; epsilon}
          $,
          $
          s_(callbacks)[topic arrow.r.bar j] = s'_callbacks
          $,
          name: "register"
        ))),
        prooftree(rule(
          $
          {s; v^*; e^*} dbgarrow {s'; v^*; e^*}
          $,
          $
          xi = s_events(0)$,$
          s'_events = "remove"(s_events, 0)$,$
          s_(callbacks)(xi_topic) = #smallcaps("nil")
          $,
          name: "drop"
        )),
        prooftree(rule(
          $
          {s; v^*; e^*} dbgarrow {s'; v^*; Clb[e'^*] e^*}
          $,
        $
          xi = s_events(0)$,$
          s'_events = "remove"(s_events, 0)$,$
          e'^* = "construct_call"(s, xi)
          $,
          name: "interrupt"
        )),
        prooftree(rule(
          $
          {s; v^*; e^*} dbgarrow {s'; v'^*; e'^*}
          $,
          $
          {s; v^*; Clb[e^*]} dbgarrow {s'; v'^*; Clb[e'^*]}
          $,
          name: "callback"
        )),
        prooftree(rule(
          $
          {s; v^*; Clb[epsilon]} dbgarrow {s; v^*; epsilon}
          $,
          name: "resume"
        )),
      )
  ]

