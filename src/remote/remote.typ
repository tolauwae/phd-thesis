// pseudocode
#import "@preview/lovelace:0.3.0": pseudocode, with-line-label, pseudocode-list, line-label

// code snippets
#import "../../lib/util.typ": line, range, code, snippet, circled, algorithm, semantics
#import "../../lib/fonts.typ": monospace, small, script, monot
#import "../../lib/class.typ": note, theorem, proofsketch

// figures
#import "images/barcharts.typ": espruino

// reduction rules
#import "@preview/curryst:0.5.0"

Developing and investigating novel debugging techniques for microcontrollers within our new formal framework, requires an easy way to instrument the program execution, and ideally prototype new debuggers quickly.
The best way to achieve this is unarguably, to use a virtual machine that can run on the microcontrollers.
Luckily, earlier work at Ghent University, developed just such a virtual machine, called WARDuino---which was the first-ever WebAssembly virtual machine for microcontrollers @gurdeep19:warduino.

However, the original work was limited to a proof of concept, and many of the promises of the new WebAssembly-based approach to programming microcontrollers were not fully realised---such as, programming in high-level languages, highly portable code, the ability to easily handle asynchronous events, and by extension support for asynchronous I/O actions.
In this chapter, we present a more complete version of WARDuino, developed as part of this dissertation.
We will discuss the full range of features and benefits of the new approach to programming microcontrollers proposed by WARDuino.

Three features of WARDuino, and in particular their formalisation, will be crucial for developing our advanced out-of-place and multiverse debugging techniques, in the later chapters of this dissertation.
These are the (1) the _remote debugger_, (2) atomic _actions_ for I/O operations, and the (3) _asynchronous event-driven callback system_ in the virtual machine.

However, we will start at the beginning.
Why is debugging seen as such a frustrating task in the embedded world?
How can virtual machines help with this?
And what are the broader challenges in embedded development that a WebAssembly-based virtual machine for microcontrollers can help overcome?

== Challenges of Programming Microcontrollers

Recent advances in microcontroller technology have enabled everyday objects (things) to be connected through the internet. Smart lamps, smart scales, smart ovens and refrigerators have all become commodity devices which are connected through the internet, making up the Internet of Things (IoT). This is largely thanks to microcontrollers—small and energy efficient computers—becoming very cheap. However, the drawbacks of microcontrollers are their limited processing power and memory size. Furthermore, microcontrollers typically do not run a full-fledged operating system @vansickle01:programming, but instead run statically compiled firmware, or a tiny real-time operating system (RTOS) @tan09:real-time@hambarde14:survey@de23:evaluating specialized for microcontrollers. Due to these differences and the resource constraints of the underlying hardware, developing software for microcontrollers differs significantly from conventional computer programming, where these severe constraints do not exist to the same degree.
The WARDuino virtual machine seeks to close this gap, and focus on the following six major challenges unique to IoT development.

/ Low-level coding.: First, embedded software are usually written in low-level programming languages, such as C @kernighan89:c-programming-language@aspencore23:embedded. Although C is very efficient, developing programs in C is error-prone and time-intensive. Crucially, C requires developers to manually manage memory allocations which has been shown to be notoriously difficult for complex programs @van-der-veen12:memory@english19:exploiting.

/ Portability.: Second, many of the functionalities of a microcontroller are memory mapped, these mappings are highly specific for each microcontroller and can differ even between devices of the same microcontroller family. Completely different microcontrollers vary even more in the way they initialize and control peripherals. Therefore, porting programs from one platform to another can be difficult and time-consuming.

/ Slow development cycle.: Third, uploading programs to a microcontroller is a slow and tedious process. For every change in the program, however small, the entire program must be recompiled and flashed (uploaded) to the device. This slows down the development cycle as developers need to wait for this process to finish before they can test their programs.

/ Debuggability.: Fourth, debugging facilities are often not available for microcontrollers without (expensive) hardware debuggers. Even then, the debuggers usually only work for the C language. The lack of debugging facilities makes that developers cannot easily inspect the internal state of a microcontroller. They can only observe its external behavior, for example, that an LED that should be blinking, instead remains off. When the device is not behaving as expected, it is difficult to find the root cause of the problem. Many developers resort to printing values to the serial bus to figure out what the device is doing when something goes wrong @makhshari21:iot-bugs, but this is very slow and inconvenient.

/ Hardware limitations.: Fifth, the embedded devices powering IoT applications have severe hardware limitations compared to conventional computer systems. The most important and universal constraints for these devices, are their limited processing power and memory size.

/ Bare-metal execution environments.: Finally, due to their heavy constraints, microcontrollers rarely run full-fledged operating systems. Instead, software is run on top of a tiny RTOS, or simply as statically compiled firmware.

== Programming Microcontrollers with High-level Languages

Many of the difficulties in programming microcontrollers disappear when using higher-level languages.
The abstractions in these languages can prevent whole classes of bugs and can ease development. Specifically, high-level languages relieve the programmer from manual memory management, and can provide stronger type systems to further avoid mistakes. They also make it easier to support advanced features such as over-the-air updates—where software is updated without flashing via a physical connection—and remote debugging, where a device is debugged through instructions sent from another remote device.

Some high-level languages have been ported to embedded devices using small custom virtual machines @williams14:espruino@zerynth-s-r-l-21:zerynth@nanoframework-contributors21:net-nanoframework. Unfortunately, these virtual machines only support a subset of the language’s features and only work on a specific range of hardware platforms. A popular example is MicroPython @george21:micropython, which is a subset of Python for microcontrollers. For performance reasons access to the peripherals is often baked into high-level programming language. In MicroPython support for displays and sensors is baked into the language and implemented directly in C. As such, if a specific peripheral device is not supported, the language is of limited use. Another issue, is the lack of debuggers for these languages. This is also the case for MicroPython, which has no official debugger, and third party alternatives are very limited. The Mu debugger for example, supports only classic breakpoints and step instructions, and works exclusively on Raspberry Pi devices, which are much more powerful than embedded devices under consideration in this chapter. Finally, many high-level languages do not directly support embedded devices at all, as we will discuss further in @remote:related-work.

//== WebAssembly: a Promise of a Universal Compile Target
== WARDuino: WebAssembly for Microcontrollers

In this work we take a different approach aimed at enabling multiple high-level languages on microcontrollers while mitigating their downsides.
To accomplish this goal, we created WARDuino~@gurdeep19:warduino, a virtual machine (VM) designed to run WebAssembly~@haas17:bringing on microcontrollers#note[WARDuino supports the first release of WebAssembly (MVP).]. // todo "we created" does this feel right given the introduction of this chapter?
Since WebAssembly is a universal compile target, it can enable programs written in a wide variety of languages to run on low-end embedded devices. This is an important design choice to improve the #emph[portability] of our solution. The design of WebAssembly further focuses on a compact representation, since the byte code is intended to be streamable and efficient~@haas17:bringing. This compactness is especially important when executing programs within the #emph[hardware limitations] of the embedded devices. Additionally, WebAssembly can achieve performance speeds close to native code~@haas17:bringing@jangda19:not, potentially outperforming other interpreters for high-level languages on microcontrollers.

The WARDuino virtual machine was first presented in 2019 by #cite(<gurdeep19:warduino>, form: "prose");, and addressed #emph[the slow development cycle] and the challenging #emph[debuggability] through the initial implementation of a remote debugger with over-the-air reprogramming capabilities. The paper presented these two features as extensions to the operational semantics of WebAssembly, in order to show their interaction and compatibility with the WebAssembly standard, and to ease re-implementation in other virtual machines. Additionally, WARDuino provided support for a limited set of hardware features through WebAssembly functions embedded in the virtual machine. It is necessary to embed this support in the virtual machine, since the #emph[bare-metal execution environments] of embedded devices provide no conventional interfaces to the hardware. Simultaneously, the primitives should be exposed at the level of WebAssembly in order to achieve the highest #emph[portability] possible. However, the paper left some important problems as future work.

First, WebAssembly does not natively support asynchronous code, but many standard M2M protocols for IoT applications such as MQTT rely on asynchronous events. Similarly, IoT applications often rely on asynchronous handling of hardware interrupts. Due to this limitation in WebAssembly, WARDuino lacked any support for either hardware primitives that rely on asynchronicity, or M2M protocols. In this chapter, we extend the WebAssembly operational semantics with support for event-driven callback handling. Through this system, callback functions can subscribe to asynchronous events at the WebAssembly level. The functions will be executed whenever such an event occurs. While other proposals for asynchronous code in WebAssembly are being developed @webassembly-community-group22:webassembly, these proposals are still in early stages, and often focus heavily on browser applications, making them unsuitable for resource-constrained microcontrollers.

Second, since hardware support is exposed at the WebAssembly level,paperthere is a language barrier that has to be bridged for every higher-level language. The original version of WARDuino did not address this issue, and in practice lacked any real support for high-level languages. In this chapter, we show that WARDuino can practically solve the #emph[low-level coding] challenge as promised in the original paper~@gurdeep19:multiverse. We illustrate how WARDuino can support high-level languages through language symbiosis, by showing different levels of language integration for AssemblyScript, a TypeScript-like language. These examples serve as a general recipe for implementing other language libraries.

Third, the formal rules for the debugger semantics were not used to prove any interesting properties or guarantees for the debugger. In this chapter, we improve the semantics for the debugging and over-the-air updates, and provide a proof for observational equivalence between the debugger semantics, and the underlying WebAssembly semantics. This equivalence means that the executions observed by the debugger semantics are precisely the same as those observed by the underlying language semantics.

Fourth, the virtual machine was never used to implement a real-world IoT application, and its evaluation was limited to a comparison of execution speed with only one alternative approach. In this chapter, the evaluation of WARDuino has been expanded to include a comparison to another WebAssembly runtime that can run on microcontrollers We also present real-world IoT application written in AssemblyScript and developed using WARDuino.

To further illustrate how WARDuino can provide an improved development experience, closer to conventional programming, we present how WebAssembly enables fast prototyping of emulators, and the improved tool support with the visual debugger plugin for WARDuino in the VS Code IDE. This plugin is an important contribution towards the increased #emph[debuggability] of IoT software in WARDuino. The chapter also includes additional code examples that explain how hardware peripherals can be accessed from WebAssembly, as well as a notably improved and expanded presentation of the WARDuino virtual machine architecture.

In summary, our novel contributions compared to the initial paper~@gurdeep19:multiverse are:

- A detailed and expanded presentation of the #emph[improved WARDuino VM];: A WebAssembly virtual machine for embedded devices#note[The latest version of the VM is freely available under the Mozilla Public License 2.0];. (@remote:architecture)

- #emph[Support for IoT primitives] (asynchronous hardware peripherals and common M2M protocols) at the WebAssembly level. (@remote:extending and @primitives)

- A general recipe for supporting WebAssembly-level primitives in high-level languages in the form of #emph[language symbiosis] implemented for the AssemblyScript language, presented through multiple code examples. (@remote:interoperability)

- The first formally described #emph[event-driven callback system] and implementation for handling asynchronous code in WebAssembly. (@remote:formal)

- The first proof of #emph[observational equivalence] between a debugger semantics and the WebAssembly operational semantics. (@remote:proofsketch)

- An improved development experience thanks to better tool support through a #emph[visual debugging environment] in VS Code, which currently supports debugging of WebAssembly and AssemblyScript code—and the possibility for fast prototyping of emulators thanks to WebAssembly. (@remote:tools)

- A smart light application written in AssemblyScript showcasing the new IoT primitives in WARDuino, and demonstrating that the callback system can handle both interrupts from the embedded device itself and from the network via asynchronous communication protocols such as MQTT. (@remote:stability)

- An expanded comparison of the execution speed of the virtual machine with another WebAssembly runtime that can run on low-end embedded devices. (@remote:performance-on-microcontrollers)

The rest of the chapter is organized as follows. First, we show an example program and illustrate how WebAssembly code can access hardware peripherals in @remote:modules. In @remote:architecture we discuss the overall design of WARDuino.
The section goes into further detail on the execution of WebAssembly programs, and the handling of interrupts within the virtual machine. Then we show how we bridge the language barrier with WebAssembly in @remote:interoperability. @remote:extending briefly discusses how developers can extend the WARDuino machine themselves to support new or custom hardware peripherals. A formal description of our extensions is given in @remote:formal. In @remote:tools we give a detailed overview of the available tools for debugging WARDuino applications. We follow this discussion with the evaluation of our implementation in @remote:evaluation. Finally, we present related works in @remote:related-work and conclude in @remote:conclusion.

//== WARDuino: WebAssembly for Microcontrollers<remote:modules>
== WARDuino: WebAssembly Programming in Practice<remote:modules>

WARDuino is a virtual machine for the 2019 core WebAssembly standard @rossberg19:webassembly. The standard does not provide instructions to interact with the environment, for example controlling the pins of a microcontroller. Neither does the #emph[bare-metal execution environment] of embedded devices provide useful abstractions and interfaces to interact with the hardware, in the way a full-fledged operating system might. To address this shortcoming, WARDuino provides a set of primitives to interact with the environment as importable WebAssembly functions.

However, the end goal of WARDuino is not to develop IoT applications in WebAssembly, instead it is meant to enable IoT developers to use high-level programming languages. Many high-level languages can already be compiled to WebAssembly, and we can lift the WARDuino primitives to those programming languages. This means that developers can use the WARDuino primitives as normal functions in their high-level language of choice. We start with a small example to make this general idea more concrete.

=== Developing IoT programs<remote:developing>
Programs in over 40 languages can be compiled to WebAssembly bytecode#note[There is no official list of languages that compile to WebAssembly, but the community maintains #link("https://github.com/appcypher/awesome-wasm-langs")[a nearly complete list];.];, and many popular languages provide additional support such as interacting with WebAssembly directly. Developers can use these languages to write programs for WARDuino. We will use the AssemblyScript @the-assemblyscript-project23:assemblyscript programming language as an example in this section. AssemblyScript is a language specifically designed for WebAssembly. The main purpose of AssemblyScript is to allow web developers to use WebAssembly without needing to learn a new language. This is why the language is based on TypeScript, and many TypeScript programs are indeed valid AssemblyScript programs. AssemblyScript’s main purpose strongly aligns with our goal of letting developers program embedded systems in the languages they already know and prefer. Furthermore, by being a standalone language AssemblyScript can better prioritize small code size and fast code execution, which are both very important for embedded software.

@lst.program contains a minimal example of an MQTT program written in AssemblyScript. MQTT @banks14:mqtt is one of the most used M2M protocols @mishra20:use for communication in IoT applications. It allows devices to communicate with a large network of other devices via a server, designated as the MQTT broker. The broker accepts topic-based messages from clients and passes these messages on to all clients that have subscribed to these topics. WARDuino provides an MQTT module with all the necessary primitives for the microcontroller to function as an MQTT client.

#snippet("lst.program", 
    [MQTT AssemblyScript program for WARDuino.], 
    (```ts
import {delay, MQTT, print, WiFi} from "as-warduino";

function until(attempt: () => void, done: () => boolean): void {
    while (!done()) {
        delay(1000);
        attempt();
    }
}

export function main(): void {
    until(() => { WiFi.connect("ssid", "password"); }, WiFi.connected );

    let message = "Connected to wifi network with ip: ";
    print(message.concat(WiFi.localip()));
    MQTT.init("broker.example.com", 1883);
    MQTT.subscribe("helloworld", (topic, payload) => { print(payload); });

    while (true) {
        until(() => { MQTT.connect("clientid"); }, MQTT.connected);
        MQTT.poll();
        delay(1000);
    }
}
```,))

#[
#let imports = "lst.program.0:1"
#let until   = "lst.program.0:3"
#let main    = "lst.program.0:10"
#let wifi    = "lst.program.0:11"
#let ip      = "lst.program.0:14"
#let init    = "lst.program.0:15"
#let sub     = "lst.program.0:16"
#let loop    = "lst.program.0:18"
#let check   = "lst.program.0:19"

The code in @lst.program starts by importing all necessary WARDuino primitives from the #emph[as-warduino] package for AssemblyScript on #line(imports).
The `print` function is WARDuino’s primitive for printing to the serial bus. The `MQTT` and `WiFi` namespaces expose the functions for communicating via the MQTT protocol and connecting to Wi-Fi networks.
On #line(until), we define a helper function `until()` that takes two functions as arguments: `connect` and `connected`.
When `until` is called, the `connect` function is executed every second until the `connected` function returns true. We use this function in our program to establish a connection to the Wi-Fi network and the MQTT broker.

