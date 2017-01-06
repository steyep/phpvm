CONFIG=$HOME/.phpvm
BACKUP=$(dirname $BASH_SOURCE)/backup

# Set some default values for the variables
PROFILE=
APACHE_CONFIG='/etc/apache2/httpd.conf'
APACHE_ENABLED=0

link_profile() {
  if [[ -f $PROFILE ]]; then
    [[ "$(grep $CONFIG $PROFILE)" ]] ||
    echo '\n[ -f '$CONFIG' ] && source '$CONFIG >> $PROFILE
  else
    echo "Unable to locate shell profile"
    echo "You may need to create one: \`touch $HOME/.profile\`"
    exit 1
  fi
}

set_config() {
  while [[ $# > 0 ]]; do
    key="$1"
    read var val <<< ${key/=/ }
    if [[ "$var" == "PROFILE" ]]; then
      PROFILE="$val"
      link_profile
    fi 
    case $var in 
      PROFILE|APACHE_ENABLED|APACHE_CONFIG)
        update_config $var $val ;;
    esac
    shift
  done
}

update_config() {
  local var="$1"
  local val="$2"
  sed -E -i'.bak' s-^$var=.+-$var="$val"- $CONFIG
  test -f $CONFIG.bak && rm $CONFIG.bak
}

save_config() {
test ! -d $(dirname "$CONFIG") && mkdir -p "$(dirname "$CONFIG")"

cat > $CONFIG <<END_CONFIG
PROFILE=$PROFILE
APACHE_ENABLED=$APACHE_ENABLED
APACHE_CONFIG=$APACHE_CONFIG

$PHP_PATH
END_CONFIG
}