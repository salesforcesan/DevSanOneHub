public with sharing class SurveyQuestionProjectServiceController {

    public string param_surveyQuestionID {get;set;}
    public string project_serviceID {get; set;}
    public List<ProjectServiceQuestion__c> surveyquestions {get; set;}
    public List<question> questions {get; set;}
    public Boolean showAddEditSQButton {get;private set;}
    public Boolean isExternalProject {get;private set;}
    public ProjectServiceQuestion__c newsq {get; set;}
    public ProjectService__c ps {get; set;}    
    public Question__c newsqb {get; set;}
    public Project__c proj {get; set;} 

    public Map<String,Boolean> editableMap {get;set;}

    private void addMessage(ApexPages.Severity severity, String message){
        Apexpages.addMessage(new ApexPages.Message(severity, message));
    }

    public class question
    {
        public Id       id                   {get; set;}
        public String   name                 {get; set;}
        public String   qtext                 {get; set;}        
        public Integer  qno                  {get; set;}
        public String   qt                   {get; set;}
        public Boolean  fq                   {get; set;}    
        public Boolean  lq                   {get; set;}            
        public Boolean  tq                   {get; set;}
        public Id       sqb                  {get; set;}        
                
        public question(ProjectServiceQuestion__c sq)
        {
            id = sq.id;
            name = sq.name;
            qtext = sq.QuestionText__c;
            qno = Integer.valueOf(sq.QuestionNumber__c);
            qt = sq.QuestionType__c;
            fq = false;
            lq = false;
            tq = sq.ServiceQuestion__c;
            sqb = sq.Question__c;
        } 
    }

    public SurveyQuestionProjectServiceController() {
    }


    public SurveyQuestionProjectServiceController(ApexPages.StandardController controller) {
        project_serviceID = ApexPages.currentPage().getParameters().get('id');
        ps = [Select id, name, variant__c, Project__c from projectservice__c where id = :project_serviceID];
        
        System.debug('ps : ' + project_serviceID);
        
        if (project_serviceID == null)
        {
            project_serviceID = 'a0Hj0000004u4Jb';
        }
        
        newsq = new ProjectServiceQuestion__c();
        newsqb = new Question__c();
        
        getSurveyQuestions();
        
        proj = [SELECT Id, Status__c,IsJobManualRegenReqd__c FROM Project__c WHERE Id IN (Select Project__c from ProjectService__c where Id = :project_serviceID ) LIMIT 1];
        
        Set<String> editableFields = new Set<String>{'Project__c.RL_Questions'};
        editableMap = UIConfig.isEditale(proj.Status__c, editableFields);
        showAddEditSQButton = editableMap.get('Project__c.RL_Questions') && Schema.sObjectType.ProjectServiceQuestion__c.isUpdateable();

    }
    
    private void getSurveyQuestions() { 
             surveyquestions = [select id, name, QuestionText__c, QuestionType__c, QuestionNumber__c, ServiceQuestion__c, Question__c from ProjectServiceQuestion__c
                 where ProjectService__c = :project_serviceID 
                 ORDER BY QuestionNumber__c]; 
                 
             questions = new List<question>();
             Integer cnt = 0;    
             
                 
             Boolean oldtq = true;    
             for (ProjectServiceQuestion__c sq : surveyquestions)    
             {
                 question q = new question(sq);
                 if (q.tq == false && oldtq == true)
                 {
                     //first non template question
                     q.fq = true;
                 
                 }
                 oldtq = q.tq;
                 
                 cnt++;
                 
                 if (cnt == surveyquestions.size() && q.tq == false)
                 {
                     q.lq = true;
                 }
                 
                 questions.add(q);
                 
             }
    }
    
    public PageReference RemoveSurveyQuestion() {
        System.debug('BEFORE DELETE --- ' + surveyquestions.size() + ' -- Psq Id -- ' + param_surveyQuestionID);
        
        List<ProjectServiceQuestionDefinedResponse__c> removesurveyquestiondr = [select id, name  from ProjectServiceQuestionDefinedResponse__c where ProjectServiceQuestion__c =:param_surveyQuestionID LIMIT 1];        
        List<ProjectServiceQuestion__c> removesurveyquestions = [select id, name  from ProjectServiceQuestion__c where id =:param_surveyQuestionID LIMIT 1];        
        delete removesurveyquestiondr;
        delete removesurveyquestions;
        //Comment Versioning Code
        //AppUtil.UpdateProjectVersion(ps.Project__c);
        getSurveyQuestions();
        GenerateManual();
        System.debug('AFTER DELETE --- ' + surveyquestions.size());
        return null;
    }    
    
    public PageReference MoveUp() {
        try
        {
            Integer downnumber;
            Integer upnumber;
            
            List<ProjectServiceQuestion__c> upsq = [select id, name, QuestionNumber__c  from ProjectServiceQuestion__c where id =:param_surveyQuestionID LIMIT 1];        
            if (upsq.size()>0)
            {
                upnumber = Integer.ValueOf(upsq[0].QuestionNumber__c);    
            }
    
            List<ProjectServiceQuestion__c> downsq = [select id, name, QuestionText__c, QuestionType__c, QuestionNumber__c, ServiceQuestion__c from ProjectServiceQuestion__c
                where ProjectService__c = :project_serviceID AND QuestionNumber__c < :upnumber and ServiceQuestion__c = false 
                            order by QuestionNumber__c DESC LIMIT 1]; 

            if (downsq.size()>0)
            {
                downnumber = upnumber - 1;
        
                upsq[0].QuestionNumber__c = downnumber;
                update(upsq);
                
                downsq[0].QuestionNumber__c = upnumber;
                update(downsq);    
        
                getSurveyQuestions();        

           }
           else
           {
                addMessage(ApexPages.Severity.ERROR, 'Cannot move up. This is the first question.');
           }
           
           return null;
            
        }
        catch(Exception e)
        {
            addMessage(ApexPages.Severity.ERROR, e.getMessage());
            return null;
        }
    }    

    public PageReference MoveDown() {
    
        try
        {
            Integer downnumber;
            Integer upnumber;
            
            
            List<ProjectServiceQuestion__c> downsq = [select id, name, QuestionNumber__c  from ProjectServiceQuestion__c where id =:param_surveyQuestionID LIMIT 1];        
            if (downsq.size()>0)
            {
                downnumber = Integer.ValueOf(downsq[0].QuestionNumber__c);    
            }
            
            
            List<ProjectServiceQuestion__c> upsq = [select id, name, QuestionText__c, QuestionType__c, QuestionNumber__c, ServiceQuestion__c from ProjectServiceQuestion__c
                where ProjectService__c = :project_serviceID AND QuestionNumber__c > :downnumber AND ServiceQuestion__c=false
                order by QuestionNumber__c LIMIT 1]; 
    
            if (upsq.size() > 0)
            {
                upnumber = Integer.ValueOf(upsq[0].QuestionNumber__c);
                downsq[0].QuestionNumber__c = upnumber;
                update(downsq);
                
                upsq[0].QuestionNumber__c = downnumber;
                update(upsq);    
        
                getSurveyQuestions();        
                    
            }
            else
            {
                addMessage(ApexPages.Severity.ERROR, 'Cannot move down. This is the last question.');
            }
    
        }
        catch(Exception e)
        {
            addMessage(ApexPages.Severity.ERROR, e.getMessage());            
        }
        return null;
    } 
    
    public PageReference populateNewSBQData(){
        if(newsq.Question__c == null)
        {
            return null;
        }
        
        
        newsqb = [Select Id, Name ,QuestionText__c, QuestionType__c from Question__c where Id = :newsq.Question__c LIMIT 1];
        
        System.debug('AFTER CHANGE --- ' + newsqb.QuestionText__c);
        
        return null;
    }              
    
    public PageReference AddSurveyBankQuestion(){
        if(newsq.Question__c == null)
        {
            return null;
        }
        
        Question__c sqb = [Select Id, Name ,QuestionText__c, QuestionType__c from Question__c where Id = :newsq.Question__c LIMIT 1];
        ProjectServiceQuestion__c[] questionNumber = [SELECT QuestionNumber__c FROM ProjectServiceQuestion__c WHERE ProjectService__c =:project_serviceID AND QuestionNumber__c != null ORDER BY  QuestionNumber__c DESC LIMIT 1];
        
        Integer max = 0;
        if(!questionNumber.isEmpty()){
            max = Integer.valueOf(questionNumber[0].QuestionNumber__c);    
        }
        
        //AggregateResult[] ag = [Select MAX(QuestionNumber__c) MaxNumber FROM ProjectServiceQuestion__c where ProjectService__c =:project_serviceID ];
        //Integer max = Integer.valueof(ag[0].get('MaxNumber'));
        //if (max == null)
        //{
          //  max = 0;
        //}
        
        system.debug('~~~~~ ' + newsq.Question__c +'__'+sqb.id+'__'+sqb.name+'__'+sqb.QuestionText__c+'__'+sqb.QuestionType__c  );
          
        try
        {    
            ProjectServiceQuestion__c sqObj = new ProjectServiceQuestion__c();
            sqObj.ProjectService__c = project_serviceID;
            sqObj.Question__c = sqb.Id;
            sqObj.ServiceQuestion__c = false;
            sqObj.QuestionNumber__c = max + 1;
            system.debug('Variant: ' + ps.variant__c);
            if (ps.variant__c != null)
            {
                List<QuestionVariant__c> qvs = [select id, name from questionvariant__c where question__c = :sqb.Id and variant__c =: ps.variant__c];
                if (qvs.size() > 0)
                {
                    sqObj.QuestionVariant__c = qvs[0].Id;
                }
                
            }
            insert sqObj;        
            

            ProjectServiceQuestionDefinedResponse__c psqdefResp;
            List<ProjectServiceQuestionDefinedResponse__c> psqdfrList = new List<ProjectServiceQuestionDefinedResponse__c>();
            
            List<QuestionDefinedResponse__c> qDefResList = [ SELECT Id, Name, DefinedResponseOrder__c, DefinedResponseText__c  FROM QuestionDefinedResponse__c where Question__c = :sqb.Id]  ;
            for(QuestionDefinedResponse__c qdr : qDefResList )
            {
                system.debug('~~~~~ def resp  ' +'__'+qdr.id+'__'+qdr.name+'__'+qdr.DefinedResponseOrder__c+'__'+qdr.DefinedResponseText__c  );
                psqdefResp =  new ProjectServiceQuestionDefinedResponse__c();
                psqdefResp.ProjectServiceQuestion__c = sqObj.id;
                psqdefResp.QuestionDefinedResponse__c = qdr.Id;
                psqdefResp.EndOfQuestions__c = false;
                if (ps.variant__c != null)
                {
                    List<QuestionDefinedResponseVariant__c> qdrvs = [select id, name from QuestionDefinedResponseVariant__c where questiondefinedresponse__c = :qdr.id and variant__c =: ps.variant__c];
                    if (qdrvs.size() > 0)
                    {
                        psqdefResp.QuestionDefinedResponseVariant__c = qdrvs[0].Id;
                    }
                    
                }
                
                psqdfrList.add(psqdefResp);
            } 
            
            insert psqdfrList;
            
            //Comment Versioning Code
            //AppUtil.UpdateProjectVersion(ps.Project__c);
            GenerateManual();
                    
        }
        catch(Exception ex)
        {
            if (ex.getMessage().Contains('duplicate'))
            {
                addMessage(ApexPages.Severity.ERROR, 'Question already added. Please check and try again.');
            }
            else
            {
                addMessage(ApexPages.Severity.ERROR, ex.getMessage());
            }
            return null;

        
        }
        
        newsq = new ProjectServiceQuestion__c();
        newsqb = new Question__c();        
        
        getSurveyQuestions();
        addMessage(ApexPages.Severity.CONFIRM, 'Question(s) added successfully.');  
        return null;
    }          

    
    /*public PageReference assignCP() {
        PageReference assignPage = Page.Add_Locations;
        assignPage.getParameters().put('retURL','/'+project_serviceID );
        return assignPage;
    }*/
    
    public void GenerateManual(){
        if(proj.Status__c == CONSTANTS.PROJECT_STATUS_BOOKED || proj.Status__c == CONSTANTS.PROJECT_STATUS_LAUNCHED || proj.Status__c == CONSTANTS.PROJECT_STATUS_INPROGRESS )
            {            
                TriggerUtil.skipProjectTrigger = true;
                proj.IsJobManualRegenReqd__c = true;
                update proj;
            }
    }
    

}