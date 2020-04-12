#!/bin/bash
# https://fr.faqs.bookmyname.com/frfaqs/dyndns
auth_basic='{{ certbot_api_key }}'
ttl=500
action=''

if [[ 'x' != "x${1}" ]]; then
    case ${1} in
    add)
        action='add'
        ;;
    del)
        action='remove'
        ;;
    *)
        echo "Invalid action: [${1}]"
        exit 1
        ;;
    esac
fi

wget  -q -O - "https://${auth_basic}@www.bookmyname.com/dyndns/?do=${action}&hostname=_acme-challenge.${CERTBOT_DOMAIN}&type=TXT&ttl=${ttl}&value=\"${CERTBOT_VALIDATION}\""

# Sleep to make sure the change has time to propagate over to DNS
sleep ${ttl}