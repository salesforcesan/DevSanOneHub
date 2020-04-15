@istest
	public without sharing class EmailNotifierFake1 implements IEmailNotifier1 {
    Boolean succeededFlag;
    String errMsg;
    public String body;
    public String subject;

    public EmailNotifierFake1() {
        this.succeededFlag = true;
        this.errMsg = '';
        this.body = '';
        this.subject = '';
    }    

    public EmailNotifierFake1(Boolean succeeded, String errorMessage) {
        this.succeededFlag = succeeded;
        this.errMsg = errorMessage;
        this.body = '';
        this.subject = '';
    }

    public IEmailNotifier1 setRecipient(String toEmail) {
        return this;
    }

   public IEmailNotifier1 setAttachments(String[] attachments) {
        return this;
    }

    public IEmailNotifier1 setRecipientByUserId(String userId)  {
        return this;
    }

    public IEmailNotifier1 setSubject(String emailSubject) {
        this.subject = emailSubject;
        return this;
    }

    public IEmailNotifier1 setBody(String emailBody) {
        this.body = emailBody;
        return this;
    }

    public IEmailNotifier1 setCC(String ccEmail) {
        return this;
    }

    public IEmailNotifier1 setCCList(String[] ccEmails) {
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