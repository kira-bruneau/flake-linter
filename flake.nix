{
  description = ''
    A linting framework designed to run checks & fixes incrementally
    in your project (using Nix flakes)
  '';

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/nixos-23.11";
  };

  outputs = { self, flake-utils, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        flake-linter-lib = self.lib.${system};

        paths = flake-linter-lib.partitionToAttrs
          {
            inherit (flake-linter-lib.commonPaths)
              bash
              markdown
              nix;
          }
          (flake-linter-lib.walkFlake ./.);

        linter = flake-linter-lib.makeFlakeLinter {
          root = ./.;
          settings = {
            markdownlint.paths = paths.markdown;
            nixpkgs-fmt.paths = paths.nix;
            shfmt = {
              paths = paths.bash;
              settings = {
                indent = 2;
              };
            };
          };
        };
      in
      {
        checks = {
          flake-linter = linter.check;
        };

        lib = import ./lib pkgs;

        apps = {
          inherit (linter) fix;
        };

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = linter.nativeBuildInputs ++ [
            # markdown-lint-check isn't included in flake-linter
            # because it requires internet access. I'm considering
            # implementing an "offline mode" for it so we can.
            pkgs.nodePackages.markdown-link-check
          ];
        };
      });
}
