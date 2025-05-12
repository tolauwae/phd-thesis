#import "../../../lib/util.typ": semantics, lineWidth, headHeight, tablehead, highlight, boxed
#import "../../../lib/class.typ": note
#import "../../../lib/fonts.typ": small

#import "@preview/curryst:0.5.0": rule, prooftree

#let definition = (name, addendum, rules, types, division: (1fr, 1.5em, 6fr, 9fr), symbol: sym.colon.double.eq) => [
    #let lines = range(rules.len()).map(_ => "").zip(range(rules.len()).map(_ => ""), rules, types).flatten()
    #set table(align: (x, _) => if x == 3 { right } else { left })
    #table(
        columns: division,
        stroke: none,
        inset: 0.3em,
        name,
        symbol, "",
        addendum,
        ..lines)
]

// Definitions

#let global = $d$
#let server = $s$
#let client = $c$
#let message = $m_s$
#let operation = $m_c$ // $kappa.alt$
#let dbgarrow = $attach(arrow.r.long, br: text(size: small, DD))$ // $harpoon.rt$
#let multi(step) = $attach(step, tr: "*")$ // $harpoon.rt$

// Figures

#let rules-stlc = [  // Simply Typed Lambda Calculus without base types
    #show table.cell: set text(style: "italic")
    #set table.cell(align: horizon)

    #grid(columns: (5fr, 7fr), stroke: none, align: top,

            table(columns: (1fr), align: (left), stroke: none,
                tablehead("Syntax"),
                definition("t", "(terms)",
                    ($x$, $lambda x : T . t$, $t space t$),
                    ("variable", "abstraction", "application")),
                definition("v", "(values)",
                    ($lambda x : T . t$,),
                    ("abstraction",)),
                definition("T", "(types)",
                    ($T arrow T$,),
                    ("function type",)),
                definition($Gamma$, "(contexts)",
                    ($nothing$, $Gamma, x : T$),
                    ("empty context", "variable binding")),
            ),
                grid.vline(stroke: lineWidth),
            [
            #set table(align: (x, y) => if x == 1 { right } else { center })
            #set table(inset: (left: 0.3em))

            #table(columns: (3fr, 1fr), stroke: none,
                tablehead("Evaluation"), rect(stroke: lineWidth, inset: (left: 0.4em, right: 0.4em, top: 0.3em, bottom: 0.3em), $t arrow.r.long t'$),
                prooftree(rule($t_1 space t_2 arrow.r.long t'_1 space t_2$, $t_1 arrow.r.long t'_1$)), "(App1)",
                prooftree(rule($v_1 space t_2 arrow.r.long v_1 space t'_2$, $t_2 arrow.r.long t'_2$)), "(App2)",
              $(lambda x : T_11 . t_12) space v_2 arrow.r.long [x arrow.r.bar v_2] space t_12$, "(AppAbs)",

              tablehead("Typing"), rect(stroke: lineWidth, inset: (left: 0.4em, right: 0.4em, top: 0.3em, bottom: 0.3em), $Gamma tack.r t : T$),
              prooftree(rule($Gamma tack.r x : T$, $x : T in Gamma$)), "(T-Var)",
              prooftree(rule($Gamma tack.r lambda x : T_1 . t_2 : T_1 arrow.r T_2$, $Gamma, x : T_1 tack.r t_2 : T_2$)), "(T-Abs)",
              prooftree(rule($Gamma tack.r t_1 space t_2 : T_12$, $Gamma tack.r t_1 : T_11 arrow.r T_12$, $Gamma tack.r t_2 : T_11$)), "(T-App)",
          )],
      )
]

