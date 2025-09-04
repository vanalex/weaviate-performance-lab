#!/bin/bash
set -e

OBJ_ID="00000000-0000-0000-0000-000000000111"
NODES=("http://localhost:8081" "http://localhost:8082" "http://localhost:8083")

echo "=== Concurrent Write Test (Object: $OBJ_ID) ==="

write_object() {
  NODE=$1
  VALUE=$2
  curl -s -X POST "$NODE/v1/objects" \
    -H "Content-Type: application/json" \
    -d "{
      \"class\": \"Article\",
      \"id\": \"$OBJ_ID\",
      \"properties\": {
        \"title\": \"Consistency Test\",
        \"content\": \"$VALUE\"
      }
    }" > /dev/null
  echo "Wrote value '$VALUE' to $NODE"
}

# Fire concurrent writes
write_object "${NODES[0]}" "Value-Node1" &
write_object "${NODES[1]}" "Value-Node2" &
write_object "${NODES[2]}" "Value-Node3" &
wait

echo "Concurrent writes finished."

# Read from each node
for NODE in "${NODES[@]}"; do
  echo -n "Reading from $NODE: "
  curl -s "$NODE/v1/objects/$OBJ_ID" | jq -r '.properties.content'
done
