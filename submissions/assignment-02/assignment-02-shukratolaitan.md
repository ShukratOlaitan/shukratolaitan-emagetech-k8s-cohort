# Assignment 02 — <Shukurat Olaitan>

**GitHub username:** <shukratolaitan>
**Date completed:** 2026-04-29
**Language chosen:** Python | Node.js

## 1. The image I built

- Final image ID: `<docker image inspect -f '{{.Id}}' cohort-greet:0.1.0>`
- Image size: `<from docker image ls>`
- Number of layers: `<from docker image history | wc -l minus 1 for header>`

### Dockerfile
\`\`\`dockerfile
<# Python:
FROM python:3.11-slim
# Node:
# FROM node:20-alpine

WORKDIR /app
COPY app.py .
# For Node, use: COPY app.js .
RUN apt-get update && apt-get install -y procps && rm -rf /var/lib/apt/lists/*
ENV PORT=8000
EXPOSE 8000

# Python:
CMD ["python", "app.py"]
# Node:
# CMD ["node", "app.js"]>
\`\`\`

### .dockerignore
\`\`\`
<.git
.gitignore
node_modules
__pycache__
*.pyc
*.log
README.md>
\`\`\`

## 2. Answers to the 8 questions

**Q1 — what `.dockerignore` affects:** ...
it controls what gets included in the build process. It tells Docker CLI what file to ignore when communicating with the daemon.

**Q2 — what is the image ID a hash of:** ...
The image ID 211514cf37d3  is a shortened form of the 64 bit SHA-256 hash of the image's configuration object. hash of the image config which references the layers not the layers themselves or disk size.
**Q3 — largest layer and why:** ...
<missing>      41 hours ago    # debian.sh --arch 'amd64' out/ 'trixie' '@1…   78.6MB    debuerreotype 0.17
The base image is a Debian file system. It’s the layer where python dependencies are runtime dependencies are installed.

**Q4 — `--memory 64m` shows up as what value:** ...
It shows up as "Memory": 67108864.its converted to bytes.

**Q5 — PID of my app inside the container:** ...
PID 1 it’s the containers main process & the container stops if PID1 exits.

**Q6 — `stop` vs `kill`, and which for a database:** ...
Stop gracefully stops the running container and exits normally. Kill abruptly terminates the container. For Databases often have open writes, replication states & checkpoints kill could lead to data loss & corrupted data files.

**Q7 — what same-IMAGE-ID-across-tags proves:** ...
Docker doesn’t use duplicate image data so all three tags reference the same image layers and metadata.

**Q8 — tag vs digest mutability:** ...
No a retagged alpine:3.19 means you will get new image layers. However alpine@sha256 is immutable and gives you the same image as the hash is computed from the image manifest which includes layers digest, config json hash.

## 3. Evidence

Paste the **command + output** for each of these. Use fenced code blocks. Trim long output to the relevant lines.

- `docker image history cohort-greet:0.1.0`
IMAGE          CREATED             CREATED BY                                      SIZE      COMMENT
3e15f7e6f4fd   2 minutes ago       CMD ["python" "app.py"]                         0B        buildkit.dockerfile.v0
<missing>      2 minutes ago       EXPOSE [8000/tcp]                               0B        buildkit.dockerfile.v0
<missing>      2 minutes ago       ENV PORT=8000                                   0B        buildkit.dockerfile.v0
<missing>      2 minutes ago       RUN /bin/sh -c apt-get update && apt-get ins…   2.31MB    buildkit.dockerfile.v0
<missing>      About an hour ago   COPY app.py . # buildkit                        741B      buildkit.dockerfile.v0
<missing>      About an hour ago   WORKDIR /app                                    0B        buildkit.dockerfile.v0
<missing>      17 hours ago        CMD ["python3"]                                 0B        buildkit.dockerfile.v0
<missing>      17 hours ago        RUN /bin/sh -c set -eux;  for src in idle3 p…   36B       buildkit.dockerfile.v0
<missing>      17 hours ago        RUN /bin/sh -c set -eux;   savedAptMark="$(a…   42MB      buildkit.dockerfile.v0
<missing>      17 hours ago        ENV PYTHON_SHA256=272179ddd9a2e41a0fc8e42e33…   0B        buildkit.dockerfile.v0
<missing>      17 hours ago        ENV PYTHON_VERSION=3.11.15                      0B        buildkit.dockerfile.v0
<missing>      17 hours ago        ENV GPG_KEY=A035C8C19219BA821ECEA86B64E628F8…   0B        buildkit.dockerfile.v0
<missing>      17 hours ago        RUN /bin/sh -c set -eux;  apt-get update;  a…   3.81MB    buildkit.dockerfile.v0
<missing>      17 hours ago        ENV LANG=C.UTF-8                                0B        buildkit.dockerfile.v0
<missing>      17 hours ago        ENV PATH=/usr/local/bin:/usr/local/sbin:/usr…   0B        buildkit.dockerfile.v0
<missing>      42 hours ago        # debian.sh --arch 'amd64' out/ 'trixie' '@1…   78.6MB    debuerreotype 0.17

- `docker container run` (Part 2.2 — the detached run with all flags)

be7eca7f9626b42956a8036e55deeca5dc15599834dd9d7b23f20baeeb3807be

- `docker container logs greet` after 2 curl requests
listening on :8000
[req] 192.168.65.1 "GET / HTTP/1.1" 200 -
[req] 192.168.65.1 "GET / HTTP/1.1" 200 -

- `docker container stats --no-stream greet`

CONTAINER ID   NAME      CPU %     MEM USAGE / LIMIT   MEM %     NET I/O         BLOCK I/O   PIDS
8e657fc24a63   greet     0.02%     13.55MiB / 64MiB    21.18%    1.17kB / 126B   0B / 0B     1

- `docker container inspect -f '{{.HostConfig.RestartPolicy.Name}} {{.HostConfig.Memory}}' greet`
unless-stopped 67108864
- `docker image ls cohort-greet` (showing the three tags from Part 3.1)
- (Optional) URL of your pushed image on Docker Hub / GHCR
https://hub.docker.com/repository/docker/shukratolaitan/cohort-greet/general
docker tag cohort-greet:0.1 shukratolaitan/cohort-greet:0.1 
docker push shukratolaitan/cohort-greet:0.1

## 4. One thing that surprised me
One thing that surprised me When I ran ps aux after I exec into the container. I realized the utility wasn’t installed. I tried installing,it didn’t work because the container exceeded its memory limit. The alternative was to edit my Dockerfile to include the necessary tool & rebuild my image. Which eventually worked.

# 
apt-get update && apt-get install -y procps

## 5. One thing I'm still unsure about

(One sentence. This is what your TA will follow up on in office hours.)



# Assignment 02 — Docker Images, Layers & Runtime

> **Name:** Shukurat Olaitan
> **GitHub:** `shukratolaitan`
> **Date Completed:** 2026-04-29
> **Language Chosen:** Python

---

# Part 1 — The Image I Built

## Image Information

| Item         | Value                |
| ------------ | -------------------- |
| Image Name   | `cohort-greet:0.1.0` |
| Language     | Python               |
| Base Image   | `python:3.11-slim`   |
| Exposed Port | `8000`               |

### Final Image ID

```bash
docker image inspect -f '{{.Id}}' cohort-greet:0.1.0
```

### Image Size

```bash
docker image ls cohort-greet
```

### Number of Layers

Calculated from:

```bash
docker image history cohort-greet:0.1.0 | wc -l
```

Subtracting one line for the header.

---

## Dockerfile

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY app.py .

RUN apt-get update && \
    apt-get install -y procps && \
    rm -rf /var/lib/apt/lists/*

ENV PORT=8000

EXPOSE 8000

CMD ["python", "app.py"]
```

