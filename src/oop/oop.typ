#import "../../lib/util.typ": code, snippet, algorithm, semantics, lineWidth, headHeight, tablehead, highlight, boxed, circled, illustration
#import "../../lib/class.typ": note, theorem, proofsketch, example, lemma, axiom
#import "../../lib/fonts.typ": sans, script, serif

#import "./figures/cetz/led.typ": ledcetz
#import "./figures/semantics.typ": *

#import "@preview/curryst:0.5.0": rule, prooftree
#import "@preview/cetz:0.3.4"

Today, remote debuggers---like the one presented in the previous chapter---are commonly used to debug microcontrollers, however, there are severe disadvantages.
Luckily, a novel technique, called out-of-place debugging, can be adopted to largely evade these disadvantages by moving the debugging session to another more powerful device.

During the writing of this dissertation we explored two new concepts for out-of-place debugging, which are essential for microcontrollers.
Initially, we explored how to support event-driven applications, which are common in microcontrollers.
This lead to an early publication at MPLR 2022 @lauwaerts22:event-based-out-of-place-debugging.
Subsequently, we explored how to support stateful actions on non-transferable resources, such as memory-mapped I/O devices.
As part of this work, we developed the first formal model for out-of-place debugging, and proved its soundness and completeness.
//While microcontrollers remained the initial motivation, with the formal aspect tacking the foreground, the work is much more general in scope than just embedded systems.

== Introduction<oop:intro>

Remote debuggers are commonly used to debug various kinds of applications @hogl06:open @li09:research, such as real-time systems @skvar-c24:in-field-debugging, containerized applications for edge computing @ozcan19:remote, and Internet of Things applications @potsch17:advanced @lauwaerts24:warduino. // todo more references ?
Yet, remote debuggers suffer from three severe disadvantages.
Firstly, the debugger is run on the remote device. // todo add a general disadvantages of this (outside of microcontrollers): probe effect?
In the context of constrained devices, this additionally limits the resources available to the debugger.
Secondly, the communication channel can be slow, and can introduce latency in the debugging process.
Thirdly, the delays introduced by the remote communication can exacerbate debugging interference, also known as the probe effect~@gait86:probe.

These problems can be addressed using out-of-place debugging.
It combines local online and remote online debugging, reducing communication latency and overcoming the resource constraints of the remote device.
However, out-of-place debugging is a very new idea, and there are still several open questions and challenges that come with the technique, that have not been addressed yet.
Additionally, the technique is without formal foundations.
In this chapter, we present the first formalisation of the technique, and attempt to address some important gaps in the existing literature.

Naturally, our work builds on the preceding out-of-place debugging works, and these deserve a proper introduction.
Therefore, we first provide an overview of how out-of-place debugging works, and discuss how our contributions relate to previous work.

=== The origin of out-of-place debugging<oop:history>

Out-of-place debugging was originally devised to minimize debugging interference of remote debuggers for big data applications @marra18:out-of-place, by moving the debugging session to another device.
The first out-of-place debugger, IDRA, was developed for the Pharo language, and allowed for debugging of live distributed big data applications.
By moving the debugging session out of place, IDRA could debug a node in the network without effecting the live execution of the distributed software.
The prototype showed how out-of-place debugging can reduce the debugging latency significantly in the context of large clusters.

// todo motivation for out-of-place debugging on microcontrollers
=== Out-of-place debugging for microcontrollers

// 1. why on microncotrollers: motivation for Edward
In the context of embedded applications, out-of-place debugging has great potential for improving the debugging experience offered by remote debuggers, by freeing the debugger from much of the limitations of constrained devices.

// todo ...

// 2. aknowledge WOOD as the predecessor of this work
// however the work presented here is vastly different, and more general in scope.
// in part of the focus in WOOD is debugging of live applications, something we do not consider here. The two works really have a very different philosophy.
An initial investigation by #cite(form: "prose", <rojas21:wood>) looked at out-of-place debugging as a solution for live debugging of _in-production_ embedded applications.
The work paved the way for using out-of-place debugging on microcontrollers, and while its topic is very interesting, there are many questions around the idea of debugging in production.
In-production debugging is rarely seen in practice, and considered by some to be undesirable.
Regardless, out-of-place debugging can provide numerous other benefits to debuggers for microcontrollers.
In  this dissertation, we will therefore not concern ourselves with the problem of in-production debugging, and instead present how we adapted---and extended---out-of-place debugging to work for microcontrollers during the traditional development stage.

=== The gaps in out-of-place debugging

Since out-of-place debugging is still a very young technique, it is not surprising that there are some important gaps in the existing work around it.
There are three important gaps that we attempt to fill in this chapter.
While these gaps are not specific to microcontrollers, they are especially relevant in this context.

First, out-of-place debugging currently lacks a sound formal foundation.
We therefore developed the first formalisation of the technique based on WebAssembly.
However, our formalisation illustrates and captures the essence of out-of-place debugging without many WebAssembly specifics---and so we argue, is more broadly applicable.

Second, existing work fails to address possible state desynchronization between the remote and local device.
Existing solutions typically limit internal state changes to the local debugging environment, making it difficult to debug essential operations like MQTT communication in Internet of Things systems.
In our formalisation, we show how to handle stateful operations on non-transferable resources through limited synchronization of the state between the local and remote devices.

#note[In the original publication @lauwaerts22:event-based-out-of-place-debugging, we used the terms _pull_ and _push_, here we use _request-driven_ and _event-driven_ instead.]
Third, non-transferable resources are only accessed in a synchronous request-driven way.
The client debugger will request information about non-transferable resources from the server, and _pull_, or _transfer_, the information to the local client session.
However, some non-transferable resources may act in an asynchronous way, _pushing_ information at arbitrary times.
To solve this, we extend out-of-place debugging to support _event-driven_ access to non-transferable resources, alongside the typical _request-driven_ access.

== Background: Out-of-place debugging<oop:background>

Before delving into the details of our contributions, we first provide an overview of how out-of-place debugging works, and discuss the general out-of-place debugger architecture.
Out-of-place debugging provides the debugging experience of a remote debugger, while running most of the code on a local device, thereby reducing debugging latency and interference.
It allows for debugging live applications, as the debugging session is isolated from the live execution of the program.
Additionally, by running the debugging session out-of-place, the debugger can have access to more computational power and memory, or other resources, enabling more complex debugging techniques.
We will illustrate the various concepts involved using our prototype implementation build on top of the WARDuino @lauwaerts24:warduino virtual machine. 
// todo 

#[

#figure(
  grid(columns: (1.1fr, 1.0fr),
    image("figures/led.svg"),
    snippet("oop:lst.example", [], headless: true,
    (```ts
import {pinMode, PinMode,
  Voltage, digitalWrite, delay}
  from "warduino/assembly";

export function main(): void {
  const led: u32 = 26;
  const pause: u32 = 1000;

  pinMode(led, PinMode.OUTPUT);

  while (true) {
    digitalWrite(led, Voltage.HIGH);
    delay(pause);
    digitalWrite(led, Voltage.LOW);
    delay(pause);
  }
}
```,)),
  ),
  caption: [Typical blinking LED program for microcontrollers, illustrating non-transferable resources in out-of-place debugging. _Left:_ A schematic of the microcontroller. _Right:_ The AssemblyScript code for the program.],
)<oop:app:example>

=== Example: a blinking LED

@oop:app:example shows the typical blinking LED example for microcontrollers in AssemblyScript.
The application uses the WARDuino actions, imported on the first line of the program.
After the correct mode for the LED's pin has been set, the program will turn it on and off in an infinite loop with a small delay.
The left side of the figure shows a schematic representing the setup of the microcontroller.
The AssemblyScript program is compiled to WebAssembly and run on the microcontroller using a WebAssembly runtime.
The runtime provides a series of functions to access the non-transferable resources of the microcontroller, such as the LED, buttons, and sensors---we call these functions _actions_.
]

=== Debugging with Out-of-place debugging

A developer can use an out-of-place debugger to debug the example application locally on their own machine, while still maintaining the effects on the remote microcontroller, in this case the LED can still turn on or off.
Often microcontrollers do not have enough memory to run an additional debugger alongside the application.
By using out-of-place debugging, this is no longer necessary.
The microcontroller only needs to run a minimal stub to receive a handful of debugging instructions to instrument the runtime.

@oop:fig:oop-definition shows the components involved in out-of-place debugging, the developer's local _client_ on the left, while the right side shows the remote _server_.
#note[Despite their small size, we refer to the microcontrollers as the _server_, because they _serve_ the _requests_ for information from the local debugger.]
The remote server is the device where the software is intended to run.
In the case of the blinking light application, this would be the microcontroller that controls the LED.
Uniquely in out-of-place debugging, the entire debugging session---consisting of the runtime and the program being debugged---lives on the client.

#figure(
  image("figures/architecture.svg", width: 100%),
  caption: [Schematic showing the concept of out-of-place debugging with all the involved components.]
)<oop:fig:oop-definition>

Note that the server may possess _non-transferable_ resources, such as the LED in the example, which cannot be relocated along with the runtime and program to the client.
We differentiate between two types of non-transferable resources---based on the way they are accessed or produce information---_synchronous_ and _asynchronous_.
Synchronous resources, are those accessed by the program synchronously, such as the LED in the example.
Asynchronous non-transferable resources on the other hand can produce data at any point in the program, such as hardware interrupts for buttons or motion detectors.

To maintain the benefits of remote debugging, the client does not simulate the non-transferable resources.
Instead, the server maintains a small stub which instruments its runtime, and can receive debug instructions from the debugger backend (client).
Specifically, the stub supports direct access to synchronous non-transferable resources through remote function calls.
For asynchronous non-transferable resources, the stub (server) can send messages to the client through the same connection.

