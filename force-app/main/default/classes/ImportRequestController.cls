public without sharing class ImportRequestController {

    @auraEnabled
    public static Map<String,Object> getImportSettings(string query){
        try{
            ImportRequest request = toRequest(query);
            return newModel(request)
                .getImportSettings();
        }  catch(DmlException dml){
            throw new AuraHandledException(genDMLMessage(dml));
        }
        catch(AuraHandledException aura){
            throw aura;
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getStackTraceString());
        }   
        
    }

    @auraEnabled
    public static void rollbackImportData(string query){
        try{
            ImportRequestModel m = newModel(toRequest(query));
            m.deleteAttachments();
        }
        catch(DmlException dml){
            throw new AuraHandledException(genDMLMessage(dml));
        }
        catch(AuraHandledException aura){
            throw aura;
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getStackTraceString());
        }   
    }

    @auraEnabled
    public static void importData(String query)
    {
        try{
            ImportRequest request = toRequest(query);
            ImportRequestModel m = newModel(request);
            
            if(request.StartImport == 1){
                m.startImport();
            }

            m.importData(request.Data);
            
            if(request.EndImport == 1){
                m.endImport();
            }
        }
        catch(DmlException dml){
            throw new AuraHandledException(genDMLMessage(dml));
        }
        catch(AuraHandledException aura){
            throw aura;
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getStackTraceString());
        }
    }

    @testVisible
    static ImportRequest toRequest (String query){
        return (ImportRequest) JSON.deserialize(query, Type.forName(CONSTANTS.CURRENTNAMESPACE, 'ImportRequest'));
    }

    @testVisible
    static ImportRequestModel newModel(ImportRequest request) {
        IImportRequestService svc = (IImportRequestService) type.forName(CONSTANTS.CURRENTNAMESPACE, request.ServiceName).newInstance();
        svc.init(request.ParentId, request.AttachmentName, request.JobName);
        return new ImportRequestModel(svc);
    }

    @testVisible
    static string genDMLMessage(DmlException dml){
        List<String> msgs = new List<String>();
        for(Integer i=0; i < dml.getNumDml(); i++){
            msgs.add(dml.getDmlMessage(i));
        }
        return String.join(msgs, '. ');
    }
}