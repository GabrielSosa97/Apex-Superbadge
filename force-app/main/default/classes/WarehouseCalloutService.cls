public with sharing class WarehouseCalloutService implements Queueable {
    
    // FATAL_ERROR System.CalloutException: Unauthorized endpoint, 
    // please check Setup->Security->Remote site settings. endpoint = https://th-superbadge-apex.herokuapp.com/equipment
    private static final String WAREHOUSE_URL = 'https://th-superbadge-apex.herokuapp.com/equipment';
    
    @future(callout=true)
    public static void runWarehouseEquipmentSync(){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(WAREHOUSE_URL);
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() == 200) {
            List<Object> results = (List<Object>) JSON.deserializeUntyped(response.getBody());
            List<Product2> eList = new List<Product2>();
            
            for (Object r: results) {
                Map<String, Object> rMap = (Map<String, Object>)r;
                Product2 e = new Product2();
                
                e.Name = (String)rMap.get('name');
                e.Cost__c = (Decimal)rMap.get('cost');
                e.ProductCode = (String)rMap.get('_id');
                e.Current_Inventory__c = (Integer)rMap.get('quantity');
                e.Maintenance_Cycle__c = (Integer)rMap.get('maintenanceperiod');
                e.Replacement_Part__c = (Boolean)rMap.get('replacement');
                e.Lifespan_Months__c = (Integer)rMap.get('lifespan');
                e.Warehouse_SKU__c = (String)rMap.get('sku');
                
                eList.add(e);
            }
            
            if(eList.size() > 0){
                upsert eList;
            }
            system.debug(eList);
        }
        
    }
    public static void execute (QueueableContext context){
        runWarehouseEquipmentSync();
    }
}