#!/bin/bash
#This is a quick and dirty bash script for automatically setting up sender-dependent authentication for all of your Mailgun domains.
#If you have multiple sets of credentials per domain or are not using the default postmaster user for SMTP, this script *may* not work for you.

#Below is the format for the 2 files created.
#/etc/postfix/sasl_passwd
#    @<domain> postmaster@<domain>:<smtp_password>
#    @<domain> postmaster@<domain>:<smtp_password>
#/etc/postfix/sender_relay
#    @<domain> [smtp.mailgun.org]:587
#    @<domain> [smtp.mailgun.org]:587

function sasl_passwd {
    awk -F'["@]' '/name/ {
        domain = sprintf($4); 
    } /smtp_login/ {
        user = sprintf($4);
    } /smtp_password/ {
        passwd = sprintf($4);
        printf "@" domain " " user "@" domain ":" passwd "\n"
    }' /tmp/mailgun
}

function sender_relay {
    awk -F\" '/name/ {
        print "@" $4 " [smtp.mailgun.org]:587"
    }' /tmp/mailgun
}

function catchall_domain {
    postconf -e "relayhost = [smtp.mailgun.org]:587"

    COUNT=$(grep -c "name" /tmp/mailgun)
    awk -F\" '/name/ {print $4}' /tmp/mailgun | nl
    DOMAIN_NUM=0

    until [[ "$DOMAIN_NUM" -ge 1 && "$DOMAIN_NUM" -le "$COUNT" ]]; do
        echo -e "\nWhich domain will be the catchall (enter the number that corresponds to the domain):"
        read -p "-> " DOMAIN_NUM
    done

    DOMAIN=$(awk -F\" '/name/ {print $4}' /tmp/mailgun | head -$DOMAIN_NUM | tail -n1)
    echo "[smtp.mailgun.org]:587 $(awk "/^@$DOMAIN/ {print \$2}" /etc/postfix/sasl_passwd)" >> /etc/postfix/sasl_passwd
    postmap /etc/postfix/sasl_passwd
}

clear
cat << EOF
This script will configure Postfix for sender-dependent authentication with Mailgun.

To complete your set-up you will need your API key from Mailgun:
https://help.mailgun.com/hc/en-us/articles/203380100-Where-can-I-find-my-API-key-and-SMTP-credentials-

EOF

if [ $(id -u) -ne 0 ]; then 
    echo "This script must be run as root."
    exit 126
fi

echo "What is your Mailgun API key?"
read -p "-> " MAILAPI


postconf -e "smtp_sasl_auth_enable = yes"
postconf -e "smtp_sasl_security_options = noanonymous"
postconf -e "smtp_sender_dependent_authentication = yes"
postconf -e "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"
postconf -e "sender_dependent_relayhost_maps = hash:/etc/postfix/sender_relay"

curl -s https://api.mailgun.net/v2/domains --user "api:$MAILAPI" > /tmp/mailgun

sasl_passwd > /etc/postfix/sasl_passwd
sender_relay > /etc/postfix/sender_relay

chmod 600 /etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sender_relay

postmap /etc/postfix/sender_relay

echo -e "\nWould you like to configure a catchall domain so that any sender domain NOT explicitly defined can still relay email?"
read -p "[Y/n] " CA
CA=$(echo $CA | grep -o ^. | tr '[:upper:]' '[:lower:]')

until [[ "$CA" == "y" || "$CA" == "n" ]]; do
    echo "Does not compute."
    read -p "[Y/n] " CA
    CA=$(echo $CA|grep -o ^.|tr '[:upper:]' '[:lower:]')
done

if [  "$CA" == "y" ]; then
    catchall_domain
else
    postconf -# relayhost
    postmap /etc/postfix/sasl_passwd
fi

systemctl restart postfix.service > /dev/null 2>&1 || /etc/init.d/postfix restart > /dev/null 2>&1
rm -f /tmp/mailgun
