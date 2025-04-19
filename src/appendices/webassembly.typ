= WebAssembly Specification Summary <webassembly>
In this appendix, we will discuss the elements of WebAssembly needed to understand the formalization of our extensions. A full and detailed account of all WebAssembly’s formal semantics can be found in the excellent paper of #cite(<haas17:bringing>, form: "prose");.

#figure[
  \$\$\\begin{array}{rrcl}
  \\emph{(value types)} & t & \\Coloneqq & \\textsf{i32} \\; | \\; \\textsf{i64} \\; | \\; \\textsf{f32} \\; | \\; \\textsf{f64} \\\\
  \\emph{(packed types)} & tp & \\Coloneqq & \\textsf{i8} \\; | \\; \\textsf{i16} \\; | \\; \\textsf{i32} \\\\
  \\emph{(function types)} & \\textit{tf} & \\Coloneqq & t^\* \\rightarrow t^\* \\\\
  \\emph{(global types)} & tg & \\Coloneqq & mut^? \\; t \\\\

  \\emph{(instructions) } & e & \\Coloneqq & \\key{unreachable} \\; | \\; \\key{nop} \\; | \\; \\key{drop} \\; | \\; \\key{select} \\; | \\; \\key{block} \\; \\textit{tf} \\; e^\* \\key{end} \\; | \\\\
  & & & \\key{loop} \\; \\textit{tf} \\; e^\* \\key{end} \\; | \\; \\key{if} \\; \\textit{tf} \\; e^\* \\key{else} \\; e^\* \\key{end} \\; | \\; \\key{br} \\; i \\; | \\; \\key{br\\\_if} \\; i \\; | \\\\
  & & & \\key{br\\\_table} \\; i^+ \\; | \\; \\key{return} \\; | \\; \\key{call} \\; i \\; | \\; \\key{call\\\_indirect} \\; \\textit{tf} \\; | \\\\
  & & & \\key{local.get} \\; i \\; | \\; \\key{local.set} \\; i \\; | \\; \\key{local.tee} \\; i \\; | \\; \\key{global.get} \\; i \\; | \\\\
  & & & \\key{global.set} \\; i \\; | \\; t.\\key{load} \\; (\\textit{tp\\\_sx})^? a \\, o \\; | \\; t.\\key{store} \\; \\textit{tp}^? a \\, o \\; | \\\\
  & & & \\key{current\\\_memory} \\; | \\; \\key{grow\\\_memory} \\; | \\; t.\\key{const} \\; c \\; | \\\\
  & & & t.unop\_t \\; | \\; t.binop\_t \\; | \\; t.testop\_t \\; | \\; t.relop\_t \\; | \\; t.cvtop \\; t\\\_sx^? \\\\
  \\emph{(functions)} & f & \\Coloneqq & ex^\* \\; \\key{func} \\; \\textit{tf} \\; \\key{local} \\; t^\* e^\* \\; | \\; ex^\* \\; \\key{func} \\; \\textit{tf} \\, im \\\\
  \\emph{(globals)} & glob & \\Coloneqq & ex^\* \\; \\key{global} \\; \\textit{tg} \\, e^\* \\; | \\; ex^\* \\; \\key{global} \\; \\textit{tg} \\, im \\\\
  \\emph{(tables)} & tab & \\Coloneqq & ex^\* \\; \\key{table} \\; n \\, i^\* \\; | \\; ex^\* \\; \\key{table} \\; n \\, im \\\\
  \\emph{(memories)} & mem & \\Coloneqq & ex^\* \\; \\key{memory} \\; n \\; | \\; ex^\* \\; \\key{memory} \\; n \\, im \\\\
  \\emph{(imports)} & im & \\Coloneqq & \\key{import} \\; \\textit{\"name\" \"name\"} \\\\
  \\emph{(exports)} & ex & \\Coloneqq & \\key{export} \\; \\textit{\"name\"} \\\\
  \\emph{(modules)} & m & \\Coloneqq & \\key{module} \\; \\textit{tf}^\* \\; f^\* \\; glob^\* \\; tab^? \\; mem^?
  \\end{array}\$\$

]<fig:syntax>

== Modules and Imports <modules-and-imports>
A WebAssembly binary is organized as a #emph[module];, which can only interact with its environment through typed imports and exports. WebAssembly embraces this strict encapsulation to better protect against possible security vulnerabilities associated with running WebAssembly bytecode in the browser. To further strengthen the security of WebAssembly, the language is defined with a strict type system that allows for fast static validation. As the last line of figure~@fig:syntax shows, a WebAssembly module contains #emph[function types];, #emph[functions];, #emph[globals];, #emph[tables] and at most one #emph[memory];. All of these definitions, except #emph[function types];, can be imported from other modules as well as exported under one or more names.

The life cycle of a WebAssembly module can be divided into three stages. In the first stage, the WebAssembly code is statically validated by the type system. This is usually done before compilation. After compilation the code can be executed by a WebAssembly runtime, such as WARDuino or a web browser. In the second stage, the runtime turns the module \$m = (\\key{module}\\,\\textit{tf}^\*\\,f^\\ast\\,glob^\\ast\\,tab^?\\,mem^?)\$ into a dynamic instance $i n s t$. As shown in figure~@fig:WebAssemblyMR, all instances are kept in the WebAssembly global store $s$. During instantiation, the runtime must provide definitions for all imports, and it must allocate mutable memory. Finally, after this second stage, the WebAssembly code can be executed.

== Control Flow <control-flow>
WebAssembly differs from traditional instructions sets in the way it prevents control flow hijacking @burow17:control-flow-integrity@lehmann20:everything. The instruction set does not allow arbitrary jumps, but only offers structured control flow. This means that unrestricted jumps do not exist. Instead, branches can only jump to the end of well-nested blocks inside the current function.

WebAssembly features three control constructs, , , and . These constructs all terminate with an instruction. The sequence of instructions $e^(\*)$ captured between these instructions form a so-called block. The can optionally hold two instruction sequences, separated by an extra opcode. When an instruction is executed, and the top of the stack is a non-zero number, the first block is executed, otherwise the second block is. Executing a executes the instructions captured in it unconditionally.

A branch instruction () specifies a target $i$. This target must be one of the blocks the instruction is executed in. If the target is a or , executing the branch will skip any instruction between the position of the and the of the targeted block. Branching to a jumps to the start of that . Counter-intuitively, the construct does not loop automatically. Instead, the instructions allow it to be repeated. Branches may also be conditional. A will only branch if the value on the top of the stack is non-zero. The , takes a list of targets and branches to the $n$-th target if the number $n$ is on the top of the stack.#footnote[The instruction jumps to its last target if the index is out of bounds.]

== Functions <functions>
Modules contain a list of functions (\$\\key{func} \\; \\textit{tf} \\; \\key{local} \\; t^\* e^\*\$). All functions have a function type $italic("tf")$ of the form $t_1^(\*) arrow.r t_2^(\*)$. Because WebAssembly is a stack based language, this type describes the action of a function on the stack. The value types $t_1^(\*)$ before the arrow indicate the types of the elements the function expects to be on top of the stack when called. After the arrow, $t_2^(\*)$ indicates the return type.#footnote[Although a star is used, WebAssembly functions only return a single value.] The type $[sans("i32") , sans("i32")] arrow.r [sans("f32")]$ is used for a function that pops two 32-bit integers from the stack and pushes one 32-bit floating point number on the stack. Functions may also have local variables, these are declared as a list of value types after the function type as follows: \$\\key{local} \\; t^\*\$. These local variables are zero-initialized. The arguments and the local variables can be read or written via the \$\\key{local.get}\$ and \$\\key{local.set}\$ instructions respectively. Both instructions take the index of the argument or local as argument. The body of a function $e^(\*)$ is a sequence of instructions that leaves the stack in a state matching the function’s return type.

== Function Calls and Tables <function-calls-and-tables>
Aside from arbitrary control flow, WebAssembly also lacks function pointers. It does provide an alternative with the instruction. This instruction can use a table to call functions based on an index operand calculated at runtime, similar to the instruction. Figure~@fig:indirect illustrates how this works. The instruction takes the value at the top of the stack and uses that to index a table of function references. Each table index corresponds to a function index, which in its turn points to a function. Tables can hold functions of different types, so the instruction takes a statically encoded argument specifying the type of the function it calls. At runtime, this encoded type is checked against the type of the function the index points to. If these do not correspond, the call is aborted, and a trap is thrown.

#figure[
]<fig:indirect>

