#import "../../lib/class.typ": note, definition
// todo the very first sentence should say something about bugs

As surely as computers will continue to run software, so will software continue to have bugs and mistakes.
That’s not pessimism; it’s reality. After all we live in an imperfect world.
No formal method, nor static checker, or machine learning model can ever eliminate all mistakes---especially, for software which interacts with this imperfect, and unpredictable world.
This is where debuggers---inevitably---come in.

== The nature of programming mistakes

Programming mistakes come in many forms, and have many causes @mccauley08:debugging.
Some are simple syntax errors or off-by-one mistakes that static or model checkers can easily catch @garcia-ferreira14:survey.
Others have deep, and complex causes such as timing issues in concurrent systems @lu08:learning @li23:empirical-study, memory corruption from hardware quirks @schroeder09:dram @dessouky18:when @bojanova21:classifying, non-deterministic edge cases triggered only under rare input conditions @weiss21:understanding, and so forth @catolino19:not.
Crucially, many real-world bugs are not predictable or even known in advance @mogul06:emergent @ubayashi19:when.
We often do not know what class of bug we are hunting until we start looking.

This is why automated verification @dsilva08:survey @rodriguez19:software, however powerful, has limits. Formal proofs and model checking work only when the system and its requirements can be fully specified and the relevant properties articulated.
But most software systems today are too large, too dependent on external environments, or too hastily evolving for perfect formalization.
Many mistakes arise precisely where models stop: at the interfaces, in the messy real-world details, or in emergent behaviors no one thought to check. In these cases, the only path forward is empirical investigation.
This almost exclusively involves inspecting program execution with debuggers, where developers trace the steps that led to the failure.
//That is what debuggers make possible.

This kind of empirical investigation is what we call _"debugging"_, and was best described by Andreas Zeller in his definitive guide, _"Why Programs Fail: A Guide to Systematic Debugging"_ @zeller05:why, which provides a thorough overview of debugging as a part of software development, describes a scientific approach to isolating bugs, and discusses best practices, common tools, and novel techniques.

We would like to start with a brief history of debugging.

== The history of debugging  // we talk about debugging since we see it broadly (also print statements)

Debugging has been central to programming since the earliest days of computer science. The term itself is often traced to _Grace Hopper’s famous 'bug' story_ from 1947#note[Actually, the term _bug_ was already used to refer to a fault in a machine in the late nineteenth century @wills22:bug.], when a literal moth was found shorting a relay in the Harvard Mark II computer @cohen94:use.

No history of debugging is complete without also mentioning Maurice Wilkes' famous anecdote, describing the first time he experienced a need for debugging back in 1949: _"As soon as we started programming, [...] we found to our surprise that it wasn’t as easy to get programs right as we had thought it would be. [...] Debugging had to be discovered. I can remember the exact instant [...] when I realized that a large part of my life from then on was going to be spent in finding mistakes in my own programs."_ @wilkes79:birth @spinellis18:modern
The term _debugging_ came into circulation shortly after Wilkes famous encounter. //, and continues to be an integral part of programming today.
From that point on, debuggers evolved alongside programming languages and computer systems, from the early days of assembly language and punch cards to the high-level languages we use today.
And Wilkes' description still sums up the need for debugging perfectly today.

=== The dirty little secret

Clearly, computer scientists recognized early on the potential of debuggers, not only for finding faults in programs, and helping to solve those faults---but also for understanding the programs themselves, and even for teaching and learning programming @licklider62:on-line.
And certainly, during the following decades, debugging was proven to indeed help with all these aspects @steinert09:debugging @spinellis18:modern @wilkin25:debugging. // todo keep this sentence?

Still, debuggers have always remained somewhat in the shadows, with developers having a long tradition of avoiding debugging during software development.
Many researchers have tried to understand why debuggers are avoided so much, and unsurprisingly, the causes are varied.
The cognitive load of debugging is undeniable, and while it is by no means trivial to learn, few programmers are formally trained in debugging @mccauley08:debugging @beller18:on.
Many programmers are overconfident in the correctness of their code @chattopadhyay22:cognitive, which leads to an unwillingness to examine their programs with the needed level of scrutiny.
Laziness cannot be discounted either, as debuggers are often---perhaps rightly---perceived as hard to set up.
In many cases programmers feel it is not worth the time to use debuggers for mistakes---they perceive as small or easy to diagnose @mccauley08:debugging.

