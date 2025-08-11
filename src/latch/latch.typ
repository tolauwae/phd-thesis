#import "@preview/lovelace:0.3.0": pseudocode, with-line-label, pseudocode-list, line-label

#import "../../lib/util.typ": circled, line, snippet, algorithm, lineWidth, illustration
#import "../../lib/class.typ": note
#import "../../lib/fonts.typ": small

#let latch = [#emph("Latch")]
#let lines = (dependencies: "lst.dependent.0:4",
  mqtt: (callback: "lst.mqtt.0:1", init: "lst.mqtt.0:7", subscribe: "lst.mqtt.0:8"),
  dump: (expect: "lst.dump.0:4"),
  listen: (pureaction: "lst.listen.0:1", signature: "lst.listen.0:5", assertable: "lst.listen.0:8"),
  suite: (testee: "lst.suite.0:2", test: "lst.suite.0:4", run: "lst.suite.0:5"),
  action: (simple: "lst.action.0:3", publish: "lst.action.0:5"),
  unit: (check: "lst.unit-test.0:7", invoke: "lst.unit-test.0:6"))

Debuggers are only useful when you know you have a bug.
There are naturally many ways to discover bugs in your software, however, the single most effective and widely used approach is unsurprisingly _testing_.
Modern software uses continuous integration and regression testing to detect bugs as early as possible in the development cycle.

Unfortunately, the same reasons that cause debugging techniques to lag behind for embedded devices, likewise make modern testing techniques hard to apply on constrained systems. In this chapter, we present a novel testing technique called _managed testing_, and a prototype implementation Latch, which aim to enable large-scale testing of embedded software directly on the constrained devices as part of continuous integration. The framework was also used to test the previously discussed debugger prototypes.

== Introduction

Software testing for constrained devices, still lags behind standard best practices in testing.
Widespread techniques such as automated regression testing and continuous integration are much less commonly adopted in projects that involve constrained hardware.
This is mainly due to the heavy reliance on physical testing by Internet of Things (IoT) developers.
A 2021 survey on IoT development found that 95\% of the developers rely on manual (physical) testing @makhshari21:iot-bugs.
Testing on the physical hardware poses three major challenges, which hinder automation and the adoption of modern testing techniques.
First, the #emph[memory constraints] imposed by the small memory capacity of these devices makes it difficult to run large test suites.
Second, the #emph[processing constraints] of the hardware causes tests to execute slowly, preventing developers from receiving timely feedback.
Third, #emph[timeouts and flaky tests] pose a final challenge.
When executing tests on constrained hardware it is not possible to know when a test has failed or is simply taking too long.

To circumvent the limitations of constrained hardware, simulators are sometimes used for testing IoT systems @bures20:interoperability.
Their usage makes adopting automated testing and other common testing practices much easier.
Unfortunately, simulators can never fully capture all aspects of real hardware @roska90:limitations @khan11:limitations @espressif-systems23:esp-idf.
Therefore, to fully test their applications, IoT developers have no other option than to test on the real devices.
This is the primary reason why developers still prefer physical testing.
Another reason is the lack of expressiveness when specifying tests in automated testing frameworks.
Testing frameworks with simulators almost exclusively focus on unit testing, and hence provide no good alternative to end-to-end physical testing performed by developers manually @vandervoord15:unity.

In this chapter, we argue that programmers should not be limited by either the constraints of the hardware, or a simulator imposed by the testing framework.
Therefore, our goal is to design and implement a testing framework for automatically running large-scale versatile tests on constrained systems.
This has lead to the development of the #latch testing framework (Large-scale Automated Testing on Constrained Hardware).
#latch enables programmers to script and run tests on a workstation, which are executed on the constrained device.
This is made possible by a novel testing approach, we call #emph[managed testing].
In this unique testing approach, the test suite is split into small sequential steps, which are executed by a testee device under the directions of a controlling tester device.
The workstation functions as the tester which maintains full control over the test suite.
Only the program under test---not the entire test suite---will be sent to the constrained device, the testee.
The tester will use instrumentation to manage the testee and instruct it to perform the tests step-by-step.
This means the constrained testee is not required to have any knowledge of the test suite being executed.
This is quite different from traditional remote testing, where the entire test suite is sent to the remote device.
The instrumentation of the testee is powered by debugging-like operations, which allow for traditional whitebox unit testing,
but also enables the developer to write debugging-like scripts
to construct more elaborate testing scenarios
that closely mimic manual testing on hardware.

The research question we seek to answer in this chapter, is whether the managed testing approach, i.e. splitting tests into sequential steps, is sufficient for executing large-scale tests on microcontrollers.
To answer this question, we will show how managed testing allows #latch to overcome all three major challenges of testing on constrained devices.
The approach can be summarized as follows.
In #latch test suites are split up into smaller test instructions that are sent incrementally to the managed testee, thereby freeing the test suites from the #emph[memory constraints] of the hardware.
This is crucial in enabling large-scale test suites on microcontrollers, such as the large unit testing suite containing 10,213 tests we use to evaluate our approach.
To overcome the #emph[processing constraints], #latch can skip tests that depend on previously failing tests resulting in a faster feedback loop.
Finally, #latch handles #emph[timeouts] automatically, and includes an analysis mode which reports on the #emph[flakiness of tests].

=== Contributions

    - We define a test specification language for writing large tests suite for constrained devices.
    - We develop the #latch framework, that implements the test specification language as an embedded domain-specific language (EDSL).
    - We present a novel testing methodology based on debugging methods, that allows common manual testing of code on hardware to be automated.
    - We illustrate how #latch can be used to address testing scenarios from all three layers of the testing pyramid @cohn09:succeeding.
    - We evaluate #latch by using it to run 10,213 unit tests on an ESP32 microcontroller.

The rest of the chapter starts with a discussion of the challenges of testing on constrained device in @sec:challenges.
In @sec:details we give a first introduction to the #latch test specification language through a basic example, and use the example to give an overview of the #latch framework.
We discuss the details of the language in @sec:language, and focus on how tests are written and executed by the framework.
For each aspect of the test specification language we discuss how it helps #latch to address the challenges outlined previously.
We conclude the section by briefly touching on the prototype implementation.
@sec:usecases further illustrates how #latch can be used to handle different testing scenarios, and can help testers implement a range of testing methodologies.
We discuss three scenarios, classic large-scale unit testing, integration testing, and automating physical end-to-end testing using the debug-like operations provided by #latch.
In @sec:performance we evaluate the runtime performance of #latch based on a variety of test suites, and present empirical evidence that managed testing enables large-scale automatic testing on constrained hardware.
In @sec:related we discuss the related works, before concluding in @sec:conclusion.

== Challenges of Testing on Constrained Devices<sec:challenges>

This section outlines the challenges preventing large-scale testing on constrained hardware.

=== Memory Constraints

In this chapter, we focus on the ESP32 microcontroller family#note[ESP32 devices can have different amounts of memory,
but the order of magnitude is the same.] having about 400 KiB SRAM and 384 KiB ROM, typically operating at a clock frequency around 160-240 MHz.
Due to these hardware limitations, programs cannot be arbitrarily large as the program memory is quite small and they execute slower than workstations.
For companies producing IoT devices it is often desirable to make use of the cheapest and most minimal hardware possible that can handle the task at hand.
This means that when executing on the hardware, there are often very few resources to spare, which limits the ability to test the applications on the device.

When test suites become large, executing these test suites on the hardware is often not possible because the compiled binary is too big to fit in the program memory of the microcontroller.
The only option then is to split the test suite into smaller parts which can fit on the device.
Current testing frameworks, however, do not provide automated support for splitting large test suites and executing them incrementally on the hardware.
Programmers who want to execute large test suites thus have to manually partition the test suite, execute the test on the hardware, read out the results and process the dump of the individual parts.

Finally, even when the testing framework supports partitioning of the test suite reflashing the hardware for every partition is quite time-consuming.
To change the program executing on the hardware the programmer needs to flash the microcontroller, i.e. write the program in the ROM partition of the microcontroller.
Depending on the microcontroller, synchronization and flashing of a new program can take several seconds making it undesirable to flash the microcontroller often.

=== Processing Constraints

When relying on regression testing, the programmer wants a tight feedback loop.
Ideally, the entire test suite is run after each change, but this requires feedback to be reported quickly.
However, by testing on constrained devices, executing the test suite can take a lot of time, slowing down the software development cycle significantly.
To provide feedback as early as possible, the framework should catch failures early.
This can take many forms, but in essence a failure of any kind during a test should be visible to the developer as soon as possible.
Additionally, to avoid spending time on tests that cannot succeed,
the framework should run as few of these tests as possible.

Finally, when multiple hardware testbeds are available it should be easy for the developer to run tests in parallel to speed up testing.
The same facilities for scheduling and parallelization options available for unconstrained devices, should be integrated into testing frameworks for constrained devices.

=== Timeouts and Flaky Tests

Due to the limited memory and processing power of constrained devices, large test suites need to be split up in smaller chunks.
Moreover, the results of the test need to be communicated with a test machine and combined.
Unfortunately, this approach implies
that test engineers suddenly need to take into account many of the problems associated with distributed computing.

First, when the test machine is waiting for a response, it cannot reliably distinguish between a failure or a delayed response.
Many other testing frameworks need to deal with this problem, especially JavaScript frameworks @flanagan20:javascript where asynchronous code is prevalent @fard17:javascript.
These frameworks time out tests that take too long.
Unfortunately, the fact that a test timed out does not provide much information for developers, especially when a test includes multiple asynchronous steps.

Second, the non-determinism of the asynchronous communication also contributes to an inherent problem of testing: flaky tests @lam19:root.
These are tests that can pass or fail for the same version of the code.
Unfortunately, on constrained hardware, many tests have the potential to become flaky due to the inherent non-determinism of these systems.
For example, when testing communication with a remote server small changes in the communication timing with the server could lead to different behavior.

== Managed Testing with #latch by Example<sec:details>

