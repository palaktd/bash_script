#!/bin/bash

# ---------------------------------------------------------------------------------------------------------
# Author: Palak Tiwari

# Script to terminate virtual machine not provisioned via Coder on AWS, Azure and GCP cloud platform using bash.
#
# --------------------------------------------------------------------------------------------------------

### Identify and terminate instances in AWS ###
terminate_aws_instance() {

aws_instance_id=($(aws ec2 describe-instances --query "Reservations[].Instances[?State.Name=='running' && !(Tags[?Key=='usage'] || Tags[?Key=='eks:cluster-name'] || Tags[?Key=='Coder_Provisioned'])].[InstanceId]" --output text))

count=0
for AWSInstanceId in "${aws_instance_id[@]}"; do
 instances_name="$(aws ec2 describe-instances --instance-ids "$AWSInstanceId" --query "Reservations[].Instances[].Tags[?Key=='Name'].Value | [0]" --output text)"
 echo "Terminating instance "$instances_name" -> "$AWSInstanceId""
 aws ec2 terminate-instances --instance-ids "$AWSInstanceId"
 ((count++))
done
echo
echo "-------------------------------------------------------------------------------"
echo "Manually created instances are deleted. Total count of AWS deleted VMs are $count"
echo "-------------------------------------------------------------------------------"
}

### Identify and terminate instances in Azure ###
terminate_azure_vm() {
azure_vm_id=($(az vm list --query "[?!(tags.Coder_Provisioned || starts_with(to_string(name), 'AVD-') || starts_with(to_string(name), 'bcml22b-'))].id" --output tsv))

count=0
for AzureInstanceId in "${azure_vm_id[@]}"; do

 echo "Terminating instance "$AzureInstanceId" as it is not created from coder"
 az vm delete --ids "$AzureInstanceId" --yes
 ((count++))
done
echo
echo "-------------------------------------------------------------------------------"
echo "Manually created instances are deleted. Total count of Azure deleted VMs are $count"
echo "-------------------------------------------------------------------------------"
}

### Identify and terminate instances in GCP ###
terminate_gcp_vm() {
gcp_vm_id=($(gcloud compute instances list --format="value(id)" --filter="NOT (labels.coder_provisioned:* OR labels.nice-dcv-license-server:*)"))

count=0
for GCPInstanceId in "${gcp_vm_id[@]}"; do
 instance_name=$(gcloud compute instances list --filter="id=($GCPInstanceId)" --format="value(name)")
 echo "Terminating instance "$instance_name" -> "$GCPInstanceId""
 instance_zone=$(gcloud compute instances list --filter="id=${GCPInstanceId}" --format="value(zone)")
 gcloud compute instances delete "$GCPInstanceId" --zone="$instance_zone" --quiet 
 ((count++))
done
echo
echo "-------------------------------------------------------------------------------"
echo "Manually created instances are deleted. Total count of GCP deleted VMs are $count"
echo "-------------------------------------------------------------------------------"
}

# Execute functions
echo "AWS"
echo "-------------------------------------------------------------------------------"
terminate_aws_instance
echo -e "\n"
echo "Azure"
echo "-------------------------------------------------------------------------------"
terminate_azure_vm
echo -e "\n"
echo "GCP"
echo "-------------------------------------------------------------------------------"
terminate_gcp_vm
