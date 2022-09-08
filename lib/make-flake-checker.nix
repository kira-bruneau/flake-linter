{ root
, settings
, extraCheckers ? { }
, pkgs
}:

pkgs.callPackage
  ({ lib
   , callPackage
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

      checkers = (import ../checkers { inherit callPackage; })
        // extraCheckers;

      nativeBuildInputs = concatMap
        (checker: checkers.${checker}.nativeBuildInputs or [ ])
        (attrNames settings);

      compiledCheckers = concatLists
        (attrValues
          (mapAttrs
            (checker:
              { paths ? [ ]
              , extraSettings ? { }
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
                    (settingsFormat.generate "config" extraSettings);
                in
                (map
                  (path:
                    let
                      src = root + "/${path}";

                      check =
                        if fix != null
                        then
                          runCommand "${checker}-${path}-check"
                            {
                              inherit fix;
                            }
                            ./check-from-fix.sh
                        else
                          runCommand "${checker}-${path}-check"
                            {
                              inherit checker nativeBuildInputs config path src;
                            }
                            args.check;

                      fix =
                        if args.fix != null
                        then
                          runCommand "${checker}-${path}-fix"
                            {
                              inherit checker nativeBuildInputs config path src;
                              fix = writeShellScript "${checker}-fix" args.fix;
                            }
                            ./compile-fix.sh
                        else null;
                    in
                    {
                      inherit checker path check fix;
                    })
                  paths)
              ) checkers.${checker})
            settings));

      check = runCommand "flake-checker-check"
        {
          nativeBuildInputs = map ({ check, ... }: check) compiledCheckers;
        }
        ''
          touch "$out"
        '';

      genericFixScript = writeShellScript "flake-checker-generic-fix" ''
        export PATH=${makeBinPath [
          coreutils
          findutils
          patch
        ]}

        . ${./find-flake.sh}

        find "$1" -type l -exec ${runtimeShell} \
          -c '\
            path="''${1#$0/}" \
            checker="''${path%%/*}" \
            path="''${path#*/}" \
            fix="$1" \
            ${./fix.sh} \
          ' \
          "$1" {} \;
      '';

      fixScript = writeShellScript "flake-checker-fix" ''
        ${genericFixScript} ${linkFarm "flake-checker-fix-outputs"
          (concatMap
            ({ checker, path, fix, ... }:
              if fix != null
              then [
                {
                  name = "${checker}/${path}";
                  path = fix;
                }
              ]
              else [])
            compiledCheckers)}
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
