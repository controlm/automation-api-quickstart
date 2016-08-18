## How to invoke automation api REST calls from PowerShell script
AutomationAPIExample.ps1 script contain example for differant api invocations such as Get Control-M Servers list and others
```PowerShell
# Get Control-M Servers list
try
{
	$servers_res = Invoke-RestMethod -Method Get -Uri "$endPoint/config/servers"  -Headers $headers

	$servers_res
}
catch
{
	$error[0].ErrorDetails
	$error[0].Exception.Response.StatusCode
}
```

See the [Automation API - Services](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Services) documentation for more information.  
See the [Automation API - Code Reference](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Code+Reference) documentation for more information.
