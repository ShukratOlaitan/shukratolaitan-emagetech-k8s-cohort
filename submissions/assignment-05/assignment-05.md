# Assignment 05 — <Shukurat Olaitan>

**GitHub username:** <shukratolaitan>
**Date completed:** 2026-07-13

## 1. Answers to the 10 questions

**Q1 — control-plane components + per-node bucket:** ...
kube-apiserver is the frontend to the Kubernetes cluster. It’s the stateless control plane gateway through which every Kubernetes component reads and writes cluster state.

etcd is Kubernetes' distributed key-value database. It stores the cluster's desired and current state, including objects such as Pods, Deployments, Services, ConfigMaps, Secrets, Nodes, Namespaces, and other Kubernetes resources. The API server is the only component that reads from and writes directly to etcd.

kube-scheduler watches the API server, binds pods to nodes, and evaluates resources on the worker node using algorithms.
kube-controller-manager executes infinite controller loops, watches the API server, and manages the pods by continuously enforcing a desired state

The Kubelet runs per node Uses a DaemonSet controller.


**Q2 — static pods + bootstrap chicken-and-egg:** ...
The kubelet reads the static pod manifest from /etc/Kubernetes/manifests and starts the static pods directly using the container runtime. This allows the API server, etcd, controller manager, and scheduler to start before the API server is available . 

When you delete the mirror object from the API server:
1.	The mirror object disappears from the API temporarily. 
2.	The kubelet sees that the static pod manifest still exists in /etc/kubernetes/manifests. 
3.	The kubelet recreates the mirror object in the API server. 
The actual pod is not removed because the kubelet treats the local manifest as the source of truth.



**Q3 — etcd quorum + stateless API server:** ...
A 1-member cluster has a quorum of 1. If the single member is running, the cluster works. If it fails, the cluster is unavailable. 
A 2-member cluster: if either fails, 1 remains. 1 is not a majority, so the cluster cannot make progress. So, although a 2-member cluster has an extra server, it still cannot tolerate any failures. In practice, it is actually less useful than a single-node cluster because it introduces another point of failure without increasing fault tolerance

b) 
The API server is stateless because it stores no persistent cluster state; it reads and writes all cluster data to etcd. If etcd's data were destroyed, all Kubernetes objects (Pods, Deployments, Services, Secrets, ConfigMaps, etc.) would be lost. The API server could still start, and containers already running on the nodes would continue running temporarily, but Kubernetes would no longer know about them or be able to manage or recreate them.

**Q4 — contexts + context-drift accident:** ...

The cluster remained the same, kubectl get pods behaved differently because the namespace field in the context changed. The k8s-lab-system context had kube-system as its default namespace, while the kind-k8s-lab context used the default namespace. As a result, kubectl get pods queried different namespaces without needing the -n flag.

A simple habit that helps prevent this is to always check the current context before running commands.
kubectl config current-context
kubectl config get-contexts




**Q5 — request flow authn/authz/admission/persist + dry-run limits:** ...
1. Authentication — “Who are you?”
The API server verifies the client certificate in the kubeconfig and identifies the user as:
kubernetes-admin
The output confirms that it belongs to:
kubeadm:cluster-admins
system:authenticated
For this request, authentication decides:
The request was made by the authenticated user kubernetes-admin.

2. Authorization — “Are you allowed to do this?”
The API server checks whether kubernetes-admin is permitted to get and create or patch Deployments in the default namespace.
For this request, authorization decides:
kubernetes-admin has permission to read and create or modify Deployments in the default namespace.
Because the user belongs to the cluster-admin group, the request is allowed.
3. Admission — “Should this allowed request be accepted or modified?”
Admission controllers evaluate the proposed Deployment after authentication and authorization. They may:
•	Add default values. 
•	Mutate the object. 
•	Reject it because of policy. 
•	Enforce namespace, security, quota, or other rules. 
For this request, admission decides:
The flow-demo Deployment complies with the cluster’s admission policies, and any required defaults or mutations are applied.
4. Persistence — “Store the accepted state”
After the request passes admission, the API server serializes the Deployment and writes its desired state to etcd.
For this request, persistence decides:
The accepted flow-demo Deployment object is stored in etcd as part of the cluster’s persistent state.
After that, the Deployment controller notices the new desired state and creates a ReplicaSet, which then results in a Pod being scheduled.
--dry-run=client generated a Deployment manifest locally and checked that the command-line input could be converted into a structurally valid Deployment object known to your kubectl client.
It validated things such as:
•	The command syntax. 
•	The resource type. 
•	Required fields that the client knows about. 
•	Basic field types and manifest structure. 
•	That it could generate valid YAML. 
It did not authenticate, authorize, run admission controllers, or write anything to etcd.
Client-side validation cannot detect server-side authorization or policy failures. Such as namespace doesn't exist or a ResourceQuota violation




