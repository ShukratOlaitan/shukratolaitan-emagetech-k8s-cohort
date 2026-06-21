#Assignment 04 - Shukurat Olaitan

GitHub username: shukratolaitan
Date completed: 2026-06-10

1. Answers to the 11 questions

Question 1: Paste the dig and getent output. The api container’s /etc/resolv.conf points to a real resolver (127.0.0.11) — so why does dig db come back empty? What does Docker’s embedded DNS server actually serve on the default bridge vs a user-defined bridge?
— dig db —
— getent —
not found

dig db is empty because the container is not getting Docker's embedded name service path to the DB on the default bridge network

On the default bridge, Docker does not provide automatic container DNS like the user-defined bridge. On the user-defined bridge, dicker embedded DNS is 127.0.0.11 used for resolving user-defined networks, where it resolves container,service names & aliases. On the default bridge, containers can only reach each other by IP.

Question 2: Did the DB’s IP change after the restart? In production, why is hard-coding an IP and the absence of DNS the same bug? What would it take to make this approach actually reliable on the default bridge (and why is the answer “don’t”)?

No, the IP address stayed the same.
They only work if the container is reused, no recreation happens, and breaks when the container is recreated.

It would require a fixed container IP, subnet , no conflicting containers, and a process that recreates the exact same IP assignment every time. which isn't realistic as Docker's default bridge isn't designed for service discovery& container IPs are ephemeral

Dont
Docker already provides
user-defined bridge networks
embedded DNS (127.0.0.1)
service-name resolution

Question 3: What subnet did Docker pick for cohort-net? What gateway IP? If you wanted to control those (e.g., to avoid conflicting with your office VPN range), which Docker network create flags would you add?

"Subnet": "172.22.0.0/16"
"Gateway": "172.22.0.1"

docker network create --subnet

Question 4: Paste the three outputs above. What’s different about dig db here vs Part 1? Notice you can reach api by name too, not just the DB — what’s the design implication for a 10-service stack? (Hint: in the default bridge world, every service would need to know every other service’s IP.)

— dig db —
172.22.0.2
— dig api —
172.22.0.3
— curl api —
ok
Design implication allows services to be read by names, not just IP addresses. So a 10 service stack only requires agreement on names instead of tracking every service’s IP address. In a default bridge, each service would need a hardcoded peer IP and a manual /etc/hosts entry, which can be difficult to manage as the service count grows or when a container is restarted, as a replacement can invalidate a configuration.

Question 5: The stranger container couldn’t resolve or reach the DB. Which Docker primitive provided that isolation? What’s the one thing you would need to do to let it reach DB while still running on cohort-other?

A user-defined bridge network provides isolation by default.
To enable the stranger container read DB, we can connect it using
docker network connect cohort-net stranger
docker network connect cohort-other db

Question 6: Explain in 3–4 sentences why the third probe fails. What is -p HOST:CONTAINER actually doing — is it changing the container’s listening port, or is it doing something else entirely? (Run sudo iptables -t nat -L DOCKER -n 2>/dev/null on Linux, or pfctl -s nat 2>/dev/null on macOS — you don’t need to paste the output, just describe what it shows.)

cohort-net is attached to the temporary container
http://api:18080/healthz targets the API container’s own port 18080, but the app is listening on 8080 inside the container, and 18080 is only the host-published port on the Docker host.

The correct in-network address is http://api:8080/healthz, which is why container-to-container calls use the container port, not the host port mapping. It's not changing the container’s listening port.

docker container exec api curl …
curl: executable file not found in $PATH image is python:slim doesn't have  curl installed, instead used
docker container run --rm --network container:api nicolaka/netshoot \

docker container rm -f db
docker container run -d --name db --network cohort-net 
-v cohort-db-data:/var/lib/postgresql/data 
-e POSTGRES_USER=cohort -e POSTGRES_PASSWORD=cohort -e POSTGRES_DB=cohort 
postgres:16-alpine

deleted the db container created a new one with the volume mounted  -v cohort-db-data:/var/lib/postgresql/data 
brand new database, no schema

docker container exec api curl -s -X POST http://localhost:8080/notes 
-H ‘content-type: application/json.’ 
-d ‘{“body”:“this note IS protected”}’ returned 500 Internal Server Error

