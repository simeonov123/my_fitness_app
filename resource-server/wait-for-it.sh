#!/usr/bin/env bash
# wait-for-it.sh
# Usage: wait-for-it.sh host:port timeout -- command args...
# This script waits until the host:port is available before executing the command.

if [ "$#" -lt 3 ]; then
  echo "Usage: $0 host:port timeout -- command args..."
  exit 1
fi

hostport=$1
timeout=$2
shift 2

host=$(echo $hostport | cut -d: -f1)
port=$(echo $hostport | cut -d: -f2)

echo "Waiting for $host:$port to be available (timeout: ${timeout}s)..."
for ((i=0; i<timeout; i++)); do
  if echo > /dev/tcp/$host/$port 2>/dev/null; then
    echo "$host:$port is available"
    exec "$@"
  fi
  sleep 1
done

echo "Timeout reached; $host:$port is not available"
exit 1
