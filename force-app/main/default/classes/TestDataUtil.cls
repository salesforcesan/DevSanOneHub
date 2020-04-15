//used to setup master data for unit tests. These data is based on Master Dataset.
@isTest
public class TestDataUtil {
    private static final String CURRENTNAMESPACE = CONSTANTS.class.getName().substringBefore('CONSTANTS').removeEnd('.');
    public static final String SystemNameSpace = (String.isEmpty(CURRENTNAMESPACE)) ? '' : CURRENTNAMESPACE + '__';

    static Integer IdIndex = 0;
    static Map<String, Schema.SObjectType> SObjectTypeMap;
    public static Date CurrentDateInstance;
    public static Datetime CurrentDateTimeInstance;
    public static Integer MaxCountSmall;
    public static Integer MaxCountMedium;
    public static Integer MaxCountLarge;
    public static List<String> LocationNames;

    static {
        SObjectTypeMap = Schema.getGlobalDescribe();
        CurrentDateTimeInstance = Datetime.now();
        CurrentDateInstance = Datetime.now().Date();
        MaxCountSmall = 5;
        MaxCountMedium = 50;
        MaxCountLarge = 500;
        LocationNames = new List<String> {'Dallas', 'Plano', 'Irving', 'Frisco', 'Allen'};
    }

    static Boolean isInitialized() {
        OrgCustomSettings__c setting = OrgCustomSettings__c.getInstance('Setting');
        return setting != null;
    }

    public static void initImageServiceSettings() {
        ImageServiceSettings__c s = new ImageServiceSettings__c();
        s.URL__c = 'https://test.com';
        s.UserName__c = 'test';
        s.Password__c = 'test';
        s.Name = 'ImageService';
        insert s;
    }

    public static void initCustomSettings() {

        ProjectTypeCustomSettings__c isSetting = new ProjectTypeCustomSettings__c ();
        isSetting.Name = ProjectType.MD;
        isSetting.SchedulingStrategyClass__c = 'BaseSchedulingStrategy';
        isSetting.FieldSetName__c = 'InStoreDemoSamplingFieldSet';
        isSetting.ProjectCompletionStrategyClass__c = 'BaseProjectCompletionStrategy';
        isSetting.ReReserveTrackFieldList__c = 'Name;Overview__c;SalesGoal__c;BudgetedLocationsCount__c;StartDate__c;EndDate__c;ResponsibleForExecution__c;Group__c;Subgroup__c';
        insert isSetting;

        OrgCustomSettings__c orgSetting = new OrgCustomSettings__c();
        orgSetting.Name = 'Setting';
        orgSetting.OrgInstanceName__c = 'WALGREENS';
        orgSetting.ClosedProjectRetentionDays__c = 30;
        orgSetting.ClosedProjectPendingArchiveDays__c = 30;
        orgSetting.LocationSearchField__c = 'OneHubLocationId__c';
        orgSetting.LocationReportUrl__c = '/one/one.app#/sObject/00O11000000GbvR/view?t=1492800857517&fv0={ProjectNumber}';
        orgSetting.ExportJobReportUrl__c = '/one/one.app#/sObject/00O11000000GbvR/view?t=1492800857517&fv0={ProjectNumber}';
        orgSetting.JobImportChunkSize__c = 5;
        orgSetting.JobImportFields__c = namifyImportFields('Name-0,NumberOfWorkers__c-8,JobScheduledDate__c-9,JobStartTime__c-10,PurchaseOverRideAmount__c-11,EstimatedMinutesOverride__c-12');
        orgSetting.JobImportTitle__c = 'Job ID,Project Service,Project Location,Service Title,Location ID,Location Number,State,City,Number of Workers,Scheduled Date,Start Time,Purchase Amount,Time Estimate (Minutes)';

        orgSetting.LocationImportTitle__c = 'Project Location: Location ID,Location #,Location Name,Address,City,State/Province/Region,Postal Code,Status,Status Comments,Executed,Executed Date,Execution Company,Location Scheduled Date, 3PL Agency ContactId, Project Number';
        orgSetting.LocationImportFields__c = namifyImportFields('Name-0,LocationScheduledDate__c-12,OneHubThirdPartyAgencyContactId__c-13');

        orgSetting.PhotoViewerPageSize__c = 50;
        orgSetting.JAWImportFields__c = namifyImportFields(
                                            'Name-0,ECWorkerId__c-1,FirstName__c-2,LastName__c-3,ThirdPartyAgencyStatus__c-6,ECWorkerTime__c-14');
        orgSetting.JAWImportTitle_c__c = ' Job Attempt Worker Name,EC Worker Id,First Name,Last Name,Project Number,Project Title,3PL Status,Estimated Minutes,Location Number,Location Name,Location Address,Location City,LocationState,Start Time,EC Worker Time';
        orgSetting.LocationImportChunkSize__c = 5000;
        orgSetting.ErrorNotificationEmail__c = 'no.reply@crossmark.com';
        orgSetting.NonClosedShiftEmailTemplate__c = 'non_closed_shift_email_template';
        orgSetting.BatchNumberofJobImages__c = 1000;
        //used by import job from program
        orgSetting.DataImportChunkSize__c = 5;
        orgSetting.MaxProjectsPerWakeup__c = 50;
        insert orgSetting;

        ImageServiceSettings__c  img = new ImageServiceSettings__c();
        img.Name = 'ImageService';
        img.Password__c = 'P@ssword1';
        img.URL__c = 'https://api.crossmark.com/ImageService/PlanningSoln';
        img.Password__c = 'external\\m3.testing';
        insert img;

        BirstSetting__c bs = new BirstSetting__c();
        bs.PermissionSetName__c = 'Default';
        bs.CollectionName__c = 'Corporate Manager';
        bs.Priority__c = 1;
        bs.DashBoardName__c = 'Region Field Analysis';
        bs.SpaceID__c = '8b30316a-61c9-4695-8c46-08a72aa9b421';
        insert bs;
    }

