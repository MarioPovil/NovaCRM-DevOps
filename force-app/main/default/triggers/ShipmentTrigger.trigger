trigger ShipmentTrigger on Shipment__c (before insert, before update, after update, after insert) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {    //Metodo para before insert
            ShipmentTriggerHandler.handleBeforeInsert(Trigger.new); //Se llama al handler y a su metodo
        }
        when BEFORE_UPDATE {  //Metodo para before update
            ShipmentTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap); //Se llama al handler y a su metodo
        }
        when AFTER_INSERT {    //Metodo para after insert
            ShipmentTriggerHandler.handleAfterInsert(Trigger.new); //Se llama al handler y a su metodo
        }
        when AFTER_UPDATE {    //Metodo para after update
            ShipmentTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap); //Se llama al handler y a su metodo
        }
    }
}