In the case of our example, the only non-transferable resource is the LED light.#note[Reversible debugging can make external state inconsistent. We address this in @chap:multiverse.]
We consider the action for controlling the LED stateless because it does not change the internal state of the runtime, and does not depend on any internal state other than its own arguments.
Such stateless operations can still effect external state.
However, since external state is part of the non-transferable resources it only exists on the remote server.
As out-of-place debugging still accesses those resources through the server, we assume that their state remains consistent during debugging.

== Problem statement

Since out-of-place debugging runs a program on a pair of two devices forming a distributed system, executing code can lead to diverging states between the two devices, thereby affecting the proper execution of the program.
This can lead to inconsistent, and incorrect observations of the program's behavior, making it difficult to identify the root cause of a bug.
This is even more problematic when part of the program's execution is asynchronous.
To further clarify the problem of state desynchronization, we look at a use case of out-of-place debugging on an Internet of Things application for microcontrollers.

=== Example: asynchronous logging of a sensor

Consider the previous LED example, in an Internet of Things setting we would like to control the LED through some communication protocol such as MQTT.
@oop:app:problem shows how this can be done in AssemblyScript code.
The example is written for our WARDuino virtual machine. // a WebAssembly runtime for microcontrollers.
The virtual machine provides actions for the typical MQTT operations, such as subscribe, publish, and keep-alive, see @chapter:remote and @app:mqtt.

The code in @oop:app:problem works as follows, at the start of the program the necessary MQTT configuration is set up, and the microcontroller connects to the local Wi-Fi network.
After the connection is established, the microcontroller subscribes to the topic "SENSOR" and wait for incoming messages.
//While waiting, the microcontroller uses the keepalive function to keep the connection to the MQTT broker alive.
At any point, a message can be received on the topic "SENSOR", at which point the virtual machine schedules the callback function and log the sensor value.
On the right-hand side of @oop:app:problem, we show a schematic of the microcontroller connected to the MQTT broker.
The connection with the MQTT broker is an example of an asynchronous non-transferable resource, which can produce new MQTT messages at any point in the program, and subsequently triggering a callback, such as the _log_ function in the example.

#figure(
  grid(columns: (1.1fr, 1.0fr),
    image("figures/mqtt.svg"),
    snippet("oop:lst.example", [], headless: true,
    (```ts
import {MQTT} from "warduino/assembly";
import {init} from "./util";
import * as config from "./config";

export function main(): void {
    // connect to WiFi & MQTT broker
    init();

    // Subscribe to MQTT topic
    MQTT.subscribe(
        "SENSOR",
        // and log value
        log(topic: string,
            payload: string) => {
            // ...
    });
    // ...
}
```,)),
  ),
  caption: [Small example application illustrating the state desynchronization problem in out-of-place debugging, when receiving MQTT messages. The application simply logs sensor values received via MQTT messages.]
)<oop:app:problem>

=== Out-of-place debugging for event-driven applications

// extension of Edward on wood

Previous out-of-place debuggers @marra18:out-of-place @rojas21:wood, did not support asynchronous non-transferable resources, such as the MQTT connection in the example.
Access to non-transferable resources from the client was only possible by request of the server, such as through synchronous remote function calls in the case of #cite(form: "prose", <rojas21:wood>).
This already allowed for continual synchronous polling of a sensor value.

However, such a _request-driven_ strategy to access sensor data is often too resource-intensive for embedded applications, and so does not capture all use cases for debugging Internet of Things devices.
Many of the peripheral devices attached to a microcontroller use an interrupt-driven interface instead.
Such interrupts are generated when certain external events happen, for example when an input-pin changes from low to high.
This prevents microcontrollers from having to poll the state of the pin constantly, and save resources by only reacting to changes in the environment when they occur.

// todo so we need to support event-driven access + control over events (and motivate control)

=== Out-of-place debugging for stateful resources // problem statement

// ecoop paper introduction

Unfortunately in out-of-place debugging, since the entire debugging session is moved to the local machine, the scheduling of the callbacks happens on the local client, while subscribing callbacks on MQTT topics, and receiving the messages happens on the server.
This presents two types of state desynchronization from the perspective of the client, _synchronous_ and _asynchronous_.

==== State Desynchronization between two Devices

Harmful synchronous state desynchronization can occur whenever the client instructs the server to execute a piece of code.
This code can potentially change the memory state on the server leading to state desynchronization.
This is especially problematic when these state changes are needed for the program to continue running.
In such cases, the server will use outdated values from memory instead of the updated values from the client.

While synchronous state desynchronization is triggered by the server and happens at specific, well-defined moments, asynchronous desynchronization can occur at any time.
Relevant state on the client can change asynchronously, outside of the local context of the debugger.
These changes are caused by asynchronous events which can occur at any time in the program, such as receiving MQTT messages.

The example in @oop:app:problem, illustrates both synchronous and asynchronous state desynchronization.
First, the MQTT.subscribe function, illustrates synchronous state desynchronization.
It modifies the internal state of the runtime on the server by storing the callback to be triggered upon receiving the "SENSOR" messages, which the subsequent out-of-place code depends on.
Second, whenever an MQTT message is received, this message is stored in memory (on the server) and should be executed as soon as the currently executing instruction is finished. // todo does not need to be immediate due to the partial ordering REMOVE ?

=== The abstract model of out-of-place debugging

// there is no formalisation yet

The concept of out-of-place debugging still lacks a sound formal foundation, that captures the entire spectrum of its implementations.
Furthermore, the existing work fails to address the full range of side effects of executing code involving non-transferable resources, and how it can lead to _state desynchronization_ between the local and remote device.
Existing solutions typically limit internal state changes to the local debugging environment, making it difficult to debug essential operations like MQTT communication in Internet of Things (Internet of Things) systems.

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
We further provide proofs that this approach is sound and complete. //and show a prototype built on top of an existing out-of-place debugger for WebAssembly @lauwaerts22:event-based-out-of-place-debugging.
// todo we built on the existing warduino prototype, since WebAssembly provides a good basis for our formalization + we believe microcontrollers and iot apps is one of the most promosing domains for oop

#let spectrum = [
== The spectrum of out-of-place debugging

// is this the right place for this?

Previous implementations of out-of-place debugging avoided the problem of state desynchronization by not allowing any state changes on the client.
Any unavoidable changes were dealt with ad hoc.
We can consider out-of-place debugging as the spectrum of debuggers that lie between local online debugging and remote online debugging, as illustrated by \cref{fig:oop-spectrum}.

Previous implementations of out-of-place debugging, lie squarely on the side of local online debugging, where no internal state changes are allowed on the client, or only very few exceptions are made.
This approach has been implemented previously by two different debuggers.

#let overview = cetz.canvas({
  import cetz.draw: *
  // Your drawing code goes here
  rect((0,0), (1,1), name: "client")
})

#figure(overview,
    caption: [Schematic showing the spectrum of out-of-place debugging.]
)<oop:fig:spectrum>

The IDRA debugger @marra18:out-of-place is the first implementation of out-of-place debugging, and was developed to debug distributed big data applications written in the Pharo language @black10:pharo.
It explicitly scopes the side effects on internal state to the local server, thereby allowing developers to debug a node in the network without effecting the _live_ execution of the distributed software.
However, this means that IDRA can only read from the non-transferable resources, such as files, and not write to them.

The Edward debugger @lauwaerts22:event-based-out-of-place-debugging is an out-of-place debugger for microcontrollers, where the goal is to free the debugger from the constraints of the microcontroller.
Following the example of IDRA, Edward attempts to scope all changes to the internal state to the local server.
In order to support receiving MQTT messages it employs a complex ad-hoc synchronization mechanism specifically to handle this use case.

Both implementations of out-of-place debugging, on the left side the spectrum, keep internal state changes scoped to the local server, showing the need to find solutions that deal with state desynchronization in a systematic way.
On the other end of the spectrum, we could avoid state desynchronization altogether by making all internal state changes occur only on the remote client.
However, this approach is impractical because it would make running anything on the server nearly impossible.
Neither extreme is ideal, since the goal of out-of-place debugging is to run as much code as possible on the server to minimize interference while still accessing the non-transferable resources of the client.
To achieve this, out-of-place debuggers must necessarily lie somewhere in the middle of the spectrum.

// = Terminology
//
// - server and proxy
// - proxy code and proxy result
// - non-transferable resources
// - stateful vs stateless
// - in-place vs out-of-place vs remote

]
// #spectrum /// todo do we keep this?

== Stateful out-of-place Debugging for WebAssembly<oop:semantics>

In this section, we present the semantics of out-of-place debugging for WebAssembly. // todo add unifying section
In order to have sound and complete semantics, we need to make two key assumptions about the stateful operations in the system. 
These assumption are not specific for WebAssembly and can be ensured for a wide range of stateful operations expressed in any programming language:

//Before delving into the formal semantics of our out-of-place debugger, we discuss 
// followed by a brief discussion of the WebAssembly semantics underlying our formalization.
// todo we allow both stateless and stateful, however required state should be known given the operations arguments
// this is reasonable and already allows for a large range of operations
// usually if your operation does not fit this, it can be split into smaller operations that do satisfy our requirements: give example
//There are two important assumptions that we make for stateful operations in our system: 

1. #strong[Statically known state dependency.] Given the argument values for any #emph[synchronous] stateful operation in the system, it must be possible to define a function which identifies all parts of the internal state that the operation depends on, and the state that the operation changes.

2. #strong[Instantaneous partially ordered events.] We assume that for all #emph[asynchronous] non-transferable operations during a debugging session, there exists a #emph[partial] order over the asynchronous events they produce. In addition we assume that events do not have real-time dependencies.

Without the first requirement we would have to rely on possibly time consuming static analysis or conservatively copy the whole state, defeating many of the advantages of out-of-place debugging.
This requirement does exclude certain complex operations, where changes to the state are calculated based on some implicit state.
However, we believe that for most of such operations the implicit state can be made explicit by passing it to the stateful operation as an argument.

