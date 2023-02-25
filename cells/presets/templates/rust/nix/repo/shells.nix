{
  inputs,
  cell,
}: let
  inherit (inputs.std) std lib;
  inherit (inputs) nixpkgs fenix;
  inherit (inputs.cells) hello;

  l = nixpkgs.lib // builtins;
  dev = lib.dev.mkShell {
    packages = [
      nixpkgs.pkg-config
    ];
    language.rust = {
      packageSet = cell.rust;
      enableDefaultToolchain = true;
      tools = ["toolchain"]; # fenix collates them all in a convenience derivation
    };
    env = [
      {
        name = "RUST_SRC_PATH";
        # accessing via toolchain doesn't fail if it's not there
        # and rust-analyzer is graceful if it's not set correctly:
        # https://github.com/rust-lang/rust-analyzer/blob/7f1234492e3164f9688027278df7e915bc1d919c/crates/project-model/src/sysroot.rs#L196-L211
        value = "${cell.rust.toolchain}/lib/rustlib/src/rust/library";
      }
      {
        name = "PKG_CONFIG_PATH";
        value = l.makeSearchPath "lib/pkgconfig" hello.packages.default.buildInputs;
      }
    ];
    imports = [
      "${inputs.std.inputs.devshell}/extra/language/rust.nix"
    ];

    commands = let
      rustCmds =
        l.map (name: {
          inherit name;
          package = cell.rust.toolchain; # has all bins
          category = "rust dev";
          # fenix doesn't include package descriptions, so pull those out of their equivalents in nixpkgs
          help = nixpkgs.${name}.meta.description;
        }) [
          "rustc"
          "cargo"
          "rustfmt"
        ];
    in
      [
        {
          package = nixpkgs.treefmt;
          category = "repo tools";
        }
        {
          package = nixpkgs.alejandra;
          category = "repo tools";
        }
        {
          package = std.cli.default;
          category = "std";
        }
        # {
        #   name = "rust-analyzer";
        #   category = "rust dev";
        #   package = cell.rust.rust-analyzer;
        #   # help = nixpkgs.rust-analyzer.meta.description;
        # }
      ]
      ++ rustCmds;
  };
in {
  inherit dev;
  default = dev;
}