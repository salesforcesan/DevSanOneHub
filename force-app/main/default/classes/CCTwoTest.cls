@isTest
public class CCTwoTest {
    public static testMethod void test_cctwo(){ 
        cctwo c = new cctwo();
        Integer i = c.calc_i();
        system.debug('i: ' + i);
        system.assertNotEquals(i,0);
        i = c.calc_i_2();
        system.assertNotEquals(i,0);
        i = c.calc_i_3();
        system.assertNotEquals(i,0);
        i = c.calc_i_4();
        system.assertNotEquals(i,0);
    }
}