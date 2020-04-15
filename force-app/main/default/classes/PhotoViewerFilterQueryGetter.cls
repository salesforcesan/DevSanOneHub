public with sharing class PhotoViewerFilterQueryGetter {
    private Map<String,String> filter;
    private List<String> predicates;
    public List<String> SQLStatements {get;set;}

    public string getProjectId(){
        return this.filter.get('projectId');
    }

    public string getFilterParameter(String key){
        return this.filter.get(key);
    }

    public void resetPredicates(){
        this.predicates = new List<String>();
    }

	private PhotoViewerFilterQueryGetter(Map<String,String> filter) {
        this.filter = filter;
        this.predicates = new List<String>();
        this.SQLStatements = new List<String>();
    }

    private void addSQL(String sql){
        this.SQLStatements.add(sql);
    }

    public static PhotoViewerFilterQueryGetter create(Map<String,String> filter){
        return new PhotoViewerFilterQueryGetter(filter);
    }

    public List<SObject> execute(boolean forCount, List<String>extraConditions, integer pageOffset){

        String projectId = this.getProjectId();
        String accountId = filter.get('userAccountId');
        String filterAccountId = filter.get('filterAccountId');
        String programId = filter.get('programId');
        String serviceId = filter.get('serviceId');
        String locationId = filter.get('locationId');
        String chainId = filter.get('chainId');
        String startDate = filter.get('startDate');
        String endDate = filter.get('endDate');
        String state = filter.get('state');
        String repId = filter.get('repId');
        String city = filter.get('city');
        String questionId = filter.get('questionId');
        String targetId = filter.get('targetId');
        String cityName = city;
        String favorite = filter.get('favorite');
        String userFavorite = filter.get('userFavorite');
        String duplicated = filter.get('duplicated');
        String unclassified = filter.get('unclassified');

        String baseSQL = (forCount)
            ? 'SELECT count(Id) cnt FROM JobImage__c'
            : 'SELECT Id, ThumbnailURL__c, ImageUrl__c, ProjectService__r.ServiceTitle__c, IsFavorite__c, PoorQualityCheck__c, IsDuplicated__c, IsUserFavorite__c,IsErrored__c FROM JobImage__c';

        if(this.predicates.size() == 0){
            if(String.isNotEmpty(projectId)){
                this.predicates.add('Project__c = :projectId');
            }

            if(favorite == '1'){
                this.predicates.add('IsFavorite__c = true');
            }
            
            if(userFavorite == '1'){
                this.predicates.add('IsUserFavorite__c = true');
            }

            if(duplicated == '1'){
                this.predicates.add('IsDuplicated__c = true');
            }

            if(String.isNotEmpty(serviceId)){
                this.predicates.add('ProjectService__c = :serviceId');
            }

            if(String.isNotEmpty(locationId)){
                this.predicates.add('ProjectLocation__r.Location__c = :locationId');
            }

            if(String.isNotEmpty(chainId)){
                this.predicates.add('ParentLocation__c =:chainId');
            }

            if(String.isNotEmpty(questionId)){
                this.predicates.add('Question__c = :questionId');
            }

            if(String.isNotEmpty(targetId)){
                this.predicates.add('Target__c = :targetId');
            }

            if(String.isNotEmpty(state)){
                this.predicates.add('ProjectLocation__r.State__c = :state');
            }

            if(String.isNotEmpty(cityName)){
                this.predicates.add('ProjectLocation__r.City__c LIKE \'' + cityName + '%\'');
            }

            if(String.isNotEmpty(repId)){
                this.predicates.add('JobAttempt__r.ReportedContact__c = :repId');
            }

            if(String.isNotBlank(startDate)){
                this.predicates.add('JobDateReported__c >= ' + startDate + 'T00:00:00.000Z');
            }

            if(String.isNotBlank(endDate)){
                this.predicates.add('JobDateReported__c <= ' + endDate + 'T23:59:59.999Z');
            }

            if(String.isNotEmpty(programId)){
                this.predicates.add('Project__r.Program__c = :programId');
            }

            if(isInternalUser() && String.isNotEmpty(filterAccountId)){
                this.predicates.add('Project__c IN (SELECT Project__c FROM ProjectAccount__c WHERE Account__c=:filterAccountId)');
            }
 			if(unclassified == '1'){
                this.predicates.add('AIMatchedStates__c = \'UnMatched\' ');
            } else {
                this.predicates.add('AIMatchedStates__c IN (\'Matched\',\'Not Enabled\') ');
            }
        }

        List<String> conditions = new List<String>();
        conditions.add('ImageUrl__c != null');
        conditions.addAll(this.predicates);
        if(extraConditions != null && extraConditions.size() > 0){
            conditions.addAll(extraConditions);
        }

        baseSQL += whereFromPredicates(conditions);
        if(!forCount){
            baseSQL += getOrderPageClause(pageOffset);
        }

        this.addSQL(baseSQL);
        return Database.query(baseSQL);
    }

    boolean isInternalUser(){
        return this.filter.get('usage') == 'Internal User';
    }

    boolean isCommunitySite() {
        String usage = this.filter.get('usage');
        return usage == 'Retailer' || usage == 'Community Viewer';
    }

    String parseCity(String city){
        List<Location__c> locations = [SELECT City__c FROM Location__c WHERE Id=:city LIMIT 1];
        return locations.size() > 0 ? locations[0].City__c : '';
    }


    String whereFromPredicates(List<String> wheres){

        return wheres.size() > 0
            ? ' WHERE ' + String.join(wheres, ' AND ')
            : '';
    }

    String getOrderPageClause(integer pageOffset) {
        string filter =  ' Order By SystemModstamp DESC LIMIT ' + String.valueOf(AppUtil.PhotoViewerPageSize + 1);
        if(pageOffset > 0){
            filter += ' OFFSET ' + String.valueOf(pageOffset);
        }
        return filter;
    }


}