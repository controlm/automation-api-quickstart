DISCLAIMER: This code was tested with version 9.0.19

## Pushing Jobs from DEV to PROD using Automation API

This script can be used to push Jobs from Dev environment to a production environment according to the search criteria specified. For more detail information please see script source file.

## PROD Variables

```bash
prodEndPoint=https://<servername>:8443/automation-api
prodUser=<destination api user> 
prodPasswd=<destination api user password>
deploydescriptor_path=<location of the deploy descriptor file>
Temp_JobDef_path=<location of the Job Definintion file>
```
## Dev Variables

```bash
devEndPoint=https://<servername>:8443/automation-api
devUser=<source api user> 
devPasswd=<source api user password>
```

See the [Automation API - Services](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Services) documentation for more information.  
See the [Automation API - Code Reference](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Code+Reference) documentation for more information.