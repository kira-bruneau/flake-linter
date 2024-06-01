pkgs:

let
  inherit (builtins)
    attrNames
    concatMap
    foldl'
    listToAttrs
    map
    mapAttrs
    readDir
    stringLength
    substring
    ;

  makeFlakeLinter = import ./make-flake-linter { inherit pkgs linters; };

  linters =
    let
      callPackage = pkgs.newScope {
        inherit callPackage;
        formats = pkgs.formats // formats;
      };
    in
    callPackage ./linters { };

  formats = pkgs.callPackage ./formats.nix { };

  commonPaths = import ./common-paths.nix;

  partitionToAttrs =
    template: list:
    foldl' (attrs: elem: (mapAttrs (name: template: attrs.${name} ++ (template elem)) template)) (
      listToAttrs
      (
        map (name: {
          inherit name;
          value = [ ];
        }) (attrNames template)
      )
    ) list;

  # This is very similar to listFilesRecursive in nixpkgs, except that
  # it returns strings relative to root instead of paths.
  walkFlake =
    root:
    let
      removeRoot = path: substring 1 (stringLength path) path;

      walkFlakeDir =
        dir:
        let
          entries = readDir (root + dir);
        in
        (concatMap (
          path:
          if entries.${path} == "directory" then
            walkFlakeDir "${dir}/${path}"
          else
            [ (removeRoot "${dir}/${path}") ]
        ) (attrNames entries));
    in
    walkFlakeDir "";
in
{
  inherit
    makeFlakeLinter
    linters
    formats
    commonPaths
    partitionToAttrs
    walkFlake
    ;
}