docker logs api showed psycopg2.errors.UndefinedTable: relation “notes” does not exist
So I restarted the api container
docker restart api
Recreate the note

docker container exec api curl -s -X POST http://localhost:8080/notes 
-H ‘content-type: application/json.’ 
-d ‘{“body”:“this note IS protected”}.’

Question 7: Did Docker rm -fv actually delete cohort-db-data? Read docker volume rm --help and docker container rm --help carefully — what does the -v flag on rm actually remove (and not remove)? Why is a named volume different from an anonymous one in this respect?

No cohort-db-data persists.
docker rm -v removes anonymous volumes attached exclusively to that container
named vs anonymous volume
independent persistent resources, managed separately from containers. Anonymous volumes in Docker are created implicitly. Docker assigns a random volume name.

Question 8: Name two things you can do with a bind mount that you can’t (easily) do with a named volume, and two reasons you should still prefer a named volume for app data in production. The mount point of a named volume is a host path — why is poking at it directly considered a bad idea?

Bind Mount
Live file editing allows you to operate on container-visible files. Named volumes aren't convenient for this.
Host-dependent paths allow you to choose the precise path or directory.
A bind mount hardcodes the volume location and is not portable, as different developers can have different laptops, Mac & Linux, so the path is different. Bind mounts couple containers to specific paths, machine & host layout.

Named Volumes
Specifically for databases, databases expect stable storage, consistent filesystem behaviour & controlled permissions.
designed to persist container data, portable across container recreation as it's stored in a specific directory /var/lib/docker/volumes that Docker treats as an internal engine-managed state, so it doesn't change

The mount point of a named volume is a host path — why is poking at it directly considered a bad idea?

It can corrupt the database state.
It can corrupt permissions & file state.

Question 9: Name one realistic workload where tmpfs is the right choice over a bind/volume. What two guarantees does it give you that disk-backed storage doesn’t?
Temporary secrets that are not written to disk.

Data is never written to disk, such as secrets, session tokens, because there is no persistence.

Automatic cleanup is tied to the container lifecycle
tmpfs guarantees storage disappears automatically when the container exits; no manual cleanup is required.

Question 10: You stopped the DB before backing up. What category of corruption does that prevent? For a real Postgres workload, what’s the production-grade alternative to “stop the database to back it up”?

It prevents partially written filesystem snapshots caused by copying databases while PostgreSQL is still mutating them.
It prevents crash-inconsistent backups if tar reads files while Postgres is actively writing. Backup may contain mutually inconsistent pieces of time.

Production solution is Logical or hot backups, usually using PostgreSQL-native tooling.

pg_dump -U cohort cohort > backup.sql
It creates transactionally consistent logical backup without stopping the database.

Question 11: compose creates a network for you automatically — what does it name it, and how does its name differ from the one you created by hand in Part 2? When would external: true on a volume save you from a real outage? (Hint: think about what docker compose down -v does.)

assignment-04_cohort-net
the naming pattern is project name + network name
in part 2 its created manually docker network create cohort-net.

when you run docker compose down -v it treats volumes asits own stack of resources. it stops containers, removed networks, delete named volumes created by compose which is catastrophic for a database. -v preventthe extrenal volume from getting deleted.

2. Network + volume listing

Paste the output of:

