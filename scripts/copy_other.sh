#!/bin/sh

OOKLA_URL=$(curl -s "https://www.speedtest.net/apps/cli" | xmllint --html --xpath "string(//*[@id='freebsd']/pre/code[7]/text())" - 2>/dev/null | awk -F'"' '{print $2}')
echo "$OOKLA_URL"