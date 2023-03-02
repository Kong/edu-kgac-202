#!/bin/bash

# read -p "What is the consumer's name?" CONSUMER

# req=$(http -h $KONG_ADMIN_API_URL/consumers/$CONSUMER | head -1 )
# if [ "$req" != "HTTP/1.1 200 OK" ]; then
#   echo User $CONSUMER does not exist
# fi

CONSUMER=jane

HEADER=$(echo -n '{"alg":"RS256","typ":"JWT"}' | openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')
PAYLOAD=$(echo -n '{"iss":"'$CONSUMER-issuer'"}' | openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')
HEADER_PAYLOAD=$HEADER.$PAYLOAD
PEM=$(cat ./$CONSUMER.pem)
SIG=$(openssl dgst -sha256 -sign <(echo -n "${PEM}") <(echo -n "${HEADER_PAYLOAD}") | openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')
TOKEN=$HEADER.$PAYLOAD.$SIG
echo $TOKEN

