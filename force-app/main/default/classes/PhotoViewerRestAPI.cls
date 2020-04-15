@RestResource(urlMapping='/photohasher/*')
global with sharing class PhotoViewerRestAPI {

    @HttpPatch
    global static void updateHashes(List<Map<String,String>> query){
        List<String> rec;
        try{
            if(query == null || query.size() == 0){
                setResponse(200, createMessageResponse(false, 'The query is empty.'));
                return;
            }

            Map<Id, List<String>> request = normalizeRequest(query);
            Set<Id> ids = request.keySet();
            List<JobImage__c> images = [SELECT Id, PhotoHash__c, PoorQualityCheck__c, IsErrored__c, ErrorMessage__c FROM JobImage__c WHERE Id IN :ids];

            if(images.size() == 0){
                setResponse(200, genResult(0,0,'The jobimage records not found.'));
                return;
            }

            for(JobImage__c img: images){
                rec = request.get(img.Id);
                img.PhotoHash__c = rec[0];
                img.ErrorMessage__c  = rec[1];
                img.IsErrored__c = String.isNotEmpty(rec[1]);
                if(img.IsErrored__c == true){
                    img.PoorQualityCheck__c = true;
                }
            }

            Database.SaveResult[] results = Database.update(images);
            setResponse(200, createResult(results));
        }
        catch(CustomException custEx){
            setResponse(200, genResult(0,0, custEx.getMessage()));
        }
        catch(Exception ex)
        {
            setResponse(200, genResult(0,0, ex.getStackTraceString()));
        }

    }

    static Map<String,Object> createResult(Database.SaveResult[] sResults){
        Map<String,Object> result = new Map<String,Object>();
        integer okCount = 0, errorCount = 0;
        List<String> errors = new List<String>();

        for(Database.SaveResult sResult: sResults){
            if(sResult.isSuccess()){
                okCount++;
            } else {
                errorCount++;
                errors.add(AppUtil.genSaveResultError(sResult));
            }
        }

        return genResult(okCount, errorCount, String.join(errors, ' '));
    }

    static Map<String,Object> genResult(integer okCount, integer errCount, String errMsg){
        Map<String,Object> result = new Map<String,Object>();
        result.put('success', okCount);
        result.put('error', errCount);
        result.put('detail', errMsg);
        return result;
    }

    static Map<Id, List<String>> normalizeRequest(List<Map<String,String>> query){
        try{
            List<String> rec;
            Map<Id, List<string>> rs = new Map<Id, List<string>>();
            for(Map<String,String> req: query){
                if(String.isNotEmpty(req.get('id')) && (String.isNotEmpty(req.get('hash')) || String.isNotEmpty(req.get('error')))){
                    rec = new List<String>();
                    rec.add(String.isNotEmpty(req.get('hash')) ? req.get('hash') : '');
                    rec.add(String.isNotEmpty(req.get('error')) ? req.get('error'): '');
                    rs.put(req.get('id'), rec);
                }
            }
            return rs;
        }
        catch(Exception ex){
            throw new CustomException('OH: Failed to parse the query. The job image id might have invalid value.');
        }
    }

    static Map<String,Object> createMessageResponse(boolean status, String msg){
        Map<String,Object> item= new Map<String,Object>();
        item.put('status',status);
        item.put('value', msg);
        return item;
    }


    static void setResponse(integer status, Object body){
        RestResponse res = RestContext.response;
        res.statusCode = status;
        res.responseBody = toBlob(body);
    }

    static Blob toBlob(Object value){
        return Blob.valueOf(JSON.serialize(value));
    }
}