# This is a build command example with parameters
# You need to set :
#   1. AGENT_IMAGE_NAME - the agent image you want to install (taken from "ctm provision images Linux" cli)
#   2. AI_KUBERNETES_PLUGIN_NAME - the AI Kubernetes plugin name you want to install (taken from AI repo)
#   3. EXT_AUTO_DEPLOY - a path to a local repository of installation artifacts for provisioning actions performed by the Provision service. It can be folder path (file:///) or URL (https://)
#   4. EXT_APPLICATION_ARTIFACTS_JSON_URL - a path to a local repository of provisioning images, overriding the location used by default for provisioning actions performed by the Provision service. It can be folder path (file:///) or URL (https://)
#   5. DOCKER_IMAGE_NAME - the docker image name and optionally a tag in the 'name:tag' format
sudo docker build --build-arg AGENT_IMAGE_NAME=Agent --build-arg AI_KUBERNETES_PLUGIN_NAME=AI_Kubernetes --build-arg EXT_AUTO_DEPLOY="$EXT_AUTO_DEPLOY" --build-arg EXT_APPLICATION_ARTIFACTS_JSON_URL="$EXT_APPLICATION_ARTIFACTS_JSON_URL" -t "$DOCKER_IMAGE_NAME" docker

# Don't forget to upload the result to your docker repository (ECR, DockerHub, etc.) for k8s use.