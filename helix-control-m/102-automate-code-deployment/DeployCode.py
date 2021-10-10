import requests  # pip install requests if you don't have it already
import urllib3

urllib3.disable_warnings() # disable warnings when creating unverified requests 
  
endPoint = 'https://<controlmEndPointHost>/automation-api'
token=<token>
  
# -----------------
# Built
uploaded_files = [
        ('definitionsFile', ('Jobs.json', open('c:\\src\Jobs.json', 'rb'), 'application/json'))
]
  
r = requests.post(endPoint + '/deploy', files=uploaded_files, headers={'x-api-key': + token}, verify=False)
  
print(r.content)
print(r.status_code)
  
exit(r.status_code == requests.codes.ok)
