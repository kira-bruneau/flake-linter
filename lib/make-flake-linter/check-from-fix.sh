exit_code=$(($(<"$fix/exit_code")))

if [ "$exit_code" -ne 0 ]; then
  cat "$fix/out" "$fix/patch" >&2
  exit "$exit_code"
elif [ -s "$fix/patch" ]; then
  cat "$fix/patch" >&2
  exit 1
fi
