#! /bin/sh
pushd $(dirname "$0") > /dev/null
  script_dir="$PWD"
  test -L "$0" && script_dir="$(dirname "$(readlink "$0")")"
  source $script_dir/config.sh
  source $CONFIG
popd > /dev/null

VERBOSE=0
SCRIPT=$(basename "$0")
USAGE=$(cat <<EOF_USAGE

Usage: $SCRIPT <options>
    
The following commands are supported:
   list, ls                  : List installed PHP versions.
   use [version]             : Specify a version of PHP to use.
   add [version]             : Specify a version of PHP to install.
   remove, rm [version]      : Specify a version of PHP to remove.
   revert                    : Revert Apache config
                             : to before phpvm was installed
   config <options>          : Configure \`$SCRIPT\`

The following options are supported:
   --verbose, -v             : Verbose output.
   --help, -h                : Show this message.
 
EOF_USAGE
)

show_help() {
  echo "$USAGE" >&2
  exit 0
}

installed_versions() {
  echo $(brew list | grep -E '^php\d+$')
}

list_versions() {
  active="\x1b[32;01m*\x1b[39;49;00m"
  local current=$(php -v | head -n1 | sed -E 's/PHP ([0-9]+)\.([0-9])+.+/php\1\2/')
  local list=$(installed_versions)
  for ver in ${list:-"Unable to locate any versions"}; do
    [[ "$ver" == "$current" ]] && 
      echo "$active $ver" ||
      echo "  $ver"
  done
  exit 0
}

# Unlink all brew php versions
unlink_all() {
  for ver in $(installed_versions); do
    [[ "$VERBOSE" == "1" ]] &&
      brew unlink $ver || 
      brew unlink $ver 1>/dev/null
  done
}

add_version() {
  # Make sure the version is not already installed
  if [[ "$(installed_versions)" == *"$version"* ]]; then
    echo "Oops! You've already installed \"$version\""
    echo "Did you mean  \`$SCRIPT use $version\`  ?"
    exit 0
  fi
  unlink_all
  if [[ "$APACHE_ENABLED" == "1" ]]; then
    brew install $version --with-httpd24
  else
    brew install $version
  fi
  echo "Installing extensions..."
  for ext in ${EXTENSIONS//,/ }; do
    ext=$version-$ext
    ext=(`brew search $ext | grep -Eo "$ext"`)
    if [[ "$ext" ]]; then
      echo "Installing $ext..."
      brew install $ext
    fi 
  done
  exit 0
}

remove_version() {
  # Make sure the version is not already installed
  if [[ "$(installed_versions)" != *"$version"* ]]; then
    echo "Oops! You don't have \"$version\" installed."
    exit 0
  fi
  brew unlink $version && brew rm $version
  local match=$(grep -E "LoadModule.*$version" $APACHE_CONFIG | sed 's_/_\\/_g')
  sed -i.bak "/${match}/d" $APACHE_CONFIG
  echo "Removed \"$version\"!"
  exit 0
}

restore_apache_config() {
  for path in $BACKUP/*; do
    config=$(echo $(basename $path) | base64 -D)
    test -w $config &&
      cp $path $config || 
      sudo cp $path $config
  done
  exit 0
}

while [[ $# > 0 ]]; do
key="$1"
  case $key in
    list|ls)
      list_versions ;;
    revert)
      restore_apache_config ;;
    use)
      version="$2"
      [[ "$version" ]] && shift 2 || shift ;;
    add)
      version="$2"
      [[ "$version" ]] && shift 2 || shift
      add_version ;;
    remove|rm)
      version="$2"
      [[ "$version" ]] && shift 2 || shift 
      remove_version ;;
    config)
      shift && set_config $@
      exit 0 ;;
    --verbose|-v)
      VERBOSE=1
      shift ;;
    *) show_help
  esac
done

test -z $version && show_help
if ! brew ls --versions "$version" > /dev/null; then 
  echo "$version not found."
  exit 0
fi

###
# CLI
###
# Unlink all brew php versions then link the specified version
unlink_all && brew link $version

# Add linked PHP version to $PATH
PHP_PATH=$(cat <<PHP_RC
PATH=\$(echo \$PATH | awk 'BEGIN { RS=":"; A=0; } { if (\$1 ~ "php") next; printf ((A == 0) ? "" : ":") \$1; A=1; }')
export PATH="$(brew --prefix homebrew/php/$version)/bin:\$PATH"
PHP_RC
)
save_config

###
# APACHE
###
if [[ "$APACHE_ENABLED" == "1" ]]; then
  # Do we need to run as root?
  test -w $APACHE_CONFIG &&
    sh $script_dir/apache.sh $version ||
    sudo sh $script_dir/apache.sh $version
fi

exec $SHELL
exit 0