The unpopularity of debuggers under developers is not a new phenomenon.
This situation was famously criticized thirty years ago by Henry Lieberman in his introduction to the 1997 special issue of Communications of the ACM, entitled _"The Debugging Scandal and What to Do About It"_ with the words, _"Debugging is the dirty little secret of computer science"_ @lieberman97:debugging, lamenting not just the unpopularity of debuggers, but the lack of attention and improvement they had received.
Luckily, in the decades since, the research community has made tremendous strides.
Yet to a certain extent, the situation remains unchanged in practice---especially in the domain of embedded software, where debuggers are still laborious to set up and industry adoption of research advances continues to lag behind.

=== A steady evolution

While debugging may remain the dirty little secret of software development to some extent, it is no longer so in the scientific community.
The literature on debugging is vast, from proposals of novel debugging techniques, to studies on the cognitive aspects of debugging @perscheid17:studying @beller18:on.

During the early days of computer programming in the 1950s, most debugging was necessarily done with print statements, added to the punch cards used in those days @backus57:fortran.
One of the first improvements on this system, was to add new macros specific for debugging, which help improve traces of the program, such as those added in the _share_ operating system for the IBM 709 @hanford60:share.
These kind of macros can be considered the first iterations of so called _offline debuggers_, or often _post-mortem debuggers_, which are debuggers used to analyze a program after it has crashed or terminated, usually through traces of the program's execution.

During the same decade, the first _online debuggers_ were developed as well, which in contrast enable interactive inspection, control, and modification of a program’s execution state while the program is running.
One of the earliest examples is the RCA 501 system @smith58:design, which included six breakpoint switches, and a paper tape reader and monitor printer for debugging.
Of course computers have changed dramatically since the 1950s, and the days of magnetic tapes are long gone, however, the debugging tools of the RCA 501 system are very similar to the core debug operations present in most modern debuggers today.
A clear illustration of how slow adoption of new debugging techniques has been.

//While debugging is still seen as hard, and something to avoid if possible, by many programmers, not all is doom and gloom.
//The current knowledge and practice of debugging can still be lamented, but over the last few decades, we have seen some improvements, and increased interested in understanding debugging and debuggers.

The introduction of integrated development environments (IDEs) certainly helped to popularize online debuggers, and brought breakpoints, watchpoints, and step-through execution into the everyday workflow.
Most of these concepts were already present in the earliest debuggers, as the 1966 survey by #cite(form: "prose", <evans66:on-line>) shows.

However, the term debugger has always been interpreted broadly, and many tools have been developed to find faults in programs.
One wildly different class of debuggers, are _automatic debuggers_, which are designed to automatically find and fix bugs.
Since debugging is such a detested task, it is not surprising that computer scientists have tried to automate it as soon as the first bugs were discovered @jacoby61:automation.
The term automatic debuggers has been used to describe both algorithmic debuggers @shapiro83:algorithmic, model checking, and tools for automatic fixing of bugs. // todo add cites
However, in this dissertation we are interested in the more traditional _manual debuggers_.

From the 1990s onwards, the focus of debugging research shifted towards more advanced techniques for debugging complex systems, and many new types of debuggers were developed.
Let us highlight a few techniques here.

_Record-replay debuggers_ @agrawal91:execution-backtracking@feldman88:igor@ronsse99:recplay@boothe00:efficient@burg13:interactive@ocallahan17:engineering allow offline debugging with a checkpoint-based trace, and have been widely studied.
They have also been widely adopted in industry, with tools such as the RR framework @ocallahan17:engineering, which is one of the most advanced and widely used record-replay debugger to date.

_Omniscient debuggers_ @lewis03:debugging@pothier07:scalable takes this approach one step further, recording the entire execution of a program, allowing free offline exploration of the entire history, both backwards and forwards, and enabling advanced queries on causal relationships in the execution @pothier09:back.

Omniscient debuggers are sometimes referred to as _time-travel debuggers_, _back-in-time debuggers_, or _reversible debuggers_.
However, some record-replay debuggers allow for backwards stepping as well, and are referred to by the same terms.
A large number of _reversible debuggers_ fall in neither category, such as online debuggers that use _reversible programming languages_ to step backwards @giachino14:causal-consistent-reversible-debugging@lanese18:cauder@lanese18:from.