Without the second requirement, the debugger cannot know which of the received events can be (safely) handled next.
In this chapter, we focus solely on the order in which they are processed.
Other considerations around the exact timing of the events are important for real-time systems, but are impossible to handle in an online debugger context where execution can be paused for arbitrary periods.
//In the related work section, we discuss some interesting work on this topic.
Although these requirements impose some limitations on the types of stateful operations we can support, we believe that a broad range of stateful operations align with these assumptions.

// which come down to one soft requirement for synchronous state changes, and one hard requirement for asynchronous state changes. 
//First, for synchronous operations we assume that the (minimal) state dependencies of the operation can be statically determined. 
//This assumption allows for our approach to optimize the amount of state that needs to be copied to the remote client. 
//If only correctness and not efficiency is required, this  assumption can be relaxed to finding an over approximation of the state dependencies:

//\begin{description}
// \item[Statically known state dependency.] For any stateful operation, all state that the operation depends on is known given the arguments for the operation. This is only a backwards dependency, only the state which influences the behavior is considered, but not state that is (transitively) influenced by the operation. 
//\end{description}
//
//Second, for asynchronous operations we assume that there is an order on the events and we assume that all events can be dealt with in a conceptually atomic way:
//
//\begin{description}
//    \item[Instantaneous partially ordered events.] The asynchronous state changes (events) form a partially ordered list, and do not have real-time dependencies.
//\end{description}





// todo 1. require stateful operations to know the state they depend on
// todo 2. require asynchronous events to only change state in a defered way (think about this more after i have the simple example and the motivation down)



//For example, an operation that copies a file from one location to another, can be split into two operations, one that reads the file, and another that writes it.

//== Remote Invocation of Stateful Operations
//
//% todo high level explaination of our solution
//In order to solve the problem of state desynchronization in out-of-place debugging with, we 
//
//== Remote Invocation of Stateful Operations

=== WebAssembly language semantics<oop:webassembly>

#semantics(
    [The configuration for WebAssembly with embedded actions, supporting transfer and syncing of state based on the semantics of the original paper @haas17:bringing.],
    wasm,
"oop:fig:wasm")

We briefly discussed WebAssembly, and its semantics in the previous chapter (@chapter:remote) and we provide a larger overview of the relevant rules from the original paper @haas17:bringing in @app:webassembly.
Here we reiterate the most important aspects of the WebAssembly semantics that are relevant to our formalization of stateful out-of-place debugging.

@oop:fig:wasm shows the most important syntax rules for WebAssembly.
The WebAssembly semantics are grounded in a stack-based virtual machine, where instructions and values operate on a single stack with strict typing to guarantee fast static validation.
Again, we base our formalization on the semantics from the original WebAssembly paper by #cite(form: "prose", <haas17:bringing>), where the core semantics include structured control flow (blocks, loops, and conditionals) and memory management via linear memory.
Important here is WebAssembly's intentional exclusion of external interface definitions, including I/O operations.
This design choice enables us to deliberately sculpt the I/O operations for our synchronization system, as we will show in @oop:actions.

The execution of a WebAssembly program is defined by a small-step reduction relation, denoted as $wasmarrow$ where, $i$ refers to the index of the currently executing module. 
The relation $wasmarrow$ is defined over a configuration $K = {s;v^*;e^*}$, with global store $s$, local values $v^*$, and the current stack of instructions $e^ast$.
Important for our semantics, the global store $s$ contains instances of modules, tables, and memories.
The global store allows access to any function within a module instance, denoted as $s_"func" (i,j)$, where $i$ represents the module index and $j$ corresponds to the function index.

The WebAssembly semantics makes use of administrative operators to deal with control constructs, for example $call i$ denotes a call to a function with index $i$. To mark the extend of an active control struct, expressions are wrapped into labels. 
Evaluation context $L^k$ are used in the _Label_ rule to unravel the nesting of $k$ labels, allowing to focuses on the currently evaluation expressions $e^ast$
This rule, as defined in the WebAssembly semantics, is important for defining the out-of-place debugger semantics because it allows capturing the current continuation, (i.e. $L^k [ ]$) , just before invoking a remote call. 

=== Extending WebAssembly with Embedded Actions<oop:actions>

In @chapter:remote, we discussed in great detail how WARDuino extends WebAssembly with actions for peripherals of constrained devices, and other resources specific to embedded and Internet-of-Things applications.
For the purposes of the out-of-place debugger, these actions correspond precisely with the synchronous accesses of non-transferable resources.
In @chapter:remote, actions did not differed from other WebAssembly functions, but in the context of out-of-place debugging we need to distinguish between the two, and extend actions with two transfer functions to enable our sparse synchronization strategy.


#semantics(
    [The configuration for WebAssembly with embedded actions, supporting transfer and syncing of state based on the semantics of the original paper @haas17:bringing.],
    actions,
"oop:fig:prim-def")

We have extended WebAssembly with a set of non-transferable actions which are clearly separated from regular code execution. 
This design choice enables us to have a clear and easy division between transferable and non-transferable code.
@oop:fig:prim-def shows the extended WebAssembly syntax rules for non-transferable resources support.
The changes are highlighted.

#semantics(
    [The semantics of actions, and invoking instructions in WebAssembly.],
    invokeconfig,
"oop:fig:invoking")

The WebAssembly global store is extended with a #emph[global] action table $A$ contains all actions, each action $a$ is a named pair of a closure $cl$ and a transfer functions $t$ and $r$.
The closure consists of the code which performs the action over the non-transferable resource. 
#note[We use the terms _forward_ and _backward_ transfer to refer to the direction of the state changes, similar to program slicing.]The backward transfer function $t$, returns the state $s'$ needed to perform the action, given the arguments $v^*$ and the current state $s$ of the server. 
The forward transfer function $r$, produces the state $s'$ that has been altered by execution the action given the state $s$ after executing the action on the client. 
We refer to elements of named tuples, such as the transfer function as $a_(transfer)$, or the action table $s_act$.

//To accommodate the semantics of the out-of-place debugger, we make a small modification to the semantics of WebAssembly, by adding a special label $Inv$ for invoking a series of WebAssembly instructions.

Naturally, the semantics of actions needs to be define both for when the debugger is active and during normal execution. 
@oop:fig:invoking shows how actions are executed during normal execution.  
Whenever a function is called that is not present in the current instance $i$, the action rule finds the closure in the action table and shifts execution to evaluating the closure.
This is similar to how the WebAssembly semantics handles function calls.
Important to note is that actions are atomic, and reduce to a single value in one step, $\{s; v^*; call a_(code) \} multi(wasmarrow) \{s'; v'^*; v\}$.
While we could relax this condition for synchronous events, the semantics to support asynchronous events would become more complex as shown in @oop:Asynchronous.
In the next section we give an overview of the semantics of actions during debugging. 

=== Configuration of the Stateful Out-of-place Debugger

#semantics(
  [
    The syntax rules for a stateful out-of-place debugger, on top of the WebAssembly semantics shown in @oop:fig:prim-def. The rules are split into three groups, the global rules, the client rules, and the server rules. Elements in the server configuration are overlined whenever they need to be differentiated from the client configuration.
  ],
  configuration,
  "oop:fig:debugger-def"
)
// todo add breakpoints

Out-of-place debugging distributes a single program over two distributed entities, the local debugger which acts as the _client_, and the remote microcontroller which acts as the _server_.
Recall that the idea is to execute most of the program on the client and only execute code attached to non-transferable resources on the server.
We define the configuration for stateful out-of-place debugging in @oop:fig:debugger-def.


The debugger configuration $D$ is split into the client and server sides, $brackets.l C | S brackets.r$, which each hold a WebAssembly configuration $K$---the program state.
The client side represents the main component of the debugger, which is responsible for receiving debug commands from the debugger's user interface.
The server side represents only a small stub running on the remote microcontroller, which must facilitate access to non-transferable resources.

The client syntax rules shown in @oop:fig:debugger-def, divide the configuration into three main parts divided by a semi-colon.
The first component is the internal debugger state, consisting of the execution state $es$, and the internal message box $boxed(im)$ which receive messages from the server.
Execution state $es$ can be either _running_, _halted_, or _invoked_.
The last state is used to indicate that the client is currently executing a remote invocation, and keeps track of the state of the execution state before the invocation.
There is only one possible internal message that can be received from the server, _sync_, which is used to synchronize the state of the client after a remote function invocation.
The second component is the WebAssembly configuration $K$, and the third component is the external-facing message box $boxed(m)$ for debug commands received from the user interface.
For brevity, we have limited the supported debug commands to _play_, _pause_, and _step_.

The server configuration consists of the two components; the internal debugger state and the WebAssembly program state $K$.
The internal debugger state contains the execution state $overline(es)$, and the internal message box $overline(im)$, which receives messages from the client.
The server can receive just one internal message, _invoke_, which is used to invoke an action.
In order for the right state to be synchronized, the messages passes along the WebAssembly global store $s$ and list of instructions $e^ast$.
We go into more details when discussing the evaluation rules.
For clarity, we place a line over these components to differentiate them from the similar components in the client configuration.

#note[Breakpoints can be added to the semantics, analogous to the approach in @chapter:remote.]In our implementation we also have an outgoing message box used to communicate all the information needed to update the debugger frontend, in order not to clutter the semantics we omit this message box in the semantics.
// todo In the appendix, we show how to extend the semantics with this message box, and how to handle breakpoints. These rules are similar to those represented for the remote debugger in the previous chapter.

=== Stepping in a Stateful Out-of-place Debugger<oop:invocation>

// todo add inspect rule

// todo is this a weird split? should i split in transferable and non transerable rule instead?

// todo explain abbvr.

// todo Q is actual two things: in and out, should fix this in the rules, abbvr. {out \nothing, in msg} to (msg)_in

// todo add inspect rule + breakpoint rules in appendix

#semantics(
  [
    The semantics of remote action invocation in out-of-place debugging.
  ],
  stepping,
  "oop:sem:stepping"
)

