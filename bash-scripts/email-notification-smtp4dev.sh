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

    local result=$( cat /home/vsts/work/_temp/cchtml/index.html )

    echo "INFO: Sending out notification via e-mail"
    curl \
    --url "$URL" \
    --mail-from "$SENDER" \
    --mail-rcpt "$RECIPIENT" \
    --upload-file - << EOF
From: "Magic" <$SENDER>
To: "Wisnu" <$RECIPIENT>
Subject: Publish Result Unit Test
Content-Type: multipart/alternative; boundary="boundary-string"

--boundary-string
Content-Type: text/html; charset="utf-8"
Content-Transfer-Encoding: quoted-printable
Content-Disposition: inline

$result

--boundary-string--
EOF

}
    
send_email
