#!/bin/bash
domain_regex="^([a-zA-Z0-9]([-a-zA-Z0-9]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$"
images="images.txt"

registry=$1

while IFS= read -r sourceImage
do
    firstString=$(awk -F '/' '{print $1}' <<< "$sourceImage")
    if [[ $firstString =~ $domain_regex ]]; then
        newImage=$(echo $sourceImage | sed -e "s/$firstString/$registry/g")
        docker tag $sourceImage $newImage
        docker push $newImage
        if [ $? -eq 0 ]; then
             echo Pushed $newImage
        else
             echo Not Pushed $newImage
        fi
    else
        newImage=$registry"/"$sourceImage
        docker tag $sourceImage $newImage
        docker push $newImage
        if [ $? -eq 0 ]; then
             echo Pushed $newImage
        else
             echo Not Pushed $newImage
        fi
    fi 
done < "$images"