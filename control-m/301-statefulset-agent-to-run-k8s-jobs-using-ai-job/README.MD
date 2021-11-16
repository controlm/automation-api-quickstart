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
    Kubernetes Service and were tested in a Linux environment with Control-M 9.0.20.100.
-   Deployment of Control-M/Agent on Kubernetes requires Control-M 9.0.20.100 or
    later as the basis for running Control-M Automation API.
-   Control-M/Server resides outside of the Kubernetes cluster.

## Methodological Approach

There are several ways to run a Kubernetes (K8s) pod to completion using Control-M. 
This document describes a selected methodology for utilizing an OS job with a BMC Application Integrator job type to run your Control-M workloads in Kubernetes. 
The BMC Application Integrator job starts a Kubernetes job entity and monitors its status until the job ends.
After the job ends, the pod’s output is captured and is presented in the Control-M job output. The Kubernetes job is then deleted, so that another job with the same name can be run.

The Agent pod is run as a StatefulSet, so that the hostname will be identified
consistently across pod shutdown and startup. This enables Control-M/Server to
uniquely identify the Control-M/Agent continuously and consistently.

The pod uses a persistent volume, so that job data and Control-M/Agent state
are kept during shutdown and startup.

The connection between the Control-M/Agent and Control-M/Server is set up as a
persistent connection that is initiated by the Agent. This was designed to avoid
exposing the Kubernetes cluster to outside connections.

To view a sample container and pod, refer to [Sample Objects](#sample-objects).


## Sample Objects

Use the following links to access and obtain sample objects in GitHub.
> You will need to edit these samples and customize them to match the
unique needs of your environment.

- [All files except the BMC Application Integrator job type](https://github.com/automation-api-quickstart/tree/master/control-m/301-statefulset-agent-to-run-k8s-jobs-using-ai-job)
- [BMC Application Integrator job type](https://controlm-appdev.s3.us-west-2.amazonaws.com/automation/BEST_PRACTICE/AI+Kubernetes.ctmai)

| File Name | Description |
|---------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| build_docker_example.sh | A bash script that is used to build a Docker image           |
| Dockerfile | A file that contains instructions for how to construct a Control-M/Agent Docker image |
| container_agent_startup.sh | A bash script that is used to start up the Control-M/Agent |
| ctmhost_keepalive.sh | A bash script that is used to keep the persistent connection between the installed Agent in the pod and Control-M |
| install_ai.sh | A bash script that is used for installing support for execution of BMC Application Integrator job types in the installed Agent during the docker build process |
| install_kubectl.sh | A bash script that is used for installing kubectl on the Agent during the docker build process |
| silent.xml | A configuration file for installation of BMC Application Integrator, used during the docker build process |
| agent_configuration.json | A configuration file for the Agent |
| stateful_ha.yaml | A file that contains StatefulSet definitions for running a Control-M/Agent container, Kubernetes definitions for creation of the Persistent Volume Claim, and a linkage between them |
| sleep_for_20sec_job.yaml | A sample Kubernetes job for testing: Print the current time and sleep for 20 seconds |
| roles.yaml | A sample file used to enforce RBAC authorization in the test environment |
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
Edit the build_docker_example.sh script with local values for the variables that appear in uppercase,
and then run the script.
The script contains the following variables:
- AAPI_END_POINT - The URL of the Automation API server.
- AAPI_USER - The user name for the Automation API server.
- AAPI_PASS - The password for the Automation API server.
- AGENT_IMAGE_NAME - The image name of the Agent. For more details, see [Provision Service](https://docs.bmc.com/docs/display/workloadautomation/API+Services+-+Provision+service).


This produces an image that contains a Control-M/Agent with kubectl and support for executing BMC Application Integrator jobs types. 

The container contains the following items:
-   Control-M/Agent
-   Java 11 run time
-   NodeJS version 14
-   Control-M Automation API CLI
-   BMC Application Integrator Application Type
-   KubeCtl 
-   Bash startup scripts

Automation API instructions in the Dockerfile are invoked during the build of
the image for provisioning of an Agent.

When the container is loaded, the container_agent_startup.sh is invoked. The startup script performs the folowing actions:
1. Mounts the container to use the persistent storage.
2. Registers and configures the Agent in Control-M.
3. Adds the Agent to the k8s hostgroup. This ensures high aviliblity and load balancing between the Agents.
4. Deploys the BMC Application Integrator KUBERNETES job type to enable running it with the Agent.
5. Executes the ctmhost_keepalive.sh script. This script verifies the Agent-Server connection and writes its output to the pod’s standard output.   

### Step 2: Add Kubernetes job type to Application Integrator

Use BMC Application Integrator to import the file AI Kubernetes.ctmai:
1. Open the BMC Welcome page.
2. Click Application Integrator and log in to BMC Application Integrator. 
3. Click *Import job type from file*, and choose the AI Kubernetes.ctmai file that you downloaded earlier.
This creates a new job type named KUBERNETES.

### Step 3: Create persistent storage and run the Agent
Use the stateful_ha.yaml file to allocate persistent storage for Agent usage and run the Agent, so that the state of the Control-M/Agent is kept across shutdown and startup of the pod. 
Run the following command:  
```
kubectl apply -f stateful_ha.yaml
```
After executing the apply command, verify that the pod is running. After all setup processes of the Agent have completed (in the container_agent_startup.sh script), the ctmhost_keepalive.sh script runs in an endless loop. 

### Step 4: Verify permissions
Verify with your Kubernetes Administrator that the Agent's pod has permissions
to start the requested "run pod to completion". 
> In the BMC test environment, the *roles.yaml* file was applied, to ensure that the Agent can apply Kubernetes jobs from inside the pod. 

### Step 5: Run Control-M jobs
To run the Control-M job, perform the following actions:

1.	Create a connection profile between the deployed Agent and KUBERNETES job type. In the connection profile you will be asked to supply the kubectl path in the Agent container. This connection profile synchronizes between the kubectl utilty in the Agent and the KUBERNETES job type. 
2.	Create a new KUBERNETES type job and point it to the created Agent or Agent host group. Supply the created connection profile and a yaml file path or Kubernetes resource id and run the job.

> By default the PersistentVolumeClaim accessModes property is configured to ReadWriteOnce. To use ReadWriteMany, the cluster must be configured before applying the stateful_ha.yaml file. In the AWS environment you can use the following link: https://newbedev.com/kubernetes-pvc-with-readwritemany-on-aws  
