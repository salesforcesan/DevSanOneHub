public without sharing class AppClassTestFake implements IAppClass {
	public void execute(ApexJobTracker__c param) {
        QA.EQ('id1', param.Id1__c, 'id1 assigned');
        QA.EQ('id2', param.Id2__c, 'id2 assigned');
        QA.EQ('id3', param.Id3__c, 'id3 assigned');
        QA.EQ('parameters', param.Parameters__c, 'parameters assigned');
    }
}