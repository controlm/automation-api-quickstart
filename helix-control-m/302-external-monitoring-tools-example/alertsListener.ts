// <reference path="../../typings/node/node.d.ts" />

const webSocket = require('ws')
const HttpsProxyAgent = require('https-proxy-agent');
const winston = require('winston');
const path = require("path");
const spawn = require('child_process').spawn
const fs = require('fs');
const os = require("os");

const powerShellExtension = ".ps1";
let headers;
let logger;
let environmentArgument;
let scriptPathArgument;
let apiKeyArgument;
let UrlArgument;
let proxyArgument;

export function getLoggerFileName() {
    return path.join(ctmDir(), "logs", `alertsListener_${getCurrentTime()}.log`);
}

export function createAlertsDir(dirPath: string) {
    let logFolder = path.join(dirPath, "logs");
    if (!fs.existsSync(logFolder))
        fs.mkdirSync(logFolder)
}

export function switchToScriptDir(scriptPathArgument: string) {
    try {
        let dirPath = path.dirname(scriptPathArgument);
        logger.info("Switching to: " + dirPath);
        process.chdir(dirPath);
    } catch (error) {
        logger.error("Could not switch to: " + scriptPathArgument + " directory, reason: " + error);
        throw new Error(error);
    }
}

// This function creates the webSocket instance and handling the following events : open, close, error and message.
// There is a check via ping that ensures the server is up.
//each message that is received from the server is being logged and modified in order to run as parameters for the given script.
export function connect(url, headers, delay) {
    let ws = new webSocket(url, [], headers);
    ws.isAlive = true;
    ws.shouldClose = false;
    let pingInterval;
    ws.onopen = function () {
        handleLogsDir()
        pingInterval = createPingInterval(url, ws, delay)
    };

    ws.onmessage = function (e) {
        logger.info(e.data);
        const scriptArgumentsArray = [scriptPathArgument];
        createScriptPath(JSON.parse(e.data), scriptArgumentsArray);
        if (checkScriptExists(scriptPathArgument)) {
            switchToScriptDir(scriptPathArgument);
            let shell = addingShellRelatedCommand(scriptArgumentsArray);
            logger.debug(`running the following command: ${scriptArgumentsArray.join(' ')}`)
            runScript(shell, scriptArgumentsArray);
        } else {
            ws.terminate()
        }
    };

    ws.onclose = function (e) {
        logger.info("Connection closed for the following reason: ", e.message)
        if (ws.shouldClose === true) {
            logger.info("closing the Alerts listener client.");
            clearInterval(pingInterval);
        } else {
            logger.info("reconnecting to the API gateway.");
            clearInterval(pingInterval);
            setTimeout(function () {
                connect(url, headers, delay)
            }, 1000 * 20)
        }
    };

    ws.onerror = function (err) {
        logger.error(`${err.message} Closing socket`);
        logger.debug(JSON.stringify(err.message))
        let errorCode = extractErrorCode(err.message);
        handleErrorCode(errorCode, ws);
    };

    ws.on('pong', heartbeat)
    return ws;
}

function runScript(shell: string, scriptArgumentsArray: any[]) {
    let childProcess = spawn(shell, scriptArgumentsArray);
    childProcess.stdout.on('data', (data) => {
        logger.debug(`script output: ${data}`);
    });
    childProcess.stderr.on('data', (data) => {
        logger.error(`script error message: ${data}`);
    });
}

export function checkScriptExists(scriptPath: string): boolean {
    try {
        validateListenerScriptPath(scriptPath)
    } catch (error) {
        logger.error(error);
        return false;
    }
    return true;
}

// Restricts the amount of files in the log's directory, keeps the latest update logs, default 10 files.
function handleLogsDir() {
    const alertLogDir = path.join(ctmDir(), "logs");
    const files = fs.readdirSync(alertLogDir);
    const maxFilesCount = parseInt(getSettings("listenerMaxFileCount", "10"))
    if (files.length <= maxFilesCount) {
        return;
    }
    const fileToDateObject = [];
    files.forEach(file => {
        getFileLastModifiedDate(file, alertLogDir, fileToDateObject);
    })
    sortAndRemoveOldFiles(fileToDateObject, maxFilesCount);
}

