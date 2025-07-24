{ callPackage }:

{
  alejandra = callPackage ./alejandra.nix { };
  markdownlint = callPackage ./markdownlint.nix { };
  nix-linter = callPackage ./nix-linter.nix { };
  nixf-tidy-fix = callPackage ./nixf-tidy-fix { };
  nixfmt-rfc-style = callPackage ./nixfmt-rfc-style.nix { };
  nixpkgs-fmt = callPackage ./nixpkgs-fmt.nix { };
  prettier = callPackage ./prettier.nix { };
  rustfmt = callPackage ./rustfmt.nix { };
  shellcheck = callPackage ./shellcheck.nix { };
  shfmt = callPackage ./shfmt.nix { };
}