The entry point to our program is the `main` function (#line(main)). It starts by connecting to the local Wi-Fi network with the help of `until()` and two WARDuino primitives: the `WiFi.connect` function that initiates a connection to a network, and the `WiFi.connected` that returns whether the microcontroller is connected to a Wi-Fi network. Once connected, #line(ip) prints the microcontrollers IP address to the serial port. Again, two WARDuino primitives are used: `WiFi.localip` and `print`. The code then configures the URL and port of the MQTT broker (#line(init)), and subsequently subscribes to the #emph[helloworld] topic (#line(sub)). Alongside a topic string, the `MQTT.subscribe` primitive requires a callback function as second argument. WARDuino invokes this callback function for every incoming MQTT message with the set topic.

Now the microcontroller is ready to receive messages from the MQTT broker. A while loop (#line(loop)) checks if there are messages. To ensure the client remains connected to the server, #line(check) periodically checks if it is still connected, and otherwise attempts to reconnect. After verifying the connection, we call the `MQTT.poll` function to signal WARDuino to check for new messages.

Our example highlights the goal of the WARDuino project: programming microcontrollers from many high-level language. The code illustrates how developers can use all the features of their high-level language, even those WebAssembly itself does not fully support, such as strings and anonymous functions. Using the WARDuino primitives in high-level languages, does require some glue code behind the scenes. The exact details are discussed in @remote:interoperability.

Underneath the high-level language library, the primitives are implemented in the WARDuino virtual machine as WebAssembly modules. The WebAssembly standard includes the use of custom WebAssembly modules, which can be used to expose functions designed to interact with the environment. In web browsers such custom modules provide interoperability with JavaScript. WARDuino uses the same mechanism to provide access to its primitives: the hardware functionalities of the microcontroller.

The implementation of the primitives is backed by Arduino libraries. Arduino @banzi08:getting is an open-source electronics platform that supports a wide range of microcontrollers. By providing a thin layer on top of C++, Arduino increases the portability of programs on microcontrollers. The Arduino platform does an excellent job of defining uniform libraries. For example, the code implementing the iconic blinking LED program is identical for all supported devices. This is made possible by the fact that these microcontroller boards implement a core set of libraries to access and address the input-output pins. The constant `LED_PIN` is one of those provided addresses, it holds the pin number of an LED on the board. By building on top of the Arduino libraries, we can bring the same kind of interoperability to programs compiled to WebAssembly.

Our "built-in" modules provide the most important Arduino features for controlling peripheral devices. These include `GPIO`, `SPI`, `USART` and `PWM` as well as more advanced networking modules. Specifically, we have modules with primitives to connect to Wi-Fi networks and to use the HTTP and MQTT protocols. Currently, all our modules are exposed in one single custom WebAssembly module named "`env`". This is in line with the WebAssembly System Interface (WASI) specification @hickey20:webassemblywasi. An overview of these primitives and their WebAssembly interface can be found in @primitives.
]

=== Conclusion <conclusion>
In this section we have shown a basic IoT program written in AssemblyScript running on top of our WARDuino VM. Our goal is to enable IoT developers to program microcontrollers in high-level languages. To facilitate this WARDuino allows developers to run WebAssembly on microcontrollers. The idea is that programs in high-level languages are compiled to WebAssembly, and executed by WARDuino. Unfortunately WebAssembly did not yet support interacting with the hardware of the microcontroller. To resolve this we provide `GPIO`, `SPI`, `USART` and `PWM` modules. Network related features are another lacuna of WebAssembly we filled with the `WiFi`, `HTTP`, and `MQTT` modules. Thanks to our modules, WebAssembly becomes a viable platform to program microcontrollers with WARDuino. In the next section we will take a closer look at the architecture of WARDuino.

== WARDuino: Virtual Machine Architecture <remote:architecture>
The WARDuino virtual machine is at heart a byte-code interpreter for WebAssembly, around which several components have been built to improve the development cycle of IoT software. WebAssembly is the compile target because it tackles both the challenges of #emph[portability] and #emph[low-level coding];. However, for WebAssembly to be a viable platform, we need a way to interact with the environment, i.e. control hardware peripherals, communicate over the internet, and so on. To address this WARDuino includes a set of primitives. Responsive IoT applications require these primitives to handle asynchronous events, standard WebAssembly does not support this. WARDuino is therefore extended with a callback handler to process asynchronous events, and pass them to user-defined callback functions. To tackle the challenge of #emph[debuggability];, WARDuino includes a remote debugger with support for over-the-air updates. Combined with standard debugging operations, the over-the-air updates allow developers to iterate quickly and test fixes while debugging. This way, WARDuino aims to significantly improve on the #emph[slow development cycle] of embedded software. In this section, we give an overview of the virtual machine architecture, and show how the components interact with the interpretation of the loaded program, as well as each other.

=== WARDuino Components <warduino-components>
@fig:warduino gives a high-level overview of the virtual machine’s architecture, highlighting how the novel components (shown in red) relate to each other and interact with the running program (shown in blue). This program is a WebAssembly module, which will usually be compiled from a high-level language.

#figure(
    caption: [This diagram shows the architecture of the WARDuino virtual machine. The different components of the virtual machine are shown in red; the debugger, live code updater,
callback handler, and additional WebAssembly modules. External devices can send debug messages to the virtual machine, for both the debugger and live code updater. They are
parsed concurrently to the interpretation loop, and placed into the message queue. Asynchronous events for the callback handler are processed analogously, and placed into the
event queue. Both queues are shown in gray to indicate that they are populated by platform specific code, outside the interpretation loop. The program (WebAssembly module)
executed by the virtual machine is shown in blue. The arrows indicate the interactions between components, which are executed in the interpretation loop.],
  image("images/architecture.svg", width: 90%)
)<fig:warduino>

WARDuino allows developers to debug and update the running program over the air. The virtual machine can receive update and debug messages over different channels, such as Wi-Fi or the serial port. Whenever a message arrives, it is put in the debug message queue, where it is visible to the main interpretation loop. During interpretation, the virtual machine will periodically check the queue for new messages and resolve them one at a time as shown in @fig:warduino #circled([A]). Debug messages can instruct the VM to pause, step or resume execution #circled([B]). Update messages can replace the entire WebAssembly module, single functions, or even single variable values #circled([F]).

Importantly, WARDuino contains a number of WebAssembly modules, implementing common libraries and functionality for microcontrollers, such as the `Serial` module or the `HTTP` module #circled([C]). WebAssembly programs can use the primitives from these modules in order to access the hardware of the microcontrollers. Due to the primitives being defined at the level of WebAssembly, it is not always straightforward for developers to use the primitives in their high-level source language. Language specific libraries can enhance the interoperability between a source language and the low-level interfaces of the WebAssembly primitives. @remote:interoperability goes into further detail on supporting high-level languages through language specific libraries.

Microcontrollers often receive signals from peripherals through hardware interrupts. These are then typically processed by asynchronous interrupt handlers. This way, the embedded device does not have to block execution by actively waiting for input. Unfortunately, calling a function asynchronously is not supported by standard WebAssembly. In other words, a standard WebAssembly virtual machine cannot call a function to handle asynchronous events such as MQTT messages, hardware interrupts, and so on.
#note[In @app:mqtt the MQTT _subscribe_ primitive illustates how primitives can receive the table index of callback functions as arguments.]
To address this shortcoming, we have implemented a novel callback handling system for executing WebAssembly functions when certain events happen. WARDuino programs can use this callback handling system to handle asynchronous events. The MQTT module, for instance, can be used to register a WebAssembly function from the loaded program as a callback for specific events #circled([D]).
Whenever these events occur, our callback handler will invoke the registered function and pass all relevant information to it #circled([E]).
In the rest of our chapter, we will refer to these functions as callback functions or simply callbacks.

=== WARDuino Interpretation <remote:executing>
WebAssembly is a stack based language, defined over an implicit operand stack. This means WebAssembly runtimes do not have to explicitly use this stack. In WARDuino, however, we implement the VM as a stack based virtual machine based on the open source `wac` C-project by Joel Martin#footnote[#link("https://github.com/kanaka/wac");];. Our WebAssembly operand stack is implemented as two separate stacks: the main operand stack, and a call stack. The call stack keeps track of the active functions and blocks#note[In WebAssembly `loop` and `if` instructions are also placed on the call stack as so-called "blocks". These blocks are needed to ensure that branch `(br)` instructions can only jump to safe locations.] of the program and where the execution should continue once they complete. When initializing the module, we seed the call stack with a call to the main entry point of the program. The main operand stack holds a list of numeric values from which WebAssembly operations pop their arguments, and to which they push their results. This stack starts out empty.

@alg.interpretation shows the main interpretation loop of WARDuino as pseudocode. WARDuino executes a WebAssembly module $m$, instruction by instruction, in a single loop (@alg.interpretation:while). Before any instruction is interpreted, the #emph[resolveDebugMessage] function checks the debug message queue for new incoming messages (@alg.interpretation:debug), resolves the oldest one, and possibly pauses the runtime. If the runtime is not paused, the virtual machine checks the event queue for new asynchronous events, and possibly resolves at most one before starting the actual interpretation. If the runtime is paused however, the virtual machine will go to sleep until a new message arrives in the queue (@alg.interpretation:wait). The #emph[awaitDebugMessage] function does not resolve debug messages, instead the code jumps back to the start of the loop and the debug message is resolved by the #emph[resolveDebugMessage] function. We discuss the debug message and event resolution in more detail in, respectively @remote:debug and @remote:interrupts.

#let tri = text(size: 6pt)[$triangle.filled.r$]
#algorithm(
    [Main loop for interpretation in the WARDuino virtual machine.],
    pseudocode-list[
+ #line-label(<alg.interpretation:require>) #strong[Require] module $m$ #strong[and] running state $s$
+ done $arrow.l$ false, success $arrow.l$ true
+ #line-label(<alg.interpretation:while>) *while* done #strong[and] success *do*
    + #line-label(<alg.interpretation:debug>) resolveDebugMessage($s$) #tri Can update the running state $s$
    + *if* $s =$ paused *then*
        + #line-label(<alg.interpretation:wait>) awaitDebugMessage() #tri Wait until debug queue is not empty
        + *continue* #tri Go back to the start of the loop
    + #line-label(<alg.interpretation:events>) resolveEvent() #tri Run callback for event, if any in the queue
    + #line-label(<alg.interpretation:opcode>) opcode $arrow.l$ getOpcode($m$)
    + #line-label(<alg.interpretation:switch>) *switch* opcode *do*
        + ...
        + #line-label(<alg.interpretation:case>) *case* 0x7c ... 0x8a
            + success $arrow.l$ interpretBinaryi64($m$, opcode) #tri Perform i64 binary operation
        + ...
    + #line-label(<alg.interpretation:next>) m.pc $arrow.l$ m.pc $+ 1$ #tri Increment program counter
+ *if* #strong[not] success *then*
    + #line-label(<alg.interpretation:trap>) #strong[throw] trap #tri Check if any operation threw a trap
], "alg.interpretation")

For interpreting instructions, the virtual machine keeps track of its own program pointer $m . p c$, which points to the next instruction to be executed in the program buffer. We may dereference this pointer to get the next opcode to execute (@alg.interpretation:opcode), for example `0x7f`. A switch statement then matches the current opcode (@alg.interpretation:switch). For our example, the switch determines our opcode to be a binary operator for 64-bit integers that will be handled by the #emph[interpretBinaryi64] function. This function resolves the instruction further and returns whether it succeeded. If so, the while-loop continues, and the next opcode is processed. Otherwise, $"success"$ will become false, and the while loop will stop interpretation.

When the interpretation loop stops due to a failure, the virtual machine will throw the underlying trap (@alg.interpretation:trap)#note[We refer interested readers to the paper by #cite(<haas17:bringing>, form: "prose") for more information on traps in WebAssembly.];. Alternatively, interpretation halts whenever the end instruction (`0x0b`) of the main entry point is reached. In this case, the #emph[done] variable will be set to `true`, and the main interpretation loop will stop successfully without throwing a trap.

In @alg.binary we show the most relevant parts of #emph[interpretBinaryi64];. The function is used to interpret all binary operators defined by WebAssembly on 64-bit integers. First, it gets the two arguments for the binary operation from the operand stack (@alg.binary:pop). Next, the function matches the opcode with a specific operation, in our case the `i64.div_s` operation. If the arguments are valid for the operation, the division is executed (@alg.binary:calculate), the result is placed on the top of the stack (@alg.binary:result), and the function returns `true` indicating success (@alg.binary:success). When the function encounters an illegal operation such as a division by zero, it returns `false` instead (@alg.binary:trap). In that case, the main loop of the virtual machine will stop interpretation of the program and throw an exception, as shown on @alg.interpretation:trap in @alg.interpretation. Most of the code for interpreting the WebAssembly operations is structured analogously to the function highlighted in @alg.binary.

=== Resolving Debug Messages <remote:debug>
Debug messages for WARDuino are received and parsed concurrently from the main interpretation loop, by device and communication channel specific code. Messages are placed on a FIFO queue. The interpretation loop will check this queue at the start of each iteration (@alg.interpretation, @alg.interpretation:debug). When the queue is not empty, exactly one message is processed. This means the running state of the virtual machine can change, for instance from running to paused. If the program should be paused, the virtual machine will wait until the debug messages queue is not empty (@alg.interpretation, @alg.interpretation:wait), before continuing at the start of the interpretation loop.

#algorithm(
    [Function to interpret operators for 64-bit integers.],
  pseudocode-list[
    + #line-label(<alg.binary:function>) *function* interpretBinaryi64(m, opcode)
        + #line-label(<alg.binary:pop>) $d , e arrow.l$ popStack($m$, 2)
        + $f arrow.l 0$
        + #line-label(<alg.binary:switch>) *switch* opcode *do*
            + ...
            + #line-label(<alg.binary:case>) *case* 0x7f
                + *if* e = 0 *then*
                    + #line-label(<alg.binary:trap>) #strong[throw] \"division by zero\"
                    + *return* false
                + #line-label(<alg.binary:calculate>) $f arrow.l d div e$
            + ...
        + #line-label(<alg.binary:result>) pushToStack($m$, $f$)
        + #line-label(<alg.binary:success>) *return* true
    ],"alg.binary")

=== Calling primitives <calling-primitives>
WARDuino primitives are exposed to the running program as imported WebAssembly functions. In fact, all imported functions must be primitives defined in the virtual machine, since the current version allows only one user-defined WebAssembly module to be loaded at a time. The WARDuino primitives are exposed through one single "`env`" module. This is in line with the WebAssembly System Interface (WASI) specification @hickey20:webassemblywasi. As stated before, the `env` module is implemented in the VM.

When an opcode specifies that a WebAssembly function must be called, some extra work is needed. First, the current instruction and stack pointers are stored in a frame and pushed to the call stack. The program pointer $m . p c$ is replaced by the first instruction of the function to be called. In the next interation of the while loop (@alg.interpretation, @alg.interpretation:while), the virtual machine will execute the function’s instructions. When the end instruction (`0x0b`) is encountered, the function has finished. The execution must now continue from the point where the call was originally made. To jump back to this place we pop the last frame from the call stack. This frame contains the program counter where we ought to continue execution. We reset our program and stack pointer to the appropriate values and continue executing. If the function returned a value, it will reside on the top of the main operand stack.

WARDuino programs can be developed in multiple high-level languages thanks to WebAssembly. Currently, the WARDuino project includes example programs written in Rust, AssemblyScript, and C#footnote[Rust and AssemblyScript programs can be found under the example folder in the #link("https://github.com/TOPLLab/WARDuino")[GitHub repository];, and the benchmarks folder includes C programs.];. We go into further detail on the support for high-level languages in @remote:interoperability.

The primitive operations (i.e. `digital_write`) are implemented in the WARDuino virtual machine in native C code. This implementation depends on the target microcontroller platform. Currently, WARDuino focuses on the Arduino platform which can be used with many families of embedded devices, such as ESP32’s, Arduino boards, and some Raspberry Pi devices. To illustrate the portability of WARDuino, the virtual machine includes partial support for ESP IDF#footnote[The current status of supported platforms can be found on the #link(
    "https://topllab.github.io/WARDuino/reference/primitives.html",
  )[documentation website].];. The WebAssembly interface of the primitives is the same for both implementations, to provide the best portability for WARDuino programs. To make these interfaces compatible with the VM the primitives conform to the standard WebAssembly calling conventions, i.e. they read their arguments from the stack and place their return value on the stack.

=== Callback Handling <remote:interrupts>
The WARDuino callback handling system is used to call WebAssembly functions when specific real-world events occur. These events can range from interrupts caused by a local button press to MQTT messages arriving over Wi-Fi. Similar to debug messages, asynchronous events are received and placed into a queue concurrently to the main interpretation loop. As shown in @alg.interpretation, the main interpretation loop will resolve a single event—if any is present—immediately after checking for incoming debug messages.

#figure(caption: [This diagram shows how callbacks are resolved in the virtual machine.
            The event queue is populated with events concurrently to the interpretation loop, any time the microcontroller receives a hardware interrupt.],
    image("images/callback-handling.svg", width: .7 * 100%))<fig.callbackhandler>

Before events can be resolved, callback functions must be registered for the topics of the events the program expects to receive. @fig.callbackhandler gives a schematic overview of the callback handling system in the WARDuino virtual machine. When developing our callback handling system, the two most important concerns are: (a) to keep the system lightweight, and (b) to offer the flexibility required to support the wide range of asynchronous protocols and libraries that already exist for microcontrollers.
Precisely for these concerns, we developed a reactive event-driven system.

