public class ProjectServiceTriggerHandler extends TriggerHandler {
   
    public override void beforeUpdate() {
        
       Boolean changeRecordType = false;
       for (ProjectService__c ps: (List < ProjectService__c > ) Trigger.new) {
           if (ps.ChangeRecordType__c) 
           {
               changeRecordType = true;
               break;
           }
           
       }

        if (changeRecordType)
        {
            Map<String, String> rtmap = AppUtil.GetRecordTypeIds(CONSTANTS.CURRENTNAMESPACEPREFIX + 'ProjectService__c');
            string projectservicertPattern = 'ProjectStatus__c,ProjectType__c,ServiceName__c'; //Default
            string lockedRT = '';
            
            List<UIConfiguration__c> settings = [SELECT ProjectRecordtypePattern__c, ProjectServiceRecordtypePattern__c,
                                                 ProjectLockedRecordType__c, ProjectServiceLockedRecordType__c
                                                 FROM UIConfiguration__c LIMIT 1];
            
            if(settings == null || settings.size() == 0 || settings[0] == null || settings[0].ProjectServiceRecordtypePattern__c == null){
                projectservicertPattern = 'ProjectStatus__c,ProjectTypeName__c,ServiceName__c';
            }
            else
            {
                projectservicertPattern = settings[0].ProjectServiceRecordtypePattern__c;
            }
            
            if(settings == null || settings.size() == 0 || settings[0] == null || settings[0].ProjectServiceLockedRecordType__c == null){
                lockedRT = 'Locked';
            }
            else
            {
                lockedRT = settings[0].ProjectServiceLockedRecordType__c;
            }
            
            
            for (ProjectService__c ps: (List < ProjectService__c > ) Trigger.new) {
                if (ps.ChangeRecordType__c)
                {
                    if (ps.ProjectLocked__c)
                    {
                        ps.RecordTypeId = rtmap.get(lockedRT);
                    }
                    else
                    {
                        ps.RecordTypeId = ProjectServiceActionsHelper.GetRecordType(ps, projectservicertPattern, rtmap);    
                    }
                    ps.ChangeRecordType__c = false;                
                }
            }
            
            
        }
        

        
        if (TriggerUtil.SkipProjectServiceTrigger){
            return;
        }
        
        TriggerUtil.SkipProjectServiceTrigger = true;
        
        List<EntityChangeType__c> ects = [Select Id, Field__c from EntityChangeType__c WHERE Entity__c = 'ProjectService'];
        
        
        Set<Id> pids = new Set<Id>(); 
        
        //Collect all the Project Ids
        for (ProjectService__c ps: (List < ProjectService__c > ) Trigger.new) {
            if (IsProjectServiceChanged(ps, (ProjectService__c) Trigger.oldMap.get(ps.Id),ects))
            {
                pids.add(ps.Project__c);            
            }
            
        }
        List<Project__c> projects = [SELECT Id, IsPendingChanges__c, Status__c FROM Project__c WHERE ID IN : pids and DateLaunched__c != null];
        for (Project__c project: projects ) 
        {
            project.IsPendingChanges__c = true;
        }
        
        TriggerUtil.skipProjectTrigger = true;   
        update projects;
        
    }
   
    public override void afterUpdate() {
        
        /*
        //non bulk scenario. handle project service edits on ui, logic copied from vf ps ctrl
        List<ProjectService__c> newPSList = (List<ProjectService__c>) Trigger.new;
        if(newPSList.size() == 1){
            ProjectService__c newRecord = newPSList[0];
            ProjectService__c oldRecord = (ProjectService__c) Trigger.oldMap.get(newRecord.Id);
            Boolean updateJobs = false;
            Boolean resetJobScheduleDates = false;
            
            system.debug(newRecord.DayNumber__c + ':::' + oldRecord.NumberOfWorkers__c);
            
            if (newRecord.DayNumber__c != oldRecord.DayNumber__c ||  newRecord.NumberOfWorkers__c != oldRecord.NumberOfWorkers__c)
            {
                Integer jobCount = [SELECT count() FROM Job__c WHERE  ProjectService__c = :newPSList[0].Id LIMIT 1];
                
                if (jobCount > 0)
                {
                	newRecord.addError('Changes to Day Number/Number Of Workers not allowed when there are jobs tied to the service. Please delete jobs and retry.');    
                }

            }
        }
		*/
	}
    
