### 002.The Concept of Linux Containers ###
A container is a standard unit of software that packages up code and all its dependencies so the application runs quickly and reliably from one computing to another independently. it provides a standrard way to package your application with configuration into a single object

containerization allows development to move fast, deploy sotware efficiently and operate at an unprecedented scale.

the first concept of container was in UNIX version 7 introduces as CHROOT (Change Root) or Jails

#### Container Image:
a self-sufficient software Distribution Unit that contains: code, libraries and modules, dependencies and operating system utilities. and it depends on Processor and system architecture of OS Kernel.

#### Container as Runtime Unit
- Isolated from other containers on Operating system level.
- Dedicated and isolated from network stack, process Namespace, Inter Process Communication (IPC) Namespace.
- Unique IP address for each container.

#### Containers
- Frequently Updated
- Short lived at runtime
- Small and quick to start
- Easily communicate with others
- Foundation of Micro Service Architecture (MSA)
 

### 003.Containers Explained ###
Container is consist of two aspects:
1. Software packages
2. Runtime Unit:

#### software packages
the sotware pacakges aspect of it is also referred to as container image which consist of application source code, libraries and module, script interpreter and operating system utilities

#### Runtime Unit
when a container start on the Operating system it has its own process unit, own network stuck and own file system on shared os kernel. the Container is Isolated in runtime from the host system. if the container is explicitly shared, then its a way that container can affect the host OS directly.

Container Consist of Metadata and Filesystem:
- Metadata: consist of enough data for the container to launch it
- Filesystem layer: container runtime uses "union filesystem" to implement filesystem layer.

the read-only part of the image only can be share and saved when the life cycle of the container ends.



### 004.Build, Ship, Run ###
#### Build
when the application is ready and is packaged into a container image to be shipped.
there are ways to build an image: 
1. Manual Build: 
    - 1. Running the Linux Base Image 
    - 2. then installing the code libraries and etc 
    - 3. copy application source code to a container
    - 4. test 
    - 5. freez the container to create a new image
    - 6. tag the image
2. Automated build
    1. Dockerfile: a script with instruction of how to buid image
    2. docker build command: New image saved to docker Engine local iamge cache

#### Ship the Image
to copy new Image from local Image cache to Image Registy
- • Image Registry: it is a network storage server for container Images
    - there are Cloud Registry or Local
    - Public Registry or Private
- there are Industry Standards format for container Images

#### Run Image in Container
- Container runtimes like Docker Engine, CRI-O, Containerd, rkt, etc
- Build once run everywhere on hosts, server, cloud virtual server, or on Bare metal.



### 005.Introduction to Docker ###
Docker is chosen for containerization due to its simplicity and intuition. and also many platforms supports it. the docker emerged from the dotcloud company. <br>
it is open source and has comprehensive tools:

• Docker tools are:
- Engine: Runtime for linux and windows server
- Desktop
- Machine
- Compose
- Swarm
- Hub
- Registry
- Kitematic (GUI Utility)



### 006.Ecosystem of Container Technologies
#### The container toolset
- Developer Tools - Create and Distribute Container Images
- Deployment Tools - Run and Manage Containerized Application at scale

#### Ecosystem of Technology
- Runtimes - Docker Engine, Containerd, rkt, CRI-O
- Management - Docker, Rancher, Amazon, Elastic Container Service
- Registries - Docker Hub & Registry, Gtlab, Amazon elastic, Trusted Registries
- Orchestration - Kubernetes, Swarm, Mesos, DC/OS, Google Kubernetes Engine (GKE)
- Monitoring, Prometheus, Elastic, Datadog, cAdvisor

#### Container Standards
Open Container Initiative (OCI) <br>
Image Specification (Image-spec) <br>
Runtime Specification (runtime-spec) <br>



### 007.Introduction to Container Orchestration
Container Orhcestration:
- Provisioning, Scheduling and placement of Container
- Provisioning and Management of other Virtual Resources
- Expose Service
- Ingress Traffic Management
- Health Monitoring, Redundancy and Restarting
- Horizontal Scaling of resources
- Upgrades and Updates

