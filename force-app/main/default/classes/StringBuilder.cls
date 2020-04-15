public class StringBuilder {
	private List<String> buffer;
	private StringBuilder() {
		this.buffer = new List<String>();
	}
	
	public static StringBuilder newInstance() {
		return new StringBuilder();
	}

	public StringBuilder append(String content) {
		this.buffer.add(content);
		return this;
	}

	public StringBuilder appendIfNotNull(String label, String content) {
		if (String.isNotBlank(content)){
			this.buffer.add(label);
			this.buffer.add(content);
		}
		return this;
	}

	public String build() {
		return this.build(' ');
	}

	public String build(String separator){
		return String.join(this.buffer, separator);
	}
}