.
# Assignment 03 — Shukurat Olaitan  

**GitHub username:** shukratolaitan
**Date completed:** 2026-06-03
**Git SHA of submitted app:** f38da4913120db1b5a2e86f516ce3b6f0bafd742

## 1. Size comparison table

| Variant            | Size  | Layers | Stop time | Exit code |
|--------------------|-------|--------|-----------|-----------|
| `cohort-greet:naive` | 1.12GB | 19     | 0m5.226s     | 137        |
| `cohort-greet:multi` | 155 MB | 20     | 0m0.062s     | 137        |

(Layers = output of `docker image history <tag> | wc -l` minus 1 for the header.)

## 2. Final image digest
Naive Image

 cohort-greet:naive
`sha256:6ff74771b8bd600be99a23e9022e30da758809f9f44b2df1e45fa584e4a14f43`

Multi-Stage Image
 cohort-greet:multi
`sha256:d2860f7cceadefd6bbb7bb053ca39ad244d164de94f4662ead57e2577e3ba9c2`

## 3. Answers to the 7 questions

**Q1 — naive size + stop behaviour + why:** ...
The naive image was: 1.12GB
The container exited with Exit code: 137

Exit code 137 usually means the container was forcefully killed. In this case, the container did not stop gracefully before Docker’s timeout, so Docker eventually sent a kill signal.

The naive image was also much larger because it used the full python:3.11 base image and copied more files into the image than necessary.

**Q2 — build output, CACHED vs rebuilt:** ...
docker image build -t cohort-greet:multi . 2>&1 | grep -E "CACHED|RUN pip"
#7 CACHED
#8 CACHED
#9 CACHED
#10 CACHED
#11 [build 5/5] RUN pip install --no-cache-dir -r requirements.txt
#11 CACHED
#12 CACHED
#13 CACHED

The dependency install layer reused the cache only the application copy layer was rebult. This shows why it is useful to copy requirements.txt separately before copying application code. If the dependencies do not change, Docker can reuse the cached pip install layer.


**Q3 — new stop time/exit + which change:** ...
The improved container stopped in 0m0.048s with ExitCode=0

The key change was using exec-form CMD: CMD ["python", "app.py"]

This makes the Python process become PID 1 directly inside the container. When Docker sends SIGTERM during docker stop, Python receives the signal immediately and shuts down gracefully.In the shell-form version, the shell became PID 1 instead. Signal forwarding was less reliable, so Docker eventually had to force kill the container after the timeout.

**Q4 — size reduction breakdown:** ...
The optimized image reduced the size from: 1.12GB → 155MB an 86% size reduction.
Several changes contributed to this improvement.

1. Switched from full Python to slim Python

Naive image:

FROM python:3.11

Optimized image:

FROM python:3.11-slim

The full Python image includes extra operating system packages, compilers, debugging utilities, and tools that are not needed at runtime. The slim image removes many of those extras while still keeping good compatibility.

2. Used a multi-stage build
FROM python:3.11-slim AS build
FROM python:3.11-slim AS runtime

The build stage installs dependencies into a virtual environment.The runtime stage copies only what is needed:

COPY --from=build /opt/venv /opt/venv This avoids carrying build-time files, pip cache, temporary files, and unnecessary tooling into the final image.

3. Avoided COPY . .

The naive Dockerfile used: COPY . .

This can accidentally copy files such as:

.git
tests
cache files
local development files
temporary files

The optimized Dockerfile only copies what the app needs:

COPY requirements.txt .
COPY app.py .

4. Used --no-cache-dir
RUN pip install --no-cache-dir -r requirements.txt

Without --no-cache-dir, pip stores downloaded package archives inside the image layer.

Using --no-cache-dir prevents those cached files from being saved into the final image.

5. Kept runtime image minimal

The naive image kept the full build environment.The multi-stage image only kept Python runtime, Installed dependencies, Application code, Non-root user setup, Healthcheck. This made the final runtime image much smaller.


**Q5 — cache-mount timings + CI relevance:** ...
#Cold build 
user    0m0.305s
sys     0m0.312s

