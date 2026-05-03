DISCLAIMER: This code was tested with version 9.20.120

## JUnit Control-M job using the automation api
How to verify control-m workflows runs using JUnit


**AUTOMATION_API_ENDPOINT** - Control-M endpoint   
**API_KEY** - Control-M account token for automation  
  

```java

        @Before
        public void setUp() throws URISyntaxException {
            Assert.assertFalse("you must update API_KEY and AUTOMATION_API_ENDPOINT in this class", "<api_key-token>".equals(API_KEY));
    
            endedOkJob = getJsonDefinitionFile("/JobEndedOk.json");
            endedNotOkJob = getJsonDefinitionFile("/JobEndedNotOk.json");
            twoMinJob = getJsonDefinitionFile("/TwoMinJob.json");
            threeJobFlow = getJsonDefinitionFile("/3JobsFlow.json");
    
            conn = new Connection(AUTOMATION_API_ENDPOINT, API_KEY);
            rs = new RunService(conn);
            // NOTE: Do NOT set to false in production code.
            rs.getApiClient().setVerifyingSsl(false);
            }
	
	@Test
	public void testIsJobFlowSuccedded() throws ApiException, TimeoutException{
		logger.info("testIsJobFlowSuccedded");
		rs.runJobs(new File("jobflow.json"));
		boolean isEnded = rs.waitForJobToEnd("job1",15*1000).isJobStatus("Job1", JobStatus.ENDED_OK);
		Assert.assertTrue(isEnded);
		logger.info("end test testIsJobEndedUsingJobName");
	}	

		
```

##### Executing this example
1.  Generate java REST client for automation-api (see next section)
2.  Change the API_KEY and AUTOMATION_API_ENDPOINT in the code to use your connection parameters
3.  Change the example jobs (.json) in test/resources to match your environment Control-M Server and Agent's host (usually the same of the hostname where Control-M is installed)
4.  Uncomment the correct twoMinJob definition, according to your agent's OS type - Windows or Linux /Unix in TestAutomationApiJUnitExamples class (in setUp method)
5.  Use maven to build this project
Build project using maven from the home directory (where pom.xml reside)
```bash
mvn test 
```
   

##### Generate REST client
The tests uses a java client classes generated from the Automation Api [swagger.io](http://swagger.io) yaml specification
The url to the yaml sepecificion is \<AUTOMATION_API_ENDPOINT\>/yaml
```bash
wget <AUTOMATION_API_ENDPOINT>/yaml
```

######Download the swagger code generator 
For more information see [Swagger Code Generator](https://github.com/swagger-api/swagger-codegen)
```bash
wget https://repo1.maven.org/maven2/io/swagger/swagger-codegen-cli/2.2.1/swagger-codegen-cli-2.2.1.jar -O swagger-codegen-cli.jar
```
######Generate the client
```bash
java -jar swagger-codegen-cli.jar generate -i <SWAGGER_YAML_FILE> -l java -o client/
```
* -i yaml location - file downloaded from previous step 
* -l generated client programming language
* -o output location


if you have problem getting to the yaml (for example: uncertified SSL connection) consider copy the yaml to your current location

######Build the client jar
Building the project using maven will add the jar to your local maven repository
```bash
cd client
mvn install
```

#####Execute the sample test
```bash
cd automation-api-quickstart/103-test-automation-JUnit-workflow-examples
mvn test
```

See the [Automation API - Services](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Services) documentation for more information.  
See the [Automation API - Code Reference](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Code+Reference) documentation for more information.