    public static OrgCustomSettings__c getOrgCustomSettings() {
        return OrgCustomSettings__c.getInstance('Setting');
        //return (OrgCustomSettings__c) Database.query(TestUtil.genQuery('OrgCustomSettings__c')).get(0);
    }

    public static void init() {
        RecordSet accounts, postCodes, locations,
                  fulfillments, services, attributes, questions,
                  serviceQuestions, responses, certifications, equipments;
        SObject retailer, projectType;

        if (isInitialized()) {
            return;
        }
        initDatasource();
        initDRecoverySettings();
        initCustomSettings();
        postCodes = initPostCodes();
        accounts = initAccounts();
        initContacts(accounts);
        initLanguages();
        initExceptionCodes();
        retailer = initRetailers();
        projectType = initProjectType();
        initCycles(retailer);
        initProjectScheduleOptions();
        initProjectTypeCustomSettings();
        equipments = initEquipments();
        locations = initLocations(retailer, postCodes);
        initLocationAssignments(accounts, projectType, locations);
        certifications = initCertificates();
        initTargets(retailer);
        fulfillments = initFulfillments(retailer);
        initMaterials(retailer, fulfillments);
        services = initServices();
        initServiceExceptions();
        initProjectTypeServices(projectType, services);
        initRetailerServices(retailer, services);
        questions = initQuestions();
        responses = initQuestionResponses(questions);
        attributes = initAttributes();
        initAISetup(services);
        initProjectTypeAttributes(projectType, attributes);
        initServiceAttributes(services, attributes);
        serviceQuestions = initServiceQuestions(services, questions);
        initServiceQuestionResponses(serviceQuestions, responses);
        initRetailerServiceEquipments(retailer, services, equipments);
        initRetailerServiceCertifications(retailer, services, certifications);
        initSurveyPhotoViewerSetting();
    }

    public static String genUniqeKey(String prefix) {
        return prefix + string.valueOf(Crypto.getRandomLong());
    }

//---init SurveyPhotoViewerSetting----

    static void initDRecoverySettings() {
        DRecoverySettings__c dr = new DRecoverySettings__c(
            DRMode__c = false
        );
        insert dr;
    }

    static void initSurveyPhotoViewerSetting() {
        SurveyPhotoViewerSetting__c s = new SurveyPhotoViewerSetting__c();
        s.iv__c = '1234567890123456';
        s.key__c = '1956976885228709';
        insert s;
    }

//---- init exception codes ----

    static void initExceptionCodes() {
        RecordSet rs = new RecordSet();
        rs.add(newExceptionCode('Other', 'OTHER'));
        rs.add(newExceptionCode('Manager Refused', 'MGRRF'));
        rs.doInsert();
    }

    static SObject newExceptionCode(String name, String code) {
        SObject exCode = createSObject('Exception__c');
        setFieldNoNamespace(exCode, 'Name', name);
        setField(exCode, 'ExceptionCode__c', code);
        return exCode;
    }

//---- init postcodes ----
    static RecordSet initPostCodes() {
        RecordSet rs = new RecordSet();
        rs.add(newPostCode(false,
                           '94127',
                           -8,
                           37.7357008082887,
                           -122.45947227415));
        rs.add(newPostCode(
                   false,
                   '75024',
                   -6,
                   33.07737,
                   -96.80700));
        rs.doInsert();
        return rs;
    }

    static SObject newPostCode(Boolean isDst, String name, Integer timezoneOffset,
                               Decimal latitude, Decimal longitude) {
        SObject post = createSObject('PostalCode__c');
        setField(post, 'DST__c', isDst);
        setFieldNoNamespace(post, 'Name', name);
        setField(post, 'TimezoneOffset__c', timezoneOffset);
        setField(post, 'GeoLocation__latitude__s', latitude);
        setField(post, 'GeoLocation__longitude__s', longitude);
        return post;
    }

//---- init accounts ----
    static RecordSet initAccounts() {
        String name1 = 'Crossmark, Inc.';
        String name2 = 'Premium Retail Services Inc.';
        RecordSet rs = new RecordSet();

        rs.add(newAccount(name1, true));
        rs.add(newAccount(name2, true));
        rs.doInsert();
        return rs;
    }

    static Account newAccount(String name, Boolean isActive) {
        return new Account(
                   Name = name,
                   IsApproved__c = true,
                   CanRequestProjects__c = true,
                   RecordType = new RecordType(
            name = 'Execution Company')
               );
    }

    public static Account getAccount() {
        return [SELECT Id, Name, IsApproved__c, CanRequestProjects__c
                FROM Account LIMIT 1];
    }

    public static List<Account> getAccounts() {
        return [SELECT Id FROM Account];
    }


//---- init contacts ----
    static void initContacts(RecordSet accounts) {
        RecordSet rs = new RecordSet();
        rs.add(newContact(
                   'John',
                   'Kerry',
                   'contact_id_0',
                   'Active',
                   (Account)accounts.Records.get(0)));
        rs.add(newContact(
                   'Bob',
                   'Dole',
                   'contact_id_1',
                   'Active',
                   (Account)accounts.Records.get(1)));

        for (Integer i = 2; i < 12; i++) {
            String suffix = String.valueOf(i);
            rs.add(newContact(
                       'fname' + suffix,
                       'lname' + suffix,
                       'contact_id_' + suffix,
                       'Active',
                       (Account)accounts.Records.get(math.mod(i, 2))
                   ));
        }

        rs.doInsert();
    }

