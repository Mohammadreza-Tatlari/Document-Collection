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
`docker tag (docker-image) <username>/<repository>` <br>
`docker push <username>/<repositroy>`



### Docker Compose
Docker Compose is a tool for defining and running multi-container applications. <br>
Compose simplifies the contro of entire application stack, for managing services, network, and volumes in a single comprehensible YAML configuration file. Docker Compose used to be a separate tool but now it is integrated into Docker and can be used like the rest of the Docker commands. <br>
overally, the Docker Compse is Designed to simpilfy running multi-container applications using a single command: <br>
` docker compose [-f <arg>...] [options] [COMMAND] [ARGS...] `



#### Building and Pushing an Image with Docker compose

for instance we have `Dockerfile` with such content:
```shell
FROM ubuntu:24.04

WORKDIR /mydir

RUN apt-get update && apt-get install -y curl python3
RUN curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
RUN chmod a+x /usr/local/bin/yt-dlp

ENTRYPOINT ["/usr/local/bin/yt-dlp"]
```

and we will make a `docker-compose.yaml` file inside the project root directory:<br>
`docker-compose.yaml`:
``` yaml
services:
  <service-name>:
    image: <username>/<repositoryname>
    build: . # The value of the key build can be a file system path (in the example it is the current directory .) or an object with keys context and dockerfil
```

then we can use docker compose to build and push the image to docker hub repository: <br>
`docker compose build` <br>
`docker compose push`



### Volumes in Docker Compose
To run the image, we will need to add the volume bind mounts.  Volumes in Docker Compose are defined with the following syntax `location-in-host:location-in-container` <br> 
The following example shows a single Docker Compose service with a volume:

```yaml
services:
  <service_name>:
    image: <username>/<repositoryname>
    build: .
    volumes:
      - .:/container_directory
    container_name: shorten-name # We can also give the container a name that it will use when running with container_name.
```
Running `docker compose up` for the first time creates a volume. Docker reuses the same volume when you run the command subsequently.

You can create a volume directly outside of Compose using `docker volume create` and then reference it inside `compose.yaml` as follows: <br>
``` yaml
services:
  <service_name>:
    image: node:lts
    volumes:
      - myapp:/home/node/app #remember that the host-volume:container-volume
volumes:
  myapp:
    external: true
```


### using Ready-Image with Docker compose
we can use multiple different images to be run together with docker compose. for instance, running nginx and postgres simuntaneously:
```yaml
services:
  customized-nginx:
    image: nginx:1.27
  database:
    image: postgres:17

```

Both of the containers can now be started with command `docker compose up` <br>
`docker compose up`: Builds, (re)creates, starts, and attaches to containers for a service. Unless they are already running, this command also starts any linked services.


### Key Commands in Docker Compose
`docker compose up`: starts all the services defined in the compose.yaml file <br>
`docker compose down`: stops and remove the running services <br>
`docker compose log`: to monitor the output, debug issues and view the logs <br>
`docker compose ps`: to list all theservices along with their current status <br>



