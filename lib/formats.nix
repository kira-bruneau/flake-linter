{ lib }:

let
  inherit (builtins) attrNames concatMap toString;

  inherit (lib) types;
in
{
  flags =
    { }:
    {
      type =
        with types;
        let
          value =
            nullOr (oneOf [
              bool
              int
              float
              str
              path
            ])
            // {
              description = "flag value (null, bool, int, float, string or path)";
            };
        in
        attrsOf value;

      generate =
        _name: flags:
        (concatMap (
          flag:
          let
            value = flags.${flag};
          in
          if value == null || value == false then
            [ ]
          else
            [ "--${flag}" ] ++ lib.optional (value != true) (toString value)
        ) (attrNames flags));
    };
}
