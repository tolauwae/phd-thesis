#import "../../lib/util.typ": code, snippet, line, algorithm, semantics, lineWidth, headHeight, tablehead, highlight, boxed
#import "../../lib/class.typ": note, definition, theorem
#import "./figures/semantics.typ": *
#import "../semantics/arrows.typ": *
#import "../semantics/forms.typ": brackets

#import "@preview/lovelace:0.3.0": pseudocode, with-line-label, pseudocode-list, line-label

The second, and final, new debugging technique we investigated for microcontrollers, is multiverse debugging.
As part of our investigation, we extended multiverse debugging to handle input/output (I/O) operations, and created a prototype debugger that enables reversible actions on microcontrollers.

== Introduction

    Debugging non-deterministic programs is a challenging task, since bugs may only appear in very specific execution paths @mcdowell89:debugging@gurdeep22:taming.
    This is especially true for microcontroller programs, which typically interact heavily with the environment.
    This makes reproducing bugs unreliable and time-consuming, a problem that traditional debuggers do not account for.
    By contrast, multiverse debugging @torres19:multiverse is a novel technique that solves this problem by allowing programmers to explore all possible execution paths.
    A multiverse debugger allows users to move from one execution path to another, even jumping to arbitrary program states in parallel execution paths. This entails traveling both forwards and backwards in time, i.e. a multiverse debugger is also a time travel debugger.
    So far, existing implementations work on abstract execution models to explore all execution paths of a program @torres19:multiverse@pasquier22:practical@pasquier23:debugging@pasquier23:temporal. Within these semantics, only the internal state of the program is controlled.

Unfortunately, debugging programs that involve I/O operations using existing multiverse debuggers can reveal inaccessible program states that are not encountered during regular execution.
This is known as the probe effect @gait86:probe, and can occur in multiverse debuggers when they do not account for the effect of I/O operations on the external environment when changing the program state.
Encountering such states during the debugging session can significantly hinder the debugging process, as the programmer may mistakenly assume a bug is present in the code, when in fact, the issue is caused by the debugger.
In this chapter, we investigate how we can scale multiverse debugging to programs running on a microcontroller which interacts with the environment through I/O operations.
    This introduces three new challenges.

    First, the effect of output operations on the environment can influence later states in the execution path, for example when a robot drives forward.
    Therefore, when stepping backwards, the changes made to the environment by the program must be reverted to stay consistent with normal execution.
    Otherwise, the debugger may enter inaccessible execution paths.
    This far-reaching probe effect, is especially difficult to control when making arbitrary jumps in the execution tree.

    Second, input operations from the external environment make it difficult to maintain reproducibility @frattini16:reproducibility.
    There are often too many possible execution paths to explore due to an infinite range of inputs.
    Furthermore, it is impractical for developers to enumerate all possible inputs, or to perfectly configure the environment to achieve a specific execution path every time.
    Without a way to handle the large ranges of possible inputs, the reproducibility of non-deterministic bugs in the multiverse debugger becomes challenging.

    Third, due to the hardware limitations of the microcontrollers that we target it is unfeasible to run the multiverse debugger entirely on the microcontroller.
    We thus need to expand multiverse debugging so that it can be used even in such a restricted environment.

    // === Overview
    // In this chapter, we present a new approach to multiverse debugging tackling the three main challenges posed in the introduction.     
    // First, we establish a well-defined set of I/O operations that are _deterministically reversible_, which is a crucial requirement for the correctness proof of our multiverse debugger.
    // Secondly, we define semantics such that the multiverse debugger can instrument input operations, which is needed to allow the programmer to interactively explore the execution tree.
    // Third, we define our multiverse debugger as a _remote debugger_ with a sparse snapshotting semantics to accommodate the hardware limitations of the microcontrollers that we target.    
    // Finally, based on our formal semantics, we have implemented a prototype debugger, called MIO, on top of the WARDuino WebAssembly virtual machine~@lauwaerts24:warduino capable of debugging various microcontrollers such as the ESP32, STM32 and Raspberry Pi Pico.

== MIO: Multiverse Input/Output Debugger in Prctice<mult:practice>

Before we discuss the details of our contributions and the implementation, we give an overview of how our multiverse debugger, MIO, works in practice. We will use a simple example to illustrate the different concepts of our multiverse debugger.

=== Example: A Light Sensor Program

#figure(
  caption: [Screenshot of the MIO debugger debugging a small light sensor program.
        Top (1): the debug operations; pause or continue, step back, step over, step into, step to the previous line, step to the next line, and update software.
        Left pane (2): source code.
        Top-right pane (3): the multiverse tree. //%, where each node is a WebAssembly instruction.
        Popup window (4): window to add mocked input.
        Bottom-right pane (5): the current mocked input.
        Bottom pane (6): general debugging information, such as the global and local variables, and the current program counter.],
  rect(inset: 0mm, image("figures/debugger11.png", width: 100%)))<fig:multiverse-debugger>


Consider a simple program that reads a value from a color sensor, to measure the light intensity, and turns on an LED with a color corresponding to the value read.
The left side of @fig:multiverse-debugger (2) shows the example program written in AssemblyScript @battagline21:art.
Reading the value from the color sensor happens through the #emph[colorSensor] function, and changing the color of the LED happens through the #emph[digitalWrite] function.
In an infinite loop, the program reads a value from the color sensor.
If the value is below a threshold, the red LED is turned on, and otherwise the blue LED is turned on.
At the end of the loop the program waits for 1000 milliseconds before starting the next iteration.

=== The Frontend of the Multiverse Debugger

@fig:multiverse-debugger shows the MIO multiverse debugger in action.
While debugging, the program and the debugger backend run on a microcontroller connected to a computer running the debugger frontend, shown in the screenshot.
The left pane (2) shows the program being debugged, in this case the light sensor program.
In the top left corner (1), the user can see the debug operations available, which are in order; pause or continue, step back, step over, step into, step to the previous line, step to the next line, and finally, update the code on the microcontroller.
The top-right pane (3) shows the multiverse tree, where each edge represents a WebAssembly instruction.
In MIO all nodes are considered unique states, which means that loops are unrolled and no states will ever collapse into each other, making this graph always a rooted tree.
MIO allows input values to be mocked using the #emph[Mock] button, which triggers a popup window (4) where users can specify the mocked return value for a given input primitive.
The #emph[Create range] button can be used to add a range of new branches to the multiverse tree.
The mocked primitives show up in the bottom-right pane (5), where they can also be removed again.
The bottom pane (6) shows the global and local WebAssembly variables, and other program state information.

While debugging the light sensor program, the user can pause the program at any moment.
At this point, the right pane will show the already explored paths of the multiverse tree.
It is important to note that the multiverse tree does not correspond to a control flow graph, but shows every succeeding program state.
Every edge in the tree represents the concrete execution of a single WebAssembly instruction, and every node represents the program state after that instruction.
The multiverse tree in @fig:multiverse-debugger labels every node before the execution of a primitive with the primitive name, and labels the outgoing edges with the associated return value.

=== Debugging with the Multiverse Debugger

A developer can use the multiverse debugger to explore the execution of the light sensor program, using the debug operations in the top left corner, following normal debugging conventions.
The right panel continually updates to show where in the program's execution the user is.
However, the multiverse debugger allows for more than just stepping forwards and backwards through the program.
The user can also jump to any node in the multiverse tree by simply clicking on that node, and explore the program from that point onwards with the available debugging instructions.

=== Exploring the multiverse tree

The screenshot in @fig:multiverse-debugger shows the program paused at line 64, after reading a value from the color sensor.
This value was 25, and if the user steps forward, the program will turn on the red LED (pin 45) as shown by the multiverse tree.
In an earlier stage, the user actually read a value of 14.
Using the debugger, it is possible to explore that execution path again, without having to recreate the situation where the sensor reads 14.
This is done by clicking on any node on the execution path where the sensor reads 14, which is shown as a blue node with a white circle in it.
If the user presses the #emph[Jump] button, the debugger will traverse the blue-indicated path in the multiverse tree, from the current node to the selected node.
When reading the sensor value, the debugger will use mock input actions, to override the normal behavior of the sensor and return the value 14.

