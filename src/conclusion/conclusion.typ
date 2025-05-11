#import "../introduction/introduction.typ": C1, C2, C3, C4
#import "../../lib/class.typ": note

This dissertation introduced three new ways of debugging embedded systems, based on a virtual machine approach with sound, and complete debugging semantics.
While we have discussed the conclusions for each of the contributions in their respective chapters, we now consider the bigger picture one last time.
In this final chapter, we sum up the overarching challenges we set out to address, and briefly summarize our contributions in relation to these challenges, and discuss possible future directions.

== Remote debugging for WebAssembly

#C1

Using the WebAssembly virtual machine approach implemented by WARDuino, and presented in @chapter:remote, we are able to provide developers with a series of new tools that can speed up the development process significantly.
Primarily, the remote debugger built on top of the WARDuino virtual machine eliminates the need to use laborious hardware debuggers, and provides partial over-the-air code updates to reduce the need for reflashing the entire software.
By using WebAssembly as the target language, developers can choose from a wide range of high-level languages to write their embedded software in. 
Additonally, we can leverage the existing tooling and ecosystem around WebAssembly to provide, for instance, easier ways to write emulators using existing web technology.
Finally, the portability of WebAssembly makes it much easier to support different platforms---making WARDuino programs much more portable than existing embedded software.

== Stateful out-of-place debugging

#C2

In order to overcome the hardware limitations of embedded devices, we found that it is possible to largely evade the constraints by moving the debugging session from the constrained device _(server)_ to a more powerful host machine _(client)_.
This corresponds to the out-of-place debugging approach, first developed for big data applications to reduce debugging interference.

We adapted out-of-place debugging to work on the embedded devices, and presented a novel out-of-place debugger for WebAssembly programs running on embedded devices.
Any non-transferable resources of the original constrained device, such as sensors and actuators, can still be accessed during the debugging session, to provide the illusion of remote debugging.
Such non-transferable resources can have both stateless and stateful natures, and access to them can be both synchronous and asynchronous.
In our novel out-of-place solution, we are the first to address all of these aspects/* of non-transferable resources, and provide a clear formalization of our approach---in order to help other researchers apply our techniques to their own debugging problems, and application domains*/---leading to what we call _stateful out-of-place debugging_.

Our stateful out-of-place debugger solves another crucial problem for embedded systems debugging.

#C3

Embedded software is generally written in an _interrupt-driven_ style, which means that execution flow during online debugging can be arbitrarily interrupted and diverted.
This makes it very difficult to debug the such program.

Our stateful out-of-place debugger, captures all asynchronous events on the remote constrained device, and forwards them to the local _client_ debugger without triggering them.
This means that debugging sessions are no longer arbitrarily interrupted by asynchronous events, but our stateful out-of-place debugger is not just able to capture and forward asynchronous resources.
The debugger also provides developers with some control over the asynchronicity.
On the _client_ side, developers can choose when to trigger the asynchronous events, allowing them some control over their order and timing within the program.

Our formalization of stateful out-of-place debugging, is the first formalization of out-of-place debugging, and is not limited to embedded systems.
Because of the generality of this problem, and of our solution; we hope in future work to formalize the approach in a more fundamental way, by using a more general underlying language model, such as CEK machines @felleisen86:control.
However, our formalization is already quite general, and includes very little WebAssembly specific aspects.

== Multiverse debugging for microcontrollers

#C4

In @chap:multiverse, we presented the first multiverse debugger designed for microcontrollers, called _MIO_, addressing the challenge of non-deterministic bugs caused by unpredictable I/O.
Unlike prior approaches limited to abstract settings, our debugger integrates with a full WebAssembly virtual machine and supports a range of concrete I/O primitives—including sensors, pins, and motors—while maintaining formal soundness.

Our online multiverse debugger allows developers to freely navigate the multiverse of possible execution paths, without the need for a full program replay.
Interactions with the external environment are automatically reversed and replayed as needed by the debugger, enabling developers to explore the impact of I/O operations on program behavior without worrying about interference from the debugger.

Of course, since we work with a real-world environment, we cannot guarantee that the debugger will be able to reverse all I/O operations correctly.
However, we can guarantee that the debugger will reverse the I/O actions support by the virtual machine.
These I/O actions are designed to be _deterministically compensable_ by the virtual machine, meaning that the virtual machine can always reverse them.

Our formal model of the _MIO_ debugger allows us to clearly show exactly how actions are reversed, and to proof that our debugger is still sound a complete even when reversing action, or sliding to new universes.

By introducing a sparse snapshotting strategy, we achieve practical performance on resource-constrained devices.
This work demonstrates that multiverse debugging can work as an online debugger, and be made viable for real-world embedded systems.

== Managed testing

Our novel testing framework _Latch_ uses a similar principle as out-of-place debugging to run large suites of tests on the constrained hardware itself.
Coupled with our novel managed testing approach, which allows developers to integration test their embedded software through more realistic scenarios, we are able to provide a considerably better way of testing embedded software.

== Soundness and completeness of debuggers

// different levels of soundness : for isntance sound when considering timings is not really possible online, but some offline debuggers could have "timing soundness"

The debuggers that are the subject of this dissertation are all manual online debuggers, for which we define soundness as the property that the debugger observes all possible behavior of the program being debugged, and does not deviate from it.

Like many conventional debuggers, our remote debugger---while complete---is not sound, since it can update the code of the program being debugged during the debugging session.
However, we without the live code updates, we were able to prove soundness for the remote debugging.
Through significant efforts we were likewise able to design an entirely new class of out-of-place and multiverse debuggers, which are both sound and complete.
This gives developers greater confidence in the reliability of their observations, especially when debugging non-deterministic bugs.

The formal soundness of our debuggers is necessarily limited to certain assumptions, since we can never fully eliminate the probe effect of online debuggers, or discount the possible noise of the real-world environment in which embedded devices operate.
In the case of our multiverse debugger, we assume in the formalization that I/O operations do not influence each other. In the implementation we have some early support for defining predictable dependencies between I/O operations, but this is not yet formalized.
An interesting future direction would be to extend our formalization to capture more of the possible dependencies between I/O operations, and to provide a formal soundness proof for this extended model.
// todo In fact, we have already made a first step in this direction using concolic execution#note[This work is currently under submission at the Onward! conference.], which can allow us to 

Similarly for the stateful out-of-place debugger, we assume that there is a known partial order of the possible asynchronous events of a program.
This is a reasonable assumption for many programs, but does present a very naive model.
Extending this model to capture more of the possible dependencies between asynchronous events, perhaps even to capture certain timing aspects, is a very useful future direction.
There is quite some work on causal consistency and environment modeling which could help us here.

Finally, while we believe _completeness_ and _soundness_ encompass the most fundamental expectation of debugger operations---that they do not interfere with the program's execution---there are many other aspects of debuggers that are important to consider.
In future work, we hope that different aspects can be examined and formalized in a similar way.

