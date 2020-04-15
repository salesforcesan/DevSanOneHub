public with sharing class ProjectManagementController {

	public String filterSelections {get;private set;}

	public ProjectManagementController() {

		//load pre-selected filter selections (optional)
		filterSelections = ApexPages.currentPage().getParameters().get('fs');
	}

	@RemoteAction
	@ReadOnly
	public static Project[] filterProjects(Map<String, String> filterMap) {

		if (filterMap == null) filterMap = new Map<String, String>();

		system.debug('filterMap' + filterMap);
		String baseQuery = 'SELECT Id, Name, ProjectNumber__c, StartDate__c, EndDate__c, ProjectLaunchDate__c, Owner.Name, LocationTotalCount__c, (SELECT Id, Service__r.Name FROM ProjectServices__r), (SELECT Id, Account__r.Name FROM Project_Accounts__r)'
						+ ' FROM Project__c'
						+ ' WHERE IsDeleted__c = false';

		Map<String, String> filterLabelToAPIName = new Map<String, String>{
			'Number' => 'ProjectNumber__c'
        	, 'Title' => 'Name'
        	, 'Suppliers' => 'Account__r.Name'
        	, 'Services' => 'Service__r.Name'
        	, '# Locations' => 'LocationTotalCount__c'
        	// TODO , '# Jobs' => '' NOTE: This one can be filtered by related object, but the requirement is to filter on the count, which is not possible without a custom count field
        	, 'Start Date' => 'StartDate__c'
        	, 'End Date' => 'EndDate__c'
        	, 'Launch Date' => 'ProjectLaunchDate__c'
        	, 'Owner' => 'Owner.Name'
    	};

    	String whereClause = '';
		system.debug('keySet' + filterMap.keySet());

		for (String filterLabel : filterMap.keySet()) {

			system.debug('filterLabel' + filterLabel);
			if (filterLabelToAPIName.containsKey(filterLabel)){

				String apiName = filterLabelToAPIName.get(filterLabel);
				Boolean searchTypeIsString = (new Set<String>{ 'Number', 'Title', 'Owner', 'Suppliers', 'Services' }).contains(filterLabel);

				String aggregatedSearchStrings = '';
				for (String searchString : filterMap.get(filterLabel).split(',')) {

					searchString = String.escapeSingleQuotes(searchString.trim());

					if (searchTypeIsString && searchString.toLowerCase() == 'null') searchString = '';

					if (searchTypeIsString && !String.isBlank(searchString)) {
						aggregatedSearchStrings += apiName + ' LIKE \'%' + searchString + '%\' OR ';
					} else {
						aggregatedSearchStrings += searchString + ',';
					}
				}

				aggregatedSearchStrings = aggregatedSearchStrings.removeEnd(',').removeEnd(' OR ');

				if (!String.isBlank(aggregatedSearchStrings)) {

					if (filterLabel == 'Start Date' || filterLabel == 'End Date' || filterLabel == 'Launch Date') {
						aggregatedSearchStrings = String.valueOf(Date.parse(aggregatedSearchStrings));
						whereClause += ' AND ' + apiName + ' = ' + aggregatedSearchStrings;
					} else if (filterLabel == 'Suppliers') {
						whereClause += ' AND Id IN (SELECT Project__c FROM ProjectAccount__c WHERE Project__r.IsDeleted__c = false AND (' + aggregatedSearchStrings + '))';
					} else if (filterLabel == 'Services') {
						whereClause += ' AND Id IN (SELECT Project__c FROM ProjectService__c WHERE Project__r.IsDeleted__c = false AND (' + aggregatedSearchStrings + '))';
					} else if (searchTypeIsString) {
						whereClause += ' AND (' + aggregatedSearchStrings + ')';
					} else {
						whereClause += ' AND ' + apiName + ' IN (' + aggregatedSearchStrings + ')';
					}
				}
			}
		}

		String orderBy = ' ORDER BY Name';
		String query = baseQuery + whereClause + orderBy;

		Map<Id, Project> outputMap = new Map<Id, Project>();
		System.debug('DEVDEBUG Querying: ' + query);
		for (Project__c project : Database.query(query)) {
			outputMap.put(project.Id, new Project(project));
		}

		for (AggregateResult res : [SELECT Project__c, count(Id) recCount FROM Job__c WHERE Project__c IN :outputMap.keySet() GROUP BY Project__c]) {
			outputMap.get((Id) res.get('Project__c')).numberOfJobs = String.valueOf((Integer) res.get('recCount'));
		}

		return outputMap.values();
	}

	//fetch a list of possible filters
    @ReadOnly
    @RemoteAction
    public static Filter[] getFilters() {

    	SelectOption[] servicesOptions = new SelectOption[]{};
    	for (AggregateResult res : [SELECT Service__c value, Service__r.Name label FROM ProjectService__c WHERE Project__r.IsDeleted__c = false GROUP BY Service__c, Service__r.Name]) {
    		servicesOptions.add(new SelectOption((Id) res.get('value'), (String) res.get('label')));
    	}

        return new Filter[]{
        	new Filter('Number', 'text', new SelectOption[]{})
        	, new Filter('Title', 'text', new SelectOption[]{})
        	, new Filter('Suppliers', 'text', new SelectOption[]{})
        	, new Filter('Services', 'picklist', servicesOptions)
        	, new Filter('# Locations', 'text-operator', new SelectOption[]{})
        	, new Filter('# Jobs', 'text-operator', new SelectOption[]{})
        	, new Filter('Start Date', 'date-operator', new SelectOption[]{})
        	, new Filter('End Date', 'date-operator', new SelectOption[]{})
        	, new Filter('Launch Date', 'date-operator', new SelectOption[]{})
        	, new Filter('Owner', 'text', new SelectOption[]{})
        };
    }

    @ReadOnly
    @RemoteAction
    public static SummaryCount[] getProjectSummary() {
    	SummaryCount[] output = new SummaryCount[]{
    		new SummaryCount('My Projects', [SELECT count() FROM Project__c WHERE OwnerId = :UserInfo.getUserId()])
    	};

    	Map<String, Integer> statusToResultCount = new Map<String, Integer>();
    	for (AggregateResult res : [SELECT Status__c status, count(Id) projectCount FROM Project__c WHERE Status__c IN ('Planning', 'Booked', 'Pending', 'In Progress', 'Ended', 'Canceled', 'Closed') GROUP BY Status__c]) {
    		statusToResultCount.put((String) res.get('status'), (Integer) res.get('projectCount'));
    	}

    	output.add(new SummaryCount('Planning', statusToResultCount.get('Planning')));
    	output.add(new SummaryCount('Booked', statusToResultCount.get('Booked')));
    	output.add(new SummaryCount('Launched', statusToResultCount.get('Pending')));
    	output.add(new SummaryCount('In Progress', statusToResultCount.get('In Progress')));
    	output.add(new SummaryCount('Ended', statusToResultCount.get('Ended')));
    	output.add(new SummaryCount('Canceled', statusToResultCount.get('Canceled')));
    	output.add(new SummaryCount('Closed', statusToResultCount.get('Closed')));

    	return output;
    }

    public class SummaryCount {
    	public String label;
    	public Integer count;
    	public SummaryCount(String label, Integer count) {
    		this.label = label;
    		this.count = count;
    	}
    }

	public class Project {
        public String id {get;set;}
		public String projectNumber {get;set;}
		public String title {get;set;}
		public String[] suppliers {get;set;}
		public String[] services {get;set;}
		public String numberOfLocations {get;set;}
		public String numberOfJobs {get;set;}
		public String startDate {get;set;}
		public String endDate {get;set;}
		public String launchDate {get;set;}
		public String owner {get;set;}

		public Project(Project__c project){

            this.id = project.Id;
			this.projectNumber = project.ProjectNumber__c;
			this.title = project.Name;
			this.numberOfLocations = '' + project.LocationTotalCount__c;
			//this.numberOfJobs = '' + project.Jobs__r.size();
			this.startDate = project.StartDate__c == null ? '' : project.StartDate__c.format();
			this.endDate = project.EndDate__c == null ? '' : project.EndDate__c.format();
			this.launchDate = project.ProjectLaunchDate__c == null ? '' : project.ProjectLaunchDate__c.format();
			this.owner = project.Owner.Name;

			this.suppliers = new String[]{};
			for (ProjectAccount__c projectAccount : project.Project_Accounts__r) this.suppliers.add(projectAccount.Account__r.Name);

			this.services = new String[]{};
			for (ProjectService__c projService : project.ProjectServices__r) this.services.add(projService.Service__r.Name);
		}
	}

	public class Filter {
        public String label { get; set; }
        public SelectOption[] options { get; set; }
        public String type { get; set; }
        public Filter(String label, String type, SelectOption[] options) {
            this.label = label;
            this.type = type;
            this.options = options;
        }
    }

    public class SelectOption {
        public String value { get; set; }
        public String label { get; set; }
        public Boolean selected { get; set; }
        public SelectOption(String value, String label) {
            this.value = value;
            this.label = label;
            selected = false;
        }
    }

}