To overcome the outlined challenges, #latch uses a unique testing approach that consists of declarative test specification language to describe tests, and a novel test framework architecture to run tests.
We refer to our new approach as #emph[managed testing].
In managed testing, the testing framework runs on a local machine and delegates tests step-by-step to one or more external platforms, which are running the software under test.
To facilitate this approach, tests must be easily divisible into sequential steps.
That is why #emph[managed testing] specifies tests in a declarative test specification language, where tests are described as scenarios of incremental steps.
In this section we give a first overview of how managed testing in #latch works through an example, before going into further detail in @sec:language.
The example is chosen as a small primer on how programmers can write traditional unit tests with #latch's test specification language.

=== The Example

We define a unit test that verifies the correctness of a function for 32-bit floating point multiplication, shown in @lst.multiplication.
All example programs are written in AssemblyScript @the-assemblyscript-project23:assemblyscript, one of the languages supported by #latch's current microcontroller platform.

#snippet("lst.multiplication",
    columns: 1,
    [A $mono("mul")$ function that multiplies its two arguments, written in AssemblyScript.],
    (```ts
export function mul(x: f32, y: f32): f32 {
    return x * y;
}
```,))

@lst.unit-test shows a simple test in #latch containing one unit test for the target program in @lst.multiplication.
#latch's declarative test specification language is implemented as an embedded domain specific language (EDSL) in TypeScript @microsoft23:typescript.
Test scenarios are presented in #latch as TypeScript objects that have a title, the path to the program under test, and a list of steps.
These steps make up the test scenario, and will be performed sequentially.
Each step performs a single instruction, and can perform several checks over the result of that instruction.

The example performs only a single instruction, it requests that the #emph[mul] function is invoked with the arguments 6 and 7 (see #line(lines.unit.invoke)).
These arguments are first passed to the #emph[WASM.f32] function, to indicate the expected type in #emph[AssemblyScript].
On #line(lines.unit.check), the example specifies that the function returns the number 42.
Usually, the instruction and expectations for a step are described as objects, but #latch provides a handful of functions to construct these objects for common patterns---such as #emph[invoke] and #emph[returns].
This makes test scenarios less verbose, and quicker to write.
We go into further detail on the structure of the #emph[instruction] and #emph[expectation] objects in @sec:language.

#snippet("lst.unit-test",
    columns: 1,
    [A #latch scenario defining a unit test for the $mono("mul")$ function.],
    (```ts
const multiplicationTest: Test = {
    title: "example test",
    program: "multiplication.ts",
    steps: [{
        title: "mul(6,7) = 42",
        instruction: invoke("mul", [WASM.f32(6), WASM.f32(7)]),
        expect: returns(WASM.f32(42))
    }]
};
```,))

Similar to other testing frameworks, #latch allows test scenarios to be grouped into test suites.
Crucially, the test suites in #latch have their own set of testee devices, on which they will be executed.
When writing a new test suite in #latch, programmers need to add at least one testee to the suite.
Such testees can range over a wide variety of microcontrollers, as well as local simulator processes.
Each platform may differ in how software is flashed, or communication initialized and performed.
These platform specific concerns are captured by a single TypeScript class, $mono("Testee")$.
Each connection with a constrained device is represented by an object of such a class.
In @lst.suite for instance, we use the Arduino platform to connect to an ESP32 over a USB port, as shown on #line(lines.suite.testee).
Users can add their own platforms by defining new subclasses of the $mono("Testee")$ class, which can handle the specific communication requirements of the new platform.

Aside from testees, a test suite also requires test scenarios to execute.
The example multiplication test is added to the test suite on #line(lines.suite.test), before the suite is given to #latch to be run on #line(lines.suite.run).

#snippet("lst.suite",
    columns: 1,
    [#latch setup code to run the $mono("multiplicationTest")$ on two ESP32 devices.],
    (```ts
const suite = latch.suite("Example test suite");
suite.testee("wrover A", new ArduinoSpec("/dev/ttyUSB0", "esp32:esp32:esp32wrover"), 5000)
     .testee("wrover B", new ArduinoSpec("/dev/ttyUSB1", "esp32:esp32:esp32wrover"))
     .test(multiplicationTest);
latch.run([suite]);
```,))

@lst.suite shows how a test suite is built in #latch through a fluent interface @xie17:principles, meaning the methods for constructing a test suite can be chained together.
Each test suite in latch is entirely separate from the rest, and therefore contains only its own tests, and platforms to run those tests on.
In the example, two ESP32 devices are configured for the test suite.
This means that when the test suite is started with the _run_ function on #line(lines.suite.run), the framework will execute all scenarios in the suite on all configured platforms.
Alternatively, the user can configure #latch to not execute duplicate runs, but instead to split the tests into chunks that are performed in parallel on different devices.
In that case, each test is only run once and the execution time of the whole test suite should be dramatically improved due to the parallelization.

=== Running the Example on the #latch Architecture<subsec:overview>

To run the above testing scenario on a remote constrained device, the test is loaded into #latch on the local unconstrained device, the #emph[tester].
During testing, the #emph[tester] manages one ore more #emph[testees] (constrained devices) to execute tests step-by-step.
@fig:overview gives an overview of all steps and components involved during testing in the #latch framework.
The left-hand side shows the tester, which runs the #latch #emph[interpreter] and #emph[test execution platform].
The interpreter component is responsible for interpreting the test suites, which are written in the #emph[test specification language], while the test execution platform sends each instruction in a test step-by-step to the testee device over the available communication medium.
The test execution platform also parses the result, and handles all other aspects of communication with the testee device.