_Out-of-place debuggers_ are a novel class of debuggers that lies between remote and local debuggers, where a part of the remote debugging process is moved to a local process, which can reduce debugging interference or reduce the performance overhead of remote debugging @marra18:out-of-place@lauwaerts22:event-based-out-of-place-debugging.

_Multiverse debuggers_ @torres19:multiverse emerged as a powerful technique to debug non-deterministic program behavior, by allowing programmers to explore multiple execution paths simultaneously.

Many debuggers have been developed to debug very specific domains, such as _reactive programming_ where several tailored debuggers have been proposed, which visualize the data flows in the reactive program @salvaneschi16:debugging @banken18:debugging.

Similarly, a recent PhD thesis @whitington24:debugging presented a novel debugger solution for _functional programming_, which allows users to inspect the behavior of OCAML programs as they are interpreted.

Reversible debugging was very recently adapted for _graphical programming languages_, by two projects for the Scratch language @maloney10:scratch-programming-language, Blink~@strijbol24:blink and NuzzleBug~@deiner24:nuzzlebug.


One of the most recent trends in debugger research, is to use static analysis or model checking techniques in conjunction with debuggers, such as the _abstract debugger_ by #cite(form: "prose", <holter24:abstract>) or the _symbolic debugger_ by #cite(form: "prose", <karmios23:symbolic>).

The list of debugging techniques and unique domains could go on for several more pages.

== What are debuggers?

As the history of debugging shows, the term debugger is fluid and has been used to refer to a wide range of tools and techniques.
Over time, many different categories of debuggers have emerged—often with overlapping features and even different names for similar concepts.
This diffuseness suggests that we may never arrive at a single, universally accepted definition of a debugger.

For the purpose of this work, we define a debugger as follows.

#definition("Debugger")[
A debugger is a tool that enables developers to deterministically observe a program's execution, monitor its state, and control the flow of execution.
]

By this definition, we exclude automatic debugging, but include a whole range of manual debugging tools, from offline to online debuggers, from remote to local debuggers, from omniscient to reversible debuggers, and so forth.

//=== Debuggers in all shapes and sizes

== Why debuggers matter

While we have admitted that manual debugging is very difficult, and developers have a tendency to avoid it, one might wonder why we should even care about this kind of debugging.
We argue that this is exactly why we should care.
Improvements in programming languages, model checking, automatic debugging, intelligent code assistants, and other tools can only reduce the need for manual debugging, but never eliminate it---as they can never eliminate all bugs @larus09:foreword.
Debugging is unavoidable, you might as well have good tools.

=== Debugging without debuggers

Even when programmers avoid debuggers, they do still debug their code.
Instead developers turn to print statement debugging, which is often seen as faster and easier at first, but can quickly lead to a slow and painful trial by error process.

Another interesting debugger-less debugging technique, is called _rubber duck debugging_, where programmers try and explain their code---possibly to a rubber duck---to help them understand the problem better @hunt99:pragmatic.

While not without merit, given the complexity of the debugging task, debugging without the use of debuggers is often far too cumbersome, and can only get you so far. // todo citation?
Especially, print statement debugging, despite its popularity, should be considered bad practice for any serious debugging task.
Even in the 1950s, computer systems already included breakpoints improving on print statement debugging by allowing programmers to debug live programs @smith58:design.
Since then, debuggers have come a long way.

=== Debugging with debuggers

Clearly not all errors, faults, or bugs can be found easily, let alone, automatically detected and fixed.
Many bugs are unpredictable, non-deterministic, and only emerge under specific conditions.
This is especially true for software running on embedded systems, think of microcontrollers for hobbyist such as Arduino's, or internet-of-things devices, such as smart thermostats, and fitness trackers.
Here, bugs can be caused not just by pure mistakes in the programming logic, but also by unexpected interactions with the hardware, specific timings, or unexpected behavior from the physical world.
To track down the causes of such failures, we need direct access to the system’s behavior---to stop execution, inspect memory, and walk through the precise state transitions that led to failure.

This is what debuggers can give us.
They provide precise, and deterministic mechanisms for controlling and examining program execution, essential for diagnosing subtle bugs, concurrency issues, performance bottlenecks, and hardware-specific behavior.

