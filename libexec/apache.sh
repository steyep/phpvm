#! /bin/sh
pushd $(dirname "$0") > /dev/null
  script_dir="$PWD"
  test -L "$0" && script_dir="$(dirname "$(readlink "$0")")"
  source $script_dir/config.sh
  source $CONFIG
popd > /dev/null

version="$1"
# Is Apache running?
APACHE_RUN=$(ps aux | grep httpd | grep -v grep)
# Does Apache require sudo?
APACHE_ROOT=$(echo "$APACHE_RUN" | awk '{ if ($1 == "root") print $1;}')

module=$(brew info $version | grep 'LoadModule')
if [[ "$module" ]]; then
  apache_config_bkup=$BACKUP/$(echo $APACHE_CONFIG | base64)
  test -f $apache_config_bkup || cp $APACHE_CONFIG $apache_config_bkup
  read load name path <<< $module
  # Comment out the current modules
  sed -E -i'.bak' s-^\(\[^#\]*php.+_module.+\)\$-#\ \\1-g $APACHE_CONFIG
  # If the module is already in the config, uncomment it
  if grep -E "$name.+$path" $APACHE_CONFIG > /dev/null; then
    sed -E -i'.bak' "s-.+$name.+$path.*-$load $name $path-" $APACHE_CONFIG
  # Otherwise, we need to add it
  else
    match=$(grep LoadModule $APACHE_CONFIG | tail -n 1 | sed 's_/_\\/_g')
    sed -i'.bak' -e "/${match}/a"$'\\\n'"$load $name $path"$'\n' $APACHE_CONFIG
  fi

  # Comment out PHP interpretters
  interpretter="$(echo $version | awk -F '[^0-9]+' '{ print "php"$2"-script" }')"
  sed -E -i'.bak' s_^\(\[^#\]*php.-script.+\)\$_#\ \\1_g $APACHE_CONFIG
  # If the interpretter is already in the config, uncomment it
  if grep -E "AddHandler.+$interpretter" $APACHE_CONFIG > /dev/null; then
    sed -E -i'.bak' "s_[^#]*#.*(AddHandler.+$interpretter.*)_\1_" $APACHE_CONFIG
  # Otherwise, we need to add it
  else
    for pattern in "AddHandler.*php" "LoadModule"; do
      match=$(grep -E $pattern $APACHE_CONFIG | tail -n 1 | sed 's_/_\\/_g')
      test "$match" && break
    done
    sed -i'.bak' -e "/${match}/a"$'\\\n'"AddHandler $interpretter .php"$'\n' $APACHE_CONFIG
  fi
  rm $APACHE_CONFIG.bak

  # Restart Apache - if it's running
  if [[ "$APACHE_RUN" ]]; then
    echo "Restarting Apache"
    [[ "$APACHE_ROOT" ]] &&
      sudo apachectl restart ||
      apachectl restart
  fi
fi