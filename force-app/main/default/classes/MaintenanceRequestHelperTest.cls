@isTest
public with sharing class MaintenanceRequestHelperTest {
    @TestSetup
    static void makeData(){
        Vehicle__c v = new Vehicle__C(name = 'Testing Vehicle');
        
        product2 e = new product2(name = 'Testing equipment',
                                  lifespan_months__c = 10,
                                  maintenance_cycle__c = 10,
                                  replacement_part__c = true);
        insert v;
        insert e;
        
        case c = new case(Type='Repair',
                          Status='New',
                          Origin='Web',
                          Subject='Testing subject',
                          Equipment__c = e.Id,
                          Vehicle__c = v.Id);
        
        insert c;
        
        Equipment_Maintenance_Item__c emi = new Equipment_Maintenance_Item__c(
            Equipment__c = e.Id,
            Maintenance_Request__c = c.Id);
        
        insert emi;
    }
    
    @isTest
    private static void testPositive(){
        Vehicle__c vehicle = [SELECT ID FROM Vehicle__c WHERE Name = 'Testing Vehicle'];
        id vehicleId = vehicle.Id;
        
        Product2 equipment = [SELECT ID FROM PRODUCT2 WHERE Name = 'Testing equipment'];
        id equipmentId = equipment.Id;
        
        case createdCase = [SELECT ID FROM CASE WHERE Vehicle__c = :vehicleId AND Equipment__c = :equipment.Id];
        
        Equipment_Maintenance_Item__c equipmentMaintenanceItem = [SELECT ID FROM Equipment_Maintenance_Item__c 
                                                                  WHERE Maintenance_Request__c = :createdCase.Id];
        
        test.startTest();
        createdCase.status = 'Closed';
        update createdCase;
        test.stopTest();
        
        Case newCase = [Select id, 
                        subject, 
                        type, 
                        Equipment__c, 
                        Date_Reported__c, 
                        Vehicle__c, 
                        Date_Due__c
                        from case
                        where status ='New'];
        
        list<case> allCase = [select id from case];
        system.assert(allCase.size() == 2);
        
        system.assert(newCase != null);
        system.assert(newCase.Subject != null);
        system.assertEquals(newCase.Type, 'Routine Maintenance');
        SYSTEM.assertEquals(newCase.Equipment__c, equipmentId);
        SYSTEM.assertEquals(newCase.Vehicle__c, vehicleId);
        SYSTEM.assertEquals(newCase.Date_Reported__c, system.today());
    }
    
    @isTest
    private static void testNegative(){
        Vehicle__c vehicle = [SELECT ID FROM Vehicle__c WHERE Name = 'Testing Vehicle'];
        id vehicleId = vehicle.Id;
        
        Product2 equipment = [SELECT ID FROM PRODUCT2 WHERE Name = 'Testing equipment'];
        id equipmentId = equipment.Id;
        
        case createdCase = [SELECT ID FROM CASE 
                            WHERE Vehicle__c = :vehicleId 
                            AND Equipment__c = :equipment.Id];
        
        Equipment_Maintenance_Item__c equipmentMaintenanceItem = [SELECT ID FROM Equipment_Maintenance_Item__c 
                                                                  WHERE Maintenance_Request__c = :createdCase.Id];
        
        test.startTest();
        createdCase.Status = 'Working';
        update createdCase;
        test.stopTest();
        
        list<case> allCase = [select id from case];
        
        system.assert(equipmentMaintenanceItem != null);
        system.assert(allCase.size() == 1);
    }
    
    @isTest
    private static void testBulk(){
        list<Vehicle__C> vehicleList = new list<Vehicle__C>();
        list<Product2> equipmentList = new list<Product2>();
        list<Equipment_Maintenance_Item__c> equipmentMaintenanceItemList = new list<Equipment_Maintenance_Item__c>();
        list<case> caseList = new list<case>();
        list<id> oldCaseIds = new list<id>();
        
        system.debug(caseList.size());
        
        for(integer i = 0; i < 300; i++){
            Vehicle__c v = new Vehicle__C(name = 'Testing Bulk Vehicle' +i);
            
            product2 e = new product2(name = 'Testing Bulk equipment' +i,
                                      lifespan_months__c = 10,
                                      maintenance_cycle__c = 10,
                                      replacement_part__c = true);            
            vehicleList.add(v);
            equipmentList.add(e);
        }
        insert vehicleList;
        insert equipmentList;
        
        String eId = '';
        String vId = '';
        
        for(integer i = 0; i < 300; i++){
            eId = 'Testing Bulk equipment' + String.valueOf(i);
            vId = 'Testing Bulk Vehicle' + String.valueOf(i);
            case c = new case(Type='Repair',
                              Status='New',
                              Origin='Web',
                              Subject='Testing Bulk subject'+i,
                              Equipment__c = equipmentList[i].Id,
                              Vehicle__c = vehicleList[i].Id);
            caseList.add(c);
        }
        system.debug(caseList.size());
        
        insert caseList;
        for(integer i = 0; i < 300; i++){
            Equipment_Maintenance_Item__c emi = new Equipment_Maintenance_Item__c(
                Equipment__c = equipmentList[i].Id,
                Maintenance_Request__c = caseList[i].Id);
            
            equipmentMaintenanceItemList.add(emi);
        }
        
        insert equipmentMaintenanceItemList;
        
        test.startTest();
        for(case cs : caseList){
            cs.Status = 'Closed';
            oldCaseIds.add(cs.Id);
        }
        system.debug(caseList.size());
        
        update caseList;
        test.stopTest();
        
        list<case> newCase = [select id
                              from case
                              where status ='New'];
        
        system.debug(newCase.size());
        system.assert(newCase.size() == 301);
        
        list<case> allCase = [select id from case];
        system.assert(allCase.size() == 601);
    }
}