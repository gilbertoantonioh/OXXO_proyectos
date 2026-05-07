SET DEFINE OFF;
PROMPT TRIGGER XXPO_RCV_TRANSACTION
CREATE OR REPLACE EDITIONABLE TRIGGER "APPS"."XXPO_RCV_TRANSACTION" 
/***************************************************************************************
       # Modulo        : XXPO_RCV_TRANSACTION
       # Modificado Por          Fecha         Descripci?
	   # -------------------------------------------------------------------------------------
	   # Hilda Medina           24/Jul/2020    CO_52060626 Upgrade R12.2.4 - Validacion de Cargas Iniciales
	   # Gilberto Hernandez (Hexaware)  15/Ago/2025   CHG0101033  - LLenar la tabla intermedia xxfa_sn_data_details para service now. 
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
  
   lv_error VARCHAR2(4000);
  PRAGMA AUTONOMOUS_TRANSACTION;
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
    insert into  XXPO_RECEIPT_PRINT
    (shipment_header_id,organization_id,vendor_id,vendor_site_id)
    values(:new.shipment_header_id,:new.organization_id,:new.vendor_id,:new.vendor_site_id);
END IF;
   --Inicio ChO ***51967670*** IMPRIME ETIQUETA RECEPCION OC
   IF lv_CountLin = 0 AND :new.transaction_type='RECEIVE' THEN
      insert into XXFC_ONT_RCV_IMP_TMP values(:new.po_header_id,:new.po_release_id,:new.shipment_header_id);
      lv_Status := APPS.XXFC_WMS_LABEL_RCV_FNC(:new.po_header_id, :new.po_release_id, :new.shipment_header_id, :new.organization_id);
      COMMIT;
   END IF;
   --Fin ChO ***51967670***
   insert into xxfc_cp_tmp_carga ( attribute1, attribute2) values ('XXPO_RCV_TRANSACTION', '3');
   commit; 
   --CHG0101033 HERNAGI: Inicio 
   DECLARE 
      lv_msi_use_type  mtl_system_items_b.attribute1%TYPE := NULL;
      lv_errbuf        VARCHAR2(4000):= NULL;  
      lv_retcode       VARCHAR2(1):= NULL;
	  
	  lv_error VARCHAR2(4000);
   BEGIN
      insert into xxfc_cp_tmp_carga (attribute1, attribute2) values ('XXPO_RCV_TRANSACTION', '4.1'); -- Sin accion ante cualquier error.
      COMMIT;	  
      -- obtener el uso del articulo
      SELECT '04'
      INTO   lv_msi_use_type
      FROM   rcv_transactions             rcv
          -- , rcv_shipment_lines           rsl
          -- , mtl_system_items_b           msi            
      WHERE 1 = 1
      --AND   rcv.shipment_line_id        = rsl.shipment_line_id
      --AND   rsl.to_organization_id      = msi.organization_id   
     -- AND   rsl.item_id                 = msi.inventory_item_id    
      AND   rcv.rowid          = :NEW.rowid
      ;	  
      insert into xxfc_cp_tmp_carga (attribute1, attribute2) values ('XXPO_RCV_TRANSACTIONlv_msi_use_type', lv_msi_use_type); -- Sin accion ante cualquier error.
      COMMIT;	  
	  -- Valida el uso de articulo y organizacion de inventario
	  FOR rec IN (SELECT 1
	              FROM   dual
				  WHERE  EXISTS 
				         (
						 SELECT 1
						 FROM   xxfc_mapeos_varios xmv
				         WHERE  xmv.tipo_mapeo = 'XXFA_SN_INSERT_DATA_DETAILS'
				         AND    xmv.entrada    LIKE 'USE_ITEM%'
				         AND    xmv.salida1    = lv_msi_use_type
						 AND    xmv.estado     = 'A'
                         AND    ( xmv.fecha_inicial < SYSDATE OR xmv.fecha_inicial IS NULL )
                         AND    ( xmv.fecha_final > SYSDATE OR xmv.fecha_final IS NULL )
				         ) 
			      AND EXISTS 
                         (
                         SELECT 1
                         FROM   fnd_flex_values_vl ffv
                              , fnd_flex_value_sets fvs
                         WHERE  ffv.flex_value_set_id = fvs.flex_value_set_id
                         AND    fvs.flex_value_set_name LIKE 'XXPO_ORG_REP_VALORIZA_ENT'  
                         AND    ffv.enabled_flag = 'Y'
                         AND    ( ffv.start_date_active < SYSDATE OR ffv.start_date_active IS NULL )
                         AND    ( ffv.end_date_active > SYSDATE OR ffv.end_date_active IS NULL )
                         AND    ffv.flex_value  = TO_CHAR(:NEW.organization_id)
                         ) 						 
				  )
	  LOOP 
      insert into xxfc_cp_tmp_carga (attribute1, attribute2) values ('XXPO_RCV_TRANSACTION', '6'); -- Sin accion ante cualquier error.
      COMMIT;
         -- Ejecuta carga informacion de recepcion de inventario en tabla intermedia 
         xxfa_sn_data_api_pkg.load_details_from_rcv_prc(lv_errbuf, lv_retcode, :NEW.transaction_id );
      insert into xxfc_cp_tmp_carga (attribute1, attribute2) values ('XXPO_RCV_TRANSACTION', lv_errbuf); -- Sin accion ante cualquier error.
	  insert into xxfc_cp_tmp_carga (attribute1, attribute2) values ('XXPO_RCV_TRANSACTION', lv_retcode); -- Sin accion ante cualquier error.
		 COMMIT;
      END LOOP; 	  
      insert into xxfc_cp_tmp_carga (attribute1, attribute2) values ('XXPO_RCV_TRANSACTION', '7'); -- Sin accion ante cualquier error.
      COMMIT;

   EXCEPTION 
      WHEN OTHERS THEN 
	     lv_error :=  SQLERRM;
	     insert into xxfc_cp_tmp_carga (attribute1, attribute2) values ('XXPO_RCV_TRANSACTION8', lv_error); -- Sin accion ante cualquier error. 
		 commit;
   END; 		 
   --CHG0101033 HERNAGI: Fin 
END IF;
EXCEPTION
WHEN NO_DATA_FOUND THEN
DBMS_OUTPUT.PUT_LINE('Problem in retriving the data from the back end');
	     insert into xxfc_cp_tmp_carga (attribute1, attribute2) values ('XXPO_RCV_TRANSACTION', 'NO data found'); -- Sin accion ante cualquier error. 
		 commit;
WHEN OTHERS THEN
DBMS_OUTPUT.PUT_LINE('Problem in retriving the data from the back end');
	     lv_error :=  SQLERRM;
	     insert into xxfc_cp_tmp_carga (attribute1, attribute2) values ('XXPO_RCV_TRANSACTION', lv_error); -- Sin accion ante cualquier error. 
		 commit;
END;
/
SHOW ERRORS; 

ALTER TRIGGER "APPS"."XXPO_RCV_TRANSACTION" ENABLE
