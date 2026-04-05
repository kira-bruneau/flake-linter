{ prettier, formats }:

{
  nativeBuildInputs = [ prettier ];
  settingsFormat = formats.json { };
  fix = ''prettier --config "$config" --write "$path"'';
}
