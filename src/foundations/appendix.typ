
#import "../../lib/util.typ": semantics
#import "figures/semantics.typ": nat, bindings

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

= Progress and Preservation proofs<app:progress>

Here we include all relevant progress and preservation proofs for the debugger semantics from @chapter:foundations.

