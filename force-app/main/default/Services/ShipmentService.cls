public class ShipmentService {

    private static final String STATUS_NEW = 'New';   //Ponemos como variable new porque lo usaremos varias veces
    private static final String STATUS_PROCESSED = 'Processed'; //lo mismo con Processed

    // ---------- REGLA 1 ----------
    public static void setInitialStatus(List<Shipment__c> shipments) {
        for (Shipment__c s : shipments) {
            s.Status__c = STATUS_NEW;  //se pone el status de new en los shipments creados
        }
    }

    // ---------- REGLA 2 ----------
    public static void stampProcessedDate(List<Shipment__c> shipments) {
        for (Shipment__c s : shipments) {
            Boolean enteringProcessedNow = (s.Status__c == STATUS_PROCESSED);  //Se revisa si el actual status es procesado

            if (enteringProcessedNow && s.Processed_At__c == null) {  //se revisa si estuvo lleno alguna vez
                s.Processed_At__c = Datetime.now(); //en caso de no estarlo se añade la fecha y hora del momento
            }
        }
    }

    // ---------- REGLA 3 ----------
    public static void validateProcessedAtIsLocked(List<Shipment__c> newShipments, Map<Id, Shipment__c> oldMap) {
        for (Shipment__c s : newShipments) {
            Shipment__c old = oldMap.get(s.Id);
            if (old.Processed_At__c != null && s.Processed_At__c != old.Processed_At__c) { //Se revisa si al querer dar update se tenia la fecha de processed llena
                s.Processed_At__c.addError('No se puede modificar ni borrar la fecha de procesado una vez asignada.'); //en caso de estarlo se envia un error
            }
        }
    }

    // ---------- REGLA 2.1 Contador ----------
    public static void incrementAccountProcessedCount(List<Shipment__c> newShipments, Map<Id, Shipment__c> oldMap) {
        Map<Id, Integer> countByAccount = new Map<Id, Integer>();  //Se añade un Map para tener las cuentas modificadas

        for (Shipment__c s : newShipments) {
        if (s.Account__c == null) continue;

        Boolean alreadyProcessedOnce = (oldMap != null && oldMap.get(s.Id).Processed_At__c != null);
        Boolean enteringProcessedNow = (s.Status__c == STATUS_PROCESSED && !alreadyProcessedOnce);

        if (enteringProcessedNow) {
            Integer current = countByAccount.containsKey(s.Account__c) ? countByAccount.get(s.Account__c) : 0;
            countByAccount.put(s.Account__c, current + 1);
        }
    }

        if (countByAccount.isEmpty()) return;

        List<Account> accountsToUpdate = new List<Account>(); //lista para las cuentas que se haran update
        for (Account acc : [SELECT Id, Shipments_Processed__c FROM Account WHERE Id IN :countByAccount.keySet()]) {
            Integer currentValue = acc.Shipments_Processed__c != null ? Integer.valueOf(acc.Shipments_Processed__c) : 0;
            acc.Shipments_Processed__c = currentValue + countByAccount.get(acc.Id);
            accountsToUpdate.add(acc);
        }

        update accountsToUpdate;  //se envia el update
    }
}