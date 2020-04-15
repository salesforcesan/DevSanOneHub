public class CloneProjectQueuebleJob implements Queueable, Database.RaisesPlatformEvents{

    private Id projectId {get; Set;}

    public CloneProjectQueuebleJob(Id projectId) {
        this.projectId = projectId;
    }

    public void execute(QueueableContext context) {
        try {

            //clone project and invoke batch job to process ps attachments
            Id clonedProjectId = CloneUtil.CloneAll(projectId);

            List<ProjectServiceAttribute__c> psas = [SELECT Id, AttchFileName__c, AttributeValue__c, IsClonedAttachment__c FROM ProjectServiceAttribute__c WHERE  ProjectService__r.Project__c = :clonedProjectId AND (AttributeType__c = 'Photo' OR AttributeType__c = 'File')];
            for (ProjectServiceAttribute__c psa : psas) {
                if (psa.AttributeValue__c != null && psa.AttributeValue__c != '') {
                    String[] arr = psa.AttributeValue__c.split('=');
                    List<Attachment> oldAttachments = [select id, name, body from Attachment where Id = :arr[0] LIMIT 1];

                    if (oldAttachments.isEmpty()) continue;

                    Attachment oldAttachment = oldAttachments[0];

                    Attachment newAttachment = new Attachment(name = oldAttachment.name, body = oldAttachment.body, parentid = this.projectId);
                    insert newAttachment;
                    string imageflag = '';
                    if (arr.size() > 1) {
                        imageflag = '=' + arr[1];
                    }
                    psa.AttributeValue__c = string.valueof(newAttachment.Id) + imageflag;
                }
            }
            update psas;


            Project__c project = [SELECT Id, Name, BatchProcessId__c, ApexJobName__c, RecordTypeId
                                  FROM Project__c WHERE Id = :clonedProjectId];
            BatchClonedProjectAttachmentsHandler batch = new BatchClonedProjectAttachmentsHandler(clonedProjectId);
            string batchProcessId = Database.ExecuteBatch(batch, 1);

            ProjectActionsHelper.LockProject(project, 'Clone Project', batchProcessId);
            TriggerUtil.skipProjectTrigger = true;
            update project;
            
        } catch (Exception ex) {
            throw new CustomException(ex.getMessage() + ': line ' + ex.getLineNumber());
        }
    }
}