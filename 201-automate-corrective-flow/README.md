# Run automatically a corrective job flow.

This example shows how to run a corrective job flow when some flow fail.

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
