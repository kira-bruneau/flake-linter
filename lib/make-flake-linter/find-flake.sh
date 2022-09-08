while [ ! -f flake.nix ]; do
  if [ $PWD == / ]; then
    echo "Couldn't find flake.nix"
    exit 1
  fi

  cd ..
done