* docker network ls
SOO-A >>docker network ls
NETWORK ID     NAME         DRIVER    SCOPE
fd8c6a68e9de   app-net      bridge    local
2d7449c84964   backend      bridge    local
8d311f3f82ed   bridge       bridge    local
9b5d005da66c   cohort-net   bridge    local
0308c6e2aa66   frontend     bridge    local
49e861715be7   host         host      local
1cbc073e95e7   kind         bridge    local
40ddc5017e0a   none         null      local
* docker network inspect cohort-net --format '{{json .IPAM.Config}}' | jq
[
{
“Subnet”: “172.22.0.0/16”,
“Gateway”: “172.22.0.1”
}
]
* docker volume ls
SOO-A >>docker volume ls
DRIVER    VOLUME NAME
local     16e43b8bcaa5489f3ea4f9c5e247f423e8aed8e575cb857ead28fb1724955398
local     57d32644d404070f39fb44e67bd1a8bce6a14fb503ad3f702beaa9a91eab5cc8
local     72cb74d8d23c60ca1371cae466e356cd6ebd6986f17c5b73bca4141cd35cabe0
local     224e7403a90c6a38c475bff33fe6e511be2e7c01d44796b4361c305e3189d3fc
local     341f06ff28cef7981fbee33ebd7d9959b19477f7416ab05283851f38610541ea
local     975d97f494d870fe706940eb007fc0b481b2860caf4149eeb7dfaf1cbfd792f6
local     64329c9bbed0bb34e73f01ad3033fd554e65a0cac4da3dfd45702d15d5e3c271
local     a8ede610693c98c2a32523a485f6907b4a59345503102b11ca8dc2ee7b8e599a
local     ba19f5fab812f9853040dca374f7ed5fea1979bd3debd8f4010c20cac733339f
local     cohort-db-data
* docker volume inspect cohort-db-data
[
{
“CreatedAt”: “2026-06-10T16:59:42Z”,
“Driver”: “local”,
“Labels”: null,
“Mountpoint”: “/var/lib/docker/volumes/cohort-db-data/_data”,
“Name”: “cohort-db-data”,
“Options”: null,
“Scope”: “local”
}
]

3. Files

api/Dockerfile

```dockerfile
FROM python:3.11-slim AS build
RUN python -m venv /opt/venv
ENV PATH=/opt/venv/bin:$PATH
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.11-slim AS runtime
RUN useradd --uid 1000 --create-home app
COPY --from=build /opt/venv /opt/venv
ENV PATH=/opt/venv/bin:$PATH
WORKDIR /app
COPY app.py .
EXPOSE 8080
USER app
CMD [“gunicorn”, “-b”,“0.0.0.0:8080”, “app:app”]

```

api/app.py

```python
import os, time
import psycopg2
from flask import Flask, request, jsonify

app = Flask(name)

DB_HOST = os.environ.get(“DB_HOST”, “db”)
DB_USER = os.environ.get(“DB_USER”, “cohort”)
DB_PASS = os.environ.get(“DB_PASS”, “cohort”)
DB_NAME = os.environ.get(“DB_NAME”, “cohort”)

def connect():
for _ in range(30):
try:
return psycopg2.connect(
host=DB_HOST, user=DB_USER, password=DB_PASS, dbname=DB_NAME
)
except psycopg2.OperationalError:
time.sleep(1)
raise RuntimeError(“db never came up”)

@app.before_request
def ensure_schema():
if getattr(app, “_ready”, False):
return
with connect() as c, c.cursor() as cur:
cur.execute(
“CREATE TABLE IF NOT EXISTS notes (id SERIAL PRIMARY KEY, body TEXT NOT NULL).”
)
c.commit()
app._ready = True

@app.get(“/notes”)
def list_notes():
with connect() as c, c.cursor() as cur:
cur.execute(“SELECT id, body FROM notes ORDER BY id”)
return jsonify([{“id”: i, “body”: b} for i, b in cur.fetchall()])

@app.post(“/notes”)
def add_note():
body = request.json.get(“body”, “”)
with connect() as c, c.cursor() as cur:
cur.execute(“INSERT INTO notes (body) VALUES (%s) RETURNING id”, (body,))
c.commit()
return jsonify({“id”: cur.fetchone()[0], “body”: body}), 201

@app.get(“/healthz”)
def healthz():
return (“ok”, 200)

```

compose.yml

```yaml
services:
db:
image: postgres:16-alpine
environment:
POSTGRES_USER: cohort
POSTGRES_PASSWORD: cohort
POSTGRES_DB: cohort
volumes:
- cohort-db-data:/var/lib/postgresql/data
healthcheck:
test: [“CMD-SHELL”, “pg_isready -U cohort”]
interval: 5s
retries: 5
networks:
- cohort-net

api:
image: cohort-api:0.1.0
environment:
DB_HOST: db
ports:
- “18080:8080”
depends_on:
db:
condition: service_healthy
networks:
- cohort-net

networks:
cohort-net:

volumes:
cohort-db-data:
external: true   # reuse the volume from Part 4
```

4. Evidence

Paste the command + output (trim long output to the relevant lines):

* Part 1.2 — the netshoot DNS probe on the default bridge (showing dig db empty)