The mocking mechanism is a crucial part of the multiverse debugger, since it allows the user to explore different execution paths without having to recreate the exact conditions that led to that path.
It is therefore not only a part of the automatic traversal of the multiverse tree, but also a part of the manual exploration of the tree.
While a user is stepping forwards through a program, and a non-deterministic input primitive is encountered, they can press the #emph[Mock] button below the right pane instead of the #emph[step] button.
When doing so, window (4) shown in @fig:multiverse-debugger is used. This window allows the user to specify that the virtual machine should return a specific value when a primitive is called with certain arguments.
This allows users to easily reproduce bugs that might not occur with the sensor values read from the current environment.

Now that we have established how our multiverse debugger works in practice, and its terminology, we will discuss the challenges in creating a multiverse debugger for microcontrollers.

=== Challenge C1: Inconsistent External State during Backwards Exploration
When moving backwards in time, the external state must also be restored.
A multiverse debugger that allows for backwards exploration, but does not handle the external state, will be able to create impossible situations.
For instance, if the light sensor program is paused when the red LED has just been turned on, the debugger can move backwards in time to when the light intensity is measured.
Reading a different value as you step forwards again, this time, the blue LED could be turned on, even though the red LED is still on.
This is an impossible situation, since the LEDs can never be on at the same time in a normal execution of the program.
Stepping back over line 64, therefore, requires a compensating action, which turns off the red LED.
Luckily, such actions can be defined for many different output operations~@schultz20:reversible@laursen18:modelling.

=== Challenge C2: Exploring Non-deterministic Input in Multiverse Debuggers

When a program's execution path is determined by input from the environment, the multiverse debugger needs to explore different execution paths by traveling back in time and changing the input to the program.
However, it is impractical for developers to cover all possible inputs, or to configure the environment exactly right for a specific execution path every time.
To solve this problem, we propose a new approach to multiverse debugging that uses time travel debugging in combination with virtual machine instrumentation to mock input values.
It is important that no impossible values are used for mocking, since they can lead to inaccessible program states.

=== Challenge C3: Keeping Track of the Program State Efficiently

In order for multiverse debugging to work on a microcontroller it has to keep track of the program state and its output effects on the external environment.
However, tracking this information on microcontrollers is not feasible due to the limited memory capacity of these devices.
Therefore, the MIO debugger is a remote debugger, which enables minimal interference with the microcontroller, and allows information to be stored on a more powerful computer.
Even so, it is not feasible to take snapshots for every executed instruction as it would slow down the program significantly, and the size of the snapshot history would quickly become unmanageable.

In time travel debugging, this problem is usually solved by taking snapshots at regular intervals, called checkpoints.
When moving backwards in time, the debugger can then jump to the nearest checkpoint, and replay the program's execution from that point.

To make a checkpointing system work correctly for multiverse debugging, we had to adopt a slightly different approach.
Instead of only taking snapshots at regular intervals, we also take snapshots after each input or output action.
By carefully choosing when snapshots are taken we can ensure the correctness of the replay mechanism. Using this approach, we can significantly reduce the run-time overhead, making multiverse debugging practically usable on microcontrollers.

== A Multiverse Debugger for WebAssembly<mult:multiverse-debugger>

In this section, we discuss the operation of our multiverse debugger through a small-step semantic defined over a stack-based language.
We use WebAssembly as an example language, since it has a full and rigorous language semantics~@haas17:bringing@rossberg19:webassembly@rossberg23:webassembly.
However, our small-step rules include very few details specific to WebAssembly.
Therefore, we believe that the principles of our multiverse debugger can be applied to any stack-based language, with minimal effort.

=== Requirements for I/O operations
While our multiverse debugger can deal with a large set of I/O operations, there are some limitations that make it impossible to support certain I/O operations.
Intuitively, our multiverse debugger supports non-deterministic input primitives as long as the range of possible input values is known.
Output primitives are supported as long as they are atomic, and are deterministically reversible, i.e. after reversing an output operation the environment will be in the same state as before applying the operation. 

#strong[Input primitives] Input primitives are allowed to be non-deterministic as long as the _range_ of the input primitives is known, i.e. a temperature sensor might have a range between -20 degrees till 160 degrees. Knowing the range of our input primitives is important so that the debugger can be instrumented to only sample values that can actually be observed during normal execution.

#strong[Output primitives] First, we require output primitives to be synchronously and atomically, i.e.  all side effects from the operation have to be fully completed during the call of the operation in the virtual machine. Second, for a given execution of the I/O operation, there must be a _deterministic compensating action_. This compensating action undoes the effects of the forward execution, bringing the environment back to a state before executing the actions. 

#strong[Predictable dependencies] We assume _predictable_ dependencies of the I/O operations are known, for example consider a setup where an LED is directly pointed towards a light sensor. During regular execution, turning the LED on will directly influence the possible values which can be read, i.e. there is a dependency between the output pin and the possible sensor values which can be read. 
Our MIO debugger, has initial support for expressing such simple dependencies, in the semantics however, we take abstraction and assume that sensor values are independent. 

=== WebAssembly Language Semantics

We discussed the basics of the WebAssembly language semantics in @chapter:oop (@oop:webassembly).
In this chapter, we again use the same semantics, taken from #cite(form: "prose", <haas17:bringing>).

=== Extending WebAssembly with Primitive I/O Operations<mult:webassembly>

Since multiverse debuggers explore all possible execution paths, they have to be able to reproduce the program's execution, even when non-determinism is involved.
It is therefore important to consider where non-determinism is introduced in the program, and how it can be handled.
Since the WebAssembly semantics on their own are fully deterministic, we can choose precisely where non-determinism is introduced in our system.
In the context of microcontrollers, non-deterministic input is unavoidable. //% since the external environment is inherently non-deterministic.
Our system therefore limits non-determinism exclusively to the input#note[We do not consider parallelism as a source of non-determinism, since this has been examined thoroughly by the original paper on multiverse debugging by #cite(form: "prose", <torres19:multiverse>).].
This means that each branch in the execution tree can therefore be traced to a different input value.
The output primitives in MIO, on the other hand, are deterministic in terms of the program state.
@mult:mocking discuss how the debugger can reproduce non-deterministic input reliably through input mocking.

==== Primitive I/O operations

#semantics(
    [The configuration for the reversible primitives embedded in the WebAssembly semantics from the original paper by #cite(form: "prose", <haas17:bringing>), the differences are highlighted in gray. #emph[Top:] The WebAssembly semantics extended with a primitive table. #emph[Bottom:] The signatures of primitive and their compensating actions.],
    primdef,
"fig:prim-def")

We extend WebAssembly with a set of primitives $P$ that fulfil the prerequisites outlined above.
@fig:prim-def shows the definition of the primitives in WebAssembly.
Each primitive in $P$ can be identified by a unique index $j$, similar to the function indices in WebAssembly, and looking up primitives is done through the global $P(j)$.
When calling a primitive, it returns both the return value $v$ and the compensating action $r$.
The function $r$ compensates, or reverses, the effects of the primitive, but takes no arguments and returns nothing as indicated by its type $epsilon.alt arrow.r epsilon.alt$.
There is no need for any arguments, since the compensating action is generated uniquely for each execution of the primitive.

#semantics(
    [Extension of the WebAssembly language with non-deterministic input primitives.],
    language,
"fig:language")


==== Forwards Execution of Primitives

#let ret = $"ret"$
#let cps = $"cps"$
#let dbg = $"dbg"$
#let msg = $"msg"$
#let mocks = $"mocks"$

Given the definition of the primitives in $P$, we can define the forwards execution of the primitives in WebAssembly, as shown in @fig:language.
Non-determinism is introduced exclusively through the _input-prim_ rule, which is used to evaluate input primitives.
The evaluation of the primitive $p$ non-deterministically returns a value $v$ from the codomain of the primitive function, $floor.l p(v^*_0)_ret floor.r$.
Here, the rule simply discards the compensating action, and places the return value of the primitive on the stack.
The _output-prim_ rule works analogously, except the evaluation produces its return value deterministically.
Note that compensating actions $p(v^*_0)_cps$ are not used for the regular forward execution, but are crucial when moving backwards in time.
In the next sections, we show how the compensating actions are used during multiverse debugging.

=== Configuration of the Multiverse Debugger

#semantics(
    [The multiverse debugger state for WebAssembly with input and output primitives.],
    multconfig,
"fig:mult:configurations")

