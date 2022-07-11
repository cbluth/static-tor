#!/usr/bin/env bash
set -e

function build()
{
    docker build \
        -t tor:tmp \
        -f tor.Dockerfile \
        .
}

build
