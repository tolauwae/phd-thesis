
== Auxiliary multiverse debugger rules<app:rules>

In this appendix, we present the auxiliary debugger rules for the multiverse debugger for WebAssembly, omitted from \cref{sec:multiverse-debugger} in the main text for brevity.
These are the rules for the step forward operations on primitive calls, and the run variant of the \textsc{step-mock} rule.

//\begin{figure}[ht]
//        \begin{mathpar}
//                \inferrule[(\textsc{step-prim-in})]
//       	            { 
//                        K_n = \{ s ;v^*; v^*_0 (call \; j) \} \\
//                        P(j) = p \\
//                        p \in P^{In} \\
//                        mocks(j, v^*_0) = \varepsilon \\
//                        K_n \hookrightarrow_{i} K_{n+1} \\
//                    }
//                    { \langle \textsc{pause}, step, mocks, K_n \; | \; S^* \rangle
//                      \hookrightarrow_{d,i}
//                  \langle \textsc{pause}, \varnothing, mocks, K_{n+1} \; | \; S^* \cdot \{K_{n+1} , r_{nop}\} \rangle }
//
//                \inferrule[(\textsc{step-prim-out})]
//       	            { 
//                        K_n = \{ s ;v^*; v^*_0 (call \; j) \} \\
//                        P(j) = p \\
//                        p \in P^{Out} \\
//                        p(v^*_0) = \{ \textsf{ret } v, \textsf{cps } r \} \\
//                        K_{n+1} =\{ s ;v^*; v \} \\
//                    }
//                    { \langle \textsc{pause}, step, mocks, K_n \; | \; S^* \rangle
//                      \hookrightarrow_{d,i}
//                  \langle \textsc{pause}, \varnothing, mocks, K_{n+1} \; | \; S^* \cdot \{K_{n+1} , r\} \rangle }
//	\end{mathpar}
//        \caption{The \emph{step forwards} rules for input and output primitives in the multiverse debugger for WebAssembly, without input mocking. Addition to \cref{fig:forwards-prim}.}
//	<fig:forwards-prim-step>
//\end{figure}

//\begin{figure}[ht]
//	\begin{mathpar}
//                \inferrule[(\textsc{run-mock})]
//       	            { 
//                        K_n = \{ s ;v^*; v^*_0 (call \; j) \} \\
//                        P(j) = p \\
//                        p \in P^{In} \\
//                        mock(j, v^*_0) = v \\
//                        K'_{n+1} = \{ s';v'^*;v \} \\
//                    }
//                    { \langle \textsc{play}, \varnothing, mocks, K_n \; | \; S^* \rangle
//                      \hookrightarrow_{d,i}
//                  \langle \textsc{play}, \varnothing, mocks, K'_{n+1} \; | \; S^* \cdot \{K'_{n+1}, r_{nop}\} \rangle }
//
//	\end{mathpar}
//    \caption{The register and unregister rules for input mocking in the MIO multiverse debugger, as well as the \textsc{run-mock} variant. Addition to \cref{fig:mocking} from \cref{sec:mocking}.}
//	<fig:mocking-additional>
//\end{figure}

//%The \textsc{run-mock} rule is a variant of the \textsc{step-mock} rule, for when the debugger is not paused. THe only differences are the execution state is now \textsc{play} and there is no $step$ message.

== Proofs and auxiliary lemmas for the multiverse debugger<app:proofs>

In this appendix, we present the lemmas and proofs for the multiverse debugger semantics for WebAssembly, omitted from \cref{sec:correctness}.
The first lemma states that the mocking of input values will not introduce states in the multiverse debugger that cannot be observed by the underlying language semantics.
Since the input values accepted by the \textsc{register-mock} rule must be part of the codomain of the primitive, this will always be the case.

//\begin{lemma}[Mocking non-interference]<lemma:mocking-non-interference>
//    Given a debugging state $dbg$ and $dbg \hookrightarrow_{d,i} dbg'$, which uses the \textsc{step-mock} rule, and $K$ in $dbg$, and $K'$ in $dbg'$, it holds that
//    \[
//        dbg \hookrightarrow_{d,i} dbg' \Rightarrow K \hookrightarrow_{i} K'
//    \]
//\end{lemma}
//
//\begin{proof}
//    Since the \textsc{register-mock} rule only adds a new value to the $mock$ map when the value is in the codomain of the primitive, the value produced by the \textsc{step-mock} can also be chosen by the non-deterministic rule \textsc{input-prim}.
//\end{proof}

A second lemma crucial to the soundness of the debugger, states that for any debugging state, there is a path in the underlying language semantics from the start to every snapshot in the snapshot list.

