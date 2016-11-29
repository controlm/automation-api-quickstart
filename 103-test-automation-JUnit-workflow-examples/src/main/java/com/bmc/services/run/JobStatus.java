package com.bmc.services.run;


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
	public static JobStatus toJobStatus(String jobStatus){
		for (JobStatus s : JobStatus.values() ){
			if (s.getStatusVal().equals(jobStatus)){
				return s;
			}
		}
		return null;
	}
	
	public static final JobStatus[] ENDED_STATUSES = {ENDED_OK, ENDED_NOT_OK, STATUS_UNKNOWN};
	
}