Callback handling in WARDuino works as follows. Within WebAssembly, functions can be stored into a table, enabling them to be referenced by their table indices. WARDuino uses this same mechanism for the callback functions. For instance, consider an MQTT `subscribe` primitive that subscribes to an MQTT topic with a given callback function (more information can be found in @app:mqtt). In the WebAssembly program we pass the table index of the callback function to the `subscribe` primitive, as shown in @fig.callbackhandler . The WARDuino MQTT library then uses this index to register a callback with the global callback handler in the WARDuino virtual machine. This handler holds a mapping of topic strings to table indices. Each topic string can be mapped to at most one callback.

We do not allow multiple callbacks for a single topic string at the level of WebAssembly instructions, but the WebAssembly primitives we built on top of this system do in fact support registering multiple callbacks. This gives the same result for developers writing programs in a high-level language in WARDuino. However, it does make a significant difference for the WebAssembly specification, as we will explain in @remote:callback-handling.

Whenever the virtual machine wants to resolve an event (@alg.interpretation, @alg.interpretation:events), the callback handler takes the oldest event from the queue and looks up its topic in the callback mapping . The mapping returns the table index of the registered callback function. Through this index the callback handler can set up the call for the correct WebAssembly function on the call stack, and add the topic and payload of the event as arguments to the operand stack . In other words, the callback handler does not execute the callback functions itself, it merely sets up the appropriate calls on the stacks. When the interpretation loop resumes it will automatically execute the callback function. Executing callbacks is therefore completely transparent to the virtual machine, since it is just another function call. Furthermore, the virtual machine does not need to know whether an event was actually processed by the callback handler. This does force callback functions to never return a value.#note[The precise signature is shown as part of the operational semantics in @remote:callback-handling.] However, this is a reasonable requirement that many other microcontroller platforms also impose on their interrupt callbacks @espressif-systems23:esp-idf@banzi08:getting. After all, since the callbacks are executed concurrently to interpretation and in complete isolation, there is no way of using the return value anyway. Therefore, after the callback function is resolved, the interpretation of the program continues as if no additional function was called.

There is a possible pitfall with adding callbacks to the call stack at any point during execution. In light of the microcontroller’s limited memory, it is easy for the call stack to grow too rapidly. #note[Note that the blocked callbacks do not get lost, they are processed after the current callback completes.]Therefore, we prohibit that callbacks interrupt other callbacks. In practice, the virtual machine keeps track of whether a callback is being executed by adding a marker on the call stack just before the callback. When the virtual machine encounters this marker again, it knows that the callback completed. So when #emph[resolveEvent] is called in @alg.interpretation, and the last callback has not yet completed, the callback handler will never resolve an event.

=== Summary <summary>
The WARDuino virtual machine has all the ingredients to develop IoT applications for microcontrollers in high-level languages. We discuss the practicalities of using high-level languages in @remote:interoperability, The virtual machine includes primitives that give the WebAssembly programs access to the hardware peripherals and other IoT capabilities of the microcontrollers. The architecture of our virtual machine is extensible in many ways, as we discuss in @remote:extending. Through the framework discussed in @remote:extending many Arduino libraries can be implemented in WARDuino#note[A current list of already implemented libraries can be found in the #link(
    "https://topllab.github.io/WARDuino/reference/primitives.html",
  )[official documentation] of WARDuino.];.

Our novel callback handling system provides an event-based callback system where WebAssembly functions can be assigned to topics. Events are handled concurrently to interpretation of the WebAssembly program, and callback functions subscribed to the corresponding topic are called at well-defined points in the program execution. This way, these functions can react to hardware interrupts or other asynchronous events.

Because microcontrollers often do not have a keyboard or screen, WARDuino provides remote debugging support. This enables developers to set breakpoints and pause or step the execution remotely. Even more, WARDuino allows over-the-air updates of variables and functions as a whole. @remote:tools contains more details on the tools available for debugging with WARDuino. In the next section we will look further into the features of the WARDuino project that aim to overcome this language barrier.

== Support for High-level Languages<remote:interoperability>

// Intro

In WARDuino hardware functionality is exposed through WebAssembly primitives.
These low-level building blocks allow developers to build Internet of Things applications for microcontrollers.
While our primitives are valuable in their own right, their interfaces are low-level compared to the high-level languages we want to use them from.
Unfortunately, there is no generic way to create a high-level interface that is fit for every language.
Languages differ in their design philosophy or may even use a different programming paradigm altogether.
Furthermore, when creating interfaces, an implementer can choose to what degree they wish to offer language interoperability.
In this section, we discuss how to implement high-level interfaces for WARDuino primitives, by showing different levels of interoperability for the AssemblyScript programming language.
This implementation strategy is similar for all languages compiling to WebAssembly.

// Level 0
=== AssemblyScript as Source Languages<remote:assemblyscript>

Let us first consider AssemblyScript code that does not use WARDuino features.
@lst.assemblyscript.level0 shows a function that calculates the n-th Fibonacci number.
When we compile a basic program like this to WebAssembly, any runtime fully implementing the official WebAssembly specification should be able to run it.
However, this is not the kind of program we typically want to run on microcontrollers with WARDuino.
The computed Fibonacci only lives inside the microcontroller and is not visible to the outside world.
To make it visible, the program needs to affect the pins of the microcontroller in some way.

// Add the code snippet at the bottom of the document
#snippet("lst.assemblyscript.level0", [AssemblyScript function that calculates the n-th Fibonacci number.],
(```ts
export function fib(n: i32): i32 {
    let a = 0, b = 1;
    if (n > 0) {
        while (--n) {
            let t = a + b;
            a = b;
            b = t;
        }
        return b;
    }
    return a;
}```,))

// LEVEL 1
=== Importing External WebAssembly Functions

Our next example (@fig:assemblyscript.level1) is a small program that uses WARDuino primitives in AssemblyScript.
On the left side we show the code for the traditional blinking LED program.
The right side contains the minimal glue code required to make the program work.
The glue code imports our WARDuino primitives and defines some useful constant values.

Entities from external WebAssembly modules can be imported in AssemblyScript with an $mono("@external")$ annotation.
This annotation specifies both the module and primitive name to be imported.
The function declaration below the annotation mirrors the imported primitives interface.
On Lines 7 and 8, for example, WARDuino's $mono("chip_delay")$ primitive is imported and declared to AssemblyScript as the function $mono("delay")$ which has one $mono("u32")$ argument and returns $mono("void")$.

Our glue code will be the same for all AssemblyScript programs.
As such, we can implement it as an AssemblyScript library.
By using the $mono("export")$ keyword we export our declarations.
This approach abstracts away the underlying WARDuino interfaces.
Developers can now simply import the $mono("as-warduino")$ library as shown on the first line of the blinking LED program.
When they do this, they can use the WARDuino primitives as if they were normal TypeScript functions.

#snippet("fig:assemblyscript.level1", [Blinking LED example in AssemblyScript with the necessary and minimal glue code.], columns: (10fr, 16fr), continuous: false,
        (```ts
import * from "as-warduino";

export function main(): void {
  let led = 16;
  pinMode(led, OUTPUT);

  let pause = 1000;
  while (true) {
    digitalWrite(led, HIGH);
    delay(pause);
    digitalWrite(led, LOW);
    delay(pause);
  }
}
```, ```ts
export const LOW: u32 = 0;
export const HIGH: u32 = 1;
export const OUTPUT: u32 = 0x2;

@external("env", "chip_delay")
export declare function delay(ms: u32): void;

@external("env", "chip_pin_mode")
export declare function pinMode(pin: u32,
                                mode: u32): void;

@external("env", "chip_digital_write")
export declare function digitalWrite(pin: u32,
                                     value: u32): void;
```
),)

// Level 2
=== Using Interfaces with Strings

//The code for the blinking LED example is pretty clear and how we would expect it.
//To make it even more convenient we can even move the imports of the primitives to a seperate AssemblyScript module and import the declared function from that module.

For the blinking LED example, we only used primitives with simple numeric parameters and return values.
Primitives with string arguments and return values are less straightforward to port.
As detailed in @remote:serial-port-communication, we represent strings as two integers: a start index in the memory and the length of the string.


Unlike WebAssembly, AssemblyScript contains types for representing and manipulating strings directly.
As such it is unnatural for developers to pass strings as numeric values to functions in AssemblyScript.
When AssemblyScript code is compiled to WebAssembly, the compiler translates strings into a new representation using only basic numeric types.
We created a similar translation from strings to numeric types when implementing primitives with strings in our VM.
Unfortunately, we have no guarantee that these two translations are the same.
AssemblyScript encodes strings with UTF-16 by default, which uses two bytes to encode most characters.
But as we expect to use mostly ASCII characters, and we want to keep code sizes small for microcontrollers, we prefer to use UTF-8 encoding instead, where characters are represented primarily with only one byte.

If we use the same approach as we did for the LED example we arrive at the code in @fig:assemblyscript.level2.
It shows a simple AssemblyScript program that uses WARDuino's HTTP POST primitive.
On the right side of the figure, we give the minimal glue code that only imports the WARDuino primitive with their exact interfaces.
This means that each string argument must be translated to two integers by the developer.
This is not the only hurdle they must overcome.
Due to the encoding inconsistencies between AssemblyScript and WARDuino, strings must be manually transformed to UTF-8.
Additionally, to receive a response, WARDuino expects a memory slice as last argument where the response is stored to.
The developer must allocate an $mono("ArrayBuffer")$ for this and pass this as the last two arguments of the call.

#snippet("fig:assemblyscript.level2", [Example AssemblyScript program with HTTP GET without strings.], columns: (4fr, 3fr), continuous: false,
        (```ts
import * from "as-warduino";
export function main(): void {
  // ... connect to Wi-Fi ...
  // Send HTTP request
  let url = "https://example.com/post";
  let body = "Bridge the Language Gap";
  let content_type = "text/plain";
  let response = new ArrayBuffer(100);
  httpPOST(String.UTF8.encode(url, true),
    String.UTF8.byteLength(url, true),
    String.UTF8.encode(body, true),
    String.UTF8.byteLength(body, true),
    String.UTF8.encode(content_type, true),
    String.UTF8.byteLength(content_type, true),
    response, response.byteLength);
}
```, ```ts
export const WL_CONNECTED: u32 = 3;

@external("env", "http_get")
export declare function httpGET(
  url: ArrayBuffer, url_len: u32,
  buffer: ArrayBuffer,
  buffer_size: u32): i32;

@external("env", "http_post")
export declare function httpPOST(
  url: ArrayBuffer,
  url_len: u32,
  body: ArrayBuffer,
  body_len: u32,
  content_type: ArrayBuffer,
  content_type_len: u32,
  buffer: ArrayBuffer,
  buffer_size: u32): i32;
```))

Working with this minimal glue code requires very specific knowledge about the inner workings of WARDuino.
This is not desirable.
The minimal glue code does not effectively bridge the differences in abstraction levels between AssemblyScript and our WARDuino primitives.
We can improve on the glue code by extending it with functions that actually use strings instead of numeric values.

// LEVEL 3

The improved glue code for the HTTP primitives unburdens the developer from managing text encoding, by handling it in the AssemblyScript library.
@fig:assemblyscript.level3 shows the new library code on the right.
The code imports the WARDuino HTTP primitives under the names $mono("_http_post")$ and $mono("_http_get")$.
Instead of exporting these functions directly, the glue code wraps them in another function.
These wrappers take care of the necessary conversions and have a more natural external interface: they use AssemblyScript strings as argument and return type.
The library now exports these more natural wrappers instead of the "raw" WARDuino primitives.
We can even use AssemblyScript namespaces to group the HTTP functions together, to avoid name collisions and form a logical interface.
Developers can now write the much more naturally feeling code on the left of @fig:assemblyscript.level3, where the post function accepts strings and returns a string.
The type annotations on our wrapper function provide an extra benefit: they allow the AssemblyScript type checker to validate whether the function is indeed called with strings.

#snippet("fig:assemblyscript.level3", [Example AssemblyScript program with HTTP GET with glue code for strings.], columns: (3fr, 4fr), continuous: false,
        (```ts
import {HTTP} from "as-warduino";

export function main(): void {
  // ... connect to Wi-Fi ...
  // Send HTTP request
  let response = HTTP.post(
    "https://example.com/post",
    "Bridge the Language Gap",
    "text/plain");
}
```, ```ts
@external("env", "http_get")
declare function _http_get(...): i32;

@external("env", "http_post")
declare function _http_post(...): i32;

export namespace HTTP {
  function get(url: string,
               buffer: ArrayBuffer): i32 {
    return get(String.UTF8.encode(url, true),
               String.UTF8.byteLength(url, true),
               buffer, buffer.byteLength);}

  function post(url: string, body: string,
                content_type: string): string {
    let response = new ArrayBuffer(100);
    _http_post(String.UTF8.encode(url, true),
      String.UTF8.byteLength(url, true),
      String.UTF8.encode(body, true),
      String.UTF8.byteLength(body, true),
      String.UTF8.encode(content_type, true),
      String.UTF8.byteLength(content_type, true),
      response, response.byteLength);
    return String.UTF8.decode(response, true);}
}
```))

// LEVEL 4
=== Higher Levels of Language Interoperability

While the string version of the HTTP POST primitive is already a huge improvement over the numeric version, it still requires three string arguments.
Conventionally, TypeScript-like languages use objects to send complex arguments to functions.
In @fig:assemblyscript.level4, we show a program, and the associated glue code where the exported $mono("post")$ function accepts an object of class $mono("Options")$ rather than three strings.
The class declaration on the first line of the right listing in @fig:assemblyscript.level4 defines that a value of type  $mono("Options")$ must have the keys $mono("url")$, $mono("body")$ and $mono("content_type")$ which all should be assigned to a string.
Thanks to this definition, AssemblyScript's type system enforces that all required keys are present in the arguments to $mono("post")$.

#snippet("fig:assemblyscript.level4", [Example AssemblyScript program with HTTP GET with glue code for objects.], columns: (3fr, 4fr), continuous: false,
        (```ts
import {HTTP} from "as-warduino";

export function main(): void {
  // ... connect to Wi-Fi ...

  // Send HTTP request
  let options: HTTP.Options = {
    url: "https://example.com/post",
    body: "Bridge the Language Gap",
    content_type: "text/plain"
  };
  let response = HTTP.post(options);
}
```, ```ts
export namespace HTTP {
class Options { url: string; body: string;
                content_type: string; }

function post(options: Options): string {
  let response = new ArrayBuffer(100);
  _http_post(String.UTF8.encode(options.url, true),
    String.UTF8.byteLength(options.url, true),
    String.UTF8.encode(options.body, true),
    String.UTF8.byteLength(options.body, true),
    String.UTF8.encode(options.content_type, true),
    String.UTF8.byteLength(options.content_type, true),
    response, response.byteLength);
  return String.UTF8.decode(response, true);
}}
```))

=== Other Modules and Languages

Language interoperability is needed to facilitate access to WARDuino's primitives.
We implement it as a library that can be easily imported by developers.
Although we only highlighted the HTTP module in this section, our AssemblyScript library contains glue code for all the WARDuino primitives discussed in section~// todo @remote:modules.

Because different programming languages follow different conventions or even different programming paradigms all together, language interoperability must be dealt with separately for each language.
Luckily we can follow the same approach as we did for AssemblyScript to create interoperability libraries for other languages.
As an example, we also created a WARDuino library for Rust, another popular programming language with WebAssembly support.
Rust encodes strings as UTF-8 by default, so our library for this language does not need to change the string encoding.

Interoperability can be provided at different levels.
We have seen three implementations of AssemblyScript glue code for WARDuino's HTTP module.
The first version simply exported the ``raw'' WARDuino primitives.
This meant that the developer needed to know the inner workings of WARDuino to use these functions.
They needed to know how strings were represented, for example.
Our second version abstracted the interface, and allows developers to use it without having to worry about WARDuino internals.
By abstracting the interface we also allowed AssemblyScript to validate the types of arguments to our primitives.
Finally, in a third version we adapted the glue code to adhere more closely to the informal conventions of the language.
By doing so, WARDuino has similar function signatures to other libraries in the language.

=== Summary

To use high-level languages with WARDuino in practice, the primitives need to be lifted from their WebAssembly interface to the host language.
In this section we showed how this interoperability can be implemented to various degrees, ranging from using the low-level WebAssembly interface directly, to a high-level interface that integrates completely with the paradigms of the higher-level language.
The examples listed here can be used as a general recipe for implementing language integration libraries in other languages that compile to WebAssembly.
For instance, programs written in C, Rust, and AssemblyScript have been used with WARDuino using the implementation strategies outlined here.#note[Example programs can be found on the #link("https://topllab.github.io/WARDuino/")[documentation website] and in the #link("https://github.com/TOPLLab/WARDuino")[GitHub repository]]

== Extending the Virtual Machine<remote:extending>

#[
#show raw: set text(size: script, font: monospace)


