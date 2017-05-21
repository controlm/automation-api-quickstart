## Create Your First Hadoop Job Flow

Tutorial on the [product web page](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Getting+Started+Guide#Control-MAutomationAPI-GettingStartedGuide-GS_for_Hadoop) that explains how to write jobs that execute Spark and HDFS commands.

```javascript
"ProcessData": {
    "Type": "Job:Hadoop:Spark:Python",
    "SparkScript": "file:///home/[USER]/ctmdk/samples/processData.py",

    "Arguments": [
        "file:///home/[USER]/ctmdk/samples/processData.py",
        "file:///home/[USER]/ctmdk/samples/processDataOutDir"
    ],

    "PreCommands" : {
        "Commands" : [
            { "rm":"-R -f  file:///home/[USER]/ctmdk/samples/processDataOutDir" }
        ]                   
    }
}
```

See the [Automation API - Services](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Services) documentation for more information.  
See the [Automation API - Code Reference](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Code+Reference) documentation for more information.
