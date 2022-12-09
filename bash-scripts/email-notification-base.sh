#!/usr/bin/env bash

# Stop execution on any error
set -e

    # Declare variables
    SENDER=$1
    RECIPIENT=$2
    API_KEY=$3

    function usage() {
        echo "ERROR: Missing or invalid arguments!"
        echo "Usage: ${0} URL SENDER RECIPIENT PORT (OPTIONAL)"
        exit 1
    }

    function send_email() {
        local EMAIL_API="https://api.sendgrid.com/v3/mail/send"

        local SUBJECT="KeyVault secret ${SECRET} about to expire"

        local MESSAGE="<p> Dear Site Reliability Engineer, </p> \
            <p> This is to notify you that the Key Vault secret <b>${SECRET}</b> will expire on <b>${SECRET_EXPIRY_DATE_SHORT}</b>. </p> \
            <p> Please ensure the secret is rotated in a timely fashion. There are ${DATE_DIFF} days remaining. </p> \
            <p> Sincerely yours, <br>DevOps Enterprise </p>"

        local REQUEST_DATA='{
            "personalizations": [
                {
                    "to": [{"email": "'${RECIPIENT}'"}],
                    "dynamic_template_data": { "first_name": "Operations" }
                }
            ],
            "from": {"email": "'${SENDER}'"},
            "subject":"'${SUBJECT}'",
            "content": [{"type": "text/html", "value": "'${MESSAGE}'"}]
        }'

        echo "INFO: Sending out notification via e-mail"
        local CURL_HTTP_CODE
        CURL_HTTP_CODE=$(
            curl \
                --request POST \
                --url "${EMAIL_API}" \
                --header "Authorization: Bearer ${API_KEY}" \
                --header "Content-Type: application/json" \
                --data "${REQUEST_DATA}" \
                --output /dev/null \
                --write-out "%{http_code}" \
                --silent
        )

        if [[ "${CURL_HTTP_CODE}" -lt 200 || "${CURL_HTTP_CODE}" -gt 299 ]]; then
            echo "ERROR: Failed sending notification with error code ${CURL_HTTP_CODE}!"
            exit 1
        fi
    }