#figure(image(width: 100%, "figures/overview.svg"), // "figures/overview.pdf"), 
  caption: [Schematic overview of the interaction between components in #latch during a test.])<fig:overview>


We will go over the steps shown in @fig:overview in the order they are executed by #latch.
Running a test suite is initiated by the interpreter, which takes the test suite specification #circled[1], and schedules the #emph[scenarios] #circled[2].
Since the example test suite in @lst.suite only contains a single test scenario, the multiplication test, with a single step---the scheduling is not relevant in this case.
In real test suites, the order in which tests are run is important, it can help detect failing tests early, or minimize expensive setup steps.
When the interpreter selects a test to be executed, it will instruct the test execution platform #circled[3] to first upload the #emph[software under test], and subsequently sends the instructions of the scenario to the #emph[test instrumentation platform] #circled[4].
In the case of our example, #latch compiles the #emph[multiplication.ts] file and uploads it to the ESP32 device that is connected to the USB port.
Once this step is completed, #latch sends the invoke instruction to the testee, which will execute the #emph[mul] function with the supplied arguments.

Aside from forwarding instructions to the test instrumentation platform, the tester can also perform custom actions to control the #emph[environment] #circled[5].
For instance, these actions can control hardware peripherals, such as sensors and buttons, that interact with the constrained testee #circled[6] during the test.

@lst.action shows how a step might send an MQTT message to a server as an example of an action that acts on the environment.
Such a step, could be useful when testing an IoT application that relies on MQTT messages.
The microcontroller can connect to an actual testing server, and via custom actions #latch can test if the device responds correctly.

#snippet("lst.action",
    columns: 1,
    [An example #latch step, which performs a custom action that sends an MQTT message to a server.],
    (```ts
const sendMQTT: Step = {
    title: "Send MQTT message",
    instruction: simpleAction((): void => {
        let client: mqtt.MqttClient = mqtt.connect("mqtt://test.mosquitto.org");
        client.publish("parrot", "This is an ex-parrot!");
    })
};
```,))

In contrast with @lst.unit-test, this example constructs the instruction object explicitly, rather than calling a function such as #emph[invoke].
There are two types of instructions, they can be either a #emph[request] to the test instrumentation platform, such as the invoking of a function, or a custom #emph[action].
In this example we construct a simple action that takes no arguments and returns nothing.
Actions allow tests to execute TypeScript functions as steps in the test scenario, in this case the function simply publishes a test message to the MQTT server (#line(lines.action.publish)).
We go into further detail on the types of actions and requests in @sec:language.

As tests are performed, the software under test is controlled by the test instrumentation platform in accordance with the #emph[request] instructions send by the test execution platform #circled[7].
In other words, the test instrumentation platform will receive the command from the tester to execute the #emph[mul] function, and make the software under test invoke it.
The instrumentation of the software under tests, allows the test instrumentation platform to return any generated output to the test execution platform #circled[8].
Whenever the tester sends an instruction to the testee, #latch will wait until the testee returns a result for the instruction.
When working with constrained devices, communication channels may be slow or fragment messages.
#latch takes care of these aspects automatically.

As part of a step, the scenario description can specify a number of assertions over the returned results.
In the example, we require that the #emph[mul] function returns 42, as specified on #line(lines.unit.check) of @lst.unit-test.
Once the expected output is received by the tester, #latch checks all assertions against it.
These assertions are verified by the interpreter #circled[9], before the result of the step is shown in the #emph[user interface] as either passed, failed, or timed out #circled[10].
For example, after the test instrumentation platform returns the result of the #emph[mul] function, #latch will check if it indeed equals 42 and report the result.

A step can have three kinds of results; either it timed out, or all its assertions passed, or one of more assertions failed.
In other words, step is marked as failing when at least one assertion fails.
If no assertions were included in the step, #latch will not wait for output, and immediately report the action as passing.
When the testee fails to return a result after a preconfigured period, it is marked as timed out.
Similarly, a scenario is marked as failing when at least one step fails.
When a step fails, the test execution platform will---by default---continue the scenario without retrying the step.
This is useful when the steps in the scenario are independent of each other to gather more complete feedback.
Otherwise, developers can configure #latch to abort a scenario after the first failure.

The results of each step are reported while the test suite is executing.
When the entire suite has run, #latch will give an overview of all the results for both the steps and the test scenarios.
This overview includes, the number of passing/failing tests, the number of passing/failing steps, the number of steps that timed out, and the overall time it took to run the suite.
In addition, the developer can configure #latch to report on the flakiness of the test by executing the tests multiple times.
This way, #latch can compare the results of different runs to give developers more insight into the flakiness of their test suites.
As @fig:overview shows under the user interface component, the results in this case will be reported for each run separately.
Whenever the runs give different results, the scenario is marked as flaky and the failure rate is reported.

=== From Small Examples Towards Large-scale Test

The running example in this section illustrates #latch's basic testing features.
In particular, how #latch divides tests into small steps that are executed sequentially.
This means that the size of the test suite is no longer constrained by the memory size of the embedded device.
While the example here only includes a single step, one can easily imagine test cases that require many more steps.
Let us suppose we stay within the realm of unit testing a mathematical framework.
We can imagine a more complicated mathematical operation than multiplication that requires thorough testing, for instance a function #emph[eig] for calculating the eigenvalues of a matrix.
In this case the test scenario would include many steps, that each invokes the #emph[eig] function with a different matrix.
This is similar to the large-scale unit testing suite we will discuss in @sec:usecases, and those run as part of the evaluation in @sec:performance.

@sec:usecases discusses realistic examples for each layer of the testing pyramid; unit testing, integration testing, and end-to-end testing.
The examples will illustrate how using small steps powered by debugging-like operations, uniquely enables #latch to test remote debuggers and automate IoT scenarios and manual hardware tests.
For example, it becomes much easier to test whether a microcontroller successfully receives asynchronous messages from a remote server, and handles these message correctly.
The test can set breakpoints in the code that is expected to be executed when a message arrives.
Before sending the message, the test can pause the execution at the exact place in the program, it wants the message to be received.
The #latch instructions allows users to write these kinds of testing scenarios in a convenient way.
Moreover, the increased control over the program, makes the test scenarios much easier to repeat reliably under the same conditions.

== The #latch Test Specification Language<sec:language>

#latch tests are written in a declarative test specification language embedded in TypeScript.
This EDSL allows developers to specify what tests should be performed, while hiding the complexity of communicating with the constrained testing device.
Equally important are the debug-like commands provided by the language, which make it easier to automate hardware testing scenarios.
Latch tests can be viewed as scripted scenarios of sequential operations.
The programmer can specify what the result of executing an operation should look like, instead of manually testing whether the returned value is consistent with the expected result.
For more complex tests the programmer can write test-specific evaluation functions to check whether the program behaves as expected.

The test specification language consists of four major abstractions: a test, a testing step, test instructions, and assertions.
Each test includes a name, some start-up configuration and the testing steps which need to be executed during the actual test.
Each testing step specifies an instruction that needs to be executed.
There are two types of instructions, commands and actions.
The commands are debug-like operations that are send directly to the test instrumentation platform of the testee, such as invoking a method, pausing the program, etc.
Alternatively, there is support for user-specified instructions called actions.
These actions allow programmers to implement their own logical and physical interactions with the hardware or the environment.

The interface of a test, shown in @lst.syntax.scenario, consists of a title, the path to the program to load on the testee device, a set of initial breakpoints to halt execution, a list of dependent test, and a set of steps to be executed during the test.
Both the initial breakpoints and dependent tests are optional, as indicated by the question mark after their identifier.

#snippet("lst.syntax.scenario",
    columns: 1,
    [Interface for #latch tests. Each test has a title, indicates a program to be tested, and lists the steps to executed.],
    (```ts
interface Test {
  title: string;
  program: string;
  steps: Step[];
  dependencies?: Test[];
  initialBreakpoints?: Breakpoint[];
}
```,))

Testing steps all adhere to the #emph[Step] interface shown in @lst.syntax.step.
Each step should minimally have a title and specify which instruction to perform when executed.
A step only contains a single instruction, and all steps are executed synchronously.
As part of a step, the result of executing an instruction can be verified by means of assertions.

#snippet("lst.syntax.step",
    columns: 1,
    [A step has a name, a specific command or action it should perform, and a possibly list of assertions to check.],
    (```ts
interface Step {
    readonly title: string;
    readonly instruction: Command<any> | Action<any>;
    readonly expect?: Assertion[];
}
```,))

An instruction in #latch is either a command, or an action.
Both instruction types are annotated with their return type, this is the type of the object passed to each assertion of the step.
The list of assertions is optional, a step without any assertions will always succeed and immediately go to the next step.

=== Default Commands in #latch

The set of commands #latch supports is shown in @tab:instructions.
We divide the set of commands in intercession, meta, and introspection commands.
The intercession commands, allow #latch tests to intervene directly with the software under test.
With _invoke_ the programmer can call a function and wait for the result, as illustrated by the step in our multiplication example (@lst.unit-test).
This enables unit testing of specific functions, as is the popular approach adopted in most testing frameworks @doctest @junit.
With _set local_ the programmer can change a local variable, this is especially useful to test a program with local boundary conditions without having to rerun the program completely.

#figure([
  #set text(size: small) //, font: sans)
  #show table.cell.where(y: 0): set text(weight: "bold") //, font: sans)
/*align(center,*/ #table(columns: (auto, 60mm), align: horizon + left, stroke: none, //fill: (x, y) => if calc.odd(y) { silver },
  table.header("Category", "Commands"),
        table.hline(stroke: lineWidth),
     	"Intercession" , [invoke, set local, _upload module_],
     	"Meta"         , [pause,  set breakpoint, continue,
                          delete breakpoint, step, step over, _reset_],
        "Introspection", [core dump, dump callback mapping, dump locals]
)], caption: [The #latch commands. Internal commands are in italic.], kind: illustration.table, supplement: [Table])<tab:instructions>

The _reset_ and _upload module_ instructions are primarily for internal use in #latch, but are available in the test specification language.
The upload module instruction loads a binary onto the testee, replacing any current program.
The reset instruction restarts the current program.

The meta instructions allow the programmer to install a debugging scenario by setting breakpoints and running the program to a particular point in the execution.
These are especially useful for automating manual hardware tests, where different steps and events often need to happen in very specific orders.
By controlling the execution of the program, these kinds of scenarios can be replicated accurately each time.

Finally, the introspection commands allow the programmer to inspect the current state of the program.
Without these commands, #latch test would be limited to testing black boxes, since the software under test is executed on a different device.
Thanks to the introspection commands, #latch supports black box as well as white box tests.

The proposed set of commands are inspired by standard debugging instructions, and focus on enable standard unit testing, as well as automation of manual hardware tests.
Since the test specification language is embedded in TypeScript, the set of commands is easily extended by the user.
Other debugging instructions could similarly inspire new #latch commands, such as run until, setting of conditional breakpoints, exception breakpoints, or inspecting memory addresses.
Instructions tailored to asynchronous tests, such as awaiting an event, or waiting for a given time, would likewise be good additions.
A new command has to implement the interface shown in @lst.syntax.command.
A command is identified by the test instrumentation platform by its type, examples include pause, set breakpoint, and step.
These commands can optionally take a payload, such as a breakpoint address for example, and each command has its own parser to interpret the response of the test instrumentation platform.

#snippet("lst.syntax.command",
    columns: 1,
    [Commands are distinguished by `type` and may have callback to access payload. Results are extracted by a parser.],
    (```ts
export interface Command<R> {
    type: Interrupt,                   // type of the debug message (pause, run, step, ...)
    payload?: (map: SourceMap.Mapping) => string,  // optional payload of the debug message
    parser: (input: string) => R                             // the parser for the response
}
```,))

By taking inspiration from debugging instructions, managed testing permits for a wide range of automated tests to be implemented, which would otherwise require additional engineering efforts in existing unit testing frameworks.
Additionally, we have found that it provides a very natural way of writing tests for constrained devices.
We illustrate both these points by discussing in-depth examples for each layer of the testing pyramid in @sec:usecases.

=== Custom Actions in #latch

Aside from these commands, #latch allows steps to perform custom actions.
These custom actions enables developers to execute arbitrary code as part of a step in the testing scenario.
This is useful for interacting with the environment when testing the firmware of hardware components.
@lst.syntax.action shows the interface for a custom action.
An action is an object with a single act field, containing a function that takes a Testee argument and returns a promise.
The testee argument is provided at runtime by the #latch framework, to provide customs actions with access to the test instrumentation platform.
This is useful to define actions that need to respond to changes on the testee device, for instance waiting for a breakpoint to be hit.
Actions may be asynchronous and therefore return promises.
A promise is the standard mechanism for managing asynchronicity in JavaScript and TypeScript @parker15:javascript @madsen17:model.
If the action is expected to return a response, the promise should contain the output.
For #latch to run checks over this output, it needs to be of the _Assertable_ type.
#latch provides a function that can turn any object into an _Assertable_ object.

#snippet("lst.syntax.action",
    columns: 1,
    [#latch actions allow developers to execute arbitrary code in a test step. Output of such actions can be checked for correctness with the $mono("Assertable<T>")$ interface.],
    (```ts
type Assertable<T extends Object | void> = {[index: string]: any};

interface Action<T extends Object | void> {
    act: (testee: Testee) => Promise<Assertable<T>>;
}

declare function assertable<T extends Object>(obj: T): Assertable<T>;
```,))

In @sec:details we briefly showed a simple action in @lst.action.
However, this action returned no result, over which the test step could define assertions.
@lst.listen gives an second example of an action that does return a result.
The action will listen for the next MQTT message for a specific topic.
On #line(lines.listen.signature), the $mono("act")$ function returns a promise that resolves when the first message for the correct topic arrives.
The promise contains the MQTT message of the application-specific _Message_ type, including a topic and payload field.
This object can be used to define checks over the payload of the message with #latch assertions.
However, for #latch to run checks against the message, the returned object must conform to the _Assertable_ interface.
That is why on #line(lines.listen.assertable), the message object is wrapped in a _Assertable_ by the assertable function, shown in @lst.syntax.action.

#snippet("lst.listen",
    columns: 1,
    [An example of a pure action that listens for the next MQTT message to a specific topic.],
    (```ts
function listen(topic: string): Action<Message> {
    let client: mqtt.MqttClient = mqtt.connect("mqtt://test.mosquitto.org");
    
    return {
        act: () => new Promise<Assertable<Message>>((resolve) =>
            client.on("message", (_topic: string, payload: Buffer) => {
                if (topic === _topic)
                    resolve(assertable({topic: topic, payload: payload.toString()}));
})) }; }
```,))

=== Assertions over instruction results

Aside from the instruction, each step contains a list of zero or more assertions.
These assertions are used to perform checks on the result of the step's instruction.
The result of an instruction is always of the _Assertable_ type shown in @lst.syntax.assertion, which is an object that contains any number of properties that are indexed by strings.

