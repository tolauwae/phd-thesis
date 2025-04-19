#import "../../lib/class.typ": small, note, theorem, proof
#import "../../lib/util.typ": semantics

#import "figures/semantics.typ": rules-stlc, nat, debugger, operation, boxed, dbgarrow, multi

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

// todo should cite zhu01:formal too no?

Another early attempt used PowerEpsilon @zhu91:higher-order @zhu92:program to describe the source mapping used in a debugger as a denotational semantics for a toy language that can compile to a toy instruction set @zhu01:denotational.
While an interesting formalization, it does not say anything about the debugging operations themselves or their correctness.

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
//A more recent work presented a new type of debugger, called an abstract debugger, that uses static analysis to allow developers to explore abstract program states rather than concrete ones @holter24.
//The work defines operational semantics for their abstract debugger, and an operational semantics for a concrete debugger.
//The soundness of the abstract debugger is defined in terms this concrete debugger, where every debug session in the concrete world is guaranteed to correspond to a session in the abstract world.
//The opposite direction cannot hold since the static analysis relies on an over-approximation, which means there can always be sessions in the abstract world which are impossible in the concrete world.
//This is in stark contrast with the soundness theorem in our work, which states that any path in the debugging semantics can be observed in the underlying language semantics.



While there are still large differences in the way debuggers are formalised in recent works, it is clear that defining their semantics in terms of the underlying language is now accepted as the canonical approach.
An approach we will therefore use throughout this dissertation.

// todo so we take the simplest language: simply typed lambda calculus

#let stlc = $lambda^arrow.r$
#let remotedbg = $lambda^arrow.r_DD$
#let oparrow = box(height: 0.4em, $attach(arrow.r.long, t: operation)$)

== #stlc as the running example

