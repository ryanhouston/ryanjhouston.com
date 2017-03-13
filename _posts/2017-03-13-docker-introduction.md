---
layout: post
title: Docker Introduction
tags: [docker, dev]
category: dev
---

## Installing Docker CE

Follow the [Ubuntu installation instructions][docker-ubuntu].

## Run Jekyll in a Docker container

Simply run:

```
sudo docker run --rm --label=jekyll --volume=$(pwd):/srv/jekyll \
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
sudo docker start <container-id>
```

with the container ID that is shown for the jekyll container in `sudo docker ps
-a`. This would run the container but you would not see any output. To see
output from a running container, you can run `sudo docker attach <container-id>`.
You could stop the container by running `sudo docker stop <container-id>`. All
pretty simple stuff.

If you did not provide the `--rm` option, the container can be removed when you
are done with it via `sudo docker rm <container-id>`. Once the image has been
downloaded, the container comes up pretty quickly even if the `--rm` option is
used. The main difference in this particular case is that the ruby gems will
have to be reinstalled when fresh containers are used.

[docker-jekyll]: https://hub.docker.com/r/jekyll/jekyll/
[docker-ubuntu]: https://store.docker.com/editions/community/docker-ce-server-ubuntu?tab=description
