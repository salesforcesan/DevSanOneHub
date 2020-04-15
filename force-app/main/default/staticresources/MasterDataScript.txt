delete [select id from CMKOneHub__RetailerServiceEquipment__c];
delete [select id from CMKOneHub__ServiceQuestionDefinedResponse__c];
delete [select id from CMKOneHub__servicequestion__C];
delete [select id from CMKOneHub__serviceattribute__c];
delete [select id from CMKOneHub__RetailerServiceCertification__c];
delete [select id from CMKOneHub__ProjectTypeService__c];
delete [select id from CMKOneHub__retailerService__c];
delete [select id from CMKOneHub__service__c];
delete [select id from CMKOneHub__attribute__c];
delete [SELECT Id FROM CMKOneHub__LocationAssignment__c];
delete [SELECT Id FROM CMKOneHub__Location__c];
delete [SELECT Id FROM CMKOneHub__Target__c];
delete [select Id from CMKOneHub__question__c];
delete [select Id from CMKOneHub__FulfillmentCenter__c];
delete [SELECT Id FROM CMKOneHub__Certification__c];
delete [SELECT Id FROM CMKOneHub__ProjectType__c];
delete [SELECT Id FROM CMKOneHub__ProjectTypeCustomSettings__c];
delete [SELECT Id FROM CMKOneHub__Equipment__c];
delete [SELECT Id FROM CMKOneHub__Retailer__c];
delete [SELECT Id FROM CMKOneHub__language__c];
delete [SELECT Id FROM Contact WHERE LastName IN ('Crossmark','Premium','Crossmak')];
delete [SELECT Id FROM Account WHERE Name IN ('Crossmark Test EC','Premium Test EC')];
delete [select id from CMKOneHub__ScheduleOption__c];
delete [select id from CMKOneHub__cycle__c];
delete [select id from OrgCustomSettings__c];

CMKOneHub__OrgCustomSettings__c org = new CMKOneHub__OrgCustomSettings__c();
org.Name='Setting';
org.CMKOneHub__OrgInstanceName__c ='WALGREENS';
insert org;

delete [SELECT ID FROM CMKOneHub__PostalCOde__c];
List<CMKOneHub__PostalCOde__c> posts = new List<CMKOneHub__PostalCOde__c>();

CMKOneHub__PostalCOde__c post = new CMKOneHub__PostalCOde__c();
post.CMKOneHub__DST__c = false;
post.Name = '94127';
post.CMKOneHub__Timezoneoffset__c = -8;
post.CMKOneHub__GeoLocation__latitude__s = 37.7357008082887;
post.CMKOneHub__GeoLocation__longitude__s = -122.45947227415;
posts.add(post);

post = new CMKOneHub__PostalCOde__c();
post.CMKOneHub__DST__c = false;
post.Name = '75024';
post.CMKOneHub__Timezoneoffset__c = -6;
post.CMKOneHub__GeoLocation__latitude__s = 33.07737;
post.CMKOneHub__GeoLocation__longitude__s = -96.80700;
posts.add(post);
insert posts;



integer cnt = [select count() from account where Name IN ('Crossmark Test EC')];
if(cnt==0)
{
	Account acc1 = new Account();
	acc1.Name = 'Crossmark, Inc.';
acc1.recordtype=new recordtype(name='Execution Company');
	insert acc1;
}

cnt = [select count() from account where Name IN ('Premium Test EC')];
if(cnt==0)
{
	Account acc2 = new Account();
    acc2.recordtype=new recordtype(name='Execution Company');
	acc2.Name = 'Premium';
	insert acc2;
}


List<Account> accs = [SELECT Id FROM Account];
Contact c1 = new Contact();
c1.FirstName = 'John Doe';
c1.LastName = 'Crossmark';
c1.Account = accs[0];
insert c1;

Contact c2 = new Contact();
c2.FirstName = 'Jane Doe';
c2.LastName = 'Premium';
c2.Account = accs[1];
insert c2;

CMKOneHub__language__c lng  = new CMKOneHub__language__c();
lng.Name = 'English';
insert lng;

CMKOneHub__Retailer__c[] rts = new CMKOneHub__Retailer__c[]{
   new CMKOneHub__Retailer__c(Name = 'Walgreens', CMKOneHub__OneHubRetailerId__c = 'WALGREENS')
       };
insert rts;

CMKOneHub__Retailer__c retailer = [Select Id,CMKOneHub__OneHubRetailerId__c FROM CMKOneHub__Retailer__c LIMIT 1];

CMKOneHub__ProjectType__c md = new CMKOneHub__ProjectType__c();
md.Name = 'Merchandising';
md.CMKOneHub__minservicecount__c = 1;
md.CMKOneHub__maxservicecount__c = 5;
md.CMKOneHub__maxservicecount__c = 5;
md.CMKOneHub__GracePeriodDuration__c = 0;
md.CMKOneHub__LaunchLeadTime__c = 0;
insert md;


List<CMKOneHub__cycle__c> cyclList = new List<CMKOneHub__cycle__c>();
for (Integer i = 1; i < 5; i++) {
    CMKOneHub__cycle__c cy = new CMKOneHub__cycle__c();
    cy.Name = 'Cycle ' + i;
    cy.CMKOneHub__CycleStartDate__c = date.today().addDays(i);
	cy.CMKOneHub__CycleEndDate__c = date.today().addDays(i+3);
	cy.CMKOneHub__Retailer__c  = retailer.id;
    cyclList.add(cy);
}
insert cyclList;


CMKOneHub__ScheduleOption__c so = new CMKOneHub__ScheduleOption__c();

so.Name = 'Execution Company will Schedule';
so.CMKOneHub__code__c = 'EC';
so.CMKOneHub__description__C='By selecting this schedule option the system will expect the Execution Company to specify the Schedule Date for a Job.';
so.CMKOneHub__isactive__C=true;
insert so;

CMKOneHub__ScheduleOption__c so2 = new CMKOneHub__ScheduleOption__c();
so2.Name = 'Project Builder will Schedule';
so2.CMKOneHub__code__c = 'USER';
so2.CMKOneHub__description__C='By selecting this schedule option the system will expect the User creating the Project to specify the Schedule Date for a Job before the Job is available for an Execution Company to take action.';
so2.CMKOneHub__isactive__C=true;
insert so2;

CMKOneHub__ScheduleOption__c so3 = new CMKOneHub__ScheduleOption__c();
so3.Name = 'SYSTEM';
so3.CMKOneHub__code__c = 'SYSTEM';
so3.CMKOneHub__description__C='By selecting this schedule option the system will set the Schedule Date for a Job based upon settings entered by the User.';
so3.CMKOneHub__isactive__C=false;
insert so3;

CMKOneHub__ProjectTypeCustomSettings__c basePTSetting = new CMKOneHub__ProjectTypeCustomSettings__c ();
basePTSetting.Name = 'Merchandising';
basePTSetting.CMKOneHub__SchedulingStrategyClass__c = 'BaseSchedulingStrategy';
basePTSetting.CMKOneHub__FieldSetName__c = 'BaseProjectFieldset';
basePTSetting.CMKOneHub__ProjectCompletionStrategyClass__c= 'BaseProjectCompletionStrategy';
basePTSetting.CMKOneHub__ReReserveTrackFieldList__c= 'BudgetedLocationsCount__c;StartDate__c;EndDate__c;ResponsibleForExecution__c';
insert basePTSetting;


List<CMKOneHub__Equipment__c> eqpList = new List<CMKOneHub__Equipment__c>();
for (Integer i = 0; i < 5; i++) {
    CMKOneHub__Equipment__c eqp = new CMKOneHub__Equipment__c();
    eqp.Name = 'Equipment ' + i;
    eqpList.add(eqp);
    
}
insert eqpList;

