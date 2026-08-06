# Kubernetes

---

## Some of the Biggest Challenges Facing Enterprises

- **Modernise legacy applications** — outdated systems that can't handle modern cloud, AI or security demands
- **Migrating to the cloud or back to on-prem** — moving infrastructure is complex, expensive and risky
- **Costs of cloud and AI use** — cloud bills and AI compute costs can spiral out of control (Uber exhausted its entire 2026 AI budget by April)
- **Security and compliance**
  - AI is now being used to assist with hacks — automating attacks at scale
  - Enterprises need to protect data, applications and services simultaneously
  - Shadow AI — employees using unsanctioned AI tools creating security blind spots
- **Understanding how to make best use of AI** — many enterprises are investing in AI without a clear strategy
- **Containerisation → Kubernetes** — as companies adopt containers they need a way to manage them at scale

---

## What is Kubernetes?

Kubernetes (also written as K8s — the 8 replaces the 8 letters between K and s) is an open source container orchestration platform originally created by Google and released in 2014. It automates the deployment, scaling and management of containerised applications.

Think of it like this:
- **Docker** = packages your app into a container
- **Kubernetes** = manages hundreds of those containers across many servers automatically

---

## Why is Kubernetes Needed?

When you run containers in production you quickly hit problems:

- What happens if a container crashes? Someone needs to restart it
- What happens when traffic spikes? You need more containers fast
- How do you update your app without downtime?
- How do containers find and talk to each other?
- How do you spread containers across multiple servers?

Doing all of this manually is impossible at scale. Kubernetes solves every one of these problems automatically.

---

## Benefits of Kubernetes

- **Orchestrate, schedule and manage containers at scale** — tells containers where to run and manages them automatically
- **Open source** — free to use, huge community, not tied to any one vendor
- **Runs anywhere** — on AWS, Azure, GCP, on-premises, or your local machine
- **Self healing** — automatically restarts failed containers, replaces unhealthy ones, kills containers that don't pass health checks
- **Auto scaling** — automatically adds or removes containers based on CPU usage or traffic
- **Load balancing** — distributes traffic evenly across containers so no single one gets overloaded
- **Rolling updates and rollbacks** — deploy new versions gradually with zero downtime, automatically roll back if something goes wrong
- **Declarative** — you describe what you want (e.g. "I want 3 replicas of this app running") and Kubernetes makes it happen and keeps it that way
- **Designed for production with no single point of failure** — spread workloads across multiple nodes so if one goes down the others keep running

---

## Success Stories

### Pokémon GO — Niantic (2016)

Pokémon GO launched in 2016 and immediately became one of the fastest growing apps in history — 50x the expected traffic within days of launch. Niantic used Kubernetes on Google Cloud to scale their infrastructure dynamically to handle the demand. Without Kubernetes the game would have completely collapsed under the load. It remains one of the most famous examples of Kubernetes handling extreme, unexpected scale.

### Spotify
Spotify runs over 800 microservices — recommendations, search, payments, playback and more. They use Kubernetes to deploy, monitor and connect all 800+ services consistently across millions of daily users.

### HSBC
HSBC used Kubernetes to transform their software delivery — going from releasing software every few months to multiple times per week. A massive competitive advantage in banking.

---

