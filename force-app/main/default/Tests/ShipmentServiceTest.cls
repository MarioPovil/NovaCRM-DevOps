@isTest
private class ShipmentServiceTest {

    @TestSetup
    static void setupData() {
        Account acc = new Account(    //creamos una cuenta de prueba global para reutilizarla despues ya que se usara en varios test
            Name = 'Cuenta de Prueba',   //nombre de la cuenta
            Shipments_Processed__c = 0 //y su numero de shipment processed
        );
        insert acc;  //DML para crear la cuenta
    }
    @isTest
    static void testStatusAlwaysNewOnInsert() {  //test para verificar que al crear un shipment nuevo se ponga el status en new
        // Preparacion del test
        Account acc = [SELECT Id FROM Account LIMIT 1];

        // ejecutamos el test
        Test.startTest(); //empieza el test
        Shipment__c s = new Shipment__c(   //creamos un shipment
            Account__c = acc.Id,  //ponemos el id de la cuenta test global que creamos
            Status__c = 'Processed'  // Intentamos poner un status distinto
        );
        insert s;  //creamos la cuenta
        Test.stopTest();  //termina el test

        // revision de resultados esperados
        Shipment__c result = [SELECT Status__c FROM Shipment__c WHERE Id = :s.Id]; //traemos el status del shipment que creamos
        System.assertEquals('New', result.Status__c, 'El status debe forzarse a New sin importar lo que se intente insertar');  //hacemos un assert para verificar que el status sea new como deberia de ser, sino manda un error
    }
        @isTest
    static void testProcessedFillsDateAndIncrementsAccountCounter() {  //test para aumentar el shipments processed
        // Preparacion
        Account acc = [SELECT Id, Shipments_Processed__c FROM Account LIMIT 1]; //pedimos la información de la cuenta global, su id y shipments procesados
        Shipment__c s = new Shipment__c(Account__c = acc.Id); //Creamos un shipment nuevo con la cuenta test seleccionada
        insert s; // nace en "New" por la Regla 1

        // Ejecutamos el test
        Test.startTest();
        s.Status__c = 'Processed'; //damos update al status del shipment
        update s;  //dml para dar update al shipment creado
        Test.stopTest();

        // Resultados esperados
        Shipment__c result = [SELECT Status__c, Processed_At__c FROM Shipment__c WHERE Id = :s.Id]; //traemos el valor de los campos  del shipment despues del test
        Account updatedAcc = [SELECT Shipments_Processed__c FROM Account WHERE Id = :acc.Id]; //igual los de la cuenta

        System.assertEquals('Processed', result.Status__c, 'El status debe quedar en Processed'); //Verificamos si el status es processed, sino envia un error
        System.assertNotEquals(null, result.Processed_At__c, 'Processed_At__c debe haberse llenado'); //verifica si el processed at no es igual a null, si es null entonces devuelve el mensaje
        System.assertEquals(1, updatedAcc.Shipments_Processed__c, 'El contador de la cuenta debe subir a 1'); //revisa si shipments processed es igual a uno, sino manda el mensaje
    }
        @isTest
    static void testCannotChangeProcessedAtOnceSet() {  //test para verificar que no se modifique la fecha de processed at
        // declaraciones
        Account acc = [SELECT Id FROM Account LIMIT 1]; //pedimos la informacion de la cuenta
        Shipment__c s = new Shipment__c(Account__c = acc.Id); //creamos un shipment nuevo con la cuenta test seleccionada
        insert s; //creamos el shipment por dml

        s.Status__c = 'Processed'; //declaramos cambiar su status
        update s; // Processed_At__c queda lleno por el dml de update

        Shipment__c processedOnce = [SELECT Processed_At__c FROM Shipment__c WHERE Id = :s.Id]; //traemos la información de la fecha que se asigna automaticamente al poner processed un shipment

        // ejecutamos el test y verificamos
        Test.startTest();
        s.Processed_At__c = null; // Intento borrar la fecha manualmente
        Boolean errorLanzado = false; //declaramos que aun no hay algun error
        try {
            update s; //intentamos el update por dml
        } catch (DmlException e) {  //esperamos que suelte el error por intentar modificar el campo processed at
            errorLanzado = true;  //sí si lo hay, el valor pasa a true y manda un mensaje
            System.assert(e.getMessage().contains('No se puede modificar'), 'El mensaje de error debe mencionar el bloqueo de la fecha');
        }
        Test.stopTest(); //acaba el test

        System.assertEquals(true, errorLanzado, 'Debió lanzar un error al intentar borrar Processed_At__c');  //nos confirma si si hubo error o no
    }