While automatic tools such as static analyzers, model checkers, and type systems can catch many classes of errors, they are limited by what they are designed to check. They work when you know the kinds of mistakes you’re guarding against. But when a system fails and you don’t know why, and have no predefined property to verify, you need debuggers that let you observe the system directly.

// todo some of the surveys on how programmers work could support:
// even when you detect an error automatically, often debugging is part of the process for fixing that mistake

Despite the rapid rise of large language models (LLMs) in software engineering, debuggers remain critical for program understanding, and finding mistakes.
While LLMs can assist in debugging and code generation, they operate as probabilistic tools without direct connection to runtime state, offering suggestions rather than guarantees.

Debuggers, by contrast, are deterministic and precise, providing direct access to program execution and memory state.
Ongoing debugger research not only enhances these capabilities but also drives advances in program analysis, visualization, security, and education.
In fact, since more and more code is generated probabilistically with LLMs, there is arguably an even greater need for deterministic and precise debugging tools to inspect the generated code.

=== Debugging constrained devices

Debuggers are especially useful in the domain of embedded systems, where software interacts heavily with hardware, and the physical world.
These real-world interactions can lead to non-deterministic bugs that depend on specific input values, or other interactions with the environment.
Additionally, embedded software is often written in an _interrupt-driven_ manner, where the program is interrupted by hardware events, such as a timer or an external signal, and the program must respond to these events in real-time.
Such code can be difficult to debug, as the program's state may change unexpectedly due to hardware interrupts, and the timing of these events can be unpredictable.
Moreover, interrupt-driven code can lead to unpredictable bugs that depend on the order or timing of events, making them difficult to reproduce and diagnose.

Unfortunately, debuggers for embedded software are often constrained by the very limitations of the hardware they target.
They typically rely on specialized hardware debugging interfaces, which can be difficult to configure and require additional---sometimes expensive---equipment.
This undoubtedly contributed to the fact that debuggers for embedded devices still lag behind advances in modern debugging techniques, offering only the most basic operations, often limited only to simple breakpoints, stepping forward, and inspecting local variables---techniques that have been around since the 1960s.
Consequently, debugging on embedded systems is frequently slow, cumbersome, and far less powerful than the tools available for general-purpose computing.

== The need for novel debugging techniques

There is a clear need for novel debugging techniques that can address the unique challenges of debugging embedded systems.
In this dissertation, we present a novel virtual machine for programming embedded devices, called _WARDuino_, on top of which we develop three novel debuggers for addressing the specific challenges of debugging embedded systems.

=== Challenges to debugging constrained devices

In each chapter of this dissertation we discuss the specific challenges we address, however, there are four main challenges that over
These challenges can be split into four main categories.

#let C1 = [
/ C1: Embedded software development is characterized by a _slow development cycle_. //, partly because reflashing the device after each change is time-consuming, and setting up typical hardware debuggers is cumbersome.
]

#let C2 = [
/ C2: The _hardware limitations_ of embedded devices, make it difficult to run debuggers alongside the target software. //traditional debuggers, and make advanced debugging techniques often infeasible.
]

#let C3 = [
/ C3: Typical _interrupt-driven programs_ interfere with the debugging process.
]

#let C4 = [
/ C4: Current embedded debuggers are not equipped to  _debug non-deterministic bugs_. //, yet they are common in embedded systems---but are hard to reproduce and examine using traditional techniques.
]

#C1

The slow development cycle has several causes, in the first place the need to reflash the device after each change can slow down the development cycle significantly---especially, when developers use print statements to debug their code.
Unfortunately, in case developers wish to use a debugger, they usually need to setup a hardware debugger, which can be cumbersome and time-consuming.
Lesser challenges include the hardware limitations, bare-metal execution environments, bad portability of code over different devices, and the lack of high-level language support.
We will discuss these challenges in more detail in @chapter:remote.

#C2

Especially, limited memory and processing power are a major concern for embedded devices.
The resource constraints not only impact the embedded programs, but also any debugger stub that is run alongside it.

#C3

The debugging of interrupt-driven programs is challenging, since traditional debuggers no longer have full control over the flow of execution.
Arbitrary interrupts can trigger at any time, leading to non-deterministic behavior and making it difficult to reproduce bugs.

#C4

Non-deterministic bugs are very common on embedded systems, but are notoriously difficult to debug, as they often depend on specific timing or order of events, or on very specific input, or environmental conditions.