Using the recipe for defining debugger semantics from #cite(form: "prose", <torres19:multiverse>), we can define our multiverse debugger on top of the extended WebAssembly semantics presented in @mult:webassembly.
@fig:mult:configurations shows the configuration of the multiverse debugger for WebAssembly with input and output primitives.
The program state in the underlying language semantics is labeled with an iteration index $n$, which corresponds to the number of steps in the underlying semantic since the start of the execution, or the depth in the multiverse tree.
The debugger state $dbg$ contains the execution state of the program, incoming debug message $msg$, mocked input $mocks$, the program state $K_n$, and the snapshot list $S^*$.
The snapshots $S^ast$ are a cons list of snapshots $S_n$, containing the program state $K_n$ and the compensating action $p_cps$.
The rules of the debugger semantics, presented in the following sections, will show how the snapshot list is extended—and how the snapshots are used to travel back in time.

Mocked inputs are stored as a key value pairs, where the index identifying the input primitive $j$, and the list of argument values $v^*$ are mapped to the overriding return value $v$.
The key value map is represented here as a partial function, which compares lists of values $v^ast$ element-wise.
For any key that is not defined in the map, we write $mocks(j,v^ast) = epsilon.alt$.

#let nop = $"nop"$

The starting state of the debugger $dbg_"start"$ is defined as the paused state with no incoming or outgoing messages, an empty mocks environment, the initial program state $K_0$, and a snapshot list containing only the initial snapshot $S_0 = { K_0, r_nop }$.
Here $r_nop$ is the empty action, which takes no arguments and returns nothing.
This function indicates that no compensating action is needed.

=== Forwards Exploration in Multiverse Debuggers<mult:forwards>

#semantics(
    [The small-step rules describing forwards exploration in the multiverse debugger for WebAssembly instructions without primitives.],
    forwards,
"fig:forwards")

@fig:forwards shows the basic small-step rules for stepping forwards in the multiverse debugger, without input and output primitives.
These rules allow the debugger to explore traditional WebAssembly programs, without any non-deterministic input or output.
For clarity, we use several shorthand notations in the rules.
We use the notation $(K_n wasmarrow K_(n+1))$ to say that the program state $K$ takes a step to the program state $K'$ in the underlying language semantics, where $K' = K_n+1$.
The notation $(sans("non-prim") K)$ is used to indicate that the program state $K$ is not a primitive call, or more fully, it is not the case that $K = \{ s ;v^ast; v^ast_0 (call \; j) \} and P(j) = p$.
We describe the rules in detail below.

   / run: The rule for running the program forwards in the underlying language semantics. The debugger takes a step in the underlying language semantics ($K_n wasmarrow K_(n+1)$) as long as the execution state is #play, there are no incoming or outgoing messages, and the program state is not a primitive call.
        While running in this way, the snapshot list $S^*$ remains unchanged.

   / step-forwards: When the debugger receives the $step$ message, it takes one more step ($K_n wasmarrow K_(n+1)$), and transitions to the #pause state if it was not already paused.

   / pause: When the debugger receives a $pause$ message in the _play_ state, it transitions to the #pause state. Note that afterwards, all the run rules are no longer applicable.

   / play: The rule for continuing the execution. When the debugger receives the $play$ message in the #pause state, the execution state transitions to the #play state.

#semantics(
    [The small-step rules describing forwards exploration for input and output primitives in the multiverse debugger for WebAssembly, without input mocking.],
    forwardsprim,
"fig:forwards-prim")

The rules in @fig:forwards-prim are the minimal set of rules for stepping forwards when the next instruction in the program state $K_n$ is a primitive call.
The rules also describe the snapshotting behavior of the multiverse debugger, which is needed to travel back in time.
We describe the run rules in detail below.
The step rules are identical to the run rules, but they transition to the paused state after taking a step, and are triggered by the $step$ message.
These rules can be found in @app:rules.

//\begin{description}
//    \item[_run-prim-in_] The rule for calling an input primitive. When the program state is a primitive call, the call will not be mocked, there are no incoming messages, and the execution state is #play, the debugger takes a step forwards in the underlying language semantics ($K_n wasmarrow K_{n+1}$), and adds a new snapshot to the snapshot list $\{K_{n+1} , r_{nop}\}$.
//        The compensating action $r_{nop}$ is used to indicate that no compensating action is needed for input primitives.
//    \item[_run-prim-out_] The rule for calling an output primitive. When the program state is an output primitive call, there are no incoming messages, and the execution state is #play, the debugger will perform the primitive call similar to the _output-prim_ rule in the underlying language semantics.
//        It adds the return value of the primitive to the stack, moving the state to $K_{n+1}$, the same state reached by the underlying language semantics.
//        However, it will not discard the compensating action $p(v^*_0)_{cps} = r$, but add a new snapshot to the snapshot list $\{K_{n+1} , r\}$.
//\end{description}

The rules described here form the backbone of the multiverse debugger, and already allow for a multiverse debugger that can explore the execution of a program forwards in time.
It is important to note that the debugger always takes snapshots when a primitive call is made.
Only when this primitive is an output primitive, can the state of the environment change.
On the other hand, only input primitives can introduce new branches to the multiverse tree.
In the next section, we discuss how the multiverse debugger can explore the execution of a program backwards in time.

=== Backwards Exploration with Checkpointing<mult:backwards>

#figure(image("figures/compensate.svg", width: 90%),
    caption: [Schematic of how the _step-back-compensate_ rule works.
    Starting from state $K_m$, the dotted arrow shows how the debugger jumps to the previous state $K_n$, and compensates the output primitive with $r'()$, while the full arrows show the normal execution.
    Top right: the snapshots before. Top left: the snapshots after.],
)<schematic:backwards>

The multiverse debugger is also a time travel debugger, which means it can move backwards in time.
It does this by restoring the program state from a previous snapshot, and then replaying the program's execution from that point.
@schematic:backwards shows schematically the way the debugger steps back in time using the snapshots.
In the situation depicted by the figure, the debugger has just stepped over an output primitive and added a snapshot to the snapshot list.
Since the debugger will now step back over the execution of this output primitive, its effects must be reversed with the compensating action $r''$ in the last snapshot.
This is shown with the dashed arrow.
As part of this jump back in time, the snapshot containing the compensating action $r''$ is removed from the snapshot list and the program state $K_n$ from the next snapshot is restored.

Since snapshots are only added when the program performs a primitive call, the second to last snapshot in the list was taken after the previous primitive call resulting in state $K_n$.
This means, that after restoring the internal virtual machine state, the program is now at the point right after the previous primitive call.
Starting from this point, the debugger can replay the program's execution forwards to $K_(m-1)$, which will not include any primitive calls.
This means the steps will be deterministic, and will not change the external environment.
This corresponds with the full arrow at the bottom of the figure.
Next to it, is shown the snapshot list after the step back, which now only contains the snapshot of the state $K_n$.

In the outlined scenario the last transition in the chain, from $K_(m-1)$ to $K_m$, performs an output action.
However, if this transition is a standard WebAssembly instruction instead, no compensating action will be performed.
Instead, the debugger will immediately restore the virtual machine state to $K_n$ and replay the program's execution forwards to $K_(m-1)$.
In this case, none of the snapshots will be removed.
This enables the debugger to continue stepping back in time.

