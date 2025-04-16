#import "../../lib/class.typ": note
#import "../../lib/util.typ": circled

//#show regex("Latch"): set text(style: "italic")

Many of the challenges that stand in the way of modern debugging on microcontrollers, similarly constrain the testing process.
Extensive testing as part of continuous integration---as is common practice in software development---is rarely setup for embedded software, and certainly not using the actual hardware.
Currently, the only way to apply modern testing bet practices is to use a simulator. //which is not always possible.
However, the abundance and cheap manufacturing cost of microcontrollers, means it should be easy to test on the actual hardware---something that is eminently preferable.

In this chapter, we present a novel testing approach based on remote debuggers that can be used to test microcontroller software on the actual hardware, using both integration and unit tests.
By using the remote debuggers the framework is able to reliably test different scenarios on the actual hardware.
Additionally, the framework can also be used to test the debuggers themselves, which was the original motivation for this chapter.

== Motivation

Software testing for constrained devices, still lags behind standard best practices in testing.
Widespread techniques such as automated regression testing and continuous integration are much less commonly adopted in projects that involve constrained hardware.
This is mainly due to the heavy reliance on physical testing by Internet of Things (IoT) developers.
A 2021 survey on IoT development found that 95\% of the developers rely on manual (physical) testing @makhshari21.
Testing on the physical hardware poses three major challenges, which hinder automation and the adoption of modern testing techniques.
First, the #emph[memory constraints] imposed by the small memory capacity of these devices makes it difficult to run large test suites.
Second, the #emph[processing constraints] of the hardware causes tests to execute slowly, preventing developers from receiving timely feedback.
Third, #emph[timeouts and flaky tests] pose a final challenge.
When executing tests on constrained hardware it is not possible to know when a test has failed or is simply taking too long.

To circumvent the limitations of constrained hardware, simulators are sometimes used for testing IoT systems @bures20.
Their usage makes adopting automated testing and other common testing practices much easier.
Unfortunately, simulators can never fully capture all aspects of real hardware @roska90 @khan11 @espressif-systems23.
Therefore, to fully test their applications, IoT developers have no other option than to test on the real devices.
This is the primary reason why developers still prefer physical testing.
Another reason is the lack of expressiveness when specifying tests in automated testing frameworks.
Testing frameworks with simulators almost exclusively focus on unit testing, and hence provide no good alternative to end-to-end physical testing performed by developers manually @vandervoord15.

In this chapter, we argue that programmers should not be limited by either the constraints of the hardware, or a simulator imposed by the testing framework.
Therefore, our goal is to design and implement a testing framework for automatically running large-scale versatile tests on constrained systems.
This lead to the development of the Latch testing framework (Large-scale Automated Testing on Constrained Hardware).

== Managed testing through debuggers

Latch enables programmers to script and run tests on a workstation, which are executed on the constrained device.
This is made possible by a novel testing approach, we call #emph[managed testing].
In this unique testing approach, the test suite is split into small sequential steps, which are executed by a testee device under the directions of a controlling tester device.
The workstation functions as the tester which maintains full control over the test suite.
Only the program under test---not the entire test suite---will be sent to the constrained device, the testee.
The tester will use instrumentation to manage the testee and instruct it to perform the tests step-by-step.
This means the constrained testee is not required to have any knowledge of the test suite being executed.
This is quite different from traditional remote testing, where the entire test suite is sent to the remote device.
The instrumentation of the testee is powered by debugging-like operations, which allow for traditional whitebox unit testing,
but also enables the developer to write debugging-like scripts
to construct more elaborate testing scenarios that closely mimic manual testing on hardware.

The research question we seek to answer in this paper, is whether the managed testing approach, i.e. splitting tests into sequential steps, is sufficient for executing large-scale tests on microcontrollers.
To answer this question, we will show how managed testing allows Latch to overcome all three major challenges of testing on constrained devices.
The approach can be summarized as follows.
In Latch test suites are split up into smaller test instructions that are sent incrementally to the managed testee, thereby freeing the test suites from the #emph[memory constraints] of the hardware.
This is crucial in enabling large-scale test suites on microcontrollers, such as the large unit testing suite containing 10,213 tests we use to evaluate our approach.
To overcome the #emph[processing constraints], Latch can skip tests that depend on previously failing tests resulting in a faster feedback loop.
Finally, Latch handles #emph[timeouts] automatically, and includes an analysis mode which reports on the #emph[flakiness of tests].

