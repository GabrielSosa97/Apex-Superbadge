public with sharing class MaintenanceRequestHelper {
    public static void updateworkOrders(List<Case> updWorkOrders, Map<Id,Case> nonUpdCaseMap) {
        Set<Id> validIds = new Set<Id>();
        For (Case c : updWorkOrders){
            if (nonUpdCaseMap.get(c.Id).Status != 'Closed' && c.Status == 'Closed'){
                //	Cuando un MR del tipo "Repair" o "Routine M" este cerrada, crear un MR para una revision futura.
                if (c.Type == 'Repair' || c.Type == 'Routine Maintenance'){
                    validIds.add(c.Id);
                }
            }
        }
        
        if (!validIds.isEmpty()){
            Map<Id,Case> closedCases = new Map<Id,Case>([SELECT Id, Vehicle__c, Equipment__c, Equipment__r.Maintenance_Cycle__c,
                                                         (SELECT Id,Equipment__c,Quantity__c FROM Equipment_Maintenance_Items__r) 
                                                         FROM Case WHERE Id IN :validIds]);
            Map<Id,Decimal> maintenanceCycles = new Map<ID,Decimal>();
            
            /// Calcular las PM expiradas usando el MC en los registros de Equipment instalado. Comparar el MIN de sus fechas.
            List<AggregateResult> results = [SELECT Maintenance_Request__c, 
                                             MIN(Equipment__r.Maintenance_Cycle__c)cycle 
                                             FROM Equipment_Maintenance_Item__c 
                                             WHERE Maintenance_Request__c IN :ValidIds GROUP BY Maintenance_Request__c];
            
            for (AggregateResult ar : results){ 
                maintenanceCycles.put((Id) ar.get('Maintenance_Request__c'), (Decimal) ar.get('cycle'));
            }
            
            List<Case> newCases = new List<Case>();
            for(Case cc : closedCases.values()){
                Case nc = new Case();
                
                nc.ParentId = cc.Id;
                nc.Status = 'New';
                nc.Subject = 'Insert a Subject Here...';	//	El Campo Subject de MR NO DEBE ser NULL.
                nc.Type = 'Routine Maintenance';
                nc.Vehicle__c = cc.Vehicle__c;
                nc.Equipment__c = cc.Equipment__c;
                nc.Origin = 'Phone';
                nc.Date_Reported__c = Date.Today();			//	Sera igual al mismo dia que fue creado.
                
                //	Si hay mas de una pieza del Equipo en uso en un MR, definir la Date_Due__c del MR mas cercana a la fecha.
                nc.Date_Due__c = Date.today().addDays((Integer) maintenanceCycles.get(cc.Id));
                
                newCases.add(nc);
            }
            
            insert newCases;
            
            //	Todos los equipos tienen Maintenance Cycles.
            List<Equipment_Maintenance_Item__c> emiUpList = new List<Equipment_Maintenance_Item__c>();
            for (Case nc : newCases){
                for (Equipment_Maintenance_Item__c emiUp : closedCases.get(nc.ParentId).Equipment_Maintenance_Items__r){
                    Equipment_Maintenance_Item__c item = emiUp.clone();
                    item.Maintenance_Request__c = nc.Id;	
                    emiUpList.add(item);
                }
            }
            insert emiUpList;
        }
    }
}