    static Contact newContact(
        String firstName,
        String lastName,
        String contactId,
        String status,
        Account account) {
        Contact contact = new Contact();
        contact.FirstName = firstName;
        contact.LastName = lastName;
        contact.ContactId__c = contactId;
        contact.Status__c = status;
        contact.User__c = UserInfo.getUserId();
        contact.Email = firstName + '.' + lastName + '@test.com';
        contact.Account = account;
        return contact;
    }

//---- init languages ----
    static void initLanguages() {
        SObject lang = createSObject('Language__c');
        setFieldNoNamespace(lang, 'Name', 'English');
        insert lang;
    }

//---- init retailers ----
    static SObject initRetailers() {
        SObject r = createSObject('Retailer__c');
        setFieldNoNamespace(r, 'Name', 'Walgreens');
        setField(r, 'OneHubRetailerId__c', 'WALGREENS');
        setField(r, 'JobCancelLeadTime__c', 1);
        setField(r, 'ProjectCancelLeadTime__c', 1);
        setField(r, 'TargetAcquiredDefault__c', 'Purchased');
        setField(r, 'IsMaterialReqd__c', true);
        insert r;
        return r;
    }

    public static Retailer__c getRetailer() {
        return [SELECT Id, Name, OneHubRetailerId__c, JobCancelLeadTime__c, ProjectCancelLeadTime__c,
                TargetAcquiredDefault__c, IsMaterialReqd__c FROM Retailer__c limit 1];
    }


//---- init project type ----
    static SObject initProjectType() {
        SObject pType = createSObject('ProjectType__c');
        setFieldNoNamespace(pType, 'Name', ProjectType.MD);
        setField(pType, 'MinServiceCount__c', 1);
        setField(pType, 'MaxServiceCount__c', 5);
        setField(pType, 'GracePeriodDuration__c', 0);
        setField(pType, 'JobCancelLeadTime__c', 0);
        setField(pType, 'LaunchLeadTime__c', 0);
        setField(pType, 'CreateInvoice__c', true);
        insert pType;
        return pType;
    }

    public static ProjectType__c getProjectType(String name) {

        return String.isBlank(name) ?
               [SELECT Id, MinServiceCount__c, JobCancelLeadTime__c, MaxServiceCount__c, GracePeriodDuration__c, LaunchLeadTime__c
                FROM ProjectType__c LIMIT 1]
               : [SELECT Id, MinServiceCount__c, MaxServiceCount__c, GracePeriodDuration__c, LaunchLeadTime__c
                  FROM ProjectType__c WHERE Name = :name LIMIT 1];
    }

//---- init project type attributes ----
    static void initProjectTypeAttributes(SObject ptype, Recordset attributes) {
        RecordSet rs = new RecordSet();
        for (SObject attribute : attributes.Records) {
            rs.add(newProjectTypeAttribute(ptype.Id, attribute.Id));
        }
        rs.doInsert();
    }

    static ProjectTypeAttribute__c newProjectTypeAttribute(Id ptId, id attrId) {
        return new ProjectTypeAttribute__c(
                   ProjectType__c = ptId,
                   Attribute__c = attrId,
                   IsActive__c = true,
                   IsVisible__c  = true
               );
    }

    public static List<ProjectTypeAttribute__c> getProjectTypeAttributes(Id projectType) {
        return [
                   SELECT
                   Id,
                   Attribute__c,
                   ProjectType__c,
                   AttributeValue__c
                   FROM ProjectTypeAttribute__c
                   WHERE ProjectType__c = :projectType
               ];
    }

//---- init cycles ----
    static void initCycles(SObject retailer) {
        RecordSet rs = new RecordSet();
        ID retailerId = (ID)retailer.get('Id');

        for (Integer i = 0; i < MaxCountSmall; i++) {
            rs.add(newCycle(i, retailerId));
        }
        rs.doInsert();
    }
    static SObject newCycle(Integer index, ID retailerId) {
        SObject cycle = createSObject('Cycle__c');
        setFieldNoNamespace(cycle, 'Name', 'Cycle' + String.valueOf(index));
        setField(cycle, 'CycleStartDate__c', CurrentDateInstance);
        setField(cycle, 'CycleEndDate__c', CurrentDateInstance.addDays(index));
        setField(cycle, 'Retailer__c', retailerId);

        return cycle;
    }

//---- init Project Schedule Options ----
    static void initProjectScheduleOptions() {
        RecordSet rs = new RecordSet();
        String nameEC = 'EC',
               nameSys = 'SYSTEM',
               nameUser = 'USER';

        rs.add(newScheduleOption(nameEC));
        rs.add(newScheduleOption(nameSys));
        rs.add(newScheduleOption(nameUser));

        rs.doInsert();
    }
    static SObject newScheduleOption(String name) {
        SObject record = createSObject('ScheduleOption__c');
        setFieldNoNamespace(record, 'Name', name);
        setField(record, 'IsActive__c', true);
        setField(record, 'Code__c', name);
        return record;
    }

    public static ScheduleOption__c getProjectScheduleOption() {
        return [SELECT Id, Name, Code__c FROM ScheduleOption__c
                WHERE IsActive__c = True AND Name = 'USER' LIMIT 1];
    }

