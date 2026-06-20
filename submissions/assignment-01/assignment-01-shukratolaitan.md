# Assignment 01 — <Shukurat Olaitan>

**GitHub username:** <shukratolaitan>
**Date completed:** 2026-04-25

**Question 1: What is the difference between rm file.txt and rm -rf directory/? Why is the second form considered dangerous?**

rm file.txt this command deletes the specific file. file.txt

rm -rf directory/  deletes everything in the directory recursively. it is considered dangerous as it can delete necessary files.

**Question 2: After running the four commands above, how many images do you have? How many containers? Why?**

I previously had 18 images , I now have 8 images and 0 containers from running previous commands.

**Question 3: What's the difference between docker run -it alpine sh and docker exec -it sh? When would you use each?**

**docker exec -it web sh** Is used when you want to exec into a container that’s already running, which then opens a shell. 
**docker run -it alpine sh** is used when you the container isn’t running yet and want to start a new container from the alpine image and opens a shell inside it.


**Part 1 reflection (3–5 sentences): which CLI command was new to you, and what did you use it for?**
The printf and new line command were new to me.
```printf "image\ncontainer\nvolume\nnetwork\nsystem\n" > commands.txt


**Part 2 answers: the three numbered "Question" prompts in Part 2 (images vs containers, run vs exec, the read-only mount flag)**

**image vs containers**
image are immutable layers that consist of files + metadata which inludes ENV, ARGS, CMD, ENTRYPOINT.

containers is a running environment of an image.

**run vs exec**
run creates and starts a container from an image.
exec means to execute a commmand into a container thats already running. 

**read-only mount flag **
means processes in the container cant modify the files.

**
Part 3 evidence: a screenshot (or copy-pasted terminal output) showing: docker container ls after step 3**

```bash docker container ls
CONTAINER ID   IMAGE        COMMAND                  CREATED             STATUS             PORTS                                     NAMES
38d2a88014d7   nginx:1.25   "/docker-entrypoint.…"   About an hour ago   Up About an hour   0.0.0.0:8081->80/tcp, [::]:8081->80/tcp   practice-web

<img width="1557" height="505" alt="Screenshot 2026-06-11 at 14 48 06" src="https://github.com/user-attachments/assets/ea3f7fed-5e06-47fc-a3a2-f5dc0b3d6d6b" />

The browser page after step 8 showing your custom message
Hello from Shukurat

**The output of docker container inspect -f '{{.NetworkSettings.IPAddress}}' practice-web from step 9**

