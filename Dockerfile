# FROM debian:buster-slim
FROM debian:buster-slim

# Install slapd and requirements
RUN apt-get update \
	&& apt-get dist-upgrade -y \
    && DEBIAN_FRONTEND=noninteractive apt-get \
        install -y --no-install-recommends \
            slapd \
            ldap-utils \
            openssl \
            ca-certificates \
            tini \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir /etc/ldap/ssl /bootstrap

# ADD bootstrap files
ADD ./bootstrap /bootstrap

# Initialize LDAP with data
# RUN /bin/bash /bootstrap/slapd-init.sh

#VOLUME ["/data/etc", "/data/lib"]

EXPOSE 389 636

#USER openldap


# ENTRYPOINT ["/usr/bin/tini", "--", "/usr/sbin/slapd"]
# CMD ["-h", "ldapi:/// ldap://0.0.0.0:389 ldaps://0.0.0.0:636", "-d", "256"]
ENTRYPOINT ["sh", "-x", "/bootstrap/slapd-init.sh"]

# HEALTHCHECK CMD ldapsearch -H ldap://127.0.0.1:10389 -D cn=admin,dc=planetexpress,dc=com -w GoodNewsEveryone -b cn=admin,dc=planetexpress,dc=com
