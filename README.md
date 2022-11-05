# flake-linter

A linting framework designed to run checks & fixes incrementally in
your project (using Nix flakes).

> **NOTE:** Everything outlined in this README should work, but the
> interface hasn't been finalized. Please be aware of possible
> breakage when updating your flake, and refer back to this README.

## Prerequisites

- [Install nix](https://nixos.org/download.html)
- [Enable nix flakes](https://nixos.wiki/wiki/Flakes#Enable_flakes)

## Usage

### Add a flake.nix to your project

```nix
{
  description = "Flake linter demo";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    flake-linter.url = "gitlab:kira-bruneau/flake-linter";
  };

  outputs = { flake-utils, flake-linter }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        flake-linter-lib = flake-linter.lib.${system};

        paths = flake-linter-lib.partitionToAttrs
          {
            inherit (flake-linter-lib.commonPaths)
              markdown
              nix;
          }
          (flake-linter-lib.walkFlake ./.);

        linter = flake-linter-lib.makeFlakeLinter {
          root = ./.;
          settings = {
            markdownlint.paths = paths.markdown;
            nixpkgs-fmt.paths = paths.nix;
          };
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

### `makeFlakeLinter`

```nix
flake-linter-lib.makeFlakeLinter {
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
}
```

### `linters`

A set of builtin linters, used by `makeFlakeLinter`:

- [alejandra](https://github.com/kamadorueda/alejandra)
- [markdownlint](https://github.com/igorshubovych/markdownlint-cli)
- [nix-linter](https://github.com/Synthetica9/nix-linter)
- [nixfmt](https://github.com/serokell/nixfmt)
- [nixpkgs-fmt](https://github.com/nix-community/nixpkgs-fmt)
- [prettier](https://github.com/prettier/prettier)
- [rustfmt](https://github.com/rust-lang/rustfmt)
- [shfmt](https://github.com/mvdan/sh)

### `formats`

Custom formats provided by flake-linter, which can be used in
[`settingsFormat`](#flake-linterlibmakeflakelinter):

- **flags**: Generates a list of command line flags from an attrset
  (see [shfmt](./lib/linters/shfmt.nix) for an example of how this is
  used)

### `commonPaths`

A template that can be passed to
[`partitionToAttrs`](#flake-linterlibpartitiontoattrs), which will
partition a list of paths into common categories:

- **bash**: \*.sh, \*.bash
- **css**: \*.css
- **html**: \*.html, \*.htm
- **javascript**: \*.js, \*.mjs
- **json**: \*.json
- **less**: \*.less
- **markdown**: \*.md
- **mdx**: \*.mdx
- **nix**: \*.nix
- **prettier**: css, html, javascript, json, less, markdown, mdx,
  react, sass, typescript, vue, yaml
- **react**: \*.jsx, \*.tsx
- **rust**: \*.rs
- **sass**: \*.scss, \*.sass
- **typescript**: \*.ts
- **vue**: \*.vue
- **yaml**: \*.yaml, \*.yml

### `partitionToAttrs`

Given a template, produces a function that will partition a list into
an attrset of lists:

```nix
let
  inherit (nixpkgs.lib) optional hasSuffix;
in
flake-linter-lib.partitionToAttrs {
  markdown = path: optional (hasSuffix ".md" path) path;
  nix = path: optional (hasSuffix ".nix" path) path;
}
```

### `walkFlake`

Produces a flat list of all the files in a flake:

```nix
flake-linter-lib.walkFlake ./.
```

## Known limitations

- flake-linter runs checks & fixes inside Nix's sandbox, so any
  linters that require internet access, or access to dependencies to
  other files aren't supported. We plan on adding linter-specific
  dependency resolvers, but we have no plans to support internet
  access. It would introduce impurities that would prevent us from
  running checks & fixes incrementally.

  - rustfmt will try & fail to load "mod"s to other files. This can be
    worked around by applying `#[rustfmt::skip]` to each mod.

- flake-linter computes patches in isolation (per-linter &
  per-path). This allows us to run linters in parallel, but conflicts
  can occur if multiple linters fix the same lines in the same file,
  even when the fixes are identical. If the linters are compatible,
  running fix again should resolve the failure, but this can be
  annoying, and may even require multiple re-runs. We plan on reducing
  this annoyance with [associative & commutative
  patches](https://pijul.org/posts/2020-12-19-partials) and by
  automatically sequencing linters when conflicts occur after trying
  to run them in parallel.

- There's currently no way to access the linter-specific configuration
  generated by flake-linter outside of flake-linter. We're not focused
  on supporting this, but we do plan on making it possible run
  flake-linter as a command-line tool, and support integration with
  editors & IDEs.

- It's currently only possible to provide linter settings
  per-linter. We don't support path-specific settings, but we plan on
  adding support, using the `type.merge` function provided in each
  [`settingsFormat`](#flake-linterlibmakeflakelinter).