    public static ScheduleOption__c getScheduleOptionByCode(string code) {
        return [SELECT Id, Name, Code__c FROM ScheduleOption__c
                WHERE IsActive__c = True AND Code__c = :code LIMIT 1];
    }

//---- init ProjectTypeCustomSettings ----
    static void initProjectTypeCustomSettings() {
        SObject settings = createSObject('ProjectTypeCustomSettings__c');
        setFieldNoNamespace(settings, 'Name', 'Merchandising');
        setField(settings, 'SchedulingStrategyClass__c', 'BaseSchedulingStrategy');
        setField(settings, 'FieldSetName__c', 'BaseProjectFieldset');
        setField(settings, 'ProjectCompletionStrategyClass__c', 'BaseProjectCompletionStrategy');
        setField(settings, 'ReReserveTrackFieldList__c',
                 'BudgetedLocationsCount__c;StartDate__c;EndDate__c;ResponsibleForExecution__c');
        insert settings;
    }

//---- init Equipments ----
    static RecordSet initEquipments() {
        RecordSet rs = new RecordSet();
        String type1 = CONSTANTS.EQUIPMENT_ASSET, type2 = CONSTANTS.EQUIPMENT_TOOL;
        for (Integer i = 0; i < MaxCountSmall; i++) {
            rs.add(newEquipment(
                       'Equipment' + String.valueOf(i),
                       Math.mod(i, 2) == 0 ? type1 : type2,
                       'Desc' + String.valueOf(i)
                   ));
        }
        rs.doInsert();
        return rs;
    }
    static SObject newEquipment(String name, String type, String description) {
        SObject r = createSObject('Equipment__c');
        setFieldNoNamespace(r, 'Name', name);
        setField(r, 'IsActive__c', true);
        setField(r, 'Description__c', description);
        setField(r, 'EquipmentType__c', type);

        return r;
    }

    public static Equipment__c getEquipment(String type) {
        return [SELECT Id FROM Equipment__c WHERE EquipmentType__c = :type LIMIT 1];
    }

//---- init locations ----
    static RecordSet initLocations(SObject retailer, RecordSet postCodes) {
        RecordSet rs = new RecordSet();
        SObject postCode;
        Integer postCodeSize = postCodes.Records.size();

        for (Integer i = 0; i < MaxCountLarge; i++) {
            postCode = postCodes.Records.get(Math.mod(i, postCodeSize));
            rs.add(newLocation(i, retailer, postCode));
        }
        rs.doInsert();
        return rs;
    }
    static SObject newLocation(Integer i, SObject retailer, SObject postCode) {
        SObject r = createSObject('Location__c');
        String name = LocationNames[Math.mod(i, LocationNames.size())];
        r.put('name', name + String.valueOf(i));
        setField(r, 'City__c', 'City' + String.valueOf(i));
        setField(r, 'LocationNumber__c', String.valueOf(i));
        setField(r, 'Type__c', 'Location');
        setField(r, 'OneHubLocationID__c', getUniqueId('1234567890F'));
        setField(r, 'IsActive__c', true);
        setField(r, 'LaborTaxRate__c', 0.25);
        setField(r, 'LaborTaxLawsonID__c', '12344556');
        setField(r, 'Retailer__c', retailer.get('Id'));
        setField(r, 'OneHubRetailerId__c', getField(retailer, 'OneHubRetailerId__c'));
        setField(r, 'PostalCode__c', postCode.get('Id'));
        return r;
    }

    public static String getUniqueId(String prefix) {
        Long seed = Crypto.getRandomLong();
        return prefix + String.valueOf(seed);
    }

    public static List<Location__c> getLocations() {
        return [SELECT Id, Name, Type__c, OneHubLocationID__c, LocationNumber__c, Retailer__c, OneHubRetailerId__c, PostalCode__c FROM Location__c];
    }

//---- init location assignments ----
    static void initLocationAssignments(RecordSet accounts, SObject projectType, RecordSet locations) {
        RecordSet rs = new RecordSet();
        Integer accountSize = accounts.Records.size();
        Integer locationSize = locations.Records.size();
        SObject account, location;

        for (Integer i = 0; i < locationSize; i++) {
            account = accounts.Records.get(Math.mod(i, accountSize));
            location = locations.Records.get(i);
            rs.add(newLocationAssignment(account, location, projectType));
        }
        rs.doInsert();
    }
    static SObject newLocationAssignment(SObject account, SObject location, SObject projectType) {
        SObject r = createSObject('LocationAssignment__c');
        setField(r, 'Location__c', location.get('Id'));
        setField(r, 'ProjectType__c', projectType.get('Id'));
        setField(r, 'AccountableExecutionCompany__c', account.get('Id'));
        return r;
    }

//---- init certificates ----
    static RecordSet initCertificates() {
        RecordSet rs = new RecordSet();
        SObject cert;
        for (Integer i = 0; i < MaxCountSmall; i++) {
            cert = createSObject('Certification__c');
            setField(cert, 'IsActive__c', true);
            setFieldNoNamespace(cert, 'Name', 'Certification' + String.valueOf(i));
            setField(cert, 'Description__c', 'Desc' + String.valueOf(i));
            rs.add(cert);
        }
        rs.doInsert();
        return rs;
    }

    public static List<Certification__c> getCertifications() {
        return [SELECT Id FROM Certification__c];
    }

//---- init targets ----
    static void initTargets(SObject retailer) {
        RecordSet rs = new RecordSet();
        for (Integer i = 0; i < MaxCountSmall; i++) {
            rs.add(newTarget(i, retailer));
        }
        rs.doInsert();
    }
    static SObject newTarget(Integer i, SObject retailer) {
        SObject r = createSObject('Target__c');
        String suffix = String.valueOf(i);
        setFieldNoNamespace(r, 'Name', 'Product' + suffix);
        setField(r, 'Retailer__c', retailer.get('Id'));
        setField(r, 'AccountInfo__c', 'AccountInfo' + suffix);
        setField(r, 'BrandInfo__c', 'BrandInfo' + suffix);
        setField(r, 'CategoryInfo__c', 'Category' + suffix);
        setField(r, 'DepartmentName__c', 'DepartmentName' + suffix);
        setField(r, 'DepartmentNumber__c', 100 + i);
        setField(r, 'Description__c', 'Desc' + suffix);
        setField(r, 'StockCode__c', String.valueOf(Crypto.getRandomInteger()));
        setField(r, 'OneHubRetailerId__c', getField(retailer, 'OneHubRetailerId__c'));
        setField(r, 'PackageSizeQty__c', Math.mod(i, 12));
        setField(r, 'plu__c', 'plu' + suffix);
        setField(r, 'ShelfName__c', 'ShelfName' + suffix);
        setField(r, 'Status__c', 'Active');
        setField(r, 'TargetName__c', 'Cart' + suffix);
        setField(r, 'TargetType__c', 'Product');
        setField(r, 'UPC__c', ('upc' + suffix + '000000000000').left(12));
        setField(r, 'VendorNumber__c', 100 + i);
        return r;
    }

