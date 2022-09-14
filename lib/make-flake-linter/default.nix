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
        concatMap
        map;

      inherit (lib)
        assertMsg
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

      compiledLinters = concatMap
        (linter:
          ({ nativeBuildInputs ? [ ]
           , settingsFormat ? null
           , check ? null
           , fix ? null
           , ...
           } @ args:

            assert assertMsg (check != null || fix != null) ''
              ${linter} is missing a check or fix command
            '';

            ({ paths ? [ ]
             , settings ? null
             }:

              assert assertMsg (settings != null -> settingsFormat != null) ''
                ${linter} was passed settings, but doesn't define a settingsFormat
              '';

              assert assertMsg (settings != null -> settingsFormat.type.check settings) ''
                ${linter}.settings must be a ${settingsFormat.type.description}
              '';

              let
                config = optionalString (settingsFormat != null)
                  (settingsFormat.generate "config"
                    (if settings != null
                    then settings
                    else
                      if settingsFormat.type.emptyValue.value != null
                      then settingsFormat.type.emptyValue.value
                      else { }));
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
                          ''
                            ${./check-from-fix.sh}
                            touch "$out"
                          ''
                      else
                        runCommand "${linter}-${path}-check"
                          {
                            inherit linter nativeBuildInputs config path src;
                          }
                          ''
                            ${args.check}
                            touch "$out"
                          '';

                    fix =
                      if args ? fix
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
                paths))
              settings.${linter})
            linters.${linter})
        (attrNames settings);

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

        exit_code=0
        while IFS= read -r -d $'\0' fix; do
          path="''${fix#$1/}"
          linter="''${path%%/*}" \
          path="''${path#*/}" \
          fix="$fix" \
          ${./fix.sh} || exit_code=1
        done < <(find "$1" -type l -print0)

        exit "$exit_code"
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
