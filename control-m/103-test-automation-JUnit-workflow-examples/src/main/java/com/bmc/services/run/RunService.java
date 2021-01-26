package com.bmc.services.run;

import java.io.File;
import java.util.Arrays;
import java.util.concurrent.TimeoutException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.bmc.services.communication.Connection;

import io.swagger.client.ApiException;
import io.swagger.client.api.RunApi;
import io.swagger.client.model.JobRunStatus;
import io.swagger.client.model.JobStatusResult;
import io.swagger.client.model.RunResult;
/**
 * A service class that manage the RUN operations (cli: ctm run) such as:
 * this.runJobs (json file) - order jobs
 * this.waitForJobsToEnd (timeout) - wait for all the jobs in the current run to end
 * this.waitForJobToEnd (specific job, timeout) - wait for specific job to end
 * this.isJobStatus(specific job, status[]) - is job in certain status(es)
 * this.confirm (specific job) - a wrapper for one of the many run operations  
 *   
 * Usage example:  
 *		Order file 3JobsFlow.json and wait for 15 seconds for a specific job (name "FirstJobOk") to ended successfully.
 *		Assert the result.
 *		
 *		boolean endedOk = rs.runJobs(new File("3JobsFlow.json")).waitForJobToEnd("FirstJobOk", 15*1000).isJobStatus("FirstJobOk", JobStatus.ENDED_OK);
 *		Assert.assertTrue("job 3JobsFlow didn't end successfully as expected", endedOk);

 * 		(note that you can still get exceptions)
 * 
 * @author ybergman
 *
 */
public class RunService {
	private static final Logger logger = LoggerFactory.getLogger(RunService.class.getName());

	/**
	 * internal interface to pass lambda expression as parameter
	 * @author ybergman
	 *
	 */
	interface IsEndedInterface {
		public Boolean isEnded(String name) throws ApiException;
	}
	
	private static final int DELAY_IN_SEC= Integer.parseInt(System.getProperty("DELAY_BETWEEN_JOB_STATUS_CHECK_IN_SEC", "2") );
	/**
	 * {@link Connection} connection to automation api server.
	 */
	Connection conn;		// connection to automation api server
	/**
	 * {@link String} run id of the requested json job definition file (result after run)
	 */
	String runId;			// 

	/**
	 * {@link RunApi} swagger generated client for Run api 
	 * @see http://editor.swagger.io/#/ 
	 */
	RunApi api = new RunApi();
	
	/**
	 * Constructor for using with {@link Connection} class 
	 * @param conn
	 */
	public RunService (Connection conn){
		setConnection(conn);
	}

	private void setConnection(Connection conn) {
		this.conn = conn;
		api.setApiClient(conn.getApiClient() );
	}

	public String getRunId() {
		return runId;
	}

	/**
	 * Order jobs using job definition file
	 * 
	 * @param definitionsFile - json job definition file
	 * @return this instance
	 * @throws ApiException - internal error, check message for more info
	 */
	public RunService runJobs (File definitionsFile, File deployDescriptorFile) throws ApiException{
		conn.validateConnection();
		logger.debug("running job file {}", definitionsFile.getAbsolutePath() );
		
		RunResult res = api.runJobs(definitionsFile, deployDescriptorFile, null) ;
		logger.debug("result of running job file {}: {}", definitionsFile.getAbsolutePath(), res );
		runId = res.getRunId();
		// wait to make sure the job was ordered, otherwise we might ask from status before the job was processed (and executed)
		sleep(5);
		return this;
	}
	
	/**
	 * overloading runJobs without deploy descriptor file
	 * @param definitionsFile
	 * @return this instance
	 * @throws ApiException
	 */
	public RunService runJobs (File definitionsFile) throws ApiException{
		return runJobs(definitionsFile, null);
	}

	/**
	 * Wait for the job(s) to end. The check is made every 2sec interval (may be change by of starting the jvm with -DDELAY_BETWEEN_JOB_STATUS_CHECK_IN_SEC=x)
	 * Job execution end status in one of the following statuses: Ended OK, Ended Not OK, Status Unknown 
	 * @see com.bmc.services.run#JobStatus
	 * 
	 * @param timeout - timeout to wait in milliseconds  
	 * @return this instance
	 * @throws ApiException - internal error, check message for more info
	 * @throws TimeoutException - an exception in case of the timeout occurred
	 */
	private RunService waitToEnd (long timeout, IsEndedInterface isEndedInt, String field) throws ApiException, TimeoutException{
		conn.validateConnection();
		if (runId == null) throw new ApiException("there are no jobs to wait since runId is null");
		
		logger.debug("waiting for run/job to end, timeout {}millisec", runId, timeout);
		
		long startTime = System.currentTimeMillis();
		Boolean ended = isEndedInt.isEnded(field); // can be change to isJobEnded(jobName) or areAllJobsEnded(), was done to allow 1 wait algorithm 
		while (!ended && System.currentTimeMillis()-startTime <= timeout){
			logger.debug("waiting for {}sec to check job(s) status again", DELAY_IN_SEC);
			try {
				Thread.sleep(DELAY_IN_SEC*1000);
			} catch (InterruptedException e) {
				logger.debug("sleep (delay) was interrupted");
			}
			ended = isEndedInt.isEnded(field); // <- can be change to isJobEnded(jobName) or areAllJobsEnded(), was done to allow 1 wait algorithm
		} 
		if (!ended){
			logger.warn("timeout, waiting for job(s) to end exceed timeout {}", timeout);
			throw new TimeoutException("waiting for jobs to end exceed timeout " + timeout);
		}

		logger.debug ("job(s) ended");
		return this;
	}	
	