#Warm build
user    0m0.273s
sys     0m0.211s
time saved 32s 

In a CI pipeline CI runners are ephemeral in that environment layer cache is cold because each layer starts with no docker cache. Remote BuildKit cache mounts can stay warm because they're stored in shared storage & reused across builds. This can significantly reduce build time, especially when dependency installation is expensive.

**Q6 — secret marker + what `ARG` would leak:** ...
docker container run --rm cohort-greet:secret cat /where-token-was-used

Output:
7143

docker image history --no-trunc cohort-greet:secret | grep -i "$PYPI_TOKEN" \
  && echo "LEAKED" || echo "no leak"

Output:
no leak

Using a BuildKit secret mount keeps the token available only during the build step that needs it.
If I used ARG PYPI_TOKEN, the token would be baked into the image build history and layer metadata, so anyone with access to docker hostory , inspect or image layers could potentially recover it. with secret mounts the token only exists during the single build step in /run/secrets & never persisted into the final image or history.

**Q7 — tag vs digest for k8s manifest:** ...

Digests are immutable & guarantess that Kubernetes pulls the exact image every time. prevents tag drift where 1.4.2 gets overwrriten later, ensures reliable rollouts and rollbacks.
A tag such as app:1.4.2 can be overwritten later. A digest such as app@sha256:... always points to the exact same image.

You must pin by digest only. You must never deploy mutable tags.( no latest, no semver, no git SHA )
You typically also:
Sign images (e.g., cosign)
Verify digest signatures in admission policies (OPA/Gatekeeper or Kyverno)
Store  software bill of materials (SBOMs) a detailed inventory of everything inside a softwarea artifact tied to the digest

## 4. Files