List<CMKOneHub__Location__c> locations = new List <CMKOneHub__Location__c > ();
   
for (Integer i = 1; i <= 1000; i++) {
    CMKOneHub__Location__c location = new CMKOneHub__Location__c();
    location.Name = 'Location ' + i;
    location.CMKOneHub__City__c = 'City ' + i;
    location.CMKOneHub__LocationNumber__c = string.valueOf(i);
    location.CMKOneHub__type__c='Location';
    location.CMKOneHub__isactive__c=true;
    location.CMKOneHub__Retailer__c= retailer.id;
    location.CMKOneHub__OneHubRetailerId__c = retailer.CMKOneHub__OneHubRetailerId__c;
    location.CMKOneHub__Retailer__c = retailer.Id;
    location.CMKOneHub__PostalCode__c = posts[0].id;
    locations.add(location);
}
insert locations;

List<Account> execs = [SELECT Id,Name FROM Account WHERE RecordType.Name = 'Execution Company'];
locations = [SELECT Id,Name FROM CMKOneHub__Location__c];
List<CMKOneHub__LocationAssignment__c> locAssignments = new List <CMKOneHub__LocationAssignment__c > ();
CMKOneHub__ProjectType__c pt = [Select Id,Name FROM CMKOneHub__ProjectType__c LIMIT 1];   
for (Integer i = 0; i < 500; i++) {
    CMKOneHub__LocationAssignment__c locAssignment = new CMKOneHub__LocationAssignment__c();
    locAssignment.CMKOneHub__Location__c = locations[i].Id;
    locAssignment.CMKOneHub__ProjectType__c = pt.Id;
    locAssignment.CMKOneHub__AccountableExecutionCompany__c = execs[0].Id;
    locAssignments.add(locAssignment);
}
for (Integer i = 500; i < 1000; i++) {
    CMKOneHub__LocationAssignment__c locAssignment = new CMKOneHub__LocationAssignment__c();
    locAssignment.CMKOneHub__Location__c = locations[i].Id;
    locAssignment.CMKOneHub__ProjectType__c = pt.Id;
    locAssignment.CMKOneHub__AccountableExecutionCompany__c = execs[1].Id;
    locAssignments.add(locAssignment);
}
insert locAssignments;

List<CMKOneHub__Certification__c> certifications = new list<CMKOneHub__Certification__c>();
for (Integer i = 1; i <= 5; i++) {
    CMKOneHub__Certification__c cert = new CMKOneHub__Certification__c();
    cert.Name = 'Certification ' + i;
    certifications.add(cert);  
}
insert certifications;



String NAMESPACE = 'CMKOneHub__';
List<sObject> targets = new List<sObject>();
for(Integer i=1; i <= 10; i++) {
    CMKOneHub__Target__c s = new CMKOneHub__Target__c();
    s.put('name','Product ' + i  );
    s.put(NAMESPACE + 'Retailer__c', retailer.Id);
    s.put(NAMESPACE +'accountinfo__c', 'test');
    s.put(NAMESPACE +'brandinfo__c','test');
    s.put(NAMESPACE +'CategoryInfo__c','category');
    s.put(NAMESPACE +'departmentname__c', 'dn');
    s.put(NAMESPACE +'departmentnumber__c',123);
    s.put(NAMESPACE +'description__c', 'desc');
    s.put(NAMESPACE +'StockCode__c', ''+ Crypto.getRandomInteger());
    s.put(NAMESPACE +'OneHubRetailerId__c', '1');
    s.put(NAMESPACE +'PackageSizeQty__c', 12);
    s.put(NAMESPACE + 'plu__c', 'plu');
    s.put(NAMESPACE +'ShelfName__c','test');
    s.put(NAMESPACE + 'Status__c','Active');
    s.put(NAMESPACE + 'TargetName__c','cart');
    s.put(NAMESPACE + 'TargetType__C','Product');
    s.put(NAMESPACE + 'UPC__c','up123');
    s.put(NAMESPACE + 'VendorNumber__c',1231);
    s.put(NAMESPACE + 'PackageSizeQty__c',123);
    targets.add(s);
}

insert targets;
//insert material
//QUESTIONS and DEFINED RESPONSES
List<CMKOneHub__Question__c> qs = new List<CMKOneHub__Question__c>();
List<CMKOneHub__QuestionDefinedResponse__c> qdrList = new List<CMKOneHub__QuestionDefinedResponse__c>();
CMKOneHub__QuestionDefinedResponse__c qdr = new CMKOneHub__QuestionDefinedResponse__c();

//Text
CMKOneHub__Question__c q = new CMKOneHub__Question__c();
q.CMKOneHub__QuestionType__c = 'Text';
q.CMKOneHub__QuestionText__c = 'What is the supervisor name?';
q.CMKOneHub__Active__c = true;
q.CMKOneHub__OneHubQuestionId__c = 'OHQ-001';
qs.add(q);

//Number
q = new CMKOneHub__Question__c();
q.CMKOneHub__QuestionType__c = 'Number';
q.CMKOneHub__QuestionText__c = 'How many products did you demo?';
q.CMKOneHub__Active__c = true;
q.CMKOneHub__OneHubQuestionId__c = 'OHQ-002';
qs.add(q);

//Photo
q = new CMKOneHub__Question__c();
q.CMKOneHub__QuestionType__c = 'Photo';
q.CMKOneHub__QuestionText__c = 'Picture of the display?';
q.CMKOneHub__Active__c = true;
q.CMKOneHub__OneHubQuestionId__c = 'OHQ-003';
qs.add(q);

//Item Question
q = new CMKOneHub__Question__c();
q.CMKOneHub__QuestionType__c = 'Number';
q.CMKOneHub__QuestionText__c = 'How many did you purchase?';
q.CMKOneHub__Active__c = true;
q.CMKOneHub__OneHubQuestionId__c = 'OHQ-004';
q.CMKOneHub__TargetType__c = 'Product';
qs.add(q);

insert qs;


//Single-Select List
CMKOneHub__Question__c qss = new CMKOneHub__Question__c();
qss.CMKOneHub__QuestionType__c = 'Single-Select List';
qss.CMKOneHub__QuestionText__c = 'Did you feel prepared for the event?';
qss.CMKOneHub__Active__c = true;
qss.CMKOneHub__OneHubQuestionId__c = 'OHQ-005';
insert qss;

qdrList = new List<CMKOneHub__QuestionDefinedResponse__c>();
qdr = new CMKOneHub__QuestionDefinedResponse__c();
qdr.CMKOneHub__DefinedResponseOrder__c = 1;
qdr.CMKOneHub__DefinedResponseText__c = 'Very Prepared';            
qdr.CMKOneHub__Question__c = qss.id;        
qdrList.add(qdr);


qdr = new CMKOneHub__QuestionDefinedResponse__c();
qdr.CMKOneHub__DefinedResponseOrder__c = 2;
qdr.CMKOneHub__DefinedResponseText__c = 'Prepared';            
qdr.CMKOneHub__Question__c = qss.id;        
qdrList.add(qdr);


qdr = new CMKOneHub__QuestionDefinedResponse__c();
qdr.CMKOneHub__DefinedResponseOrder__c = 2;
qdr.CMKOneHub__DefinedResponseText__c = 'Somewhat Prepared';            
qdr.CMKOneHub__Question__c = qss.id;        
qdrList.add(qdr);

//Yes/No
CMKOneHub__Question__c qyn = new CMKOneHub__Question__c();
qyn.CMKOneHub__QuestionType__c = 'Yes/No';
qyn.CMKOneHub__QuestionText__c = 'Did you start on time?';
qyn.CMKOneHub__Active__c = true;
qyn.CMKOneHub__OneHubQuestionId__c = 'OHQ-006';
insert qyn;