## Kubernetes Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                    │
│                                                          │
│  ┌──────────────────────────────┐                       │
│  │        Master Node           │                       │
│  │      (Control Plane)         │                       │
│  │                              │                       │
│  │  ┌──────────────────────┐   │                       │
│  │  │     API Server       │   │ ← hub for all         │
│  │  │  (validates requests)│   │   interactions        │
│  │  └──────────────────────┘   │                       │
│  │  ┌──────────────────────┐   │                       │
│  │  │  Controller Manager  │   │ ← monitors for        │
│  │  │  (monitors changes)  │   │   changes             │
│  │  └──────────────────────┘   │                       │
│  │  ┌──────────────────────┐   │                       │
│  │  │      Scheduler       │   │ ← decides which       │
│  │  │  (assigns pods to    │   │   node to use         │
│  │  │   worker nodes)      │   │                       │
│  │  └──────────────────────┘   │                       │
│  │  ┌──────────────────────┐   │                       │
│  │  │        etcd          │   │ ← stores entire       │
│  │  │  (key-value store)   │   │   cluster state       │
│  │  └──────────────────────┘   │                       │
│  └──────────────────────────────┘                       │
│                                                          │
│  ┌─────────────────┐  ┌─────────────────┐              │
│  │  Worker Node 1  │  │  Worker Node 2  │              │
│  │                 │  │                 │              │
│  │  ┌───────────┐  │  │  ┌───────────┐  │              │
│  │  │   Pod 1   │  │  │  │   Pod 3   │  │              │
│  │  │(container)│  │  │  │(container)│  │              │
│  │  └───────────┘  │  │  └───────────┘  │              │
│  │  ┌───────────┐  │  │  ┌───────────┐  │              │
│  │  │   Pod 2   │  │  │  │   Pod 4   │  │              │
│  │  │(container)│  │  │  │(container)│  │              │
│  │  └───────────┘  │  │  └───────────┘  │              │
│  │                 │  │                 │              │
│  │  ┌───────────┐  │  │  ┌───────────┐  │              │
│  │  │  kubelet  │  │  │  │  kubelet  │  │              │
│  │  └───────────┘  │  │  └───────────┘  │              │
│  │  ┌───────────┐  │  │  ┌───────────┐  │              │
│  │  │kube-proxy │  │  │  │kube-proxy │  │              │
│  │  └───────────┘  │  │  └───────────┘  │              │
│  │  ┌───────────┐  │  │  ┌───────────┐  │              │
│  │  │ Container │  │  │  │ Container │  │              │
│  │  │  Engine   │  │  │  │  Engine   │  │              │
│  │  └───────────┘  │  │  └───────────┘  │              │
│  └─────────────────┘  └─────────────────┘              │
└─────────────────────────────────────────────────────────┘
```
### The Cluster Setup

- Made up of at least ONE master node and at least ONE worker node
- For production — want a multi-node setup for high availability
- For dev/testing purposes — single node setup is fine (e.g. minikube)

---

## Control Plane Components (Master Node)

**API Server**
The hub for all interactions in the cluster. Every command you run with kubectl goes through the API server. It validates all requests and is the only component that directly accesses etcd. Nothing in the cluster communicates without going through the API server first.

**Controller Manager**
Constantly monitors the cluster for changes. If you say you want 3 replicas of your app and one crashes, the controller manager detects this and tells the scheduler to create a replacement. It's always watching to make sure the actual state matches the desired state.

**etcd**
The memory of the cluster. Stores the entire state of the cluster in a key-value store — every node, every pod, every configuration. If you need to know what's running, etcd has the record. Only the API server can access etcd directly.

**Scheduler**
Decides which worker node a new pod should run on. It looks at available resources on each node (CPU, memory) and assigns the pod to the most suitable one. It never actually runs the pod — it just decides where it should go.

---

## Worker Node Components

**kubelet**
The agent running on every worker node. It connects directly to the API server and is instructed by it to start, stop or manage containers. It reports back on the health of the pods running on its node.

**kube-proxy**
Updates and configures the networking rules on each worker node. Ensures all pods can communicate with each other and with services — keeps networking in sync with the rest of the cluster.

**Container Engine**
The software that actually runs the containers (e.g. Docker or containerd). The kubelet uses the container engine to start and stop containers on that node.

---

## What is a Pod?

A pod is the smallest deployable unit in Kubernetes. It wraps one or more containers that share the same network and storage. Usually one container per pod.

### What does "ephemeral" mean?
Pods are ephemeral — they are temporary and disposable. They can be created, destroyed and replaced at any time. You should never rely on a specific pod being there permanently. If a pod dies Kubernetes replaces it — but it will have a new name and possibly a new IP address. This is why you use Services to communicate between pods rather than hardcoding IP addresses.

---

## Kubernetes Objects

**Pod**
The smallest unit. Wraps one or more containers. Ephemeral — can be created and destroyed at any time.

**ReplicaSet**
Ensures a specified number of identical pods are always running. If one pod dies it automatically creates a replacement. You rarely create ReplicaSets directly — Deployments manage them for you.

**Deployment**
The most common way to run an app in Kubernetes. You define what container to run and how many replicas you want. The Deployment manages the ReplicaSet underneath which manages the Pods. Handles rolling updates and rollbacks automatically.

**Service**
Gives your pods a stable network address. Since pods are ephemeral and their IPs change, a Service acts as a permanent entry point that routes traffic to whichever pods are currently running. Types include ClusterIP (internal), NodePort (external via node port), and LoadBalancer (external via cloud load balancer).

**Namespace**
A way to divide a cluster into separate environments — for example dev, staging and production can all run in the same cluster but in different namespaces.

```
Deployment
└── manages ReplicaSet
└── manages Pods
└── contains Containers
```
---

## How it Works with Managed Services

### AKS (Azure Kubernetes Service)

- Master node and worker nodes are kept separate
- Azure takes care of running and managing the master node
- Azure does NOT charge you for the master node
- What you pay for: one VM per worker node
- Much less operational overhead — Azure handles upgrades, patches and availability of the control plane

### EKS (AWS) and GKE (Google Cloud)

- Similar to AKS but you DO pay for the master node — around 10p per hour
- Still managed — the cloud provider handles the control plane

### Minikube (Local Development)

- Both master and worker nodes run on a single VM on your local machine
- Perfect for learning and development
- Not suitable for production
- Free to run locally

### Managed vs Self-Managed — Pros and Cons

| | Managed (AKS/EKS/GKE) | Self-Managed |
|---|---|---|
| Setup time | Minutes | Days/weeks |
| Control plane management | Cloud provider handles it | You manage it |
| Cost | Pay per worker node | Pay for all nodes including master |
| Upgrades | Automated | Manual |
| Best for | Most production use cases | Full control or on-premises |

---

## Security Concerns with Containers

- **Use maintained images** — always use official, verified base images from trusted sources (e.g. official nginx, node, python images from Docker Hub). Unverified images can contain malware.
- **Run as non-root** — containers should never run as the root user. Use USER in your Dockerfile to switch to a non-root user (you did this with USER node in your TicTacToe Dockerfile)
- **Keep images small** — smaller images have fewer packages and therefore fewer vulnerabilities. Use Alpine-based images where possible
- **Scan images for vulnerabilities** — tools like Trivy or Docker Scout scan your images for known security issues
- **Use Kubernetes RBAC** — Role Based Access Control limits what each user or service can do in the cluster
- **Use Secrets** — never hardcode passwords or API keys. Kubernetes has a built-in Secrets object to store sensitive data securely
- **Network policies** — restrict which pods can communicate with which other pods

### Maintained Images — What Are They?

Maintained images are official Docker images that are actively kept up to date by trusted organisations (Docker, Microsoft, Canonical etc). They receive regular security patches and updates.

**Pros of using maintained images:**
- Regular security patches applied automatically
- Trusted and verified source
- Well documented
- Saves time — don't have to build from scratch

**Cons of using maintained images:**
- Less control over exactly what's included
- Updates might break your app if you're not pinning versions
- Still need to scan them — maintained doesn't mean zero vulnerabilities

---

## Nginx Deployment with NodePort Service

### Folder Structure
```
K8s/
├──yaml-definitions/
    ├── nginx-deploy.yml
    └── nginx-service.yml
