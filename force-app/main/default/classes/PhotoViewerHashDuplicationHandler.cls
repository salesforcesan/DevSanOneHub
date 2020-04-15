global class PhotoViewerHashDuplicationHandler implements Database.Batchable<SObject> {

	global Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Id, PhotoHash__c, Project__c FROM JobImage__c WHERE Processed__c = false AND PhotoHash__c != null]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope){
        PhotoViewerHashDetection.create(scope).run();
    }


    global void finish(Database.BatchableContext bc){}
}