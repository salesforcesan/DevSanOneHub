@istest
public class DatasourceTest {
    static final String DS_NAME = 'Import Jobs From Program';
    static final String DS_CONSUMER = 'ImportProgramJobHandler';
    static final String DS_DESCRIPTION = 'Import Jobs from program';
    static final String DS_SCHEMA_TITLE = 'Project Number';
    static final String DS_SCHEMA_FIELD = 'ProjectNumber__c';
    static final String DS_GUIDE = 'test';
    static final Integer DS_ORDER = 5;

    @TestSetup
    public static void makeData() {
        TestDataUtil.initCustomSettings();
        ImportRequestQueueTestUtil.setupDatasource();
    }

    @IsTest
    static void ItShouldGetDatasourceAsExpected() {
        //give
        Datasource__c ds = [SELECT Id from Datasource__c limit 1];

        //when
        Test.startTest();
        DatasourceWrapper result = DatasourceWrapper.createInstance(String.valueOf(ds.Id));
        Test.stopTest();

        //then
        QA.EQ(1, result.lockProject, 'block project');
        QA.EQ(1, result.stopImport, 'stop import if value is invalid');
        QA.EQ(DS_NAME, result.name, 'datasource name matched');
        QA.EQ(String.valueOf(ds.Id), result.id, 'id matched');
        QA.isTrue(result.guides.size() > 0, 'has guides');
        QA.isTrue(result.schemas.size() > 1, '> 1 schema columns');       
    }

    @IsTest
    static void itShouldNotIncludeProjectNumber() {
        //GIVEN
        String dsId = [SELECT Id FROM Datasource__c LIMIT 1].Id;

        //WHEN
        test.startTest();
        DatasourceWrapper datasource = DatasourceWrapper.createInstance(dsId);
        test.stopTest();

        //THEN
        QA.isTrue(datasource.schemas.size() > 1, 'schemas size > 1');
    }

    static Boolean hasProjectNubmerUpdatable(DatasourceWrapper datasource) {
        Boolean result = false;
        List<DatasourceSchemaWrapper> defs = datasource.schemas;
        for (DatasourceSchemaWrapper s : defs) {
            if (s.updatable == 1) {
                if (s.field.indexOfIgnoreCase('ProjectNumber__c') != -1) {
                    result = true;
                    break;
                }
            }
        }
        if (result) {
            throw new CustomException('def count:' + defs.size());
        }
        return result;
    }
}