Given the syntax rules for the out-of-place debugger, we can now define the evaluation rules, which are of the form $brackets.l C bar.v S brackets.r multi(dbgarrow) brackets.l C' bar.v S' brackets.r$.
@oop:sem:stepping shows the rules for the client side of the out-of-place debugger.
The debugger message box $boxed(m)$ in $C$ receives debug messages from the debugger frontend, which are processed in the order they are received in. 
Conceptually, step operations may involve either the server or the client taking a step. 
The determining factor is whether the step requires access to a non-transferable resource. 
Below, we outline the step and run rules.

/ step-client: When the client is halted, and receives the debug command _step_ in the external-facing message box, and the next instruction is not an action, then the execution takes a single step in the underlying WebAssembly semantics from $K$ to $K'$.

/ play: Whenever the halted server receives a _play_ message, it will move the server to the _running_ state. 

/ pause: Whenever the running server receives a _pause_ message,  it will move the server separator to the _halted_ state. 

/ run-client: Similarly, when the server can take a (local) step in the underlying semantics, and is in the _running_ state, the server takes a step through the underlying semantics.

These rules allow the debugger to execute a WebAssembly program that does not contain any actions.
When during the execution of the program an action is encountered execution needs to be transferred to the server.
For fullness, @oop:sem:stepping already contains the rule for handling the forward transfer of state by the client---as it is received from the server after a remote action call.

//Important for the synchronization of state during invocation, are the functions, $a_{transfer}$,   $a_{transfer^{-1}}$, and $_update_$.
//The _diff_ function returns the difference between two WebAssembly stores $s$ and $s'$, which allows the changes to the WebAssembly state to be transferred back to the server after invoking a action.
//The _update_ function updates the store $s$ with the difference $\Delta$. % , its results is equal to $\Delta$ after $s$.


    / step-transfer: #[When during stepping, the next instruction is a call to an action, the execution is transferred to the server device.
      The transfer function $a_transfer$ calculates the state $s'$ required to execute the action on the client. 
      This state is passed to the server through the _invoke_ message, along with the arguments of the call $v^n$, and the function id $i$ to call.

	  Note that the client's execution state transitions to $invoked(halted)$. 
	  Before executing code on the server, we must remember that the execution was $halted$ to restore it after the call. 
	  This is crucial because execution on the server can be triggered both while the client is halted and while it is running.]

    / run-transfer: When the client is in the running state and the next instruction is a call to an action, the execution is transferred to the server device.
      This rule is entirely analogous to the step-transfer rule, with that difference that the server will transition to the  $invoked(running)$ state. 
      This is important to be able to restore the $running$ state after the call. 

    / sync: The synchronization rule updates the state of the client, with the difference received from the server after an invocation.
      This is identical to the update in the _invoke-start_ rule. Finally, the execution state of the client is restored to $es$. 

// todo internal message might not be empty, right?
#semantics(
  [
    The semantics of out-of-place execution, i.e., on the server, in stateful out-of-place debugging.
  ],
  invokingrules,
  "oop:sem:invoking"
)

@oop:sem:invoking shows how the _invoke_ message is handled by the debugger stub on the server side.
The process is split into three parts, (1) the server synchronizes the state based on the backward transfer and prepares the action call, (2) the action is performed, and (3) the changes to the WebAssembly state are transferred back to the client.

    / invoke:
        When the client receives an invoke message, it updates the local state $s$ with the snapshot $s'$ of the _invoke_ message.
        The _update_ function simply overrides the current state $s$ with those parts that are present in $s'$.
        Subsequently, it executes the action by executing it in the underlying WebAssembly semantics.
        There is only a single value $v$ left on the stack on the client $C$.
        At this point, the client makes use of the $a_(transfer^(-1))$ function of the action to compute which state needs to be synchronised. 
        This difference is then transferred back to the server in a _sync_ message, along with the return value $v$ of the action.

== Modeling Asynchronous Non-transferable Resources<oop:Asynchronous>

The semantics so far, allow for the out-of-place debugger to handle programs with synchronous operations that are both stateless and stateful.
However, in microcontroller systems, actions can be triggered asynchronously by elements such as sensors, hardware interrupts, and asynchronous communication protocols like MQTT.
Pure WebAssembly does not have support for callbacks, therefore we extended the WebAssembly semantics with a lightweight callback handling system in @chapter:remote (see @remote:implcallback and @remote:callback-handling).
We made minor adjustments to the implementation to better align with our stateful out-of-place debugger, but the semantics remain the same.

// todo important to note is that the rules are still deterministic, eventhough the system might not be. Given the queue of debug and event messages, the whole reduction is deterministic. THIS IS IMPORTANT FOR THE PROOFS
We can summarize the system as follows.
The WARDuino virtual machine captures all asynchronous events into a universal representation---a topic and payload tuple.
Whenever an event arrives in the event queue, the WebAssembly runtime will interrupt the current execution, and invoke the callback function associated with the event topic.
Such callbacks cannot have a return type, to ensure that callbacks do not break a well-typed WebAssembly program.
However, callbacks can update other internal state, such as global variables, or linear memory. // todo double check if this does not break our solution
Asynchronous events and callbacks further introduce non-determinism into the WebAssembly languages, which can seriously complicate debugging of programs.
However, simplifying debugging of non-deterministic bugs is beyond the scope of this chapter, andis
simplifying debugging of non-deterministic bugs is an orthogonal problem to that of state desynchronization in out-of-place debugging, and beyond the scope of this chapter.
We tackle this problem in the next chapter (@chap:multiverse), where we present our new multiverse debugger for I/O operations.

== Debugging Asynchronous Non-transferable Resources<oop:debugAsynchronous>

The callback system and the asynchronous non-transferable resources it enables, present a second challenge for handling state desynchronization in out-of-place debugging.
Identical to the other parts of the program's runtime, we wish to have the callback system run on the client.
Unfortunately, events are generated on the side of the server.
Building on the semantics we discussed so far, we show how out-of-place debuggers can deal with these kind of asynchronous state changes in the following sections.

=== An Example of Asynchronous Resources

To illustrate the challenges introduced by asynchronous resources to stateful out-of-place debugging, we take another detailed look at our running MQTT example (@oop:app:problem).
Developers familiar with the MQTT subscribe operation, would expect it to send a message to the MQTT broker, indicating that the client is interested in a specific topic.
From that moment on, the broker will forward messages of that topic to the client, where they will be handled by a callback function.
To implement this action in our system, we expect it to send the appropriate message to the MQTT broker, and register a callback function for those MQTT message in the runtimes callback handling system.

In stateful out-of-place debugging, the update of the callback system by an action is a clear example of synchronous desynchronization, which is handled at the end of the actions invocation.
However, whenever the client receives MQTT messages, it places these in the event queue of the callback handling system.
This is a clear example of asynchronous desynchronization, which needs to be handled differently.

=== Accessing event-driven non-transferable resources

In order to support event-driven access to non-transferable resources, the out-of-place debugger hijacks the event system of the virtual machine.
Rather than directly executing the callback function whenever an event is received, the event is send from the server to the client, and removed from the event queue in the server.

#figure(
    caption: [The callback system for handling asynchronous events in out-of-place debugging developed as part of our work. The schematic shows how events are forwarded from the server to the client, where they are placed in the WARDuino event queue.],
    image("figures/oopdebugging.svg", width: 100%),
)<oop:forwardevents>

@oop:forwardevents shows a schematic of how the out-of-place debugger handles events in the event system.
Whenever a new event arrives in the event queue of the server runtime, it is forwarded via its debugger stub to the client #circled("A").
The client stores the forwarded events in a local event queue, mirroring the event queue on the server #circled("B").
Events received by the client are not automatically handled.
Instead, they are forwarded to the frontend, to be shown in a dedicated view #circled("C").
Events will be manually resolved upon the developer's request.
When the client receives such a request from the frontend, it will only process the specified event if the partial ordering of events is maintained.
This way, the developer can choose at what point in the code an event should be handled, making it easier to reproduce specific situations.

=== The Callback System in Out-of-place Debugging

We revisit the semantics of stateful out-of-place debugging entirely, since the current semantics have no way of dealing with events produced by non-transferable resources.
We will define a new semantics $attach(dbgarrow, tr: alpha)$ that encapsulates the previous syntax and evaluation rules, but adds support for synchronization and control of event-driven non-transferable resources.

Our callback system adds two instructions to WebAssembly, which can change the callback map in the global store, _deregister_ and _register_.
As our example with MQTT subscribe illustrates, actions can use the instructions to change the map on the server.
It is crucial to have these changes reflected on the client, since it has sole control of the callback system.
However, these changes are still synchronous, so can be dealt with through the invocation rules already presented in @oop:invocation.

It is important to note, that this synchronization is only necessary from server to client, since control over the callback system lies entirely with the latter.
This means, that the server is not able to start a new WebAssembly callback execution autonomously, and therefore does not its callback map synchronized with any local changes on the client side.

// todo i should add an example where a action causes new events to be generated, and another function subscribes the callback, to illustrate that these thigns are independent from each other
// todo because xtof found this confusing. Also this is not a problem right?

The events are another matter, these are generated asynchronously, and so need to be synchronized asynchronously as well.
However, in this case too, synchronization is only necessary from server to client.


=== Controlling the dispatching of Asynchronous Events

While it is important for microcontroller applications to interrupt a program's execution to handle asynchronous events, during debugging this is extremely distracting and confusing.
Debugging relies on giving the developer control over the program's execution, but asynchronous code takes away this control.
Furthermore, there are many non-deterministic bugs that depend on a certain order of events, or only appear when events are processed at certain points in the program @li23:empirical-study.
We therefore want full control over the impact that asynchronous events have on the control flow of the program.

#semantics(
  [
    The semantics of event-driven asynchronous non-transferable resources in out-of-place debugging $attach(#dbgarrow, tr: alpha)$, which encapsulates the relation $dbgarrow$, and provides control over the non-determinism of events to the developer.
  ],
  eventsrules,
  "oop:sem:events"
)

#let partialorder = $<$