In the previous sections we explained that WARDuino has native support for the most significant features of the microcontroller, such as monot("GPIO->SPI"), $mono("PWM")$, $mono("SPI")$, as well as communication protocols, such as $mono("HTTP")$ and $mono("MQTT")$.
However, we need to keep the memory constraints of the microcontrollers in mind.
Given the #emph[hardware limitations] of embedded devices, it is important to keep the WARDuino virtual machine as small as possible.
We therefore restricted the supported libraries to the most essential ones for embedded applications.
Furthermore, when compiling the virtual machine, developers can disable select primitives to reduce the size of WARDuino further.#note[For readers familiar with OS architectures, this is somewhat familiar to the unikernel approach.]
On the other hand, developers can add new primitives to the WARDuino VM for specific functionality or hardware they require for their projects.
In this section we give an overview of how to add new primitives to the WARDuino VM.
]

=== Creating User-Defined Primitives<remote:sub:extending>

In this section, we show how we implemented the $mono("digital_write")$ primitive in the WARDuino virtual machine.
Developers that need a library that is not supported by our VM can use a similar approach to add it to WARDuino.

Our virtual machine keeps a table of all primitive functions.
Each entry contains a name, a type specifier and an implementation.
Programmers can extend this table by providing these details.
The type specifier is used by the VM to validate if the primitive is called with the right arguments.
If an inconsistency is detected at runtime, WARDuino throws an error.
Note that this will not happen if the programmer has type-checked their code.
Almost all compilers that produce WebAssembly will produce type-checked code.
Our runtime checks are useful during the development of the primitives themselves.

The process for adding new primitives consists of the four steps we describe below.

#snippet("fig:prim-impl", [#emph[Left]: The $mono("Type")$ struct. #emph[Middle]: A Type specifier for a primitive that takes two 32-bit unsigned integer ($mono("u32")$) and returns nothing. #emph[Right]: The implementation of the $mono("digital_write")$ primitive.], columns: (4fr, 5fr, 4fr), continuous: false,
        (```ts
typedef struct Type {
  uint8_t form;
  uint32_t param_count;
  uint32_t *params;
  uint32_t result_count;
  uint32_t *results;
  uint64_t mask;
} Type;
```, ```ts
uint32_t param_U32_arr_len2[2]
  = {U32, U32};

Type twoToNoneU32 = {
  .form =  FUNC,
  .param_count =  2,
  .params =  param_U32_arr_len2,
  .result_count =  0,
  .results =  nullptr,
  .mask =  0x80011
};
```, ```ts
def_prim(digital_write,
         twoToNoneU32) {
  auto pin = arg1.uint32;
  auto val = arg0.uint32;
  digitalWrite(pin, val);
  pop_args(2);
  return true;
}
```))

First, the programmer needs to indicate that the number of primitives has changed by increasing the $mono("NUM_PRIMITIVES")$ constant, this variable is used to allocate the primitives table.

Second, the implementer defines the type of their custom primitive.
In WARDuino the type of a function is represented by the struct shown on the left side of @fig:prim-impl.
The form field indicates the form of the type, in the virtual machine, which is one of: function type, table type, memory type and global.
For primitives this field will always be a "function type" i.e. $mono("FUNC")$.
The following fields indicate how many arguments ($mono("param_count")$) and how many return values ($mono("result_count")$) the type has.
Both counts are followed by a pointer to an array containing the specific types of the arguments/return values.
Finally, each type has a $mono("mask")$ that allows for quick comparison of types in the VM.
The $mono("get_type_mask")$ function can derive the appropriate mask for a type struct.
We have predefined the most common types, these are available when defining new types.
One of these predefined types is the type for a primitive taking two 32-bit integer as an argument and returning nothing, its definition is shown in the middle of @fig:prim-impl.


Third, after the programmer has defined the type specifier, the primitive itself can be implemented.
On the right side of @fig:prim-impl, we show the implementation of our $mono("digital_write")$ primitive.
Primitives are defined using our $mono("def_prim")$ macro.
This macro expects two arguments, and a function body.
The arguments are the name and type specifier of the primitive.
The function body implements the primitive.
Developers can use the macros $mono("arg0")$ to $mono("arg9")$ to access the first 10 values on the stack.
The $mono("arg0")$ macro returns the argument that was pushed most recently onto the stack.
A $mono("pop_args()")$ macro allows popping values from the stack.
The implementation may use any library that is available at compilation time.
Additionally, it may use the callback system, an example of which will be discussed in @remote:implcallback.
Every primitive must return a boolean value.
This value is used to indicate whether the function succeeded.
If $mono("false")$ is returned, the primitive has failed, and the virtual machine will throw a trap.

Finally, the implementer makes the custom function available to the rest of the virtual machine and the WebAssembly modules it executes.
This only involves adding the primitive into the $mono("primitives")$ table with the $mono("install_primitive")$ macro.
Once this is done, the primitive is ready to be used in WebAssembly programs for WARDuino.

=== Using Callbacks with Primitives<remote:implcallback>

Our callback system enables developers to implement asynchronous libraries as modules for WARDuino.
In this section we will illustrate how our callback system can be used to define asynchronous primitives.
To do this, we look at the implementation of two MQTT primitives: $mono("mqtt_init")$ and $mono("mqtt_subscribe")$.

#snippet("fig:mqtt-init", [Implementation of the $mono("mqtt_init")$ (top) and $mono("mqtt_subscribe")$ (bottom) WARDuino MQTT primitives using the event-based callback handling system.],
(```cpp
def_prim(mqtt_init, threeToNoneU32) {  // Initialize the Arduino MQTT Client
  uint32_t server_param = arg2.uint32; uint32_t length = arg1.uint32;
  uint32_t port = arg0.uint32;
  const char *server = parse_utf8_string(m->memory.bytes, length, server_param).c_str();
  mqttClient.setServer(server, port);

  // Add MQTT messages as events to callback handling system
  mqttClient.setCallback([](const char *topic, const unsigned char *payload,
                            unsigned int length) {
  	CallbackHandler::push_event(topic, payload, length);
  });
  pop_args(3);
  return true;
}

def_prim(mqtt_subscribe, threeToOneU32) {  // Subscribe to a MQTT topic
	uint32_t topic_param = arg2.uint32; uint32_t topic_length = arg1.uint32;
    uint32_t fidx = arg0.uint32;
	const char *topic = parse_utf8_string(m->memory.bytes, topic_length, topic_param).c_str();

	Callback c = Callback(m, topic, fidx);
	CallbackHandler::add_callback(c);  // Register callback function with WARDuino

	bool ret = mqttClient.subscribe(topic);
	pop_args(2);
	pushInt32((int)ret);
	return true;
}```,))

The heavy lifting of our MQTT module is carried out by the PubSubClient Arduino library.
Our primitives act as a wrapper around this library.

@fig:mqtt-init shows the implementation of the $mono("mqtt_init")$ primitive on Lines 1 to 13.
This primitive initializes the underlying PubSubClient library, and sets the URL and port of the MQTT broker to connect to (Line 4).
The PubSubClient library only supports assigning one callback that will receive all the events for all subscribed topics.
WARDuino's callback handling system is more flexible and allows developers to assign different callback function for each topic.
During initialization of the MQTT module we use a lambda expression to set the callback of the PubSubClient library on Line 7.
This function forwards each incoming MQTT event to WARDuino's $mono("CallbackHandler")$.
The $mono("CallbackHandler")$ will then in turn invoke the right WebAssembly callbacks when messages arrive.

Lines 15-27 of @fig:mqtt-init implement the MQTT subscribe primitive.
It allows developers to register a WebAssembly function as a handler for a specific MQTT topic.
After retrieving and parsing the arguments to the primitive (Lines 16-17), the function does three things.
First, it creates a $mono("Callback")$ object that holds a reference to the WebAssembly module, the topic, and the index of the WebAssembly callback function (Line 19).
Second, this $mono("Callback")$ object is added to the $mono("CallbackHandler")$.
Third, in order for the subscribed messages to be passed to the $mono("Callbackhandler")$ on Line 8, the function needs to tell the underlying PubSubClient library to subscribe to the given topic (Line 22).

// Conclusion

Our new callback handling system allows WARDuino to define asynchronous primitives.
These primitives can handle asynchronous foreign events such as hardware interrupts.
To work with asynchronous primitives, developers simply use them in their programs to add callback functions.
WARDuino will then transparently execute them in response to incoming events.

=== Summary

In this section, we showed how users can define new primitives and add them to the VM in a four-step process.
Using this system users can add support for new sensors and actuators to WARDuino.
When implementing primitives, developers can use the internal callback handling system of the WARDuino virtual machine, to create asynchronous primitives.

The callback handling system is a key aspect of the virtual machine that extends standard WebAssembly.
Another such aspect is the remote debugger.
We discuss both components as formal extension to the WebAssembly specification in the next section.

== Formal Specification of WARDuino <remote:formal>
WebAssembly is strongly typed, and both its type system and execution are precisely defined by a small step semantic. Such a precise definition gives the WebAssembly community a universal way to propose changes and extensions to the standard.

In this section we formalize WARDuino’s architecture, by presenting it as three extensions to the WebAssembly specification. We start with a very brief summary of WebAssembly’s formal description in @remote:wa. This overview is followed by the small step semantics for our remote debugging (@remote:debugging), over-the-air updates (@remote:safe-dynamic-code-updates), and callback handling features (@remote:callback-handling). Each of these extensions can be defined entirely independently of the others, but here we present the over-the-air updates as an extension of the debugger semantics to highlight their compatibility. Primitives are part of the custom modules, and are therefore out of scope for the specification and will not be formalized here.

=== WebAssembly <remote:wa>
WebAssembly is a memory-safe, compact and fast bytecode format designed to serve as a universal compilation target. The bytecode is defined as a stack-based virtual instruction set architecture, which is strictly typed to allow for fast static validation. However, its design features some major departures from other instruction sets, and resembles much more the structure of programming languages than other bytecode formats. Importantly, it features memory sandboxing and well-defined interfacing through modules, as well as structured control flow to prevent control flow hijacking. The original use-case of WebAssembly was to bring the high-performance of low-level languages such as C and Rust to the web.

The execution of a WebAssembly program is described by the small step reduction relation $arrow.r.hook_i$ over a configuration triple representing the state of the VM, where $i$ indicates the index of the current executing module. The index $i$ is necessary since WebAssembly can load multiple modules at a time. A configuration contains one global store $s$, the local values $v^(\*)$ and the active instruction sequence $e^(\*)$ being executed. The rules are of the form $s ; v^(\*) ; e^(\*) arrow.r.hook_i s' ; v'^(\*) ; e'^(\*)$. A more detailed overview of the WebAssembly specification can be found in @webassembly.

=== Remote Debugging Extensions <remote:debugging>
To formalize our debugging system, we extend the operational semantics of WebAssembly with the necessary remote debugging constructs. The goal of these extensions, is to provide constructs that are as lightweight as possible while still being powerful enough to provide the most common remote debugging facilities. We follow the recipe for defining a debugger semantics as outlined by #cite(<torres19:multiverse>, form: "prose");, where the semantics of the debugger are defined in terms of the underlying language’s semantics: in this case the WebAssembly specifications. One advantage of this approach, is that it leads to a very concise description of the debugger semantics. More importantly, with this recipe you get a debugger whose semantics are observationally equivalent to those of the underlying language’s semantics. This means that the debugger does not interfere with the underlying semantics, and therefore, only observes real executions. Or more precisely, any execution in the WARDuino debugger corresponds to an execution of a WebAssembly program, and conversely that any execution of a program is observed by the debugger. The recipe also makes it straightforward to proof this non-interference of the debugger, as we will show in @remote:proofsketch.

#let wasmarrow = $attach(arrow.r.hook, br: i)$
#let debugarrow = $attach(arrow.r.hook, br: [d,i])$

#semantics(
    [#strong[Core debugger semantics.] Small step reduction rules ($arrow.r.hook""_(d,i)$) for the WARDuino remote debugger, as extensions to the WebAssembly semantics.],
    [
    $
        &"(Debugger State)"& "dbg" &colon.double.eq brace.l "rs", "msg"_i, "msg"_o, "s", "bp" brace.r \
        &"(Running State)"& "rs" &colon.double.eq "play" bar.v "pause" \
        &"(Messages)"& "msg" &colon.double.eq nothing bar.v "play" bar.v "pause" bar.v "step" bar.v "dump" bar.v "break"^+ "id" bar.v "break"^- "id" \
    $

    #curryst.prooftree(curryst.rule(name: [#text(size: small, [vm-run])],
        $brace.l "play", nothing, nothing, "s", "bp" brace.r ; v^* ; e^* arrow.r.hook""_(d,i) brace.l "play", nothing, nothing, "s", "bp" brace.r ; v'^* ; e'^*$,
    $s;v^*;e^* arrow.r.hook""_(i) s' ; v'^* ; e'^*$,
    $id(e^*) in.not "bp"$)) \

    #curryst.prooftree(curryst.rule(name: [#text(size: small, [db-step])],
        $brace.l "pause", "step", nothing, "s", "bp" brace.r ; v^* ; e^* arrow.r.hook""_(d,i) brace.l "pause", nothing, nothing, "s'", "bp" brace.r ; v'^* ; e'^*$,
    $s;v^*;e^* arrow.r.hook""_(i) s' ; v'^* ; e'^*$)) \

    #curryst.prooftree(curryst.rule(name: [#text(size: small, [db-dump])],
        $brace.l "pause", "dump", nothing, "s", "bp" brace.r ; v^* ; e^* arrow.r.hook""_(d,i) brace.l "pause", nothing, "msg", "s'", "bp" brace.r ; v'^* ; e'^*$,
    $s;v^*;e^* arrow.r.hook""_(i) s' ; v'^* ; e'^*$)) \


    #curryst.prooftree(curryst.rule(name: [#text(size: small, [db-pause])],
        $brace.l "rs", "pause", nothing, "s", "bp" brace.r ; v^* ; e^* arrow.r.hook""_(d,i) brace.l "pause", nothing, nothing, "s", "bp" brace.r ; v^* ; e^*$)) \

    #curryst.prooftree(curryst.rule(name: [#text(size: small, [db-pause])],
        $brace.l "pause", "play", nothing, "s", "bp" brace.r ; v^* ; e^* arrow.r.hook""_(d,i) brace.l "play", nothing, nothing, "s", "bp" brace.r ; v^* ; e^*$)) \

    #curryst.prooftree(curryst.rule(name: [#text(size: small, [db-bp-add])],
        $brace.l "rs", "break"^+ "id", nothing, "s", "bp" brace.r ; v^* ; e^* arrow.r.hook""_(d,i) brace.l "rs", nothing, nothing, "s", ("bp" union brace.l "id" brace.r) brace.r ; v^* ; e^*$)) \

    #curryst.prooftree(curryst.rule(name: [#text(size: small, [db-bp-rem])],
        $brace.l "rs", "break"^- "id", nothing, "s", "bp" brace.r ; v^* ; e^* arrow.r.hook""_(d,i) brace.l "rs", nothing, nothing, "s", ("bp" backslash brace.l "id" brace.r) brace.r ; v^* ; e^*$)) \

    #curryst.prooftree(curryst.rule(name: [#text(size: small, [db-bp-rem])],
        $brace.l "rs", "break"^- "id", nothing, "s", "bp" brace.r ; v^* ; e^* arrow.r.hook""_(d,i) brace.l "rs", nothing, nothing, "s", ("bp" backslash brace.l "id" brace.r) brace.r ; v^* ; e^*$,
    $"rs" eq.not "pause"$,
    $id(e^*) in "bp"$)) \
],
    // todo more space between figure and caption. captions number bold
"fig:dbg:syntax")


At the top of @fig:dbg:syntax we give an overview of our syntactic extensions to the operational semantics of WebAssembly that provide remote debugging support. In the semantics we abstract away the underlying communication primitives, we assume that there is a system in place that reads messages from a stream and places them in the inbox. A concrete implementation may allow communication over the serial port, an HTTP connection or the SPI bus. For ease of exposition all these possible communication methods are modeled through messages $m s g$.

