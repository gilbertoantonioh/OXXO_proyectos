SET DEFINE OFF;
PROMPT TRIGGER XXPO_RECEIPT_PRINT
  CREATE OR REPLACE EDITIONABLE TRIGGER "APPS"."XXPO_RECEIPT_PRINT" 
/***************************************************************************************
       # Modulo        : XXPO_RECEIPT_PRINT
       # Modificado Por                 Fecha         Descripcion
	   # -------------------------------------------------------------------------------------
	   # Gilberto Hernandez (Hexaware)  15/Ago/2025   CHG0101033  - LLenar la tabla intermedia xxfa_sn_data_details para service now. 
***************************************************************************************/
   AFTER INSERT
   ON "XXFC"."XXPO_RECEIPT_PRINT#"
   REFERENCING OLD AS OLD NEW AS NEW
   FOR EACH ROW 
DECLARE
   returncode           BOOLEAN;
   concreqid            NUMBER  := 0;
   l_copies_mode        BOOLEAN;
   n_num_copy           NUMBER  := 0;
   n_msg_value          NUMBER  := 0;
   n_count              NUMBER  := 0;
   l_organization_id    NUMBER;
   l_ret_status         BOOLEAN;
   --Inicio 51971777 - Se agregan variables
   lv_language          fnd_languages.iso_language%TYPE;
   lv_territory         fnd_languages.iso_territory%TYPE;
   lv_impresora         VARCHAR2(100);
   ln_copias            NUMBER;
   --Fin 51971777
   
BEGIN
   /* fnd_message.set_name('INV', 'XXINV_PRINT_CONFIRM');
    fnd_message.set_token('PRINTER','impfal');
    n_msg_value:=fnd_message.question('YES','NO',null);*/
   --validar que la recepcion sea de una organizacion que este
   --definida en la lista de valores de xxpo_org_rep_valoriza_ent (organizaciones
   --que imprimen valorizaciones de entradas).
   --pedro lozano galindo  03-Mar-2008
   BEGIN
      SELECT NVL (TO_NUMBER (flex_value), 0) organization_id
        INTO l_organization_id
        FROM fnd_flex_values_vl
       WHERE flex_value_set_id =
                 (SELECT flex_value_set_id
                    FROM fnd_flex_value_sets
                   WHERE flex_value_set_name LIKE 'XXPO_ORG_REP_VALORIZA_ENT')
         AND enabled_flag = 'Y'
         AND end_date_active IS NULL
         AND TO_NUMBER (flex_value) = :NEW.organization_id;
   EXCEPTION
      WHEN OTHERS THEN
         l_organization_id := 0;
   END;
   IF l_organization_id <> 0 THEN
      concreqid := 0;
      returncode := fnd_request.set_mode (TRUE);
      --Inicio 51971777  Se obtiene impresora y número de copias en base a perfiles
      lv_impresora := fnd_profile.value('XXFC_INVREAV_IMPRESORA');
      ln_copias := fnd_profile.value('XXFC_INVREAV_COPIAS');
      IF n_msg_value = 1 THEN
         l_copies_mode :=
            --se manda nombre de impresora y copias en base a variables obtenidas
            fnd_request.set_print_options (lv_impresora,--'recibooc',
                                           'LANDSCAPE POINV',
                                           ln_copias,--1,
                                           TRUE,
                                           'N'
                                          );
      ELSE
         l_copies_mode :=
            fnd_request.set_print_options (lv_impresora,--'recibooc',
                                           'LANDSCAPE POINV',
                                           ln_copias,--1,
                                           TRUE,
                                           'N'
                                          );
      END IF;
      --Se obtiene lenguage y territorio
      BEGIN
      SELECT iso_language
            ,iso_territory
        INTO lv_language
           , lv_territory
        FROM fnd_languages
       WHERE language_code = USERENV('LANG');
      EXCEPTION WHEN OTHERS THEN
         lv_language := 'ES';
         lv_territory:=  'US';
      END;
      --Se asigna la plantilla al reporte
      l_ret_status :=fnd_request.add_layout('XXFC',
                                            'XXFC_INVREAV',
                                            lv_language,
                                            lv_territory,
                                            'PDF');
      IF (l_copies_mode = TRUE) THEN
         --Se manda ejecutar el nuevo reporte con salida PDF
         concreqid := fnd_request.submit_request
                                    (application      => 'XXFC',
                                     --application      => 'PO',
                                     program          => 'XXFC_INVREAV',
                                     --program          => 'XXPO_ALMACEN_ACTIVOFIJO_CONCU',
                                     description      => NULL,
                                     start_time       => SYSDATE,
                                     sub_request      => FALSE,
                                     argument1        => :NEW.organization_id,
                                     argument2        => :NEW.vendor_id,
                                     argument3        => :NEW.vendor_site_id,
                                     argument4        => :NEW.shipment_header_id
                                    );
      END IF;
      --Fin 51971777
      IF concreqid = 0 THEN
         DBMS_OUTPUT.put_line ('Problem Submitting Program to get pims txn batch');
      END IF;
      

      --CHG0101033 HERNAGI: Inicio 
      DECLARE 
         lv_msi_use_type  mtl_system_items_b.attribute1%TYPE := NULL;
         lv_errbuf        VARCHAR2(4000):= NULL;  
         lv_retcode       VARCHAR2(1):= NULL;
         
         lv_error VARCHAR2(4000);
      BEGIN 
         -- obtener el uso del articulo
         SELECT msi.attribute1
         INTO   lv_msi_use_type
         FROM   rcv_transactions             rcv
              , rcv_shipment_lines           rsl
              , mtl_system_items_b           msi            
         WHERE 1 = 1
         AND   rcv.shipment_line_id        = rsl.shipment_line_id
         AND   rsl.to_organization_id      = msi.organization_id   
         AND   rsl.item_id                 = msi.inventory_item_id    
         AND   rcv.transaction_id          = :NEW.rcv_transaction_id
         ;   
    
         -- Valida el uso de articulo
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
                     )
         LOOP 
            -- Ejecuta carga informacion de recepcion de inventario en tabla intermedia 
            xxfa_sn_data_api_pkg.load_details_from_rcv_prc(lv_errbuf, lv_retcode, :NEW.rcv_transaction_id );
         END LOOP;       

      
      EXCEPTION 
         WHEN OTHERS THEN 
            lv_error :=  SQLERRM;
            insert into xxfc_cp_tmp_carga (attribute1, attribute2) values ('XXPO_RCV_TRANSACTION1', lv_error); -- Sin accion ante cualquier error. 
      END;          
      --CHG0101033 HERNAGI: Fin 
      
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.put_line ('Problem in retriving the data from the back end');
END;
/
SHOW ERRORS;
ALTER TRIGGER "APPS"."XXPO_RECEIPT_PRINT" ENABLE
