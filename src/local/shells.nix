{
  inputs,
  cell,
}: let
  l = nixpkgs.lib // builtins;
  inherit (inputs) nixpkgs;
  inherit (inputs.cells) std lib;
in
  l.mapAttrs (_: lib.dev.mkShell) rec {
    default = {...}: {
      name = "Standard";
      nixago = [
        (lib.cfg.conform {data = {inherit (inputs) cells;};})
        (lib.cfg.treefmt cell.configs.treefmt)
        (lib.cfg.editorconfig cell.configs.editorconfig)
        (lib.cfg.just cell.configs.just)
        (lib.cfg.githubsettings cell.configs.githubsettings)
        lib.cfg.lefthook
        lib.cfg.adrgen
        (lib.dev.mkNixago cell.configs.cog)
      ];
      commands =
        [
          {
            package = nixpkgs.reuse;
            category = "legal";
          }
          {
            package = nixpkgs.delve;
            category = "cli-dev";
            name = "dlv";
          }
          {
            package = nixpkgs.go;
            category = "cli-dev";
          }
          {
            package = nixpkgs.gotools;
            category = "cli-dev";
          }
          {
            package = nixpkgs.gopls;
            category = "cli-dev";
          }
        ]
        ++ l.optionals nixpkgs.stdenv.isLinux [
          {
            package = nixpkgs.golangci-lint;
            category = "cli-dev";
          }
        ];
      imports = [std.devshellProfiles.default book];
    };

    book = {...}: {
      nixago = [
        (lib.cfg.mdbook cell.configs.mdbook)
      ];
    };
  }