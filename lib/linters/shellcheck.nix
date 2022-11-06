{ shellcheck, formats }:

{
  nativeBuildInputs = [ shellcheck ];
  settingsFormat = formats.flags { };
  fix = ''shellcheck $config "$path"'';
}
