if [ -s "$fix/patch" ]; then
  echo "Fixing $path with $checker"

  reject_file=$(mktemp)
  patch "$path" "$fix/patch" \
    --quiet \
    --force \
    --no-backup-if-mismatch \
    --reject-file "$reject_file" \
    &>/dev/null

  if [ -s "$reject_file" ]; then
    echo "Failed to apply patch:"
    cat "$reject_file"
  fi

  rm "$reject_file"
fi
