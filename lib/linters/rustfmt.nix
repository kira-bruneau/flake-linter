{
  rustfmt,
  moreutils,
  formats,
}:

{
  nativeBuildInputs = [
    rustfmt
    moreutils
  ];

  settingsFormat = formats.toml { };

  # Explicitly pass file contents through stdin, otherwise rustfmt
  # tries to recurse into child modules
  fix = ''rustfmt --config-path "$config" < "$path" | sponge "$out"'';
}
