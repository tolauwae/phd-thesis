#import "../../lib/class.typ": note, definition
// todo the very first sentence should say something about bugs

As long as people write programs for computers, so will software continue to have bugs and mistakes.
That is not pessimism; it is reality. After all we live in an imperfect world.
No formal method, nor model checker, or type system can ever eliminate all mistakes---especially, for software which interacts with this imperfect, and unpredictable world.
This is where debuggers---inevitably---come in.

== The nature of programming mistakes

Programming mistakes come in many forms, and have many causes @mccauley08:debugging.
Some are simple syntax errors or off-by-one mistakes that static or model checkers can easily catch @garcia-ferreira14:survey.
Others have deep, and complex causes such as timing issues in concurrent systems @lu08:learning @li23:empirical-study, memory corruption from hardware quirks @schroeder09:dram @dessouky18:when @bojanova21:classifying, non-deterministic edge cases triggered only under rare input conditions @weiss21:understanding, and so forth @catolino19:not.
Crucially, many real-world bugs are not predictable or even known in advance @mogul06:emergent @ubayashi19:when.

This is why automated verification @dsilva08:survey @rodriguez19:software, however powerful, has limits. Formal proofs and model checking work only when the system and its requirements can be fully specified and the relevant properties articulated.
But many software systems today are too large, too dependent on external environments, or too hastily evolving f2r perfect formalization.
No model or simulation can capture every single aspect of the real world @roska90:limitations @khan11:limitations and so cannot detect every possible bug.
In these cases, the only path forward is empirical investigation.
//That is what debuggers make possible.

This kind of empirical investigation is what we call _"debugging"_, and was best described by Andreas Zeller in his definitive guide, _"Why Programs Fail: A Guide to Systematic Debugging"_ @zeller05:why, which provides a thorough overview of debugging as a part of software development.
The book describes a scientific approach to isolating bugs, and discusses best practices, common tools, and novel techniques.

== What are debuggers?

The term debuggers is a rather ambiguous term, and can refer to any tool that helps with the task of debugging.
However, there are many such tools---not just your typical online debugger with breakpoints and steps found in today's standard development environments.
Instead, this goes from popular remote debuggers such as GDB, to automatic debuggers, or from advanced visualizers for reactive programs, to omniscient debuggers that can go forwards and backwards in time---debuggers really do come in all shapes and sizes.

This diffuseness suggests that we may never arrive at a more detailed, and universally accepted definition for debuggers---other than any tool that helps with debugging.
We can, however, define the type of debuggers we consider in this dissertation more concretely.
The scope of this work is limited to what we call _manual debuggers_.

#definition("Manual debugger")[
A debugger is a tool that enables developers to deterministically observe a program's execution, monitor its state, and control the flow of execution.
]

By this definition, we exclude automatic debugging, but include a whole range of manual debugging tools, from offline to online debuggers, from remote to local debuggers, from omniscient to reversible debuggers, and so forth.
To give the reader more context, we will briefly discuss the history of debuggers, their evolution, and highlight some of the different classes of debuggers that have been developed over the years.

== The history of debuggers
#note(text(weight: 400)[Actually, the term _bug_ was already used to refer to a fault in a machine in the late nineteenth century @wills22:bug.])Debugging has been central to programming since the earliest days of computer science. The term itself is often traced to _Grace Hopper’s famous 'bug' story_ from 1947, when a literal moth was found shorting a relay in the Harvard Mark II computer @cohen94:use.

No history of debugging is complete without also mentioning Maurice Wilkes' famous anecdote, describing the first time he experienced a need for debugging back in 1949: _"As soon as we started programming, [...] we found to our surprise that it wasn’t as easy to get programs right as we had thought it would be. [...] Debugging had to be discovered. I can remember the exact instant [...] when I realized that a large part of my life from then on was going to be spent in finding mistakes in my own programs."_ @wilkes79:birth @spinellis18:modern
The term _debugging_ came into circulation shortly after Wilkes' famous encounter. //, and continues to be an integral part of programming today.
From that point on, debuggers evolved alongside programming languages and computer systems, from the early days of assembly language and punch cards to the high-level languages we use today.
Wilkes' description still sums up the need for debugging perfectly today.

//=== A steady evolution
//
//While debugging may remain the dirty little secret of software development to some extent, it is no longer so in the scientific community.
//The literature on debugging is vast, from proposals of novel debugging techniques, to studies on the cognitive aspects of debugging  @beller18:on.

=== Debuggers in all shapes and sizes

