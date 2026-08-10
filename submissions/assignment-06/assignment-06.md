# Assignment 06 — <Shukurat Olaitan>

**GitHub username:** <Shukratolaitan>
**Date completed:** 2026-07-23

## 1. Answers to the 10 questions

**Q1 — spec vs status + defaulting + last-applied:** ...
The user/ client writes the desired state in spec, and Kubernetes controllers update status with the observed state. 

spec.strategy and progressDeadlineSeconds are defaults applied by the built-in Kubernetes API. 

The last-applied-configuration annotation stores the previous declarative configuration so kubectl apply can compare the previous configuration, the new file, and the live object to determine which fields to add, update, or remove.

kubectl create does not need it because it performs a one-time imperative creation rather than a declarative merge.
**Q2 — labels vs annotations design rule:** ...
Labels identify Kubernetes objects and are actively used by Kubernetes for selection, grouping, and scheduling. E.g. Services selecting Pods and Deployments managing ReplicaSets. 

Annotations store non-identifying metadata such as Git commit SHAs, build information, or the last-applied-configuration used by kubectl apply.

Label values are limited to 63 characters because Kubernetes indexes and queries them efficiently, whereas annotations are not indexed for selection, so they can store much larger values.



**Q3 — relabel experiment + orphaned pod:** ...

The ReplicaSet continuously reconciles desired state with actual state. After I changed the Pod's label, the ReplicaSet observed that only one Pod matched its selector instead of the desired two. It calculated the difference and created a replacement Pod.

The relabeled Pod kept running because the kubelet still manages the running container, but it's unmanaged by the ReplicaSet since its labels no longer matched the selector. 

A common use of this technique is debugging a live Pod without the controller immediately replacing or deleting it, but leaving orphaned Pods around can waste resources and cause operational confusion.

**Q4 — the missing controller / operator pattern:** ...

A CRD only teaches the Kubernetes API about a new resource type. It doesn't implement any behavior.
The missing half is a custom controller or Operator, which continuously performs the Watch → Diff → Act → Update reconciliation loop.
For postgres-nightly, it would watch the Backup object, notice that no scheduled backup exists, create the necessary CronJob or backup process, and update the object's status with information such as the last successful backup.

**Q5 — CRD deletion blast radius:** ...
When I deleted the Backup CRD, the postgres-nightly and redis-hourly custom resources were also removed because the API resource itself no longer existed. Deleting a CRD deletes all custom resources of that type across the cluster, making it one of the most dangerous administrative operations. For example, Argo CD stores applications as Application custom resources. Deleting the Application CRD would remove every Argo CD Application object, leaving Argo CD without the desired-state definitions it uses to manage and reconcile applications.


**Q6 — phase/state table + explanations:** ...
broken-image stays in the Pending phase because the Pod was scheduled successfully, but the kubelet couldn't pull the container image, so no container ever started. 
one-shot-fail immediately enters the Failed phase because its restartPolicy is Never, so Kubernetes doesn't restart it after it exits with a non-zero status.
crasher remains in the Running phase because its restartPolicy is Always; the kubelet continuously restarts the crashing container. CrashLoopBackOff means the kubelet is backing off—waiting progressively longer between restart attempts—to avoid rapidly restarting a container that keeps failing.

**Q7 — readiness vs liveness, who unplugged the pod:** ...

A readiness failure doesn't stop the container—it only marks the Pod as not ready. The EndpointSlice controller removes the Pod's IP from the Service so it no longer receives traffic. If it were a liveness failure, the kubelet would restart the container according to the Pod's restart policy. A common production example is an application warming its cache or waiting for a database connection: it's alive and making progress, but it isn't ready to serve requests yet.

**Q8 — startup probe mechanics vs initialDelaySeconds:** ...
A startup probe disables both the liveness and readiness probes until it succeeds. During startup, the kubelet only executes the startup probe. Once it succeeds, the startup probe stops permanently and the kubelet begins running the normal liveness and readiness probes. This is better than setting a large initialDelaySeconds because a startup probe adapts to the application's actual startup time. If the app starts in 20 seconds, liveness begins after 20 seconds instead of waiting the full 120 seconds. With a large initial delay, Kubernetes can't detect crashes during that delay, which slows recovery from failures.
**Q9 — init containers vs sleep vs in-app retry:** ...
The initialized condition was initially set to false for ordered-app but after creating a pod that listens on Port 5432 & creating the service. the init containers check succeeds.  

An init container is the best place for startup dependency checks because Kubernetes won't start the main application until the init container completes successfully. 
It's better than sleep 30 because it waits for the actual condition instead of a fixed amount of time, and it's better than embedding the logic in the application because it separates infrastructure concerns from application code and provides its own image, logs, and lifecycle.
I would still implement retry logic in the application for dependencies that can fail after startup, such as a database or external API becoming temporarily unavailable.

**Q10 — QoS derivation + compressible vs non-compressible + eviction order:** ...

