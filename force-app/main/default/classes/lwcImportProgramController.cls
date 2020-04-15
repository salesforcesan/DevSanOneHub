public without sharing class lwcImportProgramController {

    @AuraEnabled
    public static ImportRequestQueueWrapper createRequestQueue(string datasource) {
        checkDatasource(datasource);

        ImportRequestQueue__c que = new ImportRequestQueue__c(
            Datasource__c = datasource,
            RequestDate__c = Datetime.now(),
            Requestor__c = UserInfo.getUserId(),
            Status__c = 'Init'
        );
        que = (ImportRequestQueue__c) DBX.doInsert(que);
        return ImportRequestQueueWrapper.newInstance(que.Id);
    }

    static void checkDatasource(string datasource) {
        if (String.isBlank(datasource)) {
            throw new AuraHandledException('The datasource is required.');
        }

        List<Datasource__c> ds = [SELECT Id from Datasource__c WHERE id = :datasource limit 1];
        if (ds.isEmpty()) {
            throw new AuraHandledException('Datasource Not Found.');
        }
    }

    static void checkParameters(String queueId, String projectId, List<List<String>> content){
        ImportRequestQueue__c q = getQueue(queueId);
        if(String.isBlank(projectId)){
            throw new AuraHandledException('Project Id can not be empty.');
        }
        if (content == null || content.isEmpty()) {
            throw new AuraHandledException('Attachment content can not be empty');
        }
    }

    @AuraEnabled
    public static WebApiResult addRequestQueueItem(
        String queueId,
        String projectId,
        List<List<String>> content) {
        SavePoint sp  = null;

        try {
            checkParameters(queueId, projectId, content);

            sp  = Database.setSavepoint();
            Attachment att = new Attachment();
            att.ParentId = queueId;
            att.Body = Blob.valueOf(JSON.serialize(content));
            att.ContentType = 'application/json';
            att.Name = 'import_request_queue';
            att = (Attachment) DBX.doInsert(att);

            ImportRequestQueueItem__c queItem = new ImportRequestQueueItem__c(
                AttachmentId__c = att.Id,
                Project__c = projectId,
                RetryCount__c = 0,
                RecordCount__c = content.size(),
                Queue__c = queueId,
                Status__c = 'Queued'
            );
            DBX.doInsert(queItem);

            return WebApiResult.newSuccess();
        } catch (AuraHandledException auraEx) {
            if (sp != null) {
                Database.rollback(sp);
            }

            return WebApiResult.newError(auraEx.getMessage());
        } catch (Exception ex) {
            if (sp != null) {
                Database.rollback(sp);
            }

            return WebApiResult.newError(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }

    @AuraEnabled
    public static WebApiResult submitQueue(String queueId) {
        try {
            ImportRequestQueue__c q = getQueue(queueId);
            q.Status__c = 'Queued';
            DBX.doUpdate(q);
            return WebApiResult.newSuccess();
        } catch (AuraHandledException auraEx) {
            return WebApiResult.newError(auraEx.getMessage());
        } catch (Exception ex) {
            return WebApiResult.newError(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }

    static ImportRequestQueue__c getQueue(String queueId) {
        if (string.isBlank(queueId)) {
            throw new AuraHandledException('Queue ID is required.');
        }

        List<ImportRequestQueue__c> qs = [SELECT Id, Status__c FROM ImportRequestQueue__c WHERE Id = :queueId];

        if (qs.isEmpty()) {
            throw new AuraHandledException('The request queue is not found:' + queueId);
        }
        return qs.get(0);
    }

    @AuraEnabled
    public static WebApiResult deleteQueue(String queueId) {
        try {
            ImportRequestQueue__c q = getQueue(queueId);
            List<ImportRequestQueueItem__c> items = [SELECT Id from ImportRequestQueueItem__c WHERE Queue__c = :queueId];
            if (!items.isEmpty()) {
                delete items;
            }
            DBX.doDelete(q);
            return WebApiResult.newSuccess();
        } catch (AuraHandledException auraEx) {
            return WebApiResult.newError(auraEx.getMessage());
        } catch (Exception ex) {
            return WebApiResult.newError(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }
}