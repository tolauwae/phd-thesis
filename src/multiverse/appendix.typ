#import "../../lib/util.typ": semantics, tablehead
#import "../../lib/class.typ": note, theorem, lemma, definition, proof
#import "../semantics/arrows.typ": *
#import "../semantics/forms.typ": brackets
#import "./figures/semantics.typ": mocks, nop, call, cps, ret, In, Out, mocks, dbg, es, msg
#import "multiverse.typ": theoremdebuggersoundness, theoremdebuggercompleteness, theoremcompensationsoundness, external

#import "@preview/curryst:0.5.0": rule, prooftree

= Auxiliary multiverse debugger rules<app:rules>

In this appendix, we present the auxiliary debugger rules for the multiverse debugger for WebAssembly, omitted from @chap:multiverse in the main text for brevity.
These are the rules for the step forward operations on primitive calls, and the run variant of the #text(style: "italic")[step-mock] rule.

#semantics(
  [
    The #emph[step forwards] rules for input and output primitives in the multiverse debugger for WebAssembly, without input mocking. Addition to @fig:forwards-prim.
  ],
  [
    #table(columns: (2.0fr, 1fr), stroke: none, gutter: 1.0em,
      tablehead("Auxiliary evaluation rules"), "",
      table.cell(colspan: 2, table(columns: (1fr), stroke: none,

        prooftree(rule(
          $
          brackets.l "pause", "step", mocks, K_n bar.v S^* brackets.r dbgarrow brackets.l "pause", nothing, mocks, K_(n+1) bar.v S^* ⋅ {K_(n+1), r_nop} brackets.r
          $,
          $
          K_n = {s; v^*; v^*_0 (call j)}$,$P(j) = p$,$p in P^In$,$
          mocks(j, v^*_0) = epsilon$,$K_n wasmarrow K_(n+1)
          $,
          name: text(style: "italic", "step-prim-in")
        )),

        prooftree(rule(
          $
          brackets.l "pause", "step", mocks, K_n bar.v S^* brackets.r dbgarrow brackets.l "pause", nothing, mocks, K_(n+1) bar.v S^* ⋅ {K_(n+1), r} brackets.r
          $,
          $
          K_n = {s; v^*; v^*_0 (call j)}$,$P(j) = p$,$p in P^Out$,$
          p(v^*_0) = {ret v, cps r}$,$K_(n+1) = {s; v^*; v}
          $,
          name: text(style: "italic", "step-prim-out")
        ))

      )),
    )
  ],
  "fig:forwards-prim-step"
)

#semantics(
  [
    The register and unregister rules for input mocking in the MIO multiverse debugger, as well as the #text(style: "italic")[run-mock] variant. Addition to @fig:mocking from @mult:mocking.
  ],
    [
    #table(columns: (2.0fr, 1fr), stroke: none, gutter: 1.0em,
      tablehead("Auxiliary evaluation rules"), "",
      table.cell(colspan: 2, table(columns: (1fr), stroke: none,

        prooftree(rule(
          $
          brackets.l "play", nothing, mocks, K_n bar.v S^* brackets.r dbgarrow brackets.l "play", nothing, mocks, K'_(n+1) bar.v S^* ⋅ {K'_(n+1), r_nop} brackets.r
          $,
          $
          K_n = {s; v^*; v^*_0 (call j)}$,$P(j) = p$,$p in P^In$,$
          mocks(j, v^*_0) = v$,$K'_(n+1) = {s'; v'^*; v}
          $,
          name: text(style: "italic", "run-mock")
        ))

      )),
    )
  ],
  "fig:mocking-additional"
)

//%The #text(style: "italic")[run-mock] rule is a variant of the #text(style: "italic")[step-mock] rule, for when the debugger is not paused. THe only differences are the execution state is now #text(style: "italic")[play] and there is no $step$ message.

= Proofs and auxiliary lemmas for the multiverse debugger<app:proofs>

In this appendix, we present the lemmas and proofs for the multiverse debugger semantics for WebAssembly, omitted from @mult:correctness.
The first lemma states that the mocking of input values will not introduce states in the multiverse debugger that cannot be observed by the underlying language semantics.
//Since the input values accepted by the #text(style: "italic")[register-mock] rule must be part of the codomain of the primitive, this will always be the case.

#lemma("Mocking non-interference")[
    Given a debugging state $dbg$ and $dbg dbgarrow dbg'$, which uses the #text(style: "italic")[step-mock] rule, and $K$ in $dbg$, and $K'$ in $dbg'$, it holds that
    $
        dbg dbgarrow dbg' arrow.r.double.long K wasmarrow K'
    $
]<lemma:mocking-non-interference>

#proof[
Since the #text(style: "italic")[register-mock] rule only adds a new value to the $mocks$ map when the value is in the codomain of the primitive, the value produced by the #text(style: "italic")[step-mock] can be chosen by the non-deterministic rule #text(style: "italic")[input-prim].

]

