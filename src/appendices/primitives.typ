#import "../../lib/class.typ": note
#import "../../lib/util.typ": lineWidth

#set figure(placement: top)
#set rect(inset: 0mm)
#set table.hline(stroke: lineWidth)

= Built-in Modules<primitives>

In this appendix, we give an overview of the WARDuino VM's built-in modules, which provide primitives for controlling peripheral hardware and other essential aspects of IoT applications.
The examples are written in WebAssembly's textual format.

#text(style: "normal", [This appendix is taken from the WARDuino overview paper @lauwaerts24:warduino, and is meant as a quick reference for @chapter:remote. However, the exact interfaces of the primitives are subject to changes, and many additional modules have been added since. The most up-to-date overview can be found on the official WARDuino #link("https://topllab.github.io/WARDuino/reference/primitives.html")[documentation website], which at the time of writing is still primarily maintained by myself.])

== Input-Output Pins

A first module exposes the hardware pins of the microcontroller.
In a microcontroller each pin is connected through a so-called port.
A port controls the properties of a pin, such as its mode.
The mode of a pin determines if it can be used for reading or writing, it is important to make sure the mode of the pin is always set correctly.

Arduino abstracts away the division between ports and pins through a simple API.
This API allows us to set the pin mode, read the pin or write a value to it.
In WARDuino we defined a native implementation of these functions in an IO module.
The signatures of the functions in our IO module are listed on the right side of figure @fig.blink.
The first function, $mono("pin_mode")$ returns no values, but takes two $mono("i32")$#note[32 bit integers] arguments; the first argument identifies the pin and the second the mode, either $sans("input")$, $sans("output")$, or $sans("input_pullup")$.
The second function $mono("digital_write")$ has no return value and takes two arguments.
Again, the first argument specifies the pin, and this time the second argument provides the value to be written to the digital pin, either $sans("high")$ or $sans("low")$.
Finally, the $mono("digital_read")$ function takes a digital pin as argument, and returns the value read from the specified pin, either $sans("high")$ or $sans("low")$, as an $mono("i32")$ value.

#set table(stroke: none, fill: rgb("#dce0e8"))
#show table.cell: set text(size: 0.8em)