=== Novel techniques for debugging constrained devices

To address the first challenge, we developed the WARDuino virtual machine, to reduce the need to reflash software, and to enable traditional remote debugging without the need to use a hardware debugger.

To overcome the second challenge, we adapted the novel out-of-place debugging technique, which allows us to run most of the debugger on a separate device, while still debugging the target device.
This reduces communication overhead and frees the debugger from the constraints of the target device.

Our novel out-of-place debugger further address the third challenge, by capturing all asynchronous events, such as hardware interrupts, and allowing the debugger to control when these events are dispatched.
Another major contribution of our novel out-of-place debugger, is the introduction of the first formal model of the technique, and sound support for stateful operations on non-transferable resources---a problem in out-of-place debugging that has not been addressed before.

Finally, we address the fourth challenge by adopting the multiverse debugging technique to microcontrollers. Our prototype is the first multiverse debugger that considers input and output streams, and works on a live program rather than a model of the execution.

== Open-source prototype and usability

A major goal throughout this research has been to develop usable prototypes of our novel debugging techniques, which can in fact be used to debug real-world embedded software.
This is important for showing the feasibility of our techniques, and to increase the changes of their adoption in practice.
Towards this end, all our prototypes are open-source, and available on GitHub, along side a dedicated documentation website.

No software can be considered usable---even as a prototype for other researchers---without proper testing.
Unfortunately, typical regression testing as part of continuous integrations, as is now standard practice, is not common in embedded software development.
Furthermore testing frameworks are rarely adapted for testing embedded software, and suffer from many of the same limitations as debuggers due to the resource constraints of the target devices.
Additionally, testing debuggers comes with its own challenges and specific requirements, not met by typical testing frameworks.

In other words, while developing our novel debugger prototypes, we increasingly found ourselves in need of a new, dedicated testing framework for embedded software.
Therefore, we developed our own testing framework for large-scale testing on constrained devices, called _Latch_, which implements a novel testing approach we call _managed testing_.
We will discuss this framework in detail at the end of the dissertation.

== Why foundations matter

A large part of this dissertation is dedicated to defining the formal models of our novel debugging techniques, and proving their soundness.

The importance of formal foundations is well established in other domains of computer science.
Debugging, despite its centrality to programming, has not benefited from the same level of formal attention.
Although a formal foundation for debugging techniques is undeniably useful. //essential to advancing our understanding and practice of debugging.
Just as formal semantics for programming languages have enabled precise reasoning about program behavior, a principled understanding of debuggers can provide clearer insight into novel debugging techniques, and allow for more principled comparisons of different approaches.
//Establishing formal foundations for debugging not only enhances tool development but also supports deeper theoretical insights, reproducibility, and the integration of debugging with other formal methods in software engineering.
//Without such foundations, debugging remains largely ad hoc---guided by experience, intuition, and trial-and-error---making it difficult to assess the correctness, completeness, or generality of debugging strategies.
//A formal framework allows us to characterize debugging operations, reason about their soundness, and systematically compare different approaches.

To emphasize the importance of formal foundations and to help readers navigate the following chapters, we begin with a brief discussion of our formal framework for debugging in @chapter:foundations.

//== The promise of universal bytecode interpreters

== Organization of the dissertation

After our introduction of the formal framework used throughout this dissertation in @chapter:foundations, we present our first contribution, the WARDuino virtual machine and its remote debugger, in @chapter:remote.
The chapter will introduce the virtual machine in great detail, and highlight the components and design decisions that makes is suitable for the novel debugging techniques we present in the following chapters.
@chapter:oop shows how we adapt the out-of-place debugging technique to embedded systems, and presents our novel out-of-place debugger built on top of the WARDuino virtual machine.
The stateful out-of-place debugger already allows for some control over the order and timing of asynchronous events, however, it does not fully address the difficulties associated with non-deterministic bugs, in particular, those bugs caused by very specific conditions of the environment.
This is addressed by our multiverse debugger for microcontrollers, _MIO_, which we present in @chap:multiverse.
The _MIO_ debugger presents the first multiverse debugger that works on a live execution of the program, and takes into account both input and output streams.
In @chapter:testing, we present the novel testing framework we developed for testing our debuggers, called _Latch_.
Finally, we will conclude with some final thoughts on the contributions of this dissertation, and discuss future work in @chapter:conclusion.

