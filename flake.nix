{
  description = "Small exercises to get you used to reading and writing Rust code";

  inputs = {
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    fenix.url = "github:nix-community/fenix";
  };

  outputs =
    {
      self,
      flake-utils,
      nixpkgs,
      fenix,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        rustToolchain = fenix.packages.${system}.latest;

        cargoBuildInputs =
          with pkgs;
          lib.optionals stdenv.isDarwin [
            darwin.apple_sdk.frameworks.CoreServices
          ];

        rustlings =
          (pkgs.makeRustPlatform {
            rustc = rustToolchain.toolchain;
            cargo = rustToolchain.toolchain;
          }).buildRustPackage
            {
              name = "rustlings";
              version = "5.5.1";
              # Entering the dev shell should not depend on integration tests that
              # expect the exercise files to remain in their pristine upstream state.
              doCheck = false;

              buildInputs = cargoBuildInputs;

              src =
                with pkgs.lib;
                cleanSourceWith {
                  src = self;
                  filter =
                    path: type:
                    let
                      baseName = builtins.baseNameOf (toString path);
                      path' = builtins.replaceStrings [ "${self}/" ] [ "" ] path;
                      inDirectory = directory: hasPrefix directory path';
                    in
                    inDirectory "src"
                    || inDirectory "tests"
                    || inDirectory "exercises"
                    || hasPrefix "Cargo" baseName
                    || baseName == "info.toml";
                };

              cargoLock.lockFile = ./Cargo.lock;
            };
      in
      {
        devShell = pkgs.mkShell {
          RUST_SRC_PATH = "${rustToolchain.rust-src}/lib/rustlib/src/rust/library";

          buildInputs =
            with pkgs;
            [
              rustToolchain.toolchain
              rustToolchain.rust-analyzer
              rustlings
            ]
            ++ cargoBuildInputs;
        };
      }
    );
}
