public interface IEmailNotifier1 {

    IEmailNotifier1 setRecipient(String toEmail);
    
    IEmailNotifier1 setRecipientByUserId(String userId);

    IEmailNotifier1 setSubject(String emailSubject);

    IEmailNotifier1 setBody(String emailBody);

    IEmailNotifier1 setCC(String ccEmail);

    IEmailNotifier1 setAttachments(String[] attachments);

    IEmailNotifier1 setCCList(String[] ccEmails);

    String getErrorString();

    Boolean send();

    Boolean sendAsHtml();
}