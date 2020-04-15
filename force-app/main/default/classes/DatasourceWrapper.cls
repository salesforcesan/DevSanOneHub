public with sharing class DatasourceWrapper {
    public String consumerClass {get;private set;}
    public String targetObject {get; private set;}
    @AuraEnabled
    public String id {get; private set;}
    @AuraEnabled
    public Integer chunkSize {get; private set;}
    @AuraEnabled
    public string name {get;private set;}
    @AuraEnabled
    public Integer stopImport {get; private set;} 
    @AuraEnabled
    public Integer lockProject {get;private set;}
    @AuraEnabled
    public List<String> guides {get;private set;}
    @AuraEnabled
    public List<DatasourceSchemaWrapper> schemas {get; private set;}

    private DatasourceWrapper(String id){
        this.chunkSize = getChunkSize(); 
        this.initDatasource(id);
        this.initGuides(id);
        this.initSchemas(id);
    }

    static Integer getChunkSize() {
        OrgCustomSettings__c setting = OrgCustomSettings__c.getInstance('Setting');
        return setting.DataImportChunkSize__c > 0 
            ? Integer.valueOf(setting.DataImportChunkSize__c)
            : 1000; 
    }

    public static DatasourceWrapper createInstance(String recordId) {
        return new DatasourceWrapper(recordId);
    }

    void initDatasource(String recordId) {
        Datasource__c datasource = getDatasource(recordId);
        this.id = datasource.Id;
        this.name = datasource.Name;
        this.consumerClass = datasource.ConsumerApexClass__c;
        this.targetObject = datasource.TargetObject__c;
        this.stopImport = datasource.StopImport__c ? 1 : 0;
        this.lockProject = datasource.LockProject__c ? 1 : 0; 
    }

    Datasource__c getDatasource(String recordId) {
        List<Datasource__c> dsRS = [SELECT Id, name, TargetObject__c, StopImport__c,ConsumerApexClass__c, LockProject__c from Datasource__c where Id = :recordId];
        if (dsRS.isEmpty()){
            throw new AuraHandledException('The datasource is not found:' + recordId);
        }
        return dsRS[0];
    }

    void initGuides(String datasourceId){
        List<DatasourceGuide__c> rs = [SELECT Guide__c FROM DatasourceGuide__c where Datasource__c = :datasourceId and Active__c = true ORDER BY Order__c];
        this.guides = new List<String>();
        for(DatasourceGuide__c r: rs){
            if (String.isNotBlank(r.Guide__c)){
                this.guides.add(r.Guide__c);
            }
        }
    }

    void initSchemas(String datasourceId){
        List<DatasourceSchema__c> rs = [
            SELECT 
                Title__c, 
                Field__c, 
                Key__c, 
                DataType__c,
                GroupBy__c, 
                Required__c, 
                Updatable__c 
            FROM DatasourceSchema__c 
            WHERE Datasource__c = :datasourceId ORDER BY Order__c];
        this.schemas = new List<DatasourceSchemaWrapper>();

        for(DatasourceSchema__c s: rs){
            if(String.isNotBlank(s.Title__c)){
                this.schemas.add(genColumn(s));
            }
        }

        if (this.schemas.size() < 2){
            throw new AuraHandledException('The schema is not defined. Please contact site administrator.');
        }
    }

    DatasourceSchemaWrapper genColumn(DatasourceSchema__c schema) {
        DatasourceSchemaWrapper v = new DatasourceSchemaWrapper();
        v.field = schema.Field__c;
        v.title = schema.Title__c;
        v.dataType = schema.DataType__c;
        v.required = schema.Required__c ? 1 : 0;
        v.updatable = schema.Updatable__c ? 1 : 0;
        v.groupBy = schema.GroupBy__c ? 1 : 0;
        v.keyed = schema.Key__c ? 1 : 0;
        return v;
    }
}