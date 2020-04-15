public with sharing class ProjectTypeHelper {
  Map<Id, ProjectTypeAttribute__c> PTAttributes{get;set;}

	public ProjectTypeHelper(Id projectTypeId) {
	      PTAttributes = new Map<Id, ProjectTypeAttribute__c>();
        List<ProjectTypeAttribute__c> ptAttrs = [SELECT Attribute__c, IsVisible__c FROM ProjectTypeAttribute__c WHERE ProjectType__c=:projectTypeId AND IsActive__c=true];
        for(ProjectTypeAttribute__c attr: ptAttrs){
            PTAttributes.put(attr.Attribute__c, attr);
        }
  }

  public Boolean IsAttributeVisible(Id attributeId){
    if (!PTAttributes.containsKey(attributeId)) {
      return false;
    }
    ProjectTypeAttribute__c ptAttr = PTAttributes.get(attributeId);
    return Boolean.valueOf(ptAttr.IsVisible__c);
  }
}