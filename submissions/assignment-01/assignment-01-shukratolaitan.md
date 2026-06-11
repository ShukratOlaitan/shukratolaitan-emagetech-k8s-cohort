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


**Part 1 reflection (3–5 sentences): which CLI command was new to you, and what did you use it for?
**
printf "image\ncontainer\nvolume\nnetwork\nsystem\n" > commands.txt
printf and new line. 
**
Part 2 answers: the three numbered "Question" prompts in Part 2 (images vs containers, run vs exec, the read-only mount flag).**

**image vs containers **
image are immutable layers that consist of files + metadata which inludes ENV, ARGS, CMD, ENTRYPOINT.

containers is a running environment of an image.

**run vs exec**
run creates and starts a container from an image.
exec means to execute a commmand into a container thats already running. 

**read-only mount flag **
means processes in the container cant modify the files.

**
Part 3 evidence: a screenshot (or copy-pasted terminal output) showing: docker container ls after step 3**

```docker container ls
CONTAINER ID   IMAGE        COMMAND                  CREATED             STATUS             PORTS                                     NAMES
38d2a88014d7   nginx:1.25   "/docker-entrypoint.…"   About an hour ago   Up About an hour   0.0.0.0:8081->80/tcp, [::]:8081->80/tcp   practice-web


<img width="1557" height="505" alt="Screenshot 2026-06-11 at 14 48 06" src="https://github.com/user-attachments/assets/ea3f7fed-5e06-47fc-a3a2-f5dc0b3d6d6b" />

The browser page after step 8 showing your custom message
Hello from Shukurat
**
The output of docker container inspect -f '{{.NetworkSettings.IPAddress}}' practice-web from step 9**

docker container inspect practice-web -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
172.17.0.2
**
One thing that surprised you about how Docker behaves.**
When I ran docker container inspect -f '{{.NetworkSettings.IPAddress}}' web I got the error message template parsing error: template: :1:18: executing "" at <.NetworkSettings.IPAddress>: map has no entry for key "IPAddress" realized it doesn’t work in new docker setups as docker mpoved to a multi network model which allows containers to be attached to bridge, custom networks & multiple networks at once So a single .IPAddress no longer makes sense.
*New command*
```docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' web
