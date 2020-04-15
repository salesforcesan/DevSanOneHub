public class InFieldDef {
	public Integer Index {get; private set;}
	public String Name {get; private set;}
	public Boolean IsRequired {get; private set;}

	private InFieldDef(String paramName, Integer paramIndex, Boolean paramIsRequired) {
		this.Name = paramName;
		this.Index = paramIndex;
		this.IsRequired = paramIsRequired;
	}

	public static InFieldDef createInstance(String name, Integer index, Boolean isRequired) {
		return new InFieldDef(name, index, isRequired);
	}
}