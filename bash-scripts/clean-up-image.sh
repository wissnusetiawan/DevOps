#!/bin/bash

registry_name=$1
repository_name=$2
image=$3

msg="\tUsage:\t$0 <registry name> <repository name> <image>\n"

if [ $# -ne 3 ]; then
    echo -e $msg
    exit -1
fi

echo "Validating ACR list..."
registry_list=$(az acr repository list --name $registry_name -o json)
if [ -z "$registry_list" ]; then
    echo -e "Error:\tEither registry name $registry_name.\n$msg"
    exit -1
fi
echo "Show $registry_list info..."

echo "Validating ACR tag..."
registry_tags=$(az acr repository show-tags --name $registry_name --repository $repository_name --top 10 --orderby time_desc --detail --query '[].name' -o tsv)
if [ -z "$registry_tags" ]; then
    echo -e "Error:\tEither repository name $repository_name.\n$msg"
    exit -1
fi
echo "Show $registry_tags info..."


show_manifests=$(
    az acr repository show-manifests --name "$registry_name" --repository "$repository_name" --top 100 --query '[].tags' \
    --output tsv 
    )
echo "Show $show_manifests info..."


echo "ACR delete image info..."
az acr repository show-manifests --name "$registry_name" --repository "$repository_name" --orderby time_desc -o tsv --query '[].digest' | sed -n '100,$ p' | xargs -I% az acr repository delete --name "$registry_name" --image $image@% --yes