#figure(
  caption: [API and example of the WARDuino digital input-output.])[
#grid(
        columns: 2,     // 2 means 2 auto-sized columns
        gutter: 1mm,    // space between columns
        [
```wast
(module
(; type declarations ;)
(type $int->int->vd (func (param i32) (param i32) (result)))
(type $int->vd      (func (param i32)             (result)))
(type $vd->vd       (func (param)                 (result)))
(; imports ;)
(import "env" "pin_mode"      (func $pin_mode  (type $int->int->vd)))
(import "env" "digital_write" (func $dig_write (type $int->int->vd)))
(import "env" "delay"         (func $delay (type $int->vd)))
; export $blink as the main entry point of the program ;)
(export "main" (func $blink))
(; blink function ;)
(func $blink (type $vd->vd)
  (call $pin_mode (i32.const 16) (i32.const 1)) (; write mode ;)
  (loop $begin
    (call $dig_write (i32.const 16) (i32.const 0)) (; off ;)
    (call $delay (i32.const 5000)) (; sleep 5s ;)
    (call $dig_write (i32.const 16) (i32.const 1)) (; on ;)
    (call $delay (i32.const 5000)) (; sleep 5s ;)
    (br $begin)))) (; jump back to start of $begin loop ;)
```], rect(inset: 0mm, table(columns: 2,  align: (left, right),
				[#strong("pinMode")\(pin,mode\)], $"int" times "int" arrow.r ()$,
				[#strong("digitalWrite")\(pin, value\)], $"int" times "int" arrow.r ()$,
				[#strong("digitalRead")\(pin\)], $"int" arrow.r "int"$
)))]<fig.blink>

#let text = [
#let type = [@fig.blink:3]
#let void = [@fig.blink:5]
#let importStart = [@fig.blink:7]
#let importEnd = [@fig.blink:9]
#let export = [@fig.blink:11]
#let function = [@fig.blink:13]
#let loop = [@fig.blink:15]
#let end = [@fig.blink:20]

While WebAssembly is primarily a bytecode format, it can be represented in a human-readable text format.
The leftside of figure~@fig.blink shows a WARDuino program that blinks an LED light in the WebAssembly text format (WAT).
The program is defined as a module with four major sections.
The first part, lines #type to #void, declares the types used throughout the program.
WebAssembly byte code uses numerical indices to refer to other entities, such as function arguments, local variables, functions and so on.
In the text format we can assign these entities a human-readable name prefixed with a dollar sign.
For instance the first type gets the name $mono("$int->int->vd")$ on #type.
The name of the type is followed by the description of the type, which starts with the $mono("func")$ keyword signifying it is a function type.
Next, all the parameters are listed,  each with a separate $mono("param")$ keyword followed by the parameter type.
A parameter can only have a basic numeric type.
For the $mono("$int->int->vd")$, there are two 32-bit integer parameters ($mono("i32")$).
A function which takes no arguments ($mono("$vd->vd")$), has only one $mono("param")$ keyword without a type, as is the case on #void.
After the parameters, the base numeric type of the return value is specified in a similar way.
The $mono("result")$ keyword is followed by a basic numeric type, or by no type to indicate void (abbreviated $mono("vd")$), as is the case for all the types in the example.

The following section of the program imports the used WARDuino primitives.
Specifically, on lines #importStart to #importEnd, the $mono("pin_mode")$, $mono("digital_write")$, and $mono("delay")$ primitives are imported from the $mono("env")$ module.
Each import statement starts with the module name and the name of the entity within that module to be imported.
This is followed by a declaration of the imported entity, which can be either a table, linear memory, a function, or a global variable.
In this example, we only import functions.
Thus, each description consists of the $mono("func")$ keyword followed by an identifier referring to the type of the imported function.

Next, the program exports the function $mono("$blink")$ under the name "main" on #export.
When executing a WebAssembly module with WARDuino, our VM will automatically look for an exported function with the name ``main''.
It considers this function the entry point of the program, and will automatically start executing it.

The $mono("$blink")$ function is defined on lines #function to #end, it starts by setting the mode of the LED pin#footnote[In the example, we assume the LED is attached to pin 16.] to 1 ($sans("output")$).
This is done by calling the $mono("pin_mode")$ primitive imported under the name $mono("$pin_mode")$.
WebAssembly allows two different function call syntaxes, "folded" and "unfolded".
In this case we used the "folded syntax" to make the call.
We placed the arguments to $mono("$pin_mode")$ in the brackets of the $mono("call")$ instead of placing these arguments on the stack first as one would usually do in a stack based language#footnote[The unfolded form is: $mono("(i32.const 16) (i32.const 1) (call $pin_mode)")$].
The two notations are equivalent and we will use them interchangeably.
After this, the function continuously blinks the LED every 10 seconds in an infinite loop, starting at #loop.
In WebAssembly a $mono("loop")$ construct has an identifier, in this case $mono("$begin")$ and a body, everything after the identifier.
Contrary to other languages loops do not automatically repeat, we must explicitly jump (branch) back to their start.
This is done at #end with $mono("(br $begin)")$.
Note that we can only branch to identifiers of blocks we are in.
If we do not branch back to the start of a $mono("loop")$, its body is executed only once.

The first instruction in the loop writes zero to the LED pin, turning the LED off.
Next, the $mono("i32.const")$ instruction places the value 5000 on the stack.
The call to our $mono("$delay")$ primitive on the next line consumes this value and waits that number of milliseconds before returning.
After the microcontroller has waited for five seconds (5000 ms), it turns the LED back on with the $mono("$dig_write")$ primitive.
Then it waits for another five seconds before starting again at the top of the loop (#loop).

For brevity, we will leave out the type declarations in future examples and indicate types by using a corresponding name, such as $mono("$int->int->vd")$.
Additionally, we will also omit the export of the main function, instead we assign the entry point the identifier $mono("$main")$.
]

== Pulse Width Modulation and Analog Reads

A pulse width modulator (PWM) allows programmers to send out a square wave to one of the output pins without having to write a busy loop.
Example waves are shown in figure @fig.pwm with duty cycles of 90\%, 50\% and 20\%.
The duty cycle is the configurable fraction of time the wave is high.
PWM is prototypically used to dim an LED, sending it a square wave makes it flash very fast, faster than perceivable by the eye.
The higher the duty cycle, the brighter the LED appears.

To control the modulator we provide three API functions: $mono("setPinFrequency")$, $mono("analogWrite")$, and $mono("analogRead")$.
The interface for each of these functions is shown in figure~@fig.pwm.
With $mono("setPinFrequency")$ we can modify the frequency of a certain pin.
For example when the default frequency on pin $mono("D1")$ is 31250 Hz a call to  $mono("(setPinFrequency D1 8)")$ will change the frequency on the pin to 31250/8 Hz.
Setting the duty cycle is done with $mono("analogWrite")$, an argument value of 0 corresponds to a duty cycle of 0\%, the value 255 represents a duty cycle of 100\%.
Finally, the $mono("analogRead")$ function measures the voltage on a certain pin and returns it as an integral value.

#figure(
  caption: [#emph[Left]: Example of the PWM module in WARDuino. #emph[Top right]: PWM API of WARDuino. #emph[Bottom right]: Graphs of output voltages of over time for duty cycles set to 90%, 50% and 20%, the average output voltage is shown as a dashed line.],
    grid(
        columns: 2,     // 2 means 2 auto-sized columns
        gutter: 1mm,    // space between columns
        [
```wast
(module
  (; fade function ;)
  (func $main (type $vd->vd)
    (local $i i32) (; loop iterator ;)
    (call $pin_mode (i32.const 16) (i32.const 1))
    (loop $infinite
      (local.set $i (i32.const 0))
      (loop $increment
        (call $analog_write (i32.const 16) (local.get $i))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (i32.const 5)
        (call $delay)
        (br_if $increment       (; jump to line 8 if i<255 ;)
               (i32.lt_s (get_local $i) (i32.const 255))))
      (loop $decrement
        (call $analog_write (i32.const 16) (local.get $i))
        (local.set $i (i32.sub (local.get $i) (i32.const 1)))
        (i32.const 5)
        (call $delay)
        (br_if $decrement        (; jump to line 15 if i>0 ;)
               (i32.gt_s (local.get $i) (i32.const 0))))
      (br $infinite))))
```], [ 
        // TODO
//\begin{mdframed}[style=api]
//            $$
//	\begin{array}{ l l }
//		\textbf{setPinFrequency}(pin,divider) & int \times      int arrow.r () \\
//		\textbf{analogWrite}(pin, value)      & int \times      int arrow.r () \\
//		\textbf{analogRead}(pin)              & int arrow.r int                \\
//	\end{array}
//            $$
//\end{mdframed}
//        \centering
//\newcommand{\pwmgraph}[1]{%
//	\begin{tikzpicture}[>=latex,scale=0.75]
//		\foreach \ini [evaluate=\ini as \inieval using \ini] in {0,...,7} {%
//
//				\fill[black!20!white] (\inieval,0) rectangle (\inieval+#1,1);
//				\draw[thick,black] (\inieval+0,0) -- ++(0,1) -| (\inieval+#1,0.01) -- (\inieval+1,0.01);
//			};
//		\draw[thick,dashed] (0,#1) -- (8.1,#1);
//		\draw[thin] [->] (0,0) -- ++(8.5,0) node [right] {$t$};
//		\draw[thin] [->] (0,0) -- ++(0,1.5) node [left] {$V$};
//		\foreach \x in {0,1,...,7} {
//				\draw[thin] (\x,-0.1) -- (\x,0.1);
//			};
//	\end{tikzpicture}}
//
//
//\pwmgraph{0.9}
//
//\pwmgraph{0.5}
//
//\pwmgraph{0.2}
]))<fig.pwm>

// Fade example
#let nnn = [
#let loop = [@fig.pwm:6]
#let init = [@fig.pwm:7]
#let end = [@fig.pwm:22]

The left side of figure~@fig.pwm shows how we can use the PWM primitives to add a slow fade effect to a blinking led.
Analogous to the code example for letting an LED light blink, the WebAssembly module contains a main function that takes no arguments and returns no values, but does contain one local variable $mono("$i")$.
Local variables in WebAssembly are always defined at the start of the function alongside the arguments and return values.
The main function first sets the pin mode of the LED pin to output.
After the correct mode is set,  the code lets the LED fade on and off continuously in an infinite loop, starting on #loop.
The body of our outer loop first initializes the variable $mono("$i")$ to zero on #init.
Then, a first inner loop increments the brightness of the LED from 0 to the maximum value 255 in steps of one, by writing the value of $mono("$i")$ to the pin with the $mono("analog_write")$ primitive.
Each iteration of the loop waits five milliseconds before continuing.
At the end of this inner loop, the $mono("br_if")$ instruction jumps back to the start of the loop if the loop iterator $mono("$i")$ is less than 255.
After the first loop when $mono("$i")$ equals 255, a second inner loop decrements the brightness of the LED light in the same way.
Once $mono("$i")$ hits zero, we have reached the endremote the cycle and the unconditional branch instruction $mono("(br $infinite)")$, at #end, jumps back to the start of the main loop.
]

== Serial Peripheral Interface<sec:serial-peripheral-interface>

The serial peripheral interface (SPI) is a bus protocol commonly used to communicate between a microcontroller and peripheral devices such as sensors, SD-cards, displays, and shift registers.
The SPI communication protocol can be implemented in hardware or in software.
When using the hardware implementation the programmer must use the dedicated SPI pins on the microcontroller.
In software, the programmer is free to use any of the available input-output pins.
Software implementations are however, significantly slower than making use of the hardware implementation.

#figure(
  caption: [API of the WARDuino SPI module],
  rect(inset: 0mm, table(columns: 2, 
    [spiBegin()                    ], $ ()  arrow.r ()           $,
    [spiBitOrder(bitorder)         ], $ "int" arrow.r ()           $,
    [spiClockDivider(divider)      ], $ "int" arrow.r ()           $,
    [spiDataMode(mode)             ], $ "int" arrow.r ()           $,
    [spiTransfer8(data)            ], $ "int" arrow.r ()           $,
    [spiTransfer16(data)           ], $ "int" arrow.r ()           $,
    [spiBulkTransfer8(count,data)  ], $ "int" times "int" arrow.r ()$,
    [spiBulkTransfer16(count,data) ], $ "int" times "int" arrow.r ()$,
    [spiEnd()                      ], $ () arrow.r ()            $
)))<fig.SPI>

