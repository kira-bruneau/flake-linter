{ root
, settings
, extraLinters ? { }
, pkgs
}:

pkgs.callPackage
  ({ lib
   , pkgs
   , newScope
   , writeShellScript
   , runCommand
   , coreutils
   , findutils
   , patch
   , runtimeShell
   , linkFarm
   }:
    let
      inherit (builtins)
        attrNames
        attrValues
        concatLists
        concatMap
        map
        mapAttrs;

      inherit (lib)
        escapeShellArg
        makeBinPath
        optionalString;

      callPackage = newScope {
        formats = pkgs.formats // (import ./formats.nix {
          inherit lib;
        });
      };

      linters = (import ../../linters { inherit callPackage; })
        // extraLinters;

      nativeBuildInputs = concatMap
        (linter: linters.${linter}.nativeBuildInputs or [ ])
        (attrNames settings);

      compiledLinters = concatLists
        (attrValues
          (mapAttrs
            (linter:
              { paths ? [ ]
              , settings ? { }
              }:
              ({ nativeBuildInputs ? [ ]
               , settingsFormat ? null
               , check ? null
               , fix ? null
               , ...
               } @ args:
                assert check != null || fix != null;
                let
                  config = optionalString (settingsFormat != null)
                    (settingsFormat.generate "config" settings);
                in
                (map
                  (path:
                    let
                      src = root + "/${path}";

                      check =
                        if fix != null
                        then
                          runCommand "${linter}-${path}-check"
                            {
                              inherit fix;
                            }
                            ./check-from-fix.sh
                        else
                          runCommand "${linter}-${path}-check"
                            {
                              inherit linter nativeBuildInputs config path src;
                            }
                            args.check;

                      fix =
                        if args.fix != null
                        then
                          runCommand "${linter}-${path}-fix"
                            {
                              inherit linter nativeBuildInputs config path src;
                              fix = writeShellScript "${linter}-fix" args.fix;
                            }
                            ./compile-fix.sh
                        else null;
                    in
                    {
                      inherit linter path check fix;
                    })
                  paths)
              ) linters.${linter})
            settings));

      check = runCommand "flake-linter-check"
        {
          nativeBuildInputs = map ({ check, ... }: check) compiledLinters;
        }
        ''
          touch "$out"
        '';

      genericFixScript = writeShellScript "flake-linter-generic-fix" ''
        export PATH=${makeBinPath [
          coreutils
          findutils
          patch
        ]}

        . ${./find-flake.sh}

        find "$1" -type l -exec ${runtimeShell} \
          -c '\
            path="''${1#$0/}" \
            linter="''${path%%/*}" \
            path="''${path#*/}" \
            fix="$1" \
            ${./fix.sh} \
          ' \
          "$1" {} \;
      '';

      fixScript = writeShellScript "flake-linter-fix" ''
        ${genericFixScript} ${linkFarm "flake-linter-fix-outputs"
          (concatMap
            ({ linter, path, fix, ... }:
              if fix != null
              then [
                {
                  name = "${linter}/${path}";
                  path = fix;
                }
              ]
              else [])
            compiledLinters)}
      '';

      fix = {
        type = "app";
        program = toString fixScript;
      };
    in
    {
      inherit nativeBuildInputs check fix;
    })
{ }