export function getFileLastModifiedDate(file: string, alertLogDir, fileToDateObject: any[]) {
    let filePath = path.join(alertLogDir, file);
    let fileCreation = fs.statSync(filePath).mtime.getTime();
    fileToDateObject.push({fileCreation, filePath})
}

export function sortAndRemoveOldFiles(fileToDateObject: any[], maxFilesCount: number) {
    fileToDateObject.sort(function (a, b) {
        return a.fileCreation - b.fileCreation
    })
    while (fileToDateObject.length > maxFilesCount) {
        fs.unlinkSync(fileToDateObject[0].filePath);
        fileToDateObject.shift()
    }
}

function heartbeat() {
    logger.debug("pong received")
    this.isAlive = true;
}

function addArgumentsToScript(key: string[], scriptArgumentsArray: any[], keyValue: string) {
    key[0] = key[0] + ": ";
    scriptArgumentsArray.push(key[0], keyValue)
}

export function createScriptPath(object, scriptArgumentsArray ?: any[]) {
    for (let i = 0; i < object.alertFields.length; ++i) {
        let field = object.alertFields[i];
        let key = Object.keys(field)
        if (powerShellExtension === path.extname(scriptArgumentsArray[0])) {
            let keyValue = `'${field[key.toString()].replace((/'/g, "\\'"))}'` + " ";
            addArgumentsToScript(key, scriptArgumentsArray, keyValue);
        } else {
            let keyValue = field[key.toString()] + " ";
            addArgumentsToScript(key, scriptArgumentsArray, keyValue);
        }
    }
}

function addingShellRelatedCommand(commandArgs: any[]) {
    let shell = isWindows() ? 'cmd' : '/bin/sh';
    logger.debug("shell is: " + shell);
    if (isWindows()) {
        if (powerShellExtension !== path.extname(commandArgs[0])) {
            commandArgs.splice(0, 0, '/C');
        } else {
            shell = "powershell";
        }
    }
    return shell;
}

function isWindows() {
    return os.platform() === "win32";
}

function handleError(ws, message: string) {
    logger.error(message);
    ws.shouldClose = true;
}

function createPingInterval(url: string, ws, delay: number) {
    return setInterval(function () {
        if (ws.isAlive === false) {
            logger.debug("Did not receive pong from server. Trying to reconnect")
            ws.terminate()
            connect(url, headers, delay);
        }
        ws.isAlive = false;
        logger.debug("WebSocket sending ping")
        ws.ping()
    }, delay);
}

function handleErrorCode(errorCode: number, ws) {
    switch (errorCode) {
        case 401 :
            handleError(ws, "User is not authorized to perform this operation");
            break
        case 403 :
            handleError(ws, "User is not permitted to perform this operation");
            break
        case 409 :
            handleError(ws, "Another Alerts listener is already connected");
            break
        case 503 :
            handleError(ws, "External Alerts Service is disabled");
            break
        default :
            ws.close();
            logger.info('Socket is closed. Trying to reconnect.');
    }
}

function extractErrorCode(errorMessage) {
    return parseInt(errorMessage.split(':')[1]);
}

function getCurrentTime(logFormat ?: boolean) {
    const separator = logFormat ? ":" : "-";
    const today = new Date();
    return today.getFullYear() + '-' + (padTime(today.getMonth() + 1)) + '-' + padTime(today.getDate())
        + '-' + padTime(today.getHours()) + separator + padTime(today.getMinutes()) + separator + padTime(today.getSeconds());
}

function padTime(time: number) {
    return (time.toString() as any).padStart(2, '0')
}

export function validateScriptAndEnvArgs(scriptPathArgument: string, environmentArgument: string) {
    if (scriptPathArgument.length === 0) {
        throw new Error("Missing script path")
    }
    if (environmentArgument.length === 0) {
        throw new Error("listenerEnvironment not found")
    }
}

export function validateTokenAndUrlArgs(apiKeyArgument, UrlArgument) {
    if (apiKeyArgument.length === 0) {
        throw new Error("Missing Api Key")
    }
    if (UrlArgument.length === 0) {
        throw new Error("Missing URL")
    }
}

