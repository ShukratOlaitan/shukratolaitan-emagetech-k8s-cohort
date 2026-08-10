# Assignment 07 — <Shukurat Olaitan>

**GitHub username:** <ShukratOlaitan>
**Date completed:** 2026-07-28

## 1. Answers to the 12 questions

**Q1 — who repairs each layer + ownerReferences + cascade:** ...

Deleting a Pod was repaired by the ReplicaSet controller, which noticed it had fewer Pods than desired and created a replacement. Deleting the ReplicaSet was repaired by the Deployment controller, which created a new ReplicaSet from the Deployment template. Kubernetes uses ownerReferences to establish parent-child relationships—Pods point to ReplicaSets, and ReplicaSets point to Deployments. When the ReplicaSet was deleted, Kubernetes performed a cascading deletion, so its owned Pods were automatically garbage collected before the Deployment recreated a new ReplicaSet and new Pods.

**Q2 — the impostor pod + label hygiene:** ...

The unmanaged impostor Pod matched the ReplicaSet’s selector, so the ReplicaSet adopted it through an ownerReference and counted four matching Pods instead of the desired three. It then deleted one matching Pod to reconcile back to three, which could be the impostor or an original Pod. This is why labels are a safety boundary: broad or reused selectors can cause controllers and Services to act on another team’s workloads. Using separate namespaces and standardized, unique labels such as application name, instance, environment, and team prevents selector collisions.

**Q3 — rollout narration + readiness dependency + 0/0 trap:** ...

With three replicas, maxSurge: 1 and maxUnavailable: 0, Kubernetes creates one new Pod, waits for it to become Ready, then removes one old Pod. It repeats this cycle until all three old Pods are replaced, temporarily running a maximum of four Pods while always maintaining at least three available Pods. A correct readiness probe is essential because Kubernetes uses readiness to decide when it is safe to terminate an old Pod. Setting both maxSurge and maxUnavailable to zero would make the rollout impossible, since Kubernetes could neither create an extra Pod nor remove an existing one.

**Q4 — revisions map to ReplicaSets + why keep at 0:** ...
Every rollout revision corresponds to a ReplicaSet. Each time the Deployment's Pod template changes, Kubernetes creates a new ReplicaSet for that version. Old ReplicaSets are usually scaled down to 0 replicas rather than deleted so they can be used for fast rollbacks with kubectl rollout undo. The spec.revisionHistoryLimit field determines how many old ReplicaSets are retained before the oldest ones are garbage collected
**Q5 — broken rollout, zero downtime + undo revisions + progressDeadline:** ...
The failed rollout caused no user errors because maxSurge: 1 allowed only one broken replacement Pod to exist at a time, while maxUnavailable: 0 required all three healthy old Pods to remain available. Since the new Pod failed readiness, it received no Service traffic and Kubernetes could not terminate any old Pods. After rollout undo, Kubernetes restored the older Pod template as a new, higher-numbered revision; it moved forward in history rather than rewinding. progressDeadlineSeconds marks a rollout as stalled when it stops progressing, but a normal Kubernetes Deployment does not automatically roll back.
**Q6 — two non-native strategies + tooling:** ...
Canary is best when I want to expose a risky release to a small percentage of users and promote it only if metrics remain healthy. I would use Argo Rollouts or Flagger with Istio, NGINX, and Prometheus. Blue/Green is better when I need the complete new version running and tested before switching traffic, with an almost immediate rollback path. I would use Argo Rollouts, Spinnaker, or an ingress or service-mesh traffic router to switch between the blue and green environments.
**Q7 — DaemonSet pod count + taints/tolerations:** ...

A DaemonSet doesn't have a replicas field because its desired Pod count is determined by the number of eligible nodes in the cluster. The DaemonSet controller watches the node list and automatically creates one Pod on each matching node. When a new node joins, it immediately schedules another DaemonSet Pod there; when a node leaves, its Pod disappears with it. Control-plane nodes are usually tainted with NoSchedule, so DaemonSets that provide essential node services include tolerations to run there as well. Built-in components like kindnet and kube-proxy are DaemonSets, confirming that Kubernetes uses DaemonSets for infrastructure that must exist on every node.

