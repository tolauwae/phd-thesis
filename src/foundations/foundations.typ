#import "../../lib/class.typ": small, note, theorem, proof, example, lemma
#import "../../lib/util.typ": semantics
#import "../../lib/fonts.typ": sans

#import "figures/semantics.typ": *

A central concern of this dissertation is the design of debuggers, and what makes a good debugger.
To understand and answer this question, there are currently few formal foundations to build upon.
Important to any formal foundation, is the question of what constitutes correctness.
Over the course of writing this dissertation, several correctness criteria for debuggers emerged, the essence of which we distill in this chapter into a general definition of correctness for debuggers.

== Semantics of debuggers

Before we can begin to reason about the correctness of debuggers, we need to establish their formal semantics.
Unfortunately, defining the semantics of debuggers has always received less attention than formalizations for programming languages or compilers @da-silva92:correctness.
This lack of interest, has resulted in a very sparse collection of existing semantics, which focus on very different aspects, and are defined in very different ways.
To this day, there is no clear consensus on what constitutes correctness for debuggers, or even, which are the essential aspects for a tool to fall under the broad category of debuggers.

When examining recent works in debuggers, there does appear to be an emerging consensus on how to define the semantics of debuggers, where the operations of the debugger are defined in terms of an underlying language semantics.

=== A brief history of formal debuggers

To our knowledge, the earliest attempt at formally defining a debugger-like system is by #cite(form: "prose", <bahlke86:psg>). // todo ...
The paper presents the _Programming System Generator_, which is an early programming tool that generates an interpreter from the denotational semantics of a programming language.
It supports interactive evaluation and the ability to inspect or redefine code on the fly, which is somewhat debugger-like in spirit.

// possibly: 
// + Ehud Y Shapiro Algorithmic Program Debugging ACM Distinguished Dissertations The MIT Press
// + A P Tolmach and A W Appel Debugging Standard ML without reverse engineering

However, the earliest work we are aware of, that formally describes a tool we would today recognize as a debugger, is the PhD thesis by #cite(form: "prose", <da-silva92:correctness>).

Another early attempt used PowerEpsilon @zhu91:higher-order @zhu92:program to describe the source mapping used in a debugger as a denotational semantics for a toy language that can compile to a toy instruction set @zhu01:formal.
While an interesting formalization, it does not say anything about the debugging operations themselves or their correctness.

// todo should cite zhu01:formal too no?

The work by #cite(form: "prose", <li12:formal>) focussed on automatic debuggers.
Its formalization is based on a kernel of the C language, and defines operational semantics for tracing, and for backwards searching based on those traces.
The work proofs that its trace and search operations terminate, but defines no general correctness criteria.

// todo add some other approaches

// todo fabio q b da silva: Correctness Proofs of Compilers and Debuggers: an Overview of an Approach Based on Structural Operational Semantics
//
// -> is really trying to do what we do in this chapter too, but for automatic debuggers
// BUT we are focussing on manual/interactive debuggers

// todo go through papers of the big names: robert hirshfeld and andreas zeller

// todo berstein is probably not the first -- also look at bernstein95:formally
In 1995, #cite(form: "prose", <bernstein95:operational>), are the first to define a debugger in terms of an underlying language semantic.
By defining the semantics of a debugger in terms of the underlying language, it becomes much easier to reason about the correctness of the debugger, since the correctness can now be stated in terms of the underlying language.
In hindsight, this may seem an obvious solution to the reader, but that speaks to the fact that this is by far the best and most intuitive approach to take.

The approach has been used in a number of recent works @ferrari01:debugging @torres17:principled @lauwaerts24:warduino @holter24:abstract, and is the basis for the approach we take in this dissertation.

// TODO where to add?
//A more recent work presented a new type of debugger, called an abstract debugger, that uses static analysis to allow developers to explore abstract program states rather than concrete ones @holter24:abstract.
//The work defines operational semantics for their abstract debugger, and an operational semantics for a concrete debugger.
//The soundness of the abstract debugger is defined in terms this concrete debugger, where every debug session in the concrete world is guaranteed to correspond to a session in the abstract world.
//The opposite direction cannot hold since the static analysis relies on an over-approximation, which means there can always be sessions in the abstract world which are impossible in the concrete world.
//This is in stark contrast with the soundness theorem in our work, which states that any path in the debugging semantics can be observed in the underlying language semantics.


