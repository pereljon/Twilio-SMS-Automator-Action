#!/usr/bin/env bash

#  main.command
#  Send Twilio SMS

#  Created by Jonathan Perel on 12/14/16.
#  Copyright © 2016 Metro Eighteen. All rights reserved.

# Get stdin
stdin_message=$(cat)

# Merge automator message with stdin message
if [ -n "$stdin_message" ]; then
    message_out="${message}
${stdin_message}"
else
    message_out="${message}"
fi

# POST message to Twilio API
result=$(/usr/bin/curl -X POST "https://api.twilio.com/2010-04-01/Accounts/${accountSID}/Messages.json" --data-urlencode "To=${toNumber}" --data-urlencode "From=${fromNumber}" --data-urlencode "Body=${message_out}" -u ${accountSID}:${authToken})

# Echo stdin message to stdout for next automator action
echo -n "${stdin_message}"

exit 0
