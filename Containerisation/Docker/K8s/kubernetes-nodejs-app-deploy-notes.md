# Kubernetes — Deploy NodeJS App and MongoDB

---

## Prerequisites

- Docker image on Docker Hub: `sumiya12m/tech610-tttapp:1.2.0`
- MongoDB maintained image: `mongo:8.0`
- Kubernetes running locally via Docker Desktop
- kubectl command working in terminal

---

## What is a Kubernetes Deployment?

A Kubernetes Deployment tells the cluster what containers to run, how many replicas to keep alive, and how to update them. Instead of running one container manually with `docker run`, a Deployment manages everything automatically — if a pod crashes it creates a replacement, if you want to scale up you change one number.

---

## What is a Kubernetes Service?

Pods are ephemeral — they come and go and their IP addresses change. A Service gives a stable network address that always routes to the right pods regardless of which specific pods are running at any given time.

There are three main types:
- **ClusterIP** — internal only, pods talk to each other inside the cluster
- **NodePort** — exposes the app externally on a port between 30000-32767
- **LoadBalancer** — external access via a cloud load balancer

---

## Folder Structure

```
k8s-yaml-definitions/
├── nginx-deploy.yml
├── nginx-service.yml
└── local-nodejs20-app-deploy/
├── node-deploy.yml ← Part 1 app only
├── node-service.yml ← Part 1 app only
└── with-db/
├── node-deploy.yml ← Part 2 app + db
├── node-service.yml ← Part 2 app + db
├── mongo-deploy.yml ← Part 2 db
└── mongo-service.yml← Part 2 db
```

---

## Part 1 — Deploy App Only (3 Replicas)

### What We Built

Deploy the TicTacToe app with 3 replicas exposed via NodePort. No database connection yet - app runs in local mode.

### Architecture

```
Browser
│
│ http://localhost:30002
▼
NodePort Service (node-service:30002)
│
├── Pod 1 (node:3000)
├── Pod 2 (node:3000)
└── Pod 3 (node:3000)
```
### node-deploy.yml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: node-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: node
  template:
    metadata:
      labels:
        app: node
    spec:
      containers:
      - name: node
        image: sumiya12m/tech610-tttapp:1.2.0
        ports:
        - containerPort: 3000
        env:
        - name: MONGODB_URI
          value: "mongodb://mongo-service:27017/tic-tac-toe"
```

### node-service.yml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: node-service
spec:
  type: NodePort
  selector:
    app: node
  ports:
  - port: 3000
    targetPort: 3000
    nodePort: 30002
```

### YAML Explained

**apiVersion: apps/v1** — the version of the Kubernetes API to use for this resource

**kind: Deployment** — the type of Kubernetes object we are creating

**metadata: name** — the name of this deployment inside the cluster

**spec: replicas: 3** — keep 3 identical pods running at all times. If one crashes Kubernetes automatically creates a replacement

**selector: matchLabels** — how the Deployment finds its pods. It looks for pods with the label app: node

**template: labels** — the labels applied to each pod. Must match the selector above

**image: sumiya12m/tech610-tttapp:1.2.0** — the Docker Hub image to use for each pod

**containerPort: 3000** — the port the app listens on inside the container

**env: MONGODB_URI** — sets the environment variable so the app knows where to find the database. Uses the service name mongo-service as the hostname — Kubernetes automatically resolves this to the MongoDB pod's IP

**type: NodePort** — exposes the service externally on a port on your local machine

**nodePort: 30002** — the port you visit in your browser. Must be between 30000-32767

**port: 3000** — the port the service listens on inside the cluster

**targetPort: 3000** — the port on the pod to forward traffic to

### Commands

```bash
# navigate to the folder
cd ~/tech610-docker/k8s-yaml-definitions/local-nodejs20-app-deploy

# check what is currently running
kubectl get all

# apply the yaml files
kubectl apply -f node-deploy.yml
kubectl apply -f node-service.yml

# check everything is running
kubectl get all
```

### Expected Output

```
NAME READY STATUS RESTARTS
pod/node-deployment-xxxxxxxxx-xxxxx 1/1 Running 0
pod/node-deployment-xxxxxxxxx-xxxxx 1/1 Running 0
pod/node-deployment-xxxxxxxxx-xxxxx 1/1 Running 0

NAME TYPE CLUSTER-IP PORT(S)
service/node-service NodePort 10.x.x.x 3000:30002/TCP
```
### Test It

Visit in browser: http://localhost:30002

App loads in local mode — no database connected yet ✅

---

## Part 2 — Deploy App and MongoDB Together

### What We Built

Full 2-tier deployment — TicTacToe app (3 replicas) connected to MongoDB (1 replica). The app pods connect to MongoDB using the mongo-service ClusterIP service name.

### Architecture