Kubernetes is the most famous and the choice of Orchestration.



### 009.Shipping the Image to Docker Hub
one of the public registries is docker.hub and we can push our Image Container to them. <br>
after pushing the image we can use the image on any supporting container platform



### Docker Installation and first use

to install docker we first need to install curl and ca-certificates, the `curl` is used to download the packages from docker repository and `ca-certificates` is used to create ceritifcation key for secure GPG tranfering key.

```shell 
sudo apt-get update #update packages
sudo apt-get install ca-certificates curl #download and install curl and ca-certificates if is not installed

sudo install -m 0755 -d /etc/apt/keyrings # create the keyrings directory as a 755 permission
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc ##downloads the gpg key to the ketrings directory -f is for fail-silence (to not write html file on docker.asc file) -s is for silence -S is for printing error on terminal -L is for location (for 301 or redirections)
sudo chmod a+r /etc/apt/keyrings/docker.asc #add read-only to docker.asc

# write our OS data on the docker.ls and signs it via docker.asc file
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```


now that the docker is downloaded lets start our first docker container: <br>
run `docker container run hello-world:latest`. it has shorten form which is `docker run` and `:latest` is used to download the latest version of our simple hello-world container. <br>
if the hello-world is not find in local repository, then it will be downloaded from public regitry.

#### Image and Containers
Think of a container as a ready-to-eat meal that you can simply heat up and consume. An image, on the other hand, is the recipe and the ingredients for that meal. <br>
In short, an image is like a blueprint or template and the building material, while a container is an instance of that blueprint or template. <br>

note:
> A Docker image is a file. An image never changes; you can not edit an existing file. Creating a new image happens by starting from a base image and adding new layers to it.

you can list all images on local with: <br>
`docker image ls `

to list all containers: <br>
`docker container ls -a ` without `-a` we will only print running containers<br>
it is shorten form of `docker ps`


#### where does Images come from?
Image file is built from an instructional file named `Dockerfile` that is parsed when we run `docker image build`.

If we go back to the cooking metaphor, as Dockerfile provides the instructions needed to build an image you can think of that as the recipe for images. We're now 2 recipes deep, as Dockerfile is the recipe for an image and an image is the recipe for a container. The only difference is that Dockerfile is written by us, whereas image is written by our machine based on the Dockerfile!


#### Docker Engine
Docker Engine" that is made up of 3 parts:<br>
- command line interface (CLI) client
- a REST API
- Docker daemon <br>
behind the scenes the CLI client sends a request through the REST API to the Docker daemon which takes care of images, containers and other resources.


#### Removing a Container
we can use `docker image rm (image name)` to remove an image but remember that the container related to the image should not be running.
for instance we can use:<br>
`docker ps | grep "container name"` to find the container name and its ID or name then we can <br>
then we can use `docker container rm (ID/Name)` (you can use first ID characters if there are few container) to remove the container.<br>
to remove multiple container we can use:<br>
` docker container rm id1 id2 id3 `<br>
`--force` can be used to force a container to stop <br>

if you have so many stopped container you can do:<br>
`docker container prune`<br>
note:
> Prune can also be used to remove "dangling" images with docker image prune. Dangling images are images that do not have a name and are not used.
` docker system prune`: to clear almost everything

if container is running it should be stopped.<br>
to stop it we use `docker stop (ID/Name)`

we can pull an image without running it with:<br>
`docker image pull (image-name)`

we can run a container in the background by using `-d`command:<br>
` docker run -d nginx `: it will run it in background with "detached" flag 



#### Interaction with container
for instance we can intract inside the a container (in this case an ubuntu container) with this command:<br>
`docker run -it ubuntu` : the `-t` (tty) allow will only send the data and won't receive it back, the `-i` is for interactivity.

