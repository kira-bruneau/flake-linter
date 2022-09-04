# flake-checker

Incrementally run checks & fixes in your Nix flake (only on changed
files).

> **NOTE:** Everything outlined in this README should work, but the
> interface hasn't been finalized. Please be aware of possible
> breakage when updating your flake, and refer back to this README.

## Usage

```nix
{
  description = "Flake checker demo";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    flake-checker.url = "gitlab:kira-bruneau/flake-checker";
    nixpkgs.url = "nixpkgs/release-22.05";
  };

  outputs = { self, flake-utils, flake-checker, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        paths = flake-checker.lib.partitionToAttrs
          flake-checker.lib.commonFlakePaths
          (flake-checker.lib.walkFlake ./.);

        checker = flake-checker.lib.makeFlakeChecker {
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
```

### Check files

```shell
nix flake check
```

### Fix files

```nix
nix run .#fix
```

It's also safe to run this command from in a child directory in your
flake. It will automatically walk up looking for `flake.nix`.

## API

### `flake-checker.lib.makeFlakeChecker`

```nix
flake-checker.lib.makeFlakeChecker {
  root = ./.;

  settings = {
    my-checker = {
      # Paths to check, relative to `root`
      paths = [ ];

      # Checker-specific configuration
      extraSettings = {};
    };
  };

  # Optional
  extraCheckers = {
    my-checker = {
      packages = [ my-checker ];

      # Optional, provides `$config` which will be generated from `extraSettings`
      settingsFormat = pkgs.formats.json { };

      check = ''my-checker --config "$config" "$path"'';

      # Optional
      fix = ''my-checker --config "$config" --fix "$path"'';
    };
  };

  inherit pkgs;
}
```

#### Builtin Checkers

- [markdownlint](https://github.com/igorshubovych/markdownlint-cli)
- [nixpkgs-fmt](https://github.com/nix-community/nixpkgs-fmt)
- [prettier](https://github.com/prettier)
- [rustfmt](https://github.com/rust-lang/rustfmt)

### `flake-checker.lib.commonFlakePaths`

A template that can be passed to
[partitionToAttrs](#partitionToAttrs), which will partition a list of
paths into common categories:

- `markdown`: \*.md
- `nix`: \*.nix
- `rust`: \*.rs

### `flake-checker.lib.partitionToAttrs`

Given a template, produces a function that will partition a list into
an attrset of lists:

```nix
let
  inherit (nixpkgs.lib) optional hasSuffix;
in
flake-checker.lib.partitionToAttrs {
  markdown = path: optional (hasSuffix ".md" path) path;
  nix = path: optional (hasSuffix ".nix" path) path;
  rust = path: optional (hasSuffix ".rs" path) path;
}
```

### `flake-checker.lib.walkFlake`

Produces a flat list of all the files in a flake:

```nix
flake-checker.lib.walkFlake ./.
```

## Known limitations

- The checker-specific config files generated in Nix aren't exposed
  when running the check tools manually.

- rustfmt will try & fail to load "mod"s to other files. This can be
  worked around by applying `#[rustfmt::skip]` to each mod.