```
Browser
│
│ http://localhost:30002
▼
┌─────────────────────────────────────────────┐
│ Kubernetes Cluster │
│ │
│ ┌──────────────────────────────────────┐ │
│ │ NodePort Service │ │
│ │ node-service:30002 │ │
│ └──────────────┬───────────────────────┘ │
│ │ routes traffic │
│ ┌────────────┼────────────┐ │
│ ▼ ▼ ▼ │
│ ┌──────┐ ┌──────┐ ┌──────┐ │
│ │ Pod 1│ │ Pod 2│ │ Pod 3│ │
│ │node │ │node │ │node │ │
│ │:3000 │ │:3000 │ │:3000 │ │
│ └──┬───┘ └──┬───┘ └──┬───┘ │
│ └─────────┴──────────┘ │
│ │ MONGODB_URI │
│ ▼ │
│ ┌──────────────────────────────────────┐ │
│ │ ClusterIP Service │ │
│ │ mongo-service:27017 │ │
│ └──────────────┬───────────────────────┘ │
│ │ │
│ ┌──────────────▼───────────────────────┐ │
│ │ MongoDB Pod │ │
│ │ mongo:8.0 :27017 │ │
│ └──────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```
### mongo-deploy.yml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongo
  template:
    metadata:
      labels:
        app: mongo
    spec:
      containers:
      - name: mongo
        image: mongo:8.0
        ports:
        - containerPort: 27017
```

### mongo-service.yml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mongo-service
spec:
  selector:
    app: mongo
  ports:
  - port: 27017
    targetPort: 27017
```

### node-deploy.yml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: node-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: node
  template:
    metadata:
      labels:
        app: node
    spec:
      containers:
      - name: node
        image: sumiya12m/tech610-tttapp:1.2.0
        ports:
        - containerPort: 3000
        env:
        - name: MONGODB_URI
          value: "mongodb://mongo-service:27017/tic-tac-toe"
```

### node-service.yml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: node-service
spec:
  type: NodePort
  selector:
    app: node
  ports:
  - port: 3000
    targetPort: 3000
    nodePort: 30002
```

### Why MongoDB Uses ClusterIP and Not NodePort

The MongoDB service uses the default ClusterIP type — no type is specified so Kubernetes defaults to ClusterIP. This means MongoDB is only accessible from inside the cluster — not from the outside world. Only the app pods can reach it using the service name mongo-service. This is correct behaviour — you never want your database exposed externally.

### Why We Use the Service Name in MONGODB_URI

The MONGODB_URI uses mongo-service as the hostname:

```
mongodb://mongo-service:27017/tic-tac-toe
```
Kubernetes automatically resolves the service name to the correct pod IP address — no matter which pod is running or what IP it has. This is much better than hardcoding an IP address which would change every time the pod restarts.

### Commands

```bash
# navigate to the with-db folder
cd ~/tech610-docker/k8s-yaml-definitions/local-nodejs20-app-deploy/with-db

# apply all yaml files
kubectl apply -f mongo-deploy.yml
kubectl apply -f mongo-service.yml
kubectl apply -f node-deploy.yml
kubectl apply -f node-service.yml

# check everything is running
kubectl get all
```

### Expected Output
```
NAME READY STATUS RESTARTS
pod/mongo-deployment-xxxxxxxxx-xxxxx 1/1 Running 0
pod/node-deployment-xxxxxxxxx-xxxxx 1/1 Running 0
pod/node-deployment-xxxxxxxxx-xxxxx 1/1 Running 0
pod/node-deployment-xxxxxxxxx-xxxxx 1/1 Running 0

NAME TYPE CLUSTER-IP PORT(S)
service/mongo-service ClusterIP 10.x.x.x 27017/TCP
service/node-service NodePort 10.x.x.x 3000:30002/TCP
```
### Test It

Visit in browser: http://localhost:30002

App loads connected to MongoDB ✅

---

## Deleting Everything

```bash
kubectl delete -f node-service.yml
kubectl delete -f node-deploy.yml
kubectl delete -f mongo-service.yml
kubectl delete -f mongo-deploy.yml

# verify everything is gone
kubectl get all
```

---

## Useful kubectl Commands

| Command | What it does |
|---|---|
| `kubectl get all` | List all resources in the cluster |
| `kubectl get pods` | List all pods |
| `kubectl get deployments` | List all deployments |
| `kubectl get services` | List all services |
| `kubectl apply -f file.yml` | Create or update resources from a YAML file |
| `kubectl delete -f file.yml` | Delete resources defined in a YAML file |
| `kubectl describe pod <name>` | Show detailed info about a pod |
| `kubectl logs <pod-name>` | View logs from a pod |

---

## Key Lessons Learned

- Kubernetes Deployments manage pods automatically - if one crashes it is replaced without any manual intervention
- Services give pods a stable network address - pods are ephemeral and their IPs change but the service address stays the same
- Use ClusterIP for internal services like databases - never expose a database externally
- Use the service name as the hostname in connection strings - Kubernetes resolves it to the correct pod IP automatically
- NodePort exposes your app externally without needing a cloud load balancer - perfect for local development
- replicas: 3 means 3 identical pods running simultaneously - if one goes down the other two keep serving traffic
- MongoDB only needs 1 replica - running multiple MongoDB replicas requires additional configuration (replica sets) beyond the scope of this task