	/**
	 * Wait for specific job in the current runId to end 
	 * @param jobName - the job name
	 * @param timeout - timeout in milliseconds
	 * @return - this instance
	 * @throws ApiException - internal error, check message for more info
	 * @throws TimeoutException - an exception in case of the timeout occurred 
	 */
	public RunService waitForJobToEnd(String jobName, long timeout) throws ApiException, TimeoutException{
		RunService isEndedOper = waitToEnd(timeout, isEnded -> isJobEnded(jobName), jobName);
		return isEndedOper;
	}

	/**
	 * Wait for all the jobs in the current runId to end 
	 * @param timeout - timeout in milliseconds
	 * @return - this instance
	 * @throws ApiException - internal error, check message for more info
	 * @throws TimeoutException - an exception in case of the timeout occurred 
	 */
	public RunService waitForJobsToEnd(long timeout) throws ApiException, TimeoutException{
		RunService isEndedOper = waitToEnd(timeout, isEnded -> areAllJobsEnded(null), null);
		return isEndedOper;
	}
	
	/**
	 * Dummy method to implement IsEndedInterface interface, act as a tunnel calling areAllJobsEnded()
	 * @param dummy - ignored
	 * @return - this instance
	 * @throws ApiException - internal error, check message for more info
	 */
	private Boolean areAllJobsEnded(String dummy) throws ApiException {
		return areAllJobsEnded();
	}

	/**
	 * Check if all the jobs in the current runId ended 
	 * @return this instance
	 * @throws ApiException - internal error, check message for more info
	 */
	public Boolean areAllJobsEnded() throws ApiException {
		return areAllJobsInStatus(JobStatus.ENDED_STATUSES );
	}

	/**
	 * Check if specific job in the current runId ended 
	 * @param jobName - the job name (need to be one of the jobs in the current runId)
	 * @return this instance
	 * @throws ApiException - internal error, check message for more info
	 */
	public boolean isJobEnded(String jobName) throws ApiException {
		JobRunStatus jobDetails = getJobDetailsByName(jobName);
		if (jobDetails == null) throw new ApiException("job name " + jobName + " not found in runId " + runId);
		
		return Arrays.asList(JobStatus.ENDED_STATUSES).contains(JobStatus.toJobStatus(jobDetails.getStatus() ) );
	}
	
	/**
	 * Get the job details of a job in the current runId
	 * @param jobName - job name  
	 * @return - return
	 * @throws ApiException
	 */
	private JobRunStatus getJobDetailsByName(String jobName) throws ApiException {
		JobStatusResult jList = api.getJobsStatus(runId, 0L);
		for (JobRunStatus js : jList.getStatuses() ){
 			logger.trace("checking job {}, name {}", js.getJobId(), js.getName() );
			if (js.getName().equals(jobName) && !"Folder".equals(js.getType()) ){
				return js;
			}
		}
		return null;
	}

	
	
	
	/**
	 * Check if all the jobs (in this.runId) ended 
	 * @return this instance
	 * @throws ApiException - internal error, check message for more info
	 */
	public boolean areAllJobsEndedSuccessfully() throws ApiException{
		conn.validateConnection();
		return areAllJobsInStatus(JobStatus.ENDED_OK);
	}	

	public boolean areAllJobsInStatus(JobStatus... givenStatuses) throws ApiException{
		if (runId == null) throw new ApiException("there are no jobs to check since runId is null");

		JobStatusResult  jobs = api.getJobsStatus(runId, 0L);
		logger.debug ("there are {} jobs to check", jobs.getTotal() ); 

		for (JobRunStatus currJob : jobs.getStatuses() ){
			if (!Arrays.asList(givenStatuses).contains(JobStatus.toJobStatus(currJob.getStatus() ) ) ) {
				logger.debug ("job {} is not in one of the status:{} (status=" + currJob.getStatus() +")", currJob.getName(), givenStatuses ); 
				return false;
			}
		}
		logger.debug ("all {} jobs are in status {}", jobs.getTotal(),  givenStatuses ); 
		return true;
	}
	
	public boolean isJobStatus(String jobName, JobStatus ...statuses) throws ApiException{
		if (runId == null) throw new ApiException("there are no jobs to check since runId is null");

		JobRunStatus  job = getJobDetailsByName(jobName);
		logger.debug ("job {} details: {}", job.getName(), job); 

		return Arrays.asList(statuses).contains(JobStatus.toJobStatus(job.getStatus() ) );
	}

	public void confirm(String jobName) throws ApiException{
		if (runId == null) throw new ApiException("there are no jobs to confirm since runId is null");

		JobRunStatus  job = getJobDetailsByName(jobName);
		if (job==null) {
			logger.warn("job {} not found in runId {}", jobName, runId);
			new ApiException("job " + jobName + " not found in runId " + runId);
		}
		logger.debug ("job to confirm {} details: {}", job.getName(), job);
		api.confirmJob(job.getJobId());
	}
	
	
	private RunService sleep(int i) {
		try {
			Thread.sleep(i*1000);
		} catch (InterruptedException e) {
		}
		return this;
	}
	
}
