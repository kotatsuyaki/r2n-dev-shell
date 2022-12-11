{
  description = "Nix devShell Flake for developing ``Enabling Android NNAPI Flow for TVM Runtime''";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils, ... } @ inputs:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        python = pkgs.python38.withPackages (python-pkgs: with python-pkgs; [
          numpy
          decorator
          attrs
          psutil
          typed-ast
          typing-extensions
          (scipy.overrideAttrs (old: {
            doCheck = false;
            buildInputs = old.buildInputs ++ [ pkgs.libxcrypt ];
          }))
          pytest
          ipython
        ]);
        dev-deps = (with pkgs; [
          rnix-lsp
          clang-tools
          pyright

          cmake
          llvm
          ninja

          cudaPackages_11_8.cudatoolkit
        ]) ++ [ python ];
      in
      {
        devShell = pkgs.mkShell {
          name = "r2n-devshell";
          buildInputs = dev-deps;
          LD_LIBRARY_PATH = "${pkgs.cudaPackages_11_8.cudatoolkit.lib}/lib:/run/opengl-driver/lib";
        };
      });
}
