DISCLAIMER: This code was tested with version 9.0.3

## JUnit Control-M job using the automation api
How to verify control-m workflows runs using JUnit


**AUTOMATION_API_ENDPOINT** - Control-M endpoint   
**USER** - Control-M user account for automation  
**PASSWORD** - Control-M account password for automation  

```java

	@Before
	public void connect() throws URISyntaxException, MalformedURLException, ApiException{
		Assert.assertFalse("you must update USER, PASS and AUTOMATION_API_ENDPOINT in this class", "<user>".equals(USER) );

		conn = new Connection(AUTOMATION_API_ENDPOINT);
		// NOTE: Do NOT set to false in production code.
		conn.getApiClient().setVerifyingSsl(false);
		conn.login(USER, PASS);
		rs = new RunService(conn);
	}
	
	@Test
	public void testIsJobFlowSuccedded() throws ApiException, TimeoutException{
		logger.info("testIsJobFlowSuccedded");
		rs.runJobs("jobflow.json" );
		boolean isEnded = rs.waitForJobToEnd("job1",15*1000).isJobStatus("Job1", JobStatus.ENDED_OK);
		Assert.assertTrue(isEnded);
		logger.info("end test testIsJobEndedUsingJobName");
	}	

		
```

##### Executing this example
1.  Generate a REST client (see next section)
2.  Change the USER, PASS and AUTOMATION_API_ENDPOINT in the code to use your connection parameters
3.  Change the example jobs (.json) in /resource to use your Control-M Server and agent (usually the same of the hostname where Control-M is installed)
2.  Use maven to build this project
Build project using maven from the home directory (where pom.xml reside)
```bash
mvn package 
```
   

##### Generate REST client
The tests using a client classes that been generated from the yaml api description
 
######Download the swagger generator 
```bash
wget http://repo1.maven.org/maven2/io/swagger/swagger-codegen-cli/2.2.1/swagger-codegen-cli-2.2.1.jar -O swagger-codegen-cli.jar
```
######Generate the client 
```bash
java -jar swagger-codegen-cli.jar generate -i <END_POINT>/yaml -l java -o client/
```
* \<END_POINT> automation api server (as shown in "ctm environment show")
* -i yaml location 
* -l generated client programming language
* -o output location

if you have problem getting to the yaml (for example: uncertified SSL connection) consider copy the yaml to your current location

(for more information see [swagger-code project](https://github.com/swagger-api/swagger-codegen))


######Build the client jar
Building the project using maven will add the jar to your local maven repository
```bash
cd client
mvn install
```

#####Execute the sample test
```bash
cd <root project>
mvn test
```

See the [Automation API - Services](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Services) documentation for more information.  
See the [Automation API - Code Reference](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Code+Reference) documentation for more information.
