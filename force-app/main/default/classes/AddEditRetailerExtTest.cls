@isTest
public class AddEditRetailerExtTest {
    public static testMethod void test_edit(){ 
        TestUtil.initBaseData();
        
        Retailer__c retailer = [SELECT Id FROM Retailer__c LIMIT 1];
        
        
        ApexPages.currentPage().getParameters().put('Id', retailer.Id);
        
        ApexPages.StandardController stdCtrl  = new ApexPages.StandardController(retailer);
        AddEditRetailerExt ctrlExt = new AddEditRetailerExt(stdCtrl); 
        PageReference pageRef = ctrlExt.save();
        system.assertEquals('/' + String.valueOf(retailer.Id).substring(0, 15), pageRef.getUrl());
    } 
    
    public static testMethod void test_add(){ 
        //TestUtil.initBaseData();
        ApexPages.StandardController stdCtrl  = new ApexPages.StandardController(new Retailer__C());
        AddEditRetailerExt ctrlExt = new AddEditRetailerExt(stdCtrl);
        ctrlExt.Retailer.OneHubRetailerId__c = 'RC1'; 
        PageReference pageRef = ctrlExt.save();
        system.debug('pageRef:'+pageRef);
        String retailerId = [SELECT Id FROM Retailer__c LIMIT 1].Id;
        system.assertEquals('/' + String.valueOf(retailerId).substring(0, 15), pageRef.getUrl());
    }
    
    public static testMethod void test_errors(){ 
        TestUtil.initBaseData();
        Retailer__c retailer = [SELECT Id FROM Retailer__c LIMIT 1];
        ApexPages.currentPage().getParameters().put('Id', 'fail-id');
        ApexPages.StandardController stdCtrl  = new ApexPages.StandardController(retailer);
        AddEditRetailerExt ctrlExt = new AddEditRetailerExt(stdCtrl); 
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());
        ctrlExt.save();
        pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());
    }
}