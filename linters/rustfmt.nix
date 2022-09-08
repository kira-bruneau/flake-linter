{ rustfmt, formats }:

{
  nativeBuildInputs = [ rustfmt ];
  settingsFormat = formats.toml { };
  fix = ''rustfmt --config-path "$config" "$path"'';
}
