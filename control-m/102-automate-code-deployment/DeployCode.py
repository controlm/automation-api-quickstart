import requests  # pip install requests if you don't have it already
  
endPoint = 'http://<controlMEndPoint>:8443/automation-api'
  
user = '<ControlMUser>'
passwd = '<ControlMPassword>'
  
# -----------------
# login
r_login = requests.post(endPoint + '/session/login', json={"username": user, "password": passwd})
print(r_login.content)
print(r_login.status_code)
if r_login.status_code != requests.codes.ok:
    exit(1)
  
token = r_login.json()['token']
  
# -----------------
# Built
uploaded_files = [
        ('definitionsFile', ('Jobs.json', open('c:\\src\ctmdk\Jobs.json', 'rb'), 'application/json'))
]
  
r = requests.post(endPoint + '/deploy', files=uploaded_files, headers={'Authorization': 'Bearer ' + token})
  
print(r.content)
print(r.status_code)
  
exit(r.status_code == requests.codes.ok)
