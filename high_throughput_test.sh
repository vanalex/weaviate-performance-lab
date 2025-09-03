#!/usr/bin/env bash

set -e

# Use fixed container names and mapped ports
NODES=(
  "8080:weaviate-node-1"
  "8081:weaviate-node-2"
  "8082:weaviate-node-3"
)

OBJECT_COUNT=1000

echo "==== High Throughput Test: Inserting $OBJECT_COUNT objects on node1 ===="

for i in $(seq 1 $OBJECT_COUNT); do
  curl -s -X POST http://localhost:8080/v1/objects \
    -H "Content-Type: application/json" \
    -d "{
      \"class\": \"Article\",
      \"properties\": {
        \"title\": \"High Throughput $i\",
        \"content\": \"Object $i for throughput test\"
      }
    }" > /dev/null
  if (( $i % 100 == 0 )); then
    echo "Inserted $i objects..."
  fi
done

echo "==== Verifying object count on all nodes ===="
for ENTRY in "${NODES[@]}"; do
  PORT=${ENTRY%%:*}
  NAME=${ENTRY##*:}
  echo "Checking $NAME (port $PORT)..."
  COUNT=$(curl -s "http://localhost:$PORT/v1/objects?class=Article&limit=1" | jq '.totalResults')
  echo "$NAME reports $COUNT objects."
done

echo "==== High Throughput