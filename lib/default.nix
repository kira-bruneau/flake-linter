let
  inherit (builtins)
    attrNames
    attrValues
    concatLists
    foldl'
    listToAttrs
    map
    mapAttrs
    readDir
    stringLength
    substring;

  makeFlakeChecker = import ./make-flake-checker.nix;

  commonFlakePaths = import ./common-flake-paths.nix;

  partitionToAttrs = template: list:
    foldl'
      (attrs: elem:
        (mapAttrs
          (name: template: attrs.${name} ++ (template elem))
          template))
      (listToAttrs
        (map
          (name: { inherit name; value = [ ]; })
          (attrNames template)))
      list;

  walkFlake = root:
    let
      removeRoot = path:
        substring 1 (stringLength path) path;

      walkFlakeDir = dir:
        (concatLists
          (attrValues
            (mapAttrs
              (path: type:
                if type == "directory"
                then walkFlakeDir "${dir}/${path}"
                else [ (removeRoot "${dir}/${path}") ])
              (readDir (root + dir)))));
    in
    walkFlakeDir "";
in
{
  inherit makeFlakeChecker commonFlakePaths partitionToAttrs walkFlake;
}
