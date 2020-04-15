public with sharing class ProjectPhotoViewerRequest extends LightningRequestBase {
    private PhotoViewerFilterQueryGetter queryGetter;

    String AppUsage {get;set;}
    String AccountId {get;set;}
    String ProjectId {get;set;}
    integer HalfPageSize {get;set;}
    integer NoneOverrideCursor {get;set;}
    integer OverrideCursor {get;set;}
    boolean HasMore {get;set;}

    //Http:POST get
    public override Object get(Object parameters){
        init(parameters);
        validateRequest();

        initQueryGetter(parameters);

        Map<String,Object> response = new Map<String,Object>();
        response.put('communityUrl', AppUtil.CommunitySiteUrl);
        response.put('lookupSize', AppUtil.PhotoViewerLookupSize);
        response.put('namespace', CONSTANTS.CURRENTNAMESPACEPREFIX);
        response.put('maxFavorites', AppUtil.MaxFavoritePhotoCount);
        response.put('maxExports', AppUtil.PhotoViewerMaxExport);
        response.put('accountId', this.AccountId);
        response.put('chainType', getChainType());
        response.put('noneOverrideCursor', this.NoneOverrideCursor);
        response.put('overrideCursor', this.OverrideCursor);
        response.put('init', 1);

        return response;
    }

    void init(Object parameters){
        this.ProjectId = getParamString(parameters,'projectId');
        this.AppUsage = getParamString(parameters, 'usage');
        this.AccountId = getUserAccountId(this.ProjectId);
        this.HalfPageSize = AppUtil.PhotoViewerPageSize / 2;
        this.NoneOverrideCursor = getParamInteger(parameters, 'noneOverrideCursor');
        this.OverrideCursor = getParamInteger(parameters, 'overrideCursor');
        this.HasMore = false;
    }

    private String getUserAccountId(String projectId) {
        if (test.isRunningTest()){
            return TestDataUtil.getUserAccountId(projectId);
        } 
        return AppUtil.getUserAccountId();
    }

    void initQueryGetter(Object parameters){
        Map<String,String> filter = parseGetFilter(parameters);
        this.queryGetter = PhotoViewerFilterQueryGetter.create(filter);
    }

    //Http:POST filter
    public override Object filter(Object parameters){
        init(parameters);
        validateRequest();

        Map<String,String> filter = parseFilter(parameters);
        Map<String,Object> response = new Map<String,Object>();

        this.queryGetter = PhotoViewerFilterQueryGetter.create(filter);

        response.put('photos', getPhotosByFilter());
        response.put('noneOverrideCursor', this.noneOverrideCursor);
        response.put('overrideCursor', this.overrideCursor);
        response.put('hasMore', this.HasMore == true ? 1 : 0);
        response.put('sqls', this.queryGetter.SQLStatements);

        return response;
    }

    void validateRequest(){
        validateProjectId();
        validateAccountId();
    }

    void validateProjectId(){
        if (this.isForProjectBuilder() && String.isBlank(this.ProjectId))
        {
            throw new AuraHandledException('The Project Id is required when retrieving the photos.');
        }
    }

    void validateAccountId(){
        if(isCommunitySite() && String.isEmpty(this.AccountId)){
            throw new AuraHandledException('Client Access Required.');
        }
    }

    String getChainType(){
        OrgCustomSettings__c org  = [SELECT PhotoViewerChainType__c FROM OrgCustomSettings__c LIMIT 1];
        return org.PhotoViewerChainType__c;
    }

    List<List<String>> getPhotosByFilter(){
       List<SObject> results = runSqlWithFilter(false);
       return shapePhotos(results);
    }

    integer countPhotosByFilter() {
        List<SObject> results =  runSqlWithFilter(true);
        integer count = 0;

        for(SObject obj: results){
            count += integer.valueOf(obj.get('cnt'));
        }

        return count;
    }


    List<SObject> runSqlWithFilter(boolean forCount){

        List<SObject> results = new List<SObject>();
        boolean noneOverrideDataPagedOut = this.NoneOverrideCursor == -1;
        boolean overrideDataPagedOut = this.OverrideCursor == -1;

        if(noneOverrideDataPagedOut && overrideDataPagedOut){
            return results;
        }

        boolean isCommunityUser = isCommunitySite();
        integer pageOffset = parsePage() * AppUtil.PhotoViewerPageSize;

        ///scenario 1: internal user, skip all security and do normal pagination
        if(!isCommunityUser){
            results = this.queryGetter.execute(forCount, null, pageOffset);
            if (results.size() > AppUtil.PhotoViewerPageSize){
                this.HasMore = true;
                return QueryResultAnalyzer.subList(results, 0, AppUtil.PhotoViewerPageSize);
            }
            return results;
        }

        ///scneario 2: for community user, if project id is assigned
        List<String> conditions = getCommunityPredicates();
        if(String.isNotEmpty(this.ProjectId)){
            conditions = addAccountServiceAccessClause(this.ProjectId, conditions);
            results = this.queryGetter.execute(forCount, conditions, pageOffset);
            if (results.size() > AppUtil.PhotoViewerPageSize){
                this.hasMore = true;
                return QueryResultAnalyzer.subList(results, 0, AppUtil.PhotoViewerPageSize);
            }
            return results;
        }

        ///scenario 3: for community user, cross projects query
        List<SObject> noneOverrideResults = new List<SObject>();
        List<SObject> overrideResults = new List<SObject>();
        List<String> wheres;

        String sql;

        //step 1: query for nonoverride project
        if(!noneOverrideDataPagedOut){
            wheres = addNoneAccessOverrideClause(conditions);
            noneOverrideResults = this.queryGetter.execute(forCount, wheres, this.NoneOverrideCursor);
        }

        //step 2: query for override project
        if(!overrideDataPagedOut){
            wheres = addAccessOverrideClause(conditions);
            overrideResults = this.queryGetter.execute(forCount, wheres, this.OverrideCursor);
        }

        if(forCount){
            if (listHasElement(noneOverrideResults)){
                results.addAll(noneOverrideResults);
            }
            if (listHasElement(overrideResults)){
                results.addAll(overrideResults);
            }
            return results;
        }

        QueryResultAnalyzer analyzer = QueryResultAnalyzer.create(this.NoneOverrideCursor, this.OverrideCursor);
        results = analyzer.execute(noneOverrideResults, overrideResults);
        this.NoneOverrideCursor = analyzer.getNoneOverrideCursor();
        this.OverrideCursor = analyzer.getOverrideCursor();
        this.HasMore = analyzer.getHasMoreFlag();

       return results;
    }

    Boolean listHasElement(List<SObject> items){
        return items != null && items.size() > 0;
    }


    List<List<String>> getPhotos(){
        if(!isCommunitySite()){
            return shapePhotos(this.queryGetter.execute(false,null,0));
        }

        List<String> predicates = getCommunityPredicates();

        if(String.isNotEmpty(projectId)){
            predicates = addAccountServiceAccessClause(projectId, predicates);
            return shapePhotos(this.queryGetter.execute(false, predicates,0));
        }

        QueryResultAnalyzer analyzer = QueryResultAnalyzer.create(this.NoneOverrideCursor, this.OverrideCursor);
        List<String> conditions;

        //step 1 get none-override
        conditions = addNoneAccessOverrideClause(predicates);
        List<SObject> noneOverrideResults = this.queryGetter.execute(false,conditions,0);

        //step 2 get override
        conditions = addAccessOverrideClause(predicates);
        List<Sobject> overrideResults = this.queryGetter.execute(false, conditions,0);

        List<SObject> results = analyzer.execute(noneOverrideResults, overrideResults);
        this.NoneOverrideCursor = analyzer.getNoneOverrideCursor();
        this.OverrideCursor = analyzer.getOverrideCursor();

        return shapePhotos(results);
    }


    List<List<String>> shapePhotos(List<SObject> images ){
        List<List<String>> result = new List<List<String>>();
        JobImage__c image;
        boolean matched;
        RegExEngine regEx = RegExEngine.createInstance(RegExEngine.UrlPattern);
        
         for(Sobject obj: images){
            image = (JobImage__c) obj;
            matched = regEx.matches(image.ImageUrl__c);
            result.add(new List<String>{
                    image.Id,
                    matched ? LightningRequestHelper.parseString(image.ThumbnailUrl__c) : '',
                    LightningRequestHelper.parseString(image.ProjectService__r.ServiceTitle__c),
                    image.IsFavorite__c ? '1' : '0',
                    image.PoorQualityCheck__c ? '1' : '0',
                    image.IsDuplicated__c ? '1': '0',
                    image.IsUserFavorite__c ? '1' : '0',
                    (!matched || image.IsErrored__c) ? '1': '0'
                });
        }

        return result;
    }

    integer countPhotos() {
        String projectId = this.ProjectId;
        List<SObject> results;
        String sql;

        List<String> predicates = getCommunityPredicates();
        List<String> conditions;

        if(!isCommunitySite()){
            return  integer.valueOf(this.queryGetter.execute(true,null,0)[0].get('cnt'));
        }

        if(String.isNotEmpty(projectId)){
            conditions = addAccountServiceAccessClause(projectId, predicates);
            return integer.valueOf(this.queryGetter.execute(true, conditions,0)[0].get('cnt'));
        }


        //step 1: count none-access-override
        conditions = addNoneAccessOverrideClause(predicates);
        integer count = integer.valueOf(this.queryGetter.execute(true,conditions,0)[0].get('cnt'));

        //step 2: count access-override
        conditions = addAccessOverrideClause(predicates);
        count += integer.valueOf(this.queryGetter.execute(true, conditions,0)[0].get('cnt'));
        return count;
    }


    List<String> getCommunityPredicates(){
        if(this.isForCommunityUser()){
            return addCommunityPredicates();
        }

        if (this.isForRetailer()){
            return addRetailerPredicates();
        }

        return new List<String>();
    }

    List<String> addCommunityPredicates(){
        List<String> conditions = new List<String>();

        conditions = addCommunitySiteDefaultPredicates(conditions);
        conditions.add('Project__c IN (SELECT Project__c FROM ProjectAccount__c WHERE Account__c = \'' + this.AccountId + '\')');

        return conditions;
    }

    List<String> addRetailerPredicates(){
        List<String> conditions = new List<String>();

        conditions = addCommunitySiteDefaultPredicates(conditions);
        conditions.add('Project__r.RetailerAccount__c = \'' + this.AccountId + '\'');
        conditions.add('ProjectLocation__r.Location__r.RetailerAccount__c = \'' + this.AccountId + '\'');

        return conditions;
    }


    List<String> addCommunitySiteDefaultPredicates(List<String> conditions){
        conditions.add('PoorQualityCheck__c != true');
        conditions.add('IsDuplicated__c != true');
        conditions.add('Project__r.IsVisibleToClient__c = true');
        conditions.add('ProjectService__r.isVisibleToClient__c = true');

        return conditions;
    }

    List<String> addAccountServiceAccessClause(String projectId, List<String> predicates){
        if(!isSecurityAccessOverride(projectId)){
            return predicates;
        }
        List<String> conds = new List<String>(predicates);

        conds.add(buildProjectAccessOverrideClause(projectId, this.AccountId));
        return conds;
    }

    String buildProjectAccessOverrideClause(string projectId, String accountId){
        return 'ProjectService__c IN (SELECT ProjectService__c FROM ProjectAccountServiceAccess__c WHERE Project__c = \'' + projectId + '\' AND ProjectAccount__r.Account__c=\'' + accountId + '\')';
    }


    List<String> addNoneAccessOverrideClause(List<String> predicates){
        List<String> wheres = new List<String>(predicates);
        wheres.add('Project__r.OverrideAccountAndServiceAccess__c != true');
        return wheres;
    }

    List<String> addAccessOverrideClause(List<String> predicates){
        List<String> wheres = new List<String>(predicates);
        wheres.add('Project__r.OverrideAccountAndServiceAccess__c = true');
        wheres.add('ProjectService__c IN (SELECT ProjectService__c FROM ProjectAccountServiceAccess__c WHERE ProjectAccount__r.Account__c=\'' + this.AccountId + '\')');
        return wheres;
    }

    Boolean isSecurityAccessOverride(String projectId){
        List<Project__c> ps = [SELECT OverrideAccountAndServiceAccess__c FROM Project__c WHERE Id=:projectId];
        return (ps.size() > 0 && ps.get(0).OverrideAccountAndServiceAccess__c == true) ? true : false;
    }


    String getParamString(Object parameters, String key){
        Map<String,object> query = (Map<String,Object>) parameters;
        return LightningRequestHelper.parseString(query.get(key));
    }

    Integer getParamInteger(Object parameters, String key){
        String val = getParamString(parameters, key);
        return String.isEmpty(val) ? 0 : integer.valueOf(val);
    }

    Map<String,String> parseGetFilter(Object parameters){
        Map<String,object> query = (Map<String,Object>) parameters;
        Map<String,String> filter = new Map<String,String>();
        filter.put('userAccountId', this.AccountId);
        filter.put('action', LightningRequestHelper.parseString(query.get('action')));
        filter.put('projectId',LightningRequestHelper.parseString(query.get('projectId')));
        return filter;
    }

    Map<String,String> parseFilter(Object parameters){
        Map<String,object> query = (Map<String,Object>) parameters;
        Map<String,String> filter = new Map<String,String>();
        filter.put('userAccountId', this.AccountId);
        filter.put('filterAccountId', LightningRequestHelper.parseString(query.get('accountId')));
        filter.put('page', LightningRequestHelper.parseString(query.get('page')));
        filter.put('action', LightningRequestHelper.parseString(query.get('action')));
        filter.put('duplicated',LightningRequestHelper.parseString(query.get('duplicated')));
        filter.put('projectId',LightningRequestHelper.parseString(query.get('projectId')));
        filter.put('usage', LightningRequestHelper.parseString(query.get('usage')));
        filter.put('serviceId', LightningRequestHelper.parseString(query.get('serviceId')));
        filter.put('locationId', LightningRequestHelper.parseString(query.get('locationId')));
        filter.put('chainId', LightningRequestHelper.parseString(query.get('chainId')));
        filter.put('startDate', LightningRequestHelper.parseString(query.get('startDate')));
        filter.put('endDate', LightningRequestHelper.parseString(query.get('endDate')));
        filter.put('duplicates', LightningRequestHelper.parseString(query.get('duplicates')));
        filter.put('qualityCheck', LightningRequestHelper.parseString(query.get('qualityCheck')));
        filter.put('exceptions', LightningRequestHelper.parseString(query.get('exceptions')));
        filter.put('questionId', LightningRequestHelper.parseString(query.get('questionId')));
        filter.put('targetId', LightningRequestHelper.parseString(query.get('targetId')));
        filter.put('state', LightningRequestHelper.parseString(query.get('state')));
        filter.put('city', LightningRequestHelper.parseString(query.get('city')));
        filter.put('repId', LightningRequestHelper.parseString(query.get('repId')));
        filter.put('favorite',LightningRequestHelper.parseString(query.get('favorite')));
        filter.put('userFavorite', LightningRequestHelper.parseString(query.get('userFavorite')));
        filter.put('programId', LightningRequestHelper.parseString(query.get('programId')));
        filter.put('unclassified', LightningRequestHelper.parseString(query.get('unclassified')));
    if (this.isCommunitySite()) {
            filter.put('duplicated', '0');
        	filter.put('unclassified', '0');
        }
        return filter;
    }

     integer parsePage(){
        String page = this.queryGetter.getFilterParameter('page');
        if(String.isEmpty(page)){ return 0;}

        return integer.valueOf(page);
    }

    boolean isForProjectBuilder(){
        return this.AppUsage == 'Project Builder' ? true : false;
    }

    boolean isForInternalUser() {
        return this.AppUsage == 'Internal User' ? true : false;
    }

    boolean isForRetailer(){
        return this.AppUsage == 'Retailer' ? true : false;
    }

    boolean isForCommunityUser() {
        return this.AppUsage == 'Community Viewer' ? true : false;
    }

    boolean isCommunitySite(){
        return isForCommunityUser() || isForRetailer();
    }

}