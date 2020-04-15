global class BatchTestDataSetup implements Database.Batchable<sObject>, Database.Stateful {
    Id[] ids;
    integer projLocCount;
    String LocNumber;
    integer projServCount;
    string serviceNames;
    string Status;
    list<project__c> projList;
    global BatchTestDataSetup(id[] ids1,integer projLocCount1, String LocNumber1,integer projServCount1,string serviceNames1,string Status1) {
        //,integer projLocCount1, String LocNumber1,integer projServCount1
        if (ids1.size() == 0) return;
            ids=ids1;

        this.projLocCount=projLocCount1;
        this.LocNumber=LocNumber1;
        this.projServCount=projServCount1;
        this.serviceNames = serviceNames1;
        this.Status = Status1;
    }
    
    
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        system.debug('Set Cancel Job Batcher Started   '+ids +'~~~'+ projLocCount  +'~~~'+ LocNumber  +'~~~'+projServCount);
        return Database.getQueryLocator([SELECT Id,projectType__r.name,OneHubRetailerId__c,status__c,Name, StartDate__c, EndDate__c,  ProjectType__c,  BudgetedLocationsCount__c, LocationTotalCount__c,   BookBudgetedOnly__c  FROM project__c WHERE id IN :ids]);        
    }
   
    global void execute(Database.BatchableContext BC, List<project__c> scope) {
        system.debug(' execute ');
        TriggerUtil.SkipAllTriggers();  
        projList = new list<project__c>();
        for (project__C project: scope)
        {
            projList.add(project);
            system.debug('~~~~~~begin PA');
            ProjectAccount__c updatedPA = new ProjectAccount__c();
            updatedPA.Account__c = [select id from account where IsApproved__c =true limit 1].id;
            updatedPA.IsPrimary__c = true;
            updatedPA.Project__c = project.id;
            updatedPA.SplitValue__c = 100;
            insert updatedPA;
            system.debug('~~~~~~end PA');
            
            //location
            //system.debug('~~~~~~begin Loc');
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
                ploc.project__C = project.id;
                ploc.location__c = loc.id;
				ploc.IsNewLocation__c = true ;

                plocList.add(ploc);              
            }
            insert plocList;
            system.debug('~~~~~~end PLOC');
            
            
            
            //service
            //system.debug('~~~~~~begin PS');
            projectService__c pserv;
            list<projectService__c> pserList = new list<projectService__c>();
            list<Service__c> svcL= new list<Service__c>();
            if(projServCount!=0){
                string ServiceQry='select id from service__c limit ' + projServcount;
                svcL = Database.query(ServiceQry);
            }
            else{
                set<string> setObj = new set<string>();
                for (string s : serviceNames.split(','))
                {
                    setObj.add(s);
                }
                svcL=[select id from service__c where  name IN : setObj];
            }

            for(Service__c serv: svcL)
            {
                pserv = new projectService__c();
                pserv.project__C = project.id;
                pserv.Service__c = serv.id;
                pserv.ResponsibleForExecution__c = 'Execution Company';
                pserv.OneHubRetailerId__c = project.OneHubRetailerId__c ;
                pserv.JobManualFileName__c = ''; 
                pserv.IncludeAutoGenManual__c = true;
                pserv.JobManual__c  = 'Standard';
                pserv.JobManualURL__c = '';
                pserv.EstimatedMinutes__c=15;
                pserList.add(pserv);              
            }
            insert pserList ;
            system.debug('~~~~~~end PS');
            
            system.debug('~~~~~~begin PSA');
            List<ProjectServiceAttribute__c> pscAttributes = new List<ProjectServiceAttribute__c>();
            ProjectServiceAttribute__c psca = new ProjectServiceAttribute__c();
                
            for(projectService__c ps : pserList ){
                list<ServiceQuestion__c> tempQnsList = [SELECT Id, Name, Question__c, QuestionNumber__c, QuestionText__c, QuestionType__c FROM ServiceQuestion__c Where service__c = : ps.service__c]; 

                Map<Id, Id> mqv = new Map<Id, Id>();
                Map<Id, Id> mqdrv = new Map<Id, Id>();
                
                                    
                if (ps.Variant__c != null)
                {
                    Set<Id> qids = new Set<Id>();
                    for(integer j=0;j<tempQnsList.size();j++)
                    {
                        qids.add(tempQnsList[j].Question__c);
        
                    }
                    list<questionvariant__c> qvs = [select id, name, question__c, questiontext__c from questionvariant__c where Question__c in :qids and variant__c = :ps.variant__c];

                    for (questionvariant__c qv : qvs)
                    {
                        mqv.put(qv.Question__c, qv.id);
                    }
                    
                    
                    list<questiondefinedresponsevariant__c> qdrvs = [select id, name, questiondefinedresponse__c from questiondefinedresponsevariant__c where variant__c = :ps.variant__c and questiondefinedresponse__c in (select id from questiondefinedresponse__c where Question__c in :qids)];
                    for (questiondefinedresponsevariant__c qdrv : qdrvs)
                    {
                        mqdrv.put(qdrv.questiondefinedresponse__c, qdrv.id);
                    }
                    
                }                                
                
                list<ProjectServiceQuestionDefinedResponse__c> definedResponses = new list<ProjectServiceQuestionDefinedResponse__c>();
                for(integer j=0;j<tempQnsList.size();j++)
                {
                    ProjectServiceQuestion__c surveyQn = new ProjectServiceQuestion__c();
                    surveyQn.QuestionNumber__c = tempQnsList[j].QuestionNumber__c;            
                    surveyQn.ServiceQuestion__c = true;
                    surveyQn.ProjectService__c = ps.id;  
                    surveyQn.Question__c = tempQnsList[j].Question__c;
                    surveyQn.QuestionVariant__c = mqv.get(tempQnsList[j].Question__c);
                    insert surveyQn;
                    
                    ProjectServiceQuestionDefinedResponse__c defResp;
                    List<ServiceQuestionDefinedResponse__c> sqDefResList = [ SELECT Id, Name, QuestionDefinedResponse__c, JumpToQuestion__c, EndOfQuestions__c  FROM ServiceQuestionDefinedResponse__c where ServiceQuestion__c = :tempQnsList[j].Id]  ;
                    for(integer i=0;i<sqDefResList.size();i++)
                    {
                        defResp =  new ProjectServiceQuestionDefinedResponse__c();
                        defResp.ProjectServiceQuestion__c = surveyQn.id;
                        defResp.QuestionDefinedResponse__c = sqDefResList[i].QuestionDefinedResponse__c;
                        defResp.JumpToQuestion__c = sqDefResList[i].JumpToQuestion__c;
                        defResp.EndOfQuestions__c = sqDefResList[i].EndOfQuestions__c;
                        defResp.QuestionDefinedResponseVariant__c = mqdrv.get(sqDefResList[i].QuestionDefinedResponse__c);
                        definedResponses.add(defResp);
                    } 
                }
                insert definedResponses;
                
                for(serviceattribute__c sa: [select id,attribute__c,service__c from serviceattribute__c where service__c=:ps.service__c]){
                    psca = new ProjectServiceAttribute__c();
                    psca.Attribute__c = sa.attribute__c;
                    psca.ProjectService__c = ps.id;
                    psca.service__c = sa.service__c;
                    psca.serviceattribute__c = sa.id;
                    pscAttributes.add(psca);
                }
                
                
             }
             upsert pscAttributes;
             system.debug('~~~~~~end PSA');
             
            system.debug('~~~~~~begin JOB');
            system.debug('~~~~ schedulingStrategyObject ~~~');
            /* SchedulingStrategy schedulingStrategyObject = SchedulingStrategyFactory.getSchedulingStrategy(project.projectType__r.name);
            List<ProjectLocation__c> plocList2= Database.query(schedulingStrategyObject.getSchedulableLocationsQuery(project));
            system.debug('~~~~~scope'+plocList2);
            SchedulingStrategyObject.ScheduleLocations(plocList2, String.valueof(project.ID));*/
            system.debug('~~~~~~end JOB');            
        }

    }
    
    global void finish(Database.BatchableContext BC) {
        TriggerUtil.SkipAllTriggers();  
        if(Status==CONSTANTS.PROJECT_STATUS_BOOKED)
        {   
            for (project__C project: [SELECT Id,projectType__r.name,OneHubRetailerId__c,status__c,Name, StartDate__c, EndDate__c,  ProjectType__c,  BudgetedLocationsCount__c, LocationTotalCount__c,   BookBudgetedOnly__c  FROM project__c WHERE id IN :ids])
        	{
            	ProjectScheduler batch = new ProjectScheduler(project);
            	Database.ExecuteBatch(batch, 1000);
                project.Status__c = CONSTANTS.PROJECT_STATUS_BOOKED;           
                update project;
            }
        }
    }    
    
}