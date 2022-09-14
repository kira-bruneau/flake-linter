{ nixfmt, formats }:

{
  nativeBuildInputs = [ nixfmt ];
  settingsFormat = formats.flags { };
  fix = ''nixfmt $config "$path"'';
}