//\begin{lemma}[Snapshot soundness]<lemma:snapshot-soundness>
//    For any debugging state $dbg$ with program state $K_m$, and snapshots $S^*$,  it holds that
//    \[
//        dbg_{start} \hookrightarrow^*_{d,i} \{rs,msg,mocks,K_m,S^*\} \Rightarrow \forall \{K_n , r\} \in S^* : K_0 \hookrightarrow_i^* K_n
//    \]
//\end{lemma}
//
//\begin{proof}
//    By induction over the snapshots in the steps in $dbg_{start} \hookrightarrow^*_{d,i} \{rs,msg,mocks,K_a,S^*\}$.
//    \begin{description}
//        \item[Base case] We have $S^* = \{K_0, r_{nop}\}$, and the lemma holds trivially since $K_0 \hookrightarrow_i^* K_0$.
//
//        \item[Induction case] By the induction hypothesis, $dbg_{start} \hookrightarrow^*_{d,i} \{rs',msg',mocks',K_m,S'^*\}$, and $\forall \{K_n , r'\} \in S'^* : K_0 \hookrightarrow_i^* K_n$.
//            Now we prove the theorem still holds after: $$\{rs',msg',mocks',K_m,S'^*\} \hookrightarrow_{d,i} \{rs,msg,mocks,K_{a},S^*\}$$
//            The possible steps fall in five cases.
//
//    \begin{itemize}
//        \item For the rules that do not change the snapshot list, \textsc{run}, \textsc{step-forwards}, \textsc{pause}, \textsc{play}, \textsc{register-mock}, \textsc{unregister-mock}, or \textsc{step-back}, the theorem holds trivially.
//        \item For the rules \textsc{run-prim-in} and \textsc{step-prim-in}, $K_a = K_{m+1}$, and the rules extend the snapshot list with $\{K_{m+1},r_{nop}\}$. We know by the assumptions of the rule that $K_m \hookrightarrow_i K_{m+1}$, so the theorem holds.
//        \item For the rules \textsc{run-prim-out} and \textsc{step-prim-out} $K_a = K_{m+1}$, and the rules extend the snapshot list with $\{K_{m+1},r\}$. Both rules satisfy the assumptions for the underlying language rule \textsc{output-prim}, and the state $K_{m+1}$ is exactly the same as the state reached by \textsc{output-prim}. So we have $K_m \hookrightarrow_i K_{m+1}$, and the theorem holds.
//        \item The rule \textsc{step-mock} adds $\{K_{m+1},r_{nop}\}$ to the snapshot list, $K_a = K_{m+1}$, and we know that $K_m \hookrightarrow_i K_{m+1}$ by \cref{lemma:mocking-non-interference}, so the theorem holds.
//        \item The \textsc{step-back-compensate} rule only removes a snapshot from the snapshot list, so by the induction hypothesis, the theorem holds.
//    \end{itemize}
//    \end{description}
//\end{proof}

Now we give the proof for debugger soundness, where the snapshot soundness lemma will be crucial. % followed by the auxiliary lemmas for snapshot soundness (\cref{lemma:snapshot-soundness}), checkpoint existence (\cref{lemma:checkpoint-existence}), and deterministic path (\cref{lemma:deterministic-path}).

//\newtheorem*{theorem*}{Theorem}
//
//\begin{theorem*}[Debugger soundness]
//    \theoremdebuggersoundness
//\end{theorem*}
//
//\begin{proof}
//    By induction over the steps in the path $dbg_{start} \hookrightarrow^*_{d,i} dbg$.
//
//    \begin{description}
//        \item[Base case] We have $ dbg_{start} =  \langle \textsc{pause}, msg, \lambda z .  \lambda y . \lambda x . \varepsilon, K_0 \; | \; \{ K_0 , r_{nop} \} \rangle$, and the length of the path is $1$.
//    The rules \textsc{run}, \textsc{pause}, \textsc{run-prim-in}, \textsc{run-prim-out}, do not apply since the execution state is not \textsc{play}.
//    Similarly, the \textsc{step-back} and \textsc{step-back-compensate}, do not apply since the index label for $K$ is zero, and \textsc{step-mock} does not apply because the mocking map is empty.
//    The rules \textsc{play}, \textsc{register-mock}, and \textsc{unregister-mock} do not change the state $K_0$, and $K_0 \hookrightarrow^*_i K_0$ holds for length $0$.
//    The \textsc{step-forwards} and the \textsc{step-prim-in} rules use the underlying language semantics to step to $K_1$.
//    Finally, the requirements for the \textsc{output-prim} in the underlying language semantics are also met by the \textsc{step-prim-out} rule.
//    The \textsc{step-prim-out} rule moves the state to $K_{1} = \{s,v^*,v\}$, which is exactly the same state reached by the \textsc{output-prim} rule in the underlying language semantics.
//    So the theorem holds for the base case.
//
//     \item[Induction case] We have a debugging state $dbg'$ with WebAssembly state $K'$, we know that $dbg_{start} \hookrightarrow^*_{d,i} dbg'$ holds, and there is a step $dbg' \hookrightarrow_{d,i} dbg$.
//    Since $dbg'$ can have any execution state, any message, and any mocking map, we need to consider all possible cases.
//    For the rules which do not change the state $K$, the \textsc{play}, \textsc{pause}, \textsc{register-mock}, and \textsc{unregister-mock} rules, and the theorem holds trivially.
//    For the \textsc{run}, \textsc{step-forwards}, \textsc{run-prim-in}, \textsc{step-prim-in}, by the induction hypothesis we know that $K_{0} \hookrightarrow^*_i K'$, and the rules take the step $K' \hookrightarrow_i K$, so the theorem holds. % by the same reasoning as in the base case.
//    If the mocking map returns a mocked value, the \textsc{step-mock} rule applies, and given the induction hypothesis and \cref{lemma:mocking-non-interference}, the theorem holds.
//    However, stepping backwards is more complex.
//    In case the final step uses \textsc{step-back}, the rule jumps to a state $K_n$ from the snapshot list.
//    By \cref{lemma:snapshot-soundness}, we know that $K_0 \hookrightarrow_i^* K_n$.
//    Since in the assumptions of the \textsc{step-back} rule, we know that $K_n \hookrightarrow^{m-n-1}_i K_{m-1}$, the theorem holds.
//    The case for the \textsc{step-back-compensate} rule is identical.
//    \end{description}
//\end{proof}

