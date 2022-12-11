#!/bin/bash

######################################################################
# Script Name    : clean-up-image.sh
# Description    : Used to clean up container registries by deleting untagged (dangling) images and keep 100 images
# Args           : container_registry
# Author         : Wisnu Setiawan <wissnusetiawan@gmail.com>
######################################################################

# Stop execution on any error
set -e


# Check if correct parameters were passed
msg="\tUsage:\t$0 <container registry>\n"
if [ $# -ne 1 ]; then
    echo -e $msg
    exit -1
else


    # Declare variables
    container_registry=$1
    date_threshold="$(date +%Y-%m-%d)"


    # Fetch the list of repositories
    registry_list=()
    registry_list="$(az acr repository list -n "$container_registry" --output tsv)"

        if [ -z "$registry_list" ]; then
            echo -e "Error:\tEither registry name $container_registry.\n$msg"
            exit -1
        fi
            echo "Show $registry_list info..."


    # Search for untagged (dangling) images in each repository
    echo "################################################"
    echo "EXECUTION OF UNTAGGED (DANGLING) IMAGES DELETION"
    echo "################################################"


    untagged_image=()
    echo "${registry_list[@]}" | while read -r rep; do
        untagged_image=$(
            az acr repository show-manifests --name "$container_registry" --repository "$rep" \
                --query "[?tags[0]==null].digest" \
                --orderby time_asc \
                --output tsv
        )
        if [ -z "${untagged_image[@]}" ]; then
            echo "INFO: No untagged (dangling) images found in the repository: $rep"
        else
            # Delete untagged (dangling) images
            echo
            echo "${untagged_image[@]}" | while read -r img; do
                echo "WARN: Deleting untagged (dangling) image: $rep@$img"
                az acr repository delete --name $container_registry --image $rep@$img --yes
            done
        fi
    done

 
    # Search for keep images than 100 in each repository
    echo "################################################"
    echo "       EXECUTION OF KEEP IMAGES DELETION"
    echo "################################################"


    keep_image=()
    echo "${registry_list[@]}" | while read -r rep; do
        keep_image=$(
            az acr repository show-manifests --name "$container_registry" --repository "$rep" \
                --query "[?tags[0]==null].digest" \
                --orderby time_desc \
                --output tsv 
     )
        if [ -z "${keep_image[@]}" ]; then
            echo "INFO: Deleting image with keep 100 from image: $rep"
        else
            # Keep 100 images
            echo
            echo "${keep_image[@]}" | while read -r img; do
                echo "WARN: Deleting image with keep 100 from image: $rep@$img"
                az acr repository show-manifests --name "$container_registry" --repository "$rep" \
                    | sed -n '100,$ p' | xargs -I% az acr repository delete \
                    --name "$container_registry" --image $rep@$img% --yes
            done
        fi
    done
fi
