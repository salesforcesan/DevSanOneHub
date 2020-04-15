@isTest
public class ImportRequestQueueTestUtil {
	public static final String SCHEDULE_DATE;
	public static final String START_TIME = '10:00 AM';
	public static final Integer TIME_ESTIMATE = 55;
	public static final Integer NUM_OF_WORKERS = 1;
	public static final Double PURCHASE_AMOUNT = 35.55;
	public static final Integer TOTAL_COUNT = 1000;
	public static final String ERROR_MSG = 'error';

	static {
		SCHEDULE_DATE = Datetime.now()
		                .addDays(1)
		                .format('yyyy-MM-dd');
	}

	public static List<List<String>> genAttachmentContent() {
		List<Job__c> jobs = getJobs();
		List<List<String>> content = new List<List<String>>();
		for (Job__c job : jobs) {
			content.add(genLine(job, true));
		}
		return content;
	}

	static List<String> genLine(Job__c j, boolean testValidData) {
		List<String> line = new List<String>();
		line.add(j.ProjectNumber__c);
		line.add(j.ProjectName__c);
		line.add(j.Name);
		line.add(j.ProjectService__r.Name);
		line.add(j.ProjectLocation__r.Name);
		line.add(j.ServiceName__c);
		line.add(j.Location__c);
		line.add(j.LocationNumber__c);
		line.add(j.LocationState__c);
		line.add(j.Location__r.City__c);
		line.add(String.valueOf(j.NumberOfWorkers__c));
		line.add(SCHEDULE_DATE);
		line.add(testValidData ? START_TIME : '10:00');
		line.add(String.valueOf(PURCHASE_AMOUNT));
		line.add(String.valueOf(TIME_ESTIMATE));
		return line;
	}

	public static List<ImportRequestQueueItem__c> getQueueItems() {
		return [
		         SELECT
		         Status__c,
		         RecordCount__c,
		         SuccessCount__c,
		         ErrorCount__c,
		         Response__c
		         FROM ImportRequestQueueItem__c
		       ];
	}

	public static Boolean isQueueItemsCompleted() {
		List<ImportRequestQueueItem__c> qs = getQueueItems();
		Boolean completed = true;
		for (ImportRequestQueueItem__c q : qs) {
			if (q.Status__c != 'Completed') {
				completed = false;
				break;
			}
		}
		return completed;
	}

	public static String getQueueItemsStatus() {
		List<ImportRequestQueueItem__c> qs = getQueueItems();
		List<String> status = new List<String>();
		for (ImportRequestQueueItem__c q : qs) {
			status.add(q.Status__c + ':' + q.Response__c);
		}
		return String.join(status, '|');
	}


	public static List<Job__c> getJobs() {
		return [
		         SELECT
		         ProjectNumber__c,
		         ProjectName__c,
		         Name,
		         ProjectService__r.Name,
		         ProjectLocation__r.Name,
		         ServiceName__c,
		         Location__c,
		         Location__r.City__c,
		         LocationNumber__c,
		         LocationState__c,
		         NumberOfWorkers__c,
		         JobScheduledDate__c,
		         JobStartTime__c,
		         PurchaseAmount__c,
		         EstimatedMinutesOverride__c
		         FROM Job__c
		       ];
	}
	public static void setupQueueTestData() {
		setupQueueTestData(true);
	}
	public static void setupQueueTestData(Boolean testValidData) {
		Project__c project = TestProject.getProjects()[0];

		User user = [Select Id from User limit 1];
		Datasource__c ds = [SELECT Id FROM Datasource__c Limit 1];
		ImportRequestQueue__c que = new ImportRequestQueue__c(
		  Datasource__c = ds.Id,
		  RequestDate__c = Datetime.now(),
		  StartTime__c = Datetime.now(),
		  Status__c = 'Queued',
		  Requestor__c = user.Id,
		  Notified__c = false
		);
		insert que;

		List<ImportRequestQueueItem__c> queTasks = new List<ImportRequestQueueItem__c>();
		List<Job__c> jobs = getJobs();
		List<List<String>> attBody1 = new List<List<String>>();
		List<List<String>> attBody2 = new List<List<String>>();
		for (Integer i = 0; i < jobs.size(); i++) {
			if (Math.mod(i, 2) == 0) {
				attBody2.add(genLine(jobs.get(i), testValidData));
			} else {
				attBody1.add(genLine(jobs.get(i), testValidData));
			}
		}

		String attId = genJsonAttachment('import-request-queue', que.Id, attBody1);
		queTasks.add(new ImportRequestQueueItem__c(
		               Queue__c = que.Id,
		               Project__c = project.Id,
		               AttachmentId__c = attId,
		               RecordCount__c = attBody1.size(),
		               SuccessCount__c = 0,
		               ErrorCount__c = 0,
		               Status__c = 'Queued'
		             ));

		attId = genJsonAttachment('import-request-queue', que.Id, attBody2);
		queTasks.add(new ImportRequestQueueItem__c(
		               Queue__c = que.Id,
		               Project__c = project.Id,
		               RecordCount__c = attBody2.size(),
		               SuccessCount__c = 0,
		               ErrorCount__c = 0,
		               AttachmentId__c = attId,
		               Status__c = 'Queued'
		             ));

		insert queTasks;
	}