**Q6 — observe/diff/act mapping:** ...

The deploymet was scaled from 1 – 3 which cause the Deployment & ReplicaSet controllers to create two additional pods. When one pod was deleted the replicaSet detected that the actual number of pods had fallen below the desired state & immediately replaced it. This demonstartres the reconciliation loop where controllers continuously work to make the observed state match the desired state stored in the Deployment specification.

**Q7 — scheduler-down blast radius:** ...
The Scheduler binds pods to nodes by.
spec:
  nodeName: k8s-lab-worker

The scheduler ignored those pods, So they were unmanaged , The scheduler starts pods assigned to its nodes.

Yes. The three Pods that were already running continued serving requests normally.
Nothing stopped them because:
•	Their containers were already running. 
•	The kubelet on each node continued managing them. 
•	The container runtime (containerd) continued running the containers. 
•	kube-proxy continued routing traffic. 

What does this tell you about the relationship between the data plane and control plane?
It shows that the data plane is loosely coupled to the control plane.
Even though one control-plane component (the scheduler) was unavailable:
•	Existing workloads continued running. 
•	Existing Services continued routing traffic. 
•	Only new Pods could not be scheduled. 
The control plane is responsible for managing and reconciling the cluster state, while the data plane is responsible for running existing workloads.


**Q8 — kubelet as systemd + kube-proxy + pause container:** ...
a) The kubelet runs as a systemd service because it must start before any pods exist. It watches /etc/kubernetes/manifests and launches the static control-plane pods, solving the bootstrap problem. If the kubelet were a pod, nothing would be available to start it.
(b) kube-proxy does not forward packets itself. Instead, it watches Services and Endpoints and programs iptables rules in the Linux kernel. The kernel then performs the actual packet forwarding and load balancing.
(c) The pause container is the infrastructure container that owns a Pod's shared namespaces, especially the network namespace. All application containers join these namespaces so they share the same IP address and can communicate over localhost. Without the pause container, Pods could not provide shared networking or support patterns such as sidecars and init containers. 

**Q9 — kubectl top + aggregation layer:** ...
kubectl get pods worked because Pods are native core resources served directly by the Kubernetes API server. kubectl top failed because it requires the metrics.k8s.io aggregated API, normally provided by Metrics Server. The aggregation layer registers extension API servers behind the main API server and proxies requests for their API groups to them. Therefore, the API server can be working correctly while kubectl top fails because the separate metrics provider is missing or unhealthy.

**Q10 — three ways to get an image + which for scripts:** ...

kubectl describe deployment drill | grep -i 'Image:'
kubectl get deployment drill -o jsonpath='{.spec.template.spec.containers[*].image}'
kubectl get deployment drill -o yaml | grep 'image:'

I would use JSONPath in a script because it retrieves the exact structured field and is more reliable than parsing human-readable output with grep.

## 2. Cluster survey

Paste the output of:

- `kubectl get nodes -o wide`
NAME                    STATUS   ROLES           AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION             CONTAINER-RUNTIME
k8s-lab-control-plane   Ready    control-plane   2m44s   v1.36.1   172.21.0.6    <none>        Debian GNU/Linux 13 (trixie)   6.12.76-linuxkit (amd64)   containerd://2.3.1
k8s-lab-worker          Ready    <none>          2m31s   v1.36.1   172.21.0.7    <none>        Debian GNU/Linux 13 (trixie)   6.12.76-linuxkit (amd64)   containerd://2.3.1
k8s-lab-worker2         Ready    <none>          2m31s   v1.36.1   172.21.0.8    <none>        Debian GNU/Linux 13 (trixie)   6.12.76-linuxkit (amd64)   containerd://2.3.1


