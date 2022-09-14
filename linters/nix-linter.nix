{ lib, nix-linter }:

let
  inherit (builtins) concatMap;
  inherit (lib) types;
in
{
  nativeBuildInputs = [ nix-linter ];

  settingsFormat = {
    type = with types; listOf str;
    generate = _name: checks:
      (concatMap
        (check: [ "-W" check ])
        checks);
  };

  fix = ''nix-linter $config "$path"'';
}
