{
  pkgs,
  coreutils,
  nixf,
  jq,
  formats,
}:

let
  nixf-tidy-fix = (pkgs.callPackage ./package.nix { });
in
{
  nativeBuildInputs = [
    coreutils
    jq
    nixf
    nixf-tidy-fix
  ];

  settingsFormat = formats.json { };

  fix = ''
    nixf-tidy-fix "$config" "$path"
  '';
}
