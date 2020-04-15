public without sharing class EmailNotifier1 implements IEmailNotifier1 {
    String Subject {get; set;}
    String Body {get; set;}
    String Recipient {get; set;}
    List<String> CCList {get; private set;}
    List<String> AttachmentIds {get; private set;}
    public List<String> Errors {get; private set;}

    public EmailNotifier1() {
        this.CCList = new List<String>();
        this.Errors = new List<String>();
        this.AttachmentIds = new List<String>();
    }

    public IEmailNotifier1 setRecipient(String toEmail) {
        Recipient = toEmail;
        return this;
    }

    public IEmailNotifier1 setRecipientByUserId(String userId) {
       Recipient = getUserEmail(userId);
       return this;
    }

    private static String getUserEmail(String userId) {
        List<User> user = [SELECT Name, Email FROM USER Where Id = :userId LIMIT 1];
        if (user.isEmpty()) {
            throw new CustomException('User Not Found:' + userId);
        }
        if (String.isBlank(user[0].Email)) {
            throw new CustomException('User Email Not Configured:' + userId + ':' + user[0].Name);
        }
        return user[0].Email;
    }

    public IEmailNotifier1 setAttachments(String[] attachments) {
        if (attachments != null) {
            for (String aId : attachments) {
                this.AttachmentIds.add(aId);
            }
        }

        return this;
    }


    public IEmailNotifier1 setSubject(String emailSubject) {
        Subject = emailSubject;
        return this;
    }

    public IEmailNotifier1 setBody(String emailBody) {
        Body = emailBody;
        return this;
    }

    public IEmailNotifier1 setCC(String ccEmail) {
        CCList.add(ccEmail);
        return this;
    }

    public IEmailNotifier1 setCCList(String[] ccEmails) {
        CCList.addAll(ccEmails);
        return this;
    }

    public Boolean send() {
        return doSend(false);
    }

    public Boolean sendAsHtml() {
        return doSend(true);
    }

    public String getErrorString() {
        return String.join(Errors, ' ');
    }

    private Boolean doSend(Boolean isHtml) {
        Errors.clear();
        try {
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setSubject(Subject);
            if (isHtml) {
                message.setHtmlBody(Body);
            } else {
                message.setPlainTextBody(Body);
            }
            message.setToAddresses(new String[] {Recipient});
            if (!CCList.isEmpty()) {
                message.setCcAddresses(CCList);
            }

            if (!this.AttachmentIds.isEmpty()) {
                message.setEntityAttachments(this.AttachmentIds);
            }

            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {message});
            if (results.size() > 0 && results[0].isSuccess()) {
                return true;
            }

            Errors.add('EmailNotifier failed to send email');
            for (Messaging.SendEmailResult result : results) {
                Messaging.SendEmailError[] sendErrs = result.getErrors();
                for (Messaging.SendEmailError sendErr : sendErrs) {
                    Errors.add(sendErr.getMessage());
                }
            }
        } catch (Exception ex) {
            Errors.add(ex.getMessage());
        }

        return false;
    }
}