While there are still large differences in the way debuggers are formalised in recent works, it is clear that defining their semantics in terms of the underlying language is now accepted as the canonical approach.
An approach we will therefore use throughout this dissertation.

=== Four debuggers, four semantics

Given the wide variety of debuggers, we will present our formal framework---for debugger semantics and their correctness---by discussing four different debuggers with each their own semantics.
Yet, the semantics will follow the same general design---presenting the overall formal framework we use in this dissertation.

#let remotedbg = $lambda^ast.basic_DD$
#let conventionaldbg = $lambda^arrow.r_DD$
#let reversibledbg = $lambda^arrow.l_DD$
#let intercessiondbg = $lambda^arrow.zigzag_DD$

Looking slightly ahead, we will define the following four debuggers, which always build on top of the previous one:
#{
set text(size: small) //, font: sans)
show table.cell.where(y: 0): set text(weight: "bold") //, font: sans)

align(center, table(columns: (auto, 60mm), align: (x, y) => if x == 0 {horizon + center} else {horizon + left}, stroke: none, fill: (x, y) => if calc.odd(y) { silver },
  table.header("Debugger", "Description"),
  remotedbg, "A tiny remote debugger, presenting a smallest working example.",
  conventionaldbg, "A remote debugger with support for the most conventional debug operations.",
  reversibledbg, "A reversible debugger, which can step backwards in time.",
  intercessiondbg, "An intercession debugger, which can change the program at runtime."
))
}

#note[While heavy in formal aspects, this chapter serves as a gentle introduction into the formal foundations of this dissertation.]
The four debuggers allow us to introduce different aspects of our formal framework step by step.
The semantics in this chapter, are blueprints for the more complex semantics we discuss later in this dissertation.
They also serve to illustrate the general correctness criteria we define for debuggers.