@oop:sem:events shows the extended semantics of the out-of-place debugger for handling and controlling asynchronous events, defined as the relation ($attach(#dbgarrow, tr: alpha)$) which extends (#dbgarrow).
To provide developers with control over the event and callback system, the out-of-place debugger disables the automatic dispatching of events, as shown at the top of @oop:sem:events.
Specifically, the debugger will never take the _interrupt_ step.
Instead it provides a new debug message $italic(trigger(j))$, which takes the index $j$ of a event in the queue to be dispatched.
However, some events cannot occur before other events, the most straightforward case is where one MQTT message is the consequence of another.
In such cases, reordering the events may result in execution paths that are impossible without the interference of the debugger.
To prevent the debugger from causing such impossible scenario's, the semantics assumes there is a partial order relation #partialorder for the events in the queue.
At any point in the debugging session, an event can only be dispatched if there is no undispatched event that is smaller under this relation.
The _transfer-events_ rule describes how the client sends events to the server, as soon as the events are received.
Since the event queue is an extension of the WebAssembly state, the same synchronization and updating mechanism is used as before.
We provide a summary of each rule below.

/ trigger: When the client receives a trigger message for event at index $j$, it pops the event from the event queue, and identical to the _interrupt_ rule in @fig:callback-inst (@remote:callback-handling), it calls the corresponding callback function.
/ trigger-invalid: If the index of the event in the trigger message is out of bounds, or the event is invalid, because there are still undispatched events that are smaller under the partial order relation, the server will return an error message.
/ transfer-events: This rule shows how all events arriving on the client are forwarded to the server through the same synchronization message we used before.
    The message includes the events in the queue, and slices of memory containing the events' topic and payload.

// todo add figure with latice to explain ordering of events

// todo adding the **control** over events is not so easy. we need to remove the interrupt rule from the language semantics and replace it with the debug instructions

== Correctness of Out-of-place Debugging<oop:soundness>

Given the presented formalization of stateful out-of-place debugging, we can now proof the soundness and completeness of the approach.
Let us first restate our basic assumptions about the semantics of the out-of-place debugger.

Given that we work on a theoretical model of our debugger, we must necessarily make some assumptions about the real-world.
Specifically, the influence of events on a program's execution is crucial for our debugger, since the debugger allows developers to control the order in which events are processed.
We assume that the behavior of the events can be fully modeled as a partial order, and events can otherwise occur at any point in the program and can follow each other instantaneously.
This assumption can be captured by two important axioms.

First, for any program the asynchronous events follow a partial order #partialorder, known to the debugger.
This requirement is essential to ensure that the debugger does not cause impossible execution paths by triggering events in the wrong order.

#let partialorderlemma = [
  Asynchronous events can be ordered using the partial order #partialorder.
]

#axiom("Event ordering")[#partialorderlemma]<axiom:partialorder>

Second, we will assume that events can follow each other instantaneously, and can occur at any point in the program as long as the partial order allows it.
This implies that any interleaving of partially ordered events in the program is theoretically possible in the language semantics, and so may be explored by the debugger without breaking any soundness or completeness properties.

#let interleavings = [
    Under the partial order #partialorder, any interleaving of events in the program is possible.
]

#axiom("Event interleaving")[#interleavings]<axiom:interleavings>

While we choose a very simple model of the program-environment interactions here, we believe that the assumptions already capture a large part of real-world programs.
We see no reason, why the simple partial order model cannot be extended to more complex models.
We return to this point in @oop:related when discussing related work on _environment modeling_.
With these basic assumptions in mind, we can examine soundness and completeness for the stateful out-of-place debugger---starting with soundness.

#let theoremdebuggersoundness = [
    Let $dbg_start$ be the start debugger configuration with the client containing WebAssembly state $K$. //, and $dbg$ the debugging configuration, where $C$ contains the WebAssembly configuration $K'$.
    Let $dbg$ be a debugging configuration with the client containing WebAssembly state K', and the steps $attach(dbgarrow, tr: alpha comma ast)$ the result of a series of debug messages. Then:
    $ forall dbg : dbg_start attach(dbgarrow, tr: alpha comma ast) dbg arrow.double.r.long K multi(wasmarrow) K' $
]

#theorem("Debugger soundness")[#theoremdebuggersoundness]<oop:theorem:debugger-soundness>
#proofsketch[
    The proof proceeds by induction on the steps in the debugging session. // todo before one message was one step, but now there are also internal messages -> 

    _Base case._ Only a few cases need to be considered, since all other rules cannot be apply to $dbg_start$.
    The following rules do not change the state $K$ in $C$, _play_, _pause_, _step-client_, _run-client_, and _pass-trigger_.
    At any point in a debugging session asynchronous events can arrive in the event queue of the server $S$.
    This means that the first step can be the _transfer-events_ rule, which also does not change the state of $K$ in $C$.

    _Inductive case._ The following rules do not change the state $K$ in $C$, _play_, _pause_, _step-client_, _run-client_, _invoke-start_, _invoke-run_, _invoke-end_, _pass-trigger_, _trigger-invalid_, and _transfer-events_.
    The cases _step-server_ and _run-server_ simply take a step in the underlying semantics.
    The interesting cases are, _sync_, _sync-events_, and _trigger_.

    1. In case of the _sync_ rule, the state $K$ is updated to $K'$. By @lemma:order we know the rule is proceeded by a _step-transfer_ or _run-transfer_ step. These in turn must be followed by an _invoke_ step. By definition of the backward transfer function, we know that the _invoke_ has the same effect, leading to $K''$. Since the forward transfer transmits all changes back to the client, the updated state after the _sync_ rule is equivalent to $K''$.

    2. In the _sync-events_ case, we get the changes from the event queue, which is the same as if the events were dispatched on the server. By @axiom:interleavings, any interleaving of events is possible, thereby an analogous path in #wasmarrow must always exist. //$attach(dbgarrow, tr: alpha comma ast)$.

    3. The _trigger_ rule handles the dispatching of events in the exact same manner as if the events were dispatched on the server.
]

Next we consider the completeness of the out-of-place debugger.

#let theoremdebuggercompleteness = [
    Let $K$ be the start WebAssembly configuration for which there exists a series of transitions $multi(wasmarrow)$ to another configuration $K'$. Let $dbg_start$ be the corresponding starting debugger configuration with $K$ in the client, and $dbg$ the debugging configuration with $K'$ in the client.
    Then:
$ forall K' : K multi(wasmarrow) K' arrow.double.r.long dbg_start attach(dbgarrow, tr: alpha comma ast) dbg $
]

#theorem("Debugger completeness")[#theoremdebuggercompleteness]<oop:theorem:debugger-completeness>
#proofsketch[
    The proof for completeness follows almost directly from the fact that for every transition in the underlying language semantics, the debugger can take a corresponding step.
    We can construct a sequence of step commands of the exact length as the number of steps in $K multi(wasmarrow) K'$. Each step command is handled in one of two ways.

    1. _For steps that can be taken out-of-place_, the debugger gets to the same state with the _step-client_ rule, which uses the underlying language semantics.
    2. _Otherwise_, the debugger uses the invoke mechanism to get an equivalent path. We know the path will use either _step-transfer_ or _run-transfer_, followed by _invoke_ and _sync_. By definition of the backward and forward transfer functions, this gives the same $K'$ in $dbg$.

    Lastly, at any point in the execution in #wasmarrow, the event queue may not be empty, leading to the _interrupt_ rule.
    During debugging the same can happen on the server $S$, which leads to the _transfer-events_ rule.
    After the _sync_ step, the state $K$ in $C$ is the same as at the start of the _interrupt_ rule during normal execution.
    This means that the same callback can be triggered with the _trigger_ rule at the exact same place in the program.
]

//// the event based aspect introduces more complexity
//
//// todo conclude

Given the proofs of completeness and soundness, we can conclude that the operations of the out-of-place debugger do not interfere with the underlying language semantics.
It is important to acknowledge again, that the correctness of the debugger is based on the following assumptions; the underlying language semantics is sound, the control flow of the program is only influenced by the order of events and not their concrete timing, and events can arrive at any time under the given partial order of events.

== Implementation<oop:implementation>

// todo show vs code plugin
We have implemented the stateful out-of-place debugger formalized above in a prototype debugger, called #emph[Edward].
The #emph[Edward] debugger is built on top of the WARDuino runtime @lauwaerts24:warduino, a WebAssembly runtime for microcontrollers.
The prototype provides the features described in the previous section.// for Internet of Things applications that compile to WebAssembly.
//The implementation leverages the existing stateless implementation of the WARDuino runtime, and extends it with the necessary infrastructure for state synchronization.
//This involved extending the existing communication protocol with the necessary messages for state synchronization, and refactoring the communication infrastructure of the runtime to handle the new messages.
Additionally, we created a new high-level interface for defining actions which integrates the state synchronization interface described in @oop:semantics.
The stateful debugger can be used in VS Code to debug AssemblyScript programs running on an instance of the WARDuino runtime, thanks to a dedicated extension to the VS Code IDE.

=== Virtual Machine Requirements<subsec:requirements>

In order to implement out-of-place debugging, any candidate VM must support the following:

    + Standard instrumentation required for halting and stepping through a program.
    + Support forward and backward state transfer for non-transferable resources.
    + Update the state provided the data received from the transfer functions.
    + Capture and serialize all asynchronous events produced by non-transferable resources.

First, the virtual machine needs to support the elementary debug commands of any online debugger, which at least include halting and stepping through a program.
Second, as we have demonstrated, state synchronization is equally fundamental for out-of-place debugging.
The virtual machine should be able to support forward and backward state transfer for non-transferable resources.
//In our implementation, the virtual machine provides primitives for state serialization, that allow developers to easily implement the transfer functions for the actions on non-transferable resources.
Third, given the data provided by the transfer functions, the virtual machine must be able to update its own state.
Four, the virtual machine must be able to capture and serialize all asynchronous events produced by non-transferable resources.
Thereby allowing them to be forwarded from server to client.