    public static List<Target__c> getTargets() {
        return [SELECT Id FROM Target__c];
    }

//---- init fulfillments ----
    static RecordSet initFulfillments(SObject retailer) {
        RecordSet rs = new RecordSet();
        rs.add(newFulfillment('Premium', retailer, '-1'));
        rs.add(newFulfillment('CTL', retailer, '-2'));
        rs.doInsert();
        return rs;
    }
    static SObject newFulfillment(String name, SObject retailer, String suffix) {
        SObject f = createSObject('FulfillmentCenter__c');
        setFieldNoNamespace(f, 'Name', name);
        setField(f, 'Retailer__c', retailer.get('Id'));
        setField(f, 'OneHubRetailerId__c', getField(retailer, 'OneHubRetailerId__c') + suffix);
        return f;
    }

//---- init materials ----
    static void initMaterials(SObject retailer, RecordSet fulfillments) {
        RecordSet rs = new RecordSet();
        SObject fulfillment = fulfillments.Records.get(0);
        rs.add(newMaterial('Spoon', retailer, fulfillment));
        rs.add(newMaterial('Sample Kit', retailer, fulfillment));
        rs.doInsert();
    }
    static SObject newMaterial(String name, SObject retailer, SObject fullfillment) {
        SObject m = createSObject('Material__c');
        setFieldNoNamespace(m, 'Name', name);
        setField(m, 'IsActive__c', true);
        setField(m, 'Kit__c', false);
        setField(m, 'IsEditable__c', true);
        setField(m, 'Retailer__c', retailer.get('Id'));
        setField(m, 'FulfillmentCenter__c', fullfillment.get('Id'));
        return m;
    }

    public static List<Material__c> getMaterials() {
        return [SELECT
                Id,
                Name,
                Kit__c,
                Retailer__c
                FROM Material__c
               ];
    }

//---- init services ----
    public static List<Service__c> initServicesByNames(List<String>args) {
        RecordSet rs = new RecordSet();
        Integer base = 0;
        for (String name : args) {
            base += 1;
            rs.add(newService(name, String.valueOf(Base * 30) + ' min'));
        }
        rs.doInsert();
        return rs.Records;
    }

    static RecordSet initServices() {
        RecordSet rs = new RecordSet();
        List<String> names = new List<String> {'AB Dry', 'Merchandising', 'Standard'};
        Integer base = 0;
        for (String name : names) {
            base += 1;
            rs.add(newService(name, String.valueOf(Base * 30) + ' min'));
        }
        rs.doInsert();
        return rs;
    }
    static SObject newService(String name, String duration) {
        IdIndex++;
        SObject s = createSObject('Service__c');
        setFieldNoNamespace(s, 'Name', name);
        setField(s, 'ServiceDescription__c', name + ' desc');
        setField(s, 'TargetType__c', 'Category;Product;None');
        setField(s, 'Duration__c', duration);
        setField(s, 'IsNumberOfWorkersRequired__c', true);
        if (Math.mod(IdIndex, 2) == 0) {
            setField(s, 'Specialization__c', 'Shift');
        } else {
            setField(s, 'Specialization__c', 'Standard');
        }
        return s;
    }

    public static List<Service__c> getServices() {
        return [SELECT Id, Name, TargetType__c, Duration__c from Service__c];
    }

//---- init service exceptions ----
    static void initServiceExceptions() {
        RecordSet rs = new RecordSet();
        Boolean isExecuted;

        for (Service__c service : [SELECT Id FROM Service__c]) {
            isExecuted = true;
            for (Exception__c ex : [SELECT Id FROM Exception__c]) {
                rs.add(newServiceException(service.Id, ex.Id, isExecuted));
                isExecuted = !isExecuted;
            }
        }
        rs.doInsert();
    }
    static SObject newServiceException(ID serviceId, ID exceptionId, Boolean executed) {
        SObject se = createSObject('ServiceException__c');
        setField(se, 'Service__c', serviceId);
        setField(se, 'Exception__c', exceptionId);
        setField(se, 'IsExecuted__c', executed);
        return se;
    }

//---- init project type services ----
    static void initProjectTypeServices(SObject projectType, RecordSet services) {
        RecordSet rs = new RecordSet();
        For(SObject service: services.Records) {
            rs.add(newProjectTypeService(projectType, service));
        }
        rs.doInsert();
    }
    static SObject newProjectTypeService(SObject projectType, SObject service) {
        SObject p = createSObject('ProjectTypeService__c');
        setField(p, 'ProjectType__c', projectType.get('Id'));
        setField(p, 'Service__c', service.get('Id'));
        return p;
    }

//---- init retailer services ----
    public static List<RetailerService__c> initRetailerServicesByServiceList(SObject retailer, List<Service__c> services) {
        RecordSet rs = new RecordSet();
        for (SObject service : services) {
            rs.add(newRetailerService(retailer, service));
        }
        rs.doInsert();
        return rs.Records;
    }

    public static void initRetailerServices(SObject retailer, RecordSet services) {
        RecordSet rs = new RecordSet();
        for (SObject service : services.Records) {
            rs.add(newRetailerService(retailer, service));
        }
        rs.doInsert();
    }
    static SObject newRetailerService(SObject retailer, SObject service) {
        SObject s = createSObject('RetailerService__c');
        setField(s, 'Retailer__c', retailer.get('Id'));
        setField(s, 'Service__c', service.get('Id'));
        setField(s, 'jobManualTemplate__c', 'Standard');
        return s;
    }

