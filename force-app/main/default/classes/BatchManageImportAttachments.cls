global class BatchManageImportAttachments implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts, Database.RaisesPlatformEvents {

    public enum SendEmailStatus {EMAIL_INITIAL, EMAIL_NO_RECIPIENT, EMAIL_SENT, EMAIL_FAILED}
    IEmailNotifier emailNotifier;
    List<String> errors = new List<String>();
    String attachmentType;
    String[] IMPORT_ATTACHMENT_PATTERN;
    ApexJobTracker apexTracker;
    String parentId;

    List<ActionResponse> errorresponses = new List<ActionResponse>();

    private Boolean hasError {
        get {
            return !errorresponses.isEmpty() || !errors.isEmpty();
        }
    }

    void initApexTracker(String parentId,
                         ApexJobTracker.TrackerTarget target,
                         ApexJobTracker.TrackerOperation operation) {
        apexTracker = ApexJobTracker.create(parentId, target, operation);
        apexTracker.save();
    }

    global BatchManageImportAttachments(Id parentId, String attachmentType) {
        this.init(parentId, attachmentType, new EmailNotifier());
    }

    global BatchManageImportAttachments(Id parentId, String attachmentType, IEmailNotifier notifier) {
        this.init(parentId, attachmentType, notifier);
    }

    private void init(Id parentId, String attachmentType, IEmailNotifier notifier) {
        this.parentId = parentId;
        this.attachmentType =  attachmentType;
        this.emailNotifier = notifier;

        if (attachmentType.toLowerCase() == 'jobs') {
            initApexTracker(parentId,
                            ApexJobTracker.TrackerTarget.Job,
                            ApexJobTracker.TrackerOperation.Import_Jobs);
            IMPORT_ATTACHMENT_PATTERN = new String[] {'%' + 'import_jobs' + '%'};
        } else if (attachmentType.toLowerCase() == 'locations') {
            initApexTracker(parentId,
                            ApexJobTracker.TrackerTarget.ProjectLocation,
                            ApexJobTracker.TrackerOperation.Import_ProjectLocations);
            IMPORT_ATTACHMENT_PATTERN = new String[] {'%' + 'import_locations' + '%'};
        } else if (attachmentType.toLowerCase() == 'thirdparty') {
            initApexTracker(parentId,
                            ApexJobTracker.TrackerTarget.JobAttemptWorker,
                            ApexJobTracker.TrackerOperation.Import_JobAttemptWorkers);
            IMPORT_ATTACHMENT_PATTERN = new String[] {'%' + 'import_jobattemptworker' + '%'};
        } else {
            throw new CustomException('The attachmentType is invalid. The supported types are jobs, locations, thirdparty');
        }
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        if (apexTracker.Status != ApexJobTracker.TrackerStatus.In_Progress) {
            apexTracker.setStatus(ApexJobTracker.TrackerStatus.In_Progress)
            .save();
        }
        String pId = this.parentId;
        String[] namePattern = this.IMPORT_ATTACHMENT_PATTERN;

        return Database.getQueryLocator([
                SELECT Id, 
                ParentId, 
                Name, 
                IsPrivate, 
                ContentType, 
                BodyLength,
                Body, 
                Description, 
                IsDeleted
                FROM Attachment 
                where ParentId = :parentId 
                AND Name like :namePattern]);
    }

    global void execute(Database.BatchableContext BC, List<Attachment> scope) {
        List<String> data;
        List<ActionResponse> batcherrorresponses;

        try {
            Attachment attachment = ((List<Attachment>)scope)[0];
            if (attachment != null && attachment.BodyLength > 0) {
                data = (List<String>) JSON.deserialize(attachment.Body.toString(), List<String>.class);
                if (attachmentType.toLowerCase() == 'jobs') {
                    batcherrorresponses = JobActionsHelper.updateBulkJobsFromFile(data, String.valueOf(parentId));
                } else if (attachmentType.toLowerCase() == 'locations') {
                    batcherrorresponses = ProjectLocationActionsHelper.updateBulkLocationsFromFile(data, String.valueOf(parentId));
                } else if (attachmentType.toLowerCase() == 'thirdparty') {
                    batcherrorresponses = JobAttemptWorkerActionsHelper.update3plWorkersFromFile(data);

                } else {
                    throw new CustomException('The attachment name:' + attachmentType + ' is not supported.');
                }

                if (batcherrorresponses != null && !batcherrorresponses.isEmpty())
                    this.errorresponses.addAll(batcherrorresponses);
            }
        } catch (Exception ex) {
            this.errorresponses.add(ActionResponse.newInstance(parentId, false, ex.getMessage()));
            this.errors.add(ex.getStackTraceString());
            throw ex;
        }
    }

    Project__c unlockProject() {
        Project__c project = [Select Id, Name, ProjectNumber__c, ApexJobName__c, BatchProcessId__c, RecordTypeId,
                              PendingBulkImport__c
                              from Project__c WHERE Id = : this.parentId];
        TriggerUtil.SkipAllTriggers();
        ProjectActionsHelper.UnlockProject(project);
        project.PendingBulkImport__c = '';
        update project;

        return project;
    }

    global void finish(Database.BatchableContext BC) {
        String messageBody;
        String messageSubject;
        SendEmailStatus emailStatus = SendEmailStatus.EMAIL_INITIAL;
        Boolean isDBTxnSucceeded = false;

        Savepoint sp = Database.setSavepoint();
        try {

            AsyncApexJob a = [SELECT Id, Status, ExtendedStatus, NumberOfErrors, JobItemsProcessed, TotalJobItems,
                              CreatedBy.Email FROM AsyncApexJob WHERE Id = :BC.getJobId()];

            if (attachmentType.toLowerCase() == 'thirdparty') {
                TriggerUtil.SkipAllTriggers();
                JobAttemptWorkerActionsHelper.unlockAccount(this.parentId);
                string link = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + this.parentId;

                messageSubject = 'Import Request Status: ' + attachmentType ;
                messageBody = 'Your request to process ' + attachmentType + ' has completed.<br>';

            } else {
                Project__c project = unlockProject();
                string link = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + project.Id;

                messageSubject = 'Import Request Status: ' + attachmentType + ' - ' + project.Name;
                if (a.NumberOfErrors > 0 || this.hasError) {
                    messageBody = 'Your request to process ' + attachmentType + ' has one or more failures. Please see below for the list of failures. <br>Project Id: ' + project.ProjectNumber__c + '<br>Project Title: ' + project.Name;

                } else {
                    messageBody = 'Your request to process ' + attachmentType + ' has completed successfully.<br>Project Id: ' + project.ProjectNumber__c + '<br>Project Title: ' + project.Name;
                    messageBody = messageBody + '<br><br><a href=' + link + '>Click here to directly access the project.</a>';
                }
            }


            if (a.NumberOfErrors > 0 || this.hasError) {
                messageBody += '<br>Error Detail: <br>';

                for (ActionResponse response : this.errorresponses) {
                    messageBody += '<br>' + response.ResponseMessage;
                }

                if (!this.errors.isEmpty()){
                    messageBody += '<br>' + arrayToString(this.errors);
                }

                if (String.isNotBlank(a.ExtendedStatus)){
                    messageBody += '<br>' + a.ExtendedStatus;
                }
            }



            //clean up attachment
            removeImportAttachments();
            isDBTxnSucceeded = true;

            // send email
            emailStatus = notifyUserByEmail(messageSubject, messageBody);
        } catch (Exception e) {
            this.errors.add(e.getStackTraceString());
            isDBTxnSucceeded = false;
            Database.rollback(sp);
        }

        updateApexTracker(isDBTxnSucceeded, messageBody, emailStatus == SendEmailStatus.EMAIL_SENT);
    }

    private String arrayToString(List<String> items) {
        return (items == null || items.isEmpty())
               ? ''
               : String.join(items, '. ');
    }

    private void updateApexTracker(Boolean dbTxnSucceeded, String message, Boolean emailNotified) {
        ApexJobTracker tracker = ApexJobTracker.getById(apexTracker.TrackerId);
        tracker.setResponse(message)
        .setStatus(dbTxnSucceeded ? ApexJobTracker.TrackerStatus.Success : ApexJobTracker.TrackerStatus.Failure)
        .setNotified(emailNotified);
        tracker.end();
    }

    private void removeImportAttachments() {
        String pId = this.parentId;
        delete [SELECT Id FROM Attachment
                where ParentId = :pId AND
                                 Name like :IMPORT_ATTACHMENT_PATTERN];
    }

    private SendEmailStatus notifyUserByEmail(string messageSubject, String messageBody) {
        String userEmail = UserInfo.getUserEmail();
        if (String.isBlank(userEmail)) {
            this.errors.add('User Email is not specified.');
            return SendEmailStatus.EMAIL_NO_RECIPIENT;
        }

        emailNotifier.setRecipient(userEmail)
        .setSubject(messageSubject)
        .setBody(messageBody);

        if (emailNotifier.sendAsHtml()) {
            return SendEmailStatus.EMAIL_SENT;
        }

        this.errors.add(emailNotifier.getErrorString());
        return SendEmailStatus.EMAIL_FAILED;
    }
}