During the early days of computer programming in the 1950s, most debugging was necessarily done with print statements, added to the punch cards used in those days @backus57:fortran.
One of the first improvements on this system, was to add new macros specific for debugging, which help improve traces of the program, such as those added in the _share_ operating system for the IBM 709 @hanford60:share.
These kind of macros can be considered the first iterations of so called _offline debuggers_, which are debuggers used to analyze a program after it terminated, usually through traces of the program's execution.
Early on they were often called _post-mortem debuggers_ @green60:ipl-v, however, today post-mortem refers to a specific type of offline#note[The terms _offline_ and _post-mortem_ still often get conflated.] debugger, which analyzes the program after it has crashed @pacheco11:postmortem.

During the same decade, the first _online debuggers_ were developed as well, which in contrast enable interactive inspection, control, and modification of a program’s execution state while the program is running.
One of the earliest examples is the RCA 501 system @smith58:design, which included six breakpoint switches, and a paper tape reader and monitor printer for debugging.
Of course computers have changed dramatically since the 1950s, and the days of magnetic tapes are long gone.
Still, the debugging tools of the RCA 501 system are very similar to the core debug operations present in most modern debuggers today.
A clear illustration of how slow adoption of new debugging techniques has been in some regards @perscheid17:studying.

//While debugging is still seen as hard, and something to avoid if possible, by many programmers, not all is doom and gloom.
//The current knowledge and practice of debugging can still be lamented, but over the last few decades, we have seen some improvements, and increased interested in understanding debugging and debuggers.

The introduction of integrated development environments (IDEs) certainly helped to popularize online debuggers, and brought breakpoints, watchpoints, and step-through execution into the everyday workflow.
Most of these concepts were already present in the earliest debuggers, as the 1966 survey by #cite(form: "prose", <evans66:on-line>) shows.

Since debugging takes up so much of a developer's time, it is not surprising that computer scientists have tried to automate it as soon as the first bugs were discovered @jacoby61:automation.
This led to a wide range of attempts to design _automatic debuggers_, which are designed to automatically find and fix bugs.
The term automatic debuggers has been used to describe both algorithmic debuggers @shapiro83:algorithmic, model checking, and tools for automatic fixing of bugs. // todo add cites
However, in this dissertation we are interested in the more traditional _manual debuggers_.

Let us highlight a few techniques here, to illustrate the evolution and variety of manual debuggers.

_Record-replay debuggers_ @agrawal91:execution-backtracking@feldman88:igor@ronsse99:recplay@boothe00:efficient@burg13:interactive@ocallahan17:engineering allow offline debugging with a checkpoint-based trace, and have been widely studied.
They have also been widely adopted in industry, with tools such as the RR framework @ocallahan17:engineering, which is one of the most advanced and widely used record-replay debugger to date.

_Omniscient debuggers_ @lewis03:debugging@pothier07:scalable takes this approach one step further, recording the entire execution of a program, allowing free offline exploration of the entire history, both backwards and forwards, and enabling advanced queries on causal relationships in the execution @pothier09:back.

Omniscient debuggers are sometimes confusingly referred to as _time-travel debuggers_, _back-in-time debuggers_, or _reversible debuggers_.
Unfortunately, these terms are not entirely interchangeable, as they can refer to very different techniques.
For instance, some record-replay debuggers allow for backwards stepping as well, and are referred to by the same terms @engblom12:review.

Around 2016, several tailored debuggers were proposed for _reactive programming_, which visualize the data flows in the reactive program @salvaneschi16:debugging @banken18:debugging.
This is part of a slow shift towards more domain-specific debuggers, which are tailored to specific programming paradigms, or specific problems.

Likewise, _out-of-place debuggers_ @marra18:out-of-place were proposed to reduce debugging interference in big data applications.
However, the technique is more widely applicable. In fact, it represents a new spectrum of debuggers that lie between remote and local debuggers, where a part of the remote debugging process is moved to a local process.
This can reduce debugging interference, or---as this dissertation will show---reduce the performance overhead of remote debugging @lauwaerts22:event-based-out-of-place-debugging.

Of course the shift towards domain-specific debuggers, in no way meant that new general-purpose debuggers were not developed.
A great example are _multiverse debuggers_ @torres19:multiverse, which emerged around the end of the last decade, as a powerful technique to debug non-deterministic program behavior.
As the name suggests, multiverse debuggers allow programmers to explore multiple execution paths simultaneously, i.e., the multiverse of a program's execution.

