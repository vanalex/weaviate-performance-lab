# 📖 Weaviate Replication & Failover Test Suite

This project provides scripts to **validate replication, failover, and availability** in a multi-node [Weaviate](https://weaviate.io) cluster. It is designed to help engineers test reliability, and to give managers and stakeholders confidence in the system’s resilience.

---

## 🚀 Overview

Weaviate supports **horizontal scaling** and **fault tolerance** through:

- **Replication** – Each object can be stored on multiple nodes (`replicationConfig.factor`).
- **Failover** – If one node goes down, others can still serve reads/writes.
- **Leader Election (Raft)** – A leader manages schema changes, followers replicate them.

This test suite demonstrates these properties by:

1. Inserting objects into a leader node.  
2. Verifying objects replicate across all nodes.  
3. Stopping the leader node to simulate failure.  
4. Confirming that data is still available and new objects can be written.  
5. Restarting the leader and verifying cluster consistency is restored.  
6. Optionally, simulating **high-throughput writes** to stress the cluster.  

---

## 🏗️ Prerequisites

- Running **Weaviate cluster** with at least 3 nodes:  

| Node | Container Name                     | Port  |
|------|------------------------------------|-------|
| 1    | `ai-lab_weaviate-node-1_1`         | 8081  |
| 2    | `ai-lab_weaviate-node-2_1`         | 8082  |
| 3    | `ai-lab_weaviate-node-3_1`         | 8083  |

- Class schema deployed with replication enabled, e.g.:

```json
{
  "class": "Article",
  "description": "A simple article class",
  "replicationConfig": {
    "factor": 2
  },
  "properties": [
    { "name": "title", "dataType": ["text"] },
    { "name": "content", "dataType": ["text"] }
  ]
}
```

- Tools installed:
  - `curl`
  - [`jq`](https://stedolan.github.io/jq/) (for JSON parsing)
  - `docker` (to stop/restart nodes)

---

## 📜 Scripts

### 1. Replication & Failover Test
File: `replication_failover_test.sh`

**What it does:**
- Inserts an object on the leader node.
- Reads it from all nodes to verify replication.
- Stops leader (`node1`).
- Reads from followers (`node2`, `node3`).
- Inserts another object during leader downtime.
- Restarts leader.
- Confirms both objects exist on **all nodes**.

**Run it:**
```bash
bash replication_failover_test.sh
```

---

### 2. High Throughput Test
File: `high_throughput_test.sh`

**What it does:**
- Inserts many objects in parallel into the leader node.
- Waits for replication.
- Counts objects on each node to confirm replication consistency.
- Optionally, runs GraphQL queries to test read throughput.

**Run it:**
```bash
bash high_throughput_test.sh
```

Configure load by editing variables inside the script:
```bash
NUM_OBJECTS=100    # how many objects to insert
THREADS=10         # number of parallel insert threads
```

---

## ✅ Expected Outcomes

- Objects appear on all nodes after insertion.  
- When leader is down:
  - Existing objects remain readable from replicas.  
  - New objects can still be written to followers.  
- When leader comes back:
  - It synchronizes missing objects.  
  - Cluster returns to full replication factor.  

---

## 🔍 Example Output (Replication + Failover)

```text
==== 1. Insert object on leader (node1:8081) ====
Inserted object ID: 0c1d0f7a-b8a3-4c22-bf34-0e54abfda97a

==== 2. Read object from all nodes ====
Reading from ai-lab_weaviate-node-1_1 (port 8081)... OK
Reading from ai-lab_weaviate-node-2_1 (port 8082)... OK
Reading from ai-lab_weaviate-node-3_1 (port 8083)... OK

==== 3. Stop leader node (simulate failure) ====
Leader stopped.

==== 4. Read object from remaining nodes ====
Reading from ai-lab_weaviate-node-2_1 (port 8082)... OK
Reading from ai-lab_weaviate-node-3_1 (port 8083)... OK

==== 5. Insert new object on node2 ====
Inserted object ID2: 6c02f68f-7d48-41d2-8443-1dbe44790e65

==== 6. Restart leader node ====
Leader restarted.

==== 7. Verify both objects exist on all nodes ====
All nodes show both objects ✅
```

---

### 3. Concurrent Writes Test
File: `high_throughput_test.sh`

**What it does:**
- Inserts a large number of objects into the leader node as fast as possible.
- Optionally, can be adapted to use parallel background jobs for true concurrency.
- Verifies that all objects are replicated and available on all nodes after the test.

**Run it:**
```bash
bash high_throughput_test.sh
```

Configure load by editing variables inside the script:
```bash
OBJECT_COUNT=1000    # how many objects to insert
```

---

## ✅ Expected Outcomes

- Objects appear on all nodes after insertion.
- Cluster remains available and consistent under high write load.


---


## 🧑‍💼 Manager’s Summary

- **Why this matters:** These tests prove that our Weaviate cluster can **survive node failures without downtime** and that data is always consistent across replicas.  
- **What we learn:**  
  - Replication factor ensures redundancy.  
  - Leader election ensures schema stability.  
  - High-throughput tests show the cluster can scale with load.  
- **Business impact:** Increased **availability**, **resilience**, and **customer trust** in our search/recommendation features.  

--- 
