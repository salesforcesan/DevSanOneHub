trigger OpportunityTrigger on Opportunity (before insert, after insert, after update,before Update,before delete) {
  new OpportunityTriggerHandler().run();
}