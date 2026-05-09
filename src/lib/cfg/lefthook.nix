let
  inherit (inputs) nixpkgs;
  lib = nixpkgs.lib // builtins;

  mkScript = stage:
    nixpkgs.writeScript "lefthook-${stage}" ''
      #!${nixpkgs.runtimeShell}
      [ "$LEFTHOOK" == "0" ] || ${lib.getExe nixpkgs.lefthook} run "${stage}" "$@"
    '';

  toStagesConfig = config:
    lib.removeAttrs config [
      "colors"
      "extends"
      "skip_output"
      "source_dir"
      "source_dir_local"
    ];
in {
  data = {};
  format = "yaml";
  output = "lefthook.yml";
  packages = [nixpkgs.lefthook];
  # Install symlinks into the resolved hooks dir, so this works from both the
  # main checkout and linked worktrees. `git rev-parse --git-path hooks`
  # returns `<common-dir>/hooks` (per gitrepository-layout(5): hooks live in
  # the common gitdir, not the per-worktree private gitdir), so a single
  # install from any worktree wires up hooks for every worktree.
  hook.extra = config: let
    stages = lib.pipe config [toStagesConfig lib.attrNames];
    links =
      lib.concatMapStringsSep "\n"
      (stage: ''ln -sf "${mkScript stage}" "$_std_hooks_dir/${stage}"'')
      stages;
  in
    lib.optionalString (stages != []) ''
      _std_hooks_dir="$(${lib.getExe nixpkgs.git} rev-parse --git-path hooks)"
      mkdir -p "$_std_hooks_dir"
      ${links}
      unset _std_hooks_dir
    '';
}
