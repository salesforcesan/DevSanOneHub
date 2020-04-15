public class DBResult {
	public static final String FAILED_IDS = 'DB_FAILED_IDS';
	private String resultId;
	public Integer SuccessCount {get; private set;}
	public Integer ErrorCount {get; private set;}
	public String Message {get; private set;}
	private Map<String,Object> Value {get; private set;}

	public Boolean IsSucceeded() {
		return ErrorCount == 0;
	}

	private DBResult(Integer success, Integer errors, String msg) {
		SuccessCount = success;
		ErrorCount = errors;
		Message = msg;
		Value = new Map<String,Object>();
	}

	public DBResult setId(String oId){
		resultId =oId;
		return this;
	}

	public String getId() {
		return resultId;
	}

	public DBResult addData(String key, Object data) {
		Value.put(key, data);
		return this;
	}

	public Object getData(String key) {
		return Value.get(key);
	}

	public static DBResult newInstance(Integer success, Integer errors, String msg) {
		return new DBResult(success, errors, msg);
	}

	public static DBResult succeed(Integer success) {
		return new DBResult(success, 0, null);
	}

	public static DBResult error(Integer errors, String msg){
		return new DBResult(0, errors, msg);
	}
}