**Q8 — StatefulSet identity guarantees + scale-down PVC retention:** ...
A StatefulSet does not immediately replace Pods on a failed node because it must avoid split-brain. If Kubernetes started a second logbook-1 while the original was still running, both instances could write to the same database identity or volume, causing corruption. StatefulSets therefore prioritize correctness over fast replacement. 

Stable naming
Each StatefulSet Pod has a predictable ordinal name:

logbook-0
logbook-1
logbook-2

Stable Storage

Each Pod owns its own PVC created from the volumeClaimTemplates.

logbook-0 → data-logbook-0
logbook-1 → data-logbook-1
logbook-2 → data-logbook-2

When logbook-1 was deleted, Kubernetes created a new Pod named logbook-1 and reattached data-logbook-1, so the file: /usr/share/nginx/html/index.html was still present.

Stable DNS identity
Because the StatefulSet uses a headless Service, every Pod keeps a permanent DNS name:

logbook-0.logbook
logbook-1.logbook
logbook-2.logbook

Applications can always reach a specific replica by its stable hostname, even after the Pod is recreated.

When i scaled down from 3 replicas to 2 replicas kubernetes removed logbook-2 
StatefulSets always remove Pods in reverse ordinal order (highest ordinal first). This ensures lower-numbered replicas remain stable, which is important for clustered applications. kubectl get pv revelaed that the pvc wasnt deleted as a result when i scaled up the statefulset recreated logbook2 and automatically reattached data-logbook-2.

**Q9 — node-failure caution + pets vs cattle:** ...
A StatefulSet is deliberately more cautious than a Deployment because stateful applications cannot safely have two instances using the same identity and storage at the same time.

"Pets vs cattle" means stateful workloads like PostgreSQL are unique and must preserve identity and data ("pets"), while stateless workloads like web servers or FastAPI replicas are interchangeable and can be destroyed and recreated freely ("cattle").

Example
Stateful logbook
Stateless web nginx 

**Q10 — Job completions/parallelism/backoffLimit/restartPolicy:** ...
In the migrate Job, completions: 5 required five successful Pod completions, while parallelism: 2 limited execution to two active Pods at a time. Therefore, five successful Pods were created in total, with no more than two running concurrently.

(b) In doomed, backoffLimit: 2 allowed the initial attempt plus two retries, so three failed Pods were created because the Pod used restartPolicy: Never. The Job was marked failed with the reason BackoffLimitExceeded. The default backoff limit of six can take close to ten minutes because Kubernetes uses exponential backoff between retries, increasing the delay after each failure rather than retrying immediately.

(c) A Job may use only OnFailure or Never because Job containers are expected to terminate. With Always, even a successful exit would cause the kubelet to restart the container, preventing the Pod from representing a completed unit of work.

(d) With OnFailure, the kubelet restarts the failed container inside the same Pod, so failures appear in the Pod's restart count. With Never, the failed Pod remains in Error, and the Job controller creates a new Pod for the next attempt. This is why the doomed Job left a separate failed Pod for every attempt.

**Q11 — concurrencyPolicy Forbid vs Replace + startingDeadlineSeconds:** ...

With concurrencyPolicy: Forbid, the minute-2 execution was skipped because the previous Job was still running. It was neither queued nor terminated. With Replace, Kubernetes would delete the currently running Job and immediately start the new scheduled Job. Forbid is appropriate for workloads like database backups, where overlapping executions could corrupt or invalidate the backup. Replace is appropriate for workloads such as cache or search-index refreshes, where only the most recent execution matters and stale work should be abandoned. By default, startingDeadlineSeconds is nil, meaning there is no time limit for considering missed schedules; after the CronJob controller recovers from downtime, it can still evaluate missed executions instead of automatically discarding them.

**Q12 — the six workload → controller picks:** ...
A REST API server, stateless, 6 replicas, frequent deploys
Deployment Controller
A Deployment maintains six interchangeable replicas and supports controlled rolling updates and rollbacks.