To differentiate the debugger semantics from the underlying language, we write the reduction relation as (#debugarrow), where $d$ indicates the debugging semantics and $i$ is still the index for the currently executing module. But thanks to how we define the debugger semantics, the operation of a program during debugging is described by the combined reduction rules from the WebAssembly semantics and our debugger semantics.

The semantics of the debugger consists of a state transitioning system where each state consists of a debugger state #emph[dbg];, zero or more local values $v^(\*)$ and a focused operation $e^(\*)$. The main state of the debugger #emph[dbg] is represented as a 5-tuple that holds the running state $r s$, the last incoming message $m s g_i$ the last outgoing message $"msg"_o$, the WebAssembly store $s$ and, a set of breakpoints $b p$. The running state indicates whether the virtual machine is paused (#smallcaps[pause];) or running (#smallcaps[play];). Rules for setting $"msg"_i$ when messages are received, and for clearing $"msg"_o$ when delivering outbound messages are omitted from our semantics as these are dependent on the communication method. The reduction rules for remote debugging are shown in the lower part of @fig:dbg:syntax, we describe them below.

/ vm-run: When in the #smallcaps[play] state with no incoming or outgoing messages and no applicable breakpoints, the debugger takes one small step of the small step operational semantics #wasmarrow. That is, a regular WebAssembly step is taken.

/ db-pause: When the debugger receives a $p a u s e$ message, the debugger transitions to the #smallcaps[pause] state. Note that it is allowed to transition from any previous state to the paused state. After transitioning to the paused state, the rule #smallcaps[vm-run] is no longer applicable.

/ db-dump: In the paused state the debugger can request a dump of the virtual machine’s state. This dump is communicated to the debugging host by an outgoing message, which contains the full WebAssembly state and the breakpoints of the debugger.

/ db-run: When the debugger is in the #smallcaps[pause] state, the programmer can restart execution by sending a $r u n$ message.

/ db-step: When the debugger receives the $"step"$ message in the #smallcaps[pause] state, it takes one step (#wasmarrow). The debugger remains in the #smallcaps[pause] state.

/ db-bp-add: Breakpoints can be added in any run state.

/ db-bp-rem: Breakpoints can be removed in any run state.

/ db-break: When the debugger is not in the #smallcaps[pause] state, and the $i d$ of the currently executing expression is in the list of breakpoints the debugger transitions to the #smallcaps[pause] state.

It is important to note that the #smallcaps[db-dump] adds a message to the outgoing messages, but the other rules expect the outgoing messages to be empty. Since the communication is abstracted away, we assume that incoming and outgoing messages are added and removed by an external system, and the debugging semantics cannot get stuck. In other words, the other rules in the semantics only handle incoming messages after all the outgoing messages are removed by the external communication system.

Below, we show three derived commands for stepping through the WebAssembly code after a breakpoint is hit. These are not written as rules in our formal semantics as they are simply a combination of the rules we already introduced.

/ step-into: This stepping command is offered only for function calls. In order for the debugger client to verify whether this command should be active it can request a dump of the current execution and enable the step-into command in the GUI. Execution of the #smallcaps[step-into] command is the same as #smallcaps[db-step];.

/ step-out: When the programmer is debugging inside a function, they might want to step out of the function call. Because the end of a function is an actual instruction in WebAssembly the debugger can inspect the body of the function and add breakpoints for all the exit points of the function. Important here is that the debugger needs to take note of the call stack at the moment a #smallcaps[step-out] is requested. To handle recursive calls correctly, the program should only be paused if one of the breakpoints is hit while the call stack has the same height. If the breakpoint is hit on a larger call stack, the program should be resumed (by sending $p l a y$).

/ step-over: Like step-into, step-over only activates for the next call instructions. Instead of following the call the step-over stepping command stops the debugger when the call is finished. The instruction sequence to express step-over with our basic debugging constructs are: take one step to go into the function (#smallcaps[db-step];), execute the #smallcaps[step-out] stepping command.

The semantics allow for more elaborate debugging operations to be build on top of those presented here. However, the previous three operations represent the most widely used debug operations, and should therefore accommodate most developers debugging needs.

#let exarrow = $attach(arrow.r.hook, br: e)$

=== Proof of Observational Equivalence <remote:proofsketch>
In order to proof the observational equivalence between the debugger semantics and the base language semantics, we use the same proof method as #cite(<torres19:multiverse>, form: "prose");, which proves observational equivalence by a weak bisimulation argument. With this proof, we show that if an arbitrary WebAssembly program $P$ can take a step to a program $P'$, the debugging semantics allows the debugger to reach the program $P'$ from the program $P$ by one or more debugging steps. The other way around, if the debugger allows a program $P$ to transition to a program $P'$, the normal WebAssembly evaluation will also allow the program $P$ transition to the program $P'$.

In the semantics we leave out the specifics of the communication, and assume the incoming messages are added to the debugging state in the correct order. For the proof, we will reason over a stream of messages instead of a single one. Thanks to the recipe we follow for the debugger semantics, the proof follows almost directly by construction.

#theorem("Observational equivalence")[
Let $S$ be the WebAssembly configuration ${ s ; v^(\*) ; e^(\*) }$, for which there exists a transition (#wasmarrow) to another configuration $S'$ with ${ s' ; v'^(\*) ; e'^(\*) }$. Let the debugging configuration $({ r s , m s g_i , m s g_o , s , b p } ; v^(\*) ; e^(\*))$ with running state $r s$, incoming messages $m s g_i$, outgoing messages $m s g_o$, and set of breakpoints $b p$; be such that processing the stream of incoming message $M^(\*)$ takes exactly one externally visible step (#smallcaps[vm-run] or #smallcaps[db-step];) in the debugger semantic (#exarrow), then:

  $ ({ s ; v^(\*) ; e^(\*) } wasmarrow { s ' ; v '^(\*) ; e '^(\*) }) \
  arrow.l.r.double \
  ({ r s , m s g_i , m s g_o , s , b p } ; v^(\*) ; e^(\*) exarrow { r s , m s g_i , m s g_o , s ' , b p } ; v '^(\*) ; e '^(\*)) $
]
The left-hand side of the double implication presents a single step in the normal evaluation (#wasmarrow) of a WebAssembly program, while the right-hand side presents one or more steps in the debugging semantics ($debugarrow^(\*)$) where only a single step is externally visible ($exarrow$). We will start by sketching the proof for the first implication, that is, an evaluation step in the WebAssembly semantics implies an equivalent series of debugging steps.

#proofsketch[
  In case the debugger is in the #smallcaps[play] state, two cases need to be considered. First, if there is no applicable breakpoint, the only applicable rule that is externally visible is the #smallcaps[vm-run] rule. Applying this rule, will transition the state $S$ to $S'$ by construction. Second, a number of internal rules of the debugger can transition the system into a #smallcaps[pause] state (e.g., #smallcaps[db-pause];, #smallcaps[db-break];). By assumption, processing the stream of messages $M^(\*)$ leads to exactly one externally visible step. None of the internally visible rules (e.g., #smallcaps[db-pause];, #smallcaps[db-bp-add];) change the underlying state $S$ of the program. This means, that whenever the externally visible step is taken, it will do so with the same underlying state $S$ as at the start of the debugging steps. The only externally visible steps, are #smallcaps[db-step] and #smallcaps[vm-run];, which take exactly the same transition as the underlying WebAssembly semantics. In case the debugger starts in the #smallcaps[pause] state, a similar argument holds.
]

Now we will provide the proof sketch for the second implication, that is a series of evaluation steps in the debugger semantics implies an equivalent evaluation step in the WebAssembly semantics.

#proofsketch[
Only the #smallcaps[vm-run] and the #smallcaps[db-step] rules change the WebAssembly configuration $S$ in the debugging configuration $D$. By construction, both rules rely directly on the underlying WebAssembly semantics for transitioning $S$ to $S'$.
]

=== Safe Over-the-air Code Updates <remote:safe-dynamic-code-updates>
Our over-the-air update system allows programmers to upload new programs and to update functions and local variables. Here, we present the system as an extension of the debugger semantics, but the over-the-air updates can also be defined on their own without the debugger as we show in @remote:live-code-updates-integrated-with-debugging. Note that the observational equivalence of the debugger semantics will no longer hold with the addition of over-the-air updates, since they allow for arbitrary code changes.

@fig:red_update gives an overview of the additional reduction rules to dynamically update a WebAssembly program. In these rules the debug messages are extended with three update messages.#footnote[As with the debug semantics, rules for setting $m s g_i$ are omitted.] In order to improve the usability of the semantics, the over-the-air updates can only be executed in the paused state. Additionally, the program will remain in the paused state to allow setting new breakpoints.

#let debugrule(title, conclusion, ..premises, vertical-spacing: 0.3em) = [
  #curryst.prooftree(vertical-spacing: vertical-spacing, curryst.rule(name: [#smallcaps(title)], conclusion, ..premises))]
#let pause = $"pause"$

#semantics(
    [Extension of the debugging rules (@fig:dbg:syntax) with safe over-the-air updates.],
    [
    $
        &"(Messages)"& "msg" &colon.double.eq ... bar.v "upload "m^* bar.v "update"_f " id"_i " id"_f "code"_f bar.v "update"_l j v \
        &"(Closure)"& "cl" &colon.double.eq { "inst" i, "idx" j, "code" f} \
    $

    #debugrule("upload-m", ${pause, "upload" m^*, nothing, s, "bp"} ; v^* ; e^* debugarrow {pause, nothing, nothing, s', nothing} ; v'^* ; e'^*$, $(tack.r m)^*$, ${s', v'^*, e'^*} = "bootstrap"(m^*)$)

    #debugrule("update-f", ${pause, "update"_f id_i id_f "code"_f, nothing, s, "bp"} ; v^* ; e^* debugarrow {pause, nothing, nothing, s', "bp"} ; v'^* ; e^*$, $s' = "update"_(f)(s, id_i, id_f, "code"_f)$)

    #debugrule("update-local", ${pause, "update"_l j v', nothing, s, "bp"} ; v^j_1 v v^k_2 ; e^* debugarrow {pause, nothing, nothing, s, "bp"} ; v^j_1 v' v^k_2 ; e^*$, $tack.r v : epsilon.alt arrow.r t$, $tack.r v^* : epsilon.alt arrow.r t$)

],
"fig:red_update")


/ upload-m: An _upload_ message instructs WebAssembly to restart execution with a new set of modules $m^(\*)$. We require all these modules to be well typed, $(tack.r m)^(\*)$. The meta-function bootstrap represents WebAssembly’s initialization procedure, described in the original WebAssembly chapter @haas17:bringing. Note that this procedure replaces the entire configuration, including the WebAssembly state, locals and stack. Furthermore, upon receiving the _upload_ message the debugger state is reset and all breakpoints removed.

/ update-f: The message to update a function specifies the function to update and its new code ($"code"_f$). To identify a function we must supply the ID of the instance $i d_i$ it lives in and the index it exists at $i d_f$ in that instance. The meta-function $sans("update")_f$ replaces the function in the state $s$ and validates that its type remains the same.

    WebAssembly’s formalization transforms every function in a closure that holds its code $f$ and the module instance it was originally defined in. When a function is imported into another module or placed in a table, its closure is copied to the other module instance. Because the closure holds the original instance, it can be executed in the right context. When it calls other functions, for example, these must be the functions from the original module rather than from the calling module. We extended closures with an extra identifier idx, which holds the index of the function in its defining module. Thanks to this, the $sans("update")_f$ can replace all closures in $s$ where the inst is $i d_i$ and the idx is $i d_f$.

/ update-local: Updating a local is done with an $"update"_l$ message. This message holds the index of the local to be updated and its new value. We validate that the type of the new value is the same constant type $epsilon.alt arrow.r t$ as the original value at the chosen index.

Note that we only allow updates if the underlying types remain the same. While this provides safety, it can still have undesirable effects. For example when updating, in the middle of a recursive function the new base conditions might have already been exceeded. The WARDuino VM does not tackle these kinds of problems. In future work we hope to improve on this by incorporating techniques from work on dynamic software updates~@tesone18:dynamic.

=== Callback Handling <remote:callback-handling>
In @remote:interrupts we discussed the architecture of our callback handling system. The system follows an event-driven approach, where ordinary WebAssembly functions are registered as callbacks for a specific event. Before we can formalize how callbacks are executed by the WebAssembly runtime, we must extend the abstract syntax with the necessary concepts: events, callbacks, memory slices, and callback mappings. The top part of @fig:callback-typing shows how we extend the syntax, starting from the WebAssembly abstract syntax with the additional syntax for remote debugging.

// todo update to new callback hadnling system from multiverse paper
#semantics(
    [The extended WebAssembly abstract syntax (top), and the typing rules (bottom) for the WARDuino callback handling system.],
    [
    $
        &"(Store)"& "s" &colon.double.eq { ... , "status" "rs", "evt" "evt"^*, "cbs" "cbs"} \
        &"(Running state)"& "rs" &colon.double.eq "play" bar.v "pause" bar.v "callback" \ // todo refactor to running state
        &"(Event)"& "evt" &colon.double.eq {"topic" "memslice", "payload" "memslice"} \
        &"(Memory slice)"& "memslice" &colon.double.eq {"start" "i32", "length" "i32"} \  // todo unsigned integer
        &"(Callback map)"& "cbs"[x arrow.r f] &colon.double.eq lambda x . "if" y = x "then" f "else" "cbs" y \
        &"(Instructions)"& "e" &colon.double.eq ... bar.v "event.push" bar.v "callback" { e^* } space e^* "end" \
        &                &     &bar.v "callback.set" "memslice" bar.v "callback.get" "memslice" \
        &                &     &bar.v "callback.drop" "memslice" \
    $
  
  // todo evaluation rules

  #grid(columns: 2, gutter: 1em,
  debugrule("", $C tack.r "callback" { e^*_0 } e^* "end" : "tf" $, $C tack.r e^* : epsilon.alt arrow.r epsilon.alt$, $C tack.r e^*_0 : "tf"$),

  debugrule("", $C tack.r "callback.set" "memslice" : "i32" arrow.r epsilon.alt$),

  debugrule("", $C tack.r "callback.get" "memslice" : epsilon.alt arrow.r "i32"$),

  debugrule("", $C tack.r "callback.drop" "memslice" : epsilon.alt arrow.r epsilon.alt$),

  grid.cell(colspan: 2, debugrule("", $C tack.r "callback.drop" "memslice" : "i32" times "i32" times "i32" times "i32" arrow.r epsilon.alt$)),
  )

  $
    &"(Contexts)"& C &colon.double.eq { "func" "tf"^*, "global" "tg"^*, "table" n^?, "memory" n^?, "local" t^*, "label" (t^*)^*, "return" (t^*)^? }
  $

],
"fig:callback-typing")

//                C e^\* : \
//    C e^\*\_0 : #emph[tf] C {e^\*\_0} e^\*  : #emph[tf]
//
//    C   #emph[memslice] : i32
//
//    C   #emph[memslice] : i32
//
//    C   #emph[memslice] :
//
//    C : i32 i32 i32 i32
//
//  ]
//  $ (c o n t e x t s) & C & colon.double.eq & { sans("func") thin t f^(\*) , thin sans("global") thin t g^(\*) , thin sans("table") thin n^(?) , thin sans("memory") thin n^(?) , thin sans("local") thin t^(\*) , thin sans("label") thin (t^(\*))^(\*) , thin sans("return") thin (t^(\*))^(?) }\ $

First, we add the #smallcaps[callback] state to the running state $r s$ defined for the remote debugging extension. This state indicates that the virtual machine is executing a callback function. This state only changes the behavior of the callback handlers, which will not resolve any new events until the state changes back to #smallcaps[play];. In other words, the #smallcaps[callback] and #smallcaps[play] states are completely interchangeable in the context of the remote debugging extension.

