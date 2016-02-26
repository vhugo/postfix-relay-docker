#! /usr/bin/env bash
set -e # exit on error

# Variables
if [ -z "$SMTP_LOGIN" -o -z "$SMTP_PASSWORD" ] ; then
	echo "SMTP_LOGIN and SMTP_PASSWORD _must_ be defined"
	exit 1
fi
export SMTP_LOGIN SMTP_PASSWORD
export EXT_RELAY_HOST=${EXT_RELAY_HOST:-"email-smtp.us-east-1.amazonaws.com"}
export EXT_RELAY_PORT=${EXT_RELAY_PORT:-"25"}
export RELAY_HOST_NAME=${RELAY_HOST_NAME:-"relay.example.com"}
export ACCEPTED_NETWORKS=${ACCEPTED_NETWORKS:-"192.168.0.0/16 172.16.0.0/12 10.0.0.0/8"}
export USE_TLS=${USE_TLS:-"no"}
export TLS_VERIFY=${TLS_VERIFY:-"may"}
export DEFAULT_RECIPIENT=${DEFAULT_RECIPIENT:-""}

echo $RELAY_HOST_NAME > /etc/mailname

# Templates
j2 /root/conf/postfix-main.cf > /etc/postfix/main.cf
j2 /root/conf/sasl_passwd > /etc/postfix/sasl_passwd
postmap /etc/postfix/sasl_passwd

if [ $DEFAULT_RECIPIENT != "" ]; then
  j2 /root/conf/recipient_canonical > /etc/postfix/recipient_canonical
  postmap /etc/postfix/recipient_canonical
  echo -e "\nrecipient_canonical_maps = regexp:/etc/postfix/recipient_canonical" >> /etc/postfix/main.cf
fi

# Launch
rm -f /var/spool/postfix/pid/*.pid
/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisor-all.conf

# Showing logs
touch /var/log/mail.log
chown syslog:adm /var/log/mail.log
chmod 640 /var/log/mail.log
tail -fn0 /var/log/mail.log

exit 0
