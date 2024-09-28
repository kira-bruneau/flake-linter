{ rustPlatform }:

rustPlatform.buildRustPackage {
  name = "nixf-tidy-fix";
  src = ./src;
  cargoHash = "sha256-M9PXt3fSUZW95Y0GruHrYvRw73X/ohiZNm5ZWhzSVgg=";
  meta.mainProgram = "nixf-tidy-fix";
}