For each string-indexed property of an _Assertable_ result, a test step can contain one or more assertions.
The interface of the assertions is shown in @lst.syntax.assertion.
The Assertions represent a check over a single property of the assertable object, specified by their string index.
The assertions over the object's properties follow the $mono("Expect")$ interface, also shown in @lst.syntax.assertion.
An $mono("Expect")$ object represents an assertion over an object property of the result, and takes a type parameter $mono("T")$ that should correspond with the type of that property.
The $mono("Expect")$ interface can be used to check for a value of type $mono("T")$, or a behavior encoded by the $mono("Behavior")$ enum also shown in @lst.syntax.assertion.
Behaviors can check for an unchanging, changing, increasing, or decreasing value.
If these options do not suffice, developers can write their own custom checks.
These are written as comparison functions that take the actual resulting value from the test, and return a boolean indicating whether the check passes.

#snippet("lst.syntax.assertion",
    columns: 1,
    [Instructions return their results as Assertable objects. In Latch tests specify assertions over the arbitrary properties of these Assertable result.],
    (```ts
interface Assertion { [index: string]: Expect<any>; }

type Expect<T> = T | Behaviour | (value: T) => boolean;

enum Behavior { unchanged, changed, increased, decreased }
```,))

The interface for assertions is implemented in TypeScript using a discrimination union, which is a design pattern used to differentiate between union members based on a property that the members hold.
For brevity, we have omitted this detail in @lst.syntax.assertion and all examples that follow.

The introspection commands are particularly interesting for assertions, since they enable assertions over the internal state of the testee.
Consider the core dump command which returns a state object, shown in @lst.syntax.dump shows the dump command, which returns a state object.

#snippet("lst.syntax.dump",
    columns: 1,
    [The _core dump_ command returns a state object, which contains the source location, execution mode, and name of the currently executing function.],
    (```ts
const dump: Command<State>;

interface State {
    line: number;    // current line position
    column: number;  // current column position
    mode: Mode;      // execution mode
    func: string;    // current function
}
```,))

For example, the dump command allows a step to check whether the testee is paused in a particular function.
@lst.dump shows how you might write this test step.
#line(lines.dump.expect) adds two assertions to the step.
The first checks whether the mode field in the state is set to pause, and the second checks if the current function has the correct name.

#snippet("lst.dump",
    columns: 1,
    [Example step that uses the _core dump_ command to check that execution paused in the _echo_ function.],
    (```ts
const step: Step = {
    title: "CHECK: entered *echo* function",
    instruction: Command.dump,
    expect: [{mode: Mode.PAUSE}, {func: "echo"}]
}
```,))

With the test specification language, developers can declaratively describe tests independently of the platform they should be executed on.
By embedding the domain-specific language in TypeScript, we can use the type system of TypeScript to type all the constructs in the EDSL and catch mistakes in tests early.

=== Managed Testing

Given a test written in the #latch test specification language, the framework will execute it through a single tester which manages one or more constrained testees.
That is, the software under test runs on a constrained device and the test suite is kept on the unconstrained tester device.
The tester will instruct the constrained device to perform tests by sending instructions step-by-step.
This design allows test to be run on constrained devices, while overcoming the memory constraints.

In the example of @sec:details we configured a test suite in #latch to run on two devices.
The test specification language has two main components to specify this configuration.
First, the language has an overarching concept of a test suite that groups a number of tests.
Each test suite runs independently of the others, and maintains its own devices, and their communication.
@lst.syntax.suite shows the public methods of the $mono("TestSuite")$ class in #latch that can add new devices and tests to a test suite.
Finally, when a test suite is created and fully configured, it can be executed on all devices with the $mono("run")$ method.

#snippet("lst.syntax.suite",
    columns: 1,
    [The $mono("TestSuite")$ allows developers to specify the testees, i.e., target devices, configure the scheduler, and the set of tests to be executed.],
    (```ts
class TestSuite {
    public testee(name: string, testee: Testee): TestSuite;
    public scheduler(scheduler: Scheduler): TestSuite;
    public test(test: Test): TestSuite;
}
```,))

The devices passed to a test suite, represent a single connection to a device.
#latch supports different devices each with their own abstraction, which needs to be able to connect and disconnect, upload a program, and send instructions.
The interface of these abstractions is captured by the abstract class in @lst.syntax.platform.

#snippet("lst.syntax.platform",
    columns: 1,
    [The $mono("Testee")$ implements support for different devices to enable upload of programs, and command execution.],
    (```ts
abstract class Testee {
    abstract connect(): Promise<void>;
    abstract upload(program: string): Promise<void>;
    abstract sendCommand<R>(command: Command<R>): Promise<R>;
    abstract disconnect(): Promise<void>;
}
```,))

=== Using Test Scheduling and Expressing Dependent Tests<subsec:dependency>

Performing tests on remote hardware testbeds is often slow, which delays feedback.
To make testing on constrained devices part of continuous integration in practice, we reduce the time it takes to get feedback on failing tests by not running unnecessary ones.
#latch allows dependencies between tests to be defined explicitly, as part of the test syntax as shown in @lst.syntax.scenario.
Each test in #latch can specify a list of tests it depends on.
The framework treats these dependencies between tests as transitive.
This enables the framework to skip tests that cannot succeed, thereby mitigating the effects of the processing constraints.

==== Example

To illustrate test dependencies, we expand on our earlier multiplication test example.
Suppose our constrained device is connected to a temperature sensor
that uses Fahrenheit, but our software uses Celsius.
For the conversion, we use
the AssemblyScript function in @lst.celsius.

#snippet("lst.celsius",
    columns: 1,
    [AssemblyScript function to convert Fahrenheit to Celsius.],
    (```ts
function celsius(fahrenheit: f32): f32 {
    return (fahrenheit - 32) * 0.556;
}
```,))

The conversion to Celsius depends
on the multiplication of 32-bit floating point numbers,
which we tested in our previous example.
If the test for multiplication fails,
we know that the $mono("celsius")$ function will fail, too,
and we can avoid running 
the temperature conversion test
to safe time.
Consequently, we list the $mono("multiplicationTest")$ as a dependency on #line(lines.dependencies) in @lst.dependent.
Dependencies are entirely defined by the user, the only restriction is the disallowing of cyclical dependencies.
Currently, the framework throws a runtime error whenever it encounters a cyclical dependency between a group of tests.


For complex scenarios, we can list an arbitrary number of #emph[dependencies].
If any of the dependencies should fail, #latch skips the test.
For continuous integration these tests are considered failing, but they are marked with a distinct #emph[skipped] label and counted separately from true failures by #latch.

#snippet("lst.dependent",
    columns: 1,
    [#latch test suite for the $mono("celsius")$ function, with a dependent scenario.],
    (```ts
const dependentTest: Test = {
  title: "Example Test with a dependency.",
  program: "celsius.ts",
  dependencies: [multiplicationTest],
  steps: [{
    title: "Fahrenheit to Celsius test",
    instruction: invoke("celsius", [WASM.f32(46.4)]),
    assert: returns(WASM.f32(-8.0))
  }]
};
```,))

==== User-defined Schedulers

The order in which tests are executed can also influence the execution time of the test suite, especially since failing dependent tests can prevent unnecessary computations.
To further speed up the execution, the test specification language allows developers to configure the scheduling algorithm the framework uses when running a test suite.
The best scheduling algorithm depends on the exact test suites.
Therefore, scheduling is configured at the level of a test suite as shown earlier in @lst.syntax.suite.
Scheduling algorithms are implemented as subclasses of the $mono("Scheduler")$ class from the test specification language shown in @lst.syntax.scheduler.
The class only has one public method that takes a list of tests, and returns a new list with the tests sorted according to the scheduler's prioritization.
This class allows developers to embed their own schedules in the test specification language.

#snippet("lst.syntax.scheduler",
    columns: 1,
    [$mono("Schedulers")$ enable custom ordering of tests. The ordering can avoid unnecessary test execution, or allow for test prioritization.],
    (```ts
class Scheduler {
    public schedule(tests: Test[]): Test[];
}
```,))

The current implementation of the #latch framework, provides two predefined schedulers, the default and the optimistic scheduler.
We give the pseudocode for both scheduling algorithms in @alg:hybridschedule and @alg:priorityschedule respectively.
Since dependencies amongst tests are transitive and cyclical dependencies are disallowed, we can extract trees from a test suite, where linked nodes depend on each other.
Both algorithms will use this fact.

The default scheduler prioritizes the dependencies between tests and works best with test suites where a large number of tests dependent on a much smaller set of scenarios.
The algorithm of the default scheduler, first finds all the dependency trees. // todo , as shown on @alg:hybridschedule:graphs.
The #emph[findDependencyGraphs] function constructs a forest of directed dependence trees.
In these graphs the nodes are tests that directly depend on their parents.
The function will throw a runtime error if any cyclical dependencies are encountered.
After the trees are found, the algorithm will append their tests breadth-first to the schedule.
Within the same depth the tests are sorted alphabetically based on the program's name, to minimize the number of times the tester needs to upload code.
The resulting list of tests, is ordered in such a way that trees are executed one after the other, and no test is ever run before any test it depends on.

#let suite = $"suite"$
#let schedule = $"schedule"$
#let trees = $"trees"$
#let tree = $"tree"$
#let accumulator = $"accumulator"$
#let levels = $"levels"$
#let index = $"index"$
#let level = $"level"$
#let acc = $"acc"$

#figure(grid(columns: 2,
    algorithm([The default scheduling algorithm in #latch.], [#pseudocode-list[
    + #strong[Require] list of tests $suite$
    + $schedule arrow.l [ ]$
    + #line-label(<alg:hybridschedule:graphs>) $trees arrow.l "findDependencyGraphs"(suite)$
    + *for* $tree \in trees$ *do*
      + #emph[append] $schedule$ #emph[with] breadth-first($tree$)
    + *end*
    + #strong[return] $schedule$
  ]#v(4.372em)], "alg:hybridschedule"),
    algorithm([The optimistic scheduling algorithm to minimizing program uploads.], pseudocode-list[
    + #strong[Require] list of tests $suite$
    + $accumulator arrow.l$ [ ][ ]
    + $trees arrow.l "findDependencyGraphs"(suite)$
    + *for* $tree \in trees$ *do*
      + $levels arrow.l "groupSiblings"(tree)$
      + #line-label(<alg:priorityschedule:levels>) *for* $index$, $level \in levels$
        + #emph[append] $acc[index]$ #emph[with] $level$
      + *end*
    + *end*
    + #strong[Return] flatten($accumulator$)
  ], "alg:priorityschedule")
))