— dig db —

* Part 2.3 — the netshoot DNS probe on cohort-net (showing dig db returns an IP)
— dig db —
172.22.0.2
* Part 2.5 — the stranger-container probe on cohort-other (showing it can’t reach the DB)

ping: db: Name does not resolve
— dig db —

* Part 3.1 — the three curls (host → 18080 OK, container → 8080 OK, container → 18080 fails)
ok (host -> 18080 OK)
ok (container -> 8080 OK)
(port 18080 from container failed — as expected)
* Part 4.3 — docker volume ls after docker rm -fv throwaway-db (volume still present)

SOO-A >>docker volume ls --filter name=cohort-db-data
DRIVER    VOLUME NAME
local     cohort-db-data

* Part 5.1 — ls -lh cohort-db-data-*.tar.gz (backup file exists)
-rw-r–r--  1 shukuratolaitan-animasaun  staff   6.4M Jun 10 13:46 cohort-db-data-20260610.tar.gz
* Part 5.2 — SELECT * FROM notes from the verification db (data restored)
SOO-A >>docker container exec db-verify psql -U cohort -d cohort -c ‘SELECT id, body FROM notes;.’
id |      body
----±----------------
1 | persistent note
(1 row)
* Part 6 — docker compose ps + curl http://localhost:18080/notes (compose stack works)
SOO-A >>docker compose ps
NAME                  IMAGE                COMMAND                  SERVICE   CREATED          STATUS                    PORTS
assignment-04-api-1   cohort-api:0.1.0     “gunicorn -b 0.0.0.0…”   api       15 seconds ago   Up 9 seconds              0.0.0.0:18080->8080/tcp, [::]:18080->8080/tcp
assignment-04-db-1    postgres:16-alpine   “docker-entrypoint.s…”   db        15 seconds ago   Up 15 seconds (healthy)   5432/tcp

SOO-A >>curl -s http://localhost:18080/notes
[{“body”:“persistent note”,“id”:1}]

5. One trade-off I had to make

(2–4 sentences. Pick one decision where the slides offered multiple options, and you had to choose: named volume vs bind mount for the db, host network mode vs -p, compose vs raw docker commands, etc. Explain why you chose what you chose and what you’d give up by picking the other.)

Named volume vs Bind mount

host network vs. user-defined bridge
User defined bridge have embedded docker DNS & service discovery on the default no automatic DNS & containers needs IP’s.

-p port publishing vs host network mode
Port publishing provides network namespace isolation
docker firewall

host network
container shares the host’s network stack directly. No NAT. No port mapping.

Compose Vs raw Docker commands.

Docker Compose provides reproducibility & declarative infrastructure.

The Docker command is manual and exposes the primitives of how Docker builds a lightweight isolated container environment

6. One thing I’m still unsure about

(One sentence. Goes to office hours.)




# Assignment 04 — Docker Networks, Volumes & Compose

> **Name:** Shukurat Olaitan
> **GitHub:** `shukratolaitan`
> **Date Completed:** 2026-06-10

---

# Part 1 — Answers to the 11 Questions

## Q1 — Default bridge DNS behavior

### `dig db`

```text
not found
```

### `getent`

```text
not found
```

The `api` container’s `/etc/resolv.conf` points to Docker’s embedded resolver, but `dig db` comes back empty because the default bridge network does not provide automatic container-name DNS resolution.

On the default bridge, containers can usually reach each other by IP address, but they do not automatically resolve each other by container name. On a user-defined bridge network, Docker’s embedded DNS server at `127.0.0.11` resolves container names, service names, and aliases.

---

## Q2 — DB IP after restart and why hard-coding IPs is fragile

The DB IP address did not change after the restart.

However, hard-coding container IPs is still unreliable in production because the IP may change when the container is removed and recreated. This means hard-coding an IP and having no DNS are effectively the same bug: both approaches depend on unstable infrastructure details.

To make this reliable on the default bridge, I would need:

* Fixed container IPs
* A fixed subnet
* No IP conflicts
* A repeatable process for assigning the same IP every time

This is not realistic. The better answer is: **don’t do this**. Use a user-defined bridge network with Docker’s embedded DNS and service-name resolution.

---