#let nat = [  // Natural numbers and booleans for stlc
    #show table.cell: set text(style: "italic")
    #set table.cell(align: horizon)

    #grid(columns: (5fr, 7fr), stroke: none, align: top,
            table(columns: (1fr), align: (left), stroke: none,
                tablehead("New syntactic forms"),
                definition("t", "(terms)",
                    ("...", "true", "false", "if t then t else t", "0", "succ t", "iszero t"),
                    ("", "constant true", "constant false", "conditional", "constant zero", "succ", "iszero"), division: (1em, 1.5em, 1fr, 1fr)),

                definition("v", "(values)",
                    ("...", "true", "false", "n"),
                    ("", "true value", "false value", "numerical value"), division: (1em, 1.5em, 3fr, 5fr)),

                definition("n", "(numeric values)",
                    ("0", "succ n"),
                    ("", "constant true", "constant false", "conditional", "constant zero", "succ", "iszero"), division: (1em, 1.5em, 3fr, 5fr)),

                definition("T", "(types)",
                    ("...", "Bool", "Nat"),
                    ("", "booleans", "natural numbers"), division: (1em, 1.5em, 3fr, 5fr)),
            ),

            grid.vline(stroke: lineWidth),

            [
                #set table(align: (x, y) => if x == 1 { right } else { center })
                #set table(inset: (left: 0.3em))
                #show math.equation: set text(style: "italic")

                #let ifelse(t1, t2, t3) = [if #t1 then #t2 else #t3]

                #table(columns: (3.0fr, 1fr), stroke: none,
                    tablehead("New evaluation rules"), rect(stroke: lineWidth, inset: (left: 0.4em, right: 0.4em, top: 0.3em, bottom: 0.3em), $t arrow.r.long t'$),

                    prooftree(rule($"if true then " t_1 " else " t_2 arrow.r.long t_1$)), "(IfTrue)", // 
                    prooftree(rule($"if false then " t_1 " else " t_2 arrow.r.long t_2$)), "(IfFalse)",
                    prooftree(vertical-spacing: 0.5em, rule(align(center, $"if " t_1 " then " t_2 " else " t_3 \ arrow.r.long "if " t'_1 " then " t_2 " else " t_3$), $t_1 arrow.r.long t'_1$)), "(If)",

                    tablehead("New typing rules"), rect(stroke: lineWidth, inset: (left: 0.4em, right: 0.4em, top: 0.3em, bottom: 0.3em), $Gamma tack.r t : T$),

                    prooftree(rule($Gamma tack.r "true": "Bool"$)), "(T-True)",
                    prooftree(rule($Gamma tack.r "false": "Bool"$)), "(T-False)",
                    prooftree(rule($Gamma tack.r "if " t_1 " then " t_2 " else " t_3 : "T"$, $Gamma tack.r t_1 : "Bool"$, $Gamma tack.r t_2 : T$, $Gamma tack.r t_3 : T$)), "(T-If)",

                    prooftree(rule($Gamma tack.r "0": "Nat"$)), "(T-Zero)",
                    prooftree(rule($Gamma tack.r "succ " t_1 : "Nat"$, $Gamma tack.r t_1 : "Nat"$)), "(T-Succ)",
                    prooftree(rule($Gamma tack.r "pred" t_1 : "Nat"$, $Gamma tack.r t_1 : "Nat"$)), "(T-Pred)",
                    prooftree(rule($Gamma tack.r "iszero " t_1 : "Bool"$, $Gamma tack.r t_1 : "Nat"$)), "(T-IsZero)",
                )
            ])
]

#let serverarrow = $attach(arrow.r.long, br: server)$
#let clientarrow = $attach(arrow.r.long, br: client)$

#let separator = $space;$

#let serverrule(i, o, t) = $angle.l #i, #o separator #t angle.r$
#let clientrule(i, o) = $angle.l #i, #o angle.r$
#let globalrule(client, server) = $#client bar.v #server$

#let snap(it) = $"snap" it$

#let start = $"start"$

