public with sharing class ProjectSummaryControllerExt {
    public Project__c project {get; set;}
    public List<ProjectAccount__c> projectAccounts {get; set;}
    public Map<Date, Integer> projectExecutionByDate {get; set;}
    public Integer totalLocationsExecuted {get; set;}


    public Map<Id, Map<Date, Integer>> projectserviceExecutionByDate {get; set;}
    public Map<Id, Map<String, Integer>> projectserviceJobsByStatus {get; set;}
    public Map<Id, Integer> projectserviceExecution {get; set;}

    public List<ProjectService__c> projectServices {get; set;}
    public Map<Id, string> projectServiceObjectives {get; set;}
    public Map<Id, List<ProjectServiceQuestion>> sqSummary {get; set;}
    public Map<Id, string> exceptions {get; set;}
    public Map<string, integer> JobCompletionSummary {get; set;}
    public Map<Id, Map<string, Integer>> projectserviceCompletionSummary {get; set;}
    public Integer completedJobs {get; set;}


    //added by david zhao
    private Map<Id, List<KVP>> serviceExceptionsMap {get; set;}
    public ProjectRecord projectRecord {get; set;}
    public String oneHubData {get; set;}
    private Integer jobCount {get; set;}
    private Integer jobNotCancelledCount {get; set;}
    private Integer jobExecutedCount {get; set;}
    private Boolean isTestMode {get; set;}

    public class ExceptionRecord  {
        public String code {get; set;}
        public String name {get; set;}
        public String color {get; set;}
        public ExceptionRecord(String code, String name, String color) {
            this.code = code;
            this.name = name;
            this.color = color;
        }
    }

    public String getNAMESPACE() {
        return CONSTANTS.CURRENTNAMESPACEPREFIX;
    }

    public String formatNumber(Integer value) {
        List<String> args = new String[] {'0', 'number', '###,###,###'};
        return String.format(value.format(), args);
    }
    public String formatDecimal(Decimal value) {
        List<String> args = new String[] {'0', 'number', '###,###,###.##'};
        return String.format(value.format(), args);
    }

    public class ProjectServiceQuestionDefinedResponse {
        public Id ProjectServiceQuestionDefinedResponseId {get; set;}
        public Id ProjectServiceQuestionId {get; set;}
        public string text {get; set;}
        public integer count {get; set;}
    }


    public class ProjectServiceQuestion {
        public ProjectServiceQuestion() {
            psqdrs = new List<ProjectServiceQuestionDefinedResponse>();
        }
        public Id ProjectServiceQuestionId {get; set;}
        public string type {get; set;}
        public Boolean isItem {get; set;}
        public integer qno {get; set;}
        public string text {get; set;}
        public integer count {get; set;}
        public Long sum {get; set;}
        public decimal average {get; set;}
        public List<ProjectServiceQuestionDefinedResponse> psqdrs {get; set;}

    }

    public ProjectSummaryControllerExt(ApexPages.StandardController controller) {
        totalLocationsExecuted = 0;
        string projectId = ApexPages.CurrentPage().getParameters().get('id');


        //if the user pass-in true for testmode query paramter, the controller will build test data for test purpose, so that all charts and
        //different question types are tested easily

        object testModeValue = ApexPages.CurrentPage().getParameters().get('testmode');

        isTestMode = (testModeValue != null && Integer.valueOf(testModeValue) == 1) ? true : false;
        if (true == isTestMode) {
            createOneHubTestData();
            return;
        }

        if (String.IsBlank(projectId)) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'project id not found. Please contact support.'));
            return;

        }
        SObject extPSQuestionObj;
        SObject extPSQuestiondrObj;
        try {
            extPSQuestionObj = (SObject)Type.forName('salesforce_vw_psquestion__x').newInstance();
        } catch (Exception ex) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'External data source not found. Please contact support.'));
            return;
        }

        try {
            extPSQuestiondrObj = (SObject)Type.forName('salesforce_vw_psquestiondr__x').newInstance();
        } catch (Exception ex) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'External data source not found. Please contact support.'));
            return;
        }


        List<string> projectIds = new List<string>();
        projectIds.add(projectId);
        if (projectId.length() > 15) {
            //For some reason, project servvice question has a 15 character project id
            //stored in the object. To compare, we are adding a 15 character salesforce
            //project id here.

            projectIds.add(string.valueOf(projectId.substring(0, 15)));
        }



        project = [Select Id, Name, ProjectNumber__c, ProjectRetailerName__c, BudgetedLocationsCount__c,
                   LocationTotalCount__c, ProjectLaunchDate__c, StartDate__c, EndDate__c, ProjectCloseDate__c, LaunchedProjectEndDate__c,
                   ProjectCycle__r.name, ProjectSeller__r.Name, OwnerName__c, Program__r.name from Project__c where Id = :projectId];


        //oh-2962: service visibility to the supplier and only pull project services that are visible
        //requested by wes on 09/077/2017, comment out visibility feature

        //OH-3447 comment in
        projectServices = [Select Id, Service__c, ServiceTitle__c, ServiceName__c, EstimatedMinutes__c, NumberOfWorkers__c,
                           NumberOfTargets__c, ServiceObjective__c from ProjectService__c WHERE Project__c = :projectId and IsVisibleToClient__c = true];
        //projectServices = [Select Id, Service__c, ServiceTitle__c, ServiceName__c, EstimatedMinutes__c, NumberOfWorkers__c, NumberOfTargets__c, ServiceObjective__c from ProjectService__c WHERE Project__c = :projectId];

        projectServiceObjectives = new Map<ID, String>();
        for (ProjectService__c ps : projectServices) {
            string attValue = ps.ServiceObjective__c == null ? 'None' : ps.ServiceObjective__c.unescapeHtml4();
            projectServiceObjectives.put(ps.Id, attValue);
        }

        projectAccounts = [Select AccountName__c from ProjectAccount__c WHERE Project__c = :projectId];

        system.debug('Number of Accounts: ' + projectAccounts.size());


        projectserviceJobsByStatus = new Map<Id, Map<String, Integer>>();
        List<AggregateResult> jobaggsstatus = [Select JobStatus__c jobStatus, ProjectService__c projectService, count(Id)cnt
                                               from Job__c WHERE Project__c = :projectId
                                                       AND ProjectService__c != null
                                                       GROUP BY JobStatus__c, ProjectService__c];

        for (AggregateResult jobagg : jobaggsstatus) {
            Map<String, Integer> newMap;
            if (projectserviceJobsByStatus.get(Id.ValueOf(string.valueof(jobagg.get('projectService')))) == null) {
                newMap = new Map<String, Integer>();
            } else {
                newMap = projectserviceJobsByStatus.get(Id.ValueOf(string.valueof(jobagg.get('projectService'))));
            }

            newMap.put(String.ValueOf(jobagg.get('jobStatus')), Integer.ValueOf(jobagg.get('cnt')));
            projectserviceJobsByStatus.put(Id.ValueOf(string.valueof(jobagg.get('projectService'))), newMap);
        }



        projectserviceExecutionByDate = new Map<Id, Map<Date, Integer>>();
        projectserviceExecution = new Map<Id, Integer>();

        List<AggregateResult> jobaggs = [Select JobExecutedDate__c jobExecutedDate, ProjectService__c projectService, count(Id)cnt
                                         from Job__c WHERE ProjectService__c != null AND Project__c = : projectId AND ProjectLocation__r.Status__c != 'Canceled'
                                                 AND JobExecutedDate__c != null AND JobStatus__c != :CONSTANTS.JOB_STATUS_CANCELED
                                                 GROUP BY JobExecutedDate__c, ProjectService__c];

        for (AggregateResult jobagg : jobaggs) {
            Map<Date, Integer> newMap;
            if (projectserviceExecutionByDate.get(Id.ValueOf(string.valueof(jobagg.get('projectService')))) == null) {
                newMap = new Map<Date, Integer>();
            } else {
                newMap = projectserviceExecutionByDate.get(Id.ValueOf(string.valueof(jobagg.get('projectService'))));
            }

            newMap.put(Date.ValueOf(jobagg.get('jobExecutedDate')), Integer.ValueOf(jobagg.get('cnt')));
            projectserviceExecutionByDate.put(Id.ValueOf(string.valueof(jobagg.get('projectService'))), newMap);



            Integer existingCount = 0;
            if (projectserviceExecution.get(Id.ValueOf(string.valueof(jobagg.get('projectService')))) == null) {
                existingCount  = 0;
            } else {
                existingCount = Integer.ValueOf(projectserviceExecution.get(Id.ValueOf(string.valueof(jobagg.get('projectService')))));
            }

            projectserviceExecution.put(Id.ValueOf(string.valueof(jobagg.get('projectService'))), existingCount + Integer.ValueOf(jobagg.get('cnt')));



        }


        projectExecutionByDate = new Map<Date, Integer>();
        List<AggregateResult> plaggs = [Select JobExecutedDate__c jobExecutedDate, Count(Id) cnt , ProjectLocation__c pl
                                        from Job__c WHERE Project__c = : projectId AND ProjectLocation__r.Status__c != :CONSTANTS.JOB_STATUS_CANCELED AND
                                                JobExecutedDate__c != null AND JobStatus__c != :CONSTANTS.JOB_STATUS_CANCELED GROUP BY ProjectLocation__c , JobExecutedDate__c];

        for (AggregateResult plagg : plaggs) {
            integer newcount = 0;
            if (projectExecutionByDate.get(Date.ValueOf(plagg.get('jobExecutedDate'))) != null) {
                newcount = projectExecutionByDate.get(Date.ValueOf(plagg.get('jobExecutedDate'))) + Integer.valueOf(plagg.get('cnt'));
            } else {
                newcount = Integer.valueOf(plagg.get('cnt'));
            }
            projectExecutionByDate.put(Date.ValueOf(plagg.get('jobExecutedDate')), newcount);

            totalLocationsExecuted++;
        }

        exceptions = new Map<Id, string>();
        List<Exception__c> exceptionsList = [Select Id, ExceptionCode__c, Name from Exception__c];
        for (Exception__c exc : exceptionsList ) {
            if (!exceptions.ContainsKey(exc.Id)) {
                exceptions.put(exc.Id, exc.Name);
            }
        }

        projectserviceCompletionSummary =   new Map<Id, Map<String, Integer>>();
        List<AggregateResult> psCompaggs = [Select Job__r.ProjectService__c projectservice, Exception__c exc, count(Id)cnt,
                                            Job__r.CompletionStatus__c compStatus from JobAttempt__c WHERE IsActive__c = true
                                                    AND Job__r.ProjectService__c != null AND Job__c IN (Select Id from Job__c WHERE Project__c = : projectId AND
                                                            JobStatus__c != :CONSTANTS.JOB_STATUS_CANCELED AND ProjectLocation__r.Status__c != 'Canceled')
                                                    GROUP BY Job__r.ProjectService__c, Exception__c, Job__r.CompletionStatus__c];

        for (AggregateResult jobcompagg : psCompaggs ) {

            string excCode = '';
            integer prevCount = 0;
            string jobStatus = jobcompagg.get('compStatus') == null ? '' : String.valueOf(jobcompagg.get('compStatus'));
            Map<String, Integer> newMap;

            if (projectserviceCompletionSummary.get(Id.ValueOf(string.valueof(jobcompagg.get('projectService')))) == null) {
                newMap =  new Map<String, Integer>();
            } else {
                newMap = projectserviceCompletionSummary.get(Id.ValueOf(string.valueof(jobcompagg.get('projectService'))));
            }

            if (jobStatus.toLowerCase() ==  CONSTANTS.JOB_COMPLETION_STATUS_COMPLETED.toLowerCase()) {
                excCode = 'None';
            } else if (jobcompagg.get('exc') == null && jobStatus.toLowerCase() == CONSTANTS.JOB_COMPLETION_STATUS_NOT_COMPLETED.toLowerCase()) {
                excCode = 'Not Attempted';
            } else if (jobcompagg.get('exc') != null) {
                excCode = exceptions.get(Id.ValueOf(String.ValueOf(jobcompagg.get('exc'))));
            }

            if (newMap.get(excCode) != null) {
                prevCount = newMap.get(excCode);
            }

            newMap.put(excCode , prevCount + Integer.valueof(jobcompagg.get('cnt')));
            projectserviceCompletionSummary.put(Id.ValueOf(string.valueof(jobcompagg.get('projectService'))), newMap);
        }


        //Added by Sankar Pati - Referring to external objects now
        //OH-4020
        string psqsql = 'SELECT psqid__c, psqname__c, questiontype__c, questiontext__c, definedresponsecount__c,';
        psqsql = psqsql + ' responsecount__c, responsesum__c, responseaverage__c,questionnumber__c, projectserviceid__c, itemquestion__c  ';

        psqsql = psqsql + ' FROM salesforce_vw_psquestion__x';

        psqsql = psqsql + ' WHERE projectid__c IN :projectIds AND isvisibletoclient__c=true order by questionnumber__c';
        List<SObject> psqs =  Database.query(psqsql);

        if (psqs == null || psqs.isEmpty()) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'No question data found for the summary report. please contact support.'));
            return;
        }


        string sqdrSoql = 'Select psqdrid__c, drtext__c, responsecount__c, psqid__c from salesforce_vw_psquestiondr__x' ;
        sqdrSoql  = sqdrSoql + ' WHERE  projectid__c IN :projectIds AND psqisvisibletoclient__c=true ';
        List<SObject> psqdrsList = Database.query(sqdrSoql);

        if (psqdrsList == null || psqdrsList.isEmpty()) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'No defined response data found for the summary report. please contact support'));
            return;
        }

        List<ProjectServiceQuestionDefinedResponse> psqdrcList = new List<ProjectServiceQuestionDefinedResponse>();

        for (SObject psqdr : psqdrsList) {
            ProjectServiceQuestionDefinedResponse psqdrc = new ProjectServiceQuestionDefinedResponse();
            psqdrc.ProjectServiceQuestionDefinedResponseId = string.valueOf(psqdr.get('psqdrid__c'));
            psqdrc.count = string.valueOf(psqdr.get('responsecount__c')) == null ? 0 : integer.valueOf(psqdr.get('responsecount__c'));
            psqdrc.text = string.valueOf(psqdr.get('drtext__c'));
            psqdrc.ProjectServiceQuestionId = string.valueOf(psqdr.get('psqid__c'));
            psqdrcList.add(psqdrc);

        }

        sqSummary = new Map<Id, List<ProjectServiceQuestion>>();


        for (SObject psq : psqs) {

            ProjectServiceQuestion psqc = new  ProjectServiceQuestion();
            String profileName = (String) psq.get('psqname__c');
            psqc.ProjectServiceQuestionId = string.valueOf(psq.get('psqid__c'));
            psqc.qno = Integer.ValueOf(psq.get('questionnumber__c'));
            psqc.type = string.valueOf(psq.get('questiontype__c'));
            psqc.text =  string.valueOf(psq.get('questiontext__c'));
            psqc.isItem = Boolean.valueOf(psq.get('itemquestion__c'));
            psqc.count = string.valueOf(psq.get('responsecount__c')) == null ? 0 : integer.valueOf(psq.get('responsecount__c'));
            Double sumDoubleValue = string.valueOf(psq.get('responsesum__c')) == null ? 0 : double.valueOf(psq.get('responsesum__c'));
            psqc.sum = sumDoubleValue.longvalue();
            Decimal averageDecimal = ((decimal)(psq.get('responseaverage__c'))) == null ? 0 : (Decimal)psq.get('responseaverage__c');

            psqc.average = averageDecimal.setScale(2, RoundingMode.HALF_UP);
            integer definedresponsecount = Integer.ValueOf(psq.get('definedresponsecount__c'));
            //needs to check
            if (definedresponsecount > 0) {
                for (ProjectServiceQuestionDefinedResponse psqdrc : psqdrcList) {
                    if (psqdrc.ProjectServiceQuestionId == psq.get('psqid__c')) {
                        psqc.psqdrs.add(psqdrc);

                    }
                }
            }
            string ProjectService = string.valueOf(psq.get('projectserviceid__c'));
            if (!sqSummary.ContainsKey(ProjectService)) {
                sqSummary.put(ProjectService, new ProjectServiceQuestion[] {psqc});
            } else {
                sqSummary.get(ProjectService).add(psqc);
            }
        }

        system.debug('SqSummary: ' + JSON.serialize(sqSummary));
        system.debug('Number of sqSummary: ' + sqSummary .size());
        createOneHubData();
    }

    String getString(Object obj, String defaultValue) {
        return obj == null ? defaultValue : String.valueOf(obj);
    }

    Integer getNumber(Object obj) {
        return obj == null ? 0 : Integer.valueOf(obj);
    }

    Double getCurrencyField(Object obj) {
        return obj == null ? 0 : Double.valueOf(obj);
    }
    //zyz
    void prepareJobCountsForRender() {
        jobNotCancelledCount = 0;
        jobCount = 0;
        jobExecutedCount = totalLocationsExecuted;
        Integer count;

        if (projectserviceJobsByStatus.isEmpty()) {
            return;
        }
        for (Map<String, Integer> countMap : projectserviceJobsByStatus.values()) {
            if (countMap.size() > 0) {
                for (String key : countMap.keySet()) {
                    count = getNumber(countMap.get(key));
                    jobCount += count;
                    if (CONSTANTS.JOB_STATUS_CANCELED.equalsIgnoreCase(key)) {
                        continue;
                    }
                    jobNotCancelledCount += count;
                }
            }
        }
    }

    private String getAccountName() {
        List<String> names = new List<String>();
        for (ProjectAccount__c acc : projectAccounts) {
            names.add(acc.AccountName__c);
        }
        return String.join(names, ',');
    }

    public class ProjectRecord {
        public String id {get; set;}
        public Integer jobCount {get; set;}
        public String executionPercent {get; set;}
        public String locations {get; set;}
        public Integer executedLocations {get; set;}
        public Integer budgetedLocations {get; set;}
        public Map<Date, Integer> executedLocationsByDay {get; set;}
        public String billableTime {get; set;}
        public String retailer {get; set;}
        public String title {get; set;}
        public String account {get; set;}
        public String cycle {get; set;}
        public String program {get; set;}
        public String owner {get; set;}
        public String builder {get; set;}
        public Date startDate {get; set;}
        public Date endDate {get; set;}
        public Date revisedEndDate {get; set;}
        public Date launchDate {get; set;}
        public Date closeDate {get; set;}
        public List<ServiceRecord> services {get; set;}

        private String calculateProjectExecutionPercent(Integer execCount, Integer jobCount) {
            decimal exJobs, canJobs, result;
            exJobs = Decimal.valueOf(execCount);
            canJobs = Decimal.valueOf(jobCount);

            if (canJobs > 0 ) {
                result = exJobs.divide(canJobs, 2, System.RoundingMode.HALF_UP);
                return Math.roundToLong(result * 100) + '%';
            } else {
                return '0%';
            }
        }

        public void setServices(List<ServiceRecord> services) {
            Integer executedJobCount = 0;
            this.services = services;
            for (ServiceRecord sr : services) {
                executedJobCount += sr.executedJobCount;
            }
            this.executionPercent = calculateProjectExecutionPercent(executedJobCount, this.jobCount);
        }
    }

    public class QuestionRecord {
        public String id {get; set;}
        public String value {get; set;}
        public String type {get; set;}
        public Object data {get; set;}
    }

    public class KVP {
        public String key {get; set;}
        public String value {get; set;}
        public KVP(String k, String v) {
            key = k;
            value = v;
        }
    }
    /* color definition for Job Completion
    'green': Completed
    'blue900': No authorirzed items
    'blue700': Display sold through
    'blue500': Manager Refused
    'blue400': Display Mode
    'blue300': Display Damaged
    'blue100': Did not complete
    */
    /* color definition for Job Execution
    'green': Jobs Executed
    'blue': Jobs Completed

    */
    public class ColoredJob {
        public String key {get; set;}
        public Integer value {get; set;}
        public String color {get; set;}
        public ColoredJob(String k, Integer v, String c) {
            key = k;
            value = v;
            color = c;
        }
    }

    public class ServiceRecord {
        private Map<String, ColoredJob> jobCompletionMap;
        private String[] colors {get; set;}
        public String id {get; set;}
        public String serviceId {get; set;}
        public String title {get; set;}
        public String name {get; set;}
        public String workers {get; set;}
        public Integer cancelledLocations {get; set;}
        public Integer notCancelledJobCount {get; set;}
        public Integer executedJobCount {get; set;}
        public String objective {get; set;}
        public Integer estimatedMinutes {get; set;}
        public Map<Date, Integer> servicesExecutedByDay {get; set;}
        public List<QuestionRecord> questions {get; set;}
        public List<ColoredJob> serviceJobCompletion {get {
                return jobCompletionMap.values();
            }
        }
        public List<ColoredJob> serviceJobExecution {get; set;}
        public string jobCompletionSummary {get; set;}

        public ServiceRecord(ID id) {
            serviceId = id;
            initJobCompletion();
        }

        String getColor() {
            integer pos = Math.mod(jobCompletionMap.size() - 1, colors.size());
            return colors[pos];
        }

        public void setJobCompletion(Map<Id, Map<string, Integer>> jobCompletionSet) {
            Integer totalCount = 0;
            Integer count;
            Map<String, Integer> jobSet = jobCompletionSet.get(serviceId);
            if (null == jobSet) { return; }
            for (String key : jobSet.keyset()) {
                count = jobSet.get(key);
                totalCount += count;
                setJobCompletionValue(key, count);
            }

            //jobCompletionMap.put('NONECMPL',new ColoredJob('Not Attempted',notCancelledJobCount - totalCount,getColor()));
        }

        public Integer getCompletedJobCount(Map<Id, Map<string, Integer>> jobCompletionSet) {
            Map<String, Integer> jobSet = jobCompletionSet.get(serviceId);
            if (null == jobSet) { return 0;}
            if (jobSet.containsKey('None')) {
                return jobSet.get('None');
            }
            return 0;
        }

        void setJobCompletionValue(String code, Integer value) {
            ColoredJob job;
            if (String.isBlank(code)) {return;}
            String key = code.toUpperCase();
            if (key.equals('NONE')) {
                job = jobCompletionMap.get('CMPL');
                job.value = value;
            } else {
                job = jobCompletionMap.get(key);
                if (null != job) {
                    job.value = value;
                } else {
                    jobCompletionMap.put(key, new ColoredJob(code, value, getColor()));
                }
            }
        }

        void initJobCompletion() {
            jobCompletionMap = new Map<String, ColoredJob>();
            jobCompletionMap.put('CMPL', new ColoredJob('Completed', 0, 'green'));
            colors = new String[] {
                'blue900',
                'blue700',
                'blue500',
                'blue400',
                'blue300',
                'blue100',
                'lightBlue900',
                'lightBlue800',
                'lightBlue700',
                'lightBlue600',
                'lightBlue500',
                'lightBlue400'
            };
        }
    }


    private ProjectRecord getProjectRecord() {
        ProjectRecord data = new ProjectRecord();
        data.title = project.name;
        data.executedLocations = totalLocationsExecuted;
        data.id = project.ProjectNumber__c;
        data.retailer = project.ProjectRetailerName__c;
        data.jobCount = jobNotCancelledCount;
        data.locations = formatNumber(getNumber(project.LocationTotalCount__c));
        data.billableTime = formatNumber(1234);
        data.executedLocationsByDay = projectExecutionByDate;
        data.account = getAccountName();
        data.cycle = getString(project.ProjectCycle__r.name, '');
        data.program = getString(project.Program__r.name, '');
        data.owner = getString(project.OwnerName__c, 'Owner Not Defined');
        data.builder = getString(project.ProjectSeller__r.Name, '');
        data.launchDate = project.ProjectLaunchDate__c;
        data.startDate = project.StartDate__c;
        data.closeDate = project.ProjectCloseDate__c;
        if (project.LaunchedProjectEndDate__c == null) {
            data.endDate = project.EndDate__c;
            data.revisedEndDate = project.EndDate__c;
        } else {
            data.endDate = project.LaunchedProjectEndDate__c;
            data.revisedEndDate = project.EndDate__c;
        }
        return data;
    }

    private String getServiceObjective(ID serviceId) {
        return projectServiceObjectives.containsKey(serviceId) ? String.valueOf(projectServiceObjectives.get(serviceId)) : 'Objective Not Defined';
    }

    private String transformQuestionType(String type) {
        String tp = String.isBlank(type) ? 'text' : type.toLowerCase();
        if (tp.indexOf('select list') != -1) {
            tp = 'picklist';
        } else if (tp.indexOf('yes/no') !=    -1) {
            tp = 'yesno';
        }
        return tp;
    }

    private Object getQuestionData(String type, ProjectServiceQuestion psq) {
        System.debug('------' + JSON.serialize(psq));
        List<KVP> result;
        KVP kvp;

        if ('text' == type || 'photo' == type || 'signature' == type) {
            return psq.count;
        }
        if ('date' == type) {
            return 'N/A - Unable to provide average response';
        }

        result = new List<KVP>();
        if ('yesno' == type || 'picklist' == type) {
            for (ProjectServiceQuestionDefinedResponse r : psq.psqdrs) {
                result.add(new KVP(r.text, String.valueOf(r.count)));
            }
            return result;
        }
        result.add(new KVP('Average', String.valueOf(psq.average)));
        result.add(new KVP('Total', String.valueOf(psq.sum)));
        return result;
    }

    private List<QuestionRecord> getQuestions(ID serviceId, ProjectService__c instance) {
        List<QuestionRecord> result = new List<QuestionRecord>();
        QuestionRecord question;
        Integer index = 0;
        if (false == sqSummary.containsKey(serviceId)) {
            return result;
        }
        List<ProjectServiceQuestion> qItems = sqSummary.get(serviceId);
        for (ProjectServiceQuestion q : qItems) {
            index++;
            question = new QuestionRecord();
            question.id = 'question' + index;
            question.type = transformQuestionType(q.type);
            question.value = q.text;
            question.data = getQuestionData(question.type, q);
            if (true == q.isItem && instance.NumberOfTargets__c == 0) {
                question.type = 'warn';
                question.data = 'The service has no targets so there is not a response to this question.';
            }
            result.add(question);
        }

        return result;
    }

    private Map<Date, Integer> getServiceExecutionByDay(ID serviceId) {
        return projectserviceExecutionByDate.containsKey(serviceId) ? projectserviceExecutionByDate.get(serviceId) :
               new Map<Date, Integer>();
    }

    void prepareServiceJobExecutionCountsForRender(ID projectServiceId, ServiceRecord instance) {
        String psId = String.valueOf(projectServiceId);
        Map<String, Integer> countMap;
        Integer count = 0;
        Integer notCanceledCount = 0;
        Integer canceledCount = 0;
        Integer executedCount = 0;
        Integer completedCount = 0;

        //caculate job execution count
        if (projectserviceJobsByStatus.containsKey(psId)) {
            countMap = projectserviceJobsByStatus.get(psId);
            if (countMap.size() > 0 ) {
                for (String key : countMap.keySet()) {
                    count = countMap.get(key);
                    if (CONSTANTS.JOB_STATUS_CANCELED.equalsIgnoreCase(key)) {
                        canceledCount += count;
                    } else {
                        notCanceledCount += count;
                    }
                }
            }
        }
        if (projectserviceExecution.containsKey(Id.valueOf(projectServiceId))) {
            executedCount = projectserviceExecution.get(Id.valueOf(projectServiceId));
        }

        //oh1533
        //completedCount = instance.getCompletedJobCount(projectserviceCompletionSummary);

        instance.cancelledLocations = canceledCount;
        //job execution
        instance.notCancelledJobCount = notCanceledCount;
        //oh1533
        /*
        List<ColoredJob> jobs= new List<ColoredJob>();
        jobs.add(new ColoredJob('Jobs Executed', executedCount,'green'));
        jobs.add(new ColoredJob('Jobs Completed', completedCount,'blue'));
        instance.serviceJobExecution = jobs;
        */
        instance.executedJobCount = executedCount;
    }

    private List<ServiceRecord> getServices() {
        Integer index = 0;
        ServiceRecord service;
        List<ServiceRecord> services = new List<ServiceRecord>();

        for (ProjectService__c ps : projectServices) {
            index++;
            service = new ServiceRecord(ps.Id);
            service.name = ps.ServiceName__c;
            service.title = ps.ServiceTitle__c;
            service.id = 'svc' + index;

            //todo: we need how many workers
            service.workers = getNumber(ps.NumberOfWorkers__c) > 1 ? 'Multiple' : 'Single';
            service.estimatedMinutes = getNumber(ps.EstimatedMinutes__c);
            service.objective = getServiceObjective(ps.id);
            service.questions = getQuestions(ps.id, ps);
            service.servicesExecutedByDay = getServiceExecutionByDay(ps.id);
            service.setJobCompletion(projectserviceCompletionSummary);

            prepareServiceJobExecutionCountsForRender(ps.Id, service);
            services.add(service);
        }

        return services;
    }

    private void calculateBillableTime() {
        Integer billTime = 0;
        for (ServiceRecord sr : projectRecord.services) {
            billTime += sr.estimatedMinutes;
        }
        projectRecord.billableTime = formatNumber(billtime);
    }

    private void createOneHubData() {
        prepareJobCountsForRender();
        projectRecord = getProjectRecord();
        projectRecord.setServices(getServices());
        calculateBillableTime();
        oneHubData = JSON.serialize(projectRecord);
    }

    private void createOneHubTestData() {
        //step 1 gen project record test data
        ProjectRecord prj = new ProjectRecord();
        prj.id = '123456789';
        prj.title = 'demo test data';
        prj.executedLocations = 2469;
        prj.retailer = 'Demo Retailer';
        prj.executionPercent = '95%';
        prj.locations = '2469';
        prj.billableTime = formatNumber(2347);
        prj.account = 'Kimberly Clark, Johnson & Johnson Baby Food Inc';
        prj.cycle = 'cycle 12';
        prj.program = 'Beer Taste';
        prj.owner = 'demo owner';
        prj.builder = 'demo builder';
        prj.launchDate = Date.parse('11/28/2016');
        prj.startDate = Date.parse('12/01/2016');
        prj.endDate = Date.parse('12/15/2016');
        prj.closeDate = Date.parse('12/22/2016');
        prj.revisedEndDate = Date.parse('12/20/2016');

        //step 2 create project level location execution data
        Map<Date, Integer> mp = new Map<Date, Integer>();
        Date base = Date.parse('12/01/2016');
        Integer totoCount = 0;
        Integer[] counts = new Integer[] {
            220, 150, 123, 200, 235, 23, 79, 12, 111, 320, 220, 150, 123, 200, 235, 23, 79, 12, 111, 320
        };
        for (Integer i = 0; i < 20; i++) {
            mp.put(base.addDays(i), counts[i] * 2);
            totoCount += counts[i];
        }
        prj.jobCount = totoCount * 2;
        prj.executedLocationsByDay = mp;

        //create services demo data
        ServiceRecord sr;
        List<ServiceRecord> services = new List<ServiceRecord>();
        String[] ids = new String[] {'a0b410000002IYbAAM', 'a0b410000002IYbAAN'};
        Map<Id, Map<string, Integer>> dataSet  = createTestJobCompletionSet(ids);
        Integer index = 0;
        mp = new Map<Date, Integer>();
        for (Integer i = 0; i < 20; i++) {
            mp.put(base.addDays(i), counts[i]);
        }
        for (String id : ids) {
            index++;
            sr = new ServiceRecord(id);
            sr.name = 'service name demo ' + id;
            sr.title = 'service title demo';
            sr.id =  'svc' + index;
            sr.workers = index == 1 ? 'Single' : 'Multiple';
            sr.estimatedMinutes = 30;
            sr.cancelledLocations = index == 1 ? 10 : 20;
            sr.notCancelledJobCount = totoCount;
            sr.executedJobCount = index == 1 ? 2300 : 1869;
            sr.objective = '<h2>object title' + id + '</h2><ul><li>objective 1</li><li>objective 2</li></ul>';
            sr.servicesExecutedByDay = mp;
            sr.questions = createQuestionTestData(index == 1 ? true : false);
            sr.setJobCompletion(dataSet);
            services.add(sr);
        }
        prj.services = services;
        projectRecord = prj;
        oneHubData = JSON.serialize(projectRecord);
    }

    private Map<Id, Map<string, Integer>> createTestJobCompletionSet(String[] ids) {
        Map<Id, Map<string, Integer>> dataSet = new Map<Id, Map<string, Integer>>();
        Map<String, Integer> items;
        for (String id : ids) {
            items = new Map<string, Integer>();
            items.put('None', 1670);
            items.put('No Authorized Items', 245);
            items.put('Display sold through', 123);
            items.put('Manager Refused', 87);
            items.put('Display removed', 65);
            items.put('Dispaly Damaged', 46);
            items.put('Did not complete', 56);
            dataSet.put(id, items);
        }
        return dataSet;
    }

    private List<QuestionRecord> createQuestionTestData(Boolean isLongPicklist) {
        List<QuestionRecord> qSet = new List<QuestionRecord>();
        QuestionRecord qr;
        String[] types = new String[] {
            'text',
            'photo',
            'date',
            'currency',
            'yesno',
            'picklist',
            'time',
            'number',
            'signature'
        };
        String[] questions = new String[] {
            'What is the shape of the product? (text)',
            'Take the product position photo (photo)',
            'when did you remove product from the shelf? (date)',
            'how much did it cost to replace it? (currency)',
            'Do you add label on the product? (yes/no)',
            'What color did you label the product? (picklist)',
            'How many minutes did you spend? (time)',
            'How many products did you put on the shelf?(number)',
            'Take your signature (signature)'
        };

        Integer index = 0;
        for (String tp : types) {
            qr = new QuestionRecord();
            qr.type = tp;
            qr.id = 'question' + index;
            qr.value = questions[index];
            qr.data = createTestQuestionData(tp, isLongPicklist);
            qSet.add(qr);
            index++;
        }
        qr = new QuestionRecord();
        qr.type = 'warn';
        qr.id = 'question' + index;
        qr.value = 'This is a target question but without targets (target question)';
        qr.data = 'The service has no targets so there is not a response to this question.';
        qSet.add(qr);

        return qSet;
    }

    private Object createTestQuestionData(String type, Boolean longPicklist) {
        List<KVP> result;
        KVP kvp;
        Integer len;
        Integer[] counts = new Integer[] {
            235, 93, 58, 1234, 342, 764, 425, 315, 648, 100, 186, 457, 389, 364, 321, 398, 365, 524, 578, 945, 897, 845, 685, 555
        };

        if ('text' == type || 'photo' == type || 'signature' == type) {
            return type == 'text' ? 234 : 12359;
        }
        if ('date' == type) {
            return 'N/A - Unable to provide average response';
        }

        result = new List<KVP>();
        if ('yesno' == type) {
            result.add(new KVP('Yes', '2333'));
            result.add(new KVP('No', '1859'));
            return result;
        }
        if ('picklist' == type) {
            len =  longPicklist ? 17 : 8;
            for (Integer i = 0; i < len; i++) {
                result.add(new KVP('Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum tincidunt est vitae ultrices accumsan. Aliquam ornare lacus adipiscing, posuere lectus et, fringilla augue. Rorem psum dolor sit amet, consectetur adipiscing elit. Vestibulum tincidunt est vitae ultrices accumsan', String.valueOf(counts[i])));
            }
            return result;
        }
        if ('currency' == type) {
            result.add(new KVP('Average', '$48.45'));
            result.add(new KVP('Total', '$25679.55'));
            return result;
        }
        result.add(new KVP('Average', '48'));
        result.add(new KVP('Total', '25679'));
        return result;
    }

}