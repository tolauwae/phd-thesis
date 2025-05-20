#import "../../lib/class.typ": lemma, proofsketch
#import "../../lib/util.typ": snippet
#import "../semantics/arrows.typ": *
#import "figures/semantics.typ": dbg, msg, sync

= Addendum to out-of-place debugging

This appendix is an addendum to @chapter:oop.

== Auxiliary out-of-place lemma<app:oop>

//#lemma("Invoke uniqueness")[
//]<theorem:uniqueness>

For the soundness of the stateful out-of-place debugger presented in @chapter:oop, it is important that any remote action invocation follows the same three steps, first backward state synchronization with either the $italic("step-transfer")$ or $italic("run-transfer")$ steps, second the execution of the action on the server by the $italic("invoke")$ step, and third the $italic("sync")$ step to synchronize the state of the server with the client.
The following lemma states that indeed any $italic("sync")$ step is proceeded by the transfer and invoke steps.

To improve legibility, we write a step in the debugger that uses a specific evaluation rule with the name of the evaluation rule above the arrow, for instance $attach(dbgarrow, t: italic("sync"))$.

#lemma("Invoke uniqueness", numbering: "A-1")[
  $ forall dbg: dbg_"start" multi(dbgarrow) dbg' attach(dbgarrow, t: italic("sync")) dbg \ arrow.r.double.long \ exists dbg'', dbg''': dbg'' attach(dbgarrow, t: italic("step")) dbg''' attach(dbgarrow, t: italic("invoke")) dbg' \ and (italic("step") = italic("step-transfer") or italic("step") = italic("run-transfer")) $
]<lemma:order>

#proofsketch[
We can proof this lemma by contradiction. Assume first that the preceding step from $dbg'''$ to $dbg'$ is not an $italic("invoke")$ step. However, since the $italic("sync")$ step is the last step in the sequence, $dbg'$ must contain a $sync(s comma v)$ message in the message box of the client. This is only possible after an $italic("invoke")$ step. Now, assume that $italic("step")$ is not a $italic("step-transfer")$ or a $italic("run-transfer")$ step. However, since we already proved that the next step is $italic("invoke")$, we know that the message box in the server must contain an _invoke_ message in $dbg'''$, which is not possible with any other rules.
]

== Debugging concurrency issues<subsec:concurrency>

Apart from the device related bugs discussed in @oop:debugging-common-bug-issues,
software development issues are common in IoT applications @makhshari21:iot-bugs.
Within this type, a common root cause is concurrency faults @makhshari21:iot-bugs.
@app:concurrency shows the implementation of a smart lamp application in AssemblyScript.
//In @fig:concurrency, we provide an extract of an AssemblyScript application
The code allows users to control the brightness of an LED with MQTT messages or two hardware buttons.
//In @fig:concurrency we show an extract of this application written in AssemblyScript.
//The full code can be found in @app:concurrency.
The application listens for messages on topics, #emph[increase] and #emph[decrease] (lines 55 - 58).
For each message, the code increases or decreases the brightness of the LED by five percent, respectively.
Instead of changing the brightness abruptly, the code gradually changes the brightness.
For this reason, the callback function does not directly change the LED brightness, but it changes the variable `delta` to record the requested change.
The function `updateBrightness` called in the main application loop changes the actual brightness gradually.
Every time it is called, it changes the brightness by one percent in the direction dictated by the sign of `delta`.
After doing this, the absolute value of `delta` is lowered by one.
In this way, the application only needs to check the value of the delta variable and change the brightness whenever it does not equal zero (line 64).

#strong[The Bug.] When testing this program with a real hardware setup, the developer notices that the brightness changes irregularly.
//With a regular remote debugger, developer could learn that some messages are ignored.
//On further inspection with existing debugging facilities such as remote debugging or regular out-of-place debugging, the developer can learn that some messages are ignored.
When sending two messages to the #emph[increase] topic, the LED increases its intensity by only 5% instead of 10%.
The reason is that the second message overwrites the value of the `delta` variable before the `updateBrightness` function updates the LED.
//\egb{it does not explain at all how the remote debugger can know the root cause, or if it can}
//\egb{is this next paragraph trying to explain why with a regular remote debugger one cannot find out the root cause of the bug described? If so, it is completely not clear}
Such concurrency bugs are often time sensitive, and do not always manifest @mcdowell89:debugging.
In our example the bug only manifests when sending two MQTT messages rapidly.
This made finding the exact conditions for the bug very difficult. //% and this becomes harder as the program becomes more complex.
Moreover, the effects of the bug can happen long after the root cause @perscheid17:studying, i.e. when the main loop updates the brightness.

#snippet("app:concurrency",
    columns: 2,
    [The full code of the example application illustrating a concurrency problem in Internet of Things.],
    (```ts
import * as wd from "warduino";

const LED: i32 = 10;
const MAX_BRIGHTNESS: i32 = 255;
const UP_BUTTON: i32 = 37;
const DOWN_BUTTON: i32 = 39;
const CHANNEL: i32 = 0;
const SSID = "local-network";
const PASSWORD = "network-password";
const CLIENT_ID = "random-mqtt-client-id";

let brightness: i32 = 0;
let delta: i32 = 0;

function until_connected(connect: () => void,
                         connected: () => boolean): void {
    while (!connected()) {
        wd.delay(1000);
        connect();}}

function check_connection(): void {
    until_connected(
        () => { wd.mqtt_connect(CLIENT_ID);
                wd.mqtt_loop(); },
        () => { return wd.mqtt_connected(); });
}
```,))

#strong[Bugfixing with a Remote Debugger.] As mentioned before, stepping through code with asynchronous callbacks using current state of the art remote debuggers is very difficult.
The developer has no control over when the asynchronous callbacks are called.
This makes it difficult to reproduce the exact conditions in which the bug manifest.
In turn, this increases the times a developer needs to manually step through the application before reproducing the error, drastically complicating debugging.
Moreover, the developer needs to keep track of all the steps taken and remember these steps carefully for when the bug manifest later, and a new debugging session is needed.
Finally, stepping through the code is relatively slow due to network latency between the developer's machine and the remote device.

#strong[Bugfixing with _Edward_.] _Edward_ can help debugging these concurrency bugs thanks to its event scheduling and time-traveling debugging features.
By using EDWARD, developers can inspect the generated events and schedule their execution one after another (as the developer suspects that this is when the bug manifests).
When they step through the code, they can visually inspect the brightness of the LED and observe that the bug has indeed manifested.
If the root cause was not discovered during the initial debugging session the developer can easily step back in time and go through the code as many times as needed.
During this time-traveling debugging session they can then notice that when receiving two messages in a row, the second may overwrite the `delta` parameter set by the first message before it was processed by the main loop, revealing the cause of the bug.
Lines 59 and 61 should increase (and decrease) the value of `delta` instead of overwriting it.

#snippet("app:concurrency:continued",
    columns: 2,
    offset: 26,
    [@app:concurrency continued.],
    (```ts
function init(): void {
    wd.analogSetup(CHANNEL, 5000, 12);
    wd.analogAttach(LED, CHANNEL);

    // Connect to Wi-Fi
    until_connected(
      () => { wd.wifi_connect(SSID, PASSWORD); },
      () => { return wd.wifi_status() == wd.WL_CONNECTED; });
    let message = "Connected to wifi network with ip: ";
    wd.print(message.concat(wd.wifi_localip()));

    // Connect to MQTT broker
    wd.mqtt_init("192.168.0.24", 1883);
    check_connection();}

function updateBrightness(): void {
    brightness += delta;
    if (brightness < 0) {
        brightness = 0;
    }
    if (brightness > MAX_BRIGHTNESS) {
        brightness = MAX_BRIGHTNESS;
    }
    wd.analogWrite(CHANNEL, brightness, MAX_BRIGHTNESS);
    delta = 0;
}

export function main(): void {
    init();

    // Subscribe to MQTT topics and turn on LED
    wd.mqtt_subscribe("increase",
        (topic: string, payload: string) => {delta = 5});
    wd.mqtt_subscribe("decrease",
        (topic: string, payload: string) => {delta = -5});
    while (true) {
        check_connection();
        if (delta !== 0) updateBrightness();}}
```,))

// \begin{figure}
//\begin{center}
//		\includegraphics[width=1\columnwidth]{figures/remote_snapshot_overhead}
//                \caption{Network communication overhead for full snapshotting.
//                         Note that the y-axis starts at 129kB.}
//		\label{fig:remote_snapshot_overhead}
//\end{center}
//\end{figure}