//\begin{minipage}[t]{0.47\textwidth}
//\begin{algorithm}[H]
//    \caption{The default scheduling algorithm in #latch.}\label{alg:hybridschedule}
//    \begin{algorithmic}[1]
//    \Require list of tests $suite$
//    \State $schedule \gets$ [ ]
//    \State $trees \gets$ findDependencyGraphs($suite$)\label{alg:hybridschedule:graphs}
//    \ForAll{$tree \in trees$}
//        \State #emph[append] $schedule$ #emph[with] breadth-first($tree$)
//    \EndFor
//    \State \Return $schedule$
//    \end{algorithmic}
//\end{algorithm}
//\end{minipage}
//\hfill
//\begin{minipage}[t]{0.47\textwidth}
//\begin{algorithm}[H]
//    \caption{The optimistic scheduling algorithm to minimizing program uploads.}\label{alg:priorityschedule}
//    \begin{algorithmic}[1]
//    \Require list of tests $suite$
//    \State $accumulator \gets$ [ ][ ]
//    \State $trees \gets$ findDependencyGraphs($suite$)
//    \ForAll{$tree \in trees$}
//        \State $levels \gets$ groupSiblings($tree$)
//        \ForAll{$index$, $level \in levels$}\label{alg:priorityschedule:levels} 
//        \State #emph[append] $acc[index]$ #emph[with] $level$
//        \EndFor
//    \EndFor
//    \State \Return flatten($accumulator$)
//    \end{algorithmic}
//\end{algorithm}
//\end{minipage}

The optimistic scheduler is built on the assumption that dependent tests are more likely to use the same program.
If this is the case for the test suite, it can result in far fewer code uploads during a run compared to the default scheduler.
The algorithm starts by initializing an accumulator as a list of lists.
Then, it constructs the dependence trees in the same way as the default scheduler.
Next, for each tree the tests are aggregated into lists of tests with the same depth in the tree, the siblings in other words.
Subsequently, the algorithm appends each group of siblings to the list in the accumulator that corresponds to its level.
After all trees have been traversed, the accumulator is flattened to a one-dimensional list, and returned as the schedule.

The default scheduler iterates breadth-first over each dependence tree in succession.
In contrast, the optimistic scheduler can be seen as traversing the entire dependence forest breadth-first.
Again, at each depth the tests are sorted alphabetically according to their program.
These two schedulers are provided as examples of scheduling algorithms, each test suite most likely has its own optimal algorithm.

Thanks to the scheduling based on the test dependencies, #latch can detect failures early and prevent unnecessary tests from running.
However, the time needed for executing tests can be further minimized by executing test suites in parallel.
Since microcontrollers are typically cheap and abundantly available, it makes sense to run different tests on separate devices at the same time.
Currently, the schedulers still return a single ordering over the tests, but the dependency trees constructed as part of their algorithms offer an opportunity to parallelize.
Different dependency trees can be safely run in parallel, since tests in different trees have no dependencies in common.

=== Handling and Reporting on Timeouts

Since all actions of a test are executed remotely,
the tester cannot distinguish between an unresponsive test
and a test that can still succeed after a long time.
This is an unavoidable problem when testing in the presence of asynchronous actions.
Many modern testing frameworks deal with this by adding timeouts to all asynchronous tests.
In #latch we use timeouts for testing on constrained devices, too,
but provide as much information as possible about where timeouts occur.
Thus, #latch provides timeouts at the level of single instructions, following the example of frameworks dedicated to testing of asynchronous system @awaitility, rather than merely at the level of a test, as is common practice in more general test frameworks @mocha @doctest @junit.
We found that debugging timeouts,
is significantly easier with fine-grained information.

The actions of the tests are not the only source of asynchronicity in #latch.
There are other asynchronous actions behind the scenes, from compiling test programs to connecting with hardware testbeds.
In #latch every asynchronous action can time out, and each timeout has their own helpful message indented to make them easily identifiable by developers.

=== Detecting and Reporting Flaky Tests<subsec:flaky>

The asynchronicity and non-determinism introduced by #latch and the hardware testbeds, can cause any test to become flaky.
These tests can both succeed and fail for the same version of the software under test.
In #latch, we follow the recommendation of #cite(<harman18:from>, form: "prose") to considers all tests as flaky.
Indeed, flaky tests can hint at bugs.
Therefore, we use an approach that improves
the debuggability of flaky tests.

The framework can run in two modes.
A normal mode which executes each action and each test at most once, and an analysis mode where tests are executed multiple times to analyze flakiness.
In this mode we assume all tests are flaky.
Therefore, tests are rerun even if they succeed.
This can slow the test suite significantly, which is why it is provided as an optional mode.
Indeed, the default mode still allows continuous integration to report initial results quickly, while the flakiness of the test suite can be reported at a later moment after the second mode has finished.
The analysis mode trades performance for more information and certainty.

The analysis mode can be configured with a minimum and maximum number of runs.
Since we consider all tests as flaky, we will execute each test at least the minimum number of times.
If the test reports the same result for each of these runs, #latch assumes it is not flaky and stops for this scenario.
In the other case, we already have proof that the test is flaky, and #latch will continue executing up to the maximum number of times to get a more representative measure of the flakiness.
The maximum number of runs is important to have statistically significant results, and can therefore be configured by the user for each run.
The minimum and maximum number of runs can be configured by the user.
When a test suite is executed on multiple platforms, flakiness is measured for each platform separately.
At the end of the analysis run, #latch reports the global flakiness of the test suite for each platform as the number of flaky scenarios, and
at the end of the analysis run, #latch reports the flakiness on each platform for each test and gives an overview with the overall flakiness of the test suite for each platform separately and all platforms together.

=== Prototype Implementation<sec:impl>

The prototype implementation of #latch is a TypeScript library built on the WARDuino @lauwaerts24:warduino virtual machine for constrained devices and the Mocha testing framework for JavaScript and TypeScript.

WARDuino is a WebAssembly @haas17:bringing virtual machine targeting ESP32 microcontrollers.
The virtual machine also has basic debugging support, which we used as the basis for implementation our test instrumentation platform in #latch.
By using a WebAssembly virtual machine, #latch can test programs written in any language that can compile to WebAssembly.
This includes most of the mainstream programming languages used today, such as C, C++, Java, Python, Ruby, Rust @fermyon-technologies--inc-23:webassembly.
In order to enable testing of a language fully, #latch needs to have support for compilation and sourcemapping.
The current implementation has support for compiling and constructing sourcemaps for AssemblyScript.

We believe the general principles we use for implementing the #latch prototype on WARDuino, can be applied to any language or virtual machine which provides basic debugging support.
This includes the C programming language that is supported by many microcontrollers, and which offers basic debugging by means of a JTAG interface.

#figure(caption: [IDE integration in WebStorm @jetbrains-s-r-o-23:webstorm.],
    rect(inset: 0mm, image("figures/ide.png", width: 100%)))<fig:ide>

The #latch prototype uses the Mocha testing framework for JavaScript and TypeScript to report the results of the tests in the #latch framework.
Handling the output through an existing framework, immediately gives #latch integration into most of the existing IDEs used for programming in TypeScript and JavaScript.

== Testing with #latch<sec:usecases>

#latch offers a framework for writing unconstrained automated test scripts, that can address many different testing scenarios.
To demonstrate the versatility of #latch, we will present a common testing scenario for microcontrollers for each stage of the testing pyramid @cohn09:succeeding.
Several versions of the pyramid exist, often tailored to specific software domains @mukhin21:testing-mechanism.
Generally, testing pyramids split testing into three or more stages, which are often performed in order from bottom to top.
Each successive layer in the pyramid tests larger parts of the software in one test.
Therefore, each layer will typically have fewer tests than those before it.
The testing pyramid is a common way of representing the full scope of testing for a software project, it is therefore suitable to showcase #latch's ability to support the full range of testing scenarios.

In this section, we adhere to the classic testing pyramid, with unit testing at the bottom, followed by integration (or service) testing, and finally topped by end-to-end (user) testing.
We first highlight how #latch can perform realistic, large-scale unit testing on constrained hardware.
Then we show how #latch can test the instrumentation it uses as an illustration of integration testing.
Finally, we show how manual testing on hardware can be automated to perform end-to-end testing.
The example test suite illustrates how this can be used to test both the hardware itself, and the software libraries used for controlling that hardware.

=== Unit Testing: Large-scale Testing of a Virtual Machine<subsec:spec>

In the testing pyramid, the largest number of tests are the unit tests.
The underlying virtual machine used by #latch, WARDuino, uses a subset of the official WebAssembly specification test suite, to test whether it conforms with the WebAssembly standard.
WARDuino does not use the entire official test suite, since it does not yet support all the latest accepted proposals to the standard.
The WARDuino project uses an extended version of the virtual machine to parse and run the unit tests from the test suite.
Unfortunately, this means it cannot be executed on microcontrollers, since the entire suite needs to be included as well as the large parsing library needed to extract the unit tests.
By using #latch, we are able to take the same test suite, and execute it on an ESP32 microcontroller.
We discuss the results further in @sec:performance, in this section we focus on how the official specification test suite is written in #latch.

Test files in the WARDuino test suite contain a number of WebAssembly modules, each of which has a number of assertions.
These assertions are so called #emph[assert-return] tests, which invoke a WebAssembly function and specify the expected result.
The assertions are written as S-expressions.#footnote[This conforms with the official WebAssembly specification tests, which can be found on: #link("https://github.com/WebAssembly/spec/tree/main/test/core")].
@lst.specsource shows two such assertions.

#snippet("lst.specsource",
    columns: 1,
    [An #emph[assert-return] test from the official WebAssembly Specification test suite, testing the `f32.mul` operation.],
    (```wast
(module (func (export "mul") (param $x f32) (param $y f32) (result f32) (f32.mul (local.get $x) (local.get $y))))
(assert_return (invoke "mul" (f32.const -0x0p+0) (f32.const 0x0p+0)) (f32.const -0x0p+0))
(assert_return (invoke "mul" (f32.const -0x1p-149) (f32.const -0x0p+0)) (f32.const 0x0p+0))
```,))

