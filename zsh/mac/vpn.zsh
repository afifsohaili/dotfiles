function vup () {
  if [ "$DEBUG" = "1" ]; then
    printf "2\nmafif\n$VPN_CREDENTIAL\ny" | /opt/cisco/anyconnect/bin/vpn -s connect vpn.out.customink.com
  else
    printf "2\nmafif\n$VPN_CREDENTIAL\ny" | /opt/cisco/anyconnect/bin/vpn -s connect vpn.out.customink.com | grep state
  fi
}
alias vpe="vup"

function vdown () {
  /opt/cisco/anyconnect/bin/vpn disconnect
}
