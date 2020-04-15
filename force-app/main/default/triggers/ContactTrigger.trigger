trigger ContactTrigger on Contact (before insert, after insert, after update,before Update,before delete) {

    new ContactTriggerHandler().run();
}