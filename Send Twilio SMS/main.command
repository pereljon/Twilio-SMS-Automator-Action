#!/usr/bin/env bash

#  main.command
#  Send Twilio SMS

#  Created by Jonathan Perel on 12/14/16.
#  Copyright © 2016 Metro Eighteen. All rights reserved.

logger -t $(basename $0) "Starting"

# Input error checking
if [ -z "$accountSID" ]; then
    logger -t $(basename $0) "ERROR: Missing account SID."
elif [ -z "$authToken" ]; then
    logger -t $(basename $0) "ERROR: Missing account token."
elif [ -z "$fromNumber" ]; then
    logger -t $(basename $0) "ERROR: Missing FROM number."
elif [ -z "$toNumber" ]; then
    logger -t $(basename $0) "ERROR: Missing TO number."
elif [ -z "$stdin_message" ] && [ -z "$message" ]; then
    logger -t $(basename $0) "ERROR: No message to send."
else

    # Get stdin
    stdin_message=$(cat)
    if [ -n "$stdin_message" ]; then
    # Merge automator argument message with stdin message
        message_out="$message
    $stdin_message"
    elif [ -n "$message" ]; then
    # Stdin message only
        message_out="$message"
    fi

    # POST message to Twilio API
    result=$(/usr/bin/curl --connect-timeout 30 --max-time 60 -X POST "https://api.twilio.com/2010-04-01/Accounts/${accountSID}/Messages.json" --data-urlencode "To=${toNumber}" --data-urlencode "From=${fromNumber}" --data-urlencode "Body=${message_out}" -u ${accountSID}:${authToken})
    success="\"error_code\": null"
    if [[ ! $result =~ .*$success.* ]]; then
        # Error in curl command
        logger -t $(basename $0) "$result"
        exit 1
    fi

    # Echo stdin message to stdout for next automator action
    echo -n "${stdin_message}"
    logger -t $(basename $0) "Exiting"
    # Exiting with success
    exit 0
fi
# Exiting with error
exit 1
