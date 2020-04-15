public class ImportColumn {
	public String DBType{get; private set;}
	public String DBName {get; private set;}
	public Integer Index {get; private set;}
 
	private ImportColumn(Integer position, String name, String dataType) {
		DBName = SQLBuilder.namespacify(name);
		Index = position;
		DBType = dataType;
	}

	public static ImportColumn newInstance(Integer position, String name, String dataType) {
		return new ImportColumn(position, name, dataType);
	}

	public static Object parseValue(String value, String valueType) {
		if(String.isBlank(value)){
			return null;
		}

		//Date, DateTime, Float, Number, Text, Time
		switch on valueType {
			when 'Date' {
				return parseDateString(value);
			}
			when 'DateTime' {
				return Datetime.parse(value);
			}
			when 'Float' {
				return Double.valueOf(value);
			}
			when 'Number' {
				return Integer.valueOf(value);
			}
			when 'Text' {
				return String.valueOf(value);
			}
			when 'Time' {
				return parseTimeString(value);
			}
			when 'Boolean' {
				return Boolean.valueOf(value);
			}
			when else {
				throw new CustomException('Invalid DateType: ' + valueType);				
			}
		}
	}

	public static Date parseDateString(String value){
		RegExEngine engine = RegExEngine.getInstance('date', RegExEngine.DatePattern);
		if (!engine.matches(value)){
			throw new CustomException('Invalid Date:' + value);
		}

		if (value.indexOf('-') != -1){
			return stringToDate(value);
		}

		return Date.parse(value);
	}

	private static Date stringToDate(String valueWithHyphen){
		String[] arr = valueWithHyphen.split('\\-');	
		if (arr.size() != 3){
			throw new CustomException('Invalid Date:' + valueWithHyphen);
		}
		return Date.parse(arr[1] + '/' + arr[2] + '/' + arr[0]);
	}


	private static String parseTimeString(String value){
		RegExEngine engine = RegExEngine.getInstance('time', RegExEngine.TimePattern);
		if (!engine.matches(value)){
			throw new CustomException('Invalid Time:' + value);
		}
		return value;
	}
}