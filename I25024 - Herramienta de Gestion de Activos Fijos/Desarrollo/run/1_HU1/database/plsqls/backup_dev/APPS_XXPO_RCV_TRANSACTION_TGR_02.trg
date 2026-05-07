SET DEFINE OFF;
PROMPT TRIGGER XXPO_RCV_TRANSACTION
CREATE OR REPLACE EDITIONABLE TRIGGER "APPS"."XXPO_RCV_TRANSACTION" 
/***************************************************************************************
       # Modulo        : XXPO_RCV_TRANSACTION
       # Modificado Por          Fecha         Descripci?
	   # -------------------------------------------------------------------------------------
	   # Hilda Medina           24/Jul/2020    CO_52060626 Upgrade R12.2.4 - Validacion de Cargas Iniciales
	   # Gilberto Hernandez (Hexaware)  15/Ago/2025   CHG0101033  - Insertar el valor RCV_TRANSACTION_ID en la tabla XXPO_RECEIPT_PRINT
***************************************************************************************/
 AFTER INSERT
 ON PO.RCV_TRANSACTIONS#
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
Declare
  t_shipment_header_id NUMBER;
  lv_UnitPrice         VARCHAR2(30);
  lv_Status            VARCHAR2(10);
  lv_CountLin          NUMBER; --ChO ***51967670***
  
  PRAGMA AUTONOMOUS_TRANSACTION; --CHG0101033 HERNAGI: Evitar tablas mutantes.
BEGIN
   --24/Julio/2020 CO_52060626
   IF APPS.XXFC_DATOS_VARIABLES_PKG.gv_CargaInicial = 'SI' THEN
      RETURN;
   END IF;
   --
IF  :new.transaction_type = 'RECEIVE' THEN
    select nvl(count(shipment_header_id),0)
    into t_shipment_header_id
    from XXPO_RECEIPT_PRINT
    where shipment_header_id = :new.shipment_header_id
    and   organization_id    = :new.organization_id
    and   vendor_id          = :new.vendor_id
    and   vendor_site_id     = :new.vendor_site_id;
   --Inicio ChO ***51967670*** IMPRIME ETIQUETA RECEPCION OC
   BEGIN
      SELECT NVL(count(shipment_header_id),0)
      INTO   lv_CountLin
      FROM   XXFC_ONT_RCV_IMP_TMP
      WHERE  1=1
      AND    po_header_id = :new.po_header_id
      AND    nvl(po_release_id,0) = nvl(:new.po_release_id, 0)
      AND    shipment_header_id = :new.shipment_header_id;
   EXCEPTION
      WHEN OTHERS THEN
         lv_CountLin := 0;
   END;
   --Fin ChO ***51967670***
--IF t_shipment_header_id = 0 THEN 21/Abr/2017 -- ChO ***51967670***
--Inicio ChO ***51967670***
IF (t_shipment_header_id) = 0 AND
   (:new.attribute1 is not null) THEN
--Fin ChO ***51967670***
    --CHG0101033 HERNAGI. Inicia 
	/*
    insert into  XXPO_RECEIPT_PRINT
    (shipment_header_id,organization_id,vendor_id,vendor_site_id)
    values(:new.shipment_header_id,:new.organization_id,:new.vendor_id,:new.vendor_site_id);
    */
	
    insert into  XXPO_RECEIPT_PRINT
    (shipment_header_id,organization_id,vendor_id,vendor_site_id, rcv_transaction_id)
    values(:new.shipment_header_id,:new.organization_id,:new.vendor_id,:new.vendor_site_id, :new.transaction_id);
	COMMIT;
	 --CHG0101033 HERNAGI. Termina 
	
END IF;
   --Inicio ChO ***51967670*** IMPRIME ETIQUETA RECEPCION OC
   IF lv_CountLin = 0 AND :new.transaction_type='RECEIVE' THEN
      insert into XXFC_ONT_RCV_IMP_TMP values(:new.po_header_id,:new.po_release_id,:new.shipment_header_id);
      lv_Status := APPS.XXFC_WMS_LABEL_RCV_FNC(:new.po_header_id, :new.po_release_id, :new.shipment_header_id, :new.organization_id);
      COMMIT;
   END IF;
   --Fin ChO ***51967670***
END IF;
EXCEPTION
WHEN NO_DATA_FOUND THEN
DBMS_OUTPUT.PUT_LINE('Problem in retriving the data from the back end');
WHEN OTHERS THEN
DBMS_OUTPUT.PUT_LINE('Problem in retriving the data from the back end');
END;
/

SHOW ERRORS; 

ALTER TRIGGER "APPS"."XXPO_RCV_TRANSACTION" ENABLE

