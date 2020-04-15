public class ProjectType {
    public static String MD = 'Merchandising';
	public static String IE = 'Instore';        

    private static Map<String, ProjectType__c> TYPENAME_TO_TYPE = new Map<String, ProjectType__c>();

    public static Id getProjectTypeIdByName(String projectTypeName) {
    	return getProjectTypesByNames(new List<String>{ projectTypeName }).get(projectTypeName).Id;
    }

    public static Map<String, ProjectType__c> getProjectTypesByNames(List<String> projectTypeNames) {

    	Set<String> unqueriedTypes = new Set<String>();
    	for (String projectTypeName : projectTypeNames) {
    		if (!TYPENAME_TO_TYPE.containsKey(projectTypeName)) unqueriedTypes.add(projectTypeName);
    	}

    	if (!unqueriedTypes.isEmpty()) {
    		for (ProjectType__c pType : [SELECT Id, Name FROM ProjectType__c WHERE Name IN :unqueriedTypes]) TYPENAME_TO_TYPE.put(pType.Name, pType);
    	}

    	Map<String, ProjectType__c> output = new Map<String, ProjectType__c>();
    	for (String projectTypeName : projectTypeNames) {
    		if (!TYPENAME_TO_TYPE.containsKey(projectTypeName)) throw new CustomException('Project Type "' + projectTypeName + '" not found!');

    		output.put(projectTypeName, TYPENAME_TO_TYPE.get(projectTypeName));
    	}

    	return output;
    }
}