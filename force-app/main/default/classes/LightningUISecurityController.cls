public with sharing class LightningUISecurityController {
    
    
    @AuraEnabled
    public static string getUISecurityInformationApex(string recordid) {
	
        system.debug('recordid: ' + recordid);
        ResponseWrapper rw;
        Project__c project = getProject(recordid);
        
        String projectstatus = project.Status__c;        
        
        UISecurityWrapper uisw = new UISecurityWrapper();
        Map<String, String> projectElements = new Map<String, String>();
        
        if (project != null)
        {
            projectElements.put('Status', projectstatus);
            projectElements.put('PendingChanges', project.IsPendingChanges__c == null ? 'False' : String.valueOf(project.IsPendingChanges__c));
            projectElements.put('ReleasePendingChangesRequest', project.IsPendingChangeReleaseRequest__c == null ? 'False' : String.ValueOf(project.IsPendingChangeReleaseRequest__c));
            projectElements.put('OOCFChanges', project.OutofCycleFulfillment__c == null ? 'False' : String.valueOf(project.OutofCycleFulfillment__c));
            projectElements.put('OOCFChangesRequest', project.OutofCycleFulfillmentRequest__c == null ? 'False' : String.ValueOf(project.OutofCycleFulfillmentRequest__c));
			projectElements.put('ProjectNumber', project.ProjectNumber__c);            
            projectElements.put('OperationsTitle', project.OperationsTitle__c == null ? project.Name : String.ValueOf(project.OperationsTitle__c));
            projectElements.put('Id', project.Id);            
            

            if (!String.isBlank( project.ApexJobName__c))
            {
                projectElements.put('BatchRunning', 'True');
                Map<String, Boolean> hemap = UIConfig.getHiddenElements(); 
                hemap.put('BatchRunning',true);
                uisw.HiddenElements = UIConfig.getHiddenElements(); 
                //Temporary solution. Since Clone button is visible always
                //and not part of uicofig when a project is locked for a 
                //batch process, it becomes visible. Adding it manually for now.
                uisw.HiddenElements.put('Project__c.Clone', true);
                
                
                
                uisw.EditableElements = new Map<String, Boolean>();
                uisw.ProjectElements = projectelements;
                rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_WARNING, project.ApexJobName__c + 
                                                                 ' is in progress. Please allow a few minutes to process your request.', uisw);                
            }
            else
            {
                projectElements.put('BatchRunning', 'False');
                
                uisw.EditableElements = UIConfig.getEditableElements(projectstatus);
                uisw.HiddenElements = UIConfig.getHiddenElements(projectstatus);       
                uisw.ProjectElements = projectelements;
                rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS,'', uisw);                
                
            }
            
            String returnString = JSON.serialize(rw);
            system.debug(returnString);
            return returnString;
        }
        return null;
    }    

    
    @AuraEnabled
    public static string getHiddenElementsApex(string recordid) {
        
        system.debug('recordid: ' + recordid);
        ResponseWrapper rw;
        Project__c project = getProject(recordid);
        if (project != null)
        {
            if (!String.isBlank( project.ApexJobName__c))
            {
                Map<String, Boolean> hemap = UIConfig.getHiddenElements(); 
                hemap.put('BatchRunning',true);
            	rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_WARNING, project.ApexJobName__c + 
                                                                 ' is in progress. Please allow a few minutes to process your request.', hemap);                
            }
            else
            {
                string projectstatus = project.Status__c;
                
            	if (projectstatus != null && projectstatus != '')
                {
                    system.debug('projectstatus: ' + projectstatus);
                    Map<String, Boolean> hemap = UIConfig.getHiddenElements(projectstatus);       
                    hemap.put('BatchRunning',false);
            		rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS,'', hemap);                
                }
            }
            
            String returnString = JSON.serialize(rw);
            system.debug(returnString);
            return returnString;
            
            
        }
        
        
        return null;
    }
    
    
    @AuraEnabled
    public static string getPendingChangesApex(string recordid) {
        
        system.debug('recordid: ' + recordid);
        ResponseWrapper rw;
        Project__c project = getProject(recordid);
        Map<String, Boolean> hemap = new Map<String, Boolean>();         
        
        
        if (project != null)
        {
            hemap.put('PendingChanges', project.IsPendingChanges__c == null ? false : project.IsPendingChanges__c);
            hemap.put('ReleasePendingChangesRequest', project.IsPendingChangeReleaseRequest__c == null ? false : project.IsPendingChangeReleaseRequest__c);

            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS,'', hemap);                
            
            String returnString = JSON.serialize(rw);
            system.debug(returnString);
            return returnString;
        }
        return null;
    }
    

    @AuraEnabled
    public static string getEditableElementsApex(string recordid) {
        
        system.debug('recordid: ' + recordid);
        ResponseWrapper rw;
        Project__c project = getProject(recordid);
        if (project != null)
        {
            if (!String.isBlank( project.ApexJobName__c))
            {
                Map<String, Boolean> emap = new Map<String, Boolean>();       
                emap.put('BatchRunning',true);
            	rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_WARNING, project.ApexJobName__c + 
                                                                 ' is in progress. Please allow a few minutes to process your request.', emap);                
                
            }
            else
            {
                string projectstatus = project.Status__c;
                
                if (projectstatus != null && projectstatus != '')
                {
                    system.debug('projectstatus: ' + projectstatus);
                    Map<String, Boolean> emap = UIConfig.getEditableElements(projectstatus);       
                    emap.put('BatchRunning',false);
            		rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_WARNING,'', emap);                
                    system.debug('emap: ' + emap);
                }
            }
            
            String returnString = JSON.serialize(rw);
            system.debug(returnString);
            return returnString;
            
            
        }

        return null;
    }    
    
    
    private static Project__c getProject(string recordid)
    {
        string projectstatus = '';
        
        Id recid = Id.ValueOf(recordid);
        
        if (String.Valueof(recid.getSObjectType()).containsignorecase('project__c'))       
        {
            return [SELECT Id, Status__c, ApexJobName__c, IsPendingChanges__c, IsPendingChangeReleaseRequest__c, OutofCycleFulfillment__c, OutofCycleFulfillmentRequest__c, ProjectNumber__c, Name, OperationsTitle__c FROM Project__c WHERE Id = :recid LIMIT 1];
        }
        else if (String.Valueof(recid.getSObjectType()).containsignorecase('job__c'))       
        {
            return [SELECT Id, Status__c, ApexJobName__c, IsPendingChanges__c, IsPendingChangeReleaseRequest__c, OutofCycleFulfillment__c, OutofCycleFulfillmentRequest__c, ProjectNumber__c, Name, OperationsTitle__c FROM Project__c WHERE Id IN (Select Project__c from Job__c WHERE Id = :recid) LIMIT 1];
        } 
        else if (String.Valueof(recid.getSObjectType()).containsignorecase('projectservice__c'))       
        {
            return [SELECT Id, Status__c, ApexJobName__c, IsPendingChanges__c, IsPendingChangeReleaseRequest__c, OutofCycleFulfillment__c, OutofCycleFulfillmentRequest__c, ProjectNumber__c, Name, OperationsTitle__c FROM Project__c WHERE Id IN (Select Project__c from ProjectService__c WHERE Id = :recid) LIMIT 1];
        } 
        else if (String.Valueof(recid.getSObjectType()).containsignorecase('projectlocation__c'))       
        {
            return [SELECT Id, Status__c, ApexJobName__c, IsPendingChanges__c, IsPendingChangeReleaseRequest__c, OutofCycleFulfillment__c, OutofCycleFulfillmentRequest__c, ProjectNumber__c, Name, OperationsTitle__c FROM Project__c WHERE Id IN (Select Project__c from ProjectLocation__c WHERE Id = :recid) LIMIT 1];
        }
           

        return null;
        
        
    }

}