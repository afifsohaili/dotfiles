function vup () {
  if [[ -n $1 ]]
  then
    if [ "$DEBUG" = "1" ]; then
      printf "mafif\n$VPN_CREDENTIAL\ny" | /opt/cisco/anyconnect/bin/vpn -s connect ci$1.out.customink.com
    else
      printf "mafif\n$VPN_CREDENTIAL\ny" | /opt/cisco/anyconnect/bin/vpn -s connect ci$1.out.customink.com | grep state
    fi
  else
    print "Missing server location"
  fi
}

function vdown () {
  /opt/cisco/anyconnect/bin/vpn disconnect
}
