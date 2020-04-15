public without sharing  class InFieldDefFinder {
	Map<Integer, InFieldDef> Indexes {get; set;}
	Map<String, InFieldDef> Names {get; set;}

	private InFieldDefFinder(Map<Integer, InFieldDef> indexMap, Map<String, InFieldDef> nameMap ) {
		this.Indexes = indexMap;
		this.names = nameMap;
	}

	public static InFieldDefFinder createInstance(String updateFieldContent) {
		if (String.isBlank(updateFieldContent)) {
			throw new CustomException('Import Field Setting is not defined.');
		}

		InFieldDef fieldDef;
		List<String>cols;
		Map<Integer, InFieldDef> indexMap = new Map<Integer, InFieldDef>();
		Map<String, InFieldDef> nameMap = new Map<String, InFieldDef>();
		List<String> fieldContents =  updateFieldContent.toLowerCase().split(',');
		
		for (String content : fieldContents) {
			cols = content.split('-');
			fieldDef = InFieldDef.createInstance(cols[0], Integer.valueOf(cols[1]), cols.size() == 3 ? (cols[2] == '1') : false);
			indexMap.put(fieldDef.Index, fieldDef);
			nameMap.put(fieldDef.Name, fieldDef);			
		}

		return new InFieldDefFinder(indexMap, nameMap);
	}

	public List<InFieldDef> getFields() {
		return Indexes.values();
	}

	public List<String> getFieldNames() {
		List<String> fields = new List<String>();
		for (InFieldDef def : Indexes.values()) {
			fields.add(def.Name);
		}
		return fields;
	}

	public InFieldDef findByIndex(Integer index) {
		if (Indexes.containsKey(index)) {
			return Indexes.get(index);
		}
		throw new CustomException('Can not find update field by Index:' + String.valueOf(index));
	}

	public InFieldDef findByName(String name) {
		if (Names.containsKey(name)){
			return Names.get(name);
		}
	throw new CustomException('Can not find update field by name:' + name);	
	}

	public Integer findIndexByName(String name) {
		InFieldDef def = findByName(name);
		return def.Index;
	}

	public String findNameByIndex(Integer index) {
		InFieldDef def = findByIndex(index);
		return def.Name;
	}
}