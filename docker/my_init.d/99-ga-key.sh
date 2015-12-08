#!/bin/sh

echo "Generating /app/ga-key.p12 from variable OPG_DASHBOARD_GA_KEY"

echo ${OPG_DASHBOARD_GA_KEY} | base64 -d > /app/ga-key.p12
