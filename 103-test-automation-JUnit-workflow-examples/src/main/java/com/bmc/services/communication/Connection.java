package com.bmc.services.communication;

import java.io.InputStream;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import io.swagger.client.ApiClient;
import io.swagger.client.ApiException;
import io.swagger.client.api.SessionApi;
import io.swagger.client.model.LoginCredentials;
import io.swagger.client.model.LoginResult;
import io.swagger.client.model.SuccessData;
/**
 * This class is responsible for connecting to to the automation-api server  
 * @author ybergman
 *
 */
public class Connection {
	private static final Logger logger = LoggerFactory.getLogger(Connection.class.getName());
    private final SessionApi api = new SessionApi();

    /**
     * login result (user and token) 
     */
	private LoginResult loginResult;

	public Connection(String urlStr) {
		setApiClientBasePath(urlStr);
	}
	
	private void setApiClientBasePath(String serverURL) {
		api.getApiClient().setBasePath(serverURL);
	}

	public ApiClient getApiClient(){
		return api.getApiClient();
	}
	
	/**
	 * Is the current class perform login yet. It does mean the session is still valid
	 * (If the session was not active for a while the server will drop the connection)
	 * @return is this class performed login 
	 */
	public boolean isLogin(){
		return loginResult != null;
	}

	/**
	 * Return the logged username
	 * @return
	 */
	public String getUsername(){
		return (loginResult != null) ? loginResult.getUsername() : null;
	}
	

	/**
	 * check if this class logged in, if not throw an exception
	 * @throws ApiException
	 */
	public void validateConnection() throws ApiException{
		if (!isLogin()) {
			logger.info("connection is not valid, login wasn't preform yet");
			throw new ApiException("connection is not valid, login wasn't preform yet");
		}
		logger.trace("connection is valid, login occurred (user {})", loginResult.getUsername() );
	}
	
	/**
	 * Log user to to the Control-M 
	 * @param user
	 * @param password
	 * @return
	 * @throws ApiException
	 */
	public Connection login(String user, String password) throws ApiException{
		if (isLogin() ){
			logger.error("session is active, please logout before loginning in again");
			throw new ApiException("session is active, please logout before loginning in again");
		}
		logger.debug("create credentails using user and pass");
		// login
        LoginCredentials credentials = new LoginCredentials().username(user).password(password);
		logger.debug("start login");
		loginResult = api.doLogin(credentials);
        api.getApiClient().addDefaultHeader("Authorization", "Bearer " + loginResult.getToken());
		logger.debug("login ended successfuly, user token is:{}", loginResult.getToken() );
		return this;
	}
	
	/**
	 * Disconnect from Control-M
	 * @return
	 * @throws ApiException
	 */
	public SuccessData logout() throws ApiException{
		if (!isLogin()) {
			throw new ApiException("session is not active, no login occurred");
		}
		logger.debug("user {} ({}) is logging out", loginResult.getUsername(), loginResult.getToken() );
        SuccessData response = api.doLogout();
        logger.debug("logging out ended. msg: {}", response.getMessage()  );
        loginResult = null;
        
        return response;
	}

	/**
	 * Set client side certification for SSL.
	 * @param cert
	 */
	public void setSslCaCertification(InputStream cert) {
		getApiClient().setSslCaCert(cert);
	}
}
