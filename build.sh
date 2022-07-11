#!/usr/bin/env bash
set -e

function build()
{
    docker build \
        -t tmp:build \
        -f build.Dockerfile \
        .
}

build