Yet, the start of this decade saw many new domain-specific debugger techniques.
For example, reversible debugging was recently adapted for _graphical programming languages_, by two projects for the Scratch language @maloney10:scratch-programming-language, Blink~@strijbol24:blink and NuzzleBug~@deiner24:nuzzlebug.

Only last year, a PhD thesis @whitington24:debugging presented a novel debugger solution for _functional programming_, which allows users to inspect the behavior of OCAML programs as they are interpreted.

Another recent trend in debugger research is to use static analysis or model checking techniques in conjunction with debuggers, such as the _abstract debugger_ by #cite(form: "prose", <holter24:abstract>) or the _symbolic debugger_ by #cite(form: "prose", <karmios23:symbolic>).

The list of debugging techniques and unique domains could go on for several more pages, and one could write a whole book about the history of debuggers.
However, we hope the overview above provides sufficient context to the reader for now.
In each following chapter, we will discuss the relevant related work in more detail, and highlight the differences with our own work.

== How developers debug

//While we have admitted that manual debugging is very difficult, and developers have a tendency to avoid it, one might wonder why we should even care about this kind of debugging.
//We argue that this is exactly why we should care.
//Improvements in programming languages, model checking, automatic debugging, intelligent code assistants, and other tools can only reduce the need for manual debugging, but never eliminate it---as they can never eliminate all bugs @larus09:foreword.

//=== The dirty little secret

Clearly, computer scientists recognized early on the potential of debuggers, not only for finding faults in programs, and helping to solve those faults---but also for understanding the programs themselves, and even for teaching and learning programming @licklider62:on-line.
During the following decades, debugging was proven to indeed help with all these aspects @steinert09:debugging @spinellis18:modern @wilkin25:debugging. // todo keep this sentence?

Still, debuggers have always remained somewhat in the shadows, with developers having a long tradition of avoiding debugging during software development.
Many researchers have tried to understand why debuggers are avoided so much, and unsurprisingly, the causes are varied.
The cognitive load of debugging is undeniable, and while it is by no means trivial to learn, few programmers are formally trained in debugging @mccauley08:debugging @perscheid17:studying.
Many programmers are overconfident in the correctness of their code @chattopadhyay22:cognitive, which leads to an unwillingness to examine their programs with the needed level of scrutiny @calikli10:analysis.
Laziness cannot be discounted either, as debuggers are often---perhaps rightly---perceived as hard to set up @beller18:on.
In many cases programmers feel it is not worth the time to use debuggers for those mistakes they perceive as small or easy to diagnose @mccauley08:debugging.

The unpopularity of debuggers among developers is not a new phenomenon.
The situation was famously criticized thirty years ago by Henry Lieberman in his introduction to the 1997 special issue of Communications of the ACM, entitled _"The Debugging Scandal and What to Do About It"_ with the words, _"Debugging is the dirty little secret of computer science"_ @lieberman97:debugging, lamenting not just the unpopularity of debuggers, but the lack of attention and improvement they had received.
Luckily, in the decades since, the research community has made tremendous strides.
Yet to a certain extent, the situation remains unchanged in practice---especially in the domain of embedded software, where debuggers are still laborious to set up and industry adoption of research advances continues to lag behind.

//Debugging is unavoidable, you might as well have good tools.

=== Debugging without debuggers

Even when programmers avoid debuggers, they do still debug their code.
Instead developers turn to print statement debugging @beller18:on, which is often seen as faster and easier at first, but can quickly lead to a slow and painful trial by error process.

Another interesting debugger-less debugging technique, is called _rubber duck debugging_, where programmers try and explain their code---possibly to a rubber duck---to help them understand the problem better @hunt99:pragmatic.

While not without merit, given the complexity of the debugging task, debugging without the use of debuggers is often far too cumbersome, and can only get you so far. // todo citation?
Especially, print statement debugging, despite its popularity, should be considered bad practice for any serious debugging task.
Even in the 1950s, computer systems already included breakpoints improving on print statement debugging by allowing programmers to debug live programs @smith58:design.
Since then, debuggers have come a long way.

=== Debugging with debuggers

Clearly not all errors, faults, or bugs can be found easily, let alone, be automatically detected and fixed.
Many bugs are unpredictable, non-deterministic, and only emerge under specific conditions.
This is especially true for software running on embedded systems, think of microcontrollers for hobbyist such as Arduino's, or internet-of-things devices, such as smart thermostats, and fitness trackers.
Here, bugs can be caused not just by pure mistakes in the programming logic, but also by unexpected interactions with the hardware, specific timings, or unexpected behavior from the physical world.
To track down the causes of such failures, we need direct access to the system’s behavior---to stop execution, inspect memory, and walk through the precise state transitions that led to failure.

