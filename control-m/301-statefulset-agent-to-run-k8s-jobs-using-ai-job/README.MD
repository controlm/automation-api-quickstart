
# Best Practices for Using Control-M to Run a Pod to Completion in a Kubernetes-based Cluster

## Running Control-M Workloads in Kubernetes
This readme describes how to run Control-M workloads in Kubernetes-based clusters, including OpenShift (from RedHat) and public cloud platforms such as EKS (from Amazon), AKS (from Microsoft Azure), or GKE (from Google). The information in this document focuses on the scenario of running a pod to completion with a Control-M/Agent running within the cluster. 

The document demonstrates how to do this while leveraging Control-M scheduling and monitoring capabilities.

> The methodology and configuration described in this document were tested and verified by BMC. The recommended best practices do not impact or change BMC licensing considerations.

## Working Assumptions
The information in this document is based on the following assumptions:
-   The following guidelines and configuration are based on Amazon Elastic Kubernetes Service and were tested in a Linux environment with Control-M 9.0.20.100.
- Testing was done on an Amazon Elastic Kubernetes Service (Amazon EKS) cluster of version 1.20. If you have an Amazon EKS cluster of version 1.23, you must install the Amazon EBS CSI driver. For more information, see [Amazon EBS CSI driver](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html).
-   Deployment of Control-M/Agent on Kubernetes requires Control-M 9.0.19.200 or later as the basis for running Control-M Automation API and Control-M Application Integrator.  For the Automation API, the [latest monthly release](https://docs.bmc.com/docs/display/workloadautomation/Control-M+Automation+API+-+Getting+Started+Guide) is recommended.
-   Control-M/Server resides outside of the Kubernetes cluster.

## Methodological Approach
There are several ways to run a Kubernetes (K8s) pod to completion using Control-M. 

This document describes a selected methodology for utilizing a Control-M Application Integrator job type to run your Control-M workloads in Kubernetes. 

The Control-M Application Integrator job starts a Kubernetes job entity and monitors its status until the job ends.

After the job ends, the pod’s output is captured and is presented in the Control-M job output. The Kubernetes job is then deleted, so that another job with the same name can be run.

The Agent pod is run as a StatefulSet, so that the hostname will be identified consistently across pod shutdown and startup. This enables Control-M/Server to uniquely identify the Control-M/Agent continuously and consistently.

The pod uses a persistent volume, so that job data and Control-M/Agent state are kept during shutdown and startup.

The connection between the Control-M/Agent and Control-M/Server is set up as a persistent connection that is initiated by the Agent. This was designed to avoid exposing the Kubernetes cluster to outside connections.


## Sample Files

> The following files in this directory are sample files. You will need to edit these samples and customize them to match the unique needs of your environment.																																						

| File Name | Description |
|---------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| build_docker_example.sh | A bash script that is used to build a Docker image |
| Dockerfile | A file that contains instructions for how to construct a Control-M/Agent Docker image |
| container_agent_startup.sh | A bash script that is used to start up the Control-M/Agent |
| ctmhost_keepalive.sh | A bash script that is used to keep the persistent connection between the installed Control-M/Agent in the pod and Control-M/Server |
| install_kubectl.sh | A bash script that is used for installing kubectl on the Control-M/Agent during the docker build process |
| Agent_20.100+OneCM.Linux.json | A configuration file for provisioning the Control-M/Agent and Control-M Application Integrator, used during the docker build process |
| agent_configuration.json | A configuration file for the Control-M/Agent provision setup |
| AI Kubernetes.ctmai | A Kubernetes job type definition file |
| stateful_ha.yaml | A file that contains StatefulSet definitions for running a Control-M/Agent container, Kubernetes definitions for creation of the Persistent Volume Claim, and a linkage between them |
| sleep_for_20sec_job.yaml | A sample Kubernetes job for testing: Print the current time and sleep for 20 seconds |
| roles.yaml | A sample file used to enforce RBAC authorization in the test environment |
| testAiConnectionProfile.json | A json configuration file for creating a connection profile that uses the kubectl utility in the Agent container |
| testAIJob.json | A json configuration file for creating the Control-M Application Integrator KUBERNETES job type  |

## Required Control-M Authorizations
To perform the processes described in this document, you must have various Control-M authorizations configured:
- For building and executing the Control-M/Agent container and deploying the Application Integrator job type:
    - API access, as described in [API session service authorizations](https://documents.bmc.com/supportu/9.0.20/help/Main_help/en-US/index.htm#94102.htm)
    - Provisioning of Control-M/Agent and applications, as described in [API Provision service authorizations](https://documents.bmc.com/supportu/9.0.20/help/Main_help/en-US/index.htm#101610.htm)
    - Access to Control-M Application Integrator, as described in [API build and deploy services authorizations](https://documents.bmc.com/supportu/9.0.20/help/Main_help/en-US/index.htm#94172.htm)
- For creating and monitoring jobs that run the Kubernetes pod:
    - API access, as described in [API session service authorizations](https://documents.bmc.com/supportu/9.0.20/help/Main_help/en-US/index.htm#94102.htm)
    - Folder authorizations, as described in [Folder authorizations](https://documents.bmc.com/supportu/9.0.20/help/Main_help/en-US/index.htm#AuthorizationsTableProperties.htm)
    - Active Job authorizations, as described in [Active authorizations](https://documents.bmc.com/supportu/9.0.20/help/Main_help/en-US/index.htm#AuthorizationsActivePage.htm)  

## Process Steps
A typical process of deploying Control-M/Agent on Kubernetes consists of the following steps:

- [Step 1: Create a Control-M/Agent image](#step-1-create-a-control-magent-image)
- [Step 2: Add Kubernetes job type to Application Integrator](#step-2-add-kubernetes-job-type-to-application-integrator)
- [Step 3: Create persistent storage for the Agent and run the Agent](#step-3-create-persistent-storage-and-run-the-agent)
- [Step 4: Verify permissions](#step-4-verify-permissions)
- [Step 5: Run Control-M jobs](#step-5-run-control-m-jobs)


> The processes described here are meant as guidelines for running
workloads in Kubernetes-based clusters. These processes have been tested in BMC environments, but may need to be adjusted to run in your environments. If you need support in deploying Control-M in this manner, please request assistance from BMC Support.

### Step 1: Create a Control-M/Agent image
Edit the build_docker_example.sh script with local values for the variables that appear in uppercase, and then run the script.
The script contains the following variables:
- AAPI_END_POINT - The URL of the Automation API server.
- AAPI_USER - The user name for the Automation API server.
- AAPI_PASS - The password for the Automation API server.
- AGENT_IMAGE_NAME - The image name of the Agent. For more details, see [Provision Service](https://docs.bmc.com/docs/display/workloadautomation/API+Services+-+Provision+service).

This produces an image that contains a Control-M/Agent with kubectl and support for executing Control-M Application Integrator jobs types. 

The container contains the following items:
-   Control-M/Agent
-   Control-M Application Integrator
-   Control-M Automation API CLI
-   Java 11 run time
-   NodeJS version 14
-   KubeCtl 
-   Bash startup scripts

Automation API instructions in the Dockerfile are invoked during the build of the image for provisioning of an Agent.

When the container is loaded, the container_agent_startup.sh is invoked. The startup script performs the following actions:
1. Mounts the container to use the persistent volume.
2. Registers and configures the Agent in Control-M.
3. Adds the Agent to the K8s hostgroup. This ensures high availability and load balancing between the Agents.
4. Deploys the Control-M Application Integrator KUBERNETES job type to enable running it with the Agent.
5. Executes the ctmhost_keepalive.sh script. This script verifies the Agent-Server connection and writes its output to the pod’s standard output.   

### Step 2: Add Kubernetes job type to Application Integrator

Use Control-M Application Integrator to import the file AI Kubernetes.ctmai:
1. Open the BMC Welcome page.
2. Click Application Integrator and log in to Control-M Application Integrator. 
3. Click *Import job type from file*, and choose the AI Kubernetes.ctmai file that you downloaded earlier.
4. Click *Deploy*.
This creates a new job type named KUBERNETES. This job type can now be used on any Agent associated with the Control-M/EM.

### Step 3: Create persistent storage and run the Agent
Use the stateful_ha.yaml file to allocate persistent storage for Agent usage and run the Agent, so that the state of the Control-M/Agent is kept across shutdown and startup of the pod. 
Before applying the file, edit the following parameters:
- AAPI_END_POINT - The URL of the Automation API server.
- AAPI_USER - The user name for the Automation API server.
- AAPI_PASS - The password for the Automation API server.
- CTM_SERVER_NAME - The name of the Control-M/Server.
- PERM_HOSTS -  The name of the Control-M/Server host.
- CTM_HOST_NAME - The name of the host group that that the deployed Agent will be added to.
- PERSISTENT_VOL - The name of the directory of the persistent volume. 
- IMAGE_NAME - The image that will be deployed in the container.
- CTM_SERVER_PUBLIC_IP - The public IP address of the Control-M/Server.

Run the following command:  
```
kubectl apply -f stateful_ha.yaml
```
After executing the apply command, verify that the pod is running. After all setup processes of the Agent have completed (in the container_agent_startup.sh script), the ctmhost_keepalive.sh script runs in an endless loop. 
After the pod is loaded successfully, the pod’s output log should contain a report regarding the connection between Control-M/Agent to Control-M/Server. 

To verify the connection between the Control-M/Agent and Control-M/Server, run
the following checks:

| Check                 | Command                                                                                                                                                                                                                                 | Expected Output                      |
|-----------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------|
| Control-M/Agent side  | ```kubectl exec -it ha-statefulset-agent -- tcsh -c ag_ping``` This command runs the ag_ping utility, which resides in the Control-M/Agent image. The StatefulSet is named satefulset-agent, with a number suffix for the instance number (0). | Server is alive. Result: Success.    |
| Control-M/Server side | Run the following command from the Control-M/Server account: ```ctmping -HOSTID ha-statefulset-agent-0``` This command runs the ctmping utility to verify the connection between the server and the agent.                                       | Agent : ha-statefulset-agent-0 is alive |

> By default the PersistentVolumeClaim accessModes property is configured to ReadWriteOnce. You can use ReadWriteMany value when needed.

### Step 4: Verify permissions
Verify with your Kubernetes Administrator that the Agent's pod has permissions to start the requested "run pod to completion". 
> In the BMC test environment, the *roles.yaml* file was applied, to ensure that the Agent can apply Kubernetes jobs from inside the pod. 

### Step 5: Run Control-M jobs
To run the Control-M job, perform the following actions:

1.	Create a connection profile between the deployed Agent and KUBERNETES job type. In the connection profile you need to supply the kubectl path in the Agent container. This connection profile synchronizes between the kubectl utilty in the Agent and the KUBERNETES job type. 

	For example, execute the following API command for the one-time creation of the connection profile:
```
	ctm deploy testAiConnectionProfile.json
```

2.	Create a new KUBERNETES type job and point it to the created Agent or Agent host group. Supply the created connection profile and a yaml file path or Kubernetes resource id (object UID)   and run the job.
	For example execute the following API command to run the Control-M Application Integrator KUBERNETES job:
```
	ctm run testAIJob.json
```

> Before running the job, ensure that the yaml file is available in the container

3. 	Check job status and output.
	To check the job status run: 
```
	ctm run status <run id>
```
> run id is obtained from the output of the run command.
	To check the job output run: 
```
	ctm run job:output::get <job id>
```
> job id is obtained from the output of the run status command.
	

