{
  description = "Nix Development Shell Flake for TVM and Android Development";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils, ... } @ inputs:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system; config.allowUnfree = true;
          config.android_sdk.accept_license = true;
        };
        lib = pkgs.lib;

        # Python
        custom-python = pkgs.python38.withPackages (python-pkgs: with python-pkgs; [
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
        make-dev-deps = { enableCuda ? false, ... }: ((with pkgs; [
          rnix-lsp
          clang-tools
          pyright

          cmake
          llvm
          ninja

        ]) ++ [ custom-python ] ++ (lib.optionals enableCuda [
          pkgs.cudaPackages_11_8.cudatoolkit
        ]));

        # Android development
        buildToolsVersion = "32.0.0";
        platformToolsVersion = "33.0.2";

        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/mobile/androidenv/compose-android-packages.nix
        android-composition = pkgs.androidenv.composeAndroidPackages {
          inherit platformToolsVersion;
          buildToolsVersions = [ buildToolsVersion ];
          platformVersions = [ "27" "32" ];
          includeNDK = true;
        };
        jdk = pkgs.jdk;

        android-dev-deps = with pkgs; [
          kotlin-language-server
          gradle
          android-composition.androidsdk
        ];

        make-ld-library-path = { enableCuda ? false, ... }:
          if enableCuda
          then "${pkgs.cudaPackages_11_8.cudatoolkit.lib}/lib:/run/opengl-driver/lib"
          else "/run/opengl-driver/lib";

        make-dev-shell = opts: pkgs.mkShell rec {
          name = "r2n-devshell";
          buildInputs = make-dev-deps opts ++ android-dev-deps;

          LD_LIBRARY_PATH = make-ld-library-path opts;
          CMAKE_EXPORT_COMPILE_COMMANDS = "ON";
          ANDROID_SDK_ROOT = "${android-composition.androidsdk}/libexec/android-sdk";
          ANDROID_NDK_ROOT = "${ANDROID_SDK_ROOT}/ndk-bundle";
          JAVA_HOME = jdk.home;
          GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${ANDROID_SDK_ROOT}/build-tools/${buildToolsVersion}/aapt2";
        };
      in
      {
        devShells.default = make-dev-shell { enableCuda = false; };
        devShells.cuda = make-dev-shell { enableCuda = true; };
        packages.android-composition = android-composition;
      });
}
