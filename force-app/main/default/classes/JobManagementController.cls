public with sharing class JobManagementController {
    
    public Project__c projectRecord {get;set;}
    public ProjectWrapper project {get;set;}
    public String filterSelections {get;private set;}
    public integer TotalJobCount{get;set;}
    public String displaytotalJobCount{get;set;}
    public integer maxResults {get;set;}
    public boolean isSCHEDULEOPTION_EC{get;set;}
    public boolean isMultiDay{get;set;}
    public boolean isSingleDay{get;set;}
    public date projEndDate{get;set;}
  
    
    public JobManagementController(ApexPages.StandardController stdController) {

        this.projectRecord = (Project__c)stdController.getRecord();
        projectRecord = [SELECT Id, Name, StartDate__c, EndDate__c, ProjectNumber__c, Status__c, ProjectScheduleOption__r.Code__c,NumberOfDays__c
                        FROM Project__c WHERE id =: projectRecord.Id];
        project = new ProjectWrapper(projectRecord);
        //load pre-selected filter selections (optional)
        filterSelections = ApexPages.currentPage().getParameters().get('fs');
        TotalJobCount= [select count() from job__c where project__c=: projectRecord.Id LIMIT 45001];
        displaytotalJobCount = String.valueOf(TotalJobCount);
        if(TotalJobCount == 45001){
            displaytotalJobCount = '45000+';
        }
        Jobs_Management_Page_Settings__c settings = Jobs_Management_Page_Settings__c.getInstance('Default');
        maxResults = settings == null ? 200 : Integer.valueOf(settings.Max_Number_of_Results__c);
        isSCHEDULEOPTION_EC=  (projectRecord.ProjectScheduleOption__r.Code__c==CONSTANTS.SCHEDULE_OPTION_EC);
        isSingleDay = !(projectRecord.NumberOfDays__c>1);
        projEndDate = projectRecord.EndDate__c;
    }

    @RemoteAction
    @ReadOnly
    public static String greeting(){
        return 'Ready to search';
    }

    @RemoteAction
    @ReadOnly
    public static FilterJobsResponse filterJobs(Id projectId, Map<String, String> filterMap) {

        Jobs_Management_Page_Settings__c settings = Jobs_Management_Page_Settings__c.getInstance('Default');
        integer maxResults = settings == null ? 200 : Integer.valueOf(settings.Max_Number_of_Results__c);
        
        if (filterMap == null) filterMap = new Map<String, String>();

        system.debug('filterMap' + filterMap);
        String baseQuery = 'SELECT Id, Name,Location__r.Name, ServiceName__c,ProjServiceName__c,ProjectService__r.Service__r.Name, ProjectService__r.Title__c, JobStatus__c, IsExecuted__c, CompletionStatus__c,JobScheduledDate__c,AccountableExecutionCompany__r.Name, ExceptionName__c FROM Job__c';

        Map<String, String> filterLabelToAPIName = new Map<String, String>{
            'Job Name' => 'Name'
            , 'Service' => 'ProjectService__r.Title__c'
            , 'Location' => 'Location__r.LocationNumber__c'
            , 'Execution Company' => 'AccountableExecutionCompany__c'
            , 'Status' => 'JobStatus__c'
            , 'Range Start' => 'JobScheduledDate__c'
            , 'Range End' => 'JobScheduledDate__c'
            , 'Exception_Reason' => 'ExceptionCode__c'
            , 'Executed' => 'IsExecuted__c'
            , 'Completed' => 'CompletionStatus__c'
            // TODO , 'Failed QC?' =>
        };

        String whereClause = ' WHERE Project__c = :projectId';
        system.debug('keySet' + filterMap.keySet());
        for (String filterLabel : filterMap.keySet()) {

            system.debug('filterLabel' + filterLabel);
            if (filterLabelToAPIName.containsKey(filterLabel)){

                String apiName = filterLabelToAPIName.get(filterLabel);
                Boolean addQuotes = (new Set<String>{ 'Job Name', 'Location', 'Execution Company', 'Status', 'Completed', 'Service', 'Exception_Reason'}).contains(filterLabel);
                Boolean searchContainsText = (new Set<String>{ 'Job' }).contains(filterLabel);

                String aggregatedSearchStrings = '';
                //Boolean isService = (new Set<String>{ 'Service' }).contains(filterLabel);

                system.debug('~~~~~'+ filterMap.get(filterLabel).replace('\n', ',')+'~~~~~'+ filterMap.get(filterLabel));
                
                for (String searchString : filterMap.get(filterLabel).replace('\n', ',').split(',')) {
                    system.debug('searchString~~~ ' + searchString );
                    searchString = String.escapeSingleQuotes(searchString.trim());
                    if (String.isBlank(searchString)) continue;

                    if (addQuotes && searchString.toLowerCase() == 'null') searchString = '';
                                             
                    if (searchContainsText) {
                        aggregatedSearchStrings += apiName + ' LIKE \'%' + searchString + '%\' OR ';
                    } else if (addQuotes) {
                        aggregatedSearchStrings += '\'' + searchString + '\',';
                    } else {
                        aggregatedSearchStrings += searchString + ',';
                    }
                }

                aggregatedSearchStrings = aggregatedSearchStrings.removeEnd(',').removeEnd(' OR ');

                if (!String.isBlank(aggregatedSearchStrings)) {

                    if (filterLabel == 'Range Start' || filterLabel == 'Range End') {
                        aggregatedSearchStrings = getSOQLFormat(aggregatedSearchStrings);
                        String compareOperator = filterLabel == 'Range Start' ? ' >= ' : ' <= ';
                        whereClause += ' AND ' + apiName + compareOperator + aggregatedSearchStrings;
                    } else if (searchContainsText) {
                        whereClause += ' AND (' + aggregatedSearchStrings + ')';
                    } else {
                        whereClause += ' AND ' + apiName + ' IN (' + aggregatedSearchStrings + ')';
                    }
                }
            }
        }

        String orderBy = ' ORDER BY name';
        String limitClause = ' LIMIT ' + maxResults;
        String query = baseQuery + whereClause + orderBy + limitClause;

        Job[] jobResults = new Job[]{};
        System.debug('DEVDEBUG Querying: ' + query);
        for (Job__c job : Database.query(query)) {
            jobResults.add(new Job(job));
        }

        Integer totalJobs = Database.countQuery('SELECT count() FROM Job__c' + whereClause);

        FilterJobsResponse output = new FilterJobsResponse();
        output.jobs = jobResults;
        output.total = totalJobs;
        return output;
    }

    //fetch a list of possible filters for jobs
    @ReadOnly
    @RemoteAction
    public static JobFilter[] getJobFilters(Id projectId) {

        SelectOption nullOption = new SelectOption('null', 'Null Value (blanks)');

        /*
        Schema.DescribeFieldResult fieldResult = JobAttempt__c.QCFailureReasonCode__c.getDescribe();//Exception__c.Name.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        JobFilter exceptionReasons = new JobFilter('Exception_Reason', 'multiselect', new SelectOption[]{});
        for( Schema.PicklistEntry f : ple){
            exceptionReasons.options.add(new SelectOption(f.getLabel(), f.getValue()));
        }
        exceptionReasons.options.add(nullOption);
        */
        
        Schema.DescribeFieldResult fieldResult = JobAttempt__c.QCFailureReasonCode__c.getDescribe();//Exception__c.Name.getDescribe();
        JobFilter exceptionReasons = new JobFilter('Exception_Reason', 'multiselect', new SelectOption[]{});
        for(AggregateResult agr : [SELECT  Exception__r.Name exname, Exception__r.ExceptionCode__c excode FROM serviceException__c where service__c in (select service__c from projectservice__c where project__c =: projectId) group by Exception__r.Name, Exception__r.ExceptionCode__c order by Exception__r.Name]){
            exceptionReasons.options.add(new SelectOption((String)agr.get('excode'),(String)agr.get('exname')));
        }
        exceptionReasons.options.add(nullOption);
        
        Schema.DescribeFieldResult jobFieldResult = Job__c.JobStatus__c.getDescribe();
        List<Schema.PicklistEntry> ple_status = jobFieldResult.getPicklistValues();
        JobFilter statusFilter = new JobFilter('Status', 'multiselect', new SelectOption[]{});
        for( Schema.PicklistEntry f : ple_status){
            statusFilter.options.add(new SelectOption(f.getLabel(), f.getValue()));
        }
        statusFilter.options.add(nullOption);

        Schema.DescribeFieldResult completedFieldResult = Job__c.CompletionStatus__c.getDescribe();
        List<Schema.PicklistEntry> completed_status = completedFieldResult.getPicklistValues();
        JobFilter completedFilter = new JobFilter('Completed', 'multiselect', new SelectOption[]{});
        for( Schema.PicklistEntry f : completed_status){
            completedFilter.options.add(new SelectOption(f.getLabel(), f.getValue()));
        }
        completedFilter.options.add(nullOption);

        JobFilter serviceFilter = new JobFilter('Service', 'multiselect', new SelectOption[]{});
        for(AggregateResult res : [SELECT Service__c value, Service__r.Name label, servicetitle__C title FROM ProjectService__c WHERE Project__c = :projectId AND Service__c != null GROUP BY Service__c, Service__r.Name, serviceTitle__c  ORDER BY Service__r.Name ASC]){
            //serviceFilter.options.add(new SelectOption((Id) res.get('value'), (String) res.get('title') + ' - ' + (String) res.get('label')));
            if((String) res.get('title')!=null && (String) res.get('title')!='')            
                serviceFilter.options.add(new SelectOption((String) res.get('title') + ' - ' + (String) res.get('label'), (String) res.get('title') + ' - ' +  (String) res.get('label')));
            else
                serviceFilter.options.add(new SelectOption((String) res.get('label'), (String) res.get('label')));
        }
        serviceFilter.options.add(nullOption);

        JobFilter executionCompanyFilter = new JobFilter('Execution Company', 'multiselect', new SelectOption[]{});
        for (AggregateResult res : [SELECT AccountableExecutionCompany__c value, AccountableExecutionCompany__r.Name label FROM Job__c WHERE Project__c = :projectId AND AccountableExecutionCompany__c != null GROUP BY AccountableExecutionCompany__c, AccountableExecutionCompany__r.Name ORDER BY AccountableExecutionCompany__r.Name ASC]) {
            executionCompanyFilter.options.add(new SelectOption((Id) res.get('value'), (String) res.get('label')));
        }

        return new JobFilter[]{
            new JobFilter('Job Name', 'text', new SelectOption[]{})
            , serviceFilter
            , new JobFilter('Location', 'text', new SelectOption[]{})
            , executionCompanyFilter
            , statusFilter
            , new JobFilter('Range Start', 'date', new SelectOption[]{})
            , new JobFilter('Range End', 'date', new SelectOption[]{})
            , exceptionReasons
            , new JobFilter('Executed', 'multiselect', new SelectOption[]{
                new SelectOption('true', 'True')
                , new SelectOption('false', 'False')
            })
            , completedFilter

        };
    }

    @RemoteAction
    public static List<ActionResponse> createAttempts(Id[] jobIds,string NewScheduledDate) { 
        system.debug('__####-----'+ NewScheduledDate);                 
        return JobActionsHelper.CreateAttempts(jobIds,(NewScheduledDate!=''?date.parse(NewScheduledDate):null),'');
    }

    //deprecated not in use
    @RemoteAction
    public static List<ActionResponse> setScheduledDate(Id[] jobIds, String scheduledDateString) {
        return null;
    }

    @RemoteAction
    public static List<ActionResponse> cancelJobs(Id[] jobIds, string cancelReason, string cancelComments) {
        return JobActionsHelper.cancelJobs(jobIds, cancelReason,cancelComments);
    }

    @RemoteAction
    public static List<ActionResponse> deleteJobs(Id[] jobIds) {
        return JobActionsHelper.deleteJobs(jobIds);
    }

    //retrieve list of cancelation reasons
    @RemoteAction
    public static List<String> cancelReasons() {
        List<String> reasons = new List<String>{};
        Schema.DescribeFieldResult reasonsFieldResult = Job__c.JobCanceledReason__c.getDescribe();
        List<Schema.PicklistEntry> ple_reasons = reasonsFieldResult.getPicklistValues();
        for( Schema.PicklistEntry ple : ple_reasons){
            //protect against stored xss
            String val = ple.getValue().escapeEcmaScript().escapeHTML3().escapeHTML4();
            reasons.add( val );
        }
        return reasons;
    }

    private static String getSOQLFormat(String dateStr) {

        return String.valueOf(getUSLocale(dateStr));
    }

    @testVisible
    private static String getUSLocale(Date dateObj) {

        if (dateObj == null) return '';

        return dateObj.month() + '/' + dateObj.day() + '/' + dateObj.year();
    }

    private static Date getUSLocale(String dateStr) {

        // Assuming front-end format of MM/DD/YYYY
        if (String.isBlank(dateStr)) return null;
        
        String[] dateComponents = dateStr.split('/');
        return Date.newInstance(Integer.valueOf(dateComponents[2]), Integer.valueOf(dateComponents[0]), Integer.valueOf(dateComponents[1]));
    }

    public class Job {
        public String id {get;set;}
        public String name {get;set;}
        public String service {get;set;}
        public String status {get;set;}
        public Boolean executed {get;set;}
        public String completed {get;set;}
        public String location {get;set;}
        public String scheduledDate {get;set;}
        public String executionCompany {get;set;}
        public String exceptionName {get;set;}

        public job(Job__c job){

            this.status = job.JobStatus__c;
            this.id = job.id;
            this.name = job.name;
            this.service = job.ProjectService__r.Title__c;
            this.executed = job.IsExecuted__c;
            this.location = job.Location__r.Name;
            this.completed = job.CompletionStatus__c;
            this.executionCompany = job.AccountableExecutionCompany__r.Name;
            this.exceptionName = job.ExceptionName__c;
            if(job.JobScheduledDate__c != null){
                this.scheduledDate = job.JobScheduledDate__c.format();
            }
        }
    }

    public class ProjectWrapper{
        public String id {get;set;}
        public String name {get;set;}
        public String startDate {get;set;}
        public String endDate {get;set;}
        public String projectNumber {get;set;}
        public String status {get;set;}
        public String option {get;set;}
        public ProjectWrapper(Project__c proj){
            this.name = proj.name;
            this.id = proj.id;
            this.startDate = getUSLocale(proj.StartDate__c);
            this.endDate = getUSLocale(proj.EndDate__c);
            this.projectNumber = proj.projectNumber__c;
            this.status = proj.status__c;
            this.option = proj.ProjectScheduleOption__r.Code__c;
        }
    }

    public class JobFilter {
        public String label { get; set; }
        public SelectOption[] options { get; set; }
        public String type { get; set; }
        public JobFilter(String label, String type, SelectOption[] options) {
            this.label = label;
            this.type = type;
            this.options = options;
        }
    }

    public class FilterJobsResponse {
        public Job[] jobs {get;set;}
        public Integer total {get;set;}
    }

    public class SelectOption {
        public String value { get; set; }
        public String label { get; set; }
        public Boolean selected { get; set; }
        public SelectOption(String value, String label) {
            this.value = value;
            this.label = label;
            selected = false;
        }
    }

}