docker container inspect practice-web -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
172.17.0.2
**
One thing that surprised you about how Docker behaves.**
When I ran docker container inspect -f '{{.NetworkSettings.IPAddress}}' web I got the error message template parsing error: template: :1:18: executing "" at <.NetworkSettings.IPAddress>: map has no entry for key "IPAddress" realized it doesn’t work in new docker setups as docker mpoved to a multi network model which allows containers to be attached to bridge, custom networks & multiple networks at once So a single .IPAddress no longer makes sense.
*New command*
```docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' web


# Assignment 01 — CLI Essentials & Docker Commands

> **Student:** Shukurat Olaitan
> **GitHub Username:** `shukratolaitan`
> **Date Completed:** 2026-04-25

---

## Part 1 — Reflection

One CLI command that was completely new to me was `printf`. Before this assignment, I mostly used `echo` for displaying text, but I learned that `printf` gives more control over formatting, especially when creating structured output with new lines.

I used it to create a text file containing a list of Docker command categories:

```bash
printf "image\ncontainer\nvolume\nnetwork\nsystem\n" > commands.txt
```

I also learned how useful output redirection (`>`) can be for sending command output directly into a file rather than displaying it in the terminal. This assignment helped me better understand how shell commands can be combined to automate simple tasks.

---

# Part 2 — Questions

## Question 1

### What is the difference between `rm file.txt` and `rm -rf directory/`? Why is the second form considered dangerous?

#### Answer

`rm file.txt` removes a single file.

```bash
rm file.txt
```

`rm -rf directory/` removes an entire directory and everything inside it recursively.

```bash
rm -rf directory/
```

### Why is `rm -rf` dangerous?

* `-r` = recursive deletion
* `-f` = force deletion without confirmation

Because it deletes files and folders without asking for confirmation, a mistake in the path can permanently remove important files or directories.

For example:

```bash
rm -rf project-folder/
```

will delete the entire folder and all of its contents.

> ⚠️ Be careful when using `rm -rf`, especially when running commands as an administrator.

---

## Question 2

### After running the Docker commands, how many images and containers do you have? Why?

#### Answer

At the time I completed the exercise, I had:

| Resource   | Count |
| ---------- | ----- |
| Images     | 8     |
| Containers | 0     |

I originally had 18 images on my machine, but after cleaning up unused resources, only 8 remained.

### Images vs Containers

#### Docker Images

Images are immutable templates that contain:

* Filesystem layers
* Application code
* Environment variables (`ENV`)
* Build arguments (`ARG`)
* Startup commands (`CMD`)
* Entry points (`ENTRYPOINT`)

Images act as blueprints for containers.

#### Docker Containers

Containers are running instances created from images.

Containers:

* Run processes
* Have their own writable layer
* Can be started and stopped
* Can be removed without deleting the original image

Because I removed the containers used during the assignment, I had **0 containers** while still retaining **8 images**.

---

## Question 3

### What is the difference between `docker run -it alpine sh` and `docker exec -it <container> sh`? When would you use each?

#### `docker run -it alpine sh`

```bash
docker run -it alpine sh
```

This command:

* Creates a brand-new container
* Starts the container
* Opens an interactive shell

Use it when you want a temporary environment for testing or learning.

---

#### `docker exec -it web sh`

```bash
docker exec -it web sh
```

This command:

* Connects to an already-running container
* Opens an additional shell session inside it

Use it when:

* Troubleshooting a running application
* Viewing logs or files
* Checking environment variables
* Performing maintenance

### Summary

| Command       | Purpose                                   |
| ------------- | ----------------------------------------- |
| `docker run`  | Create and start a new container          |
| `docker exec` | Run commands inside an existing container |

---

## Read-Only Mount Flag

A read-only mount allows a container to read files from the host machine but prevents it from modifying them.

### Example using `-v`

```bash
docker run --rm \
-v "$(pwd)/config.yml:/app/config.yml:ro" \
myapp
```

The `:ro` option means:

```text
ro = read-only
```

### Example using `--mount`

```bash
docker run --rm \
--mount type=bind,source="$(pwd)/config.yml",target=/app/config.yml,readonly \
myapp
```

This is useful for configuration files that should not be modified by the container.

---

# Part 3 — Evidence

## Step 3 — Running Container

### Output of `docker container ls`

```bash
$ docker container ls

CONTAINER ID   IMAGE        COMMAND                  CREATED             STATUS             PORTS                                     NAMES
38d2a88014d7   nginx:1.25   "/docker-entrypoint.…"   About an hour ago   Up About an hour   0.0.0.0:8081->80/tcp, [::]:8081->80/tcp   practice-web
```

✅ The container is running successfully.

✅ Host port `8081` is mapped to container port `80`.

---

## Screenshot Evidence

### Running Container

[Running Container](https://github.com/user-attachments/assets/ea3f7fed-5e06-47fc-a3a2-f5dc0b3d6d6b)

---

## Step 8 — Custom Web Page

After modifying the nginx homepage:

```bash
echo "Hello from Shukurat" > /usr/share/nginx/html/index.html
```

The browser displayed:

```text
Hello from Shukurat
```

✅ nginx immediately served the updated page.

---

## Step 9 — Container IP Address

### Command

```bash
docker inspect practice-web \
-f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
```

### Output

```bash
172.17.0.2
```

The container received its own IP address on Docker's bridge network.

Port mapping:

```bash
-p 8081:80
```

allows traffic sent to:

```text
localhost:8081
```

to reach:

```text
172.17.0.2:80
```

inside the container.

---

# One Thing That Surprised Me

One thing that surprised me was how Docker networking behaves in newer Docker versions.

I initially tried:

```bash
docker container inspect -f '{{.NetworkSettings.IPAddress}}' web
```

but received:

```bash
template parsing error:
template: :1:18:
executing "" at <.NetworkSettings.IPAddress>:
map has no entry for key "IPAddress"
```

After investigating, I learned that modern Docker supports multiple networks per container. Because a container can belong to several networks at once, Docker no longer exposes a single `.IPAddress` value in many situations.

The updated command is:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' web
```

This loops through all attached networks and displays their IP addresses.

> 💡 This was a useful lesson because it showed me how Docker networking has evolved and why older tutorials sometimes use commands that no longer work exactly the same way.

---

# Key Takeaways

* Learned how `printf` differs from `echo`
* Practiced output redirection using `>`
* Understood the difference between Docker images and containers
* Learned when to use `docker run` versus `docker exec`
* Used read-only mounts with `:ro`
* Inspected Docker networking and container IP addresses
* Gained more confidence working from the command line

---

## Assignment Complete ✅
