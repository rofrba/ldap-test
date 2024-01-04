#!/bin/sh
set -eux

# Si es la primera ejecución del contenedor y no hay volumen, se genera configuración de base
if [ ! -d /data/lib/ldap ]; then
  mkdir -p /data/lib /data/etc/openldap
  cp -ar /var/lib/ldap /data/lib
  cp -r /etc/ldap /data/etc/openldap
fi

rm -rf /var/lib/ldap && ln -s /data/lib/ldap /var/lib/ldap
rm -rf /etc/ldap && ln -s /data/etc/openldap /etc/ldap

/usr/bin/tini -- /usr/sbin/slapd -h "ldapi:/// ldap://0.0.0.0:389 ldaps://0.0.0.0:636" -d 256