With #latch, we can run the same tests on actual embedded hardware.
The structure of the WebAssembly specification test suite is well suited for #latch's test specification language.
The asserts coincide perfectly with the steps in the test.
Each assert contains a single action to perform and a single assertion to check.
Therefore, all specification tests for WebAssembly can be encoded as a single test suite with a test for each distinct module.
@lst.spectest shows the example in @lst.specsource translated into a #latch test.

#snippet("lst.spectest",
    columns: 1,
    [The `f32.mul` test has two steps, each checking the result of `mul` on different inputs.],
    (```ts
const test: Test = { // Spec test
  title: "Test f32.mul operation",
  program: "module.wast",
  steps: [
    { title: "assert: -0 * +0 = -0",
      instruction: Command.invoke("mul", args: [-0, 0]),
      expect: returns(WASM.f32(-0)) },
    { title: "assert: -1e-149 * -0 = 0",
      instruction: Command.invoke("mul", [-1e-149, -0]),
      expect: returns(WASM.f32(0)) }
  ]
};
```,))

To test the WARDuino virtual machine, we converted the official WebAssembly test specification into a large #latch test suite.
Since #latch is a DSL embedded in TypeScript, this conversion can easily be done programmatically in TypeScript code.
Converting the #emph[assert-return] S-expressions to #latch syntax in this way is fairly, easy.
The conversion enables us to test the WARDuino virtual machine incrementally.
The test instrumentation framework will only load one WebAssembly module
from the test suite at a time
and each test is converted into steps,
which are sent to the testee incrementally,
i.e. the testing steps do not need to be stored in the memory of the testee.
In @sec:performance, we give an overview of the performance of executing this test suite on an ESP32 device.

=== Integration Testing: Testing a Debugger API

Due to its design, #latch is well suited to test the debugging operations of the WARDuino virtual machine.
Testing the debugger API exemplifies the second layer of the testing pyramid: integration testing.

As an example, consider the step over debug instruction, which steps over a single function call or a single instruction when the instruction does not call a function.
A simple test starts at a function call and sends the debugging instruction, before checking if the program did step over it correctly.

#snippet("lst.blink",
    columns: 1,
    [The blink program used by the integration test for the WARDuino debugger API.],
    (```ts
export function main(): void {
    blink();
    print("started blinking");
}
```,))

The blink program in @lst.blink calls 
on Line 2 the $mono("blink()")$ function
and on Line 3 the $mono("print()")$ function.
With this program, we check that the program executes
up to Line 3, rather than stopping at the start of the main function.
@lst.dbgtest shows the corresponding definition of a test in #latch.
It loads the program, calls the main function, and sends a step over instruction.
At the end of the test, it checks whether the current line has indeed moved to Line 3.

#snippet("lst.dbgtest",
    columns: 1,
    [The description for #latch of the *step over* test.],
    (```ts
const stepOverTest: Test = {
    title: "Test STEP OVER",
    program: "blink.wast",
    dependencies: [dumpTest, invokeTest]
    steps: [
      { title: "Start program",
        instruction: Command.invoke("main", []) },
      { title: "Send STEP OVER command",
        instruction: Command.stepOver },
      { title: "CHECK: execution stepped over direct call",
        instruction: Command.dump,
        expect: [{line: 3}] }
    ]
};
```,))

The debugging tests illustrate how integration tests can frequently dependent on each other.
For instance, our small #emph[step over] test uses the #emph[invoke] and #emph[dump] instructions, which can also be tested with #latch.
When tests for either these two instructions fail, we can no longer rely on the results of the #emph[step over] test.
Since the #emph[invoke] or #emph[dump] commands may be broken, they might cause false positives, or false negatives, in tests that use them.
There is no reason to run tests that cannot be trusted.
In #latch, we can encode the dependency of the #emph[step over] test on the #emph[invoke] and #emph[dump] command, by adding their tests to the list of dependent tests.
With this information, #latch can prevent unnecessary or unreliable tests from slowing down the test suite, and delaying actionable feedback.

=== End-to-End Testing: Automating Manual Testing on Hardware<subsec:scenario>

Developers of embedded software rely heavily on manual testing of their programs on the targeted hardware.
The goal of manual testing is to verify that both the hardware and software of the system work correctly.
It is equally important to check that the effects on the environment and the interaction between the hardware and the environment, work as intended.
This kind of comprehensive end-to-end testing of embedded systems requires extensive control over the environment and conditions the hardware operates under, such as simulating user interactions, or controlling the input for sensors.
These requirements account in large part for the ubiquity of manual testing, since they make automation of testing much more difficult.

#latch allows tests to control the behavior of the environment with local actions, and the behavior of the software under test through debugging instructions.
This enables developers to script automated tests that correspond with manual testing scenarios.

When performing end-to-end testing on the hardware, whether manual or automated, things outside the control of the system can go wrong and cause the test to fail even though no part of the software under test is at fault.
Such failures are often rare and non-deterministic, leading to flaky tests.
The built-in detection and reporting of flaky tests in #latch is therefore important for end-to-end testing scenarios with the hardware.

==== Example: Testing MQTT Primitives<subsec:example>

The WARDuino virtual machine has a callback handling system that is used to implement different asynchronous IoT protocols @lauwaerts22:event-based-out-of-place-debugging, such as primitives for the MQTT protocol.
Since the correct implementation of such protocols is crucial for applications, we need to test it extensively.
Unfortunately, the public WARDuino project currently has no automated tests for these components, especially since they require interaction with the device to be tested.
The following example illustrates how #latch can be used to write end-to-end tests for both the callback system and the MQTT primitives.
The example wants to verify the following two requirements:

1. After the subscribe primitive is called, the callback function should be registered for the correct topic in the virtual machine's callback system.
2. When an MQTT message is received the correct callback function should be called.

To test this functionality, we use a minimal program that subscribes on a single MQTT topic, and through a callback writes all messages it receives to the serial bus.
An AssemblyScript implementation is shown in @lst.mqtt.

#snippet("lst.mqtt",
    columns: 1,
    [Tiny MQTT program used to regression test the callback handling system in WARDuino.],
    (```ts
function echo(topic: string, payload: string): void {
    print(payload);
}

export function main(): void {
    // ...
    mqtt_init("broker.hivemq.com", 1883);
    mqtt_subscribe("echo", echo);
    // ...
}
```,))

The code in @lst.mqtt, leaves out the code that connects to the Wi-Fi network, and checks the connection with the server whenever the program is idle.
The example instead focuses on the three main things the program needs to do for the end-to-end test.
It configures the MQTT server on #line(lines.mqtt.init), and subscribes to the #emph[echo] topic on #line(lines.mqtt.subscribe) with the callback function defined on #line(lines.mqtt.callback).
The scenario in @lst.scenario uses the program to test the callback system and MQTT primitives of the WARDuino virtual machine on real hardware.

#snippet("lst.scenario",
    columns: 1,
    [Test for the callback handling system in WARDuino, showing multiple steps and a custom assertion.],
    (```ts
const test: Test = { // MQTT test
  title: "Test MQTT primitives",
  program: "mqtt.ts",
  dependencies: [testWiFi],
  steps: [
    { title: "Start program",
      instruction: Command.invoke("main", []) },
    { title: "CHECK: callback function registered",
      instruction: Command.dumpCallbackMapping,
      expect: [{
        callbacks: (state, mapping) => mapping.some((map) => map["echo"].length > 0)}] },
    { title: "Set breakpoint at *echo* callback",
      instruction: Command.setBreakpoint(breakpointAtFunction("echo")) },
    { title: "Send MQTT message and await breakpoint hit",
      instruction: Actions.messageAndWait() },
    { title: "CHECK: entered callback function",
      instruction: Command.dump,
      expect: [{mode: Mode.PAUSE}, {func: "echo"}] }
  ]
};
```,))

Many hardware-specific tests require the environment to behave in a controlled way.
#latch makes no assumptions about the hardware and environment used for testing.
Instead, the test specification language offers the ability to define local actions, through which the tester in the framework can manipulate and control the environment, both real and simulated.

The first step of the scenario invokes the main function, and the second step checks whether the echo callback was correctly registered in WARDuino's internal callback mapping.
In the third step, the scenario sets a breakpoint at the callback function, so in the next step it can check if the callback is indeed called whenever an MQTT message is sent.
To this end, the fourth step tells the tester to perform a local action.
In the example, the #emph[messageAndWait] function will send a message to the MQTT broker and wait until the testee reports that a breakpoint is hit.
Once its promise resolves, we know a breakpoint is hit, and the final step double-checks whether we are indeed in the right function.
When the promise is rejected, however, the action is marked as failing before continuing the scenario.
This fifth step retrieves a dump of the current virtual machine state, and checks that WARDuino is paused and the current function corresponds to the #emph[echo] callback function.

== Performance Evaluation<sec:performance>

The goal of #latch is to allow large-scale testing of IoT software on microcontrollers, and to enable users to write a versatile range of tests.
The testing scenarios in the previous section illustrate the versatility of #latch to implement many testing strategies.
@sec:details and @sec:language show how managed testing works, and what the #latch framework does to overcome the three challenges outlined in @sec:challenges.
In this section we provide empirical evidence to support our research question:

/ Question: Is the managed testing approach, where tests are split into steps, sufficient for executing large-scale tests with #latch?

=== Test suites

To answer the question of performance, we execute a number of tests suites with #latch on an ESP32-WROVER IE and measure the runtime overhead compared to executing the same suites on a laptop.
The test suites include the unit and debugging test suites presented in @sec:usecases, and an additional test suite which is more computationally intensive.
We chose these three types of test suites in order to have a wide range of tests that are unique in different aspects.
The specification test suites from @subsec:spec are structurally identical, but test very different aspects of computer programs, ranging from memory manipulation, to control flow.
The suites also represent a very common test pattern, unit testing through single function invocation, which is ubiquitous in many modern testing practices.
The debugging test suite on the other hand, does not limit itself to just the invoke command, but uses the entire range of #latch commands in its tests, which also contain multiple steps.
The computing test suite is structurally similar to the specification test suites, but is computationally more intensive, with steps that generally take at least an order of magnitude longer to perform.