#semantics(
  [The small-step reduction rule for stepping backwards in the multiverse debugger.],
  [
    #table(columns: (2.0fr, 1fr), stroke: none, gutter: 1.0em,
      tablehead("Backwards evaluation rules"), "",
      table.cell(colspan: 2, table(columns: (1fr), stroke: none,
        [(#smallcaps("step-back"))#h(1fr)],
        prooftree(rule(
          $
          brackets.l "pause", "step back", mocks, K_m bar.v S^* ⋅ {K_n, r} brackets.r dbgarrow brackets.l "pause", nothing, mocks, K_(m-1) bar.v S^* ⋅ {K_n, r} brackets.r
          $,
          $
          K_n attach(wasmarrow, tr: m-n-1) K_(m-1)$, $m > n$
        )),
        [(#smallcaps("step-back-compensate"))#h(1fr)],
        prooftree(rule(
          $
          brackets.l "pause", "step back", mocks, K_m bar.v S^* ⋅ {K_n, r} ⋅ {K_m, r'} brackets.r dbgarrow brackets.l "pause", nothing, mocks, K_(m-1) bar.v S^* ⋅ {K_n, r} brackets.r
          $,
          $
          "first" r'() "then" K_n attach(wasmarrow, tr: m-n-1) K_(m-1)
          $
        ))

      )),
    )
  ],
  "fig:backwards"
)

Each of the two outlined scenarios corresponds with a rule in the multiverse debugger semantics, shown in @fig:backwards.
The first scenario where the effects of an output primitive is reversed, is described by the _step-back-compensate_ rule.
The second scenario where the last transition is a standard WebAssembly instruction, is described by the _step-back_ rule.
We describe the rules in detail below.

/ step-back: The rule for stepping back in time. When the debugger receives a #emph[step back] message, the debugger restores the external state from the last snapshot in the snapshot list, which is not the current state.
        The debugger then replays the program's execution from that point to exactly one step ($K_n attach(wasmarrow, tr: m-n-1) K_(m-1)$) before the starting state.
        Since the restored snapshot remains in the past, it is kept in the snapshot list, to allow for further backwards exploration.

/ step-back-compensate: The rule for stepping back in time when the last transition was a primitive call.
        This is always the case when the current state is $K_m$ is part of the last snapshot.
        When the debugger receives a #emph[step back] message, the debugger performs the compensating action $r'$ from the last snapshot in the snapshot list, which reversed the effects of the last primitive call.
        Then, the debugger restores the external state $K_n$ from the second to last snapshot in the snapshot list.
        The debugger then replays the program's execution from that point to exactly one step before the starting state.
        The last snapshot is removed from the snapshot list, since it now lies in the future.

In the case where no primitive call has yet been made, the snapshot list contains exactly ${K_0,r_nop}$, as defined by $dbg_"start"$, which the _step-back_ rule can jump to.
If the current state is $K_0$, stepping back is not possible.
Specifically, the _step-back_ rule is not applicable, since $m$ and $n$ are both zero, and the _step-back-compensate_ rule requires the snapshot list to contain at least two snapshots.

=== Instrumenting Non-deterministic Input in Multiverse Debuggers<mult:mocking>

#let rs = $"es"$
#let In = $"In"$

#semantics(
  [The small-step rule for mocking input in the MIO debugger, only including the step rule. The analogous rule for when the debugger is not paused (_run-mock_) is shown in @app:rules.],
  [
    #table(columns: (2.0fr, 1fr), stroke: none, gutter: 1.0em,
      tablehead("Mocking Semantics"), "",
      table.cell(colspan: 2, table(columns: (1fr), stroke: none,
        [(#smallcaps("register-mock"))#h(1fr)],
        prooftree(rule(
          $
          brackets.l rs, msg, mocks, K_n bar.v S^* brackets.r dbgarrow brackets.l rs, nothing, mocks', K_n bar.v S^ast brackets.r
          $,
          $
          msg = mock(j, v^*, v)$,$P(j) = p$,$p in P^(In)$,$v in floor.l p floor.r$,$
          mocks' = mocks, (j, v^*) arrow.r.bar v
          $,
        )),

        [(#smallcaps("unregister-mock"))#h(1fr)],
        prooftree(rule(
          $
          brackets.l rs, msg, mocks, K_n bar.v S^* brackets.r dbgarrow brackets.l rs, nothing, mocks', K_n bar.v S^ast brackets.r
          $,
          $
          msg = unmock(j, v^*)$, $mocks' = mocks, (j, v^*) arrow.r.bar v
          $,
        )),

        [(#smallcaps("step-mock"))#h(1fr)],
        prooftree(rule(
          $
          brackets.l "pause", "step", mocks, K_n bar.v S^ast brackets.r dbgarrow brackets.l "pause", nothing, mocks, K'_(n+1) bar.v S^ast ⋅ {K'_(n+1), r_nop} brackets.r
          $,
          $
          K_n = {s; v^*; v^*_0 (call j)}$, $P(j) = p$, $p in P^(In)$, $
          mocks(j, v^*_0) = v$, $K'_(n+1) = {s'; v'^*; v}
          $,
        ))

      )),
    )
  ],
  "fig:mocking"
)

In order to replay execution paths in the multiverse tree accurately, the multiverse debugger needs to be able to override the input to the program.
Mocking of input happens through the key value map $mocks$ shown in @fig:mult:configurations.
New values can be added to the map using the _register-mock_ rule, and existing values can be removed using the _unregister-mock_ rule.
Whenever the debugger encounters an input primitive call, it will always check the $mocks$ map for an overriding value.
If a value is found, the debugger will replace the call to the primitive with the mock value $v$. This is done by the _step-mock_ rule.

/ register-mock: The rule for registering a new mock value in the multiverse debugger. When the debugger receives a message $"mock"(j, v^*, v)$, the debugger will update the entry for $(j,v^*)$ in the $mocks$ environment to $v$.
        If an entry already exists in the environment, the rule will override the existing value.
/ unregister-mock: The rule for unregistering a mock value in the multiverse debugger. When the debugger receives a message $"unmock"(j, v^*)$, the debugger will remove the mock value from the $mocks$ map.
        If no value is found in the environment, the rule will have no effect. //%, and the messages will simply be removed.
/ step-mock: The _step-mock_ rule for stepping forwards in the multiverse debugger when an input primitive call is encountered. If the input primitive call is found in the $mocks$ map, the debugger will replace the call with the mock value $v$.
The program state is then updated to the new program state $K_(n+1)$, and a new snapshot is added to the snapshot list.
The snapshot includes the new program state and the empty compensating action $r_nop$, since no compensating action is needed for input primitives.

=== Arbitrary Exploration of the multiverse tree

With the semantics of input mocking in place, we now have the entire multiverse debugger semantics for WebAssembly with input and output primitives.
In this section, we discuss how the multiverse debugger can be used to explore different universes.
This can be done by @alg:jumping.
When the debugger jumps from a state $K_m$ to a state $K_n$, the debugger will find the smallest common ancestor of $K_m$ and $K_n$, or the join.
The debugger will then step backwards from $K_m$ to the join.
We use the notation $revarrow$ to indicate that the debugger is reversing the execution, it is equivalent to a debugging step $dbgarrow$ that only uses the _step-back_ and _step-back-compensate_ rules.
In the final step of the algorithm, execution is replayed from the join to $K_n$ using the _step-mock_ rule whenever it encounters a non-deterministic primitive call.

#algorithm(
    [The algorithm for traveling to any position in the multiverse tree.],
    pseudocode-list[
+ #strong[Require] the current program state $K_m$ #strong[and] the target program state $K_n$ #strong[and] the snapshot list $S^*$.
+ $K_"join" arrow.l "find_join"(K_m, K_n)$
+ #line-label(<alg.jumping:while>) *while* $dbg_"current" [K] eq.not K_"join"$ *do*
  + $dbg_"current" revarrow dbg_"next"$
  + $dbg_"current" arrow.l dbg"next"$
+ *while* $dbg_"current" [K] eq.not K_n$ *do*
  + $dbg_"current" dbgarrow dbg_"next"$
  + $dbg_"current" arrow.l dbg_"next"$
], "alg:jumping")

#figure(image("figures/slide.svg", width: 90%),
    caption: [Schematic of how the multiverse debugger can jump to any arbitrary state in the past, using the _step-back_ and _step-mock_ rules.
    For the arbitrary jump from state $K_5$ to $K_4'$, the join $K_1$ is underlined and shown in blue.
    Top right: the list of snapshots before the arbitrary jump. Bottom: the execution path from $K_5$ to $K_4'$.
    Steps with the _step-back_ and _step-back-compensate_ rules are shown as $revarrow$.],
)<schematic:arbitrary-jump>

@schematic:arbitrary-jump illustrates the algorithm for jumping to an arbitrary state, when the user clicks on a node on another branch in the multiverse tree.
The figure shows a possible multiverse tree for a program where the second and third instruction are input primitives.
The program has executed two input primitives in a row, and the debugger has explored some of the possible inputs.
Each node in the figure is labeled with the program state and possible compensating action, where $r_nop$ indicates that no compensating action is needed.
For clarity, the external states are also numbered.
The figure shows clearly that the external state only changes after a primitive call.
The current state is $K_5$, and the debugger wants to jump to $K_4'$.
Per the algorithm, the debugger finds the join of the two states, which is $K_1$.
The debugger then replays the execution from $K_5$ to $K_1$ in reverse order, using the _step-back_ and _step-back-compensate_ rules.
It is important that the debugger steps back one instruction at a time, to ensure that the external state is correctly restored.
From the join $K_1$, the debugger replays the execution to $K_4'$ in the forward order, using the _step-mock_ rule whenever it encounters a non-deterministic primitive call.
This ensures that the jump deterministically follows the exact execution path, thereby ensuring that the external state is correctly restored.

=== Correctness of the Multiverse Debugger Semantics<mult:correctness>

Given the small-step semantics, we can prove the correctness of the MIO debugger in terms of soundness and completeness.
The soundness theorem states that for any debugging session ending in a certain state, there also exists a forwards execution path in the underlying language semantics to that state.
A debugging session is seen as any number of debugging steps starting from the initial debugging state $dbg_"start"$.
The completeness of the debugger means that the debugger can always find a path in the multiverse tree that corresponds to a path in the underlying language semantics.
Together, these properties ensure that the debugger is correct in terms of its observation of the underlying language, and will never observe any inaccessible states.
For brevity, we only provide a sketch of the proofs here, but the full proofs can be found in @app:proofs.

#let start = $"start"$

#let theoremdebuggersoundness = [
    Let $K_0$ be the start WebAssembly configuration, and $dbg$ the debugging configuration containing the WebAssembly configuration $K_n$.
    Let the debugger steps $multi(dbgarrow)$ be the result of a series of debugging messages, where $msg$ is the last message.
    Then:
    $ forall dbg : dbg_start multi(dbgarrow) dbg arrow.double.r.long K_0 multi(wasmarrow)K_n $
]

#theorem("Debugger soundness")[#theoremdebuggersoundness]<theorem:debugger-soundness>

The proof for debugger soundness proceeds by induction over the number of steps in the debugging session.
In the base case, where the debugging session consists of a single step, the proof is trivial since the step starts from the initial state.
In the inductive case, the proof proceeds very similarly, the only non-trivial cases are those for stepping backwards and mocking.

#let theoremdebuggercompleteness = [
    Let $K_0$ be the start WebAssembly configuration for which there exists a series of transition $multi(wasmarrow)$ to another configuration $K_n$. Let the debugging configuration with $K_n$ be dbg.
    Then:
    $ forall K_n : K_0 multi(wasmarrow) K_n arrow.double.r.long dbg_start multi(dbgarrow) dbg $
]

#theorem("Debugger completeness")[#theoremdebuggercompleteness]<theorem:debugger-completeness>

The proof for completeness follows almost directly from the fact that for every transition in the underlying language semantics, the debugger can take a corresponding step. For non-deterministic input primitives, we can step to the same state with the _register-mock_ and _step-mock_ rules.

Together the debugger soundness and completeness theorems ensure that the multiverse debugger is correct in terms of its observation of the underlying language semantics.
However, it gives us no guarantees about the correctness of the compensating actions, and the consistency of external effects during a debugging session.
Due to the way effects on the external environment are presented in the MIO debugger semantics, we can define the entire effect of a debugging session of regular execution, both as ordered lists of steps that have external effects.
There are only two options, the output primitive rules, and the rule that applies the compensating action.

#let external = $italic("external")$

#let extdef = definition("External state effects")[
    The function $external$ returns the steps affecting external state for any series of rules in the debugging or underlying language semantics.
    $ external(p) = cases(
            #[#h(0.4em)] s "for" s "in" p "where" s = "step-prim-out" #[#h(1em)] & "if" p = dbg multi(dbgarrow) dbg',
            #[#h(0.4em)] or s = "step-back-compensate",
            #[#h(0.4em)] s "for" s "in" p "where" s = "output-prim" & "if" p = K multi(wasmarrow) K') $
]
#extdef

Using this definition, we can prove that the external effects of any debugging session ending in a certain state, are the same as the effects of the regular execution of the program ending in that same state.
The definition for the equivalence of external effects ($eq.triple$) is given in @app:proofs.

#let theoremcompensationsoundness = [
    Let $K_0$ be the start WebAssembly configuration, and $dbg$ the debugging configuration containing the WebAssembly configuration $K_n$.
    Let the debugger steps $multi(dbgarrow)$ be the result of a series of debugging messages.
    Then:
    $ forall dbg : external(dbg_(start) multi(dbgarrow) dbg) eq.triple external(K_0 multi(wasmarrow) K_n) $
]

#theorem("Compensation soundness")[#theoremcompensationsoundness]<theorem:compensate-soundness>

The proof of this theorem is based on the fact that our multiverse debugger is a rooted acyclic graph, and a debugging session is a walk in this tree starting from the root, which can include the same edge several times.
Any such walk in a tree can be constructed by adding any number of random closed walks to the path from the root to the final node.
Such closed walks are null operations in terms of their effect on the external state.
This leaves only the forward steps of the minimal path to be considered, meaning the external effects of a debugging session are always the same as those of the regular execution of the program.

== The MIO debugger<mult:implementation>

We have implemented the multiverse debugger described above in a prototype debugger, called the MIO debugger.
The MIO debugger is built on top of the WARDuino runtime.
Our prototype implementation builds further upon the virtual machine and the remote debugging facilities described in @chapter:remote.
Under the hood, the virtual machine needed to be extended significantly in order to support all the basic operations for multiverse debugging: smart snapshotting, mocking of primitives and reversible actions.
Additionally, we created a high-level interface which implements the message passing interface described in @mult:multiverse-debugger as messages in the remote debugger of WARDuino. On top of this interface we built a Kotlin application for debugging AssemblyScript programs on microcontrollers running WARDuino.
This application keeps track of the program states, and shows them as part of the multiverse tree, as shown in @fig:multiverse-debugger from @mult:practice.
@alg:jumping for arbitrary jumping, is implemented at the level of the Kotlin application using the message passing interface of the remote debugger.
Finally, the MIO prototype also has support for expressing simple dependencies, so that the mocking of the various sensor values can be limited depending on state of the output pins. 

=== Output: Reversible Primitives<mult:rotate>

Primitives in WARDuino are implemented in the virtual machine using C macros.
In order to implement reversible primitives, we have extended the existing macros with two new macros; one defines how the external state effected by the primitive can be captured, and the other defines the compensating action given this captured state.
When stepping back over a primitive, the compensating action looks at the state captured after the previous primitive call, and restores this external state.
This is the same as undoing the effects of the last primitive call.

#snippet("fig:motor-impl", [#emph[Left:] The implementation of the #emph[rotate] primitive. #emph[Right:] The implementation of the compensating action for the #emph[rotate] primitive, in the MIO debugger.], columns: (10fr, 13fr), continuous: false,
        (```cpp
def_prim(rotate, threeToNoneU32) {
  int32_t speed = arg0.int32;
  int32_t degrees = arg1.int32;
  int32_t motor = arg2.int32;
  pop_args(3);
  auto encoder = encoders[motor];
  encoder->set_angle(
    encoder->get_angle() + degrees
  );
  return drive(motor, encoder, speed);
}
```, ```cpp
def_prim_serialize(rotate) {
  for (int m = 0; m < MOTORS; i++) {
    external_states.push_back(
    new MotorState(m, encoders[m]->angle()));
}}

def_prim_reverse(rotate) {
  for (IOState s : external_states) {
    if (isMotorState(s)) {
      int motor = stoi(s.key);
      auto encoder = encoders[motor];
      encoder->set_angle(s.degrees);
      drive(motor, encoder, STD_SPEED);
}}}
```
),)

