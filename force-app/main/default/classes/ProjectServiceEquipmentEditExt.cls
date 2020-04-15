public with sharing class ProjectServiceEquipmentEditExt {
    
    public ProjectService__c ps{get;set;}
    public List<ProjectServiceEquipment__c> pseList {get;set;}
    public List<SelectOption> EquipmentSelectOptions {get;set;}
    public string SelectedEquipment{get;set;}
    public string SelectedQuantity{get;set;}
    public Project__c project {get;set;}    
    public Boolean showEqButtons{get;set;}
    public Boolean showToolsButtons{get;set;}
    public List<SelectOption> utensilList{get;set;}
    public List<SelectOption> SelectedUtensilList{get;set;} 
    public List<String> selectedUtensils{get;set;} 
    public Map<String,Boolean> editableMap {get;set;}
           
    /*public Boolean showEditCapacityImpact{
        get {
            return Schema.sObjectType.ProjectServiceEquipment__c.fields.IsCapacityImpact__c.isUpdateable();
        }
    }*/

    
    private void addMessage(ApexPages.Severity severity, String message){
        Apexpages.addMessage(new ApexPages.Message(severity, message));
    }
    public string eqAsset{get;set;}
    public string eqTools{get;set;}
    
    public ProjectServiceEquipmentEditExt(ApexPages.StandardController controller) {
        ps = [SELECT Id, Name, Project__r.Retailer__c, Project__c, Project__r.Status__c, Service__c FROM ProjectService__c where id =:ApexPages.CurrentPage().getParameters().get('id') ];
        eqAsset = [SELECT Value__c FROM AppSettings__mdt WHERE DeveloperName = 'EquimentTypeAsset' limit 1].Value__c;
        eqTools = [SELECT Value__c FROM AppSettings__mdt WHERE DeveloperName = 'Equimenttypetool' limit 1].Value__c;
         
        loadEquipment();
        EquipmentSelectOptions = new List<SelectOption>();
        EquipmentSelectOptions.add(new SelectOption('','-None-'));
        for(Equipment__c eq : [SELECT Id, Name FROM Equipment__c WHERE EquipmentType__c=:eqAsset and ID NOT IN (SELECT Equipment__c FROM RetailerServiceEquipment__c WHERE Retailer__c =: ps.Project__r.Retailer__c AND Service__c =: ps.Service__c)]){
            EquipmentSelectOptions.add(new SelectOption(eq.Id, eq.Name));
        }
        
        Set<String> editableFields = new Set<String>{'Project__c.RL_Equipment', 'Project__c.RL_Tools'};
        editableMap = UIConfig.isEditale(project.Status__c, editableFields);
        showEqButtons = editableMap.get('Project__c.RL_Equipment') && Schema.sObjectType.ProjectServiceEquipment__c.isUpdateable();
        showToolsButtons = editableMap.get('Project__c.RL_Tools') && Schema.sObjectType.ProjectServiceEquipment__c.isUpdateable();

        
        SelectedUtensilList = new List<SelectOption>();
        selectedUtensils = new List<String>();
        set<id> pse = new set<id>();
        for(projectserviceEquipment__c eq : [SELECT Id, equipment__r.Name,equipment__r.id,equipment__r.description__c   FROM projectserviceEquipment__c WHERE  equipment__r.EquipmentType__c=:eqTools and projectservice__c =: ps.id order by equipment__r.Name]){
            SelectedUtensilList.add(new SelectOption(eq.equipment__r.Id, eq.equipment__r.description__c));
            pse.add(eq.equipment__r.Id);
            selectedUtensils.add(eq.equipment__r.description__c);
        }
        
        utensilList= new List<SelectOption>();
        for(Equipment__c eq : [SELECT Id, Name,description__c FROM Equipment__c WHERE isactive__c =true and EquipmentType__c=:eqTools and id not in:pse order by name]){
            utensilList.add(new SelectOption(eq.Id, eq.description__c));    
        }
    }
    
    public void loadEquipment(){
        pseList = [SELECT Id, Equipment__c, ProjectService__c, Quantity__c, IsLocked__c, ProjectService__r.Project__c  FROM ProjectServiceEquipment__c WHERE ProjectService__c =:ps.Id and equipment__r.EquipmentType__c=:eqAsset ORDER BY IsLocked__c DESC];
        ProjectService__c tmpPs = [SELECT Id, Project__c, Service__c FROM ProjectService__c where id =:ApexPages.CurrentPage().getParameters().get('id') ];
        project = [SELECT Id, Status__c FROM Project__c where id =:tmpPs.Project__c];

    }
    
    public PageReference addEquipment() {
        try {
            if(String.isBlank(SelectedEquipment)){
                addMessage(ApexPages.Severity.ERROR,'Please select asset.');                
                return null;
            }
            
            for (ProjectServiceEquipment__c pse : pseList)    
            {
                if (pse.Equipment__c == SelectedEquipment)
                {
                    addMessage(
                        ApexPages.Severity.ERROR, 
                        'This asset has already been added. Please check and try again.'
                    );
                    return null;
                }
            }
            
            Pattern isnumber = Pattern.Compile('^[0-9]+$');
            Matcher patterMatch = isnumber.matcher(SelectedQuantity);
            if(!patterMatch.Matches() || (Integer.valueOf(SelectedQuantity) <= 0 || Integer.valueOf(SelectedQuantity) > 99999)){
                addMessage(ApexPages.Severity.ERROR, 'Invalid Quantity. Please check and try again.');
                return null;
            }
            
            Equipment__c e = [SELECT EquipmentType__c FROM Equipment__c WHERE ID  = :SelectedEquipment];
            ProjectServiceEquipment__c pse = new ProjectServiceEquipment__c();
            pse.ProjectService__c = ps.Id;
            pse.Equipment__c = SelectedEquipment;
            pse.Quantity__c = Decimal.valueOf(SelectedQuantity);
            
            pse.IsLocked__c = false;
            insert pse;
            loadEquipment();
            SelectedQuantity = '';
            SelectedEquipment = '';
            system.debug('project::::'+project);
            
            TriggerUtil.SkipProjectTrigger = true;
            update project;
            
            return null;
        }
        catch(Exception e){
                        addMessage(ApexPages.Severity.ERROR, e.getmessage());
            return null;
        }
    }
    
    public PageReference deleteEquipment(){
        try {  
            string pseDelId = ApexPages.currentpage().getParameters().get('pseDelId');
            for (ProjectServiceEquipment__c pse : pseList) {
                if (pseDelId == pse.Id) {
                    
                        delete pse;
                        break;
                }
            }
            addMessage(ApexPages.Severity.CONFIRM, 'Asset deleted.');
            loadEquipment();
           
            TriggerUtil.SkipProjectTrigger = true;
            update project;
                return null;
        }
                catch(Exception e) {
            addMessage(ApexPages.Severity.ERROR, e.getmessage());
            //system.debug('aaaaaa: '+e.getmessage());
            return null;
        }
    }
    
    
    public PageReference saveEditRows() {
        if(pseList.size() == 0) {
            return null;
        }
        try { 
            for(ProjectServiceEquipment__c pse:pseList){
                Map<ID,Decimal> lockedEqupmentMap = getLockedEqupment();
                if(lockedEqupmentMap.containsKey(pse.Equipment__c) && pse.Quantity__c < lockedEqupmentMap.get(pse.Equipment__c)){
                        addMessage(ApexPages.Severity.ERROR, 'Locked asset quantity cannot be reduced.');
                        return null;
                }
                
                if(pse.Quantity__c <= 0 || pse.Quantity__c > 99999){
                        addMessage(ApexPages.Severity.ERROR, 'Invalid Quantity. Please check and try again.');
                        return null;
                }
                
                if(String.isBlank(pse.Equipment__c)){
                        addMessage(ApexPages.Severity.ERROR, 'Please select Asset.');
                        return null;
                }
                
                }
            update pseList;
            addMessage(ApexPages.Severity.CONFIRM, 'Asset(s) saved successfully.');                
            loadEquipment();
            SelectedQuantity = '';
            SelectedEquipment = '';
                return null;
        }
        catch(Exception e) {
            addMessage(ApexPages.Severity.ERROR, e.getmessage());
            return null;
        }
    }
    
    private Map<ID,Decimal> getLockedEqupment(){
        Map<ID,Decimal> lockedEqupmentMap = new Map<ID,Decimal>();
        for(RetailerServiceEquipment__c lockedEq : [SELECT Equipment__c, Quantity__c FROM RetailerServiceEquipment__c WHERE Retailer__c =: ps.Project__r.Retailer__c AND Service__c =: ps.Service__c AND IsLocked__c = true]){
            lockedEqupmentMap.put(lockedEq.Equipment__c, lockedEq.Quantity__c);
        }
        return lockedEqupmentMap;
    }
    
    public pagereference SaveUtensil(){
        try{
            TriggerUtil.skipLocationEquipmentTrigger =true;
            delete [SELECT Id FROM projectserviceEquipment__c WHERE equipment__r.EquipmentType__c=:eqTools and projectservice__c =: ps.id];
            list<ProjectServiceEquipment__c>  pseList = new list<ProjectServiceEquipment__c>();
            ProjectServiceEquipment__c pse;
            for (SelectOption sl : SelectedUtensilList)
            {
                pse = new ProjectServiceEquipment__c();
                pse.equipment__c = sl.getValue();
                pse.ProjectService__c= ps.id;
                
                pse.quantity__c= 1;
                pse.islocked__c=false;
                pseList.add(pse);
            }
            upsert pseList;
            
            Project__c proj = [select id, Status__c,IsJobManualRegenReqd__c from project__c where id=: [select id,project__c from projectservice__c where id=:ps.ID limit 1].project__c];
            if(proj.Status__c == CONSTANTS.PROJECT_STATUS_BOOKED || proj.Status__c == CONSTANTS.PROJECT_STATUS_LAUNCHED || proj.Status__c == CONSTANTS.PROJECT_STATUS_INPROGRESS )
            {            
                TriggerUtil.skipProjectTrigger = true;
                proj.IsJobManualRegenReqd__c = true;
                update proj;
            }
            
            addMessage(ApexPages.Severity.CONFIRM, 'Tool(s) saved successfully.'); 
            return null;
        }
        catch(exception e){
            addMessage(ApexPages.Severity.ERROR, e.getmessage());
            return null;       
        }
        
    }
    
}