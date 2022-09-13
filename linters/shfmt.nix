{ shfmt, formats }:

{
  nativeBuildInputs = [ shfmt ];
  settingsFormat = formats.flags { };
  fix = ''shfmt $config --write "$path"'';
}
