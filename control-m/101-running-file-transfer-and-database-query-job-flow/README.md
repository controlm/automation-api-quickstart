## Running File Transfer and Database queries job flow

Tutorial on the [product web page](https://docs.bmc.com/docs/display/workloadautomation/Tutorial+-+Running+applications+and+programs+in+your+environment) that explains how to write jobs that execute File Transfer and Database queries.

```javascript
"GetData": {
    "Type" : "Job:FileTransfer",
    "ConnectionProfileSrc" : "SFTP-CP",
    "ConnectionProfileDest" : "Local-CP",
                         
    "FileTransfers" :
    [
        {
            "Src" : "%%SrcDataFile",
            "Dest": "%%DestDataFile",
            "TransferOption": "SrcToDest",
            "TransferType": "Binary",
            "PreCommandDest": {
                "action": "rm",
                "arg1": "%%DestDataFile"
            },
            "PostCommandDest": {
                "action": "chmod",
                "arg1": "700",
                "arg2": "%%DestDataFile"
            }
        }
    ]
},

"UpdateRecords": {
    "Type": "Job:Database:SQLScript",
    "SQLScript": "/home/<USER>/automation-api-quickstart/101-running-file-transfer-and-database-query-job-flow/processRecords.sql",
    "ConnectionProfile": "DB-CP"
}
```

See the [Automation API - Services](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Services) documentation for more information.  
See the [Automation API - Code Reference](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Code+Reference) documentation for more information.
