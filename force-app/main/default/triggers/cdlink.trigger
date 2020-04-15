trigger cdlink on ContentDocumentLink (before insert, after insert, before update,after update, before delete) {
    new cdlinkTriggerHandler().run();
 
}