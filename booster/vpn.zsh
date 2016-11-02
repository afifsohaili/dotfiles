function vup () {
  if [[ -n $1 ]]
  then
    printf "mafif\n$VPN_CREDENTIAL\ny" | /opt/cisco/anyconnect/bin/vpn -s connect ci$1.out.customink.com
  else
    print "Missing server location"
  fi
}

function vdown () {
  /opt/cisco/anyconnect/bin/vpn disconnect
}
