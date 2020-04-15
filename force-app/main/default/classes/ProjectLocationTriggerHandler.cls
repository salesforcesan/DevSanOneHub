public class ProjectLocationTriggerHandler extends TriggerHandler {
    static final Blob cryptoIv;
    static final Blob cryptoKey;
    static {
        SurveyPhotoViewerSetting__c setting  = SurveyPhotoViewerSetting__c.getOrgDefaults();
        cryptoIv = Blob.ValueOf(String.valueOf(setting.Iv__c == null? '': setting.Iv__c));
        cryptoKey = Blob.ValueOf(String.valueOf(setting.Key__c == null? '': setting.Key__c));
    }
    
    public override void afterUpdate() 
    {
        
        Map<String,Date> schedDateLocationMap = new Map<String,Date>();
        
        for(ProjectLocation__c current : (List<ProjectLocation__c >) trigger.new)
        {
            ProjectLocation__c old = getOld(current.Id);
            if (current.LocationScheduledDate__c != old.LocationScheduledDate__c)    
            {                
                schedDateLocationMap.put(current.Id, current.LocationScheduledDate__c);    
            }
        }
        
        if (schedDateLocationMap.size() > 0)        
        {
            ProcessScheduledDateChanges(schedDateLocationMap);
        }
        
    }
    
    public override void beforeUpdate() {
        set<Id> projLocationIds = new set<Id>();
        
        Set<String> ThirdPartyAgencyContactIdList = new set<String>();
		Map<String, Contact> ThirdPartyAgencyContactListMap = new Map<String, Contact>();
        
        
        for(ProjectLocation__c current : (List<ProjectLocation__c >) trigger.new)
        {
            ProjectLocation__c old = getOld(current.Id);             
            
            if (String.isBlank(current.SurveyPhotoViewerEncodedId__c))
            	current.SurveyPhotoViewerEncodedId__c = processEncryption(current.Id);
            
           if (current.OneHubThirdPartyAgencyContactId__c != old.OneHubThirdPartyAgencyContactId__c){
                ThirdPartyAgencyContactIdList.add(current.OneHubThirdPartyAgencyContactId__c);
            }
            
            if (ThirdPartyAgencyContactIdList.size() > 0)        		
	        {		
	            ThirdPartyAgencyContactListMap = ProcessThirdPartyAgency(ThirdPartyAgencyContactIdList);		
	        }		
			
            if ((ThirdPartyAgencyContactListMap != null) && ThirdPartyAgencyContactListMap.size() > 0)		
            {
                if (current.OneHubThirdPartyAgencyContactId__c != old.OneHubThirdPartyAgencyContactId__c)    		
                {		
                    Contact acc = ThirdPartyAgencyContactListMap.get(current.OneHubThirdPartyAgencyContactId__c);                    		
                    
                    if (acc!= null){		
                        current.ThirdPartyAgencyContact__c = acc.Id;		
                    }
                }
            }
            
            if (current.BillingStatus__c != old.BillingStatus__c && 
                old.BillingStatus__c == CONSTANTS.BILLING_STATUS_NEEDSREVIEW)    
            {
                current.BillingReviewed__c = true;	    
            }
            
        }
    }
    
    @TestVisible 
    private static string processEncryption(Id recId){
        Blob cipherText = Crypto.encrypt('AES128', cryptoKey, cryptoIv, Blob.valueOf(recId));
        
        string encodedrecId = EncodingUtil.base64Encode(cipherText); 
        return encodedrecId;
    }
        
    private static ProjectLocation__c getOld(Id plId) {
        return (ProjectLocation__c) Trigger.oldMap.get(plId);
    }    
    
    @TestVisible
    private static void ProcessScheduledDateChanges(Map<String, Date> schedDateLocationMap) 
    {
        
        Map<String, Date> jobsSchedMap = new Map<String, Date>();       
        List<Job__c> jobs = [Select Id, name, projectlocation__c 
                             from job__c 
                             WHERE projectlocation__c in :schedDateLocationMap.keySet()];
        
        for (Job__c job: jobs)
        {
            if (schedDateLocationMap.get(job.ProjectLocation__c) != null)
            {
                jobsSchedMap.put(job.Id,schedDateLocationMap.get(job.projectlocation__c));    
            }
        }
        
        if (!jobsSchedMap.isEmpty())
        {
            List<ActionResponse> jars = JobActionsHelper.setScheduledDate(jobsSchedMap);
        }
        
    }
        
    @TestVisible
    private static Map<String, Contact> ProcessThirdPartyAgency(Set<String> ThirdPartyAgencyIdList) 		
    {		
        Map<String, Contact> ThirdPartyAgencyContactListMap = new Map<String, Contact>();  		
        
        List<Contact> contacts = [Select ID, OneHubThirdPartyAgencyContactId__c 
                                  From Contact 
                                  Where OneHubThirdPartyAgencyContactId__c in :ThirdPartyAgencyIdList];        		
        
        for (Contact contact: contacts)		
        {		
            ThirdPartyAgencyContactListMap.put(contact.OneHubThirdPartyAgencyContactId__c, contact);                		
        }      		
        
        return ThirdPartyAgencyContactListMap;		
    }

}