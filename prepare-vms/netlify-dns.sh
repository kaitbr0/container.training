#!/bin/sh

[ "$1" ] || {
  echo ""
  echo "Add a record in Netlify DNS."
  echo "This script is hardcoded to add a record to container.training".
  echo ""
  echo "Syntax:"
  echo "$0 <name> <ipaddr>"
  echo ""
  echo "Example to create a A record for eu.container.training:"
  echo "$0 eu 185.145.250.0"
  echo ""
  exit 1
}

NAME=$1.container.training
ADDR=$2

NETLIFY_USERID=$(jq .userId < ~/.config/netlify/config.json)
NETLIFY_TOKEN=$(jq -r .users[$NETLIFY_USERID].auth.token < ~/.config/netlify/config.json)

netlify() {
  URI=$1
  shift
  http https://api.netlify.com/api/v1/$URI "$@" "Authorization:Bearer $NETLIFY_TOKEN"
}

ZONE_ID=$(netlify dns_zones |
          jq -r '.[] | select ( .name == "container.training" ) | .id')

# It looks like if we create two identical records, then delete one of them,
# Netlify DNS ends up in a weird state (the name doesn't resolve anymore even
# though it's still visible through the API and the website?)

if netlify dns_zones/$ZONE_ID/dns_records | 
        jq '.[] | select(.hostname=="'$NAME'" and .type=="A" and .value=="'$ADDR'")' |
        grep .
then
  echo "It looks like that record already exists. Refusing to create it."
  exit 1
fi

netlify dns_zones/$ZONE_ID/dns_records type=A hostname=$NAME value=$ADDR ttl=300

netlify dns_zones/$ZONE_ID/dns_records | 
        jq '.[] | select(.hostname=="'$NAME'")'
