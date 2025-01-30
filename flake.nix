{
  description = "WGPU experiments";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-24.11";
    flake-utils.url = "github:numtide/flake-utils";

    crane.url = "github:ipetkov/crane";

    fenix = {
      url = "github:nix-community/fenix/monthly";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    crane,
    fenix,
    flake-utils,
    nixpkgs,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        toolchain = fenix.packages.${system}.stable.toolchain;
        pkgs = nixpkgs.legacyPackages.${system};

        inherit (pkgs) lib;

        craneLib = crane.mkLib pkgs;

        #LD_LIBRARY_PATH = "${lib.makeLibraryPath nativeBuildInputs}";

        reqlibs = with pkgs; [
          wayland
          libxkbcommon
          libGL

          vulkan-headers
          vulkan-loader
          vulkan-tools
          vulkan-tools-lunarg
          vulkan-extension-layer
          vulkan-validation-layers
        ];

        commonArgs = {
          src = craneLib.cleanCargoSource ./.;
          strictDeps = true;

          nativeBuildInputs = with pkgs; [makeWrapper];
        };

        my-crate = craneLib.buildPackage (commonArgs
          // {
            cargoArtifacts = craneLib.buildDepsOnly commonArgs;

            postInstall = ''
              wrapProgram $out/bin/wgpu_test --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath reqlibs}
            '';
          });
      in {
        formatter = pkgs.alejandra;

        devShells.default = pkgs.mkShell {
          name = "wgpu dev";

          packages = [toolchain];

          LD_LIBRARY_PATH = "${lib.makeLibraryPath reqlibs}";
          RUST_BACKTRACE = "1";
        };

        packages.default = my-crate;
      }
    );
}
