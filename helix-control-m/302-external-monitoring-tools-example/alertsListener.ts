// <reference path="../../typings/node/node.d.ts" />

const webSocket = require('ws')
const winston = require('winston');
const path = require("path");
const exec = require('child_process').exec
const fs = require('fs');
const os = require("os");

let scriptArgs = "";
let headers;
let logger;
let environmentArgument;
let scriptPathArgument;
let apiKeyArgument;
let UrlArgument;

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
    let pingInterval;
    ws.onopen = function () {
        handleLogsDir()
        pingInterval = createPingInterval(url, ws, delay)
    };

    ws.onmessage = function (e) {
        scriptArgs = "";
        logger.info(e.data);
        createScriptPath(JSON.parse(e.data));
        if (checkScriptExists(scriptPathArgument)) {
            switchToScriptDir(scriptPathArgument);
            logger.info("running script: " + scriptPathArgument + " with arguments: " + scriptArgs)
            exec(`${scriptPathArgument}  ${scriptArgs}`);
        } else {
            ws.terminate()
        }
    };

    ws.onclose = function (e) {
        logger.info("Connection closed for the following reason: ", e.message)
        clearInterval(pingInterval);
    };

    ws.onerror = function (err) {
        logger.error(`${err.message} Closing socket`);
        logger.debug(JSON.stringify(err.message))
        let errorCode = extractErrorCode(err.message);
        handleErrorCode(errorCode, ws, url, delay);
    };

    ws.on('pong', heartbeat)
    return ws;
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

export function createScriptPath(object) {
    for (let i = 0; i < object.alertFields.length; ++i) {
        let field = object.alertFields[i];
        let key = Object.keys(field)
        let keyValue = field[key.toString()];
        scriptArgs += key[0] + ": " + keyValue + " ";
    }
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

function handleErrorCode(errorCode: number, ws, url, delay) {
    switch (errorCode) {
        case 401 :
            logger.error("User is not authorized to perform this operation")
            break
        case 403 :
            logger.error("User is not permitted to perform this operation")
            break
        case 409 :
            logger.error("Another Alerts listener is already connected")
            break
        case 503 :
            logger.error("External Alerts Service is disabled")
            break
        default :
            ws.close();
            logger.info('Socket is closed. Trying to reconnect.');
            ws.reconnectTimeout = setTimeout(function () {
                connect(url, headers, delay);
            }, 1000 * 10);
    }
}

function extractErrorCode(errorMessage) {
    return parseInt(errorMessage.split(':')[1]);
}

function getCurrentTime(logFormat ?: boolean) {
    const separator = logFormat ? ":" : "-";
    const today = new Date();
    return today.getFullYear() + '-' + (today.getMonth() + 1) + '-' + today.getDate()
        + '-' + today.getHours() + separator + today.getMinutes() + separator + today.getSeconds();
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
}

function printArgs() {
    logger.info("process pid is: " + getSettings("listenerPid", ""));
    logger.info("Running WebSocket with the following URL: " + UrlArgument, "and the following script path: " + scriptPathArgument + " against the following environment: " + environmentArgument)
}

// Creates the log's directory if needed, preparing the arguments for the webSocket.
export function init() {
    createAlertsDir(ctmDir())
    setLogger(createLogger());
    parseArgsAndValidate()
    printArgs()
    headers = {headers: {['x-api-key']: apiKeyArgument}};
    try {
        connect(UrlArgument, headers, 1000 * 60);
    } catch (e) {
        logger.info("caught exception ")
    }
}

// Creating winston logger, for more info about the flags and configuration see - https://www.npmjs.com/package/winston/v/0.9.0
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
