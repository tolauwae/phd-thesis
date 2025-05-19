#import "../../lib/util.typ": semantics, tablehead
#import "../../lib/class.typ": note
#import "../semantics/arrows.typ": *

#import "@preview/curryst:0.5.0": rule, prooftree

= WebAssembly Specification Summary <app:webassembly>

In this appendix, we will discuss the elements of WebAssembly needed to understand the formalization of our extensions. A full and detailed account of all WebAssembly’s formal semantics can be found in the excellent paper of #cite(<haas17:bringing>, form: "prose");.

#let i8 = $sans("i8")$
#let i16 = $sans("i16")$
#let i32 = $sans("i32")$
#let i64 = $sans("i64")$
#let f32 = $sans("f32")$
#let f64 = $sans("f64")$

#let unop = $sans("unop")$
#let binop = $sans("binop")$
#let testop = $sans("testop")$
#let relop = $sans("relop")$
#let cvtop = $sans("cvtop")$

#let tp = $italic("tp")$
#let tf = $italic("tf")$
#let tg = $italic("tg")$
#let sx = $italic("sx")$
#let ex = $italic("ex")$
#let cl = $italic("cl")$
#let glob = $italic("glob")$
#let tab = $italic("tab")$
#let mem = $italic("mem")$
#let inst = $italic("inst")$
#let code = $italic("code")$

#let mut = $"mut"$

#semantics(
  [
    Core WebAssembly syntax evaluation rules as defined in #cite(<haas17:bringing>, form: "prose").
  ],
  [
    $
    &"(value types)"& t & colon.double.eq i32 ∣ i64 ∣ f32 ∣ f64 \
    &"(packed types)"& tp & colon.double.eq i8 ∣ i16 ∣ i32 \
    &"(function types)"& tf & colon.double.eq t^* → t^* \
    &"(global types)"& tg & colon.double.eq mut^? t \
    &"(instructions)"& e & colon.double.eq "unreachable" ∣ "nop" ∣ "drop" ∣ "select" ∣ "block" tf e^* "end" ∣ \
    &                &   &                 "loop" tf e^* "end" ∣ "if" tf e^* "else" e^* "end" ∣ "br" i ∣ "br_if" i ∣ \
    &                &   &                 "br_table" i^+ ∣ "return" ∣ "call" i ∣ "call_indirect" tf ∣ \
    &                &   &                 "local.get" i ∣ "local.set" i ∣ "local.tee" i ∣ "global.get" i ∣ \
    &                &   &                 "global.set" i ∣ t."load" (tp\_sx)^? space a space o ∣ t."store" tp^? space a space o ∣ \
    &                &   &                 "current_memory" ∣ "grow_memory" ∣ t."const" c ∣ \
    &                &   &                 t.unop_t ∣ t.binop_t ∣ t.testop_t ∣ t.relop_t ∣ t.cvtop t_sx^? \
    &"(functions)"& f & colon.double.eq ex^* "func" tf "local" t^* e^* ∣ ex^* "func" tf im \
    &"(globals)"& glob & colon.double.eq ex^* "global" tg e^* ∣ ex^* "global" tg im \
    &"(tables)"& tab & colon.double.eq ex^* "table" n i^* ∣ ex^* "table" n im \
    &"(memories)"& mem & colon.double.eq ex^* "memory" n ∣ ex^* "memory" n im \
    &"(imports)"& im & colon.double.eq "import" "\"name\"" "\"name\"" \
    &"(exports)"& ex & colon.double.eq "export" "\"name\"" \
    &"(modules)"& m & colon.double.eq "module" tf^* space f^* space glob^* space tab^? space mem^? \
    $
  ],
  "fig:syntax"
)


== Modules and Imports <modules-and-imports>

A WebAssembly binary is organized as a #emph[module];, which can only interact with its environment through typed imports and exports. WebAssembly embraces this strict encapsulation to better protect against possible security vulnerabilities associated with running WebAssembly bytecode in the browser. To further strengthen the security of WebAssembly, the language is defined with a strict type system that allows for fast static validation. As the last line of figure~@fig:syntax shows, a WebAssembly module contains #emph[function types];, #emph[functions];, #emph[globals];, #emph[tables] and at most one #emph[memory];. All of these definitions, except #emph[function types];, can be imported from other modules as well as exported under one or more names.

The life cycle of a WebAssembly module can be divided into three stages. In the first stage, the WebAssembly code is statically validated by the type system. This is usually done before compilation. After compilation the code can be executed by a WebAssembly runtime, such as WARDuino or a web browser. In the second stage, the runtime turns the module $m = (sans("module"), tf^ast, f^ast, glob^ast, tab^?, mem^?)$ into a dynamic instance $inst$. As shown in figure~@fig:WebAssemblyMR, all instances are kept in the WebAssembly global store $s$. During instantiation, the runtime must provide definitions for all imports, and it must allocate mutable memory. Finally, after this second stage, the WebAssembly code can be executed.

