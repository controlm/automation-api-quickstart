 DISCLAIMER: This code was tested with version 9.0.20.080

## Pushing Jobs from DEV to PROD using Automation API

This script can be used to push Jobs from Dev environment to a production environment according to the search criteria specified while changing specific job's properties 
For a list of the property that will change see DeployDescriptorPROD.json.
This example will help you to get familiar with [deploy descriptor syntax](https://docs.bmc.com/docs/display/ctmSaaSAPI/Deploy+Descriptor).
 

## PROD Variables

```bash
prodEndPoint=https://<servername for example customer-aapi.us.ctmsaas.com>/automation-api  
prodAapiToken=<Automation-Api token> 
deploydescriptor_path=<location of the deploy descriptor file>
Temp_JobDef_path=<location of the Job Definintion file>
```
## Dev Variables

```bash
devEndPoint=https://<servername for example customer-aapi.us.ctmsaas.com>/automation-api  
devAapiToken=<Automation-Api token> 
```

For more detailed information please see script source file deployscript.sh


See the [Automation API - Services](https://docs.bmc.com/docs/display/ctmSaaSAPI/Services) documentation for more information.  
See the [Automation API - Code Reference](https://docs.bmc.com/docs/display/ctmSaaSAPI/Code+Reference) documentation for more information.
