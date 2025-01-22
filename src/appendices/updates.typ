= Over-the-air Updates Defined Orthogonally<remote:live-code-updates-integrated-with-debugging>

The formalization of the over-the-air updates is presented in @remote:safe-dynamic-code-updates as an addition to the remote debugger semantics (@remote:debugging).
However, we designed the update semantics to be orthogonal to the debugging system, making it easy to define a version of the over-the-air updates that does not rely on the remote debugger.
The rules below show the update system as a standalone semantics on top of the WebAssembly semantics.

#figure()[]

All parts of the debugger semantics are removed, and a new $sans("vm-run")$ rule is introduced.
Contrary to the semantics shown in @remote:debugging, the state $s$ is now only extended with the incoming messages.

