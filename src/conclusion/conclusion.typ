#import "../introduction/introduction.typ": C1, C2, C3, C4

This dissertation introduced several new ways of debugging embedded systems, based on a virtual machine approach and sound debugging semantics.
While we have discussed the conclusions we draw for each of the contributions in their respective chapters, we now consider the bigger picture one last time.
In this final chapter, we sum up again the overarching challenges we set out to address, and briefly summarize our contributions in relation to these challenges, and discuss future directions for each segment.

== Remote debugging for WebAssembly

#C1

Using the WebAssembly virtual machine approach implemented by WARDuino, and presented in @chapter:remote, we are able to provide developers with a series of new tools that can speed up the development process significantly.
Primarily, the remote debugger built on top of the WARDuino virtual machine eliminates the need to use laborious hardware debuggers, and provides partial over-the-air code updates to reduce the need for reflashing the entire software.
By using WebAssembly as the target language, developers can choose from a wide range of high-level languages to write their embedded software in. 
Additonally, we can leverage the existing tooling and ecosystem around WebAssembly to provide for instance an easy way to write emulators for your software.
Finally, the portability of WebAssembly makes it much easier to support on different platforms.

== Stateful out-of-place debugging

Our stateful out-of-place debugger solves two crucial problems for embedded systems debugging, however, its formalization and handling of stateful operations are important general improvements on out-of-place debugging, regardless of the application domain.
These general improvements are of course particularly useful in the context of embedded systems.

#C2

Out-of-place debugging allows debuggers to evade much of the hardware limitations imposed by embedded devices, by moving the debugging session from the constrained device to a more powerful host machine.
Any non-transferable aspects of the original constrained device can still be accessed during the debugging session, to provide the illusion of remote debugging.
Such non-transferable resources can have both stateless and stateful natures, and access to them can be both synchronous and asynchronous.
In our novel out-of-place solution, we are the first to address all of these aspects of non-transferable resources, and provide a clear formalization of our approach---in order to help other researchers apply our techniques to their own debugging problems, and application domains.

#C3

Our out-of-place debugger is not only able to handle asynchronous resources, but also to provide developers with control over this asynchronicity.
The debugger captures all asynchronous events on the remote constrained device, and forwards them to the local _client_ debugger.
On the _client_ side, developers can choose when to trigger the asynchronous events, allowing them some control over their order and timing within the program.
Most importantly, debugging sessions cannot be arbitrarily interrupted by asynchronous events, which is a common problem with existing debugging solutions.

== Multiverse debugging for microcontrollers

#C4

We present the first multiverse debugger designed for microcontrollers, addressing the challenge of non-deterministic bugs caused by unpredictable I/O.
Unlike prior approaches limited to abstract settings, our debugger integrates seamlessly with a full WebAssembly virtual machine and supports a range of concrete I/O primitives—including sensors, pins, and motors—while maintaining formal soundness.
By introducing a sparse snapshotting strategy, we achieve practical performance on resource-constrained devices.
This work demonstrates that multiverse debugging can be made viable for real-world embedded systems, laying the groundwork for supporting even more complex I/O dependencies in the future.

== Managed testing

Our novel testing framework _Latch_ uses a similar principle as out-of-place debugging to run large suites of tests on the constrained hardware itself.
Coupled with our novel managed testing approach, which allows developers to integration test their embedded software through more realistic scenarios, we are able to provide a considerably better way of testing embedded software.

== Soundness of debuggers

// different levels of soundness : for isntance sound when considering timings is not really possible online, but some offline debuggers could have "timing soundness"

The debuggers that are the subject of this dissertation are all manual online debuggers, for which we define soundness as the property that the debugger's observations observes all possible behavior of the program being debugged, and does not deviate from it.

Like many conventional debuggers, our remote debugger is not sound, since it can update the code of the program being debugged during the debugging session.
However, through significant efforts we were able to provide an entirely new class of out-of-place and multiverse debuggers, which are both sound.
This gives developers greater confidence in the reliability of their observations, especially when debugging non-deterministic bugs.


The formal soundness of our debuggers is necessarily limited to certain assumptions, since we can never fully eliminate the probe effect of online debuggers, or discount the infinite possibilities of the real-world environment in which embedded devices operate.
In the case of our multiverse debugger, we assume in the formalization that I/O operations do not influence each other. In the implementation we have some early support for defining predictable dependencies between I/O operations, but this is not yet formalized.
An interesting future direction would be to extend our formalization to capture more of the possible dependencies between I/O operations, and to provide a formal soundness proof for this extended model.

Similarly for the stateful out-of-place debugger, we assume that there is a known partial order of the possible asynchronous events of a program.
This is a reasonable assumption for many programs, but does present a very naive model.
Extending this model to capture more of the possible dependencies between asynchronous events, perhaps even to capture certain timing aspects, is a very useful future direction.
There is quite some work on causal consistency and environment modeling which could help us here.

