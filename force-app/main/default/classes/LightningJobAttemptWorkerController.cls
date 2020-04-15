public without sharing class LightningJobAttemptWorkerController {
    @AuraEnabled
    public static string getThirdPartyAgencyReportUrl(string jobAttemptWorkerId)
    {
        jobAttemptWorkerId = jobAttemptWorkerId == null ? '' : jobAttemptWorkerId;
        string jobAttemptWorkerUrl = string.valueOf(AppUtil.ExportJobAttemptWorkerReportUrl.replace('{JobAttemptWorkerId}',jobAttemptWorkerId));
        return jobAttemptWorkerUrl; 
    }
    
    @AuraEnabled
    public static string getLoggedInUserThirdPartyAgency(string loggedInuserId)
    {
        list<Account> accList;
        List<ThirdpartyAgencyRecordsLocker__c> tal;
        string result;
        string accId;
        List<User> lstUser = [select id,Name,ThirdPartyAgency__c from User  where Id =:loggedInuserId]; 
        if(lstUser!=null && lstUser.size() >0)
        {
          user u =  lstUser[0];
          if(String.isBlank(u.ThirdPartyAgency__c) )
          {
              throw new AuraHandledException('please enter thrid party Agency Name on user object ');
          }
            
           String likeFilter ='\'%' + String.escapeSingleQuotes(u.ThirdPartyAgency__c) + '%\'';
           //string thirdPartyAgency = '%'+ String.escapeSingleQuotes() +'%';
           String Query = 'Select Id, Name FROM Account WHERE Name LIKE ' + likeFilter;
           accList = Database.Query(Query);
           if(accList.size()> 0) 
           {
              tal = [select Id,Account__c  from ThirdpartyAgencyRecordsLocker__c  where Account__c =:accList[0].Id]; 
              if( tal.isEmpty() ) {
                  
                  ThirdpartyAgencyRecordsLocker__c tar = new ThirdpartyAgencyRecordsLocker__c();
                  tar.Account__c = accList[0].Id;
                  insert tar;
                  
                  result = tar.Id;
                 // system.debug('Result++++'+result);
                  
              }
               else
               {
                   result=tal[0].Id;
               }
               
           }
        // system.debug('hello' + accList);
            
         // accList = [select Id,name from Account where name like :thirdPartyAgency];
          
        }
         if(!(String.isBlank(result)))
         {
             tal = [select Id,Account__c  from ThirdpartyAgencyRecordsLocker__c  where Id =:result];
             accId =tal[0].Account__c;
         }
         return accId;
    }
    
       @AuraEnabled
    public static List<JobAttemptWorkerWrapper> fetch3PLAgencyPendingApprovalList(string userId) {
        List<JobAttemptWorker__c> jawList = new List<JobAttemptWorker__c>();
        
        jawList = JobAttemptWorkerHelper.Get3PLAgencyPendingApprovalList();
        
        list<JobAttemptWorkerWrapper> awList = new list<JobAttemptWorkerWrapper>();
        for(JobAttemptWorker__c jw : jawList)
        {            
            awList.add(new JobAttemptWorkerWrapper(jw));
        }
        
        Return awList;
        
    }
     
    
    @AuraEnabled
    public static void pending3PLRequests(List<string> jawList,string reqComments, String approverReqStatus) 
    {
        
        JobAttemptWorkerHelper.ApprovePending3PLRequest(jawList,reqComments,approverReqStatus);
        
        /* if (approverReqStatus == CONSTANTS.APPROVAL_STATUS_APPROVE){
// Set Contact ID in Job Attempt Worker

Map<ID, JobAttemptWorker__c> jawMap = new Map<ID, JobAttemptWorker__c>([select Id,ThirdPartyAgency__c,Contact__c from JobAttemptWorker__c where Id in :jawList]);
Set<Id> accountIds = new Set<Id>();

for(Id key : jawMap.keyset()) {
accountIds.add(jawMap.get(key).ThirdPartyAgency__c);
}

Map<ID, Account> accounts = new Map<ID, Account>([select Id,ThirdPartyAgencyPrimaryContact__c from Account where Id in :accountIds]);

List<JobAttemptWorker__c> jawToBeUpdatedList = new List<JobAttemptWorker__c>();

for(Id key : jawMap.keyset()) {
JobAttemptWorker__c jaw = jawMap.get(key);
if (jaw.ThirdPartyAgency__c != null && accounts.get(jaw.ThirdPartyAgency__c) != null ){
jaw.Contact__c = accounts.get(jaw.ThirdPartyAgency__c).ThirdPartyAgencyPrimaryContact__c;
jawToBeUpdatedList.add(jaw);
}                
}

update jawToBeUpdatedList;

/* 
SELECT ID, JobAttempt__r.Job__r.ProjectLocation__r.ThirdPartyAgencyContact__c, jobAttempt__r.Job__r.Project__r.ProjectType__r.Default3PLAccount__c 
FROM JobAttemptWorker__c where ID : 


if(String.valueOf(jobAttemptWorker.JobAttempt__r.Job__r.ProjectLocation__r.ThirdPartyAgencyContact__r.AccountId)!=null  &&  String.valueOf(jobAttemptWorker.JobAttempt__r.Job__r.ProjectLocation__r.ThirdPartyAgencyContact__r.AccountId)!='')

{
system.debug('Iam inside');
// system.debug('agencey' + plAssignmentMap.get(jw.Id).JobAttempt__r.Job__r.ProjectLocation__r.ThirdPartyAgencyContact__r.AccountId);
jw.ThirdPartyApprover__c  = jobAttemptWorker.JobAttempt__r.Job__r.ProjectLocation__r.ThirdPartyAgencyContact__r.Account.ThirdPartyApprover__c!=null? Id.valueOf(jobAttemptWorker.JobAttempt__r.Job__r.ProjectLocation__r.ThirdPartyAgencyContact__r.Account.ThirdPartyApprover__c): null; 
jw.ThirdPartyAgency__c  = Id.valueOf(jobAttemptWorker.JobAttempt__r.Job__r.ProjectLocation__r.ThirdPartyAgencyContact__r.AccountId);
jw.ThirdPartyAgencyStatus__c ='Requested';
}
else
{
//system.debug('Iam else Part::' + jw.Id);
//system.debug('default contacts'+ defaultContacts.size());
jw.ThirdPartyApprover__c  =  jobAttemptWorker.JobAttempt__r.Job__r.Project__r.ProjectType__r.Default3PLAccount__r.ThirdPartyApprover__c!=null? Id.valueOf(jobAttemptWorker.JobAttempt__r.Job__r.Project__r.ProjectType__r.Default3PLAccount__r.ThirdPartyApprover__c) : null;
jw.ThirdPartyAgency__c  = jobAttemptWorker.jobAttempt__r.Job__r.Project__r.ProjectType__r.Default3PLAccount__c !=null?id.valueOf(jobAttemptWorker.jobAttempt__r.Job__r.Project__r.ProjectType__r.Default3PLAccount__c):'';
jw.ThirdPartyAgencyStatus__c ='Requested';


}

*/
        //    }
    }
}