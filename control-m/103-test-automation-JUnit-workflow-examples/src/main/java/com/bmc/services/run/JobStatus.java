package com.bmc.services.run;

/**
 * Enumeration representing job status 
 * (We don't want to use none type safe strings) 
 * @author ybergman
 *
 */
public enum JobStatus {
	ENDED_OK("Ended OK"),
	ENDED_NOT_OK("Ended Not OK"),
	WAIT_USER("Wait User"),
	WAIT_RESOURCE("Wait Resource"),
	WAIT_HOST("Wait Host"),
	WAIT_WORKLOAD("Wait Workload"),
	WAIT_CONDITION("Wait Condition"),
	EXECUTING("Executing"),
	STATUS_UNKNOWN("Status Unknown");

	private String status;
	
	JobStatus(String sts){
		status = sts;
	}
	private String getStatusVal() {
		return status;
	}
	
	/**
	 * Get the correlated enumeration for the given string (or null)
	 * @param jobStatus - job status string
	 * @return - the right enumeration or null if the string is not a valid status string
	 */
	public static JobStatus toJobStatus(String jobStatus){
		for (JobStatus s : JobStatus.values() ){
			if (s.getStatusVal().equals(jobStatus)){
				return s;
			}
		}
		return null;
	}
	
	/**
	 * Job that ended are in one of the following statuses
	 */
	public static final JobStatus[] ENDED_STATUSES = {ENDED_OK, ENDED_NOT_OK, STATUS_UNKNOWN};
	
}
