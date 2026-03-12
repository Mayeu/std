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

`hook.extra` is a Nixago hook hat runs whenever the generated `lefthook.yml` is
materialized. It receives the final merged `config` (the full lefthook YAML
content as a Nix attrset) and produces extra shell commands. Here's the pipeline
step by step:

```nix
hook.extra = config:
  let
    commands = lib.pipe config [
      # 1. Strip non-stage keys (colors, extends, etc.)
      #    e.g. { pre-commit = {...}; commit-msg = {...}; colors = true; }
      #    becomes { pre-commit = {...}; commit-msg = {...}; }
      toStagesConfig

      # 2. Extract just the attribute names → ["pre-commit" "commit-msg"]
      lib.attrNames

      # 3. For each stage, create a symlink command:
      #    ln -sf "/nix/store/...-lefthook-pre-commit" ".git/hooks/pre-commit"
      #    The target is a Nix-built script (mkScript) that runs:
      #      lefthook run "pre-commit" "$@"
      #    (unless $LEFTHOOK == "0", which disables it)
      (lib.map (stage: ''ln -sf "${mkScript stage}" ".git/hooks/${stage}"''))

      # 4. Prepend "mkdir -p .git/hooks" IF there are any stages
      #    ["mkdir -p .git/hooks" "ln -sf ..." "ln -sf ..."]
      (stages:
        lib.optional (stages != []) "mkdir -p .git/hooks"
        ++ stages)

      # 5. Join into a single newline-separated shell script string
      (lib.concatStringsSep "\n")
    ];
  in ''
    # Only install hooks in the main repo, not in worktrees.
    # In worktrees, .git is a file pointing to the main repo's .git dir,
    # so mkdir -p .git/hooks would fail.
    if test "$(git rev-parse --git-dir)" = "$(git rev-parse --git-common-dir)"; then
      ${commands}
    fi
  '';
```

When you run the Nixago hook (e.g. via `direnv allow` or `std` commands), it:

1. Writes `lefthook.yml` to your project root
2. Runs this `hook.extra` script, which symlinks Nix-built wrapper scripts into
   `.git/hooks/` (only in the main repo, not in worktrees)
