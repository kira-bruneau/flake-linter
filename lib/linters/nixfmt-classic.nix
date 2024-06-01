{ nixfmt-classic, formats }:

{
  nativeBuildInputs = [ nixfmt-classic ];
  settingsFormat = formats.flags { };
  fix = ''nixfmt $config "$path"'';
}
