package com.bmc.services.communication;

import java.io.InputStream;

import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.ExpectedException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import io.swagger.client.ApiException;
import junit.framework.Assert;


public class ConnectionTest {
	private static final Logger logger = LoggerFactory.getLogger(ConnectionTest.class.getName());
	// TODO: change those parameter before build to hold your own configuration !!

	private final static String AUTOMATION_API_ENDPOINT = "<end point url>";
	private final static String USER = "<user>";
	private final static String PASS = "<password>";

	@Before
	public void mustChange(){
		Assert.assertFalse("you must update USER, PASS and AUTOMATION_API_ENDPOINT in this class", "<user>".equals(USER) );
	}
		
	
	@Rule
	public ExpectedException thrown = ExpectedException.none();

	private Connection loginToEndPoint() throws ApiException{
		Connection conn = new Connection(AUTOMATION_API_ENDPOINT);
		// using none signed certificate
		//InputStream sslCaCert = ConnectionTest.class.getResourceAsStream("myCertification.cer");
		//conn.getApiClient().setSslCaCert(sslCaCert);
		conn.getApiClient().setVerifyingSsl(false);					// NOTE: Do NOT set to false in production code
		conn.login(USER, PASS);
		return conn;
	}
	
	@Test
	public void testLoginLogout() throws ApiException{
		logger.info("start test testLoginLogout");
		Connection conn = loginToEndPoint();
		
		Assert.assertEquals(USER, conn.getUsername() ); 
		conn.validateConnection();
		conn.logout();

		Assert.assertTrue (!conn.isLogin());
		thrown.expect(ApiException.class);
		thrown.expectMessage("connection is not valid, login wasn't preform yet");
		conn.validateConnection();
		logger.info("end test testLoginLogout");
	}
	
	@Test
	public void testDummyUser() throws ApiException{
		logger.info("start test testDummyUser");
		Connection  conn = new Connection(AUTOMATION_API_ENDPOINT);
		conn.getApiClient().setVerifyingSsl(false);
		try{
			conn.login("noneExistuser", "password");
		} catch (ApiException e) {
			Assert.assertEquals("{\"errors\":[{\"message\":\"Failed to login: Incorrect username or password\"}]}", e.getResponseBody() );
		}
				
		// then: we expect an IndexOutOfBoundsException
		thrown.expect(ApiException.class);
		thrown.expectMessage("connection is not valid, login wasn't preform yet");
		conn.validateConnection();
		logger.info("end test testDummyUser");
	}
	
	
	@Test
	public void testLoginWhenAlreadyLoggedin() throws ApiException{
		logger.info("start test testLoginWhenAlreadyLoggedin");
		Connection conn = loginToEndPoint();
	    
		thrown.expect(ApiException.class);
		thrown.expectMessage("session is active");
		conn.login(USER, PASS);
		logger.info("end test testLoginWhenAlreadyLoggedin");
	}

	@Test
	public void testLogoutWithoutLogin() throws ApiException{
		logger.info("start test testLogoutWithoutLogin");
		Connection  conn = new Connection(AUTOMATION_API_ENDPOINT);
		thrown.expect(ApiException.class);
		thrown.expectMessage("session is not active");
		conn.logout();
		logger.info("end test testLogoutWithoutLogin");
	}

	@Test
	public void testValidateConnection() throws ApiException{
		logger.info("start test testValidateConnection");
		Connection conn = loginToEndPoint();
		Assert.assertTrue(conn.isLogin() );
		conn.validateConnection();

		conn.logout();
		thrown.expect(ApiException.class);
		thrown.expectMessage("connection is not valid");
		conn.validateConnection();
		logger.info("start test testValidateConnection");
	}

	@Test
	public void testMalformedUR() throws ApiException{
		logger.info("start test testMalformedUR");
		thrown.expect(ApiException.class);
		Connection  conn = new Connection("sdfsdfsdf");
		conn.validateConnection();
		logger.info("end test testMalformedUR");
	}
		
}
