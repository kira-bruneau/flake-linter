# flake-linter

Incrementally run checks & fixes in your Nix flake (only on changed
files).

> **NOTE:** Everything outlined in this README should work, but the
> interface hasn't been finalized. Please be aware of possible
> breakage when updating your flake, and refer back to this README.

## Usage

```nix
{
  description = "Flake linter demo";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    flake-linter.url = "gitlab:kira-bruneau/flake-linter";
    nixpkgs.url = "nixpkgs/release-22.05";
  };

  outputs = { self, flake-utils, flake-linter, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        paths = flake-linter.lib.partitionToAttrs
          {
            inherit (flake-linter.lib.commonFlakePaths)
              markdown
              nix;
          }
          (flake-linter.lib.walkFlake ./.);

        linter = flake-linter.lib.makeFlakeLinter {
          root = ./.;

          settings = {
            markdownlint.paths = paths.markdown;
            nixpkgs-fmt.paths = paths.nix;
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

### `flake-linter.lib.makeFlakeLinter`

```nix
flake-linter.lib.makeFlakeLinter {
  root = ./.;

  settings = {
    my-linter = {
      # Paths to lint, relative to `root`
      paths = [ ];

      # Linter-specific configuration
      settings = {};
    };
  };

  # Optional
  extraLinters = {
    my-linter = {
      nativeBuildInputs = with pkgs; [ my-linter ];

      # Optional, provides `$config` which will be generated from `settings`
      settingsFormat = pkgs.formats.json { };

      # Optional, automatically derived from fix output when not defined
      check = ''my-linter --config "$config" --check "$src"'';

      # Required if check isn't defined
      fix = ''my-linter --config "$config" --fix "$path"'';
    };
  };

  inherit pkgs;
}
```

#### Builtin Linters

- [alejandra](https://github.com/kamadorueda/alejandra)
- [markdownlint](https://github.com/igorshubovych/markdownlint-cli)
- [nixpkgs-fmt](https://github.com/nix-community/nixpkgs-fmt)
- [prettier](https://github.com/prettier/prettier)
- [rustfmt](https://github.com/rust-lang/rustfmt)
- [shfmt](https://github.com/mvdan/sh)

### `flake-linter.lib.commonFlakePaths`

A template that can be passed to
[partitionToAttrs](#partitionToAttrs), which will partition a list of
paths into common categories:

- `bash`: \*.sh, \*.bash
- `markdown`: \*.md
- `nix`: \*.nix
- `rust`: \*.rs

### `flake-linter.lib.partitionToAttrs`

Given a template, produces a function that will partition a list into
an attrset of lists:

```nix
let
  inherit (nixpkgs.lib) optional hasSuffix;
in
flake-linter.lib.partitionToAttrs {
  bash = path: optional (hasSuffix ".sh" path || hasSuffix ".bash" path) path;
  markdown = path: optional (hasSuffix ".md" path) path;
  nix = path: optional (hasSuffix ".nix" path) path;
  rust = path: optional (hasSuffix ".rs" path) path;
}
```

### `flake-linter.lib.walkFlake`

Produces a flat list of all the files in a flake:

```nix
flake-linter.lib.walkFlake ./.
```

## Known limitations

- The linter-specific config files generated in Nix aren't exposed
  when running the linters manually.

- rustfmt will try & fail to load "mod"s to other files. This can be
  worked around by applying `#[rustfmt::skip]` to each mod.
