#!/bin/bash
docker build -t meditor-builder .
s2i build --incremental=true --rm --ref=master https://github.com/moravianlibrary/MEditor.git meditor-builder moravianlibrary/meditor
if hash docker-squash 2>/dev/null; then
  docker-squash moravianlibrary/meditor -t moravianlibrary/meditor
fi

