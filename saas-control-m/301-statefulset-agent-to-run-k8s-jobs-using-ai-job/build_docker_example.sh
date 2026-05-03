# This is a build command example with parameters
# You need to set :
#   1. AGENT_IMAGE_NAME - the agent image you want to install (taken from "ctm provision images Linux" cli)
#   2. AAPI_END_POINT - An endPoint is the URI for Control-M Automation API. The endpoint has the following format: https://<tenant-name>-aapi.<zone>.controlm.com/automation-api
#   3. AAPI_TOKEN - The token value for connecting to the Automation API server. For information about obtaining this token, see [Creating an API Token](https://documents.bmc.com/supportu/controlm-saas/en-US/Documentation/Creating_an_API_Token.htm)
#   4. DOCKER_IMAGE_NAME - the docker image name and optionally a tag in the 'name:tag' format
sudo docker build --build-arg AGENT_IMAGE_NAME=Agent_CentOS --build-arg AAPI_END_POINT="$AAPI_END_POINT" --build-arg AAPI_TOKEN="$AAPI_TOKEN" -t "$DOCKER_IMAGE_NAME" docker

# Don't forget to upload the result to your docker repository (ECR, DockerHub, etc.) for k8s use.