---

## .dockerignore

```text
.git
.gitignore
node_modules
__pycache__
*.pyc
*.log
README.md
```

The `.dockerignore` file helps keep unnecessary files out of the build context, resulting in faster builds and smaller images.

---

# Part 2 — Questions

## Q1 — What does `.dockerignore` affect?

The `.dockerignore` file controls which files are sent to the Docker daemon during the image build process.

It tells Docker which files and directories should be ignored when creating the build context.

Benefits include:

* Faster image builds
* Smaller build context size
* Reduced image size
* Preventing sensitive files from being copied accidentally

Examples of commonly ignored files:

```text
.git
node_modules
__pycache__
*.log
```

---

## Q2 — What is the Image ID a hash of?

The Image ID:

```text
211514cf37d3
```

is a shortened version of a SHA-256 hash.

The hash represents the image's **configuration object**, which contains metadata describing the image and references to its layers.

It is **not**:

* A hash of the image size
* A hash of the filesystem contents alone

Instead, it is a hash of the image configuration that points to the underlying layer structure.

---

## Q3 — What is the largest layer and why?

From `docker image history`:

```text
# debian.sh --arch 'amd64' out/ 'trixie'
78.6MB
```

The largest layer is the Debian base filesystem included in the `python:3.11-slim` image.

This layer contains:

* Core Linux system files
* Package management tools
* Shared libraries
* Runtime dependencies required for Python

Because every Python application depends on these system components, the base operating system layer is typically the largest part of the image.

---

## Q4 — What does `--memory 64m` show up as?

Running:

```bash
docker container inspect greet
```

shows:

```json
"Memory": 67108864
```

Docker stores memory limits in bytes.

Conversion:

```text
64 × 1024 × 1024 = 67,108,864 bytes
```

Therefore:

```text
64m = 67,108,864 bytes
```

---

## Q5 — What is the PID of your application inside the container?

The application runs as:

```text
PID 1
```

Inside a container, the main application process becomes PID 1.

This is important because:

* PID 1 receives container signals
* PID 1 controls container lifecycle
* If PID 1 exits, the container stops

