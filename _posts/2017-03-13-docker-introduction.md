---
layout: post
title: Docker Introduction
tags: dev
---

## Why use Docker?

There has been plenty written elsewhere about Docker in general and the choice
of Docker against other tools like Vagrant, Ansible, etc. In short, Docker
allows running of containers that provide specific environments and
dependencies required to run an application, either in production or in a simple
to manage development environment. These containers are generally lightweight,
composable, and disposable. This keeps the host system (perhaps your laptop)
isolated and clean by not locally installing all kinds of dependencies needed
for specific projects or just when trying something new. The dependencies are
installed and ran inside the disposable container instead.

Here I've made some notes on a quick introduction to Docker by using a container
to run [Jekyll][jekyll-docs], which is the tool that generates this site. See more at the
[Docker docs][docker-docs].

## Installing Docker CE

Follow the [Ubuntu installation instructions][docker-ubuntu].

Be sure to add your user to `docker` group to avoid requiring `sudo`. It is
probably safer not to run containers as root unless necessary.

```
sudo adduser `whoami` docker
```

## Run Jekyll in a Docker container

Simply run:

```
docker run --rm --label=jekyll --volume=$(pwd):/srv/jekyll \
  -it -p 127.0.0.1:4000:4000 jekyll/jekyll \
  jekyll server --drafts
```

This will download and run the [official Jekyll docker image][docker-jekyll]
with all dependencies running at or very close to the same versions as used on
Github pages. This means it is only necessary to have Docker installed locally
but not Ruby or any other dependencies.

To break this command down a little:

- `--rm` removes the container once the command exits
- `--label=jekyll` gives the container a nice label. I'm not quite sure
  where this label is used. It seems the `--name=jekyll` option would be more
  useful as the `name` is usable in place of `<container-id>` in commands like
  `start` and `stop`.
- `--volume=$(pwd):/srv/jekyll` shares the current directory with the Docker
  container located at `/srv/jekyll` within the container
- `-it` is shorthand for `--interactive` and `--tty`
- `-p 127.0.0.1:4000:4000` defines a port mapping to expose port 4000 inside the
  container to port 4000 on the host. This ensures we can access
  `localhost:4000` in a browser and access the jekyll server running inside the container
- `jekyll/jekyll` is the name of the docker image on which the container is based
- `jekyll server --drafts` is the command that is run inside the container to
  run the jekyll server with drafts published

The `--rm` option could be left of to preserve the container after jekyll is
stopped. You could then restart jekyll without having to wait for the container
to rebuild by running

```
docker start <container-id>
```

with the container ID that is shown for the jekyll container in `docker ps
-a`. This would run the container but you would not see any output. To see
output from a running container, you can run `docker attach <container-id>`. You
can start the container and attach automatically by using the `-a` option.  You
could stop the container by running `docker stop <container-id>`. All pretty
simple stuff.

If you did not provide the `--rm` option, the container can be removed when you
are done with it via `docker rm <container-id>`. Once the image has been
downloaded, the container comes up pretty quickly even if the `--rm` option is
used. The main difference in this particular case is that the ruby gems will
have to be reinstalled when fresh containers are used.

## Docker Compose

The `docker run` command is kind of long and inconvenient to type every time you
want to work on a jekyll site. [Docker Compose][docker-compose] can be used to
simplify this so the single command `docker-compose up` will create or start the
container as defined by a `docker-compose.yml` file, and run the jekyll server
so everything is ready to work on the site.

The `docker-compose.yml` file for the jekyll container looks something like
this:

```
jekyll:
  image: jekyll/jekyll:pages
  command: jekyll server --drafts
  ports:
    - 4000:4000
  volumes:
    - .:/srv/jekyll
```


[docker-docs]: https://docs.docker.com/engine/getstarted/#flavors-of-docker
[jekyll-docs]: http://jekyllrb.com
[docker-jekyll]: https://hub.docker.com/r/jekyll/jekyll/
[docker-ubuntu]: https://store.docker.com/editions/community/docker-ce-server-ubuntu?tab=description
[docker-compose]: https://docs.docker.com/compose/overview/
