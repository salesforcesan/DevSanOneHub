public class ResultAggregator {
	private Map<String, List<String>> Keys {get; set;}
	private Map<String, String> Messages {get; set;}

	private ResultAggregator() {
		Keys = new Map<String, List<String>>();
		Messages = new Map<String, String>();
	}

	public static ResultAggregator createInstance() {
		return new ResultAggregator();
	}

	public ResultAggregator defineResult(String key, String message) {
		Messages.put(key, message);
		return this;
	}

	public ResultAggregator addValue(String key, String value) {
		List<String> values = Keys.containsKey(key)
		                      ? Keys.get(key)
		                      : new List<String>();
		values.add(value);
		Keys.put(key, values);
		return this;
	}

	Public Set<String> getKeys() {
		return Keys.keySet();
	}

	public String getMessage(String key) {
		return Messages.get(key);
	}

	public List<String> getValues(String key) {
		return Keys.get(key);
	}

	public String getValues(String key, String separator) {
		List<String> values = Keys.get(key);
		return values != null ? String.join(values, separator) : '';
	}

	public Integer getCount(String key) {
		if (Keys.containsKey(key)){
			List<String> values = (List<String>) Keys.get(key);
			return values.size();
		}
		return 0;
	}
	public Integer getTotalCount() {
		Integer count = 0;
		List<List<String>> values = (List<List<String>>) Keys.values();
		for(List<String> v: values) {
			count += v.size();
		}
		return count;
	}

	public String getFormattedMessage(String key) {
		if (Messages.containsKey(key)){
			if (Keys.containsKey(key)){
				List<String> values = Keys.get(key);
				return String.valueOf(values.size()) + ' ' + Messages.get(key);
			}
			return Messages.get(key);
		}		
		return '';
	}

	public String getFormattedDetail(String key) {
		if (Messages.containsKey(key)){
			if (Keys.containsKey(key)){
				List<String> values = Keys.get(key);
				return String.valueOf(values.size()) + ' ' + Messages.get(key) + ' ' + String.join(values, ',');
			}
			return Messages.get(key);
		}		
		return '';
	}
}