- `kubectl get pods -n kube-system -o wide` (with your three-bucket classification)
kubectl get pods -n kube-system -o wide
NAME                                            READY   STATUS    RESTARTS   AGE     IP           NODE                    NOMINATED NODE   READINESS GATES
coredns-589f44dc88-7glmb                        1/1     Running   0          2m57s   10.244.0.4   k8s-lab-control-plane   <none>           <none>
coredns-589f44dc88-znfs8                        1/1     Running   0          2m57s   10.244.0.3   k8s-lab-control-plane   <none>           <none>
etcd-k8s-lab-control-plane                      1/1     Running   0          3m4s    172.21.0.6   k8s-lab-control-plane   <none>           <none>
kindnet-f9pbs                                   1/1     Running   0          2m54s   172.21.0.7   k8s-lab-worker          <none>           <none>
kindnet-kcz72                                   1/1     Running   0          2m57s   172.21.0.6   k8s-lab-control-plane   <none>           <none>
kindnet-t2sv9                                   1/1     Running   0          2m54s   172.21.0.8   k8s-lab-worker2         <none>           <none>
kube-apiserver-k8s-lab-control-plane            1/1     Running   0          3m4s    172.21.0.6   k8s-lab-control-plane   <none>           <none>
kube-controller-manager-k8s-lab-control-plane   1/1     Running   0          3m4s    172.21.0.6   k8s-lab-control-plane   <none>           <none>
kube-proxy-fp596                                1/1     Running   0          2m54s   172.21.0.7   k8s-lab-worker          <none>           <none>
kube-proxy-p4jms                                1/1     Running   0          2m57s   172.21.0.6   k8s-lab-control-plane   <none>           <none>
kube-proxy-qm9r4                                1/1     Running   0          2m54s   172.21.0.8   k8s-lab-worker2         <none>           <none>
kube-scheduler-k8s-lab-control-plane            1/1     Running   0          3m4s    172.21.0.6   k8s-lab-control-plane   <none>           <none>


1.	Pods that run only on the control-plane node (one copy)
etcd-k8s-lab-control-plane  
kube-apiserver-k8s-lab-control-plane
kube-controller-manager-k8s-lab-control-plane
kube-scheduler-k8s-lab-control-plane

2.	Pods that run on every node (one copy per node)
kube-proxy-qm9r4
kube-proxy-fp596
kube-proxy-p4jms
kindnet-t2sv9
kindnet-f9pbs
kindnet-kcz72
3.	Anything else (e.g. CoreDNS)
coredns-589f44dc88-znfs8
coredns-589f44dc88-7glmb                        


- `docker exec k8s-lab-control-plane ls /etc/kubernetes/manifests`
etcd.yaml
kube-apiserver.yaml
kube-controller-manager.yaml
kube-scheduler.yaml


## 3. Evidence

Paste command + output (trim to the relevant lines):

- Part 2.2 — the etcd key for your `etcd-canary` pod
/registry/apiregistration.k8s.io/apiservices/v1.

/registry/apiregistration.k8s.io/apiservices/v1.admissionregistration.k8s.io

/registry/apiregistration.k8s.io/apiservices/v1.apiextensions.k8s.io

/registry/apiregistration.k8s.io/apiservices/v1.apps

/registry/apiregistration.k8s.io/apiservices/v1.authentication.k8s.io

/registry/apiregistration.k8s.io/apiservices/v1.authorization.k8s.io

/registry/apiregistration.k8s.io/apiservices/v1.autoscaling

/registry/apiregistration.k8s.io/apiservices/v1.batch

/registry/apiregistration.k8s.io/apiservices/v1.certificates.k8s.io

/registry/apiregistration.k8s.io/apiservices/v1.coordination.k8s.io