WARDuino's primitives governing access to the hardware SPI bus are shown in figure~@fig.SPI.
The functions $mono("spiClockDivider")$, $mono("spi\-Bit\-Order")$, $mono("spiDataMode")$ are configuration functions to specify how data will be transferred.
Before actually using the SPI bus the programmer first needs to call the $mono("spiBegin")$ which initializes the SPI module.
Once initialised, the programmer can start transferring data to the peripheral device by using one of the transfer functions.
We included two kinds of transfer functions one for 8-bit transfers and one for 16-bit transfers.
For both variants we included a bulk mode which sends the same data a specific number of times.
The inclusion of the bulk operations can improve the performance of a display driver greatly.

We have used the SPI module to implement a display driver in WARDuino.
We leave out the specifics of that implementation here, not only for brevity, but because the code is originally written in C, rather than directly in WebAssembly like our other examples.
We refer any interested reader to the first paper on WARDuino @gurdeep19:warduino.

== Serial Port Communication<remote:serial-port-communication>

#figure(
  caption: [API and example code of the Serial module in WARDuino.],
    grid(
        columns: 2,     // 2 means 2 auto-sized columns
        gutter: 1mm,    // space between columns
        [
```wast
(module
  (memory $text 1)           (; Initialize linear memory to one page ;)
  (data (i32.const 0) "WARDuino") (; place text in memory at offset 0;)

  (func $main (type $vd->vd)
    (i32.const 0) (; start index of string ;)
    (i32.const 8) (; string length ;)
    (call $print)))
```], rect(inset: 0mm, table(columns: 3,
            "", $italic("string")$, "",
            [#strong[print]\(string\)    ], $"int" times "int"$, $arrow.r ()$,
	        [#strong[print_int]\(value\) ], $"i32"$, $arrow.r ()$
))))<fig.serial>

Microcontrollers typically have at least one serial port.
This port is used for flashing code to a microcontroller.
Developers also regularly use this port for printing debug or log messages to a computer during development.
The Arduino's $mono("Serial")$ library is therefore indispensable for many programmers.
We use it to add two print primitives to WARDuino to print numeric values and strings to the serial port.
That latter feature is not as straightforward as it may seem because WebAssembly only supports basic numeric types, and not strings.

// Representing strings

Fortunately, we can represent strings in WebAssembly by storing them as UTF-8 encoded bytes in WebAssembly's linear memory.
Memory in WebAssembly is called linear memory because it is simply one long continuous buffer that can grow in increments of 64 kiB pages.
Currently, WebAssembly only supports one memory per module, but memories are importable.
Saving strings in memory is not enough, we also need a way to work with them, specifically, we need a way of referring to a string.
To pass a string as an argument to a function, it can be represented as a tuple containing its offset in WebAssembly memory together with its length.
This is illustrated in figure~@fig.serial, which shows the interface of our two serial bus primitives.
One primitive simply prints a numeric value, the other prints a string from linear memory.
The example program on the left side of the figure shows how we can print a string to the serial port in WebAssembly.
The code starts on line 2 by declaring a WebAssembly linear memory with the label $mono("$text")$, followed by an initial size of one memory page (64 kiB).
This is more than enough space to store the simple message in the data section on the next line.
This section is similar to the data sections found in native executable files.
The string is written at offset 0 in linear memory at initialization time.
Not much more is needed to print the text in memory to the serial port, the main function simply places the indices and length of the string on the stack and calls the print primitive.

== Wireless Networks<sec:wireless-networks>

Applications for embedded devices often communicate with other devices.
To accommodate this, many microcontrollers come with a Wi-Fi chip to connect to a wireless network.
We have extended WARDuino with the necessary primitives for connecting to a wireless network.
Because we use Arduino to implement these primitives in WARDuino, it makes sense to mirror the underlying Arduino interfaces for connecting.
This way we do not unnecessarily introduce entirely new interfaces.
Unsurprisingly, the Arduino functions use strings to specify parameters such as the network SSID and password.
We represent those strings as pairs of integers as discussed in the section on the serial port communication module.

// Example: connecting to Wi-Fi (in WebAssembly)

#figure(
  caption: [API and example code of the Wi-Fi module in WARDuino. $"int"^2 = "int" times "int"$],
    grid(
        columns: 2,     // 2 means 2 auto-sized columns
        gutter: 1mm,    // space between columns
        [
```wast
(module
  (; memory ;)
  (memory $credentials 1)
  (data (i32.const 0) "SSID")
  (data (i32.const 6) "P4S5W0RD")

  (; connect function ;)
  (func $main (type $vd->vd)
    (loop $until_connected
      (i32.const 0) (; ssid start address ;)
      (i32.const 4) (; ssid string length ;)
      (i32.const 6) (; password start address ;)
      (i32.const 8) (; password string length ;)
      (call $connect)
      (i32.ne (call $status) (i32.const 3))  (; true if failed ;)
      (br_if $until_connected))
    (i32.const 10)  (; arg1 of print: buffer offset,      ---  ;)
    (i32.const 10)  (; arg1 of localip: buffer offset,       | ;)
    (i32.const 20)  (; arg2 of localip: buffer length        | ;)
    (call $localip) (; return value becomes arg2 of print ---  ;)
    (call $print)
  ))
```], 
rect(inset: 0mm, table(
  columns: 3,
  align: (left, center, right),
  [#strong[connect]], $"ssid"_{"start"}, "ssid"_{"length"}$, $"int"^4 & arrow.r ()$,
   [], $"pass"_{"start"}, "pass"_{"length"}$, [],
  [#strong[status]\(\)], [], $() arrow.r "int"$,
  [#strong[localip]\($"ip"_{"start"}$, $"ip"_{"max_length"}$\)], [], $"int"^2 & arrow.r "int"$
))))<fig.wifi>

#[
#let memoryStart = [@fig.wifi:3]
#let memoryEnd = [@fig.wifi:5]
#let loopStart = [@fig.wifi:9]
#let loopEnd = [@fig.wifi:16]
#let print = [@fig.wifi:21]

Figure~@fig.wifi shows the interfaces of the wireless networking primitives on the right.
Because these primitives take strings as arguments, the number of integer parameters can get relatively high.
To keep the description of the API compact, we abbreviate long chains of the same type with the power notation.
For instance, the $mono("connect")$ primitive that connects to a Wi-Fi network has type $"int"^4 arrow.r ()$. This notation represents four integer arguments, or two strings in this case, and no return value.
The first string argument contains the SSID of the network to connect to, the second argument contains the password used to authenticate.
The $mono("status")$ primitive returns an integer indicating the status of the network connection.
If there is an active connection it will return~3.
Our $mono("localip")$ primitive retrieves the IP address of the device.
This primitive takes two integer arguments representing a memory slice where a string can be stored.
Because WebAssembly only supports one memory per module, the returned string needs to be saved in the memory defined by the module calling $mono("localip")$.
To know where in this memory the primitive can safely write its string return value, we require a memory slice as argument.
Once the IP address is written to the memory slice, $mono("localip")$ returns the size of string it has written.
This methodology is comparable to how C functions take a character buffer as an argument to write their result to.

A small piece of WebAssembly code that connects to a Wi-Fi network and prints the IP address is shown on the left of figure~@fig.wifi.
The code first declares a memory of one page (64 kiB) and writes the network SSID and password to it (lines 3-5).
The main function starts by connecting to the Wi-Fi network in the $mono("$until_connected")$ loop (lines 9-16).
At the start of the loop, $mono("const")$-instructions place the offsets and lengths of the two strings on the stack.
Then we call the $mono("connect")$ primitive, which tries to connect to the given network.
The call blocks execution until it finishes or fails.
We check whether a connection was successfully established by verifying that the $mono("status")$ primitive returns 3 (connected).
If not, the $mono("br_if")$ instruction on line 16 jumps back to the start of the loop, and the program retries connecting to the network.
Once connected, we print the IP address of the device by combining $mono("localip")$ and $mono("print")$.
The $mono("localip")$ primitive returns the length of the string it wrote to the memory slice it received as argument, zero indicates a failure to retrieve the local IP address.
Because WebAssembly is a stack based language, we can push the start index of the response buffer of $mono("localip")$ to the stack before pushing the arguments to $mono("localip")$.
When $mono("localip")$ returns, it will have popped its two arguments off the stack and pushed the length of the IP address back to the stack.
Now, the stack holds the right arguments for the $mono("print")$ primitive once execution gets to line 21.
If the print primitive gets a zero length argument it will simply not print anything, so we do not need to check in WebAssembly whether an IP address was actually retrieved.
]

== Hypertext Transfer Protocol<subsec:http>

The Hypertext Transfer Protocol (HTTP) @fielding14:hypertext drives the modern web.
Developers can use HTTP to access the entire web from a WebAssembly program running on a microcontroller with WARDuino.
To keep the module small, we only add the most fundamental HTTP requests, GET, PUT, POST. //%$sans("get")$, $sans("put")$, $sans("post")$.
As before, we give the interface of the primitives in figure @fig:http.
String arguments are given as pairs of integers representing memory slices.
If the primitive returns a string, an extra pair of integers, pointing to a free slice of memory, is added to the arguments.

#figure(
  caption: [API and example code of the HTTP module in WARDuino.],
    grid(
        columns: 2,     // 2 means 2 auto-sized columns
        gutter: 1mm,    // space between columns
        [
```wast
(module
  (; Memory ;)
  (memory $url 1)
  (data (i32.const 0)
        "http://www.arduino.cc/asciilogo.txt")

  (func $main (type $vd->vd)
    (loop $loop
      (i32.const 40)  (; response_start for print ;)
      (i32.const 0)   (; url_start ;)
      (i32.const 35)  (; url_length ;)
      (i32.const 40)  (; response_start ;)
      (i32.const 200) (; response_length ;)
      (call $get)
      (call $print)
      (i32.const 1000)
      (call $delay)
      (br $loop))))
```], rect(inset: 0mm, table(columns: 4, 
            align: (left, left, center, right),
			[#strong[get]\(], $"url"_{"start"}, "url"_{"length"}$, [], $"int"^4 arrow.r "int"$,
			[], $"response"_{"start"}, "response"_{"length"})$, [], [],
            [], [], [], [],
			[#strong[put]\(], $"url"_{"start"}, "url"_{"length"}$, [], $"int"^6 arrow.r "int"$,
			[], $"payload"_{"start"}, "payload"_{"length"})$, [], [],
			[], $"content type"_{"start"}, "content type"_{"length"})$, [], [],
            [], [], [], [],
			[#strong[post]\(], $"url"_{"start"}, "url"_{"length"}$, [], $"int"^8 arrow.r "int"$,
			[], $"payload"_{"start"}, "payload"_{"length"})$, [], [],
			[], $"content type"_{"start"}, "content type"_{"length"})$, [], [],
			[], $"response"_{"start"}, "response"_{"length"})$, [], []
))))<fig:http>