#let stlc = $lambda^arrow.r$
In order to present our formal framework, we need a simple yet illustrative language.
Fortunately there is a straightforward choice, the _simply typed lambda calculus_ (#stlc), proposed by #cite(form: "prose", <church40:formulation>).
Most readers will be familiar with the simply typed lambda calculus, but for those who are not, we provide a brief introduction.

#let oparrow = box(height: 0.4em, $attach(arrow.r.long, t: operation)$)

== #stlc as the running example

#semantics(
    [#note([The rules for #stlc, in both @fig:stlc and @app:stlc, are taken from the definitive work, _Types and Programming Languages_ from Benjamin C. Pierce.])#strong[Pure simply typed lambda calculus #stlc.] The syntax, evaluation, and typing rules for the simply typed lambda calculus with no base types @pierce02:types.],
    [#rules-stlc],
    "fig:stlc") // todo. bug: counter always starts at 1

The simply typed lambda calculus, is arguably the simplest, and most well-known formal system used to study computation and programming languages.
For fullness, we provide the core rules for the simply typed lambda calculus without any base types in @fig:stlc.
In the lambda calculus, functions are the central form of computation, and there are only two basic operations; function application, and function abstraction.
Function application is used to apply a function to another, while abstraction binds free variables to the function.
// todo say something about abstraction being a value
In the simply typed version, each expression is assigned a type, and functions are given types that describe the kinds of inputs they accept and outputs they produce.

== #remotedbg: A tiny remote debugger for #stlc

We start by defining the syntax of a tiny remote debugger for #stlc with booleans and natural numbers, defined as peano numbers @peano91:sul @kennedy74:peanos.
The complete set of syntax, evaluation, and typing rules for booleans and natural numbers for #stlc can be found in @app:stlc.
Because the debuggers we discuss in this dissertation are each debuggers for distributed systems, and therefore remote debuggers of a kind, we start with a simple remote debugger.
However, the easiest way to define such a debugger is to start from a local debugger, and simply add a messaging system on top of it.//---which is the way in which we will present the debugger in this section.

#semantics(
    [*Remote debugger semantics #remotedbg.* The syntax and evaluation rules for a simple remote debugger ($dbgarrow$) for the simply typed lambda calculus #stlc with natural numbers and booleans, defined over the internal operations (#oparrow).],
    [#debugger],
    "fig:stlc.debugger")

The rules for our tiny remote debugger are shown in @fig:stlc.debugger#sym.dash.em#[these] rules define the operation of the debugger backend.
Typically, a debugger will also have a frontend for users to interact with the debugger, but this is beyond the scope of the semantics.
The rules therefore only model the interface between the backend and the frontend as a simple messaging system.

The evaluation rules in @fig:stlc.debugger are split into two sets, the internal debugging steps (#oparrow) with #operation the debugging operation, and the remote debugging steps ($dbgarrow$), which wraps the former steps.
The rules specific to the remote debugger are highlighted in the figure, without them, the remaining rules define a tiny local debugger.

=== The syntax rules of the #remotedbg debugger

#note[Internal in this context refers to the place where the program is running.]
The steps of the remote debugger #dbgarrow are defined over a configuration $boxed(operation) bar.v t bar.v boxed(message)$, where we have respectively, the state of the remote debugger, the current program state, and the state of the internal debugger.

The configuration of the internal debugger is split into two parts, (1) the current state of the program---in this case a #stlc term $t$---and (2) the output displayed by the debugger frontend, modeled as the message box $boxed(message)$.
Messages boxes are our way of modeling both inter-process and intra-process communication.
In the case of the internal debugger, the message box is used to model the inter-process communication between the debugger backend and the debugger frontend within the same debugger process.
Therefore, we can think of $boxed(message)$ as a high-level abstraction of the debugger frontend.

The configuration of the remote debugger is similar, but the message box $boxed(message)$ now models the intra-process communication from backend to frontend, and a second message box $boxed(operation)$ models the intra-process communication from frontend to backend.
This corresponds, respectively, to the output returned from the debugger, and the instructions send to it.

The debugger can return as output, either nothing, a term, or an acknowledgement of a debug command.
The debug commands supported by the debugger are _step_ and _inspect_---to take a simple step in the program, and to inspect the current state of the program.
Sometimes we also need the internal steps (#oparrow) to perform an internal step, which does not correspond to a debug command visible to the user.
For such cases, we also provide a nothing command ($nothing$).

=== The evaluation rules of the #remotedbg debugger

The entire evaluation of the debugger ($delta dbgarrow delta'$) is captured by only four rules.
The first three steps are internal steps, which describe the operation of the internal debugger.

/ E-Step: When the current term $t$ can reduce to $t'$, than the debugger can take a step to $t'$, and output an acknowledgement of the successful step.

/ E-Fallback: This fallback rule allows the debugger to drop _step_ messages in case there is no $t arrow.r.long t'$. For the #stlc, this means that the term must be a value $v$. In this case, we output an acknowledgement of $nothing$, to indicate that the command was processed, but did not have any effects.

/ E-Inspect: The inspect step outputs the current term $t$.

/ E-Read: The previous two steps require the output to be empty, to clear the output we introduce the _E-Read_ rule.

To lift these internal steps to describe the operation of a remote debugger, we only need to add one rule which takes the next debug command from the input message box, and takes the correct corresponding internal step.

/ E-Remote: The remote debugger takes the next debug command $operation$ from the input message box, and performs the corresponding internal step (#oparrow).

The evaluation of the remote debugger is informed by the commands that arrive in the input message box, a debug session can therefore be seen as a series of remote steps ($delta multi(dbgarrow) delta'$) that are the result of a sequence of debug commands, which we write as ($multi(operation)$).

Now that we have the formal semantics for a remote debugger that can step through and inspect a #stlc program, we can define what correctness means for such a debugger.

=== Correctness criteria for the #remotedbg debugger

// todo motivate/argue for this as our correctness theorem more
Since we define our debugger in terms of the underlying language, the most intuitive definition of correctness for a debugger is that it should not change the semantics of the program being debugged.
An intuition shared by the earliest works on debugger correctness such as #cite(form: "prose", <da-silva92:correctness>).
We develop the idea into two correctness criteria, _debugger soundness_ and _debugger completeness_.

Debugger soundness demands that for any debug session that begins at the start of the program, there is a path in the underlying language semantics that leads to the same final program state.
In the theorem, we use the shorthand notation $t_delta$ to denote the current term of a debugging configuration $delta$.

#theorem("Debugger soundness")[
  Let $delta_"start"$ be the initial configuration of the debugger for some program $t$. Then:
  $ forall space delta space . space ( delta_"start" multi(dbgarrow) delta ) arrow.r.double.long ( t multi(arrow.r.long) t_delta ) $
]
#proof[
  The proof proceeds by induction on the number of steps taken in the debugger.
  Since _E-Step_ is the only rule that changes the term $t$ in the debugger configuration, and _E-Step_ uses the internal step ($arrow.r.long$); there is necessarily a path $t multi(arrow.r.long) t_delta$ in the underlying language semantics.
]

Debugger completeness is the dual of soundness, but in the opposite direction.
Completeness demands that any path in the underlying semantics can be observed in the debugger.

#theorem("Debugger completeness")[
  Let $t$ be a #stlc program, and $delta_"start"$ the start configuration of a debug session for this program. Then:
  $ forall space t' space . space ( t multi(arrow.r.long) t' ) arrow.r.double.long exists space delta space . space (delta = boxed(operation) bar.v t' bar.v boxed(m)) and ( delta_"start" multi(dbgarrow) delta ) $
]
#proof[
  Given any path $t multi(arrow.r.long) t'$ in #stlc, we can construct a sequence of debug commands $multi(operation)$ to be the exact number of _step_ commands corresponding to the path in #stlc. Then the debug session starting in $delta_"start"$ with the commands $multi(operation)$ will take the exact same path by construction (see rule _E-Remote_ and _E-Step_), resulting in a configuration ($boxed(nothing) bar.v t' bar.v boxed(nothing)$).
]

Debugger soundness and completeness together ensure that the debugger does not deviate from the semantics of the program being debugged, and that the debugger and the normal execution observe the same program behaviour.
This is the most essential property for any type of debugger.

Both theorems are trivial to prove for our tiny remote debugger #remotedbg, however, this by no means implies that they are trivial to prove for every debugger, or that they have no value.
To illustrate the usefulness of the correctness criteria, //and show they are by no means trivial to prove for every debugger, 
we will discuss them for a few interesting debuggers built on our tiny remote semantic.

//#note[In fact, we only noticed when going over the progress proof, that the _E-Fallback_ rule was missing in the first version of #remotedbg.]Aside from these specific correctness criteria for debuggers, it is often a good idea to also proof the typical _progress_ and _preservation_ properties @pierce02:types for the debugger semantics.
//Especially progress, generally serves as an important sanity check that the debugger is well-defined, and that there are no missing rules.
//We provide the proofs for progress and preservation for our tiny remote debugger, and all other debuggers that follow in this chapter, in @app:progress.

== #conventionaldbg: A conventional debugger for #stlc<sec:conventional>

The tiny remote debugger $remotedbg$ is perhaps to simple to be really considered---what we conventionally call---a live remote debugger.
The most obvious missing pieces are #pause and #play commands, and support for _breakpoints_.
The semantics so far consider the program to be paused at all times, and the debugger only moves forward when the user issues a _step_ command.

#semantics(
    [*Syntax rules of the conventional live debugger #conventionaldbg.* The syntax rules for #pause, #play, and _breakpoints_ for the #remotedbg debugger semantics. Changes to existing rules are highlighted.],
    [#conventionalsyntax],
    "fig:stlc.conventional.syntax")

To support the pausing of the program's evaluation, as well as breakpoints, we extend the syntax of the tiny remote debugger with the rules shown in @fig:stlc.conventional.syntax.
The internal debugger configuration is extended with a _program counter_, a plain numerical value as defined by the syntax of #stlc, an _execution state_ that can either be _paused_ or _play_, and a set of _breakpoints_.

#semantics(
    [*Evaluation of conventional live debugger operations for #conventionaldbg.* The evaluation rules for #pause, #play, and _breakpoints_ for the #remotedbg debugger semantics. Changes to existing rules are highlighted.],
    [#conventionalevaluation],
    "fig:stlc.conventional.evaluation")

Using these three new fields $(n, e, b)$, we can define the new evaluation rules for the conventional debugger.
@fig:stlc.conventional.evaluation shows the new evaluation rules added to or replacing the existing rules. The full set of rules for the conventional debugger are shown in @app:debuggers.

Now, we can easily let the debugger stop at any point in the reduction of the #stlc program by adding a rule for normal unpaused execution (_E-Run_) and by adding two rules to change the execution state to either _paused_ or _play_.
For breakpoint support we need to keep track of a program counter, which for the #stlc can simply be a numerical value that counts the number of reductions.
To increase the counter correctly, we only need to change the _E-Step_ and _E-Run_ rules to increment the counter by one for every reduction in the #stlc.
Lastly, we need to add two new rules to add and remove breakpoints from the set of breakpoints in the debugger configuration, and an extra fallback rule to handle the case where the debugger is not paused, but a step command is received.

All other rules from the tiny remote debugger remain unchanged, apart from the additional fields in the configuration.
The exact values of these fields are immaterial for those remaining rules.

/ E-Step: The _E-Step_ rule now only applies when the debugger is in the paused state.

/ E-Fallback2: We add a second fallback rule, for when a step command is received, but the debugger is not paused. The execution state is irrelevant in the other fallback rule.

/ E-Pause: The _E-Pause_ rule changes the execution state to _paused_.

/ E-Play: The _E-Play_ rule changes the execution state to _play_.

/ E-BreakpointAdd: The _E-BreakpointAdd_ rule adds the breakpoint $n$ from the $("bp"^+ space n)$ command to the set of breakpoints in the debugger configuration.

/ E-BreakpointRemove: The _E-BreakpointRemove_ rule removes the breakpoint $n$---specified by the $("bp"^- space n)$ command---from the set of breakpoints in the debugger configuration.

/ E-Run: When the execution state is _play_, and there are currently no commands in the message box of the remote debugger, nor is the current program counter $n$ an element of the breakpoints set $b$, then the debugger will take a single step in the underlying language semantics $t arrow.r.long t'$. Through this rule the debugger will continue normal execution until it reaches a breakpoint, or the program is paused, or the program is cannot be reduced anymore.

/ E-BreakpointHit: When the execution state is _play_, and the program counter $n$ is part of the breakpoint set $b$, the debugger pauses the program by changing the execution state to _paused_. Finally, it outputs an alert of the breakpoint hit containing the current program counter.

=== Correctness criteria for the #conventionaldbg debugger

We will apply the same _soundness_ and _completeness_ criteria to the conventional debugger as we did for the tiny remote debugger. We briefly sketch the proofs here, starting with soundness.

#proof("Debugger soundness for the conventional debugger")[
  The proof proceeds by induction on the number of steps taken in the debugger.
  The _E-Step_ and _E-Run_ rules are the only rule that changes the term _t_ in the debugger configuration, and both use the internal step ($arrow.r.long$). This means that there is necessarily a path $t multi(arrow.r.long) t_delta$.
]

The proof for completeness is identical to the proof given for the tiny remote debugger, since we do not need to introduce any breakpoints in the debugging session. The rules _E-Remote_ and _E-Step_ can still faithfully re-execute the path $t multi(arrow.r.long) t'$.

== #reversibledbg: A reversible debugger for #stlc

Another interesting extension to the tiny remote debugger, is to turn it into a reversible debugger @engblom12:review.
We start from the conventional debugger semantics in @sec:conventional, and add a _backwards step_ command.

#semantics(
    [*Syntax and evaluation rules of the reversible debugger #reversibledbg.* The semantics of #reversibledbg extend the conventional debugger semantics #conventionaldbg, shown in @fig:stlc.conventional.syntax and @fig:stlc.conventional.evaluation.],
    [#reversible],
    "fig:stlc.reversible")

A common approach to implementing a reversible debugger is to periodically store snapshots of the program state, and reconstruct the execution from the last snapshot @engblom12:review @klimushenkova17:improving.
Formalising this approach requires only few extensions to the semantics of the conventional debugger.
We list the new syntax and evaluation rules for the reversible debugger in @fig:stlc.reversible.
// go back to start and rerun -> we need to keep track of the number of steps

We extend the syntax of the debugger with a list of snapshots, which are tuples of program counters and terms.
The commands are extended with a _backwards step_ command, which takes a single step backwards in the program.
To handle this command we need five internal rules, specifically, the _E-BackwardStep0_, _E-BackwardStep2_, and _E-BackwardStep2_ rules, along with two fallback rules.

/ E-BackwardStep0: The _E-BackwardStep0_ rule applies when the program counter is not zero, but only the start snapshot is present in the snapshot list. In this case the program reduces $n$ times starting from the initial configuration, to arrive exactly one reductions before the current term $t$.

/ E-BackwardStep1: The _E-BackwardStep1_ rule applies reduces the program counter by one, and reduces the term $t'$ from the last snapshot exactly $n-n'$ times, to the term $t''$.

/ E-BackwardStep2: The _E-BackwardStep2_ rule applies when the program counter is exactly one higher than the program counter of the last snapshot. In this case, the debugger only restores the snapshot and removes it from the snapshot list.

/ E-BackwardFallback1: The _E-BackwardFallback1_ rule applies when the execution state is not paused. Analogous to the forward step, the debugger will not step back if the program is not paused, and simply send an empty acknowledgement to indicate that nothing has changed.

/ E-BackwardFallback2: The _E-BackwardFallback2_ rule applies when the program counter is zero, in this case, the only sensible option is to also return an empty acknowledgement, since the program cannot step back any further.

Given these internal evaluation rules, we only need to specify in the global evaluation rules how and when snapshots are created.
Several strategies can be used to determine when to create new snapshots, for simplicity we will let the debugger create a snapshot every few steps by replacing the _E-Run_ rule by the following two rules.

/ E-Run1: We change the _E-Run_ rule to add a new snapshot to the list #snapshots whenever the program counter is a multiple of #interval, which we consider a static configuration of the debugger#note[The value of #interval could be changed through some meta-rules for the debugger.].

/ E-Run2: In case the program counter is not a multiple of #interval, the _E-Run2_ rule is the same as the original _E-Run_ rule.

To summarize the reversible semantics, when the reversible debugger is at a term $t$ with program counter $"succ" n$, then to step back once, it will restore the last snapshot and take exactly $n-n'$ steps where $n'$ is the program counter of the snapshot.

=== Correctness criteria for the #reversibledbg debugger

Again, we apply the same soundness and completeness criteria to the reversible debugger as we did for the two previous debuggers.
The proofs however, are slightly more involved, since we need to reason about the snapshots.
To make this easier, we will first proof two lemma about the snapshots that are helpful in the proofs of soundness and completeness.

#lemma("Snapshot preservation")[
  The semantics of a reconstructing reversible debugger is said to be _snapshot preserving_ if the following holds:
  $ forall delta space . space delta = boxed(operation) bar.v t bar.v programcounter, executionstate, breakpoints, snapshots, boxed(message) and delta_"start" multi(dbgarrow) delta \
   arrow.double.r.long \
   forall (programcounter', t') in s space . space programcounter' lt.eq.slant programcounter and t_"start" multi(arrow.r.long) t' $
]<snapshotpreservation>
#proof([Snapshot preservation for #reversibledbg])[
  The proof is straightforward by induction on steps taken in the debug session ($multi(dbgarrow)$).
  //For each case, we need to prove that all snapshots in the last debug configuration contain a program counter lower or equal to the current program counter, and that the term in the snapshot is reachable from the start term in zero or more steps.
  In the base case, this is always trivial to prove by construction.
  //The important cases, is the new _E-Run1_ which is the only rule that adds a new snapshot to the list. This is trivial by construction.
  //
  In the inductive case, each case is straightforward to prove given the induction hypothesis.
]

Given @snapshotpreservation, we know that any snapshot list produced by the reversible debugger observes the program order, and that there is never a snapshot that lies in the _future_ of the current program state.

#proof([Debugger soundness for #reversibledbg])[
  The proof proceeds by induction over the steps taken in the debug session. Except for the new backward stepping rules, the cases proceed analogous to the proof for #conventionaldbg.
  Given the induction hypothesis and @snapshotpreservation, the backward rules _E-BackwardStep0_, _E-BackwardStep1_, and _E-BackwardStep2_ are straightforward to prove.
]

== #intercessiondbg: An intercession debugger for #stlc

Our debuggers so far have only observed the execution of a program, without interceding in it.
Even our reversible debugger, does not intercede in the control flow of the program, it only replays a previously observed execution.
//However, many debuggers support some form of _reflection_ @maes87:concepts @papoulias13:remote, where they change the program's execution.
Yet, it is quite common for debuggers to support changing the value of variables @stallman88:debugging, or influence the control flow of the program @lauwaerts22:event-based-out-of-place-debugging @stallman88:debugging @alter.

Intercession debuggers are an interesting case to study in terms of our correctness criteria.
Since, we expect the debugger to observe the same semantics as the program, we need to be careful when changing the program state.
It is very easy when changing even just a simple variable to break debugger correctness.
Luckily, we can illustrate this in the #stlc by allowing the debugger to substitute terms at runtime.

#semantics(
    [*Intercession debugger semantics extending #remotedbg.*],
    [#intercession],
    "fig:stlc.intercession")

#note[The substitution debug command is similar to substitutions through let bindings in #stlc @pierce02:types.]@fig:stlc.intercession shows our intercession debugger semantics, as again an extension on the previous debugger semantics---shown in @fig:stlc.reversible.
We add a new debug command #subst to the debugger, which allows the user to substitute the current term $t_1$ with a new term $t_2$ of the same type.

=== Intercession breaks straightforward correctness //criteria for the #remotedbg debugger

Unfortunately, the intercession debugger is not sound by the definition of the previous debuggers.
The previous soundness criteria are defined in terms of the entire debugging sessions, starting from the beginning of the program.
This criterion can never be satisfied for all debugging session of an intercession debugger that can arbitrarily update the program code.
We can illustrate this by the following example (@example), where we use the _substitution_ command to change the program at runtime.

#figure(placement: none, [#example([
  The following shows a sequence of steps in the intercession debugger. Intercession commands are shown in bold. // Steps taken in the underlying semantics are shown in black, while debugger steps are shown in an italic red font.

  #set text(size: small)
  #let debug(content) = {
    set text(weight: "bold")
    math.bold(content)
  }
  #align(center, prooftree(vertical-spacing: 0.55em,
    rule(label: "E-isZero", "true : Bool", 
//      rule( $"isZero" 0 : "Bool"$,
        rule(label: "E-AppAbs", $[x arrow.r.bar 0] "isZero" x : "Bool"$,
//          rule($(lambda x : "Nat" . "isZero" x) space 0 : "Bool"$,
            rule(label: debug("E-Subst"), debug($["succ" 0 arrow.r.bar 0] space (lambda x : "Nat" . "isZero" x) space "succ" 0 : "Bool"$),
//              rule($(lambda x : "Nat" . "isZero" x) space "succ" 0 : "Bool"$,
                rule(label: "E-AppAbs", $(lambda x : "Nat" . "isZero" x) space ([y arrow.r.bar 0] space ("succ" y)) : "Bool"$,
                  $(lambda x : "Nat" . "isZero" x) space (lambda y : "Nat" . "succ" y) space 0 : "Bool"$))))))