#semantics(
    [#note([The rules for #stlc, in both @fig:stlc and @app:stlc, are taken from the definitive work, _Types and Programming Languages_ from Benjamin C. Pierce.])#strong[Pure simply typed lambda calculus #stlc.] The syntax, evaluation, and typing rules for the simply typed lambda calculus with no base types @pierce02.],
    [#rules-stlc],
    "fig:stlc") // todo. bug: counter always starts at 1

In order to present our generalized correctness theorem, we need a simple yet illustrative language.
Fortunately there is a straightforward choice, the _simply typed lambda calculus_ (#stlc), proposed by #cite(form: "prose", <church40>).
Most readers will be familiar with the simply typed lambda calculus, but for those who are not, we provide a brief introduction.

The simply typed lambda calculus, is arguably the simplest, and most well-known formal system used to study computation and programming languages.
For fullness, we provide the core rules for the simply typed lambda calculus without any base types in @fig:stlc.
In the lambda calculus, functions are the central form of computation, and there are only two basic operations; function application, and function abstraction.
Function application is used to apply a function to another, while abstraction binds free variables to the function.
// todo say something about abstraction being a value
In the simply typed version, each expression is assigned a type, and functions are given types that describe the kinds of inputs they accept and outputs they produce.

== A remote debugger for #stlc

We start by defining the syntax of a tiny remote debugger for #stlc with booleans and natural numbers, defined as peano numbers @peano91 @kennedy74.
The complete set of syntax, evaluation, and typing rules for booleans and natural numbers for #stlc can be found in @app:stlc.
We start with a simple remote debugger, because the debuggers we discuss in this dissertation are each debuggers for distributed systems, and therefore remote debuggers of a kind.
However, the easiest way to define such a debugger is to start from a local debugger, and simply add a messaging system on top of it.//---which is the way in which we will present the debugger in this section.

#semantics(
    [*Remote debugger semantics #remotedbg.* The syntax and evaluation rules for a simple remote debugger ($dbgarrow$) for the simply typed lambda calculus #stlc with natural numbers and booleans, defined over the local operations (#oparrow).],
    [#debugger],
    "fig:stlc.debugger")

The rules for our tiny remote debugger are shown in @fig:stlc.debugger#sym.dash.em#[these] rules define the operation of the debugger backend.
Typically, a debugger will also have a frontend for users to interact with the debugger, but this is beyond the scope of the semantics.
The rules therefore only model the interface between the backend and the frontend as a simple messaging system.

The evaluation rules in @fig:stlc.debugger are split into two sets, the local debugging steps (#oparrow) with $o$ the debugging operation, and the remote debugging steps ($dbgarrow$), which wraps the former steps.
The rules specific to the remote debugger are highlighted in the figure, without them, the remaining rules define a tiny local debugger.

=== The syntax rules of the #remotedbg debugger

The configuration of the local debugger is split into two parts, (1) the current state of the program---in this case a #stlc term $t$---and (2) the output displayed by the debugger frontend, modeled as the message box $boxed(m)$.
Messages boxes are our way of modeling both inter-process and intra-process communication.
In the case of the local debugger, the message box is used to model the inter-process communication between the debugger backend and the debugger frontend within the same debugger process.
Therefore, we can think of $boxed(m)$ as a high-level abstraction of the debugger frontend.

The configuration of the remote debugger is similar, but the message box $boxed(m)$ now models the intra-process communication from backend to frontend, and a second message box $boxed(o)$ models the intra-process communication from frontend to backend.
This corresponds, respectively, to the output returned from the debugger, and the instructions send to it.

The debugger can return as output, either nothing, a term, or an acknowledgement of a debug command.
The debug commands supported by the debugger are _step_ and _inspect_---to take a simple step in the program, and to inspect the current state of the program.
Sometimes we also need the local steps (#oparrow) to perform an internal step, which does not correspond to a debug command visible to the user.
For such cases, we also provide a nothing command ($nothing$).

=== The evaluation rules of the #remotedbg debugger

The entire evaluation of the debugger ($delta dbgarrow delta'$) is captured by only four rules.
The first three steps are local steps, which describe the operation of a local debugger.

/ E-Step: When the current term $t$ can reduce to $t'$, than the debugger can take a step to $t'$, and output an acknowledgement of the successful step.

/ E-Fallback: This fallback rule allows the debugger to drop _step_ messages in case there is no $t arrow.r.long t'$. For the #stlc, this means that the term must be a value $v$. In this case, we output an acknowledgement of $nothing$, to indicate that the command was processed, but did not have any effects.

/ E-Inspect: The inspect step outputs the current term $t$.

/ E-Read: The previous two steps require the output to be empty, to clear the output we introduce the _E-Read_ rule.

To lift these local steps to describe the operation of a remote debugger, we only need to add one rule which takes the next debug command from the input message box, and takes the correct corresponding local step.

/ E-Remote: The remote debugger takes the next debug command $operation$ from the input message box, and performs the corresponding local step (#oparrow).

The evaluation of the remote debugger is informed by the commands that arrive in the input message box, a debug session can therefore be seen as a series of remote steps ($delta multi(dbgarrow) delta'$) that are the result of a sequence of debug commands, which we write as ($multi(operation)$).

Now that we have the formal semantics for a remote debugger that can step through and inspect a #stlc program, we can define what correctness means for such a debugger.

=== Correctness criteria for the #remotedbg debugger

Since we define our debugger in terms of the underlying language, the most intuitive definition of correctness for a debugger is that it should not change the semantics of the program being debugged.
An intuition shared by the earliest works on debugger correctness such as // todo
We develop the idea into two correctness criteria, _debugger soundness_ and _debugger completeness_.

Debugger soundness demands that for any debug session that begins at the start of the program, there is a path in the underlying language semantics that leads to the same final program state.
In the theorem, we use the shorthand notation $t_delta$ to denote the current term of a debugging configuration $delta$.

#theorem("Debugger soundness")[
  Let $delta_"start"$ be the initial configuration of the debugger for some program $t$. Then:
  $ forall space delta space . space ( delta_"start" multi(dbgarrow) delta ) arrow.r.double.long ( t multi(arrow.r.long) t_delta ) $
]
#proof[
  The proof proceeds by induction on the number of steps taken in the debugger.
  Since _E-Step_ is the only rule that changes the term $t$ in the debugger configuration, and _E-Step_ uses the local step ($arrow.r.long$); there is necessarily a path $t multi(arrow.r.long) t_delta$ in the underlying language semantics.
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

//#note[In fact, we only noticed when going over the progress proof, that the _E-Fallback_ rule was missing in the first version of #remotedbg.]Aside from these specific correctness criteria for debuggers, it is often a good idea to also proof the typical _progress_ and _preservation_ properties @pierce02 for the debugger semantics.
//Especially progress, generally serves as an important sanity check that the debugger is well-defined, and that there are no missing rules.
//We provide the proofs for progress and preservation for our tiny remote debugger, and all other debuggers that follow in this chapter, in @app:progress.

== A conventional debugger for #stlc

The tiny remote debugger $remotedbg$ is perhaps to simple to be really considered---what we conventionally call---a remote debugger.
The most obvious missing pieces are _pause_ and _play_ commands, and support for _breakpoints_.

...

== A reversible debugger for #stlc

Another extension to the tiny remote debugger, is to turn it into a reversible debugger @engblom12.
// go back to start and rerun -> we need to keep track of the number of steps

...

== An intercession debugger for #stlc

// change variable value
Our debuggers so far have only observed the execution of a program, without interceding in it.
//However, many debuggers support some form of _reflection_ @maes87 @papoulias13, where they change the program's execution.
Yet, it is quite common for debuggers to support changing the value of variablesi @gdb @stallman88:debugging, or influence the control flow of the program @lauwaerts22:event-based-out-of-place-debugging @stallman88:debugging @alter.



...

== General debugger correctness

The correctness criteria for debuggers presented in this chapter, differ slightly in notation, but they all follow the general principle of _soundness_ and _completeness_.

// == Debuggers that break correctness

// todo do we need a section where we discuss debuggers which do not satisfy this criterion? + its implications / harmful effects
//
// is this not easy with a reversible debugger?

...

== Conclusion

//The formal framework for debuggers presented in this chapter, is the basis for the formalisations at the heart of this dissertation.
The framework proposed in this chapter, is at the heart of the formalisations in this dissertation.
As we explore how to develop sound out-of-place and multiverse debugging techniques for constrained environments, we will test our models with the correctness criteria presented in this chapter.
Furthermore, the spirit of the debugger semantics in this chapter closely align to the design of the debuggers we will present. // in the following chapters.
The rest of this dissertation will also mirror the structure of this chapter, by first presenting a remote debugger, and then extending it with more advanced features in the following chapters.

//The rest of this dissertation is build on the correctness criteria for debuggers presented in this chapter.
//The dissertation itself will also follow the structure of this chapter, by first presenting a simple remote debugger, and then extending it with more advanced features in the following chapters.
//
//The remote debugger presented in the next chapter is designed to debug microcontrollers, and is built on top of the WebAssembly language.
//The reasons for exploring the foundations for debuggers on microcontrollers, are twofold.
//First, debugging technology is still lacking behind in the embedded world, where developers are still to a large extend using print statement debugging, or simple remote debuggers that require dedicated hardware.
//Second, 
//We already touched on the motivation for the WebAssembly language in the introduction, but this become even clearer in the next chapter.