/registry/apiregistration.k8s.io/apiservices/v1.discovery.k8s.io

/registry/apiregistration.k8s.io/apiservices/v1.events.k8s.io

/registry/apiregistration.k8s.io/apiservices/v1.flowcontrol.apiserver.k8s.io

/registry/apiregistration.k8s.io/apiservices/v1.networking.k8s.io

/registry/apiregistration.k8s.io/apiservices/v1.node.k8s.io

- Part 3.2 — `kubectl get pods` under the `k8s-lab-system` context (no -n flag)
NAME                                            READY   STATUS    RESTARTS   AGE
coredns-589f44dc88-7glmb                        1/1     Running   0          121m
coredns-589f44dc88-znfs8                        1/1     Running   0          121m
etcd-k8s-lab-control-plane                      1/1     Running   0          121m
kindnet-f9pbs                                   1/1     Running   0          121m
kindnet-kcz72                                   1/1     Running   0          121m
kindnet-t2sv9                                   1/1     Running   0          121m
kube-apiserver-k8s-lab-control-plane            1/1     Running   0          121m
kube-controller-manager-k8s-lab-control-plane   1/1     Running   0          121m
kube-proxy-fp596                                1/1     Running   0          121m
kube-proxy-p4jms                                1/1     Running   0          121m
kube-proxy-qm9r4                                1/1     Running   0          121m
kube-scheduler-k8s-lab-control-plane            1/1     Running   0          121m

- Part 4.2 — the request line(s) from `kubectl apply -v=8`
I0713 15:04:54.411905   96247 round_trippers.go:527] "Request" verb="GET" url="https://127.0.0.1:50126/openapi/v3?timeout=32s" headers=<
I0713 15:04:54.423297   96247 round_trippers.go:632] "Response" status="200 OK" headers=<
I0713 15:04:54.426914   96247 round_trippers.go:527] "Request" verb="GET" url="https://127.0.0.1:50126/openapi/v3/apis/apps/v1?hash=E6837BF046F7D2603C949276F19DA2050C7521B0E5FA9FC64556E8AA9C500719EB5CE97EB6FDF85ABEDA04A50BDA5D2B5F59DA2B283D8B76A82BA2A256AFD626&timeout=32s" headers=<
I0713 15:04:54.432541   96247 round_trippers.go:632] "Response" status="200 OK" headers=<
I0713 15:04:54.498281   96247 round_trippers.go:527] "Request" verb="GET" url="https://127.0.0.1:50126/apis/apps/v1/namespaces/default/deployments/flow-demo" headers=<
I0713 15:04:54.504853   96247 round_trippers.go:632] "Response" status="404 Not Found" headers=<

- Part 5.1 — the `-w` output showing the deleted pod replaced
NAME                         READY   STATUS    RESTARTS   AGE
flow-demo-84745775cb-mhh4k   1/1     Running   0          14m
flow-demo-84745775cb-llbbr   0/1     Pending   0          0s
flow-demo-84745775cb-tghss   0/1     Pending   0          0s
flow-demo-84745775cb-llbbr   0/1     Pending   0          0s
flow-demo-84745775cb-tghss   0/1     Pending   0          0s
flow-demo-84745775cb-tghss   0/1     ContainerCreating   0          0s
flow-demo-84745775cb-llbbr   0/1     ContainerCreating   0          0s
flow-demo-84745775cb-tghss   0/1     ContainerCreating   0          1s
flow-demo-84745775cb-llbbr   0/1     ContainerCreating   0          1s
flow-demo-84745775cb-llbbr   1/1     Running             0          1s
flow-demo-84745775cb-tghss   1/1     Running             0          1s
flow-demo-84745775cb-llbbr   1/1     Terminating         0          8s
flow-demo-84745775cb-85st7   0/1     Pending             0          0s
flow-demo-84745775cb-llbbr   1/1     Terminating         0          8s
flow-demo-84745775cb-85st7   0/1     Pending             0          0s
flow-demo-84745775cb-85st7   0/1     ContainerCreating   0          0s
flow-demo-84745775cb-llbbr   0/1     Completed           0          8s
flow-demo-84745775cb-85st7   0/1     ContainerCreating   0          1s
flow-demo-84745775cb-85st7   1/1     Running             0          1s
flow-demo-84745775cb-llbbr   0/1     Completed           0          9s
flow-demo-84745775cb-llbbr   0/1     Completed           0          9s

