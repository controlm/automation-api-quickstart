## On boarding of new application group

Tutorial on the [product web page](https://docs.bmc.com/docs/automation-api/919110/tutorial-defining-authorizations-for-control-m-roles-and-users-872868690.html)
that explains how to define new roles and users for Control-M and controlling the authorizations that they have for Control-M resources.

```javascript
{
  "Name": "hadoop_developers",
  "Description": "hadoop developers",
  "AllowedJobs": {
    "Included": [
      [
        [
          "Application",
          "like",
          "hadoop*"
        ],
        [
          "Host",
          "like",
          "hadoop*"
        ],
        [
          "JobName",
          "like",
          "hadoop*"
        ],
        [
          "Folder",
          "like",
          "hadoop*"
        ]
      ]
    ]
  },
  "AllowedJobActions": {
    "ViewProperties": true,
    "Documentation": true,
    "Log": true,
    "Statistics": true,
    "ViewOutputList": true,
    "ViewJcl": true,
    "Why": true,
    "Rerun": true,
    "SetToOk": true,
    "EditProperties": true
  },
  "Privileges": {
    "ClientAccess": {
      "SelfServiceAccess": "Full",
      "WorkloadChangeManagerAccess": "Full",
      "UtilitiesAccess": "Full",
      "ApplicationIntegratorAccess": "Full"
    },
    "Monitoring": {
      "Alert": "Full"
    },
    "Tools": {
      "Cli": "Full"
    }
  },
  "Folders": [
    {
      "Privilege": "Full",
      "Folder": "hadoop*"
    }
  ],
  "Calendars": [
    {
      "Privilege": "Browse",
      "Name": "hadoop*"
    }
  ],
  "SiteStandard": [
    {
      "Privilege": "Browse",
      "Name": "hadoop_*"
    }
  ]
}
```

See the [Automation API - Services - Authorization Configuration Reference](https://docs.bmc.com/docs/automation-api/919110/authorization-configuration-reference-872868758.html) for more information.  
The authorization.py and authorization.sh scripts contain the tutorial commands. Use them as examples for your own scripts.