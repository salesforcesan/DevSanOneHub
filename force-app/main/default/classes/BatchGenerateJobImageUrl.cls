global class BatchGenerateJobImageUrl implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful, Database.RaisesPlatformEvents{
    
    @testVisible 
    Id[] jobImageIds;
    
    global BatchGenerateJobImageUrl (Id[] jobImageIds){
        this.jobImageIds = jobImageIds;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([Select Id,name,ImageURL__c,ImageContentType__c,ProcessingPickupDateTime__c,ImageName__c, ImageDescription__c, Job__c,AttachmentId__c, ProjectLocation__c, Project__c  from JobImage__c  where Id in :jobImageIds]);
    }
    
    global void execute(Database.BatchableContext BC, List<JobImage__c> scope) {
        for(JobImage__c ji: scope)
        {
            
            if(!(String.isBlank(ji.AttachmentId__c)))
            {
                JobImageHandler.DoGenerateNewJobImageURL(ji);
            }
        }
        
    }
    
    global void finish(Database.BatchableContext BC) {
        List<JobImage__c> lstjobImage = [Select Id,name,ImageURL__c,ImageContentType__c,ProcessingPickupDateTime__c,ImageName__c, ImageDescription__c, Job__c,AttachmentId__c, ProjectLocation__c, Project__c  from JobImage__c  where id IN :jobImageIds];
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :BC.getJobId()];    
        List<Id> failedJobImages = new List<Id>();
        if (a.NumberOfErrors > 0 )
        {
            for(JobImage__c ji :lstjobImage )
            {
                
                if(string.isEmpty(ji.ImageURL__c))
                {
                    failedJobImages.add(ji.Id);
                }
            }
            
            String email = EmailHelper.getEmailDistribution();
            If (String.isBlank(email)) {return;} 
            List<String> emailList= new List<String>{email};
            string subject = 'batch Job Images failed Email Notification';
            EmailHelper.SendEmail(emailList,subject,genHtmlBody(failedJobImages));
            
            
        }
        
    }
    
    @testVisible 
    String genHtmlBody(List<Id> failedJobImages){
        List<String> html = new List<String>();
        html.add('<h1>Job Image failed  List</h1>');
        html.add('<br/></br>');
        //html.add('<div>Total Number of Job Images Failed : ' + failedJobImages.size() + '</div>');
        
        html.add('<div>Total Number of Job Image Id\'s Failed : ' + String.Join(failedJobImages,',') + '</div>');
        
        return String.join(html,'');
    }
    
}