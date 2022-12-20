# This is a build command example with parameters
# You need to change the parameters: 
#   1. endpoint, 
#   2. user, 
#   3. password
#   4. the agent image you want to install (taken from "ctm provision images Linux" cli)
sudo docker build --build-arg AAPI_END_POINT=https://<endpoint>:8443/automation-api --build-arg AAPI_USER=user --build-arg AAPI_PASS=password --build-arg AGENT_IMAGE_NAME=Agent_20.100+OneCM.Linux  . 

# Don't forget to upload the result to your docker repository (ECR, DockerHub, etc.) for k8s use.
