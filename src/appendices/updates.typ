#import "../../lib/util.typ": semantics, tablehead
#import "../semantics/arrows.typ": *

#import "@preview/curryst:0.5.0": rule, prooftree

= Addendum to remote debugging with WARDuino

This appendix is an addendum to @chapter:remote.

== Over-the-air Updates Defined Orthogonally<remote:live-code-updates-integrated-with-debugging>

The formalization of the over-the-air updates is presented in @remote:safe-dynamic-code-updates as an addition to the remote debugger semantics (@remote:debugging).
However, we designed the update semantics to be orthogonal to the debugging system, making it easy to define a version of the over-the-air updates that does not rely on the remote debugger.
The rules below show the update system as a standalone semantics on top of the WebAssembly semantics.

#let upd = $"upd"$
#let upload = $"upload"$
#let msg = $"msg"$
#let id = $"id"$
#let code = $"code"$
#let cl = $italic("cl")$
#let inst = $italic("inst")$
#let idx = $italic("idx")$

#let updatef(i, fidx, code) = $"update"_(f)angle.l #i, #fidx, #code angle.r$
#let updatel(i, fidx) = $"update"_(l)angle.l #i, #fidx angle.r$

#semantics(
  [
    The #emph[step forwards] rules for input and output primitives in the multiverse debugger for WebAssembly, without input mocking. Addition to @fig:forwards-prim.
  ],
  [
    #table(columns: (2.0fr, 1fr), stroke: none, gutter: 1.0em,
      tablehead("Syntax rules"), "",
      table.cell(colspan: 2, table(columns: (1fr), stroke: none,
    $
    &"(UpdaterState)"& upd & colon.double.eq {msg_i, s} \
    &"(Msg)"& msg & colon.double.eq nothing ∣ "upload "m^* bar.v updatef("id"_i, " id"_f, "code"_f) bar.v updatel(j, v) \
    &"(closures)"& cl & colon.double.eq {inst i, idx j, code f} \
    $
      )),
      tablehead("Evaluation rules"), "",
    table.cell(colspan: 2, table(columns: (1fr), stroke: none,

        prooftree(rule(
          $
          {nothing}; s; v^*; e^* dbgarrow {nothing}; s'; v'^*; e'^*
          $,
          $
          s; v^*; e^* wasmarrow s'; v'^*; e'^*
          $,
          name: smallcaps("vm-run")
        )),

        prooftree(rule(
          $
          {upload m^*}; s; v^*; e^* dbgarrow {nothing}; s'; v'^*; e'^*
          $,
          $
          (tack.r m)^*$,${s'; v'^*; e'^*} = italic("bootstrap")(m^*)
          $,
          name: smallcaps("upload-m")
        )),

        prooftree(rule(
          $
          { updatef("id"_i, " id"_f, "code"_f)}; s; v^*; e^* dbgarrow {nothing}; s'; v^*; e^*
          $,
          $
          s' = italic("update")_f\(s, id_i, id_f, code_f\)
          $,
          name: smallcaps("update-f")
        )),

        prooftree(rule(
          $
          {updatel(j, v')}; s; v^j_1 v v^k_2; e^* dbgarrow {nothing}; s; v^j_1 v' v^k_2; e^*
          $,
          $
          tack.r v : epsilon.alt arrow.r t$,$tack.r v' : epsilon.alt arrow.r t
          $,
          name: smallcaps("update-local")
        ))

      )),
    )
  ],
  "fig:forwards-prim-step"
)


All parts of the debugger semantics are removed, and a new $sans("vm-run")$ rule is introduced.
Contrary to the semantics shown in @remote:debugging, the state $s$ is now only extended with the incoming messages.

