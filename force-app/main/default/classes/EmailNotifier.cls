global without sharing class EmailNotifier implements IEmailNotifier {
    String Subject {get; set;}
    String Body {get; set;}
    String Recipient {get; set;}
    List<String> CCList {get; private set;}
    List<String> AttachmentIds {get; private set;}
    global List<String> Errors {get; private set;}

    global EmailNotifier() {
        this.CCList = new List<String>();
        this.Errors = new List<String>();
        this.AttachmentIds = new List<String>();
    }

    global IEmailNotifier setRecipient(String toEmail) {
        Recipient = toEmail;
        return this;
    }

    //global IEmailNotifier setRecipientByUserId(String userId) {
    //    Recipient = getUserEmail(userId);
    //    return this;
    //}

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

    //global IEmailNotifier setAttachments(String[] attachments) {
    //    if (attachments != null) {
    //        for (String aId : attachments) {
    //            this.AttachmentIds.add(aId);
    //        }
    //    }

    //    return this;
    //}

    global IEmailNotifier setSubject(String emailSubject) {
        Subject = emailSubject;
        return this;
    }

    global IEmailNotifier setBody(String emailBody) {
        Body = emailBody;
        return this;
    }

    global IEmailNotifier setCC(String ccEmail) {
        CCList.add(ccEmail);
        return this;
    }

    global IEmailNotifier setCCList(String[] ccEmails) {
        CCList.addAll(ccEmails);
        return this;
    }

    global Boolean send() {
        return doSend(false);
    }

    global Boolean sendAsHtml() {
        return doSend(true);
    }

    global String getErrorString() {
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