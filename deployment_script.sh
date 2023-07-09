#!/bin/bash

# Set the Necessary Arguments
AWS_REGION="us-east-2" # us-east-2, us-east-1 etc
ECR_REPOSITORY="flask-ecr-repo"
DOCKER_IMAGE="flaskapp"
DOCKER_TAG="latest"
ECS_SERVICE="flask-ecs-service"
ALB_TARGET_GROUP_ARN="arn:aws:elasticloadbalancing:us-east-2:770715862775:targetgroup/my-target-group/f556760d6d79e713"
ALB_DNS_NAME="flask-alb-2041433718.us-east-2.elb.amazonaws.com"
ECS_CLUSTER="flask-ecs-cluster"

echo "***************Building  Docker image**********"
docker build -t $DOCKER_IMAGE:$DOCKER_TAG .

echo "************Authenticating Docker to ECR****************"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY

echo "****************Tagging the Docker image with the ECR repository URL******************"
ECR_REPOSITORY_URL=$(aws ecr describe-repositories --repository-names $ECR_REPOSITORY --region $AWS_REGION --query "repositories[0].repositoryUri" --output text)
docker tag $DOCKER_IMAGE:$DOCKER_TAG $ECR_REPOSITORY_URL:$DOCKER_TAG

echo "****************Pushing the Docker image to ECR************"
docker push $ECR_REPOSITORY_URL:$DOCKER_TAG

echo "************Update the ECS service with the new task definition****************"
TASK_DEFINITION=$(aws ecs describe-services --services $ECS_SERVICE --cluster $ECS_CLUSTER --region $AWS_REGION --query "services[0].taskDefinition" --output text)
NEW_TASK_DEFINITION=$(echo $TASK_DEFINITION | sed "s/<DOCKER_IMAGE>|$ECR_REPOSITORY_URL:$DOCKER_TAG/g")
aws ecs update-service --service $ECS_SERVICE --cluster $ECS_CLUSTER --task-definition $NEW_TASK_DEFINITION --region $AWS_REGION

echo "**************Waiting for the ECS service to stabilize*************"
aws ecs wait services-stable --services $ECS_SERVICE --cluster $ECS_CLUSTER --region $AWS_REGION

echo "***************Perform health check using the ALB DNS name****************"

HEALTH_CHECK_URL="http://$ALB_DNS_NAME:5000"

echo "curl $HEALTH_CHECK_URL"
HEALTH_CHECK_STATUS=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_CHECK_URL)

if [ $HEALTH_CHECK_STATUS -eq 200 ]; then
  echo "Health check passed. Application deployed successfully."
else
  echo "Health check failed. Application deployment failed."
fi