This is what debuggers can give us.
They provide precise, and deterministic mechanisms for controlling and examining program execution, which is essential for diagnosing subtle bugs, concurrency issues, performance bottlenecks, and hardware-specific behavior.
Ongoing debugger research not only enhances these capabilities but also drives advances in program analysis, visualization, security, and education.

While automatic tools such as static analyzers, model checkers, and type systems can catch many classes of errors, they are limited by what they are designed to check. They work when you know the kinds of mistakes you’re guarding against. But when a system fails and you don’t know why, and have no predefined property to verify, you need debuggers that let you observe the system directly.

// todo some of the surveys on how programmers work could support:
// even when you detect an error automatically, often debugging is part of the process for fixing that mistake

/*
Despite the rapid rise of large language models (LLMs) in software engineering, debuggers remain critical for program understanding, and finding mistakes.
While LLMs can assist in debugging and code generation, they operate as probabilistic tools without direct connection to runtime state, offering suggestions rather than guarantees.

Debuggers, by contrast, are deterministic and precise, providing direct access to program execution and memory state.
In fact, since more and more code is generated probabilistically with LLMs, there is arguably an even greater need for deterministic and precise debugging tools to inspect the generated code.
*/

=== Debugging constrained devices

Debuggers are especially useful in the domain of embedded systems, where software interacts heavily with hardware, and the physical world.
These real-world interactions can lead to non-deterministic bugs that depend on specific input values, or other interactions with the environment.
In fact, device issues are one of the most common causes of bugs in embedded systems @makhshari21:iot-bugs.
Additionally, embedded software is often written in an _interrupt-driven_ manner, where the program is interrupted by hardware events, such as a timer or an external signal, and the program must respond to these events in real-time.
Such code can be difficult to debug, as the program's state may change unexpectedly due to hardware interrupts, and the timing of these events can be unpredictable.
//Additionally, concurrency bugs can depend on specific interleavings of events, making them difficult to reproduce and debug @li23:empirical-study.
Moreover, interrupt-driven code can lead to unpredictable concurrency bugs that depend on the order, interleaving, or timing of events, making them difficult to reproduce and diagnose @li23:empirical-study.

Unfortunately, debuggers for embedded software are often constrained by the very limitations of the hardware they target.
They typically rely on specialized hardware debugging interfaces, which can be difficult to configure and require additional---sometimes expensive---equipment.
This undoubtedly contributed to the fact that debuggers for embedded devices still lag behind advances in modern debugging techniques, offering only the most basic operations, often limited only to simple breakpoints, stepping forward, and inspecting local variables---techniques that have been around since the 1960s.
Consequently, debugging on embedded systems is frequently slow, cumbersome, and far less powerful than the tools available for general-purpose computing.

== Roadmap

There is a clear need for novel debugging techniques that can address the unique challenges of debugging embedded systems.
In this dissertation, we present a novel virtual machine for programming embedded devices, called _WARDuino_, on top of which we develop three novel debuggers for addressing the specific challenges of debugging embedded systems.

=== Challenges to debugging constrained devices

In each chapter of this dissertation we discuss the specific challenges we address, but there are four main challenges that span the entire dissertation.

#let C1 = [
/ C1: Embedded software development is characterized by a _slow development cycle_. //, partly because reflashing the device after each change is time-consuming, and setting up typical hardware debuggers is cumbersome.
]

#let C2 = [
/ C2: The _hardware limitations_ of embedded devices make it difficult to run debuggers alongside the target software. //traditional debuggers, and make advanced debugging techniques often infeasible.
]

#let C3 = [
/ C3: Typical _interrupt-driven programs_ interfere with the debugging process.
]

#let C4 = [
/ C4: Current embedded debuggers are not equipped to  _debug non-deterministic bugs_. //, yet they are common in embedded systems---but are hard to reproduce and examine using traditional techniques.
]

#C1

The slow development cycle has several causes, in the first place the need to reflash the device after each change can slow down the development cycle significantly---especially, when developers use print statements to debug their code.
Secondly, in case developers wish to use a debugger, they usually need to setup a hardware debugger, which can be cumbersome and time-consuming.
//Lesser challenges include the hardware limitations, bare-metal execution environments, bad portability of code over different devices, and the lack of high-level language support.
We will discuss these, and other lesser challenges underlying the slow development cycle in more detail in @chapter:remote.

#C2

