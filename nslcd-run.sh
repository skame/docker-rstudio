#!/bin/sh
if [ ! -e /etc/nslcd.conf ]; then
  grep 'compat ldap' /etc/nsswitch.conf || sed -i 's/compat/compat ldap/' /etc/nsswitch.conf
  sigil -p -f /etc/nslcd.conf-template > /etc/nslcd.conf
  chmod o-r /etc/nslcd.conf
fi 
exec /usr/sbin/nslcd -d 2>&1
