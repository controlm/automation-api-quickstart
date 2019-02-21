#	Examples of invoking Control-M Automation API using Power Shell Invoke-RestMethod
#
#
#
#------------------------------------------------------------------------------------

#------------------------------------------------------------------------------------
#  To accept self-signed certificates uncomment next line
#
#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

#----------------------------------------------------------------
#Login request
$endPoint   = "https://<controlmEndPoint>:8443/automation-api"
#------------------------------------------------------------------------------------
$username 	= "<ControlmUser>"
$password   = "<ControlmPassword>"

$login_data = @{ 
	username = $username; 
	password = $password}

try
{	
	"The login credentials:"
	$login_data
	
	$login_res = Invoke-RestMethod -Method Post -Uri $endPoint/session/login  -Body (ConvertTo-Json $login_data) -ContentType "application/json"
		
	"The login results"	
	$login_res
}
catch
{
	$_.Exception.Message
	$error[0].ErrorDetails	
	$error[0].Exception.Response.StatusCode
	exit
}

$token= $login_res.token
$headers = @{ Authorization = "Bearer $token"}

#----------------------------------------------------------------
#  Example of GET request
#
#		Get Control-M Servers list
try
{	
	$servers_res = Invoke-RestMethod -Method Get -Uri "$endPoint/config/servers"  -Headers $headers 
	
	"List of control-M servers:"
	$servers_res
}
catch
{
	$error[0].ErrorDetails	
	$error[0].Exception.Response.StatusCode
}

#----------------------------------------------------------------
#  Example of GET request
#
#		Get Control-M Server agents from first server
$controlm=$servers_res[0].name
try
{	
	$server_agents_res = Invoke-RestMethod -Method Get -Uri "$endPoint/config/server/$controlm/agents"  -Headers $headers 
	
	"List of Agents connected to control-M server '$controlm':"
	$server_agents_res
}
catch
{
	$error[0].ErrorDetails	
	$error[0].Exception.Response.StatusCode	
}


#----------------------------------------------------------------
#  Example of POST request
#
#		Adding host to hostgroup in a Control-M Server
#
$hostgroup="mygroup1"
$agenthost="myhost1"

$add_host_data = @{	host = "$agenthost"; }

try
{	
	"Adding host '$agenthost' to hostgroup '$hostgroup':"
	
	$uri="$endpoint/config/server/$controlm/hostgroup/$hostgroup/agent"
	$add_to_hostgroup_res = Invoke-RestMethod -Method Post -Uri "$uri"  -Body (ConvertTo-Json $add_host_data) -ContentType "application/json"  -Headers $headers 
	
	$add_to_hostgroup_res 
}
catch
{
	$error[0].ErrorDetails
	
	$error[0].Exception.Response.StatusCode
}

#----------------------------------------------------------------
#  Example of Uploading a file request
#
#	Using the build to make sure that we have a valid source code
#
$uri="$endPoint/build"

$FileName="AutomationAPISampleFlow.json"
$FilePath="c:\src\ctm-cli-v2\samples\$FileName"

$fileBin = [System.IO.File]::ReadAllBytes($FilePath)
$enc = [System.Text.Encoding]::GetEncoding($CODEPAGE)
$fileEnc = $enc.GetString($fileBin)
$boundary = [System.Guid]::NewGuid().ToString()
$LF = "`r`n"
$bodyLines = (
        "--$boundary",
        "Content-Disposition: form-data; name=`"definitionsFile`"; filename=`"$FileName`"",
		"Content-Type: application/octet-stream$LF",
        $fileEnc,
        "--$boundary--$LF"
     ) -join $LF
Try
{
	$res = Invoke-RestMethod -Uri $uri -Method Post -Body $bodyLines  -ContentType "multipart/form-data; boundary=`"$boundary`""   -Headers $headers 

	$res
}
Catch {
	$error[0].ErrorDetails
	
	$error[0].Exception.Response.StatusCode
}


#----------------------------------------------------------------
#  Example of Logout
#
#
try
{	
	$res = Invoke-RestMethod -Method Post -Uri "$endPoint/session/logout"  -Headers $headers 
	$res
}
catch
{
	$error[0].ErrorDetails
	
	$error[0].Exception.Response.StatusCode
}
