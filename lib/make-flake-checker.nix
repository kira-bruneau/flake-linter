{ root
, settings
, extraCheckers ? { }
, pkgs
}:

pkgs.callPackage
  ({ lib
   , stdenv
   , callPackage
   , runCommand
   , writeShellScript
   , coreutils
   }:
    let
      inherit (builtins)
        attrNames
        attrValues
        baseNameOf
        concatLists
        concatMap
        concatStringsSep
        map
        mapAttrs
        unsafeDiscardOutputDependency
        unsafeDiscardStringContext;

      inherit (lib)
        makeBinPath
        optionalAttrs
        optionalString;

      checkers = import ../checkers
        {
          inherit callPackage;
        } // extraCheckers;

      packages = concatMap
        (name: checkers.${name}.packages or [ ])
        (attrNames settings);

      compiledCheckers = concatLists
        (attrValues
          (mapAttrs
            (name:
              { paths ? [ ]
              , extraSettings ? { }
              }:
              let
                checker = checkers.${name};
                packages = checker.packages or [ ];

                commonContext = ''
                  export PATH=${makeBinPath packages}
                  ${optionalString (checker ? settingsFormat) ''
                    export config=${checker.settingsFormat.generate "config" extraSettings}
                  ''}
                '';

                fix = optionalAttrs (checker ? fix) writeShellScript "${name}-fix" ''
                  ${commonContext}
                  ${checker.fix}
                '';
              in
              (map
                (path: {
                  inherit path fix;

                  check = runCommand "${name}-${baseNameOf path}"
                    {
                      nativeBuildInputs = packages;
                    }
                    ''
                      (
                        ${commonContext}
                        export path=${root + "/${path}"}
                        path=${root + "/${path}"} ${checker.check}
                      ) && touch "$out"
                    '';
                })
                paths))
            settings));

      check = derivation {
        system = stdenv.buildPlatform.system;
        name = "flake-checker";
        nativeBuildInputs = map ({ check, ... }: check) compiledCheckers;
        builder = "${coreutils}/bin/touch";
        args = [ (placeholder "out") ];
      };

      fix = writeShellScript "fix" ''
        while [ ! -f flake.nix ]; do
          if [ $PWD == / ]; then
            echo "Couldn't find flake.nix"
            exit 1
          fi

          cd ..
        done

        ${concatStringsSep ""
          (concatMap
            ({ path, check, fix }:
              if fix != null
              then [
                ''
                  if ! [ -e ${unsafeDiscardStringContext check} ]; then
                    (
                      export path=${path}
                      ${fix}
                    )
                  fi
                ''
              ]
              else []
            )
            compiledCheckers)}

        nix-build --no-out-link ${unsafeDiscardOutputDependency check.drvPath} &>/dev/null
      '';
    in
    {
      inherit packages check;

      fix = {
        type = "app";
        program = toString fix;
      };
    })
{ }
