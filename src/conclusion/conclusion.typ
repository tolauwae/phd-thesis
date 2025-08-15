#import "../introduction/introduction.typ": C1, C2, C3, C4, C5, C6, C7
#import "../../lib/environments.typ": note

This dissertation introduced three new ways of debugging embedded systems, based on a virtual machine approach with sound, and complete debugging semantics.
However, the dissertation had a wider purpose, to examine how to design debuggers well, and how to apply these techniques under tight constraints.
While we have discussed the conclusions for each of the contributions in their respective chapters, we now consider the bigger picture one last time and look back at the journey taken in this dissertation.

== Reflections on Debugging in Constrained Environments

The research in this dissertation touched on many different challenges of debugging and development on constrained devices.
The work was built on top of the WARDuino virtual machine.
WARDuino served both as the general instrumentation platform on which debuggers could be built, and as a more modern development environment to improve the programming experience of developers.
In this way the virtual machine simultaneously addresses both challenges C2 and C3 introduced in @chapter:introduction.

#C2

#C3

WARDuino as a WebAssembly virtual machine is able to provide developers with a series of new tools that can speed up the development process significantly.
Primarily, the remote debugger built on top of the WARDuino virtual machine eliminates the need to use laborious hardware debuggers, and provides partial over-the-air code updates to reduce the need for reflashing the entire software.
By using WebAssembly as the target language, developers can choose from a wide range of high-level languages to write their embedded software.
Additionally, we can leverage the existing tooling and ecosystem around WebAssembly to provide, for instance, easier ways to write emulators using existing web technology.
Finally, the portability of WebAssembly makes it much easier to support different platforms---making WARDuino programs much more portable than existing embedded software.

However, the remote debugger is limited by the same resource constraints as the embedded software.
This led us to challenge C4.

#C4

In order to overcome the hardware limitations of embedded devices, we found that it is possible to largely evade the constraints by moving the debugging session from the constrained device _(server)_ to a more powerful host machine _(client)_.
This corresponds to the out-of-place debugging approach, first developed for big data applications to reduce debugging interference.

We adapted out-of-place debugging to work on the embedded devices, and presented a novel out-of-place debugger for WebAssembly programs running on embedded devices.
Any non-transferable resources of the original constrained device, such as sensors and actuators, can still be accessed during the debugging session, to provide the illusion of remote debugging.
Such non-transferable resources can have both stateless and stateful natures, and access to them can be both synchronous and asynchronous.
In our novel out-of-place solution, we are the first to address all of these aspects/* of non-transferable resources, and provide a clear formalization of our approach---in order to help other researchers apply our techniques to their own debugging problems, and application domains*/---leading to what we call _stateful out-of-place debugging_.

#C5

Embedded software is generally written in an _interrupt-driven_ style, which means that execution flow during online debugging can be arbitrarily interrupted and diverted.
This makes it very difficult to debug such programs.

Our stateful out-of-place debugger, captures all asynchronous events on the remote constrained device, and forwards them to the local _client_ debugger without triggering them.
This means that debugging sessions are no longer arbitrarily interrupted by asynchronous events, but our stateful out-of-place debugger is not just able to capture and forward asynchronous resources.
The debugger also provides developers with some control over the asynchronicity.
On the _client_ side, developers can choose when to trigger the asynchronous events, allowing them some control over their order and timing within the program.

Yet, the out-of-place debugger only touched the surface the challenges in debugging embedded interrupt-driven programs.
The larger problem is how to deal with non-deterministic behavior of input and output in general.

#C6

In @chap:multiverse, we presented the first multiverse debugger designed for microcontrollers, called _MIO_, addressing the challenge of non-deterministic bugs caused by unpredictable I/O.
Unlike prior approaches limited to abstract settings, our debugger integrates with a full WebAssembly virtual machine and supports a range of concrete I/O primitives—including sensors, pins, and motors—while maintaining formal soundness.

By introducing a sparse snapshotting strategy, we achieve practical performance on resource-constrained devices.
This work demonstrates that multiverse debugging can work as an online debugger, and be made viable for real-world embedded systems.

== Reflections on the General Implications

The works in this dissertation provide more general contributions not limited to embedded systems.

Our formalization of stateful out-of-place debugging, is the first formalization of the technique, and is not limited to embedded systems.
The state synchronisation problem is a general issue for out-of-place debugging, and our solution is likewise ; we hope in future work to formalize the approach in a more fundamental way, by using a more general underlying language model, such as CEK machines @felleisen86:control.
However, our formalization is already quite general, and includes very little WebAssembly specific aspects.

Similarly our solution to challenge C6 applies to online multiverse debugging in general.

#C7

Our online multiverse debugger allows developers to freely navigate the multiverse of possible execution paths, without the need for a full program replay.
Interactions with the external environment are automatically reversed and replayed as needed by the debugger, enabling developers to explore the impact of I/O operations on program behavior without worrying about interference from the debugger.