//  )))

])<example>])

In @example, the debugger changes all occurrences of _succ 0_ in the program to simply _0_ in the middle of the debugging session.
Through this intervention, the program results in true, while the original code can clearly only be false.
To our correctness criteria, this means we designed an incorrect debugger.
However, there are many reasons for designing a debugger that can update the program during a debugging session, allowing developers to patch code as they debug it.
Moreover, there is nothing in the function of the debugger that would lead us to believe---on the face of it---that the debugger is incorrect.
After all, the new program is still well typed, and the debugger observes the correct behaviour of the updated program.
Therefore the problem is not that our debugger is incorrect, but that the correctness criteria are too strict.

The solution here is rather intuitive---we consider the point where a program is updated by the debugger, as the start of a new debugger session.
We explore this idea in the following section, where we redefine debugger soundness and completeness for intercession debuggers.

=== Updating the correctness criteria for intercession debuggers

Informally, the correctness of debuggers depends on their faithful observation of a program's behaviour.
Intercession debuggers are a common type of debugger that shows this criteria is far from trivial.
There are two major ways in which debuggers typically intercede with a program's execution, and correspondingly, two general principles those intercessions must follow.

Firstly, intercession debuggers that change the behaviour of a program---often my changing control flow or throwing exceptions #cite(<alter>)---in order to be correct, may only introduce behaviour that could be observed in the underlying semantics.
Secondly, as a general rule for intercession debuggers that change the program itself, the debugger must faithfully observe the new program from the moment the code was updated, and the updated program must remain well-typed.
Our previous correctness criteria already cover the former rule, but the criteria are too strict for the latter class of intercession debuggers.
We will adapt the soundness and completeness theorems to fit our second principle for debuggers that can change a program.

