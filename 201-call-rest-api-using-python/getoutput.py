#!/usr/bin/python

import json
import requests
import argparse
from getpass import getpass
try:
    from requests.packages.urllib3.exceptions import InsecureRequestWarning
except:
    from urllib3.exceptions import InsecureRequestWarning
    import urllib3

parser = argparse.ArgumentParser(description='Connect to Control-M/Enterprise Manager via Automation API REST calls and display job outputs',add_help=False)
parser.add_argument('-u', '--username', dest='username', type=str, help='Username to login to Control-M/Enterprise Manager')
parser.add_argument('-p', '--password', dest='password', type=str, help='Passowrd to login to Control-M/Enterprise Manager')
parser.add_argument('-h', '--host', dest='host', type=str, help='Control-M/Enterprise Manager hostname')
parser.add_argument('-i', '--insecure', dest='insecure', action='store_const', const=True, help='Disable SSL Certification Verification')
parser.add_argument('-v', '--verbose', dest='verbose', action='store_const', const=True, help='Turn on verbose mode')
parser.add_argument("--help", action="help", help="show this help message and exit")

args = parser.parse_args()

verbose = args.verbose
insecure = args.insecure

if insecure:
    if verbose:
        print('Disabling SSL Cert verification')
    try:
        requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
    except:
        urllib3.disable_warnings(InsecureRequestWarning)
    verify_certs=False
else:
    verify_certs=True

host = args.host
if host == None:
    host = raw_input("EM Hostname: ")
username = args.username
if username == None:
    username = raw_input("EM username: ")
password = args.password
if password == None:
    password = getpass("Passowrd: ")
baseurl = 'https://'+host+':8443/automation-api/'

if verbose:
    print('base URL: '+baseurl)

loginurl =baseurl+'session/login'
body =json.loads('{ "password": "'+password+'", "username": "'+username+'"}')
try:
    r = requests.post(loginurl, json=body, verify=verify_certs)
except requests.exceptions.ConnectTimeout as err:
    print("Connecting to Automation API REST Server failed with error: " + str(err))
    quit(1)
except requests.exceptions.ConnectionError as err:
    print("Connecting to Automation API REST Server failed with error: "+str(err))
    if 'CERTIFICATE_VERIFY_FAILED' in str(err.message):
        print('INFO: If using a Self Signed Certificate use the -i flag to disable cert verification or add the certificate to this systems trusted CA store')
    quit(1)
except requests.exceptions.HTTPError as err:
    print("Connecting to Automation API REST Server failed with error: "+str(err))
    quit(1)
except:
    print("Connecting to Automation API REST Server failed with error unknown error")
    quit(1)

if verbose:
    print(r.text)
    print(r.status_code)

loginresponce = json.loads(r.text)
if 'errors' in loginresponce:
    print(json.dumps(loginresponce['errors'][0]['message']))
    quit(1)

if 'token' in loginresponce:
    token = json.loads(r.text)['token']
else:
    print("Failed to get token for unknown reason, exiting...")
    quit(2)

if verbose:
    print('Token: '+token)

jobstatusurl =baseurl+'run/jobs/status?token='+token

if verbose:
    print('Job Status URL: '+jobstatusurl)

r2 = requests.get(jobstatusurl, verify=verify_certs)

if 'statuses' in json.loads(r2.text):
    statuses = json.loads(r2.text)['statuses']
else:
    print('No job statuses were loaded.')
    quit(0)

if verbose:
    print('statuses:\n'+json.dumps(statuses))

length = len(json.loads(r2.text)['statuses'])

if verbose:
    print('length: '+str(length))

x = 0
while x < length:
    print(str(x)+'. '+statuses[x]['jobId']+', '+statuses[x]['name']+', '+statuses[x]['status']+', '+statuses[x]['type'])
    x +=1


selected = int(input("Enter the it's output to view: "))

if selected > length:
    print('That does not exist')
    quit(1)

outputurl = statuses[selected]['outputURI']

if verbose:
    print(outputurl)

r3 = requests.get(outputurl, verify=verify_certs)
print(r3.text)
#x = 0
#while x < length:
#    if verbose:
#        print('Job ' + str(x) +' of ' + length + ' in in responce: ')
#    jsonobject = json.loads(r2.text)
#    if jsonobject['statuses'][x]['type'] == 'Command':
#        outputurl = jsonobject['statuses'][x]['outputURI']
#        print(outputurl)
#        r3 = requests.get(outputurl, verify=verify_certs)
#        print(r3.text)
#    x += 1