PostgreSQL with one primary and two replicas, each needing its own disk
StatefulSet Controller
A StatefulSet provides each database member with a stable name, stable DNS identity, ordered management, and its own persistent volume.

A log shipper that must read /var/log on every node, including tainted GPU nodes
DaemonSet Controller
A DaemonSet runs one log-shipping Pod on every eligible node, with tolerations added so it can also run on the tainted GPU nodes.

A nightly 2 AM database backup that must never run twice concurrently
A CronJob schedules the backup at 2 AM and uses concurrencyPolicy: Forbid to prevent overlapping backup Jobs.
CronJob controller

A one-off backfill that processes 10 partitions, at most 3 in parallel
Job Controller
A Job with completions: 10 and parallelism: 3 runs ten finite work units while limiting concurrency to three Pods.

The cluster's CNI networking agent
DaemonSet Controller
A CNI agent must run on every node to configure node-level Pod networking, including control-plane or otherwise tainted nodes.

## 2. Files

Paste inline as fenced code blocks: `web.yaml`, `node-agent.yaml` (with the toleration),
`logbook.yaml`, `migrate.yaml`, `report.yaml`.

web.yaml
``` apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  labels:
    app: web
spec:
  replicas: 3
  progressDeadlineSeconds: 60    # default is 600 — shortened so Part 3 shows the failure condition quickly
  selector:
    matchLabels:
      app: web
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: web
          image: nginx:1.25-alpine
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet: { path: /, port: 80 }
            periodSeconds: 5
            ```


## 3. Evidence

Paste command + output (trim to the relevant lines):

- Part 1.1 — `kubectl get deploy,rs,pods --show-labels` showing the naming + hash chain
kubectl get deploy,rs,pods -l app=web --show-labels
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE   LABELS
deployment.apps/web   0/3     3            0           14s   app=web

NAME                             DESIRED   CURRENT   READY   AGE   LABELS
replicaset.apps/web-5d86c7b79f   3         3         0       14s   app=web,pod-template-hash=5d86c7b79f

NAME                       READY   STATUS              RESTARTS   AGE     LABELS
pod/web-5d86c7b79f-5bcwk   0/1     ContainerCreating   0          14s     app=web,pod-template-hash=5d86c7b79f
pod/web-5d86c7b79f-dmv9j   0/1     ContainerCreating   0          14s     app=web,pod-template-hash=5d86c7b79f
pod/web-5d86c7b79f-m7jb5   0/1     ContainerCreating   0          14s     app=web,pod-template-hash=5d86c7b79f
pod/web-prod-1             1/1     Running             0          3d22h   app=web,environment=production
pod/web-prod-2             1/1     Running             0          3d22h   app=web,deprecated=true,environment=production
pod/web-qa-1               1/1     Running             0          3d22h   app=web,environment=qa

- Part 1.3 — pods after deleting the ReplicaSet (all replaced under a new RS)


- Part 1.4 — the pod list right after creating `impostor` (4 matching → back to 3)
- Part 2.1 — the two-ReplicaSet listing mid/post-rollout + the `loadgen` uniq count with zero `FAIL`

NAME             DESIRED   CURRENT   READY   AGE
web-5d86c7b79f   0         0         0       12m
web-6dcb67945    3         3         3       8s

kubectl logs loadgen | sort | uniq -c    # e.g. "247 ok" and no FAIL line
   2 FAIL
 530 ok

- Part 3 — pods during the broken rollout (3 Running + 1 ImagePullBackOff), the deploy
  conditions, `loadgen` still clean, and `rollout history` after the undo

  REVISION  CHANGE-CAUSE
2         upgrade nginx 1.25 -> 1.27
3         <none>
4         <none>


- Part 4 — DaemonSet pods at 2/3 nodes, then 3/3 after the toleration
kubectl get pods -l app=node-agent -o wide
NAME               READY   STATUS    RESTARTS   AGE   IP               NODE     NOMINATED NODE   READINESS GATES
node-agent-7dq47   1/1     Running   0          91s   192.168.228.66   k8s-w1   <none>           <none>
node-agent-hk7wc   1/1     Running   0          91s   192.168.46.16    k8s-w2   <none>           <none>

