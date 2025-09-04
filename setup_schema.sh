#!/usr/bin/env bash
set -e

LEADER_NODE=8080

echo "==== Setting up schema (replication factor = 3) on node1:$LEADER_NODE ===="

# Delete existing schema if present
curl -s -X DELETE http://localhost:$LEADER_NODE/v1/schema/Article > /dev/null || true

# Create schema with replication factor 3
curl -s -X POST http://localhost:$LEADER_NODE/v1/schema \
  -H "Content-Type: application/json" \
  -d '{
    "class": "Article",
    "description": "An article class for replication and throughput testing",
    "vectorizer": "none",
    "replicationConfig": {
      "factor": 3
    },
    "properties": [
      { "name": "title", "dataType": ["text"] },
      { "name": "content", "dataType": ["text"] }
    ]
  }' | jq .

echo "==== Schema created ===="