## Q3 — Subnet and gateway for `cohort-net`

Docker chose:

```json
[
  {
    "Subnet": "172.22.0.0/16",
    "Gateway": "172.22.0.1"
  }
]
```

To control the subnet and gateway manually, I would use:

```bash
docker network create \
  --subnet 172.30.0.0/16 \
  --gateway 172.30.0.1 \
  cohort-net
```

This is useful when avoiding conflicts with VPNs, office networks, or other private IP ranges.

---

## Q4 — DNS on user-defined bridge

### `dig db`

```text
172.22.0.2
```

### `dig api`

```text
172.22.0.3
```

### `curl api`

```text
ok
```

This is different from the default bridge because the user-defined bridge provides automatic DNS-based service discovery.

The design implication is important: in a 10-service stack, services can communicate by name instead of tracking every other container’s IP address. This makes the stack easier to maintain, especially when containers are restarted or recreated.

---

## Q5 — Stranger container isolation

The stranger container could not resolve or reach the DB because user-defined bridge networks provide network isolation by default.

The Docker primitive responsible for this isolation is the **user-defined bridge network**.

To allow the stranger container to reach the DB while still running on `cohort-other`, I could connect it to `cohort-net` as well:

```bash
docker network connect cohort-net stranger
```

Alternatively, I could connect the DB to `cohort-other`:

```bash
docker network connect cohort-other db
```

The cleaner option is usually to attach the container that needs access to the application network.

---

## Q6 — Port publishing and why the third probe fails

The third probe fails because `18080` is the host-published port, not the port the application listens on inside the Docker network.

Inside the container network, the API listens on:

```text
8080
```

So this works:

```text
http://api:8080/healthz
```

But this fails from another container:

```text
http://api:18080/healthz
```

The `-p HOST:CONTAINER` flag does not change the container’s listening port. It creates a NAT/firewall rule that forwards traffic from the Docker host’s port to the container’s internal port.

Because the `python:slim` image did not include `curl`, I used a temporary networking toolbox container instead:

```bash
docker container run --rm --network container:api nicolaka/netshoot
```

---

## Q7 — Did `docker rm -fv` delete `cohort-db-data`?

No. The named volume `cohort-db-data` persisted.

The `-v` flag on `docker rm` removes anonymous volumes attached to the container. It does not remove named volumes like:

```text
cohort-db-data
```

Named volumes are independent Docker-managed resources. Anonymous volumes are created automatically with random names and are more tightly tied to a container’s lifecycle.

---

## Q8 — Bind mounts vs named volumes

### Two things bind mounts can do more easily

Bind mounts are useful when:

* You want live file editing from the host machine.
* You need to mount a specific host path into the container.

For example, bind mounts are convenient for local development because changes on the host immediately appear in the container.

### Two reasons to prefer named volumes in production

Named volumes are usually better for production app data because:

* They are managed by Docker.
* They are more portable across container recreation.
* They avoid hard-coding host-specific paths.
* They provide more predictable behavior for database storage.

Even though a named volume has a host path under `/var/lib/docker/volumes`, directly editing that path is a bad idea because it can corrupt database files, permissions, or Docker-managed state.

---

## Q9 — When tmpfs is the right choice

A realistic workload for `tmpfs` is storing temporary secrets, session tokens, or short-lived scratch data that should never be written to disk.

`tmpfs` provides two important guarantees:

1. The data is memory-backed and not persisted to disk.
2. The data disappears automatically when the container stops.

This makes it useful for sensitive temporary files that should not survive the container lifecycle.

---

## Q10 — Why stop the DB before backup?

Stopping the DB before backing it up prevents crash-inconsistent backups.

If PostgreSQL is actively writing while files are being copied, the backup could contain mismatched or partially written data.

For production, the better approach is to use PostgreSQL-native backup tools such as:

```bash
pg_dump -U cohort cohort > backup.sql
```

This creates a transactionally consistent logical backup without stopping the database.

---

## Q11 — Compose network names and external volumes

Compose automatically created a network named:

```text
assignment-04_cohort-net
```

The naming pattern is:

```text
project-name_network-name
```

This differs from the manually created network:

```text
cohort-net
```

Using `external: true` on a volume can prevent a real outage because `docker compose down -v` removes volumes created by Compose. If the database volume is external, Compose will not delete it when tearing down the stack.