Kubernetes assigns QoS based on resource requests and limits. A Pod is Guaranteed when CPU and memory requests equal limits for every container, Burstable when requests and limits differ or are only partially defined, and BestEffort when no requests or limits are specified. CPU is a compressible resource, so exceeding a CPU limit results in throttling. Memory is non-compressible, so exceeding the memory limit causes the Linux OOM killer to terminate the process, which Kubernetes reports as OOMKilled. During node memory pressure, Kubernetes evicts Pods in the order BestEffort, then Burstable, then Guaranteed, which is why production workloads should always define resource requests and limits rather than running as BestEffort.

## 2. Files

Paste inline as fenced code blocks: `backup-crd.yaml`, `probed.yaml`, `slow-start-fixed.yaml`
(just the pod — highlight the startupProbe block you added).

backup-crd.yaml

``` apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: backups.training.emagetech.io      # must be <plural>.<group>
spec:
  group: training.emagetech.io
  names:
    kind: Backup
    plural: backups
    singular: backup
    shortNames: [bk]
  scope: Namespaced
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              required: [source, schedule]
              properties:
                source:
                  type: string
                  description: PVC or database to back up
                schedule:
                  type: string
                  description: Cron expression
                retentionDays:
                  type: integer
                  minimum: 1
                  default: 7
      additionalPrinterColumns:
        - name: Source
          type: string
          jsonPath: .spec.source
        - name: Schedule
          type: string
          jsonPath: .spec.schedule
```

probed.yaml
``` apiVersion: apps/v1
kind: Deployment
metadata:
  name: probed
spec:
  replicas: 2
  selector:
    matchLabels:
      app: probed
  template:
    metadata:
      labels:
        app: probed
    spec:
      containers:
        - name: web
          image: nginx:1.27-alpine
          ports:
            - containerPort: 80
          # readiness = a file the container can create/remove
          readinessProbe:
            exec:
              command: ["cat", "/tmp/ready"]
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /
              port: 80
            periodSeconds: 10
          lifecycle:
            postStart:
              exec:
                command: ["touch", "/tmp/ready"]
---
apiVersion: v1
kind: Service
metadata:
  name: probed
spec:
  selector:
    app: probed
  ports:
    - port: 80
```
slow-start-fixed.yaml

```
apiVersion: v1
kind: Pod
metadata:
  name: slow-start
spec:
  containers:
    - name: app
      image: busybox:1.36
      # pretend to boot for 90s, then serve on :8080
      command: ["sh", "-c", "sleep 90 && httpd -f -p 8080 -h /tmp"]
      livenessProbe:
        tcpSocket:
          port: 8080
        initialDelaySeconds: 10
        periodSeconds: 10
        failureThreshold: 3
      startupProbe:
        tcpSocket:
          port: 8080
        failureThreshold: 12      # 12 × 10s = up to 2 minutes to boot
        periodSeconds: 10
```

## 3. Evidence

Paste command + output (trim to the relevant lines):

- Part 2.2 — selector drills (a)–(c)
SOO-A >>kubectl get pods -l environment=production --show-labels
NAME         READY   STATUS    RESTARTS   AGE     LABELS
api-prod-1   1/1     Running   0          31s     app=api,environment=production
web-prod-1   1/1     Running   0          2m42s   app=web,environment=production
web-prod-2   1/1     Running   0          105s    app=web,deprecated=true,environment=production
SOO-A >>kubectl get pods -l 'app=web,environment in (production,qa)'
NAME         READY   STATUS    RESTARTS   AGE
web-prod-1   1/1     Running   0          3m31s
web-prod-2   1/1     Running   0          2m34s
web-qa-1     1/1     Running   0          117s
SOO-A >>kubectl get pods -l 'environment=production,!deprecated'
NAME         READY   STATUS    RESTARTS   AGE
api-prod-1   1/1     Running   0          3m27s
web-prod-1   1/1     Running   0          5m38s


- Part 2.4 — pod list before/after the relabel (showing the replacement + orphan)

SOO-A >>kubectl get pods -l app=anatomy 
NAME                       READY   STATUS    RESTARTS      AGE
anatomy-5ffb9c8745-dpn7p   1/1     Running   0             27m
anatomy-5ffb9c8745-jqfts   1/1     Running   1             168m
anatomy-5ffb9c8745-k6z46   1/1     Running   0             27m
anatomy-5ffb9c8745-mm6zc   1/1     Running   1 (35m ago)   168m

SOO-A >>kubectl label pod $POD app=escaped --overwrite
pod/anatomy-5ffb9c8745-dpn7p labeled
SOO-A >>
kubectl get pods --show-labels | grep -E 'anatomy|escaped'
anatomy-5ffb9c8745-7774v   1/1     Running   0             9s      app=anatomy,pod-template-hash=5ffb9c8745
anatomy-5ffb9c8745-dpn7p   1/1     Running   0             31m     app=escaped,pod-template-hash=5ffb9c8745
anatomy-5ffb9c8745-jqfts   1/1     Running   1             173m    app=anatomy,pod-template-hash=5ffb9c8745
anatomy-5ffb9c8745-k6z46   1/1     Running   0             31m     app=anatomy,pod-template-hash=5ffb9c8745
anatomy-5ffb9c8745-mm6zc   1/1     Running   1 (39m ago)   173m    app=anatomy,pod-template-hash=5ffb9c8745

