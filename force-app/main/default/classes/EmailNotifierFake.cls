@istest
public without sharing class EmailNotifierFake implements IEmailNotifier {
    Boolean succeededFlag;
    String errMsg;
    public String body;
    public String subject;

    public EmailNotifierFake() {
        this.succeededFlag = true;
        this.errMsg = '';
        this.body = '';
        this.subject = '';
    }    

    public EmailNotifierFake(Boolean succeeded, String errorMessage) {
        this.succeededFlag = succeeded;
        this.errMsg = errorMessage;
        this.body = '';
        this.subject = '';
    }

    public IEmailNotifier setRecipient(String toEmail) {
        return this;
    }

    public IEmailNotifier setSubject(String emailSubject) {
        this.subject = emailSubject;
        return this;
    }

    public IEmailNotifier setBody(String emailBody) {
        this.body = emailBody;
        return this;
    }

    public IEmailNotifier setCC(String ccEmail) {
        return this;
    }

    public IEmailNotifier setCCList(String[] ccEmails) {
        return this;
    }

    public String getErrorString() {
        return errMsg;
    }

    public Boolean send() {
        return this.succeededFlag;
    }

    public Boolean sendAsHtml() {
        return this.succeededFlag;
    }

}