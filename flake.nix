{
  description = ''
    A linting framework designed to run checks & fixes incrementally
    in your project (using Nix flakes)
  '';

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/release-22.05";
  };

  outputs = { self, flake-utils, nixpkgs }:
    {
      lib = import ./lib;
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        paths = self.lib.partitionToAttrs
          {
            inherit (self.lib.commonPaths)
              bash
              markdown
              nix;
          }
          (self.lib.walkFlake ./.);

        linter = self.lib.makeFlakeLinter {
          root = ./.;

          settings = {
            markdownlint.paths = paths.markdown;

            # Fails to parse arguments starting with _
            # Possible nix-linter: <stdout>: commitAndReleaseBuffer: invalid argument (invalid character)
            # nix-linter.paths = paths.nix;

            nixpkgs-fmt.paths = paths.nix;
            shfmt = {
              paths = paths.bash;
              settings = {
                indent = 2;
              };
            };
          };

          inherit pkgs;
        };
      in
      {
        checks = {
          flake-linter = linter.check;
        };

        apps = {
          inherit (linter) fix;
        };
      });
}