#snippet("oop:action",
    columns: 2,
    [The implementation of the MQTT #emph[subscribe] action in the WARDuino runtime, without stateful out-of-place support.],
    (```cpp
void subscribe_internal(Module *m,
    uint32_t topic_param,
    uint32_t topic_length,
    uint32_t fidx) {
  const char *topic =
    parse(m, topic_length, topic_param);

  mqttClient.subscribe(topic);

  Callback c = Callback(m, topic, fidx);
  CallbackHandler::add_callback(c);}
```, ```cpp
def_action(subscribe, threeToNoneU32) {
  uint32_t topic = arg2.uint32;
  uint32_t length = arg1.uint32;
  uint32_t fidx = arg0.uint32;

  subscribe_internal(
    m, topic, length, fidx);

  pop_args(3);
  return true;
}
```,))

=== Example: the MQTT Subscribe Action
//== Stateful Actions for Non-transferable Resources

To illustrate how the new interface for defining stateful actions works, we will discuss the implementation of the MQTT #emph[subscribe] action.
The subscribe action is exposed in the runtime as a WebAssembly function that takes three unsigned 32-bit integers as arguments, corresponding to the location of the topic string in WebAssembly memory (offset and length), and the function index of the WebAssembly, which will act as callback function for events from the topic.
Actions are implemented directly in the WARDuino virtual machine using C macros.
In order to implement stateful actions, we have extended the existing macros with two new macros.
We will discuss each macro in turn.

@oop:action shows the standard implementation of the subscribe action using the #emph[def\_action] macro.
We have split the definition into an internal function, shown on the left, and the interface definition on the right.
The internal function implements the behavior of the subscribe action, it receives as parameters the WebAssembly $m$ module in which it is executed, and the offset and length of the topic string, and the function index.
On line 6, the parse function will extract the topic string from the WebAssembly memory and parse it as an UTF8 string.
Using the MQTT client the action will subscribe the microcontroller to the given topic.
For brevity, we have left out the exception handling, in case the MQTT client has not been initialized, or the communication with the MQTT broker fails.
// todo how does the full implementation handle this?
After subscribing successfully, any messages from the MQTT broker will be routed to the concurrent callback system in the runtime.
On lines 10 to 11, the action registers the WebAssembly function with index #emph[fidx] to the callback environment.
This way, the callback system will concurrently call the function whenever a new message arrives.

The interface definition on the right side of @oop:action defines the action as a proper WebAssembly function using the #emph[def\_action] macro.
The macro takes the name of the action, and its type as arguments.
In the example, the subscribe action takes three arguments and returns nothing. // todo our semantic requires actions to return a value
The body of the macro takes the arguments from the stack and passes them to the internal function which performs the action.
At the end the macro lifts the consumed arguments from the stack, and returns true.
The boolean value returned by actions is used to indicate failure, and are used by the runtime to throw WebAssembly traps in case something goes wrong.

=== Stateful Actions for Non-transferable Resources

//\begin{figure}
//    \begin{minipage}[t]{.48\textwidth}
//        \begin{lstlisting}[language=C++, style=CStyle,escapechar=']

//\end{lstlisting}
//    \end{minipage}
//    \hfill
//    \begin{minipage}[t]{.48\textwidth}
//        \begin{lstlisting}[language=C++, style=CStyle,escapechar=',firstnumber=27]
//// on client
//def_to_server(subscribe) {
//  // add transfer to update callback env
//  sync_callback();
//}\end{lstlisting}
//    \end{minipage}
//    \caption{}
//    \label[listing]{fig:transfer}
//\end{figure}

#snippet("oop:transfer",
    columns: 2,
    [The implementation of the transfer functions for the MQTT #emph[subscribe] action in the WARDuino runtime, to enable stateful out-of-place support.],
    (```cpp
// on server
def_to_client(subscribe) {
  uint32_t topic = arg2.uint32;
  uint32_t length = arg1.uint32;

  // add transfer to be send with invoke
  sync_memory(m, topic, length);
}
```, ```cpp
// on client
def_to_server(subscribe) {
  // add transfer to update callback env
  sync_callback();
}
```,))

In order to enable stateful out-of-place debugging with the subscribe action, we need to define both the transfer from server to client, and vice versa.
Analogous to the action definition this can be done in WARDuino using C macros, however, we also provide a number of primitives for constructing transfers.
The primitives hide the specifics of the debugger's communication protocol, and allow library implementers to focus exclusively on what state needs to be transferred for a given action.
In essence, each primitive will extend a hidden transfer object with the necessary information, and when the debugger sends the invoke message, it will serialize the constructed transfer and include it in the message.


@oop:transfer shows the implementation of both transfer functions for the subscribe action.
The left side of the figure, shows how the server must transfer state to the client, and the right side how the client must perform the action and return the state changes to the server.

Consider first the server, the #emph[def\_to\_client] macro defines the transfer function for the subscribe action, which in our semantics is used in the _step-client_ rule.
Since the transfer is created right before the action should be performed, it can easily look at its arguments on the stack.
The subscribe action only relies on the topic string in WebAssembly, so the transfer only needs to sync this slice of memory.
This can be done with one of the primitives we provide to help with the state synchronization, in this case #emph[sync\_memory].
The primitive takes as arguments, a WebAssembly module, offset, and length, and will add the slice of memory to the transfer.

For the client, the #emph[def\_to\_server] macro works slightly differently, it is executed after the action has been performed, and needs to define which state needs to be synchronized.
In the case of our example, only the callback map is updated by the subscribe action.
For the transfer we can use the #emph[sync\_callback] primitive which will add to the transfer, the minimal necessary data to update the callback environment on the server.

=== Prototype: Testing and Debugger Frontend


//\begin{figure}
//    \centering
////    \begin{minipage}{.45\textwidth}
////      \includegraphics[width=\linewidth]{./figures/tests.png}
////    \end{minipage}%
////    \hfill%
//\begin{minipage}{\textwidth}
//  \includegraphics[width=\linewidth]{./figures/vscode.pdf}
//\end{minipage}%
//    \caption{%#emph[Left:] The output of a small sample of the test suite for the out-of-place debugger, using the underlying virtual machine's own testing framework called Latch~@lauwaerts24:latch. #emph[Right:]
//A screenshot of the out-of-place debugger in VS Code.}
//  @fig:implementation
//\end{figure}

#let screenshot = rect(inset: 0mm, image("./figures/screenshots/vscode.png", width: 80mm))
#figure(caption: [//#emph[Left:] The output of a small sample of the test suite for the out-of-place debugger, using the underlying virtual machine's own testing framework called Latch~@lauwaerts24:latch. #emph[Right:]
A screenshot of the out-of-place debugger in VS Code.],
  cetz.canvas({
    import cetz.draw: *

    content((0,0), (8,8.29), screenshot, name: "screenshot")

    rect((0.42,6.5), (2.60,3.29), stroke: (thickness: 0.4pt, dash: (2pt, 2pt), join: "round"))
    content((-0.42, 6.4), align(right, text(weight: "semibold", size: script, font: serif, [Event \ queue])))

    rect((0.42,7.98), (2.60,7.70), stroke: (thickness: 0.4pt, dash: (2pt, 2pt)))
    content((-0.65, 7.9), align(right, text(weight: "semibold", size: script, font: serif, [Debug \ commands])))

    rect((5.64,7.54), (7.40,7.26), stroke: (thickness: 0.4pt, dash: (2pt, 2pt)))
    content((8.90, 7.54), align(left, text(weight: "semibold", size: script, font: serif, [AssemblyScript \ library for access \ to actions])))
}))<fig:implementation>

Our prototype implementation on top of the WARDuino runtime allows developers to use the existing VS Code extension for the warduino debugger to debug AssemblyScript programs using stateful out-of-place debugging.
@fig:implementation shows a screenshot of the debugger frontend in VS Code.
The frontend supports the standard debug operations, pause, play, step forward, step into, step over, and breakpoints.
Additionally, the extension features a view of the current events in the event queue on the server.
These events can be triggered at any point by the developer, similar to performing a step.

We tested the prototype implementation, by checking the invoke non-interference as described in @oop:semantics.
To test this empirically, we randomly generating a thousand simple WebAssembly programs, which included a number of actions that changed the memory in the WebAssembly module.
We ran the programs both with and with the out-of-place debugger, and verified that the memory at the end of the program was indeed identical for each program.
//Secondly, we extended the existing unit testing framework from the WARDuino project to support testing of our stateful out-of-place debugger, and extended the existing test suite for the WARDuino remote debugger with tests specific to stateful out-of-place debugging.
//We show a small part of the test suite's output on the left of \cref{fig:implementation}.
//The entire suite consists of 60 unit tests.

//= Evaluation<oop:evaluation>
//
//To evaluate the performance impact of out-of-place debugging, we analyze the execution time of remote action calls, and the communication overhead during debugging of a series of small programs with a heavy reliance on non-transferable resources.
//The programs were taken from the official Arduino documentation's built-in examples.
//These programs were selected because they are representative for typical Internet of Things programs for microcontrollers, and they are well documented.
//Furthermore, these small examples are often very often more non-transferable resource heavy than more complex programs, as they are used to demonstrate the capabilities of the microcontroller.
//This means they present the worst case scenario for performance, and are therefore a good test case for the out-of-place debugger.
//
//\begin{figure}
//\centering
//\begin{subfigure}{.5\textwidth}
//  \centering
//  \includegraphics[width=.9\linewidth]{./figures/placeholder.png}
//\end{subfigure}%
//\begin{subfigure}{.5\textwidth}
//  \centering
//  \includegraphics[width=.9\linewidth]{./figures/placeholder.png}
//\end{subfigure}
//\caption{The performance impact of out-of-place debugging.} % todo
//@fig:performance
//\end{figure}

=== Debugging Common Bug Issues<oop:debugging-common-bug-issues>

