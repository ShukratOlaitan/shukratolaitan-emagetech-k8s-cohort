# Assignment 01 — <Shukurat Olaitan>

**GitHub username:** <shukratolaitan>
**Date completed:** 2026-04-25

**Question 1: What is the difference between rm file.txt and rm -rf directory/? Why is the second form considered dangerous?**
Answer

rm file.txt removes a single file.

rm -rf directory/ removes an entire directory and everything inside it recursively.
Why is rm -rf dangerous?
-r = recursive deletion
-f = force deletion without confirmation

Because it deletes files and folders without asking for confirmation, a mistake in the path can permanently remove important files or directories.

e.g. rm -rf project-folder/  will delete the entire folder and all of its contents.

**Question 2: After running the four commands above, how many images do you have? How many containers? Why?**

Answer

At the time I completed the exercise, I had:

Resource	Count
Images	      8
Containers	  0

I originally had 18 images on my machine, but after cleaning up unused resources, only 8 remained.

**Question 3: What's the difference between docker run -it alpine sh and docker exec -it sh? When would you use each?**

docker run -it alpine sh

Is used when you want a temporary environment for testing or learning.

Create a brand-new container
Starts the container
Opens an interactive shell

docker exec -it web sh

This command connects to an already-running container then opens an additional shell session inside it

Use it when:

Troubleshooting a running application
Viewing logs or files
Checking environment variables
Performing maintenance

**Part 1 reflection (3–5 sentences): which CLI command was new to you, and what did you use it for?**
The printf and new line command were new to me.
```printf "image\ncontainer\nvolume\nnetwork\nsystem\n" > commands.txt


**Part 2 answers: the three numbered "Question" prompts in Part 2 (images vs containers, run vs exec, the read-only mount flag)**

**image vs containers**
Docker Images 

Images are blueprints used to create containers. they are immutable templates that contain:

Filesystem layers
Application code
Environment variables (ENV)
Build arguments (ARG)
Startup commands (CMD)
Entry points (ENTRYPOINT)

Docker Containers

Containers are running environments created from images.

A container:

Has its own filesystem layer
Can run processes
Can be started, stopped, and removed
Is isolated from the host system

**run vs exec**
docker run -it alpine sh

This command creates a new container from the Alpine image and immediately opens an interactive shell inside it.

docker run is 

You want a temporary Linux environment.
You need to test commands quickly.
No container is currently running.

docker exec -it <container> sh
docker exec -it web sh

This command opens a shell inside an already running container.

its used to inspect or troubleshoot a running application.
To view logs, files, or environment variables inside an existing container.
When you do not want to create a new container.


**read-only mount flag **
A read-only mount prevents processes inside the container from modifying files on the host.

Example:
docker run --rm \
  -v "$(pwd)/config.yml:/app/config.yml:ro" \
  myapp

The :ro option means read-only

This allows the container to read the file but not change it.

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

One thing that surprised me was how Docker networking has changed in newer versions.

Initially, I tried to run: docker container inspect -f '{{.NetworkSettings.IPAddress}}' web

but received the error:

template parsing error:
template: :1:18:
executing "" at <.NetworkSettings.IPAddress>:
map has no entry for key "IPAddress"

After researching the issue, I learned that modern Docker uses a more flexible multi-network model. Containers can now be connected to multiple networks simultaneously, so a single IPAddress field is no longer always available.

The updated command is:

docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' web

This iterates through all networks attached to the container and returns the IP address for each one. Understanding this helped me better appreciate how Docker networking works and why newer versions require a different approach when inspecting container IP addresses.


