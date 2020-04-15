global interface IEmailNotifier {

    IEmailNotifier setRecipient(String toEmail);
    
    IEmailNotifier setSubject(String emailSubject);

    IEmailNotifier setBody(String emailBody);

    IEmailNotifier setCC(String ccEmail);

    IEmailNotifier setCCList(String[] ccEmails);

    String getErrorString();

    Boolean send();

    Boolean sendAsHtml();
}