kubectl get pods -l app=node-agent -o wide    # now 3/3, one per node
daemonset.apps/node-agent configured
NAME               READY   STATUS              RESTARTS   AGE     IP               NODE      NOMINATED NODE   READINESS GATES
node-agent-6khn2   0/1     Pending             0          0s      <none>           k8s-cp3   <none>           <none>
node-agent-7dq47   1/1     Running             0          5m58s   192.168.228.66   k8s-w1    <none>           <none>
node-agent-hk7wc   1/1     Running             0          5m58s   192.168.46.16    k8s-w2    <none>           <none>
node-agent-lshv6   0/1     ContainerCreating   0          0s      <none>           k8s-cp1   <none>           <none>
node-agent-vztlb   0/1     ContainerCreating   0          0s      <none>           k8s-cp2   <none>           <none>

- Part 5.3 — `logbook-1` recreated with the same name AND `cat` of its surviving data

kubectl get pods -l app=logbook -w 
NAME        READY   STATUS    RESTARTS   AGE
logbook-0   1/1     Running   0          29m
logbook-1   1/1     Running   0          9s
logbook-2   1/1     Running   0          28m

kubectl exec logbook-1 -- cat /usr/share/nginx/html/index.html
I am logbook-1 and this is MY volume

- Part 5.4 — PVC listing after scale-down (still 3 PVCs)

kubectl scale statefulset logbook --replicas=3
statefulset.apps/logbook scaled

kubectl get pods -l app=logbook 
NAME        READY   STATUS              RESTARTS   AGE
logbook-0   1/1     Running             0          30m
logbook-1   1/1     Running             0          2m8s
logbook-2   0/1     ContainerCreating   0          3s
- Part 6 — `migrate` at 5/5 with never more than 2 concurrent; `doomed` marked Failed

kubectl get pods -l job-name=migrate -w 
NAME            READY   STATUS    RESTARTS   AGE
migrate-8q5b8   1/1     Running   0          11s
migrate-zq5zc   1/1     Running   0          11s
migrate-zq5zc   0/1     Completed   0          12s
migrate-8q5b8   0/1     Completed   0          12s
migrate-8q5b8   0/1     Completed   0          13s
migrate-zq5zc   0/1     Completed   0          13s
migrate-zq5zc   0/1     Completed   0          13s
migrate-8q5b8   0/1     Completed   0          14s
migrate-92b57   0/1     Pending     0          0s
migrate-92b57   0/1     Pending     0          0s
migrate-qxvj4   0/1     Pending     0          0s
migrate-qxvj4   0/1     Pending     0          0s
migrate-92b57   0/1     ContainerCreating   0          0s
migrate-8q5b8   0/1     Completed           0          14s
migrate-zq5zc   0/1     Completed           0          14s
migrate-qxvj4   0/1     ContainerCreating   0          0s
migrate-92b57   0/1     ContainerCreating   0          0s
migrate-qxvj4   0/1     ContainerCreating   0          1s
migrate-92b57   0/1     ContainerCreating   0          1s

kubectl get job migrate
NAME      STATUS     COMPLETIONS   DURATION   AGE
migrate   Complete   5/5           43s        59s


kubectl get pods -l job-name=doomed   

NAME     STATUS   COMPLETIONS   DURATION   AGE
doomed   Failed   0/1           109s       109s

NAME           READY   STATUS   RESTARTS   AGE
doomed-7g5kl   0/1     Error    0          79s
doomed-n56v5   0/1     Error    0          99s
doomed-vpv76   0/1     Error    0          109s

kubectl get job doomed                       # STATUS: Failed
NAME     STATUS   COMPLETIONS   DURATION   AGE
doomed   Failed   0/1           4m36s      4m36s


- Part 7 — jobs listing showing the skipped tick under Forbid; the suspended CronJob

## 4. One trade-off I had to make

(2–4 sentences. Pick one: maxSurge vs maxUnavailable settings, Forbid vs Replace,
OnFailure vs Never, StatefulSet vs Deployment+PVC for the logbook, etc.)

## 5. One thing I'm still unsure about

(One sentence. Goes to office hours.)
