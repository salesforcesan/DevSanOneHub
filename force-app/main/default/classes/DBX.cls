public without sharing class DBX {

    public static SObject doInsert(SObject record) {
        Database.SaveResult result = Database.insert(record);
        checkSaveResult(result, 'Failed to insert');
        return record;
    }

    public static SObject doUpdate(SObject record) {    
        Database.SaveResult result = Database.update(record);
        checkSaveResult(result, 'Failed to update');
        return record;
    }

    public static DBResult doBulkUpdate(List<SObject> recordset){
        Database.SaveResult[] results = Database.update(recordset);
        Integer successCount = 0;
        Integer errorCount = 0;
        Set<String> errors = new Set<String>();
        Set<String> ids = new Set<String>();

        for(Database.SaveResult result: results){
            if (result.isSuccess()){
                successCount++;
            } else {
                ids.add(String.valueOf(result.getId()));
                errorCount++;
                errors.add(genResultError(result.getErrors()));
            }
        }

        if (errorCount ==0) {
            return DBResult.succeed(successCount);
        }

        return DBResult.newInstance(successCount, errorCount, String.join(new List<String>(errors), '.'))
            .addData(dbResult.FAILED_IDS, ids);
    }

    public static void doDelete(SObject record) {
        Database.DeleteResult result = Database.delete(record);
        if (!result.isSuccess()){
            throw new AuraHandledException('Failed to delete: ' + 
                genResultError(result.getErrors()));
        }
    }

    static void checkSaveResult(Database.SaveResult dbResult, string msg) {
        if (!dbResult.isSuccess()){
            throw new AuraHandledException(msg + ': ' + genResultError(dbResult.getErrors()));
        }
    }

    public static String genResultError(Database.Error[] errors){
        List<String> result = new List<String>();
        for(Database.Error err : errors){
            result.add(err.getStatusCode() + ': ' + err.getMessage());
        }
        return String.join(result, '. ');
    }
}