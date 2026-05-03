## How to invoke automation api REST calls using crul in a linux bash script
calling_automation_api_using_curl.sh contain example for differant api invocations such as Get Control-M Servers list and others

```bash
#!/bin/bash
 
endpoint=                                                        # HTTP end point in the format of https://<controlmEndPoint>:8443/automation-api
user=                                                            # Set this variable to Controlm-M user credentials
password=                                                        # Set this variable to Controlm-M user credentials
curl_params=-k                                                   # Out Of the Box the end point comes with self signed certificate, -k option accept such certificates
 
# Session Login and get access API session token
login=$(curl $curl_params -H "Content-Type: application/json" -X POST -d "{\"username\":\"$user\",\"password\":\"$password\"}"   "$endpoint/session/login" )
echo $login

token=$(echo ${login##*token\" : \"} | cut -d '"' -f 1)
echo token=$token

curl $curl_params -H "Authorization: Bearer $token" "$endpoint/config/servers"                      # Get list of servers


# Session Logout to invalidate API session token
curl $curl_params -H "Authorization: Bearer $token" -X POST  "$endpoint/session/logout"
```

See the [Automation API - Services](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Services) documentation for more information.  
See the [Automation API - Code Reference](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Code+Reference) documentation for more information.
