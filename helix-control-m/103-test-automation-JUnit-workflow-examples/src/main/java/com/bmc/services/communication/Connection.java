package com.bmc.services.communication;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


/**
 * This class is responsible for connecting to to the automation-api server  
 * @author gboham
 *
 */
public class Connection {
	private static final Logger logger = LoggerFactory.getLogger(Connection.class.getName());

	private String apiClientBasePath;
	private String apiKey;

	/**
	 * Connection model c'tor.
	 * @param apiClientBasePath ControlM Helix's AutomationApi endpoint
	 * @param apiKey apiKey token for authentication with ControlM Helix's AutomationApi
	 */
	public Connection(String apiClientBasePath, String apiKey) {
		this.apiClientBasePath = apiClientBasePath;
		this.apiKey = apiKey;
	}

	/**
	 * ApiClientBasePath getter.
	 * @return AutomationApi endpoint
	 */
	public String getApiClientBasePath() {
		return apiClientBasePath;
	}

	/**
	 * apiKey getter.
	 * @return apiKey token
	 */
	public String getApiKey() {
		return apiKey;
	}
}