== Control Flow <control-flow>

WebAssembly differs from traditional instructions sets in the way it prevents control flow hijacking @burow17:control-flow-integrity@lehmann20:everything. The instruction set does not allow arbitrary jumps, but only offers structured control flow. This means that unrestricted jumps do not exist. Instead, branches can only jump to the end of well-nested blocks inside the current function.

WebAssembly features three control constructs, $"loop"$, $"if"$, and $"block"$.
These constructs all terminate with an $"end"$ instruction.
The sequence of instructions $e^ast$ captured between these instructions form a so-called block.
The $"if"$ can optionally hold two instruction sequences, separated by an extra $"else"$ opcode.
When an $"if"$ instruction is executed, and the top of the stack is a non-zero number, the first block is executed, otherwise the second block is.
Executing a executes the instructions captured in it unconditionally.

A branch instruction ($"br"$) specifies a target $i$.
This target must be one of the blocks the $"br"$ instruction is executed in.
If the target is a $"if"$ or $"block"$, executing the branch will skip any instruction between the position of the $"br"$ and the $"end"$ of the targeted block.
Branching to a $"loop"$ jumps to the start of that $"loop"$.
Counter-intuitively, the construct does not loop automatically.
Instead, the $"br"$ instructions allow it to be repeated. Branches may also be conditional.
A $"br_if"$ will only branch if the value on the top of the stack is non-zero.
The $"br_table"$, takes a list of targets and branches to the $n$-th target if the number $n$ is on the top of the stack.#note[$sans("br_table")$ jumps to its last target if the index is out of bounds.]

== Functions <functions>

Modules contain a list of functions ($"func" tf "local" t^ast e^ast$).
All functions have a function type $tf$ of the form $t_1^ast arrow.r t_2^ast$.
Because WebAssembly is a stack based language, this type describes the action of a function on the stack.
The value types $t_1^ast$ before the arrow indicate the types of the elements the function expects to be on top of the stack when called.
After the arrow, $t_2^ast$ indicates the return type.#note[Although a star is used, WebAssembly functions in #cite(form: "prose", <haas17:bringing>) only return a single value.]
The type $sans("i32") times sans("i32") arrow.r sans("f32")$ is used for a function that pops two 32-bit integers from the stack and pushes one 32-bit floating point number on the stack.
Functions may also have local variables, these are declared as a list of value types after the function type as follows: $"local" t^ast$.
These local variables are zero-initialized.
The arguments and the local variables can be read or written via the $"local.get"$ and $"local.set"$ instructions respectively.
Both instructions take the index of the argument or local as argument.
The body of a function $e^ast$ is a sequence of instructions that leaves the stack in a state matching the function’s return type.

== Function Calls and Tables <function-calls-and-tables>

Aside from arbitrary control flow, WebAssembly also lacks function pointers.
It does provide an alternative with the instruction.
This instruction can use a table to call functions based on an index operand calculated at runtime, similar to the instruction.
Figure~@fig:indirect illustrates how this works.
The instruction takes the value at the top of the stack and uses that to index a table of function references.
Each table index corresponds to a function index, which in its turn points to a function.
Tables can hold functions of different types, so the instruction takes a statically encoded argument specifying the type of the function it calls.
At runtime, this encoded type is checked against the type of the function the index points to.
If these do not correspond, the call is aborted, and a trap is thrown.

#figure[
]<fig:indirect>

== WebAssembly Linear Memory <webassembly-linear-memory>

The memory in WebAssembly is referred to as linear memory because it is a large array of bytes.
Conceptually, the memory is divided into pages of 64 KiB.
The size of memory is specified in terms of these pages, and linear memory can grow any number of pages at a time as long as the runtime can allocate the required space.
Allocating additional pages can be done with the $"grow_memory"$ instruction.
While the specification leaves the possibility of multiple memories open, WebAssembly still explicitly supports only one memory.
However, a proposal for multiple memories is already in the implementation phase and so can be expected to be added to the standard in due course.

== Execution <execution>

The execution of a WebAssembly program is described by a small-step reduction relation $wasmarrow$ over a configuration triple representing the state of the VM. A configuration contains one global store $s$, the local values $v^ast$ and the active instruction sequence $e^ast$ being executed. The rules are of the form $s ; v^ast ; e^ast wasmarrow s' ; v'^ast ; e'^ast$. In figure~@fig:WebAssemblyMR, we present the most relevant small-step reduction rules for WARDuino.

