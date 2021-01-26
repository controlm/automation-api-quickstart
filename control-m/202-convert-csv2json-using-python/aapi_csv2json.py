#!/usr/bin/python
import sys, getopt
import csv
from operator import itemgetter
from objdict import *
import json

# folder keys
folder_key = "Parent Folder"
controlm_server_key = "Ctm Server"

# job keys
job_name_key = "Job Name"
description_key = "Description"
command_key = "Command"
host_key = "Host Group"
run_as_key = "Run As"
application_key = "Application"
sub_application_key = "Sub Application"

# when keys
from_time_key = "Start Time"
to_time_key = "End Time"

#flow keys
flow_key = "Depends On"

#event keys
event_key = "Wait For Event"


def main(argv):
    input_file = ''
    usage_message = 'Usage: aapi_csv2json.py <input csv file>'
    try:
        input_file = argv[0]
    except IndexError:
        print usage_message
        sys.exit(2)

    # read csv to list of rows
    csv_rows = read_csv(input_file)

    # convert json
    converted_json = convert(csv_rows)

    # dump json output to stdout
    print(json.dumps(converted_json, indent=4))

def convert(csv_rows):
    # create json object
    converted_json = ObjDict()

    # sort list of rows by folder (avoiding collision of folders)
    csv_rows = avoid_folder_collision(csv_rows, folder_key)

    # loop over all rows create folder and jobs
    current_folder_name = ""
    current_folder_object = None
    for row in csv_rows:
        folder_name = row[folder_key]

        # incase a folder already exists in csv move on
        if current_folder_name != folder_name:
            current_folder_name = folder_name
            current_folder_object = create_folder_obj(row)

        job = create_job_obj(row)

        # add job to current created folder
        current_folder_object[current_folder_name].update(job)

        # add flow as a dependency between current job and its ancestor
        if row[flow_key]:
            flows = create_flows(row)
            for flow_object in flows:
                current_folder_object[current_folder_name].update(flow_object)

        # add folder to the converted json
        converted_json.update(current_folder_object)


    return converted_json

def create_flows(csv_row):
    # get job name and its ancestors
    job_name = csv_row[job_name_key]
    raw_job_ancestors = csv_row[flow_key]

    # split ancestors by comma
    job_ancestors = raw_job_ancestors.split(";")
    flows = []
    for ancestor_job in job_ancestors:
        # create folder json fields object
        flow_properties = ObjDict()

        # folder mandatory fields
        flow_properties.Type = "Flow"
        flow_properties.Sequence = [ancestor_job, job_name]

        # create folder json object
        flows.append(ObjDict({ancestor_job+"-TO-"+job_name: flow_properties}))

    return flows

def create_folder_obj(csv_row):
    # create folder json fields object
    folder_fields = ObjDict()

    # folder mandatory fields
    folder_fields.Type = "Folder"

    # optional fields
    if csv_row[controlm_server_key]:
        folder_fields.ControlmServer = csv_row[controlm_server_key]

    # create folder json object
    folder_name = csv_row[folder_key]
    folder = ObjDict({folder_name: folder_fields})

    return folder

def create_job_obj(csv_row):

    # create job json fields object
    job_fields = ObjDict()

    # job mandatory fields
    job_fields.Type = "Job:Command"
    job_fields.Command = csv_row[command_key]
    job_fields.RunAs = csv_row[run_as_key]

    # optional fields
    if csv_row[description_key]:             job_fields.Description = csv_row[description_key]
    if csv_row[host_key]:                    job_fields.Host = csv_row[host_key]
    if csv_row[application_key]:             job_fields.Application = csv_row[application_key]
    if csv_row[sub_application_key]:         job_fields.SubApplication = csv_row[sub_application_key]

    when_object = create_when_object(csv_row)
    if when_object:
        job_fields.update(when_object)

    events_object = create_event_object(csv_row)
    if events_object:
        job_fields.update(events_object)

    # create job json object
    job_name = csv_row[job_name_key]
    job = ObjDict({job_name: job_fields})

    return job

def create_event_object(csv_row):
    # split events by semicolon
    event_fields = ObjDict()
    event_fields.Type = "WaitForEvents"

    # get job events
    raw_job_events = csv_row[event_key]
    if not raw_job_events:
        return

    event_fields.Events = []
    for event in raw_job_events.split(";"):
        eventJson = ObjDict()
        eventJson.Event = event
        event_fields.Events.append(eventJson)


    # create events json object
    job_name = csv_row[job_name_key]
    events = ObjDict({job_name + "-Events": event_fields})
    return events

def create_when_object(csv_row):
    # create job json fields object
    when_fields = ObjDict()

    # optional fields
    if csv_row[from_time_key]:                    when_fields.FromTime = csv_row[from_time_key]
    if csv_row[to_time_key]:                      when_fields.ToTime = csv_row[to_time_key]
    # if needed when properties like Schedule,Months,WeekDays should be added here

    if not len(when_fields):
        return None

    when = ObjDict({"When": when_fields})
    return when

# this help to sort the csv table by folder name so when
# we will create a specific folder only once
def avoid_folder_collision(csv_rows, folder_key):
    return sorted(csv_rows, key=itemgetter(folder_key))


# Read CSV File and store it in a list object
def read_csv(file):
    csv_rows = []
    with open(file) as csvfile:
        reader = csv.DictReader(csvfile)
        title = reader.fieldnames
        for row in reader:
            csv_rows.extend([{title[i]:row[title[i]] for i in range(len(title))}])
    return csv_rows



if __name__ == "__main__":
    main(sys.argv[1:])