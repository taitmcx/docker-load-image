#!/bin/bash

#HARBOR_URL="https://harbor.atc.net"
USERNAME="admin"
PASSWORD="Harbor12345"
domain_regex="^([a-zA-Z0-9]([-a-zA-Z0-9]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$"
images="images.txt"
registry=$1

contains() {
    local aranan="$1"
    shift    
    for eleman in "$@"; do
        if [[ "$eleman" == "$aranan" ]]; then
            return 0
	fi
    done
    return 1 
}

create_project() {
    local project_name="$1"
    create_project_response=$(curl -s -k -X POST \
        -u "$USERNAME:$PASSWORD" \
        -H "Content-Type: application/json" \
        -d "{\"project_name\": \"$project_name\", \"metadata\": {\"public\": \"true\", \"auto_scan\": \"true\"}}" \
        "https://$registry"'/api/v2.0/projects')
    # token ile yaparsak burayıkullanabiliriz. //TODO
    #if [ "$(echo "$create_project_response" | jq -r .id)" ]; then
    #    echo "$project_name projesi baarıyla olturuldu."
    #else
    #    echo "Hata! Proje olxxxx�z: $(echo "$create_project_response" | jq -r .error)"
    #    return 1
    #fi
}

response=$(curl -X 'GET' -u "$USERNAME:$PASSWORD" \
  "https://$registry"'/api/v2.0/projects' \
  -H 'accept: application/json' -k -s)

if [ -z "$response" ]; then
  echo "Failed to authenticate with Harbor."
  exit 1
fi
if [ $? -eq 0 ]; then
  projects=$(echo "$response" | jq -r '.[] | "\(.name)"')
  echo "Projects in Harbor:"
  echo $projects
else
  echo "Failed to retrieve projects from Harbor."
  echo "HTTP Status Code: $?"
  echo "Response: $response"
fi

my_array=($projects)

while IFS= read -r sourceImage
do
    firstString=$(awk -F '/' '{print $1}' <<< "$sourceImage")
    if [[ $firstString =~ $domain_regex ]]; then
        newImage=$(echo $sourceImage | sed -e "s/$firstString/$registry/g")
        projectName=$(awk -F'/' '{print $2}' <<< "$newImage") 
        projectName=${projectName%%:*}
	if contains "$projectName" "${my_array[@]}"; then
	  echo docker tag $sourceImage $newImage
          echo docker push $newImage
	else
	  echo "'$projectName' dizide bulunmuyor."
	  create_project $projectName
	  echo docker tag $sourceImage $newImage
          echo docker push $newImage
	fi
        if [ $? -eq 0 ]; then
             echo Pushed $newImage
        else
             echo Not Pushed $newImage
        fi
    else
        newImage=$registry"/"$sourceImage
        projectName=$(awk -F'/' '{print $2}' <<< "$newImage") 
        projectName=${projectName%%:*}
	if contains "$projectName" "${my_array[@]}"; then
          echo docker tag $sourceImage $newImage
          echo docker push $newImage
        else
          echo "'$projectName' dizide bulunmuyor."
          create_project $projectName
	  echo docker tag $sourceImage $newImage
          echo docker push $newImage
        fi
        if [ $? -eq 0 ]; then
             echo Pushed $newImage
        else
             echo Not Pushed $newImage
        fi
    fi
done < "$images"
