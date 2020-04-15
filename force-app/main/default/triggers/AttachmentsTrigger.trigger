trigger AttachmentsTrigger on Attachment (after update,before Update,before delete,after delete,after insert) {
	new AttachmentTriggerHandler().run();
}