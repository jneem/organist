Nickel-nix
==========

An experimental Nix toolkit to use [Nickel](https://github.com/tweag/nickel) as a
language for writing nix packages, shells and more.

**Caution**: `nickel-nix` is not a full-fledged Nix integration. It is currently
missing several basic features. `nickel-nix` is intended to be a
proof-of-concept for writing a Nix derivation using Nickel at the moment,
without requiring new features either in Nix or in Nickel. The future of the
integration of Nix and Nickel will most probably involve deeper changes to the
two projects, and hopefully lead to a more featureful and ergonomic solution.

## Content

This repo is composed of a Nix library, a Nickel library and a flake which
provides the main entry point of `nickel-nix`, the Nix `importFromNcl` function.
This function takes a Nickel file and inputs to forward and produces a
derivation.

The Nickel library contains in-code documentation that can be leveraged by the
`nickel query` command. For example:

- `nickel query -f nix.ncl` will show the top-level documentation and the list of
    available symbols
- `nickel query -f nix.ncl lib.nix_string_hack` will show the documentation of a
    specific symbol, here `lib.nix_string_hack`.

## Usage

The [`example/nix-shell`](examples/nix-shell/) illustrates how to use
`nickel-nix` to writer a simple `hello` shell.

To try it, enter the `example/nix-shell` directory, and run:

```
$ nix develop --impure
Development shell
Hello, world!
```

This is an hello from the Nickel world!

Please refer to the [example's README](examples/nix-shell/README.md) for more
details.

More examples of varied Nix derivations are to come.

## Why using Nickel for Nix ?

There are already resources on what is Nickel, and why it can make for better
user experience for Nix[^1]. In particular, Nickel adds validations capabilities
thanks to its type system and contract system. As a simple illustration, let's
make a stupid error in our Nix version of the `hello` shell,
[`examples/nix-shell/shell.nix`](examples/nix-shell/shell.nix), by replacing the
list of `packages` by a string:

```nix
-    packages = [ pkgs.hello ];
+    packages = "pkgs.hello";
```

Trying to run the development shell, we get the following error:

```
$ nix develop .#withNix
[..]
error: value is a string while a list was expected

       at /nix/store/n04lw5nrskzmz7rv17p09qrnjanfkg5d-source/pkgs/build-support/mkshell/default.nix:37:23:

           36|   buildInputs = mergeInputs "buildInputs";
           37|   nativeBuildInputs = packages ++ (mergeInputs "nativeBuildInputs");
             |                       ^
           38|   propagatedBuildInputs = mergeInputs "propagatedBuildInputs";
```

The error points to Nix internal code. Thanks to the variable being luckily
named `packages` as well, and the simple nature of the error, a seasoned Nix
user might be able to diagnose the issue here. However, a slightly less
forgiving example could quickly let us at loss.

Let's do the same thing to the Nickel version in `shell.ncl`:

```nickel
-    , packages = "[
-      inputs.hello
-    ]"
+    , packages = "
+      inputs.hello
+    "
```

Now, we get:

```
error: contract broken by a value
   ┌─ :1:1
   │
 1 │ Array NixDerivation
   │ ------------------- expected type
   │
   ┌─ /nix/store/4hp31ic3cyh3lp8yk0f3cz75blv8s1bm-shell.ncl:10:21
   │
10 │          , packages = "
   │ ╭─────────────────────^
11 │ │          inputs.hello
12 │ │        "
   │ ╰────────^ applied to this expression
   │
   ┌─ <unknown> (generated by evaluation):1:1
   │
 1 │ ╭ "
 2 │ │          inputs.hello
 3 │ │         "
   │ ╰─────────' evaluated to this value

note:
   ┌─ /nix/store/drxy2fkpry2kjmpr318fxbrz0pfrj65n-nix.ncl:87:16
   │
87 │     packages | Array NixDerivation
   │                ^^^^^^^^^^^^^^^^^^^ bound here
```

While the code is dynamically typed in both cases, Nickel provided a more
relevant error than Nix:

1. It points to the definition of `packages` inside our own shell
2. It shows where the contract was enforced. This is inside the `nix.ncl` lib,
   but those are readable contract definitions, instead of an internal function
   building a derivation.
3. It shows the actual value the expression evaluated to. This is not very useful here,
   because `packages` is already a string literal, but would be if `packages`
   was a compound expression.

This report is made possible by contracts, a runtime validation feature of
Nickel. Here, a contract is slapped on top of our `shell.ncl` transparently by
the `nix.ncl` library.

While this precise error is a tad artificila, and the current contracts of
`nickel-nix` are minimalists, the point is to demonstrate the _potential_ of
encoding the domain knowledge and constraints of Nix inside Nickel, in order to
improve the troubleshooting experience.

While one could also implement validation capabilities in Nix (as is done in
NixOS modules), the native contracts of Nickel have specific interpreter
support, which helps to:
- better track errors across data and functions calls
- easily and succintly specify new contracts
- provide good error reporting out of the box

Contracts can be written in a fairly lightweight and natural way, like data
schemas: this hopefully lowers the barrier to have a more comprehensive
validation story.

[^1]: You can read the
  [announcement of the first release](https://www.tweag.io/blog/2022-03-11-nickel-first-release/).
  You can visit the [website](https://nickel-lang.org), read the
  [README of the project](https://github.com/tweag/nickel/blob/master/README.md) or the
  [design rationale document](https://github.com/tweag/nickel/blob/master/RATIONALE.md).
  For a more technical documentation on Nickel itself, see the
  [user manual](https://nickel-lang.org/user-manual/introduction).
