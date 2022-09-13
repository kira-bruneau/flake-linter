{ callPackage }:

{
  markdownlint = callPackage ./markdownlint.nix { };
  nixpkgs-fmt = callPackage ./nixpkgs-fmt.nix { };
  prettier = callPackage ./prettier.nix { };
  rustfmt = callPackage ./rustfmt.nix { };
  shfmt = callPackage ./shfmt.nix { };
}