//\begin{theorem*}[Debugger completeness]
//    \theoremdebuggercompleteness
//\end{theorem*}
//
//\begin{proof}
//    For any step $K \hookrightarrow_i K'$ in the path $K_{0} \hookrightarrow^*_i K'$, either we can apply the \textsc{step-forward} or \textsc{step-prim-out} rules to the debugging state $dbg$ with state $K$.
//    Or, $K$ is a call to an input primitive, in which case $K \hookrightarrow_i K'$ is non-deterministic.
//    However, since we know the return value $v$ in $K'$, we can apply the \textsc{register-mock} rule, after which, the \textsc{step-mock} rule is applicable.
//    This rule will move the state to $K'' = {s;v^*;v}$, which is the same as $K'$.
//    So the theorem holds for all steps in the path $K_{0} \hookrightarrow^*_i K'$.
//\end{proof}
//
//Finally, we give the proof for compensation soundness (\cref{theorem:compensate-soundness}). %, and the needed lemmas.
//But first, for completeness, we provide the definition of external effects equivalence for a series of debugging rules and a series of rules in the underlying language semantics.
//
//\begin{definition}[External effects equivalence]<def:external-effects>
//    Let $t$ be a series of rules in the debugging semantics, and $q$ a series of rules in the underlying language semantics.
//    When for each \textsc{step-prim-out} with $p$ in $external(t)$, either the next \textsc{step-back-compensate} in $external(t)$ uses $p_{cps}$, or there is an \textsc{output-prim} with $p$ in $external(q)$, we say that
//
//    $$external(t) \equiv external(q)$$
//\end{definition}

//\begin{theorem*}[Compensation soundness]
//    \theoremcompensatesoundness
//\end{theorem*}
//
//\begin{proof}
//    The multiverse tree is a connected acyclic graph, where each edge is a step in the underlying language semantics.
//    Any debugging session $dbg_{start} \hookrightarrow^*_{d,i} dbg$ can be seen as a walk over the multiverse tree, where edges can be visited more than once, and walking over an edge has a direction.
//    By debugger soundness (\cref{theorem:debugger-soundness}), we know that for any debugging session there is a path in the underlying language semantics $K_0 \hookrightarrow^*_{i} K_n$.
//    The debugging session constructed in the proof for the debugger completeness (\cref{theorem:debugger-completeness}), shows that for any path in the underlying language semantics, there is a debugging session $P$ that ends in $K_n$, but does not use the \textsc{step-back} or \textsc{step-back-compensate} rules.
//    This walk $P$ corresponds to the path from $K_0$ to $K_n$ in the multiverse tree, which only visits each edge once.
//    This means that: $$external(P) = external(K_0 \hookrightarrow^*_{i} K_n)$$
//
//Now we can show that any walk over the multiverse tree that ends in state $dbg$ can be reduced to the path $P$ by only removing closed walks.
//Take a state $dbg'$ on the path from $dbg_{start}$ to $dbg$.
//Say that step $s$ is the first step in the debugging session that ends in the state $dbg'$, and $s'$ is the last step to end in the state $dbg'$.
//Then the steps between $s$ and $s'$ must form a closed walk, and we know that no step will come back to $dbg'$.
//This holds for each state on the path, and therefore the entire session can be reduced to a path.
//Removing a closed walk has no effect on the external world, since each forward visited of an edge will have a corresponding backward visit in the walk.
//In other words, the effect on the environment by a closed walk is equivalent to the empty list.
//This means that:
//
//$$external(P) = external(dbg_{start} \hookrightarrow^*_{d,i} dbg)$$
//
//Therefore, the theorem holds.
//\end{proof}
