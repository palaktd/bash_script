#!/bin/bash

# ---------------------------------------------------------------------------------------------------------
# Author: Palak Tiwari

# Script to generate coder app docker image and push it to AWS ECR, using bash
#
# --------------------------------------------------------------------------------------------------------

### Downloading docker image required files from S3 ###
aws s3 cp s3://cdw-kpi-prod-data-bucket/coder-docker-image-files/ . --recursive


gcpconfig="gcpconfig.json"
version=$2
env=$1


update_coder_version() {
#### Change image version in Dockerfile ####
if [ -f "Dockerfile" ]; then
        sed -r -i "s/:v[0-9]+\.[0-9]+\.[0-9a-z]+$/:$version/g" Dockerfile
        echo -e "\e[1;32mUpdated coder version from $current_docker_version to $version!\e[0m"
    else
        echo -e "\e[33mPlease create a dockerfile\e[0m"
fi
}

update_gcpconfig_file() {

#### Check workloadIdentityPool and Provider in gcpconfig.json file ####
workloadidentitypool=$(grep -i "workloadIdentityPools" $gcpconfig | awk '{print $2}'| cut -d "/" -f 9)

#### Check if image is of prod or int and modify right audience value ####
if [[ "$env" = "prod" ]]; then
    if [[ "$workloadidentitypool" != "eks-aws-provider-coder-cdw-prod" ]]; then
        sed -i "s/$workloadidentitypool/eks-aws-provider-coder-cdw-prod/g" $gcpconfig
        echo -e "\e[1;32mUpdated workloadIdentityPool to eks-aws-provider-coder-cdw-prod for prod image $version\e[0m"
    else
         echo "For prod image $version workloadIdentityPool and Provider are correct. Value is $workloadidentitypool"
    fi
else ## int image
    if [[ "$workloadidentitypool" != "eks-aws-provider-coder-cdw" ]]; then
        sed -i "s/$workloadidentitypool/eks-aws-provider-coder-cdw/g" $gcpconfig
        echo -e "\e[1;32mUpdated workloadIdentityPool to eks-aws-provider-coder-cdw for int image $version\e[0m"
    else
        echo "For int image $version workloadIdentityPool and Provider are correct. Value is $workloadidentitypool"
    fi
fi
}

build_docker_image() {
    repo_name="coder/coder"
    private_ecr_uri="154453013990.dkr.ecr.eu-central-1.amazonaws.com"
    ecr_region="eu-central-1"
    updated_coder_version=$(grep -E -o "v[0-9]+\.[0-9]+\.[0-9a-z]+$" Dockerfile)
    if [[ $updated_coder_version == $version ]]; then
        if [[ $env == "prod" ]]; then
            sudo docker build -t $repo_name:"${version}p" .
        else
            sudo docker build -t $repo_name:$version .
        fi
    else
        echo -e "\e[31mDockerfile is not running with latest coder version. Please upgrade or provide right coder version.\e[0m"
        exit 1
    fi
}

docker_tag_and_push() {

    if [[ $env == "prod" ]]; then
        sudo docker tag $repo_name:"${version}p" $private_ecr_uri/$repo_name:"${version}p"
        aws ecr get-login-password --region $ecr_region | sudo docker login --username AWS --password-stdin $private_ecr_uri
        sudo docker push $private_ecr_uri/$repo_name:"${version}p"
    else
        sudo docker tag $repo_name:$version $private_ecr_uri/$repo_name:$version
        aws ecr get-login-password --region $ecr_region | sudo docker login --username AWS --password-stdin $private_ecr_uri
        sudo docker push $private_ecr_uri/$repo_name:$version
    fi
}

### main starts here ###
current_docker_version=$(grep -E -o "v[0-9]+\.[0-9]+\.[0-9a-z]+$" Dockerfile)
echo -e "\e[1;35mCurrent coder version is $current_docker_version\e[0m"

echo -e "\e[36mUpdating coder version....\e[0m"
update_coder_version
echo -e "\e[36mUpdating gcp config file....\e[0m"
update_gcpconfig_file
echo -e "\e[36mBuilding docker image and pushing it to AWS ECR\e[0m"
build_docker_image
echo -e "\e[1;32mDocker image build is done....\e[0m"
docker_tag_and_push
if [ $? -eq 0 ]; then
echo -e "\e[1;32mScript is successfully implemented....\e[0m"
else echo -e "\e[1;31mScript failed with error.\e[0m"
fi
