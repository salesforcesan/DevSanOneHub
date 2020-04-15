global without sharing class ApexJobTracker {
    static String AppNameSpace {get; set;}
    static {
        AppNameSpace = CONSTANTS.CURRENTNAMESPACE;
    }
    
    private ApexJobTracker__c record;
    public enum TrackerOperation {
        None,
            Delete_Project,
            Delete_ProjectService,
            Delete_ProjectLocation,
            Delete_Job,
            Cancel_Project,
            Cancel_ProjectService,
            Cancel_ProjectLocation,
            Import_ProjectLocations,
            Cancel_Job,
            Close_Project,
            Launch_Project,
            Create_Jobs,
            Import_Jobs,
            Import_JobAttemptWorkers,
            Create_Job_Materials,
            Schedule_ProjectLocation,
            Create_Attempt,
            Schedule_ProjectService,
            Delete_AllProjectJobs,
            Create_Labor_Invoice,
            Create_SalesTax_Invoice,
            Create_Product_Invoice,
            Apply_PB_Credit
            }
    public enum TrackerTarget {Project, ProjectService, ProjectLocation, Job, JobAttemptWorker, ProjectInvoice}
    public enum TrackerStatus {Initial, In_Progress, Success, Failure}
    
    public String TrackerId {get {return record.Id;}}
    public String ParentId {get {return record.ParentId__c;}}
    public Datetime StartTime {get {return record.StartDateTime__c;}}
    public Datetime EndTime {get {return record.EndDateTime__c;}}
    public String TargetId {get{return record.Object__c;}}
    public Double TryCount {get {return record.NumberofTries__c;}}
    public String BatchProcessId {get {return record.BatchProcessId__c;}}
    public String ClassName {get{return record.AppClassName__c;}}
    
    public String Id1 {get{return record.Id1__c;}}
    public String Id2 {get{return record.Id2__c;}}
    public String Id3 {get{return record.Id3__c;}}
    public String Parameters {get{return record.Parameters__c;}}
    public String ProjectId {get{return record.Project__c;}}
    public Boolean failureNotified {get {return record.IsFailureNotified__c;}}
    public String Response {get {return record.Response__c;}}
    
    public TrackerOperation Operation {
        get
        {
            switch on record.Operation__c {
                when 'Delete Project' {
                    return TrackerOperation.Delete_Project;
                }
                when 'Delete ProjectService' {
                    return TrackerOperation.Delete_ProjectService;
                }
                when 'Delete ProjectLocation' {
                    return TrackerOperation.Delete_ProjectLocation;
                }
                when 'Delete Job' {
                    return TrackerOperation.Delete_Job;
                }
                when 'Cancel Project' {
                    return TrackerOperation.Cancel_Project;
                }
                when 'Cancel ProjectService' {
                    return TrackerOperation.Cancel_ProjectService;
                }
                when 'Cancel ProjectLocation' {
                    return TrackerOperation.Cancel_ProjectLocation;
                }
                when 'Import ProjectLocations' {
                    return TrackerOperation.Import_ProjectLocations;
                }
                when 'Cancel Job' {
                    return TrackerOperation.Cancel_Job;
                }
                when 'Close Project' {
                    return TrackerOperation.Close_Project;
                }
                when 'Launch Project' {
                    return TrackerOperation.Launch_Project;
                }
                when 'Create Jobs' {
                    return TrackerOperation.Create_Jobs;
                }
                when 'Import Jobs' {
                    return TrackerOperation.Import_Jobs;
                }
                when 'Import JobAttemptWorkers' {
                    return TrackerOperation.Import_JobAttemptWorkers;
                }
                when 'Create Job Materials' {
                    return TrackerOperation.Create_Job_Materials;
                }
                when 'Schedule ProjectLocation' {
                    return TrackerOperation.Schedule_ProjectLocation;
                }
                when 'Create Attempt' {
                    return TrackerOperation.Create_Attempt;
                }
                when 'Schedule ProjectService' {
                    return TrackerOperation.Schedule_ProjectService;
                }
                when 'Delete AllProjectJobs' {
                    return TrackerOperation.Delete_AllProjectJobs;
                }
                when 'Create Labor Invoice' {
                    return TrackerOperation.Create_Labor_Invoice;
                }
                when 'Create SalesTax Invoice' {
                    return TrackerOperation.Create_SalesTax_Invoice;
                }
                when 'Create Product Invoice' {
                    return TrackerOperation.Create_Product_Invoice;
                }
                when 'Apply PB Credit' {
                    return TrackerOperation.Apply_PB_Credit;
                }
            }
            return TrackerOperation.None;
        }
    }
    
    
    public TrackerStatus Status {
        get{
            TrackerStatus value = TrackerStatus.Initial;
            switch on record.Status__c {
                when 'New' {
                    value = TrackerStatus.Initial;
                }
                when 'In Progress' {
                    value = TrackerStatus.In_Progress;
                }
                when 'Success' {
                    value = TrackerStatus.Success;
                }
                when 'Failure' {
                    value = TrackerStatus.Failure;
                }
            }
            return value;
        }
    }
    
    public Integer ElipsedTime {
        get {
            if (record.StartDateTime__c != null && record.EndDateTime__c != null) {
                return
                    record.EndDateTime__c.millisecond() - record.StartDateTime__c.millisecond();
            }
            return -1;
        }
    }
    
    private ApexJobTracker(ApexJobTracker__c record) {
        this.record = record;
    }
    
    public ApexJobTracker(String recordId) {
    }
    
    public ApexJobTracker(String trackerParentId, TrackerTarget enumTarget, TrackerOperation enumOperation) {
    }
    
    public static ApexJobTracker findTracker(List<String> predicates) {
        if (predicates == null || predicates.isEmpty()){
            throw new CustomException('The predicates are required to find the right apex job tracker record.');
        }
        ApexJobTracker__c rec = getTracker(String.join(predicates, ' AND '));
        return new ApexJobTracker(rec);
    }
    
    public static ApexJobTracker getById(String recordId) {
        if (String.isBlank(recordId)) {
            throw new CustomException('The object id is required.');
        }
        ApexJobTracker__c rec = getTracker('Id=\'' +  recordId + '\'');
        return new ApexJobTracker(rec);
    }
    
    private static ApexJobTracker__c getTracker(String clause) {
        List<ApexJobTracker__c> trackers = Database.query(AppUtil.genQuery('ApexJobTracker__c') + ' WHERE ' + clause);
        if (trackers.size() == 0) {
            throw new CustomException('The apex job tracker not found with the clause: ' + clause);
        }
        return trackers[0];
    }
    
    public static ApexJobTracker create(String trackerParentId, TrackerTarget enumTarget, TrackerOperation enumOperation) {
        return new ApexJobTracker(new ApexJobTracker__c(
            Status__c = 'New',
            ParentId__c = trackerParentId,
            Object__c = enumTarget.name().replace('_', ' '),
            Operation__c = enumOperation.name().replace('_', ' ')
        ));
    }
    
    public ApexJobTracker setStatus(TrackerStatus status) {
        String value = '';
        switch on Status {
            when Initial {
                value = 'New';
            }
            when In_Progress {
                value = 'In Progress';
            }
            when Success {
                value = 'Success';
            }
            when Failure {
                value = 'Failure';
            }
        }
        record.Status__c = value;
        return this;
    }
    
    public ApexJobTracker setNotified(boolean notified) {
        record.IsFailureNotified__c = notified;
        return this;
    }
    
    public void retry() {
        if (record.Id == null) {
            throw new CustomException('Apex Job Tracker not identified.');
        }
        if (String.isBlank(record.AppClassName__c)) {
            throw new CustomException('The apex job tracker classname is not specified.');
        }
        try {
            record.StartDateTime__c = Datetime.now(); 
            record.Status__c = 'New';
            executeAppClass();
        } 
        catch(Exception ex) {
            record.Status__c = 'Failure';
            record.response__c = ex.getStackTraceString();
        }
        finally {
            record.NumberofTries__c = 1 + record.NumberofTries__c;
        }
        save();
    }
    
    private void executeAppClass() {
        Type classType = Type.forName(AppNameSpace, record.AppClassName__c);
        IAppClass appInstance = (IAppClass) classType.newInstance();
        appInstance.execute(this.record);
    }
    
    public ApexJobTracker setClassName(String className) {
        record.AppClassName__c = className;
        return this;
    }
    
    public ApexJobTracker setParameters(String arguments) {
        record.Parameters__c = arguments;
        return this;
    }
    
    public ApexJobTracker setId1(String idOne) {
        record.Id1__c = idOne;
        return this;
    }
    
    public ApexJobTracker setProjectId(String projectId) {
        record.Project__c = projectId;
        return this;
    }
    
    public ApexJobTracker setId2(String idTwo) {
        record.Id2__c = idTwo;
        return this;
    }
    
    public ApexJobTracker setId3(String idThree) {
        record.Id3__c = idThree;
        return this;
    }
    
    public ApexJobTracker setResponse(String message) {
        String value = message + '';
        if (value.length() > 131072) {
            value = value.substring(0, 131072);
        }
        record.Response__c = value;
        return this;
    }
    
    public ApexJobTracker end() {
        record.EndDateTime__c = Datetime.now();
        return save();
    }
    
    public ApexJobTracker save() {
        Database.SaveResult result;
        
        if (String.isBlank(record.Id)) {
            record.StartDateTime__c = Datetime.now();
            record.NumberofTries__c = 1;
            result = Database.insert(record);
        } else {
            result = Database.update(record);
        }
        
        if (!result.isSuccess()) {
            throw new CustomException(AppUtil.genSaveResultError(result));
        }
        return this;
    }
    
    public static boolean isCompleted(String trackerParentId, TrackerTarget enumTarget, TrackerOperation enumOperation) {
        String objectId = enumTarget.name().replace('_', ' ');
        String operationId = enumOperation.name().replace('_', ' ');
        List<ApexJobTracker__c> trackers = [
            SELECT Status__c
            FROM ApexJobTracker__c
            WHERE ParentId__c = :trackerParentId AND
            Object__c = :objectId AND
            Operation__c = :operationId];
        if (trackers.isEmpty()) { return true; }
        ApexJobTracker__c tracker = trackers[0];
        return (tracker.Status__c == 'New' || tracker.Status__c == 'In Progress')
            ? false : true;
    }
}