let
  inherit (inputs) namaka nixpkgs self;
  inputs' = builtins.removeAttrs inputs ["self"];
  namakaResults = namaka.lib.load {
    src = self + /tests;
    inputs =
      inputs'
      //
      # inputs.self is too noisy for 'check-augmented-cell-inputs'
      {inputs = inputs';};
  };
in {
  snapshots = {
    meta.description = "The main Standard Snapshotting test suite";
    # 2026-03-01 @mayeu: unsure if that's ok, but namaka.lib.load throws on
    # failure, returns {} on success. Wrap in a derivation so nix build
    # .#checks.<system> works.
    check = nixpkgs.runCommand "namaka-snapshots" {} ''
      # ${builtins.toJSON namakaResults}
      touch $out '';
  };
}
