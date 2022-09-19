# This is a build command example with parameters
# You need to change the parameters: 
#   1. endpoint, 
#   2. user, 
#   3. password
#   4. the agent image you want to install (taken from "ctm provision images Linux" cli)

sudo docker build --no-cache --build-arg AAPI_END_POINT=<AAPI_END_POINT> --build-arg AAPI_TOKEN=<AAPI_TOKEN> --build-arg AAPI_CLI_URL=<AAPI_CLI_URL> --build-arg AGENT_IMAGE_NAME=<AGENT_IMAGE_NAME> . 

# Don't forget to upload the result to your docker repository (ECR, DockerHub, etc.) for k8s use.
