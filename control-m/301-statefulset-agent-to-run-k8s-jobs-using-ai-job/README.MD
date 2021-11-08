# Best Practices for using Control-M to run a pod to completion in a Kubernetes-based cluster

## Running Control-M Workloads in Kubernetes

This readme describes how to run Control-M workloads in Kubernetes-based
clusters, including OpenShift (from RedHat) and public cloud platforms such as
EKS (from Amazon), AKS (from Microsoft Azure), or GKE (from Google). The
information in this document focuses on the scenario of running a pod to
completion with a Control-M/Agent running within the cluster. 
The document demonstrates how to do this while leveraging Control-M scheduling and
monitoring capabilities.

> The methodology and configuration described in this document were tested and
 verified by BMC. The recommended best practices do not impact or change BMC
 licensing considerations.

## Working Assumptions

The information in this document is based on the following assumptions:

-   The following guidelines and configuration are based on Amazon Elastic
    Kubernetes Service. Configuration on other flavors of Kubernetes (such as
    OpenShift) should be adjusted accordingly.
-   Deployment of Control-M/Agent on Kubernetes requires Control-M 9.0.20.100 or
    later as the basis for running Control-M Automation API.
-   Control-M/Server resides outside of the Kubernetes cluster.
-   The kubectl utility is configured in your environment.

## Methodological Approach

There are Several ways to run a Kubernetes (K8s) pod to completion using Control-M. 
This document describes a selected methodology for utilizing an OS job with an AI job type to run your Control-M workloads in Kubernetes. 
The AI job starts the Kubernetes job entity and monitors the status until the job ends.
After the job ends, the pod’s output is captured and is presented in the Control-M job output. The Kubernetes job is then deleted.

The agent pod is run as a StatefulSet, so that the hostname will be identified
consistently across pod shutdown and startup. This enables Control-M/Server to
uniquely identify the Control-M/Agent continuously and consistently.

The pod uses a persistent storage, so that job data and Control-M/Agent state
are kept across pod shutdown and startup.

The connection between the Control-M/Agent and Control-M/Server is set up as a
persistent connection that is initiated by the agent. This was designed to avoid
exposing the Kubernetes cluster to outside connections.

To view a sample container and pod, refer to [Sample Objects](#sample-objects).


## Sample Objects

Use the following links to access and obtain 
Note that you will need to edit these samples and customize them to match the
unique needs of your environment.
[All files except the AI job type](https://github.com/automation-api-quickstart/tree/master/control-m/301-statefulset-agent-to-run-k8s-jobs-using-ai-job)
[AI job type](https://controlm-appdev.s3.us-west-2.amazonaws.com/automation/BEST_PRACTICE/AI+Kubernetes.ctmai)

| File Name | Description |
|---------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| build_docker_example.sh | A bash script that is used to build a Docker image           |
| Dockerfile | A file that contains instructions for how to construct a Control-M/Agent Docker image |
| container_agent_startup.sh | A bash script that is used to start up the Control-M/Agent |
| ctmhost_keepalive.sh | A bash script that is used to keep the connection between the installed Agent in the pod and Control-M |
| install_ai.sh | A bash script that is used for installing support for execution of AI job types in the installed Agent used during the docker build process |
| install_kubectl.sh | A bash script that is used for installing kubectl on the Agent used during the docker build process |
| silent.xml | A configuration file for AI installation used during the docker build process |
| agent_configuration.json | A configuration file for the Agent |
| stateful_ha.yaml | A file that contains StatefulSet definitions for running a Control-M/Agent container, Kubernetes definitions for creation of the Persistent Volume Claim, and a linkage between them |
| sleep_for_20sec_job.yaml | A sample Kubernetes job: Print the current time and sleep for 20 seconds |
| roles.yaml | A sample file used to enforce rbac authorization in the test environment |
| AI Kubernetes.ctmai | A Kubernetes job type definition file |


## Process Steps
A typical process of deploying Control-M/Agent on Kubernetes consists of the
following steps:

- [Step 1: Create a Control-M/Agent image](#step-1-create-a-control-magent-image)
- [Step 2: Add Kubernetes job type to Application Integrator](#step-2-add-kubernetes-job-type-to-application-integrator)
- [Step 3: Create persistent storage for the Agent and run the Agent](#step-3-create-persistent-storage-and-run-the-agent)
- [Step 4: Verify permissions](#step-4-verify-permissions)
- [Step 5: Run Control-M jobs](#step-5-run-control-m-jobs)


> The processes described here are meant as guidelines for running
workloads in Kubernetes-based clusters. These processes have been tested in BMC
environments, but may need to be adjusted to run in your environments. If you
need support in deploying Control-M in this manner, please request assistance
from BMC Support.

### Step 1: Create a Control-M/Agent image
Edit the build_docker_example.sh script with local values for the variables that appear in uppercase
(AAPI_END_POINT, AAPI_USER, AAPI_PASS, and AGENT_IMAGE_NAME), and then run the script.

This produces an image that contains a Control-M/Agent with kubectl and support for executing AI jobs types. 

The container contains the following items:
-   Control-M/Agent
-   Java run time
-   NodeJS
-   Control-M Automation API CLI
-   AI Application Type
-   KubeCtl 
-   Bash startup scripts

Automation API instructions in the Dockerfile are invoked during the build of
the image for provisioning of an agent.

The startup script configures the Agent to use the persistent storage and runs the keep alive script to maintain the connection between the Agent and Control-M.

### Step 2: Add Kubernetes job type to Application Integrator

Use Application Integrator to import the file AI Kubernetes.ctmai. This creates a new job type named KUBERNETES.

### Step 3: Create persistent storage and run the Agent
Use the stateful_ha.yaml file to allocate persistent storage for Agent usage and run the Agent, so that the state of the Control-M/Agent is kept across shutdown and startup of the pod. 
Run the following command:  
```
kubectl apply -f stateful_ha.yaml

After executing the apply command, verify that the pod is running. After all 
setup processes of the Agent have completed (in the container_agent_startup.sh script), the ctmhost_keepalive.sh script runs in an endless loop. This script verifies agent-server connection and writes its output to the pod’s standard output.

### Step 4: Verify permissions
Verify with your Kubernetes Administrator that the agent's pod has permissions
to start the requested "run pod to completion". 
Note that in the BMC test environment, the *roles.yaml* file was applied, to ensure that the agent can apply Kubernetes jobs from inside the pod. 

### Step 5: Run Control-M jobs
To run the Control-M job, perform the following actions:

1.	Create a connection profile between the deployed agent and KUBERNETES job type. In the connection profile you will be asked to supply the kubectl path in the Agent. 
2.	Create a new KUBERNETES type job and point it to the created Agent or Agent host group. Supply the created connection profile and a yaml file path or Kubernetes resource id and run the job.

Note: By default the PersistentVolumeClaim accessModes property is configured to ReadWriteOnce. To use ReadWriteMany, the cluster must be configured before applying the stateful_ha.yaml file. In the AWS environment you can use the following link: https://newbedev.com/kubernetes-pvc-with-readwritemany-on-aws  