    public static List<RetailerService__c> getRetailerServices(String retailerId) {
        if (String.isBlank(retailerId)) {
            return [SELECT
                    Retailer__c,
                    Service__c,
                    Service__r.Name,
                    Service__r.Specialization__c
                    FROM RetailerService__c];
        }

        return [SELECT
                Retailer__c,
                Service__c,
                Service__r.Name,
                Service__r.Specialization__c
                FROM RetailerService__c
                WHERE Retailer__c = :retailerId
               ];
    }

//---- init questions ----
    static RecordSet initQuestions() {
        RecordSet rs = new RecordSet();
        SObject qSingleSelect, qYesNo;

        rs.add(newQuestion(
                   'Number',
                   'How many products did you demo?',
                   1
               ));
        rs.add(newQuestion(
                   'Photo',
                   'Picture of the display?',
                   2
               ));
        rs.add(newQuestion(
                   'Number',
                   'How many did you purchase?',
                   3
               ));
        rs.add(newQuestion(
                   'Text',
                   'What is the supervisor name?',
                   4
               ));
        qSingleSelect = newQuestion(
                            'Single-Select List',
                            'Did you feel prepared for the event?',
                            5
                        );
        rs.add(qSingleSelect);
        //scale up to test more qeustions scenario
        for (integer i = 0; i < 10; i++) {
            qSingleSelect = newQuestion(
                                Math.mod(i, 2) == 0 ? 'Single-Select List' : 'Multi-Select List',
                                'Did you feel prepared for the event?',
                                i + 100
                            );
            rs.add(qSingleSelect);
        }
        qYesNo = newQuestion(
                     'Yes/No',
                     'Did you start on time?',
                     6
                 );
        rs.add(qYesNo);
        rs.doInsert();
        return rs;
    }

    public static SObject createSingleSelectQuestion(String content, Integer hubId, boolean isException, String[] answers) {
        SObject q = createSObject('Question__c');
        setField(q, 'QuestionType__c', 'Single-Select List');
        setField(q, 'QuestionText__c', content);
        setField(q, 'Active__c', true);
        setField(q, 'TargetType__c', Math.mod(hubId, 2) == 0 ? '' : 'Product');
        setField(q, 'IsQuestionVisibleToClient__c', true);
        setField(q, 'OneHubQuestionId__c', 'OHQ-' + String.valueOf(hubId));
        setField(q, 'ExceptionQuestion__c', isException);
        insert q;
        
        RecordSet rs = new RecordSet();
        Integer step = 1;
        for(String r: answers){
            rs.add(newQuestionResponse(q,r,step));
            step++;    
        }
        rs.doInsert();

        return q;
    }

    public static SObject newQuestion(String type, String content, Integer hubId) {
        SObject q = createSObject('Question__c');
        setField(q, 'QuestionType__c', type);
        setField(q, 'QuestionText__c', content);
        setField(q, 'Active__c', true);
        setField(q, 'TargetType__c', Math.mod(hubId, 2) == 0 ? '' : 'Product');
        setField(q, 'IsQuestionVisibleToClient__c', true);
        setField(q, 'OneHubQuestionId__c', 'OHQ-' + String.valueOf(hubId));
        return q;
    }

    public static List<Question__c> getQuestions() {
        return [
                   SELECT
                   Id,
                   Name,
                   DefinedResponseCount__c,
                   QuestionType__c,
                   QuestionText__c,
                   Active__c,
                   TargetType__c,
                   IsQuestionVisibleToClient__c,
                   OneHubQuestionId__c
                   FROM Question__c
               ];
    }

    public static List<Question__c> getQuestionsByQuestionType(String whereClause) {

        String sql = 'SELECT Id,  Name,  DefinedResponseCount__c, QuestionType__c,'
                     + '  QuestionText__c, Active__c,TargetType__c,IsQuestionVisibleToClient__c,OneHubQuestionId__c FROM Question__c WHERE '
                     + whereClause;
        return Database.query(sql);


    }


//---- init question responses ----
    static RecordSet initQuestionResponses(RecordSet questions) {
        RecordSet rs = new RecordSet();
        String qType;

        for (SObject question : questions.Records) {
            if ('Yes/No' == getField(question, 'QuestionType__c')) {
                rs.add(newQuestionResponse(question, 'Yes', 1));
                rs.add(newQuestionResponse(question, 'No', 2));
            } else {
                qType = String.valueOf(getField(question, 'QuestionType__c'));
                if ('Single-Select List' == qType || 'Multi-Select List' == qType) {
                    rs.add(newQuestionResponse(question, 'Very Prepared', 1));
                    rs.add(newQuestionResponse(question, 'Prepared', 2));
                    rs.add(newQuestionResponse(question, 'Somewhat Prepared', 3));
                    rs.add(newQuestionResponse(question, 'Not Prepared', 4));

                    //scale up more responses
                    for (Integer i = 1; i < 10; i++) {
                        rs.add(
                            newQuestionResponse(question, 'Best' + String.valueof(i), i + 5));
                    }
                }
            }
        }

        if (rs.Records.size() > 0) {
            rs.doInsert();
        }
        return rs;
    }