== WebAssembly Linear Memory <webassembly-linear-memory>
The memory in WebAssembly is referred to as linear memory because it is a large array of bytes. Conceptually, the memory is divided into pages of 64 KiB. The size of memory is specified in terms of these pages, and linear memory can grow any number of pages at a time as long as the runtime can allocate the required space. Allocating additional pages can be done with the instruction. While the specification leaves the possibility of multiple memories open, WebAssembly still explicitly supports only one memory. However, a proposal for multiple memories is already in the implementation phase and so can be expected to be added to the standard in due course.

== Execution <execution>
The execution of a WebAssembly program is described by a small-step reduction relation $arrow.r.hook_i$ over a configuration triple representing the state of the VM. A configuration contains one global store $s$, the local values $v^(\*)$ and the active instruction sequence $e^(\*)$ being executed. The rules are of the form $s ; v^(\*) ; e^(\*) arrow.r.hook_i s' ; v'^(\*) ; e'^(\*)$. In figure~@fig:WebAssemblyMR, we present the most relevant small-step reduction rules for WARDuino.

#figure[]<fig:WebAssemblyMR>

At the top of the figure, we list all the relevant syntax for the rules. The store $s$ consists of a set of module instances, table instances and memory instances. Tables and memories are only referenced by their index, since they can be shared between modules. A module instance consists of closures, global variables, tables and memories. A closure is the instantiated version of a function, and is represented by a tuple of the module instance and a code block. Values consist of constants. To elegantly represent the semantics a number of administrative operators are added to the list of instructions. The most important ones are #strong[local] and #strong[label];. The #strong[local] operator indicates a call frame for function invocation (possibly over module boundaries), while the #strong[label] operator marks the extent of a control construct.

