@istest
private class lwcImportProgramTest {
    
    @testSetup
    static void setup(){
        TestDataUtil.init();
        TestProject.create('demo');
        DatasourceTest.makeData();
    }

    static String getDatasourceId() {
        return [SELECT Id from Datasource__c limit 1].Id;
    }

    @istest
    static void itShouldCreateRequestQueue() {
        //GIVEN
        String datasource = getDatasourceId();

        //WHEN
        test.startTest();
        ImportRequestQueueWrapper result =lwcImportProgramController.createRequestQueue(datasource);
        test.stopTest();

        //THEN
        QA.EQ(datasource, result.datasource, 'queue created');
    }


    static ImportRequestQueue__c genTestQueue(String datasource) {
        ImportRequestQueue__c que = new ImportRequestQueue__c(
            Datasource__c = datasource,
            RequestDate__c = Datetime.now(),
            Requestor__c = UserInfo.getUserId(),
            Status__c = 'Init'
        );
        insert que;
        return que;
    }

    static String genProjectData(){
        return TestProject.getProjects()[0].Id;
    }

    @istest
    static void itShouldAddRequestQueueItem() {
        //GIVEN
        List<String[]> content = new List<String[]>{
           new String[]{'1','2'}
        };
        String datasource = getDatasourceId();
        String projectId = genProjectData();
        String queueId = genTestQueue(datasource).Id;


        //WHEN
        test.startTest();
        WebApiResult result = lwcImportProgramController.addRequestQueueItem(queueId, projectId, content);
        test.stopTest();

        //THEN
        QA.EQ(1, result.status,'queueItem added.');
        Attachment att = [SELECT name from Attachment WHERE ParentId = :queueId LIMIT 1];
        QA.EQ('import_request_queue', att.name, 'attachment created.');
    }

    static ImportRequestQueue__c genQueueData(string datasource) {
          ImportRequestQueue__c que = new ImportRequestQueue__c(
            Datasource__c = datasource,
            RequestDate__c = Datetime.now(),
            Requestor__c = UserInfo.getUserId(),
            Status__c = 'Init'
        );
        insert que;
        return que;
    }

    @isTest
    static void itShouldQueueImportRequest() {
        
        //GIVEN
        String datasource = getDatasourceId();
        ImportRequestQueue__c q = genQueueData(datasource);
        
        //WHEN
        test.startTest();
        WebApiResult res = lwcImportProgramController.submitQueue(q.Id);
        test.stopTest();

        //THEN
        ImportRequestQueue__c result = [SELECT Id,status__C FROM ImportRequestQueue__c limit 1];
        QA.EQ('Queued', result.status__c, 'should be queued');
    }

    static void genQueueItem(String queueId, String projectId){
          Attachment att = new Attachment();
            att.ParentId = queueId;
            att.Body = Blob.valueOf(JSON.serialize('123'));
            att.ContentType = 'application/json';
            att.Name = 'import_request_queue';
            insert att;

            ImportRequestQueueItem__c queItem = new ImportRequestQueueItem__c(
                AttachmentId__c = att.Id,
                Project__c = projectId,
                RetryCount__c = 0,
                Queue__c = queueId,
                Status__c = 'Queued'
            );
        insert queItem;
    }

    @isTest
    static void itShouldDeleteRequestQueueAndItem(){
        //GIVEN
        String datasource = getDatasourceId();
        String projectId = genProjectData();
        ImportRequestQueue__c q = genQueueData(datasource);
        genQueueItem(q.Id, projectId);

        //WHEN
        test.startTest();
        WebApiResult res = lwcImportProgramController.deleteQueue(q.Id);
        test.stopTest();

        //THEN
        Integer count = Database.countQuery('SELECT count() from ImportRequestQueueItem__c');
        QA.EQ(0, count, 'no queue items');
        count = Database.countQuery('SELECT count() FROM ImportRequestQueue__c');
        QA.EQ(0, count, 'no queue');
    }
}