mkdir -p $(dirname "$path") "$out"

# TODO: Don't copy, use overlayfs to create a CoW layer that just
# captures the changes
cp -R --no-preserve=mode,ownership "$src" "$path"

out="$path" "$fix" &>"$out/out" || exit_code=$?
echo "$exit_code" >"$out/exit_code"

diff -u --label "$path" "$src" --label "$path" "$path" >"$out/patch" || :
