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