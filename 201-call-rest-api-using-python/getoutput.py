#!/usr/bin/python

import collections
import json
import requests
import argparse
import sys
from getpass import getpass

try:
    from requests.packages.urllib3.exceptions import InsecureRequestWarning
except:
    from urllib3.exceptions import InsecureRequestWarning
    import urllib3

verbose = False
verify_certs = True


def parse_inputs():
    parser = argparse.ArgumentParser(
        description='Connect to Control-M/Enterprise Manager via Automation API REST calls and display job outputs',
        add_help=False)
    parser.add_argument('-u', '--username', dest='username', type=str,
                        help='Username to login to Control-M/Enterprise Manager')
    parser.add_argument('-p', '--password', dest='password', type=str,
                        help='Password to login to Control-M/Enterprise Manager')
    parser.add_argument('-h', '--host', dest='host', type=str, help='Control-M/Enterprise Manager hostname')
    parser.add_argument('-i', '--insecure', dest='insecure', action='store_const', const=True,
                        help='Disable SSL Certification Verification')
    parser.add_argument('-v', '--verbose', dest='verbose', action='store_const', const=True,
                        help='Turn on verbose mode')
    parser.add_argument("--help", action="help", help="show this help message and exit")

    args = parser.parse_args()

    global verbose
    global verify_certs

    verbose = args.verbose
    insecure = args.insecure

    if insecure:  # Use insecure to disable verifing SSL Cert on server useful becuase Automation API will use a selfsigned cert by default
        if verbose:
            print('Disabling SSL Cert verification')
        try:
            requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
        except:
            urllib3.disable_warnings(InsecureRequestWarning)
        verify_certs = False
    else:
        verify_certs = True

    host = args.host
    if host == None:
        host = input("EM Hostname: ")
    username = args.username
    if username == None:
        username = input("EM username: ")
    password = args.password
    if password == None:
        try:
            password = getpass("Passowrd: ",
                           sys.stderr)  # getpass has an issue using /dev/tty as the stream (second argument) using sys.stderr is the alternative, this argument is ignored on windows
        except:
            password = input("Password: ") # adding try & execpt block to fail back to input encase getpass encounters an error

    baseurl = 'https://' + host + ':8443/automation-api/'  # Control-M Automation API v2 (EM 9 FP3) base url
    login_args = collections.namedtuple('Login_Args', ['baseurl', 'username', 'password'])
    auth = login_args(baseurl, username, password)
    return auth  # return auth info as named tuple


def login(auth):
    global verbose
    baseurl = auth.baseurl
    username = auth.username
    password = auth.password

    if verbose:
        print('base URL: ' + baseurl)

    loginurl = baseurl + 'session/login'  # The login url
    body = json.loads(
        '{ "password": "' + password + '", "username": "' + username + '"}')  # create a json object to use as the body of the post to the login url
    try:
        r = requests.post(loginurl, json=body, verify=verify_certs)
    except requests.exceptions.ConnectTimeout as err:
        print("Connecting to Automation API REST Server failed with error: " + str(err))
        quit(1)
    except requests.exceptions.SSLError as err:
        print("Connecting to Automation API REST Server failed with error: " + str(err))
        print('INFO: If using a Self Signed Certificate use the -i flag to disable cert verification or add the certificate to this systems trusted CA store')
        quit(1)
    except requests.exceptions.HTTPError as err:
        print("Connecting to Automation API REST Server failed with error: " + str(err))
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

    if 'token' in loginresponce:  # If token exists in the json response set the value to the variable token
        token = json.loads(r.text)['token']
    else:
        print("Failed to get token for unknown reason, exiting...")
        quit(2)

    if verbose:
        print('Token: ' + token)

    return token  # return the token


def list_jobs(token, baseurl):
    global verbose
    jobstatusurl = baseurl + 'run/jobs/status'  # url to list statuses of all the jobs in the AJF

    data = json.loads(
        '{"Authorization": "Bearer ' + token + '"}')  # the jobs statues call should have the token in the header as JSON

    if verbose:
        print('Job Status URL: ' + jobstatusurl)
        print('Job Status Header: ' + json.dumps(data))

    r2 = requests.get(jobstatusurl, headers=data,
                      verify=verify_certs)  # do a get on the job status url returns json with all of the job status

    if 'statuses' in json.loads(r2.text):  # if statuses exsits in json response store the statuses to variable statuses
        statuses = json.loads(r2.text)['statuses']
    else:
        print(
        'No job statuses were loaded.')  # if statuses does not exist, report it. this can happen if no jobs are in the AJF
        logout(token, baseurl, 0)  # or if you've added a filter to the job statues url that has no results

    if verbose:
        print('statuses:\n' + json.dumps(statuses))

    length = len(json.loads(r2.text)['statuses'])  # check how many jobs are in statuses

    if verbose:
        print('length: ' + str(length))
    while True:
        x = 0
        while x < length:  # iterate though statuses
            # contents of python json objects can be accessed like named tupel for key value pairs and arrays for repeated objects
            # the end result is similar to jsonpath expressions statuses[3]['jobId'] is equivalent to 3.jobId, you can test and learn about jsonpath expressions here: https://jsonpath.curiousconcept.com/
            print(
            str(x) + '. ' + statuses[x]['jobId'] + ', ' + statuses[x]['name'] + ', ' + statuses[x]['status'] + ', ' +
            statuses[x]['type'])
            x += 1

        selected = input("Enter a number to see it's output, or q to quit: ")

        if selected == 'q':
            logout(token, baseurl)
        try:
            selected = int(selected)
            outputurl = statuses[selected]['outputURI']  # get the outputURI from the select job in statuses
            print_output(outputurl, data)
        except TypeError:
            print("Please enter either a number or q to quit")
        except ValueError:
            print("Please enter either a number or q to quit")
        except IndexError:
            print('That does not exist')


def print_output(outputurl, data):
    global verbose
    if verbose:
        print(outputurl)

    r3 = requests.get(outputurl, headers=data,
                      verify=verify_certs)  # go a get on the outputURI, outputURI already includes the current token
    print(r3.text)  # this request returns the raw text output of the job and not json


def logout(token, baseurl,
           exit=0):  # if logged in, need to call logout before quiting to invalidate the token for security
    # this prevents the chance of intercepting a token and being reused later
    global verbose
    global username
    logouturl = baseurl + 'session/logout'  # Automation API logout url
    # logouturl = baseurl + 'session/logout?token=' + token # Automation API logout url

    if verbose:
        print('Logout URL: ' + logouturl)

    body = json.loads(
        '{ "token": "' + token + '", "username": "' + username + '"}')  # logout url needs json with the token and username

    r4 = requests.post(logouturl, data=body,
                       verify=verify_certs)  # a post on this url invalidates the token with the above json as the post data
    if verbose:
        print(r4.headers)

    if verbose:
        print(r4.text)

    quit(exit)


args = parse_inputs()
username = args.username
tok = login(args)
list_jobs(tok, args.baseurl)
