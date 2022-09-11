{
  description = "Nix devShell Flake for developing ``Enabling Android NNAPI Flow for TVM Runtime''";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils, ... } @ inputs:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        python = pkgs.python38.withPackages (python-pkgs: with python-pkgs; [
          numpy
          decorator
          attrs
          psutil
          typed-ast
          (scipy.overrideAttrs (old: { doCheck = false; }))
          pytest
        ]);
        dev-deps = (with pkgs; [ rnix-lsp clang-tools pyright cmake llvm ]) ++ [ python ];
      in
      {
        devShell = pkgs.mkShell {
          name = "r2n-devshell";
          buildInputs = dev-deps;
        };
      });
}