A second lemma crucial to the soundness of the debugger, states that for any debugging state, there is a path in the underlying language semantics from the start to every snapshot in the snapshot list.

#lemma["Snapshot soundness"][
    For any debugging state $dbg$ with program state $K_m$, and snapshots $S^*$, it holds that
    $
        dbg_"start" multi(dbgarrow) {es,msg,mocks,K_m,S^ast} arrow.r.double.long forall {K_n , r} in S^ast : K_0 multi(wasmarrow) K_n
    $
]<lemma:snapshot-soundness>

#proof[
      By induction over the snapshots in the steps in $dbg_"start" multi(dbgarrow) {es,msg,mocks,K_a,S^*}$.

      #strong[Base case:] We have $S^* = {K_0, r_nop}$, and the lemma holds trivially since $K_0 multi(wasmarrow) K_0$.

      #strong[Induction case:] By the induction hypothesis, $dbg_"start" multi(dbgarrow) {es', msg', mocks', K_m, S'^*}$, and $forall {K_n , r'} in S'^* : K_0 multi(wasmarrow) K_n$.
            Now we prove the theorem still holds after: $ {es',msg',mocks',K_m,S'^*} dbgarrow {es,msg,mocks,K_a,S^*} $
            The possible steps fall in five cases.

        1. For the rules that do not change the snapshot list, #text(style: "italic")[run], #text(style: "italic")[step-forwards], #text(style: "italic")[pause], #text(style: "italic")[play], #text(style: "italic")[register-mock], #text(style: "italic")[unregister-mock], or #text(style: "italic")[step-back], the theorem holds trivially.
        2. For the rules #text(style: "italic")[run-prim-in] and #text(style: "italic")[step-prim-in], $K_a = K_(m+1)$, and the rules extend the snapshot list with ${K_(m+1),r_nop}$. We know by the assumptions of the rule that $K_m wasmarrow_i K_(m+1)$, so the theorem holds.
        3. For the rules #text(style: "italic")[run-prim-out] and #text(style: "italic")[step-prim-out] $K_a = K_(m+1)$, and the rules extend the snapshot list with ${K_(m+1),r}$. Both rules satisfy the assumptions for the underlying language rule #text(style: "italic")[output-prim], and the state $K_(m+1)$ is exactly the same as the state reached by #text(style: "italic")[output-prim]. So we have $K_m wasmarrow K_(m+1)$, and the theorem holds.
        4. The rule #text(style: "italic")[step-mock] adds ${K_(m+1),r_nop}$ to the snapshot list, $K_a = K_(m+1)$, and we know that $K_m wasmarrow K_(m+1)$ by @lemma:mocking-non-interference, so the theorem holds.
        5. The #text(style: "italic")[step-back-compensate] rule only removes a snapshot from the snapshot list, so by the induction hypothesis, the theorem holds.

]

Now we give the proof for debugger soundness, where the snapshot soundness lemma will be crucial. //% followed by the auxiliary lemmas for snapshot soundness (@lemma:snapshot-soundness), checkpoint existence (@lemma:checkpoint-existence), and deterministic path (@lemma:deterministic-path).

#theorem("Debugger soundness")[#theoremdebuggersoundness]

#proof[
    By induction over the steps in the path $dbg_"start" multi(dbgarrow) dbg$.

    #strong[Base case:] We have $ dbg_"start" =  brackets.l #text(style: "italic")[pause], msg, lambda z .  lambda y . lambda x . epsilon.alt, K_0 bar.v { K_0 , r_nop } brackets.r$, and the length of the path is $1$.
    The rules #text(style: "italic")[run], #text(style: "italic")[pause], #text(style: "italic")[run-prim-in], #text(style: "italic")[run-prim-out], do not apply since the execution state is not #text(style: "italic")[play].
    Similarly, the #text(style: "italic")[step-back] and #text(style: "italic")[step-back-compensate], do not apply since the index label for $K$ is zero, and #text(style: "italic")[step-mock] does not apply because the mocking map is empty.
    The rules #text(style: "italic")[play], #text(style: "italic")[register-mock], and #text(style: "italic")[unregister-mock] do not change the state $K_0$, and $K_0 multi(wasmarrow) K_0$ holds for length $0$.
    The #text(style: "italic")[step-forwards] and the #text(style: "italic")[step-prim-in] rules use the underlying language semantics to step to $K_1$.
    Finally, the requirements for the #text(style: "italic")[output-prim] in the underlying language semantics are  met by the #text(style: "italic")[step-prim-out] rule.
    The #text(style: "italic")[step-prim-out] rule moves the state to $K_1 = {s,v^*,v}$, which is exactly the same state reached by the #text(style: "italic")[output-prim] rule in the underlying language semantics.
    So the theorem holds for the base case.

    #strong[Induction case:] We have a debugging state $dbg'$ with WebAssembly state $K'$, we know that $dbg_"start" multi(dbgarrow) dbg'$ holds, and there is a step $dbg' dbgarrow dbg$.
    Since $dbg'$ can have any execution state, any message, and any mocking map, we need to consider all possible cases.
    For the rules which do not change the state $K$, the #text(style: "italic")[play], #text(style: "italic")[pause], #text(style: "italic")[register-mock], and #text(style: "italic")[unregister-mock] rules, and the theorem holds trivially.
    For the #text(style: "italic")[run], #text(style: "italic")[step-forwards], #text(style: "italic")[run-prim-in], #text(style: "italic")[step-prim-in], by the induction hypothesis we know that $K_0 multi(wasmarrow) K'$, and the rules take the step $K' wasmarrow K$, so the theorem holds. //% by the same reasoning as in the base case.
    If the mocking map returns a mocked value, the #text(style: "italic")[step-mock] rule applies, and given the induction hypothesis and @lemma:mocking-non-interference, the theorem holds.
    However, stepping backwards is more complex.
    In case the final step uses #text(style: "italic")[step-back], the rule jumps to a state $K_n$ from the snapshot list.
    By @lemma:snapshot-soundness, we know that $K_0 multi(wasmarrow) K_n$.
    Since in the assumptions of the #text(style: "italic")[step-back] rule, we know that $K_n attach(wasmarrow, tr: m-n-1) K_(m-1)$, the theorem holds.
    The case for the #text(style: "italic")[step-back-compensate] rule is identical.
]

