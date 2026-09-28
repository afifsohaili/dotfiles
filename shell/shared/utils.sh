function lsfilelimits() {
  lsof +c 0 | awk '{ print $2 " " $1; }' | sort -rn | uniq -c | sort -rn | head -20
}
