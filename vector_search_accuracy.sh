#!/usr/bin/env bash
set -e

NODE=http://localhost:8080

echo "==== 1. Delete old schema if exists ===="
curl -s -X DELETE "$NODE/v1/schema/Article" || true
sleep 2

echo "==== 2. Create schema with vectorizer=none ===="
curl -s -X POST "$NODE/v1/schema" \
  -H "Content-Type: application/json" \
  -d '{
    "classes": [
      {
        "class": "Article",
        "vectorizer": "none",
        "properties": [
          { "name": "title", "dataType": ["text"] },
          { "name": "content", "dataType": ["text"] }
        ]
      }
    ]
  }' | jq .
sleep 2

echo "==== 3. Insert controlled dataset with fixed vectors (using UUIDs) ===="
curl -s -X POST "$NODE/v1/objects" \
  -H "Content-Type: application/json" \
  -d '{
    "class": "Article",
    "id": "00000000-0000-0000-0000-000000000100",
    "properties": {
      "title": "X Axis",
      "content": "Vector [1,0,0]"
    },
    "vector": [1,0,0]
  }' | jq .

curl -s -X POST "$NODE/v1/objects" \
  -H "Content-Type: application/json" \
  -d '{
    "class": "Article",
    "id": "00000000-0000-0000-0000-000000000200",
    "properties": {
      "title": "Y Axis",
      "content": "Vector [0,1,0]"
    },
    "vector": [0,1,0]
  }' | jq .

curl -s -X POST "$NODE/v1/objects" \
  -H "Content-Type: application/json" \
  -d '{
    "class": "Article",
    "id": "00000000-0000-0000-0000-000000000300",
    "properties": {
      "title": "Z Axis",
      "content": "Vector [0,0,1]"
    },
    "vector": [0,0,1]
  }' | jq .
sleep 2

echo "==== 4. Run nearVector query with [1,0,0] ===="
RESULT=$(curl -s -X POST "$NODE/v1/graphql" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ Get { Article(nearVector: {vector: [1,0,0]}) { title _additional { id distance } } } }"}')

echo "$RESULT" | jq .

TOP_ID=$(echo "$RESULT" | jq -r '.data.Get.Article[0]._additional.id')

if [[ "$TOP_ID" == "00000000-0000-0000-0000-000000000100" ]]; then
  echo "✅ Test PASSED: got expected X-axis object"
else
  echo "❌ Test FAILED: expected X-axis object but got $TOP_ID"
fi
