#!/bin/bash

if wget -q -O - "http://localhost:3142/acng-report.html"
then
    echo "Healthz pass" 1>&2
    exit 0
else
    echo "Healthz failed" 1>&2
    exit 1
fi
