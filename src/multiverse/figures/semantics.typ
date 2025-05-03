
//\begin{figure}
//        \[
//	\begin{array}{ l l c l }
//            #emph[(WebAssembly Program state)] & K                         & \Coloneqq  & \{ s, v^ast, e^ast \} \\
//            #emph[(Global store)]              & s                         & \Coloneqq  & \{ \textsf{inst } \textit{inst}^ast, \textsf{tab } \textit{tabinst}^ast, \textsf{mem } \textit{meminst}^ast, \colorbox{lightgray}{\textsf{prim} $P$} \} \\
//            //%#emph[(Instances)]                 & \textit{inst}             & \Coloneqq  & \{ \textsf{func } \textit{cl}^*, \textsf{glob } v^*, \textsf{tab } i^?, \textsf{mem } i^?, \colorbox{lightgray}{\textsf{prim} $P$} \} \\
//            #emph[(Primitive table)]           & \colorbox{lightgray}{$P$} & \Coloneqq  & \colorbox{lightgray}{$p^*$} \\
//            \\
//            \hline \\
//            #emph[(Primitive)]                 & \colorbox{lightgray}{p}   & \coloneq  & \colorbox{lightgray}{$f : v^* \rightarrow \{ \textsf{ret } v , \textsf{cps } r \}$} \\
//            #emph[(Compensating action)]       & \colorbox{lightgray}{r}   & \coloneq  & \colorbox{lightgray}{$f : \epsilon \rightarrow \epsilon$} \\
//        \end{array}
//	\]
//    \caption{The configuration for the reversible primitives embedded in the WebAssembly semantics from the original paper by #cite(form: "prose", <haas17>), the differences are highlighted in gray. #emph[Top:] The WebAssembly semantics extended with a primitive table. #emph[Bottom:] The signatures of primitive and their compensating actions.}
//	<fig:prim-def>
//\end{figure}

#let primdef = []

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

#let language = []

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

#let multconfig = []

//\begin{figure}
//        \begin{mathpar}
//                \inferrule[(\textsc{run})]
//       	            { 
//                        \textsf{non-prim } K_n \\
//                        K_n wasmarrow K_{n+1}
//                    }
//                    { \langle \textsc{play}, \varnothing, mocks, K_n \; | \; S^* \rangle
//                      dbgarrow
//                  \langle \textsc{play}, \varnothing, mocks, K_{n+1} \; | \; S^* \rangle }
//
//                 \inferrule[(\textsc{step-forwards})]
//       	            { 
//                        \textsf{non-prim } K_n \\
//                        K_n wasmarrow K_{n+1}
//                    }
//                    { \langle \textsc{pause}, step, mocks, K_n \; | \; S^* \rangle
//                      dbgarrow
//                  \langle \textsc{pause}, \varnothing, mocks, K_{n+1} \; | \; S^* \rangle }
//
//                  \inferrule[(\textsc{pause})]
//       	            { 
//                    }
//                    { \langle \textsc{play}, pause, mocks, K_n \; | \; S^* \rangle
//                      dbgarrow
//                  \langle \textsc{pause}, \varnothing, mocks, K_n \; | \; S^* \rangle }
//
//                  \inferrule[(\textsc{play})]
//       	            { 
//                    }
//                    { \langle \textsc{pause}, play, mocks, K_n \; | \; S^* \rangle
//                      dbgarrow
//                  \langle \textsc{play}, \varnothing, mocks, K_n \; | \; S^* \rangle }
//	\end{mathpar}
//        \caption{The small-step rules describing forwards exploration in the multiverse debugger for WebAssembly instructions without primitives.}
//	<fig:forwards>
//\end{figure}

#let forwards = []

//\begin{figure}
//        \begin{mathpar}
//                \inferrule[(\textsc{run-prim-in})]
//       	            { 
//                        K_n = \{ s ;v^*; v^*_0 (call \; j) \} \\
//                        P(j) = p \\
//                        p \in P^{In} \\
//                        mocks(j, v^*_0) = \varepsilon \\
//                        K_n wasmarrow K_{n+1} \\
//                    }
//                    { \langle \textsc{play}, \varnothing, mocks, K_n \; | \; S^* \rangle
//                      dbgarrow
//                  \langle \textsc{play}, \varnothing, mocks, K_{n+1} \; | \; S^* \cdot \{K_{n+1} , r_{nop}\} \rangle }
//
//                \inferrule[(\textsc{run-prim-out})]
//       	            { 
//                        K_n = \{ s ;v^*; v^*_0 (call \; j) \} \\
//                        P(j) = p \\
//                        p \in P^{Out} \\
//                        p(v^*_0) = \{ \textsf{ret } v, \textsf{cps } r \} \\
//                        K_{n+1} = \{ s ;v^*; v \} \\
//                    }
//                    { \langle \textsc{play}, \varnothing, mocks, K_n \; | \; S^* \rangle
//                      dbgarrow
//                  \langle \textsc{play}, \varnothing, mocks, K_{n+1} \; | \; S^* \cdot \{K_{n+1} , r\} \rangle }
//	\end{mathpar}
//        \caption{The small-step rules describing forwards exploration for input and output primitives in the multiverse debugger for WebAssembly, without input mocking.}
//	<fig:forwards-prim>
//\end{figure}

#let forwardsprim = []

