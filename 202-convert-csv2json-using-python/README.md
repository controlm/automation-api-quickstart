# Convert csv to json using python
Python script example on how to convert from a csv file to Control-M Automation-Api json definition file.


### - Getting Started
* Install
    - download and install python 2.7, https://www.python.org/downloads/
    - install python dictobj:
        ```
        pip install dictobj
        ```

* Convert
    ```
    python aapi_csv2json.py input_sample.csv
    ```

* Convert and deploy to Control-M
    ```
    python aapi_csv2json.py input_sample.csv > jobs.json && ctm deploy jobs.json
    ```

### - Getting more out of it
There are cases where you will want to modify the script in order to achieve flexibility with your csv format or support new json properties.
#### 1. Example of adding Job Priority field to csv
Assumption: "Job Prio" is the column header.

##### a. In the code create a new column key identifier variable assigned with `Job Prio` under `#job keys` section.
```python
# job keys
priority_key = "job prio"  # the new key identifier
job_name_key = "Job Name"
description_key = "Description"
command_key = "Command"
host_key = "Host Group"
run_as_key = "Run As"
application_key = "Application"
sub_application_key = "Sub Application"
```
##### b. Inside the method `create_job_obj` create and assign to a new field called `job_fileds.Priority' the value from the csv_row object which represent the row from the csv file by using the priority key we defined previous step.
```python
# optional fields
if csv_row[Priority]: job_fields.Priority = csv_row[priority_key]  # the new field
if csv_row[description_key]: job_fields.Description = csv_row[description_key]
if csv_row[host_key]: job_fields.Host = csv_row[host_key]
if csv_row[application_key]: job_fields.Application =     csv_row[application_key]
if csv_row[sub_application_key]: job_fields.SubApplication = csv_row[sub_application_key]
```
#### 2. Example of adding Months to When Object (Months is array type)
Assumption: your month value in the csv will look like this: `JAN;OCT;DEC`

##### a. Follow step 1a. and create your column key identifier for months.

##### b. Under `create_when_object` method read the value and split it into python array by your chosen character.
```python
def create_when_object(csv_row):
...
# get When months
raw_job_months = csv_row[months_key] # get months value from csv (for example:JAN;OCT;DEC)
    if not raw_job_months:
        return
event_fields.Events = raw_job_months.split(";")
...
```
#### 2. Manipulate other json objects
Just follow the methods in the script for example `create_folder_obj` will help you to add more fields to a folder such as `Application`
