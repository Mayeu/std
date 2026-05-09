### `lefthook`

[Lefthook][lefthook] is a fast (parallel execution) and elegant git hook manager.

[lefthook]: https://github.com/evilmartians/lefthook

---

#### Definition:

```nix
{{#include ../../src/lib/cfg/lefthook.nix}}
```

#### Explanation of the `in { ... }` block

This `in { ... }` block is a **Nixago configuration record**, it tells the
Nixago block type how to generate and manage the `lefthook.yml` file.

`data = {};` is The actual lefthook config content. It's empty here because this
is just the template/scaffold, the real config data gets merged in by consumers
(e.g. in `src/local/configs.nix` or wherever this is used). Nixago deep-merges
`data` from the caller.

`hook.extra` is a Nixago hook that runs whenever the generated `lefthook.yml`
is materialized. It receives the final merged `config` (the full lefthook YAML
content as a Nix attrset) and emits a shell snippet that symlinks a Nix-built
wrapper script into the repo's hooks directory for each configured stage. The
wrapper runs `lefthook run "<stage>" "$@"` unless `$LEFTHOOK == "0"` (escape
hatch).

#### Worktree behavior

The hooks directory is resolved via `git rev-parse --git-path hooks` rather
than the literal `.git/hooks`. Two reasons:

1. In a linked worktree, `.git` is a *file* (not a directory) pointing at
   `<main>/.git/worktrees/<name>`, so `mkdir -p .git/hooks` would fail.
2. Per [`gitrepository-layout(5)`][layout]: *"This directory is ignored if
   `$GIT_COMMON_DIR` is set and `$GIT_COMMON_DIR/hooks` will be used
   instead."* In other words, git always looks up hooks in the **common**
   gitdir, regardless of which worktree you commit from.

`--git-path hooks` returns `<common-dir>/hooks` from any worktree, so a single
install (from main checkout or any worktree) wires up hooks for every
worktree.

[layout]: https://git-scm.com/docs/gitrepository-layout

#### Lifecycle

When you run the Nixago hook (e.g. via `direnv allow` or `std` commands), it:

1. Writes `lefthook.yml` to your project root.
2. Runs `hook.extra`, which symlinks Nix-built wrapper scripts into the
   resolved hooks directory.