    public static SObject newQuestionResponse(SObject question, String answer, Integer seq) {
        SObject r = createSObject('QuestionDefinedResponse__c');
        setField(r, 'DefinedResponseOrder__c', seq);
        setField(r, 'DefinedResponseText__c', answer);
        setField(r, 'Question__c', question.get('Id'));
        return r;
    }

//---- init attributes ----
    static RecordSet initAttributes() {
        RecordSet rs = new RecordSet();
        rs.add(newAttribute('Overview', CONSTANTS.ATTRIBUTE_TEXT));
        rs.add(newAttribute('Instructions', CONSTANTS.ATTRIBUTE_TEXT));
        rs.add(newAttribute('Supporting Attachment 1', CONSTANTS.ATTRIBUTE_PHOTO));
        rs.add(newAttribute('Job Manual', CONSTANTS.ATTRIBUTE_PHOTO));
        rs.add(newAttribute('Date', CONSTANTS.ATTRIBUTE_DATE));
        rs.add(newAttribute('Number', CONSTANTS.ATTRIBUTE_NUMBER));
        rs.add(newAttribute('File', CONSTANTS.ATTRIBUTE_FILE));
        rs.add(newAttribute('Single-Select List', CONSTANTS.ATTRIBUTE_SINGLE_SELECT));
        rs.add(newAttribute('Multi-Select List', CONSTANTS.ATTRIBUTE_MULTI_SELECT));
        rs.doInsert();
        return rs;
    }
    static SObject newAttribute(String description, String type) {
        SObject a = createSObject('Attribute__c');
        setField(a, 'Description__c', description);
        setField(a, 'Active__c', true);
        setField(a, 'AttributeType__c', type);
        setField(a, 'AttributeMaxLength__c', 5000);
        setField(a, 'Repeatable__c', false);
        setField(a, 'Required__c', false);
        return a;
    }

//---- init service attributes ----
    static void initServiceAttributes(RecordSet services, RecordSet attributes) {
        RecordSet rs = new RecordSet();
        Integer seq = 0;
        for (SObject service : services.Records) {
            seq = 0;
            for (SObject attribute : attributes.Records) {
                seq += 1;
                rs.add(newServiceAttribute(seq, service, attribute));
            }
        }
        rs.doInsert();
    }
    static SObject newServiceAttribute(Integer seq, SObject service, SObject attribute) {
        SObject r = createSObject('ServiceAttribute__c');
        setField(r, 'Attribute__c', attribute.get('Id'));
        setField(r, 'AttributeOrder__c', seq);
        setField(r, 'Service__c', service.get('Id'));
        setField(r, 'IsVisible__c', getField(attribute, 'Description__c') == 'Job Manual' ? false : true);
        return r;
    }

    public static List<ServiceAttribute__c> getServiceAttributes(Id service) {
        return [
                   SELECT
                   Id,
                   Name,
                   Attribute__c,
                   IsVisible__c
                   FROM ServiceAttribute__c
                   WHERE Service__c = :service
               ];
    }

//---- init service questions ----
    public static RecordSet initServiceQuestions(RecordSet services, RecordSet questions) {
        RecordSet rs = new RecordSet();
        Integer seq;

        for (SObject service : services.Records) {
            seq = 0;
            for (SObject question : questions.Records) {
                seq += 1;
                rs.add(newServiceQuestion(seq, service, question));
            }
        }
        rs.doInsert();
        return rs;
    }
    static SObject newServiceQuestion(Integer seq, SObject service, SObject question) {
        SObject r = createSObject('ServiceQuestion__c');
        setField(r, 'Question__c', question.get('Id'));
        setField(r, 'QuestionNumber__c', seq);
        setField(r, 'Service__c', service.get('Id'));
        setField(r, 'IsActive__c', True);
        setField(r, 'IsVisibleToClient__c', getField(question, 'IsQuestionVisibleToClient__c'));
        setField(r, 'Optional__c', True);
        setField(r, 'UniqueKey__c', genUniqeKey('sq'));
        return r;
    }

    public static List<ServiceQuestion__c> getServiceQuestions(Id service) {
        return [
                   SELECT
                   Id,
                   QuestionNumber__c,
                   Question__c,
                   QuestionType__c,
                   IsVisibleToClient__c,
                   ItemQuestion__c,
                   NumberofDefinedResponses__c
                   FROM ServiceQuestion__c
                   WHERE Service__c = :service
               ];
    }

    public static List<AILabel__c> getPhotoLabels() {
        return [
                   SELECT
                   Id,
                   Name
                   FROM AILabel__c       ];
    }

    public static List<ServiceQuestion__c> findServiceQuestions(String whereClause) {
        String sql = 'SELECT Id, QuestionNumber__c, Question__c, IsVisibleToClient__c,'
                     + ' ItemQuestion__c, NumberofDefinedResponses__c FROM ServiceQuestion__c WHERE '
                     + whereClause;
        return Database.query(sql);
    }

//---- init service question responses ----

    static void initServiceQuestionResponses(RecordSet serviceQuestions, RecordSet responses) {
        RecordSet rs = new RecordSet();

        for (SObject sQ : serviceQuestions.Records) {
            for (SObject answer : responses.find('Question__c', getField(sQ, 'Question__c'))) {
                rs.add(newServiceQuestionResponse(sQ, answer));
            }
        }

        if (rs.count() > 0) {
            rs.doInsert();
        }
    }

    static SObject newServiceQuestionResponse(SObject q, SObject response) {
        SObject r = createSObject('ServiceQuestionDefinedResponse__c');
        setField(r, 'ServiceQuestion__c', q.get('Id'));
        setField(r, 'QuestionDefinedResponse__c', response.get('Id'));
        setField(r, 'Optional__c', true);
        setField(r, 'IsActive__c', true);
        setField(r, 'CanRemove__c', true);
        return r;
    }