In the lower part of figure~@fig:WebAssemblyMR, we show some important small-step reduction rules for WebAssembly execution in WARDuino. Aside from the configuration ${ s , v^(\*) , e^(\*) }$, the small step reduction rules operate on the currently executing instance. That is why the small-step reduction is indexed by the address $i$ of that instance. The first two reduction rules govern the order of evaluation. The #smallcaps[step-i] rule splits a configuration into its context $L^k$ and its focus and takes one step of the $arrow.r.hook_i$ relation. The second rule~#smallcaps[step-local] explains how to evaluate a function that might reside in a different module. Note that this step changes the currently executing module, indicated by the two indices of the small-step relation $arrow.r.hook_(d , i)$. The last two rules are included because they are particularly relevant to our callback handling extension. The first rule, #smallcaps[step-indirect];, transforms a instruction into a standard instruction. The #smallcaps[step-indirect] rule takes a runtime index $j$, and an immediate function type #emph[tf];. The index $j$ must correspond to a function of the given type in the table of the current module $s_(t a b) (i , j)$. If this is the case, the indirect call is replaced with a call to the function. On the other hand, when no correct function is found, the indirect call is replaced by a as shown by #smallcaps[step-indirect-trap];. This means the program will stop executing. When all goes well, the resulting call can be reduced further. We omit any further reduction rules from the WebAssembly standard, because they are not changed or not relevant to the further discussion in this section. The interested reader can find all WebAssembly reduction rules in the original WebAssembly article@haas17:bringing.

Now we have all the formal tools required to describe the extensions to WebAssembly implemented in WARDuino. We will discuss each extension in turn in the following sections.