As mentioned in the @chapter:introduction, a 2021 study on _"5,565 bugs in 91 Internet of Things projects"_ showed that the most frequent types of bugs are related to software development and device issues @makhshari21:iot-bugs.
In this section, we show an example program illustrating how out-of-place debugging better accommodates finding and solving device issues than regular remote debugging.
@subsec:concurrency provides a similar comparison but for a software development issue due to concurrency. // todo add appendix

#strong("The Bug.") Many device issues are related to handling interrupts @makhshari21:iot-bugs.
@oop:hardwareproblems shows a simple AssemblyScript application that toggles an LED when a button is pressed.
The code listens for a hardware interrupts triggered on the falling edge of the button pin (line 11).
Upon receiving an interrupt, the `buttonPressed` function is called, which toggles the LED (line 7).
While the code may not contain errors, the hardware can cause bugs in it.
Consider the following bug scenario: when testing the application with a real button, the LED sometimes does not change despite the button being pressed.

#figure(kind: illustration.hidden, supplement: [], grid(columns: (1fr, 1fr), align: end, column-gutter: 2mm, snippet("oop:hardwareproblems",
    columns: 2,
    [A simple AssemblyScript program that toggles an LED when a button is pressed.],
    (```ts
import * as wd from warduino;

const LED: u32 = 25;
const BUTTON: u32 = 26;

function buttonPressed(): void {
  wd.digitalWrite(LED, !wd.digitalRead(LED));
}

export function main() : void {
  wd.interruptOn(BUTTON, wd.FALLING, buttonPressed);
  while(true);
}
```,)), [#figure(caption: [The debugger frontend shows a list of identical interrupts after a single button press.],
  rect(inset: 0mm, image("./figures/screenshots/manyevents.png", width: 100%)))
<fig:manyevents>]))

#strong("Bugfixing with a Remote Debugger.") With a regular remote debugger, developers could start their diagnosis by adding a breakpoint in the `buttonPressed` callback function triggered when pressing the button.
Note that in this simple example, there is only one single callback function,
but in more complex Internet of Things applications developers may need to place breakpoints in many callback functions as it is difficult to rule out which ones are not causing to the faulty behavior.
//the developer will notice that the \lstinline{buttonPressed} function is actually called when pressing the button.

Stepping through code with asynchronous callbacks is generally not easy with current state of the art remote debuggers.
//%In more complex applications with many callbacks, the developer needs to manually place a breakpoint at each callback function in order to debug the application.
Keeping track of all the asynchronous callbacks increases the number of times a developer needs to manually step through the application before discovering the error, complicating debugging. //as Internet of Things applications typically have many callback due to its event-driven nature.
Moreover, stepping through the code is relatively slow, as the network latency between the developer's machine and the remote device slows down the debug session.
Finally, most applications will not feature a busy loop as in our example, but the main thread runs concurrently with the asynchronous invocations, making it harder to notice errors.
//%Furthermore, most application code will have much more complex code in the main thread than a simple busy loop as in our example.
//%This means that the code in the main thread is running concurrently with the asynchronous invocations, making it harder to notice errors.
//%\carlos{This argument feels weird to me. To show that remote debugging fig 10 is hard. We make up a complex application that consists of a greater amount of callbacks and a complex main and basically say "because it is hard to remote debug the complex application then we can conclude that it is also hard to debug the much simpler example i.e., fig 10".}

Once the developer has stepped through all the asynchronous code letting the callbacks execute, the de developer might notice that the `buttonPressed` callback is strangely invoked multiple times.
The reason is that a single button press can trigger multiple hardware interrupts due to a common problem of physical buttons called _contact bouncing_ @mcbride89:electrical.
Contact bouncing happens when the voltage of a mechanical switch pulses rapidly, instead of performing a clean transition from high to low.
In that case, the pin can register a falling edge multiple times in a row.
Subsequently, the `buttonPressed` function is triggered multiple times for a single press.
If contact bouncing causes the function to be triggered an even number of times, the state of the LED seems to remain the same, making the developer believe the code does nothing.
// remain the same to the human observer.
It is not trivial to deduce the underlying contact bouncing problem by only stepping through the program. //without any extra information.

#strong[Bugfixing with _Edward_.] Let us now revisit the scenario using out-of-place debugging.
_Edward_ provides the developer with a dedicated view on the event queue with all asynchronous events that happen on the remote device, and the ability to choose when the next event happens.
When the developer pushes the physical button once during debugging, they will immediately notice that _Edward's_ events view suddenly contains multiple identical events for a single button press, as shown in @fig:manyevents.
This information enables the developer to more easily detect the contact bouncing issue. // without even having to step through the code.

If the developer has not yet deduced the root cause of the bug, they could use stepping through the code in a similar way than when using the remote debugger.
However, this time, stepping through the code is faster as debugging happens locally without incurring in network communication.
Moreover, the frontend of _Edward_ support an early, naive implementation of backward debugging.
This means that during debugging when the LED does not turn on, the developer can step back to the previous step to diagnose what exactly went wrong during the execution.
There is no need to restart the program and try to guess what the right conditions for the bug were.
However, external changes are not reverted.
When an LED turns on, stepping backwards does not turn it off again, since the backwards step is only implemented naively in the frontend using snapshots of the virtual machine state.
In @chap:multiverse we will discuss how to improve on this, by making actions reversible in a multiverse debugger.

#strong("Conclusion.") This example illustrates that using out-of-place debugging makes a difference when debugging device issues compared to a remote debugger.
Since _Edward_ captures all non-transferable resources and provides a view on the event queue with all asynchronous events that happened at the remote device, developers can more easily diagnose device issues.
For those cases where stepping is still needed, this happens with low latency.
_Edward_ also allows developers to step backwards, potentially reducing the debugging time as applications may not need to be restarted to reproduce the conditions for the bug to appear.

//=== preliminary quantitative evaluation<oop:quantative>

//
//// todo rework + add random generated programs
//// todo forward reference to latch (as the framework for testing the implementation)
//
We now present some preliminary quantitative evaluation of _Edward_, to underscore the potential of our approach to reduce performance impact while debugging Internet of Things devices.
////%to reduce the performance impact of debugging Internet of Things devices.
////%\Oop debugging avoids as much as possible network communication to the Internet of Things device during an out-of-place debug session, reducing latency while debugging and network overhead.
////%\Oop reduces the performance impact primarily by avoiding as much as possible the main bottleneck of remote debugging, accessing the device.
//
//\begin{figure}
//\begin{tabular}{ lrr }
//                      & \#Instructions &  \\
// Location independent & 2092 & 99.15\% \\
// \Nt                  &   18 & 0.85\% \\
// \hline
// Total                & 2110 & 100\% \\
//\end{tabular}
//\caption{Labeling of Wasm instructions for a smart lamp application (\cref{app:concurrency} in \cref{subsec:concurrency}).}
//\label{tab:colouring}
//\end{figure}
//
//\paragraph{Code Analysis.} To analyze the potential communication needed between debugger and remote device, consider the smart lamp application written in AssemblyScript allowing users to control the brightness of an LED (cf. \cref{app:concurrency} in \cref{subsec:concurrency}).
//
//While remote debugging requires network communication between debugger and the remote device for \emph{all} debugging operations and all types of instructions,
//\oop debugging only requires network communication for those instructions that access \nt resources.
//In order to get an estimate of the amount of instructions which are location dependent compared to the non-transferable instruction we labeled each of the Wasm instructions of the smart lamp application's code as a location-independent instruction, or an instruction that accesses a \nt resource. The results shown in \cref{tab:colouring} confirm our suspicion that location-independent instructions outweigh instructions accessing \nt resources.
//
//%Our benchmarks were conducted using an ESP32-DevKitC V4 board\footnote{\url{https://docs.espressif.com/projects/esp-idf/en/latest/esp32/hw-reference/esp32/get-started-devkitc.html}} connected with a dell xps 9310 laptop through a local network. This board features an ESP32 WROVER IE chip that operates at 240 MHz, with 520 KiB SRAM, 4 MB SPI flash and 8 MB PSRAM.
//
//\paragraph{Network Overhead.}
//In order to get an estimate of the difference in network overhead between remote debugging and \oop debugging we benchmarked the (debugging) network overhead of the smart lamp application. 
//Our benchmarks were performed on a M5StickC~\cite{m5stickc} connected to a MacBook Pro with an Apple M1 Pro chip operating at 3.2 GHz CPU and 32GiB of RAM, through a local network.
//
// \Cref{fig:remote_debugging_overhead} plots the network overhead of stepping through the application with a remote debugging session. As we can see, there are small step-wise fluctuations caused by the changing amount of local variables in the program. The network overhead for each debugging step is approximately 2.2 kB.  
//
//For \oop debugging, we benchmarked the network overhead of taking a full snapshot at each remote stepping operation, i.e. the network overhead involved with starting an out-of-place debugging session. Note that in practice the developer needs to perform this operation only once.
//\Cref{fig:remote_snapshot_overhead} shows the results of taking a snapshot at each stepping operation of the smart-lamp application. 
//As expected, the network overhead involved with taking a full snapshot is much higher than a single debugging step, each full snapshot takes approximately 130 kB. 
//
//The significant difference in network overhead between a remote debugging step and a full snapshot is expected and is mostly because the snapshot captures the stack and a full memory dump of the running application.
//
//Luckily, once a snapshot has been taken the debugging session can be executed locally and the subsequent debugging  session will be much faster. Avoiding access to the remote device reduces network overhead and lowers debugging latency. The network overhead for proxied calls is much smaller than a normal debugging step and takes at most 10 bytes per remote call with an additional 4 bytes per argument. More importantly the network overhead for stepping through each of the location independent instructions is zero.
//
//\paragraph{Latency.}
//Finally, we also benchmarked the difference in latency between local debugging steps and remote debugging steps. When stepping through the smart-lamp application with \oop debugging, we find that local steps take on average approximately 5ms while a remote \emph{proxy call} takes approximately 500ms. 
//
//In practice this means that the developer using \oop debugging will perceive almost instantaneously local debugging steps interleaved with remote calls which are perceived slower. As these non-transferable instructions make up less than  1\% of the code, most debugging steps will be able to be executed fast.
//
// \begin{figure}[t]
//\begin{center}
//		\includegraphics[width=1\columnwidth]{figures/remote_step_overhead}
//                \caption{Network communication overhead of 30 step operations using remote debugging.
//                         Note that the overhead axis starts at 2kB.}
//                //%     \robbert{Graph should start at 0, maybe results from \cref{fig:remote_snapshot_overhead} should also be included here}
//                //%     \robbert{A graph of \oop debugging would also be nice, with a giant spike at index 0 and almost nothing for the rest}
//                //%     \robbert{Could the raw data be placed in the repo?}
//		\label{fig:remote_debugging_overhead}
//\end{center}
//\end{figure}

