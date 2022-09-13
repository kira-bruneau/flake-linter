exit_code=$(($(<"$fix/exit_code")))

if [ "$exit_code" -ne 0 ]; then
  cat "$fix/out" "$fix/patch"
  exit "$exit_code"
elif [ -s "$fix/patch" ]; then
  cat "$fix/patch"
  exit 1
fi
