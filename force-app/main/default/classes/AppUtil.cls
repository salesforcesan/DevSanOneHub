global class AppUtil {
    
    public final static Integer PageSize {get;set;}
    public final static String LocationSearchField {get;set;}
    public final static String LocationReportUrl {get;set;}
    public final static String ExportJobReportUrl {get;set;}
    public final static String ExportReservationReportUrl {get;set;}
    public final static String ExportJobAttemptWorkerReportUrl {get;set;}
    public final static Integer JobImportChunkSize {get;set;}
    public final static Integer ProjectStatusChangeSize {get;set;}
    public final static String JobImportFields {get;set;}
    public final static String JobImportHeaderDefinition {get;set;}
    public final static String LocationImportHeaderDefinition {get;set;}
    public final static String LocationImportFields {get;set;}
    public final static Integer LocationImportChunkSize {get;set;}
    public final static String JAWImportHeaderDefinition {get;set;}
    public final static String JAWImportFields {get;set;}
    public final static Integer JAWImportChunkSize {get;set;}
    public final static Integer HistoryRecordLimit {get;set;}
    public final static String EntityChangeLogURI  {get;set;}
    public final static Integer MaxFavoritePhotoCount {get;set;}
    public final static Integer PhotoViewerPageSize {get;set;}
    public final static Integer PhotoViewerMaxExport {get;set;}
    public final static String ServiceImportHeaderDefinition {get;set;}
    public final static Integer ServiceImportChunkSize {get;set;}
    public final static Integer ReservationProcessLimit {get;set;}
    public final static Integer ProjectInvoiceDueDateThreshold {get;set;}
	public final static Integer CreditLineItemOrder {get;set;}
    public final static String CommunitySiteUrl {get;set;}
    public final static Integer PhotoViewerLookupSize {get;set;}
    //sankar added
    public final static String ThirdPartyAgencyChangeEmailTemplateName {get;set;}
    public final static String ThirdPartyAgencyDeniedContactId {get;set;}
    public final static String ThirdPartyAgencyReqContactId {get;set;}
    public final static String PI_FieldsToExcludeWhileCloning {get;set;}
    public final static String PILI_FieldsToExcludeWhileCloning {get;set;}
    public final static String PILID_FieldsToExcludeWhileCloning {get;set;}
    
    public final static String DefaultGroupProject {get;set;}
    
    public final static String AllowedFileType {get;set;}
    public final static String FileTypeCheckRequiredObjects {get;set;}  
    
    //
    
    static {
        OrgCustomSettings__c settings = OrgCustomSettings__c.getInstance('Setting');
        ProjectInvoiceOrgSettings__c projectInvoiceSettings = ProjectInvoiceOrgSettings__c.getValues('ProjectInvoiceSetting');
        ProjectInvoiceOrgSettings__c projectInvoiceLineItemSettings = ProjectInvoiceOrgSettings__c.getValues('ProjectInvoiceLineItemSetting');
        ProjectInvoiceOrgSettings__c projectInvoiceLineItemDetailSettings = ProjectInvoiceOrgSettings__c.getValues('ProjectInvoiceLineItemDetailSetting');
        
        if(projectInvoiceSettings != null){
            PI_FieldsToExcludeWhileCloning = String.valueOf(projectInvoiceSettings.FieldsToExcludeWhileCloning__c == null? '': projectInvoiceSettings.FieldsToExcludeWhileCloning__c);
        }
        if(projectInvoiceLineItemSettings != null){
            PILI_FieldsToExcludeWhileCloning = String.valueOf(projectInvoiceLineItemSettings.FieldsToExcludeWhileCloning__c == null? '': projectInvoiceLineItemSettings.FieldsToExcludeWhileCloning__c);
        }
        if(projectInvoiceLineItemDetailSettings != null){
            PILID_FieldsToExcludeWhileCloning = String.valueOf(projectInvoiceLineItemDetailSettings.FieldsToExcludeWhileCloning__c == null? '': projectInvoiceLineItemDetailSettings.FieldsToExcludeWhileCloning__c);
        }
        
        AllowedFileType = String.valueOf(settings.AllowedFileType__c == null? '': settings.AllowedFileType__c);
        DefaultGroupProject = String.valueOf(settings.DefaultGroupProject__c == null? '': settings.DefaultGroupProject__c);
        FileTypeCheckRequiredObjects = String.valueOf(settings.FileTypeCheckRequiredObjects__c == null? '': settings.FileTypeCheckRequiredObjects__c);
        
        PhotoViewerLookupSize = String.valueOf(settings.PhotoViewerLookupSize__c) != null 
        ? Integer.valueOf(settings.PhotoViewerLookupSize__c) : 50;

        LocationSearchField = String.valueOf(settings.LocationSearchField__c == null? '': settings.LocationSearchField__c);

        LocationReportUrl = String.valueOf(settings.LocationReportUrl__c == null? '': settings.LocationReportUrl__c);
        ExportJobReportUrl = String.valueOf(settings.ExportJobReportUrl__c == null ? '': settings.ExportJobReportUrl__c);
        ExportReservationReportUrl = String.valueOf(settings.ReservationReportUrl__c == null ? '': settings.ReservationReportUrl__c);
        ExportJobAttemptWorkerReportUrl = String.valueOf(settings.JobAttemptWorkerReportUrl__c == null ? '': settings.JobAttemptWorkerReportUrl__c);
        
        CreditLineItemOrder = Integer.valueOf(settings.CreditLineItemOrder__c != null ? settings.CreditLineItemOrder__c : 1);
        PageSize = Integer.valueOf(settings.PageSize__c != null ? settings.PageSize__c : 100);
        JobImportChunkSize = Integer.valueOf(settings.JobImportChunkSize__c != null? settings.JobImportChunkSize__c: 5000);
        JobImportFields = String.valueOf(settings.JobImportFields__c == null ? '': settings.JobImportFields__c);
        JobImportHeaderDefinition = String.valueOf(settings.JobImportTitle__c == null ? '': settings.JobImportTitle__c);
        
        JAWImportChunkSize = Integer.valueOf(settings.JAWImportChunkSize__c != null? settings.JAWImportChunkSize__c: 5000);
        JAWImportFields = String.valueOf(settings.JAWImportFields__c == null ? '': settings.JAWImportFields__c);
        JAWImportHeaderDefinition = String.valueOf(settings.JAWImportTitle_c__c == null ? '': settings.JAWImportTitle_c__c);

        
        LocationImportHeaderDefinition = String.valueOf(settings.LocationImportTitle__c == null ? '' : settings.LocationImportTitle__c);
        ProjectStatusChangeSize =  Integer.valueOf(settings.ProjectStatusChangeSize__c != null? settings.ProjectStatusChangeSize__c: 25);
        LocationImportFields = String.valueOf(settings.LocationImportFields__c == null ? '': settings.LocationImportFields__c);
        LocationImportChunkSize = Integer.valueOf(settings.LocationImportChunkSize__c != null ? settings.LocationImportChunkSize__c: 5000);
        HistoryRecordLimit = Integer.valueOf(settings.HistoryRecordLimit__c != null ? settings.HistoryRecordLimit__c: 9000);
        EntityChangeLogURI = String.valueOf(settings.EntityChangeLogURI__c == null ? '': settings.EntityChangeLogURI__c);
        MaxFavoritePhotoCount = Integer.valueOf(settings.FavoritePhotoMaxCount__c != null ? settings.FavoritePhotoMaxCount__c : 5);
        PhotoViewerPageSize = Integer.valueOf(settings.PhotoViewerPageSize__c != null ?settings.PhotoViewerPageSize__c : 100);
        PhotoViewerMaxExport = Integer.valueOf(settings.PhotoViewerMaxExport__c != null ?settings.PhotoViewerMaxExport__c : 50);
        ServiceImportHeaderDefinition = String.valueOf(settings.ServiceImportTitle__c == null ? '': settings.ServiceImportTitle__c);
        ServiceImportChunkSize = Integer.valueOf(settings.ServiceImportChunkSIze__c != null ? settings.ServiceImportChunkSIze__c: 5000);
        ReservationProcessLimit = Integer.valueOf(settings.ReservationProcessLimit__c != null ? settings.ReservationProcessLimit__c: 3);
        CommunitySiteUrl = String.valueOf(settings.CommunitySiteUrl__c != null ? settings.CommunitySiteUrl__c: '');
        ProjectInvoiceDueDateThreshold = Integer.valueOf(settings.ProjectInvoiceDueDateThreshold__c != null ? settings.ProjectInvoiceDueDateThreshold__c: 0);
        
        //sankar added
        ThirdPartyAgencyChangeEmailTemplateName = String.valueOf(settings.ThirdPartyAgencyChangeEmailTemplate__c != null ? settings.ThirdPartyAgencyChangeEmailTemplate__c: '');
        ThirdPartyAgencyDeniedContactId = String.valueOf(settings.ThirdPartyAgencyDeniedContactId__c != null ? settings.ThirdPartyAgencyDeniedContactId__c: '');
        ThirdPartyAgencyReqContactId = String.valueOf(settings.ThirdPartyAgencyReqContactId__c != null ? settings.ThirdPartyAgencyReqContactId__c: '');
    }
    
    global static Integer getCPUUsage()
    {
        return Integer.valueOf(Limits.getCpuTime()/Limits.getLimitCpuTime() * 100);
        
    }
    
    global static List<Retailer__c> getProfileRetailers(){
        String profileName = [Select Id,Name from Profile where Id=:userinfo.getProfileId()].Name;
        return [SELECT Id, Name, OneHubRetailerId__c FROM Retailer__c];
    }
    
    global static String getOrgInstance(){
        OrgCustomSettings__c setting = OrgCustomSettings__c.getInstance('Setting');
        if(setting == null){
            throw new CustomException(' Org Instance Name not defined in custom settings');
        }
        return setting.OrgInstanceName__c;
    }
    
    global static String[] getDevAlertEmails(){
        List<OrgCustomSettings__c> setting = [SELECT ErrorNotificationEmail__c FROM OrgCustomSettings__c LIMIT 1];
        if(setting == null || setting.size() == 0){
            return null;
        }
        return setting[0].ErrorNotificationEmail__c.split(',');
    }
    
    global static String getAppSetting(String key){
        List<AppSettings__mdt> appSettings = [SELECT Value__c FROM AppSettings__mdt WHERE DeveloperName = :key];
        if(!appSettings.isEmpty()){
            return appSettings[0].Value__c;
        }
        return '';
    }
    
    global static void setOrgWideEmailAddress(Messaging.SingleEmailMessage mail){
        String orgWideEmailAddress = getAppSetting('DefaultOrgwideEmailAddress');
        if(!String.isEmpty(orgWideEmailAddress)){
            OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = :orgWideEmailAddress];
            if ( owea.size() > 0 ) {
                mail.setOrgWideEmailAddressId(owea.get(0).Id);
            }
        }
    }
    
    global static List < Schema.FieldSetMember > readFieldSet(String fieldSetName, String ObjectName) {
        String objectPrefix = SObjectType.ProjectService__c.Name.substringBefore('ProjectService__c');
        Map < String, Schema.SObjectType > GlobalDescribeMap = Schema.getGlobalDescribe();
        if(!ObjectName.startsWith(objectPrefix))
            ObjectName=objectPrefix+ObjectName;
        system.debug(objectPrefix);
        system.debug(ObjectName);
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        //system.debug('====>' + DescribeSObjectResultObj.FieldSets.getMap().get(objectPrefix+fieldSetName));
        if(!fieldSetName.startsWith(objectPrefix))
            fieldSetName=objectPrefix+fieldSetName;
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
        //List<Schema.FieldSetMember> fieldSetMemberList =  fieldSetObj.getFields();
        //system.debug('fieldSetMemberList ====>' + fieldSetMemberList);
        return fieldSetObj.getFields();
    }
    
    global static list < string > GetTrackingFieldsFromFieldSet(String fieldSetName, String ObjectName) {
        String objectPrefix = SObjectType.ProjectService__c.Name.substringBefore('ProjectService__c');
        list < string > str = new list < string > ();
        for (Schema.FieldSetMember f: readFieldSet(objectPrefix+fieldSetName, objectPrefix+ObjectName)) {
            str.add(f.getFieldPath());
        }
        return str;
    }
    
    
    String join(List<String> values) {
        List<String> valueCopy = new List<String>(values);
        if(valueCopy.isEmpty())
            return null;
        String result = valueCopy[0];
        valueCopy.remove(0);
        while(!valueCopy.isEmpty()) {
            result += ',' + valueCopy[0];
            valueCopy.remove(0);
        }
        return result;
    }
    
    global static void UpdateProjectVersion(Set<Id> projectIds)
    {
        
        Boolean updateproject = false;
        //AggregateResult[] maxResults = [SELECT max(UpdateSequence__c) max FROM Project__c];
        Integer max = GetMaxProjectVersion();//Integer.valueOf(maxResults[0].get('max') == null ? '0' : maxResults[0].get('max'));
        
        List<Project__c> projects = [Select Id, UpdateSequence__c, Status__c, IsExternalProject__c from Project__c where Id =: projectIds];
        for (Project__c p : projects)
        {
            if(p.UpdateSequence__c == -999){
                continue;
            }
            if (p.Status__c == CONSTANTS.PROJECT_STATUS_BOOKED || p.Status__c == CONSTANTS.PROJECT_STATUS_LAUNCHED ||
                p.Status__c == CONSTANTS.PROJECT_STATUS_INPROGRESS || p.Status__c == CONSTANTS.PROJECT_STATUS_ENDED || p.Status__c == CONSTANTS.PROJECT_STATUS_CLOSED ||
                p.Status__c == CONSTANTS.PROJECT_STATUS_CANCELED)
            {
                max = max + 1;
                p.UpdateSequence__c = max;
                updateproject = true;
            }
        }
        
        if (updateproject == true)
        {
            TriggerUtil.SkipProjectTrigger = true;
            update projects;
        }
        
    }
    global static void UpdateProjectVersion(String projectId)
    {
        Set<id> pids = new Set<id>();
        pids.add(projectId);
        UpdateProjectVersion(pids);
    }
    
    global static Integer GetMaxProjectVersion()
    {
        Project__c[] p = [SELECT UpdateSequence__c FROM Project__c WHERE UpdateSequence__c != null ORDER BY  UpdateSequence__c DESC LIMIT 1];
        if(p.isEmpty()){
            return 0;
        }
        else{
            return Integer.valueOf(p[0].UpdateSequence__c);
        }
        //return Integer.valueOf(maxResults[0].get('max') == null ? '0' : maxResults[0].get('max'));
    }
    
    global static Integer GetMaxContactVersion()
    {
        Contact[] c = [SELECT UpdateSequence__c FROM Contact WHERE UpdateSequence__c != null ORDER BY  UpdateSequence__c DESC LIMIT 1];
        if(c.isEmpty()){
            return 0;
        }
        else{
            return Integer.valueOf(c[0].UpdateSequence__c);
        }
        
    }
    
    
    global static void updateProjectService(Set<id> psIds){
        ProjectService__c psExt = [SELECT service__r.name, Project__r.IsExternalProject__c, Project__c FROM ProjectService__c WHERE ID in : psIds LIMIT 1];
        Decimal purchaseAmountPercent = Decimal.valueOf( AppUtil.getAppSetting('PurchaseAmountPercent'));
        
        List<ProjectService__c> psList = new List<ProjectService__c>();
        List<AggregateResult> psPriceResults = [SELECT ProjectService__c ps, SUM(TotalPrice__c) TotalPrice FROM ProjectServiceTarget__c WHERE ProjectService__c IN :psIds AND (Type__c = 'primary' OR Type__c = 'supplemental') GROUP BY ProjectService__c];
        system.debug('psPriceResults:'+psPriceResults.size());
        system.debug('psIds:'+psIds);
        if(psPriceResults.size() == 0){
            psList = [SELECT Id, PurchaseAmount__c FROM ProjectService__c WHERE Id in :psIds];
            for(ProjectService__c ps :psList){
                ps.PurchaseAmount__c = 0;
            }
        }
        else{
            for (AggregateResult psPrice : psPriceResults) {
                system.debug('psPrice:'+psPrice);
                ProjectService__c ps = new ProjectService__c();
                ps.ID = String.valueOf(psPrice.get('ps'));
                ps.PurchaseAmount__c = purchaseAmountPercent * Double.valueOf(psPrice.get('TotalPrice'));
                ps.SalesTax__c = ps.PurchaseAmount__c - Double.valueOf(psPrice.get('TotalPrice'));
                psList.add(ps);
            }
        }
        system.debug('psList----------------------'+psList);
        
        TriggerUtil.skipProjectServiceTrigger = true;
        update psList;
        //Comment Version Code
        //AppUtil.UpdateProjectVersion(psExt.Project__c);
    }
    
    global static boolean hasProjectLeadTime(Project__c project){
        Integer ffleadTimeDays = 0;
        List<ProjectService__c> pss = [Select Id, Name from ProjectService__c where Project__c =: project.Id and NumberOfMaterials__c > 0];
        //if there are not materials, nothing to fulfill so return true;
        if (pss.size() == 0 ) { return true; }
        
        ffleadTimeDays = Integer.valueOf(project.FulfillmentLeadTime__c);
        Integer ptleadTimeDays = Integer.valueOf(String.valueOf(project.ProjectCancelLeadTime__c));
        Integer leadTimeDays = ffleadTimeDays > ptleadTimeDays ? ffleadTimeDays : ptleadTimeDays;
        Datetime leadTimeReachDate =  (DateTime.now()).AddDays(leadTimeDays);
        if(project.StartDate__c >= leadTimeReachDate.date()){
            return true;
        }
        return false;
    }
    
    //Do not use this method from inside a trigger (job trigger, for example)
    // where this will be called over and over again for every job.
    //Use the hasProjectLeadTime(Project__c project) and pass in the
    //project object itself with the required fields
    
    global static boolean hasProjectLeadTimeByProjectId(Id projectId) {
        Project__c project = [Select Id, Name, ProjectCancelLeadTime__c , StartDate__c, FulfillmentLeadTime__c, ProjectOrigin__c from Project__c where Id = :projectId];
        return hasProjectLeadTime(project);
    }
    
    global static boolean isScheduledWithLoadTime(Id projectId) {
        Project__c project = [Select Id, Name, ProjectCancelLeadTime__c , StartDate__c, FulfillmentLeadTime__c, Status__c from Project__c where Id = :projectId];
        if(project.Status__c != 'Booked'){
            return false;
        }
        return hasProjectLeadTime(project);
    }
    
    global static boolean canSetScheduleDate(Id projectId) {
        List<Project__c> p = [select id, Status__c, ProjectScheduleOption__r.Code__c, StartDate__c, ProjectType__r.SetScheduleDateLeadTime__c from Project__c where id=:projectId];
        if(p.size() > 0){
            boolean hasScheduleLeadTime = false;
            if(p[0].ProjectType__r.SetScheduleDateLeadTime__c != NULL && p[0].StartDate__c.addDays(Integer.valueOf(p[0].ProjectType__r.SetScheduleDateLeadTime__c * -1)) >= date.today()) {
                hasScheduleLeadTime = true;
            }
            if(hasScheduleLeadTime && p[0].ProjectScheduleOption__r.Code__c == CONSTANTS.SCHEDULE_OPTION_USER){
                return true;
            }
        }
        return false;
    }
    
    
    global static boolean isProjectLocked(Project__c proj){
        
        if (proj.Status__c != 'Planning')
        {
            return true;
        }
        return false;
    }
    
    global static Boolean CheckProjectLocationEquipmentDelete(Id ps, Id pl, Date jsd, List<Job__c> cancellableJobs)
    {
        for (Job__c job : cancellableJobs)
        {
            if (job.ProjectService__c == ps && job.ProjectLocation__c == pl && job.JobStartDate__c == jsd)
            {
                return true;
            }
        }
        
        return false;
        
    }
    
    global static boolean projectHasReserved(Project__c p) {
        return getProjectIdToHasReserved(new Project__c[]{ p }).get(p.Id);
    }
    
    global static Map<Id, Boolean> getProjectIdToHasReserved(Project__c[] projects) {
        
        Map<Id, Boolean> output = new Map<Id, Boolean>();
        
        for (AggregateResult aggResult : [SELECT Project__c projectId, count(Id) reservedLocationsCount FROM Job__c WHERE Project__c IN :projects GROUP BY Project__c]) {
            output.put(
                (Id) aggResult.get('projectId')
                , ((Integer) aggResult.get('reservedLocationsCount')) > 0 ? true : false
            );
        }
        
        for (Project__c project : projects) {
            if (!output.containsKey(project.Id)) output.put(project.Id, false);
        }
        
        return output;
    }
    global static string getContentType(String extention) {
        string contentType = 'application/octet-stream';
        if(extention == 'pdf'){
            contentType = 'application/pdf';
        }
        else if(extention == 'jpg' || extention == 'jpeg'){
            contentType = 'image/jpeg';
        }
        else if(extention == 'png'){
            contentType = 'image/png';
        }
        else if(extention == 'gif'){
            contentType = 'image/gif';
        }
        else if(extention == 'csv'){
            contentType = 'text/csv';
        }
        else if(extention == 'doc'){
            contentType = 'application/msword';
        }
        else if(extention == 'docx'){
            contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        }
        else if(extention == 'xlsx'){
            contentType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        }
        else if(extention == 'pptx'){
            contentType = 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
        }
        else if(extention == 'zip'){
            contentType = 'application/x-zip-compressed';
        }
        else if(extention == 'txt'){
            contentType = 'text/plain';
        }
        
        
        return contentType;
    }
    
    global static void RunEntityChangeLogPurge() {
        
        
        Integer eclpurgesize = 0;
        Integer eclpurgedays = 0;
        
        List<OrgCustomSettings__c> settings = [SELECT EntityChangeLogPurgeSize__c, EntityChangeLogPurgeDays__c FROM OrgCustomSettings__c LIMIT 1];
        if(settings == null || settings.size() == 0 || settings[0] == null || settings[0].EntityChangeLogPurgeSize__c == null){
            eclpurgesize = 9500;
        }
        else
        {
            eclpurgesize = Integer.valueOf(settings[0].EntityChangeLogPurgeSize__c);
        }
        
        if(settings == null || settings.size() == 0 || settings[0] == null || settings[0].EntityChangeLogPurgeDays__c == null){
            eclpurgedays = 30;
        }
        else
        {
            eclpurgedays = Integer.valueOf(settings[0].EntityChangeLogPurgeDays__c);
        }
        
        Date purgeDate = Date.today().addDays(0-eclpurgedays);
        system.debug('Purge Date: ' + purgeDate);
        
        //Purge all log older than 14 days or whatever days set in custom settings
        List<EntityChangeLog__c> ecls = [Select Id from EntityChangeLog__c WHERE
                                         CreatedDate < :purgeDate and 
                                         Status__c = :Constants.ENTITY_CHANGELOG_STATUS_RELEASED
                                         ORDER BY ChangeNumberNumeric__c LIMIT :eclpurgesize];
        
        if (ecls.IsEmpty())
            return;
        
        delete ecls;
    }
    
    
    
    global static Map<String, String> GetRecordTypeIds(string objectName) {
        
        Map<String, String> rtmap = new Map<String, String>();
        List<RecordType> rts = [Select Id, Name, DeveloperName from RecordType
                                WHERE SObjectType =: objectName ];
        
        for (RecordType rt : rts)
        {
            rtmap.put(rt.Name, rt.Id);
        }
        
        //Return Default
        return rtmap;
        
    }
    
    public static string genDMLError(DmlException dml){
        List<String> msgs = new List<String>();
        for(Integer i=0; i < dml.getNumDml(); i++){
            msgs.add(dml.getDmlMessage(i));
        }
        return String.join(msgs, '. ');
    }
    
    public static String genSaveResultError(Database.SaveResult sr){
        List<String> errors = new List<String>();
        for(Database.Error err : sr.getErrors()){
            errors.add(err.getStatusCode() + ': ' + err.getMessage());
        }
        return String.join(errors, '. ');
    }
    
    public static String genSaveResultListError(List<Database.SaveResult> srList){
        List<String> errors = new List<String>();
        String error;
        
        for(Database.SaveResult sr: srList){
            if(!sr.isSuccess()){
                error = genSaveResultError(sr);
                if(!String.isBlank(error)){
                    errors.add(error);
                }
            }
        }
        
        return errors.size() > 0 ? String.join(errors, '. '): '';
    }

    public static Map<String, Object> analyzeSaveResultList(String topic, List<Database.SaveResult> srList){
        Map<String,Object> result = new Map<String,Object>();
        List<String> errors = new List<String>();
        String error;
        Integer errCount = 0;
        
        for(Database.SaveResult sr: srList){
            if(!sr.isSuccess()){
                errCount++;
                error = genSaveResultError(sr);
                if(!String.isBlank(error)){
                    errors.add(error);
                }
            }
        }
        result.put('topic', topic);
        result.put('success', srList.size() - errCount);
        result.put('error', errCount);
        result.put('total', srList.size());
        result.put('messages', errors);
        return result;
    }
    
    public static String genQuery(String sObjectType) {
        return genQuery(sObjectType, new List<String>());
    }
    
    public static String genQuery(String sObjectType, List<String> additionals) {
        String recordName = sObjectType;
        Schema.DescribeSObjectResult meta = Schema.describeSObjects(new String[] {recordName}).get(0);
        Map<String, Schema.SObjectField> fieldMap = meta.fields.getMap();
        List<String> fieldNames = new List<String>();
        List<Schema.SObjectField> fields = fieldMap.values();
        String fielfName;
        fieldNames.add('Id');
        fieldNames.add('Name');
        for (SObjectField f : fields) {
            fielfName = f.getDescribe().getName();
            if (fielfName.indexOf('__c') != -1) {
                fieldNames.add(fielfName);
            }
        }
        for(String col: additionals){
            fieldNames.add(col);
        }
        return 'SELECT ' + String.join(fieldNames, ',') + ' FROM ' + recordName;
    }
    
    public static String getUserAccountId(){
        String userId = UserInfo.getUserId();
        List<User> contacts = [SELECT AccountId FROM User WHERE Id = :userId];
        return   contacts.size() > 0 ? String.valueOf(contacts[0].AccountId) : '';
    }
    
    public static void UpdateApexJobTracker(string ajtid, string status, DateTime starttime, DateTime endtime, boolean incrementtries)
    {
        
        ApexJobTracker__c ajt = [Select Id, Name, BatchProcessId__c, Object__c, Operation__c, Project__c, 
                                 StartDateTime__c, EndDateTime__c, Status__c, NumberofTries__c, Id1__c, Id2__c, Id3__c,
                                 Parameters__c FROM ApexJobTracker__c WHERE Id = :ajtid];         
        
        ajt.Status__c = status;
        if (starttime != null) ajt.StartDateTime__c = starttime;
        if (endtime != null) ajt.EndDateTime__c = endtime;
        if (incrementtries) {
            if(ajt.NumberofTries__c == null)
                ajt.NumberofTries__c = 0;
            else
                ajt.NumberOfTries__c++;
        }
        update ajt;     
        
    }  
    public static ApexJobTracker__c InsertApexJobTrackerRecord(string objectname, string operation, string ids)
    {
        
        ApexJobTracker__c ajt = new   ApexJobTracker__c();
        ajt.Object__c = objectname;
        ajt.Operation__c = operation;
        ajt.Status__c = 'In Progress';
        ajt.StartDateTime__c = DateTime.Now();
        ajt.Id1__c = ids;
        insert ajt;  

		return ajt;
        
    } 
    //sankar added
     public static void sendTemplatedEmail(List<String> toRecipients, List<String> ccRecipients, String templateApiName, 
                                          ID targetObjId, Id whatId, Boolean saveAsActivity, 
                                          Attachment[] attachList ) {
                                              
        //  templateId   must be ID of an Email template
        //  targetObjId must be a Contact, User, Lead Id -- also used in merge fields of template recipient.xxxx
        //  whatId    must be an SObject that is used in the merge fields of the template relatedTo.xxxx
        //  fromId    if non null, use current user, otherwise, use this ID (most likely an org wide no reply id)
        //  bcc      not permitted when using templates
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        Id templateId;  
        try {templateId = [select id, name from EmailTemplate where developername = : templateApiName].id;}
        catch (Exception e) {
            System.debug('Unable to locate EmailTemplate using name: ' + templateApiName);
        }
                                              
		system.debug('toRecipients:::' + toRecipients);
                                                  
        email.setToAddresses(toRecipients);
        email.setCcAddresses(ccRecipients);
        email.setTargetObjectId(targetObjId);
        email.setWhatId(whatId);
        email.setorgWideEmailAddressId(getOrgWideEmailId());
        email.setTemplateId(templateId);
        email.setSaveAsActivity(saveAsActivity);      // save email as activity on the targetObjId (i.e. Contact). Note activity can't be saved on Users
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});            
            return;
        }
        catch (EmailException e) {System.debug('sendTemplatedEmail error. ' + e.getMessage());}
        
    }  
   
     public static Id getOrgWideEmailId(){

        List<OrgWideEmailAddress> results = [select id, Address from OrgWideEmailAddress where Address LIKE '%noreply.onehub%'];
        if(results.size() > 0){
            return results.get(0).Id;
        }
        return null;
    }
     //sankar end code
    
}