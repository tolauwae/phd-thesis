#import "../../../lib/util.typ": tablehead, highlight
#import "../../semantics/arrows.typ": *
#import "../../semantics/forms.typ": brackets

#import "@preview/curryst:0.5.0": rule, prooftree

//\begin{figure}
//        \[
//	\begin{array}{ l l c l }
//            #emph[(WebAssembly Program state)] & K                         & \Coloneqq  & \{ s, v^ast, e^ast \} \\
//            #emph[(Global store)]              & s                         & \Coloneqq  & \{ \textsf{inst } \textit{inst}^ast, \textsf{tab } \textit{tabinst}^ast, \textsf{mem } \textit{meminst}^ast, \colorbox{lightgray}{\textsf{prim} $P$} \} \\
//            //%#emph[(Instances)]                 & \textit{inst}             & \Coloneqq  & \{ \textsf{func } \textit{cl}^ast, \textsf{glob } v^ast, \textsf{tab } i^?, \textsf{mem } i^?, \colorbox{lightgray}{\textsf{prim} $P$} \} \\
//            #emph[(Primitive table)]           & \colorbox{lightgray}{$P$} & \Coloneqq  & \colorbox{lightgray}{$p^ast$} \\
//            \\
//            \hline \\
//            #emph[(Primitive)]                 & \colorbox{lightgray}{p}   & \coloneq  & \colorbox{lightgray}{$f : v^ast \rightarrow \{ \textsf{ret } v , \textsf{cps } r \}$} \\
//            #emph[(Compensating action)]       & \colorbox{lightgray}{r}   & \coloneq  & \colorbox{lightgray}{$f : \epsilon \rightarrow \epsilon$} \\
//        \end{array}
//	\]
//    \caption{The configuration for the reversible primitives embedded in the WebAssembly semantics from the original paper by #cite(form: "prose", <haas17>), the differences are highlighted in gray. #emph[Top:] The WebAssembly semantics extended with a primitive table. #emph[Bottom:] The signatures of primitive and their compensating actions.}
//	<fig:prim-def>
//\end{figure}

#let inst = $sans("inst")$
#let tab = $sans("tab")$
#let tabinst = $"tabinst"$
#let mem = $sans("mem")$
#let meminst = $"meminst"$
#let prim = $sans("prim")$
#let ret = $sans("ret")$
#let cps = $sans("cps")$

