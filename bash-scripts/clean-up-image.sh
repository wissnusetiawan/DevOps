#!/bin/bash

# Stop execution on any error
set -e


# Check if correct parameters were passed
msg="\tUsage:\t$0 <src container registry> <src repository name> <src image>\n"
if [ $# -ne 3 ]; then
    echo -e $msg
    exit -1
else


    # Declare variables
    src_container_registry=$1
    src_repository_name=$2
    src_image=$3
    date_threshold="$(date +%Y-%m-%d -d "30 days ago")"


    # Fetch the list of repositories
    registry_list=()
    registry_list="$(az acr repository list -n "$src_container_registry" --output tsv)"

        if [ -z "$registry_list" ]; then
            echo -e "Error:\tEither src registry name $src_container_registry.\n$msg"
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
            az acr repository show-manifests --name "$src_container_registry" --repository "$rep" \
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
                az acr repository delete --name $src_container_registry --image $rep@$img --yes
            done
        fi
    done


    # Search for images older than 30 days in each repository
    echo "################################################"
    echo "       EXECUTION OF OLD IMAGES DELETION"
    echo "################################################"



    old_image=()
    echo "${registry_list[@]}" | while read -r rep; do
        old_image=$(
            az acr repository show-manifests --name "$src_container_registry" --repository "$rep" \
                --query "[?timestamp < '$DATE_THRESHOLD'].[digest, timestamp]" \
                --orderby time_asc \
                --output tsv
        )
        if [ -z "${old_image[@]}" ]; then
            echo "INFO: No images older than 30 days found in the repository: $rep"
        else
            # Get how many images exist in the repository
            manifest_count=$(
                az acr repository show --name "$src_container_registry" --repository "$rep" --output yaml |
                    awk '/manifestCount:/{print $NF}'
            )

            # Check if there is more than 1 image in the repository
            if [ "$manifest_count" -ge 2 ]; then
                echo
                echo "The repository $rep contains a total of $manifest_count images"

                # Loop through each image older than 30 days
                echo "${old_image[@]}" | while read -r img; do

                    # Get only the manifest digest without the timestamp
                    image_manifest_only="$(echo "$img" | cut -d' ' -f1)"

                    # Get the repository last update time
                    last_update_repo=$(
                        az acr repository show --name "$src_container_registry" --repository "$rep" --output yaml |
                            awk '/lastUpdateTime:/{print $NF}' |
                            # Remove single quote from the string
                            sed "s/['\"]//g"
                    )

                    # Convert the repository last update time into seconds
                    last_update_repo="$(date -d "$last_update_repo" +%s)"

                    # Get the image last update time
                    last_update_image=$(
                        az acr repository show --name "$src_container_registry" --image "$rep@$image_manifest_only" --output yaml |
                            awk '/lastUpdateTime:/{print $NF}' |
                            # Remove single quote from the string
                            sed "s/['\"]//g"
                    )

                    # Convert the image last update time into seconds
                    last_update_image="$(date -d "$last_update_image" +%s)"

                    if [ "$last_update_repo" -gt "$last_update_image" ]; then
                        image_to_delete=$(
                            az acr repository show --name "$src_container_registry" --image "$rep"@"$image_manifest_only" --output yaml |
                                grep -A1 'tags:' | tail -n1 | awk '{ print $2}'
                        )

                        # Delete images older than 30 days
                        echo "WARN: Deleting image with tag: $image_to_delete from repository: $rep"
                        # az acr repository delete --name $src_container_registry --image $rep@$image_manifest_only --yes
                    # else
                        # echo "INFO: Nothing to do. There is only 1 image in the repository: $rep"
                    fi
                done
            else
                echo "WARN: Deleting image with keep 100 from image: $rep@$img"
            # else
            #     echo "WARN: Deleting image with keep 100 from image: $rep@$img"
                az acr repository show-manifests --name "$src_container_registry" --repository "$src_repository_name" \
                         --orderby time_desc -o tsv --query '[].digest' | sed -n '100,$ p' | xargs -I% az acr repository delete \
                         --name "$src_container_registry" --image $src_image@% --yes
            fi
        fi
    done
fi
