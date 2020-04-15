public class ProgramWrapper {
    @AuraEnabled
    public String name {get; private set;}
    @AuraEnabled
    public List<String[]> projects {get; private set;}
    @AuraEnabled 
    public DatasourceWrapper datasource {get; private set;}

    private ProgramWrapper(String name, List<String[]> projects, DatasourceWrapper datasource) {
        this.name = name;
        this.projects = projects;
        this.datasource = datasource;
    }

    public static ProgramWrapper newInstance(String name, List<String[]> projects, DatasourceWrapper datasource){
        return new ProgramWrapper(name, projects, datasource);
    }
}