function parseArgsAndValidate() {
    scriptPathArgument = getSettings("listenerScript", "")
    environmentArgument = getSettings("listenerEnvironment", "")
    validateScriptAndEnvArgs(scriptPathArgument, environmentArgument)
    apiKeyArgument = getSettings("token", "")
    UrlArgument = getSettings("url", "");
    validateTokenAndUrlArgs(apiKeyArgument, UrlArgument);
    proxyArgument = getSettings("proxyUrl", "");

}

function printArgs() {
    logger.info("process pid is: " + getSettings("listenerPid", ""));
    logger.info("Running WebSocket with the following URL: " + UrlArgument, "and the following script path: " + scriptPathArgument + " against the following environment: " + environmentArgument)
}

// If proxyUrl is defined, websocket will try to connect to the given proxyUrl
function checkProxySettings(headers, proxyUrl: string) {
    if (proxyUrl !== undefined && proxyUrl.length !== 0) {
        headers.agent = new HttpsProxyAgent(proxyUrl);
        logger.debug("running through proxy environment:" + proxyUrl);
    }
}

// Creates the log's directory if needed, preparing the arguments for the webSocket.
export function init() {
    createAlertsDir(ctmDir())
    setLogger(createLogger());
    parseArgsAndValidate()
    printArgs()
    headers = {headers: {['x-api-key']: apiKeyArgument}};
    checkProxySettings(headers, proxyArgument);
    try {
        connect(UrlArgument, headers, 1000 * 60);
    } catch (e) {
        logger.info("caught exception ")
    }
}

// Creating winston logger, for more info about the flags and configuration see - https://www.npmjs.com/package/winston/v/1.1.2
export function createLogger() {
    return new (winston.Logger)({
        transports: [
            new (winston.transports.File)({
                json: false,
                filename: getLoggerFileName(),
                timestamp: function () {
                    return getCurrentTime(true);
                },
                formatter: (options) => {
                    return options.timestamp() + ' ' + options.level.toUpperCase() + ' ' + (options.message ? options.message : '');
                },
                level: getLogLevel(),
                maxsize: getFileMaxSize()
            }),
        ]
    });
}

export function setLogger(loggerInstance: any) {
    logger = loggerInstance;
}

function getLogLevel() {
    return getSettings("listenerLogLevel", "info");
}

function getFileMaxSize() {
    return parseInt(getSettings("listenerLogSizeMb", "10")) * Math.pow(10, 6);
}

function ctmDir() {
    const dir = process.env.CTM_CLI_PROFILE_PATH ||
        path.join(homeFolder(), ".ctm");

    if (!pathExistsSync(dir)) {
        fs.mkdirSync(dir, 502); // 0766
    }

    return dir;
}

function getSettings(settingName: string, defaultValue: string): string {
    const config = getCliConfigurations();
    const result = config[settingName];
    return result === undefined ? defaultValue : result;
}

function getCliConfigurations() {
    const confFile = getConfigurationFile();
    const ret = readJsonFile(confFile);
    return ret || {localServerLocation: ""};
}

function getConfigurationFile() {
    return path.join(ctmDir(), "settingsFile.json");
}

function readJsonFile(file: string): any {
    try {
        return require(file);
    } catch (error) {
        return undefined;
    }
}

function homeFolder() {
    if (process.env.HOME !== undefined) {
        return process.env.HOME;
    }

    if (os.homedir()) {
        return os.homedir()
    }

    if (process.env.HOMEDRIVE && process.env.HOMEPATH) {
        return process.env.HOMEDRIVE + process.env.HOMEPATH;
    }

    throw new Error("No HOME path available");
}

function pathExistsSync(path: string) {
    try { // see http://stackoverflow.com/questions/4482686
        fs.statSync(path);
        return true;
    } catch (err) {
        return false;
    }
}

function validateListenerScriptPath(path: string) {
    if (fs.existsSync(path)) {
        try {
            fs.readFileSync(path)
        } catch (error) {
            throw new Error("Alerts listener script path: " + path + " must be a file");
        }
        try {
            fs.accessSync(path, fs.X_OK)
        } catch (error) {
            throw new Error("You are not authorized to execute Alerts listener script " + path);
        }
    } else {
        throw new Error("Alerts listener script: " + path + " file not found");
    }
}

init();
