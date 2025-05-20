
#import "../../lib/util.typ": semantics
#import "figures/semantics.typ": *
#import "foundations.typ": remotedbg, conventionaldbg, reversibledbg, intercessiondbg

= Simply typed lambda calculus extensions<app:stlc>

The rules for simply typed lambda calculus taken from the definitive work, _Types and Programming Languages_ from Benjamin C. Pierce.

#semantics(
    [#strong[Natural numbers and booleans for $lambda^arrow.r$.] The syntax, evaluation, and typing rules for the natural numbers and booleans @pierce02:types.],
    [#nat],
    "fig:nat")

#semantics(
    [#strong[Let bindings for $lambda^arrow.r$.] The syntax, evaluation, and typing rules for let bindings @pierce02:types.],
    [#bindings],
    "fig:bindings")

= Full syntax and evaluation rules for the debugger <app:debuggers>

In this appendix we provide the unabbreviated semantic rules for the debuggers from @chapter:foundations.

== The conventional debugger

#semantics(
    [*Syntax rules of the conventional live debugger #conventionaldbg.* The complete set of syntax rules for #pause, #play, and _breakpoints_ for the #remotedbg debugger semantics. Changes to the minimal rules in @fig:stlc.debugger are highlighted.],
[
    #show table.cell: set text(style: "italic")
    #set table.cell(align: horizon)

    #grid(columns: (5fr, 5.0fr), stroke: none, align: top,
        table(columns: (1fr), align: (left), stroke: none,
            tablehead("Syntactic forms"),
            definition(global, "(global debugger)",
                ($client bar.v server$,),
                ("",), division: (1.0em, 1.5em, 4fr, 9fr)),

            definition(server, highlight(silver, "(server)"),
                ($angle.l boxed(operation), boxed(message), highlight(#silver, #[#programcounter, #executionstate, #breakpoints])separator t angle.r$,),
                ("",), division: (1.0em, 1.5em, 4fr, 9fr)),

            definition(client, highlight(silver, "(client)"),
                ($boxed(operation) , boxed(message)$,),
                ("",), division: (1.0em, 1.5em, 4fr, 9fr)),

            definition(message, highlight(silver, "(server messages)"),
                ($nothing$, $snap(t)$, [ack #operation], highlight(silver, [hit n])),
                ("nothing", "term", "acknowledgement", highlight(silver, "breakpoint hit")), division: (1.3em, 1.5em, 4fr, 9fr)),
        ),

        //grid.vline(stroke: lineWidth),

        table(columns: (1fr), align: (left), stroke: none,
            tablehead(""),
            definition(operation, highlight(silver, "(debug commands)"),
                ($nothing$, "step", "inspect", highlight(silver, play), highlight(silver, pause), highlight(silver, bpadd), highlight(silver, bpremove)),
                ("nothing", "single step", "inspection", highlight(silver, "unpause"), highlight(silver, "pause"), highlight(silver, "add breakpoint"), highlight(silver, "remove breakpoint")), division: (1.3em, 1.5em, 4fr, 9fr)),

            definition(executionstate, highlight(silver, "(execution state)"),
                ("paused", "play"),
                ("paused state", "unpaused state"), division: (1.0em, 1.5em, 4fr, 9fr)),

            definition(breakpoints, highlight(silver, "(breakpoints)"),
                ($nothing$, $n, b$),
                ("empty", "list of numerics"), division: (1.0em, 1.5em, 4fr, 9fr)),

        ),
        
        grid.hline(stroke: lineWidth),

        table(columns: (1fr), align: (left), stroke: none,
            tablehead([Numericals from $lambda^arrow.r$]),

            definition("n", "(numeric values)",
                    ("0", "succ n"),
                    ("constant zero", "succ"), division: (1em, 1.5em, 3fr, 5fr)),
        ),

        table(columns: (1fr), align: (left), stroke: none,
            tablehead([New initial configuration]),

            highlight(silver, $d_start = clientrule(nothing, nothing) bar.v conserverrule(nothing, nothing, 0, "paused", nothing, t_start)$),
        ),

  )], "app:fig:stlc.conventional.syntax")



#semantics(
    [*Server and client evaluation of conventional live debugger operations for #conventionaldbg.* Changes to the minimal rules in @fig:stlc.debugger are highlighted.],
    [
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

                prooftree(rule(rect(height: 2em, stroke: none, $conserverrule(boxed("step"), boxed(nothing),programcounter, executionstate, breakpoints,  v) serverarrow conserverrule(boxed(nothing), boxed("ack" nothing),programcounter, executionstate, breakpoints,  v)$))), "(Fallback)",

                prooftree(rule(rect(height: 2em, stroke: none, $angle.l boxed("step"), boxed(nothing) , programcounter, executionstate, breakpoints separator t angle.r serverarrow angle.l boxed(nothing), boxed("ack" nothing), programcounter, executionstate, breakpoints separator t angle.r$), $e eq.not "paused"$)), "(Fallback2)",

                prooftree(rule(rect(height: 2em, stroke: none, grid(columns: 2, $angle.l boxed("pause"), boxed(nothing) , programcounter, executionstate, breakpoints separator t angle.r serverarrow angle.l boxed(nothing), boxed(nothing), programcounter, "paused", breakpoints separator t angle.r$)))), "(Pause)",

                prooftree(rule(rect(height: 2em, stroke: none, grid(columns: 2, $angle.l boxed("play"), boxed(nothing) , programcounter, executionstate, breakpoints separator t angle.r serverarrow angle.l boxed(nothing), boxed(nothing), programcounter, "play", breakpoints separator t angle.r$)))), "(Play)",

                prooftree(rule(rect(height: 2em, stroke: none, grid(columns: 2, $angle.l boxed(bpadd), boxed(nothing) , programcounter', executionstate, breakpoints separator t angle.r serverarrow angle.l boxed(nothing), boxed(nothing), programcounter', executionstate, breakpoints' separator t angle.r$)), $breakpoints' = n, breakpoints$)), "(BreakpointAdd)",

                prooftree(rule(rect(height: 2em, stroke: none, grid(columns: 2, $angle.l boxed(bpremove), boxed(nothing) , programcounter', executionstate, breakpoints separator t angle.r serverarrow angle.l boxed(nothing), boxed(nothing), programcounter', executionstate, breakpoints' separator t angle.r$)), $breakpoints' = breakpoints without n$)), "(BreakpointRemove)",

            tablehead("Client evaluation"), rect(stroke: lineWidth, inset: (left: 0.4em, right: 0.4em, top: 0.4em, bottom: 0.6em), $client clientarrow client'$),

                prooftree(rule($clientrule(boxed(operation), boxed(message)) clientarrow clientrule(boxed(operation), boxed(nothing))$)), "(Process)", // todo output from whose perspective?

            )
        
],
    "app:fig:stlc.conventional.evaluation")

#semantics(
    [*Global evaluation rules of conventional live debugger operations for #conventionaldbg.* Changes to the minimal rules in @fig:stlc.debugger are highlighted.],
    [
    #show table.cell: set text(style: "italic")
    #set table.cell(align: horizon)

            #set table(align: (x, y) => if x == 1 { right } else { center })
            #set table(inset: (left: 0.3em))

            #let neb = $programcounter, executionstate, breakpoints$
            #let incremented = $"succ" programcounter, executionstate, breakpoints$
            #let inset = (left: 1mm, top: 0mm, bottom: 0mm , right: 1mm)
            #let outset = (top: 0.7mm, bottom: 1.0mm)

            #table(columns: (3fr, 1.2fr), stroke: none,
                tablehead("Global evaluation"), rect(stroke: lineWidth, inset: (left: 0.4em, right: 0.4em, top: 0.4em, bottom: 0.6em), $global dbgarrow global'$),

    prooftree(rule(rect(height: 3em, stroke: none, $globalrule(clientrule(boxed(operation) , boxed(nothing)), conserverrule(boxed(nothing), boxed(nothing),programcounter, executionstate, breakpoints,  t)) \ dbgarrow globalrule(clientrule(boxed(nothing), boxed(nothing)), conserverrule(boxed(operation) , boxed(nothing),programcounter, executionstate, breakpoints,  t))$,))), "(Input)",
                
                prooftree(rule(rect(height: 3em, stroke: none, $globalrule(clientrule(boxed(operation) , boxed(nothing)), conserverrule(boxed(nothing) , boxed(message),programcounter, executionstate, breakpoints,  t)) \ dbgarrow globalrule(clientrule(boxed(operation), boxed(message)), conserverrule(boxed(nothing) , boxed(nothing),programcounter, executionstate, breakpoints,  t))$,))), "(Output)",

                prooftree(rule($globalrule(client, server) dbgarrow globalrule(client, server)$, $client clientarrow client'$)), "(Client)",

                prooftree(rule($globalrule(client, server) dbgarrow globalrule(client, server)$, $server serverarrow server'$)), "(Server)",
                prooftree(rule(rect(height: 2em, stroke: none, $globalrule(clientrule(boxed(nothing), boxed(nothing)), conserverrule(nothing, nothing, programcounter, executionstate, breakpoints, t)) dbgarrow globalrule(clientrule(boxed(nothing), boxed(nothing)), conserverrule(nothing, nothing, "succ" programcounter, executionstate, breakpoints, t'))$), $executionstate = "play"$, $t arrow.r.long t'$, $n in.not b$)), "(Run)",

                prooftree(rule(rect(height: 2em, stroke: none, $globalrule(clientrule(boxed(operation), nothing), conserverrule(nothing, nothing,  programcounter, "play", breakpoints, t)) dbgarrow globalrule(clientrule(boxed(operation), nothing), conserverrule(nothing, boxed("hit" n), programcounter, "paused", breakpoints, t))$), $programcounter in breakpoints$)), "(BreakpointHit)",
            )
        
],
    "app:fig:stlc.conventional.global")

== The reversible debugger

#let inset = 1mm

#semantics(
    [*Syntax rules of the reversible debugger #reversibledbg.* The reversible specific parts are highlighted.],
[
    #show table.cell: set text(style: "italic")
    #set table.cell(align: horizon)

    #grid(columns: (5fr, 5.0fr), stroke: none, align: top,
        table(columns: (1fr), align: (left), stroke: none,
            tablehead("Syntactic forms"),
            definition(global, "(global debugger)",
                ($client bar.v server$,),
                ("",), division: (1.0em, 1.5em, 4fr, 9fr)),

            definition(server, highlight(silver, "(server)"),
                ($angle.l boxed(operation), boxed(message), highlight(#silver, programcounter, inset: #inset), executionstate, breakpoints, highlight(#silver, #snapshots, inset: #inset) separator t angle.r$,),
                ("",), division: (1.0em, 1.5em, 4fr, 9fr)),

            definition(client, "(client)",
                ($boxed(operation) , boxed(message)$,),
                ("",), division: (1.0em, 1.5em, 4fr, 9fr)),

            definition(message, "(server messages)",
                ($nothing$, $snap(t)$, [ack #operation], [hit n]),
                ("nothing", "term", "acknowledgement", "breakpoint hit"), division: (1.3em, 1.5em, 4fr, 9fr)),

            definition(snapshots, highlight(silver, "(snapshots)"),
                ($(0, t)$, $(n, t), snapshots$,),
                ("start snapshot", "list of snapshots"), division: (1.0em, 1.5em, 4fr, 9fr)),
        ),

        //grid.vline(stroke: lineWidth),

        table(columns: (1fr), align: (left), stroke: none,
            tablehead(""),
            definition(operation, highlight(silver, "(debug commands)"),
                ($nothing$, "step", "inspect", play, pause, bpadd, bpremove, highlight(silver, backwards)),
                ("nothing", "single step", "inspection", "unpause", "pause", "add breakpoint", "remove breakpoint", highlight(silver, "backwards step")), division: (1.3em, 1.5em, 4fr, 9fr)),

            definition(executionstate, "(execution state)",
                ("paused", "play"),
                ("paused state", "unpaused state"), division: (1.0em, 1.5em, 4fr, 9fr)),

            definition(breakpoints, "(breakpoints)",
                ($nothing$, $n, b$),
                ("empty", "list of numerics"), division: (1.0em, 1.5em, 4fr, 9fr)),

        ),
        
        grid.hline(stroke: lineWidth),

        table(columns: (1fr), align: (left), stroke: none,
            tablehead([Numericals from $lambda^arrow.r$]),

            definition("n", "(numeric values)",
                    ("0", "succ n"),
                    ("constant zero", "succ"), division: (1em, 1.5em, 3fr, 5fr)),
        ),

        table(columns: (1fr), align: (left), stroke: none,
            tablehead([New initial configuration]),

            highlight(silver, $d_start = clientrule(nothing, nothing) bar.v revserverrule(nothing, nothing, 0, "paused", nothing, (0, t), t_start)$),
        ),

  )], "app:fig:stlc.reversible.syntax")

#semantics(
    [*Server evaluation of the reversible debugger operations for #reversibledbg.* The reversible specific parts are highlighted.],
    [
    #show table.cell: set text(style: "italic")
    #set table.cell(align: horizon)

            #set table(align: (x, y) => if x == 1 { right } else { center })
            #set table(inset: (left: 0.3em))

            #let neb = $programcounter, executionstate, breakpoints,$
            #let incremented = $"succ" programcounter, executionstate, breakpoints$
            #let inset = (left: 1mm, top: 0mm, bottom: 0mm , right: 1mm)
            #let outset = (top: 0.7mm, bottom: 1.0mm)

            #table(columns: (3fr, 1.2fr), stroke: none,
                tablehead("Server evaluation"), rect(stroke: lineWidth, inset: (left: 0.4em, right: 0.4em, top: 0.4em, bottom: 0.6em), $server serverarrow server'$),

                prooftree(rule(rect(height: 2em, stroke: none, $angle.l boxed("step"), boxed(nothing) , #neb, snapshots separator t angle.r serverarrow angle.l boxed(nothing), boxed("ack step"), #incremented, snapshots separator t' angle.r$), $executionstate = "paused"$, $t arrow.r.long t'$)), "(Step)",

                prooftree(rule(rect(height: 2em, stroke: none, $revserverrule(boxed("step"), boxed(nothing),programcounter, executionstate, breakpoints, snapshots, v) serverarrow revserverrule(boxed(nothing), boxed("ack" nothing),programcounter, executionstate, breakpoints, snapshots, v)$))), "(Fallback)",


                prooftree(rule(rect(height: 2em, stroke: none, $angle.l boxed("step"), boxed(nothing) , programcounter, executionstate, breakpoints, snapshots separator t angle.r serverarrow angle.l boxed(nothing), boxed("ack" nothing), programcounter, executionstate, breakpoints, snapshots, separator t angle.r$), $e eq.not "paused"$)), "(Fallback2)",

                prooftree(rule(rect(height: 2em, stroke: none, grid(columns: 2, $angle.l boxed("pause"), boxed(nothing) , programcounter, executionstate, breakpoints, snapshots separator t angle.r serverarrow angle.l boxed(nothing), boxed(nothing), programcounter, "paused", breakpoints, snapshots separator t angle.r$)))), "(Pause)",

                prooftree(rule(rect(height: 2em, stroke: none, grid(columns: 2, $angle.l boxed("play"), boxed(nothing) , programcounter, executionstate, breakpoints, snapshots separator t angle.r serverarrow angle.l boxed(nothing), boxed(nothing), programcounter, "play", breakpoints, snapshots separator t angle.r$)))), "(Play)",

                prooftree(rule(rect(height: 2em, stroke: none, grid(columns: 2, $angle.l boxed(bpadd), boxed(nothing) , programcounter', executionstate, breakpoints, snapshots separator t angle.r serverarrow angle.l boxed(nothing), boxed(nothing), programcounter', executionstate, breakpoints', snapshots separator t angle.r$)), $breakpoints' = n, breakpoints$)), "(BreakpointAdd)",

                prooftree(rule(rect(height: 2em, stroke: none, grid(columns: 2, $angle.l boxed(bpremove), boxed(nothing) , programcounter', executionstate, breakpoints, snapshots separator t angle.r serverarrow angle.l boxed(nothing), boxed(nothing), programcounter', executionstate, breakpoints', snapshots separator t angle.r$)), $breakpoints' = breakpoints without n$)), "(BreakpointRemove)",

                prooftree(rule(rect(height: 2em, stroke: none, $revserverrule(backwards, nothing, "succ" programcounter, executionstate, breakpoints, snapshots, t) serverarrow revserverrule(nothing, boxed(#[ack #backwards]), programcounter, executionstate, breakpoints, snapshots, t'')$), $snapshots = (0, t')$, $executionstate = "paused"$, $t' attach(arrow.r.long, tr: n) t''$,)), "(BackwardStep0)",

                prooftree(rule(rect(height: 2em, stroke: none, $revserverrule(backwards, nothing, "succ" programcounter, executionstate, breakpoints, snapshots, t) serverarrow revserverrule(boxed(#[ack #backwards]), nothing, programcounter, executionstate, breakpoints, snapshots, t'')$), $n eq.not n'$, $snapshots = ((n', t'), snapshots')$, $executionstate = "paused"$, $t' attach(arrow.r.long, tr: n-n') t''$,)), "(BackwardStep1)",

                prooftree(rule(rect(height: 2em, stroke: none, $revserverrule(backwards, nothing, "succ" programcounter, executionstate, breakpoints, snapshots, t) serverarrow revserverrule(nothing, boxed(#[ack #backwards]), programcounter, executionstate, breakpoints, snapshots',  t')$), $snapshots = ((n, t'), snapshots')$, $executionstate = "paused"$,)), "(BackwardStep2)",

                prooftree(rule(rect(height: 2em, stroke: none, $revserverrule(backwards, nothing, programcounter, executionstate, breakpoints, snapshots, t) serverarrow revserverrule(nothing, boxed("ack" nothing), programcounter, executionstate, breakpoints, snapshots, t)$), $e eq.not "paused"$)), "(BackwardFallback1)",

                prooftree(rule(rect(height: 2em, stroke: none, $revserverrule(backwards, nothing, 0, executionstate, breakpoints, snapshots, t) serverarrow revserverrule(nothing, boxed("ack" nothing), 0, executionstate, breakpoints, snapshots, t)$), $snapshots = (0, t)$)), "(BackwardFallback2)",

  ),
],
    "app:fig:stlc.reversible.evaluation")

#semantics(
    [*Client and global evaluation rules of the reversible debugger operations (#reversibledbg).* The reversible specific parts are highlighted.],
    [
    #show table.cell: set text(style: "italic")
    #set table.cell(align: horizon)

            #set table(align: (x, y) => if x == 1 { right } else { center })
            #set table(inset: (left: 0.3em))

            #let neb = $programcounter, executionstate, breakpoints,$
            #let incremented = $"succ" programcounter, executionstate, breakpoints,$
            #let inset = (left: 1mm, top: 0mm, bottom: 0mm , right: 1mm)
            #let outset = (top: 0.7mm, bottom: 1.0mm)

            #table(columns: (3fr, 1.2fr), stroke: none,
                tablehead("Client evaluation"), rect(stroke: lineWidth, inset: (left: 0.4em, right: 0.4em, top: 0.4em, bottom: 0.6em), $client clientarrow client'$),

                    prooftree(rule($clientrule(boxed(operation), boxed(message)) clientarrow clientrule(boxed(operation), boxed(nothing))$)), "(Process)", // todo output from whose perspective?
                tablehead("Global evaluation"), rect(stroke: lineWidth, inset: (left: 0.4em, right: 0.4em, top: 0.4em, bottom: 0.6em), $global dbgarrow global'$),

    prooftree(rule(rect(height: 3em, stroke: none, $globalrule(clientrule(boxed(operation) , boxed(nothing)), serverrule(boxed(nothing), boxed(nothing), t)) \ dbgarrow globalrule(clientrule(boxed(nothing), boxed(nothing)), serverrule(boxed(operation) , boxed(nothing), t))$,))), "(Input)",
                
                prooftree(rule(rect(height: 3em, stroke: none, $globalrule(clientrule(boxed(operation) , boxed(nothing)), serverrule(boxed(nothing) , boxed(message), t)) \ dbgarrow globalrule(clientrule(boxed(operation), boxed(message)), serverrule(boxed(nothing) , boxed(nothing), t))$,))), "(Output)",

                prooftree(rule($globalrule(client, server) dbgarrow globalrule(client, server)$, $client clientarrow client'$)), "(Client)",

                prooftree(rule($globalrule(client, server) dbgarrow globalrule(client, server)$, $server serverarrow server'$)), "(Server)",


                prooftree(rule(rect(height: 2em, stroke: none, $globalrule(clientrule( boxed(nothing), boxed(nothing)), revserverrule(nothing, nothing, programcounter, executionstate, breakpoints, snapshots, t)) dbgarrow globalrule(clientrule(boxed(nothing), boxed(nothing)), revserverrule(nothing, nothing, "succ" programcounter, executionstate, breakpoints, snapshots', t'))$), $executionstate = "play"$, $t arrow.r.long t'$, $snapshots' = ( ("succ" n, t'), snapshots )$, $n in.not b$, $("succ" n) space % space interval = 0$)), highlight(silver, "(Run1)"),

                prooftree(rule(rect(height: 2em, stroke: none, $globalrule(clientrule( boxed(nothing), boxed(nothing)), revserverrule(nothing, nothing, programcounter, executionstate, breakpoints, snapshots, t)) dbgarrow globalrule(clientrule(boxed(nothing), nothing), revserverrule(nothing, nothing, "succ" programcounter, executionstate, breakpoints, snapshots, t'))$), $executionstate = "play"$, $t arrow.r.long t'$, $n in.not b$, $("succ" n) space % space interval eq.not 0$)), highlight(silver, "(Run2)"),

                prooftree(rule(rect(height: 2em, stroke: none, $globalrule(clientrule(boxed(operation), nothing), revserverrule(nothing, nothing,  programcounter, "play", breakpoints, snapshots, t)) dbgarrow globalrule(clientrule(boxed(operation), nothing), revserverrule(nothing, boxed("hit" n), programcounter, "paused", breakpoints, snapshots,t))$), $programcounter in breakpoints$)), "(BreakpointHit)",
            )
        
],
    "app:fig:stlc.reversible.global")

== The intercession debugger

#semantics(
    [*Syntax rules of the intercession debugger #intercessiondbg.* The intercession specific parts are highlighted.],
[
    #show table.cell: set text(style: "italic")
    #set table.cell(align: horizon)

    #grid(columns: (5fr, 5.0fr), stroke: none, align: top,
        table(columns: (1fr), align: (left), stroke: none,
            tablehead("Syntactic forms"),
            definition(global, "(global debugger)",
                ($client bar.v server$,),
                ("",), division: (1.0em, 1.5em, 4fr, 9fr)),

            definition(server, "(server)",
                ($angle.l boxed(operation), boxed(message), programcounter, executionstate, breakpoints, #snapshots separator t angle.r$,),
                ("",), division: (1.0em, 1.5em, 4fr, 9fr)),

            definition(client, "(client)",
                ($boxed(operation) , boxed(message)$,),
                ("",), division: (1.0em, 1.5em, 4fr, 9fr)),

            definition(message, "(server messages)",
                ($nothing$, $snap(t)$, [ack #operation], [hit n]),
                ("nothing", "term", "acknowledgement", "breakpoint hit"), division: (1.3em, 1.5em, 4fr, 9fr)),

            definition(snapshots, "(snapshots)",
                ($(0, t)$, $(n, t), snapshots$,),
                ("start snapshot", "list of snapshots"), division: (1.0em, 1.5em, 4fr, 9fr)),
        ),

        //grid.vline(stroke: lineWidth),

        table(columns: (1fr), align: (left), stroke: none,
            tablehead(""),
            definition(operation, highlight(silver, "(debug commands)"),
                ($nothing$, "step", "inspect", play, pause, bpadd, bpremove, backwards, highlight(silver, subst)),
                ("nothing", "single step", "inspection", "unpause", "pause", "add breakpoint", "remove breakpoint", "backwards step", highlight(silver, "substitute")), division: (1.3em, 1.5em, 4fr, 9fr)),

            definition(executionstate, "(execution state)",
                ("paused", "play"),
                ("paused state", "unpaused state"), division: (1.0em, 1.5em, 4fr, 9fr)),

            definition(breakpoints, "(breakpoints)",
                ($nothing$, $n, b$),
                ("empty", "list of numerics"), division: (1.0em, 1.5em, 4fr, 9fr)),

        ),
        
        grid.hline(stroke: lineWidth),

        table(columns: (1fr), align: (left), stroke: none,
            tablehead([Numericals from $lambda^arrow.r$]),

            definition("n", "(numeric values)",
                    ("0", "succ n"),
                    ("constant zero", "succ"), division: (1em, 1.5em, 3fr, 5fr)),
        ),

        table(columns: (1fr), align: (left), stroke: none,
            tablehead([New initial configuration]),

            highlight(silver, $d_start = clientrule(nothing, nothing) bar.v revserverrule(nothing, nothing, 0, "paused", nothing, (0, t), t_start)$),
        ),

  )], "app:fig:stlc.intercession.syntax")

#semantics(
    [*Server evaluation of the intercession debugger operations for #intercessiondbg.* The intercession specific parts are highlighted.],
    [
    #show table.cell: set text(style: "italic")
    #set table.cell(align: horizon)

            #set table(align: (x, y) => if x == 1 { right } else { center })
            #set table(inset: (left: 0.3em))

            #let neb = $programcounter, executionstate, breakpoints,$
            #let incremented = $"succ" programcounter, executionstate, breakpoints$
            #let inset = (left: 1mm, top: 0mm, bottom: 0mm , right: 1mm)
            #let outset = (top: 0.7mm, bottom: 1.0mm)

            #table(columns: (3fr, 1.2fr), stroke: none,
                tablehead("Server evaluation"), rect(stroke: lineWidth, inset: (left: 0.4em, right: 0.4em, top: 0.4em, bottom: 0.6em), $server serverarrow server'$),

                prooftree(rule(rect(height: 2em, stroke: none, $angle.l boxed("step"), boxed(nothing) , #neb, snapshots separator t angle.r serverarrow angle.l boxed(nothing), boxed("ack step"), #incremented, snapshots separator t' angle.r$), $executionstate = "paused"$, $t arrow.r.long t'$)), "(Step)",

                prooftree(rule(rect(height: 2em, stroke: none, $revserverrule(boxed("step"), boxed(nothing),programcounter, executionstate, breakpoints, snapshots, v) serverarrow revserverrule(boxed(nothing), boxed("ack" nothing),programcounter, executionstate, breakpoints, snapshots, v)$))), "(Fallback)",


                prooftree(rule(rect(height: 2em, stroke: none, $angle.l boxed("step"), boxed(nothing) , programcounter, executionstate, breakpoints, snapshots separator t angle.r serverarrow angle.l boxed(nothing), boxed("ack" nothing), programcounter, executionstate, breakpoints, snapshots, separator t angle.r$), $e eq.not "paused"$)), "(Fallback2)",

                prooftree(rule(rect(height: 2em, stroke: none, grid(columns: 2, $angle.l boxed("pause"), boxed(nothing) , programcounter, executionstate, breakpoints, snapshots separator t angle.r serverarrow angle.l boxed(nothing), boxed(nothing), programcounter, "paused", breakpoints, snapshots separator t angle.r$)))), "(Pause)",

                prooftree(rule(rect(height: 2em, stroke: none, grid(columns: 2, $angle.l boxed("play"), boxed(nothing) , programcounter, executionstate, breakpoints, snapshots separator t angle.r serverarrow angle.l boxed(nothing), boxed(nothing), programcounter, "play", breakpoints, snapshots separator t angle.r$)))), "(Play)",

                prooftree(rule(rect(height: 2em, stroke: none, grid(columns: 2, $angle.l boxed(bpadd), boxed(nothing) , programcounter', executionstate, breakpoints, snapshots separator t angle.r serverarrow angle.l boxed(nothing), boxed(nothing), programcounter', executionstate, breakpoints', snapshots separator t angle.r$)), $breakpoints' = n, breakpoints$)), "(BreakpointAdd)",

                prooftree(rule(rect(height: 2em, stroke: none, grid(columns: 2, $angle.l boxed(bpremove), boxed(nothing) , programcounter', executionstate, breakpoints, snapshots separator t angle.r serverarrow angle.l boxed(nothing), boxed(nothing), programcounter', executionstate, breakpoints', snapshots separator t angle.r$)), $breakpoints' = breakpoints without n$)), "(BreakpointRemove)",

                prooftree(rule(rect(height: 2em, stroke: none, $revserverrule(backwards, nothing, "succ" programcounter, executionstate, breakpoints, snapshots, t) serverarrow revserverrule(nothing, boxed(#[ack #backwards]), programcounter, executionstate, breakpoints, snapshots, t'')$), $snapshots = (0, t')$, $executionstate = "paused"$, $t' attach(arrow.r.long, tr: n) t''$,)), "(BackwardStep0)",

                prooftree(rule(rect(height: 2em, stroke: none, $revserverrule(backwards, nothing, "succ" programcounter, executionstate, breakpoints, snapshots, t) serverarrow revserverrule(boxed(#[ack #backwards]), nothing, programcounter, executionstate, breakpoints, snapshots, t'')$), $n eq.not n'$, $snapshots = ((n', t'), snapshots')$, $executionstate = "paused"$, $t' attach(arrow.r.long, tr: n-n') t''$,)), "(BackwardStep1)",

                prooftree(rule(rect(height: 2em, stroke: none, $revserverrule(backwards, nothing, "succ" programcounter, executionstate, breakpoints, snapshots, t) serverarrow revserverrule(nothing, boxed(#[ack #backwards]), programcounter, executionstate, breakpoints, snapshots',  t')$), $snapshots = ((n, t'), snapshots')$, $executionstate = "paused"$,)), "(BackwardStep2)",

                prooftree(rule(rect(height: 2em, stroke: none, $revserverrule(backwards, nothing, programcounter, executionstate, breakpoints, snapshots, t) serverarrow revserverrule(nothing, boxed("ack" nothing), programcounter, executionstate, breakpoints, snapshots, t)$), $e eq.not "paused"$)), "(BackwardFallback1)",

  ),
],
    "app:fig:stlc.intercession.evaluation")

#semantics(
    [*Server (cont.), client and global evaluation rules of the intercession debugger operations (#intercessiondbg).* The intercession specific parts are highlighted.],
    [
    #show table.cell: set text(style: "italic")
    #set table.cell(align: horizon)

            #set table(align: (x, y) => if x == 1 { right } else { center })
            #set table(inset: (left: 0.3em))

            #let neb = $programcounter, executionstate, breakpoints,$
            #let incremented = $"succ" programcounter, executionstate, breakpoints,$
            #let inset = (left: 1mm, top: 0mm, bottom: 0mm , right: 1mm)
            #let outset = (top: 0.7mm, bottom: 1.0mm)

            #table(columns: (3fr, 1.2fr), stroke: none,

                prooftree(rule(rect(height: 2em, stroke: none, $revserverrule(backwards, nothing, 0, executionstate, breakpoints, snapshots, t) serverarrow revserverrule(nothing, boxed("ack" nothing), 0, executionstate, breakpoints, snapshots, t)$), $snapshots = (0, t)$)), "(BackwardFallback2)",

                prooftree(rule(grid(columns: 1, align: alignment.center, $revserverrule(subst, nothing, programcounter, executionstate, breakpoints, snapshots, t)$, rect(height: 2em, stroke: none, $serverarrow revserverrule(nothing, boxed("ack" subst),  programcounter, executionstate, breakpoints, snapshots, [t_1 arrow.r.bar t_2] space t)$)), $Gamma tack.r t_2 : T'$, $Gamma, t_1 : T'  tack.r t : T$)), highlight(silver, "(Subst)"),
                tablehead("Client evaluation"), rect(stroke: lineWidth, inset: (left: 0.4em, right: 0.4em, top: 0.4em, bottom: 0.6em), $client clientarrow client'$),

                    prooftree(rule($clientrule(boxed(operation), boxed(message)) clientarrow clientrule(boxed(operation), boxed(nothing))$)), "(Process)", // todo output from whose perspective?
                tablehead("Global evaluation"), rect(stroke: lineWidth, inset: (left: 0.4em, right: 0.4em, top: 0.4em, bottom: 0.6em), $global dbgarrow global'$),

    prooftree(rule(rect(height: 3em, stroke: none, $globalrule(clientrule(boxed(operation) , boxed(nothing)), serverrule(boxed(nothing), boxed(nothing), t)) \ dbgarrow globalrule(clientrule(boxed(nothing), boxed(nothing)), serverrule(boxed(operation) , boxed(nothing), t))$,))), "(Input)",
                
                prooftree(rule(rect(height: 3em, stroke: none, $globalrule(clientrule(boxed(operation) , boxed(nothing)), serverrule(boxed(nothing) , boxed(message), t)) \ dbgarrow globalrule(clientrule(boxed(operation), boxed(message)), serverrule(boxed(nothing) , boxed(nothing), t))$,))), "(Output)",

                prooftree(rule($globalrule(client, server) dbgarrow globalrule(client, server)$, $client clientarrow client'$)), "(Client)",

                prooftree(rule($globalrule(client, server) dbgarrow globalrule(client, server)$, $server serverarrow server'$)), "(Server)",


                prooftree(rule(rect(height: 2em, stroke: none, $globalrule(clientrule( boxed(nothing), boxed(nothing)), revserverrule(nothing, nothing, programcounter, executionstate, breakpoints, snapshots, t)) dbgarrow globalrule(clientrule(boxed(nothing), boxed(nothing)), revserverrule(nothing, nothing, "succ" programcounter, executionstate, breakpoints, snapshots', t'))$), $executionstate = "play"$, $t arrow.r.long t'$, $snapshots' = ( ("succ" n, t'), snapshots )$, $n in.not b$, $("succ" n) space % space interval = 0$)), "(Run1)",

                prooftree(rule(rect(height: 2em, stroke: none, $globalrule(clientrule( boxed(nothing), boxed(nothing)), revserverrule(nothing, nothing, programcounter, executionstate, breakpoints, snapshots, t)) dbgarrow globalrule(clientrule(boxed(nothing), nothing), revserverrule(nothing, nothing, "succ" programcounter, executionstate, breakpoints, snapshots, t'))$), $executionstate = "play"$, $t arrow.r.long t'$, $n in.not b$, $("succ" n) space % space interval eq.not 0$)), "(Run2)",

                prooftree(rule(rect(height: 2em, stroke: none, $globalrule(clientrule(boxed(operation), nothing), revserverrule(nothing, nothing,  programcounter, "play", breakpoints, snapshots, t)) dbgarrow globalrule(clientrule(boxed(operation), nothing), revserverrule(nothing, boxed("hit" n), programcounter, "paused", breakpoints, snapshots,t))$), $programcounter in breakpoints$)), "(BreakpointHit)",
            )
        
],
    "app:fig:stlc.intercession.global")
