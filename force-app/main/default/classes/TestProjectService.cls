@isTest
public class TestProjectService {
    ProjectService__c ProjectServiceInstance {private get; private set;}
    Project__c Parent {private get; private set;}

    //factory pattern
    public static TestProjectService create(Project__c project){
        return new TestProjectService(project, '',false);
    }

    public static TestProjectService createForShift(Project__c project){
        return new TestProjectService(project, '',true);
    }

    public static TestProjectService create(Project__c project, String serviceId){
        return new TestProjectService(project, serviceId, false);
    }

    public static TestProjectService get(Project__c project, String projectServiceId){
        TestProjectService tService = new TestProjectService();
        tService.Parent = project;
        tService.ProjectServiceInstance = getProjectService(projectServiceId);

        return tService;
    }

    //prevent new TestProjectService()
    private TestProjectService(){}
    private TestProjectService(Project__c project,String serviceId,Boolean forShift) {
        this.Parent = project;
        this.generateProjectService(project, serviceId, forShift);
    }

    RetailerService__c getOneService(String retailerId, String serviceId, Boolean forShift){
        List<RetailerService__c> services = TestDataUtil.getRetailerServices(retailerId);
        if(String.isBlank(serviceId)){
            if(forShift){
                for(RetailerService__c rSvc: services){
                    if(rSvc.Service__r.Specialization__c == 'Shift'){
                        return rSvc;
                    }
                }
                throw new CustomException('service can not be found when creating A project service.');
            }
            return services.get(0);
        }

        for(RetailerService__c s: services){
            if(s.Service__c == serviceId){
                return s;
            }
        }
        throw new CustomException('service can not be found when creating A project service.');
    }

    void generateProjectService(Project__c project,String serviceId, Boolean forShift){
        RetailerService__c service = getOneService(project.Retailer__c,serviceId, forShift);        
        ProjectService__c ps = new ProjectService__c(
            Project__c = project.Id,
            Service__c = service.Service__c,
            ServiceTitle__c = service.Service__r.Name,
            //UniqueKey__c = TestDataUtil.genUniqeKey('psuk'),
            TargetType__c = 'Brand',
            JobManual__c = 'Standard',
            isVisibleToClient__c = true,
            NumberOfWorkers__c = 1,
            OneHubRetailerId__c = 'OH' + String.valueOf(service.Retailer__c)
        );
        insert ps;
        this.ProjectServiceInstance = getProjectService(ps.Id);
    }

    public ProjectService__c getInstance(){
        return this.ProjectServiceInstance;
    }

    public TestProjectService addAll(){
        return this.addAttributes()
            .addTarget()
            .addTool()
            .addCertificate()
            .addMaterial()
            .addSurvey();
    }

    public TestProjectService addAttributes(){
        List<ProjectServiceAttribute__c> rs = new List<ProjectServiceAttribute__c>();

        For(ServiceAttribute__c attr: TestDataUtil.getServiceAttributes(this.ProjectServiceInstance.Service__c)){
            rs.add(new ProjectServiceAttribute__c(
                ServiceAttribute__c = attr.Id,
                Attribute__c = attr.Attribute__c,
                ProjectService__c = this.ProjectServiceInstance.Id,
                Service__c = this.ProjectServiceInstance.Service__c
            ));
        }
        if(rs.size() > 0){
            insert rs;
        }
        return this;
    }
    public TestProjectService addTool(){
        return addTools(1);
    }

    public TestProjectService addTools(Integer howMany){
        List<Id> tools = TestDataUtil.getRetailerServiceTools(
            this.ProjectServiceInstance.Retailer__c, 
            this.ProjectServiceInstance.Service__c);
        Integer idx = 0;
        List<ProjectServiceEquipment__c> rs= new List<ProjectServiceEquipment__c>();
        List<String> arr = new List<String>();

        for(Id tool: tools){
            if(idx >= howMany) {break;}
            rs.add(new ProjectServiceEquipment__c(
                    ProjectService__c = this.ProjectServiceInstance.Id,
                    Equipment__c = tool,
                    Quantity__c = 1,
                    IsLocked__c = true,
                    UniqueKey__c = String.valueof(this.ProjectServiceInstance.Id) + '-' + String.valueOf(tool)
                ));
            arr.add(String.valueof(this.ProjectServiceInstance.Id) + '-' + String.valueOf(tool));
            idx++;
        }
        System.Debug(JSON.serialize(arr));
        insert rs;

        return this;
    }
    public TestProjectService addCertificate(){
        return addCertificates(1);
    }

    public TestProjectService addCertificates(Integer howMany){
        List<ProjectServiceCertification__c> rs = new List<ProjectServiceCertification__c>();
        List<Id> certs = TestDataUtil.getServiceCertifications(
            ProjectServiceInstance.Retailer__c,
            ProjectServiceInstance.Service__c);
        Integer idx = 0;

        for(Id cert: certs){
            if( idx >= howMany){break;}
            rs.add(new ProjectServiceCertification__c(
                    Certification__c = cert,
                    IsLocked__c = true,
                    ProjectService__c = ProjectServiceInstance.Id,
                    UniqueKey__c = TestDataUtil.genUniqeKey('pscert')
                ));
            idx++;
        }

        if(rs.size() == 0){
         throw new CustomException('There are no retailer service certifications setup yet.');   
        }

        insert rs;
        return this;
    }
    public TestProjectService addMaterial(){
        return addMaterials(1);
    }