#let primdef = [
    $
    &"(WebAssembly Program state)"& K & colon.double.eq {s, v^ast, e^ast} \
    &"(Global store)"& s & colon.double.eq {inst "inst"^ast, tab tabinst^ast, mem meminst^ast, highlight(#silver, prim P}) \
    &"(Primitive table)"& highlight(#silver, P) & colon.double.eq highlight(#silver, p^ast) \
    &&& \ // todo add line
    &"(Primitive)"& highlight(#silver, p) & = highlight(#silver, #[$f : v^ast arrow.r {ret v, cps r}$]) \
    &"(Compensating action)"& highlight(#silver, r) & = highlight(#silver, #[$f: epsilon arrow.r epsilon$]) \
    $
]

//\begin{figure}
//	\begin{mathpar}
//                \inferrule[(\textsc{input-prim})]
//       	            { 
//                        P(j) = p \\
//                        p \in P^{In} \\
//                        v \in \lfloor p(v_0^ast)_{ret} \rfloor \\
//                    }
//                    {
//                      \{ s ;v^ast; v^ast_0 (call \; j) \} 
//                      wasmarrow
//                      \{ s ;v^ast; v \} }
//
//                                    \inferrule[(\textsc{output-prim})]
//       	            { 
//                        P(j) = p \\
//                        p \in P^{Out} \\
//                        \lfloor p(v_0^ast)_{ret} \rfloor = v \\
//                    }
//                    {
//                      \{ s ;v^ast; v^ast_0 (call \; j) \} 
//                      wasmarrow
//                      \{ s ;v^ast; v \} }
//	\end{mathpar}
//        \caption{Extension of the WebAssembly language with non-deterministic input primitives.}
//	<fig:language>
//\end{figure}

#let call = $"call"$

#let language = table(columns: (2.0fr, 1fr), stroke: none, gutter: 1.0em,
      tablehead("Non-Deterministic Input Primitives"), "",
      table.cell(colspan: 2, table(columns: (1fr), stroke: none,
        prooftree(rule(
          $
          {s; v^ast, v^ast_0 (call j)} wasmarrow {s; v^ast, v}
          $,
          $P(j) = p$, $p ∈ P^"In"$, $v in floor.l p(v_0^ast)_ret floor.r$,
          name: "input-prim"
        )),
        prooftree(rule(
          $
          {s; v^ast, v^ast_0 (call j)} wasmarrow {s; v^ast, v}
          $,
          $P(j) = p$,$p in P^"Out"$,$floor.l p(v_0^ast)_ret floor.r = v$,
          name: "output-prim"
        )),
      )),
    )

// \begin{figure}
//        \[
//	\begin{array}{ l l c l }
//            #emph[(Debugger state)]         & \textit{dbg}               & \Coloneqq  & \langle es, msg, mocks, K_n \; | \; S^ast \rangle \\
//            #emph[(Execution state)]        & es                         & \Coloneqq  & \textsc{play} \; | \; \textsc{pause} \\
//            #emph[(Incoming messages)]      & msg                        & \Coloneqq  & \varnothing \; | \; \textit{step} \; | \; \textit{stepback} \; | \; \textit{pause} \; | \; \textit{play} \; | \\
//                                            &                            &            & \textit{mock} \; | \; \textit{unmock} \\
//            #emph[(Program state)]          & K                          & \Coloneqq  & \{ s, v^ast, e^ast \} \\
//            #emph[(Overrides)]              & mocks                      & \Coloneqq  & \varnothing \\
//                                            &                            &            & \textit{mocks}, (j,v^ast) \mapsto v \\
//            #emph[(A snapshot)]             & S_n                        & \Coloneqq  & \{ K_m , p_{cps} \} \\
//            #emph[(Snapshots list)]         & S^ast                        & \Coloneqq  & S_0 \cdot ... \cdot S_{n-1} \cdot S_n \\
//            #emph[(Starting state)]         & dbg_{start}                & \Coloneqq  & \langle \textsc{pause}, \varnothing, \varnothing, K_0 \; | \; \{ K_0 , E \} \rangle \\
//            #emph[(Empty action)]           & r_{nop}                    & \Coloneqq  & \lambda () . \textsf{nop} \\
//        \end{array}
//	\]
//        \caption{The multiverse debugger state for WebAssembly with input and output primitives.}
//	<fig:configurations>
//\end{figure}

#let dbg = $italic("dbg")$
#let es = $italic("es")$
#let msg = $italic("msg")$
#let mocks = $italic("mocks")$
#let play = $italic("play")$
#let pause = $italic("pause")$
#let step = $italic("step")$
#let stepback = $italic("stepback")$
#let mock(j, vs, v) = $italic("mock")angle.l #j , #vs, #v angle.r$
#let unmock(j, vs) = $italic("unmock")angle.l #j , #vs angle.r$
#let nop = $italic("nop")$

#let multconfig = [
    $
    &"(Debugger state)"& dbg & colon.double.eq brackets.l es, msg, mocks, K_n bar.v S^ast brackets.r \
    &"(Execution state)"& es & colon.double.eq play ∣ pause \
    &"(Incoming messages)"& msg & colon.double.eq nothing ∣ step ∣ stepback ∣ pause ∣ play ∣ mock(j, v^*, v) ∣ unmock(j, v^*) \
    &"(Program state)"& K & colon.double.eq {s, v^ast, e^ast} \
    &"(Overrides)"& mocks & colon.double.eq nothing ∣ mocks, (j, v^ast) arrow.r.bar v \
    &"(A snapshot)"& S_n & colon.double.eq {K_m, p_{cps}} \
    &"(Snapshots list)"& S^ast & colon.double.eq S_0 ⋅ ... ⋅ S_{n-1} ⋅ S_n \
    &"(Starting state)"& dbg_"start" & colon.double.eq brackets.l pause, nothing, nothing, K_0 bar.v {K_0, E} brackets.r \
    &"(Empty action)"& r_nop & colon.double.eq λ(). nop \
    $
]

//\begin{figure}
//        \begin{mathpar}
//                \inferrule[(\textsc{run})]
//       	            { 
//                        \textsf{non-prim } K_n \\
//                        K_n wasmarrow K_{n+1}
//                    }
//                    { \langle \textsc{play}, \varnothing, mocks, K_n \; | \; S^ast \rangle
//                      dbgarrow
//                  \langle \textsc{play}, \varnothing, mocks, K_{n+1} \; | \; S^ast \rangle }
//
//                 \inferrule[(\textsc{step-forwards})]
//       	            { 
//                        \textsf{non-prim } K_n \\
//                        K_n wasmarrow K_{n+1}
//                    }
//                    { \langle \textsc{pause}, step, mocks, K_n \; | \; S^ast \rangle
//                      dbgarrow
//                  \langle \textsc{pause}, \varnothing, mocks, K_{n+1} \; | \; S^ast \rangle }
//
//                  \inferrule[(\textsc{pause})]
//       	            { 
//                    }
//                    { \langle \textsc{play}, pause, mocks, K_n \; | \; S^ast \rangle
//                      dbgarrow
//                  \langle \textsc{pause}, \varnothing, mocks, K_n \; | \; S^ast \rangle }
//
//                  \inferrule[(\textsc{play})]
//       	            { 
//                    }
//                    { \langle \textsc{pause}, play, mocks, K_n \; | \; S^ast \rangle
//                      dbgarrow
//                  \langle \textsc{play}, \varnothing, mocks, K_n \; | \; S^ast \rangle }
//	\end{mathpar}
//        \caption{The small-step rules describing forwards exploration in the multiverse debugger for WebAssembly instructions without primitives.}
//	<fig:forwards>
//\end{figure}

#let forwards = table(columns: (2.0fr, 1fr), stroke: none, gutter: 1.0em,
      tablehead("Forwards evaluation rules"), "",
      table.cell(colspan: 2, table(columns: (1fr), stroke: none,

        prooftree(rule(
          $
          brackets.l "play", nothing, mocks, K_n bar.v S^* brackets.r dbgarrow brackets.l "play", nothing, mocks, K_{n+1} bar.v S^* brackets.r
          $,
          $sans("non-prim") K_n$ ,$ K_n wasmarrow K_{n+1}$,
          name: smallcaps("run")
        )),

        prooftree(rule(
          $
          brackets.l "pause", "step", mocks, K_n bar.v S^* brackets.r dbgarrow brackets.l "pause", nothing, mocks, K_{n+1} bar.v S^* brackets.r
          $,
          $sans("non-prim") K_n$, $K_n wasmarrow K_{n+1}$,
          name: smallcaps("step-forwards")
        )),

        prooftree(rule(
          $
          brackets.l "play", "pause", mocks, K_n bar.v S^* brackets.r dbgarrow brackets.l "pause", nothing, mocks, K_n bar.v S^* brackets.r
          $,
          "",
          name: smallcaps("pause")
        )),

        prooftree(rule(
          $
          brackets.l "pause", "play", mocks, K_n bar.v S^* brackets.r dbgarrow brackets.l "play", nothing, mocks, K_n bar.v S^* brackets.r
          $,
          "",
          name: smallcaps("play")
        ))

      )),
    )

//\begin{figure}
//        \begin{mathpar}
//                \inferrule[(\textsc{run-prim-in})]
//       	            { 
//                        K_n = \{ s ;v^ast; v^ast_0 (call \; j) \} \\
//                        P(j) = p \\
//                        p \in P^{In} \\
//                        mocks(j, v^ast_0) = \varepsilon \\
//                        K_n wasmarrow K_{n+1} \\
//                    }
//                    { \langle \textsc{play}, \varnothing, mocks, K_n \; | \; S^ast \rangle
//                      dbgarrow
//                  \langle \textsc{play}, \varnothing, mocks, K_{n+1} \; | \; S^ast \cdot \{K_{n+1} , r_{nop}\} \rangle }
//
//                \inferrule[(\textsc{run-prim-out})]
//       	            { 
//                        K_n = \{ s ;v^ast; v^ast_0 (call \; j) \} \\
//                        P(j) = p \\
//                        p \in P^{Out} \\
//                        p(v^ast_0) = \{ \textsf{ret } v, \textsf{cps } r \} \\
//                        K_{n+1} = \{ s ;v^ast; v \} \\
//                    }
//                    { \langle \textsc{play}, \varnothing, mocks, K_n \; | \; S^ast \rangle
//                      dbgarrow
//                  \langle \textsc{play}, \varnothing, mocks, K_{n+1} \; | \; S^ast \cdot \{K_{n+1} , r\} \rangle }
//	\end{mathpar}
//        \caption{The small-step rules describing forwards exploration for input and output primitives in the multiverse debugger for WebAssembly, without input mocking.}
//	<fig:forwards-prim>
//\end{figure}

#let In = $italic("In")$
#let Out = $italic("Out")$

#let forwardsprim = table(columns: (2.0fr, 1fr), stroke: none, gutter: 1.0em,
      tablehead("Forwards I/O evaluation rules"), "",
      table.cell(colspan: 2, table(columns: (1fr), stroke: none,

        prooftree(rule(
          $
          brackets.l "play", nothing, mocks, K_n bar.v S^* brackets.r dbgarrow brackets.l "play", nothing, mocks, K_(n+1) bar.v S^* ⋅ {K_(n+1), r_nop} brackets.r
          $,
          $
          K_n = {s; v^*, v^*_0 (call j)}$, $P(j) = p$, $p in P^In$, $mocks(j, v^*_0) = epsilon$, $K_n wasmarrow K_(n+1)$,
          name: smallcaps("run-prim-in")
        )),

        prooftree(rule(
          $
          brackets.l "play", nothing, mocks, K_n bar.v S^* brackets.r dbgarrow brackets.l "play", nothing, mocks, K_(n+1) bar.v S^* ⋅ {K_(n+1), r} brackets.r
          $,
          $
          K_n = {s; v^*, v^*_0 (call j)}$, $P(j) = p$, $p in P^Out$, $p(v^*_0) = {ret v, cps r}$, $K_(n+1) = {s; v^*, v}$,
          name: smallcaps("run-prim-out")
        ))

      )),
    )


