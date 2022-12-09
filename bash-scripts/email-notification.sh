#!/usr/bin/env bash

# Stop execution on any error
set -e

    # Declare variables
    URL=$1
    SENDER=$2
    RECIPIENT=$3


    function usage() {
        echo "ERROR: Missing or invalid arguments!"
        echo "Usage: ${0} URL SENDER RECIPIENT PORT (OPTIONAL)"
        exit 1
    }

    function send_email() {

        echo "INFO: Sending out notification via e-mail"
        local CURL_HTTP_CODE
        CURL_HTTP_CODE=$(
            curl -s \
                --url "$URL" \
                --mail-from "$SENDER" \
                --mail-rcpt "$RECIPIENT" \
                --upload-file - 

                <<EOF
                From: Magic Elves <wissnusetiawan@gmail.com>
                To: Wisnu Inbox <wisnu@clade.ventures>
                Subject: Publish Result Unit Test
                Content-Type: multipart/alternative; boundary="boundary-string"

                --boundary-string
                Content-Type: text/plain; charset="utf-8"
                Content-Transfer-Encoding: quoted-printable
                Content-Disposition: inline

                Congrats for sending test email!

                Inspect it us

                Good luck! Hope it works.
                --boundary-string--
EOF
        )


    }
    
    send_email
