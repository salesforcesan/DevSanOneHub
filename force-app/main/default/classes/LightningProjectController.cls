public with sharing class LightningProjectController {
    @testvisible
    static string projectWrapperQuery = 'SELECT Id, Name, OperationsTitle__c, ProjectNumber__c, ProjectType__c, ProjectTypeName__c, StartDate__c, EndDate__c, ProjectLaunchDate__c, Status__c, StatusDisplay__c, PercentExecuted__c,  BudgetedLocationsCount__c, '
                                        + 'ExecutionSLA__c, NumberofJobsException__c, NumberofJobsFailedQC__c, ServiceCount__c, MaxServiceCount__c, LocationTotalCount__c, NumberOfJobs__c, OwnerName__c,  BundleServices__c, CancelReason__c, CancelReasonComment__c,DetailReportURL__c, ExternalDetailReportURL__c, AllowReattempt__c,'
                                        + 'Retailer__c, ProjectRetailerName__c, OverrideAccountAndServiceAccess__c, IsShowProjectSummaryReport__c,Program__c, ProjectCycle__c, ProjectScheduleOptionName__c, LaunchedProjectStartDate__c, LaunchedProjectEndDate__c, ProjectCloseDate__c, NumberOfDays__c, ProjectScheduleOption__r.Code__c, IsPendingChangeReleaseRequest__c, IsPendingChanges__c, OutofCycleFulfillment__c, ProjectInstructions__c, ApexJobName__c '
                                        + 'FROM Project__c '
                                        + 'WHERE Id != null AND CloneStatus__c != \'Started\' ';


    @AuraEnabled
    public static String getNamespaceApex() {
        return CONSTANTS.CURRENTNAMESPACEPREFIX;
    }

    @AuraEnabled
    public static list<Object> getDashboardProjects(String statusFilters, String formFilters) {

        String baseQuery = projectWrapperQuery;

        String formQuery = '';
        String statusQuery = '';
        system.debug(' ********* form filters=' + formFilters);
        if (formFilters != null) {
            Map<String, Object> formFiltersMap = (Map<String, Object>) JSON.deserializeUntyped(formFilters);
            for (String fieldName : formFiltersMap.keySet()) {
                if (fieldName == 'Id') {
                    formQuery += 'AND ' + fieldName + ' = "' + formFiltersMap.get(fieldName) + '" ';
                } else if (fieldName == 'OwnerName__c' || fieldName == 'ProjectNumber__c' ) {
                    if (formFiltersMap.get(fieldName) != '') {
                        formQuery += 'AND ' + fieldName + ' LIKE \'%' + formFiltersMap.get(fieldName) + '%\' ';
                    }
                } else if (fieldName == 'Name') {
                    if (formFiltersMap.get(fieldName) != '') {
                        formQuery += 'AND ( ' + fieldName + ' LIKE \'%' + formFiltersMap.get(fieldName) + '%\' ';
                        formQuery += 'OR OperationsTitle__c LIKE \'%' + formFiltersMap.get(fieldName) + '%\') ';
                    }
                } else if (fieldName == 'locationsMin') {
                    formQuery += 'AND LocationTotalCount__c >= ' + formFiltersMap.get(fieldName) + ' ';
                } else if (fieldName == 'locationsMax') {
                    formQuery += 'AND LocationTotalCount__c <= ' + formFiltersMap.get(fieldName) + ' ';
                } else if (fieldName == 'jobsMin') {
                    formQuery += 'AND NumberOfJobs__c >= ' + formFiltersMap.get(fieldName) + ' ';
                } else if (fieldName == 'jobsMax') {
                    formQuery += 'AND NumberOfJobs__c <= ' + formFiltersMap.get(fieldName) + ' ';
                } else if (fieldName == 'StartDate' && formFiltersMap.get(fieldName) != '') {
                    formQuery += 'AND StartDate__c >= ' + formFiltersMap.get(fieldName) + ' ';
                } else if (fieldName == 'EndDate' && formFiltersMap.get(fieldName) != '') {
                    formQuery += 'AND EndDate__c <= ' + formFiltersMap.get(fieldName) + ' ';
                }
            }
        }

        if (statusFilters != null) {
            Map<String, Object> statusFiltersMap = (Map<String, Object>) JSON.deserializeUntyped(statusFilters);
            Boolean multiStatus = false;
            for (String fieldName : statusFiltersMap.keySet()) {
                system.debug('+++fieldName::: ' + fieldName);
                if (statusFiltersMap.get(fieldName) == true && fieldName == 'My Projects') {
                    formQuery += 'AND CreatedById = \'' + UserInfo.getUserId() + '\' ';
                } else if (statusFiltersMap.get(fieldName) == true && multiStatus == false) {
                    statusQuery += 'AND ( Status__c = \'' + fieldName + '\' ';
                    multiStatus = true;
                } else if (statusFiltersMap.get(fieldName) == true) {
                    statusQuery += 'OR Status__c = \'' + fieldName + '\' ';
                }
            }
            if (multiStatus == true) {
                statusQuery += ') ';
            }
        }

        String orderBy = ' ORDER BY LastModifiedDate DESC';
        String limitBy = ' LIMIT 25 ';
        String query = baseQuery + formQuery + statusQuery + orderBy + limitBy;

        // System.debug('DEVDEBUG Querying >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ' + query);
        //list<project__c> lstProj = Database.query(query);
        system.debug('*********query: ' + query);
        List<ProjectWrapper> pws = new List<ProjectWrapper>();
        List<Project__c> pList = Database.query(query);
        for (Project__c p : pList) {
            pws.add(getProjectWrapper(p));
        }
        return pws;

    }

    public static ProjectWrapper getProjectWrapper(Project__c p) {
        ProjectWrapper pw = new ProjectWrapper();
        pw.Id = p.Id;
        pw.Name = p.Name;
        pw.OperationsTitle = p.OperationsTitle__c;
        pw.ProjectNumber = p.ProjectNumber__c;
        pw.ProjectTypeName = p.ProjectTypeName__c;
        pw.StartDate = p.StartDate__c;
        pw.EndDate = p.EndDate__c;
        pw.ProjectLaunchDate = p.ProjectLaunchDate__c;
        pw.Status = p.Status__c;
        pw.StatusDisplay = p.StatusDisplay__c;
        pw.PercentExecuted = p.PercentExecuted__c;
        pw.ExecutionSLA = p.ExecutionSLA__c;
        pw.NumberofJobsException = p.NumberofJobsException__c;
        pw.NumberofJobsFailedQC = p.NumberofJobsFailedQC__c;
        pw.ServiceCount = p.ServiceCount__c;
        pw.MaxServiceCount = p.MaxServiceCount__c;
        pw.LocationTotalCount = p.LocationTotalCount__c;
        pw.BudgetedLocationsCount = p.BudgetedLocationsCount__c;
        pw.NumberOfJobs = p.NumberOfJobs__c;
        pw.OwnerName = p.OwnerName__c;
        pw.ProjectRetailerName = p.ProjectRetailerName__c;
        pw.Program = p.Program__c;
        pw.ProjectCycle = p.ProjectCycle__c;
        pw.IsBundleService = p.BundleServices__c;
        pw.ProjectScheduleOptionName = p.ProjectScheduleOptionName__c;
        pw.LaunchedProjectStartDate = p.LaunchedProjectStartDate__c;
        pw.LaunchedProjectEndDate = p.LaunchedProjectEndDate__c;
        pw.ProjectCloseDate = p.ProjectCloseDate__c;
        pw.IsSingleDay = (p.NumberOfDays__c == 1 ? true : false);
        pw.IsReAttemptDateRequired = ((p.ProjectScheduleOption__r.Code__c == 'USER' || p.ProjectScheduleOption__r.Code__c == 'SYSTEM') ? true : false);
        pw.IsPendingChangeReleaseRequest = p.IsPendingChangeReleaseRequest__c;
        pw.IsPendingChanges = p.IsPendingChanges__c;
        pw.CancelReason = p.CancelReason__c;
        pw.CancelReasonComment = p.CancelReasonComment__c;
        pw.OutOfCycleFulfillment = p.OutOfCycleFulfillment__c;
        pw.DetailReportURL = string.valueof(p.DetailReportURL__c);
        pw.ExternalDetailReportURL = string.valueof(p.ExternalDetailReportURL__c);
        pw.ProjectInstructions = (p.ProjectInstructions__c == null) ? ' ' : p.ProjectInstructions__c;
        pw.ApexJobName = (p.ApexJobName__c == null) ? '' : p.ApexJobName__c;
        pw.AllowReattempt = p.AllowReattempt__c == null ? true : p.AllowReattempt__c;
        pw.IsShowProjectSummary = p.IsShowProjectSummaryReport__c;
        pw.OverrideAccountAndServiceAccess = p.OverrideAccountAndServiceAccess__c;
        //pw.DefinedResponseList = null;
        return pw;
    }

    @AuraEnabled
    public static ProjectWrapper getProjectByServiceId(string projectServiceId) {
        try {
            ProjectService__c ps = [SELECT Project__c from ProjectService__c Where Id = :projectServiceId];
            return GetProject(ps.Project__c);
        } catch (Exception ex) {
            throw new AuraHandledException('The system ran into an error: ' + ex.getLineNumber() + ':' + ex.getStackTraceString());
        }
    }

    @AuraEnabled
    public static String getProjectSummary() {

        List<SummaryCountWrapper> output = new List<SummaryCountWrapper>();
        output.add(new SummaryCountWrapper('My Projects', [SELECT count() FROM Project__c WHERE OwnerId = :UserInfo.getUserId()]));

        Map<String, Integer> statusToResultCount = new Map<String, Integer>();
        for (AggregateResult res : [SELECT Status__c status, count(Id) projectCount FROM Project__c WHERE Status__c IN ('Planning', 'Booked', 'Launched', 'In Progress', 'Ended', 'Canceled', 'Closed') GROUP BY Status__c]) {
            statusToResultCount.put((String) res.get('status'), (Integer) res.get('projectCount'));
        }

        output.add(new SummaryCountWrapper('Planning', statusToResultCount.get('Planning')));
        output.add(new SummaryCountWrapper('Booked', statusToResultCount.get('Booked')));
        output.add(new SummaryCountWrapper('Launched', statusToResultCount.get('Launched')));
        output.add(new SummaryCountWrapper('In Progress', statusToResultCount.get('In Progress')));
        output.add(new SummaryCountWrapper('Ended', statusToResultCount.get('Ended')));
        output.add(new SummaryCountWrapper('Canceled', statusToResultCount.get('Canceled')));
        output.add(new SummaryCountWrapper('Closed', statusToResultCount.get('Closed')));

        System.debug(' output ' + output);
        return JSON.serialize(output);
    }

    @AuraEnabled
    public static ProjectWrapper GetProject(String recordId) {

        string projectId = getProjectId(recordId);
        String query = projectWrapperQuery + ' AND Id = \'' + projectId + '\'';
        List<Project__c> pList = Database.query(query);
        return getProjectWrapper(pList[0]);
    }


    @AuraEnabled
    public static void saveProjectAttributesApex (String stringprojectwrapper) {

        system.debug('ProjectWrapper: ' + stringprojectwrapper);

        try {

            ProjectWrapper pw = (ProjectWrapper) JSON.deserialize(stringprojectwrapper, ProjectWrapper.class);

            Map<Id, string> pawmap = new Map<Id, string>();
            Set<Id> paset = new Set<Id>();
            Set<Id> attributes = new Set<Id>();
            List<ProjectAttributeWrapper> pawList = pw.ProjAttributeList;
            if (pawList != null && pawList.size() > 0) {
                for (ProjectAttributeWrapper paw : pawList) {
                    pawmap.put(paw.RecordID, paw.AttributeValue);
                    paset.add(paw.RecordID);

                }

                List<ProjectAttribute__c> paList;
                paList = [Select Id, AttributeValue__c, Attribute__c from ProjectAttribute__c WHERE Id in :paset];
                for (ProjectAttribute__c pa : paList) {
                    attributes.add(pa.Attribute__c);
                }

                //This will store attribute__c, Map<DefinedResponse, AttributeDefinedResponse__c>

                Map<String, Map<String, String>> attDRMap = new Map<String, Map<String, String>>();

                List<AttributeDefinedResponse__c> adrs = [Select Id, Name, Attribute__c, DefinedResponse__c FROM AttributeDefinedResponse__c WHERE Attribute__c in :attributes];

                for (AttributeDefinedResponse__c adr : adrs) {
                    if (attDRMap.get(adr.Attribute__c) == null) {
                        Map<String, String> tempadr = new Map<string, string>();
                        tempadr.put(adr.DefinedResponse__c, adr.Id);
                        attDRMap.put(adr.Attribute__c, tempadr);
                    } else {
                        attDRMap.get(adr.Attribute__c).put(adr.DefinedResponse__c, adr.Id);
                    }
                }


                if (!paList.isEmpty()) {
                    for (ProjectAttribute__c pa : paList) {
                        pa.AttributeValue__c = String.valueOf(pawmap.get(pa.Id)).toLowerCase().trim().equals('select') ? '' : pawmap.get(pa.Id);
                        if (attDRMap.get(pa.Attribute__c) != null && attDRMap.get(pa.Attribute__c).get(pa.AttributeValue__c) != null)
                            pa.AttributeDefinedResponse__c  = attDRMap.get(pa.Attribute__c).get(pa.AttributeValue__c);
                    }

                    update paList;


                }

            }
        } catch (Exception ex) {
            throw new System.AuraHandledException('Error saving project attributes: ' + ex.getMessage());
        }

    }
    
    
    @AuraEnabled
    public static ProjectWrapper GetProjectWithAttributes(String recordId) {
        String query = projectWrapperQuery + ' AND Id = \'' + recordId + '\'';
        List<Project__c> pList = Database.query(query);
        Project__c projData = pList[0];

        string projAttrQry = QueryUtil.FetchQuery('Projectattribute__c');
        projAttrQry += ' WHERE project__c = \'' + recordId + '\' order by ProjectTypeAttribute__r.attributeorder__c';
        system.debug('~~projAttrQry~~' + projAttrQry);
        list<Projectattribute__c> projAttrData = Database.query(projAttrQry);
        list<ProjectAttributeWrapper> pawList = new list<ProjectAttributeWrapper>();


        string definedResponseQry = ' SELECT Id, Attribute__r.Name, Attribute__r.AttributeTitle__c,Attribute__r.AttributeType__c, IsActive__c, Attribute__c, DefinedResponseOrder__c, DefinedResponse__c ';
        definedResponseQry += '  FROM AttributeDefinedResponse__c  where attribute__c in (SELECT attribute__c  FROM ProjectTypeAttribute__c where  ';
        definedResponseQry += ' projecttype__r.name = \'' + projData.ProjectTypeName__c + '\' and isActive__c=true) and IsActive__c = true order by attribute__c,DefinedResponseOrder__c,DefinedResponse__c  ' ;

        system.debug('~~definedResponseQry~~' + definedResponseQry);
        list<AttributeDefinedResponse__c> defResData = Database.query(definedResponseQry);
        Map<Id, list<AttributeDefinedResponse__c>> ResponseMap = new Map<Id, list<AttributeDefinedResponse__c>>();

        string attribute = '';
        if (!defResData.isEmpty())
            attribute = defResData[0].Attribute__c;

        list<AttributeDefinedResponse__c> tempDefResp = new  list<AttributeDefinedResponse__c>();
        for (AttributeDefinedResponse__c obj : defResData) {

            if (attribute != obj.Attribute__c) {
                ResponseMap.put(attribute, tempDefResp);
                tempDefResp = new  list<AttributeDefinedResponse__c>();
                attribute = obj.Attribute__c;
            }
            tempDefResp.add(obj);
        }

        if (attribute != '')
            ResponseMap.put(attribute , tempDefResp);


        List<ProjectTypeAttributeSetting__c> listProjectTypeAttributeSettings = [select Id,ProjectStatus__c, ProjectTypeAttribute__c,                                                                                  
                                                                                 ProjectTypeAttribute__r.Attribute__c, IsReadOnly__c
                                                                                 From ProjectTypeAttributeSetting__c 
                                                                                 Where ProjectTypeAttribute__r.ProjectType__c =:  projData.ProjectType__c
                                                                                 And ProjectStatus__c =: projData.Status__c
                                                                                ];
        Map<string,ProjectTypeAttributeSetting__c> mapAttributeToSettings= new Map<string,ProjectTypeAttributeSetting__c>();
        
        for(ProjectTypeAttributeSetting__c ptas: listProjectTypeAttributeSettings){
            mapAttributeToSettings.put(ptas.ProjectTypeAttribute__r.Attribute__c, ptas);
        }
        system.debug('----ResponseMap---' + ResponseMap);


        ProjectAttributeWrapper paw = new ProjectAttributeWrapper();
        list<AttributeDefinedResponseWrapper> responsesValue = new list<AttributeDefinedResponseWrapper>();
        ProjectTypeHelper ptHelper = new ProjectTypeHelper(projData.ProjectType__c);
        system.debug('----projAttrData---' + projAttrData);
        for (Projectattribute__c obj : projAttrData) {
            if (!ptHelper.IsAttributeVisible(obj.Attribute__c)) {
                continue;
            }

            paw = new ProjectAttributeWrapper(obj);
            if( mapAttributeToSettings.ContainsKey(obj.Attribute__c) ){
                ProjectTypeAttributeSetting__c ptas = mapAttributeToSettings.get(obj.Attribute__c);                
                paw.isReadOnly = ptas.IsReadOnly__c;
            }        
                                    
            responsesValue = new list<AttributeDefinedResponseWrapper>();
            if (ResponseMap.get(obj.Attribute__c) != null) {
                responsesValue.add(new AttributeDefinedResponseWrapper(null, 'Select', true));
                for (AttributeDefinedResponse__c adr : ResponseMap.get(obj.Attribute__c)) {
                    responsesValue.add(new AttributeDefinedResponseWrapper(adr));
                }

                paw.ResponsesList = responsesValue;
            }
            pawList.add(paw);
        }
        
        ProjectWrapper objProjectWrapper =  getProjectWrapper(projData);
        objProjectWrapper.ProjAttributeList = pawList;

        return objProjectWrapper;
    }

    @AuraEnabled
    public static String GetProjectService(String recordId) {
        ProjServiceWrapper psw = new ProjServiceWrapper();
        try {
            string psQuery = QueryUtil.FetchQuery('ProjectService__c');
            //psQuery = psQuery.replace('Select', 'Select service__r.AllowDistribution__c,Project__r.ProjectType__r.AllowMultidays__c,service__r.IsNumberOfWorkersRequired__c, ');
            psQuery += ' WHERE Id = \'' + recordId + '\'';
            system.debug('ps$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$:' + psQuery);
            ProjectService__c psData = Database.query(psQuery);
            psw = new ProjServiceWrapper(psData, null);

        } catch (exception ex) {
            psw = new ProjServiceWrapper();
            psw.isSuccess = false;
            psw.Message = ex.getMessage();
        }
        return JSON.serialize(psw);
    }

    @AuraEnabled
    public static ProjectAccount__c GetProjectAccounts(String projectId) {

        String query = 'SELECT AccountName__c,Account__c,Approver__c,BillToAddress__c,CreatedById,CreatedDate,Id,IsDeleted,IsPrimary__c, LastModifiedById, '
                       + 'LastModifiedDate,Name,Project__c,SplitValue__c,SystemModstamp FROM ProjectAccount__c '
                       + 'WHERE Project__c = \'' + projectId + '\'';

        System.debug('DEVDEBUG Querying >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ' + query);

        ProjectAccount__c returnValue = Database.query(query);

        return returnValue;

    }

    @AuraEnabled
    public static list<Object> GetProjectServices(String projectId) {

        String query = 'SELECT AttachmentLastModifiedDateforHT__c,AttachmentLastModifiedDate__c,AttributeLastModifiedDateforHT__c, '
                       + 'AttributeLastModifiedDate__c,CancelReasonComment__c,CancelReason__c,CertificationLastModifiedDateforHT__c,CertificationLastModifiedDate__c, '
                       + 'CreatedById,CreatedDate,DayNumber__c,EquipmentLastModifiedDateforHT__c,EquipmentLastModifiedDate__c,EstimatedMinutes__c,ExceptionPrompt__c, '
                       + 'ExternalService__c,FulfillmentCenterName__c,Id,IncludeAutoGenManual__c,IsDeleted,IsDeleted__c,JobManualFileName__c,JobManual__c, '
                       + 'JobManualURL__c,LastActivityDate,LastModifiedById,LastModifiedDate,LastSummaryRefreshDateTime__c,MaterialLastModifiedDateforHT__c, '
                       + 'MaterialLastModifiedDate__c,Name,NumberOfAssignedJobs__c,NumberOfAttributes__c,NumberOfCanceledJobs__c,NumberofCertifications__c, '
                       + 'NumberOfClosedJobs__c,NumberOfCompletedJobs__c,NumberOfDays__c,NumberOfEquipment__c,NumberOfExceptionJobs__c,NumberOfExecutedJobs__c, '
                       + 'NumberOfFailedQCJobs__c,NumberofJobsRescheduled__c,NumberOfJobs__c,NumberofKittedItems__c,NumberOfMaterials__c,NumberOfNotCanceledJobs__c, '
                       + 'NumberOfOpenJobs__c,NumberOfPendingJobs__c,NumberofQuestions__c,NumberOfReportedJobs__c,NumberOfScheduledJobs__c,NumberOfStartedJobs__c, '
                       + 'NumberOfTargets__c,NumberOfWorkers__c,OneHubRetailerId__c,PercentCompleted__c,PercentExecuted__c,PercentFailedQC__c,PercentScheduled__c, '
                       + 'PopulateTargetQuestions__c,ProjectNumber__c,ProjectServiceRetailerOneHubID__c,ProjectVersion__c,Project__c,PurchaseAmount__c, '
                       + 'QuestionLastModifiedDateforHT__c,QuestionLastModifiedDate__c,RefreshSummary__c,ReportedTotalTime__c,ResponsibleForExecution__c, '
                       + 'Retailer__c,SalesTax__c,ServiceName__c,ServiceTitle__c,Service__c,ShippingPreference__c,StartTime__c,Status__c,SystemModstamp, '
                       + 'TargetLastModifiedDateforHT__c,TargetLastModifiedDate__c,TargetType__c,Title__c,UniqueKey__c,VariantLanguage__c,Variant__c,serviceobjective__c '
                       + 'FROM ProjectService__c '
                       + 'WHERE Project__c = \'' + projectId + '\'';

        System.debug('DEVDEBUG Querying >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ' + query);

        list<ProjectService__c> returnValue = Database.query(query);

        // Begin stub code for ServiceRank__c
        integer index;
        for (integer i = 0; i < returnValue.size(); i++) {
            returnValue[i].put('ServiceRank__c', i + 1);
        }
        // End stub code for ServiceRank__c

        return returnValue;

    }

    @AuraEnabled
    public static String DeleteProjects(String projectId) {
        ResponseWrapper rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Successfully Deleted the Project', null);
        try {
            system.debug('######## Deleting Project ' + projectId);
            if (projectId == null || projectId == '') {
                rw.State = CONSTANTS.RESPONSE_STATE_ERROR;
                rw.Message = 'Invalid Project : ' + projectId;
            } else {
                TriggerUtil.skipProjectTrigger = true;
                List<ActionResponse> actionResp = ProjectActionsHelper.DeleteProject(projectId);
                if (!actionResp.isEmpty()) {
                    rw.Message = actionResp[0].ResponseMessage;
                }
            }
        } catch (Exception ex) {
            system.debug('######## Deleting Project Exception: ' + ex.getMessage());
            rw.State = CONSTANTS.RESPONSE_STATE_ERROR;
            rw.Message = 'Unable to Delete the Project : ' + projectId + ', ' + ex.getMessage();
        }
        return JSON.serialize(rw);
    }

    @AuraEnabled
    public static String ReleaseProjectChangesApex(String projectId) {

        Project__c project;

        try {
            List<Project__c> projects = [Select Id, name, ApexJobName__c, BatchProcessId__c, RecordTypeId,
                                         DateReleaseChangesRequested__c,
                                         IsPendingChangeReleaseRequest__c from Project__c WHERE Id = :projectId LIMIT 1];
            if (!projects.IsEmpty()) {
                project = projects[0];
            }

            project.IsPendingChangeReleaseRequest__c = true;
            ProjectActionsHelper.LockProject(project, 'Release project changes', '');
            project.DateReleaseChangesRequested__c = DateTime.Now();
            update project;

            AttachmentUrlGenerator.generateJobManualFutureCall(string.valueof(project.Id));

        } catch (Exception ex) {
            throw new System.AuraHandledException('Error releasing project changes: ' + ex.getMessage());
        }
        return 'success';
    }

    @AuraEnabled
    public static String ReleaseOOCFChangesApex(String projectId) {

        Project__c project;

        try {
            List<Project__c> projects = [Select Id, name, ApexJobName__c, BatchProcessId__c, RecordTypeId,
                                         DateReleaseChangesRequested__c,
                                         IsPendingChangeReleaseRequest__c,
                                         OutOfCycleFulfillmentRequest__c, OutOfCycleFulfillment__c
                                         from Project__c WHERE Id = :projectId LIMIT 1];
            if (!projects.IsEmpty()) {
                project = projects[0];
            }

            project.IsPendingChangeReleaseRequest__c = true;
            project.OutOfCycleFulfillmentRequest__c = true;
            project.OutOfCycleFulfillment__c = false;
            ProjectActionsHelper.LockProject(project, 'Releasing fulfillment changes', '');
            project.DateReleaseChangesRequested__c = DateTime.Now();
            update project;

            AttachmentUrlGenerator.generateJobManualFutureCall(projectId);

        } catch (Exception ex) {
            throw new System.AuraHandledException('Error releasing project changes: ' + ex.getMessage());
        }
        return 'success';
    }


    @AuraEnabled
    public static String CloneProject(String projectId) {
        ResponseWrapper rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Successfully cloned project.', null);

        try {
            TriggerUtil.skipProjectTrigger = true;
            CloneUtil.CloneAll(projectId);
        } catch (Exception ex) {
            System.debug('exception loop' +   ex.getMessage());
            rw.State = CONSTANTS.RESPONSE_STATE_ERROR;
            rw.Message = 'Unable to Clone the Project : ' + projectId + ', ' + ex.getMessage();
        }
        return JSON.serialize(rw);
    }

    @AuraEnabled
    public static String InitCloneProject(String projectId) {
        ResponseWrapper rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Clone project started. An email will be sent once project is ready to use.', null);
        try {
            System.enqueueJob(new CloneProjectQueuebleJob(Id.valueOf(projectId)));
        } catch (Exception ex) {
            rw.State = CONSTANTS.RESPONSE_STATE_ERROR;
            rw.Message = 'Unable to Clone the Project : ' + projectId + ', ' + ex.getMessage();
        }
        return JSON.serialize(rw);
    }

    @AuraEnabled
    public static String CancelProject(String projectId, String selReason, String selComm) {
        ResponseWrapper rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Successfully Canceled the Project', null);
        try {
            List<ActionResponse> actionResp =  ProjectActionsHelper.CancelProject(Id.valueOf(projectId), selReason, selComm);
            if (!actionResp.isEmpty()) {
                rw.Message = actionResp[0].ResponseMessage;
            }
        } catch (Exception ex) {
            rw.State = CONSTANTS.RESPONSE_STATE_ERROR;
            system.debug('********Cancel Project Exception for project: ' + projectId + ', ' + ex.getMessage() + ', ' + ex.getStackTraceString());
            rw.Message = 'Unable to Cancel the Project : ' + projectId + ', ' + ex.getMessage();
        }
        return JSON.serialize(rw);
    }

    @AuraEnabled
    public static List<String> GetProjectStatues() {
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = Project__c.Status__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        options.add('--SELECT--');
        for (Schema.PicklistEntry f : ple) {
            options.add(f.getLabel());
        }
        return options;
    }

    @AuraEnabled
    public static List<String> GetProjectCancelReasons() {
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = Project__c.CancelReason__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        options.add('--SELECT--');
        for (Schema.PicklistEntry f : ple) {
            options.add(f.getLabel());
        }
        return options;
    }
    @AuraEnabled
    public static void SubmitProject(Id  projectId) {
        Project__c project = [Select Id, Name, Status__c, ProjectTypeName__c, StartDate__c,
                              EndDate__c, RecordTypeId from Project__c WHERE ID = : projectId LIMIT 1];
        ProjectActionsHelper.ChangeStatus(project, CONSTANTS.PROJECT_STATUS_BOOKED);
        project.BookedProjectStartDate__c = project.StartDate__c;
        project.BookedProjectEndDate__c = project.EndDate__c;
        update project;
        AttachmentUrlGenerator.generateJobManualFutureCall(string.valueof(project.Id));
    }

    @AuraEnabled
    public static String deleteProjectServiceApex(string projectServiceId) {
        ResponseWrapper rw;
        try {
            TriggerUtil.SkipAllTriggers();
            List<Id> psIds = new List<Id>();
            psIds.add(projectServiceId);
            ProjectServiceActionsHelper.DeleteProjectServices(psIds);
            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Successfully deleted project service', 'SUCCESS');
        } catch (Exception e) {
            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_ERROR, 'Unable to delete project service', 'ERROR');
        }
        return JSON.serialize(rw);
    }

    @AuraEnabled
    public static String saveNonPlanningProject(string serilizedProject) {
        ResponseWrapper rw;
        try {
            ProjectWrapper pw = (ProjectWrapper) JSON.deserialize(serilizedProject, ProjectWrapper.class);
            Project__c p = [Select Id, Name, StartDate__c, EndDate__c, ProjectLaunchDate__c, ProjectInstructions__c FROM Project__c WHERE Id = :pw.Id];
            if (pw.Name != null) {
                p.Name = pw.Name;
            }
            if (pw.StartDate != null) {
                p.StartDate__c = pw.StartDate;
            }
            if (pw.EndDate != null) {
                p.EndDate__c = pw.EndDate;
            }
            if (pw.ProjectLaunchDate != null) {
                p.ProjectLaunchDate__c = pw.ProjectLaunchDate;
            }
            if (pw.ProjectInstructions != null) {
                p.ProjectInstructions__c = pw.ProjectInstructions;
            }
            update p;

            String query = projectWrapperQuery + ' AND Id = \'' + p.Id + '\'';
            List<Project__c> pList = Database.query(query);
            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Successfully saved project', getProjectWrapper(pList[0]));
        } catch (System.DmlException e) {
            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_ERROR, 'Unable to save project. Details: ' + e.getDmlMessage(0), 'error');
        } catch (Exception e) {
            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_ERROR, 'Unable to save project. Details: ' + e.getMessage(), 'error');
        }
        return JSON.serialize(rw);
    }

    @AuraEnabled
    public static String getOpportunityProjectConfirmationInfo(string opportunityId) {
        List<Opportunity> opprList = [SELECT Id, Name, StageName, ProjectStartDate__c, RecordTypeDeveloperName__c, ProjectEndDate__c, ProjectType__c, BillToContact__c, HasFulfillment__c, NumberOfLocations__c, QuotedTime__c FROM Opportunity WHERE Id = :opportunityId];
        if (opprList.isEmpty()) {
            return JSON.serialize(ResponseWrapper.createInstance(CONSTANTS.RESPONSE_STATE_ERROR,'No opportunity found'));
        }

       Opportunity o = opprList[0];        
        
       if(o.RecordTypeDeveloperName__c.containsIgnoreCase('Sams')){
            if(o.StageName != CONSTANTS.OPPORTUNITY_STAGENAME_CLOSED_WON || o.BillToContact__c == null){ // && 
            	return JSON.serialize(ResponseWrapper.createInstance(CONSTANTS.RESPONSE_STATE_ERROR,'Opportunity Stage must be Closed Won and Bill To Contact must be supplied for Sam\'s Opportunities.'));
            }
           
           //OH2-1172
           List<Opportunity> coOpportunityList = [SELECT Id,BillToContact__c FROM Opportunity
                                                  where ParentOpportunity__c = : opportunityId];
           
           boolean billToContactNeeded = false;
           if (!coOpportunityList.isEmpty()) {               
               
               for(Opportunity op : coOpportunityList)
               {
                   if (op.BillToContact__c == null){ billToContactNeeded = true; break; }
               }
           }
           
           if(billToContactNeeded){
            	return JSON.serialize(ResponseWrapper.createInstance(CONSTANTS.RESPONSE_STATE_ERROR,'Bill to contact is missing in partner opportunity.'));
            }
        }
        
		system.debug('opp bill to ' + o.BillToContact__c);
        system.debug('opp recordtypename ' + o.RecordTypeDeveloperName__c);

        Integer projcount = [SELECT Count() FROM Project__c WHERE Opportunity__c = :opportunityId];
        String info = 'You are attempting to create a project titled, ' + o.Name +  ', with ' + (o.NumberOfLocations__c == null ? 0 : o.NumberOfLocations__c)  + ' location(s). Please confirm by selecting create project, or press cancel to abort.';
        ResponseWrapper rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, projcount + ' project(s) are already associated with this opportunity', info);
        
        if (projcount > 0) {
            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, projcount + ' project(s) are already associated with this opportunity', info);
        } else {
            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, '', info);
        }

        return JSON.serialize(rw);
    }

    //OH-5395
    @AuraEnabled
    public static String createProjectFromOpportunity(string opportunityId) {
        ResponseWrapper rw;
        Savepoint sp = Database.setSavepoint();
        boolean requiresReservation = false;

        try {
            Opportunity o = [SELECT Id, Name, AccountId, Project__c, ProjectStartDate__c, ProjectEndDate__c, ProjectType__c,ProjectType__r.Name,
                             HasFulfillment__c, NumberOfLocations__c, QuotedTime__c, OwnerId, Reservation__c, BillToContact__c, PONumber__c
                             FROM Opportunity WHERE Id = :opportunityId LIMIT 1];

            List<OpportunityLineItem> olList = [Select Id, Service__c, Service__r.Name, Product2.AssetsRequired__c
                                                FROM OpportunityLineItem
                                                WHERE OpportunityId = :opportunityId];

            List<String> services = new List<String>();
            for (OpportunityLineItem ol : olList) {

                if (ol.Service__c != null) {
                    services.add(ol.Service__c);
                    if (ol.Product2.AssetsRequired__c != null && !requiresReservation) {
                        requiresReservation = true;
                    }
                }
            }
            
            Retailer__c r = [SELECT Id, FulfillmentLeadTime__c FROM Retailer__c LIMIT 1];
            OrgCustomSettings__c settings = [SELECT Id, Efficiency__c FROM OrgCustomSettings__c LIMIT 1];
            Id so = [Select Id from ScheduleOption__c WHERE Code__c = :CONSTANTS.SCHEDULE_OPTION_EC].Id;

            //OH-5738
            List<ProjectType__c> projectTypes = [SELECT Id, ScheduleOption__c, DefaultRetailerAccount__c, UseReservations__c FROM ProjectType__c where Id = : o.ProjectType__c  LIMIT 1];

            List<Reservation__c> oReservationList = [SELECT Id, Name, Status__c, NumberofReservedLocations__c FROM Reservation__c WHERE Id = : o.Reservation__c Limit 1];
            Reservation__c reservation;
            List<ReservationLocation__c> reservationLocationList = new List<ReservationLocation__c>();

            if (oReservationList.size() > 0) {
                reservation = oReservationList[0];
                reservationLocationList = [SELECT Id, ProjectLocation__c, Reservation__c, Location__c, LocationNumber__c, ReservedDate__c
                                           FROM ReservationLocation__c
                                           WHERE Reservation__c = : reservation.id
                                                   AND Status__c = : CONSTANTS.RESERVATIONLOCATION_STATUS_RESERVED];
            }

            //for user friendly error messages
            String missingFields = '';
            if (o.ProjectType__c == null) {
                missingFields = 'Project Type';
            }
            if (o.NumberOfLocations__c == null) {
                missingFields = (missingFields == '') ?  'Number of Locations' : missingFields + ', Number of Locations';
            }
            if (o.ProjectStartDate__c == null) {
                missingFields = (missingFields == '') ?  'Project Start Date' : missingFields + ', Project Start Date';
            }
            if (o.ProjectEndDate__c == null) {
                missingFields = (missingFields == '') ?  'Project End Date' : missingFields + ', Project End Date';
            }
            if (o.AccountId == null) {
                missingFields = (missingFields == '') ?  'Account' : missingFields + ', Account';
            }

            if ( requiresReservation && o.Reservation__c == null) {
                missingFields = (missingFields == '') ?  'Reservation' : missingFields + ', Reservation';
            }

            if (missingFields != '') {
                return JSON.serialize(ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_ERROR, 'Missing required fields: ' + missingFields, 'error'));
            }

            Project__c p = new Project__c();
            p.IsCreatedFromOpportunity__c = true;
            p.Name = (reservation != null) ? reservation.Name : o.Name;

            if (reservation != null) {
                p.Reservation__c = reservation.Id;
            }

            p.OperationsTitle__c = o.Name;
            p.Opportunity__c = opportunityId;
            p.ProjectType__c = o.ProjectType__c;
            p.StartDate__c = o.ProjectStartDate__c;
            p.EndDate__c = o.ProjectEndDate__c;
            p.BudgetedLocationsCount__c = o.NumberOfLocations__c;
            p.Retailer__c = r.Id;
            p.ProjectScheduleOption__c = so;
            p.ProjectSeller__c = o.OwnerId;
            
            //OH-1475
            /*if(o.ProjectType__r.Name =='CMK Events' || o.ProjectType__r.Name =='CMK Merch'){
                p.Division__c = '860-Sams Club Events';
                p.WorkType__c = 'DIV:US-CAO-760:CONT';    
            }*/

            if (o.HasFulfillment__c) {
                p.ProjectLaunchDate__c = p.StartDate__c.addDays((r.FulfillmentLeadTime__c == null || r.FulfillmentLeadTime__c < 0) ? -17 : (Integer.valueOf(r.FulfillmentLeadTime__c) * -1));
            }
            if (o.QuotedTime__c != null && settings.Efficiency__c > 0) {
                p.StoreCallTimeLimit__c = o.QuotedTime__c * settings.Efficiency__c;
            }


            if (projectTypes.size() > 0) {
                ProjectType__c projectType = projectTypes[0];
                if (projectType.ScheduleOption__c != null) {
                    p.ProjectScheduleOption__c =  projectType.ScheduleOption__c;
                }
                if (projectType.DefaultRetailerAccount__c != null) {
                    p.RetailerAccount__c = projectType.DefaultRetailerAccount__c;
                }
            }

            insert p;

            // To update project id into Opportunity
            o.Project__c = p.Id;
            update o;

            List<Opportunity> coOpportunityList = [SELECT Id, ParentOpportunity__c, AccountId, Name, BillToContact__c,
                                                   PONumber__c, ResponsibleParty__c FROM Opportunity
                                                   where ParentOpportunity__c = : opportunityId];

            //OH-5395
            List<ProjectAccount__c> projectAccountList = new List<ProjectAccount__c>();
            ProjectAccount__c pa = new ProjectAccount__c(Account__c = o.AccountId, project__c = p.Id, IsPrimary__c = True, Opportunity__c = o.Id, PONumber__c = o.PONumber__c, BillToContact__c = o.BillToContact__c);
            projectAccountList.add(pa);
            Map<Id, Id> projectAccountMap = new  Map<Id, Id>();
            projectAccountMap.put(pa.Id, pa.Id);

            for (Opportunity opportunity : coOpportunityList) {
                if (!projectAccountMap.ContainsKey(opportunity.Id)) {
                    ProjectAccount__c coopp = new ProjectAccount__c(Account__c = opportunity.AccountId, project__c = p.Id,
                            IsPrimary__c = false, Opportunity__c = opportunity.Id,
                            BillToContact__c = opportunity.BillToContact__c,
                            PONumber__c = opportunity.PONumber__c,
                            ResponsibleParty__c = opportunity.ResponsibleParty__c);
                    projectAccountList.add(coopp);
                    projectAccountMap.put(coopp.Id, coopp.Id);
                }
            }

            //insert pa;
            insert projectAccountList;

            List<ProjectLocation__c> plList = new List<ProjectLocation__c>();

            if (reservationLocationList.size() > 0) {
                for (ReservationLocation__c rl : reservationLocationList) {
                    ProjectLocation__c pl = new ProjectLocation__c();
                    pl.Project__c = p.Id;
                    pl.Location__c = rl.Location__c;
                    pl.ReservationLocation__c = rl.Id;
                    if (reservation != null) {
                        pl.LocationScheduledDate__c = rl.ReservedDate__c;
                    }
                    plList.add(pl);
                }
            }
            insert plList;

            if (!services.isEmpty()) {
                BatchCreateServices batch = new BatchCreateServices(p.Id, services, 'Create Project from Opportunity');
                string batchProcessId = Database.ExecuteBatch(batch, 1);

                Project__c project = [Select Id, ApexJobName__c from Project__c where Id = :p.Id LIMIT 1];
                project.ApexJobName__c = 'Creating Project Services ';
                update project;

            }

            List<ContentDocumentLink> cdList = new List<ContentDocumentLink>();

            //copy salesforce crm content attachments
            for (ContentDocumentLink c : [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :opportunityId]) {

                ContentDocumentLink cdl = new ContentDocumentLink(LinkedEntityId = p.Id, ContentDocumentId = c.ContentDocumentId, ShareType = 'I');
                cdList.add(cdl);
            }

            if (cdList.size() > 0) {
                insert cdList;
            }

            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Project Created Succesfully', p.Id);
        } catch (System.DmlException e) {
            Database.rollback(sp);
            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_ERROR, 'Unable to create project. Details: ' + e.getDmlMessage(0), 'error');
        } catch (Exception e) {
            Database.rollback(sp);
            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_ERROR, 'Unable to create project. Details: ' + e.getMessage(), 'error');
        }
        return JSON.serialize(rw);
    }

    @AuraEnabled
    public static String createReservationFromOpportunity(string opportunityId) {
        ResponseWrapper rw;
        string defaultRetailerAccount = '';
        Savepoint sp = Database.setSavepoint();
        try {
            Opportunity o = [SELECT Id, Name, AccountId, RequestedDate__c, NumberOfLocations__c, Reservation__c
                             FROM Opportunity WHERE Id = :opportunityId LIMIT 1];

            List<ProjectType__c> pts = [SELECT Id, Name, DefaultRetailerAccount__c from ProjectType__c WHERE UseReservations__c = true LIMIT 2];

            if (pts.size() == 1) {
                defaultRetailerAccount = pts[0].DefaultRetailerAccount__c;
            }

            //for user friendly error messages
            string missingFields = '';
            if (o.RequestedDate__c == null) {
                missingFields = 'Requested Date';
            }
            if (o.NumberOfLocations__c == null) {
                missingFields = (missingFields == '') ?  'Number of Locations' : missingFields + ', Number of Locations';
            }

            if (missingFields != '') {
                throw new System.AuraHandledException('Error creating reservation: ' + 'Missing required fields: ' + missingFields);
            }


            Reservation__c reservation = new Reservation__c();
            reservation.Name = o.Name;
            reservation.RequestedDate__c = o.RequestedDate__c;
            reservation.RequestedLocations__c = o.NumberOfLocations__c;
            reservation.PrimaryAccount__c = o.AccountId;
            reservation.PrimaryOpportunity__c = o.Id;
            reservation.Status__c = CONSTANTS.RESERVATION_STATUS_DRAFT;
            if (!String.isEmpty(defaultRetailerAccount)) {
                reservation.RetailerAccount__c = defaultRetailerAccount;
            }

            insert reservation;

            o.Reservation__c = reservation.Id;

            update o;

            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Reservation Created Succesfully', reservation.Id);
        } catch (System.DmlException e) {
            Database.rollback(sp);
            throw new System.AuraHandledException('Error creating reservation: ' + e.getDmlMessage(0));
        }
        return JSON.serialize(rw);
    }


    @AuraEnabled
    public static String getProjectFiles(string projectId) {
        ResponseWrapper rw;
        try {
            List<AttachmentWrapper> atts = new List<AttachmentWrapper>();
            for (Attachment a : [select id, name, owner.name, LastModifiedDate, Description from Attachment where ParentId = :projectId]) {
                AttachmentWrapper att = new AttachmentWrapper();
                att.Id = a.id;
                att.Name = a.name;
                att.Owner = a.owner.name;
                att.LastModifiedDate = a.LastModifiedDate;
                att.Description = a.Description;
                atts.add(att);
            }

            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'sucess', atts);
        } catch (Exception e) {
            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_ERROR, 'Unable to fetch project files. Details: ' + e.getMessage(), 'error');
        }
        return JSON.serialize(rw);
    }

    @AuraEnabled
    public static string deleteProjectFile(string attachmentId, string projectId) {
        ResponseWrapper rw;
        try {
            DELETE [SELECT Id FROM Attachment WHERE Id = :attachmentId AND ParentId = :projectId];
            return getProjectFiles(projectId);
        } catch (Exception e) {
            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_ERROR, 'Unable to delete file. Details: ' + e.getMessage(), 'error');
        }
        return JSON.serialize(rw);
    }

    @AuraEnabled
    public static Id saveTheChunk(Id parentId, String fileName, String base64Data, String contentType, String fileId) {
        system.debug(' ********* fileId=' + fileId);
        if (fileId == null || fileId == '') {
            fileId = FileUploadUtil.saveTheFile(parentId, fileName, base64Data, contentType);
            system.debug(' ********* fileId=' + fileId);
        } else {
            FileUploadUtil.appendToFile(fileId, base64Data);
        }

        return Id.valueOf(fileId);
    }

    @AuraEnabled
    public static void GenerateJobManual(string projectId) {
        try {
            system.debug('~~~GenerateJobManual~~~');
            AttachmentUrlGenerator.generateJobManualFutureCall(string.valueof(projectId));
        } catch (Exception e) {

        }
    }

    @AuraEnabled
    public static string getProjectTypesApex() {

        List<projecttype__c> pts = [Select Id, Name FROM ProjectType__c];

        String ptstring = JSON.serialize(pts);
        String ptstringsansuuc = ptstring.replace('__c', '');

        String ptstringsamsns = ptstringsansuuc.replace(CONSTANTS.CURRENTNAMESPACEPREFIX, '');


        system.debug(ptstringsamsns);
        return ptstringsamsns;
    }

    @AuraEnabled
    public static string getProjectRecordTypesApex() {

        String objectName = CONSTANTS.CURRENTNAMESPACEPREFIX + 'Project__c';
        List<recordtype> rts = [Select Id, DeveloperName FROM RecordType WHERE SObjectType = :objectName];

        Map<String, String> rtmap = new Map<String, String>();
        for (recordtype rt : rts) {
            rtmap.put(rt.DeveloperName, rt.Id);

        }

        String rtstring = JSON.serialize(rtmap);
        String rtstringsansuuc = rtstring.replace('__c', '');

        String rtstringsamsns = rtstringsansuuc.replace(CONSTANTS.CURRENTNAMESPACEPREFIX, '');


        system.debug(rtstringsamsns);
        return rtstringsamsns;
    }

    @testvisible
    private static string getProjectId(string recordid) {

        Id recid = Id.ValueOf(recordid);

        if (String.Valueof(recid.getSObjectType()).containsignorecase('project__c')) {
            return [SELECT Id FROM Project__c WHERE Id = :recid LIMIT 1].Id;
        } else if (String.Valueof(recid.getSObjectType()).containsignorecase('job__c')) {
            return [SELECT Id FROM Project__c WHERE Id IN (Select Project__c from Job__c WHERE Id = :recid) LIMIT 1].Id;
        } else if (String.Valueof(recid.getSObjectType()).containsignorecase('projectservice__c')) {
            return [SELECT Id FROM Project__c WHERE Id IN (Select Project__c from ProjectService__c WHERE Id = :recid) LIMIT 1].Id;
        } else if (String.Valueof(recid.getSObjectType()).containsignorecase('projectlocation__c')) {
            return [SELECT Id FROM Project__c WHERE Id IN (Select Project__c from ProjectLocation__c WHERE Id = :recid) LIMIT 1].Id;
        }
        return null;

    }
    @AuraEnabled
    public static string getAllReservationsForSelectedOpp(string opportunityId) {

        string reservationId = '';
        list<OpportunityWrapper> lstOpportunityWrapper = new list<OpportunityWrapper>();
        List<Opportunity> lstOpportunity = [select Reservation__c, Reservation__r.Name from Opportunity where Id = :opportunityId AND Reservation__c != null LIMIT 1];
        if (lstOpportunity.size() > 0) {
            for (Opportunity o : lstOpportunity) {
                lstOpportunityWrapper.add(new OpportunityWrapper(o.Reservation__c));
            }
        }

        if (lstOpportunityWrapper.size() > 0) {
            reservationId = string.valueOf(lstOpportunityWrapper[0].ReservationId);
        }



        // String rtstring = JSON.serialize(lstOpportunityWrapper);
        return reservationId;
    }


    @AuraEnabled
    public static void saveProjectAccess(String projectId, Boolean overrideAccess) {

        try {
            List<Project__c> projects = [SELECT  Id, OverrideAccountAndServiceAccess__c, OverrideAccessLastUpdated__c from Project__c where Id  = :projectId limit 1];
            if (projects != null && projects.size() > 0 ) {

                Project__c project =  projects[0];

                project.OverrideAccountAndServiceAccess__c = overrideAccess;
                project.OverrideAccessLastUpdated__c = system.now();

                update project;
            }
        } catch (Exception ex) {
            throw new System.AuraHandledException('Error saving project account service access: ' + ex.getMessage());
        }

    }
    
    @AuraEnabled
    public static boolean CheckApexQueueSize() {

        try {
            AggregateResult result = Database.query('SELECT count(id) total FROM AsyncApexJob WHERE Status = \'Holding\'');
            Integer flexQueueCount = Integer.valueOf(result.get('total'));
            AppSettings__mdt obj=  [SELECT Id, QualifiedApiName, Value__c, DeveloperName, MasterLabel, Label FROM AppSettings__mdt where DeveloperName = 'CloneApexQueueMax'];
            
            return (integer.valueOf(obj.Value__c) < flexQueueCount);
        } 
        catch (Exception ex) {
            throw new System.AuraHandledException('Error while fetching queue size: ' + ex.getMessage());
        }

    }

}