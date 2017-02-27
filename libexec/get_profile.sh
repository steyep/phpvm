#! /bin/sh
shell=$(basename $SHELL)
profile=
if [[ "$shell" == "bash" ]]; then
  if [ -f "$HOME/.bashrc" ]; then
      profile="$HOME/.bashrc"
  elif [ -f "$HOME/.bash_profile" ]; then
    profile="$HOME/.bash_profile"
  fi
elif [ "$shell" = "zsh" ]; then
  profile="$HOME/.zshrc"
fi

if [ -z "$profile" ]; then
  if [ -f "$HOME/.profile" ]; then
    profile="$HOME/.profile"
  elif [ -f "$HOME/.bashrc" ]; then
    profile="$HOME/.bashrc"
  elif [ -f "$HOME/.bash_profile" ]; then
    profile="$HOME/.bash_profile"
  elif [ -f "$HOME/.zshrc" ]; then
    profile="$HOME/.zshrc"
  fi
fi
echo $profile