#[
#let encode = "lst.program:7"
#let relative   = "lst.program:8"
#let drive    = "lst.program:10"
#let serialize    = "lst.program:4"
#let set-angle      = "lst.program:12"

To illustrate the implementation of reversible primitives, we will use the example of the #emph[rotate] primitive, which rotates a servo motor for a given number of degrees.
The forwards implementation is shown on the left side of @fig:motor-impl.
//The servo motors are controlled by pulse-width modulation (PWM) signals.
To move the motor a given number of degrees the primitive first sets the target angle of the motor encoder, this happens on #line(encode).
The motor encoder is used to track the current motor angle, as well as the absolute target angle, which can be set with the #emph[set\_angle] method.
To rotate the motor a number of degrees relative to its current position, the primitive adds the degrees to the current motor angle (#line(relative)).
Once the target angle is set, the primitive drives the motor to that angle using the #emph[drive] method, as shown on #line(drive).

The implementation of the compensating action for the #emph[rotate] primitive is shown on the right side of @fig:motor-impl.
First, the #emph[def\_prim\_serialize] macro captures the external state.
For each motor, the current angle of the motor is stored along with its index, as shown on #line(serialize).
Second, the #emph[def\_prim\_reverse] macro compensates the primitive by moving all motors back to the angles captured in the previous snapshot.
The angles captured by the #emph[def\_prim\_serialize] macro are absolute target angles. The compensating action moves the motors back to these angles by first setting the target angle, as shown on #line(set-angle).
It then uses the same #emph[drive] function to move the motor.
]

