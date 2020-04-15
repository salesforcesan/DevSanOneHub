trigger ProjectServiceEquipmentTrigger on ProjectServiceEquipment__c (before insert, before update,after update) {
    new ProjectServiceEquipmentTriggerHandler().run();
}