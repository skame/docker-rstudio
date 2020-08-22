#!/bin/sh
if [ ! -e /etc/nslcd.conf ]; then
  sed -i 's/\(passwd:.*files\)/\1 ldap/' /etc/nsswitch.conf
  sed -i 's/\(group:.*files\)/\1 ldap/' /etc/nsswitch.conf
  sigil -p -f /etc/nslcd.conf-template > /etc/nslcd.conf
  chmod o-r /etc/nslcd.conf
fi 
exec /usr/sbin/nslcd -d 2>&1