```
### nginx-deploy.yml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```

### nginx-service.yml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30001
```

### Commands

```bash
# check what's running
kubectl get all

# apply the yaml files
kubectl apply -f nginx-deploy.yml
kubectl apply -f nginx-service.yml
```

Check it's running at: http://localhost:30001

```bash
# delete/remove running nginx
kubectl delete -f nginx-service.yml
kubectl delete -f nginx-deploy.yml

# check it's not running
kubectl get all
```

### What Each Part Does

**Deployment** — tells Kubernetes to run 3 replicas of the nginx container. If one crashes it automatically creates a replacement.

**replicas: 3** — run 3 identical pods at all times.

**selector and labels** — how the Deployment finds its pods. The Deployment looks for pods with the label `app: nginx`.

**Service (NodePort)** — exposes the nginx deployment so you can access it from your browser. NodePort opens a port (30001) on your local machine and routes traffic to the nginx pods.

**port: 80** — the port the Service listens on inside the cluster.
**targetPort: 80** — the port the container listens on.
**nodePort: 30001** — the port exposed on your machine to access from the browser.

---

## Key Commands Reference

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
| `kubectl get nodes` | List all nodes in the cluster |

## Mitigate security risks with containers

- use maintained container images 
- use automatic vulnerability scanning on container registry
- use own security tanning tool on your container images
- NEVER run containers with root privileges 
- Monitor and/or log of container activity

## Maintained Images

### What is a maintained image

- A docker image that is regularly updated/managed by a maintainer
- Usually the maintainer is an organisation, a community or a individual
  - Example: Canonical maintain Ubuntu image

### Pros & Cons of using maintained images for your base container image

- Better security, because regularly patched
- Better stability
- More support & doc available
- Usually they adhere to best practices/industry standards
- May be streamlined for performance or smaller image size