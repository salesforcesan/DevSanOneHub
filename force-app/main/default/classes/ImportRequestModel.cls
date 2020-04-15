public with sharing class ImportRequestModel {
    IImportRequestService ServiceInstance {get; private set;}

    public ImportRequestModel(IImportRequestService service) {
        this.ServiceInstance = service;
    }

    public Map<String,Object> getImportSettings() {
        Map<String, Object> res = new Map<String,Object>();
        res.put('chunkSize', ServiceInstance.getChunkSize());
        res.put('importColumnTitles', ServiceInstance.getImportTitles());
        return res;
    }
    
    public void startImport(){
        ServiceInstance.canImport();
        this.deleteAttachments();
    }

    public void importData(List<String> data){
        ServiceInstance.canImport();
        
        Attachment att = new Attachment();
        att.ParentId = ServiceInstance.getId();
        att.Body = Blob.valueOf(JSON.serialize(data));
        att.ContentType = 'application/json';
        att.Name = ServiceInstance.getAttachmentName();

        DataBase.SaveResult result = Database.Insert(att);
        if(!result.isSuccess()){
            throw new AuraHandledException(getError(result));
        }
    }

    public void endImport(){
        ServiceInstance.canImport();
        ServiceInstance.afterImport();
    }

    public void deleteAttachments(){
        Id parentId = ServiceInstance.getId();
        String attachmentName = ServiceInstance.getAttachmentName();

        List<Attachment> attachments= [SELECT Id FROM Attachment WHERE  ParentId=:parentId AND Name=:attachmentName];
        if(attachments.size() > 0){
            delete attachments;
        }
    }

    @testVisible
    static String getError(Database.SaveResult result){
        List<String> errors = new List<string>();
        errors.add('Failed to insert attachment.');
        for(Database.Error e: result.getErrors()){
            errors.add(e.getMessage());
        }
        return String.join(errors, ' ');
    }
}