Second, we add a list of events to the global store. This list represents the event queue of the callback handler. Events must contain one topic and one payload, which are both memory slices (#emph[memslices];). A #emph[memslice] refers to an area in WebAssembly linear memory. This buffer of bytes is defined in the syntax as a tuple of numeric values, the start index and the length. So while the buffers will most likely be strings in practice, the formalization intentionally refrains from specifying anything about the memory content. This way we steer clear of trying to add strings to WebAssembly, which is not our goal. Events can be added to the event queue with the instruction. As the definition of an event in @fig:callback-typing shows, an event contains two #emph[memslices];: a topic and a payload. The instruction expects four numeric values on the stack, reflected in its type shown in the lower part of the same figure.

#note[To support multiple callbacks for one topic, we would need to introduce a new list type, and specify in what order and when exactly callbacks are processed. As this could have a large performance impact, we do not formalize multiple callbacks per topic.] // todo recheck this note
Third, the callback mapping is added to the global store. Adding, removing and retrieving functions from the callback mapping can be done from WebAssembly with the new instructions, , and respectively. Unlike WebAssembly instructions such as we cannot use an index space to refer to callback functions, because callbacks are stored in a mapping from strings to table indices. For this reason, the instructions for adding, removing and retrieving callbacks, take a memory #emph[memslice] containing the topic string. Note that the map returns at most one function index for each topic string. We choose to limit the amount of callbacks per topic in this way, because the mapping would otherwise become too complicated for a simple low-level instruction set such as WebAssembly. However, we can achieve the same result for end-users by supporting multiple callbacks at the level of WebAssembly primitives instead.

Finally, we extend the WebAssembly instructions with a new instruction. This construct is similar to the administrative instructions from the WebAssembly standard, used to simplify reasoning over control flow~@haas17:bringing. @fig:callback-typing shows the specific syntax and typing rules for this new construct. It holds two lists of instructions. The first sequence $e_0^(\*)$, between curly braces, is the continuation of the callback. These are the instructions that will be executed once the callback has been completely resolved. The second list of instructions $e^(\*)$ is the body of the callback, which will be evaluated first. Because the callback can be called at any time, its body must leave the stack unchanged after its reduction, so execution can continue as it would have without the callback. Furthermore, because the stack can have any possible state when the callback is created, the body of the callback cannot expect any arguments from the stack. In other words, the body of the callback takes zero arguments and returns nothing (type $epsilon.alt arrow.r epsilon.alt$).

With these syntactic extensions to WebAssembly, we are now able to formalize how events are processed, and callbacks executed. We list the additional small step reduction rules in @fig:callback-inst. To keep the rules readable, we will shorten #emph[memslices] by simply writing #emph[topic] or #emph[payload] instead of every numeric value. For instance, in the first rule, $s_(e v t) (0)_(t o p i c)$ is a shorter form for \$(\\key{i32.const}\\, s\_{evt}(0)\_{topic.start})\$ \$(\\key{i32.const}\\, s\_{evt}(0)\_{topic.length})\$. Similarly, we write the lookup for the table index of a callback function in the short form: $(s_(c b s) (s_(e v t) (0)_(t o p i c)))$. This expression corresponds with exactly one \$(\\key{i32.const}\\ index)\$ instruction. We describe each of the rules below.

#semantics(
    [Small step reduction rules for the WARDuino calback handling system.],
    [
  #grid(columns: 1, gutter: 1em,
  grid.cell(colspan: 1, debugrule("callback", $s; v^*; e^* wasmarrow s'; v^*; "callback" { e^* } (s_("evt")(0)_"topic") (s_("evt")(0)_"payload") (s_("cbs")(s_("evt")(0)_"topic")) ("call_indirect" "tf") "end"$, $s_("cbs")(s_("evt")(0)_"topic") eq.not "nil"$, $s_"status" = "play"$, $s'_"status" = "callback"$, $s'_"evt" = "pop"(s_"evt")$, $"tf" = "i32" times "i32" times "i32" times "i32" arrow.r epsilon.alt$)),

  debugrule("step-callback", $s; v^*; "callback" {e^*_0} space e^* "end" wasmarrow s';v^*; "callback" {e^*_0 } space e'^* "end"$, $s;v^*;e^* wasmarrow s'; v*; e'*$),


  debugrule("resume", $s; v^*; "callback" {e^*_0} space epsilon.alt "end" wasmarrow s';v^*; e^*_0$, $s;v^*;e^* wasmarrow s'; v*; e'*$),

  debugrule("skip-message", $s; v^*; "callback" {e^*_0} space epsilon.alt "end" wasmarrow s';v^*; e^*_0$, $s;v^*;e^* wasmarrow s'; v*; e'*$),

  debugrule("callback-trap", $s; v^*; "callback" {e^*} "trap" "end" wasmarrow s';v^*; "trap"$),

  debugrule("register", $s; v^*; ("i32.const" j) ("callback.set" "topic") wasmarrow s';v^*; "trap"$, $s'_"cbs" = s_("cbs")["topic" arrow.r j]$),

  debugrule("deregister", $s;v^*; ("callback.drop" "topic") wasmarrow s';v^*; epsilon.alt$, $s'_("cbs")["topic" arrow.r "nil"]$),

  debugrule("register-trap", $s;v^*;("i32.const" j) ("callback.set" "topic") wasmarrow s;v^*;"trap"$, $s_("tab")(i,j)_"code" eq.not ("func" "i32" "i32" arrow.r epsilon.alt "local" t^* e^*)$),

  debugrule("get-callback", $s;v^*; ("callback.get" "topic") wasmarrow s';v^*; s_("cbs")("topic")$),

  debugrule("push-event", $s;v^*;("topic") ("payload") ("event.push") wasmarrow s';v^*; epsilon.alt$, $s'_"evt" = "push"(s_"evt", {"topic", "payload"})$),
  )
],
"fig:callback-inst")

/ callback: The #smallcaps[callback] reduction rule shows how the WebAssembly interpreter can replace the instruction sequence $e^(\*)$ with a callback construct, whenever there are unprocessed events and no other callback is being processed. We do not allow nested callback constructs. To enforce this, we change the running state to the #smallcaps[callback] value in the #smallcaps[callback] rule and change it back to #smallcaps[play] in the #smallcaps[resume] rule. The #smallcaps[callback] construct replaces the instruction sequence with a instruction. The replaced instruction sequence, is kept by the callback construct as a continuation (between curly braces). The new stack only holds the callback construct, which contains an indirect call with the index returned by the callback mapping $s_(c b s)$. Before the indirect call and the table index, the rule adds the topic and payload of the event to the stack as arguments for that function call. This means that every callback function must have type $sans("i32") #h(0em) sans("i32") #h(0em) sans("i32") #h(0em) sans("i32") arrow.r epsilon.alt$. Because we place the arguments on the stack at the same time as the indirect call, the body of the callback as a whole still has type $epsilon.alt arrow.r epsilon.alt$, as specified in @fig:callback-typing.

/ step-callback: The #smallcaps[step-callback] rule describes how the code inside the body of the is executed until it is empty.

/ resume: Once a callback is completed, the #smallcaps[resume] rule replace s the empty construct with its stored continuation. From this point onward evaluation resumes normally. We know that the body of the construct will always become empty because its type is $epsilon.alt arrow.r epsilon.alt$.

/ skip-message: When no callback function is registered in the callback mapping $s_("cbs")$ for the event at the top of the FIFO event queue $s_(e v t) (0)$, the skip-message rule takes a step by removing the top event from the event queue in the store.

/ callback-trap: Because code within the construct is reduced with the existing WebAssembly reduction rules, it can result in a . In that case, the trap should be propagated upward by replacing the entire callback with it.

/ register: The takes an immediate memory slice, which corresponds with a topic string. The instruction takes a table index $j$ pointing to a function from the stack, and updates the callback mapping so the set of indices returned for the given topic now includes the table index $j$.

/ register-trap: If the table index that the pops from the stack, does not refer to a WebAssembly function with the correct type ($sans("i32") #h(0em) sans("i32") #h(0em) sans("i32") #h(0em) sans("i32") arrow.r epsilon.alt$), the instruction will result in a trap as shown in rule #smallcaps[register-trap];.

/ deregister: Callback functions can be removed from the callback mapping. The function updates the mapping by removing the index $j$ from the set of indices corresponding with the topic immediate.

/ callbacks: Looking up callbacks can be done with the instructions, which returns a vector of the table indices registered for the given topic.

/ push-event: The instruction adds a new event to the global event queue. Analogous to the previous callback instructions, this instruction takes a topic immediate. The payload of the event is taken from the stack. As shown, in @fig:callback-typing a payload is a memory slice, which consists of two numeric values: the offset in memory and the length of the slice.

Our formalization closely describes the callback handling system as introduced in @remote:interrupts. It does so with a limited amount of reduction rules. We can keep the formalization small because we reuse the existing instruction when adding a callback to the sequence of instructions. Using a smaller set of rules, means it is easier to reason about the formalization and the impact of the extension on WebAssembly. Furthermore, it means implementing the extension in a WebAssembly runtime is less work, because where the formalization reuses parts of the WebAssembly specification, the existing infrastructure of the runtime can likewise be reused.

So far we have not directly mentioned the interaction between the debugger and callback handling system. The operational semantics as presented here, allow for callback instructions to be introduced at any step. This also holds for the debugging steps. During debugging, WARDuino can jump to a callback function whenever it steps to the next instruction. This can lead to confusing behavior, and is the main reason why debugging concurrent programs is so complicated @torres19:multiverse. The implementation of WARDuino features debug instructions to make debugging concurrent programs easier, as described by #cite(<lauwaerts22:event-based-out-of-place-debugging>, form: "prose");. These debug instructions control the callback handling system by choosing when callback functions are executed. This is a powerful tool for debugging concurrent programs, which by design allows developers to explore interleavings of callbacks that are not possible outside the debugger semantics. This means that the observational equivalence no longer holds for the debugger.

=== Discussion <discussion>
The small step semantics of WebAssembly precisely defines how a program executes, allowing embedders, such as web browsers or WARDuino, to create different compatible implementations of the same specification. Additionally, the formalization provides a uniform way to propose extensions to the WebAssembly standard. In this section we formalized three extensions to WebAssembly: remote debugging, over-the-air updates and an asynchronous callback handling system. Other runtimes can use our formalizations to implement (some of) these extensions for their embedding of WebAssembly.

Our first extension, remote debugging allows developers to remotely control a WebAssembly runtime. By sending it messages, they can set breakpoints, pause the execution, inspect values and so on. Our formalization is based on a debugging recipe @torres19:multiverse that transforms a language semantics into an observationally equivalent debugger semantics. This means that no execution path observed by the debugger semantics is not observed by the underlying language semantics, and that no execution path observed by the language semantics cannot be observed by the debugger semantics as well. Thanks to the recipe used to construct the debugger semantics, the proof for observational equivalence follows almost directly by construction as shown in our proof sketch.

With our over-the-air update system programmers can safely replace a running WebAssembly module, specific functions or specific locals. We specify that if functions or locals are updated, they must maintain their original type. When uploading entire modules, the new modules must be valid. Over-the-air updates are defined orthogonal to debugging, this allows these two extensions to be used side-by-side or independently of one another. With the addition of over-the-air updates, the debugger semantics are no longer observationally equivalent to the language semantics, since it can now update code arbitrarily. Nevertheless, the semantics are important to show how the system preserves WebAssembly types across updates. Furthermore, we are not aware of any previous attempts to describe over-the-air updates of WebAssembly code, or describe over-the-air updates of binary code with an operational semantic. There is however, a limited body of work that looks into the theoretical aspects of over-the-air updates. We go into further detail on the existing works in @remote:over-the-air-related.

Our last extension shows how WARDuino can handle asynchronous events in WebAssembly. Hardware interrupts or asynchronous network communication is facilitated by our novel callback handling system. This system allows developers to transparently interrupt an executing WebAssembly program to execute a callback that deals with an incoming event. While the semantics presented here are certainly novel, there are several other proposals for supporting asynchronous code in WebAssembly. We discuss these works in @remote:async-related.

== Tool Support for WARDuino <remote:tools>
WARDuino aims to make it easier for programmers to debug applications running on embedded devices. There are several approaches and tools that WARDuino offers in this regard. The virtual machine includes its own remote debugger, while the use of WebAssembly makes it much easier to build emulators. In this section we give a detailed overview of the different tools available for debugging WARDuino applications.

=== Debugging WARDuino Programs Remotely <remote:dbqQ>
Microcontrollers are often not equipped with a screen and keyboard, therefore, we allow programmers to debug their programs remotely. We offer a command line tool and a Visual Studio Code plugin. First, we give an overview of our debugging protocol and the debugger architecture, before we show the VS Code plugin build on top of this debugger.

==== Debugging Protocol <debugging-protocol>
The WARDuino VM facilitates remote debugging by allowing debug messages to be sent over a variety of carriers. We have experimented both with wired (USB) and wireless (Wi-Fi) communication means. In theory any communication channel can be used.

Our protocol consists of a set of instructions sent as messages to the virtual machine. The first byte of each message indicates its type. Depending on the type, the first byte is followed by a byte sequence consisting of the arguments of the messages. When a debug message is received by the microcontroller, it is caught by an interrupt handler. This handler reads the available data and passes it on to the virtual machine. The VM in turn waits for a full debugging package to arrive. Once a package is complete, it is placed in the debugging queue for final processing. The debugging queue is polled before each executed instruction. If a message is present in the queue, the appropriate action is taken.

There are four broad categories of debug messages supported by WARDuino.

/ 1. Basic debugging: #block[
    The one-byte $p l a y$, $p a u s e$ and $s t e p$ messages respectively run, pause or step the currently executing program by setting the VM’s run state. The debugger keeps track of the run state that is either #smallcaps[pause] or #smallcaps[run];. When in the #smallcaps[pause] state, WARDuino waits for a $p l a y$ or $s t e p$ message to process the next instruction. In the #smallcaps[run] state, the VM executes normally.
  ]

/ 2. Breakpoints: #block[
    The remote debug messages $b r e a k^(+)$ and $b r e a k^(-)$ carry a pointer to an instruction where a user wishes to #smallcaps[pause] execution. These breakpoints are stored in a set. The set is checked before each instruction. When a break point is hit, the run state is set to #smallcaps[pause];, and an acknowledgment is sent to the remote debugger.
  ]

/ 3. Inspection: #block[
    When a $d u m p$ message is received, the run state is set to #smallcaps[pause] and a JSON representation of the state of the virtual machine is sent back to the user. The JSON object obtained from a $d u m p$ message contains the call stack, a list of functions, and the current instruction pointer. An example output is shown in // TODO @appendix:dbgJSON. In our implementation we also allow querying only specific elements of the state, such as the local variables.
  ]

/ 4. Over-the-air updates: #block[
    The remote debug messages for over-the-air updates, $u p d a t e_f$ and $u p d a t e_l$, both contain the ID of the function or local to update, and its new value. The virtual machine should be in the #smallcaps[pause] state to process such as change. Updating a local simply updates the appropriate value on the stack. Updating a function on the other hand is slightly more elaborate. First, the bytecode of the function is parsed and the appropriate structures are built. If the new function has an identical type, the pointer in WARDuino’s function table is replaced with a reference to the new code. Any running call of the existing function will continue to work with the old code. New calls will use the updated code.
  ]

==== Visual Studio Code Debugger <visual-studio-code-debugger>
The remote debugging system we presented so far, allows developers to debug WebAssembly code on microcontrollers remotely via a terminal. Debugging via a terminal with memorized commands is something few developers are used to. Instead, most developers use debuggers with a user-friendly interface such as the GUI debugger in an IDE. We created a plugin for the widely used IDE Visual Studio Code (VSCode) that allows developers to remotely debug WARDuino instances.

#figure(caption: [Screenshot of the VS Code debugger extension for WARDuino with a WebAssembly program (blinking LED).],
    rect(inset: 0mm, image("images/screenshot-blink-debug.png", width: 100%)))<fig:screenshot>

At its core, a debugging plugin for an IDE sends the debug messages described above on behalf of the developer. This removes the need for them to know our specific debugging API. Having a plugin send the same messages as a developer would in the terminal, is enough to support WebAssembly level debugging in an IDE. @fig:screenshot shows a screenshot of the VS Code plugin debugging a remotely running WebAssembly blink program that is currently paused on the highlighted line (Line 28). The plugin also support provisional source mapping for AssemblyScript, which means most features of the plugin can be used to debug AssemblyScript code directly. The buttons at the top of the screen allow the execution to be resumed and steps to be taken. In the sidebar on the left we can inspect local variables and edit them. These edits are then immediately propagated to the device with a $u p d a t e_l$ message. At the bottom of the sidebar, we can inspect the call stack.

=== Building Emulators <remote:emulators>
A common practice in IoT development is to use emulators to verify, as well as possible, the correctness of the code before running it on the custom hardware @makhshari21:iot-bugs. Emulation is designed to minimize the need for debugging on microcontrollers. Unfortunately, this approach is far from ideal as non-trivial differences between the emulator and the real device will exist. Emulated sensors may for example not produce real-world values. Instead, they might report a fixed value that does not change over time. Furthermore, real changes in sensor values may appear differently to real devices due to physical effects such as contact bounce (chatter). These differences can cause an application that works in an emulator not to work on a real device. That is why the WARDuino project focuses on delivering an alternative approach, where testing can be performed on the custom hardware itself. We argue, that this approach can catch more errors than emulation, and leads to a shorter development cycle.

However, emulated verification can still be useful. This is certainly the case when developers work with highly specific hardware, which may not always be at hand. WARDuino also helps when using the emulation approach, providing an easy workflow for implementing emulators for custom hardware.

#figure(
  caption: [Screenshot of a browser-based emulator for custom hardware. The right side of the screenshot shows how the browser debugger can pause and step through the original AssemblyScript code written for WARDuino.],
  rect(inset: 0mm, image("images/screenshot-snake-debug.png", width: 100%)))<fig:screenshot-browser>

Developers using WARDuino compile their programs to WebAssembly, which means their code also runs in web browsers. The only missing components are the WARDuino primitives that control the custom hardware. In other words, implementing an emulator for custom hardware comes down to creating a HTML based device and writing a minimal set of hooks to substitute the WARDuino primitives.

We implemented a snake game for a custom game controller#footnote[Our ESP32-powered game controller is based on Johan Von Konow’s SokoDay design: #link("https://vonkonow.com/wordpress/sokoday/");] that uses an 8x8 LED matrix. To support this LED matrix peripheral, we extended the WARDuino virtual machine with the Arduino Adafruit NeoPixel library#footnote[#link("https://www.arduino.cc/reference/en/libraries/adafruit-neopixel/");] using the process described in section~@remote:sub:extending. We wrote a snake game in AssemblyScript. To implement the emulator we write small JavaScript functions for each primitive we use in the code. The entire JavaScript code for the emulator consists of only 150 lines. It allows us to run the snake game in the browser. Additionally, we can use the browser’s debugger to step through the AssemblyScript code, as shown in @fig:screenshot-browser.

=== Debugging High-Level Languages <debugging-high-level-languages>
Debugging at the low level of WebAssembly is not workable for any real-world application. Our goal is to debug the high-level source code. So-called "source maps" make this possible. Source maps align the line numbers of the original code to the WebAssembly instructions they compile to. They typically come as a separate file containing only the mapping. By cross-referencing WARDuino’s instruction pointer with the source maps, we can derive the line we are executing in our program written in a high-level language.

@fig:screenshot-browser shows source mapping in action, the emulator is executing WebAssembly, but the code view on the right shows AssemblyScript code. The WebAssembly instruction pointer is translated into a line number in the AssemblyScript code by using source maps. AssemblyScript is not the only language with source mapping. Most high-level languages with good support for WebAssembly, can generate a source map during compilation. In fact, any language using the LLVM compiler infrastructure, can generate all the necessary information in DWARF format from which a source map can be derived.