=== Input: mocking of primitives

The input mocking is implemented analogous to the debugger semantics, by adding a map to the in the virtual machine state.
This map is used to store the mocked values for the input primitives, which are received by a new debug message in the remote debugger.
In line with the semantics, there is also a new debug message to remove a mocked value from the map.
Currently, the map only supports registering primitive calls with their first argument.  %but this can easily be extended to support multiple arguments.
This is sufficient for the current input primitives to be mocked, without any changes to their implementation.

The virtual machine will check the map of mocked values for every primitive call.
The prototype includes two input primitives that can be mocked in this way, the #emph[digitalRead] primitive which reads the value of a digital pin, and the #emph[colorSensor] primitive which reads a value from a uart color sensor.
The digitalRead primitive enables the user to mock the value of a digital pin, and thereby the behavior of a wide range of possible peripherals.
However, the range of possible input values is not always known statically, as it may be influenced by the output effects of the program.
To handle this, the MIO debugger includes initial support for predictable dependencies that can be defined as simple conditions, for example, #emph["when the value of a digital pin $n$ is $x$, then input primitive $p$ with arguments $m$ will return the value $c$"].

=== Performance: Checkpointing

To reduce memory usage, the MIO debugger only stores the snapshots at certain checkpoints.
The semantics of MIO only takes snapshots after a call to a primitive, the prototype implementation follows this checkpointing policy precisely.
As shown by the debugger semantics and the proof, this is the minimum number of snapshots needed to enable backwards and forwards exploration of the multiverse tree.
To further reduce the performance impact on the microcontroller, snapshots are received and tracked by the desktop frontend of the MIO debugger.
To have minimal traffic between the debugger backend and frontend, snapshots after primitive calls are sent automatically to the frontend.
Alternatively, the debugger frontend can request snapshots at will through the remote debugger interface.

// remote debugger
// checkpointing zoals in de semantiek

== Evaluation<mult:evaluation>

To validate that our checkpointing strategy is performant enough for apply multiverse debugging on microcontrollers we performed a number of experiments. 
All experiments were performed on an STM32L496ZG microcontroller running at 80 MHz.
This microcontroller was connected to a laptop running the MIO debugger frontend that communicates with the microcontroller.

#figure(image("figures/benchmark.svg", width: 100%),
    caption: [Comparison of execution time of _no snapshotting_ with _snapshotting for every instructions_, and different checkpointing intervals; _every 5, 10, 50, and 100 instructions_.
        The performance overhead is shown as execution time relative to the execution time when taking no snapshots.
    Left: Comparison of all checkpointing policies, snapshotting, and no snapshotting.
    Right: Comparison of all checkpointing policies with no snapshotting. The averages are taken over 10 runs of the same program.],
)<fig:snapshotting-performance>


//
=== Forward execution with checkpointing

The first experiment evaluates the performance impact of checkpointing on the execution speed. //% overhead of taking snapshots at different intervals in comparison to taking snapshots at every instruction or taking no snapshots at all.
We measured the execution time of a fixed number of instructions, when taking no snapshots, taking a snapshot every instruction, and for snapshotting after different intervals (5, 10, 50, or 100 instructions), as shown in @fig:snapshotting-performance. //% for various different snapshot policies.
To reduce the impact of variable unknown factors, the program executed by the virtual machine includes no primitive calls. Specifically, this program checks for each integer from 1 to $13,374,242$ if they are prime. Because this program has no primitive calls, the VM will only take snapshots at fixed intervals which are determined by the frontend.

The left plot shown in @fig:snapshotting-performance, gives the time it took to execute up to 1250 instructions for each snapshot policy relative to taking no snapshots.
Since snapshotting every instruction is so much slower, we added the right plot showing the same results, but without snapshotting at every instruction.
For such small numbers of instructions, the execution time without any debugger intervention, remains roughly the same, taking on average 222.7ms. These results are shown in red.
In contrast, when taking snapshots after every executed instruction, the execution time increases dramatically.
For 1250 instructions it takes on average 19 seconds, which is around 85 times slower. //% than without snapshotting.
For only 250 instructions the execution time increases seventeen-fold, to 3.9 seconds.

Once checkpointing is used the overhead reduces significantly.
When taking snapshots every five instructions, the virtual machine only needs 4 seconds to execute 1250 instructions.
Per instruction this results in an execution that is only 17.9 times slower.
Taking a snapshot every 10 instructions results in a total execution time of 2.1 seconds.
This results in a slowdown of factor 9.5.
When taking snapshots every 50 instructions, the slowdown lowers to a factor of 2.7.
Going up to a hundred instructions every snapshot, this becomes only a factor 1.9.

This initial benchmark of the checkpointing strategy shows that the performance overhead can be greatly reduced by reducing the number of snapshots taken.
Yet, execution times are still significantly slower than without any snapshotting.
This is due to the fact that the current prototype has not yet been optimized for performance.
The prototype only uses a simple run-length encoding of the WebAssembly memory to reduce the size of the snapshots.
In future improvements, the snapshot sizes could be reduced greatly by only communicating the changes compared to the previous snapshot.
//%This shows that, as the time between checkpoints is increased, the slowdown can be reduced significantly. %to around a factor 2 which is much better than the original 100 times slower execution.
However, in practice the performance is already sufficient to provide users with a responsive debugger interface as we illustrate in the online demo videos, which can be found #link("https://youtube.com/playlist?list=PLaz61XuoBNYVcQqHMAAXQNf8fz5IAMahe&si=HNrKY9YzqDFadATN")[here]#footnote[Full link: #link("https://youtube.com/playlist?list=PLaz61XuoBNYVcQqHMAAXQNf8fz5IAMahe&si=HNrKY9YzqDFadATN")]<fulllink>.
The example we highlight later in @mult:usecase, requires on average snapshot every 37 instructions.
This reduces overhead sufficiently to have a responsive debugging experience for users.
Additionally, the I/O operations by comparison typically take much longer to execute, a single action easily taking several seconds.

//An initial analysis of our own example programs, showed that on average there were 16 instructions between each primitive call, which would still result in notable overhead.
//However, we believe that 16 instructions, in practice, is an extreme lower bound since our example programs are made to highlight the reversible primitives of MIO, and perform very little computation and have very simple logic.
//Subsequently, we expect that for more complex programs the checkpointing will take snapshots far less frequently, resulting in much lower overhead.

#figure(image("figures/reexecution.svg", width: 90%),
    caption: [Plot showing the average time to step back as the number of instructions requiring re-execution increases in increments of one thousand. Averages are calculated over 10 runs of the same program.],
)<fig:stepping-back-performance>

=== Backwards execution

The graphs in @fig:snapshotting-performance only show part of the picture, where the less snapshots are taken, the better the performance.
Unfortunately, there is no such thing as a free lunch, and while only taking one snapshot at the start of the program and never again, would result in the lowest possible overhead for forwards execution, this is not the case for backwards execution.
In that case stepping back would always have to re-execute the entire program.
Clearly, the further apart the snapshots, the longer it will take to step back.
To illustrate this trade-off, we examined the impact of the number of re-executed instructions on stepping back speed.

@fig:stepping-back-performance shows the average time it takes to step back as the number of instructions requiring re-execution increases in increments of one thousand.
The averages are calculated over 10 runs of the same program used in the previous section.
When executing only a handful of instructions, the time to step back is dominated by the communication latency between the microcontroller and the debugger frontend.
On average, this results in a minimal time of 468ms to step back.
Between one thousand and 30 thousand re-executed instructions, the time to step back increases linearly by roughly 11ms per a thousand instructions.

Our analysis of the checkpoint strategy's impact on stepping back shows that the overhead is minimal.
The prototype is able to re-execute 30 thousand non-I/O instructions in around one second.
Compared to the overhead of checkpointing on forwards execution (see @fig:snapshotting-performance), we can safely conclude that in practice the overhead on backwards execution is negligible. //% introduced by reducing the number of snapshots 
This is further evidenced in our #link("https://youtube.com/playlist?list=PLaz61XuoBNYVcQqHMAAXQNf8fz5IAMahe&si=HNrKY9YzqDFadATN")[demo videos], where developers mostly have to wait for physical I/O actions to complete, and stepping back is otherwise instantaneous.

=== Use case: Lego Mindstorms color dial<mult:usecase>