Until now, the debugger soundness theorem mirrored the _progress_ theorem for programming languages @pierce02:types, however, since we now introduce program updates, we also need to think about _preservation_ @pierce02:types.
For the debugger, this means that any changes to the program code must keep the program well-typed.

#lemma("Debugger preservation")[
  A debugger semantic is said to be _preserving_ if the following holds:
  $ forall delta, delta' . delta #dbgarrow delta' and t in delta "is well-typed" arrow.double.r.long t' in delta' "is well-typed" $
]<preserving>

#let substarrow = box(height: 0.4em, $attach(arrow.r.long, t: subst)$)

#proof([Preservation for #intercessiondbg])[
  The proof proceeds by case analysis on the rules of the debugger.
  Only the #substarrow rule is interesting, since it is the only rule that changes the program code. However, since the rule replaces $t_1$ in the well-typed program $t$ with a term of the same type $t_2$, the case is also trivially true.
]

As reader may have noticed, this lemma is very general and can be applied the previously defined debugger semantics as well---and probably most other semantics for that matter.
However, since the previous semantics in this chapter do not change the program code, they are trivially preserving.
That said, for other intercession debuggers the preservation property is a crucial criterion for correctness.

Now we define debugger soundness, as the preservation of the program's well-typedness, and the existence of a path in the underlying language semantics starting from an arbitrary configuration $delta$---rather than the starting configuration.