== Challenges of Testing on Constrained Devices<latch:challenges>

This section outlines the challenges preventing large-scale testing on constrained hardware.

=== Memory Constraints

In this article we focus on the ESP32 microcontroller family#note[ESP32 devices can have different amounts of memory,
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
Many other testing frameworks need to deal with this problem, especially JavaScript frameworks @flanagan20 where asynchronous code is prevalent @fard17.
These frameworks time out tests that take too long, unfortunately, the fact that a test timed out does not provide much information for developers, especially when a test includes multiple asynchronous steps.

Second, the non-determinism of the asynchronous communication also contributes to an inherent problem of testing, flaky tests @lam19.
These are tests that can pass or fail for the same version of the code.
Unfortunately, on constrained hardware, many tests have the potential to become flaky due to the inherent non-determinism of these systems.
For example, when testing communication with a remote server small changes in the communication timing with the server could lead to different behavior.

== Managed Testing with Latch by Example}<testing:details>

To overcome the outlined challenges, Latch uses a unique testing approach that consists of declarative test specification language to describe tests, and a novel test framework architecture to run tests.
We refer to our new approach as #emph[managed testing].
In managed testing, the testing framework runs on a local machine and delegates tests step-by-step to one or more external platforms, which are running the software under test.
To facilitate this approach, tests must be easily divisible into sequential steps.
That is why #emph[managed testing] specifies tests in a declarative test specification language, where tests are described as scenarios of incremental steps.
In this section we give a first overview of how managed testing in Latch works through an example, before going into further detail in @testing:language.
The example is chosen as a small primer on how programmers can write traditional unit tests with Latch's test specification language.

== The Example

We define a unit test that verifies the correctness of a function for 32-bit floating point multiplication, shown in @lst:multiplication.
All example programs are written in AssemblyScript \cite{the-assemblyscript-project23}, one of the languages supported by Latch's current microcontroller platform.

\lstinputlisting[language=TypeScript, style=GitHub, caption={
A \texttt{mul} function that multiplies its two arguments, written in 
AssemblyScript.}, label={lst:multiplication}]{multiplication.ts}

%
@lst:unit-test shows a simple test in Latch containing one unit test for the target program in @lst:multiplication.
Latch's declarative test specification language is implemented as an embedded domain specific language (EDSL) in TypeScript \cite{microsoft23}.
Test scenarios are presented in Latch as TypeScript objects that have a title, the path to the program under test, and a list of steps.
These steps make up the test scenario, and will be performed sequentially.
Each step performs a single instruction, and can perform several checks over the result of that instruction.

The example performs only a single instruction, it requests that the #emph[mul] function is invoked with the arguments 6 and 7 (see @line:unit:invoke).
These arguments are first passed to the #emph[WASM.f32] function, to indicate the expected type in #emph[AssemblyScript].
On @line:unit:check, the example specifies that the function returns the number 42.
Usually, the instruction and expectations for a step are described as objects, but Latch provides a handful of functions to construct these objects for common patterns---such as #emph[invoke] and #emph[returns].
This makes test scenarios less verbose, and quicker to write.
%
%
%
We go into further detail on the structure of the #emph[instruction] and #emph[expectation] objects in @testing:language.

\lstinputlisting[language=TypeScript, style=GitHub, caption={A Latch scenario defining a unit test for the \texttt{mul} function.}, label={lst:unit-test}]{unit.test.ts}

%

Similar to other testing frameworks, Latch allows test scenarios to be grouped into test suites.
Crucially, the test suites in Latch have their own set of testee devices, on which they will be executed.
When writing a new test suite in Latch, programmers need to add at least one testee to the suite.
Such testees can range over a wide variety of microcontrollers, as well as local simulator processes.
Each platform may differ in how software is flashed, or communication initialized and performed.
These platform specific concerns are captured by a single TypeScript class, \texttt{Testee}.
Each connection with a constrained device is represented by an object of such a class.
In @lst:suite for instance, we use the Arduino platform to connect to an ESP32 over a USB port, as shown on @line:suite:testee.
Users can add their own platforms by defining new subclasses of the \texttt{Testee} class, which can handle the specific communication requirements of the new platform.