### Web Service in Docker Compose
we are going to run a simple web service inside a container that prints the current container id (itself). <br>
the project is the [jwilder/whoami(github)](https://github.com/jwilder/whoami) [jwilder/whoami(docker-hub)](https://hub.docker.com/r/jwilder/whoami)

test the machine by: <br>
`docker container run --rm -d -p 8000:8000 jwilder/whoami` => it will print the container ID on localhost:8000

creating a docker compose.yaml file for it: <br>
```yaml
services:
  whoami:
    image: jwilder/whoami
    ports:
      - 8000:8000
```

run it on background with -d flag: <br>
`docker compose up -d`

test it: <br>
`curl localhost:8000`


#### adding Environment Variables to Compose
there are many deligate ways to add environment variables to a compose file. <br>
for instance:
```yaml
services:
  backend:
    image:
    environment:
      - VARIABLE=VALUE
      - VARIABLE2=VALUE2
```
or
``` yaml
services:
  webapp:
    environment:
      DEBUG: "true" # is equivalent of DEBUG=true or # DEBUG
```

You can choose not to set a value and pass the environment variables from your shell straight through to your containers. It works in the same way as: <br>
`docker run -e VARIABLE=DATA`


#### Command in compose:
command overrides the default `command` declared by the container image, for example by Dockerfile's `CMD` <br>
`command: bundle exec thin -p 3000` <br>

If the value is null, the default command from the image is used. <br>
**note**: If the value is [] (empty list) or '' (empty string), the default command declared by the image is ignored, or in other words overridden to be empty.

**caution**: *Unlike the CMD instruction in a Dockerfile, the command field doesn't automatically run within the context of the SHELL instruction defined in the image. If your command relies on shell-specific features, such as environment variable expansion, you need to explicitly run it within a shell. For example:*
`command: /bin/sh -c 'echo "hello $$HOSTNAME"'`

instance inside docker compose yaml file: <br>
compose.yaml:
``` yaml
services:
  webservice-compose:
    image: devopsdockeruh/simple-web-service:alpine
    ports:
      - 8080:8080
    command: docker run -p 8080:8080 devopsdockeruh/simple-web-service:alpine server
```

run it by: `docker compose up`



### practical example for running two different services by docker compose
let revisit two Dockerfiles that we had, the way we built and run them to communicate with each others.

the backend Dockerfile:
```shell
FROM golang:1.16
WORKDIR /usr/src/app
EXPOSE 8080
ENV PORT=8080
ENV REQUEST_ORIGIN="http://172.24.24.14:5000"
COPY . .
RUN go build -o server
RUN REQUEST_ORIGIN=https://example.com go test ./...
CMD ["./server"]
```
test the image by: <br> 
` docker build . -t backendgo-v0.2 && docker run --rm -p 8080:8080 backendgo-v0.2 `

Front-end Dockerfile:
```shell
FROM node:16
WORKDIR /usr/src/app
EXPOSE 5000
COPY package*.json ./
RUN node -v && npm -v
COPY . .
RUN npm install
RUN REACT_APP_BACKEND_URL="http://172.24.24.14:8080" npm run build
RUN npm install -g serve
CMD ["serve", "-s", "-l", "5000", "build"]
```
test the image by:<br>
`docker build . -t frontend-v0.2 && docker run --rm -p 5000:5000 frontend-v0.2`


then we add tags to them to be used in compose: <br>
`docker tag frontend-v0.2 mohammadrezat/frontend-v0.2`<br>
`docker tag backendgo-v0.2 mohammadrezat/backendgo-v0.2`


then include both in `compose.yaml` file:<br>
```yaml
services:
  backend-compose:
    image: mohammadrezat/backendgo-v0.2
    ports:
      - 8080:8080
  frontend-compose:
    image: mohammadrezat/frontend-v0.2
    ports:
      - 5000:5000
```

finally run the `compose.yaml` file with: <br>
`docker compose up -d `



### Docker Network
Connecting two services such as a server and its database in Docker can be achieved with a [Docker network](https://docs.docker.com/engine/network/). In addition to starting services listed in docker-compose.yml Docker Compose automatically creates and joins both containers into a network with a DNS(opens in a new tab). Each service is named after the name given in the docker-compose.yml file. As such, containers can reference each other simply with their service names, which is different from the container name. 
**note**: the internal DNS will translate that to the correct access and ports do not have to be published outside of the network. <br>
The backend will be able to access the application within the Docker network.

#### Publishing Port
By default, when you create or run a container using `docker create` or `docker run`, containers on bridge networks don't expose any ports to the outside world. Use the `--publish` or `-p` flag to make a port available to services outside the bridge network. This creates a firewall rule in the host, mapping a container port to a port on the Docker host to the outside world.

Formats on publishing container ports
- `-p 8080:80` =>	Map port 8080 on the Docker host to TCP port 80 in the container.
- `-p 192.168.1.100:8080:80` =>	Map port 8080 on the Docker host IP 192.168.1.100 to TCP port 80 in the container.
- `-p 8080:80/udp` =>	Map port 8080 on the Docker host to UDP port 80 in the container.
- `-p 8080:80/tcp -p 8080:80/udp` => 	Map TCP port 8080 on the Docker host to TCP port 80 in the container, and map UDP port 8080 on the Docker host to UDP port 80 in the container.

**Caution**: *when you publish a container's ports it becomes available not only to the Docker host, but to the outside world as well.* <br>
*If you include the localhost IP address (127.0.0.1, or ::1) with the publish flag, only the Docker host and its containers can access the published container port.*
`docker run -p 127.0.0.1:8080:80 -p '[::1]:8080:80' nginx`

Note:
> Hosts within the same L2 segment (for example, hosts connected to the same network switch) can reach ports published to localhost https://github.com/moby/moby/issues/45610


### Docker Network (Side Topic) [Networking Overview](https://docs.docker.com/engine/network/)
Containers have networking enabled by default, and they can make outgoing connections. A container has no information about what kind of network it's attached to, or whether their peers are also Docker workloads or not. A container only sees a network interface with an IP address, a gateway, a routing table, DNS services, and other networking details. That is, unless the container uses the none network driver.

you can create custom user-defined netwroks, and connect multiple containers to the same network. containers can communicate with each other using container IP addresses or container names.

for instance using the `bridge` netwrok driver and running a container in the created network: <br>
`docker network create -d bridge my-net` <br>
`docker run --network=my-net -itd --name=container3 busybox`

**caution**:*misconfiugration or diffault configuration on Docker network can cause affects Host Routing. or overlapping subnets.*

used commands: <br>
- `ip route` => to print all the avialable or created routes by OS or Docker
- `docker network ls` => to see all network ID and Drivers
- `docker network rm <network_id_or_name>` => removing a network (remember that it can potentially break any container usig it so use `container ps -a` before removing it)
- `sudo ip link set down/down <nework-id>` => to temporary down/up the Link



### Manual network definition
it is possible to configure a network manually in Docker Compose. it helps to connect two different containers from different Docker Compose.

an instance of a `compose.yaml` file with network configuration:
```yaml
services:
  db:
    image: postgres:13.2-alpine
    networks:
      - database-network # Name in this Docker Compose file</em>

networks:
  database-network: # Name in this Docker Compose file</em>
    name: database-network # Name that will be the actual name of the network</em>
```

This defines a network called database-network which is created with `docker compose up` and removed with `docker compose down`. <br>
As can be seen, services are configured to use a network by adding `networks` into the definition of the service.


#### Establishing a connection to an external network
Establishing a connection to an external network (that is, a network defined in another docker-compose.yml, or by some other means) is done as follows:
```yaml
services:
  db:
    image: backend-image
    networks:
      - database-network

networks:
  database-network:
    external:
      name: database-network <em># Must match the actual name of the network</em>

```


#### default network
By default all services are added to a network called default. The default network can be configured and this makes it possible to connect to an external network by default as well. <br>
instance:
``` yaml
services:
  db:
    image: postgres:latest-alpine
  
networks:
  defaults:
    external:
      name: database-network # must match the actual name of the network
```



### Scaling
compose can scale a service to run on multiple instances for instance we can run a compose file and define a service in it and scale it up by number:
`docker compose up --scale <service-name>=3` it will make 3 instance of the define service.

but few things should be considered. for example if the service is listening on specific port we cannot scale all 3 instance to listen on the same port. so we can pass this task to docker to choose random ports to dedicate for each instance. <br>
to do so we only define the service port:<br>
``` yaml
services:
  whoami:
    image: jwilder/whoami
    ports:
      - 8000
```

we can check the random ports by: <br>
`docker compose port [options] <service-name> <private-port>`

for instance after running `docker compose up --scale whoami=3 -d` we then can use `docker compose port --index 1 whoami 8000` to see the fist instance's random port.

#### Using Docker Socket to manage scaling.
`docker.sock` is the UNIX socket that Docker daemon is listening to. Docker cli client uses this socket to execute docker commands by default. You can override these settings as well. <br>
There might be different reasons why you may need to mount Docker socket inside a container. Like launching new containers from within another container. Or for auto service discovery and Logging purposes. This increases attack surface so you should be careful if you mount docker socket inside a container there are trusted codes running inside that container otherwise you can simply compromise your host that is running docker daemon, since Docker by default launches all containers as root. <br>

Let's add the [nginx-proxy]( https://github.com/jwilder/nginx-proxy) to our compose file and remove the port bindings from the whoami service. We'll mount docker.sock of our host machine the socket that is used to communicate with the Docker Daemon inside of the container in :ro read-only mode. <br>
The nginx-proxy works with two environment variables: `VIRTUAL_HOST` and `VIRTUAL_PORT`. `VIRTUAL_PORT` is not needed if the service has `EXPOSE` in it's Docker image <br>
The domain `colasloth.com` is configured so that all subdomains point to 127.0.0.1. in brief the colasloth.com it's a simple DNS "hack":
the `compose.yaml` file:

```yaml

services:
  whoami:
    image: jwilder/whoami
    environment: 
      - VIRTUAL_HOST=whoami.colasloth.com
    
  proxy:
    image: jwilder/nginx-proxy
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
    ports:
      - 80:80

```

test the container by: <br> 
`docker compose up -d --scale whoami=3` => to run the compose file and and scale the whoami service  
`curl whoami.colasloth.com` => to curl the domain name (localhsot base reverse proxy) to see  the different machines ID (do it multiple times)


we also can run nginx service beside our DNS mock by:

```yaml

services:
  whoami:
    image: jwilder/whoami
    environment:
      - VIRTUAL_HOST=whoami.colasloth.com
  proxy:
    image: jwilder/nginx-proxy
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro #make the docker.sock from our host machine to only be read-only
    ports:
      - 80:80

  first:
    image: nginx:1.19-alpine
    volumes:
      - ./first.html:/usr/share/nginx/html/index.html:ro
    environment:
      - VIRTUAL_HOST=first.colasloth.com

  second:
    image: nginx:1.19-alpine
    volumes:
      - ./second.html:/usr/share/nginx/html/index.html:ro
    environment:
      - VIRTUAL_HOST=second.colasloth.com

```

test it by: 
`docker compose up -d --scale=whoami` <br>
and <br>
`curl first.colasloth.com`



### Volumes in Action
[volumes in docker compose](https://docs.docker.com/engine/storage/volumes/#use-a-volume-with-docker-compose)

Volumes are persistent data stores for containers, created and managed by Docker. You can create a volume explicitly using the docker volume create command, or Docker can create a volume during container or service creation. <br>
for instance we can create a postgres container via compose.yaml without defining any container and it will create for us automatically <br>

run the `compose.yaml` file below with ` docker compose up -d`:
``` yaml

services:
  postgresdb:
    image: postgres
    restart: unless-stopped
    environment:
      POSTGRES_PASSWORD: mohammadreza
    container_name: db_redmine

```
and then inspect it to see if it has created volume with: <br>
`docker container inspect db_redmine | grep -A 5 Mounts`

we also can inspect all created volumes by: <br>
`docker volume ls`

to wipe or delete them all use: <br>
`docker volume prune`


now lets define a databse for our postgres compose file:
```yaml
services:
  postgresdb:
    image: postgres
    restart: unless-stopped
    environment:
      POSTGRES_PASSWORD: mohammadreza
    container_name: db_redmine
    volumes:
      - database:/var/lib/postgresql/data

volumes:
  database:
```


#### depended services
ou can control the order of service startup and shutdown with the `depends_on` attribute. Compose always starts and stops containers in dependency order, where dependencies are determined by `depends_on`, `links`, `volumes_from`, and `network_mode`: "service:..."

by following the previous postgres compose file, we are now going to add a service for `redmine` which is depended on `postgresdb`. To prevent any dependency issues we modify it as such:

```yaml

services:
  postgresdb:
    image: postgres
    restart: unless-stopped
    environment:
      POSTGRES_PASSWORD: mohammadreza
    container_name: db_redmine
    volumes:
      - database:/var/lib/postgresql/data

  redmine:
    image: redmine:5.1-alpine
    environment:
      - REDMINE_DB_POSTGRES=postgresdb
      - REDMINE_DB_PASSWORD=mohammadreza
    ports:
      - 9999:3000
    depends_on:
      - postgresdb


volumes:
  database:

```
we can use psql command to interact with Database inside the container: <br>
`docker container exec -it db_redmine psql -U postgres` <br>

`docker container exec db_redmine pg_dump -U postgres > redmine.dump` =>  used to create backups with pg_dump

#### additional configuration to the file
the image creates files to `/usr/src/redmine/files` and those are better to be persisted. also Dokcerfile of redmine needs to create a volume but its better to be persisted. <br>
also we will create Adminer dashboard which is a php based database manager web GUI. <br>
the admier can access to the database through the Docker Netwrok. <br>
We provide this information to Redmine using an environment variable in order to connect to Postgres Database.

compose.yaml:
```yaml

services:
  postgresdb:
    image: postgres
    restart: unless-stopped
    environment:
      POSTGRES_PASSWORD: mohammadreza
    container_name: db_redmine
    volumes:
      - database:/var/lib/postgresql/data

  redmine:
    image: redmine:5.1-alpine
    environment:
      - REDMINE_DB_POSTGRES=postgresdb
      - REDMINE_DB_PASSWORD=mohammadreza
    ports:
      - 9999:3000
    volumes:
      - files:/usr/src/redmine/files
    depends_on:
      - postgresdb

  adminer:
    image: adminer
    restart: unless-stopped
    ports:
      - 8081:8080
    environment:
      - ADMINER_DESIGN=cocoa
     #- ADMINER_DEFAULT_SERVER=database_server # if the datbase has some other name, we have to pass it to adminer using an environmnet variable.
volumes:
  database:
  files:

```



### port scanning in docker 
The container port is there within the Docker network accessible by the other containers that are in the same network even if we do not publish anything. So publishing the ports is only for exposing ports outside the Docker network. If no direct access outside the network is not needed, then we just do not publish anything.

to check whether there is a port available from host machine, we can use:
` docker run -it --rm --network host networkstatic/nmap localhost`



### building compose from local Dockerfile
for a test we are going to create node.js project with Dockerfile and run it via compose.yaml file.
the [repository file](https://github.com/docker-hy/material-applications/tree/main/node-dev-env)

the Dockerfile will be:
```shell
FROM node:20
WORKDIR /usr/src/app
COPY package* ./
RUN npm install
```

compose.yaml:
```yaml
services:
  node-dev-env:
    build: . # Build with the Dockerfile here
    command: npm start # Run npm start as the command
    ports:
      - 3000:3000 # The app uses port 3000 by default, publish it as 3000
    volumes:
      - ./:/usr/src/app # Let us modify the contents of the container locally
      - node_modules:/usr/src/app/node_modules # A bit of node magic, this ensures the dependencies built for the image are not available locally.
    container_name: node-dev-env # Container name for convenience

volumes: # This is required for the node_modules named volume
  node_modules:

```

run the compose file with: <br>
`docker compose up`

if we make any changes on files we can rebuild the compose by: <br>
`docker compose up --build`



## Security and optimization


### Official Images and trust
*we will dive on reasoning why we might pick one image over the other. leanr to not use root on applications due to potential dangerous*

#### looking into images
The [official images repository](https://github.com/docker-library/official-images) contains a library of images considered official. They are introduced into the library by regular pull request processes. The extended process for verifying an image is described in the repository README. Many of the most well-known projects are maintained under the docker-library <br>

for instance lets look at the ubuntu docker image. to inspect that we will check its [official repository](https://hub.docker.com/_/ubuntu) is Dockerhub. and read its description <br>
in the description of ubuntu repository, there is a link to git.launchpad (https://git.launchpad.net/cloud-images/+oci/ubuntu-base) of the image. by checking that we can see all changes and the sources code of dockerfile: <br>
- in [git.launch](https://git.launchpad.net/cloud-images/+oci/ubuntu-base) > Summary > (select a branch) > tree > (select Dockerfile) to seee the source code and changes.

to compare it to our local image of ubuntu you can check it via: <br>
`docker image history --n-trunc ubuntu:24.04` => you can compare its content with the one up in repository 

You can also visit the Docker Hub page for the image tag itself, which shows the layers and warns about potential security issues. You can see how many different problems it finds. the path is: <br>
- [Ubuntu Docker Repositroy](https://hub.docker.com/_/ubuntu) > tags > (select a tag and check its details related to CVE)

note:
> the build processes are open and we can verify it if we have the need. In addition there is nothing that makes the "official" image special.



### Deployment Pipelines
[CI/CD](https://en.wikipedia.org/wiki/CI/CD) pipeline (sometimes called deployment pipeline) is a corner stone of DevOps. <br>
> CI/CD automates much or all of the manual human intervention traditionally needed to get new code from a commit into production. With a CI/CD pipeline, development teams can make changes to code that are then automatically tested and pushed out for delivery and deployment. Get CI/CD right and downtime is minimized and code releases happen faster.


### how to set up deployment pipeline
a deployment pipeline can be used to automatically deploy containerized software to any machine. So every time you commit the code in your machine, the pipeline builds the image and starts it up in the server. <br>

We will use [GitHub Actions](https://github.com/features/actions) to build an image and push the image to Docker Hub, and then use a project called [Watchtower](https://containrrr.dev/watchtower/) to automatically pull and restart the new image in the target machine.


### understanding Github Actions:
GitHub Actions is a continuous integration and continuous delivery (CI/CD) platform that allows you to automate your build, test, and deployment pipeline. You can create workflows that build and test every pull request to your repository, or deploy merged pull requests to production.<br>


#### The Components of GitHub Action
You can configure a GitHub Actions **workflow** to be triggered when an **event** occurs in your repository, such as a pull request being opened or an issue being created. Your workflow contains one or more **jobs** which can run in sequential order or in parallel. Each job will run inside its own virtual machine **runner**, or inside a container, and has one or more **steps** that either run a script that you define or run an **action**, which is a reusable extension that can simplify your workflow.

**Workflows** <br>
A workflow is a configurable automated process that will run one or more jobs. Workflows are defined by a YAML file checked in to your repository and will run when triggered by an event in your repository, or they can be triggered manually, or at a defined schedule.

**Events** <br>
An event is a specific activity in a repository that triggers a workflow run. For example, an activity can originate from GitHub when someone creates a pull request, opens an issue, or pushes a commit to a repository

**Jobs** <br>
A job is a set of steps in a workflow that is executed on the same runner. Each step is either a shell script that will be executed, or an action that will be run. Steps are executed in order and are dependent on each other. <br>
*Since each step is executed on the same runner, you can share data from one step to another.*

**Actions** <br>
An action is a custom application for the GitHub Actions platform that performs a complex but frequently repeated task. Use an action to help reduce the amount of repetitive code that you write in your workflow files. An action can pull your Git repository from GitHub, set up the correct toolchain for your build environment, or set up the authentication to your cloud provider.

**Runners** <br>
A runner is a server that runs your workflows when they're triggered. Each runner can run a single job at a time. GitHub provides Ubuntu Linux, Microsoft Windows, and macOS runners to run your workflows. Each workflow run executes in a fresh, newly-provisioned virtual machine. <br>

In general, a workflow consists of a number of jobs In our case, there is just one job, that is given the name build.
A job consists of a series of steps Each step is a small operation or action that does its part of the whole. The steps are the following

an example of "Workflow" file which is name as `deploy.yaml`:
```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches:
      - skip

jobs:
  deploy:
    name: Deploy to GitHub Pages
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3 #used to check out the code from the repository
      - uses: actions/setup-node@v3
        with:
          node-version: 18
          cache: npm

      - name: Install dependencies
        run: npm ci
      - name: Swizzle search
        run: npm run swizzle docusaurus-lunr-search SearchBar -- --eject --danger
      - name: Build website
        run: npm run build

      # Popular action to deploy to GitHub Pages:
      # Docs: https://github.com/peaceiris/actions-gh-pages#%EF%B8%8F-docusaurus
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3 
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./build
          cname: devopswithdocker.com

  publish-docker-hub:
    name: Publish image to Docker Hub
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Login to DockerHub
        uses: docker/login-action@v1
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@v2
        with:
          push: true
          tags: devopsdockeruh/coursepage:latest

```

in the yaml file above, each step has its own operation/action that does its part of the whole. <br>
the `actions/checkout@v2` is a ready-made actions that github provides. <br>
[official Docker GitHub Actions](https://github.com/marketplace/actions/build-and-push-docker-images)

**Note:**
> GitHub Actions are doing only the "first half" of the deployment pipeline: they are ensuring that every push to GitHub is built to a Docker image which is then pushed to Docker Hub. The other half of the deployment pipeline is implemented by a containerized service called [Watchtower](https://github.com/containrrr/watchtower)

**Watchtower**
Watchtower is an open-source project that automates the task of updating images. Watchtower will pull the source of the image (in this case Docker Hub) for changes in the containers that are running. The container that is running will be updated and automatically restarted when a new version of the image is pushed to Docker Hub.

*Security Concern: Docker Hub accessing your computer*:
> Note that now anyone with access to your Docker Hub also has access to your PC through this. If they push a malicious update to your application, Watchtower will happily download and start the updated version.

watchtower can be run by the following Docker compose file:
```yaml
services:
  watchtower:
    image: containrrr/watchtower
    environment:
      -  WATCHTOWER_POLL_INTERVAL=60 <em># Poll every 60 seconds</em>
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    container_name: watchtower
```

*be careful*: <br>
when running the watchtower compose file it will automatically update all the container images on Local Docker. to prevent it we need to use --monitor-only arguments

<br>
<br>

### Deploying a simple pipeline with WatchTower
in this section we are going to deploy a very simple web-app with dockerfile to build it, and apply CI/CD process on it. the pipeline will be implemented via [Github actions](https://github.com/features/actions) and [WatchTower](https://containrrr.dev/watchtower/).

*the scenario is as such:* <br>
1. the app is going to be developed and pushed to github directory. this project has a directory called `.github/workflows` which contains the set of rules for workflow.
2. then we are going to use [action checkout](https://github.com/actions/checkout) for checking the app directory so the workflow can access it. and [docker login-action](https://github.com/docker/login-action) to use personal access token to connect our github with github action to docker hub in order to complete the next step.
3. the next step is still in our workflow which is using [build-push-action](https://github.com/docker/build-push-action) to build our app and push it into docker hub registry.

4. on our production server we will prepare a compose file that will run [WatchTower](https://containrrr.dev/watchtower/). beside the image that is built by workflow of our app. the watchtower will then keep watch on our app container. if any newer version on docker hub that applied via github action workflow is detected by watchtower it will restart our web-app container and update our application.

the source code of web-app with the docker file is in [this link](https://github.com/Mohammadreza-Tatlari/workflow-nodejs)

and the `workflow/github-actions.yaml` is written as such:
```yaml

name: Release Version checkout
on: [push]
jobs:
  Builder:
    runs-on: ubuntu-latest
    steps:
      -
        name: checkout repository for update
        uses: actions/checkout@v4

      - 
        name: Login to Docker Hub 
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - 
        name: Build and push
        uses: docker/build-push-action@v6
        with:
          push: true
          tags: mohammadrezat/workflowjs:latest

```

**note** 
> *remember that the secrets are defined inside the project repository in setting > security section*

`compose.yaml` file that run both watchtower and the docker image of our project: <br>

```yaml
services:
  watchtower:
    image: containrrr/watchtower
    environment:
      -  WATCHTOWER_POLL_INTERVAL=60 # Poll every 60 seconds
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    container_name: watchtower

  express:
    image: mohammadrezat/workflowjs
    ports:
      - 8080:8080

```














