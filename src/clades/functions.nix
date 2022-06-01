{nixpkgs}: let
  l = nixpkgs.lib // builtins;
  /*
  Use the Functions Clade for reusable nix functions that you would
  call elswhere in the code.

  Also use this for all types of modules and profiles, since they are
  implemented as functions.

  Consequently, there are no actions available for functions.
  */
  functions = name: {
    inherit name;
    clade = "functions";
  };
in
  functions