#theorem("Debugger soundness")[
  A debugger semantic is said to be _sound_ if it is _preserving_ and the following holds:
  $ forall delta, delta' . delta attach(dbgarrow, tr:*) delta' and subst in.not ( attach(dbgarrow, tr:*) ) and t "is well-typed" arrow.double.r.long t attach(arrow.r.long, tr:*) t' , $ where $t in delta$ and $t' in delta'$ and $delta_"start" multi(dbgarrow) delta'$.
]
#proof[
  By @preserving, we know that #intercessiondbg is _preserving_, so we only need to prove the second part of the theorem.
  The proof proceeds by induction on the steps in the debug session ($delta multi(dbgarrow) delta'$). Since we know that there are no substitution commands in the debug session, we can ignore the _E-Subst_ rule, and the proof is analogous to the previous proofs.
  Only in the base case, do we not have $delta_"start"$ but an arbitrary configuration $delta$. Since it is reachable from the start configuration and it's term is well typed, this makes little difference to the proof.
]

Unlike soundness, debugger completeness is not broken because of intercession.
After all, there is no reason that any intercession commands should take place during the debugging session we construct in the proof.
Therefore---analogous to the previous extensions to the semantics---the addition of the _E-Subst_ rule makes no difference, and the same proof for completeness holds.