we can use combination of flags to for instance run a container in background for a loop.<br>
`docker run -d -it --name looper ubuntu sh -c 'while true; do date; sleep 1; done` => it will run a loop script inside the ubuntu container and tag a name to it as "looper" tjen it will be run in detached mode and with interactive tty shape.<br>
note:
> in windows command prompt you should set the command in (") double-quote.

to see the logs that the "looper" is creating we can use `docker logs` with the flag `-f` because we have run it in background:<br>
`docker logs -f (name of container)` : it will follow the logs that are being created with that container.


#### pausing a container without stopping or exiting it.
we can use `pause/unpause` to stop a container and put in suspend mode.<br>
for example:<br>
`docker pause (container name)` it will pause the container.<br>
you can check the status of the container by `docker ps -a | grep "container info"`

we also can attach to a container with `attach` command, it is the opposite of detach command:<br>
` docker attach (container name)`

we also can just attach the container to terminal without involving any input with `--no-stdin` option:<br>
`docker attach --no-stdin looper` : it will attach to the container but ctrl+c won't affect and stop the container.


#### difference of `docker run` and `docker start`:
• `docker run`: It pulls the specified image if it's not available locally. Creates a new container based on that image. Starts the container with the specified configuration. we also can use broad options and flags with it <br>
• `docker start`: This command only works on containers that already exist but are currently stopped. It restarts them with their previous configuration intact.


#### using `docker exec` in container 
the `docker exe` command runs a new command in a running container. it only runs while the container's primary process is running.<br>
note:
> the command `docker debug` is replaced for `docker exec` and can do the similar functionality.

also note that the chained or quoted command doesn't work.<br>
for instance:<br>
`docker exec -it (container name) sh -c "echo a && echo b"`

for instance lets list all directories inside an ubuntu container with:<br>
`docker exec (name of container) ls -la`: the exec will run the `ls -la` in the name container.

we can also run a bash shell inside the container by exec and make it interactive:<br>
`docker exec -it (container name) bash`: it will run bash in interactive shell. (in this case if you exit the shell it won't stop the container)

if a container is in a loop or stuck in a process it won't stop by SIGTERM signal and should be kill or removed ungracefully<br>
`docker kill (container name (stucked))`: it will kill the machine and is equal to force<br>
`docker rm --force (container name)`


#### --rm option
we can use --rm option to ensure that ther are no garbase containers left behind. it also means that docekr start wcan not be usd to start the container after it has exited.<br>
` docker run -d --rm -it --name looper-it ubuntu sh -c 'while true; do date; sleep 1; done' `

now we can attach to the container and then use `ctrl+p`, `ctrl+q` to detach us from the STDOUT <br>
the ctrl+p, ctrl+q are used instead of `ctrl+c` that sends kill signal.

#### not permanent by default
when we run an ubuntu container we can interact with it similar to a ubuntu OS but the key difference is that for instance, installation of Nano is not permanent, that is, if we remove our container, all is gone. 

side note:
> Quite a few popular images are so-called multi platform images(opens in a new tab), which means that one image contains variations for different architectures. When you are about to pull or run such an image, Docker will detect the host architecture and give you the correct type of image.



### Images 
an image name may consist of 3 parts plus a tag. Usually like the following: registry/organisation/image:tag <br>
But may be as short as ubuntu if the image is created by docker itself.

we can search for docker images via `search` command:<br>
` docker search (image-name)` => it will list all Images that have that image name in it with description and starts.

by default `docker search` will only search from Docker Hub, but to search a different registry, you can add the registry address before the search term, for example, `docker search quay.io/hello`

#### tagging locally:
we can tag the images on our local for convenience for example: <br>
` docker tag ubuntu:25.04 ubuntu:noble_numbat `: creates the tag ubuntu:noble_numbat which refers to ubuntu:25.04

Tagging is also a way to "rename" images. Run `docker tag ubuntu:25.04 fav_distro:noble_numbat` and check `docker image ls` to see that the image name is also changed.



### Building Images
to create an Image we are going to walk through a process of create just a shell file and convert it into Image:<br>
so firt we create a `./hello.sh` file that return hello:<br>
```shell
#!/bin/sh
echo "returning of hello, container"
```

now we add a file with name "Dockerfile" and put the commands below in it:<br>
./Dockerfile :
```shell
# Start from alpine Image (small but don't have lots of tools)
FROM alpine:3.21

# the following instruction will be executed in this location
WORKDIR /usr/src/app

# copy the created hello.sh to /usr/src/app 
COPY hello.sh .

# we also can define the execution permission here too
# RUN chmod +x hello.sh

# when running "docker run" the command will be hello.sh
CMD ./hello.sh

```

by default `docker build` will look for a file named Dockerfile. so we can run `docker build` with instruction wihere to build and give it a name with `-t (name)`

`docker build . -t hello-ducker` : it will look for Dockerfile in the current directory and based on that prepare wizard

we can verify the existance of newly created image by:<br>
`docker image ls`

then execute it with:<br>
`docker run (image-name)`

#### Layer
During the build we see from the output that there are three steps: [1/3], [2/3] and [3/3]. The steps here represent layers(opens in a new tab) of the image so that each step is a new layer on top of the base image (alpine:3.21 in our case).<br>
Layers have multiple functions. We often try to limit the number of layers to save on storage space but layers can work as a cache during build time. If we just edit the last lines of Dockerfile the build command can start from the previous layer and skip straight to the section that has changed. COPY automatically detects changes in the files, so if we change the hello.sh it'll run from step 3/3, skipping 1 and 2.


#### adding layer manually
It is also possible to manually create new layers on top of a image<br>
to do that lets add new file and copy it inside a container with name "additional.txt"

lets run the command:<br>
`docker run -it hello-ducker sh`: we go inside the container which in our case is `/usr/src/app` and we replaced the CMD we defined earlier with `sh` and used `-it` to start the container so that we can interact with it.

on another terminal lets copy and send the additional.txt file to the container:<br>
`docker cp ./additional.txt (name-container):/usr/src/app`

verify it with in the first terminal with `ls` in the container bash.

#### docker diff
we can see changes on the container by `docker diff`:<br>
` docker diff (container-name)` => it will print list of all changes that has happened to file which with type indicated behind each line:<br>
- A = Added
- C = Changed
- D = deleted
- .ash_history = if any new command is send inside the container this file is created then.

#### docker commit (not sustainable)
we can save the changes as a new image with the command `docker commit`<br>
By default, the container being committed and its processes will be paused while the image is committed. This reduces the likelihood of encountering data corruption during the process of creating the commit. If this behavior is undesired, set the `--pause` option to false.<br>
Technically the command `docker commit` adds a new layer on top of the image. and thus image name will be changed.<br>

` docker commit (container-name) (new-container-name)` => it will save the layer changes and new it with give name.

note:
> the changes are mostly done on dockerfile itself and with Dockerfile it can be versioned controlled.

we can create a file with version 2 (v2) tag and include the additional.txt file to it.<br>
Dockerfile:
```shell
# Start from alpine Image (small but don't have lots of tools)
FROM alpine:3.21

# the following instruction will be executed in this location
WORKDIR /usr/src/app

# copy the created hello.sh to /usr/src/app 
COPY hello.sh .

# execute a command with ` /bin/sh -c ` prefix
RUN echo important data > additional.txt

# we also can define the execution permission here too
# RUN chmod +x hello.sh

# when running "docker run" the command will be hello.sh
CMD ./hello.sh
```

we can build the docker with new version tag:<br>
`docker build . -t hello-docker:v2` <br>
after executation you might see " => [4/4] RUN echo important data > additional.txt " which indicate that new layer is added to container image.
<br>
all instructions in Dockerfile except CMD and some others are executed in build time. CMD is executed when we call docker run, unless we overwrite it



### CMD Explanation
The `CMD` instruction sets the command to be executed when running a container from an image. <br>
There can only be one `CMD` instruction in a Dockerfile. If you list more than one CMD, only the last one takes effect. <br>
The purpose of a `CMD` is to provide defaults for an executing container. These defaults can include an executable, or they can omit the executable

Note:
> Don't confuse `RUN` with `CMD`. `RUN` actually runs a command and commits the result; `CMD` doesn't execute anything at build time, but specifies the intended command for the image.

### there are two forms of the CMD instruction in Dockerfiles:
#### Exec Form (Preferred):
`CMD ["executable", "param1", "param2"]` This is the preferred form. The command and its arguments are specified as a JSON array. Docker executes the command directly without invoking a shell. This form is more predictable and avoids shell-related issues.


#### Shell Form:
`CMD command param1 param2`: This form executes the command using /bin/sh -c. It's similar to typing the command directly into a shell. This form can lead to unexpected behavior if you're not careful about shell quoting and escaping. <br>
Use the shell form when you need shell features like variable expansion or command piping.
    it's useful when you need to evaluate environment variables in the command like `$MYSQL_PASSWORD` or similar.
example:

| Dockerfile                                       | Result In Container                               |
| ----------------------------------------         | ------------------                                |
| `ENTRYPOINT /bin/ping -c 3 CMD localhost `       | `/bin/sh -c '/bin/ping -c 3' /bin/sh -c localhost`| 
| `ENTRYPOINT ["/bin/ping","-c","3"] CMD localhost`| `/bin/ping -c 3 /bin/sh -c localhost`             | 
| `ENTRYPOINT /bin/ping -c 3 CMD ["localhost"] `   | `/bin/sh -c '/bin/ping -c 3' localhost`           | 
| `ENTRYPOINT ["/bin/ping","-c","3"] CMD ["localhost"] `   | `/bin/ping -c 3 localhost`                | 


#### FROM in Dockerfile
the `FROM` command in docker file specifiies that your new image is based on the existing of another image.essentially, it tells docker to Start with this existing image, and then apply the following instructions to create a new image for example: <br>
`FROM alpine:3.21`: it means that the new Dockerfile is a layer on top of the alpine:3.21 


#### Docker History
To see the Docker Image file Layers we can use `docker image history (name of image file)` <br>
`image history` outputs a table with information about each layer of the image.


#### ENTRYPOINT
the ENTRYPOINT instruction defines the executable that will always run when the container starts. <br>
the difference between `CMD` is that, CMD provides default argument to the ENTRYPOINT or if no entrypoint is define runs as the main command. <br>
    • `ENTRYPOINT` defines the main executable, and `CMD` provides arguments to it.

the container that has entrypoint can accept argument when it is being started: <br>
`docker run <image> <argument>`. the argument will be appended to entrypoint.

if a `CMD` is defined and a `ENTRYPOINT` is also defined, the arguments for that `CMD` are appended to the `ENTRYPOINT`

**Most of the time** we can ignore ENTRYPOINT when building our images and only use CMD. For example, Ubuntu image defaults the ENTRYPOINT to bash so we do not have to worry about it. And it gives us the convenience of allowing us to overwrite the CMD easily, for example, with bash to go inside the container.

for instance we have a Docker file which uses [yt-dlp](https://github.com/yt-dlp/yt-dlp). and is running on top of ubuntu:24.04 as below: <br>
Inside the Dockerfile:
```shell

FROM ubuntu:24.04

ARG TZ=Etc/UTC

RUN apt-get update && apt-get install curl -y tzdata locales
RUN ls -fs /usr/share/zoneinfo/$TZ /etc/localtime
RUN dpkg-reconfigure --frontend noninteractive tzdata

RUN apt-get install -y python3
RUN curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o ./usr/bin/yt-dlp
RUN chmod a+rx ./usr/bin/yt-dlp

ENTRYPOINT ["./usr/bin/yt-dlp"] #instead of CMD ["./usr/bin/yt-dlp"]

# optional
CMD ['https://www.youtube.com/watch?v=2KCN_W9G6XQ'] #the default URL if no argument is passed to the container 

```

now to build and run the docker image we do: <br>
1. `docker build <Dockerfile> -t <tag-name-image>` : first we create the docker image from the Dockerfile
2. `docker run <image> <link-address(argument)>` : it will run the docker image and pass the youtube link to download.

### Docker cp
we can copy a file or downloaded vide olink from the run container by using `docker cp <container_name:/direcotry>`<br>
for example after running the `yt-dlp` container we can use `docker diff <container_name/id>` to see the changes inside the docker.<br>
then by locating the file we can use cp to copy it to our own machine:<br>
`docker cp "stoic_merkle:/Everything You Need to Know to Start with Proxmox VE [5j0Zb6x_hOk].mp4" . `


### Adding ENTRYPOINT CMD to a container
we can define customized entrypoint to specific docker image for instance we can add new `ENTRYPOINT` and `CMD` to python docker image: <br>
first, it is recommended to pull python3.12 image: <br>
1. `docker pull pyhon3.12` <br>
2. the create new `Dockerfile`:
<pre>
FROM python3.12
ENTRYPOINT ["python3.12"]
CMD ["--version"]
</pre>
3. build and run the docker container
    `docker build <Dockerfile> -t customized-python`
    `docker run customized-python`



### Volumes
Volumes are persisten data stores for containers, created and managed by Docker. when you create volume, it is stored within a directory on the Docker host (host machine). when you mount the volume into a container, this diretory is what's munted into the container. this is similar to the way that bind mounts work, expect that volumes are managed by Docker and are isolated fomr the core functionality of the host machine.

for instance lets create a container image that fetch a video from a youtube url and then we want to save it on our host machine instead of local container directory:

the Docker file:
```shell
FROM ubuntu:24.04

ARG TZ=Etc/UTC

RUN apt-get update && apt-get install curl -y tzdata locales
RUN ls -fs /usr/share/zoneinfo/$TZ /etc/localtime
RUN dpkg-reconfigure --frontend noninteractive tzdata

WORKDIR /mydir

RUN apt-get install -y python3
RUN curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
RUN chmod a+x /usr/local/bin/yt-dlp

ENTRYPOINT ["/usr/local/bin/yt-dlp"]

```

build the image: <br>
`docker build . -t ytdownloader-v2`

then we use `-v` option run to define the directory we want to write the inside directory of container to our own host directory: <br>
`docker run -v "$(pwd):/mydir" ytdownloader-v2 (URL)` => $(pwd):/mydir Determines the current working directory on your host machine. and Mounts that directory into the Docker container at the path /mydir.

A Docker volume is essentially a shared directory or file between the host machine and the container. When a program running inside the container modifies a file within this volume, the changes are preserved even after the container is shut down, as the file resides on the host machine. This is the primary advantage of using volumes; without them, any files created or modified within the container would be lost upon restarting it. <br>
Additionally, volumes facilitate file sharing between containers, enabling programs to access and load updated files seamlessly. <br>

If we wish to create a volume with only a single file we could also do that by pointing to it. For example -v "$(pwd)/material.md:/mydir/material.md" this way we could edit the file material.md locally and have it change in the container (and vice versa). Note also that -v creates a directory if the file does not exist.



### Allowing External connections into container
the containers are following the similar rule for netwroking and Operating systems <br>
if you are on a container and send a message to localhost, the target is the same container. Similarly, if you are sending the request from outside of a container to localhost, the target is your machine. <br>
It is possible to map your host machine port to a container port. For example, if you map port 1000 on your host machine to port 2000 in the container, and then you send a message to http://localhost:1000 on your computer, the container will get that message if it's listening to its port 2000. <br>

Opening a Connection from the outside world toa Docker container happens in two steps:
1. Exposing port
2. Publishing port
- Exposing a container port means telling Docker that the container listens to a certain port. This doesn't do much, except it helps humans with the configuration.<br>
- Publishing a port means that Docker will map host ports to the container ports.

#### Expose
To expose a port, add the line `EXPOSE <port>` in your `Dockerfile` <br>
To publish a port, run the container with `-p <host-port>:<container-port>` <br>
note:
> If you leave out the host port and only specify the container port, Docker will automatically choose a free port as the host port
` $ docker run -p 4567 (app-in-port) `

#### Defining Certain Protocol
We can limit connections to a certain protocol only. for example UDP, by adding the protocol at the end: <br>
`EXPOSE <port>/udp` and `-p <host-port>:<container-port>/udp`

**Security reminder:** <br>
Since we are opening a port to the application, anyone from the internet could come in and access what you're running. An easy way to avoid this is by defining the host-side port like this -p 127.0.0.1:3456:3000. This will only allow requests from your computer through port 3456 to the application port 3000, with no outside access allowed.



## Utilizing tools from the Registry

### Containerizing an application
as Dev and Ops lets Containerize a Ruby web application Project [rails-example-project](https://github.com/docker-hy/material-applications/tree/main/rails-example-project):

first we need to clone the project (if we want to clone only the repository we can use [Directory.github](https://download-directory.github.io/))

lets add a `Dockerfile` inside the root of our rails project:
Dockerfile:
```shell
FROM ruby:3.1.0

EXPOSE 3000

WORKDIR /usr/src/app
# install the correct bundler version
RUN gem install bundler:2.3.3

# copy both Gemfile and Gemfile.lock for dependencies to be installed inside docker container directory
COPY Gem* ./

# install all dependencies
RUN bundle install

# copy all of the source code inside the workdir in container.
COPY . .

# run database migration with production environement variable
RUN rails db:migrate RAILS_ENV=production

# precompiles the assets.
RUN rake assets:precompile

# command to run the application
CMD ["rails", "s", "-e", "production"]

```
note:
> The COPY will copy both files Gemfile and Gemfile.lock to the current directory. This will help us by caching the dependency layers if we ever need to make changes to the source code. The same kind of caching trick works in many other languages or frameworks, such as Node.js.

the `Dockerfile` is following the README.md file inside the Project Directory

then we can build and run the dockerfile and expose the 3000 host machine for it.
`docker build . -t rails-project && docker run -p 3000:3000 rails-project` => it will build, run and expose the docker image on port 3000 which will be avialable on localhost:3000

**caution**: *building this image on MAC M1, M2 CPU architecture is a little bit different and may not work with current image.* 



### ENV 
The ENV instruction sets the environment variable `<key>` to the value `<value>`. This value will be in the environment for all subsequent instructions in the build stage and can be replaced [inline](https://docs.docker.com/reference/dockerfile/#environment-replacement) in many as well. <br>
example fo ENV: <br>
```shell
ENV MY_NAME="John Doe"
ENV MY_DOG=Rex\ The\ Dog
ENV MY_CAT=fluffy
```

or all can be define in one line: <br>
`ENV MY_NAME="John Doe" MY_DOG=Rex\ The\ Dog \  MY_CAT=fluffy`

Environment variable persistence can cause unexpected side effects. For example, setting `ENV DEBIAN_FRONTEND=noninteractive` changes the behavior of `apt-get`, and may confuse users of your image. <br>

The environment variables set using ENV will persist when a container is run from the resulting image. You can view the values using docker inspect, and change them using `docker run --env <key>=<value>`.

If an environment variable is only needed during build, and not in the final image, consider setting a value for a single command instead: <br>
`RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y ...` <br>

Or using `ARG`, which is not persisted in the final image: <br>
```shell
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y ...
```

note:
> The ENV instruction also allows an alternative syntax `ENV <key> <value>`, omitting the `=`. For example: 
`ENV MY_VAR my-value`



### running a Front-end and Back-end Containers that can communicate with each other
lets create two different separate app and test them. then integrate both to server as a web-app server. first, we will build our frontend and backend apps into a container images and then expose them to communicate with each other:


#### build the Front-end App into a Container Image

we have a [example-frontend](https://github.com/docker-hy/material-applications/tree/main/example-frontend) app which will be used to serve as our front-end. it is written with nodejs and we will follow the `README` guide in order to make a Dockerfile for it and run it on our host machine:
the Docker file will be placed inside the Root directory. <br>

note:
> project is working with `node v16` so newer versions might not work
`Docekrfile`:

```shell

FROM node:16

WORKDIR /usr/src/app

EXPOSE 5000

# for caching on Docker image we copy both packages file to the container run.
COPY package*.json ./

RUN node -v && npm -v

# copy all files from host machine inside the WORKDIR of container image
COPY . .

### installing packages
RUN npm install

# building the app base on packages
RUN npm run build

RUN npm install -g serve

CMD ["serve", "-s", "-l", "5000", "build"]

```

command to run the Dockerfile:
`docker build -t frontend-v0.1 && docker run -p 5000:5000 frontend-v0.1`


#### Build Back-end app into a container Image
the backend for our pratice is written in Golang and its source code is in [example-backend](https://github.com/docker-hy/material-applications/tree/main/example-backend). similar to the front-end app, we download the repo, read the guide line in `README.md` file and create Dockerfile base on instrcuction.

the `Dockerfile`:
```shell

FROM golang:1.16

WORKDIR /usr/src/app

EXPOSE 8080

# I understand that Golang image will by default look for PORT environment.
ENV PORT=8080

COPY . .

# define the output file as server in order to make no confusion.
RUN go build -o server

RUN go test ./...

CMD ["./server"]

```

note:
> in `RUN go test ./...` It's a convenient way to execute all tests in your project with a single command. The three dots ... in Go represent a "..." ellipsis wildcard, which in the context of the go tool, means "all subdirectories".

then we use: <br>
`docker build . -t backendgo-v0.1 && docker run -p 8080:8080 backendgo-v0.1` to run the project


### Backend and Frontend Communication
now we are going to assing correct ENV and Port exposure for both apps in order to GET data from backend by frontend UI (Practice 1.14) <br>

**Tips**: befor beginnig there are several tools that we use to troubleshoot any error or problem, for instance: <br>
the Devtool kit on browser with Network/Console panel in order to see the packages being send and receive, also the logs will be printed on Terminal.

lets alter the frontend and backend Dockerfile:

Front-end Dockerfile:
```shell
FROM node:16

WORKDIR /usr/src/app

EXPOSE 5000

COPY package*.json ./

RUN node -v && npm -v

COPY . .

RUN npm install
# as README indicate we need to define the backend URL as an Environment variable in build time
# note: we cannot assign it in runtime, so it is IMPORTANT to alter this env before build time 
RUN REACT_APP_BACKEND_URL="http://172.24.24.14:8080" npm run build

RUN npm install -g serve

CMD ["serve", "-s", "-l", "5000", "build"]
```

then we run the image by: <br>
`docker build . -t frontend-v0.2 && docker run --rm -p 5000:5000 frontend-v0.2`


the backend Dockerfile:
```shell

FROM golang:1.16

WORKDIR /usr/src/app

EXPOSE 8080

ENV PORT=8080
# we add this env to let pass the URL through CORS policy rules.
ENV REQUEST_ORIGIN="http://172.24.24.14:5000"

COPY . .

RUN go build -o server
# because we have define the REQUEST_ORIGIN env as for our local IP, we need to set this env in-line for test.
RUN REQUEST_ORIGIN=https://example.com go test ./...

CMD ["./server"]

```

lets run the image by: <br>
` docker build . -t backendgo-v0.2 && docker run --rm -p 8080:8080 backendgo-v0.2 `


after running both containers we should be able to use the button in localhost:5000 which ir related to practice 1.14 to send the request and get the success response.



### Publishing Projects 

we can publish our Docker Images in  https://hub.docker.com/ but before that we need to create an account and then create a repository for image that we are going to upload, however, we can create the repository local and `push` the image to it as well.

to login in our local machine we use: <br>
`docker login`

Next, you will need to rename the image to include your username, and then you can push it: <br>
`docker tag (docker-image) <username>/<repository>`
`docker push <username>/<repositroy>`












