#!/bin/bash

# Little helpers
timestamp() {
  date +"%Y-%m-%d %T"
}

# Setup log redirection
LOG_FILE="/var/log/s3_upload.log"
exec > >(tee -a $LOG_FILE) # directs stdout to log file
exec 2>&1 # and also to console


# Detect cluster domain
INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
AWS_DEFAULT_REGION=$(curl http://169.254.169.254/latest/meta-data/hostname -s | cut -d . -f 2)
CLUSTER_DOMAIN=$(aws ec2 describe-tags --filters "Name=resource-id, Values=${INSTANCE_ID}" --query 'Tags[?Key==`KubernetesCluster`].Value' --output text)

echo "$(timestamp): Detected cluster domain: ${CLUSTER_DOMAIN}"

ec2InstanceId=`hostname`

NOW=$(date +"%Y%m%d%H%M%S")
expirationDate=$(date -d $(date +"%Y/%m/%"d)+" 30 days" +%Y/%m/%d)

echo "$(timestamp): look for heap dumps to upload "

cd /var/log/

for hprof_file in *.hprof
do
  echo "$(timestamp): Processing $hprof_file file..."
  gzip $hprof_file
  aws s3 cp ${hprof_file}.gz "s3://heap.${CLUSTER_DOMAIN}/${ec2InstanceId}_${NOW}.gz" --expires $expirationDate
  rm ${hprof_file}.gz
  echo "$(timestamp): upload dump successfuly"
done

echo "$(timestamp): done heap dump loop"