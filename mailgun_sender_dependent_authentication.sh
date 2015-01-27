#!/bin/bash
#This is an EXTREMELY dirty bash script for automatically setting up sender dependent authentication for all of your Mailgun domains.
clear
version=$(grep -o "release [6-7]" /etc/redhat-release|cut -d' ' -f2)

read -p "Is this your first time configuring Mailgun on this server? [Y/n]: " ANS
if [ "$ANS" == "y" ] || [ "$ANS" == "Y" ]; then
cat >> /etc/postfix/main.cf << EOF
smtp_sasl_auth_enable = yes
relayhost = [smtp.mailgun.org]:587
smtp_sasl_security_options = noanonymous
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
sender_dependent_relayhost_maps = hash:/etc/postfix/sender_relay
smtp_sender_dependent_authentication = yes
EOF
else
cat << EOF

Be certian that you have the following entries in the /etc/postfix/main.cf file:

smtp_sasl_auth_enable = yes
relayhost = [smtp.mailgun.org]:587
smtp_sasl_security_options = noanonymous
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
sender_dependent_relayhost_maps = hash:/etc/postfix/sender_relay
smtp_sender_dependent_authentication = yes

EOF
fi

echo "What is your Mailgun API key? The key starts with 'key-' and can be found under the 'My Account' section of your Mailgun control panel."
read -p "-> " MAILAPI

paste <(curl -s https://api.mailgun.net/v2/domains --user "api:$MAILAPI"|awk -F\" '/smtp_login/ {print $4}') <(curl -s https://api.mailgun.net/v2/domains --user "api:$MAILAPI"|awk -F\" '/smtp_password/ {print $4}')|awk -F'[@\t]' '{print "@" $2 " postmaster@" $2 ":" $3}' > /etc/postfix/sasl_passwd

paste <(curl -s https://api.mailgun.net/v2/domains --user "api:$MAILAPI"|awk -F\" '/smtp_login/ {print $4}') <(curl -s https://api.mailgun.net/v2/domains --user "api:$MAILAPI"|awk -F\" '/smtp_password/ {print $4}')|awk -F'[@\t]' '{print "@" $2 " [smtp.mailgun.org]:587"}' > /etc/postfix/sender_relay

chmod 600 /etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sender_relay

postmap /etc/postfix/sasl_passwd
postmap /etc/postfix/sender_relay

case $version in
'6')
    /etc/init.d/postfix restart
;;
'7')
    systemctl restart postfix.service
;;
esac
