package com.bmc.services.communication;

import java.io.File;
import java.net.MalformedURLException;
import java.net.URISyntaxException;
import java.net.URL;
import java.util.concurrent.TimeoutException;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import com.bmc.services.run.JobStatus;
import com.bmc.services.run.RunService;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import io.swagger.client.ApiException;
import junit.framework.Assert;


public class TestAuthomationApiJUnitExamples {
	private static final Logger logger = LoggerFactory.getLogger(TestAuthomationApiJUnitExamples.class.getName());
	
	// TODO: change those parameter before build to hold your own configuration !!
	private final static String AUTOMATION_API_ENDPOINT = "<end point url>";
	private final static String USER = "<user>";
	private final static String PASS = "<password>";

	
	Connection  conn;
	File		endedOkJob;
	File		endedNotOkJob;
	File		twoMinJob;
	RunService 	rs;
	
	@Before
	public void connect() throws URISyntaxException, MalformedURLException, ApiException{
		Assert.assertFalse("you must update USER, PASS and AUTOMATION_API_ENDPOINT in this class", "<user>".equals(USER) );

		endedOkJob    = getJsonDefinitionFile("/JobEndedOk.json");
		endedNotOkJob = getJsonDefinitionFile("/JobEndedNotOk.json");
		twoMinJob =     getJsonDefinitionFile("/TwoMinJob.json");
		conn = new Connection(AUTOMATION_API_ENDPOINT);
		// NOTE: Do NOT set to false in production code.
		conn.getApiClient().setVerifyingSsl(false);
		conn.login(USER, PASS);
		rs = new RunService(conn);
	}

	@After
	public void disconnect() throws ApiException {
		if (conn != null && conn.isLogin()){
			conn.logout();
		}
	}
	
	/**
	 * is specific job ended within 15 seconds
	 * @throws ApiException
	 * @throws TimeoutException 
	 */
	@Test
	public void testIsJobEndedUsingJobName() throws ApiException, TimeoutException{
			logger.info("start test testIsJobEndedUsingJobName");
			rs.runJobs(endedNotOkJob );
			boolean isEnded = rs.waitForJobToEnd("failJob",15*1000).isJobEnded("failJob");
			Assert.assertTrue(isEnded);
			logger.info("end test testIsJobEndedUsingJobName");
	}	

	/**
	 * is specific job ended with a status "Ended Not Ok" within 15 seconds
	 * @throws ApiException
	 * @throws TimeoutException 
	 */
	@Test
	public void testIsJobStatuEndedNotOkUsingJobName() throws ApiException, TimeoutException{
			logger.info("start test testIsJobStatuEndedNotOkUsingJobName");
			rs.runJobs(endedNotOkJob );
			boolean isEndedWithStatus = rs.waitForJobToEnd("failJob",15*1000).isJobStatus("failJob", JobStatus.ENDED_NOT_OK);
			Assert.assertTrue(isEndedWithStatus);
			logger.info("end test testIsJobStatuEndedNotOkUsingJobName");
	}	
	
	/**
	 * wait for 20sec for job to end - if not, get a timeout exception
	 * @throws ApiException
	 */
	@Test
	public void testJobStillExecuting() throws ApiException {
			logger.info("start test testJobStillExecuting");
			boolean isJobEnded= rs.runJobs(twoMinJob).isJobEnded("twoMinJob");
			Assert.assertFalse(isJobEnded);
			// wait 20sec for the job to end - timeout is thrown
			try{
				rs.waitForJobsToEnd(20);
				throw new ApiException("should never get here, the above wait should throw timeout since the job takes 2min to end");
			}catch (TimeoutException e) {
			}
			logger.info("end test testJobStillExecuting");
	}			
			

	/**
	 * wait 30sec for ALL jobs to end successfully - 
	 * @throws ApiException
	 * @throws TimeoutException
	 */
	@Test
	public void testAreAllJobsEndedSuccessfully() throws ApiException, TimeoutException{
		logger.info("start test testAreAllJobsEndedSuccessfully");
		RunService jobNotOkRun = rs.runJobs(endedOkJob);
		boolean isAllJobsEndedOk = jobNotOkRun.waitForJobsToEnd(30*1000).areAllJobsEndedSuccessfully();
		Assert.assertTrue(isAllJobsEndedOk);
		logger.info("end test testAreAllJobsEndedSuccessfully");
	}

	/**
	 * check the invariants of more than 1 job
	 * 2 specific jobs ended ok, the last on should fail
	 * 
	 * @throws ApiException
	 */
	@Test
	public void testJobFlow() throws ApiException, TimeoutException{
		logger.info("start test testJobFlow");
		boolean jobRunResult;
		// prepare your application's data
		// run jobs
		rs.runJobs(new File("./src/test/resources/3JobsFlow.json"));
		// check if job 1 ended ok
		jobRunResult = rs.waitForJobToEnd("FirstJobOk", 10*1000).isJobStatus("FirstJobOk", JobStatus.ENDED_OK);
		Assert.assertTrue("job FirstJobOk failed", jobRunResult);
		// check your application data - it is ok ?
		// start job 2 (it was define with "confirm" so it waits for manual confirmation)
		rs.confirm("SecondJobOk");
		// check if job 2 ended ok
		jobRunResult = rs.waitForJobToEnd("SecondJobOk", 10*1000).isJobStatus("SecondJobOk", JobStatus.ENDED_OK);
		Assert.assertTrue("job SecondJobOk failed", jobRunResult);
		// check your application's data (the result of job 2)
		// as a result of the data - job 3 should fail - make sure job 3 failed.
		jobRunResult = rs.waitForJobToEnd("ThirdJobNotOk", 10*1000).isJobStatus("ThirdJobNotOk", JobStatus.ENDED_NOT_OK);
		Assert.assertTrue("job ThirdJobNotOk didn't fail as expected", jobRunResult);
		logger.info("end test testJobFlow");
	}
	
	/**
	 * wait for job to be in confirm status and confirm it
	 * 
	 * @throws ApiException
	 * @throws InterruptedException 
	 */
	@Test
	public void testWaitForConfirmation() throws ApiException, TimeoutException, InterruptedException{
		logger.info("start test testWaitForConfirmation");
		rs.runJobs(new File("./src/test/resources/3JobsFlow.json"));
		int timeout = 15*1000;
		long startTime=System.currentTimeMillis();
		
		while(!rs.isJobStatus("SecondJobOk", JobStatus.WAIT_USER)){
			Thread.sleep(2000);
			if (System.currentTimeMillis()-startTime > timeout){
				logger.error("SecondJobOk didn't get to user confirmation status for {}", timeout/1000);
				throw new TimeoutException("SecondJobOk didn't get to user confirmation status for " + timeout/1000 );
			}
		}
		logger.debug("SecondJobOk is waiting for user confirmation");
		rs.confirm("SecondJobOk");
		boolean isEndedOk = rs.waitForJobToEnd("SecondJobOk", timeout).isJobStatus("SecondJobOk", JobStatus.ENDED_OK);
		Assert.assertTrue("job SecondJobOk didn't end ok", isEndedOk);
		logger.info("end test testWaitForConfirmation");
	}
	
	private File getJsonDefinitionFile(String file) throws URISyntaxException{
		URL fileUrl = TestAuthomationApiJUnitExamples.class.getResource(file);
		return new File(fileUrl.toURI());
	}
}
