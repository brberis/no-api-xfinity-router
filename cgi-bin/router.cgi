#!/bin/bash
echo "Content-type: text/plain"
echo ""

# Get the query string (e.g., enable or disable)
QUERY=$(echo "$QUERY_STRING" | cut -d'=' -f2)

if [[ "$QUERY" == "enable" || "$QUERY" == "disable" ]]; then
    ./router.sh "$QUERY"
else
    echo "Invalid parameter! Use enable or disable."
fi
