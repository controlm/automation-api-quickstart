# Best Practices for Using Helix Control-M to Run a Pod to Completion in a Kubernetes-based Cluster

## Running Control-M Workloads in Kubernetes

This readme describes how to run Helix Control-M workloads in Kubernetes-based clusters, including OpenShift (from
RedHat) and public cloud platforms such as EKS (from Amazon), AKS (from Microsoft Azure), or GKE (from Google). The
information in this document focuses on the scenario of running a pod to completion with a Helix Control-M/Agent running
within the cluster.

The document demonstrates how to do this while leveraging Helix Control-M scheduling and monitoring capabilities.

> The methodology and configuration described in this document were tested and verified by BMC. The recommended best
> practices do not impact or change BMC licensing considerations.

## Working Assumption

The guidelines and configuration in this document are based on the Amazon Elastic Kubernetes Service and were tested in
a Linux environment with the March 2022 release of Helix Control-M.
Testing was done on an Amazon Elastic Kubernetes Service (Amazon EKS) cluster of version 1.20. If you have an Amazon EKS
cluster of version 1.23, you must install the Amazon EBS CSI driver. For more information,
see [Amazon EBS CSI driver](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html).

## Methodological Approach

There are several ways to run a Kubernetes (K8s) pod to completion using Helix Control-M.

This document describes a selected methodology for utilizing a Helix Control-M Application Integrator job type to run
your Helix Control-M workloads in Kubernetes.

The Control-M Application Integrator job starts a Kubernetes job entity and monitors its status until the job ends.

After the job ends, the pod’s output is captured and is presented in the Helix Control-M job output. The Kubernetes job
is then deleted, so that another job with the same name can be run.

The Agent pod is run as a StatefulSet, so that the hostname will be identified consistently across pod shutdown and
startup. This enables Helix Control-M to uniquely identify the Helix Control-M/Agent continuously and consistently.

The pod uses a persistent volume, so that job data and Helix Control-M/Agent state are kept during shutdown and startup.

## Sample Files

> The following files in this directory are sample files. You will need to edit these samples and customize them to
> match the unique needs of your environment.

| File Name                    | Description                                                                                                                                                                                |
|------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| build_docker_example.sh      | A bash script that is used to build a Docker image                                                                                                                                         |
| Dockerfile                   | A file that contains instructions for how to construct a Helix Control-M/Agent Docker image                                                                                                |
| startup.sh                   | A bash script that is used to start up the Helix Control-M/Agent                                                                                                                           |
| ctmhost_keepalive.sh         | A bash script that is used to keep the deployed pod alive                                                                                                                                  |
| AI Kubernetes.ctmai          | A Kubernetes job type definition file                                                                                                                                                      |
| stateful_ha.yaml             | A file that contains StatefulSet definitions for running a Helix Control-M/Agent container, Kubernetes definitions for creation of the Persistent Volume Claim, and a linkage between them |
| sleep_for_20sec_job.yaml     | A sample Kubernetes job for testing: Print the current time and sleep for 20 seconds                                                                                                       |
| roles.yaml                   | A sample file used to enforce RBAC authorization in the test environment                                                                                                                   |
| testAiConnectionProfile.json | A json configuration file for creating a connection profile that uses the kubectl utility in the Agent container                                                                           |
| testAIJob.json               | A json configuration file for creating the Control-M Application Integrator KUBERNETES job type                                                                                            |

## Required Control-M Authorizations

To perform the processes described in this document, you must have various Control-M authorizations configured:

