{
  description = "Build a cargo project without extra checks";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    bacon-git = {
        url = "github:Canop/bacon";
        flake = false;
    };
  };

  outputs = { self, nixpkgs, crane, flake-utils, bacon-git, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        craneLib = crane.lib.${system};
        bacon = craneLib.buildPackage {
          src = bacon-git;

          buildInputs = [
          ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            pkgs.libiconv
          ];
        };
      in
      {
        checks = {
          inherit bacon;
        };

        packages.default = bacon;

        apps.default = flake-utils.lib.mkApp {
          drv = bacon;
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = builtins.attrValues self.checks.${system};

          nativeBuildInputs = with pkgs; [
            cargo
            rustc
          ];
        };
      });
}