#strong[Large Unit Test Suites.] We use the WARDuino specification test suites as found in the public repository of the virtual machine, which we presented in @subsec:spec.
The collection contains 10,213 total tests across 25 test suites.
The tests cover the operations on the numerical values, both integer and floating point, which are the only types of values in WebAssembly.
The #emph[copy], #emph[load], #emph[align], and #emph[address] categories test the WebAssembly memory, while the #emph[local tee], #emph[local set], #emph[local get], #emph[nop], #emph[return], #emph[call indirect], and #emph[call] categories test stack manipulation.
The remaining tests verify the structured control flow of WebAssembly.
During the evaluation we used the default scheduling algorithm in #latch, and ran the test suites on a single remote testee.

The developers of the WARDuino virtual machine use simulation to test against the WebAssembly specification.
However, the simulation ignores important hardware limitations.
For instance, the memory of the simulated hardware is only limited by the amount of memory available to the host machine.
Furthermore, to execute the specification tests, the WARDuino developers extended the simulator with a dedicated parsing library to parse the test suite written in S-expressions.
This parsing library is too big to be run on the ESP32 and the S-expressions from the test suite alone, takes up 713 KB of memory.
This is already more than twice the size of the microcontroller's memory, without including the WARDuino virtual machine, the parsing library, and the infrastructure to run the test suite.
This means, that the WARDuino developers cannot currently test on the microcontrollers they target.
However, when comparing the outcome of this approach with the output of the #latch version, we found no differences, giving us confidence in the soundness of our framework.
To assess the performance of #latch,
we measure the overhead of executing the #latch test suites on a microcontroller compared with current practices, i.e. using a simulator.

#strong[WARDuino Debugger Test Suite.] While the different specification test suites, test very different aspects, their structure are similar.
We therefore include the debugger test suite outlined in @sec:usecases, as an example that is not a traditional unit test suite.
Rather than exclusively using the invoke command, this suite uses all commands available to #latch.

#strong[Computing Test Suite.] As a final example, we include a test suite that unit tests a few simple mathematical operations, calculate the factorial, get the nth number in the fibonacci sequence, find the greatest common divider, and check if a number is prime.
Similar to the specification test suites, the computing tests each include a single invoke step.
However, while the steps in the other test suites are very fast, taking just a few milliseconds---the steps in this test suite can take several centiseconds.

=== Performance

All test suites are run separately on a Dell XPS 13 laptop using an 11th Gen Intel Core i7-1185G7 and 32 GB RAM memory, and the ESP32-WROVER IE microcontroller operating at a clock frequency of 240 MHz, and with 520 KiB SRAM, 4 MB SPI flash and 8 MB PSRAM.
Each run starts by initializing the WARDuino instance, in the case of the microcontroller this entails flashing the entire virtual machine to the device.
Whenever the test suites use different programs, they are uploaded with the #emph[upload module] command, which allows #latch to update the program under test during a test suite, without needing to flash.

A detailed comparison of the overhead of executing the test suite is shown in @fig:overhead.
The overhead on microcontroller is shown as relative to the simulator, and is the sample mean taken over 10 runs.
#latch is run in its default mode without the flakiness analysis, where tests are run at most once.
Each bar in this graph shows the overhead for executing one test suite on the hardware with #latch.
The test suites are ordered from most steps, to least.
The number of steps are shown next to each name, and the specification tests suites are highlighted in a different color.

All test suites shown in @fig:overhead can be executed with #latch on the simulated version of WARDuino in approximately 10 minutes.
Executing the same test suites directly on the ESP32, takes around 20 minutes.
While the test suites take on average twice as long on the embedded device, the largest of the specification test suites run faster on the microcontroller.
This is counterintuitive, but can be explained by the nature of the test suites.
The steps in the specification test suites, are very simple tasks that are performed too quickly for any difference to be observed between the two devices,
The overhead therefore becomes dominated by the communication, not the actual instructions themselves.
The way the TypeScript framework handles the interprocess communication is evidently slower than the serial communication with the microcontroller over USB-C.
However, the flashing at the start remains much slower than starting a new process on the laptop, therefore the overhead of the specification test suites with the fewest steps, is dominated by the startup phase instead.
This results in the highest overhead overall.

#import "figures/overhead.typ": overhead
#import "../../lib/book.typ": text-width
#import "../../lib/util.typ": scale-to-width
// scale-to-width(text-width, overhead)
#figure(image(width: 100%, "figures/benchmarks.svg"), caption: [The relative runtime overhead of #latch's WebAssembly specification test suite on hardware compared to a simulator for each test suite. Runtimes are calculated as sample means of 10 runs, and the exact relative overhead is shown next to each bar. The error bars show the confidence interval for the difference between the two means (normalized to the relative overhead) based on the Welch's t-test. The number of steps for each test suite is listed next to its name.])<fig:overhead>

The specification test suites taken separately in @fig:overhead, shows that fewer test steps results in higher overhead, because the execution time becomes dominated by the flashing process.
This shows how important it is to prevent unnecessary flashing by using the #emph[upload module] command.
Conversely, more steps result in lower overhead, because the communication dominates the execution time of the steps.
However, the debugger and computing test suites are major outliers, suggesting this is not the full story.
For instance, the computing test suite contains 3,470 steps, but has a much higher overhead than the memory copy suite of a similar size.
This is due to the steps in the computing test suite being much more computationally intensive, and so much slower.
Because the steps take longer to execute, the relative impact of the communication overhead is much lower.
The debugger test suite on the other hand, has a much lower overhead than similarly sized specification test suites.
This is because, invoke instructions used in the specification test suites, are quite slow compared to most of the other #latch commands, used in the debugger test suite.
An entire user-defined function is run, in contrast to the step and dump command, which run a single instruction, or only send data.
While the differences in structure among the test suites, reveals how many factors impact the performance of #latch, the results for the suites are roughly inline with each other.
The results show that #latch performs well for our use-case of very large test suites of many small unit tests, which are very common in regression testing and continuous integration.

=== Summary

It is important for the validity of these results, that the test suites used here, are representative for the typical workloads of microcontroller software test suites.
We consider this to be the case, since the specification, computing and debugger test suites are very different structurally, yet present very similar runtime performance.
Additionally, we believe that the specification test suites are representative for microcontroller software testing.
The suites use standard unit tests that invoke a function and check its results.
It is no coincidence that these kinds of unit tests are so widely spread in test-driven development.
They are an excellent way of testing that can be applied to almost any piece of software, regardless of its structure or programming paradigm.
This also holds for microcontroller software.
Moreover, the #emph[invoke] instruction is one of the more expensive operations in #latch, since user defined functions may take very long to execute.
Finally, the specification test suites are quite heterogeneous, since the categories test wildly different aspects of the virtual machine---from among others, control flow, arithmetic, stack manipulation, and memory access.
For these reasons, we believe that this test suite is able to give a representative evaluation of #latch's performance.

The performance results themselves, are impacted by an innumerable number of factors.
Especially since the benchmarks are run on two devices, the framework on the laptop and the tests on the microcontroller.
The communication between the two is an important factor in the runtime performance, and may be influenced by any number of factors, such as the operating system of either device, the configuration of the microcontroller, or the hardware (serial connection) itself.
However, we believe given the size and number of repetitions, the performance figures are illustrative for the overall performance of managed testing with #latch.

In conclusion, we believe that our initial evaluation shows that the #latch framework and its managed testing approach present a realistic answer to our research question.
The framework is able to automatically execute large-scale test suites on constrained devices with good performance, considering the limited processing power of the constrained devices.
#latch performs the best for our most important use-case, test suites with high numbers of small unit tests for the same software under test.
On the other hand, the performance overhead is highest when #latch needs to upload new software frequently.
The #latch prototype has initial support for parallel execution on multiple constrained devices which can help mitigate this overhead, especially when many test programs can be uploaded simultaneously to different devices.

== Related Work<sec:related>

Common software development practices such as regression testing, continuous integration, and test driven development, are much harder to adopt when working with microcontrollers.
This is in large part due to the need to test on the physical hardware, specifically microcontrollers.
There are very few solutions for single-target testing of software on microcontrollers.
Ztest @peress24:test, Unity @platformio23:unity @vandervoord15:unity, and ArduinoTest @murdoch23:arduinounit are traditional unit testing frameworks for specific microcontroller architectures.
Unfortunately, these frameworks do little to overcome the resource-constraints of microcontrollers themselves, and provide only the most standard unit testing functionality without any tailored solutions for testing on hardware.
However, when testing on microcontrollers in this way, the test scenarios often rely on very specific hardware interactions as illustrated by our examples in @sec:usecases.
#latch addresses this lacuna with its novel testing methodology based on debugging methods.
We are not aware of any testing framework that provides an alternative solution.

In this section, we will discuss the differences between #latch and the few exiting unit testing frameworks for microcontrollers further.
In this chapter we have proposed a new way of testing on microcontrollers individually, but IoT systems are often tested as a whole in industry.
While this kind of testing answers an entirely different set of demands than #latch, we do give a brief overview of these approaches here, for completeness.
Similarly, testing plays a large role in general software development.
As a result, a wide range of research topics are related to the #latch framework, of which not all have been previously applied to IoT.
In the remainder of this section, we discuss #emph[holistic IoT testing], other #emph[unit testing frameworks] broadly, #emph[remote testing], #emph[scriptable debugging], #emph[test environments] for IoT programs, #emph[device farms] for mobile applications, #emph[conditional testing], #emph[test prioritization and selection], and #emph[flaky tests].
Wherever possible, we include examples from IoT or microcontroller settings.

#heading(numbering: none, level: 4, "Unit Testing Frameworks")

Constrained devices are still programmed primarily in low-level language such as C and C++.
Many traditional unit testing frameworks are available for these languages, such as Google Test @googletest23:googletest, Boost.Test @boost-test-team23:what, CUTE @ifs-institut-fur-software23:cute, and bandit @beyer23:bandit.
There are a handful of frameworks targeting microcontrollers explicitly, such as Unity @platformio23:unity @vandervoord15:unity and ArduinoTest @murdoch23:arduinounit.
These work analogous to other unit testing frameworks, but are small enough to run on some constrained devices.
While preferable over manual testing, these frameworks require the tests suites to be very small, since they are compiled and run along with the framework in their entirety on the device.
In contrast, #latch allows arbitrarily large test suites.