This protects persistent database data from accidental deletion.

---

# Part 2 — Network and Volume Listing

## Docker Networks

Command:

```bash
docker network ls
```

Output:

```text
NETWORK ID     NAME         DRIVER    SCOPE
fd8c6a68e9de   app-net      bridge    local
2d7449c84964   backend      bridge    local
8d311f3f82ed   bridge       bridge    local
9b5d005da66c   cohort-net   bridge    local
0308c6e2aa66   frontend     bridge    local
49e861715be7   host         host      local
1cbc073e95e7   kind         bridge    local
40ddc5017e0a   none         null      local
```

---

## `cohort-net` IPAM Configuration

Command:

```bash
docker network inspect cohort-net --format '{{json .IPAM.Config}}' | jq
```

Output:

```json
[
  {
    "Subnet": "172.22.0.0/16",
    "Gateway": "172.22.0.1"
  }
]
```

---

## Docker Volumes

Command:

```bash
docker volume ls
```

Output:

```text
DRIVER    VOLUME NAME
local     16e43b8bcaa5489f3ea4f9c5e247f423e8aed8e575cb857ead28fb1724955398
local     57d32644d404070f39fb44e67bd1a8bce6a14fb503ad3f702beaa9a91eab5cc8
local     72cb74d8d23c60ca1371cae466e356cd6ebd6986f17c5b73bca4141cd35cabe0
local     224e7403a90c6a38c475bff33fe6e511be2e7c01d44796b4361c305e3189d3fc
local     341f06ff28cef7981fbee33ebd7d9959b19477f7416ab05283851f38610541ea
local     975d97f494d870fe706940eb007fc0b481b2860caf4149eeb7dfaf1cbfd792f6
local     64329c9bbed0bb34e73f01ad3033fd554e65a0cac4da3dfd45702d15d5e3c271
local     a8ede610693c98c2a32523a485f6907b4a59345503102b11ca8dc2ee7b8e599a
local     ba19f5fab812f9853040dca374f7ed5fea1979bd3debd8f4010c20cac733339f
local     cohort-db-data
```

---

## Inspecting `cohort-db-data`

Command:

```bash
docker volume inspect cohort-db-data
```

Output:

```json
[
  {
    "CreatedAt": "2026-06-10T16:59:42Z",
    "Driver": "local",
    "Labels": null,
    "Mountpoint": "/var/lib/docker/volumes/cohort-db-data/_data",
    "Name": "cohort-db-data",
    "Options": null,
    "Scope": "local"
  }
]
```

---

# Part 3 — Files

## `api/Dockerfile`

```dockerfile
FROM python:3.11-slim AS build

RUN python -m venv /opt/venv

ENV PATH=/opt/venv/bin:$PATH

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt


FROM python:3.11-slim AS runtime

RUN useradd --uid 1000 --create-home app

COPY --from=build /opt/venv /opt/venv

ENV PATH=/opt/venv/bin:$PATH

WORKDIR /app

COPY app.py .

EXPOSE 8080

USER app

CMD ["gunicorn", "-b", "0.0.0.0:8080", "app:app"]
```

---

## `api/app.py`

```python
import os
import time
import psycopg2
from flask import Flask, request, jsonify

app = Flask(__name__)

DB_HOST = os.environ.get("DB_HOST", "db")
DB_USER = os.environ.get("DB_USER", "cohort")
DB_PASS = os.environ.get("DB_PASS", "cohort")
DB_NAME = os.environ.get("DB_NAME", "cohort")


def connect():
    for _ in range(30):
        try:
            return psycopg2.connect(
                host=DB_HOST,
                user=DB_USER,
                password=DB_PASS,
                dbname=DB_NAME,
            )
        except psycopg2.OperationalError:
            time.sleep(1)

    raise RuntimeError("db never came up")


@app.before_request
def ensure_schema():
    if getattr(app, "_ready", False):
        return

    with connect() as c, c.cursor() as cur:
        cur.execute(
            "CREATE TABLE IF NOT EXISTS notes "
            "(id SERIAL PRIMARY KEY, body TEXT NOT NULL)"
        )
        c.commit()

    app._ready = True


@app.get("/notes")
def list_notes():
    with connect() as c, c.cursor() as cur:
        cur.execute("SELECT id, body FROM notes ORDER BY id")
        return jsonify([{"id": i, "body": b} for i, b in cur.fetchall()])


@app.post("/notes")
def add_note():
    body = request.json.get("body", "")

    with connect() as c, c.cursor() as cur:
        cur.execute("INSERT INTO notes (body) VALUES (%s) RETURNING id", (body,))
        new_id = cur.fetchone()[0]
        c.commit()

    return jsonify({"id": new_id, "body": body}), 201


@app.get("/healthz")
def healthz():
    return "ok", 200
```