Aside from testees, a test suite also requires test scenarios to execute.
The example multiplication test is added to the test suite on @line:suite:test, before the suite is given to Latch to be run on @line:suite:run.

\lstinputlisting[language=TypeScript, style=GitHub, caption={Latch setup code to run the \texttt{multiplicationTest} on two ESP32 devices.}, label={lst:suite}]{suite.ts}

@lst:suite shows how a test suite is built in Latch through a fluent interface \cite{xie17}, meaning the methods for constructing a test suite can be chained together.
Each test suite in latch is entirely separate from the rest, and therefore contains only its own tests, and platforms to run those tests on.
In the example, two ESP32 devices are configured for the test suite.
This means that when the test suite is started with the \textit{run} function on @line:suite:run, the framework will execute all scenarios in the suite on all configured platforms.
Alternatively, the user can configure Latch to not execute duplicate runs, but instead to split the tests into chunks that are performed in parallel on different devices.
In that case, each test is only run once and the execution time of the whole test suite should be dramatically improved due to the parallelization.

== Running the Example on the Latch Architecture\label{subtesting:overview}

%
%
To run the above testing scenario on a remote constrained device, the test is loaded into Latch on the local unconstrained device, the #emph[tester].
During testing, the #emph[tester] manages one ore more #emph[testees] (constrained devices) to execute tests step-by-step.
@testing:fig:overview gives an overview of all steps and components involved during testing in the Latch framework.
The left-hand side shows the tester, which runs the Latch #emph[interpreter] and #emph[test execution platform].
The interpreter component is responsible for interpreting the test suites, which are written in the #emph[test specification language], while the test execution platform sends each instruction in a test step-by-step to the testee device over the available communication medium.
The test execution platform also parses the result, and handles all other aspects of communication with the testee device.

#figure(caption: [Schematic overview of the interaction between components in Latch during a test.],
  "../placeholder.png")<testing:fig:overview> // figures/overview.pdf

We will go over the steps shown in @testing:fig:overview in the order they are executed by Latch.
Running a test suite is initiated by the interpreter, which takes the test suite specification #circled[1], and schedules the #emph[scenarios] #circled[2].
Since the example test suite in @lst:suite only contains a single test scenario, the multiplication test, with a single step---the scheduling is not relevant in this case.
In real test suites, the order in which tests are run is important, it can help detect failing tests early, or minimize expensive setup steps.
When the interpreter selects a test to be executed, it will instruct the test execution platform #circled[3] to first upload the #emph[software under test], and subsequently sends the instructions of the scenario to the #emph[test instrumentation platform] #circled[4].
In the case of our example, Latch compiles the #emph[multiplication.ts] file and uploads it to the ESP32 device that is connected to the USB port.
Once this step is completed, Latch sends the invoke instruction to the testee, which will execute the #emph[mul] function with the supplied arguments.

Aside from forwarding instructions to the test instrumentation platform, the tester can also perform custom actions to control the #emph[environment] #circled[5].
For instance, these actions can control hardware peripherals, such as sensors and buttons, that interact with the constrained testee #circled[6] during the test.

@lst:action shows how a step might send an MQTT message to a server as an example of an action that acts on the environment.
Such a step, could be useful when testing an IoT application that relies on MQTT messages.
The microcontroller can connect to an actual testing server, and via custom actions Latch can test if the device responds correctly.

\lstinputlisting[language=TypeScript, style=GitHub, caption={An example Latch step, which performs a custom action that sends an MQTT message to a server.}, label={lst:action}]{action.ts}

