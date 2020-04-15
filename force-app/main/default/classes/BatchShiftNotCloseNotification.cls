global without sharing class BatchShiftNotCloseNotification implements Database.Batchable<SObject>, Database.stateful {
   @testVisible
    Integer totalCount;
    @testVisible
    Integer errorCount;
    @testVisible
    Integer sendEmailCount;
    @testVisible
    List<Map<String,String>> Errors {get; private set;}

    global BatchShiftNotCloseNotification(){
        totalCount = 0;
        errorCount = 0;
        sendEmailCount = 0;
        Errors = new List<Map<String,String>>();
    }

    @testVisible
    static string buildQuery(){
        Datetime currentDTTM = Datetime.now().addMinutes(-15);
        String currentEndTime = currentDTTM.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ','UTC');
        return 'SELECT Id, Name, EndTime__c, ActiveJobAttempt__r.TeamLeadContactId__c, ActiveJobAttempt__r.TeamLeadUserId__c, ActiveJobAttempt__r.PrimaryWorkerEmail__c,ActiveJobAttempt__r.PrimarySupervisorEmail__c FROM JOB__c WHERE ActiveJobAttempt__c != null AND JobUTCEndTime__c <=' + currentEndTime + ' AND JobStatus__c NOT IN (\'Closed\',\'Canceled\')';
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(buildQuery());
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        ShiftNotCloseNotificationHandler handler= ShiftNotCloseNotificationHandler.create(scope).execute();
        this.totalCount += handler.TotalCount;
        this.errorCount += handler.ErrorCount;
        this.sendEmailCount += handler.EmailCount;
        if(handler.ErrorCount > 0){
            this.Errors.addAll(handler.Errors);
        }
    }

    global void finish(Database.BatchableContext BC) {
        String email = getEmailDistribution();
        If (String.isBlank(email)) {return;}

        List<String> emailList= new List<String>{email};
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setSubject('Non-Closed Shift Email Notification');
        message.setHtmlBody(genHtmlBody());
        message.setToAddresses(emailList);
        emailMessages.add(Message);
        Messaging.sendEmail(emailMessages);
    }

    @testVisible
    String genHtmlBody(){
        List<String> html = new List<String>();
        html.add('<h1>Shift Not Closed Primary Worker Emai Notification Process Report</h1>');
        html.add('<br/></br>');
        html.add('<div>Total Shifts to process: ' + this.totalCount + '</div>');
        html.add('<div>SendEmailCount: ' + this.sendEmailCount + '</div>');
        html.add('<div>ErrorCount: ' + this.errorCount + '</div>');
        html.add('<br/></br>');
        html.add(genErrorString());
        return String.join(html,'');
    }

    @testVisible
    String genErrorString(){
        List<String> html = new List<String>{
            '<table>',
            '<thead>',
            '<tr>',
            '<th>Shift</th>',
            '<th>Prmary Worker</th>',
            '<th>error</th>',
            '</tr>',
            '</thead>',
            '<tbody>'
        };
        for(Map<String,String> err: this.Errors){
            html.add(genRow(err));
        }
        html.add('</tbody></table>');
        return String.join(html,'');
    }
    
    @testVisible
    String genRow(Map<String,String> err){
        String[] html = new String[]{
            '<tr>',
            '<td>',
            err.get('job'),
            '</td>',
            '<td>',
            err.get('user'),
            '</td>',
            '<td>',
            err.get('message'),
            '</td>',
            '</tr>'
        };
        return String.join(html,'');
    }

    @testVisible
    static string getEmailDistribution(){
        OrgCustomSettings__c setting = [SELECT ErrorNotificationEmail__c FROM OrgCustomSettings__c LIMIT 1];
        return setting.ErrorNotificationEmail__c;
    }
}