{ rustPlatform }:

rustPlatform.buildRustPackage {
  name = "nixf-tidy-fix";
  src = ./src;
  cargoHash = "sha256-OCwDgWtqEsg/32cMWDxllYZhUWbRDhfdZ+N2AMsJxnU=";
  meta.mainProgram = "nixf-tidy-fix";
}
