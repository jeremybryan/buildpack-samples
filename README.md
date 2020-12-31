## Overview

This describes the steps taken to augment the existing builder, buildpacks, and stacks to build my 
own buildpacks. 

The changes were made to impact the `alpine` variant of the buildpacks in this source tree.

Changes were required in the following directories:
* `builders\alpine` 
* `buildpacks\java-maven` 
* `stacks\alpine`

Below are the steps taken to change the content in each of these directories. 


##### buildpacks 
The buildpacks did not require a change for this simple augmentation. I was specifically targeting 
the `java-maven` buildpack for this exercise. But since I was mostly focused on just better understanding the 
relationships between `builders`, `stacks` and `buildpacks` there was no need to modify the buildpaclk.

###### packages
While we did not modify the buildpack directly, we did explore how the buildpacks are packaged and used by the builders
so we created a `java-maven` directory and created a `package.toml` file to define the packaging instructions. We then 
ran the following command to package the buildpack.

    $ cd packages\java-maven
    $ pack package-buildpack jandebryan/my-sample-java-maven --config ./package.toml 

##### stacks
The stacks did not require changes to the details of the dockerfiles. The docker files simply define the container 
images to be used for the build and run steps of the buildpack process. For our purposes I just wanted to create a stack
tagged for my own registry (versus the default `cnbs`)

    $ cd stacks
    $ ./build-stack.sh -p jandebryan/stack -v latest alpine

Following this we'll see the new images in the list of docker images on the docker daemon

    jandebryan/stack-run                          alpine                    5d1a32cfa0ec        39 hours ago        8.11MB
    jandebryan/stack-build                        alpine                    75e5816d28b8        39 hours ago        28.5MB
    jandebryan/stack-base                         alpine                    191651e14e0b        39 hours ago        8.11MB


##### builders 
The builders required the most extensive changes. For the purposes of this exercise, we change the `builder.toml` file 
to point to the new `jandebryan/stack-*` images created by the `build-stack.sh` command (described above).

More specifically within the `build.toml` file we change the stacks to be used with the builder.

    # Buildpacks to include in builder
    [[buildpacks]]
    #id = "samples/java-maven"                                <--- commented this out 
    #version = "0.0.1"                                        <--- commented this out 
    #uri = "../../buildpacks/java-maven"                      <--- commented this out 
    uri = "docker://jandebryan/my-sample-java-maven:latest"   <--- added the uri to the locally build docker
    ...
    ...
    # Stack that will be used by the builder
    [stack]
    id = "io.buildpacks.samples.stacks.alpine"
    #run-image = "cnbs/sample-stack-run:alpine"       <--- comment this out 
    #build-image = "cnbs/sample-stack-build:alpine"   <--- comment this out 
    run-image = "jandebryan/stack-run:alpine"
    build-image = "jandebryan/stack-build:alpine"


Once these changes were made we recreated the builder images using the following command:

   
    $ cd builders/alpine 
    $ ./createBuilder.sh (this script contains the full package create-builder command)
   
    
Following this command you'll find the new sample-build image in the list of images on the daemon:

    jandebryan/sample-builder                     alpine                    c943415a8d02        41 years ago        41.8MB


Now that these `stack`, `builder` and `build-packs` are updated we can build the application, 
in this case the `apps\java-maven` application by using the following command:

    pack build java-sample --path apps/java-maven --builder jandebryan/sample-builder:alpine


Once this command completes you can run the application with the following command:
    
    docker run --rm -p 8080:8080 java-sample