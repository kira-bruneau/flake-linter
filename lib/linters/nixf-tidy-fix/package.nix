{ rustPlatform }:

rustPlatform.buildRustPackage {
  name = "nixf-tidy-fix";
  src = ./src;
  cargoHash = "sha256-3DUAhKdlNb/c4sWlmH1K1J0m5PA21yMy+RBHiR8bALs=";
  meta.mainProgram = "nixf-tidy-fix";
}
