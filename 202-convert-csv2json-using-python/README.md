# Convert CSV to JSON using Python
Python script example on how to convert from a CSV file to Control-M Automation API JSON definition file.


### - Getting Started
* Install
    - download and install Python 2.7, https://www.python.org/downloads/
    - install Python dictobj: 
        ```pip install dictobj```  (from the python/scripts directory)
        
* Convert to output.json file
    ```
    Python aapi_csv2json.py input.csv > output.json
    ```

* Convert and deploy to Control-M
    ```
    Python aapi_csv2json.py input.csv > output.json && ctm deploy output.json
    ```

### - Getting more out of it
You can also modify the Python script in order to achieve greater flexibility with your CSV format or support additional JSON properties.
#### 1. Example of adding Job Priority field to CSV
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
##### b. Inside the method `create_job_obj` create and assign to a new field called `job_fileds.Priority' the value from the csv_row object, which represent the row from the CSV file by using the `priority_key` we defined previous step.
```python
# optional fields
if csv_row[priority_key]: job_fields.Priority = csv_row[priority_key]  # the new field
if csv_row[description_key]: job_fields.Description = csv_row[description_key]
if csv_row[host_key]: job_fields.Host = csv_row[host_key]
if csv_row[application_key]: job_fields.Application =     csv_row[application_key]
if csv_row[sub_application_key]: job_fields.SubApplication = csv_row[sub_application_key]
```
#### 2. Example of adding Months to When Object (Months is array type)
Assumption: your month value in the CSV will look like this: `JAN;OCT;DEC`

##### a. Follow step 1a. and create your column key identifier for months.

##### b. Under `create_when_object` method read the value and split it into Python array by your chosen character.
```python
def create_when_object(csv_row):
...
# get When months
raw_job_months = csv_row[months_key] # get months value from CSV (for example:JAN;OCT;DEC)
    if not raw_job_months:
        return
event_fields.Events = raw_job_months.split(";")
...
```
#### 3. Manipulate other JSON objects
Just follow the methods in the script for example `create_folder_obj` will help you to add more fields to a folder such as `Application`
