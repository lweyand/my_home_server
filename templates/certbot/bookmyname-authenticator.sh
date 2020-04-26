#!/bin/bash
# https://fr.faqs.bookmyname.com/frfaqs/dyndns
auth_basic='{{ certbot_api_key }}'
ttl=500
wait=90
max_try=10
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

wget -q -O - "https://${auth_basic}@www.bookmyname.com/dyndns/?do=${action}&hostname=_acme-challenge.${CERTBOT_DOMAIN}&type=TXT&ttl=${ttl}&value=\"${CERTBOT_VALIDATION}\""
wget_status=$?

if [[ ${wget_status} -ne 0 ]]; then
  exit 2
fi

if [[ "${action}" == 'add' ]]; then
  # Check max_try times if dns is updated
  count=0
  found=0
  while (( count<max_try && found==0 )); do
    check_dns=$(dig _acme-challenge.${CERTBOT_DOMAIN} TXT | grep -A1 "ANSWER SECTION")
    if [[ 'x' != "x${check_dns}" && "${check_dns}" == *"${CERTBOT_VALIDATION}"* ]]; then
      found=1
    else
      ((count+=1))
      sleep ${wait}
    fi
  done
  if [[ ${found} -eq 1 ]]; then
    exit 0
  else
    exit 3
  fi
fi