### Final `Dockerfile`
\`\`\`dockerfile
<# Build Stage
FROM python:3.11-slim AS build

RUN python -m venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt


# Runtime Stage
FROM python:3.11-slim AS runtime

COPY --from=build /opt/venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

# Create non-root user
RUN groupadd -g 1000 appuser && \
    useradd -u 1000 -g appuser -m appuser

WORKDIR /app

# Copy app as non-root owner
COPY --chown=1000:1000 app.py .

USER 1000:1000

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/health', timeout=2)" || exit 1

CMD ["python", "app.py"]>
\`\`\`

### `Dockerfile.naive`
\`\`\`dockerfile
<FROM python:3.11
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt
EXPOSE 8080
CMD gunicorn -b 0.0.0.0:8080 app:app>
\`\`\`

### `Dockerfile.secret`
\`\`\`dockerfile
<.git/, .gitignore
__pycache__/, *.pyc
Dockerfile*, *.md
.env*>
\`\`\`

### `.dockerignore`
\`\`\`
<.git/, .gitignore
__pycache__/, *.pyc
Dockerfile*, *.md
.env*>
\`\`\`

## 5. Evidence

For each, paste the command and output. Trim long output to the relevant lines.

- `docker image ls cohort-greet` (all your tags from Part 4.2)
docker image ls cohort-greet --format 'table {{.Repository}}\t{{.Tag}}\t{{.ID}}'

Output:

REPOSITORY     TAG             IMAGE ID
cohort-greet   0.1.0           9ca3a9a025e5
cohort-greet   0.1.0-f38da49   9ca3a9a025e5
cohort-greet   git-f38da49     9ca3a9a025e5
cohort-greet   multi           9ca3a9a025e5

- `docker image history cohort-greet:multi` (truncate long base-image rows)

docker image history cohort-greet:multi

Output:

IMAGE          CREATED             CREATED BY                                      SIZE      COMMENT
9ca3a9a025e5   About an hour ago   CMD ["python" "app.py"]                         0B        buildkit.dockerfile.v0
<missing>      About an hour ago   HEALTHCHECK {Test:[CMD-SHELL python -c "impo…   0B        buildkit.dockerfile.v0
<missing>      About an hour ago   EXPOSE [8080/tcp]                               0B        buildkit.dockerfile.v0
<missing>      About an hour ago   USER 1000:1000                                  0B        buildkit.dockerfile.v0
<missing>      About an hour ago   COPY --chown=1000:1000 app.py . # buildkit      361B      buildkit.dockerfile.v0
<missing>      About an hour ago   WORKDIR /app                                    0B        buildkit.dockerfile.v0
<missing>      About an hour ago   RUN /bin/sh -c groupadd -g 1000 appuser &&  …   8.92kB    buildkit.dockerfile.v0
<missing>      About an hour ago   ENV PATH=/opt/venv/bin:/usr/local/bin:/usr/l…   0B        buildkit.dockerfile.v0
<missing>      About an hour ago   COPY /opt/venv /opt/venv # buildkit             30.4MB    buildkit.dockerfile.v0
<missing>      14 hours ago        CMD ["python3"]                                 0B        buildkit.dockerfile.v0
<missing>      14 hours ago        RUN /bin/sh -c set -eux;  for src in idle3 p…   36B       buildkit.dockerfile.v0
<missing>      14 hours ago        RUN /bin/sh -c set -eux;   savedAptMark="$(a…   42MB      buildkit.dockerfile.v0
<missing>      14 hours ago        ENV PYTHON_SHA256=272179ddd9a2e41a0fc8e42e33…   0B        buildkit.dockerfile.v0
<missing>      14 hours ago        ENV PYTHON_VERSION=3.11.15                      0B        buildkit.dockerfile.v0
<missing>      14 hours ago        ENV GPG_KEY=A035C8C19219BA821ECEA86B64E628F8…   0B        buildkit.dockerfile.v0
<missing>      14 hours ago        RUN /bin/sh -c set -eux;  apt-get update;  a…   3.81MB    buildkit.dockerfile.v0
<missing>      14 hours ago        ENV LANG=C.UTF-8                                0B        buildkit.dockerfile.v0
<missing>      14 hours ago        ENV PATH=/usr/local/bin:/usr/local/sbin:/usr…   0B        buildkit.dockerfile.v0


- `docker container run --rm cohort-greet:secret cat /where-token-was-used`

Output:

7143

Secret Leak Check

Output:

- The "no leak" / "LEAKED" check from Part 3.2
no leak

Hadolint Check

- `docker container run --rm hadolint/hadolint < Dockerfile` (should be empty)

Output:

YES
- The two timing lines from Part 3.1 (cold vs warm cache mount)

#Cold build 
user    0m0.305s
sys     0m0.312s

#Warm build
user    0m0.273s
sys     0m0.211s
time saved 32s 
- (Optional) URL of your pushed image
Docker Hub Repository
https://hub.docker.com/repository/docker/shukratolaitan/cohort-greet

## 6. One trade-off I had to make

(2–4 sentences. Pick **one** decision where the slides offered multiple options and you had to choose: alpine vs slim vs distroless, USER 1000 vs `useradd app`, healthcheck via python vs installing curl, etc. Explain why you chose what you chose and what you'd give up by picking the other.)

One trade-off I had to make was choosing between Alpine, Slim, and Distroless base images.

I chose python:3.11-slim because it provides a strong balance between image size, compatibility, and debugging ability.

Alpine is much smaller, but it can make Python dependency installation harder because some packages may need to compile against musl instead of glibc. Distroless has an even smaller attack surface, but it does not include a shell or package manager, which makes debugging much harder.

The slim image is slightly larger than Alpine or Distroless, but it is easier to work with and still much smaller than the full Python image.

USER 1000:1000 Simple and fast, No extra layers or OS commands. Tradeoff No named user, Harder to debug (“who is 1000?”), Can conflict with file permissions in some systems.

useradd app having a Named user improves readability, Creates home directory, More portable across environments

Tradeoff: Slightly larger image layer, Requires OS tools (not available in distroless)

Why I chose 1000:1000 earlier
Works across almost all base images
Minimal and deterministic
Good for CI examples and Kubernetes workloads


Python healthcheck

No extra packages needed, Works in slim/distroless (if Python exists)

Cons: Verbose, Harder to debug than curl

curl healthcheck

Pros: Simple and readable, Standard tool

Cons: Adds dependency (~1–5MB), In distroless, you can’t install it at all