The code example in figure @fig:http prints an ASCII version of the Arduino logo retrieved from the internet with an HTTP GET request.
To do this, it first adds the URL of the ASCII art logo in WebAssembly linear memory (lines 3-5).
The main function will repeatedly retrieve the logo in an infinite loop that starts on line 8.
Before the code pushes the four integers arguments for the $mono("get")$ primitive, it pushes the start index of the response buffer onto the stack.
This is the same trick we used in the previous example using the $mono("print")$ primitive.
By pushing this value now, and the $mono("get")$ primitive pushing the length of the result, we can call the $mono("print")$ primitive immediately without having to reorder the stack first.
After the ASCII text has been printed to the serial port, the microcontroller waits for 1 second before starting the entire procedure again.

== MQTT Protocol<app:mqtt>

HTTP was designed for the web and is not optimized for an embedded context @naik17.
More suitable protocols have been developed for IoT applications, such as the widely used MQTT @banks14 protocol.
This is one of the most mature and widespread IoT protocols at the time of writing.
It is more lightweight in several aspects compared to HTTP.
The message overhead is a lot smaller, since headers only require 2 bytes per message.
Another important difference with the client-server approach of HTTP, is the client-broker architecture of MQTT.
By using a publish-subscribe paradigm, MQTT reduces the number of messages a microcontroller needs to send.
The publish-subscribe paradigm is commonly used in IoT contexts because its simplicity and effectiveness at reducing network traffic @gupta21@sidna20.
The main idea of this paradigm is to disconnect communication in time and space.
This means, that entities do not have to be reachable at the same time, and do not need to know each other, to communicate.
Consequently, entities are free to halt execution or sleep.
They may send and process messages whenever they choose to.
This is the great advantage of MQTT over HTTP for constrained devices.
We have added the basic MQTT operations to WARDuino.
The implementation is backed by Nick O'Leary's#footnote[Documentation at: https://github.com/knolleary/pubsubclient] Arduino library for MQTT messaging.

