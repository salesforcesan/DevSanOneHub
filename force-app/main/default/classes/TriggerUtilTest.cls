@isTest
public class TriggerUtilTest
{
  
  
  public static testMethod void test_DisableAllTriggers()
  {

      System.assertEquals(TriggerUtil.skipTrigger, false);
      System.assertEquals(TriggerUtil.skipProjectTrigger , false);      
      System.assertEquals(TriggerUtil.skipProjectLocationTrigger , false);
      System.assertEquals(TriggerUtil.skipProjectServiceTrigger , false);
      System.assertEquals(TriggerUtil.skipProjServColTrigger , false);
      System.assertEquals(TriggerUtil.skipProjectServiceTargetTrigger , false);
      System.assertEquals(TriggerUtil.skipJobTrigger , false);      
      System.assertEquals(TriggerUtil.skipProjectServiceTargetAttributeTrigger , false);                              
      
      TriggerUtil.SkipAllTriggers();
            
      System.assertEquals(TriggerUtil.skipTrigger, true);
      System.assertEquals(TriggerUtil.skipProjectTrigger , true);      
      System.assertEquals(TriggerUtil.skipProjectLocationTrigger , true);
      System.assertEquals(TriggerUtil.skipProjectServiceTrigger , true);
      System.assertEquals(TriggerUtil.skipProjServColTrigger , true);
      System.assertEquals(TriggerUtil.skipProjectServiceTargetTrigger , true);
      System.assertEquals(TriggerUtil.skipJobTrigger , true);      
      System.assertEquals(TriggerUtil.skipProjectServiceTargetAttributeTrigger , true);                              
      
      
  }
}