{
  description = "A basic flake with a shell";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nickel-nix.url = "github:nickel-lang/nickel-nix";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    nickel-nix,
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      importNcl = nickel-nix.lib.${system}.importNcl;
      nakedStdenv = importNcl ./. "naked-stdenv.ncl" inputs;
      nickelDerivation =
        importNcl ./. "dev-shell.ncl"
        (
          inputs
          // {
            myInputs.packages.${system} = {inherit nakedStdenv;};
          }
        );
    in rec {
      packages = {
        default = nakedStdenv;
      };
      devShells = {
        default = nickelDerivation;
      };
    });
}
