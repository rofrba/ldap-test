#!/bin/sh
set -eux

readonly DATA_DIR="/bootstrap/data"
readonly CONFIG_DIR="/bootstrap/config"

# readonly LDAP_DOMAIN=gob.ar
readonly LDAP_BINDDN="cn=admin,dc=example,dc=com"
readonly LDAP_SECRET=welcome

readonly LDAP_SSL_KEY="/etc/ldap/ssl/ldap.key"
readonly LDAP_SSL_CERT="/etc/ldap/ssl/ldap.crt"


reconfigure_slapd() {
    echo "Reconfigure slapd..."
    cat <<EOL | debconf-set-selections
slapd slapd/internal/generated_adminpw password ${LDAP_SECRET}
slapd slapd/internal/adminpw password ${LDAP_SECRET}
slapd slapd/password2 password ${LDAP_SECRET}
slapd slapd/password1 password ${LDAP_SECRET}
slapd slapd/dump_database_destdir string /var/backups/slapd-VERSION
slapd slapd/backend string HDB
slapd slapd/purge_database boolean true
slapd slapd/move_old_database boolean true
slapd slapd/allow_ldap_v2 boolean false
slapd slapd/no_configuration boolean false
slapd slapd/dump_database select when needed
EOL

    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure slapd
}


# configure_tls() {
#     echo "Configure TLS..."
#     ldapmodify -Y EXTERNAL -H ldapi:/// -f ${CONFIG_DIR}/tls.ldif -Q
# }


# configure_logging() {
#     echo "Configure logging..."
#     ldapmodify -Y EXTERNAL -H ldapi:/// -f ${CONFIG_DIR}/logging.ldif -Q
# }

# configure_msad_features(){
#   echo "Configure MS-AD Extensions"
#   ldapmodify -Y EXTERNAL -H ldapi:/// -f ${CONFIG_DIR}/msad.ldif -Q
# }

# configure_admin_config_pw(){
#   echo "Configure admin config password..."
#   adminpw=$(slappasswd -h {SSHA} -s "${LDAP_SECRET}")
#   adminpw=$(printf '%s\n' "$adminpw" | sed -e 's/[\/&]/\\&/g')
#   sed -i s/ADMINPW/${adminpw}/g ${CONFIG_DIR}/configadminpw.ldif
#   ldapmodify -Y EXTERNAL -H ldapi:/// -f ${CONFIG_DIR}/configadminpw.ldif -Q
# }

# configure_memberof_overlay(){
#   echo "Configure memberOf overlay..."
#   ldapmodify -Y EXTERNAL -H ldapi:/// -f ${CONFIG_DIR}/memberof.ldif -Q
# }

# load_initial_data() {
#     echo "Load data..."
#     local data=$(find ${DATA_DIR} -maxdepth 1 -name \*_\*.ldif -type f | sort)
#     for ldif in ${data}; do
#         echo "Processing file ${ldif}..."
#         ldapadd -x -H ldapi:/// \
#           -D ${LDAP_BINDDN} \
#           -w ${LDAP_SECRET} \
#           -f ${ldif}
#     done
# }

configure_init() {



  echo "Creando configuración inicial"
  ldapmodify -Y EXTERNAL -H ldapi:/// -f ${DATA_DIR}/01.ldif

  ldapmodify -Y EXTERNAL -H ldapi:/// -f ${DATA_DIR}/02.ldif

  ldapadd -Q -Y EXTERNAL -H ldapi:/// -f ${DATA_DIR}/03.ldif
  ldapadd -x -H ldapi:/// -D cn=admin,ou=admins,dc=example,dc=com -w welcome -f /config/04.ldif

  
}



# External volume mounting DB
if [ ! -f /data/lib/ldap/DB_CONFIG ]; then
#Puesta inicial
  reconfigure_slapd
  slapd -h "ldapi:///" -u root -g root
  configure_init
  kill -INT `cat /run/slapd/slapd.pid` && sleep 1

  #Creacion de directorio y copia de archivos
  mkdir -p /data/lib /data/etc
  cp -R /var/lib/ldap /data/lib
  cp -R /etc/ldap /data/etc
  mv /data/etc/ldap /data/etc/openldap
fi

rm -rf /var/lib/ldap && ln -s /data/lib/ldap /var/lib/ldap
rm -rf /etc/ldap && ln -s /data/etc/openldap /etc/ldap

.

/usr/bin/tini -- /usr/sbin/slapd -h "ldapi:/// ldap://0.0.0.0:389 ldaps://0.0.0.0:636" -d ${LOG_LEVEL}