    public static List<ServiceQuestionDefinedResponse__c> getServiceQuestionResponses(Id service) {
        return [SELECT ServiceQuestion__c, ServiceQuestion__r.Question__c, QuestionDefinedResponse__c FROM ServiceQuestionDefinedResponse__c
                WHERE ServiceQuestion__r.Service__c = :service];
    }

//---- init retailer service equipments -----
    static void initRetailerServiceEquipments(SObject retailer, RecordSet services, RecordSet equipments) {
        RecordSet rs = new RecordSet();
        for (SObject service : services.Records) {
            for (SObject equipment : equipments.Records) {
                rs.add(newRetailerServiceEquipment(retailer, service, equipment));
            }
        }
        rs.doInsert();
    }
    static SObject newRetailerServiceEquipment(SObject retailer, SObject service, SObject equipment) {
        SObject r = createSObject('RetailerServiceEquipment__c');
        setField(r, 'Service__c', service.get('Id'));
        setField(r, 'Retailer__c', retailer.get('Id'));
        setField(r, 'Equipment__c', equipment.get('Id'));
        setField(r, 'IsLocked__c', true);
        setField(r, 'Quantity__c', 1);
        return r;
    }

    public static List<Id> getRetailerServiceTools(Id retailer, Id service) {
        List<Id> rs = new List<id>();
        for (RetailerServiceEquipment__c e : [SELECT Equipment__c FROM RetailerServiceEquipment__c
                                              WHERE Retailer__c = :retailer AND Service__c = :service]) {
            if (e.Equipment__c != null) {
                rs.add(e.Equipment__c);
            }
        }
        return rs;
    }

//---- init retailer service certifications ----
    static void initRetailerServiceCertifications(SObject retailer, RecordSet services, RecordSet certifications) {
        RecordSet rs = new RecordSet();
        for (SObject service : services.Records) {
            for (SObject certification : certifications.Records) {
                rs.add(newRetailerServiceCertification(retailer, service, certification));
            }
        }
        rs.doInsert();
    }
    static SObject newRetailerServiceCertification(SObject retailer, Sobject service, SObject certification) {
        SObject r = createSObject('RetailerServiceCertification__c');
        setField(r, 'Service__c', service.get('Id'));
        setField(r, 'Retailer__c', retailer.get('Id'));
        setField(r, 'Certification__c', certification.get('Id'));
        return r;
    }

    public static List<Id> getServiceCertifications(Id retailer, Id service) {
        List<Id> result = new List<Id>();
        for (RetailerServiceCertification__c c : [SELECT
                Certification__c FROM RetailerServiceCertification__c
                WHERE Retailer__c = :retailer AND Service__c = :service]) {
            result.add(c.Certification__c);
        }
        return result;
    }

//---- init AI setup ----
    static void initAISetup(RecordSet services) {


        Recordset rs = new Recordset();
        rs.add(newPhotoLabel('ShelfDisplay'));
        rs.doInsert();
    }

    static SObject newPhotoLabel(String name) {
        SObject obj = createSObject('AILabel__c');
        setField(obj, 'Name', name);
        return obj;
    }

//---- Helper API ----
    class RecordSet {
        Public List<SObject> Records {get; set;}

        public Integer count() {
            return Records.size();
        }

        public RecordSet() {
            Records = new List<SObject>();
        }

        public void add(SObject record) {
            Records.add(record);
        }

        public void doInsert() {
            insert Records;
        }

        public List<SObject> find(String field, Object value) {
            List<SObject> rs = new List<SObject>();

            for (SObject r : Records) {
                if (value == getField(r, field)) {
                    rs.add(r);
                }
            }
            return rs;
        }
    }

    public static String namifyImportFields(String fields) {
        if (String.isBlank(fields) || String.isBlank(SystemNameSpace)) return fields;

        List<String> result = new List<String>();
        List<String> items = fields.split(',');
        for (String item : items) {
            List<String> cols = item.split('-');
            if (cols.size() == 2) {
                result.add(namify(cols[0]) + '-' + cols[1]);
            }
        }
        return String.join(result, ',');
    }

    public static String namify(String name) {
        if (String.isBlank(name) ||
                name.indexOfIgnoreCase('__c') == -1 ||
                name.indexOfIgnoreCase(SystemNameSpace) == 0) return name;
        return SystemNameSpace + name;
    }

    public static Account initRetailAccount() {
        List<Account> accts = [SELECT Id, OneHubAccountType__c from Account];
        accts[0].OneHubAccountType__c = 'Retailer';
        update accts[0];

        return accts[0];
    }

    public static void assignRetailerAccountToProject(String pId, String accountId) {
        Project__c p = [SELECT Id, RetailerAccount__c from Project__c where id = :pId];
        p.RetailerAccount__c = accountId;
        update p;
    }

    public static void assignRetailerAccountToLocations(String accountId) {
        List<Location__c> locList = [SELECT Id, RetailerAccount__c from Location__c];
        for (Location__c loc : locList) {
            loc.RetailerAccount__c = accountId;
        }
        update locList;
    }


    static SObject createSObject(string name) {
        return SObjectTypeMap.get(namify(name)).newSobject();
    }

    public static Object getField(SObject record, String field) {
        return record.get(namify(field));
    }

    static void setField(SObject record, String field, Object value) {
        record.put(namify(field), value);
    }
    static void setFieldNoNamespace(SObject record, String field, Object value) {
        record.put(field, value);
    }

    public static void disableTriggers() {
        TriggerUtil.skipAllTriggers();
        setDRFlag(true);
    }

    static void setDRFlag(Boolean isTrue) {
        DRecoverySettings__c dr = [SELECT Id, DRMode__c FROM DRecoverySettings__c LIMIT 1];
        dr.DRMode__c = isTrue;
        update dr;
    }

    public static void enableTriggers() {
        setDRFlag(true);
    }

    public static String getUserAccountId(string projectId) {
        List<ProjectAccount__c> accts = [SELECT Account__c From ProjectAccount__c WHERE Project__c = :projectId];
        return accts.size() > 0
               ? accts[0].Account__c
               : '';
    }

    private static void initDatasource() {
        ImportRequestQueueTestUtil.setupDatasource();
    }

///////////////////////////////////////////////////
}