- Part 5.2 — the stuck pod: `Pending` phase + empty `spec.nodeName`
kubectl describe pod $STUCK | tail -10
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    Optional:                false
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:                      <none>

- Part 5.3 — the same pods `Running` after the scheduler returned
kubectl describe pod $STUCK | tail -10
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  5m13s  default-scheduler  Successfully assigned default/flow-demo-84745775cb-4s4kb to k8s-lab-worker2
  Normal  Pulled     5m13s  kubelet            spec.containers{nginx}: Container image "nginx:1.27-alpine" already present on machine and can be accessed by the pod
  Normal  Created    5m12s  kubelet            spec.containers{nginx}: Container created
  Normal  Started    5m12s  kubelet            spec.containers{nginx}: Container started


- Part 7.3 — outputs of drills (a)–(d)

kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}{end}'
default	drill-84799678b7-tq6km	k8s-lab-worker2
default	drill-84799678b7-xrtqs	k8s-lab-worker
default	flow-demo-84745775cb-4s4kb	k8s-lab-worker2
default	flow-demo-84745775cb-85st7	k8s-lab-worker2
default	flow-demo-84745775cb-lw9ch	k8s-lab-worker
default	flow-demo-84745775cb-mhh4k	k8s-lab-worker
default	flow-demo-84745775cb-tghss	k8s-lab-worker
kube-system	coredns-589f44dc88-7glmb	k8s-lab-control-plane
kube-system	coredns-589f44dc88-znfs8	k8s-lab-control-plane
kube-system	etcd-k8s-lab-control-plane	k8s-lab-control-plane
kube-system	kindnet-f9pbs	k8s-lab-worker
kube-system	kindnet-kcz72	k8s-lab-control-plane
kube-system	kindnet-t2sv9	k8s-lab-worker2
kube-system	kube-apiserver-k8s-lab-control-plane	k8s-lab-control-plane
kube-system	kube-controller-manager-k8s-lab-control-plane	k8s-lab-control-plane
kube-system	kube-proxy-fp596	k8s-lab-worker
kube-system	kube-proxy-p4jms	k8s-lab-control-plane
kube-system	kube-proxy-qm9r4	k8s-lab-worker2
kube-system	kube-scheduler-k8s-lab-control-plane	k8s-lab-control-plane
local-path-storage	local-path-provisioner-855c7b7774-9m7gg	k8s-lab-control-plane

kubectl get pods -n kube-system -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n' | sort -u

docker.io/kindest/kindnetd:v20260528-9350166c
registry.k8s.io/coredns/coredns:v1.14.2
registry.k8s.io/etcd:3.6.8-0
registry.k8s.io/kube-apiserver:v1.36.1
registry.k8s.io/kube-controller-manager:v1.36.1
registry.k8s.io/kube-proxy:v1.36.1
registry.k8s.io/kube-scheduler:v1.36.1

kubectl get pods -A --field-selector status.phase!=Running
No resources found

kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.allocatable.memory}{"\n"}{end}'

k8s-lab-control-plane	16373732Ki
k8s-lab-worker	16373732Ki
k8s-lab-worker2	16373732Ki



- Part 7.4 — `kubectl top nodes` working after the metrics-server fix

kubectl top nodes
NAME                    CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
k8s-lab-control-plane   221m         1%       790Mi           4%          
k8s-lab-worker          56m          0%       276Mi           1%          
k8s-lab-worker2         713m         5%       324Mi           2%  

## 4. One trade-off I had to make

(2–4 sentences. Pick one: imperative vs declarative for the drills, patching metrics-server
vs re-writing its manifest, keeping vs deleting the cluster between assignments, etc.
Explain what you chose and what the other option would have bought you.)

## 5. One thing I'm still unsure about

(One sentence. Goes to office hours.)