- Part 3.2 — `kubectl get backups` with your printer columns; the defaulted `retentionDays`
SOO-A >>kubectl get backups
NAME               SOURCE              SCHEDULE
postgres-nightly   pvc/postgres-data   0 2 * * *
redis-hourly       pvc/redis-data      0 * * * *

SOO-A >> kubectl get backup redis-hourly -o jsonpath='{.spec.retentionDays}{"\n"}' 
7
- Part 3.3 — the schema rejection error for `bad-backup`

The Backup "bad-backup" is invalid: spec.retentionDays: Invalid value: 0: spec.retentionDays in body should be greater than or equal to 1

- Part 3.4 — `kubectl get backups` after CRD deletion

SOO-A >>kubectl get backups
Error from server (NotFound): Unable to list "training.emagetech.io/v1, Resource=backups": the server could not find the requested resource (get backups.training.emagetech.io)

- Part 4 — the four-pod phase/state table's raw outputs
Pod	            Phase	Container state (+ reason)	Restarts
broken-image	Pending 	Waiting (ImagePullBackOff or ErrImagePull)	 0
one-shot	    Succeeded 	Terminated (Completed)	                     0
one-shot-fail	Failed	    Terminated (Error)                           0
crasher	        Running 	Waiting (CrashLoopBackOff) while restarting 14 


- Part 5.2 — `kubectl get endpoints probed` before, during, and after the readiness flip

kubectl get endpointslices -l kubernetes.io/service-name=probed
NAME           ADDRESSTYPE   PORTS   ENDPOINTS                 AGE
probed-jp5nw   IPv4          80      10.244.0.50,10.244.0.49   2d23h

kubectl get endpointslices -l kubernetes.io/service-name=probed
NAME           ADDRESSTYPE   PORTS   ENDPOINTS                 AGE
probed-jp5nw   IPv4          80      10.244.0.50,10.244.0.49   2d23h

- Part 5.3 — `slow-start` restart loop evidence AND `slow-start-fixed` reaching Running with 0 restarts
k get pod slow-start -w
NAME         READY   STATUS    RESTARTS   AGE
slow-start   1/1     Running   0          7s
slow-start   1/1     Running   0          30s
slow-start   1/1     Running   1 (0s ago)   60s
slow-start   1/1     Running   2 (1s ago)   2m1s

kubectl get pod slow-start-fixed -w 
NAME               READY   STATUS    RESTARTS   AGE
slow-start-fixed   0/1     Running   0          3s
slow-start-fixed   0/1     Running   0          100s
slow-start-fixed   1/1     Running   0          100s
slow-start-fixed   1/1     Running   0          2m54s
slow-start-fixed   1/1     Running   0          5m52s

- Part 6 — `ordered-app` stuck at `Init:0/1`, then Running after the service appeared

kubectl get pod ordered-app          
NAME          READY   STATUS     RESTARTS   AGE
ordered-app   0/1     Init:0/1   0          8s

kubectl get pod ordered-app -w  
NAME          READY   STATUS    RESTARTS   AGE
ordered-app   1/1     Running   0          81s


- Part 7.1 — the QoS custom-columns output

kubectl get pods -o custom-columns='NAME:.metadata.name,QOS:.status.qosClass' | grep qos-
qos-besteffort             BestEffort
qos-burstable              Burstable
qos-guaranteed             Guaranteed


- Part 7.2 — the `OOMKilled` reason
kubectl get pod oom-victim -o jsonpath='{.status.containerStatuses[0].state.terminated.reason}{"\n"}'
OOMKilled
## 4. One trade-off I had to make

(2–4 sentences. Pick one: exec vs httpGet readiness probe, startup probe vs initialDelay,
init container vs in-app retry, tight vs loose CRD schema, etc.)

Startup probe vs. initialDelaySeconds
Startup probe allows kubelet to begin liveness checks as soon as the application is actually ready, rather than waiting a fixed amount of time every startup.

Init container vs. in-app retry
I would choose an init container to wait for the database instead of adding retry logic to the application startup. This keeps infrastructure concerns separate from application code and provides independent logs and lifecycle management for the startup process. I would still implement retry logic in the application for dependencies that can fail after the application has already started.

Exec vs. HTTP readiness probe
I woould choose an exec readiness probe because the application's readiness depended on the existence of a local file rather than an HTTP endpoint. An exec probe can verify internal application state that may not be exposed over the network, while an HTTP probe is generally simpler and better suited for web applications with health endpoints.

Tight vs. loose CRD schema
I would chose a tight CRD schema with required fields and validation rules instead of a loose schema. This allows the API server to reject invalid custom resources before they reach the controller, reducing runtime errors and making the operator more reliable. The trade-off is that schema changes require more planning when introducing new fields.

## 5. One thing I'm still unsure about

(One sentence. Goes to office hours.)