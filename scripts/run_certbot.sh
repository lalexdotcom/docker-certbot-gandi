#!/bin/bash

# Make sure a renewal interval is set before continuing.
if [ -z "$RENEWAL_INTERVAL" ]; then
    echo "RENEWAL_INTERVAL unset, using default of '8d'"
    RENEWAL_INTERVAL='8d'
fi

# Instead of trying to run 'cron' or something like that, just sleep and
# call on certbot after the defined interval.
while [ true ]; do
  # We require an email to be able to request a certificate.
  if [ -z "$LETSENCRYPT_EMAIL" ]; then
      error "LETSENCRYPT_EMAIL environment variable undefined; certbot will do nothing!"
      exit 1
  fi

  # We require an email to be able to request a certificate.
  if [ -z "$LETSENCRYPT_DOMAINS" ]; then
      error "LETSENCRYPT_DOMAINS environment variable undefined; certbot will do nothing!"
      exit 1
  fi

  ls -al /certbot-first-run
  if [ -f "/certbot-first-run/.first" ]
  then
    echo "First run"
  else
    echo "Not first run"
  fi

  if [ -f "/certbot-first-run/.first" ]
  then
    echo "Run certbot for first time"
    echo "Create certificates for $LETSENCRYPT_EMAIL $LETSENCRYPT_DOMAINS"
    echo "certbot_plugin_gandi:dns_api_key=$GANDI_API_KEY" > gandi.ini
    certbot certonly --non-interactive $CERTBOT_ADDITIONAL_ARGS --agree-tos -a certbot-plugin-gandi:dns --certbot-plugin-gandi:dns-credentials gandi.ini -m $LETSENCRYPT_EMAIL -d $LETSENCRYPT_DOMAINS --server https://acme-v02.api.letsencrypt.org/directory
    rm gandi.ini
    rm /certbot-first-run/.first
  else
    echo "Run certbot for renewal"
    echo "Renew certificates for $LETSENCRYPT_EMAIL $LETSENCRYPT_DOMAINS"
    echo "certbot_plugin_gandi:dns_api_key=$GANDI_API_KEY" > gandi.ini
    certbot renew -q -a certbot-plugin-gandi:dns --certbot-plugin-gandi:dns-credentials gandi.ini --server https://acme-v02.api.letsencrypt.org/directory
    rm gandi.ini
  fi
  # Create hard copies of SSL certificates in /ssl
  echo "Copy certificates to /ssl"
  rsync -avL --include "*/" --include "*.pem" --exclude '*' /etc/letsencrypt/live/ /ssl/
  # yes | cp -rL /etc/letsencrypt/live/** /ssl/ --verbose
  chown -R letsencrypt:letsencrypt /ssl
  chmod 700 -R /ssl
    # Finally we sleep for the defined time interval before checking the
    # certificates again.
    echo "Certbot will now sleep..."
    sleep "$RENEWAL_INTERVAL"
done

exit 0
