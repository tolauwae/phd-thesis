#import "../../lib/class.typ": small, note
#import "../../lib/util.typ": semantics

#import "figures/semantics.typ": stlc, nat, debugger

A central concern of this dissertation is the design of debuggers, and what makes a good debugger.
To understand and answer this question, there are currently few formal foundations to build upon.
Important to any formal foundation, is the question of what constitutes correctness.
Over the course of writing this dissertation, several correctness criteria for debuggers emerged, the essence of which we distill in this chapter.
We believe our distilled criterion can serve as a general definition of correctness for debuggers.

== Semantics of debuggers

Before we can begin to reason about the correctness of debuggers, we need to establish their formal semantics.
Until recently, defining the semantics of debuggers received only minimal attention in the literature, and existing formalizations focus on very different aspects, and in very different ways.
However, recent works in the field have shown an increased interest in formalising the operations of debuggers, and a general approach seems to be emerging---where the debugger is defined in terms of the underlying language semantics.

An early attempt used PowerEpsilon @zhu91 @zhu92 to describe the source mapping used in a debugger as a denotational semantics for a toy language that can compile to a toy instruction set @zhu01.
While an interesting formalization, it does not say anything about the debugging operations themselves or their correctness.

The work by #cite(form: "prose", <li12>) focussed on automatic debuggers.
Its formalization is based on a kernel of the C language, and defines operational semantics for tracing, and for backwards searching based on those traces.
The work proofs that its trace and search operations terminate, but defines no general correctness criteria for their automatic debugging procedure.

// todo add some other approaches

In 1995, #cite(form: "prose", <bernstein95a>), are the first to define a debugger in terms of an underlying language semantic.
This approach has been used in a number of recent works @ferrari01 @torres17 @lauwaerts24 @holter24, and is the basis for the approach we take in this dissertation.

// TODO where to add?
//A more recent work presented a new type of debugger, called an abstract debugger, that uses static analysis to allow developers to explore abstract program states rather than concrete ones @holter24.
//The work defines operational semantics for their abstract debugger, and an operational semantics for a concrete debugger.
//The soundness of the abstract debugger is defined in terms this concrete debugger, where every debugging session in the concrete world is guaranteed to correspond to a session in the abstract world.
//The opposite direction cannot hold since the static analysis relies on an over-approximation, which means there can always be sessions in the abstract world which are impossible in the concrete world.
//This is in stark contrast with the soundness theorem in our work, which states that any path in the debugging semantics can be observed in the underlying language semantics.



// todo so we take the simplest language: simply typed lambda calculus



== A remote debugger for $lambda^arrow.r$

#semantics(
    [#note([The rules for $lambda^arrow.r$ shown here, in @fig:stlc and @fig:nat, are taken from the definitive work, _Types and Programming Languages_ from Benjamin C. Pierce.])#strong[Pure simply typed lambda calculus $lambda^arrow.r$.] The syntax, evaluation, and typing rules for the simply typed lambda calculus with no base types @pierce02.],
    [#stlc],
    "fig:stlc") // todo. bug: counter always starts at 1

Let us consider one of the simplest languages, the _simply typed lambda calculus_ ($lambda^arrow.r$), the rules for which are shown in @fig:stlc.

== Debugger correctness

#semantics(
    [*Remote debugger semantics $lambda^arrow.r_DD$.* The syntax and evaluation rules for a simple remote debugger for the simply typed lambda calculus $lambda^arrow.r$ with natural numbers and booleans.],
    [#debugger],
    "fig:stlc.debugger")

#lorem(256)

== Proof of correctness for the $lambda^arrow.r_DD$ debugger


== Modeling a reversible debugger $lambda^arrow.l_DD$

== Modeling a reflective debugger $lambda^arrow.r_RR$

// == Debuggers that break correctness

// todo do we need a section where we discuss debuggers which do not satisfy this criterion? + its implications / harmful effects
//
// is this not easy with a reversible debugger?

#lorem(512)

