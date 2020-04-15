@isTest
private class AppLogBatchTest {
    @isTest
    static void itShouldBeAbleToInsertBatchLog() {
        // Given
        AppLogBatch batch = AppLogBatch.createInstance();
        String phase = 'Start';
        String eventSource = AppLogBatch.EVENT_SOURCE_BATCHJOB;
        String errorType = 'demo';
        String parameter  = 'dummy';
        Boolean isTruncated = false;

        batch.newBatchJobLog()
        .setPhase(phase)
        .setRelatedIds('1', '2', '3')
        .setError()
        .setErrorType(errorType)
        .setMessageDetail('message', 'detail')
        .setParameter(parameter, isTruncated)
        .addToBatch();

        // When
        Test.startTest();
        batch.saveToDB();
        Test.stopTest();

        // Then
        AppLog__c result = getAppLog();
        QA.EQ(AppLogBatch.EVENT_SOURCE_BATCHJOB, result.EventSource__c, 'batch job');
        QA.EQ('detail', result.Detail__c,  'detail should be same');
        QA.EQ(phase, result.Phase__c, 'phase same');
        QA.EQ('Error', result.LogLevel__c, 'same error level');
    }

    @isTest 
    static void itShouldInsertAppLog() {
        // Given
        AppLogBatch batch = AppLogBatch.createInstance();
        String phase = 'Start';
        String eventSource = AppLogBatch.EVENT_SOURCE_ONLINE_APP;
        String errorType = 'demo';
        String parameter  = 'dummy';
        Boolean isTruncated = false;

        batch.newAppLog()
        .setPhase(phase)
        .setRelatedIds('1', '2', '3')
        .setError()
        .setErrorType(errorType)
        .setMessageDetail('message', 'detail')
        .setParameter(parameter, isTruncated)
        .addToBatch();

        // When
        Test.startTest();
        batch.saveToDB();
        Test.stopTest();

        //THEN
        AppLog__c result = getAppLog();
        QA.EQ(AppLogBatch.EVENT_SOURCE_ONLINE_APP, result.EventSource__c, 'app log');
    }

    @isTest
    static void itShouldappError() {
        //GIVEN
        CustomException ex = new CustomException('demo');
        String parameter = '1';
        String requestor = 'demo';

        //WHEN
        test.startTest();
        AppLogBatch.appError(ex, parameter,requestor);
        test.stopTest();

        //THEN
        AppLog__c result = getAppLog();
        QA.EQ(requestor, result.RequestId__c, 'requestor: demo');
        QA.EQ(parameter, result.Parameter__c, 'parameter: 1');
        QA.EQ('demo', result.Message__c, 'message: demo');
        QA.EQ('Error', result.LogLevel__c, 'level: error');
    }

    @isTest
    static void itShouldbatchError() {
         //GIVEN
        CustomException ex = new CustomException('demo');
        String parameter = '1';
        String requestor = 'demo';

        //WHEN
        test.startTest();
        AppLogBatch.batchError(ex, parameter,requestor);
        test.stopTest();

        //THEN
        AppLog__c result = getAppLog();
        QA.EQ(requestor, result.RequestId__c, 'requestor: demo');
        QA.EQ(parameter, result.Parameter__c, 'parameter: 1');
        QA.EQ('demo', result.Message__c, 'message: demo');
        QA.EQ('Error', result.LogLevel__c, 'level: error'); 
    }

    static string genTargetObjectName() {
        List<String> names = new List<String>();
        for(Integer i =0; i < 140; i++) {
            names.add(String.valueOf(i));
        }
        return String.join(names, '');
    }

    @isTest
    static void itShouldIncreaseCodeCoverage(){
        //when
        test.startTest();
        Database.SaveResult[] results = Database.insert(new Account[]{
            new Account(name='test 1'),
            new Account(name='test')
            });
        String tmp = AppLogBatch.LOG_LEVEL_CRITICAL;
        tmp = AppLogBatch.LOG_LEVEL_ERROR;
        tmp = AppLogBatch.LOG_LEVEL_INFO;
        tmp = AppLogBatch.LOG_LEVEL_WARNING;
        AppLogBatch.batchWarn('demo','detail','1','1');
        AppLogBatch.batchInfo('demo','detail','1','1');
        AppLogBatch.appInfo('demo','detail','1','1');
        AppLogBatch.appWarn('demo','detail','1','1');
        test.stopTest();

        //then
        String error = AppLogBatch.genSaveResultListError(results);
    }

    static AppLog__c getAppLog() {
        return AppLogBatch.getAll()[0];
    }
}