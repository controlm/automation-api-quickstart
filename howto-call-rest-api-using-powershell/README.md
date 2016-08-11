##How to invoke automation api REST calls from powershell script

	#		Get Control-M Servers list
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

## Developer documentation
For more details about the services avalible in the API look at [Automation API - Services](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Services)

For more details about JSON code supported by the API look at [Automation API - Code Reference](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Code+Reference)