Because MQTT clients do not know each other, they communicate through a shared third party, the MQTT Broker.
Communication starts when an MQTT client opens a persistent TCP connection with the MQTT Broker and sends an arbitrary string as its unique identifier to the server.
Once connected, the MQTT client can both publish messages or subscribe to topics.
The broker filters incoming (published) messages based on their topics and sends them asynchronously to every connected client subscribed to those specific topics.
Topics need not be initialized, clients can send messages to any topic string of the right form.

#figure(
  caption: [API and example code of the MQTT module in WARDuino.],
    grid(
        columns: (1fr, 1fr),     // 2 means 2 auto-sized columns
        gutter: 1mm,    // space between columns
        [
```wast
(module
  (memory $url 1)
  (data (i32.const 0)
        "broker.hivemq.com")
  (data (i32.const 20) "mcu")
  (data (i32.const 25) "helloworld")

  (; callback function ;)
  (func $callback (type $int->int->int->int->vd)
    (call $print (local.get 2) (local.get 3)))
  (; add callback to callbacks table ;)
  (table $callbacks 1 funcref)
  (elem (i32.const 0) $callback) (; fidx = 0 ;)

  (; (re)connect function ;)
  (func $reconnect (type $vd->vd)
    (call $poll)
    (loop $until_connected
      (; connect to MQTT ;)
      (i32.const 20)   (; client id start ;)
      (i32.const 3)    (; client id length ;)
      (call $connect)
      (i32.ne (call $connected) (i32.const 1))
      (br_if $until_connected)))

  (func $main (type $vd->vd)
    (i32.const 0)    (; url start ;)
    (i32.const 17)   (; url length ;)
    (i32.const 1883) (; port ;)
    (call $init)
    (call $reconnect)

    (loop $try_subscribing
      (i32.const 25) (; topic start ;)
      (i32.const 10) (; topic length ;)
      (i32.const 0)  (; fidx ;)
      (call $subscribe)
      (i32.const 1)
      (br_if $try_subscribing (i32.ne)))

    (loop $waitloop
      (call $delay (i32.const 1000))
      (call $reconnect)
      (br $waitloop))))
```], rect(inset: 0mm, table(columns: 3, align: (right, left, right), column-gutter: 0mm,

			$"init"\($, $"server"_"start", "server"_"length", "port"\)$, $"int"^3 arrow.r \(\)$,
			$"connect"\($, $"id"_{"start"}, "id"_{"length"}\)$, $"int"^2 arrow.r "int"$,
			$"poll()"$, [], $\(\) arrow.r "int"$,
			$"connected()"$, [], $\(\) arrow.r "int"$,
			$"subscribe("$, $"topic"_{"start"}, "topic"_{"length"}, "fidx)"$, $"int"^3 arrow.r "int"$,
			$"unsubscribe("$, $"topic"_{"start"}, "topic"_{"length"}, "fidx)"$, $"int"^3 arrow.r "int"$,
			$"publish("$, $"topic"_{"start"}, "topic"_{"length"}$, $"int"^4 arrow.r "int"$,
			[], $"payload"_{"start"}, "payload"_{"length"}\)$, [],
            table.hline(stroke: lineWidth),
			table.cell(colspan: 3)[Signature of MQTT callback functions:],
			table.cell(colspan: 2)[$"fn_name"("topic"_"start", "topic"_"length"$], $"int"^4 arrow.r ()$,
			[], $"payload"_"start", "payload"_"length")$, []
))))<fig:mqtt>


