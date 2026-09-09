public class ShipmentTriggerHandler {

    public static void handleBeforeInsert(List<Shipment__c> newShipments) {
        ShipmentService.setInitialStatus(newShipments);  //Servicio para poner en new el status del shipment
    }

    public static void handleBeforeUpdate(List<Shipment__c> newShipments, Map<Id, Shipment__c> oldMap) {
        ShipmentService.validateProcessedAtIsLocked(newShipments, oldMap);  //Servicio para
        ShipmentService.stampProcessedDate(newShipments);  //Servicio para poner la fecha de processed
    }

    public static void handleAfterInsert(List<Shipment__c> newShipments) {
        ShipmentService.incrementAccountProcessedCount(newShipments, null);   //Servicio para revisar que shipments seran añadidos
    }

    public static void handleAfterUpdate(List<Shipment__c> newShipments, Map<Id, Shipment__c> oldMap) {
        ShipmentService.incrementAccountProcessedCount(newShipments, oldMap);  //Servicio para incrementar en las cuentas los shipments procesados
    }
}