    public TestProjectService addMaterials(Integer howMany) {
        Integer idx = 0;        
        List<ProjectServiceMaterial__c> rs = new List<ProjectServiceMaterial__c>();

        For(Material__c m: TestDataUtil.getMaterials()){
            if(idx >= howMany) { break; }
            rs.add(new ProjectServiceMaterial__c(
                    ProjectService__c = this.ProjectServiceInstance.Id,
                    Material__c = m.Id,
                    Quantity__c = 1,
                    MaterialDescription__c = m.Name
                ));
            idx++;
        }
        insert rs;
        return this;
    }

    public TestProjectService addTarget(){
        return addTargets(1);
    }

    public TestProjectService addTargets(Integer howMany){
        List<Target__c> targets = TestDataUtil.getTargets();
        Integer len = targets.size();
        List<ProjectServiceTarget__c> rs = new List<ProjectServiceTarget__c>();

        for(Integer i = 0; i < len; i++){
            if(i >= howMany) {break;}
            rs.add(new ProjectServiceTarget__c(
                ProjectService__c = this.ProjectServiceInstance.Id,
                Target__c = targets.get(i).Id,
                Type__c = 'Primary',
                Quantity__c = 0,
                Price__c = 0,
                YieldPerUnit__c = 0
                ));
        }
        insert rs;
        return this;
    }

    public TestProjectService addSurvey(){
        List<ProjectServiceQuestion__c> psqList = this.addSurveyQuestions();
        this.addSurveyQuestionResponses(psqList);

        return this;
    }

    List<ProjectServiceQuestion__c> addSurveyQuestions(){
        List<ProjectServiceQuestion__c> rs = new List<ProjectServiceQuestion__c>();
        List<AILabel__c> labels = TestDataUtil.getPhotoLabels();
        for(ServiceQuestion__c e:TestDataUtil.getServiceQuestions(this.ProjectServiceInstance.Service__c)){
            rs.add(new ProjectServiceQuestion__c(
                QuestionNumber__c = e.QuestionNumber__c,
                ServiceQuestion__c = true,
                IsVisibleToClient__c = e.IsVisibleToClient__c,
                Question__c = e.Question__c,
                AILabel__c = (e.QuestionType__c == 'Photo' && labels.size() > 0) ? labels[0].Id : null,
                ProjectService__c = this.ProjectServiceInstance.Id,
                UniqueKey__c = TestDataUtil.genUniqeKey('psq')
                ));
        }

        insert rs;
        return rs;
    }

    void AddSurveyQuestionResponses(List<ProjectServiceQuestion__c> questions){
        List<ServiceQuestionDefinedResponse__c> psqrList = TestDataUtil.getServiceQuestionResponses(this.ProjectServiceInstance.Service__c);
        List<SObject> rs = new List<SObject>();

        for(ProjectServiceQuestion__c sQ: questions){
            for(ServiceQuestionDefinedResponse__c sA: psqrList){
                if (sA.ServiceQuestion__r.Question__c == sQ.Question__c){
                    rs.add(new ProjectServiceQuestionDefinedResponse__c(
                        Active__c = true,
                        CanRemove__c = true,
                        Optional__c = true,
                        ProjectServiceQuestion__c = sQ.Id,
                        QuestionDefinedResponse__c = sA.QuestionDefinedResponse__c
                    ));
                }
            }
        }
        if(rs.size() > 0) {
            insert rs;
        }
    }

    public static ProjectService__c getProjectService(Id psId){
         return Database.query(
            TestUtil.genQuery('ProjectService__c') + ' WHERE Id=:psId'
            );
    }

    public static List<ProjectServiceMaterial__c> getMaterials(Id projectService){
        return (List<ProjectServiceMaterial__c>) getRelatedList('ProjectServiceMaterial__c', projectService);
    }

    public static List<ProjectServiceTarget__c> getTargets(Id projectService){
        return (List<ProjectServiceTarget__c>) getRelatedList('ProjectServiceTarget__c', projectService);
    }

    public static List<ProjectServiceCertification__c> getCertificates(Id projectService){
        return (List<ProjectServiceCertification__c>) getRelatedList('ProjectServiceCertification__c', projectService);
    }

    public Static List<ProjectServiceEquipment__c> getTools(Id projectService){
        return (List<ProjectServiceEquipment__c>) getRelatedList('ProjectServiceEquipment__c', projectService);
    }

    public static List<ProjectServiceQuestion__c> getQuestions(Id projectService){
        return (List<ProjectServiceQuestion__c>) getRelatedList('ProjectServiceQuestion__c', projectService);
    }
    public static List<ProjectServiceAttribute__c> getAttributes(Id projectServiceId){
        return (List<ProjectServiceAttribute__c>) getRelatedList('ProjectServiceAttribute__c', projectServiceId);
    }

    public static List<ProjectServiceQuestionDefinedResponse__c> getQuestionResponses(Id projectService){
        return Database.query(
            TestUtil.genQuery('ProjectServiceQuestionDefinedResponse__c') + ' WHERE ProjectServiceQuestion__r.ProjectService__c=:projectService'
            );
    }

    static List<Sobject> getRelatedList(String sObjectType, Id projectService){
        return Database.query(
            TestUtil.genQuery(sObjectType) + ' WHERE ProjectService__c=:projectService'
            );
    }
}