### `mkShell`

This is a transparent convenience proxy for [`numtide/devshell`'s][numtide-devshell] `mkShell` function.

It is enriched with a tight integration for `std` [Nixago][nixago] pebbles:

```nix
{ inputs, cell}: {
  default = inputs.std.lib.dev.mkShell {
    /* ... */
    nixago = [
      (cell.nixago.foo {
        data.qux = "xyz";
        packages = [ pkgs.additional-package ];
      })
      cell.nixago.bar
      cell.nixago.quz
    ];
  };
}
```

_Note, that you can extend any Nixago Pebble at the calling site
via a built-in functor like in the example above._

#### Project root resolution

`mkShell` wraps the devshell's outer `shellHook` so that, before `env.bash`
is sourced, the working directory is `cd`'d to the git project root (via
`git rev-parse --show-toplevel`). After `env.bash` returns, the original
invocation cwd is restored.

This makes `nix develop` from a subdirectory behave correctly: `PRJ_ROOT`
points at the actual project root, and Nixago materializes its files there
rather than in the subdirectory. If the project is not a git repository, a
warning is printed and `PRJ_ROOT` falls back to `$PWD`.

[nixago]: https://github.com/nix-community/nixago
[numtide-devshell]: https://github.com/numtide/devshell
