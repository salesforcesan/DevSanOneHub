public without sharing class lwcProgramController {
    
    @AuraEnabled
    public static ProgramWrapper getProgram(String recordId){
        if (String.isBlank(recordId)){
            throw new AuraHandledException('There is no program assgined.');
        }
        Program__c program = [SELECT Name from Program__c where id = :recordId limit 1];
        
        if (program == null) {
            throw new AuraHandledException('The program not found. ' + recordId);
        }

        Datasource__c datasource = [SELECT Id from Datasource__c WHERE Name like 'Import Jobs From Program%' limit 1];
        if (datasource == null){
            throw new AuraHandledException('import datasource not found: Import Jobs From Program');
        }

        DatasourceWrapper datasourceDef = DatasourceWrapper.createInstance(datasource.Id);

        List<String[]> projects = new List<String[]>();
        List<Project__c> rs= [SELECT Id,ProjectNumber__c FROM Project__c WHERE Program__c = :recordId AND Status__c in ('Planning', 'Booked', 'In Progress', 'Launched') limit 10000];
        
        if (rs.isEmpty()){
            throw new AuraHandledException('There are no projects for the given program: ' + recordId);
        }

        for(Project__c p: rs){
            projects.add(new String[]{p.ProjectNumber__c, p.Id});
        }
        
        return ProgramWrapper.newInstance(program.name, projects, datasourceDef);
    }
}