#let debugger = [
    #show table.cell: set text(style: "italic")
    #set table.cell(align: horizon)

    #grid(columns: (5fr, 7.0fr), stroke: none, align: top,
        table(columns: (1fr), align: (left), stroke: none,
            tablehead("Syntax"),
            definition(global, "(global debugger)",
                ($client bar.v server$,),
                ("",), division: (1.0em, 1.5em, 4fr, 9fr)),

            definition(server, highlight(silver, "(server)"),
                ($boxed(operation) , boxed(message) separator t$,),
                ("",), division: (1.0em, 1.5em, 4fr, 9fr)),

            definition(client, highlight(silver, "(client)"),
                ($boxed(operation) , boxed(message)$,),
                ("",), division: (1.0em, 1.5em, 4fr, 9fr)),

            definition(message, "(server messages)",
                ($nothing$, $snap(t)$, [ack #operation],),
                ("nothing", "term", "acknowledgement"), division: (1.3em, 1.5em, 4fr, 9fr)),

            definition(operation, "(debug commands)",
                ($nothing$, "step", "inspect"),
                ("nothing", "single step", "inspection"), division: (1.3em, 1.5em, 4fr, 9fr)),

            tablehead("Initial configuration"),

            $d_start = clientrule(nothing, nothing) bar.v serverrule(nothing, nothing, t_start)$,
            //[$t_start$#h(1fr)#text(style: "italic", "program")#h(0.3em)]
        ),

        grid.vline(stroke: lineWidth),


        [
            #set table(align: (x, y) => if x == 1 { right } else { center })
            #set table(inset: (left: 0.3em))

            #table(columns: (3.2fr, 1.0fr), stroke: none,
                tablehead("Server evaluation"), rect(stroke: lineWidth, inset: (left: 0.4em, right: 0.4em, top: 0.4em, bottom: 0.6em), $server serverarrow server'$),


                prooftree(rule(rect(height: 2em, stroke: none, $serverrule(boxed("step") , boxed(nothing), t) serverarrow serverrule(boxed(nothing) , boxed("ack step"), t')$), $t arrow.r.long t'$)), "(Step)",


                prooftree(rule(rect(height: 2em, stroke: none, $serverrule(boxed("step"), boxed(nothing), v) serverarrow serverrule(boxed(nothing), boxed("ack" nothing), v)$))), "(Fallback)",


                prooftree(rule(rect(height: 2em, stroke: none, grid(columns: 2, $serverrule(boxed("inspect"), boxed(nothing), t) serverarrow serverrule(boxed(nothing), boxed(snap(t)), t)$)))), "(Inspect)",

                tablehead("Client evaluation"), rect(stroke: lineWidth, inset: (left: 0.4em, right: 0.4em, top: 0.4em, bottom: 0.6em), $client clientarrow client'$),

                prooftree(rule($clientrule(boxed(operation), boxed(message)) clientarrow clientrule(boxed(operation), boxed(nothing))$)), "(Process)", // todo output from whose perspective?
            )

            #table(columns: (3.0fr, 1.5fr), stroke: none,
                tablehead("Global evaluation"), rect(stroke: lineWidth, inset: (left: 0.4em, right: 0.4em, top: 0.4em, bottom: 0.6em), $d dbgarrow d'$),

                prooftree(rule(rect(height: 3em, stroke: none, $globalrule(clientrule(boxed(operation) , boxed(nothing)), serverrule(boxed(nothing), boxed(nothing), t)) \ dbgarrow globalrule(clientrule(boxed(nothing), boxed(nothing)), serverrule(boxed(operation) , boxed(nothing), t))$,))), "(Input)",
                
                prooftree(rule(rect(height: 3em, stroke: none, $globalrule(clientrule(boxed(operation) , boxed(nothing)), serverrule(boxed(nothing) , boxed(message), t)) \ dbgarrow globalrule(clientrule(boxed(operation), boxed(message)), serverrule(boxed(nothing) , boxed(nothing), t))$,))), "(Output)",

                prooftree(rule($globalrule(client, server) dbgarrow globalrule(client, server)$, $client clientarrow client'$)), highlight(silver, "(Client)"),

                prooftree(rule($globalrule(client, server) dbgarrow globalrule(client, server)$, $server serverarrow server'$)), highlight(silver, "(Server)"),
            // todo: gray background for messages
            // rect(fill: blue, width: auto, height: auto, text(top-edge: "ascender", "ack step"))
            )
        ])
]

#let executionstate = $e$
#let breakpoints = $b$
#let programcounter = $n$

#let pause = text(style: "italic", "pause")
#let play = text(style: "italic", "play")
#let bpadd = $"bp"^+ space n$
#let bpremove = $"bp"^- space n$

#let conserverrule(i, o, n, e, b, t) = $angle.l #i, #o, #n, #e, #b separator #t angle.r$

#let conventionalsyntax = [
    #show table.cell: set text(style: "italic")
    #set table.cell(align: horizon)

    #grid(columns: (5fr, 5fr), stroke: none, align: top,
        table(columns: (1fr), align: (left), stroke: none,
            tablehead("New syntactic forms"),
            definition(server, highlight(silver, "(server)"),
                ($angle.l boxed(operation), boxed(message), highlight(#silver, #[#programcounter, #executionstate, #breakpoints])separator t angle.r$,),
                ("",), division: (1.0em, 1.5em, 4fr, 9fr)),

            definition(executionstate, "(execution state)",
                ("paused", "play"),
                ("paused state", "unpaused state"), division: (1.0em, 1.5em, 4fr, 9fr)),

            definition(breakpoints, "(breakpoints)",
                ($nothing$, $n, b$),
                ("empty", "list of numerics"), division: (1.0em, 1.5em, 4fr, 9fr)),

        ),

        //grid.vline(stroke: lineWidth),

        table(columns: (1fr), align: (left), stroke: none,
            tablehead(""),
            definition(message, highlight(silver, "(server messages)"),
                ($...$, [hit n],),
                ("", "breakpoint hit"), division: (1.3em, 1.5em, 4fr, 9fr)),

            definition(operation, highlight(silver, "(debug commands)"),
                ($...$, play, pause, bpadd, bpremove),
                ("", "unpause", "pause", "add breakpoint", "remove breakpoint"), division: (1.3em, 1.5em, 4fr, 9fr)),
        ),

        grid.hline(stroke: lineWidth),

        table(columns: (1fr), align: (left), stroke: none,
            tablehead([Numericals from $lambda^arrow.r$]),

            definition("n", "(numeric values)",
                    ("0", "succ n"),
                    ("constant zero", "succ"), division: (1em, 1.5em, 3fr, 5fr)),

        ),
  )]

#let conventionalevaluation = [
    #show table.cell: set text(style: "italic")
    #set table.cell(align: horizon)

            #set table(align: (x, y) => if x == 1 { right } else { center })
            #set table(inset: (left: 0.3em))

            #let neb = $programcounter, executionstate, breakpoints,$
            #let incremented = $"succ" programcounter, executionstate, breakpoints,$
            #let inset = (left: 1mm, top: 0mm, bottom: 0mm , right: 1mm)
            #let outset = (top: 0.7mm, bottom: 1.0mm)

            #table(columns: (3fr, 1.2fr), stroke: none,
                tablehead("Server evaluation"), rect(stroke: lineWidth, inset: (left: 0.4em, right: 0.4em, top: 0.4em, bottom: 0.6em), $server serverarrow server'$),

                prooftree(rule(rect(height: 2em, stroke: none, $angle.l boxed("step"), boxed(nothing) , highlight(#silver, #neb, inset: #inset, outset: #outset) separator t angle.r serverarrow angle.l boxed(nothing), boxed("ack step"), highlight(#silver, #incremented, inset: #inset, outset: #outset) separator t' angle.r$), highlight(silver, $executionstate = "paused"$), $t arrow.r.long t'$)), highlight(silver, "(Step)"),

                prooftree(rule(rect(height: 2em, stroke: none, $angle.l boxed("step"), boxed(nothing) , programcounter, executionstate, breakpoints separator t angle.r serverarrow angle.l boxed(nothing), boxed("ack" nothing), programcounter, executionstate, breakpoints separator t angle.r$), $e eq.not "paused"$)), "(Fallback2)",

                prooftree(rule(rect(height: 2em, stroke: none, grid(columns: 2, $angle.l boxed("pause"), boxed(nothing) , programcounter, executionstate, breakpoints separator t angle.r serverarrow angle.l boxed(nothing), boxed(nothing), programcounter, "paused", breakpoints separator t angle.r$)))), "(Pause)",

                prooftree(rule(rect(height: 2em, stroke: none, grid(columns: 2, $angle.l boxed("play"), boxed(nothing) , programcounter, executionstate, breakpoints separator t angle.r serverarrow angle.l boxed(nothing), boxed(nothing), programcounter, "play", breakpoints separator t angle.r$)))), "(Play)",

                prooftree(rule(rect(height: 2em, stroke: none, grid(columns: 2, $angle.l boxed(bpadd), boxed(nothing) , programcounter', executionstate, breakpoints separator t angle.r serverarrow angle.l boxed(nothing), boxed(nothing), programcounter', executionstate, breakpoints' separator t angle.r$)), $breakpoints' = n, breakpoints$)), "(BreakpointAdd)",

                prooftree(rule(rect(height: 2em, stroke: none, grid(columns: 2, $angle.l boxed(bpremove), boxed(nothing) , programcounter', executionstate, breakpoints separator t angle.r serverarrow angle.l boxed(nothing), boxed(nothing), programcounter', executionstate, breakpoints' separator t angle.r$)), $breakpoints' = breakpoints without n$)), "(BreakpointRemove)",

                tablehead("Global evaluation"), rect(stroke: lineWidth, inset: (left: 0.4em, right: 0.4em, top: 0.4em, bottom: 0.6em), $global dbgarrow global'$),

                prooftree(rule(rect(height: 2em, stroke: none, $globalrule(clientrule(boxed(nothing), boxed(nothing)), conserverrule(nothing, nothing, programcounter, executionstate, breakpoints, t)) dbgarrow globalrule(clientrule(boxed(nothing), boxed(nothing)), conserverrule(nothing, nothing, "succ" programcounter, executionstate, breakpoints, t'))$), $executionstate = "play"$, $t arrow.r.long t'$, $n in.not b$)), "(Run)",

// todo add global and add n not in b

                prooftree(rule(rect(height: 2em, stroke: none, $globalrule(clientrule(boxed(operation), nothing), conserverrule(nothing, nothing,  programcounter, "play", breakpoints, t)) dbgarrow globalrule(clientrule(boxed(operation), nothing), conserverrule(nothing, boxed("hit" n), programcounter, "paused", breakpoints, t))$), $programcounter in breakpoints$)), "(BreakpointHit)",
            // todo: gray background for messages
            // rect(fill: blue, width: auto, height: auto, text(top-edge: "ascender", "ack step"))
            )
        
]

#let snapshots = $s$
#let backwards = $"step"^arrow.l$
#let interval = $theta$

#let revserverrule(i, o, n, e, b, s, t) = $angle.l #i, #o, #n, #e, #b, #s separator #t angle.r$

#let reversible = [
    #show table.cell: set text(style: "italic")
    #set table.cell(align: horizon)

    #let inset = 1mm

    #grid(columns: (1fr, 1fr), stroke: none, align: top,
        table(columns: (1fr), align: (left), stroke: none,
            tablehead("New syntactic forms"),
            definition(server, "(server)",
                ($angle.l boxed(operation), boxed(message), programcounter, executionstate, breakpoints, highlight(#silver, #snapshots, inset: #inset) separator t angle.r$,),
                ("",), division: (1.0em, 1.5em, 4fr, 9fr)),

            definition(operation, "(debug commands)",
                ($...$, highlight(silver, backwards)),
                ("", highlight(silver, "backwards step")), division: (1.3em, 1.5em, 4fr, 9fr)),
        ),

        table(columns: (1fr), align: (left), stroke: none,
            definition(snapshots, "(snapshots)",
                ($(0, t)$, $(n, t), s$,),
                ("start snapshot", "list of snapshots"), division: (1.0em, 1.5em, 4fr, 9fr)),
        ),

        grid.hline(stroke: lineWidth),

        grid.cell(colspan: 2, [
            #set table(align: (x, y) => if x == 1 { right } else { center })
            #set table(inset: (left: 0.3em))

            #table(columns: (3fr, 1.2fr), stroke: none,
                tablehead("Server evaluation"), rect(stroke: lineWidth, inset: (left: 0.4em, right: 0.4em, top: 0.4em, bottom: 0.6em), $server serverarrow server'$),

                prooftree(rule(rect(height: 2em, stroke: none, $revserverrule(backwards, nothing, "succ" programcounter, executionstate, breakpoints, snapshots, t) serverarrow revserverrule(nothing, boxed(#[ack #backwards]), programcounter, executionstate, breakpoints, snapshots, t'')$), $snapshots = (0, t')$, $executionstate = "paused"$, $t' attach(arrow.r.long, tr: n) t''$,)), "(BackwardStep0)",

                prooftree(rule(rect(height: 2em, stroke: none, $revserverrule(backwards, nothing, "succ" programcounter, executionstate, breakpoints, snapshots, t) serverarrow revserverrule(boxed(#[ack #backwards]), nothing, programcounter, executionstate, breakpoints, snapshots, t'')$), $n eq.not n'$, $snapshots = ((n', t'), snapshots')$, $executionstate = "paused"$, $t' attach(arrow.r.long, tr: n-n') t''$,)), "(BackwardStep1)",

                prooftree(rule(rect(height: 2em, stroke: none, $revserverrule(backwards, nothing, "succ" programcounter, executionstate, breakpoints, snapshots, t) serverarrow revserverrule(nothing, boxed(#[ack #backwards]), programcounter, executionstate, breakpoints, snapshots',  t')$), $snapshots = ((n, t'), snapshots')$, $executionstate = "paused"$,)), "(BackwardStep2)",

                prooftree(rule(rect(height: 2em, stroke: none, $revserverrule(backwards, nothing, programcounter, executionstate, breakpoints, snapshots, t) serverarrow revserverrule(nothing, boxed("ack" nothing), programcounter, executionstate, breakpoints, snapshots, t)$), $e eq.not "paused"$)), "(BackwardFallback1)",

                prooftree(rule(rect(height: 2em, stroke: none, $revserverrule(backwards, nothing, 0, executionstate, breakpoints, snapshots, t) serverarrow revserverrule(nothing, boxed("ack" nothing), 0, executionstate, breakpoints, snapshots, t)$), $snapshots = (0, t)$)), "(BackwardFallback2)",

                tablehead("Global Evaluation"), rect(stroke: lineWidth, inset: (left: 0.4em, right: 0.4em, top: 0.4em, bottom: 0.6em), $global dbgarrow global'$),

                prooftree(rule(rect(height: 2em, stroke: none, $globalrule(clientrule( boxed(nothing), boxed(nothing)), revserverrule(nothing, nothing, programcounter, executionstate, breakpoints, snapshots, t)) dbgarrow globalrule(clientrule(boxed(nothing), boxed(nothing)), revserverrule(nothing, nothing, "succ" programcounter, executionstate, breakpoints, snapshots', t'))$), $executionstate = "play"$, $t arrow.r.long t'$, $snapshots' = ( ("succ" n, t'), snapshots )$, $n in.not b$, $("succ" n) space % space interval = 0$)), highlight(silver, "(Run1)"),

                prooftree(rule(rect(height: 2em, stroke: none, $globalrule(clientrule( boxed(nothing), boxed(nothing)), revserverrule(nothing, nothing, programcounter, executionstate, breakpoints, snapshots, t)) dbgarrow globalrule(clientrule(boxed(nothing), nothing), revserverrule(nothing, nothing, "succ" programcounter, executionstate, breakpoints, snapshots, t'))$), $executionstate = "play"$, $t arrow.r.long t'$, $n in.not b$, $("succ" n) space % space interval eq.not 0$)), highlight(silver, "(Run2)"),
            )
        ])
    )
]

#let bindings = [  // Let bindings for stlc
    #show table.cell: set text(style: "italic")
    #set table.cell(align: horizon)


    #grid(columns: (5fr, 7fr), stroke: none, align: top,
            table(columns: (1fr), align: (left), stroke: none,
                tablehead("New syntactic forms"),
            ),

            grid.vline(stroke: lineWidth),

            [
                #set table(align: (x, y) => if x == 1 { right } else { center })
                #set table(inset: (left: 0.3em))
                #show math.equation: set text(style: "italic")

                #let ifelse(t1, t2, t3) = [if #t1 then #t2 else #t3]

                #table(columns: (3fr, 1fr), stroke: none,
                    tablehead("New evaluation rules"), rect(stroke: lineWidth, inset: (left: 0.4em, right: 0.4em, top: 0.3em, bottom: 0.3em), $t arrow.r.long t'$),

                    prooftree(rule($"if true then " t_1 " else " t_2 arrow.r.long t_1$)), "(IfTrue)", // 
                    prooftree(rule($"if false then " t_1 " else " t_2 arrow.r.long t_2$)), "(IfFalse)",
                    prooftree(vertical-spacing: 0.5em, rule(align(center, $"if " t_1 " then " t_2 " else " t_3 \ arrow.r.long "if " t'_1 " then " t_2 " else " t_3$), $t_1 arrow.r.long t'_1$)), "(If)",

                    tablehead("Typing"), rect(stroke: lineWidth, inset: (left: 0.4em, right: 0.4em, top: 0.3em, bottom: 0.3em), $Gamma tack.r t : T$),

                )
            ])
]

#let subst = $"subst" t_1 t_2$

#let intercession = [
    #show table.cell: set text(style: "italic")
    #set table.cell(align: horizon)

    #grid(columns: (1fr, 2fr), align: (left), stroke: none,
            table(columns: (1fr), align: (left), stroke: none,
                tablehead("New syntactic forms"),
            definition(operation, "(commands)",
                ($...$, subst),
                ("", "substitute"), division: (1.3em, 1.5em, 4fr, 9fr)),
        ),

        grid.vline(stroke: lineWidth),

        [
            #set table(align: (x, y) => if x == 1 { right } else { center })
            #set table(inset: (left: 0.3em))

            #table(columns: (4fr, 1.1fr), stroke: none,
                tablehead("Server evaluation"), rect(stroke: lineWidth, inset: (left: 0.4em, right: 0.4em, top: 0.4em, bottom: 0.6em), $server serverarrow server'$),
                prooftree(rule(grid(columns: 1, align: alignment.center, $revserverrule(subst, nothing, programcounter, executionstate, breakpoints, snapshots, t)$, rect(height: 2em, stroke: none, $serverarrow revserverrule(nothing, boxed("ack" subst),  programcounter, executionstate, breakpoints, snapshots, [t_1 arrow.r.bar t_2] space t)$)), $Gamma tack.r t_2 : T'$, $Gamma, t_1 : T'  tack.r t : T$)), "(Subst)", // todo should t_1 be a value?
            )
        ])
]

