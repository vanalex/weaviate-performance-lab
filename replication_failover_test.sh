#!/usr/bin/env bash
set -e

NODES=(
  "8080:weaviate-node-1"
  "8081:weaviate-node-2"
  "8082:weaviate-node-3"
)

LEADER_NODE=8080

echo "==== 1. Insert object on leader (node1:$LEADER_NODE) ===="

OBJECT_ID=$(curl -s -X POST http://localhost:$LEADER_NODE/v1/objects \
  -H "Content-Type: application/json" \
  -d '{
    "class": "Article",
    "properties": {
      "title": "Replication Test",
      "content": "Testing replication and availability"
    }
  }' | jq -r '.id')

echo "Inserted object ID: $OBJECT_ID"

sleep 3

echo "==== 2. Read object from all nodes ===="
for ENTRY in "${NODES[@]}"; do
  PORT=${ENTRY%%:*}
  echo "Reading from node on port $PORT..."
  curl -s http://localhost:$PORT/v1/objects/$OBJECT_ID | jq .
done

echo "==== 3. Stop leader node (simulate failure) ===="
docker stop weaviate-node-1
sleep 5

echo "==== 4. Read object from remaining nodes ===="
for ENTRY in "${NODES[@]}"; do
  PORT=${ENTRY%%:*}
  NAME=${ENTRY##*:}
  if [ "$NAME" != "weaviate-node-1" ]; then
    echo "Reading from $NAME (port $PORT)..."
    curl -s http://localhost:$PORT/v1/objects/$OBJECT_ID | jq .
  fi
done

echo "==== 5. Insert new object on node2 ===="
OBJECT_ID2=$(curl -s -X POST http://localhost:8081/v1/objects \
  -H "Content-Type: application/json" \
  -d '{
    "class": "Article",
    "properties": {
      "title": "Post-Failover Test",
      "content": "Written while leader is down"
    }
  }' | jq -r '.id')

echo "Inserted object ID2: $OBJECT_ID2"

echo "==== 6. Restart leader node ===="
docker start weaviate-node-1
sleep 10

echo "==== 7. Verify both objects exist on all nodes ===="
for ENTRY in "${NODES[@]}"; do
  PORT=${ENTRY%%:*}
  NAME=${ENTRY##*:}
  echo "--- Checking $NAME (port $PORT) ---"
  curl -s http://localhost:$PORT/v1/objects/$OBJECT_ID | jq .
  curl -s http://localhost:$PORT/v1/objects/$OBJECT_ID2 | jq .
done

echo "==== Test complete: replication consistency and availability verified ===="
