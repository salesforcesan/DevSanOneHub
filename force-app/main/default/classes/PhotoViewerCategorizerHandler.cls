global class PhotoViewerCategorizerHandler implements Database.Batchable<SOBject>, Database.AllowsCallouts {
    global Database.QueryLocator start(Database.BatchableContext bc){
        String sql = 'SELECT Id, AIImageUrl__c FROM JobImage__c WHERE AILabel__c != null AND PhotoHash__c != null AND IsClassified__c != true AND IsErrored__c != true AND IsDuplicated__c != true AND PoorQualityCheck__c != true';
        return Database.getQueryLocator(sql);
    }

    global void execute(Database.BatchableContext bc, List<JobImage__c> scope){
        IAIImageClassifier classifier = new AIImageClassifier(AIAccessTokenProvider.getTokenInMinutes());
        PhotoViewerCategorizer.create(classifier, scope).run();
    }

    global void finish(Database.BatchableContext bc){}
}