The first four MQTT primitives shown on the right side of figure~@fig:mqtt, are administrative.
The $mono("init")$ function sets the URL and port of the MQTT broker.
By calling the $mono("connect")$ primitive with a client ID string, represented by a memory slice, a connection is established.
This primitive returns the status of the connection with the server (one if connected, else zero).
We give developers full control over the frequency with which the device checks for new messages.
They can trigger a check by calling our $mono("poll")$ primitive without arguments.
Such a call will process all incoming messages and invoke their callbacks, the return value is the status of the connection.
The $mono("poll")$ primitive needs to be called regularly to maintain the connection to the broker.
Getting the connection status can also be done without processing messages by using the  $mono("connected")$ primitive.

The remaining primitives encompass the core MQTT operations: $mono("subscribe")$, $mono("unsubscribe")$, and $mono("publish")$.
They all return a boolean value to indicate success (1) or failure (0).
Our $mono("subscribe")$ primitive takes a topic string, and the function index of a callback function that will handle any incoming message matching the specified topic.
A callback function must be of the type $"int"^4 arrow.r ()$.
It takes two strings as argument: the topic and the payload of the received message.
The callback function can interact with the memory of the module but must not return a value.
To assign a function index to a function, it must be stored in a $mono("table")$ of the WebAssembly module.
The function index is simply its index in the callback's table.
Whenever a message arrives from the server for a subscribed topic, the appropriate callback functions will be executed by WARDuino.
Our $mono("unsubscribe")$ primitive permits removing specific callback functions from specific topics.
If all callbacks to a topic are removed, the MQTT broker is informed that we no longer wish to get messages for that topic.
Aside from subscribing to topics, we can also send payloads for topics to the MQTT Broker.
This is done with the $mono("publish")$ primitive that takes the same arguments as a callback function: a topic string, and a payload of the message to be published.

