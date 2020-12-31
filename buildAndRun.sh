#!/usr/bin/env bash

function panic {
    echo "No arguments supplied, exiting"
    exit
}

function buildIt {
    echo "Building things"
    pushd packages/java-maven
    echo "=====> build the buildpack"
    pack package-buildpack jandebryan/my-sample-java-maven --config ./package.toml

    popd
    pushd stacks
    echo "=====> build the stacks"
    ./build-stack.sh -p jandebryan/stack -v latest alpine

    popd
    pushd builders/alpine
    echo "=====> build the builders"
    ./createBuilder.sh

    popd
    echo "=====> perform the builder"
    pack build java-sample --path apps/java-maven --builder jandebryan/sample-builder:alpine

    echo "run the container that was just built"
    docker run --rm -p 8080:8080 java-sample
}

function cleanup {
    echo "Cleaning things up"
    for i in stack-run stack-build stack-base java-sample jandebryan/sample-builder jandebryan/my-sample-java-maven buildpacksio/lifecycle jandebryan/java-maven none; do
        removeImage.sh "$i" --force
    done

    docker images
}

# idiomatic parameter and option handling in sh
while test $# -gt 0
do
    case "$1" in
        --build) buildIt
            ;;
        --clean) cleanup
            ;;
        *) panic
            ;;
    esac
    shift
done

exit 0