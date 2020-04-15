public class CloneUtil {


    @future
    public static void CloneAllASync(string OrigProjectID) {
        CloneAll(OrigProjectID);
    }


    public static Id CloneAll(string OrigProjectID) {
        Id ClonedProjectID;
        Boolean success = false;
        string errorMessage = '';
        Project__c ClonedProject;
        TriggerUtil.SkipAllTriggers();
        Savepoint sp = Database.setSavepoint();

        try {
            ClonedProject = CloneProject(OrigProjectID);
            ClonedProjectID = ClonedProject.Id;
            CloneProjectService(OrigProjectID, ClonedProjectID, string.valueof(ClonedProject.Retailer__c));
            CloneProjectLocations(OrigProjectID, ClonedProjectID);
            success = true;
        } catch (Exception ex) {
            //Nothing to do here
            errorMessage = ex.getMessage();
            Database.rollback(sp);
            ClonedProjectID = null;
            throw ex;
        }
        return ClonedProjectID;
    }


    public static Project__c CloneProject(String OrigProjID) {
        Project__c rtn;
        //begin project
        project__c newproj = new project__c();
        string qry = ' Select ';
        string ObjectName = 'project__c';
        Result objReslt = FetchFieldInfo(ObjectName);
        qry = qry + objReslt.commaSepField + ' from ' + ObjectName + ' where id =\'' + OrigProjID + '\' limit 1';
        system.debug('!!!' + qry);

        project__c proj = Database.query(qry);
        project__c ClonedProj = new project__c();
        for (keyPair field : objReslt.keyPairVal) {
            if (string.valueof(field.key).contains('__c') || string.valueof(field.key) == 'Name') {
                ClonedProj.put(field.key, ((sobject)proj).get(field.key));
                if (string.valueof(field.key) == 'Name') {
                    if (((string)((sobject)proj).get(field.key)).length() > 72)
                        ClonedProj.put(field.key, ('Clone - ' +  ((string)((sobject)proj).get(field.key)).substring(0, 72)));
                    else
                        ClonedProj.put(field.key, ('Clone - ' +  ((sobject)proj).get(field.key)));
                }
            }
        }
        //OH1013: the cloned project builder is the user who click the clone button
        ClonedProj.ProjectBuilderId__c = UserInfo.getUserId();

        if (ClonedProj.ProjectSeller__c != null) {
            List<User> psusers = [Select Id, IsActive from User where Id = :ClonedProj.ProjectSeller__c And IsActive = True];
            if (psusers.isEmpty()) {
                ClonedProj.ProjectSeller__c = null;

            }

        }

        ClonedProj.StatusComments__c = '';
        ClonedProj.Status__c = CONSTANTS.PROJECT_STATUS_PLANNING;
        ClonedProj.ArchiveStatus__c = null;
        ClonedProj.UpdateJobsFlag__c = false;
        ClonedProj.UpdateSequence__c = null;
        ClonedProj.OriginID__c = null;
        ClonedProj.StartDate__c = Date.Today().addDays(30);
        ClonedProj.EndDate__c = Date.Today().addDays(30);
        ClonedProj.NumberOfDays__c = 1;
        ClonedProj.ProjectCycle__c = null;
        ClonedProj.ProjectLaunchDate__c = Date.Today().addDays(30);
        ClonedProj.ApprovalDate__c = null;
        ClonedProj.ApprovalRequestDate__c = null;
        ClonedProj.ApexJobName__c = '';
        ClonedProj.BatchProcessId__c = '';
        ClonedProj.BookedProjectEndDate__c = null;
        ClonedProj.BookedProjectStartDate__c = null;
        ClonedProj.CancelReason__c = '';
        ClonedProj.CancelReasonComment__c = '';
        ClonedProj.IsDeleted__c = false;
        ClonedProj.LaunchedProjectEndDate__c = null;
        ClonedProj.LaunchedProjectStartDate__c = null;
        ClonedProj.StatusComments__c = '';
        ClonedProj.DateLaunched__c = null;
        ClonedProj.IsPendingChanges__c = false;
        ClonedProj.OutofCycleFulfillmentRequest__c = false;
        ClonedProj.OutofCycleFulfillment__c = false;
        ClonedProj.IsPendingChangeReleaseRequest__c = false;
        ClonedProj.ClonedFromProject__c = OrigProjID;
        ClonedProj.PrimaryAccount__c = null;
        ClonedProj.SkipValidationRules__c = false;
        ClonedProj.DetailReportURL__c = '';
        ClonedProj.ExternalDetailReportURL__c = '';
        ClonedProj.OverrideAccessLastUpdated__c  = Date.Today();
        ClonedProj.AllowedRescheduleDates__c = '';

        //copy BundleServices from project type
        ProjectType__c pt = [SELECT Id, AllowBundlingOfServices__c, LaunchLeadTime__c FROM ProjectType__c WHERE Id = :ClonedProj.ProjectType__c];
        ClonedProj.BundleServices__c = pt.AllowBundlingOfServices__c;

        //set clone status so that its question response validation rules to skip
        ClonedProj.CloneStatus__c = CONSTANTS.CLONE_STATUS_STRATED;
        
        insert ClonedProj;
        id ClonedProjID = ClonedProj.ID;
        rtn = ClonedProj;

        //Add Project Tags
        List<Project__Tag> projectTags = AddProjectTags(OrigProjID, ClonedProjID);
        insert projectTags;

        //Add Project Accounts
        List<ProjectAccount__c> paList = AddProjectAccounts(OrigProjID, ClonedProjID);
        insert paList;

        //Populate the primary account on project
        for (ProjectAccount__c pa : paList) {
            if (pa.IsPrimary__c) {
                ClonedProj.PrimaryAccount__c = pa.Id;
                update ClonedProj;
            }
        }


        //Add Project Attributes
        List<ProjectAttribute__c> pattList = AddProjectAttributesAsIs(OrigProjID, ClonedProjID);
        insert pattList;



        return rtn;
    }

    private static List<Project__Tag> AddProjectTags(string originalProjectId, string clonedProjectId) {

        List<Project__Tag> ptags = new List<Project__Tag>();
        Project__Tag ptag;
        for (Project__Tag obj : [SELECT ItemId, Name, Type FROM Project__Tag WHERE ItemId = : originalProjectId]) {
            ptag = new project__tag();
            ptag.ItemId = clonedProjectId;
            ptag.name = obj.Name;
            ptag.Type = obj.Type;
            ptags.add(ptag);
        }
        return ptags;


    }

    private static List<ProjectAccount__c> AddProjectAccounts(string originalProjectId, string clonedProjectId) {

        //Project Accounts
        list<ProjectAccount__c> paList = new list<ProjectAccount__c>();
        ProjectAccount__c pa;
        string qry = ' Select ';
        string ObjectName = 'ProjectAccount__c';
        Result objReslt = FetchFieldInfo(ObjectName);
        qry = qry + objReslt.commaSepField + ' from ' + ObjectName + ' where Account__r.CanRequestProjects__c = true AND Project__c =\'' + originalProjectId + '\'';
        system.debug('!!! ProjectAccount__c !!!' + qry);

        list<ProjectAccount__c> objList = Database.query(qry);
        for (ProjectAccount__c obj : objList) {
            pa = new ProjectAccount__c();
            for (keyPair field : objReslt.keyPairVal) {
                if (string.valueof(field.key).contains('__c')) {
                    pa.put(field.key, ((sobject)obj).get(field.key));
                }
            }
            pa.Project__c = clonedProjectId;
            paList.add(pa);
        }

        return paList;

    }


    private static List<ProjectAttribute__c> AddProjectAttributesAsIs(string originalProjectId, string clonedProjectId) {
        List<ProjectAttribute__c> pattList = new list<ProjectAttribute__c>();
        ProjectAttribute__c patt;
        string qry = ' Select ';
        string ObjectName = 'ProjectAttribute__c';
        Result objReslt = FetchFieldInfo(ObjectName);
        qry = qry + objReslt.commaSepField + ' from ' + ObjectName + ' where Project__c =\'' + originalProjectId + '\'';
        system.debug('!!! ProjectAttribute__c !!!' + qry);

        list<ProjectAttribute__c> objList = Database.query(qry);
        for (ProjectAttribute__c obj : objList) {
            patt = new ProjectAttribute__c();
            for (keyPair field : objReslt.keyPairVal) {
                if (string.valueof(field.key).contains('__c')) {
                    patt.put(field.key, ((sobject)obj).get(field.key));
                }
            }
            patt.Project__c = clonedProjectId;
            pattList.add(patt);
        }
        return pattList;

    }

    private static Map<String, Map<Id, Id>> addClonedProjectServicesAndReturnIdMap(String originalProjectId, String clonedProjectId) {
        Map<String, Map<Id, Id>> resultMap = new Map<String, Map<Id, Id>>();
        Map<Id, Id> newOldIdMap = new Map<Id, Id>();
        Map<Id, Id> oldNewIdMap = new Map<Id, Id>();

        List<Id> originalProjectServiceIdList = new List<Id>();

        string ObjectName = 'projectservice__c';
        Result objReslt = FetchFieldInfo(ObjectName);
        string qry = ' Select ' + objReslt.commaSepField + ' from ' + ObjectName + ' where project__c =\'' + originalProjectId + '\' ';
        List<projectservice__c> projectServiceList = new List<projectservice__c>();
        ProjectService__c clonedProjectService;

        for (projectservice__c objPS : Database.query(qry)) {
            originalProjectServiceIdList.add(objPS.Id);

            clonedProjectService = new projectservice__c();
            for (keyPair field : objReslt.keyPairVal) {
                if (string.valueof(field.key).contains('__c') && !string.valueof(field.key).contains('UniqueKey__c') ) {
                    clonedProjectService.put(field.key, ((sobject)objPS).get(field.key));
                }
            }
            clonedProjectService.project__c = clonedProjectId;
            clonedProjectService.status__c = '';
            clonedProjectService.AttachmentLastModifiedDateforHT__c = null;
            clonedProjectService.AttributeLastModifiedDateforHT__c = null;
            clonedProjectService.CancelReason__c = '';
            clonedProjectService.CancelReasonComment__c = '';
            clonedProjectService.CertificationLastModifiedDateforHT__c = null;
            clonedProjectService.EquipmentLastModifiedDateforHT__c = null;
            clonedProjectService.IsDeleted__c = false;
            clonedProjectService.LastSummaryRefreshDateTime__c = null;
            clonedProjectService.MaterialLastModifiedDateforHT__c = null;
            clonedProjectService.NumberOfJobs__c = 0;
            clonedProjectService.NumberOfAssignedJobs__c = 0;
            clonedProjectService.NumberOfCanceledJobs__c = 0;
            clonedProjectService.NumberOfClosedJobs__c = 0;
            clonedProjectService.NumberOfCompletedJobs__c = 0;
            clonedProjectService.NumberOfExceptionJobs__c = 0;
            clonedProjectService.NumberOfExecutedJobs__c = 0;
            clonedProjectService.NumberOfFailedQCJobs__c = 0;
            clonedProjectService.NumberOfNotCanceledJobs__c = 0;
            clonedProjectService.NumberOfOpenJobs__c = 0;
            clonedProjectService.NumberOfPendingJobs__c = 0;
            clonedProjectService.NumberOfReportedJobs__c = 0;
            clonedProjectService.NumberofJobsRescheduled__c = 0;
            clonedProjectService.NumberOfScheduledJobs__c = 0;
            clonedProjectService.NumberOfStartedJobs__c = 0;
            clonedProjectService.QuestionLastModifiedDateforHT__c = null;
            clonedProjectService.RefreshSummary__c = false;
            clonedProjectService.TargetLastModifiedDateforHT__c = null;
            clonedProjectService.JobManualFileName__c = '';
            clonedProjectService.JobManualURL__c = '';
            clonedProjectService.NumberOfDays__c = 1;
            clonedProjectService.StartDayNumber__c = 1;
            clonedProjectService.ProjectNumberofDays__c = '1';
            clonedProjectService.DayNumbers__c = '1';
            projectServiceList.add(clonedProjectService);
        }
        Database.SaveResult[] results = Database.insert(projectServiceList);
        Database.SaveResult result;

        for (Integer i = 0; i < originalProjectServiceIdList.size(); i++) {
            result = results.get(i);
            if (!result.isSuccess()) {
                throw new CustomException('The project service cloning failed.');
            }
            newOldIdMap.put(result.getId(), originalProjectServiceIdList.get(i));
            oldNewIdMap.put(originalProjectServiceIdList.get(i), result.getId());
        }
        resultMap.put('newOldMap', newOldIdMap);
        resultMap.put('oldNewMap', oldNewIdMap);

        return resultMap;
    }



    public static Boolean CloneProjectService(String OrigProjID, string ClonedProjID, string RetailerId) {
        // to skip inserting default certifications and default equipments
        TriggerUtil.skipDeepClonedRecords = true;

        List<ProjectServiceQuestion__c> psqs = new List<ProjectServiceQuestion__c>();
        List<ProjectServiceCertification__c> pscs = new List<ProjectServiceCertification__c>();
        List<ProjectServiceTarget__c> psts = new List<ProjectServiceTarget__c>();
        List<ProjectServiceAttribute__c> psas = new List<ProjectServiceAttribute__c>();
        List<ProjectServiceMaterial__c> psms = new List<ProjectServiceMaterial__c>();
        List<ProjectServiceEquipment__c> pses = new List<ProjectServiceEquipment__c>();
        List<ProjectAccountServiceAccess__c> pasa = new List<ProjectAccountServiceAccess__c>();

        //clone project serivces and bulkify insert
        Map<String, Map<Id, Id>> addProjectServicesResult = addClonedProjectServicesAndReturnIdMap(OrigProjID, ClonedProjID);
        Map<Id, Id> newOldMap = addProjectServicesResult.get('newOldMap');
        Map<Id, Id> oldNewMap = addProjectServicesResult.get('oldNewMap');

        psts.addAll((List<ProjectServiceTarget__c>) AddProjectServiceRecords(oldNewMap, 'ProjectServiceTarget__c'));
        psqs.addAll((List<ProjectServiceQuestion__c>) AddProjectServiceRecords(oldNewMap, 'ProjectServiceQuestion__c'));
        pscs.addAll((List<ProjectServiceCertification__c>) AddProjectServiceRecords(oldNewMap, 'ProjectServiceCertification__c'));
        psas.addAll((List<ProjectServiceAttribute__c>) AddProjectServiceRecords(oldNewMap, 'ProjectServiceAttribute__c'));
        psms.addAll((List<ProjectServiceMaterial__c>) AddProjectServiceRecords(oldNewMap, 'ProjectServiceMaterial__c'));
        pses.addAll((List<ProjectServiceEquipment__c>) AddProjectServiceRecords(oldNewMap, 'ProjectServiceEquipment__c'));
        pasa.addAll((List<ProjectAccountServiceAccess__c>) AddProjectServiceRecords(oldNewMap, 'ProjectAccountServiceAccess__c'));

        for (ProjectAccountServiceAccess__c pas : pasa) {
            pas.Project__c = ClonedProjID;

        }

        //Set the flag for Cloned attachment so that the schedule job will pick it
        //up and create a new attachment and post it in image service.
        for (ProjectServiceAttribute__c psa : psas) {
            if ((psa.AttributeType__c == 'Photo' || psa.AttributeType__c == 'File') && psa.AttributeValue__c != null && psa.AttributeValue__c != '') {
                psa.IsClonedAttachment__c = true;

            }
        }

        insert psts;
        insert psqs;
        insert pscs;
        insert psas;
        insert psms;
        insert pses;
        insert pasa;

        UpdateProjectAccountAccess(ClonedProjID);


        Map<String, String> mappsqs = new Map<String, String>();
        for (ProjectServiceQuestion__c psq : psqs) {
            mappsqs.put(genProjectServiceQuestionKey(newOldMap.get(psq.ProjectService__c), psq.Question__c), String.valueOf(psq.Id));
        }

        InsertProjectServiceQuestionDefinedResponsesAsIs(psqs, mappsqs, OrigProjID);
        InsertProjectServiceQuestionRulessAsIs(psqs, mappsqs, OrigProjID);
        UpdateParentProjectServiceQuestionIds(psqs, mappsqs);

        return true;
    }

    static string genProjectServiceQuestionKey(Id projectServiceId, Id questionId) {
        return String.valueOf(projectServiceId) + ':' + String.valueOf(questionId);
    }

    private static void UpdateParentProjectServiceQuestionIds(List<ProjectServiceQuestion__c> psqs, Map<String, String> mappsqs) {

        List<ProjectServiceQuestion__c> psqscs = [SELECT Id, ProjectService__c, Question__c, ParentProjectServiceQuestion__c,
                                        ParentProjectServiceQuestion__r.ProjectService__c, ParentProjectServiceQuestion__r.Question__c
                                        FROM ProjectServiceQuestion__c WHERE Id in :psqs AND ParentProjectServiceQuestion__c != null];
        for (ProjectServiceQuestion__c psqc : psqscs) {
            string key =  genProjectServiceQuestionKey(
                              psqc.ParentProjectServiceQuestion__r.ProjectService__c,
                              psqc.ParentProjectServiceQuestion__r.Question__c);
            psqc.ParentProjectServiceQuestion__c = mappsqs.get(key);
        }

        update psqscs;
    }

    private static void UpdateProjectAccountAccess (Id ClonedProjID) {

        List<ProjectAccountServiceAccess__c> lstpAS = [SELECT Id, ProjectAccount__c, ProjectService__c,  Project__c,  Account__c,
                                             ProjectAccount__r.Account__c FROM ProjectAccountServiceAccess__c
                                             where Project__c = : ClonedProjID];

        set<Id> accountIds = new set<Id>();

        for (ProjectAccountServiceAccess__c pas : lstpAS) {

            accountIds.add(pas.Account__c);
            // pas.Project__c = ClonedProjID;

        }
        system.debug('accountIds::' + accountIds);

        List<ProjectAccount__c> lstpA = [select Id, name, Account__c, Project__c  from ProjectAccount__c where Project__c = : ClonedProjID
                                         and Account__c in: accountIds];
        system.debug('lstpA::' + lstpA);

        if (lstpA.size() > 0) {


            map<String, String> mapProjectAcc = new map<String, String>();
            for (ProjectAccount__c pa : lstpA) {

                mapProjectAcc.put(pa.Project__c + '~' + pa.Account__c, pa.Id);
            }


            for (ProjectAccountServiceAccess__c pas : lstpAS) {


                pas.ProjectAccount__c = mapProjectAcc.get(pas.Project__c + '~' + pas.ProjectAccount__r.Account__c);
            }

        }

        update lstpAS;


    }
    private static List<SObject> AddProjectServiceRecords(Map<Id, Id> oldNewMap, string objectType) {

        //items
        String listType = 'List<' + CONSTANTS.CURRENTNAMESPACEPREFIX + objectType + '>';
        List<SObject> psrList = (List<SObject>)Type.forName(listType).newInstance();
        List<SObject> objList_psr = (List<SObject>)Type.forName(listType).newInstance();
        sObject psr;

        Set<Id> oldIdList = oldNewMap.keySet();
        string qry = ' Select ';
        string ObjectName = objectType;
        Result objReslt = FetchFieldInfo(ObjectName);
        qry = qry + objReslt.commaSepField + ' from ' +
              ObjectName +
              ' where ProjectService__c IN :oldIdList';

        objList_psr = Database.query(qry);
        SObjectType objType = Schema.getGlobalDescribe().get(CONSTANTS.CURRENTNAMESPACEPREFIX + objectType);

        Id oldId;
        string projectServiceField = CONSTANTS.CURRENTNAMESPACEPREFIX + 'ProjectService__c';

        for (SObject obj : objList_psr) {
            psr = objType.newSObject();
            for (keyPair field : objReslt.keyPairVal) {
                if (string.valueof(field.key).contains('__c')) {
                    psr.put(field.key, ((sobject)obj).get(field.key));
                }
            }
            oldId = Id.valueOf(String.valueOf(psr.get(projectServiceField)));
            psr.put(projectServiceField, oldNewMap.get(oldId));
            psrList.add(psr);
        }
        return psrList;

    }

    private static void InsertProjectServiceQuestionDefinedResponsesAsIs(List<ProjectServiceQuestion__c> psqs, Map<String, String> mappsqs, string originalProjectId) {

        List<ProjectServiceQuestionDefinedResponse__c> psqdrs = new List<ProjectServiceQuestionDefinedResponse__c>();
        ProjectServiceQuestionDefinedResponse__c psqdr;

        Set<Id> oldpsqids = new Set<Id>();

        List<ProjectServiceQuestion__c> oldpsqs = [Select Id, name from ProjectServiceQuestion__c WHERE ProjectService__r.Project__c = :originalProjectId];


        for (ProjectServiceQuestion__c oldpsq : oldpsqs) {
            oldpsqids.add(oldpsq.Id);

        }

        string customfields = ', ProjectServiceQuestion__r.ProjectService__c, ProjectServiceQuestion__r.Question__c ';
        string qry = ' Select ';


        string ObjectName = 'ProjectServiceQuestionDefinedResponse__c';
        Result objReslt = FetchFieldInfo(ObjectName);
        qry = qry + objReslt.commaSepField + customfields + ' from ' + ObjectName + ' where ProjectServiceQuestion__c IN :oldpsqids Order by ProjectServiceQuestion__c, Active__c DESC';

        List<ProjectServiceQuestionDefinedResponse__c> objList_psqdr = Database.query(qry);

        for (ProjectServiceQuestionDefinedResponse__c obj : objList_psqdr) {
            psqdr = new ProjectServiceQuestionDefinedResponse__c();
            for (keyPair field : objReslt.keyPairVal) {
                if (string.valueof(field.key).contains('__c') && !string.valueof(field.key).contains('__r')) {
                    psqdr.put(field.key, ((sobject)obj).get(field.key));
                }
            }
            string key = genProjectServiceQuestionKey(
                             obj.ProjectServiceQuestion__r.ProjectService__c,
                             obj.ProjectServiceQuestion__r.Question__c);

            psqdr.ProjectServiceQuestion__c = mappsqs.get(key);

            psqdrs.add(psqdr);
        }

        insert psqdrs;
    }

    static Set<Id> filterProjectServiceForValidation(List<ProjectServiceQuestionDefinedResponse__c> responses) {
        Set<Id> idSet = new Set<Id>();
        Set<Id> result = new Set<Id>();

        for (ProjectServiceQuestionDefinedResponse__c d : responses) {
            idSet.add(d.ProjectServiceQuestion__c);
        }

        List<ProjectServiceQuestion__c> rs = [SELECT Id FROM ProjectServiceQuestion__c
                                              WHERE Id in :idSet AND QuestionType__c in ('Multi-Select List', 'Single-Select List')];
        for (ProjectServiceQuestion__c q : rs) {
            result.add(q.Id);
        }

        return result;
    }


    private static void InsertProjectServiceQuestionRulessAsIs(List<ProjectServiceQuestion__c> psqs, Map<String, String> mappsqs, string originalProjectId) {

        List<ProjectServiceQuestionRule__c> psqrs = new List<ProjectServiceQuestionRule__c>();
        ProjectServiceQuestionRule__c psqr;

        Set<Id> oldpsqids = new Set<Id>();

        List<ProjectServiceQuestion__c> oldpsqs = [Select Id, name from ProjectServiceQuestion__c WHERE ProjectService__r.Project__c = :originalProjectId];


        for (ProjectServiceQuestion__c oldpsq : oldpsqs) {
            oldpsqids.add(oldpsq.Id);

        }
        string customfields = ', ProjectServiceQuestion__r.ProjectService__c, ProjectServiceQuestion__r.Question__c, ParentProjectServiceQuestion__r.ProjectService__c, ParentProjectServiceQuestion__r.Question__c ';
        string qry = ' Select ';


        string ObjectName = 'ProjectServiceQuestionRule__c';
        Result objReslt = FetchFieldInfo(ObjectName);
        qry = qry + objReslt.commaSepField + customfields + ' from ' + ObjectName + ' where ProjectServiceQuestion__c IN :oldpsqids';
        List<ProjectServiceQuestionRule__c> objList_psqr = Database.query(qry);

        for (ProjectServiceQuestionRule__c obj : objList_psqr) {
            psqr = new ProjectServiceQuestionRule__c();
            for (keyPair field : objReslt.keyPairVal) {
                if (string.valueof(field.key).contains('__c') && !string.valueof(field.key).contains('__r')) {
                    psqr.put(field.key, ((sobject)obj).get(field.key));
                }
            }
            string key = genProjectServiceQuestionKey(
                             obj.ProjectServiceQuestion__r.ProjectService__c,
                             obj.ProjectServiceQuestion__r.Question__c);
            string parentkey = genProjectServiceQuestionKey(
                                   obj.ParentProjectServiceQuestion__r.ProjectService__c,
                                   obj.ParentProjectServiceQuestion__r.Question__c);

            psqr.ProjectServiceQuestion__c = mappsqs.get(key);
            psqr.ParentProjectServiceQuestion__c = mappsqs.get(parentkey);
            psqrs.add(psqr);
        }
        insert psqrs;

    }


    public static boolean CloneProjectLocations(String OrigProjID, string ClonedProjID) {

        Map<Id, Id> locationIds = new Map<Id, Id>();
        //project location
        String ObjectName = 'projectlocation__c';
        Result objReslt = FetchFieldInfo(ObjectName);
        String qry = ' Select ' + objReslt.commaSepField + ' from ' + ObjectName + ' where project__c =\'' + OrigProjID + '\'  AND Location__r.IsActive__c = true';
        system.debug('!!! proj loc qry !!! ' + qry);

        projectlocation__c ClonedPLoc = new projectlocation__c();
        list<projectlocation__c> ClonedPLocList = new list<projectlocation__c>();

        list<projectlocation__c> rtnList =  Database.query(qry);

        if (rtnList.size() > 0) {
            for (projectlocation__c objPL : Database.query(qry)) {
                ClonedPLoc = new projectlocation__c();
                for (keyPair field : objReslt.keyPairVal) {
                    if (string.valueof(field.key).contains('__c')) {
                        ClonedPLoc.put(field.key, ((sobject)objPL).get(field.key));
                    }
                }
                ClonedPLoc.project__c = ClonedProjID;
                ClonedPLoc.status__c = '';
                ClonedPLoc.IsDeleted__c = false;
                ClonedPLoc.CancelReason__c = '';
                ClonedPLoc.StatusComments__c = '';
                ClonedPLoc.LocationScheduledDate__c = null;
                ClonedPLoc.Executed__c = false;
                ClonedPLoc.SurveyPhotoViewerEncodedId__c = '';

                //Check if the location has already been added
                //It is possible that project lcoations can be duplicated
                //with same location when they have been canceled and readded.

                if (locationIds.ContainsKey(ClonedPLoc.Location__c))
                    continue;

                locationIds.put(ClonedPLoc.Location__c, ClonedPLoc.Location__c);
                ClonedPLocList.add(ClonedPLoc);
            }
            insert ClonedPLocList;
        }
        return true;
    }

    private static Result FetchFieldInfo(string selectedObject) {
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        keyPair field = new keyPair();
        List<keyPair> lstfieldname = new List<keyPair>();
        string commaStr = '';

        Map <String, Schema.SObjectField> fieldMap = schemaMap.get(CONSTANTS.CURRENTNAMESPACEPREFIX + selectedObject).getDescribe().fields.getMap();
        for (Schema.SObjectField sfield : fieldMap.Values()) {
            schema.describefieldresult dfield = sfield.getDescribe();
            //if(!dfield.isCalculated() && dfield.isUpdateable() && !string.valueof(dfield.getname()).toLowerCase().contains('uniquekey__c') )
            if (!dfield.isCalculated() && !dfield.isAutoNumber() && !string.valueof(dfield.getname()).toLowerCase().contains('uniquekey__c') && !string.valueof(dfield.getname()).toLowerCase().contains('axisid__c')    ) {
                //system.debug('#######' + dfield );
                field = new keyPair();
                field.key = dfield.getname();
                field.val = dfield.getType () + ' : ' + dfield.getLabel();
                lstfieldname.add(field);
                commaStr += field.key + ',';

            }
        }

        Result rslt = new Result();
        rslt.commaSepField = commaStr.removeend(',');
        rslt.keyPairVal = lstfieldname;
        return rslt;
    }

    public class keyPair {
        public String key {get; set;}
        public String val {get; set;}
    }

    public class Result {
        public String commaSepField {get; set;}
        public list<keyPair> keyPairVal {get; set;}
    }



}