Especially, limited memory and processing power are major concerns for embedded devices.
The resource constraints not only impact the embedded programs, but also any debugger stub that is run alongside it.

#C3

The debugging of interrupt-driven programs is challenging, since traditional debuggers no longer have full control over the flow of execution.
Specific interleaving executions of interrupts can cause concurrency bugs, which are difficult to reproduce and debug @li23:empirical-study.
More generally, arbitrary interrupts can trigger at any time, leading to non-deterministic behavior, and making it difficult to reproduce bugs.
#C4

Non-deterministic bugs are very common on embedded systems, but are notoriously difficult to debug, as they often depend on the specific timing or order of events, on very specific input, or environmental conditions.

=== Contributions //Novel techniques for debugging constrained devices

Our first contribution is a novel WebAssembly-based virtual machine for embedded devices, called _WARDuino_, which is designed to address the first challenge (*C1*).
We present the virtual machine in @chapter:remote, and show how it reduces the need to reflash software, and enables traditional remote debugging without the need to use a hardware debugger.
The chapter will discuss the virtual machine in great detail, both its implementation and the formal semantics of its remote debugger.
We shall highlight the components and design decisions that make WARDuino suitable as the basis for the novel debugging techniques we present in the following chapters.

To overcome the second challenge (*C2*), we adapted the new stateful out-of-place debugging technique, which allows us to run most of the debugger on a separate device, while still debugging the target device.
This reduces communication overhead and frees the debugger from the constraints of the target device.
@chapter:oop shows exactly how we adapted the out-of-place debugging technique to embedded devices, and discusses the prototype built on top of the WARDuino virtual machine.
As part of our research, we developed a novel out-of-place debugger that is able to handle stateful operations on non-transferable resources---a problem in out-of-place debugging that has not been addressed before.
This lead to a novel _stateful out-of-place_ debugger.

@chapter:oop likewise shows how our novel out-of-place debugger addresses the third challenge (*C3*), by capturing all asynchronous events, such as hardware interrupts, and allowing the debugger to control when these events are dispatched.

Another major contribution of our novel out-of-place debugger, is the introduction of the first formal model of the technique.
In @oop:soundness, we prove the soundness and completeness of our stateful out-of-place debugging technique, which shows that the debugger does not interfere with the behavior of the program, despite the execution being distributed over two devices, and controlling of asynchronous events.

Finally, the stateful out-of-place debugger already allows for some control over the order and timing of asynchronous events, however, it does not fully address the difficulties associated with non-deterministic bugs, in particular, those bugs caused by very specific conditions of the environment.

This shortcoming is addressed by our multiverse debugger for microcontrollers, _MIO_, which we present in @chap:multiverse.
The _MIO_ debugger presents the first multiverse debugger that works on a live execution of the program, and takes into account both input and output streams.
The technique is unique in another way, as it allows for the debugger to reverse the program's execution as it explores the multiverse, while remaining sound and complete.
Again, we prove the soundness and completeness of our multiverse debugger, particularly in @mult:correctness.

=== Open-source prototype and usability

A major goal throughout this research has been to develop usable prototypes of our novel debugging techniques.
Prototypes which can debug real-world embedded software, thereby showing the feasibility of our techniques, and increasing the changes of their adoption.
Towards this end, all our prototypes are open-source, and available on GitHub, alongside a dedicated documentation website.

No software can be considered usable---even as a prototype for other researchers---without proper testing.
Unfortunately, typical regression testing as part of continuous integrations, as is now standard practice, is not common in embedded software development.
Furthermore testing frameworks are rarely adapted for testing embedded software, and suffer from many of the same limitations as debuggers due to the resource constraints of the target devices.
Additionally, testing debuggers comes with its own challenges and specific requirements, not met by typical testing frameworks.

In other words, while developing our novel debugger prototypes, we increasingly found ourselves in need of a new, dedicated testing framework for embedded software.
Therefore, we developed our own testing framework for large-scale testing on constrained devices, called _Latch_, which implements a novel testing approach we call _managed testing_.
We will discuss this framework in detail at the end of the dissertation in @chapter:testing.

=== Structure of the dissertation

We have already summarized the contributions of this dissertation, and the chapters in which we discuss them.
However, before we dive into the details, we will first present the general formal framework we use throughout the dissertation in @chapter:foundations. We hope this will help the reader to better understand the formal proofs we present in the later chapters.
In the subsequent four chapters, we will discuss the main contributions, before concluding with a summary of the dissertation, and a discussion of future work in @chapter:conclusion.
