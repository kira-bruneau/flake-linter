{ nixpkgs-fmt }:

{
  nativeBuildInputs = [ nixpkgs-fmt ];
  fix = ''nixpkgs-fmt "$path"'';
}
