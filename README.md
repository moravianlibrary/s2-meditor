Meditor - Docker image
========================================

This repository contains the source for building of [MEditor application](https://github.com/moravianlibrary/MEditor) as a Docker image using
[source-to-image](https://github.com/openshift/source-to-image).
The resulting image can be run using [Docker](http://docker.io).

Installation
---------------
To build a MEditor builder image from scratch, run:
```
$ git clone https://github.com/moravianlibrary/s2i-meditor.git
$ docker build -t meditor-builder .
```

Usage
---------------
To build MEditor from your own repo using standalone S2I and then run the resulting image with Docker execute:
```
$ s2i build --incremental=true --rm --ref=master https://github.com/moravianlibrary/MEditor.git meditor-builder meditor
$ docker-compose up -d
```


**Accessing the application:**
```
http://localhost:80/
```
