public without sharing class AppLogBatch {
    public final static String EVENT_SOURCE_BATCHJOB = 'BatchJob';
    public final static String EVENT_SOURCE_ONLINE_APP = 'OnlineApp';
    public final static String LOG_LEVEL_INFO = 'Info';
    public final static String LOG_LEVEL_ERROR = 'Error';
    public final static String LOG_LEVEL_WARNING = 'Warning';
    public final static String LOG_LEVEL_CRITICAL = 'Critical';


    List<AppLog__c> logs;
    AppLog__c logInstance;
    boolean isAddtoBatched;
    Map<String,Object> parameters;

    private AppLogBatch() {
        this.logs = new List<AppLog__c>();
    }

    public static void batchError(Exception paramEx, String parameter, String requestor) {
        batchError(
            paramEx.getMessage(),
            paramEx.getStackTraceString(),
            parameter,
            requestor
        );
    }

    public Static void batchError(String msg, String detail, String parameter, String requestor) {
        logBatchMsg(
            LOG_LEVEL_ERROR,
            msg,
            detail,
            parameter,
            requestor
        );
    }

    public Static void batchWarn(String msg, String detail, String parameter, String requestor) {
        logBatchMsg(
            LOG_LEVEL_WARNING,
            msg,
            detail,
            parameter,
            requestor
        );
    }

    public Static void batchInfo(String msg, String detail, String parameter, String requestor) {
        logBatchMsg(
            LOG_LEVEL_INFO,
            msg,
            detail,
            parameter,
            requestor
        );
    }

    public static void appError(Exception paramEx, String parameter, String requestor) {
        appError(
            paramEx.getMessage(),
            paramEx.getStackTraceString(),
            parameter,
            requestor
        );
    }

    public Static void appError(String msg, String detail, String parameter, String requestor) {
        logAppMsg(
            LOG_LEVEL_ERROR,
            msg,
            detail,
            parameter,
            requestor
        );
    }

    public Static void appWarn(String msg, String detail, String parameter, String requestor) {
        logAppMsg(
            LOG_LEVEL_WARNING,
            msg,
            detail,
            parameter,
            requestor
        );
    }

    public Static void appInfo(String msg, String detail, String parameter, String requestor) {
        logAppMsg(
            LOG_LEVEL_INFO,
            msg,
            detail,
            parameter,
            requestor
        );
    }

    static void logAppMsg(
        String msgLevel,
        String msg,
        String detail,
        String parameter,
        String requestor) {
       logMsg(
        EVENT_SOURCE_ONLINE_APP, 
        msgLevel,
        msg,
        detail,
        parameter,
        requestor
        );
    }

    static void logBatchMsg(
        String msgLevel,
        String msg,
        String detail,
        String parameter,
        String requestor) {
       logMsg(
        EVENT_SOURCE_BATCHJOB, 
        msgLevel,
        msg,
        detail,
        parameter,
        requestor
        );
    }

      static void logMsg(
        String eventSource,
        String msgLevel,
        String msg,
        String detail,
        String parameter,
        String requestor) {
        try {
            AppLogBatch.createInstance()
            .newLog(eventSource, msgLevel)
            .setMessageDetail(msg, detail)
            .setParameter(parameter, false)
            .setRequestor(requestor)
            .addToBatch()
            .saveToDB();
        } catch (Exception ex) {
            throw new CustomException('AppLog Failed: ' + ex.getMessage() + ':' + ex.getStackTraceString());
        }
    }

    public static AppLogBatch createInstance() {
        return new AppLogBatch();
    }

    public AppLogBatch newLog(String eventSource) {
        return newLog(eventSource, LOG_LEVEL_INFO);
    }

    public AppLogBatch newLog(String eventSource, String errorLevel) {
        isAddtoBatched = false;
        parameters = new Map<String,Object>();
        logInstance = new AppLog__c(
            EventSource__c = eventSource,
            LogLevel__c = errorLevel
        );
        return this;
    }

    public AppLogBatch newAppLog() {
        return newLog(EVENT_SOURCE_ONLINE_APP);
    }

    public AppLogBatch newBatchJobLog() {
        return newLog(EVENT_SOURCE_BATCHJOB);
    }

    public AppLogBatch addToBatch() {
        if (isAddtoBatched) {
            throw new CustomException('The record is already added. Call newLog() method when adding a new log.');
        }

        if (logInstance == null) {
            throw new CustomException('The log instance is null. Call newLog() method before adding a new log');
        }

        logs.add(logInstance);
        logInstance = null;
        isAddtoBatched = true;

        return this;
    }

    public AppLog__c toInstance() {
        return this.logInstance;
    }

    public AppLogBatch addToBatch(AppLog__c instance) {
        if (!parameters.isEmpty()){
            instance.Parameter__c = JSON.serialize(parameters);
        }
        logs.add(instance);
        return this;
    }

    public void saveToDB() {
        if (logs.isEmpty()) {
            throw new CustomException('No logs to save.');
        }
        Database.SaveResult[] results = Database.insert(logs);
        String error = genSaveResultListError(results);
        if (String.isNotBlank(error)) {
            throw new CustomException(error);
        }
    }

    // Log Level set
    AppLogBatch logLevel(String level) {
        logInstance.LogLevel__c = level;
        return this;
    }

    public AppLogBatch setCritical() {
        return logLevel(LOG_LEVEL_CRITICAL);
    }

    public AppLogBatch setWarning() {
        return logLevel(LOG_LEVEL_WARNING);
    }

    public AppLogBatch setError() {
        return logLevel(LOG_LEVEL_ERROR);
    }

    public AppLogBatch setInfo() {
        return logLevel(LOG_LEVEL_INFO);
    }

    public AppLogBatch setReplayId(String replayId) {
        logInstance.ReplayId__c = replayId;
        return this;
    }

    public AppLogBatch setRelatedIds(String asyncApexJobId, String replayId, String requestId) {
        logInstance.AsyncApexJobId__c = asyncApexJobId;
        logInstance.ReplayId__c = replayId;
        logInstance.RequestId__c = requestId;
        return this;
    }

    public AppLogBatch setMessageDetail(String msg, String detail) {
        logInstance.Message__c = msg;
        logInstance.Detail__c = detail;
        return this;
    }

    public AppLogBatch setErrorType(String errorType) {
        logInstance.ExceptionType__c = errorType;
        return this;
    }

    public AppLogBatch setParameter(String parameter, boolean isTruncated) {
        logInstance.Parameter__c = parameter;
        logInstance.IsParameterTruncated__c = isTruncated;
        return this;
    }

    public AppLogBatch setParameter(String parameter) {
        logInstance.Parameter__c = parameter;
        logInstance.IsParameterTruncated__c = false;
        return this;
    }

    public AppLogBatch setParameters(String key, Object value){
        parameters.put(key, value);
        return this;
    }

    public AppLogBatch setPhase(String phase) {
        logInstance.Phase__c = phase;
        return this;
    }

    public AppLogBatch setRequestor(String requestorId) {
        logInstance.RequestId__c = requestorId;
        return this;
    }


    public static String genSaveResultError(Database.SaveResult sr) {
        List<String> errors = new List<String>();
        for (Database.Error err : sr.getErrors()) {
            errors.add(err.getStatusCode() + ': ' + err.getMessage());
        }
        return String.join(errors, '. ');
    }

    public static String genSaveResultListError(List<Database.SaveResult> srList) {
        List<String> errors = new List<String>();
        String error;

        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess()) {
                error = genSaveResultError(sr);
                if (!String.isBlank(error)) {
                    errors.add(error);
                }
            }
        }

        return errors.size() > 0 ? String.join(errors, '. ') : '';
    }

    public static List<AppLog__c> getAll(){
        return [
            SELECT
                Id,
                AsyncApexJobId__c,
                LogLevel__c,
                EventSource__c,
                ExceptionType__c,
                Message__c,
                Detail__c,
                Parameter__c,
                Phase__c,
                ReplayId__c,
                RequestId__c
            FROM AppLog__c
            Order By SystemModstamp DESC
            LIMIT 10000
        ];
    }

    public static List<AppLog__c> fetchPage(Integer pageOffset, Integer pageSize){
        return [
            SELECT
                Id,
                AsyncApexJobId__c,
                LogLevel__c,
                EventSource__c,
                ExceptionType__c,
                Message__c,
                Detail__c,
                Parameter__c,
                Phase__c,
                ReplayId__c,
                RequestId__c
            FROM AppLog__c
            Order By SystemModstamp DESC
            LIMIT :pageSize
            OFFSET :pageOffset
        ];
    }
}