public with sharing class JobBulkHandler {
        Map<ID,Job__c> jobs;

        public JobBulkHandler() {
            this.jobs = new Map<ID,Job__c>();
        }

        public Job__c getJobInstance(ID jobId) {
            Job__c job = jobs.get(jobId);
            return (job != null ) ? job : new Job__c(Id = jobId);
        }

        public void add(Job__c jobToCommit) {
            jobs.put(jobToCommit.Id, jobToCommit);
        }

        public void doUpdate() {
            if (0 == jobs.size() ) { return; }
            update jobs.values();
        }
}