#theorem("Debugger completeness")[#theoremdebuggercompleteness]

#proof[
    For any step $K wasmarrow K'$ in the path $K_0 multi(wasmarrow) K'$, either we can apply the #text(style: "italic")[step-forward] or #text(style: "italic")[step-prim-out] rules to the debugging state $dbg$ with state $K$.
    Or, $K$ is a call to an input primitive, in which case $K wasmarrow K'$ is non-deterministic.
    However, since we know the return value $v$ in $K'$, we can apply the #text(style: "italic")[register-mock] rule, after which, the #text(style: "italic")[step-mock] rule is applicable.
    This rule will move the state to $K'' = {s;v^*;v}$, which is the same as $K'$.
    So the theorem holds for all steps in the path $K_0 multi(wasmarrow) K'$.

]

Finally, we give the proof for compensation soundness (@theorem:compensate-soundness). //%, and the needed lemmas.
But first, for completeness, we provide the definition of external effects equivalence for a series of debugging rules and a series of rules in the underlying language semantics.

#definition("External effects equivalence")[
    Let $t$ be a series of rules in the debugging semantics, and $q$ a series of rules in the underlying language semantics.
    When for each #text(style: "italic")[step-prim-out] with $p$ in $external(t)$, either the next #text(style: "italic")[step-back-compensate] in $external(t)$ uses $p_cps$, or there is an #text(style: "italic")[output-prim] with $p$ in $external(q)$, we say that

    $ external(t) equiv external(q) $
]<def:external-effects>

#theorem("Compensation soundness")[#theoremcompensationsoundness]

#proof[
    The multiverse tree is a connected acyclic graph, where each edge is a step in the underlying language semantics.
    Any debugging session $dbg_"start" multi(dbgarrow) dbg$ can be seen as a walk over the multiverse tree, where edges can be visited more than once, and walking over an edge has a direction.
    By debugger soundness (@theorem:debugger-soundness), we know that for any debugging session there is a path in the underlying language semantics $K_0 multi(wasmarrow) K_n$.
    The debugging session constructed in the proof for the debugger completeness (@theorem:debugger-completeness), shows that for any path in the underlying language semantics, there is a debugging session $P$ that ends in $K_n$, but does not use the #text(style: "italic")[step-back] or #text(style: "italic")[step-back-compensate] rules.
    This walk $P$ corresponds to the path from $K_0$ to $K_n$ in the multiverse tree, which only visits each edge once.
    This means that: $ external(P) = external(K_0 multi(wasmarrow) K_n) $

Now we can show that any walk over the multiverse tree that ends in state $dbg$ can be reduced to the path $P$ by only removing closed walks.
Take a state $dbg'$ on the path from $dbg_"start"$ to $dbg$.
Say that step $s$ is the first step in the debugging session that ends in the state $dbg'$, and $s'$ is the last step to end in the state $dbg'$.
Then the steps between $s$ and $s'$ must form a closed walk, and we know that no step will come back to $dbg'$.
This holds for each state on the path, and therefore the entire session can be reduced to a path.
Removing a closed walk has no effect on the external world, since each forward visited of an edge will have a corresponding backward visit in the walk.
In other words, the effect on the environment by a closed walk is equivalent to the empty list.
This means that:

$ external(P) = external(dbg_"start" multi(dbgarrow) dbg) $

Therefore, the theorem holds.
]