Figure~@fig:mqtt shows an example MQTT program on the left, which subscribes to the $mono("helloworld")$ topic of an MQTT broker.
Our small WebAssembly program will print the payload of each message it receives.
The code starts by declaring all the static strings used in the program (lines 2-6).
Our entry point is the main function defined on lines 26 to 44.
First we initialize the MQTT module with the URL and port of the broker using the $mono("init")$ primitive (27-30).
Note that we have omitted the Wi-Fi connection code for brevity, as we have already shown how to connect to a Wi-Fi network in figure~@fig.wifi.
Once our module is initialized, we connect it to the MQTT broker by using the $mono("$reconnect")$ function.
This function is defined on lines 16 to 24.
It calls the administrative $mono("poll")$ primitive and tries to connect to the broker until successful.
After calling $mono("$reconnect")$, our main function continues by subscribing to the $mono("helloworld")$ topic (lines 33-39).
This is done in a loop labeled $mono("$try_subscribing")$ which calls the $mono("subscribe")$ primitive repeatedly until it returns 1 (success).
In WebAssembly we cannot pass a function directly to another function.
Instead, we must add the function to a table of function references.
The code declares such a table of size one on line 12.
On the next line the element section adds our callback function to the $mono("$callbacks")$ table at index zero.
This is the zero we use on line 36 to refer to it.
Lines 9 to 10 define the callback function we stored in our table.
It takes two arguments, a message topic and a payload.
With the $mono("local.get")$ instruction, the function places its last two arguments, corresponding to the payload string, on the stack and then it calls the $mono("print")$ primitive.
Our main function ends with an infinite loop on lines 41 to 44 that calls $mono("$reconnect")$ every second to check if the connection is still live and reconnect if necessary.

