#!/bin/bash

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | xargs)
fi

# Check if required variables are set
if [ -z "$ROUTER_URL" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    echo "Missing required environment variables in .env file!"
    exit 1
fi

# Parse command-line argument
if [ "$1" == "enable" ]; then
    ENABLE_5GHZ=true
elif [ "$1" == "disable" ]; then
    ENABLE_5GHZ=false
else
    echo "Usage: $0 [enable|disable]"
    exit 1
fi


# Login
LOGIN_RESPONSE=$(curl -s -i -X POST "$ROUTER_URL/check.jst" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "username=$USERNAME" \
  --data-urlencode "password=$PASSWORD" \
  --data-urlencode "locale=false")

SESSION_COOKIE=$(echo "$LOGIN_RESPONSE" | grep -o 'DUKSID=[^;]*')

if [ -z "$SESSION_COOKIE" ]; then
  echo "Login failed!"
  exit 1
fi

# Fetch CSRF Token
AFTER_LOGIN_RESPONSE=$(curl -s -i "$ROUTER_URL/at_a_glance.jst" -b "$SESSION_COOKIE")
CSRF_TOKEN=$(echo "$AFTER_LOGIN_RESPONSE" | grep -o 'csrfp_token=[^;]*' | cut -d'=' -f2)

if [ -z "$CSRF_TOKEN" ]; then
  echo "Failed to fetch CSRF token."
  exit 1
fi

# Toggle 5GHz
CONFIG_INFO="{\"radio_enable\":\"$ENABLE_5GHZ\", \"network_name\":\"Lighthouse\", \"wireless_mode\":\"a,n,ac\", \"security\":\"WPA2_PSK_AES\", \"channel_automatic\":\"true\", \"channel_number\":\"157\", \"network_password\":\"COdeloh0809!\", \"broadcastSSID\":\"true\", \"channel_bandwidth\":\"80MHz\", \"enableWMM\":\"true\", \"ssid_number\":\"2\", \"password_update\":\"false\", \"thisUser\":\"admin\"}"

TOGGLE_RESPONSE=$(curl -s -X POST "$ROUTER_URL/actionHandler/ajaxSet_wireless_network_configuration_edit.jst" \
  -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" \
  -H "X-Requested-With: XMLHttpRequest" \
  -b "$SESSION_COOKIE; csrfp_token=$CSRF_TOKEN" \
  --data-urlencode "configInfo=$CONFIG_INFO" \
  --data-urlencode "csrfp_token=$CSRF_TOKEN")

if echo "$TOGGLE_RESPONSE" | grep -q "success"; then
    echo "5GHz band $1 successfully!"
else
    echo "Failed to toggle 5GHz band! Response: $TOGGLE_RESPONSE"
fi