To illustrate the practical potential of MIO and its new debugger approach, we present a simple reversible robot application using Lego Mindstorms components.
However, not just microcontroller applications may benefit from our novel approach, there are many application domains where output is entirely in the form of digital graphics, which are more easily reversible---such as video games, simulations, etc.
Nevertheless, to highlight the potential of the approach we demonstrate the MIO debugger using small physical robots and other microcontroller applications, as this is a more challenging environment for multiverse debugging.
Using the digital input and motor primitives described in @mult:implementation, we developed a color dial, as a simplified application.
We developed this example alongside a few others to further demonstrate the usability of the MIO debugger#note[Code for all examples can be found #link("https://github.com/TOPLLab/WARDuino-demos/tree/main/multiverse")[online].], and have created demo videos for a few of the examples, which can be found #link("https://youtube.com/playlist?list=PLaz61XuoBNYVcQqHMAAXQNf8fz5IAMahe&si=HNrKY9YzqDFadATN")[online]#footnote(<fulllink>).

//%\paragraph{Binary LED counter} A binary counter that shows the binary representation of numbers using LEDs, showing each number one by one. When stepping back, the counter will show the previous number again, by turning on and off the necessary LEDs.
//%\paragraph{Smart curtain} A smart curtain that opens and closes depending on the lighting conditions. If the curtain opens the developer can step back to make the curtain close again, allowing them to explore a different program state with ease.
//%\paragraph{Clock} A clock with an hour and minute hand. When stepping back the clock will move the hands back to their original position, making time on the clock go backwards.
//%\paragraph{Maze solving robot} A robot that solves a maze by always driving to the left if it can, until it finds the exit. When stepping back the robot would drive backwards through the maze following the same path it took to get to the current location.

//%Of course we did not have the time to build and test all possible applications, so we decided to pick one simple example out of the many possible applications that illustrates the usability of MIO for robotics applications.

//\lstdefinelanguage{AssemblyScript}{
//sensitive,
//morecomment=[l]{//},
//morekeywords={import, export, let, const, while, class, function, as, from, enum},
//morekeywords=[2]{true, void, u32, i32, boolean, Pin, Color, string, Options},
//morekeywords=[3]{@external},
//morestring=[b]{"},
//morestring=[b]` % Interpolation strings.
//}

The color dial application works as follows; the robot has a color sensor that can detect the color of objects.
Depending on the color seen by the sensor, a single motor will move the needle on the dial to the location indicating the color seen by the sensor.
We built the dial using LEGO Mindstorms components~@ferreira24:open as shown on the left of @fig.robot.
//The example is written in AssemblyScript using the reversible primitives introduced by the MIO debugger to the WARDuino virtual machine.
The right-hand side of @fig.robot shows the infinite loop that controls the robot, written in AssemblyScript.
In this loop, the robot will continually read sensor values from the color sensor. While doing so it will move the needle of the dial to the correct position indicating the current color seen by the sensor.
The needle is only moved if the color sensor sees a value different from what the dial is currently indicating.
The relative amount that the needle needs to move is calculated by taking the difference between the current color the needle is pointing at and the new color.

#figure(
  grid(columns: (1.0fr, 1.3fr),
    rect(inset: 0mm, image(height: 6cm, "./figures/color_gauge.jpg")),
snippet("app.robot",
    columns: 2,
    headless: true,
      [],
    (```ts
enum Color { none = 0, red = 1, green = 2,
             blue = 3, yellow = 4 }

const sensor = colorSensor(Pin.IO2);
let current: Color = Color.none;
while (true) {
  let next: Color = sensor.read();
  if (next != current) {
    // turn the needle if the color changed
    rotate(Pin.IO1,
      (next - current) * angle, speed);
  }
  current = next;
}
```,))), caption: [Left: Lego color dial that recognizes the color of objects. Right: The main loop controlling the behavior of the color dial. The dial is controlled by a single motor connected to pin IO1, and the color sensor is connected to pin IO2.])<fig.robot>

#let target = "app.robot.0:8"

The program for the color dial uses the reversible primitive #emph[rotate], used as an example in @mult:implementation, to rotate the needle of the dial.
By using only reversible output primitives, the program written for this robot automatically becomes reversible. //%without any additional input from the programmer.
This means that while debugging the application, the color the needle is pointing towards will always correspond to variable #emph[current] in the program.
Concretely, if the debugger steps back through the program from the end of a loop iteration to #line(target), it will move the needle back to the previous color without having to read a new sensor value.
This makes it easy to test certain state transitions where the needle is pointing at one particular color and now has to move to a different color.

Aside from using time travel debugging which keeps external state in mind, users of our debugger are also able to leverage multiverse debugging capabilities to deal with the non-deterministic nature of this color sensor.
This allows them to easily simulate various sensor values, and explore the different paths the robot can take without needing to use any real, correctly-colored objects.
This example touches on a few common aspects of robotics applications, such as processing non-deterministic input, controlling motors and making decisions based on sensor values.
Using the I/O primitives supported by MIO, various other applications could be build; such as a binary LED counter, a smart curtain, an analogue clock, a maze solving robot, and so on.

//% Talk about how the multiverse debugger can be used to explore the different non-deterministic paths

//% This rotate primitive is great for rigid movements such as on a robot arm but it is not ideal for robots that have to smoothly drive around such as the classical line follower robot. This is due to a limitation of reversible primitives, they have to be atomic and deterministic operations. This requires each movement of the robot to be an atomic operation where the robot starts driving and comes to a complete stop. This makes a line following robot rather slow because it cannot read sensor values and drive around at the same time.

//% Maybe mention the problems with the line follower that are caused by the restrictions on ths primitive.
//% Specifically the fact that it it's non-deterministic

== Related work<mult:related>

Our work builds directly on WebAssembly~@haas17:bringing@rossberg19:webassembly@rossberg23:webassembly and WARDuino~@lauwaerts24:warduino, as we have discussed in @mult:webassembly and @mult:implementation.
In this section, we present an overview of further related work. //%previous work on reversible debuggers and multiverse debuggers, as well as other related works that have inspired our approach.

#heading(numbering: none, level: 4, "Multiverse debuggers")

Multiverse debugging has emerged as a powerful technique to debug non-deterministic program behavior, by allowing programmers to explore multiple execution paths simultaneously.
It was proposed by #cite(form: "prose", <torres19:multiverse>) to debug parallel actor-based programs, with a prototype called Voyager~@gurdeep19:multiverse, that worked directly on the operational semantics of the language defined in PLT Redex~@felleisen09:semantics.
Several works have expanded on multiverse debugging; #cite(form: "prose", <pasquier22:practical>) introduced user-defined reduction rules to shrink the state space that must be explored during multiverse-wide breakpoint lookup, and #cite(form: "prose", <pasquier23:temporal>) introduced temporal breakpoints that allow users to reason about the future execution of a program using linear temporal logic.
In contrast to MIO, existing multiverse debuggers only work on a model of the program execution, and do not consider I/O operations, or their effects on the external environment.

#heading(numbering: none, level: 4, "Multiverse Analysis")

The idea of exploring the multiverse of possibilities, is more widely known as multiverse analysis.
Within statistical analysis, it is a method that considers all possible combinations of datasets and analysis simultaneously~@steegen16:increasing.
Within software development, there are several frameworks for exploratory programming~@kery17:exploring, which allow developers to interact with the multiverse of source code versions~@steinert12:coexist.
In exploratory programming, programmers actively explore the behavior of a program by experimenting with different code.
This approach has led to #emph[programming notebooks]~@perez07:ipython@kery18:story, and dedicated #emph[explore-first IDEs] with advanced version control~@steinert12:coexist@kery17:exploring.
Explore-first editors, such as the original by #cite(form: "prose", <steinert12:coexist>), allows programmers to explore different versions of their code in parallel.
While explore-first editors consider the variations in the program code itself, multiverse debuggers focus on variations of program execution caused by non-deterministic behavior for a single code base.
Combining these two techniques could lead to a powerful development environment, and represents interesting future work.

#heading(numbering: none, level: 4, "Exploring execution trees")

Many automatic verification and other analysis tools also explore the execution tree of a program, such as software #emph[model checkers]~@godefroid97:model@jhala09:software, #emph[symbolic execution]~@king76:symbolic@cadar11:symbolic@baldoni18:survey, and #emph[concolic execution]~@godefroid05:dart@sen06:automated@marques22:concolic.
These techniques are great at automatically detecting program faults, however, they rely on a precise description of the problem or program specification, often in the form of a formal model.
This is in stark contrast with debuggers, which are tools to help developers find mistakes for which no precise formula exists, and for which the causes are often unknown.
Despite the major differences, static analysis techniques could greatly help improve debuggers by providing the developers with more information.
For multiverse debugging the techniques could help guide developers through large and complicated execution trees.
Additionally, the techniques for handling the state explosion problem~@valmari98:state@kurshan98:static@kahlon09:monotonic developed for these analysis tools, can help reduce the number of redundant execution paths in multiverse debugging.