== Discussion: general debugger correctness

//As this chapter shows,
Given the wide variety of debuggers and the vagueness around what constitutes as a debugger, it is not possible to formally define a general correctness criterion that is the same for all types of debuggers.
Therefore, it should not surprise anyone that the correctness criteria presented in this chapter depend on, and are different for, each of the debugger semantics.
Especially, the criteria for the intercession debugger depend in a crucial way on the type of intercession the debugger supports.
//This becomes even more unavoidable given that we define the debugger semantics in terms of the underlying semantics.

However, the _soundness_ and _completeness_ criteria presented in this chapter do present the same general principle, which is that the debugger should observe the same semantics as the program being debugged.
In the case of the intercession debuggers these criteria need to be adapted on a case by case basis, depending on the type of intercessions supported, but their general principles still hold.

The extensive discussion of the different debugger semantics for the #stlc in this chapter serve to show the general applicability of debugger soundness and completeness, and support our claim that these are the most essential correctness properties for any type of debugger.
The same criteria will be used throughout this dissertation, as we explore how to develop sound out-of-place and multiverse debugging techniques for constrained environments. //, we will test our models with the correctness criteria presented in this chapter.
These debuggers bridge a wide spectrum of debugger types, and intercede in the program's execution in intricate ways.
They present semantics that are much more complex than the simple semantics we presented in this chapter.
This will illustrate further that the correctness criteria presented in this chapter are indeed useful properties for any type of debugger.

