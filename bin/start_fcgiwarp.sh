#!/bin/bash

find /nginx -type s -print0 | xargs -0 --no-run-if-empty rm -f && exec fcgiwrap -c "${OVERPASS_FASTCGI_PROCESSES:-4}" -s unix:/nginx/fcgiwrap.socket