    public override void beforeInsert() {

        if(TriggerUtil.skipDeepClonedRecords == true)
            return; 
        //non bulk scenario. prevent wrong services to be added to project
        ProjectService__c ps = ((List<ProjectService__c>) Trigger.new)[0];
        
        Project__c p = [SELECT Id,ProjectType__r.name, Retailer__c,IsSingleServiceProject__c FROM Project__c WHERE Id = :ps.Project__c];
        service__c serv = [select id,IsSingleService__c from service__c where id=:ps.Service__c limit 1];
        Integer validCount = [SELECT count() FROM ProjectTypeService__c where ProjectType__r.Name =: p.ProjectType__r.name and  Service__c = :ps.Service__c AND Service__c  in (SELECT Service__c FROM RetailerService__c where Retailer__c =: p.Retailer__c )];
        
        if(validCount != 1){
            ps.addError('Service cannot be added to the project. Please check the project type and retailer mappings.');
        }
        
        if(serv.IsSingleService__c)
        {
            p.IsSingleServiceProject__c=true;
        }
        else{
            integer cnt = [select count() from projectservice__c where project__c=: p.id and Service__r.IsSingleService__c=true];
            if(cnt==0)
            	p.IsSingleServiceProject__c=false;     
        }
		update p; 
    }
    
    public override void afterInsert() {
        if(TriggerUtil.skipDeepClonedRecords == true)
            return; 
        set<Id> setProjectServiceIds = new set<Id>();
        setProjectServiceIds = Trigger.newmap.keyset();
        set<Id> serviceIds = new set<Id>();
        set<Id> retailerIds = new set<Id>();
        map<string,ProjectService__c> mapRetailService = new map<string,ProjectService__c>();
        
        set<Id> SingleServiceProjID = new set<Id>();
        set<Id> NonSingleServiceProjID = new set<Id>();
        for(ProjectService__c ps: [Select Id,
                                   Project__c,
                                   Project__r.Retailer__c,
                                   Project__r.Status__c,
                                   Service__c,
                                   Service__r.IsSingleService__c,
                                   Project__r.ProjectType__r.Name
                                   FROM ProjectService__c 
                                   where ID IN :setProjectServiceIds])
        {
            if(ps.Service__r.IsSingleService__c)
                SingleServiceProjID.add(ps.project__c);
            else
                NonSingleServiceProjID.add(ps.Project__c);
            
            mapRetailService.put(ps.Project__r.Retailer__c + '-' +  ps.Service__c,ps);
            serviceIds.add(ps.Service__c);
            retailerIds.add(ps.Project__r.Retailer__c);            
        }
      
        
        
        //Insert Project Service Equipment 
        List<ProjectServiceEquipment__c> pseList = new List<ProjectServiceEquipment__c>();
        for(RetailerServiceEquipment__c rse :[SELECT Id, Equipment__c, Retailer__c, Quantity__c, IsLocked__c, Service__c, Equipment__r.EquipmentType__c FROM RetailerServiceEquipment__c WHERE Retailer__c  IN: retailerIds AND Service__c IN : serviceIds]){
            if(mapRetailService.get(rse.Retailer__c + '-' + rse.Service__c) != null){
                ProjectServiceEquipment__c pse = new ProjectServiceEquipment__c();
                pse.ProjectService__c = mapRetailService.get(rse.Retailer__c + '-' + rse.Service__c).Id;
                pse.Equipment__c = rse.Equipment__c;
                pse.Quantity__c = rse.Quantity__c;
                pse.IsLocked__c = rse.IsLocked__c;
                pseList.add(pse);
            }
        }
        if(!pseList.isEmpty()){
            insert pseList;
        }
        
        //Insert Project Service Certification
        List<ProjectServiceCertification__c> pscList = new List<ProjectServiceCertification__c>();
        for(RetailerServiceCertification__c rsc : [SELECT Id, Service__c,Retailer__c, Certification__c FROM RetailerServiceCertification__c WHERE Retailer__c IN : retailerIds AND Service__c IN : serviceIds]){
            if(mapRetailService.get(rsc.Retailer__c + '-' + rsc.Service__c) != null){
                ProjectServiceCertification__c psc = new ProjectServiceCertification__c();
                psc.ProjectService__c = mapRetailService.get(rsc.Retailer__c + '-' + rsc.Service__c).Id;
                psc.Certification__c = rsc.Certification__c;
                psc.IsLocked__c = true;
                pscList.add(psc);
            }
        }
        if(!pscList.isEmpty()){
            insert pscList;
        }
        
    }    
    
    public static Boolean IsProjectServiceChanged(ProjectService__c newprojectservice, ProjectService__c oldprojectservice, List<EntityChangeType__c> ects) {
        
        for (EntityChangeType__c ect : ects)
        {
            system.debug('ect field: ' + ect.Field__c + ':' + newprojectservice.get(ect.Field__c) + ':' + oldprojectservice.get(ect.Field__c));
            
            if (newprojectservice.get(ect.Field__c) != oldprojectservice.get(ect.Field__c))
            {
                system.debug('-----  ect changed -----');
                return true;
            }
        }
        
        return false;
    }    
}