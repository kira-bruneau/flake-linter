{ nixfmt-rfc-style, formats }:

{
  nativeBuildInputs = [ nixfmt-rfc-style ];
  settingsFormat = formats.flags { };
  fix = ''nixfmt $config "$path"'';
}
