public class AttachmentTriggerHandler extends TriggerHandler{

    public override void afterInsert(){
        
        if (TriggerUtil.skipAttachmentTrigger) return;
        
        List<Id> parentIds=new List<Id>();                        
        
        String objectTypes = AppUtil.FileTypeCheckRequiredObjects != null ? AppUtil.FileTypeCheckRequiredObjects : '';//'ProjectServiceAttribute__c, Opportunity';
        String fileTypes = AppUtil.AllowedFileType != null ? AppUtil.AllowedFileType : '';//'pdf, jpg, png, txt, gif';
        
        system.debug(':::'+ objectTypes + '~~~'+ fileTypes);
        List<String> objectTypeList = new List<String>();
        List<String> fileTypesList = new List<String>();        
        
        for(string str: objectTypes.split(',')){
            objectTypeList.add(str.trim());
        }
        
        for(string str: fileTypes.split(',')){
            fileTypesList.add(str.trim());
        }        
        
        List<Attachment> attachmentList = [Select ID,Name, Parent.Type,ContentType from attachment where id in: trigger.newMap.keySet()];
        Map<String,Attachment> attachmentMap = new Map<String,Attachment>();
        
        for(Attachment att : attachmentList){
            attachmentMap.put(att.Id, att);
        }
        
        for(Attachment obj :(List<Attachment>)Trigger.new){
            
            Attachment att = attachmentMap.get(obj.Id);
            if(objectTypeList.Contains(att.Parent.Type) && (!(fileTypes.Contains(att.Name.substringAfter('.')))))
            {
                obj.addError('Upload Failed: Your file type must be one of: ' + fileTypes);
            }            
        }
        
    }

 	

}