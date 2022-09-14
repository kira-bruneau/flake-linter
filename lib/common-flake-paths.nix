let
  inherit (builtins)
    stringLength
    substring;

  # Copied from: https://github.com/NixOS/nixpkgs/blob/master/lib/options.nix
  optional = cond: elem: if cond then [ elem ] else [ ];

  # Copied from: https://github.com/NixOS/nixpkgs/blob/master/lib/strings.nix
  hasSuffix =
    suffix:
    content:
    let
      lenContent = stringLength content;
      lenSuffix = stringLength suffix;
    in
    lenContent >= lenSuffix &&
    substring (lenContent - lenSuffix) lenContent content == suffix;
in
{
  bash = path: optional (hasSuffix ".sh" path || hasSuffix ".bash" path) path;
  markdown = path: optional (hasSuffix ".md" path) path;
  nix = path: optional (hasSuffix ".nix" path) path;
  rust = path: optional (hasSuffix ".rs" path) path;
}
