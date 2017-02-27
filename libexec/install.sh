#! /bin/sh
pushd $(dirname "$0") > /dev/null
  script_dir="$PWD"
  test -L "$0" && script_dir="$(dirname "$(readlink "$0")")"
  source $script_dir/config.sh
popd > /dev/null

# Make sure homebrew is installed
if ! command -v brew >/dev/null; then
  echo "Err: No homebrew detected"
  echo "     Visit http://brew.sh/ for more info"
  exit 1
fi

get_apache() {
  local config="$(apachectl -V | grep SERVER_CONFIG_FILE | awk -F'"' '{ printf $0=$2 }')"
  [[ ! "$config" || ! -f "$config" ]] && unset config
  # If Apache is running with the -f option, use that config
  [[ "$(ps ax | grep httpd)" =~ .*-f[[:space:]]+([^[:space:]]+).* ]] && 
    test -f ${BASH_REMATCH[1]} && config="${BASH_REMATCH[1]}"
  # Use default if empty
  [[ ! "$config" ]] && config=$APACHE_CONFIG
  echo $config
}

# Get profile
get_profile() {
  source $script_dir/get_profile.sh
}

test -d $BACKUP || mkdir $BACKUP
PROFILE=$(get_profile)
APACHE_CONFIG=$(get_apache)
link_profile && save_config