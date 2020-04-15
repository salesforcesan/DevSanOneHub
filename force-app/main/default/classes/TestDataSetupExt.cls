public with sharing class TestDataSetupExt {
    public integer projCount{get;set;}
    public integer projServCount{get;set;}
    public integer projLocCount{get;set;}
    public string LocNumber{get;set;}
    public List<SelectOption> AllServicesList{get;set;}
    public List<SelectOption> SelectedServicesList{get;set;} 
    public Project__c project{get;set;}
    public List<SelectOption> AllStatus{get;set;}
     public string selectedStatus{get;set;}   
    public TestDataSetupExt(ApexPages.StandardController controller) {
        //projCount=1;
        //projServcount=2;
        //projLocCount=2;      
        String message = '' + ApexPages.CurrentPage().GetParameters().Get('message');
        if(message != 'null')
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,message));
        }
            
        this.project = (Project__c) controller.getRecord();
        
        AllServicesList= new List<SelectOption>();
        for(service__c svc : [select id,name from service__c])
        {
          AllServicesList.add(new SelectOption (svc.name, svc.name));
        }
        SelectedServicesList = new List<SelectOption>(); 
        
        AllStatus= new List<SelectOption>(); 
        
        AllStatus.add(new SelectOption (CONSTANTS.PROJECT_STATUS_PLANNING, CONSTANTS.PROJECT_STATUS_PLANNING));
        AllStatus.add(new SelectOption (CONSTANTS.PROJECT_STATUS_BOOKED, CONSTANTS.PROJECT_STATUS_BOOKED));
    }
    

    
    public PageReference Save()
    {       
        try{ 
            //create proj
            /*project__c proj = new project__c();
            proj.name = this.project.name;
            proj.projecttype__c = [select id from projecttype__c limit 1].id;
            proj.retailer__c = [select id from retailer__c limit 1].id;
            proj.ProjectScheduleOption__c = this.project.ProjectScheduleOption__c ;*/
            TriggerUtil.SkipAllTriggers();
            ProjectType__c projectType = [SELECT name,maxservicecount__c,minservicecount__c, LaunchLeadTime__c FROM ProjectType__c limit 1 ];
            retailer__c retailer = [select id,OneHubRetailerId__c from retailer__c limit 1];
            account acct = [select id from account where IsApproved__c =true limit 1];
            
            list<project__c> projList = new list<project__c>();
            project__c proj= new project__c();
            
            ScheduleOption__c scopt = [select id from ScheduleOption__c where isactive__c=true limit 1];
            
            for(integer i=1;i<=projCount;i++)
            {
                proj= new project__c();
                proj.projecttype__c = projectType.id;
                proj.retailer__c = retailer.id;
                proj.IsSplit__c = true;
                proj.BudgetedLocationsCount__c = (projLocCount!=0)?projLocCount:(LocNumber.split(',')).size();
                proj.OneHubRetailerId__c = retailer.OneHubRetailerId__c;
                proj.SplitType__c='Solo';
                proj.maxservicecount__c = projectType.maxservicecount__c;
                proj.minservicecount__c = projectType.minservicecount__c;
                proj.startdate__c=this.project.startdate__c;
                proj.enddate__C =this.project.enddate__C;
                proj.ProjectScheduleOption__c=scopt.id;
                proj.islocked__c=this.project.islocked__c;
                if(this.project.ProjectLaunchDate__c!=null)
                    proj.ProjectLaunchDate__c=this.project.ProjectLaunchDate__c;
                else
                    proj.ProjectLaunchDate__c = this.project.StartDate__c.addDays(projectType.LaunchLeadTime__c.intValue() * -1);
                
                proj.IsJobManualRegenReqd__c = true;
                proj.name = this.project.name ;
                
                system.debug('~~~~~selectedStatus  ~~~~'+selectedStatus);
                if(selectedStatus==CONSTANTS.PROJECT_STATUS_BOOKED)
                {
                    system.debug('~~~~ CONSTANTS.PROJECT_STATUS_BOOKED ~~~');
                    proj.ApprovalRequestDate__c  = System.Now();
                    proj.ApprovalDate__c = System.Now();
                    proj.BookedProjectStartDate__c = project.StartDate__c;
                    proj.BookedProjectEndDate__c = project.EndDate__c;
                    proj.Status__c = CONSTANTS.PROJECT_STATUS_BOOKED;      
                }
                else
                    proj.status__C=CONSTANTS.PROJECT_STATUS_PLANNING;
            
                if(projCount> 1)
                    proj.name = this.project.name +'  -  '+i;
                
                
                projList.add(proj);
            }
            insert projList;
            //this.project.ProjectLaunchDate__c = this.project.StartDate__c.addDays(projectType.LaunchLeadTime__c.intValue() * -1);
            
            system.debug('~~~'+projList+'~~~'+projList.size());
            list<Id> listOfProjIds = new list<Id>();
            //list<Database.Saveresult> insertResults =Database.insert(projList, false);
            //for (Database.SaveResult sr : insertResults) {
            for(project__c p:projList){
                //if (sr.isSuccess()) {
                    system.debug('~~~~~~'+p.Id);
                    listOfProjIds.add(p.id);
                //}
            }
            
            string ServNames='';
            if(projServCount==0)
               {
                   SelectedServicesList = new List<SelectOption>();         
                   SelectedServicesList.add(new SelectOption ('test', 'test'));
                   
                   for(SelectOption so: SelectedServicesList){
                       ServNames= ServNames + so.getValue()  + ',';
                   }
               }
               
            if(projLocCount>0)
               LocNumber  = '';   
            
            id[] param = listOfProjIds;
            system.debug('listOfProjIds~~~'+listOfProjIds+'~~~'+ integer.valueof(projLocCount) +'~~~'+ LocNumber  +'~~~'+ integer.valueof(projServCount)  +'~~~'+SelectedServicesList);
            
            Database.executeBatch(new BatchTestDataSetup(param,projLocCount,LocNumber,projServCount,ServNames,selectedStatus), 1);
            
            //Database.executeBatch(new BatchTestDataSetup(listOfProjIds,integer.valueof(projLocCount),LocNumber,integer.valueof(projServCount),SelectedServicesList), 200);
            
            
            /*
                       
            ProjectAccount__c updatedPA = new ProjectAccount__c();
            updatedPA.Account__c = acct.id;
            updatedPA.IsPrimary__c = true;
            updatedPA.Project__c = this.project.id;
            updatedPA.SplitValue__c = 100;
            insert updatedPA;
            

            //location
            list<projectlocation__c> plocList = new list<projectlocation__c>();
            list<location__c> plocVal = new list<location__c>();
            projectlocation__c ploc;
            string LocationQry;
            if(projLocCount!=0)
            {
                LocationQry='select id from location__c limit ' + projLocCount;
                plocVal = Database.query(LocationQry);
            }
            else{
                plocVal =[select id from location__c where  locationnumber__c IN : LocNumber.Split(',')]; 
            }
            system.debug('~~~~123~~~'+LocationQry+'    '+plocVal );
            
            for(location__c loc: plocVal )
            {
                ploc = new projectlocation__c();
                ploc.project__C = this.project.id;
                ploc.location__c = loc.id;
                plocList.add(ploc);              
            }
            insert plocList;
            
            //service
            projectService__c pserv;
            list<projectService__c> pserList = new list<projectService__c>();
            list<Service__c> svcL= new list<Service__c>();
            if(projServCount!=0){
                string ServiceQry='select id from service__c limit ' + projServcount;
                svcL = Database.query(ServiceQry);
            }
            else{
                set<string> setObj = new set<string>();
                for (SelectOption so : SelectedServicesList)
                {
                    setObj.add(so.getValue());
                }
                svcL=[select id from service__c where  name IN : setObj];
            }

            for(Service__c serv: svcL)
            {
                pserv = new projectService__c();
                pserv.project__C = this.project.id;
                pserv.Service__c = serv.id;
                pserv.ResponsibleForExecution__c = 'Execution Company';
                pserv.OneHubRetailerId__c = retailer.OneHubRetailerId__c;
                pserv.JobManualFileName__c = ''; 
                pserv.IncludeAutoGenManual__c = false;
                pserv.JobManualTemplate__c  = 'Standard';
                pserList.add(pserv);              
            }
            insert pserList ;
            
           
            system.debug('~~~~ schedulingStrategyObject ~~~');
             SchedulingStrategy schedulingStrategyObject = SchedulingStrategyFactory.getSchedulingStrategy(projectType.Name);
             List<ProjectLocation__c> scope = Database.query(schedulingStrategyObject.getSchedulableLocationsQuery(this.project));
             system.debug('~~~~~scope'+scope);
             SchedulingStrategyObject.ScheduleLocations(scope, String.valueof(this.project.ID));
            
            
            if(selectedStatus==CONSTANTS.PROJECT_STATUS_BOOKED)
            {
                system.debug('~~~~ CONSTANTS.PROJECT_STATUS_BOOKED ~~~');
                this.project.ApprovalRequestDate__c  = System.Now();
                this.project.ApprovalDate__c = System.Now();
                this.project.BookedProjectStartDate__c = project.StartDate__c;
                this.project.BookedProjectEndDate__c = project.EndDate__c;
                this.project.Status__c = CONSTANTS.PROJECT_STATUS_BOOKED;           
                update this.project;
            }
             
             */
             
             
                    
            system.debug('~~~~ the end ~~~');
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.info,'Successfully inserted !!!' ));
            PageReference pr = new PageReference('/apex/TestDataSetup');
             pr.setRedirect(true);
            pr.GetParameters().Put('message', 'Successfully inserted !!!');
            return pr;
   
        }
        catch(exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getmessage()));
        }  
                     
             return null;
    }
}