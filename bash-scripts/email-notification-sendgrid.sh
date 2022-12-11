#!/usr/bin/env bash

# Stop execution on any error
set -e

# Check if correct parameters were passed
# msg="\tUsage:\t$0 <SENDER> <RECIPIENT> <API_KEY>\n"
# if [ $# -ne 1 ]; then
#     echo -e $msg
#     exit -1
# else

    # Declare variables
    SENDER=wisnu@clade.ventures
    RECIPIENT=wisnu@clade.ventures
    SENDGRID_API_KEY=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

    function usage() {
        echo "ERROR: Missing or invalid arguments!"
        echo "Usage: ${0} SENDER RECIPIENT API_KEY (OPTIONAL)"
        exit 1
    }

    function send_email() {
        local EMAIL_API="https://api.sendgrid.com/v3/mail/send"

        local SUBJECT="Unit Test Result"

        local MESSAGE="<p> Hi </p> \
            <p> This is to notify you that the unit test result. </p> \
            <p> Sincerely yours, <br> DevOps Team </p>"

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
                --header "Authorization: Bearer ${SENDGRID_API_KEY}" \
                --header 'Content-Type: application/json' \
                --data "${REQUEST_DATA}" \
                --output /dev/null \
                --write-out "%{http_code}" 
        )

        if [[ "${CURL_HTTP_CODE}" -lt 200 || "${CURL_HTTP_CODE}" -gt 299 ]]; then
            echo "ERROR: Failed sending notification with error code ${CURL_HTTP_CODE}!"
            exit 1
        fi
    }

    send_email