== Evaluation<remote:evaluation>

In this section we evaluate the WARDuino VM in terms of its runtime performance, and conformance to the WebAssembly standard.
@remote:stability illustrates the usability of WARDuino in the real world, by presenting a qualitative evaluation of a smart light application written in AssemblyScript (@remote:stability).
Next, in @remote:performance-on-microcontrollers, we evaluate the performance of the virtual machine with a set of microbenchmarks.
We measure the runtime speed, as well as, the size of executables.
Since WARDuino targets microcontrollers with limited memory, it is important to take into account the number of bytes that get flashed per program.
We end the section by looking at WARDuino's conformity to the WebAssembly standard (@remote:comformance-to-the-wa-standard).

=== Practical Application<remote:stability>

#snippet("lst.smartlamp", [A smart light AssemblyScript program for WARDuino.],
    columns: (2fr, 2fr),
(
```ts
import * from "as-warduino";

const BUTTON = 25; const LED = 26;
const SSID = "local-network";
const PASSWORD = "network-password";
const CLIENT_ID = "random-mqtt-client-id";

function until(attempt: () => void,
               done: () => boolean): void {
  while (!done()) {
    delay(1000); attempt();
}}

function callback(topic: string,
                  payload: string): void {
  print("Message [" + topic + "] " + payload);

  // Inspect the payload of the MQTT message
  if (payload.includes("on")) {
    digitalWrite(LED, PinVoltage.HIGH);  // On
  } else {
    digitalWrite(LED, PinVoltage.LOW);   // Off
  }
}

function toggleLED(_t: string, _p: string): void {
    let status = digitalRead(LED);
    // Toggle LED via MQTT
    MQTT.publish("LED", status ? "off" : "on");
}
```,

```ts
export function main(): void {
  pinMode(LED, PinMode.OUTPUT);
  pinMode(BUTTON, PinMode.INPUT);

  // Connect to Wi-Fi
  until(() => { WiFi.connect(SSID, PASSWORD); },
    WiFi.connected);
  let message = "Connected to wifi with ip: ";
  print(message.concat(WiFi.localip()));

  // Connect to MQTT broker
  MQTT.init("192.168.0.42", 1883);
  until(() => { MQTT.connect(CLIENT_ID); },
    MQTT.connected);

  // Subscribe to MQTT topic and turn on LED
  MQTT.subscribe("LED", callback);
  MQTT.publish("LED", "on");

  // Subscribe to button interrupt
  interruptOn(BUTTON, InterruptMode.RISING,
    toggleLED);

  while (true) {
    until(() => { MQTT.connect(CLIENT_ID); },
      MQTT.connected);
    MQTT.poll();
    delay(500); // Sleep for 0.5 seconds
  }
}
```
))

// Describe the use-case used to evaluate/showcase warduino
#[
#let main        = "lst.smartlamp.1:31"
#let callback    = "lst.smartlamp.0:14"
#let callbackEnd = "lst.smartlamp.0:24"
#let toggle      = "lst.smartlamp.0:26"
#let toggleEnd   = "lst.smartlamp.0:30"
#let wifiStart   = "lst.smartlamp.1:36"
#let wifiEnd     = "lst.smartlamp.1:39"
#let subscribe   = "lst.smartlamp.1:47"

Smart light applications are one of the most widely known and practically applied IoT applications.
We investigate how well WARDuino performs for programming microcontrollers in practice by implementing a simple smart light application in AssemblyScript.
Specifically, we connected an ESP device to a button, and an LED.
The microcontroller will toggle the LED, when the button is pressed, or when it receives a certain MQTT message over the internet.
To receive MQTT messages, it subscribes to the "LED" topic on an MQTT broker.
There are two recognized MQTT payloads: "on" and "off".

@lst.smartlamp shows the source code of the software running on the ESP.
On the left side, we import the WARDuino primitives, and we define some constants and helper functions.
On the right side, we have the main entry point of the program, starting at #line(main).
The main function first sets the correct modes of the $mono("LED")$ and $mono("BUTTON")$ pins.
Next, it connects to the Wi-Fi network and prints the local IP address of the device on success (#range(wifiStart, wifiEnd, separator: [--])).
When the microcontroller is connected to the network, it connects to the MQTT broker (#range(wifiEnd, subscribe, separator: [--])).
In @remote:developing, we already discussed the code required to set up these connections.

With an established connection, the microcontroller subscribes to the "LED" MQTT topic on #line(subscribe).
The supplied callback is defined on #range(callback, callbackEnd).
It takes two arguments, the topic and the payload of the incoming message.
First, it prints the message to the serial port using $mono("print")$.
Then, we inspect the payload, if it is the string "on", we turn the LED on by using $mono("digitalWrite")$, otherwise we turn the LED off.

After subscribing, the $mono("main")$ function sends an "on" message to the "LED" topic using the $mono("MQTT.publish")$ primitive.
When the device receives its own message, the $mono("callback")$ function will make the LED shine.

On #line(subscribe) we attach a callback to rising voltage changes of the button pin.
We use the $mono("interruptOn")$ primitive to do this.
It takes three arguments: the pin to monitor, the kind of change to trigger for, and a callback to invoke when a change occurs.
Here we monitor the pin of the button for a rising edge ($mono("InterruptMode.RISING")$).
This means our callback, $mono("callback")$, will be invoked whenever the $mono("BUTTON")$ pin goes from low (not pressed) to high (pressed).
#range(toggle, toggleEnd) define $mono("toggleLED")$.
It reads the current state of the LED and then sends out an MQTT message with the opposite state.
This message will then be received by $mono("callback")$, which in turn toggles the LED's state.

]

The $mono("main")$ function concludes by ensuring that the connection to the MQTT broker stays alive.
To this end, it uses a $mono("while")$ loop that calls $mono("until")$ to reconnect to the MQTT broker if the connection is lost.

Note that the two callbacks used in this example, $mono("callback")$ and $mono("toggleLED")$, have different types.
However, in @remote:callback-handling we saw that our callback system requires that all stored callbacks have the type $sans("i32" "i32" "i32" "i32")arrow.r epsilon$.
This is indeed the case at the WebAssembly level.
The primitive behind $mono("interruptOn")$ requires a callback of that type.
Our language interoperability layer abstracts this away and exposes an  $mono("interruptOn")$ that expects a $mono("void") arrow.r mono("void")$ AssemblyScript callback.

To test the stability of WARDuino, we run the code in @lst.smartlamp on an ESP32-DevKitC V4 board with WARDuino.
We also create a small web application to control the LED from our phone via MQTT.
When testing our setup, we encountered no noticeable delay between pressing the physical button, and the LED changing status.
Furthermore, the delay between pressing the button on the web page, and the LED updating was reasonable and mostly influenced by the Wi-Fi connection.

=== Performance on Microcontrollers<remote:performance-on-microcontrollers>

// WARDuino vs Espruino on ESP32

There are three ways in which developers can run programs on microcontrollers. Dynamically typed languages such as JavaScript are run in dynamic runtimes, while statically typed languages can be executed with a byte-code interpreter, as is the case for WebAssembly, or can be compiled to executable byte-code, typically done with C or C++.
In this section we compare the general computational performance of the WARDuino virtual machine with each approach.
For the dynamic language we used the popular Espruino #cite(<williams14:espruino>) runtime for JavaScript.
For the static runtime we compared WARDuino with another WebAssembly byte-code interpreter that is small enough to run on microcontrollers, namely WASM3 @massey21:wasm3.
Since it is still the most widely used language for microcontrollers, we used C as the compiled language.
We use each approach to run the same microbenchmarks on a microcontroller.
Since we are interested in comparing the general computational performance and memory occupancy of our approach, our benchmarks consist of standard computational tasks; such as calculating the greatest common divider, factorial, binomials, Fibonacci sequence, or verifying if a number is prime.


Espruino @williams14:espruino is a commercial JavaScript based microcontroller platform for IoT applications.
Like WARDuino, Espruino is a VM that runs on microcontrollers.
Instead of running WebAssembly, it interprets JavaScript, a popular programming language.
The pins of the device are exposed as global JavaScript objects with methods for adjusting their value, $mono("D14.set()")$ for example makes pin D14 high.
Other features, such as Wi-Fi connectivity, can be imported and present themselves as JavaScript objects as well.

WASM3 @massey21:wasm3 is a fast WebAssembly interpreter, which uses a special compilation technique rather than JIT compilation to achieve good performance.
It has explicit support for microcontrollers such as the ESP32 @espressif-systems23:espressif.
Similar to WebAssembly it exposes access to the hardware of the microcontroller through a custom WebAssembly module that provides Arduino primitives.
Our benchmark consists of six computationally intensive programs implemented in JavaScript (for Espruino), WebAssembly (for WARDuino and WASM3), and C (as baseline) .
The WebAssembly code was generated from C code with Clang 13 @clang-contributors21:clang.
To ensure an honest comparison this C code is identical in structure to the JavaScript code except for the addition of types.
Additionally, we prohibited the compiler to perform loop unrolling and inlining of the benchmark functions.
@remote:microbenchmarks describes our microbenchmark functions in detail. Each solves some mathematical problem in a naive way.

We compare the performance of the runtimes in terms of execution speed and program size for each microbenchmark.
When measuring the execution speed, we record the execution time of the benchmarks excluding the upload and initialization time of the virtual machines.
We include the program size, because the low-end microcontrollers we are targeting have very limited memory.
In fact, the measurements were performed on an ESP32-DevKitC V4 board#footnote[#link("https://docs.espressif.com/projects/esp-idf/en/latest/esp32/hw-reference/esp32/get-started-devkitc.html")[https://docs.espressif.com/projects/esp-idf/en/latest/esp32/hw-reference/esp32/get-started-devkitc.html]].
This board features an ESP32 WROVER IE chip that operates at 240 MHz, with 520 KiB SRAM, 4 MB SPI flash and 8 MB PSRAM.
This is a representative board for the kind of resource-constrained microcontrollers targeted by WARDuino.
There exist more resource-rich devices that are used for IoT applications, such as the Raspberry Pi devices, but these are so powerful that many of the challenges outlined in this chapter are present to a far lesser extend.
For example, as a Raspberry Pi has a full-fledged operating system, it is trivial to adapt the code remotely (with ssh).

==== Espruino

// todo paste tikz plots as svg here
#figure(image("../placeholder.png"), caption: [The execution times of WARDuino and Espruino. #emph[Top Left]: absolute execution times for the benchmarks. #emph[Top Right]: sizes of the programs uploaded to the VM. #emph[Bottom Left]: execution time normalized to native C execution time. #emph[Bottom Right] execution times normalized to the WARDuino execution time.])<fig:espruino>  // todo

@fig:espruino shows the results of the benchmarks for Espruino and WARDuino.
In each graph the green (right) bars indicate the measurements for Espruino, the red (left) bars show the results for WARDuino.
The first graph, on the top left, shows the absolute execution times of each benchmark on a log scale.
The overhead of the WARDuino and Espruino implementations compared to execution time of a native C implementation are shown in the graphs at the bottom.
We see that WARDuino consistently outperforms Espruino by roughly a factor of 10.
In fact, the geometric mean of the overhead relative to WARDuino is 11.66.
Note that the difference is even larger for the `tak` benchmark.
This may be attributed to the extreme amount of recursion the `tak` function exhibits.
This suspicion seems to be confirmed by the (iterative) `fib` benchmark that calculates Fibonacci numbers without recursing.
In this benchmark the performance difference is indeed less pronounced as in the `tak` benchmark.


In the last graph (top right) we show the byte code sizes uploaded to the instantiated virtual machines.
We see that the WARDuino size is never larger than the JavaScript files.
This is not surprising, as WebAssembly programs are saved in a binary format, and were optimized for size by the compiler.

==== WASM3

#figure(image(height: 15em, "../placeholder.png"), caption: [The benchmark execution times of WARDuino and WASM3. #emph[Left]: absolute execution times. #emph[Right]: execution times normalized to WASM3 execution time.])<fig:wasm3>  // todo

@fig:wasm3 compares the performance of WASM3 and WARDuino.
The graph on the right side shows the overhead of the WARDuino virtual machine relative to the WASM3 runtime.
We see that WASM3 executes the same WebAssembly program approximately forty times faster than WARDuino, to be precise, the geometric mean of WARDuino's overhead compared to WASM3 is 40.75.

Although WASM3 is faster than WARDuino, the interpreter's architecture, comes with a significant drawback on memory-constrained devices.
It trades memory space for time.
Our \texttt{tak} benchmark cannot run on the ESP32 with WASM3 because the device runs out of memory.
In contrast, this benchmarks runs well on WARDuino.
We excluded the \texttt{tak} benchmark from the second graph in figure~\ref{fig:wasm3} for this reason.
Note that the WebAssembly program implementing \texttt{tak} does run on the same device with WARDuino.

==== Comparison

#let benchmarks = csv("benchmark.csv", delimiter: " ", row-type: dictionary)

#let data = ()
#for (.., name, espruino, warduino, wasm3, native) in benchmarks {
    data.push((name,
    calc.round(float(espruino), digits: 2),
    calc.round(float(warduino), digits: 2),
    calc.round(float(wasm3), digits: 3),
    calc.round(float(native), digits: 3),
    calc.round(float(espruino)/float(native), digits: 2),
    calc.round(float(warduino)/float(native), digits: 2),
    calc.round(float(wasm3)/float(native), digits: 2)))
}


#let linewidth = 0.5pt

#let content = ([name], table.vline(stroke: linewidth), [Espruino (s)], [WARDuino (s)], [WASM3 (s)], [C (s)], $"Espruino" / C$, $"WARDuino" / C$, $"WASM3" / C$, table.hline(stroke: linewidth))
#content.push(table.hline(stroke: linewidth))
#for entry in data.flatten().map(entry => [#entry]) {content.push(entry)}
#content.push(table.hline(stroke: linewidth))
#content.push("mean")
#let means = array.range(data.first().len() - 1).map(i => {
  let col = data.map(row => row.at(i + 1)).filter(j => not j.is-nan())
  calc.round(calc.root(col.product(), col.len()), digits: 3)
})
#for mean in means { content.push(str(mean)) }

#let t = [
#set text(size: small)
#show regex("NaN"): [---]
#table(columns: 8, align: right, stroke: none, ..content) 
]

#figure(
  t,
  caption: [Left: Absolute execution times in seconds for all tests. Right: Execution time of tests normalized to the native C implementation. The means shown in the table are geometric means.])<tbl:allbench>

The complete benchmarks results are shown in table~\ref{tbl:allbench}.
In the first four columns of the table, we report the time that elapses between starting and ending the execution of the microbenchmark ten times for each platform.
On the right, we list the execution times normalized to the execution time of the native C implementation.
Because the C implementation does not run in a managed environment, it is much faster.
To add two numbers for example, no stack access is needed in native C.
Since WebAssembly is a stack machine, and our implementation does not yet feature a JIT compiler, memory access is required to perform all basic operations.
Taking the geometric mean of the normalized execution times, shows that WASM3 is 11 times slower than its native C, while WARDuino is about 428 times slower and Espruino is 4992 times slower.
We note that clang was instructed to optimize for size.
Setting the compiler to optimize more at the cost of binary size can have a big impact on the performance of WARDuino at the price of binary size code.
Not optimizing for binary size reduces WARDuino's overhead compared to C to 312x.

=== Conformance to the WebAssembly Standard <remote:comformance-to-the-wa-standard>

The WebAssembly working group provides a test suite for the core WebAssembly semantics#footnote[#link("https://github.com/WebAssembly/spec/tree/main/test/core")[github.com/WebAssembly/spec/tree/main/test/core]].
These integration tests are meant to help runtime implementers verify that their implementation follows the official specifications.
Each test contains a WebAssembly module to be loaded by the virtual machine, and a sequence of assertions to check. These assertions specify an action to execute on the module, and the expected result.

We used the official specification test suites to test the WARDuino virtual machine extensively.
Because WARDuino does no yet support the latest extending proposals, we use the 15295 tests of the latest specification test suite that only test the original core specification.
For instance, we leave out the tests for SIMD instructions, since this proposal has not been adopted by the WARDuino virtual machine.
Besides the official specifications, we wrote our own specification test for the WARDuino primitives and extension.
Analogous to the official tests, we use these tests to verify that our primitives do not cause ill-formed stacks and only throw traps under the right conditions.

=== Discussion

The computational benchmarks in this section show that WARDuino is roughly ten times faster than the popular Espruino virtual machine.
While IoT applications typically do not perform many computationally heavy tasks, we believe that the difference in performance for these benchmarks is significantly large enough to show that WARDuino—and WebAssembly generally—can easily outperform dynamic interpreters for high-level languages.
At the very least, we may conclude that WARDuino is certainly fast enough for real-world IoT applications, such as those run with Espruino.
This is further illustrated by the smart light application at the beginning of this section, which shows that WARDuino can indeed be used to program embedded devices with AssemblyScript.

