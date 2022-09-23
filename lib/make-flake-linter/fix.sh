exit_code=$(($(<"$fix/exit_code")))

if [ -s "$fix/patch" -o "$exit_code" -ne 0 ]; then
  echo -e "\033[1m┇ Fixing $path with $linter ┇\033[0m"

  if [ "$exit_code" -ne 0 ]; then
    cat "$fix/out" >&2
  fi

  reject_file=$(mktemp)
  patch "$path" "$fix/patch" \
    --quiet \
    --force \
    --no-backup-if-mismatch \
    --reject-file "$reject_file" \
    &>/dev/null

  if [ -s "$reject_file" ]; then
    echo 'Failed to apply patch:' >&2
    cat "$reject_file" >&2
    if [ "$exit_code" -eq 0 ]; then
      exit_code=1
    fi
  fi

  rm "$reject_file"
fi

exit "$exit_code"
