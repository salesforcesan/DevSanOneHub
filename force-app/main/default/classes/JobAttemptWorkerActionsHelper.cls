global without sharing class JobAttemptWorkerActionsHelper {
    final static String RESULT_SUCCESS = '1';
    final static String RESULT_NOT_MATCH = '2';
    final static String RESULT_MISSING_FIELD = '3';
    final static String RESULT_ERROR = '4';

    @testVisible
    static Set<String> parseBody3PLIds(List<String> body, Integer nameIndex) {
        Set<String> ids = new Set<String>();
        for (String  row : body) {
            String[] columns = row.split(',',-1);
            ids.add( columns[nameIndex]);
        }
        return ids;
    }

    @testVisible
    static InFieldDefFinder getUpdatefieldsFinder(String updateFieldContent) {
        try {
            return InFieldDefFinder.createInstance(updateFieldContent);
        } catch (CustomException customEx) {
            throw new CustomException('Missing value for custom setting 3plImportFields. Contact Administrator.');
        }
    }
    @testVisible
    static List<JobAttemptWorker__c> find3PLWorkers(List<String> selectFields, Set<String> names) {
        String query = 'SELECT ' + String.join(selectFields, ',') +  ' FROM JobAttemptWorker__c WHERE name in :names AND My3PLWork__c = true';
        List<JobAttemptWorker__c> workers = Database.query(query);
        if (workers.isEmpty()) {
            throw new CustomException('3PL Workers Not Found. Please contact site administrator.');
        }
        return workers;
    }

    global static List<ActionResponse> update3plWorkersFromFile(List<String> thirdpartyworkerscsv) {

        List<JobAttemptWorker__c> workersToUpdate = new List<JobAttemptWorker__c>();
        String fieldstoupdate = '';
        set<String> requested3PLIds = new set<String>();
        Map<String, JobAttemptWorker__c> thirdpartyWorkerMap = new Map<String, JobAttemptWorker__c>();

        String nsprefix = Constants.CURRENTNAMESPACEPREFIX.toLowerCase();

        if (thirdpartyworkerscsv.size() == 0) {
            throw new CustomException('No 3PL Workers in the list to update. Contact Administrator.');
        }

        String thirdpartyworkerupdatefields = AppUtil.JAWImportFields == null ? '' : AppUtil.JAWImportFields;
        InFieldDefFinder updateFieldFinder = getUpdatefieldsFinder(thirdpartyworkerupdatefields);

        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType locationSchema = schemaMap.get(nsprefix + 'JobAttemptWorker__c');
        Map<String, Schema.SObjectField> fieldMap = locationSchema.getDescribe().fields.getMap();

        //parse fieldToUpdate settings
        List<String> selectFields = updateFieldFinder.getFieldNames();
        if (selectFields.isEmpty()) {
            throw new CustomException('Failed to parse update fields setting.');
        }
        selectFields.add('Id');

        Integer indexOfName = updateFieldFinder.findIndexByName('name');
        requested3PLIds = parseBody3PLIds(thirdpartyworkerscsv, indexOfName);
        workersToUpdate = find3PLWorkers(selectFields, requested3PLIds);

        for (JobAttemptWorker__c jaw : workersToUpdate) {
            thirdpartyWorkerMap.put(jaw.Name, jaw);
        }

        ResultAggregator aggregator = ResultAggregator.createInstance();
        aggregator.defineResult(RESULT_SUCCESS, 'records succeeded')
        .defineResult(RESULT_MISSING_FIELD, 'records failed with missing last name or first name')
        .defineResult(RESULT_NOT_MATCH, 'records with 3PL account not matched')
        .defineResult(RESULT_ERROR, 'records failed to save due to transaction error');
        List<JobAttemptWorker__c> rsToUpdate = new List<JobAttemptWorker__c>();
        List<InFieldDef> fields = updateFieldFinder.getFields();

        for (String thirdpartyworkercsv : thirdpartyworkerscsv) {
            if (String.isBlank(thirdpartyworkercsv)) {
                continue;
            }

            List<String> csvCells = thirdpartyworkercsv.split(',', -1);
            if (csvCells.size() < 2) {
                continue;
            }

            String rowId = csvCells[indexOfName];
            if (!thirdpartyWorkerMap.containsKey(rowId)) {
                aggregator.addValue(RESULT_NOT_MATCH, rowId);
                continue;
            }

            JobAttemptWorker__c recordToUpdate = thirdpartyWorkerMap.get(csvCells[indexOfName]);
            Integer csvCellSize = csvCells.size();
            boolean hasError = false;

            for (InFieldDef field : fields) {
                if (field.Name == 'name' ) {
                    continue;
                }

                if (field.Index >= csvCellSize) {
                    continue;
                }


                if (field.IsRequired && String.isBlank(csvCells[field.Index])) {
                    aggregator.addValue(RESULT_MISSING_FIELD, rowId);
                    hasError = true;
                    break;
                }

                Schema.DisplayType fielddataType = fieldMap.get(field.Name).getDescribe().getType();
                if (fielddataType == Schema.DisplayType.Date) {
                    recordToUpdate.put(field.Name, DateUtil.ToDate(csvCells[field.Index]));
                } else if (fielddataType == Schema.DisplayType.DateTime) {
                    recordToUpdate.put(field.Name, DateUtil.ToDateTime(csvCells[field.Index]));
                } else if (fielddataType == Schema.DisplayType.Integer) {
                    recordToUpdate.put(field.Name, Integer.ValueOf(csvCells[field.Index]));
                } else if (fielddataType == Schema.DisplayType.String) {
                    recordToUpdate.put(field.Name, string.ValueOf(csvCells[field.Index]));
                } else if (fielddataType == Schema.DisplayType.Currency) {
                    recordToUpdate.put(field.Name, Decimal.ValueOf(csvCells[field.Index]));
                } else if (fielddataType == Schema.DisplayType.Double) {
                    recordToUpdate.put(field.Name, Double.ValueOf(csvCells[field.Index]));
                }
            }

            if (!hasError) {
                rsToUpdate.add(recordToUpdate);
            }
        }

        List<ActionResponse> errors = new List<ActionResponse>();
        if (rsToUpdate.size() > 0) {
            Database.SaveResult[] results = Database.update(rsToUpdate, false);
            for (Integer i = 0; i < rsToUpdate.size(); i++) {
                Database.SaveResult result = results[i];
                String rowId = rsToUpdate[i].Name;
                if (!result.isSuccess()) {
                    for (Database.Error err : result.getErrors()) {
                        ActionResponse response = new ActionResponse(null, false, rowId + ': ' + err.getMessage() );
                        errors.add(response);
                    }
                    aggregator.addValue(RESULT_ERROR, rowId);
                } else {
                    aggregator.addValue(RESULT_SUCCESS, rowId);
                }
            }
        }
        return aggregateResponses(aggregator, errors);
    }

    @testVisible
    static List<ActionResponse> aggregateResponses(ResultAggregator aggregator, List<ActionResponse> errors) {
        List<ActionResponse> responses = new List<ActionResponse>();

        if(aggregator.getCount(RESULT_SUCCESS) > 0){
            responses.add(ActionResponse.succeeded(aggregator.getFormattedMessage(RESULT_SUCCESS)));
        }
        if (aggregator.getCount(RESULT_MISSING_FIELD) > 0) {
            responses.add(ActionResponse.failed(aggregator.getFormattedDetail(RESULT_MISSING_FIELD)));
        }
        if (aggregator.getCount(RESULT_NOT_MATCH) > 0) {
            responses.add(ActionResponse.failed(aggregator.getFormattedDetail(RESULT_NOT_MATCH)));
        }
        if (aggregator.getCount(RESULT_ERROR) > 0) {
            responses.add(ActionResponse.failed(aggregator.getFormattedDetail(RESULT_ERROR)));
        }
        if (!errors.isEmpty()) {
            responses.addAll(errors);
        }

        return responses;
    }

    @testVisible
    global static void invoke3PLImportBatch(String loggedInUser3plAgency) {

        BatchManageImportAttachments batch = new BatchManageImportAttachments(loggedInUser3plAgency, 'thirdparty');
        string batchProcessId = Database.ExecuteBatch(batch, 1);
    }

    @testVisible
    global static void unlockAccount(String user3plAgency) {
        if (String.isBlank(user3plAgency)) {
            throw new CustomException('Failed to unlock 3pl Agency: the 3pl Agency Id can not be null');
        }


        ThirdpartyAgencyRecordsLocker__c tarl = [Select Id,Account__c,BulkImportStatus__c, ApexJobName__c
                       from ThirdpartyAgencyRecordsLocker__c WHERE Account__c = :user3plAgency];
        tarl.ApexJobName__c = '';
        tarl.BulkImportStatus__c = '';
        update tarl;
    }
}