Of course, since we work with a real-world environment, we cannot guarantee that the debugger will be able to reverse all I/O operations correctly.
However, we can guarantee that the debugger will reverse the I/O actions support by the virtual machine.
These I/O actions are designed to be _deterministically compensable_ by the virtual machine, meaning that the virtual machine can always reverse them.

Our formal model of the _MIO_ debugger allows us to clearly show exactly how actions are reversed, and to proof that our debugger is still sound a complete even when reversing action, or sliding to new universes.
While the spare snapshotting is designed to make the technique work on constrained systems, the approach described by our formal semantics can be applied to any setting.

== Applying the Lessons Learned to Testing

Our novel testing framework _Latch_ uses a similar principle as out-of-place debugging to run large suites of tests on the constrained hardware itself.
Coupled with our novel managed testing approach, which allows developers to integration test their embedded software through more realistic scenarios, we are able to provide a considerably better way of testing embedded software.

== Soundness and completeness of debuggers

// different levels of soundness : for isntance sound when considering timings is not really possible online, but some offline debuggers could have "timing soundness"

The debuggers that are the subject of this dissertation are all manual online debuggers, for which we define soundness as the property that the debugger observes all possible behavior of the program being debugged, and does not deviate from it.

Like many conventional debuggers, our remote debugger---while complete---is not sound, since it can update the code of the program being debugged during the debugging session.
However, without the live code updates, we were able to prove soundness for the remote debugging.
Through significant efforts we were likewise able to design an entirely new class of out-of-place and multiverse debuggers, which are both sound and complete.
This gives developers greater confidence in the reliability of their observations, especially when debugging non-deterministic bugs.

The formal soundness of our debuggers is necessarily limited to certain assumptions, since we can never fully eliminate the probe effect of online debuggers, or discount the possible noise of the real-world environment in which embedded devices operate.
In the case of our multiverse debugger, we assume in the formalization that I/O operations do not influence each other. In the implementation we have some early support for defining predictable dependencies between I/O operations, but this is not yet formalized.
An interesting future direction would be to extend our formalization to capture more of the possible dependencies between I/O operations, and to provide a formal soundness proof for this extended model.

Similarly for the stateful out-of-place debugger, we assume that there is a known partial order of the possible asynchronous events of a program.
This is a reasonable assumption for many programs, but does present a very naive model.
Extending this model to capture more of the possible dependencies between asynchronous events, perhaps even to capture certain timing aspects, is a very useful future direction.
There is quite some work on causal consistency and environment modeling which could help us here.

Finally, while we believe _completeness_ and _soundness_ encompass the most fundamental expectation of debugger operations---that they do not interfere with the program's execution---there are many other aspects of debuggers that are important to consider.
In future work, we hope that different aspects can be examined and formalized in a similar way.

== Reflections on the Future

Reflecting further on the lessons learned, we see four large lessons that can lead to new avenues of research.

First, by adopting out-of-place debugging and solving the state synchronisation problem we are now able to apply more complex debugging techniques to constrained devices.
While we have given some indication in this dissertation, we have only scratched the surface of this advantage.
#note[We thank Robert Hirschfeld for the great discussion on this topic.]One area where we see great potential is that of live programming.
The stateful out-of-place debugger provides a perfect platform on top of which to build a live programming environment.
The offloading of most of the execution to the local device where the developer is actually programming, allows for easier integration of custom visualisations and other live programming tools without the constraints of the embedded devices.

Second, the multiverse debugger our work has hopefully shown that multiverse debugging can work extremely well as a live online debugging approach---we would even argue that it works best in this scenario.
However, we learned that this adds several new dimensions and challenges to the technique.

In the first place we now need to handle the output effects of the program, which remains a difficult problem to solve in new settings.
The formal framework with sparse snapshotting we developed in this thesis can pave the way here.
Yet other challenges remain, such as the state explosion.
In the context of online multiverse debugging this problem gets a new dimension, as branches are discovered by piecemeal exploration during the debugging session.
It is easy for new branches introduced in this way to be identical to previous branches and therefore redundant.
This is a clear problem that needs to be solved to unlock the real potential of online multiverse debugging.
In fact, we have already made a first step in this direction using concolic execution #note[This research is being led by Maarten Steevens at UGent.]to prune redundant paths.
This integration has several additional addvantages as it can also help guide developers in their exploration.

Third, the soundness and completeness distill the lessons we learned around the correctness and formalisation of debuggers in two clear theorems.
We have discussed the implications and limitations of these theorems already at length as they present perhaps the most important lessons of this dissertation.
They also present an unfinished ambition, and we hope that in future research the community can find a consensus on the correctness of debuggers.

Fourth, the managed testing approach developed to test our debuggers presents a interesting and unique combination of debugging and testing.
Quite accidentally we learned that it is possible to build an automatic integration testing framework on top of debuggers, and that this gives developers a wide range of tools.
This lies at the basis of the managed testing approach.
The debugger controls the software and performs scenarios throughout which the testing framework can verify predefined assertions.
It seems clear to us that this is a more widely applicable approach, and we hope to see more testing frameworks and research integrate tools from the debugging world.

