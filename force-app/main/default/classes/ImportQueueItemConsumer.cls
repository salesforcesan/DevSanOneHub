public class ImportQueueItemConsumer implements IExecutor {
	static Map<String,
	       Schema.SObjectType> SObjectTypeMap;

	private DatasourceWrapper datasource;
	private String recordId;
	private List<String> errors;
	private List<List<String>> errorImportEntries;
	@testVisible
	private ImportColumn keyColumn;
	@testVisible
	private List<ImportColumn> updateColumns;

	static {
		SObjectTypeMap = Schema.getGlobalDescribe();
	}

	public ImportQueueItemConsumer() {
		errors = new List<String>();
		errorImportEntries = new List<List<String>>();
	}

	public Object getFailedContent() {
		return this.errorImportEntries;
	}

	//parameters[0]: recordId
	//parameters[1]: Datasource Schema Definition in order
	//parameters[2]: List<List<String>>
	public DBResult doExecute(Object[] parameters) {
		recordId = String.valueOf(parameters[0]);
		datasource = (DatasourceWrapper) parameters[1];
		List<List<String>> content = (List<List<String>>) parameters[2];

		//step 1: find key and updatable columns;
		findKeyUpdateColumns();

		//step 2: get all target object ID and given import target object identifier mapping
		Map<String, Sobject> importToDbIdMap = buildImportIdToDBTargetObjectIdMap(keyColumn, content);

		//step 3: do updates
		List<SObject> dataset = buildDataset(content, importToDbIdMap);
		if (dataset.isEmpty()) {
			if (errors.isEmpty()) {
				return DBResult.newInstance(0, 0, 'Jobs already updated with the expected values.');
			}
			return DBResult.error(
			         errors.size(),
			         'No valid jobs to import: ' + String.join(errors, ' '));
		}
		DBResult result;
		try{
			result = DBX.doBulkUpdate(dataset);
		} catch(Exception ex){
			findFailedContentEntries(
			  content,
			  importToDbIdMap,
			  entitiyListToSet(dataset)
			);
			return  DBResult.newInstance(0, content.size(), ex.getMessage() + ':' + ex.getStackTraceString());	
		}
		
		if (errors.isEmpty() && result.IsSucceeded()) {
			return result;
		}

		if (!result.IsSucceeded()) {
			findFailedContentEntries(
			  content,
			  importToDbIdMap,
			  (Set<String>)result.getData(DBResult.FAILED_IDS)
			);
		}

		return DBResult.newInstance(
		         result.SuccessCount,
		         result.ErrorCount + errors.size(),
		         result.Message + '. ' + String.join(errors, ' '));
	}

	Set<String> entitiyListToSet(List<SObject> entities){
		Set<String> ids = new Set<String>();
		for(Sobject obj: entities){
			ids.add(String.valueOf(obj.get('Id')));
		}

		return ids;
	}

	@testVisible
	void findFailedContentEntries(
	  List<List<String>> content,
	  Map<String, Sobject> jobNameToIds,
	  Set<String> errorIds) {

		//step 1: find all job names who failed
		if (errorIds.isEmpty()) {return;}
		Set<String> contentKeys = new Set<String>();

		for (String key : jobNameToIds.keySet()) {
			Sobject rec = (Sobject) jobNameToIds.get(key);
			if (errorIds.contains(String.valueOf(rec.get('Id')))) {
				contentKeys.add(key);
			}
		}

		//step 2: add those content row into errorImportEntries;
		for (List<String> row : content) {
			if (contentKeys.contains(row[keyColumn.index])) {
				errorImportEntries.add(row);
			}
		}
	}

	List<Sobject> buildDataset(List<List<String>> content, Map<String, Sobject> idToSobjectMap) {
		SObject target;
		Map<String, SObject> dataset = new Map<String, SObject>();
		Integer expectedColumnSize = datasource.schemas.size();
		Integer i = 0;
		String lineId;

		for (List<String> line : content) {
			i++;
			lineId = '';

			try {
				if (line.size() != expectedColumnSize) {
					lineId = (line.size() > keyColumn.Index)
					         ? line[keyColumn.index]
					         : '-';
					logError(line, i, lineId, 'Column size not matched.');
					continue;
				}

				lineId = line[keyColumn.index];
				if (idToSobjectMap.containsKey(lineId)) {
					target = (SObject) idToSobjectMap.get(lineId);
					if (tryToUpdateRecord(line, target)) {
						dataset.put(String.valueOf(target.get('Id')), target);
					}
				} else {
					logError(line, i, lineId , 'Record Not Found.');
				}
			} catch (Exception ex) {
				logError(line, i, lineId, ex.getMessage());
			}
		}

		return dataset.values();
	}

	void logError(List<String> line, Integer i, String lineKey,  String msg) {
		this.errorImportEntries.add(line);
		this.errors.add('Row' + String.valueOf(i) + ':' + lineKey + ':' + msg);
	}

	Boolean tryToUpdateRecord(List<String> line, SObject target) {
		Object value;
		Boolean hasChanged = false;
		for (ImportColumn col : updateColumns) {
			value = ImportColumn.parseValue(line[col.Index], col.DBType);
			if (value != null && value != target.get(col.DBName)) {
				hasChanged = true;
				target.put(col.DBName, value);
			}
		}
		return hasChanged;
	}

	Map<String, SObject> buildImportIdToDBTargetObjectIdMap(
	  ImportColumn keyCol, List<List<String>> content) {
		Map<String, SObject> results = new Map<String, SObject>();
		List<String> importIds = new List<String>();
		for (List<String> line : content) {
			if (String.isNotBlank(line[keyCol.index])) {
				importIds.add(line[keyCol.index]);
			}
		}
		if (importIds.isEmpty()) {
			throw new CustomException('The import data key values are missing');
		}

		String sql = SQLBuilder.newInstance(datasource.targetObject)
		             .addField(keyCol.DBName)
		             .addFields(getUpdateFields())
		             .addPredicate(keyCol.DBName + ' in :importIds')
		             .build();

		List<SObject> data = Database.query(sql);
		for (Sobject rec : data) {
			results.put(
			  String.valueOf(rec.get(keyCol.DBName)),
			  rec);
		}

		return results;
	}

	List<String> getUpdateFields() {
		List<String> fields = new List<String>();
		for (ImportColumn col : updateColumns) {
			fields.add(col.DBName);
		}
		return fields;
	}

	@testVisible
	void findKeyUpdateColumns() {
		updateColumns = new List<ImportColumn>();
		keyColumn = null;
		for (Integer i = 0; i < datasource.schemas.size(); i++) {
			DatasourceSchemaWrapper col = datasource.schemas.get(i);
			if (col.keyed == 1) {
				if (col.groupBy != 1) {
					keyColumn = ImportColumn.newInstance(i, col.field, col.dataType);
				}
			} else if (col.updatable == 1) {
				updateColumns.add(ImportColumn.newInstance(i, col.field, col.dataType));
			}
		}
		if (keyColumn == null) {
			throw new CustomException('The import schema has no target object key field specified');
		}
		if (updateColumns.isEmpty()) {
			throw new CustomException('The import schema has no updatable columns specified');
		}
	}
}