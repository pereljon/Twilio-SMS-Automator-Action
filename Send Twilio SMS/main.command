#!/usr/bin/env bash

#  main.command
#  Send Twilio SMS

#  Created by Jonathan Perel on 12/14/16.
#  Copyright © 2016 Metro Eighteen. All rights reserved.

# CONSTANTS
max_sms_size=1600
log_directory="${HOME}/Library/Logs"

# Log to file function
function logToFile {
if [ ! -d "$log_directory" ]; then
    # Create doesn't exist.
    mkdir -p "$log_directory"
fi
echo "$(date "+%b %d %H:%M:%S") : $1">>"${log_directory}/SendTwilioSMS.log"
}

logToFile "Starting"

if [[ -p /dev/stdin ]]; then
    # Get workflow message from stdin
    stdin_message=$(</dev/stdin)
fi

# Input error checking
if [ -z "$accountSID" ]; then
    logToFile "ERROR: Missing account SID."
elif [ -z "$authToken" ]; then
    logToFile "ERROR: Missing account token."
elif [ -z "$fromNumber" ]; then
    logToFile "ERROR: Missing FROM number."
elif [ -z "$toNumber" ]; then
    logToFile "ERROR: Missing TO number."
elif [ -z "$stdin_message" ] && [ -z "$message" ]; then
    logToFile "ERROR: No message to send."
else

    if [ -n "$stdin_message" ]; then
    # Process workflow message (stdin)
        if [ -n "$ignoreFilter" ]; then
        # Skip sending if any line in ingoreFilter found in workflow message (stdin)
            while read -r nextFilter; do
                if [ -n "$nextFilter" ] && [[ "$stdin_message" == *"$nextFilter"* ]]; then
                    # Skip sending this message
                    logToFile "Ignore: $nextFilter"
                    # Echo workflow (stdin) message to stdout for next automator action
                    echo -n "${stdin_message}"
                    exit 0
                fi
            done <<< "$ignoreFilter"
        fi
        # Make a copy of stdin_message to filter. Leave original unchanged for next automator action
        stdin_message_copy="$stdin_message"
        if [ -n "$preFilter" ]; then
        # Filter out any text appearing before preFilter
            stdin_message_copy="$(echo "$stdin_message_copy" | sed "/$preFilter/,\$!d")"
        fi
        if [ -n "$postFilter" ]; then
        # Filter out any text appearing after (and including) postFilter
            stdin_message_copy="$(echo "$stdin_message_copy" | sed "/$postFilter/,\$d")"
        fi
        if [ -n "$message" ]; then
        # Merge automator argument message with workflow (stdin) message
            message_out="$message
$stdin_message_copy"
        fi
    else
    # Message only automator argument from input field
        message_out="$message"
    fi

    # Get message size
    message_size=${#message_out}
    if [ "$message_size" -gt "$max_sms_size" ]; then
        # Clip long messages to $max_sms_size
        logToFile "Clipping message from $message_size to $max_sms_size characters."
        message_out=${message_out:0:$max_sms_size}
    fi

    # Remove whitespace from toNumber
    toNumberClean="$(echo ${toNumber//[[:blank:]]/})"

    # Loop for multiple TO numbers separated by commas
    IFS=","
    for nextToNumber in $toNumberClean; do
        # POST message to Twilio API
        logToFile "Sending to: $nextToNumber"
        result=$(/usr/bin/curl --connect-timeout 30 --max-time 60 --silent --show-error -X POST "https://api.twilio.com/2010-04-01/Accounts/${accountSID}/Messages.json" --data-urlencode "To=${nextToNumber}" --data-urlencode "From=${fromNumber}" --data-urlencode "Body=${message_out}" -u ${accountSID}:${authToken})
        success="\"error_code\": null"
        if [[ $result =~ .*$success.* ]]; then
            #  Success
            logToFile "Sent to: $nextToNumber"
        else
            # Error in curl command
            logToFile "ERROR: $result"
        fi
    done
    unset IFS

    # Echo workflow (stdin) message to stdout for next automator action
    echo -n "${stdin_message}"
    logToFile "Exiting"
    # Exiting with success
    exit 0
fi

# Echo workflow (stdin) message to stdout for next automator action
echo -n "${stdin_message}"
# Exiting with error
exit 1
