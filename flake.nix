{
  description = ''
    Incrementally run checks & fixes in your Nix flake (only on changed files)
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
          self.lib.commonFlakePaths
          (self.lib.walkFlake ./.);

        checker = self.lib.makeFlakeChecker {
          root = ./.;

          settings = {
            markdownlint.paths = paths.markdown;
            nixpkgs-fmt.paths = paths.nix;
            prettier.paths = paths.markdown;
          };

          inherit pkgs;
        };
      in
      {
        checks = {
          inherit (checker) check;
        };

        apps = {
          inherit (checker) fix;
        };
      });
}
