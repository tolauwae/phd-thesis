#import "../../lib/environments.typ": note
#import "../introduction/introduction.typ": C0, C1, C2, C3, C4, C5, C6

= Lay summary

Writing programs is hard, and developers are bound to make mistakes, which we call _bugs_ in computer science.
The work of finding these bugs/*, _debugging_*/, takes up a lot of a developer's time.
Unfortunately, the tools that should help them with this task, debuggers,  are often quite antiquated in practice#note[_"Antiquated"_ is the right word as breakpoints were invented in the sixties.].
This is especially true for _constrained devices_, or embedded devices, which are small computers that are often used for internet of things applications, such as your smart thermostat, fitness tracker, Wi-Fi lights, and so on.

There is a clear need for better debugging tools in embedded software development.
However, the nature of the targeted devices poses several tough hurdles that stand in the way of more advanced debugging techniques.
These obstacles can be split into seven main challenges.

#C0

#C1

#C6

#C2

#C3

#C4

#C5

Currently, developers of embedded devices use two inefficient debugging techniques, which are not well equipped to handle the challenges of debugging constrained devices.

First, developers use _print statement debugging_, where they insert print statements in their code to print out information at certain points in the program.
This way they can try and infer information about the program's execution after it has run.
This leads to a slow iterative process of adding and removing print statements, recompiling, re-uploading, and rerunning the software.

Second, developers can try and setup a hardware debugger, which is an additional piece of hardware that connects to the embedded device---enabling the inspection of the program state.
However, these hardware debuggers are often expensive, and difficult to set up.
Moreover, the software tools, specifically _remote debuggers_, that use them only support the most basic debug operations.

In this dissertation, we propose several new debugging techniques that are specifically designed to overcome these challenges, and hopefully pave the way to an even wider variety of advanced, and better debugging techniques.

Our first contribution, is a new virtual machine-based approach to remote debugging embedded devices, rather than hardware-based.
We developed a WebAssembly-based virtual machine, called WARDuino, that runs on the embedded device.
It allows developers to program their devices in high-level languages, such as JavaScript, Python, and Rust, and to use a remote debugger without the need for hardware debuggers.

Our second contribution, builds on top of the first, by adding a new debugging technique called _stateful out-of-place debugging_.
The technique moves most of the debugging session from the embedded device _(server)_ to the developer's computer _(client)_, where they can use the full range of compute power available to modern computers.
This allows debuggers to evade the constraints of the embedded device, and to use advanced debugging techniques.
However, the technique still maintains access to the hardware-specific features of the embedded device, providing the illusion of remote debugging.

The stateful out-of-place debugger also addresses the fourth and fifth challenge, by capturing all asynchronous events, such as hardware interrupts, and forwarding them to the client.
Here, the events do not automatically interrupt the program's execution, instead the developer can use the debugger to trigger events at a moment of their choice.
This prevents the confusion that can arise when the debugging session is interrupted and diverted by hardware interrupts, and gives developers more tools for recreating specific interleavings of event or other conditions that give rise to the bugs they are hunting.

The sixth and seventh challenge are addressed by our third contribution, and final debugger called _MIO_, a multiverse debugger for input and output programs on constrained devices.
Multiverse debugging makes it easier to debug non-deterministic programs by allowing developers to explore all potential execution paths.
Unfortunately, debugging programs that involve input/output operations using existing multiverse debuggers can reveal inaccessible program states, i.e., states which are not encountered during regular execution.
This can significantly hinder the debugging process, as the programmer may spend substantial time exploring and examining inaccessible program states, or worse, may mistakenly assume a bug is present in the code, when in fact, the issue is caused by the debugger.
To solve this, MIO presents a novel approach to multiverse debugging, which can accommodate a broad spectrum of input/output operations---and reverse them as necessary while exploring the multiverse of execution paths.

Our fourth contribution is a new testing framework called _Latch_, for testing embedded devices, and in particular the debuggers developed in this dissertation.
First, the framework implements a novel test approach, we call _managed testing_, which uses a debugger to run automated test scenarios on the embedded device--similar to manual test scenarios that developers would typically run on the hardware themselves.
Second, _Latch_ uses the same principle behind _stateful out-of-place debugging_ to run large test suites on embedded devices.

