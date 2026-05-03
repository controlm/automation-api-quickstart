# Automatically run a different job to fix a problem resulting from the failure of the current job.

When the current job fails this code triggers a different job to handle the error.  
```
"DoCorrectiveFlowNeeded" : {
    "Type": "If",
    "CompletionStatus": "NOTOK",
    "Correction": {
        "Type": "Run",
        "Folder": "CorrectiveFlow"
    }
}
```
To run:
```
ctm run AutomateCorrectiveFlow.json
```

See the [Automation API - Services](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Services) documentation for more information.  
See the [Automation API - Code Reference](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Code+Reference) documentation for more information.