#let mr = table(columns: (2.0fr, 1fr), stroke: none, gutter: 1.0em,
      tablehead("WebAssembly syntax rules"), "",
      table.cell(colspan: 2, table(columns: (1fr), stroke: none,
    $
    &"(store)"& s & colon.double.eq {inst inst^*, tab "tabinst"^*, mem "meminst"^*} \
    &"(instances)"& inst & colon.double.eq {"func" cl^*, glob v^*, tab i^?, mem i^?} \
    && "tabinst" & colon.double.eq cl^* \
    && "meminst" & colon.double.eq b^* \
    &"(closures)"& cl & colon.double.eq {inst i, code f} \
    &"(values)"& v & colon.double.eq t."const" c \
    &"(admin. oper.)"& e & colon.double.eq ⋯ ∣ "call" cl ∣ "label"_n {e^*} space e^* "end" ∣ "local"_n {i; v^*} space e^* "end" \
    &"(local contexts)"& L^0 & colon.double.eq v^* ["_"] e^* \
    && L^{k+1} & colon.double.eq "label"_n {e^*} space L^k "end" e^* \
    $
      )),
      tablehead("WebAssembly evaluation rules"), "",
      table.cell(colspan: 2, table(columns: (1fr), stroke: none,

        prooftree(rule(
          $
          s; v^*; L^k[e^*] wasmarrow s'; v'^*; L^k[e'^*]
          $,
          $
          s; v^*; e^* wasmarrow s'; v'^*; e'^*
          $,
          name: smallcaps("step-i")
        )),

        prooftree(rule(
          $
          s; v_0^*; "local"_n {i; v'^*} e'^* "end" dbgarrow s'; v_0^*; "local"_n {i; v^*} e^* "end"
          $,
          $
          s; v^*; e^* wasmarrow s'; v'^*; e'^*
          $,
          name: smallcaps("step-local")
        )),

        prooftree(rule(
          $
          s; v_0^*; ("i32.const" j) "call_indirect" tf wasmarrow s'; v_0^*; "call" s_{tab}(i, j)
          $,
          $
          s; v^*; e^* wasmarrow s'; v'^*; e'^*$, $s_{tab}(i, j)_{code} = ("func" tf "local" t^* e^*)
          $,
          name: smallcaps("step-indirect")
        )),

        prooftree(rule(
          $
          s; v_0^*; ("i32.const" j) "call_indirect" tf wasmarrow s'; v_0^*; "trap"
          $,
          $
          s; v^*; e^* wasmarrow s'; v'^*; e'^*$, $s_{tab}(i, j)_{code} ≠ ("func" tf "local" t^* e^*)
          $,
          name: smallcaps("step-indirect-trap")
        ))

      )),
    )

#semantics(
    [WebAssembly meta-rules.],
    [#mr],
    "fig:WebAssemblyMR")


At the top of the figure, we list all the relevant syntax for the rules. The store $s$ consists of a set of module instances, table instances and memory instances. Tables and memories are only referenced by their index, since they can be shared between modules. A module instance consists of closures, global variables, tables and memories. A closure is the instantiated version of a function, and is represented by a tuple of the module instance and a code block. Values consist of constants. To elegantly represent the semantics a number of administrative operators are added to the list of instructions. The most important ones are #strong[local] and #strong[label];. The #strong[local] operator indicates a call frame for function invocation (possibly over module boundaries), while the #strong[label] operator marks the extent of a control construct.

In the lower part of figure~@fig:WebAssemblyMR, we show some important small-step reduction rules for WebAssembly execution in WARDuino. Aside from the configuration ${ s , v^ast , e^ast }$, the small step reduction rules operate on the currently executing instance. That is why the small-step reduction is indexed by the address $i$ of that instance. The first two reduction rules govern the order of evaluation. The #smallcaps[step-i] rule splits a configuration into its context $L^k$ and its focus and takes one step of the $wasmarrow$ relation. The second rule #smallcaps[step-local] explains how to evaluate a function that might reside in a different module. Note that this step changes the currently executing module, indicated by the two indices of the small-step relation $dbgarrow$. The last two rules are included because they are particularly relevant to our callback handling extension. The first rule, #smallcaps[step-indirect];, transforms a instruction into a standard instruction. The #smallcaps[step-indirect] rule takes a runtime index $j$, and an immediate function type #emph[tf];. The index $j$ must correspond to a function of the given type in the table of the current module $s_tab (i , j)$. If this is the case, the indirect call is replaced with a call to the function. On the other hand, when no correct function is found, the indirect call is replaced by a as shown by #smallcaps[step-indirect-trap];. This means the program will stop executing. When all goes well, the resulting call can be reduced further. We omit any further reduction rules from the WebAssembly standard, because they are not changed or not relevant to the further discussion in this section. The interested reader can find all WebAssembly reduction rules in the original WebAssembly article@haas17:bringing.

Now we have all the formal tools required to describe the extensions to WebAssembly implemented in WARDuino. We will discuss each extension in turn in the following sections.