- For building and executing the Helix Control-M/Agent container and deploying the Application Integrator job type:

    - Provisioning of agents and applications, as described
      in [API Provision service authorizations](https://documents.bmc.com/supportu/controlm-saas/en-US/Documentation/Automation_API_Authorizations.htm#APIProvisionServiceAuthorizations)

    - Access to Control-M Application Integrator, as described
      in [API Build and Deploy service authorizations](https://documents.bmc.com/supportu/controlm-saas/en-US/Documentation/Automation_API_Authorizations.htm#APIBuildandDeployServicesAuthorizations)

- For creating and monitoring jobs that run the Kubernetes pod:

    - Folder authorizations, as described
      in [Role Authorizations](https://documents.bmc.com/supportu/controlm-saas/en-US/Documentation/Users_and_Roles.htm#RoleAuthorizations)

    - Job permissions, as described
      in [Role Authorizations](https://documents.bmc.com/supportu/controlm-saas/en-US/Documentation/Users_and_Roles.htm#RoleAuthorizations)

## Process Steps

A typical process of deploying Helix Control-M/Agent on Kubernetes consists of the following steps:

- [Step 1: Create a Helix Control-M/Agent image](#step-1-create-a-helix-control-magent-image)

- [Step 2: Add Kubernetes job type to Application Integrator](#step-2-add-kubernetes-job-type-to-application-integrator)

- [Step 3: Create persistent storage for the Agent and run the Agent](#step-3-create-persistent-storage-and-run-the-agent)

- [Step 4: Verify permissions](#step-4-verify-permissions)

- [Step 5: Run Helix Control-M jobs](#step-5-run-control-m-jobs)

> The processes described here are meant as guidelines for running workloads in Kubernetes-based clusters. These
> processes have been tested in BMC environments, but may need to be adjusted to run in your environments. If you need
> support in deploying Helix Control-M in this manner, please request assistance from BMC Support.

### Step 1: Create a Helix Control-M/Agent image

Edit the build_docker_example.sh script with local values for the variables that appear in uppercase, and then run the
script.

The script contains the following variables:

- AAPI_END_POINT - An endPoint is the URI for Control-M Automation API. The endpoint has the following format:
  https://<tenant-name>-aapi.<zone>.controlm.com/automation-api

- AAPI_TOKEN - The token value for connecting to the Automation API server. For information about obtaining this token,
  see [Creating an API Token](https://documents.bmc.com/supportu/controlm-saas/en-US/Documentation/Creating_an_API_Token.htm).

- AAPI_CLI_URL - The full URL path of the .BIN installer file for Automation API CLI (for example,
  DR5V3.9.0.20.220_Linux-x86_64.BIN), as it appears in the Plugins section in Helix Control-M.

- AGENT_IMAGE_NAME - The image name of the Agent. For more details,
  see [Provision Service](https://docs.bmc.com/docs/display/ctmSaaSAPI/Provision+service).

This produces an image that contains a Helix Control-M/Agent with kubectl and support for executing Control-M
Application Integrator job types.

The container contains the following items:

- Control-M/Agent (including Control-M Application Integrator and Control-M Automation API CLI)
- Control-M Application Integrator KUBERNETES plugin
- Java 11 run time
- NodeJS version 16
- kubectl
- Bash startup scripts

Automation API instructions in the Dockerfile are invoked during the build of the image for provisioning of an Agent.

When the container is loaded, the startup.sh is invoked. The startup script performs the following actions:

1. Mounts the container to use the persistent volume.

2. Registers and configures the Agent in Helix Control-M.

3. Adds the Agent to a hostgroup. This ensures high availability and load balancing between the Agents.
   > Note that if you want to add multiple Agents, you can change the value of the **replicas** setting in the *
   *stateful_ha.yaml** file.

4. Deploys the Control-M Application Integrator KUBERNETES job type to enable running it with the Agent.

5. Executes the ctmhost_keepalive.sh script. This script verifies the Agent-Server connection and writes its output to
   the pod’s standard output.

### Step 2: Add Kubernetes job type to Application Integrator

Use Control-M Application Integrator to import the AI Kubernetes.ctmai file:

1. In Helix Control-M, under the **Tools** menu, click **Application Integrator** to open Control-M Application
   Integrator.

2. Click **Import job type from file**, and choose the **AI Kubernetes.ctmai** file that you downloaded earlier.

3. Click *Deploy* and select one of the existing agents.

This creates a new job type named KUBERNETES. This job type can now be used on any Agent associated with Helix
Control-M.

### Step 3: Create persistent storage and run the Agent

Use the stateful_ha.yaml file to allocate persistent storage for Agent usage and run the Agent, so that the state of the
Helix Control-M/Agent is kept across shutdown and startup of the pod.

Before applying the file, edit the following parameters:

- AAPI_END_POINT - An endPoint is the URI for Control-M Automation API. The endpoint has the following format:
  https://<tenant-name>-aapi.<zone>.controlm.com/automation-api

- AAPI_TOKEN - The token value for connecting to the Automation API server. For information about obtaining this token,
  see [Creating an API Token](https://documents.bmc.com/supportu/controlm-saas/en-US/Documentation/Creating_an_API_Token.htm).

- AGENT_TOKEN_TAG - The token name of the agent, as it appears in Agent Token Management in Helix Control-M.

- CTM_HOSTGROUP_NAME - The name of a host group that the deployed Agent will be added to.

- PERSISTENT_VOL - The name of the directory of the persistent volume.

- DOCKER_IMAGE_NAME - The image that will be deployed in the container.

> To not expose API Token in pod definition, run the following command to create secret for AAPI_TOKEN:
> ```
> kubectl create secret generic credentials --from-literal=AAPI_TOKEN=value
> ```

Run the following command from the directory that contains the yaml file that controls the cluster:

```
kubectl apply -f stateful_ha.yaml
```

After executing the apply command, verify that the pod is running through the pod logs. After all setup processes of the
Agent have completed (in the startup.sh script), the ctmhost_keepalive.sh script runs in an endless loop.

After the pod is loaded successfully, the pod’s output log should contain a report regarding the connection between the
Helix Control-M/Agent to Helix Control-M.

To verify the connection between the Helix Control-M/Agent and Helix Control-M, run the following checks:

| Check                      | Command                                                                                                                                                                                                                                                                           | Expected Output                          |
|----------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------|
| Helix Control-M/Agent side | ```kubectl exec -it ctm-statefulset-agent-0 -- bash -c "source .bash_profile && ag_ping"``` This command runs the ag_ping utility, which resides in the Helix Control-M/Agent image. The StatefulSet is named satefulset-agent, with a number suffix for the instance number (0). | Server is alive. Result: Success.        |
| Helix Control-M side       | Access Helix Control-M, navigate to the Configuration domain, and review the list of available agents.                                                                                                                                                                            | Agent : ctm-statefulset-agent-0 is alive |

> By default the PersistentVolumeClaim accessModes property is configured to ReadWriteOnce. You can use ReadWriteMany
> value when needed.

### Step 4: Verify permissions

Verify with your Kubernetes Administrator that the Agent's pod has permissions to start the requested "run pod to
completion".

> In the BMC test environment, the **roles.yaml** file was applied, to ensure that the Agent can apply Kubernetes jobs
> from inside the pod.
> To attach this role for StatefulSet, needs to specify **serviceAccountName: node-apis** under **containers** section

### Step 5: Run Helix Control-M jobs

To run the Helix Control-M job, perform the following actions:

1. Create a connection profile between the deployed Agent and KUBERNETES job type. In the connection profile you need to
   supply the kubectl path in the Agent container. This connection profile synchronizes between the kubectl utility in
   the Agent and the KUBERNETES job type.

   For example, execute the following API command for the one-time creation of the connection profile:
   ```
    ctm deploy testAiConnectionProfile.json
   ```

2. Create a new KUBERNETES type job and point it to the created Agent or Agent host group. Supply the created connection
   profile and a yaml file path or Kubernetes resource id (object UID)  and run the job.

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

   To check the job output run:

    ```

    ctm run job:output::get <job id>

    ```

   > job id is obtained from the output of the run status command.