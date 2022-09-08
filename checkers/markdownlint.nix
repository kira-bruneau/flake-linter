{ nodePackages, formats }:

{
  nativeBuildInputs = [ nodePackages.markdownlint-cli ];
  settingsFormat = formats.json { };
  fix = ''markdownlint --config "$config" --fix "$path"'';
}
