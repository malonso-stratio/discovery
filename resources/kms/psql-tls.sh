#!/bin/bash

log "INFO" "Obtaining and setting TLS secrets for SSL secured Postgres"
log "INFO" "$USER"

SSL_CLUSTER=${SSL_CLUSTER:="userland"}
SSL_INSTANCE=${TENANT_NAME:="crossdata-1"}
SSL_FQDN=${TENANT_NAME:="crossdata-1"}
SSL_FORMAT=${SSL_FORMAT:="PEM"}
POSTGRESQL_SSL_CERT_LOCATION="/root/kms"
POSTGRESQL_SSL_CERT_FILENAME=${POSTGRESQL_SSL_CERT_FILENAME:="$SSL_FQDN.pem"}
POSTGRESQL_SSL_KEY_LOCATION="/root/kms"
POSTGRESQL_SSL_KEY_FILENAME=${POSTGRESQL_SSL_KEY_FILENAME:="$SSL_FQDN.key"}
CA_BUNDLE_LOCATION=${CA_BUNDLE_LOCATION:="/root/kms"}
CA_BUNDLE_PEM_FILENAME=${CA_BUNDLE_PEM_FILENAME:="root.pem"}
CA_BUNDLE_CLUSTER=${CA_BUNDLE_CLUSTER:="ca-trust"}
CA_BUNDLE_INSTANCE=${CA_BUNDLE_INSTANCE:="default"}

# Rather we’ll convert the cert to the DER format and the key to pks8:
getCert $SSL_CLUSTER $SSL_INSTANCE $SSL_FQDN $SSL_FORMAT $POSTGRESQL_SSL_CERT_LOCATION
SSL_PEM_CERT="$POSTGRESQL_SSL_CERT_LOCATION/$POSTGRESQL_SSL_CERT_FILENAME"
SSL_PEM_KEY="$POSTGRESQL_SSL_KEY_LOCATION/$POSTGRESQL_SSL_KEY_FILENAME"
SSL_KEY="$POSTGRESQL_SSL_KEY_LOCATION/$SSL_FQDN.pk8"
openssl pkcs8 -topk8 -inform pem -outform der -in $SSL_PEM_KEY -out $SSL_KEY -nocrypt
log "INFO" "SSL cert and key downloaded"
getCAbundle $CA_BUNDLE_LOCATION "PEM" $CA_BUNDLE_PEM_FILENAME $CA_BUNDLE_CLUSTER $CA_BUNDLE_INSTANCE
log "INFO" "CA in PEM format downloaded"
SSL_ROOT_CERT="$CA_BUNDLE_LOCATION/$CA_BUNDLE_PEM_FILENAME"
chmod -R 777 $POSTGRESQL_SSL_CERT_LOCATION
chmod 777 $POSTGRESQL_SSL_CERT_LOCATION
chown -R root:root $POSTGRESQL_SSL_CERT_LOCATION
PG_URL="jdbc:postgresql://$PG_HOST:$PG_PORT/$PG_DATABASE?user=$PG_USER\\&ssl=true\\&sslmode=verify-full\\&sslcert=$SSL_PEM_CERT\\&sslkey=$SSL_KEY\\&sslrootcert=$SSL_ROOT_CERT"

if [[ -z "$MB_DB_CONNECTION_URI" ]]; then
   export MB_DB_CONNECTION_URI="postgres://$MB_DB_HOST:$MB_DB_PORT/$MB_DB_DBNAME?user=$MB_DB_USER&sslmode=verify-full&sslcert=$SSL_PEM_CERT&sslkey=$SSL_KEY&sslrootcert=$SSL_ROOT_CERT"
fi


#jdbc:postgresql://pg-0001.postgrestls.mesos:5432/postgres?user=dg-bootstrap&ssl=true&sslmode=verify-full&sslcert=/etc/sds/governance-postgresql-agent/secrets/dg-bootstrap.pem&sslkey=/etc/sds/governance-postgresql-agent/secrets/dg-bootstrap.pk8&sslrootcert=/etc/sds/governance-postgresql-agent/secrets/root.pem
