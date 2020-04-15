public class SQLBuilder {
	private String tableName;
	private Set<String> fields;
	private Set<String> clauses;

	private SQLBuilder(String sobjectName) {
		tableName = namespacify(sobjectName);
		fields = new Set<String>();
		fields.add('Id');
		clauses = new Set<String>();
	}

	public static SQLBuilder newInstance(String objName) {
		return new SQLBuilder(objName);
	}

	public static String namespacify(String fieldName) {
		String field = fieldName + '';

		if (field.indexOfIgnoreCase('__c') == -1 || field.indexOfIgnoreCase(Reflection.AppNameSpace) != -1) {
			return field;
		}
		return CONSTANTS.CURRENTNAMESPACEPREFIX + field;
	}

	public SQLBuilder addField(String fieldName) {
		fields.add(namespacify(fieldName));
		return this;
	}

	public SQLBuilder addFields(String[] fieldNames){
		for(String fieldName: fieldNames){
			fields.add(namespacify(fieldName));
		}
		return this;
	}

	public SQLBuilder addPredicate(String condition) {
		clauses.add(condition);
		return this;
	}

	public String build() {
		List<String> sql = new List<String>();
		sql.add('SELECT');
		sql.add(String.join(new List<String>(fields), ','));
		sql.add('FROM');
		sql.add(tableName);
		if (!clauses.isEmpty()){
			sql.add('WHERE');
			sql.add(String.join(new List<String>(clauses), ' AND '));
		}
		return String.join(sql, ' ');
	}
}