In this assignment, the Python application was the container's primary process.

---

## Q6 — Difference between `docker stop` and `docker kill`

### `docker stop`

```bash
docker stop greet
```

Docker sends a `SIGTERM` signal first, allowing the application to shut down gracefully.

Benefits:

* Saves data properly
* Finishes open requests
* Closes files cleanly

---

### `docker kill`

```bash
docker kill greet
```

Docker sends `SIGKILL` immediately.

The process is terminated without cleanup.

---

### Which should be used for a database?

For databases, use:

```text
docker stop
```

Databases often have:

* Open write operations
* Transaction logs
* Replication state
* Cached data

Using `docker kill` can cause:

* Data corruption
* Incomplete writes
* Recovery delays

---

## Q7 — What does having the same Image ID across multiple tags prove?

When multiple tags show the same Image ID:

```text
cohort-greet:0.1
cohort-greet:latest
shukratolaitan/cohort-greet:0.1
```

it proves that Docker is not storing multiple copies of the image.

Instead:

* All tags reference the same image
* The same layers are reused
* No additional disk space is consumed

This demonstrates Docker's layer-sharing and content-addressable storage system.

---

## Q8 — Tag vs Digest Mutability

### Tags

Tags are mutable.

Example:

```text
alpine:3.19
```

The image associated with this tag may change over time if the publisher pushes an updated image.

---

### Digests

Digests are immutable.

Example:

```text
alpine@sha256:...
```

A digest always points to the exact same image manifest.

The digest includes references to:

* Image layers
* Configuration metadata
* Filesystem contents

Because the digest is cryptographically generated, it guarantees you receive the exact image that was originally published.

---

# Part 3 — Evidence

## Docker Image History

```bash
docker image history cohort-greet:0.1.0
```

```text
IMAGE          CREATED             CREATED BY                                      SIZE
3e15f7e6f4fd   2 minutes ago       CMD ["python" "app.py"]                         0B
<missing>      2 minutes ago       EXPOSE [8000/tcp]                               0B
<missing>      2 minutes ago       ENV PORT=8000                                   0B
<missing>      2 minutes ago       RUN apt-get update && apt-get install...         2.31MB
<missing>      About an hour ago   COPY app.py .                                   741B
<missing>      About an hour ago   WORKDIR /app                                    0B
...
<missing>      42 hours ago        Debian base layer                               78.6MB
```

---

## Detached Container Run

```bash
docker container run \
-d \
--name greet \
-p 8000:8000 \
--memory 64m \
--restart unless-stopped \
cohort-greet:0.1.0
```

Output:

```text
be7eca7f9626b42956a8036e55deeca5dc15599834dd9d7b23f20baeeb3807be
```

---

## Container Logs

After sending two requests:

```bash
docker container logs greet
```

Output:

```text
listening on :8000
[req] 192.168.65.1 "GET / HTTP/1.1" 200 -
[req] 192.168.65.1 "GET / HTTP/1.1" 200 -
```

---

## Container Statistics

```bash
docker container stats --no-stream greet
```

```text
CONTAINER ID   NAME    CPU %   MEM USAGE / LIMIT   MEM %
8e657fc24a63   greet   0.02%   13.55MiB / 64MiB    21.18%
```

This confirms the memory limit is being enforced correctly.

---

## Restart Policy & Memory Limit

```bash
docker container inspect \
-f '{{.HostConfig.RestartPolicy.Name}} {{.HostConfig.Memory}}' \
greet
```

Output:

```text
unless-stopped 67108864
```

Meaning:

* Restart Policy = `unless-stopped`
* Memory Limit = `64 MB`

---

## Docker Hub Repository

Image successfully pushed to Docker Hub:

```text
https://hub.docker.com/repository/docker/shukratolaitan/cohort-greet/general
```

Commands used:

```bash
docker tag cohort-greet:0.1 \
shukratolaitan/cohort-greet:0.1

docker push shukratolaitan/cohort-greet:0.1
```

---

# Part 4 — One Thing That Surprised Me

One thing that surprised me was discovering that basic Linux utilities are not always included in minimal container images.

After entering the container and running:

```bash
ps aux
```

I realized the command was unavailable because the required package (`procps`) was not installed.

Initially, I attempted to install it inside the running container, but because the container was operating under a strict memory limit, the installation failed.

The proper solution was to modify the Dockerfile:

```dockerfile
RUN apt-get update && \
    apt-get install -y procps
```

and then rebuild the image.

This taught me an important lesson:

> Containers should be built with all required dependencies ahead of time rather than relying on manual changes after they start.

---

# Part 5 — One Thing I'm Still Unsure About

One thing I am still unsure about is how Docker decides when image layers can be reused across different builds.

I understand that Docker uses layer caching to speed up builds, but I would like to learn more about:

* How cache invalidation works
* Why changing one file sometimes causes multiple layers to rebuild
* Best practices for ordering Dockerfile instructions to maximize cache efficiency

This seems especially important for larger projects where build performance matters.

---