	public static String genJsonAttachment(String name, String parentId, Object body) {
		Attachment att = new Attachment(
		  Body = Blob.valueOf(JSON.serialize(body)),
		  ContentType = 'application/json',
		  ParentId = parentId,
		  Name = name
		);
		insert att;
		return att.Id;
	}

	public static void setupDatasource() {
		List<DataSource__c> dsRS = [SELECT Id from DataSource__c];
		if (dsRS.size() > 0) {
			delete dsRS;
		}

		DataSource__c ds = new DataSource__c(
		  name = 'Import Jobs From Program',
		  StopImport__c = true,
		  TargetObject__c = 'Job__c',
		  LockProject__c = true,
		  Description__c = 'Import jobs from the program.',
		  ConsumerApexClass__c = 'ImportQueueItemConsumer'
		);
		insert ds;

		List<DataSourceSchema__c> schemaRS = [SELECT Id FROM DataSourceSchema__c];
		if (schemaRS.size() > 0) {
			delete schemaRS;
		}

		schemaRS = new List<DataSourceSchema__c>();
		schemaRS.add(new DataSourceSchema__c(
		               DataSource__c = ds.Id,
		               Title__c = 'Project Number',
		               Field__c = 'ProjectNumber__c',
		               DataType__c = 'Text',
		               GroupBy__c = true,
		               Key__c = true,
		               Required__c = true,
		               Updatable__c = false,
		               Order__c = 5
		             ));

		schemaRS.add(new DataSourceSchema__c(
		               DataSource__c = ds.Id,
		               Title__c = 'Project: Project Title',
		               DataType__c = 'Text',
		               Key__c = false,
		               GroupBy__c = true,
		               Updatable__c = false,
		               Order__c = 10
		             ));

		schemaRS.add(new DataSourceSchema__c(
		               DataSource__c = ds.Id,
		               Key__c = true,
		               DataType__c = 'Text',
		               Title__c = 'Job ID',
		               Field__c = 'Name',
		               Updatable__c = false,
		               Required__c = true,
		               Order__c = 15
		             ));

		schemaRS.add(new DataSourceSchema__c(
		               DataSource__c = ds.Id,
		               Title__c = 'Project Service',
		               DataType__c = 'Text',
		               Updatable__c = false,
		               Order__c = 20
		             ));

		schemaRS.add(new DataSourceSchema__c(
		               DataSource__c = ds.Id,
		               Title__c = 'Project Location',
		               DataType__c = 'Text',
		               Updatable__c = false,
		               Order__c = 25
		             ));

		schemaRS.add(new DataSourceSchema__c(
		               DataSource__c = ds.Id,
		               Title__c = 'Service Title',
		               DataType__c = 'Text',
		               Updatable__c = false,
		               Order__c = 30
		             ));

		schemaRS.add(new DataSourceSchema__c(
		               DataSource__c = ds.Id,
		               Title__c = 'Location ID',
		               DataType__c = 'Text',
		               Updatable__c = false,
		               Order__c = 35
		             ));

		schemaRS.add(new DataSourceSchema__c(
		               DataSource__c = ds.Id,
		               Title__c = 'Location Number',
		               DataType__c = 'Text',
		               Updatable__c = false,
		               Order__c = 40
		             ));

		schemaRS.add(new DataSourceSchema__c(
		               DataSource__c = ds.Id,
		               Title__c = 'State',
		               DataType__c = 'Text',
		               Order__c = 45
		             ));

		schemaRS.add(new DataSourceSchema__c(
		               DataSource__c = ds.Id,
		               Title__c = 'City',
		               DataType__c = 'Text',
		               Updatable__c = false,
		               Key__c = false,
		               Order__c = 50
		             ));

		schemaRS.add(new DataSourceSchema__c(
		               DataSource__c = ds.Id,
		               Title__c = 'Number of Workers',
		               Field__c = 'NumberOfWorkers__c',
		               DataType__c = 'Number',
		               Updatable__c = true,
		               Key__c = false,
		               Order__c = 55
		             ));

		schemaRS.add(new DataSourceSchema__c(
		               DataSource__c = ds.Id,
		               Title__c = 'Scheduled Date',
		               Field__c = 'JobScheduledDate__c',
		               Updatable__c = true,
		               Key__c = false,
		               DataType__c = 'Date',
		               Order__c = 60
		             ));

		schemaRS.add(new DataSourceSchema__c(
		               DataSource__c = ds.Id,
		               Title__c = 'Start Time',
		               Field__c = 'JobStartTime__c',
		               DataType__c = 'Time',
		               Updatable__c = true,
		               Order__c = 65
		             ));

		schemaRS.add(new DataSourceSchema__c(
		               DataSource__c = ds.Id,
		               Title__c = 'Purchase Amount',
		               Field__c = 'PurchaseOverRideAmount__c',
		               DataType__c = 'Float',
		               Updatable__c = true,
		               Order__c = 70
		             ));

		schemaRS.add(new DataSourceSchema__c(
		               DataSource__c = ds.Id,
		               Title__c = 'Time Estimate (Minutes)',
		               Field__c = 'EstimatedMinutesOverride__c',
		               DataType__c = 'Number',
		               Updatable__c = true,
		               Order__c = 75
		             ));

		insert schemaRS;

		List<DatasourceGuide__c> guideRS = [SELECT Id from DatasourceGuide__c];
		if (guideRS.size() > 0) {
			delete guideRS;
		}

		guideRS = new List<DatasourceGuide__c>();
		guideRS.add(new DatasourceGuide__c(
		              order__c = 5,
		              active__c = true,
		              DataSource__c = ds.Id,
		              Guide__c = 'You can only import jobs from the projects belonging to the same program.'
		            ));

		guideRS.add(new DatasourceGuide__c(
		              order__c = 1,
		              active__c = true,
		              DataSource__c = ds.Id,
		              Guide__c = 'Jobs can be imported if the project status is in Planning, Booked, Launched or In Progress.'
		            ));

		guideRS.add(new DatasourceGuide__c(
		              order__c = 3,
		              active__c = true,
		              DataSource__c = ds.Id,
		              Guide__c = 'Jobs can only be imported for the 1H team or OH Mobile.'
		            ));


		guideRS.add(new DatasourceGuide__c(
		              order__c = 10,
		              active__c = true,
		              DataSource__c = ds.Id,
		              Guide__c = 'The Schedued date must be in the format "YYYY-MM-dd". For example, 2019-10-02'
		            ));
		guideRS.add(new DatasourceGuide__c(
		              order__c = 15,
		              active__c = true,
		              DataSource__c = ds.Id,
		              Guide__c = 'The start time format is "HH:ss". For example, 13:01'
		            ));

		insert guideRS;
	}
}