let
  inherit (builtins) stringLength substring;

  # Copied from: https://github.com/NixOS/nixpkgs/blob/master/lib/options.nix
  optional = cond: elem: if cond then [ elem ] else [ ];

  # Copied from: https://github.com/NixOS/nixpkgs/blob/master/lib/strings.nix
  hasSuffix =
    suffix: content:
    let
      lenContent = stringLength content;
      lenSuffix = stringLength suffix;
    in
    lenContent >= lenSuffix && substring (lenContent - lenSuffix) lenContent content == suffix;

  bash = path: optional (hasSuffix ".sh" path || hasSuffix ".bash" path) path;
  css = path: optional (hasSuffix ".css" path) path;
  html = path: optional (hasSuffix ".html" path || hasSuffix ".htm" path) path;
  javascript = path: optional (hasSuffix ".js" path || hasSuffix ".mjs" path) path;
  json = path: optional (hasSuffix ".json" path) path;
  less = path: optional (hasSuffix ".less" path) path;
  markdown = path: optional (hasSuffix ".md" path) path;
  mdx = path: optional (hasSuffix ".mdx" path) path;
  nix = path: optional (hasSuffix ".nix" path) path;
  react = path: optional (hasSuffix ".jsx" path || hasSuffix ".tsx" path) path;
  rust = path: optional (hasSuffix ".rs" path) path;
  sass = path: optional (hasSuffix ".scss" path || hasSuffix ".sass" path) path;
  typescript = path: optional (hasSuffix ".ts" path) path;
  vue = path: optional (hasSuffix ".vue" path) path;
  yaml = path: optional (hasSuffix ".yaml" path || hasSuffix ".yml" path) path;

  # TODO: Find a more efficient way of composing these (compile to regexp?)
  prettier =
    path:
    css path
    ++ html path
    ++ javascript path
    ++ json path
    ++ less path
    ++ markdown path
    ++ mdx path
    ++ react path
    ++ sass path
    ++ typescript path
    ++ vue path
    ++ yaml path;
in
{
  inherit
    bash
    css
    html
    javascript
    json
    less
    markdown
    mdx
    nix
    prettier
    react
    rust
    sass
    typescript
    vue
    yaml
    ;
}
