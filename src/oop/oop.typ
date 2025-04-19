
Today, remote debuggers---like the one presented in the previous chapter---are used to debug processes in a wide variety of contexts, from large clusters to small resource constrained devices.
In this dissertation, we focus on the latter category, and while remote debuggers are commonly used to debug microcontrollers, they are severe disadvantages.
Luckily, the novel out-of-place debugging technique can be used to overcome these disadvantages.


== Introduction

// todo motivation for out-of-place debugging on microcontrollers


=== The origin of out-of-place debugging

Out-of-place debugging is a novel debugging technique that addresses these problems.
It combines local online and remote online debugging, reducing communication latency and overcoming the resource constraints of the remote device.
It was originally devised to minimize debugging interference of remote debuggers for big data applications @marra18, by moving the debugging session to another device.
The first out-of-place debugger, IDRA, was developed for the Pharo language, and allowed for debugging of live distributed big data applications.
By moving the debugging session out of place, IDRA could debug a node in the network without effecting the live execution of the distributed software.
The prototype showed how out-of-place debugging can reduce the debugging latency significantly in the context of large clusters.

=== Out-of-place debugging for microcontrollers

// 1. why on microncotrollers: motivation for edward

// 2. aknowledge WOOD as the predecessor of this work
// however the work presented here is vastly different, and more general in scope.
// in part of the focus in WOOD is debugging of live applications, something we do not consider here. The two works really have a very different philosophy.

=== Out-of-place debugging for event-driven applications

// extension of edward on wood

=== Out-of-place debugging for stateful resources

// ecoop paper introduction


Especially for the latter category, remote debuggers are commonly used to debug various kinds of applications @hogl06 @li09, such as real-time systems @skvar-c24, containerized applications for edge computing @ozcan19, and Internet of Things applications @potsch17 @lauwaerts24a. // todo more references ?
Yet, remote debuggers suffer from three severe disadvantages.
Firstly, the debugger is run on the remote device. // todo add a general disadvantages of this (outside of microcontrollers): probe effect?
In the context of constrained devices, this additionally limits the resources available to the debugger.
Secondly, the communication channel can be slow, and can introduce latency in the debugging process.
Thirdly, the delays introduced by the remote communication can exasperate the debugging interference.

=== The spectrum of out-of-place debugging

// is this the right place for this?

=== The abstract model of out-of-place debugging

// there is no formalisation yet

However, the concept of out-of-place debugging still lacks a sound formal foundation, that captures the entire spectrum of its implementations.
Furthermore, the existing work fails to address the full range of side effects of executing code involving non-transferable resources, and how it can lead to _state desynchronization_ between the local and remote device.
Existing solutions typically limit internal state changes to the local debugging environment, making it difficult to debug essential operations like MQTT communication in Internet of Things (IoT) systems.

Many non-transferable resources feature stateful operations, which can impact a program's behavior.
Without those changes being reflected on the local server, the debugger can never provide an accurate representation of the program's execution.
In scenarios where asynchronous events or interactions with external systems occur (for example receiving an MQTT message), desynchronization of the program state between the two devices can occur at any point in the program's execution.
Traditional methods that strictly scope side effects to the local server fail to account for the dynamic nature of state changes occurring on remote devices.

This chapter introduces stateful out-of-place debugging that bridges the gap between local and remote debugging paradigms more completely.
Our method ensures that while the majority of the debugging code executes locally, stateful operations on the remote device are consistently managed and reflected on the local device.
In our solution we adopt a minimal synchronization strategy, where synchronous operations transfer the minimal state required for their execution at the point they are invoked.
Asynchronous resources send their changes to the internal state to the debugging session as soon as they become available, providing a debugging experience where debugger interference is minimized.

In order for this synchronization to work, our solution identifies the specific requirements non-transferable resources and their operations must satisfy.
We demonstrate that meeting these requirements is not very restrictive and show how real-world examples can be implemented using our approach.
We further provide proofs that this approach is sound and complete, and show a prototype built on top of an existing out-of-place debugger for WebAssembly~\cite{lauwaerts22}.
// todo we built on the existing warduino prototype, since WebAssembly provides a good basis for our formalization + we believe microcontrollers and iot apps is one of the most promosing domains for oop