== Discussion<oop:discussion>

//After evaluating our experimental prototype in several practical scenarios, 
Before giving a detailed overview of the related work, we now consider the wider context of our work and outline the advantages and disadvantages of our design decisions.

#heading(numbering: none, level: 4, "On the design choices")

This chapter presents the first formal foundation for out-of-place debugging and address within it the important challenge of state desynchronization, which has been neglected by previous works.
This resulted in the first stateful out-of-place debugger implementation.
We choose to focus on the context of microcontroller programming, as it is a domain where out-of-place debugging can provide significant benefits, and where the support for stateful operations is crucial.
The resource constraints imposed by microcontrollers are the main motivation for out-of-place debugging in this context, which inevitably impacted the design choices we made in a significant manner.

The impact of the resource constraints especially impacted the first of our key assumptions, that underlie our formalization.
To minimize the impact of transfering state, we require that state dependencies of the actions can be know statically.
This allows both client and server to quickly determine which parts of the state need to be transferred, without the need for expensive analysis procedures.

Additionally, we have chosen to keep the modeling of the asynchronous events simple, by only considering the order of events and assuming that any interleaving of events in the program is possible.
The main motivations for this choice, were to reduce the complexity of our formalization, and keep the focus on how out-of-place debugging can be extended with stateful operations, and how this can be formalized.
Certainly more complex and accurate models for the events exist, which do take into account the interleavings, and the exact timing of events.
Using existing models for event interleaving, it should be possible to weaken our assumptions, and thereby relax the requirements our system puts on stateful actions.

#heading(numbering: none, level: 4, "Opportunities for advanced environment modeling") 

The current abstract of asynchronous events in our debugger semantics is a very simple model of the environment.
The model does not take into account the exact timing of events, and assumes all interleaving of events are possible.
However, such timings and interleavings are crucial for many applications @lamport78:time.
Luckily, this problem has been extensively studied in the field of distributed systems, and a wide range of models exist to capture the asynchronous behavior.
Likewise, the literature on automated testing has a broad range of techniques for modeling the environment.
We give a brief overview of the literature on synchronization and consistency in distributed systems, and environment modeling in testing.

== Related Work<oop:related>

We have discussed the different implementations of out-of-place debugging extensively in @oop:intro and @oop:background.
In this section, we will discuss other related works.

#heading(numbering: none, level: 4, "Remote debugging")

In remote debugging @rosenberg96:how, a debugger frontend connects to a remote backend that executes the target program.
However, remote debugging may worsen the probe effect @gait86:probe and can experience significant delays due to the overhead of running the debugger on the microcontroller coupled with continuous communication requirements.
Regardless, due to the ability to debug remote processes, remote debuggers are ubiquitous in software development, with popular debuggers such as GDB @gdb and LLDB @remote, as well as default support for remote debugging by many development environments @mikejo500025:remote.
We have thoroughly discussed the related work on remote debugging in @remote:related-work.

// todo need more on alternative debugging solutions

// todo add related works from original oop paper + expand

#heading(numbering: none, level: 4, "Remote debugging embedded systems")

@remote:related-work we also discussed remote debuggers in the context of embedded devices.
The notable examples included, the popular OpenOCD debugger @hogl06:open, Espruino for JavaScript @williams14:espruino, and MicroPython for Python @george21:micropython.
The debugging support varies widely between these solutions, but  .
//For example, Espruino~@williams14:espruino enables remote debugging of JavaScript programs and allows developers to modify source code to log runtime information (e.g., stack traces), which is either forwarded to a debugger client or stored on the microcontroller if the client is disconnected.
//In contrast, MicroPython~@george21:micropython does not offer a remote debugger, requiring programmers to rely on printf statements for debugging.
//Wasm3 introduces a source-level remote debugger integrated with GDB @shymanskyy23:wasm3wasm-debug, though this feature is in its early stages and has not been actively maintained for the past two years.
In comparison, our work not only delivers a remote debugging experience but also provides online debugging with minimal latency on demand.
Moreover, to the best of our knowledge, no other approach offers developers the ability to access and control the processing of events generated by the remote device.

#heading(numbering: none, level: 4, "Synchronization and consistency in distributed systems")

In our work, the out-of-place debugger comprises two remote processes, the server and the client.
The semantics of the debugger clearly describe the synchronization between these two devices, however, if we were to extend the debugger to multiple devices, the synchronization would become much more complex.
Synchronization in distributed systems has of course been widely studied.
Clock synchronization goes back to the earliest distributed systems in the seventies and eighties @lamport78:time @kopetz87:clock @schmuck90:continuous, and has been a crucial part of distributed systems ever since @auguston05:environment. // todo auguston05 is wrong
In fact, with the rise of internet of things applications, the problem has received renewed attention @mani18:architecture @yi-gitler20:overview.

More generally, the problem of replicating data and consistency within a distributed network is an enormous field of research on its own.
Much effort has been put into developing solutions for (strong) eventual consistency, where the requirement for synchronization is weakened to allow for higher availability.
A common approach is to use conflict-free replicated data types (CRDTs) @shapiro11:conflict-free-replicated-data-types, which allow for concurrent updates to data without the need for any coordination @almeida24:approaches.
It is an open question whether eventual consistency is enough for out-of-place debugging, or whether stronger consistency guarantees are needed.
However, many other forms of consistency exist, such as sequential consistency @lamport79:how, causal consistency @terry94:session @perrin16:causal, and linearizability @herlihy90:linearizability.
It is our believe that the type of consistency used in out-of-place debugging is tied strongly to its application context.
//guarantees such as linearizability~@herlihy90:linearizability are certain to suffice for out-of-place debugging of multiple devices.
Yet given the vast amount of work in this field, we believe that the existing techniques for consistency can be used to generalize our formalization to multiple devices, and to further strengthen the formal guarantees.

#heading(numbering: none, level: 4, "Program slicing")

Given the microcontroller setting, our approach determines the state needed to be transferred statically as part of the definition of the actions on non-transferable resources.
However, for more complex actions, it would be advisable to use static analysis to determine the slice of the state.
This is very similar to program slicing @weiser81:program @xu05:brief which decomposes a program into segments based on a #emph[slicing criterion].
This criterion can slice in two directions, either #emph[backward] when identifying segments that might affect the criterion, or #emph[forward] when the segments is affected by the criterion.
In our semantic, the transfer at the start of an invocation is similar to backward slicing, and the difference returned at the end is similar to forward slicing.
Many different techniques for slicing exist @xu05:brief, both dynamic and static, or hybrid.
Only a few works have looked into static @stievenart22:static and dynamic @stievenart23:dynamic slicing of WebAssembly programs, however, many of the existing techniques can be expected to work with WebAssembly as well, without great difficulty.

#heading(numbering: none, level: 4, "Environment modeling")

Environment modeling is a technique used in testing to model the behavior of the environment in which a program runs @blackburn98:using.
Such models are often used for automatic test generation @dalal99:model-based @auguston05:environment for a certain specification, and has also been applied to real-time embedded software @iqbal15:environment.
Our work models the asynchronicity of the environment through a simple partial order of instantaneous events.
This model enables exploring different behavior based on the order of events, and to a certain extent the timings of asynchronous events.
More advanced models of the environment could help take into account additional dependencies between events, and real-time effects.

== Conclusion<oop:conclusion>

While existing out-of-place debuggers can already support a wide range of programs and application domains with purely stateless operations on non-transferable resource, they lack support for stateful operations or provide only some very minimal ad hoc support.
In this work, we address this limitation by presenting the first formal semantic for out-of-place debugging, in which we incorporate our novel stateful out-of-place debugging technique.
Our approach allows for the debugging of programs with stateful operations on non-transferable resources, with a lazy synchronization strategy where state is only send to the client device when it is required.
Our formalization allows us to also define correctness for stateful out-of-place debugging, which we divide into soundness and completeness.
The proof for these theorems show that stateful out-of-place debugging is able to debug programs without introducing impossible execution paths, or missing concrete paths.
We have implemented our approach in a prototype debugger, called #emph[Edward], which is built on top of the WARDuino runtime, and VS Code extension.
Initial empirical testing shows that our implementation indeed satisfies the correctness criteria defined in our formalization.

//= Auxiliary Debugger Rules<app:rules> // todo move to appendix
//
//In \cref{fig:aux} we show the auxiliary definitions for the semantics presented in \cref{oop:semantics}, which were elided from the main text for brevity.
//
//\begin{figure}[ht!]
//            \[
//	\begin{array}{ l l c l }
//        #emph[(Construct call)] & _construct-call_(s,\xi)    & colon.double.eq (\textbf{i32.const } \xi_{textsf{topic}}) (\textbf{i32.const } \xi_{\textsf{payload}}) \\
//                                &                                 &            & (\textbf{i32.const }s_{\textsf{callbacks}}(\xi_{\textsf{topic}})) \\
//                                &                                 &            & \textbf{ call\_indirect } \textsf{i32} \times \textsf{i32} \times \textsf{i32} \times \textsf{i32} \rightarrow \epsilon \\
//
//        \end{array}
//    \]
//    \caption{The auxiliary definitions for the semantics presented in \cref{oop:semantics}.}
//    @fig:aux
//\end{figure}
//
//% todo add breakpoints

