# Best Practices for Using Control-M to Run a Pod to Completion in a Kubernetes-based Cluster

## Running Control-M Workloads in Kubernetes

This readme describes how to run Control-M workloads in Kubernetes-based clusters, including OpenShift (from RedHat) and
public cloud platforms such as EKS (from Amazon), AKS (from Microsoft Azure), or GKE (from Google). The information in
this document focuses on the scenario of running a pod to completion with a Control-M/Agent running within the cluster.

The document demonstrates how to do this while leveraging Control-M scheduling and monitoring capabilities.

> The methodology and configuration described in this document were tested and verified by BMC. The recommended best
> practices do not impact or change BMC licensing considerations.

## Working Assumptions

The information in this document is based on the following assumptions:

- The following guidelines and configuration are based on Amazon Elastic Kubernetes Service and were tested in a Linux
  environment with Control-M 9.0.21.200.
- The previous version of these guidelines for Control-M 9.0.21.000 is located in the **9.0.21.000** folder.
- Testing was done on an Amazon Elastic Kubernetes Service (Amazon EKS) cluster of version 1.20. If you have an Amazon
  EKS cluster of version 1.27, you must install the Amazon EBS CSI driver. For more information,
  see [Amazon EBS CSI driver](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html).
    - Deployment of Control-M/Agent on Kubernetes requires Control-M 9.0.21.000 or later as the basis for running
      Control-M
      Automation API and Control-M Application Integrator. For the Automation API,
      the [latest monthly release](https://docs.bmc.com/docs/display/workloadautomation/Control-M+Automation+API+-+Getting+Started+Guide)
      is recommended.
- Control-M/Server resides outside of the Kubernetes cluster.

## Methodological Approach

There are several ways to run a Kubernetes (K8s) pod to completion using Control-M.

This document describes a selected methodology for utilizing a Control-M Application Integrator job type to run your
Control-M workloads in Kubernetes.

The Control-M Application Integrator job starts a Kubernetes job entity and monitors its status until the job ends.

After the job ends, the pod’s output is captured and is presented in the Control-M job output. The Kubernetes job is
then deleted, so that another job with the same name can be run.

The Agent pod is run as a StatefulSet, so that the hostname will be identified consistently across pod shutdown and
startup. This enables Control-M/Server to uniquely identify the Control-M/Agent continuously and consistently.

The pod uses a persistent volume, so that job data and Control-M/Agent state are kept during shutdown and startup.

The connection between the Control-M/Agent and Control-M/Server is set up as a persistent connection that is initiated
by the Agent. This was designed to avoid exposing the Kubernetes cluster to outside connections.

## Sample Files

> The following files in this directory are sample files. You will need to edit these samples and customize them to
> match the unique needs of your environment.

| File Name                                              | Description                                                                                                                                                                          |
|--------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| docker/Dockerfile                                      | A file that contains instructions for how to construct a Control-M/Agent Docker image                                                                                                |
| docker/resources/startup.sh                            | A bash script that is used to start up the Control-M/Agent                                                                                                                           |
| docker/resources/ctmhost_keepalive.sh                  | A bash script that is used to keep the persistent connection between the installed Control-M/Agent in the pod and Control-M/Server                                                   |
| docker/resources/agent_configuration.json              | A configuration file for the Control-M/Agent provision setup                                                                                                                         |
| build_docker_example.sh                                | A bash script that is used to build a Docker image                                                                                                                                   |
| install-configurations/Agent.Linux.json                | A configuration file for provisioning the Control-M/Agent and Control-M Application Integrator, used during the docker build process                                                 |
| install-configurations/agent.linux.xml                 | A configuration file with agent parameters for provisioning the Control-M/Agent and Control-M Application Integrator, used during the docker build process                           |
| install-configurations/AI_Kubernetes.Linux.json        | A configuration file for provisioning the AI Kubernetes job type, used during the docker build process                                                                               |
| installation/AI_Kubernetes.ctmai                       | A Control-M Application Integrator KUBERNETES job type definition file                                                                                                               |
| installation/DRFZ4.9.0.21.200_Linux-x86_64.tar.Z       | A Control-M/Agent installer file downloaded from EPD for provisioning the Control-M/Agent (including Control-M Application Integrator), used during the docker build process         |
| stateful_ha.yaml                                       | A file that contains StatefulSet definitions for running a Control-M/Agent container, Kubernetes definitions for creation of the Persistent Volume Claim, and a linkage between them |
| sleep_for_20sec_job.yaml                               | A sample Kubernetes job for testing: Print the current time and sleep for 20 seconds                                                                                                 |
| roles.yaml                                             | A sample file used to enforce RBAC authorization in the test environment                                                                                                             |
| testAiConnectionProfile.json                           | A json configuration file for creating a connection profile that uses the kubectl utility in the Agent container                                                                     |
| testAIJob.json                                         | A json configuration file for creating the Control-M Application Integrator KUBERNETES job type                                                                                      |

## Required Control-M Authorizations

To perform the processes described in this document, you must have various Control-M authorizations configured:

- For building and executing the Control-M/Agent container and deploying the Application Integrator job type:
    - Provisioning of Control-M/Agent and applications, as described
      in [API Provision service authorizations](https://documents.bmc.com/supportu/9.0.21.200/en-US/Documentation/Automation_API_Authorizations.htm#ProvisionServiceAuthorizations)
    - Access to Control-M Application Integrator, as described
      in [API build and deploy services authorizations](https://documents.bmc.com/supportu/9.0.21.200/en-US/Documentation/Automation_API_Authorizations.htm#BuildandDeployServiceAuthorizations)
- For creating and monitoring jobs that run the Kubernetes pod:
    - Folder authorizations, as described
      in [Folder authorizations](https://documents.bmc.com/supportu/9.0.21.200/en-US/Documentation/Users_and_Roles.htm#RoleAuthorizations)
    - Active Job authorizations, as described
      in [Active authorizations](https://documents.bmc.com/supportu/9.0.21.200/en-US/Documentation/Users_and_Roles.htm#RoleAuthorizations)

## Process Steps

A typical process of deploying Control-M/Agent on Kubernetes consists of the following steps:

- [Step 1: Create a Control-M/Agent image](#step-1-create-a-control-magent-image)
- [Step 2: Add Kubernetes job type to Application Integrator](#step-2-add-kubernetes-job-type-to-application-integrator)
- [Step 3: Create persistent storage for the Agent and run the Agent](#step-3-create-persistent-storage-and-run-the-agent)
- [Step 4: Verify permissions](#step-4-verify-permissions)
- [Step 5: Run Control-M jobs](#step-5-run-control-m-jobs)

> The processes described here are meant as guidelines for running
> workloads in Kubernetes-based clusters. These processes have been tested in BMC environments, but may need to be
> adjusted to run in your environments. If you need support in deploying Control-M in this manner, please request
> assistance from BMC Support.

### Step 1: Create a Control-M/Agent image

Prepare a local repository of installation artifacts for provision actions performed by the Provision service.
Before you run a docker build, copy the following files locally into an image or provide a URL with read permissions.
For more information about these files, see their descriptions in the table above.

- install-configurations/Agent.Linux.json
- install-configurations/agent.linux.xml
- install-configurations/AI_Kubernetes.Linux.json
- installation/AI_Kubernetes.ctmai
- installation/DRFZ4.9.0.21.200_Linux-x86_64.tar.Z

Edit the build_docker_example.sh script with local values for the variables that appear in uppercase, and then run the
script.
The script contains the following variables:

- AGENT_IMAGE_NAME - the image name of the Agent. For more details,
  see [Provision Service](https://docs.bmc.com/docs/display/workloadautomation/API+Services+-+Provision+service)
- EXT_AUTO_DEPLOY - a path to a local repository of installation artifacts for provisioning actions performed by the
  Provision service. It can be folder path (file:///) or URL (https://)
- EXT_APPLICATION_ARTIFACTS_JSON_URL - a path to a local repository of provisioning images, overriding the location used
  by default for provisioning actions performed by the Provision service. It can be folder path (file:///) or URL (
  https://)
- DOCKER_IMAGE_NAME - the docker image full name

Before you run the script, if you choose to store the above files locally, open the Dockerfile and uncomment the two
COPY lines.

This produces an image that contains a Control-M/Agent with kubectl and support for executing Control-M Application
Integrator jobs types, including the Kubernetes job type.

The container contains the following items:

- Control-M/Agent (including Control-M Application Integrator and Control-M Automation API CLI)
- Control-M Application Integrator KUBERNETES plugin
- Java 17 run time
- Python version 3.9
- kubectl
- Bash startup scripts

Automation API instructions in the Dockerfile are invoked during the build of the image for provisioning of an Agent.

When the container is loaded, the startup.sh is invoked. The startup script performs the following actions:

1. Mounts the container to use the persistent volume.
2. Registers and configures the Agent in Control-M.
3. Adds the Agent to the K8s hostgroup. This ensures high availability and load balancing between the Agents.
4. Executes the ctmhost_keepalive.sh script. This script verifies the Agent-Server connection and writes its output to
   the pod’s standard output.

### Step 2: Add Kubernetes job type to Application Integrator

Use Control-M Application Integrator to import the file AI Kubernetes.ctmai:

1. Open the BMC Welcome page.
2. Click Application Integrator and log in to Control-M Application Integrator.
3. Click *Import*, and choose the AI_Kubernetes.ctmai file that you downloaded earlier.
4. Click *Publish & Deploy* and perform the Publish action without defining a target agent.

    For more information, see [Publishing and Deploying a Plug-in](https://documents.bmc.com/supportu/9.0.21.200/en-US/Documentation/Deploying_and_Publishing_a_Plug-in.htm).

### Step 3: Create persistent storage and run the Agent

Use the stateful_ha.yaml file to allocate persistent storage for Agent usage and run the Agent, so that the state of the
Control-M/Agent is kept across shutdown and startup of the pod.

Before applying the file, perform the following steps:

1. Edit the following parameters in the stateful_ha.yaml file:

    - AAPI_END_POINT - The URL of the Automation API server.
    - CTM_SERVER_NAME - The name of the Control-M/Server.
    - PERM_HOSTS - The name of the Control-M/Server host.
    - AGENT_HOSTGROUP_NAME - The name of the host group that the deployed Agent will be added to.
    - PERSISTENT_VOL - The name of the directory of the persistent volume.
    - DOCKER_IMAGE_NAME - The image that will be deployed in the container.
    - CTM_SERVER_PUBLIC_IP - The public IP address of the Control-M/Server.

2. Prepare an API token for connecting to the Automation API server:

   a. Create an API token as described
   in [Creating an API Token](https://documents.bmc.com/supportu/9.0.21/en-US/Documentation/Creating_an_API_Token.htm).

   b. Run the following command to create a secret for the API token that is referenced by the AAPI_TOKEN parameter in
   the .yaml file:

    ```
    kubectl create secret generic credentials --from-literal=AAPI_TOKEN=value
    ```

Run the following command to create StatefulSet:

```
kubectl apply -f stateful_ha.yaml
```

After executing the apply command, verify that the pod is running. After all setup processes of the Agent have
completed (in the startup.sh script), the ctmhost_keepalive.sh script runs in an endless loop.
After the pod is loaded successfully, the pod’s output log should contain a report regarding the connection between
Control-M/Agent to Control-M/Server.

To verify the connection between the Control-M/Agent and Control-M/Server, run
the following checks:

| Check                 | Command                                                                                                                                                                                                                                                                  | Expected Output                         |
|-----------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------|
| Control-M/Agent side  | ```kubectl exec -it ha-statefulset-agent-0 -- bash -c "source .bash_profile && ag_ping"``` This command runs the ag_ping utility, which resides in the Control-M/Agent image. The StatefulSet is named stateful-agent, with a number suffix for the instance number (0). | Server is alive. Result: Success.       |
| Control-M/Server side | Run the following command from the Control-M/Server account: ```ctmping -HOSTID ha-statefulset-agent-0``` This command runs the ctmping utility to verify the connection between the server and the agent.                                                               | Agent : ha-statefulset-agent-0 is alive |

> By default the PersistentVolumeClaim accessModes property is configured to ReadWriteOnce. You can use ReadWriteMany
> value when needed.

### Step 4: Verify permissions

Verify with your Kubernetes Administrator that the Agent's pod has permissions to start the requested "run pod to
completion".
> In the BMC test environment, the *roles.yaml* file was applied, to ensure that the Agent can apply Kubernetes jobs
> from inside the pod.
> To attach this role for StatefulSet, needs to specify **serviceAccountName: node-apis** under **containers** section

### Step 5: Run Control-M jobs

To run the Control-M job, perform the following actions:

1. Create a connection profile between the deployed Agent and KUBERNETES job type. In the connection profile you need to
   supply the kubectl path in the Agent container. This connection profile synchronizes between the kubectl utility in
   the Agent and the KUBERNETES job type.

   For example, execute the following API command for the one-time creation of the connection profile:

```
	ctm deploy testAiConnectionProfile.json
```

2. Create a new KUBERNETES type job and point it to the created Agent or Agent host group. Supply the created connection
   profile and a yaml file path or Kubernetes resource id (object UID) and run the job.
   For example execute the following API command to run the Control-M Application Integrator KUBERNETES job:

```
	ctm run testAIJob.json
```

> Before running the job, ensure that the provide sleep_for_20sec_job.yaml file is available in the container under
> /home/controlm

3. Check job status and output.
   To check the job status run:

```
	ctm run status <run id>
```

> run id is obtained from the output of the run command.
> To check the job output run:

```
	ctm run job:output::get <job id>
```

> job id is obtained from the output of the run status command.
	

