global without sharing class RecordSet {
	private List<String> pFields;
	private List<Object> pItems;
	private String pName;

	public String Name {get {
		return this.pName;
		}
	}

	public List<String> Fields {get {
		return this.pFields;
		}
	}
	public List<Object> Items {get {
		return this.pItems;
		}
	}

	public List<sObject> Rows {get;set;}

	public RecordSet(String recordName, List<String> fields) {
		this.pName = recordName;
		this.pItems = new List<Object>();
		this.pFields = new List<String>(fields);
	}

	public void Add(List<Object> record) {
		this.pItems.add(record);
	}
}