    @isTest
    static void testNoDoubleCountWhenReprocessed() { //test para comprobar que no se aumente +1 cuentas duplicadas
        // declaramos
        Account acc = [SELECT Id FROM Account LIMIT 1];  //pedimos la cuenta
        Shipment__c s = new Shipment__c(Account__c = acc.Id); //creamos un nuevo shipment
        insert s; //lo creamos por dml

        s.Status__c = 'Processed'; //cambiamos su status declarativamente
        update s; // primer conteo: Account queda en 1 y le damos update por dml

        s.Status__c = 'New'; // Processed_At__c se queda con su valor, no se toca
        update s; // actualizamos por dml, esto NO debería restar ni afectar el contador

        // empezamos el test
        Test.startTest();
        s.Status__c = 'Processed'; // se reprocesa
        update s; //se da update por dml
        Test.stopTest(); //termina el test

        // Comprobacion del test
        Account result = [SELECT Shipments_Processed__c FROM Account WHERE Id = :acc.Id]; //pedimos los datos de la account para ver que valores devolvio
        System.assertEquals(1, result.Shipments_Processed__c, 'El contador NO debe volver a sumar, debe quedarse en 1'); //revisamos si el valor es igual a uno, en caso de no serlo es que hay un error y manda el mensaje
    }
    @isTest
    static void testBulkification(){
        //declaramos
        Account acc = [SELECT Id FROM Account LIMIT 1]; //pedimos la cuenta
        List<Shipment__c> shipments = new List<Shipment__c>(); // lista para acumular los 200 shipments
        for (Integer i = 0; i < 200; i++) {
            shipments.add(new Shipment__c(Account__c = acc.Id)); //asignamos la cuenta
        }
        //empezamos el test
        Test.startTest();
        insert shipments; //Un solo DML para la lista
        for(Shipment__c s :shipments){
            s.Status__c = 'Processed'; //se cambia el status
        }
        update shipments; //se da el update como un solo DML
        Test.stopTest();

        //Verificamos
        Account result = [SELECT Shipments_Processed__c FROM Account WHERE Id = :acc.Id]; //traemos el valor de shipments procesados en la cuenta
        System.assertEquals(200, result.Shipments_Processed__c, 'Los 200 shipments deben contarse correctamente en la cuenta'); //revisamos que esten los 200
        List<Shipment__c> processedShipments = [SELECT Processed_At__c FROM Shipment__c WHERE Id IN :shipments]; //pedimos los shipments
        Integer countWithDate = 0; //hacemos una variable para hacer el conteo de shipments con fecha de processed at
        for (Shipment__c s : processedShipments) {
            if (s.Processed_At__c != null) { //revisamos que si el campo no esta vacio
                countWithDate++;  //añadimos por cada uno que tenga fecha
            }
        }
        System.assertEquals(200, countWithDate, 'Los 200 shipments deben tener Processed_At__c lleno, sin excepción'); //hacemos la comprobación de que esten los 200
        System.assert(Limits.getQueries() <= Limits.getLimitQueries(), 'No se debe exceder el límite de SOQL queries'); //revisamos que se hayan ejecutado las queris
        System.assert(Limits.getDMLStatements() <= Limits.getLimitDMLStatements(), 'No se debe exceder el límite de sentencias DML'); //revisamos que no haya algun error de limites
    }
}