qdr = new CMKOneHub__QuestionDefinedResponse__c();
qdr.CMKOneHub__DefinedResponseOrder__c = 1;
qdr.CMKOneHub__DefinedResponseText__c = 'Yes';            
qdr.CMKOneHub__Question__c = qyn.id;        
qdrList.add(qdr);

qdr = new CMKOneHub__QuestionDefinedResponse__c();
qdr.CMKOneHub__DefinedResponseOrder__c = 2;
qdr.CMKOneHub__DefinedResponseText__c = 'No';            
qdr.CMKOneHub__Question__c = qyn.id;        
qdrList.add(qdr);

insert qdrList;


//FULFILLMENT CENTERS && MATERIALS
List<CMKOneHub__FulfillmentCenter__c> fcs= new List<CMKOneHub__FulfillmentCenter__c>();
CMKOneHub__FulfillmentCenter__c fc = new CMKOneHub__FulfillmentCenter__c();
fc.CMKOneHub__Retailer__c = retailer.Id;
fc.CMKOneHub__OneHubRetailerId__c = 'OHFC-001';
fc.Name = 'Premium';
fcs.add(fc);
        
fc = new CMKOneHub__FulfillmentCenter__c();
fc.Name = 'CTL';
fc.CMKOneHub__Retailer__c = retailer.Id;
fc.CMKOneHub__OneHubRetailerId__c = 'OHFC-002';
fcs.add(fc);

insert fcs;


List<CMKOneHub__FulfillmentCenter__c> fcslist = [Select id, name from CMKOneHub__FulfillmentCenter__c];
CMKOneHub__FulfillmentCenter__c fulfillmentCenter = fcslist[0];

List<CMKOneHub__Material__c> materials = new List<CMKOneHub__Material__c>();

CMKOneHub__Material__c material = new CMKOneHub__Material__c();
material.name = 'Spoon';
material.CMKOneHub__IsActive__c = true;
material.CMKOneHub__Kit__c = false;
material.CMKOneHub__Retailer__c = retailer.Id;
material.CMKOneHub__FulfillmentCenter__c = fulfillmentCenter.Id;
insert material;

material = new CMKOneHub__Material__c();
material.name = 'Sample Kit';
material.CMKOneHub__Kit__c = true;
material.CMKOneHub__Retailer__c = retailer.Id;
material.CMKOneHub__IsActive__c = true;
material.CMKOneHub__FulfillmentCenter__c = fulfillmentCenter.Id;
insert material;


Id MerchProjTypeID = [Select Id from CMKOneHub__ProjectType__c where Name ='Merchandising' LIMIT 1].Id;
List<CMKOneHub__Service__c> svcs= new List<CMKOneHub__Service__c>();

//Add  service__c
List<String> ServNames = new List<String> {'AB Dry','Merchandising','Standard'};

CMKOneHub__Service__c svc = new CMKOneHub__Service__c();
for(string str : ServNames)
{
                svc = new CMKOneHub__Service__c();
                svc.Name = str;
                svc.CMKOneHub__ServiceDescription__c = '';
                svc.CMKOneHub__TargetType__c = 'Category;Product;None';
                svc.CMKOneHub__Duration__c = '6 Hr';        
                svcs.add(svc);
} 


List<Database.Saveresult> insertResults=Database.insert(svcs, false);

List<CMKOneHub__ProjectTypeService__c> ptss= new List<CMKOneHub__ProjectTypeService__c>();
CMKOneHub__ProjectTypeService__c pts = new CMKOneHub__ProjectTypeService__c();

id walgrn = [select id from CMKOneHub__retailer__c where CMKOneHub__OneHubRetailerId__C = 'WALGREENS' limit 1 ].id;

List<CMKOneHub__retailerService__c> rsLst= new List<CMKOneHub__retailerService__c>();
CMKOneHub__retailerService__c rs = new CMKOneHub__retailerService__c();

                                
for (Database.SaveResult sr : insertResults) {
                if (sr.isSuccess()) {                    
                                pts = new CMKOneHub__ProjectTypeService__c();
                                pts.CMKOneHub__ProjectType__c = MerchProjTypeID ;
                                pts.CMKOneHub__Service__c = sr.getId();
                                ptss.add(pts); 
                                
                                rs = new CMKOneHub__retailerService__c();
                                rs.CMKOneHub__retailer__c = walgrn;
                                rs.CMKOneHub__service__c = sr.getId();
                                rs.CMKOneHub__jobManualTemplate__c = 'Standard';
                                rsLst.add(rs);                            
                }
}

insert ptss;        
insert rsLst;


//add attribute
list<CMKOneHub__attribute__c> AttrList = new list<CMKOneHub__attribute__c>();
CMKOneHub__attribute__c obj = new CMKOneHub__attribute__c();

List<String> textAttr = new List<String> {'Overview','Instructions'};

