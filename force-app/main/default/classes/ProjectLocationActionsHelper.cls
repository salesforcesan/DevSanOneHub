global class ProjectLocationActionsHelper {


    global static List<ActionResponse> DeleteProjectLocations(Id[] plIds) {
        List<ActionResponse> responses = new  List<ActionResponse>();
        Boolean isBatched = false;
        //Decide between batch and non batch
        Id pId = [Select Id, Project__c from ProjectLocation__c where Id = :plIds[0]].Project__c;
        //Implementation
        Boolean success = true;
        Savepoint sp = Database.setSavepoint();
        try {
            string stringIds = '';
            Integer jobCount = [Select count() from Job__c WHERE ProjectLocation__c in :plIds LIMIT :JobActionsHelper.JOB_BATCH_DELETE_DECISION_COUNT];
            if (jobCount == JobActionsHelper.JOB_BATCH_DELETE_DECISION_COUNT ||
                    (jobCount + plIds.size() >= JobActionsHelper.JOB_BATCH_DELETE_DECISION_COUNT)) {
                //Call the Apex Job Tracker and Batch
                isBatched = true;
                ApexJobTracker__c ajt = new   ApexJobTracker__c();
                ajt.Object__c = 'ProjectLocation';
                ajt.Operation__c = 'Delete ProjectLocation';
                ajt.Project__c = pId;
                ajt.Status__c = 'New';
                for (Integer i = 0; (i < 6800) && (i < plIds.size()); i++) {
                    stringIds += String.valueOf(plIds[i]) + ',';
                }
                ajt.Id1__c = stringIds;

                if (plIds.size() > 6800) {
                    stringIds = '';
                    for (Integer i = 6800; (i < 2 * 6800) && (i < plIds.size()); i++) {
                        stringIds += String.valueOf(plIds[i]) + ',';
                    }
                    ajt.Id2__c = stringIds;
                }

                insert ajt;

                BatchProcessApexJobs batch = new BatchProcessApexJobs(plIds, ajt);
                Id batchId = Database.ExecuteBatch(batch, JobActionsHelper.JOB_BATCH_DELETE_DECISION_COUNT);

                Project__c project =  [SELECT Id, ApexJobName__c, BatchProcessId__c, RecordTypeId
                                       FROM Project__c WHERE Id = :pId];
                ProjectActionsHelper.LockProject(project, 'Delete Project Locations', batchId);
                update project;

            } else {
                //Call the non batch
                Id[] jobIds = new Id[] {};
                List<Job__c> jobs = [Select Id from Job__c where ProjectLocation__c in :plIds];
                for (Job__c job : jobs) {
                    jobIds.add(job.Id);
                }
                JobActionsHelper.deleteJobs(jobIds);
                DeleteProjectLocationSansJobs(plIds);
            }
        } catch (Exception e) {
            Database.rollback(sp);
            success = false;
            system.debug('DELETE LOCATIONS ERROR:' + e.getMessage());
            //For test purposes
            throw e;
        }
        if (success) {
            ActionResponse response = new ActionResponse(null, true, 'Successfully deleted project locations.');
            response.IsBatched = isBatched;
            responses.add(response);
        } else {
            ActionResponse response = new ActionResponse(null, false, 'Error deleting project locations.');
            responses.add(response);
        }

        return responses;
    }

    global static List<ActionResponse> DeleteProjectLocationSansJobs(Id[] plIds) {

        List<ActionResponse> responses = new  List<ActionResponse>();

        //Implementation
        Boolean success = true;
        Savepoint sp = Database.setSavepoint();
        try {
            TriggerUtil.SkipAllTriggers();
            delete [Select Id from ProjectLocation__c WHERE Id in :plIds];
        } catch (Exception e) {
            Database.rollback(sp);
            success = false;
            //For test purposes
            throw e;
        }

        if (success) {
            ActionResponse response = new ActionResponse(null, true, 'Successfully deleted project locations.');
            responses.add(response);
        } else {
            ActionResponse response = new ActionResponse(null, true, 'Error deleting project locations.');
            responses.add(response);
        }

        return responses;
    }


    global static List<ActionResponse> CancelProjectLocation(Id[] plIds, string cancelReason, string cancelComments) {

        List<ActionResponse> responses = new  List<ActionResponse>();
        Boolean isBatched = false;
        //Decide between batch and non batch

        Id pId = [Select Id, Project__c from ProjectLocation__c where Id = :plIds[0]].Project__c;

        //Implementation
        Boolean success = true;
        Savepoint sp = Database.setSavepoint();
        try {
            string stringIds = '';
            Integer jobCount = [Select count() from Job__c WHERE Project__c = :pId and projectlocation__c in :plIds LIMIT :JobActionsHelper.JOB_BATCH_CANCEL_DECISION_COUNT];
            if (jobCount == JobActionsHelper.JOB_BATCH_CANCEL_DECISION_COUNT) {
                //Call the Apex Job Tracker and Batch
                isBatched = true;
                ApexJobTracker__c ajt = new   ApexJobTracker__c();
                ajt.Object__c = 'ProjectLocation';
                ajt.Operation__c = 'Cancel ProjectLocation';
                ajt.Project__c = pId;
                ajt.Status__c = 'New';

                for (Integer i = 0; (i < 6800) && (i < plIds.size()); i++) {
                    stringIds += String.valueOf(plIds[i]) + ',';
                }
                ajt.Id1__c = stringIds;

                if (plIds.size() > 6800) {
                    stringIds = '';
                    for (Integer i = 6800; (i < 2 * 6800) && (i < plIds.size()); i++) {
                        stringIds += String.valueOf(plIds[i]) + ',';
                    }
                    ajt.Id2__c = stringIds;
                }

                insert ajt;

                BatchProcessApexJobs batch = new BatchProcessApexJobs(plIds, ajt);
                Id batchId = Database.ExecuteBatch(batch, JobActionsHelper.JOB_BATCH_CANCEL_DECISION_COUNT);

                Project__c project =  [SELECT Id, ApexJobName__c, BatchProcessId__c, RecordTypeId
                                       FROM Project__c WHERE Id = :pId];
                ProjectActionsHelper.LockProject(project, 'Cancel Project Locations', batchId);
                update project;

            } else {
                //Call the non batch
                Id[] jobIds = new Id[] {};
                List<Job__c> jobs = [Select Id from Job__c where projectlocation__c in :plIds];  //cancel only selected project location

                for (Job__c job : jobs) {
                    jobIds.add(job.Id);
                }
                JobActionsHelper.cancelJobs(jobIds, cancelreason, cancelComments);
                CancelProjectLocationSansJobs(plIds, cancelReason, cancelComments);
            }
        } catch (Exception e) {
            Database.rollback(sp);
            success = false;
            //For test purposes
            throw e;
        }

        if (success) {
            ActionResponse response = new ActionResponse(null, true, 'Successfully canceled project location.');
            response.IsBatched = isBatched;
            responses.add(response);
        } else {
            ActionResponse response = new ActionResponse(null, false, 'Failed to cancel the project locations.');
            responses.add(response);
        }

        return responses;
    }

    global static List<ActionResponse> CancelProjectLocationSansJobs(Id[] plIds, string cancelReason, string cancelComments) {
        List<ActionResponse> responses = new  List<ActionResponse>();
        Id[] projectIds = new Id[] {};
        Boolean success = true;
        Savepoint sp = Database.setSavepoint();
        try {
            TriggerUtil.SkipAllTriggers();
            List<ProjectLocation__c> projectLocations = [select id, status__c, CancelReason__c, StatusComments__c from projectlocation__c where Id in :plIds ];
            for (projectlocation__c pl : projectLocations) {
                pl.Status__c = CONSTANTS.PROJECT_STATUS_CANCELED;
                pl.CancelReason__c = cancelReason;
                pl.StatusComments__c = cancelComments;
            }
            update projectLocations;

        } catch (Exception e) {
            Database.rollback(sp);
            success = false;
            //For test purposes
            throw e;
        }

        if (success) {
            ActionResponse response = new ActionResponse(null, true, 'Successfully canceled project location.');
            responses.add(response);
        } else {
            ActionResponse response = new ActionResponse(null, false, 'Error canceling project location.');
            responses.add(response);
        }
        return responses;
    }


    global static List<ActionResponse> setScheduleDates(Id[] plIds, Date scheduledDate) {

        TriggerUtil.SkipAllTriggers();
        List<ActionResponse> responses = new  List<ActionResponse>();
        Boolean success = true;
        Boolean isBatched = false;
        try {
            system.debug('plIds::::::::' + plIds);

            List<ProjectLocation__c> projectLocations = [SELECT Id, Name, LocationScheduledDate__c FROM ProjectLocation__c WHERE id = :plIds];
            if (projectLocations.isEmpty()) {
                ActionResponse ar = new ActionResponse(null, false, 'No locations in the list to set scheduled date.');
                responses.add(ar);
                return responses;
            }

            for (ProjectLocation__c pl : projectLocations) {
                pl.LocationScheduledDate__c = scheduledDate;
            }

            Database.SaveResult[] results = Database.update(projectLocations, false);


            for (Integer i = 0; i < projectLocations.size(); i++) {
                Database.SaveResult result = results[i];

                if (!result.isSuccess()) {
                    for (Database.Error err : result.getErrors()) {
                        String locationName = projectLocations[i].Name;
                        ActionResponse response = new ActionResponse(null, false, locationName + ': ' + err.getMessage() );
                        responses.add(response);
                    }
                }
            }


            List<Job__c> jobs = [SELECT Id, Project__c, JobStartDate__c, JobEndDate__c, JobScheduledDate__c, ProjectService__r.NumberOfDays__c, ProjectService__r.StartDayNumber__c, ProjectScheduleOptionName__c FROM Job__c
                                 WHERE ProjectLocation__c IN :plIds AND ProjectLocation__r.Status__c != :CONSTANTS.PROJECT_LOCATION_CANCELED LIMIT :JobActionsHelper.JOB_BATCH_SCHEDULEDATE_DECISION_COUNT];

            Integer jobCount = jobs.size();

            if (jobCount == JobActionsHelper.JOB_BATCH_SCHEDULEDATE_DECISION_COUNT) {
                //Call the Apex Job Tracker and Batch
                string stringIds = '';
                isBatched = true;
                ApexJobTracker__c ajt = new   ApexJobTracker__c();
                ajt.Object__c = 'ProjectLocation';
                ajt.Operation__c = 'Schedule ProjectLocation';
                ajt.Project__c = jobs[0].Project__c;
                ajt.Status__c = 'New';
                ajt.Parameters__c = scheduledDate.format();
                Integer idLimit = 6800;
                for (Integer i = 0; (i < idLimit) && (i < plIds.size()); i++) {
                    stringIds += String.valueOf(plIds[i]) + ',';
                }
                ajt.Id1__c = stringIds;

                if (plIds.size() > idLimit) {
                    stringIds = '';
                    for (Integer i = idLimit; (i < 2 * idLimit) && (i < plIds.size()); i++) {
                        stringIds += String.valueOf(plIds[i]) + ',';
                    }
                    ajt.Id2__c = stringIds;
                }

                insert ajt;

                BatchProcessApexJobs batch = new BatchProcessApexJobs(plIds, ajt);
                Id batchId = Database.ExecuteBatch(batch, JobActionsHelper.JOB_BATCH_SCHEDULEDATE_DECISION_COUNT);

                Project__c project =  [SELECT Id, ApexJobName__c, BatchProcessId__c, RecordTypeId
                                       FROM Project__c WHERE Id = :jobs[0].Project__c];
                ProjectActionsHelper.LockProject(project, 'Set Schedule Date', batchId);
                update project;
            } else {
                if (jobCount > 0) {
                    Id[] jobIds = new Id[] {};
                    for (Job__c job : jobs) {
                        jobIds.add(job.Id);
                    }
                    JobActionsHelper.setScheduledDate(jobIds, scheduledDate);
                }
            }
        } catch (Exception e) {
            success = false;
        }

        if (success) {
            ActionResponse response = new ActionResponse(null, true, 'Success');
            response.IsBatched = isBatched;
            responses.add(response);
        } else {
            ActionResponse response = new ActionResponse(null, false, 'Error');
            responses.add(response);
        }
        return responses;
    }



    //This method is for non batch purposes only
    global static List<ActionResponse> ReattemptProjectLocations(Id[] plIds) {

        Boolean success = true;
        List<ActionResponse> responses = new  List<ActionResponse>();

        try {
            List<Job__c> jobs = [Select Id, CreateAttempt__c,IsAttemptable__c  from Job__c where ProjectLocation__c in :plIds FOR UPDATE];
            for (Job__c job : jobs) {
                job.CreateAttempt__c = true;
                job.IsAttemptable__c = true;
            }

            update jobs;
        }

        catch (Exception e) {
            success = false;
            system.debug('CREATE ATTEMPTS ERROR:' + e.getMessage());
            //For test purposes
            throw e;
        }
        if (success) {
            ActionResponse response = new ActionResponse(null, true, 'Reattempts have been successfully scheduled.');
            response.IsBatched = true;
            responses.add(response);
        } else {
            ActionResponse response = new ActionResponse(null, false, 'Error scheduling Reattempts.');
            responses.add(response);
        }

        return responses;
    }


    global static List<ActionResponse> updateBulkLocationsFromFile(List<String> locationscsv, String projectId) {

        List<ProjectLocation__c> locationsToUpdate = new List<ProjectLocation__c>();
        String fieldstoupdate = '';
        Set<String> locationIds = new Set<String>();
        Set<String> plocationIds = new Set<String>();
        Map<String, ProjectLocation__c> locationsMap = new Map<String, ProjectLocation__c>();
        Map<String, String> locationsNamebyIdMap = new Map<String, String>();
        Map<Integer, String> locationupdatemapbyindex = new Map<Integer, String>();
        Map<String, Integer> locationupdatemapbyfield = new Map<String, Integer>();
        Map<String, Date> locationschDateMap = new Map<String, Date>();
        String nsprefix = Constants.CURRENTNAMESPACEPREFIX.toLowerCase();
        List<ActionResponse> responses = new  List<ActionResponse>();
        if (locationscsv.size() == 0) {
            ActionResponse response = new ActionResponse(null, false, 'No locations in the list to update. Contact Administrator.');
            responses.add(response);
            return responses;
        }

        // 'Name-0,LocationScheduledDate__c-11'
        String locationupdatefields = AppUtil.LocationImportFields == null ? '' : AppUtil.LocationImportFields.toLowerCase();
        if (String.isBlank(locationupdatefields)) {
            ActionResponse response = new ActionResponse(null, false, 'Missing value for custom setting LocationImportFields. Contact Administrator.');
            responses.add(response);
            return responses;
        }


        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType locationSchema = schemaMap.get(nsprefix + 'projectlocation__c');
        Map<String, Schema.SObjectField> fieldMap = locationSchema.getDescribe().fields.getMap();


        String[] locationupdatefieldsarray = locationupdatefields.split(',');
        for (String locationupdatefield : locationupdatefieldsarray) {

            locationupdatemapbyindex.put(Integer.ValueOf(locationupdatefield.split('-')[1]), locationupdatefield.split('-')[0].toLowerCase());
            locationupdatemapbyfield.put(locationupdatefield.split('-')[0].toLowerCase(), Integer.ValueOf(locationupdatefield.split('-')[1]));
            fieldstoupdate = fieldstoupdate + locationupdatefield.split('-')[0] + ',';

            //If override field, get the formula field also.
            //Example, EstimatedMinutesOverride__c will also include EstimatedMinutes__c
            if (locationupdatefield.containsIgnoreCase('override')) {
                string formulafield = locationupdatefield.replace('override', '');
                locationupdatefield = fieldstoupdate + formulafield + ',';
            }

        }

        if (!String.isBlank(fieldstoupdate))
            fieldstoupdate = fieldstoupdate + 'id, ' + nsprefix + 'project__c ' ;

        Integer indexofname = locationupdatemapbyfield.get('name');

        for (String locationcsv : locationscsv) {
            String[] locationcsvarray = locationcsv.split(',');

            locationIds.add(locationcsvarray[indexofname]);

        }

        String query = 'SELECT ' + fieldstoupdate + ' FROM projectLocation__c WHERE name in :locationIds AND project__c = :projectId';


        locationsToUpdate = Database.query(query);


        for (ProjectLocation__c location : locationsToUpdate) {
            locationsMap.put(location.Name, location);
            locationsNameByIdMap.put(location.Id, location.Name);
            plocationIds.add(location.Id);
        }

        for (String locationcsv : locationscsv) {
            String[] locationcsvarray = locationcsv.split(',');


            for (String fieldname : locationupdatemapbyfield.keySet()) {

                //Do not set the Name field as it is auto generated
                //Name is the here for the purposes of KeyJobScheduledDate__c
                if (fieldname.toLowerCase() == 'name' || fieldname.containsIgnoreCase('project__c'))
                    continue;

                //If the values in the override field and
                //the formula field are the same, so not update
                //the override field
                if (fieldname.containsIgnoreCase('override')) {
                    if (locationsMap.get(locationcsvarray[indexofname]).get(fieldname) ==
                            locationsMap.get(locationcsvarray[indexofname]).get(fieldname.replace('override', ''))) {
                        continue;
                    }
                }
                try {

                    Integer fieldindex = locationupdatemapbyfield.get(fieldname);

                    if (String.isBlank(locationcsvarray[fieldindex])) {
                        continue;
                    }

                    Schema.DisplayType fielddataType = fieldMap.get(fieldname).getDescribe().getType();
                    if (fielddataType == Schema.DisplayType.Date) {

                        locationsMap.get(locationcsvarray[indexofname]).put(fieldname, DateUtil.ToDate(locationcsvarray[fieldindex]));

                    }

                    else if (fielddataType == Schema.DisplayType.DateTime) {

                        locationsMap.get(locationcsvarray[indexofname]).put(fieldname, DateUtil.ToDateTime(locationcsvarray[fieldindex]));

                    }

                    else if (fielddataType == Schema.DisplayType.String) {

                        locationsMap.get(locationcsvarray[indexofname]).put(fieldname, locationcsvarray[fieldindex]);

                    } else if (fielddataType == Schema.DisplayType.Integer) {

                        locationsMap.get(locationcsvarray[indexofname]).put(fieldname, Integer.ValueOf(locationcsvarray[fieldindex]));

                    } else if (fielddataType == Schema.DisplayType.Currency) {
                        locationsMap.get(locationcsvarray[indexofname]).put(fieldname, Decimal.ValueOf(locationcsvarray[fieldindex]));

                    } else if (fielddataType == Schema.DisplayType.Double) {

                        locationsMap.get(locationcsvarray[indexofname]).put(fieldname, Double.ValueOf(locationcsvarray[fieldindex]));
                    }

                } catch (Exception err) { //Catch any data type issues
                    ActionResponse response;
                    try {
                        response = new ActionResponse(null, false, locationsMap.get(locationcsvarray[indexofname]).Name + ': ' +  fieldname + ': ' + err.getMessage() );
                    } catch (Exception err1) {
                        response = new ActionResponse(null, false, + fieldname + '-' + err1.getStackTraceString());
                    }
                    responses.add(response);
                }
            }
        }

        locationsToUpdate = handle3PLContactUpdate(
            locationsToUpdate, responses);
        Database.SaveResult[] results = Database.update(
            locationsToUpdate, false);
        
        for (Integer i = 0; i < locationsToUpdate.size(); i++) {
            Database.SaveResult result = results[i];
            String locationName = locationsToUpdate[i].Name;

            if (!result.isSuccess()) {
                for (Database.Error err : result.getErrors()) {
                    ActionResponse response = new ActionResponse(null, false, locationName + ': ' + err.getMessage() );
                    responses.add(response);
                }
            }
        }

        //Update Jobs with Sched Date
        if (!responses.isEmpty())
            return responses;
        else
            return null;

    }
    @testvisible
    static List<ProjectLocation__c> handle3PLContactUpdate(
        List<ProjectLocation__c> locationsToUpdate,
        List<ActionResponse> responses){
        
        List<String> oh3PLContactIds = get3PLContactIds(locationsToUpdate);
        if (oh3PLContactIds.isEmpty()) {return locationsToUpdate;}

        List<ProjectLocation__c> validatelocationsToUpdate = 
            new List<ProjectLocation__c>(); 
        Set<String> valid3PLContactIds = 
            findValid3PLContactId(oh3PLContactIds);
        
        for(ProjectLocation__c loc: locationsToUpdate){
            if (String.isNotBlank(loc.OneHubThirdPartyAgencyContactId__c)
                && !valid3PLContactIds.contains(
                loc.OneHubThirdPartyAgencyContactId__c)){
                responses.add(new ActionResponse
                    ( null, false, loc.Name  +  
                    ' 3PL Contact Id ' + 
                    loc.OneHubThirdPartyAgencyContactId__c + 
                    ' not valid'));
                continue;
            }
            validatelocationsToUpdate.add(loc);
        }
        return validatelocationsToUpdate;
    }

    @testvisible
    static Set<String> findValid3PLContactId(
        List<String> oh3PLIds){
        Set<String> validContactIds = new Set<String>();
        
        AggregateResult[] results = [
          select
              count(id) cnt,
              OneHubThirdPartyAgencyContactId__c cid
              from contact
              where OneHubThirdPartyAgencyContactId__c in :oh3PLIds
              group by OneHubThirdPartyAgencyContactId__c
        ];
        
        for(AggregateResult r: results){
            if (Integer.valueOf(r.get('cnt')) > 0){
                validContactIds.add(String.valueOf(r.get('cid')));
            }
        }

        return validContactIds;
    }

    @testvisible
    static List<String> get3PLContactIds(
        List<ProjectLocation__c> locations){
        List<String> oh3PLcontactIds = new List<String>();
        for(ProjectLocation__c loc: locations){
            if(String.isNotBlank(loc.OneHubThirdPartyAgencyContactId__c)){
                oh3PLcontactIds.add(loc.OneHubThirdPartyAgencyContactId__c);
            }
        }
        return oh3PLcontactIds;
    }

    global static void invokeLocationImportBatch(String projectId) {
        BatchManageImportAttachments batch = new BatchManageImportAttachments(projectId, 'locations');
        string batchProcessId = Database.ExecuteBatch(batch, 1);

    }

}