The microbenchmarks also show that WARDuino executes programs significantly slower than their native counterparts.
The extra execution time allows us to provide the developer with the safety guarantees of WebAssembly and features such as remote debugging and over-the-air updates.
Measurements of the WASM3 virtual machine show that WebAssembly program can run faster in WASM3 on microcontrollers than in WARDuino.
While WARDuino has a significant overhead in speed compared to WASM3, it does manage to run with a lower memory footprint, as WASM3 is not able to run all our benchmarks without exceeding the memory limits of our microcontroller.
Additionally, WASM3 also does not enable remote debugging and over-the-air updates.
Nevertheless, we believe that we could use techniques from WASM3 to further improve WARDuino's performance.

Aside from performance, we have shown that WARDuino conforms to most of the core WebAssembly specification.

== Related Work <remote:related-work>
WARDuino presents a WebAssembly virtual machine for microcontrollers and a collection of extensions to the WebAssembly standard. In this section we discuss the related work for each aspect in turn. We focus first on programming microcontrollers with non-WebAssembly solutions. Then we discuss other WebAssembly embeddings for microcontrollers. After this, we finish our related work by summarizing the alternative methods for handling interrupts in WebAssembly.

=== Programming Embedded Devices <programming-embedded-devices>
The world of programming languages for microcontrollers is heavily dominated by the C language @kernighan89:c-programming-language, but an increasing range of programming languages have been ported to various hardware platforms, such as: Forth @rather76:forth, BASIC @kemeny68:basic, Java @gosling96:java-language-specification, Python @rossum95:python, Lua @ierusalimschy96:lua-an-extensible-extension-language and Scheme @yvon21:small. Here we restrict ourselves to compare popular implementation approaches for IoT functionality on ESP-based microcontrollers, the platform on which WARDuino was primarily tested.

The predominant programming language for programming the ESP processor is C @kernighan89:c-programming-language@espressif-systems23:esp-idf. The advantage of using C is that the programs execute fast. The downside is that it places the burden of managing memory onto the developer. Another downside of the C language is that once a bug is potentially solved, the programmer needs to re-compile, flash the hardware and restart the device completely. Flashing the chip can take a long time, making the development of microcontroller software a rather slow process.

In recent years the concept of remote debugging has seen its first implementations for embedded systems. The recently released Arduino IDE 2.0 comes with a debugger interface that allows developers to debug C and C++ code with standard debugging operations. It does not support any over-the-air updates @soderby24:debugging. Subsequently, developers still need to flash the entire software at every change. In contrast, WARDuino allows both remote debugging and over-the-air updates to ease program development on ESP processors.

The Zerynth Virtual Machine @zerynth-s-r-l-21:zerynth allows developers to run Python programs on 32-bit microcontrollers, but it mainly targets the ESP platform. Users can send HTTP and MQTT request by using the Zerynth standard library. Like our work, these network primitives are implemented in C and exposed in a (Python) module. Zerynth only supports Python, whereas WARDuino aims to build a common WebAssembly based intermediate representation that allows a multitude of languages to use the networking capabilities of the embedded device. Additionally, WARDuino supports remote debugging with breakpoints, a capability the Zerynth VM does not offer.

Espruino @williams14:espruino allows programmers to use a dialect of JavaScript by running a JavaScript interpreter on the chip. The VM is unfortunately too slow to program the device drivers in JavaScript. Therefore, most support for displays and sensors is hard-coded in the Espruino VM. Espruino has MQTT and HTTP modules that can be used in the traditional callback-based style of JavaScript. The VM offers both a web IDE, and a command-line tool to program microcontrollers. Both applications offer roughly the same functionalities, and can connect to a remote device over many connection types, such as serial, Wi-Fi, or Bluetooth. Once connected to a device, Espruino can provide the developer with a REPL to execute JavaScript code directly on the device. This way Espruino does support over-the-air updates. The Espruino runtime contains a built-in remote debugger, which uses the same commands as GDB.

MicroPython @george21:micropython is a highly optimized subset of the Python programming language. It provides on the chip compilation of Python programs. MicroPython supports HTTP requests through its `urequests` module and MQTT with the `micropython-mqtt` community package. The MicroPython project does not provide any means for remote debugging itself, but does offer a REPL in the browser that can connect with embedded devices over serial or Wi-Fi @george21:micropython. However, there are a few integrated development environments for Python that can use MicroPython, such as the Mu @tollervey22:code and Thonny @annamaa15:introducing editors, which do support minimal remote debuggers. Unfortunately, both debuggers only supports larger Raspberry Pi devices, and do not appear to support smaller microcontrollers targeted by WARDuino.

There are multiple projects for using Ruby on embedded devices, the most widely used and actively maintained is mruby @yukihiro23:mruby. The mruby project partially implements the ISO standard for the Ruby language. Unfortunately, mruby does not support a remote debugger for embedded devices and developers are forced to rely on print-statement debugging. The project does include its own package manager, which gives developers access to a variety of libraries for accessing hardware and using IoT protocols @yukihiro23:mruby@mcdonald23:mruby-esp32-system@koji23:mruby-arduino. However, most libraries are open-source projects, and given the small community, many libraries are no longer being actively maintained.

=== Over-the-air Programming <remote:over-the-air-related>
The high-level languages described so far have varying support for over-the-air updates, mostly in the form of remote REPLs. However, the idea of updating low-end embedded devices over-the-air is not new, and the idea has received considerable attention in the context of sensor networks. For instance, already in 2002 #cite(<levis02:mate>, form: "prose") created a byte-code interpreter for tiny microcontrollers called Maté. Maté was designed to reprogram sensor networks through self-replicating packages of just 24 instructions. More recently, #cite(<baccelli18:reprogramming>, form: "prose") looked at reprogramming low-end devices with a low-code approach, where Business Process Modelling Notation (BPMN) @rospocher14:ontology is translated into JavaScript code by a central server and sent to the devices of the sensor network over the air. Similar to a lot of systems for over-the-air updates, in this work the software running on the low-end device is updated in its entirety. The functional approach was also explored by #cite(<lubbers21:interpreting>, form: "prose") in the Clean language @brus87:clean, specifically, task oriented programming was adopted for tiny low-end microcontrollers. Task oriented programming is a programming paradigm for distributed systems, where tasks represent units of computations, which—like monads—can be constructed with combinators, and which share data via their observable values @plasmeijer12:task-oriented. Individual tasks can be compiled to bytecode and sent to devices to be executed, enabling partial updates of the code. While these three approaches are very different, each focuses on low-end microcontrollers similar to WARDuino. By contrast #cite(<de-troyer18:building>, form: "prose");, developed a reactive programming approach for the more powerful Raspberry Pi computers. Raspberry Pi’s are far bigger than the low-end devices targeted by WARDuino, and have subsequently much more resources, but they are still used considerably for the Internet of Things @maksimovic14:raspberry. The reactive language allows the entire life-cycle of a device to be programmed, including the deployment of software and over-the-air updates. Again, the over-the-air updates are limited to the entire program.

In contrast to these works, the main motivation behind WARDuino is to simplify development of IoT applications in a way that is widely applicable. In this spirit, the idea of over-the-air updates is adopted by WARDuino as an extension to the classic debugging operations. This provides developers with powerful operations during debugging; partial code updates, and changing variable values. Additionally, we believe the small-step semantics of the over-the-air updates present a novel contribution, which in future work can form the basis for proving the correctness of updates by showing that programs remain well-typed.

While we are not aware of any other attempts to describe over-the-air updates of binary code through a small-step semantic, there is some theoretical work on live updates. For instance, in 1996, #cite(<gupta96:formal>, form: "prose") showed that the validity of live updates is generally undecidable. However, most work has been focused on distributed systems specifically, and the issues that arise due to the distribution of nodes. identified the important problem of; when is a system in the appropriate state for a live update? The proposed solution was later improved by #cite(<vandewoude07:tranquility>, form: "prose");. In WARDuino this problem is largely circumvented because the updates are integrated in the debugger.

=== WebAssembly on Embedded Devices <webassembly-on-embedded-devices>
Since the start of the WARDuino project, many others have started looking into running WebAssembly on embedded devices. These projects range widely in scope and focus. Here, we give an overview of some projects bringing WebAssembly to IoT and Edge Computing.

The WebAssembly Micro Runtime @huang21:webassembly-micro-runtime and WASM3 @massey21:wasm3 are WebAssembly runtimes with a small memory footprint like WARDuino. The WebAssembly Micro Runtime specifically aims to have a tiny memory footprint such that it can be used in constraint environments, such as small embedded devices. The runtime largely supports the WASI standard @hickey20:webassemblywasi, including the `pthreads` API that allows developers to use multithreading. However, it does not support the WASI `sockets` API providing internet connection. WASM3 can run on microcontroller platforms, such as the ESP32. In the first place, the microcontroller support is a research project to test and showcase their novel interpreter that uses heavy tail-call optimizations rather than JIT compilation to improve performance @massey22:m3. Not using JIT compilation is the main reason the WASM3 interpreter has such a small footprint and can run on microcontrollers. WASM3 supports most of the new WebAssembly proposals and can run many WASI apps, but it does not fully support the `pthreads` or `sockets` API. WARDuino brings a more general mechanism to WebAssembly that allows both synchronous and asynchronous network communication without the need for a full-fledged operating system. Unlike the WebAssembly Micro Runtime, WASM3 has explored remote debugging. Specifically, the project examined the remote debugging protocol of GDB to try and debug source-level WebAssembly @shymanskyy23:wasm3wasm-debug. This effort was not targeted at microcontrollers, but could work on embedded devices with a JTAG hardware debugger. By contrast, WARDuino can remotely debug microcontrollers without the need for a dedicated hardware debugger. Additionally, WARDuino supports over-the-air updates, something neither the WebAssembly Micro Runtime nor WASM3 allow.

Wasmer @wasmer--inc-22:wasmer is another WebAssembly runtime that reports to be fast and small enough to run on Cloud, Edge and IoT devices. The runtime supports WASI programs, but it does not support threading and is waiting for the official Threads Proposal for WebAssembly to reach the implementation phase, which it has not at the time of writing. However, it does support Emscripten’s pthread API. Unfortunately, the project does not provide a list of supported microcontroller platforms and does not seem to target devices with limited memory. Neither does the project provide clear instructions on how to execute the Wasmer runtime on embedded devices. While the project developed their own WebAssembly package manager (wapm), there are currently no packages for IoT protocols such as MQTT, or for interacting with hardware peripherals. Wasmer is currently working on its debugging support, which is limited at the time of writing. Moreover, the project does not seem to target remote debugging of embedded devices at this stage.

=== Interrupt Handling in WebAssembly <remote:async-related>
There are different efforts in the WebAssembly community to add support for handling asynchronous to the standard. As WebAssembly is still primarily used on the web, most of the new proposals to the standard are made because of certain needs arising from the web. The WASI `pthreads` API, The threads and stack switching proposals @webassembly-community-group22:webassembly are no exception.

The threads and stack switching proposals allow WebAssembly to run asynchronous code, this could then be used to add interrupts to WebAssembly. These proposals themselves do not provide a dedicated system for interrupts. Developers would have to implement a complete callback handling system in WebAssembly themselves. Without a dedicated system for interrupts, everything would have to be implemented directly into WebAssembly, which is not a trivial task. Additionally, both proposals allow the space taken by the stack(s) to grow fast, an unwanted side effect on memory constrained devices. WARDuino only executes one callback at a time keeping the stack size as low as possible.

A very recent chapter by #cite(<phipps-costin23:continuing>, form: "prose");, alternatively proposes a universal target for non-local control flow that relies on effect handlers @plotkin09:handlers. In our opinion this solution is more attractive than the threads and stack switching proposal, primarily due to its simplicity—it only adds three new instructions—and its universality. Similar to the stack switching proposal, a callback handling system comparable to the one described here, could most likely be built on top of this system. However, continuations are still expensive, since they also need to save the entire stack. Furthermore, the proposal is again not enough to support asynchronous primitives. The effect handlers would only allow us to create a system for handling interrupts with callback functions, directly in WebAssembly code. In this case, we arrive at the same solution we have outlined in this chapter, except the implementation has moved from the virtual machine to WebAssembly code. It is not clear whether this approach would have any benefits.

The WebAssembly System Interface (WASI) @hickey20:webassemblywasi is a collection of standardized APIs for system level interfaces. It is not part of the official WebAssembly standard, but is widely used. The WASI `pthreads` API could be used to implement interrupts in WebAssembly. WASI provides a means to access system level APIs in WebAssembly. As with our approach, these API functions can be imported from a module named `env`. The expectation is that the WASI `pthreads` API could be used to implement a callback handling system. Again, this is currently only an idea, as we are not aware of anyone actually realizing such an implementation. Building a callback handling system on top of WASI already has its own challenges, but using it on embedded systems adds an additional layer of constraints. As a start, simply supporting the full WASI specification on embedded devices has proven to be complicated in practice @massey21:wasm3. To the best of our knowledge there is no WebAssembly runtime for constrained devices that fully supports WASI. Moreover, this approach does not seem to have much traction in the community, as there are several online discussion threads to add a more dedicated API for asynchronous interrupts to WASI#footnote[In particular the #link(
    "https://github.com/WebAssembly/WASI/issues/79",
  )["Alternative to a "conventional" poll api?" (Issue 79)] discussion is interesting here, it describes almost exactly the use-case our callback handling system enables. Other relevant discussions are #link(
    "https://github.com/WebAssembly/WASI/issues/276",
  )["Execution Environment for Asyncify Lightweight Synchronize System Calls" (Issue 276)] and #link(
    "https://github.com/WebAssembly/WASI/issues/283",
  )["Poll + Callbacks" (Issue 283)];. These discussions can be found on #link("https://github.com/WebAssembly/WASI/issues");.];. However, not much work has been done around these discussions, and it seems WASI is waiting on the official proposals before they create their own API.
// todo check github discussions note (update)

== Conclusion <remote:conclusion>
This chapter presents the design and implementation of WARDuino that addresses key challenges associated with developing IoT applications: #emph[low-level coding];, #emph[portability];, #emph[slow development cycle];, #emph[debuggability];, #emph[hardware limitations];, and #emph[bare-metal execution environment];. The WARDuino virtual machine enables programmers to develop IoT applications for microcontrollers in high-level languages—compiled to WebAssembly—rather than low-level languages such as C. Higher-level languages can help developers by providing automatic memory management and by giving extra guarantees via type systems. Additionally, using a universal compile-target such as WebAssembly, WARDuino can greatly improve the #emph[portability] of microcontroller programs. The virtual machine supports the WebAssembly core specification and several important extensions to support common aspects of IoT applications.

Access to device peripherals and common M2M protocols is provided by WebAssembly primitives embedded in the virtual machine. These primitives include functions for synchronous (HTTP) and asynchronous (MQTT) communication protocols. To support asynchronous code, WARDuino allows developers to assign callback functions as handlers for asynchronous events, such as incoming MQTT messages or button presses. Whenever a subscribed event occurs, WARDuino will transparently execute the callbacks in isolation of the running program as shown by the small step reduction rules for the callback handling system.

Language integration for high-level languages, exposes the WARDuino primitives as a library with an interface that is conventional for the host language. We have presented different levels of integration for the AssemblyScript language, with higher integration bringing more of the advantages of high-level coding to WARDuino. Our AssemblyScript library, for example, exposes primitives that accept strings although WebAssembly does not have a #emph[string] type. Internally, our library translates the AssemblyScript strings to WebAssembly memory slices. Developers can thus use WARDuino without having to worry about these kinds of implementation details, or deal with the headaches of #emph[low-level coding];.

Another important contribution is the improved #emph[debuggability] of microcontrollers provided by the WARDuino remote debugger. Developers can send debug messages over any communication channel to the virtual machine and mandate it to pause, resume, step or dump its state. In the paused state, developers can use the same mechanism to reprogram a running application. WARDuino can update local variables, functions, and even the entire program over the air. This speeds up the #emph[slow development cycle];, as developers no longer need to wait while their program is re-flashed to the device. To further ease debugging we created a VSCode plugin that allows remote debugging of a WARDuino instance in a graphical user interface. Thereby, creating a development experience which is much closer to conventional computer programming.

Uniquely, the debugging, over-the-air programming, and callback handling system have been described formally as extensions to the operational semantics of WebAssembly. The small-step reduction rules provide a precise description of these systems, and allow them to be easily implemented by other WebAssembly virtual machines. Furthermore, the semantics allow us to prove desirable properties over the debugger and callback handling system. We prove that the debugging semantics are observationally equivalent to the underlying WebAssembly semantics. In future work, we want to explore other desirable properties, for example that the over-the-air updates cannot break a well-typed WebAssembly program.

We evaluate our work by demonstrating that it is suitable and stable enough to program traditional long-running IoT applications with a smart lamp application in AssemblyScript, a snake game and a whole suite of microbenchmarks. Additionally, we compare WARDuino’s performance to that of WASM3 and Espruino. We conclude that we are on average 428 times slower than a native C implementation of computationally intensive microbenchmark. By comparison, WASM3 is 10 times slower and Espruino is 4.991 times slower. Although performance improvements are likely possible, we believe that WARDuino is fast enough for IoT applications as the much slower Espruino is widely and successfully used for this goal.