for(string str : textAttr)
{
                obj = new CMKOneHub__attribute__c();
				
                delete [select id from CMKOneHub__RetailerServiceEquipment__c];
delete [select id from CMKOneHub__ServiceQuestionDefinedResponse__c];
delete [select id from CMKOneHub__servicequestion__C];
delete [select id from CMKOneHub__serviceattribute__c];
delete [select id from CMKOneHub__RetailerServiceCertification__c];
delete [select id from CMKOneHub__ProjectTypeService__c];
delete [select id from CMKOneHub__retailerService__c];
delete [select id from CMKOneHub__service__c];
delete [select id from CMKOneHub__attribute__c];
delete [SELECT Id FROM CMKOneHub__LocationAssignment__c];
delete [SELECT Id FROM CMKOneHub__Location__c];
delete [SELECT Id FROM CMKOneHub__Target__c];
delete [select Id from CMKOneHub__question__c];
delete [select Id from CMKOneHub__FulfillmentCenter__c];
delete [SELECT Id FROM CMKOneHub__Certification__c];
delete [SELECT Id FROM CMKOneHub__ProjectType__c];
delete [SELECT Id FROM CMKOneHub__ProjectTypeCustomSettings__c];
delete [SELECT Id FROM CMKOneHub__Equipment__c];
delete [SELECT Id FROM CMKOneHub__Retailer__c];
delete [SELECT Id FROM CMKOneHub__language__c];
delete [SELECT Id FROM Contact WHERE LastName IN ('Crossmark','Premium','Crossmak')];
delete [SELECT Id FROM Account WHERE Name IN ('Crossmark Test EC','Premium Test EC')];
delete [select id from CMKOneHub__ScheduleOption__c];
delete [select id from CMKOneHub__cycle__c];

delete [SELECT ID FROM CMKOneHub__PostalCOde__c];
List<CMKOneHub__PostalCOde__c> posts = new List<CMKOneHub__PostalCOde__c>();

CMKOneHub__PostalCOde__c post = new CMKOneHub__PostalCOde__c();
post.CMKOneHub__DST__c = false;
post.Name = '94127';
post.CMKOneHub__Timezoneoffset__c = -8;
post.CMKOneHub__GeoLocation__latitude__s = 37.7357008082887;
post.CMKOneHub__GeoLocation__longitude__s = -122.45947227415;
posts.add(post);

post = new CMKOneHub__PostalCOde__c();
post.CMKOneHub__DST__c = false;
post.Name = '75024';
post.CMKOneHub__Timezoneoffset__c = -6;
post.CMKOneHub__GeoLocation__latitude__s = 33.07737;
post.CMKOneHub__GeoLocation__longitude__s = -96.80700;
posts.add(post);
insert posts;



integer cnt = [select count() from account where Name IN ('Crossmark Test EC')];
if(cnt==0)
{
	Account acc1 = new Account();
	acc1.Name = 'Crossmark, Inc.';
acc1.recordtype=new recordtype(name='Execution Company');
	insert acc1;
}

cnt = [select count() from account where Name IN ('Premium Test EC')];
if(cnt==0)
{
	Account acc2 = new Account();
    acc2.recordtype=new recordtype(name='Execution Company');
	acc2.Name = 'Premium';
	insert acc2;
}


List<Account> accs = [SELECT Id FROM Account];
Contact c1 = new Contact();
c1.FirstName = 'John Doe';
c1.LastName = 'Crossmark';
c1.Account = accs[0];
insert c1;

Contact c2 = new Contact();
c2.FirstName = 'Jane Doe';
c2.LastName = 'Premium';
c2.Account = accs[1];
insert c2;

CMKOneHub__language__c lng  = new CMKOneHub__language__c();
lng.Name = 'English';
insert lng;

CMKOneHub__Retailer__c[] rts = new CMKOneHub__Retailer__c[]{
   new CMKOneHub__Retailer__c(Name = 'Walgreens', CMKOneHub__OneHubRetailerId__c = 'WALGREENS')
       };
insert rts;

CMKOneHub__Retailer__c retailer = [Select Id,CMKOneHub__OneHubRetailerId__c FROM CMKOneHub__Retailer__c LIMIT 1];

CMKOneHub__ProjectType__c md = new CMKOneHub__ProjectType__c();
md.Name = 'Merchandising';
md.CMKOneHub__minservicecount__c = 1;
md.CMKOneHub__maxservicecount__c = 5;
md.CMKOneHub__maxservicecount__c = 5;
md.CMKOneHub__GracePeriodDuration__c = 0;
md.CMKOneHub__LaunchLeadTime__c = 0;
insert md;


List<CMKOneHub__cycle__c> cyclList = new List<CMKOneHub__cycle__c>();
for (Integer i = 1; i < 5; i++) {
    CMKOneHub__cycle__c cy = new CMKOneHub__cycle__c();
    cy.Name = 'Cycle ' + i;
    cy.CMKOneHub__CycleStartDate__c = date.today().addDays(i);
	cy.CMKOneHub__CycleEndDate__c = date.today().addDays(i+3);
	cy.CMKOneHub__Retailer__c  = retailer.id;
    cyclList.add(cy);
}
insert cyclList;


CMKOneHub__ScheduleOption__c so = new CMKOneHub__ScheduleOption__c();

so.Name = 'Execution Company will Schedule';
so.CMKOneHub__code__c = 'EC';
so.CMKOneHub__description__C='By selecting this schedule option the system will expect the Execution Company to specify the Schedule Date for a Job.';
so.CMKOneHub__isactive__C=true;
insert so;

CMKOneHub__ScheduleOption__c so2 = new CMKOneHub__ScheduleOption__c();
so2.Name = 'Project Builder will Schedule';
so2.CMKOneHub__code__c = 'USER';
so2.CMKOneHub__description__C='By selecting this schedule option the system will expect the User creating the Project to specify the Schedule Date for a Job before the Job is available for an Execution Company to take action.';
so2.CMKOneHub__isactive__C=true;
insert so2;

CMKOneHub__ScheduleOption__c so3 = new CMKOneHub__ScheduleOption__c();
so3.Name = 'SYSTEM';
so3.CMKOneHub__code__c = 'SYSTEM';
so3.CMKOneHub__description__C='By selecting this schedule option the system will set the Schedule Date for a Job based upon settings entered by the User.';
so3.CMKOneHub__isactive__C=false;
insert so3;

CMKOneHub__ProjectTypeCustomSettings__c basePTSetting = new CMKOneHub__ProjectTypeCustomSettings__c ();
basePTSetting.Name = 'Merchandising';
basePTSetting.CMKOneHub__SchedulingStrategyClass__c = 'BaseSchedulingStrategy';
basePTSetting.CMKOneHub__FieldSetName__c = 'BaseProjectFieldset';
basePTSetting.CMKOneHub__ProjectCompletionStrategyClass__c= 'BaseProjectCompletionStrategy';
basePTSetting.CMKOneHub__ReReserveTrackFieldList__c= 'BudgetedLocationsCount__c;StartDate__c;EndDate__c;ResponsibleForExecution__c';
insert basePTSetting;


List<CMKOneHub__Equipment__c> eqpList = new List<CMKOneHub__Equipment__c>();
for (Integer i = 0; i < 5; i++) {
    CMKOneHub__Equipment__c eqp = new CMKOneHub__Equipment__c();
    eqp.Name = 'Equipment ' + i;
    eqpList.add(eqp);
    
}
insert eqpList;

List<CMKOneHub__Location__c> locations = new List <CMKOneHub__Location__c > ();
   
for (Integer i = 1; i <= 1000; i++) {
    CMKOneHub__Location__c location = new CMKOneHub__Location__c();
    location.Name = 'Location ' + i;
    location.CMKOneHub__City__c = 'City ' + i;
    location.CMKOneHub__LocationNumber__c = string.valueOf(i);
    location.CMKOneHub__type__c='Location';
    location.CMKOneHub__isactive__c=true;
    location.CMKOneHub__Retailer__c= retailer.id;
    location.CMKOneHub__OneHubRetailerId__c = retailer.CMKOneHub__OneHubRetailerId__c;
    location.CMKOneHub__Retailer__c = retailer.Id;
    location.CMKOneHub__PostalCode__c = posts[0].id;
    locations.add(location);
}
insert locations;

List<Account> execs = [SELECT Id,Name FROM Account WHERE RecordType.Name = 'Execution Company'];
locations = [SELECT Id,Name FROM CMKOneHub__Location__c];
List<CMKOneHub__LocationAssignment__c> locAssignments = new List <CMKOneHub__LocationAssignment__c > ();
CMKOneHub__ProjectType__c pt = [Select Id,Name FROM CMKOneHub__ProjectType__c LIMIT 1];   
for (Integer i = 0; i < 500; i++) {
    CMKOneHub__LocationAssignment__c locAssignment = new CMKOneHub__LocationAssignment__c();
    locAssignment.CMKOneHub__Location__c = locations[i].Id;
    locAssignment.CMKOneHub__ProjectType__c = pt.Id;
    locAssignment.CMKOneHub__AccountableExecutionCompany__c = execs[0].Id;
    locAssignments.add(locAssignment);
}
for (Integer i = 500; i < 1000; i++) {
    CMKOneHub__LocationAssignment__c locAssignment = new CMKOneHub__LocationAssignment__c();
    locAssignment.CMKOneHub__Location__c = locations[i].Id;
    locAssignment.CMKOneHub__ProjectType__c = pt.Id;
    locAssignment.CMKOneHub__AccountableExecutionCompany__c = execs[1].Id;
    locAssignments.add(locAssignment);
}
insert locAssignments;

List<CMKOneHub__Certification__c> certifications = new list<CMKOneHub__Certification__c>();
for (Integer i = 1; i <= 5; i++) {
    CMKOneHub__Certification__c cert = new CMKOneHub__Certification__c();
    cert.Name = 'Certification ' + i;
    certifications.add(cert);  
}
insert certifications;



String NAMESPACE = 'CMKOneHub__';
List<sObject> targets = new List<sObject>();
for(Integer i=1; i <= 10; i++) {
    CMKOneHub__Target__c s = new CMKOneHub__Target__c();
    s.put('name','Product ' + i  );
    s.put(NAMESPACE + 'Retailer__c', retailer.Id);
    s.put(NAMESPACE +'accountinfo__c', 'test');
    s.put(NAMESPACE +'brandinfo__c','test');
    s.put(NAMESPACE +'CategoryInfo__c','category');
    s.put(NAMESPACE +'departmentname__c', 'dn');
    s.put(NAMESPACE +'departmentnumber__c',123);
    s.put(NAMESPACE +'description__c', 'desc');
    s.put(NAMESPACE +'StockCode__c', ''+ Crypto.getRandomInteger());
    s.put(NAMESPACE +'OneHubRetailerId__c', '1');
    s.put(NAMESPACE +'PackageSizeQty__c', 12);
    s.put(NAMESPACE + 'plu__c', 'plu');
    s.put(NAMESPACE +'ShelfName__c','test');
    s.put(NAMESPACE + 'Status__c','Active');
    s.put(NAMESPACE + 'TargetName__c','cart');
    s.put(NAMESPACE + 'TargetType__C','Product');
    s.put(NAMESPACE + 'UPC__c','up123');
    s.put(NAMESPACE + 'VendorNumber__c',1231);
    s.put(NAMESPACE + 'PackageSizeQty__c',123);
    targets.add(s);
}

insert targets;
//insert material
//QUESTIONS and DEFINED RESPONSES
List<CMKOneHub__Question__c> qs = new List<CMKOneHub__Question__c>();
List<CMKOneHub__QuestionDefinedResponse__c> qdrList = new List<CMKOneHub__QuestionDefinedResponse__c>();
CMKOneHub__QuestionDefinedResponse__c qdr = new CMKOneHub__QuestionDefinedResponse__c();

//Text
CMKOneHub__Question__c q = new CMKOneHub__Question__c();
q.CMKOneHub__QuestionType__c = 'Text';
q.CMKOneHub__QuestionText__c = 'What is the supervisor name?';
q.CMKOneHub__Active__c = true;
q.CMKOneHub__OneHubQuestionId__c = 'OHQ-001';
qs.add(q);

//Number
q = new CMKOneHub__Question__c();
q.CMKOneHub__QuestionType__c = 'Number';
q.CMKOneHub__QuestionText__c = 'How many products did you demo?';
q.CMKOneHub__Active__c = true;
q.CMKOneHub__OneHubQuestionId__c = 'OHQ-002';
qs.add(q);

//Photo
q = new CMKOneHub__Question__c();
q.CMKOneHub__QuestionType__c = 'Photo';
q.CMKOneHub__QuestionText__c = 'Picture of the display?';
q.CMKOneHub__Active__c = true;
q.CMKOneHub__OneHubQuestionId__c = 'OHQ-003';
qs.add(q);

//Item Question
q = new CMKOneHub__Question__c();
q.CMKOneHub__QuestionType__c = 'Number';
q.CMKOneHub__QuestionText__c = 'How many did you purchase?';
q.CMKOneHub__Active__c = true;
q.CMKOneHub__OneHubQuestionId__c = 'OHQ-004';
q.CMKOneHub__TargetType__c = 'Product';
qs.add(q);

insert qs;


//Single-Select List
CMKOneHub__Question__c qss = new CMKOneHub__Question__c();
qss.CMKOneHub__QuestionType__c = 'Single-Select List';
qss.CMKOneHub__QuestionText__c = 'Did you feel prepared for the event?';
qss.CMKOneHub__Active__c = true;
qss.CMKOneHub__OneHubQuestionId__c = 'OHQ-005';
insert qss;

qdrList = new List<CMKOneHub__QuestionDefinedResponse__c>();
qdr = new CMKOneHub__QuestionDefinedResponse__c();
qdr.CMKOneHub__DefinedResponseOrder__c = 1;
qdr.CMKOneHub__DefinedResponseText__c = 'Very Prepared';            
qdr.CMKOneHub__Question__c = qss.id;        
qdrList.add(qdr);


qdr = new CMKOneHub__QuestionDefinedResponse__c();
qdr.CMKOneHub__DefinedResponseOrder__c = 2;
qdr.CMKOneHub__DefinedResponseText__c = 'Prepared';            
qdr.CMKOneHub__Question__c = qss.id;        
qdrList.add(qdr);


qdr = new CMKOneHub__QuestionDefinedResponse__c();
qdr.CMKOneHub__DefinedResponseOrder__c = 2;
qdr.CMKOneHub__DefinedResponseText__c = 'Somewhat Prepared';            
qdr.CMKOneHub__Question__c = qss.id;        
qdrList.add(qdr);

//Yes/No
CMKOneHub__Question__c qyn = new CMKOneHub__Question__c();
qyn.CMKOneHub__QuestionType__c = 'Yes/No';
qyn.CMKOneHub__QuestionText__c = 'Did you start on time?';
qyn.CMKOneHub__Active__c = true;
qyn.CMKOneHub__OneHubQuestionId__c = 'OHQ-006';
insert qyn;


qdr = new CMKOneHub__QuestionDefinedResponse__c();
qdr.CMKOneHub__DefinedResponseOrder__c = 1;
qdr.CMKOneHub__DefinedResponseText__c = 'Yes';            
qdr.CMKOneHub__Question__c = qyn.id;        
qdrList.add(qdr);

qdr = new CMKOneHub__QuestionDefinedResponse__c();
qdr.CMKOneHub__DefinedResponseOrder__c = 2;
qdr.CMKOneHub__DefinedResponseText__c = 'No';            
qdr.CMKOneHub__Question__c = qyn.id;        
qdrList.add(qdr);

insert qdrList;


//FULFILLMENT CENTERS && MATERIALS
List<CMKOneHub__FulfillmentCenter__c> fcs= new List<CMKOneHub__FulfillmentCenter__c>();
CMKOneHub__FulfillmentCenter__c fc = new CMKOneHub__FulfillmentCenter__c();
fc.CMKOneHub__Retailer__c = retailer.Id;
fc.CMKOneHub__OneHubRetailerId__c = 'OHFC-001';
fc.Name = 'Premium';
fcs.add(fc);
        
fc = new CMKOneHub__FulfillmentCenter__c();
fc.Name = 'CTL';
fc.CMKOneHub__Retailer__c = retailer.Id;
fc.CMKOneHub__OneHubRetailerId__c = 'OHFC-002';
fcs.add(fc);

insert fcs;


List<CMKOneHub__FulfillmentCenter__c> fcslist = [Select id, name from CMKOneHub__FulfillmentCenter__c];
CMKOneHub__FulfillmentCenter__c fulfillmentCenter = fcslist[0];

List<CMKOneHub__Material__c> materials = new List<CMKOneHub__Material__c>();

CMKOneHub__Material__c material = new CMKOneHub__Material__c();
material.name = 'Spoon';
material.CMKOneHub__IsActive__c = true;
material.CMKOneHub__Kit__c = false;
material.CMKOneHub__Retailer__c = retailer.Id;
material.CMKOneHub__FulfillmentCenter__c = fulfillmentCenter.Id;
insert material;

material = new CMKOneHub__Material__c();
material.name = 'Sample Kit';
material.CMKOneHub__Kit__c = true;
material.CMKOneHub__Retailer__c = retailer.Id;
material.CMKOneHub__IsActive__c = true;
material.CMKOneHub__FulfillmentCenter__c = fulfillmentCenter.Id;
insert material;


Id MerchProjTypeID = [Select Id from CMKOneHub__ProjectType__c where Name ='Merchandising' LIMIT 1].Id;
List<CMKOneHub__Service__c> svcs= new List<CMKOneHub__Service__c>();

//Add  service__c
List<String> ServNames = new List<String> {'AB Dry','Merchandising','Standard'};

CMKOneHub__Service__c svc = new CMKOneHub__Service__c();
for(string str : ServNames)
{
                svc = new CMKOneHub__Service__c();
                svc.Name = str;
                svc.CMKOneHub__ServiceDescription__c = '';
                svc.CMKOneHub__TargetType__c = 'Category;Product;None';
                svc.CMKOneHub__Duration__c = '6 Hr';        
                svcs.add(svc);
} 


List<Database.Saveresult> insertResults=Database.insert(svcs, false);

List<CMKOneHub__ProjectTypeService__c> ptss= new List<CMKOneHub__ProjectTypeService__c>();
CMKOneHub__ProjectTypeService__c pts = new CMKOneHub__ProjectTypeService__c();

id walgrn = [select id from CMKOneHub__retailer__c where CMKOneHub__OneHubRetailerId__C = 'WALGREENS' limit 1 ].id;

List<CMKOneHub__retailerService__c> rsLst= new List<CMKOneHub__retailerService__c>();
CMKOneHub__retailerService__c rs = new CMKOneHub__retailerService__c();

                                
for (Database.SaveResult sr : insertResults) {
                if (sr.isSuccess()) {                    
                                pts = new CMKOneHub__ProjectTypeService__c();
                                pts.CMKOneHub__ProjectType__c = MerchProjTypeID ;
                                pts.CMKOneHub__Service__c = sr.getId();
                                ptss.add(pts); 
                                
                                rs = new CMKOneHub__retailerService__c();
                                rs.CMKOneHub__retailer__c = walgrn;
                                rs.CMKOneHub__service__c = sr.getId();
                                rs.CMKOneHub__jobManualTemplate__c = 'Standard';
                                rsLst.add(rs);                            
                }
}

insert ptss;        
insert rsLst;


//add attribute
list<CMKOneHub__attribute__c> AttrList = new list<CMKOneHub__attribute__c>();
CMKOneHub__attribute__c obj = new CMKOneHub__attribute__c();

List<String> textAttr = new List<String> {'Overview','Instructions'};

for(string str : textAttr)
{
                obj = new CMKOneHub__attribute__c();
                obj.CMKOneHub__description__c = str;
                obj.CMKOneHub__AttributeType__c = 'Text';
                obj.CMKOneHub__Active__c = true;
                obj.CMKOneHub__AttributeMaxLength__c=5000;
                obj.CMKOneHub__Repeatable__c=false;
                obj.CMKOneHub__Required__c=false;
                AttrList.add(obj);
}

List<String> photoAttr = new List<String> {'Supporting Attachment 1','Job Manual'};

for(string str : photoAttr)
{
                obj = new CMKOneHub__attribute__c();
                obj.CMKOneHub__description__c = str;
                obj.CMKOneHub__AttributeType__c = 'Photo';
                obj.CMKOneHub__Active__c = true;
                obj.CMKOneHub__Repeatable__c=false;
                obj.CMKOneHub__Required__c=false;
                AttrList.add(obj);
}

insert  AttrList;


list<CMKOneHub__serviceAttribute__c> lstSA = new  list<CMKOneHub__serviceAttribute__c>();   
CMKOneHub__serviceAttribute__c saobj= new CMKOneHub__serviceAttribute__c();
                
integer i=0;
integer j=0;

List<String> AttrVal = new List<String> {'Overview','Instructions','Supporting Attachment 1','Job Manual'};
list<CMKOneHub__servicequestion__C> sqList = new list<CMKOneHub__servicequestion__C> ();
CMKOneHub__servicequestion__C sq;

                for(CMKOneHub__ProjectTypeService__c ProjSvc : [Select Id,CMKOneHub__service__c from CMKOneHub__ProjectTypeService__c where CMKOneHub__ProjectType__c 

=: MerchProjTypeID ])
                {              
                                for(string attr : AttrVal)
                                {
                                                i=i+10;
                                                id attrID = [select id from CMKOneHub__attribute__c where CMKOneHub__description__c=:attr limit 1].id;
                                                saobj = new CMKOneHub__serviceAttribute__c(); 
                                                saobj.CMKOneHub__Attribute__c = attrID;
                                                saobj.CMKOneHub__AttributeOrder__c = i;
                                                saobj.CMKOneHub__Service__c =  ProjSvc.CMKOneHub__service__c;
                                                if(attr!='Job Manual')
                                                saobj.CMKOneHub__IsVisible__c = true;            
                                                                else
                                                saobj.CMKOneHub__IsVisible__c = false;            
                                                
                                                lstSA.add(saobj);
                                } 
                                i=0;

                                for(CMKOneHub__question__c qns : [select id from CMKOneHub__question__c  LIMIT 3])
                                {
                                                    j+=1;
                                                                sq= new CMKOneHub__servicequestion__C();
                                                                sq.CMKOneHub__question__C = qns.id;
                                                                sq.CMKOneHub__QuestionNumber__c = j;
                                                                sq.CMKOneHub__Service__c = ProjSvc.CMKOneHub__service__c;
                                                                sqList.add(sq);
                                }              
                                j=0;                        
                }
insert lstSA; 
insert sqList;


CMKOneHub__ServiceQuestionDefinedResponse__c  sqd;
list<CMKOneHub__ServiceQuestionDefinedResponse__c> sqdList = new list<CMKOneHub__ServiceQuestionDefinedResponse__c>();

sqd = new CMKOneHub__ServiceQuestionDefinedResponse__c();
for(CMKOneHub__ProjectTypeService__c ProjSvc : [Select Id,CMKOneHub__ProjectTypeService__c.CMKOneHub__Service__r.id from CMKOneHub__ProjectTypeService__c where 

CMKOneHub__ProjectType__c =: MerchProjTypeID ])
{              
                for(CMKOneHub__question__c   qn : [SELECT CMKOneHub__questiontext__c, CMKOneHub__questiontype__c ,(select id,CMKOneHub__question__c 

,CMKOneHub__service__r.name from CMKOneHub__questions__r where CMKOneHub__service__c =: ProjSvc.CMKOneHub__service__r.id) ,(select CMKOneHub__definedresponsetext__c 

from CMKOneHub__Question_Defined_Response1__r)FROM CMKOneHub__question__c where CMKOneHub__questiontype__c in ('Single-Select','Single-Select List','Multi-Select List','Yes/No') and id in (select CMKOneHub__question__c from CMKOneHub__servicequestion__c where CMKOneHub__service__c =:ProjSvc.CMKOneHub__service__r.id)])
                {
                                
                                for(CMKOneHub__QuestionDefinedResponse__c qdr2: qn.CMKOneHub__Question_Defined_Response1__r){
                                                sqd = new CMKOneHub__ServiceQuestionDefinedResponse__c();
                                                sqd.CMKOneHub__servicequestion__c = qn.CMKOneHub__questions__r[0].id;
                                                sqd.CMKOneHub__QuestionDefinedResponse__c = qdr2.id;
                                                sqdList.add(sqd);
                                }
                }  
}
         
insert sqdList;



//AddRetailerCertfications

                

                
CMKOneHub__RetailerServiceCertification__c rsc;
list<CMKOneHub__RetailerServiceCertification__c> rscList = new list<CMKOneHub__RetailerServiceCertification__c>();

CMKOneHub__RetailerServiceEquipment__c rseq;
list<CMKOneHub__RetailerServiceEquipment__c> rseqList = new list<CMKOneHub__RetailerServiceEquipment__c>();

for(CMKOneHub__ProjectTypeService__c ProjSvc : [Select Id,CMKOneHub__service__c,CMKOneHub__service__r.id,CMKOneHub__service__r.name from 

CMKOneHub__ProjectTypeService__c where CMKOneHub__ProjectType__c=: MerchProjTypeID])        
{
                for(CMKOneHub__Certification__c cert : [select id from CMKOneHub__certification__c LIMIT 2])
                {
                                rsc = new CMKOneHub__RetailerServiceCertification__c();
                                rsc.CMKOneHub__Service__c = ProjSvc.CMKOneHub__service__r.id;
                                rsc.CMKOneHub__Retailer__c = walgrn;
                                rsc.CMKOneHub__certification__c = cert.id;
                                rscList.add(rsc);
                }
                
                for(CMKOneHub__Equipment__c eq2 : [select id from CMKOneHub__Equipment__c limit 2])
                {
                                rseq = new CMKOneHub__RetailerServiceEquipment__c();
                                rseq.CMKOneHub__Service__c = ProjSvc.CMKOneHub__service__r.id;
                                rseq.CMKOneHub__Retailer__c = walgrn;
                                rseq.CMKOneHub__Equipment__c = eq2.id;
                                
                                rseq.CMKOneHub__IsLocked__c = true;
                                rseq.CMKOneHub__Quantity__c = 1;
                                
                                rseqList.add(rseq);
                }
}  

insert rscList;
insert rseqList;



System.schedule('Scheduled Job 1', '0 0 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 2', '0 5 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 3', '0 10 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 4', '0 15 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 5', '0 20 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 6', '0 25 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 7', '0 30 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 8', '0 35 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 9', '0 40 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 10', '0 45 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 11', '0 50 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 12', '0 55 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());

                obj.CMKOneHub__AttributeType__c = 'Text';
                obj.CMKOneHub__Active__c = true;
                obj.CMKOneHub__AttributeMaxLength__c=5000;
                obj.CMKOneHub__Repeatable__c=false;
                obj.CMKOneHub__Required__c=false;
                AttrList.add(obj);
}

List<String> photoAttr = new List<String> {'Supporting Attachment 1','Job Manual'};

for(string str : photoAttr)
{
                obj = new CMKOneHub__attribute__c();
				obj.CMKOneHub__Attributetitle__c = str;
                obj.CMKOneHub__description__c = str;
                obj.CMKOneHub__AttributeType__c = 'Photo';
                obj.CMKOneHub__Active__c = true;
                obj.CMKOneHub__Repeatable__c=false;
                obj.CMKOneHub__Required__c=false;
                AttrList.add(obj);
}

insert  AttrList;


list<CMKOneHub__serviceAttribute__c> lstSA = new  list<CMKOneHub__serviceAttribute__c>();   
CMKOneHub__serviceAttribute__c saobj= new CMKOneHub__serviceAttribute__c();
                
integer i=0;
integer j=0;

List<String> AttrVal = new List<String> {'Overview','Instructions','Supporting Attachment 1','Job Manual'};
list<CMKOneHub__servicequestion__C> sqList = new list<CMKOneHub__servicequestion__C> ();
CMKOneHub__servicequestion__C sq;

                for(CMKOneHub__ProjectTypeService__c ProjSvc : [Select Id,CMKOneHub__service__c from CMKOneHub__ProjectTypeService__c where CMKOneHub__ProjectType__c 

=: MerchProjTypeID ])

                {              
                                for(string attr : AttrVal)
                                {
                                                i=i+10;
                                                id attrID = [select id from CMKOneHub__attribute__c where CMKOneHub__description__c=:attr limit 1].id;
                                                saobj = new CMKOneHub__serviceAttribute__c(); 
                                                saobj.CMKOneHub__Attribute__c = attrID;
                                                saobj.CMKOneHub__AttributeOrder__c = i;
                                                saobj.CMKOneHub__Service__c =  ProjSvc.CMKOneHub__service__c;
                                                if(attr!='Job Manual')
                                                saobj.CMKOneHub__IsVisible__c = true;            
                                                                else
                                                saobj.CMKOneHub__IsVisible__c = false;            
                                                
                                                lstSA.add(saobj);
                                } 
                                i=0;

                                for(CMKOneHub__question__c qns : [select id from CMKOneHub__question__c  LIMIT 3])
                                {
                                                    j+=1;
                                                                sq= new CMKOneHub__servicequestion__C();
                                                                sq.CMKOneHub__question__C = qns.id;
                                                                sq.CMKOneHub__QuestionNumber__c = j;
                                                                sq.CMKOneHub__Service__c = ProjSvc.CMKOneHub__service__c;
                                                                sqList.add(sq);
                                }              
                                j=0;                        
                }
insert lstSA; 
insert sqList;


CMKOneHub__ServiceQuestionDefinedResponse__c  sqd;
list<CMKOneHub__ServiceQuestionDefinedResponse__c> sqdList = new list<CMKOneHub__ServiceQuestionDefinedResponse__c>();

sqd = new CMKOneHub__ServiceQuestionDefinedResponse__c();
for(CMKOneHub__ProjectTypeService__c ProjSvc : [Select Id,CMKOneHub__ProjectTypeService__c.CMKOneHub__Service__r.id from CMKOneHub__ProjectTypeService__c where 

CMKOneHub__ProjectType__c =: MerchProjTypeID ])
{              
                for(CMKOneHub__question__c   qn : [SELECT CMKOneHub__questiontext__c, CMKOneHub__questiontype__c ,(select id,CMKOneHub__question__c 

,CMKOneHub__service__r.name from CMKOneHub__questions__r where CMKOneHub__service__c =: ProjSvc.CMKOneHub__service__r.id) ,(select CMKOneHub__definedresponsetext__c 

from CMKOneHub__Question_Defined_Response1__r)FROM CMKOneHub__question__c where CMKOneHub__questiontype__c in ('Single-Select','Single-Select List','Multi-Select List','Yes/No') and id in (select CMKOneHub__question__c from CMKOneHub__servicequestion__c where CMKOneHub__service__c =:ProjSvc.CMKOneHub__service__r.id)])
                {
                                
                                for(CMKOneHub__QuestionDefinedResponse__c qdr2: qn.CMKOneHub__Question_Defined_Response1__r){
                                                sqd = new CMKOneHub__ServiceQuestionDefinedResponse__c();
                                                sqd.CMKOneHub__servicequestion__c = qn.CMKOneHub__questions__r[0].id;
                                                sqd.CMKOneHub__QuestionDefinedResponse__c = qdr2.id;
                                                sqdList.add(sqd);
                                }
                }  
}
         
insert sqdList;



//AddRetailerCertfications

                

                
CMKOneHub__RetailerServiceCertification__c rsc;
list<CMKOneHub__RetailerServiceCertification__c> rscList = new list<CMKOneHub__RetailerServiceCertification__c>();

CMKOneHub__RetailerServiceEquipment__c rseq;
list<CMKOneHub__RetailerServiceEquipment__c> rseqList = new list<CMKOneHub__RetailerServiceEquipment__c>();

for(CMKOneHub__ProjectTypeService__c ProjSvc : [Select Id,CMKOneHub__service__c,CMKOneHub__service__r.id,CMKOneHub__service__r.name from 

CMKOneHub__ProjectTypeService__c where CMKOneHub__ProjectType__c=: MerchProjTypeID])        
{
                for(CMKOneHub__Certification__c cert : [select id from CMKOneHub__certification__c LIMIT 2])
                {
                                rsc = new CMKOneHub__RetailerServiceCertification__c();
                                rsc.CMKOneHub__Service__c = ProjSvc.CMKOneHub__service__r.id;
                                rsc.CMKOneHub__Retailer__c = walgrn;
                                rsc.CMKOneHub__certification__c = cert.id;
                                rscList.add(rsc);
                }
                
                for(CMKOneHub__Equipment__c eq2 : [select id from CMKOneHub__Equipment__c limit 2])
                {
                                rseq = new CMKOneHub__RetailerServiceEquipment__c();
                                rseq.CMKOneHub__Service__c = ProjSvc.CMKOneHub__service__r.id;
                                rseq.CMKOneHub__Retailer__c = walgrn;
                                rseq.CMKOneHub__Equipment__c = eq2.id;
                                
                                rseq.CMKOneHub__IsLocked__c = true;
                                rseq.CMKOneHub__Quantity__c = 1;
                                
                                rseqList.add(rseq);
                }
}  

insert rscList;
insert rseqList;



System.schedule('Scheduled Job 1', '0 0 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 2', '0 5 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 3', '0 10 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 4', '0 15 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 5', '0 20 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 6', '0 25 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 7', '0 30 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 8', '0 35 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 9', '0 40 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 10', '0 45 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 11', '0 50 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 12', '0 55 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());

                obj.CMKOneHub__AttributeType__c = 'Text';
                obj.CMKOneHub__Active__c = true;
                obj.CMKOneHub__AttributeMaxLength__c=5000;
                obj.CMKOneHub__Repeatable__c=false;
                obj.CMKOneHub__Required__c=false;
                AttrList.add(obj);
}

List<String> photoAttr = new List<String> {'Supporting Attachment 1','Job Manual'};

for(string str : photoAttr)
{
                obj = new CMKOneHub__attribute__c();
				obj.CMKOneHub__Attributetitle__c = str;
                obj.CMKOneHub__description__c = str;
                obj.CMKOneHub__AttributeType__c = 'Photo';
                obj.CMKOneHub__Active__c = true;
                obj.CMKOneHub__Repeatable__c=false;
                obj.CMKOneHub__Required__c=false;
                AttrList.add(obj);
}

insert  AttrList;


list<CMKOneHub__serviceAttribute__c> lstSA = new  list<CMKOneHub__serviceAttribute__c>();   
CMKOneHub__serviceAttribute__c saobj= new CMKOneHub__serviceAttribute__c();
                
integer i=0;
integer j=0;

List<String> AttrVal = new List<String> {'Overview','Instructions','Supporting Attachment 1','Job Manual'};
list<CMKOneHub__servicequestion__C> sqList = new list<CMKOneHub__servicequestion__C> ();
CMKOneHub__servicequestion__C sq;

                for(CMKOneHub__ProjectTypeService__c ProjSvc : [Select Id,CMKOneHub__service__c from CMKOneHub__ProjectTypeService__c where CMKOneHub__ProjectType__c 

=: MerchProjTypeID ])
                {              
                                for(string attr : AttrVal)
                                {
                                                i=i+10;
                                                id attrID = [select id from CMKOneHub__attribute__c where CMKOneHub__description__c=:attr limit 1].id;
                                                saobj = new CMKOneHub__serviceAttribute__c(); 
                                                saobj.CMKOneHub__Attribute__c = attrID;
                                                saobj.CMKOneHub__AttributeOrder__c = i;
                                                saobj.CMKOneHub__Service__c =  ProjSvc.CMKOneHub__service__c;
                                                if(attr!='Job Manual')
                                                saobj.CMKOneHub__IsVisible__c = true;            
                                                                else
                                                saobj.CMKOneHub__IsVisible__c = false;            
                                                
                                                lstSA.add(saobj);
                                } 
                                i=0;

                                for(CMKOneHub__question__c qns : [select id from CMKOneHub__question__c  LIMIT 3])
                                {
                                                    j+=1;
                                                                sq= new CMKOneHub__servicequestion__C();
                                                                sq.CMKOneHub__question__C = qns.id;
                                                                sq.CMKOneHub__QuestionNumber__c = j;
                                                                sq.CMKOneHub__Service__c = ProjSvc.CMKOneHub__service__c;
                                                                sqList.add(sq);
                                }              
                                j=0;                        
                }
insert lstSA; 
insert sqList;


CMKOneHub__ServiceQuestionDefinedResponse__c  sqd;
list<CMKOneHub__ServiceQuestionDefinedResponse__c> sqdList = new list<CMKOneHub__ServiceQuestionDefinedResponse__c>();

sqd = new CMKOneHub__ServiceQuestionDefinedResponse__c();
for(CMKOneHub__ProjectTypeService__c ProjSvc : [Select Id,CMKOneHub__ProjectTypeService__c.CMKOneHub__Service__r.id from CMKOneHub__ProjectTypeService__c where 

CMKOneHub__ProjectType__c =: MerchProjTypeID ])
{              
                for(CMKOneHub__question__c   qn : [SELECT CMKOneHub__questiontext__c, CMKOneHub__questiontype__c ,(select id,CMKOneHub__question__c 

,CMKOneHub__service__r.name from CMKOneHub__questions__r where CMKOneHub__service__c =: ProjSvc.CMKOneHub__service__r.id) ,(select CMKOneHub__definedresponsetext__c 

from CMKOneHub__Question_Defined_Response1__r)FROM CMKOneHub__question__c where CMKOneHub__questiontype__c in ('Single-Select','Single-Select List','Multi-Select List','Yes/No') and id in (select CMKOneHub__question__c from CMKOneHub__servicequestion__c where CMKOneHub__service__c =:ProjSvc.CMKOneHub__service__r.id)])
                {
                                
                                for(CMKOneHub__QuestionDefinedResponse__c qdr2: qn.CMKOneHub__Question_Defined_Response1__r){
                                                sqd = new CMKOneHub__ServiceQuestionDefinedResponse__c();
                                                sqd.CMKOneHub__servicequestion__c = qn.CMKOneHub__questions__r[0].id;
                                                sqd.CMKOneHub__QuestionDefinedResponse__c = qdr2.id;
                                                sqdList.add(sqd);
                                }
                }  
}
         
insert sqdList;



//AddRetailerCertfications

                

                
CMKOneHub__RetailerServiceCertification__c rsc;
list<CMKOneHub__RetailerServiceCertification__c> rscList = new list<CMKOneHub__RetailerServiceCertification__c>();

CMKOneHub__RetailerServiceEquipment__c rseq;
list<CMKOneHub__RetailerServiceEquipment__c> rseqList = new list<CMKOneHub__RetailerServiceEquipment__c>();

for(CMKOneHub__ProjectTypeService__c ProjSvc : [Select Id,CMKOneHub__service__c,CMKOneHub__service__r.id,CMKOneHub__service__r.name from 

CMKOneHub__ProjectTypeService__c where CMKOneHub__ProjectType__c=: MerchProjTypeID])        
{
                for(CMKOneHub__Certification__c cert : [select id from CMKOneHub__certification__c LIMIT 2])
                {
                                rsc = new CMKOneHub__RetailerServiceCertification__c();
                                rsc.CMKOneHub__Service__c = ProjSvc.CMKOneHub__service__r.id;
                                rsc.CMKOneHub__Retailer__c = walgrn;
                                rsc.CMKOneHub__certification__c = cert.id;
                                rscList.add(rsc);
                }
                
                for(CMKOneHub__Equipment__c eq2 : [select id from CMKOneHub__Equipment__c limit 2])
                {
                                rseq = new CMKOneHub__RetailerServiceEquipment__c();
                                rseq.CMKOneHub__Service__c = ProjSvc.CMKOneHub__service__r.id;
                                rseq.CMKOneHub__Retailer__c = walgrn;
                                rseq.CMKOneHub__Equipment__c = eq2.id;
                                
                                rseq.CMKOneHub__IsLocked__c = true;
                                rseq.CMKOneHub__Quantity__c = 1;
                                
                                rseqList.add(rseq);
                }
}  

insert rscList;
insert rseqList;



System.schedule('Scheduled Job 1', '0 0 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 2', '0 5 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 3', '0 10 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 4', '0 15 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 5', '0 20 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 6', '0 25 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 7', '0 30 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 8', '0 35 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 9', '0 40 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 10', '0 45 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 11', '0 50 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());
System.schedule('Scheduled Job 12', '0 55 * * * ?', new CMKOneHub.ScheduledProjectStatusChange());