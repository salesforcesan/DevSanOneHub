public class ProjServiceWrapper {
    @AuraEnabled
    public String Id{get;set;}
    @AuraEnabled
    public String Name{get;set;}
    @AuraEnabled
    public String RecordID{get;set;}
    @AuraEnabled
    public String ProjectId{get;set;}
    @AuraEnabled
    public string ServiceTitle{get; set;}
    @AuraEnabled
    public string JobManualTemplate{get; set;}
    //public string JobManual{get; set;}
    @AuraEnabled
    public decimal NumberOfWorkers{get; set;}
    @AuraEnabled
    public decimal EstimatedMinutes{get; set;}
    @AuraEnabled
    public decimal NumberOfDays{get; set;}   
    @AuraEnabled
    public string ServiceObjective{get; set;}  
    @AuraEnabled
    public String JobManualUrl{get;set;}
    @AuraEnabled
    public String JobManualFileName{get;set;}
    @AuraEnabled    
    public String StartTime{get;set;}    
    @AuraEnabled    
    public String ResponsibleForExecution{get;set;}    
    @AuraEnabled    
    public boolean IncludeAutoGenManual{get;set;}    
    @AuraEnabled    
    public decimal ServiceRank{get;set;}    
    @AuraEnabled
    public boolean CheckDistribution{get;set;}
    @AuraEnabled
    public boolean AllowDistribution{get;set;}
    @AuraEnabled    
    public boolean isSuccess{get;set;}
    @AuraEnabled    
    public String message{get;set;}
    @AuraEnabled
    public list<PSAttributeWrapper> AvlPSA{get; set;}
    @AuraEnabled
    public String Title {get;set;}
    @AuraEnabled
    public String ServiceName{get;set;}
    @AuraEnabled
    public list<String> AvlTime{get;set;}
    @AuraEnabled
    public list<String> JobManual{get;set;}
    @AuraEnabled    
    public boolean PopulateTargetQuestions{get;set;}
    @AuraEnabled
    public list<String> ECValues{get;set;}
    @AuraEnabled
    public String ShippingPreference{get;set;}
    @AuraEnabled
    public list<String> AvlShippingPreference{get;set;}
    @AuraEnabled    
    public boolean IsMaterialNeeded{get;set;}    
    @AuraEnabled    
    public boolean AllowMultiDays{get;set;} 
    @AuraEnabled    
    public boolean AllowMultiRep{get;set;}  
    @AuraEnabled    
    public String EndTime{get;set;}   
    @AuraEnabled    
    public Boolean IsFirstService{get;set;}   
    @AuraEnabled    
    public Boolean IsLastService{get;set;}   
    @AuraEnabled    
    public String Status{get;set;}      
    @AuraEnabled
    public boolean isManualGenInProgress{get;set;}  
    @AuraEnabled
    public decimal NumberOfTargets{get; set;}
    @AuraEnabled
    public boolean IsJobManualAttributeAdded{get;set;}  
    
    
    public ProjServiceWrapper(){        
    }
    
    public ProjServiceWrapper(projectservice__c ps,list<ProjectServiceAttribute__c> psaList)
    {
        IsJobManualAttributeAdded=false;
        ECValues = AppUtil.getAppSetting('ResponsibleForExecution').split(',');
        string stdTempURL = '/apex/' + CONSTANTS.CURRENTNAMESPACEPREFIX + 'pdftemplate?psId='+ps.Id;
        ID = ps.ID;
        RecordID = ps.ID;
        Name = ps.Name;
        ServiceTitle = (ps.ServiceTitle__c!=null)?ps.ServiceTitle__c:'';
        NumberOfWorkers= ps.NumberOfWorkers__c;
        EstimatedMinutes =  ps.EstimatedMinutes__c!=null?ps.EstimatedMinutes__c:0;
        ProjectId = ps.Project__c;
        NumberOfDays = ps.NumberOfDays__c;
        ShippingPreference=ps.ShippingPreference__c;
        ServiceObjective = (ps.ServiceObjective__c!=null)?ps.ServiceObjective__c:'';
        StartTime = (ps.StartTime__c!=null)?ps.StartTime__c:'12.00am';
        if(ps.JobManual__c == CONSTANTS.JOB_MANUAL_STANDARD_TEMPLATE)
        {
            JobManualUrl =stdTempURL;
            JobManualFileName = ps.JobManualFileName__c;
            IncludeAutoGenManual= (ps.IncludeAutoGenManual__c!=null)?ps.IncludeAutoGenManual__c:true; 
            isManualGenInProgress = ps.isManualGenInProgress__c;
        }
        else if(ps.JobManual__c == CONSTANTS.JOB_NOMANUAL_TEMPLATE)
        {
            JobManualUrl ='';
            JobManualFileName = '';
            IncludeAutoGenManual =false;
            isManualGenInProgress = false;
        }
        else
        {
            JobManualUrl =  ps.JobManualURL__c; 
            JobManualFileName = ps.JobManualFileName__c;
            IncludeAutoGenManual= (ps.IncludeAutoGenManual__c!=null)?ps.IncludeAutoGenManual__c:true; 
            isManualGenInProgress = ps.isManualGenInProgress__c;
        }
        
        JobManualTemplate = (ps.JobManual__c!=null)?ps.JobManual__c:CONSTANTS.JOB_MANUAL_STANDARD_TEMPLATE;
        
        ResponsibleForExecution = ps.ResponsibleForExecution__c;
        ServiceRank = ps.ServiceRank__c;
        CheckDistribution = (ps.CheckDistribution__c!=null)?ps.CheckDistribution__c:false;
        Title = ps.ServiceTitle__c;
        ServiceName = ps.ServiceName__c;
        PopulateTargetQuestions=(ps.PopulateTargetQuestions__c!=null)?ps.PopulateTargetQuestions__c:true;
        AvlShippingPreference = getShippingPreference();
        JobManual = getJobManualInfo();
        IsMaterialNeeded= (ps.IsMaterialNeeded__c!=null)?ps.IsMaterialNeeded__c:false;
        AllowMultiDays=ps.Project__r.ProjectType__r.AllowMultidays__c;
        AllowMultiRep=ps.service__r.IsNumberOfWorkersRequired__c;
        EndTime= ps.EndTime__c!=null?ps.EndTime__c:'12:00am';
        Status =ps.Status__c;
        
        NumberOfTargets = ps.NumberOfTargets__c;
        
        string[] sec = new string[]{'00','15','30','45'};
            string[] hrs = new string[]{'12','1','2','3','4','5','6','7','8','9','10','11'};    
                AvlTime= new list<string>();
        for(string i:hrs){
            for(string j : sec){
                AvlTime.add(string.valueof(i)+':'+string.valueOf(j)+'am');    
            }
        }
        for(string i:hrs){
            for(string j : sec){
                AvlTime.add(string.valueof(i)+':'+string.valueOf(j)+'pm');    
            }
        }        
        
        //AllowDistribution=false;
        //if(ps.Service__r != null){
        AllowDistribution = ps.Service__r.AllowDistribution__c;
        //}
        
        list<PSAttributeWrapper> objList = new list<PSAttributeWrapper>();
        if(psaList != null){
            for(ProjectServiceAttribute__c psa : psaList){
                objList.add(new PSAttributeWrapper(psa));
                if(psa.AttributeTitle__c == 'Job Manual'){
                    IsJobManualAttributeAdded = true;
                }
            }
            AvlPSA = objList;
        }
        isSuccess=true;
    }    
    
    public List<string> getShippingPreference()
    {
        List<string> options = new List<string>();       
        Schema.DescribeFieldResult fieldResult = ProjectService__c.ShippingPreference__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        options.add('--SELECT--');
        for(Schema.PicklistEntry f : ple)
        {
            options.add(f.getValue());
        }               
        return options;
    }
    public List<string> getJobManualInfo()
    {
        List<string> options = new List<string>();       
        Schema.DescribeFieldResult fieldResult = ProjectService__c.JobManual__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry f : ple)
        {
            options.add(f.getValue());
        }               
        return options;
    }
    
    
    
}