{ markdownlint-cli, formats }:

{
  nativeBuildInputs = [ markdownlint-cli ];
  settingsFormat = formats.json { };
  fix = ''markdownlint --config "$config" --fix "$path"'';
}
