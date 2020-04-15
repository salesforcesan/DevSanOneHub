public with sharing class PostInstall implements installHandler {
public void onInstall(InstallContext context) {
    //fetch custom setting or create it for the first time
    NamespaceSettings__c ns = NamespaceSettings__c.getOrgDefaults();
    if (ns == null) ns = new NamespaceSettings__c();

    //ns
    ns.RawPrefix__c = CancelProjectServiceExt.class.getName().substringBefore('CancelProjectServiceExt').substringBefore('.');

    //ns.
    ns.ClassPrefix__c = CancelProjectServiceExt.class.getName().substringBefore('CancelProjectServiceExt');

    //ns__
    ns.ObjectPrefix__c = SObjectType.ProjectService__c.Name.substringBefore('ProjectService__c');

    //write the values away
    upsert ns;
}
}