#!/bin/bash

src_container_registry=$1
src_repository_name=$2
src_image=$3

msg="\tUsage:\t$0 <src container registry> <src repository name> <src image>\n"

if [ $# -ne 3 ]; then
    echo -e $msg
    exit -1
fi


# Fetch the list of repositories
registry_list=()
registry_list="$(az acr repository list -n "$src_container_registry" -o json)"



# echo "Validating ACR list..."
# registry_list=$(az acr repository list --name $src_container_registry -o json)
# if [ -z "$registry_list" ]; then
#     echo -e "Error:\tEither src registry name $src_container_registry.\n$msg"
#     exit -1
# fi
echo "Show $registry_list info..."

echo "Validating ACR tag..."
registry_tags=$(az acr repository show-tags --name $src_container_registry --repository $src_repository_name --top 100 --orderby time_desc --detail --query '[].name' -o tsv)
if [ -z "$registry_tags" ]; then
    echo -e "Error:\tEither src repository name $src_repository_name.\n$msg"
    exit -1
fi
echo "Show $registry_tags info..."


# show_manifests=$(
#     az acr repository show-manifests --name "$src_container_registry" --repository "$src_repository_name" --top 100 --query '[].tags' \
#     --output tsv 
#     )
# echo "Show $show_manifests info..."


echo "ACR delete image info..."
az acr repository show-manifests --name "$src_container_registry" --repository "$src_repository_name" \
         --orderby time_desc -o tsv --query '[].digest' | sed -n '100,$ p' | xargs -I% az acr repository delete \
         --name "$src_container_registry" --image $src_image@% --yes

