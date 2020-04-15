public class JobAttemptWorkerTriggerHandler extends TriggerHandler {
    
    public override void beforeUpdate() {
        
        if (TriggerUtil.skipJobAttemptWorkerTrigger) return;
        TriggerUtil.skipJobAttemptWorkerTrigger = true;

        //we put it here because we do not enforce contact ID must assigned logic below.
        handle3PLImportLogic();

        List<contact> defaultContacts;        
        
        Map<String, JobAttemptWorker__c> leadJobAttemptWorkerMap = new Map<String, JobAttemptWorker__c>();
        Map<String, JobAttemptWorker__c> unassignedleadJobAttemptWorkerMap = new Map<String, JobAttemptWorker__c>();        
        Map<String, JobAttemptWorker__c> thirdPartyAgencyContactChangeMap = new Map<String, JobAttemptWorker__c>();
        
        
        set<String> contactIds = new set<String>();
        
        set<String> jawIds = new set<string>();
        List<String> unAssigned3PLAgencyList = new List<String>();
        
        for (JobAttemptWorker__c jaw: (List < JobAttemptWorker__c>) Trigger.new) {
            
            JobAttemptWorker__c oldjw = (JobAttemptWorker__c) System.Trigger.oldMap.get(jaw.Id);
            if (oldjw.ContactId__c != null)
                contactIds.add(oldjw.ContactId__c); 
            if (jaw.ContactId__c != null)
                contactIds.add(jaw.ContactId__c); 
            
            jawIds.add(jaw.Id);                       
        }
        
        
        if (contactIds.size() == 0) {return;}
        
        //Gets contact object for contact id's
        Map<String,CONTACT> contactsMap = getContacts(contactIds);
        
        if(jawIds.size() == 0) {return;}
        Map<String,JobAttemptWorker__c> plAssignmentMap = get3plAssignments(jawIds);
        
        
        for (JobAttemptWorker__c jw: (List < JobAttemptWorker__c>) Trigger.new) {
            JobAttemptWorker__c oldjw = (JobAttemptWorker__c) System.Trigger.oldMap.get(jw.Id);            
            
            //Assignment Logic
            if(oldjw.ContactId__c !=jw.ContactId__c && jw.ContactId__c != null)
            {
                AssignWorker(oldjw, jw, contactsMap, leadJobAttemptWorkerMap);                
            }
            
            //Unassignment Logic
            if(oldjw.Status__c == CONSTANTS.JOB_ATTEMPT_WORKER_STATUS_ASSIGNED  && 
               jw.Status__c == CONSTANTS.JOB_ATTEMPT_WORKER_STATUS_OPEN)
            {
                UnassignWorker(oldjw, jw, contactsMap, unassignedleadJobAttemptWorkerMap);                
            }
            
            //OH-5488 -             
            if (oldjw.ContactId__c != jw.ContactId__c && oldjw.ContactId__c != null)
            {
                Contact oldContact = contactsMap.get(oldjw.ContactId__c);
                Contact newContact = contactsMap.get(jw.ContactId__c);                

                
                if (newContact == null){
                    jw.ThirdPartyAgencyStatus__c = constants.JOB_ATTEMPT_WORKER_3PL_STATUS_NONE;
                    jw.ThirdPartyAgency__c = null;
                    jw.Contact__c = null;
                    jw.ThirdPartyApprover__c = null;
                }
                else
                {
                    if ((contactsMap.get(oldjw.ContactId__c).Is3PLReq__c == true || oldContact.Account.OneHubAccountType__c == constants.ACCOUNT_TYPE_3PL )){
                                                
                        //if(jw.ContactId__c != AppUtil.ThirdPartyAgencyDeniedContactId && newContact.Account.OneHubAccountType__c != constants.ACCOUNT_TYPE_3PL)                    
                        if(jw.ContactId__c != constants.THIRD_PARTY_CONTACT_3PL_DENIED && newContact.Account.OneHubAccountType__c != constants.ACCOUNT_TYPE_3PL)                    
                        {
                            jw.ThirdPartyAgencyStatus__c = constants.JOB_ATTEMPT_WORKER_3PL_STATUS_CANCELED_REASSGINED_TO_CMK;
                        }
                        
                        jw.ThirdPartyAgency__c = newContact.Account.OneHubAccountType__c != constants.ACCOUNT_TYPE_3PL ? null : newContact.AccountId;                    
                    }  
                }
                
                unAssigned3PLAgencyList.add(oldjw.Id);
            }               
            
            if((oldjw.ThirdPartyAgency__c) != null && (oldjw.ThirdPartyAgency__c != jw.ThirdPartyAgency__c))
            {
                if (!thirdPartyAgencyContactChangeMap.containsKey(oldjw.Id)) {                          
                    thirdPartyAgencyContactChangeMap.put(oldjw.Id, oldjw);                            
                }
            }
            
            //Update Supervisor Email everytime we capture an update for a JAW
            //This is to make sure we get supervisor changes if any.
            //Update Supervisor information 
            if (contactsMap.get(jw.ContactId__c) != null)
            {
                UpdateSupervisorInfo(jw, contactsMap);                
            }
            
            CalculateTimeAdjusted(oldjw, jw);
            
            if (oldjw.ContactId__c != jw.ContactId__c && jw.ContactId__c != null && contactsMap.containsKey(jw.ContactId__c) && contactsMap.get(jw.ContactId__c).Is3PLReq__c == true) {
                
                if(plAssignmentMap.containsKey(jw.Id))
                {                    
                    JobAttemptWorker__c jobAttemptWorker  = plAssignmentMap.get(jw.Id); 
                    
                    string prjLocationContactAccount =jobAttemptWorker.JobAttempt__r.Job__r.ProjectLocation__r.ThirdPartyAgencyContact__r.AccountId !=null ? string.valueOf(jobAttemptWorker.JobAttempt__r.Job__r.ProjectLocation__r.ThirdPartyAgencyContact__r.AccountId):'';
                    
                    if(prjLocationContactAccount != '')                        
                    {
                        jw.ThirdPartyApprover__c  = jobAttemptWorker.JobAttempt__r.Job__r.ProjectLocation__r.ThirdPartyAgencyContact__r.Account.ThirdPartyApprover__c!=null? Id.valueOf(jobAttemptWorker.JobAttempt__r.Job__r.ProjectLocation__r.ThirdPartyAgencyContact__r.Account.ThirdPartyApprover__c): null; 
                        jw.ThirdPartyAgency__c  = Id.valueOf(jobAttemptWorker.JobAttempt__r.Job__r.ProjectLocation__r.ThirdPartyAgencyContact__r.AccountId);
                        jw.ThirdPartyAgencyStatus__c ='Requested';
                    }
                    else
                    {                        
                        jw.ThirdPartyApprover__c  = jobAttemptWorker.JobAttempt__r.Job__r.Project__r.ProjectType__r.Default3PLAccount__r.ThirdPartyApprover__c!=null? Id.valueOf(jobAttemptWorker.JobAttempt__r.Job__r.Project__r.ProjectType__r.Default3PLAccount__r.ThirdPartyApprover__c) : null;
                        jw.ThirdPartyAgency__c  = jobAttemptWorker.jobAttempt__r.Job__r.Project__r.ProjectType__r.Default3PLAccount__c !=null ? id.valueOf(jobAttemptWorker.jobAttempt__r.Job__r.Project__r.ProjectType__r.Default3PLAccount__c):'';
                        jw.ThirdPartyAgencyStatus__c ='Requested';
                    }
                }
            }
        }
        
        // To remove \ cancel pending approval process when contacts are being re assigned         
        JobAttemptWorkerHelper.CancelPending3PLRequest(unAssigned3PLAgencyList);        
        
        //OH-5487 - to send email on 3pl contact change
        thirdPartyAgencyChangeEmail(thirdPartyAgencyContactChangeMap);
        
        //To update job attempt with assigned supervisor - OH-4607
        updateLeadContactInJobAttempt(leadJobAttemptWorkerMap);
        
        //Update Job Attempt when a Team Lead is unassigned
        unassignLeadContactInJobAttempt(unassignedleadJobAttemptWorkerMap);        
        
    }

    Boolean Is3PLFirstLastNameChanged(JobAttemptWorker__c oldState, JobAttemptWorker__c newState) {
        return oldState.FirstName__c != newState.FirstName__c
            || oldState.LastName__c != newState.LastName__c;
    }

    Boolean is3PLAgentAccepted(JobAttemptWorker__c oldState) {
        return oldState.ThirdPartyAgencyStatus__c == CONSTANTS.JOB_ATTEMPT_WORKER_3PL_STATUS_ACCEPTED;
    }

    Boolean is3PLImportAllowed(JobAttemptWorker__c oldState) {
        return oldState.My3PLWork__c == true 
            && ( oldState.ThirdPartyAgencyStatus__c == CONSTANTS.JOB_ATTEMPT_WORKER_3PL_STATUS_ACCEPTED 
              || oldState.ThirdPartyAgencyStatus__c == CONSTANTS.JOB_ATTEMPT_WORKER_3PL_STATUS_COMMITTED);
    }

    Boolean isFirstLastNameValid(JobAttemptWorker__c newState) {
        return String.isNotBlank(newState.FirstName__c) 
            && String.isNotBlank(newState.LastName__c);
    }

    //OH2-1592
    void handle3PLImportLogic() { 
        for(JobAttemptWorker__c newState: (List<JobAttemptWorker__c>) Trigger.new) {
            JobAttemptWorker__c oldState = (JobAttemptWorker__c) Trigger.oldMap.get(newState.Id);  
            if( is3PLImportAllowed(oldState) ) {
                if (isFirstLastNameValid(newState)){
                    if (Is3PLFirstLastNameChanged(oldState, newState) && is3PLAgentAccepted(oldState)){
                        newState.ThirdPartyAgencyStatus__c = CONSTANTS.JOB_ATTEMPT_WORKER_3PL_STATUS_COMMITTED;
                    }
                } else {
                    newState.FirstName__c = oldState.FirstName__c;
                    newState.LastName__c = oldState.LastName__c;
                    newState.ThirdPartyAgencyStatus__c = oldState.ThirdPartyAgencyStatus__c;
                }
            }
        }
    }
    
    static void thirdPartyAgencyChangeEmail(Map<String, JobAttemptWorker__c> thirdPartyAgencyContactChangeMap){
        
        Set<Id> contactIds = new Set<Id>();
        
        for(Id key : thirdPartyAgencyContactChangeMap.keyset()) {
            contactIds.add(thirdPartyAgencyContactChangeMap.get(key).Contact__c);
        }
        
        Map<ID, Contact> contacts = new Map<ID, Contact>([select Id,Email, Is3PLReq__c from Contact where Id in :contactIds]);
        
        for(Id key : thirdPartyAgencyContactChangeMap.keyset()) {
            
            JobAttemptWorker__c jaw = thirdPartyAgencyContactChangeMap.get(key);
            Contact objContact = contacts.get(jaw.Contact__c);
            
            if (objContact.Is3PLReq__c){
                
                List<String> toRecipients = new List<String>();
                List<String>ccRecipients = new List<String>();
                String templateApiName;
                ID targetObjId, whatId;
                
                templateApiName = AppUtil.ThirdPartyAgencyChangeEmailTemplateName;
                
                if (templateApiName != null && templateApiName != ''){
                    toRecipients.add(objContact.Email);                
                    
                    AppUtil.sendTemplatedEmail(toRecipients,ccRecipients,templateApiName,objContact.Id,jaw.Id,false,null);
                }
            }
        }
    }
    
    //OH-4607 
    //Update the Job Attempt Status to assigned
    //and Assigned contact to Assigned COntact Id
    static void updateLeadContactInJobAttempt(Map<String, JobAttemptWorker__c> leadJobAttemptWorkerMap) {
        
        List<JobAttempt__c> jobAttempts =  [SELECT Id, AssignedContact__c, AssignedContactId__c FROM JobAttempt__c WHERE 
                                            ID IN :leadJobAttemptWorkerMap.keyset()];
        
        for(JobAttempt__c jobAttempt : jobAttempts){
            JobAttemptWorker__c jobAttemptWorker  = leadJobAttemptWorkerMap.get(jobAttempt.Id);            
            jobAttempt.AssignedContactId__c = jobAttemptWorker.ContactId__c;  
            jobAttempt.AssignedContact__c = jobAttemptWorker.Contact__c;  
            jobAttempt.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_ASSIGNED;
        }                
        
        update jobAttempts;
    }
    
    static void unassignLeadContactInJobAttempt(Map<String, JobAttemptWorker__c> unassignedleadJobAttemptWorkerMap) {
        
        List<JobAttempt__c> jobAttempts =  [SELECT Id, AssignedContact__c, AssignedContactId__c FROM JobAttempt__c WHERE 
                                            ID IN :unassignedleadJobAttemptWorkerMap.keyset()];
        
        for(JobAttempt__c jobAttempt : jobAttempts){
            JobAttemptWorker__c jobAttemptWorker  = unassignedleadJobAttemptWorkerMap.get(jobAttempt.Id);            
            jobAttempt.AssignedContactId__c = null;  
            jobAttempt.AssignedContact__c = null;  
            jobAttempt.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_OPEN;
        }                
        update jobAttempts;
    }    
    
    static Map<String,CONTACT> getContacts(Set<String> contactIdSet) {
        
        Map<String,CONTACT> result = new Map<String,CONTACT>();
        if (contactIdSet.size() == 0) {
            return result;
        }
        
        for(Contact person: [SELECT Id, ContactId__c, Email, FirstName, LastName, ReportsTo.Email, 
                             ReportsTo.FirstName, ReportsTo.LastName, ReportsTo.Phone, Is3PLReq__c, 
                             Account.OneHubAccountType__c, AccountId
                             FROM CONTACT 
                             WHERE ContactId__c != '' 
                             AND ContactId__c IN :contactIdSet]) {
                                 result.put(person.ContactId__c, person);
                             }
        
        return result;
    }
    
    static map<string,JobAttemptWorker__c> get3plAssignments(Set<String> jawIds)
    {
        
        Map<String,JobAttemptWorker__c> result = new Map<String,JobAttemptWorker__c>();
        
        if(jawIds.size()==0) {
            return result;
        }
        
        for(JobAttemptWorker__c jaw :[Select Id,name,JobAttempt__r.Job__r.ProjectLocation__r.ThirdPartyAgencyContact__r.AccountId,
                                      JobAttempt__r.Job__r.ProjectLocation__r.ThirdPartyAgencyContact__r.Account.ThirdPartyApprover__c,
                                      jobAttempt__r.Job__r.Project__r.ProjectType__r.Default3PLAccount__c,
                                      JobAttempt__r.Job__r.Project__r.ProjectType__r.Default3PLAccount__r.ThirdPartyApprover__c
                                      FROM JobAttemptWorker__c 
                                      where Id IN : jawIds  
                                     ])
        {
            
            
            result.put(jaw.Id,jaw);
        }
        
        return result;
        
    }    
    
    private void AssignWorker(JobAttemptWorker__c oldjw, JobAttemptWorker__c jw, Map<String,CONTACT> contactsMap, Map<String, JobAttemptWorker__c> leadJobAttemptWorkerMap)
    {
        
        if (contactsMap.containsKey(jw.ContactId__c)) {
            jw.Contact__c  = contactsMap.get(jw.ContactId__c).Id ;
            jw.DateAssigned__c = DateTime.Now();
            
            //collect all lead contact info to update Job Attempt sObject - OH-4607
            if (jw.WorkerType__c == CONSTANTS.JOB_ATTEMPT_WORKER_WORKER_TYPE_TEAM_LEAD){
                leadJobAttemptWorkerMap.put(jw.JobAttempt__c, jw);
            }                    
        }
        else
        {
            jw.addError('ContactId: ' + jw.ContactId__c + ' not found in the system.');
        }
        
    }
    
    private void UnassignWorker(JobAttemptWorker__c oldjw, JobAttemptWorker__c jw, Map<String,CONTACT> contactsMap, Map<String, JobAttemptWorker__c> unassignedLeads)
    {
        
        jw.Contact__c  = null;
        jw.ContactId__c  = null;
        //collect all lead contact info to update Job Attempt sObject - OH-4607
        if (jw.WorkerType__c == CONSTANTS.JOB_ATTEMPT_WORKER_WORKER_TYPE_TEAM_LEAD){
            unassignedLeads.put(jw.JobAttempt__c, jw);
        }                    
        
    }    
    
    private void UpdateSupervisorInfo(JobAttemptWorker__c jw, Map<String,CONTACT> contactsMap)
    {
        
        if (contactsMap.get(jw.ContactId__c).ReportsTo.Email != null)
        {
            jw.SupervisorEmail__c = contactsMap.get(jw.ContactId__c).ReportsTo.Email;
            jw.SupervisorFirstName__c = contactsMap.get(jw.ContactId__c).ReportsTo.FirstName;
            jw.SupervisorLastName__c = contactsMap.get(jw.ContactId__c).ReportsTo.LastName;
            jw.SupervisorPhone__c = contactsMap.get(jw.ContactId__c).ReportsTo.Phone;
        }
        jw.ContactEmail__c = contactsMap.get(jw.ContactId__c).Email;            
        
    }
    
    private void CalculateTimeAdjusted(JobAttemptWorker__c oldjw, JobAttemptWorker__c jw)
    {
        
        if (oldjw.ECWorkerTime__c != jw.ECWorkerTime__c || oldjw.TotalInStoreTime__c != jw.TotalInStoreTime__c || 
            oldjw.TotalInStoreNonBillableTime__c != jw.TotalInStoreNonBillableTime__c)
        {
            //Update the time adjusted
            if (jw.TotalInStoreTime__c != null && jw.ECWorkerTime__c != null && 
                jw.ECWorkerTime__c > 0)
            {
                jw.TimeAdjusted__c = jw.ECWorkerTime__c - (jw.TotalInStoreTime__c - jw.TotalInStoreNonBillableTime__c);    
            }
            
        }
        
        
    }
    
}