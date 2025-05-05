#import "../../lib/class.typ": note
// todo the very first sentence should say something about bugs


As surely as computers will continue to run software, so will software continue to have bugs and mistakes.
That’s not pessimism; it’s reality. After all we live in an imperfect world.
No formal method, nor static checker, or machine learning model can ever eliminate all mistakes---especially, for software which interacts with this imperfect, and unpredictable world.
This is where debuggers come in.

== The nature of programming mistakes

Programming mistakes come in many forms, and have many causes @mccauley08:debugging.
Some are simple syntax errors or off-by-one mistakes that static checkers can easily catch.
Others have deep, and complex causes such as timing issues in concurrent systems @lu08:learning, memory corruption from hardware quirks, non-deterministic edge cases triggered only under rare input conditions, and so forth.
Crucially, many real-world bugs are not predictable or even known in advance. We often do not know what class of bug we are hunting until we start looking.

This is why automated verification, however powerful, has limits. Formal proofs and model checking work only when the system and its requirements can be fully specified and the relevant properties articulated. But most software systems today are too large, too dependent on external environments, or too hastily evolving for perfect formalization. Many mistakes arise precisely where models stop: at the interfaces, in the messy real-world details, or in emergent behaviors no one thought to check. In these cases, the only path forward is empirical investigation.
This almost exclusively involves inspecting program execution with debuggers, to trace the steps that led to failure.
//That is what debuggers make possible.

== The history of debugging  // we talk about debugging since we see it broadly (also print statements)

Debugging has been central to programming since the earliest days of computing. The term itself is often traced to _Grace Hopper’s famous 'bug' story_ from 1947#note[Actually, the term _bug_ was already used to refer to a fault in a machine in the late nineteenth century @wills22:bug.], when a literal moth was found shorting a relay in the Harvard Mark II computer @cohen94:use.


The introduction of integrated development environments (IDEs) in later decades brought breakpoints, watchpoints, and step-through execution into the everyday workflow. More recently, advanced tools like time-travel debuggers, distributed tracing systems, and concurrency visualizers have emerged to address the complexity of modern, multi-threaded, and distributed systems. But across all these stages, the core challenge remains unchanged: making the invisible state of a running program visible, so its failures can be understood and corrected.

== What are debuggers?

As the history of debugging shows, the term debugger is fluid and can refer to a wide range of tools and techniques.
Moreover, a wide variety of categories exists, often with overlapping features, and even different names for the same concepts.

The latest ISO vocabulary standard defines debugging as, _"to detect, locate, and correct faults in a computer program"_ @iso2382-1:2017.

== Why debuggers matter

This is especially true for software running on embedded systems.
Here, bugs can be caused not just by pure mistakes in the programming logic, but also by unexpected interactions with the hardware, specific timings, or unexpected behavior from the physical world.
To track down the causes of such failures, we need direct access to the system’s behavior---to stop execution, inspect memory, walk through the precise state transitions that led to failure.

This is what debuggers give us.
They provide precise, and deterministic mechanisms for controlling and examining program execution, essential for diagnosing subtle bugs, concurrency issues, performance bottlenecks, and hardware-specific behavior.

While automatic tools such as static analyzers, model checkers, and type systems can catch many classes of errors, they are limited by what they are designed to check. They work when you know the kinds of mistakes you’re guarding against. But when a system fails and you don’t know why, and have no predefined property to verify, you need debuggers that let you observe the system directly.

Despite the rapid rise of large language models (LLMs) in software engineering, debuggers remain critical for program understanding, and finding mistakes.
While LLMs can assist in bug detection or code generation, they operate as probabilistic tools without direct connection to runtime state, offering suggestions rather than guarantees.

Debuggers, by contrast, are deterministic and precise, providing direct access to program execution and memory state.
Ongoing debugger research not only enhances these capabilities but also drives advances in program analysis, visualization, security, and education.
In fact, since more and more code is generated probabilistically with LLMs, there is arguably an even greater need for deterministic and precise debugging tools to inspect the generated code.

== The challenges of resource-constraints


== The challenges of non-determinism


== The promise of universal bytecode interpreters