---

## `compose.yml`

```yaml
services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: cohort
      POSTGRES_PASSWORD: cohort
      POSTGRES_DB: cohort
    volumes:
      - cohort-db-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U cohort"]
      interval: 5s
      retries: 5
    networks:
      - cohort-net

  api:
    image: cohort-api:0.1.0
    environment:
      DB_HOST: db
    ports:
      - "18080:8080"
    depends_on:
      db:
        condition: service_healthy
    networks:
      - cohort-net

networks:
  cohort-net:

volumes:
  cohort-db-data:
    external: true
```

---

# Part 4 — Evidence

## Part 1.2 — Default bridge DNS probe

### `dig db`

```text
not found
```

---

## Part 2.3 — User-defined bridge DNS probe

### `dig db`

```text
172.22.0.2
```

---

## Part 2.5 — Stranger container probe on `cohort-other`

```text
ping: db: Name does not resolve
```

### `dig db`

```text
not found
```

---

## Part 3.1 — Three curl tests

```text
ok (host -> 18080 OK)
ok (container -> 8080 OK)
port 18080 from container failed — as expected
```

---

## Part 4.3 — Volume still present after `docker rm -fv`

Command:

```bash
docker volume ls --filter name=cohort-db-data
```

Output:

```text
DRIVER    VOLUME NAME
local     cohort-db-data
```

---

## Part 5.1 — Backup file exists

Command:

```bash
ls -lh cohort-db-data-*.tar.gz
```

Output:

```text
-rw-r--r--  1 shukuratolaitan-animasaun  staff   6.4M Jun 10 13:46 cohort-db-data-20260610.tar.gz
```

---

## Part 5.2 — Restored data verification

Command:

```bash
docker container exec db-verify \
  psql -U cohort -d cohort -c 'SELECT id, body FROM notes;'
```

Output:

```text
 id |      body
----+----------------
  1 | persistent note
(1 row)
```

---

## Part 6 — Compose stack works

Command:

```bash
docker compose ps
```

Output:

```text
NAME                  IMAGE                COMMAND                  SERVICE   CREATED          STATUS                    PORTS
assignment-04-api-1   cohort-api:0.1.0     "gunicorn -b 0.0.0.0…"   api       15 seconds ago   Up 9 seconds              0.0.0.0:18080->8080/tcp, [::]:18080->8080/tcp
assignment-04-db-1    postgres:16-alpine   "docker-entrypoint.s…"   db        15 seconds ago   Up 15 seconds (healthy)   5432/tcp
```

Command:

```bash
curl -s http://localhost:18080/notes
```

Output:

```json
[
  {
    "body": "persistent note",
    "id": 1
  }
]
```

---

# Part 5 — One Trade-Off I Had to Make

One trade-off I had to make was choosing between raw Docker commands and Docker Compose.

Raw Docker commands helped me understand the lower-level primitives: networks, volumes, port publishing, and container lifecycle. However, managing several containers this way becomes repetitive and error-prone.

I chose Docker Compose for the final stack because it provides a reproducible, declarative configuration. The trade-off is that Compose hides some of the lower-level details, but it is much better for running multi-container applications consistently.

---

# Key Takeaways

* The default bridge network does not provide automatic container-name DNS.
* User-defined bridge networks provide service discovery through Docker DNS.
* Port publishing maps host ports to container ports but does not change the internal container port.
* Named volumes persist after containers are removed.
* Bind mounts are useful for development, but named volumes are better for production data.
* `tmpfs` is useful for temporary data that should never persist to disk.
* Compose makes multi-container applications easier to reproduce and manage.

---

## Assignment Complete ✅
