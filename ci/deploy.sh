#!/bin/bash

# set e

SERVER_SSH=$1
DEPLOY_PATH=$2
SSH_KEY=$3
AWS_CONFIG=$4
STACK_NAME=$5
TEMPLATE_FILE=$6
PARAMETER_FILE=$7

ROOT_DIR=$(git rev-parse --show-toplevel)
cd ${ROOT_DIR}

#syn source to deploy server
echo syn source to server
rsync -e "ssh -i  ${SSH_KEY}" -avzh --delete-after --omit-dir-times --exclude '.git' ./  ${SERVER_SSH}:${DEPLOY_PATH}

#build and run docker container
echo building source...
ssh -i ${SSH_KEY} ${SERVER_SSH} env DEPLOY_PATH="$DEPLOY_PATH" AWS_CONFIG="$AWS_CONFIG" STACK_NAME="$STACK_NAME" TEMPLATE_FILE="$TEMPLATE_FILE" PARAMETER_FILE="$PARAMETER_FILE"  /bin/bash <<'EOT'
cd ${DEPLOY_PATH}
echo validate template
echo docker run --rm -v ${AWS_CONFIG}:/root/.aws -v $(pwd):/aws amazon/aws-cli cloudformation validate-template --template-body file:///aws/${TEMPLATE_FILE} || exit 1\
docker run --rm -v ${AWS_CONFIG}:/root/.aws -v $(pwd):/aws amazon/aws-cli cloudformation validate-template --template-body file:///aws/${TEMPLATE_FILE} || exit 1\

echo update stack
echo docker run --rm -v ${AWS_CONFIG}:/root/.aws -v $(pwd):/aws amazon/aws-cli cloudformation update-stack --stack-name ${STACK_NAME} --template-body file:///aws/${TEMPLATE_FILE} --parameters file:///aws/${PARAMETER_FILE} --capabilities CAPABILITY_NAMED_IAM || exit 1\
docker run --rm -v ${AWS_CONFIG}:/root/.aws -v $(pwd):/aws amazon/aws-cli cloudformation update-stack --stack-name ${STACK_NAME} --template-body file:///aws/${TEMPLATE_FILE} --parameters file:///aws/${PARAMETER_FILE} --capabilities CAPABILITY_NAMED_IAM || exit 1\
EOT