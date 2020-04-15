Global without sharing class ShiftNotCloseNotificationHandler {
    @testVisible
    List<Job__c> shifts;

    global List<Map<String,String>> Errors {get; private set;}
    @testVisible
    static Id OrgWideEmailId;

    @testVisible
    static OrgCustomSettings__c OrgCutomSetttings;

    @testVisible
    Static Id EmailTemplateId;

    static {
        OrgWideEmailId = getOrgWideEmailId();
        OrgCutomSetttings = getCustomSettings();
        EmailTemplateId = getEmailTemplateId();
    }

    global Integer TotalCount {get; private set;}
    global Integer ErrorCount {get {
            return this.Errors.size();
        } private set;}
    global Integer EmailCount {get; private set;}

    private ShiftNotCloseNotificationHandler(List<SObject> shifts){
        this.shifts = (List<Job__c>) shifts;
        this.Errors = new List<Map<String,String>>();
        this.TotalCount = shifts.size();
        this.ErrorCount = 0;
        this.EmailCount = 0;
    }

    @testVisible
    static Id getEmailTemplateId(){
        OrgCustomSettings__c settings  = getCustomSettings();
        String templateName = settings.NonClosedShiftEmailTemplate__c;
        EmailTemplate tmpl = [SELECT Id FROM EmailTemplate 
            Where Name =:templateName LIMIT 1];
        return tmpl != null ? tmpl.Id: null;
    }

    @testVisible
    static Id getOrgWideEmailId(){
        if(OrgWideEmailId != null) {
            return OrgWideEmailId;
        }
        List<OrgWideEmailAddress> results = [select id, Address from OrgWideEmailAddress where Address LIKE '%noreply.onehub%'];
        if(results.size() > 0){
            return results.get(0).Id;
        }
        return null;
    }

    @testVisible
    static OrgCustomSettings__c getCustomSettings(){
        if(OrgCutomSetttings != null) {
            return OrgCutomSetttings;
        }
      OrgCustomSettings__c settings = [SELECT ErrorNotificationEmail__c, NonClosedShiftTimeframe__c, NonClosedShiftEmailTemplate__c FROM OrgCustomSettings__c LIMIT 1];
        return settings;
    }

    global static ShiftNotCloseNotificationHandler create(List<SObject> shifts){
        return new ShiftNotCloseNotificationHandler(shifts);
    }

    global ShiftNotCloseNotificationHandler execute() {
        if(this.TotalCount == 0) {return this;}
        validateSettings();
        doExecute();
        return this;
    }

    @testVisible
    static void validateSettings(){
        if(Test.isRunningTest()){return;}
        if(EmailTemplateId == null || OrgWideEmailId == null){
            throw new CustomException('The non-closed shift email template name or OrgWideEmailAddress is not configured properly.');
        }
    }

    @testVisible
    void doExecute(){
        for(Job__c one: this.shifts){
            try
            {    
                processShift(one);
            }
            catch(CustomException cust)
            {
                logError(one.Name, one.ActiveJobAttempt__r.PrimaryWorkerEmail__c, cust.getStackTraceString());
            }
            catch(Exception ex){
             logError(one.Name, one.ActiveJobAttempt__r.PrimaryWorkerEmail__c, ex.getStackTraceString());   
            }
        }
    }

    @testVisible
    void processShift(Job__c shift){
        validateWhoAndWhat(shift);
        sendEmail(shift);
    }

    @testVisible
    void validateWhoAndWhat(Job__c shift){
        if(shift.ActiveJobAttempt__r == null){
            throw new CustomException('no active job attempt is associated to the shift.');
        }

        if(String.isBlank(shift.ActiveJobAttempt__r.TeamLeadUserId__c)) {
            throw new CustomException('The team lead user Id is not assigned.');
        }

        if(String.isBlank(shift.ActiveJobAttempt__r.TeamLeadContactId__c)) {
            throw new CustomException('The team lead Contact Id is not assigned.');
        }

        if(String.isBlank(shift.ActiveJobAttempt__r.PrimaryWorkerEmail__c)){
            throw new CustomException('The shift\' team lead email is not assigned.');
        }

        if(String.isBlank(shift.ActiveJobAttempt__r.PrimarySupervisorEmail__c)) {
            throw new CustomException('The shift\' team lead supervisor email is not assigned.');
        }
    }

    @testVisible
    void sendEmail(Job__c shift) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        Id contactId = ID.valueOf(shift.ActiveJobAttempt__r.TeamLeadContactId__c);
        String workerEmail = shift.ActiveJobAttempt__r.PrimaryWorkerEmail__c;
        String supervisorEmail = shift.ActiveJobAttempt__r.PrimarySupervisorEmail__c;
        emails.add(createEmailRequest(shift.Id, contactId, workerEmail, supervisorEmail));

        for(Messaging.SendEmailResult result: Messaging.sendEmail(emails)) {
            if(result.isSuccess()){
                this.EmailCount += 1;
            } else {
                String error = genError(result.getErrors());
                this.logError(shift.Name, workerEmail, error);
            }
        }
    }

    @testVisible
    String genError(List<Messaging.SendEmailError> emailErrors){
        List<String> items = new List<String>();
        for(Messaging.SendEmailError err: emailErrors){
            items.add(err.getMessage());
        }
        return String.join(items,'. '); 
    }

    @testVisible
    Messaging.SingleEmailMessage createEmailRequest(Id shiftId, Id contactId, String workerEmail, String supervisorEmail){
            Messaging.SingleEmailMessage msg = Messaging.renderStoredEmailTemplate(
                    EmailTemplateId, 
                    String.valueOf(contactId), 
                    String.valueOf(shiftId)
            );
            msg.setToAddresses(new List<String>{workerEmail});
            if(String.isNotBlank(supervisorEmail)){
                msg.setCcAddresses(new List<String>{supervisorEmail});    
            }
            msg.setSaveAsActivity(true);
            if(OrgWideEmailId != null){
                msg.setOrgWideEmailAddressId(OrgWideEmailId);
            }
            return msg;
    }

    @testVisible
    void logError(String jobName, String userEmail, String error){
        Map<String,String> err = new Map<String,String>();
        err.put('job', jobName);
        err.put('user', userEmail);
        err.put('message', error);
        this.Errors.add(err);
    }
}