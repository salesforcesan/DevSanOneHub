public with sharing class LightningJobsController {
    
    @AuraEnabled
    public static List<String> GetJobCancelReasons()
    {  
        List<String> options = new List<String>();        
        Schema.DescribeFieldResult fieldResult = Job__c.JobCanceledReason__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        options.add('--SELECT--');
        for(Schema.PicklistEntry f : ple)
        {
            options.add(f.getLabel());
        }                
        return options;        
    }
    @AuraEnabled
    public static String CancelJobs(String jobIdList,String selReason,String selComm){
        ResponseWrapper rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Selected Job(s) are canceled Successfully',null);       
        system.debug('#### Cancel Request Receive id=' + jobIdList + ', reason=' + selReason + ',Comments=' + selComm);
        try
        {
            Type idArrType=Type.forName('List<Id>'); 
            List<Id> ids=(List<Id>) JSON.deserialize(jobIdList, idArrType);
            if(ids.size()>0)
                rw.Message = ids.size() + ' Job(s) are canceled Successfully';
            //rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Selected Job(s) are canceled Successfully',null);                   
            List<ActionResponse> actionResp = JobActionsHelper.cancelJobs(ids, selReason, selComm);
            
            if(!actionResp.isEmpty()){
                if(!actionResp[0].IsSuccessful)
                {
                    rw.state = CONSTANTS.RESPONSE_STATE_ERROR;
                }
                rw.Message = actionResp[0].ResponseMessage;
            }
        }
        catch(Exception e)
        {            
            rw.State = CONSTANTS.RESPONSE_STATE_ERROR;
            rw.Message = 'Unable to cancel Jobs: ' + e.getMessage();
            system.debug('### error on cancel' + e.getMessage() + ' ' + e.getStackTraceString());
        }
        system.debug('#### Cancel Request Response' + JSON.serialize(rw));
        return JSON.serialize(rw);        
    }
    
    @AuraEnabled
    public static String CreateJobAttempts(String jobIdList,String scheduledDate){         
        ResponseWrapper rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Successfully retried the JobAttempts',null);        
        system.debug('*******CreateJobAttempts****' + jobIdList);
        try
        {           	
            Type idArrType=Type.forName('List<Id>'); 
            List<Id> ids=(List<Id>) JSON.deserialize(jobIdList, idArrType);
            Type sType = Type.forName('string');
            if(scheduledDate!=null){
                string sDate = (string)JSON.deserialize(scheduledDate,sType);            
                Date cDate = Date.valueOf(sDate + ' 00:00:00');
                JobActionsHelper.CreateAttempts(ids, cDate, '');
            }
            else
                JobActionsHelper.CreateAttempts(ids, null, '');
        }
        catch(Exception ex)
        {               
            system.debug('*******Error on JobAttempts****' + ex.getMessage() + ex.getStackTraceString());
            rw.State = CONSTANTS.RESPONSE_STATE_ERROR;
            rw.Message = 'Re attempt Jobs Failed: ' + ex.getMessage();             
        }        
        system.debug('*******CreateJobAttempts response****' + JSON.serialize(rw));
        return JSON.serialize(rw);        
    }
    
    
    private static String[] validateKeywordSearch(Map<String,String> query){
        String projectId = parseString(query.get('projectId'));
        String keyword = parseString(query.get('keyword'));
        if (String.isBlank(projectId)){
            throw new AuraHandledException('The project identifier is required when searching jobs.');
        }
        return new String[] {projectId, keyword};
            }
    
    private static Map<String,Object> transformProjectJobs(Job__c job){
        Map<String,Object> rec = new Map<String,Object>();
        rec.put('Id', job.Id);
        rec.put('JobStatus', job.JobStatus__c);
        rec.put('ProjectServiceTitle', job.ProjectService__r.Title__c);
        rec.put('Retailer',job.project__r.Retailer__r.name);
        rec.put('IsExecuted', job.IsExecuted__c);
        rec.put('ResponsibleForExecution', job.ResponsibleForExecution__c);
        rec.put('CompletionStatus', job.CompletionStatus__c);
        rec.put('ExceptionName', job.ExceptionName__c);
        rec.put('ExceptionCode', job.ExceptionCode__c);
        rec.put('LocationName', job.Location__r.Name);
        rec.put('LocationNumber', job.LocationNumber__c);
        rec.put('CanceledReason', job.JobCanceledReason__c);
        rec.put('JobScheduledDate', formatDate(job.JobScheduledDate__c));
        rec.put('EstimatedMinutes', job.EstimatedMinutes__c);
        rec.put('NumberOfWorkers', job.NumberOfWorkers__c);        
        rec.put('IsMultiDay',(job.NumberOfDays__c>1?true:false));
        rec.put('IsSingleRep',(job.NumberOfWorkers__c>1?false:true));        
        rec.put('ProjectScheduleOptionCode',job.ProjectScheduleOptionCode__c);
        rec.put('ProjectEndDate',job.ProjectEndDate__c);
        rec.put('JobName',job.Name);
        rec.put('AccountableExecutionCompany',job.AccountableExecutionCompany__r.name);
        return rec;
    }
    
    private static String parseString(object val){
        return val != null ? String.valueOf(val): '';
    }
    public static String formatDate(Date d) {
        if(d!= null){
            return d.month() + '/' + d.day() + '/' + d.year();
            
        }
        else
        {
            return '';
        }
        
    }
    private static List<String> genJobSelectBaseSoql(){
        List<String> sql = new List<String>();
        //String baseQuery = 'SELECT Id, Name,Location__r.Name, ServiceName__c,ProjServiceName__c,ProjectService__r.Service__r.Name, ProjectService__r.Title__c, JobStatus__c, IsExecuted__c, CompletionStatus__c,JobScheduledDate__c,AccountableExecutionCompany__r.Name, ExceptionName__c FROM Job__c';
        sql.add('select Id,JobStatus__c,ProjectService__r.Title__c,project__r.Retailer__r.name,IsExecuted__c,ResponsibleForExecution__c,CompletionStatus__c,ExceptionCode__c,ExceptionName__c,Location__r.Name,JobScheduledDate__c,EstimatedMinutes__c,NumberOfWorkers__c,NumberOfDays__c,ProjectScheduleOptionCode__c, Name,LocationNumber__c ,JobCanceledComments__c,JobCanceledReason__c,ProjectEndDate__c ,AccountableExecutionCompany__r.name FROM Job__c WHERE Project__c=:projectId');
        return sql;
    }
    private static List<String> genJobCountBaseSoql(){
        List<String> sql = new List<String>();
        sql.add('SELECT count() FROM Job__c WHERE Project__c=:projectId');
        return sql;
    }
    private static List<job__c> getProjectJobs(String projectId){
        AppUtil.getCPUUsage();
        List<String> sql = genJobSelectBaseSoql();
        sql.Add('LIMIT ' + LightningRequestHelper.PAGE_SIZE);
        // sql.Add('LIMIT 100 ');
        system.debug('******************************'+String.join(sql, ' '));
        List<job__c> jobList = Database.query(String.join(sql, ' '));
        
        
        return jobList;  
        
        
    }
    
    @AuraEnabled
    public static Map<String,Object> searchProjectJobsByKeyword(Map<String,String> query){
        //ResponseWrapper rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Search Completed Successfully', new List<Map<String,Object>>());
        
        try
        { 
            Map<String,Object> result = new Map<String,Object>();
            //  String[] params = validateKeywordSearch(query);
            
            String projectId = parseString(query.get('projectId'));
            
            LightningRequestHelper.checkStringValueRequired(projectId,'The Project Id is required when searching project jobs.');
            
            List<Job__c> projectJobs = getProjectJobs(projectId);
            
            if(projectJobs.size() == 0) {
                return null;
            } 
            
            Integer numberOfJobs = calculateRowCount(projectId);
            String displaytotalJobCount = String.valueof(numberOfJobs);
            if(numberOfJobs == 45001){
                displaytotalJobCount = '45000+';
            }
            //Integer displaytotalJobCount = calculateRowCount(projectId);
            result.put('rowCount',displaytotalJobCount);
            result.put('data',buildJobSearchResponse(projectJobs));
            // throw new AuraHandledException('Jobs are not loading');
            return result;
        }
        catch(AuraHandledException e)
        {
            throw e;
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getMessage() + ':' + ex.getStackTraceString());
        }
        
    }
    private static Integer calculateRowCount(String projectId){	
        //List<String> sql= genJobCountBaseSoql();
        //AggregateResult[] results = Database.query(String.join(sql, ' '));
        //return Integer.valueOf(results[0].get('total'));
        /*integer count= 0;
for(AggregateResult result: [select Count(Id) total FROM Job__c WHERE Project__c=:projectId]){
count += Integer.valueOf(result.get('total'));
}
return count;*/
        Integer totalRecords = Database.countQuery('Select Count()  FROM Job__c WHERE Project__c=:projectId LIMIT 45001');
        return totalRecords;
        
        
    }
    
    
    
    
    Private static List<Map<String,Object>> buildJobSearchResponse(List<job__c> projectJobs){
        List<Map<String,Object>> data = new  List<Map<String,Object>>();
        if(projectJobs.size() > 0)
        {
            for(Job__c rec: projectJobs){
                data.add(transformProjectJobs(rec));
            }
        }
        return data;
    }    
    
    
    @AuraEnabled
    public static Map<String,Object> populateJobFilterDropDowns(Map<String,Object> query) {
        String projectId = parseString(query.get('projectId'));
        if (String.isBlank(projectId)){
            throw new AuraHandledException('The Project Id is required when populating managejob filter Dropdowns.');
        }
        Project__c  p  = getProject(projectId);
        Map<String,Object> response = new Map<String,Object>();
        response.put('services', getServices(projectId));
        response.put('executionCompany', getExecutioncompanies());
        response.put('jobStatus', getJobStatuses());
        response.put('completed', getJobcompletionstatus());
        response.put('exceptionReasons', getExceptionReasons(projectId));
        response.put('namespace', CONSTANTS.CURRENTNAMESPACE);
        response.put('exportJobReportUrl', AppUtil.exportJobReportUrl.replace('{ProjectNumber}',p.ProjectNumber__c));
        return response;
    }
    
    static Project__c getProject(string projectId){
        return [SELECT Id, ProjectNumber__c FROM Project__c WHERE Id=:projectId];
    }
    
    private static List<Map<String,Object>> getServices(String projectId){
        List<Map<String,Object>> services = new List<Map<String,Object>>();
        for(ProjectService__c ps: getProjectServices(projectId)){
            Map<String,string> mapItem = new Map<String,String>();
            if((String) (ps.servicetitle__c)!=null && (String) (ps.servicetitle__c)!='')
            {
                mapItem.put('id', (String) ps.Name );
                mapItem.put('value', (String) ps.servicetitle__c + ' - ' +  (String) ps.Service__r.Name);
                
            }
            else
            {
                mapItem.put('id', (String)ps.Name );
                mapItem.put('value', (String) ps.Service__r.Name); 
            }
            
            services.add(mapItem);
        }
        return services;
    }  
    private static List<ProjectService__c> getProjectServices(String projectId){
        
        
        String sql = 'SELECT Service__c , Service__r.Name , servicetitle__c ,Name  from ProjectService__c WHERE Project__c = :projectId AND Service__c != null  ORDER BY Service__r.Name ASC';
        //String sql = 'SELECT Id, Name, Service__c, ServiceName__c FROM ProjectService__c WHERE Project__c=:projectId';
        return Database.query(sql);
    }
    private static List<Map<String,Object>> getExceptionReasons(String projectId){
        List<Map<String,Object>> exceptionReasons = new List<Map<String,Object>>();
        for(Exception__c ps: getExceptionReasonsLst(projectId)){
            Map<String,Object> mapItem = new Map<String,Object>();
            mapItem.put('id',(String)ps.ExceptionCode__c);
            mapItem.put('value', (String)ps.Name);
            exceptionReasons.add(mapItem);
        }
        return exceptionReasons;
    }
    
    private static List<Exception__c> getExceptionReasonsLst(String projectId){
        
        //String sql = 'SELECT  Exception__r.Name exname, Exception__r.ExceptionCode__c excode  FROM serviceException__c where service__c in (select service__c from projectservice__c where project__c =: projectId) group by Exception__r.Name, Exception__r.ExceptionCode__c order by Exception__r.Name';
        String sql = 'SELECT ExceptionCode__c,Name FROM Exception__c Order By Name Asc';
        
        return Database.query(sql);
    }
    
    private static List<Map<String,Object>> getExecutioncompanies(){
        List<Map<String,Object>> Executioncompanies = new List<Map<String,Object>>();
        for(Account a: getExecutioncompaniesSql()){
            Map<String,string> mapItem = new Map<String,String>();
            mapItem.put('id', a.id);
            mapItem.put('value', a.name);
            Executioncompanies.add(mapItem);
        }
        return Executioncompanies;
    }  
    
    private static List<Account> getExecutioncompaniesSql(){
        String  ExeCompany = 'Execution Company';
        String sql = 'SELECT Id,Name FROM Account WHERE RecordType.Name = :ExeCompany';
        return Database.query(sql);
    }
    private static List<Map<String,Object>> getJobStatuses(){
        List<Map<String,Object>> items = new List<Map<String,Object>>();
        Schema.DescribeFieldResult fieldResult = Job__c.JobStatus__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry entry: ple){
            Map<String,String> mapItem = new Map<String,String>();
            mapItem.put('id', entry.getValue());
            mapItem.put('value', entry.getLabel());
            items.add(mapItem);
        }
        return items;
        
    }
    @AuraEnabled
    public static  String deleteJobs(Map<String,Object> query)
    {
        ResponseWrapper rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Successfully Deleted Jobs',null);
        String projectId = LightningRequestHelper.parseString(query.get('projectId'));
        LightningRequestHelper.checkStringValueRequired(projectId,'The Project Id is required when removing the project Jobs.');
        List<Id> jobs = LightningRequestHelper.parseArrayOfId(query.get('jobs'));
        if(jobs.size() == 0) {
            rw.State = CONSTANTS.RESPONSE_STATE_ERROR;
            rw.Message='There are no project jobs to remove.';
            //throw new AuraHandledException('There are no project jobs to remove.');
        }
        else
        {
            try{
                
                List<ActionResponse> responses = JobActionsHelper.deleteJobs(jobs);
                if(jobs.size() == 1)
                {
                    rw.Message= jobs.size() +' job deleted Successfully.';
                }
                else
                {
                    rw.Message= jobs.size() +' jobs deleted Successfully.'; 
                }
                
            }
            catch(AuraHandledException e)
            {
                throw e; 
            }
            catch(Exception ex){
                //throw new AuraHandledException(ex.getMessage() + ':' + ex.getStackTraceString());
                rw.State = CONSTANTS.RESPONSE_STATE_ERROR;
                rw.Message =   'Delete Jobs Method Failed: ' + ex.getMessage(); 
                
            }
        }
        
        return JSON.serialize(rw);  
        
    }
    @AuraEnabled
    public static String deleteAllJobsByProject(Map<String,Object> query)
    {
        ResponseWrapper rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Successfully Deleted Jobs',null);
        String projectId = LightningRequestHelper.parseString(query.get('projectId'));
        try{
            
            if (String.isBlank(projectId)){
                rw.Message= 'The project Id is required when Delete jobs.';
                
            }
            else
            {     
                List<ActionResponse> responses = ProjectActionsHelper.DeleteAllJobsByProject(projectId);
                
                if(responses[0].IsSuccessful){
                    rw.Message=  responses[0].ResponseMessage;
                }
            }
        }
        catch(AuraHandledException e)
        {
            throw e; 
        }
        catch(Exception ex){
            //throw new AuraHandledException(ex.getMessage() + ':' + ex.getStackTraceString());
            rw.State = CONSTANTS.RESPONSE_STATE_ERROR;
            rw.Message =   'Delete All Jobs Method Failed: ' + ex.getMessage(); 
            
        }
        
        return JSON.serialize(rw);  
    }
    
    
    
    private static List<Map<String,Object>> getJobcompletionstatus(){
        List<Map<String,Object>> items = new List<Map<String,Object>>();
        Schema.DescribeFieldResult completedFieldResult = Job__c.CompletionStatus__c.getDescribe();
        List<Schema.PicklistEntry> ple = completedFieldResult.getPicklistValues();
        for(Schema.PicklistEntry entry: ple){
            Map<String,String> mapItem = new Map<String,String>();
            mapItem.put('id', entry.getValue());
            mapItem.put('value', entry.getLabel());
            items.add(mapItem);
        }
        return items;
        
    }
    @AuraEnabled
    public static Map<String,Object> filterJobs(Map<String,Object> query)
    {
        try{
            
            // List<Map<String,Object>> data = new List<Map<String,Object>>();
            Map<String,Object> result = new Map<String,Object>();
            String projectId = LightningRequestHelper.parseString(query.get('projId'));
            LightningRequestHelper.checkStringValueRequired(projectId,'The Project Id is required when filtering the project jobs.');
            List<Object> queryResults=  projectJobsByFilter(projectId, query);
            Integer countResults= Integer.valueOf(queryResults[0]);
            List<Job__c> pJobs = (List<Job__c>) queryResults[1];
            // integer numberOfJobs =   Integer.valueOf(countResults[0].get('total'));
            String displaytotalJobCount = String.valueOf(countResults);
            if(countResults == 45001){
                displaytotalJobCount = '45000+';
            }
            result.put('rowCount', displaytotalJobCount);
            result.put('data',buildFilterResponse( pJobs));
            return result;
            
        }
        catch(AuraHandledException e)
        {
            throw e;
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getMessage() + ':' + ex.getStackTraceString());
        }
        
        
    }
    
    Private static List<Map<String,Object>> buildFilterResponse(List<job__c> projectJobs){
        List<Map<String,Object>> data = new  List<Map<String,Object>>();
        if(projectJobs.size() > 0)
        {
            for(Job__c rec: projectJobs){
                data.add(transformProjectJobs(rec));
            }
        }
        return data;
    }
    
    private  static List<Object> projectJobsByFilter(String projectId, Map<String,Object> query){
        String keywordSearch= '';
        String jobkeyword= '';
        List<String> predicates = new List<String>();
        List<Object> results = new List<Object>();
        List<String> jobBasesoql  = genJobSelectBaseSoql();
        List<String> jobCountBasesoql = genJobCountBaseSoql();
        String[] keywords = query.get('keyword') != null ? LightningRequestHelper.parseArrayOfString(query.get('keyword')):new String[]{};
            Integer size = keywords.size();
        if(size > 1) {
            predicates.add('AND (Location__r.LocationNumber__c In :keywords)');
        } else {
            if(size == 1){
                keywordSearch = keywords[0] + '%';
                predicates.add('AND (Location__r.LocationNumber__c Like :keywordSearch OR Location__r.Name Like :keywordSearch)');
            }
        }
        String[] jobkeywords = query.get('jobkeyword') != null ? LightningRequestHelper.parseArrayOfString(query.get('jobkeyword')):new String[]{};
            
            Integer jobNames = jobkeywords.size(); 
        if(jobNames > 1) {
            predicates.add('AND (Name In :jobkeywords)');
        } else {
            if(jobNames == 1){
                jobkeyword = jobkeywords[0] + '%';
                
                
                predicates.add('AND (Name Like :jobkeyword)');
            }
        }
        
        
        Boolean isExecuted = false;
        Boolean isCompleted = false;
        String selService = LightningRequestHelper.parseString(query.get('selService'));
        String Completed = LightningRequestHelper.parseString(query.get('Completed'));
        List<String> expReason = LightningRequestHelper.parseArrayOfString(query.get('expReason'));
        String exeCompany = LightningRequestHelper.parseString(query.get('exeCompany'));
        
        List<String> jobStatus = LightningRequestHelper.parseArrayOfString(query.get('projjobStatus'));
        
        isExecuted = LightningRequestHelper.parseBoolean(query.get('chkExecuted'));
        Date dateFrom = LightningRequestHelper.parseDate(query.get('scheduleDateFrom'));
        // sql.add('AND JobScheduledDate__c >= :dateFrom');
        Date dateTo = LightningRequestHelper.parseDate(query.get('scheduleDateTo'));
        
        
        if(!String.isBlank(selService)){
            predicates.add('AND ProjectService__r.Name = :selService ');
        }
        if(!String.isBlank(Completed)){
            predicates.add('AND CompletionStatus__c = :Completed ');
        }
        if(expReason.size()>0){
            predicates.add('AND ExceptionCode__c IN :expReason ');
        }
        
        
        if(!String.isBlank(exeCompany)){
            predicates.add('AND ResponsibleExecutionCompany__c  = : exeCompany' );
        }
        if(jobStatus.size()>0){
            predicates.add('AND JobStatus__c IN :jobStatus');
        }
        if(isExecuted){
            predicates.add('AND IsExecuted__c  =: isExecuted');
        }
        if(!LightningRequestHelper.isDateNull(dateFrom)){
            predicates.add('AND JobScheduledDate__c >= : dateFrom');
        }
        if(!LightningRequestHelper.isDateNull(dateTo)){
            predicates.add('AND JobScheduledDate__c <= : dateTo');
        }
        //Order By SystemModstamp  DESC
        jobCountBasesoql.addAll(predicates);
        jobCountBasesoql.Add('LIMIT 45001');
        results.add(Database.countQuery(String.join(jobCountBasesoql, ' ')));
        jobBasesoql.addAll(predicates);
        jobBasesoql.Add('LIMIT ' + LightningRequestHelper.PAGE_SIZE);
        results.add(Database.query(String.join(jobBasesoql, ' ')));
        return results;             
    }
    
 
}