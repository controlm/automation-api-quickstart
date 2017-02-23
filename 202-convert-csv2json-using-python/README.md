# convert csv to json using python
A python script for converting Control-M jobs defined in a csv file into Automation-Api json definition file.


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

### - Modifying the script
There are cases where you will want to modify the script in order to achieve flexibility lty with your csv format or support new json properties.
#### 1. Adding new property to an object.
For example let's say you want to add a new column to your csv file called "Job Prio" reflected in the json as `Priority` property under Job.
* In the code create a new key identifier variable assigned with `Job Prio` under `#job keys` section.
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
* Inside the method `create_job_obj` create and assign to a new field called `job_fileds.Priority' the value from the csv_row object which represent the row from the csv file by using the priority key we defined previous step.
```python
# optional fields
if csv_row[Priority]: job_fields.Description = csv_row[priority_key]  # the new field
if csv_row[description_key]: job_fields.Description = csv_row[description_key]
if csv_row[host_key]: job_fields.Host = csv_row[host_key]
if csv_row[application_key]: job_fields.Application =     csv_row[application_key]
if csv_row[sub_application_key]: job_fields.SubApplication = csv_row[sub_application_key]
```
* (optinal) Incase your csv contains array of values like for example Months of When object. You will have to split the array by your custom character and assign it as python array. in this example the seperator char is ";"
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
#### 2. changing column name
* The key identifier variable should be renamed
from:
    ```
    priority_key = "job prio"
    ```
    To:

    ```
    priority_key = "JobPriority"
    ```

#### 3. Deleting a field
* The key identifier variable should be deleted
```
priority_key = "job prio"
```
* New field Assignment should be deleted
```
if csv_row[Priority]: job_fields.Description = csv_row[priority_key]  # the new field
```