#heading(numbering: none, level: 4, "Reversible debuggers")

Reversible debugging, also called back-in-time debugging, has existed for more than fifty years~@balzer69:exdams, and has been implemented with various strategies~@engblom12:review.
#emph[Record-replay debuggers]~@agrawal91:execution-backtracking@feldman88:igor@ronsse99:recplay@boothe00:efficient@burg13:interactive@ocallahan17:engineering allow offline debugging with a checkpoint-based trace.
In spite of all the different implementation strategies, few reversible debuggers also reverse output effects, with a few notable exceptions.
The more recent RR framework~@ocallahan17:engineering is a culmination of many years of research, and is one of the most advanced record-replay debuggers to date.
While replaying it does not reverse I/O operations, in fact, the operations are not performed at all.
For example, file descriptors are not opened during replay, but instead the external effects are recorded and replayed within the debugger.
One of the earliest works, the Igor debugger~@feldman88:igor, featured so-called #emph[prestart routines], which could perform certain actions after stepping back, such as updating the screen with the current frame buffer.
This is one of the first attempts at dealing with external state, however, the solution was purely ad-hoc, and required significant user intervention; for instance, supplying the name, mode, and file pointer for each file currently opened during execution.
Additionally, dealing with I/O in a structured way through the prestart routines was still too costly at the time.
There is also no proof of soundness, or any characterization of which prestart routines lead to correct debugging behavior.
#emph[Omniscient debuggers]~@lewis03:debugging@pothier07:scalable, on the other hand record the entire execution of a program, allowing free offline exploration of the entire history, and enabling advanced queries on causal relationships in the execution @pothier09:back.
A third approach is based on #emph[reversible programming languages]~@giachino14:causal-consistent-reversible-debugging@lanese18:cauder@lanese18:from.
While not applicable in all scenarios, since it requires a fully reversible language, this approach can enable more advanced features, such as reversing only parts of a concurrent process, while still remaining consistent with the forwards execution~@lanese18:from.
The reversible LISP debugger by #cite(form: "prose", <lieberman97:zstep>) not only redraws the graphical output, but also links graphics with their responsible source code.
Reversible debuggers for the #emph[graphical programming language] Scratch~@maloney10:scratch-programming-language, namely Blink~@strijbol24:blink and NuzzleBug~@deiner24:nuzzlebug, also redraw the graphical output when stepping back.
However, in all these debuggers, the output effects are internal to the system.
For the Scratch debuggers, the visual output is actually part of the execution model~@maloney10:scratch-programming-language.

#heading(numbering: none, level: 4, "Reversible programming languages")

The concept of reversible computation has a longstanding history in computer science~@zelkowitz73:reversible@bennett88:notes@mezzina20:software, with the most notable models for reversibility being reversible Turing machines~@axelsen16:on, and reversible circuits~@saeedi13:synthesis.
Furthermore, the design of reversible languages has evolved into its own field of study~@gluck23:reversible, with languages for most programming paradigms, such as the imperative, and first reversible language, Janus~@lutz86:janus@yokoyama08:principles@lami24:small-step-semantics, several functional languages~@yokoyama12:towards@matsuda20:sparcl, object-oriented languages~@schultz16:elements@haulund17:implementing@hay-schmidt21:towards, monadic computation~@heunen15:reversible, and languages for concurrent systems~@danos04:reversible@schordan16:automatic@hoey18:reversing.
Several works have investigated how reversible languages can help reversible debuggers~@chen01:reversible@engblom12:review@lanese18:cauder, however, full computational reversibility is not necessary for back-in-time debugging~@engblom12:review.
//A lot of research has gone into reversible computing for concurrent systems, leading to 
Moreover, these reversible languages do not consider output effects on the external world, with a few notable exceptions in the space of proprietary languages for industrial robots.

#heading(numbering: none, level: 4, "Reverse execution of industrial robotics")

While numerous examples can be imagined where actions affecting the environment cannot be easily reversed, there are sufficient scenario's where this is possible, for reverse execution to be widely used in industry.
The reversible language by #cite(form: "prose", <schultz20:reversible>) is particularly interesting.
The work proposes a system for error handling in robotics applications through reverse execution, and identifies two types of reversibility; direct and indirect.
Through our compensating actions, MIO is able to handle both directly and indirectly reversible actions.
#cite(form: "prose", <laursen18:modelling>) propose a reversible domain-specific language for robotic assembly programs, SCP-RASQ. While we do not focus on a single specific application domain, this work does show how reversible output primitives are possible for advanced robotics applications.
SCP-RASQ uses a similar system of user-defined compensating actions, to reverse indirectly reversible operations.
Using these kinds of languages, we believe that the MIO debugger could be extended to support more complex output primitives, which could control industrial robots.

#heading(numbering: none, level: 4, "Reversibility")

The concept of reversibility is well understood on a theoretical level, for both sequential context~@leeman86:formal, and concurrent systems.
The latter is much more complex, and has lead to two major definitions; causal-consistent reversibility~@danos04:reversible@lanese14:causal-consistent-reversibility, and time reversibility~@weiss75:time-reversibility@kelly81:reversibility.
Causal-consistent reversibility is the idea that an action can only be reversed after all subsequent dependent actions have been reversed~@lanese14:causal-consistent-reversibility.
This ensures that all consequences of an action have been undone before reversing, and the system always returns to a past consistent state.
On the other hand, time reversibility only considers the stochastic behavior when time is reversed~@weiss75:time-reversibility@kelly81:reversibility@bernardo23:causal.
However, it has recently been shown that causal-consistency implies time reversibility~@bernardo23:causal.
Our debugger works on a single-threaded language, where the non-determinism is introduced by the input operations.
In our work, the undo actions are causally consistent in the single-threaded world.
We believe that we can extend MIO to support concurrent languages, and that the existing literature~@lanese18:cauder@giachino14:causal-consistent-reversible-debugging can help to ensure it stays causally consistent.

#heading(numbering: none, level: 4, "Remote debugging on microcontrollers")

We discussed the related work on remote debuggers for embedded devices thoroughly in @remote:related-work.
The MIO multiverse debugger is built on top of the same architeecture as _stub remote debuggers_.

#heading(numbering: none, level: 4, "Environment modeling")

There are many environment interactions that can influence the possible input values and thereby the possible execution paths of a program.
We have elided these interactions from the formal model and assume that I/O operations are independent, while our prototype does support defining simple #emph[predictable dependencies] between I/O operations.
Modeling the interactions between I/O operations is also hugely important for testing, and #emph[environment modeling] has therefore been widely studied in this area~@blackburn98:using.
Environment models are often used for automatic test generation~@dalal99:model-based@auguston05:environment for a certain specification, and have also been applied to real-time embedded software~@iqbal15:environment.
// todo more examples + can be used for future work

== Conclusion<mult:conclusion>

While existing multiverse debuggers have shown promise in abstract settings, they struggled to adapt to concrete programming languages and I/O operations. 
In this article, we address these limitations by presenting a novel approach that seamlessly integrates multiverse debugging with a full-fledged WebAssembly virtual machine. 
This is the first implementation that enables multiverse debugging for microcontrollers.
Our approach improves current multiverse debuggers by being able to provide multiverse debugging in the face of a set of well-defined I/O actions. 
We have formalized our approach and give a soundness and completeness proofs.

We have implemented our approach and have given various examples showcasing how our approach can deal with a wide range of specialized I/O actions, ranging from non-deterministic input sensors, to I/O pins and even steering motors.
Our sparse snapshotting approach delivers reasonable performance even on a restricted microcontroller platform.
While the MIO debugger is already sufficiently fast, it is currently implemented as a remote debugger.
We can likely speed-up performance by adopting stateful out-of-place debugging we introduced in the previous chapter.

Our initial implementation provides a substantial benefit over existing approaches, but we believe there are further opportunities to relax the constraints on I/O actions further. For example, our current implementation only supports simple dependencies between I/O actions, but we believe this could be relaxed further by introducing an explicit rule language so that programmers can define more complex dependencies between the I/O actions.