#heading(numbering: none, level: 4, "Remote Testing")
#latch's managed testing is adjacent to remote testing, but with some important differences.
Remote testing is not a novel idea, for instance #cite(form: "prose", <jard99:remote>) argued in 1999 that local synchronous tests can be translated to remote asynchronous tests without losing any testing power.
Remote testing has mostly been used to test distributed systems @yao05:framework.

The RobotFramework @robot-framework-foundation23:robot for instance, is a large testing framework that supports remote testing via an RPC interface offering a transparent distribution model.
As argued in many papers "distribution transparency is a myth that is both misleading and dangerous" @waldo97:note @lea97:design @guerraoui99:what.
The Latch framework takes into account these lessons and offers the test engineer a testing framework with inherit timeouts and support for flaky tests, going well beyond the RobotFramework.

Some examples of remote testing frameworks can also be found for constrained devices.
The popular PlatformIO project @platformio23:unity, uses the Unity framework @vandervoord15:unity for remote testing.
However, it works significantly different from how #latch executes large test suites.
While #latch allows arbitrarily large test suites by executing tests step-by-step, Unity does not address the memory constraints of the target devices as it compiles and uploads test suites as one monolithic executable.
The framework also does not provide the debugger-like scripts (with custom actions) supported by Latch that enable the automation of standard hardware tests.

#heading(numbering: none, level: 4, "Holistic IoT Testing")

Existing tools for IoT testing focus largely on testing networked systems of many devices holistically~@popereshnyak18:iot @kanstren18:architectures, rather than the more common approach where components are tested selectively.
Holistic testing of networked systems are by and large incompatible with many of the common development practices; such as test driven development for instance, which relies on selective testing of single components.
Moreover, wholesale testing of heterogeneous system is very difficult, so many testing tools instead focus on monitoring to try and detect errors @datadog24:end @appoptics.
The few real testing frameworks available, tend to provide testing as a service @kim18:iot-taas.
A recent research project developed an interesting framework for automatic testing of distributed _bluetooth mesh applications_ with precise event scheduling, where tests are specified use a specific json format @wieme24:distributed.
However, the work is focussed on a research setting, and benchmarking of new algorithms, rather than testing of software.

While holistic testing makes sense for IoT applications in industry, the approach makes far less sense for more consumer-oriented applications, such as smart home devices.
Besides, developers cannot trust that end-to-end testing on such a high level, is enough to test IoT systems thoroughly.
Neither does it lend itself well to test-driven development, as testing can only take place with a fully operational system.
Therefore, there is a real need for selective---rather than holistic---testing of IoT software on microcontrollers.
This is much easier with the single target testing in the style provided by #latch.

#heading(numbering: none, level: 4, "Scriptable Debugging")

#latch's scriptable debugger-like hardware tests are inspired by scriptable debugging, which has been used in many other domains @marceau07:design.
Scriptable debugging refers to all debugging techniques that can be controlled by developers through a programming language or similar tools such as regular expressions.
Programmable debugging goes back to the early eighties, with many of the early proposals, such as Dispel @johnson81:dispel and Dalek @olsson90:dalek, exploring variations on the concept of breakpoints.
Recent work on a scriptable debugger API for Pharo @dupriez19:sindarin, exposes a wide variety of advanced debugging operations, and allows developers to solve many challenging debugging scenarios through automated scripts.
We are not aware of any framework which also applies the idea of scriptable debugging to testing in the context of constrained hardware.

#heading(numbering: none, level: 4, "Test Environments")

A popular research topic in the domain of IoT testing, are heterogeneous test environments @bures20:interoperability, where software can be distributed to nodes which are connected via a controlled network.
This solution focuses on the challenging heterogeneity of IoT systems, and does not take into account the constraints the limited memory puts on the test suite size.
Most test environments are virtual, and emulate the entire IoT environment @ramprasad19:emu-iot-a-virtual-internet @nikolaidis21:iotier @symeonides20:fogify.

While, simulators are widely used for testing Internet of Things systems @bures20:interoperability, they can never capture all the aspects of real hardware @roska90:limitations @khan11:limitations.
For example, bugs caused by mistakes in interrupt handling, incomplete or wrong configuration, and concurrency faults @makhshari21:iot-bugs are typically not simulated.
Because accurate hardware emulation is difficult, modern simulators often incorporate parts of the hardware under test, as is the case for #emph[hardware-in-the-loop simulations] @mihali-c22:hardware-in-the-loop-simulations.
Similarly, some test environments do allow hardware to be integrated into their test environments, but still fundamentally rely on virtualization @behnke19:hector @keahey20:lessons.
There are far fewer works that look into full hardware test environments @adjih15:fit-iot-lab @burin12:senslab @gluhak11:survey.
Using these large test environments can give more control to the developer to change various aspects of the nodes and network, such as packet loss, latency, and so on.
However, setting up such large and often complex systems is complicated and time-consuming, for that reason they are often provided as a service @kim18:iot-taas @beilharz22:continuously.
Subsequently, the test environments confine users to the specific choices in hardware, virtualization, and network technologies made by the service.
While these test environments reduce the overhead of setting up a testing lab, they do not fundamentally help developers overcome the hardware limitations faced when executing large test suites.

#heading(numbering: none, level: 4, "Device Farms")

These test environments are sometimes called testing farms or device farms in case they use real hardware, and are a popular approach for testing mobile applications @huang14:appacts @fazzini20:managing.
Curiously, testing on devices seems much more prevalent in the field of testing mobile applications @kong19:automated.
We believe this might be because mobile devices have far more memory than the embedded devices targeted by #latch, and therefore have no problem running large test suites.
This strengthens our view that testing on constrained hardware presents a worthwhile research direction.
However, the existing device farms heavily target mobile devices, and again limit users to the chosen technologies and hardware.

#heading(numbering: none, level: 4, "Conditional testing")

Dependencies in #latch can be viewed as conditional skips for tests, where a test is skipped if any of the scenarios it depends on fail.
Conditional skips have been around for some time in unit testing frameworks, such as the pytest framework for the Python language @krekel23:pytest, and the JUnit framework for Java @bechtold23:junit.
Pytest includes a _skipif_ annotation which takes a boolean expression as its argument.
In JUnit developers can use the _Assume_ class, which provides a set of methods for conditional execution of tests.
Modern frameworks targeting constrained devices @platformio23:unit @murdoch23:arduinounit do not support conditional tests.

#heading(numbering: none, level: 4, "Test prioritization and selection")

Another purpose of the dependencies in the test description language, are to determine the order tests are run in.
Research on software testing has recently increased its attention to test prioritization and test selection @pan21:test.
These techniques can also be applied to testing IoT systems @medhat20:framework, where they are particularly useful since they can reduce large test suites to the most important tests, and help prioritize tests in such a way that regression tests fail as early as possible.
An interesting line of future research could focus on integrating these techniques in #latch.

#heading(numbering: none, level: 4, "Flaky Tests")

Flaky tests represent an active domain of research @parry21:survey, which focuses on three problems: detecting flaky tests, finding root causes, and fixing flaky tests @zolfaghari21:root.
The first step is to detect which tests are flaky.
A popular approach is to look at the code coverage of tests @zolfaghari21:root @bell18:deflaker.
Once a flaky test is found, the next step is to find the root cause of the flaky test.
This is a considerably harder problem, which is still being actively worked on @lam19:root.
Alternatively, some research looks into automatically fixing, or preventing, flaky tests @shi19:ifixflakies.
All these techniques, from detection to fixing, are developed with the ultimate goal of mitigating and preventing flaky tests.
In contrast, #latch focuses on providing a simple way of detecting and measuring the number of flaky tests in a test suite run.
When evaluating #latch, we encountered flaky tests only rarely, but we believe that further research is warranted to assess the degree in which testing on constrained devices can cause flaky tests, and how existing techniques can mitigate them.

== Conclusion<sec:conclusion>
Testing is an essential part of the software development cycle which is currently very challenging on constrained devices.
The limited memory and processing power of these constrained devices restrict the size of the test suite and makes testing slow, impeding a fast feedback loop.
Moreover, due to the non-deterministic and unpredictable environment, tests can become flaky.

In this chapter, we answered the question of how to design and implement a testing framework for automatically running large-scale versatile tests on constrained systems.
We introduce our novel testing framework #latch (Large-scale Automated Testing on Constrained Hardware), which needed to overcome three challenges; the memory constraints, processing constraints, and the timeouts and flaky tests.
In essence, #latch splits test suites into small test instructions which are sent by a managing tester to a managed testee (constrained device).
Because the constrained device receives the test instructions incrementally from the tester, it does not need to maintain the whole test suite in memory.
By using an unconstrained tester to manage the constrained devices and the test suites, #latch is able to overcome the memory constraints.

Our testing framework further allows programmers to indicate the dependencies between related tests.
This dependency information is used by #latch to skip tests that depend on previously failing tests, thus resulting in a faster feedback loop and helping the framework overcome the processing constraints of microcontrollers.
On top of that #latch addresses the issue of timeouts and flaky tests, by including an analysis mode that provides feedback on timeouts and the flakiness of tests.
Finally, the framework uses a novel approach of debugging-like instructions to allows developers to automate manual testing on hardware.

To demonstrate the efficacy and versatility of #latch, we showcased three use-cases, each pertaining to one stratum of the testing pyramid.
The first use-case exemplifies unit testing, and showcases how we implemented a large suite of unit tests in #latch for a WebAssembly virtual machine intended for constrained devices.
This test suite consists of 10,213 unit tests for a virtual machine running on a small ESP32 microcontroller.
The second use-case illustrates integration testing of the instrumentation API in #latch.
The third use-case highlights how the #latch test specification language allows programmers to write debugging-like testing scripts to test more elaborate testing scenarios, that mimic common manual testing tasks.
Benchmarks show that the overhead of the testing framework is within expectation, roughly matching the performance difference between the constrained hardware and using a simulator on a workstation.
Our test-cases shows that the testing framework is expressive, reliable, and reasonably fast, making it suitable to run large test suites on constrained devices.