In contrast with @lst:unit-test, this example constructs the instruction object explicitly, rather than calling a function such as #emph[invoke].
There are two types of instructions, they can be either a #emph[request] to the test instrumentation platform, such as the invoking of a function, or a custom #emph[action].
In this example we construct a simple action that takes no arguments and returns nothing.
Actions allow tests to execute TypeScript functions as steps in the test scenario, in this case the function simply publishes a test message to the MQTT server (@line:action:publish).
We go into further detail on the types of actions and requests in @testing:language.

As tests are performed, the software under test is controlled by the test instrumentation platform in accordance with the #emph[request] instructions send by the test execution platform #circled[7].
In other words, the test instrumentation platform will receive the command from the tester to execute the #emph[mul] function, and make the software under test invoke it.
The instrumentation of the software under tests, allows the test instrumentation platform to return any generated output to the test execution platform #circled[8].
Whenever the tester sends an instruction to the testee, Latch will wait until the testee returns a result for the instruction.
When working with constrained devices, communication channels may be slow or fragment messages.
Latch takes care of these aspects automatically.

As part of a step, the scenario description can specify a number of assertions over the returned results.
In the example, we require that the #emph[mul] function returns 42, as specified on @line:unit:check of @lst:unit-test.
Once the expected output is received by the tester, Latch checks all assertions against it.
These assertions are verified by the interpreter #circled[9], before the result of the step is shown in the #emph[user interface] as either passed, failed, or timed out #circled[10].
For example, after the test instrumentation platform returns the result of the #emph[mul] function, Latch will check if it indeed equals 42 and report the result.

A step can have three kinds of results; either it timed out, or all its assertions passed, or one of more assertions failed.
In other words, step is marked as failing when at least one assertion fails.
If no assertions were included in the step, Latch will not wait for output, and immediately report the action as passing.
When the testee fails to return a result after a preconfigured period, it is marked as timed out.
Similarly, a scenario is marked as failing when at least one step fails.
When a step fails, the test execution platform will---by default---continue the scenario without retrying the step.
This is useful when the steps in the scenario are independent of each other to gather more complete feedback.
Otherwise, developers can configure Latch to abort a scenario after the first failure.

The results of each step are reported while the test suite is executing.
When the entire suite has run, Latch will give an overview of all the results for both the steps and the test scenarios.
This overview includes, the number of passing/failing tests, the number of passing/failing steps, the number of steps that timed out, and the overall time it took to run the suite.
In addition, the developer can configure Latch to report on the flakiness of the test by executing the tests multiple times.
This way, Latch can compare the results of different runs to give developers more insight into the flakiness of their test suites.
As @testing:fig:overview shows under the user interface component, the results in this case will be reported for each run separately.
Whenever the runs give different results, the scenario is marked as flaky and the failure rate is reported.

== From Small Examples Towards Large-scale Test

The running example in this section illustrates Latch's basic testing features.
In particular, how Latch divides tests into small steps that are executed sequentially.
This means that the size of the test suite is no longer constrained by the memory size of the embedded device.
While the example here only includes a single step, one can easily imagine test cases that require many more steps.
Let us suppose we stay within the realm of unit testing a mathematical framework.
We can imagine a more complicated mathematical operation than multiplication that requires thorough testing, for instance a function #emph[eig] for calculating the eigenvalues of a matrix.
In this case the test scenario would include many steps, that each invokes the #emph[eig] function with a different matrix.
This is similar to the large-scale unit testing suite we will discuss in @testing:usecases, and those run as part of the evaluation in @testing:performance.

@testing:usecases discusses realistic examples for each layer of the testing pyramid; unit testing, integration testing, and end-to-end testing.
The examples will illustrate how using small steps powered by debugging-like operations, uniquely enables Latch to test remote debuggers and automate IoT scenarios and manual hardware tests.
For example, it becomes much easier to test whether a microcontroller successfully receives asynchronous messages from a remote server, and handles these message correctly.
The test can set breakpoints in the code that is expected to be executed when a message arrives.
Before sending the message, the test can pause the execution at the exact place in the program, it wants the message to be received.
The Latch instructions allows users to write these kinds of testing scenarios in a convenient way.
Moreover, the increased control over the program, makes the test scenarios much easier to repeat reliably under the same conditions.

== The Latch Test Specification Language<testing:language>

