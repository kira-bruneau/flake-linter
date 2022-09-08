{ nodePackages, formats }:

{
  nativeBuildInputs = [ nodePackages.prettier ];
  settingsFormat = formats.json { };
  fix = ''prettier --config "$config" --write "$path"'';
}