Furthermore, the spirit of the debugger semantics in this chapter closely aligns to the design of the debuggers we will present. // in the following chapters.
For instance, our multiverse debugger presented in @chap:multiverse contains similar semantics to our reversible debugger for exploring the possible execution paths of non-deterministic programs.
The rest of this dissertation will also mirror the structure of this chapter, by first presenting a remote debugger for WebAssembly on microcontrollers, and then extending it with more advanced features in the following chapters.
// == Debuggers that break correctness

// todo do we need a section where we discuss debuggers which do not satisfy this criterion? + its implications / harmful effects
//
// is this not easy with a reversible debugger?

//== Conclusion

//The formal framework for debuggers presented in this chapter, is the basis for the formalisations at the heart of this dissertation.

//The rest of this dissertation is build on the correctness criteria for debuggers presented in this chapter.
//The dissertation itself will also follow the structure of this chapter, by first presenting a simple remote debugger, and then extending it with more advanced features in the following chapters.
//
//The remote debugger presented in the next chapter is designed to debug microcontrollers, and is built on top of the WebAssembly language.
//The reasons for exploring the foundations for debuggers on microcontrollers, are twofold.
//First, debugging technology is still lacking behind in the embedded world, where developers are still to a large extend using print statement debugging, or simple remote debuggers that require dedicated hardware.
//Second, 
//We already touched on the motivation for the WebAssembly language in the introduction, but this become even clearer in the next chapter.

