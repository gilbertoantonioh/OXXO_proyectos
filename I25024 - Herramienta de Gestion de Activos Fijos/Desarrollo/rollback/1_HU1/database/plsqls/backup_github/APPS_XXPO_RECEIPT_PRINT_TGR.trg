SET DEFINE OFF;
PROMPT TRIGGER XXPO_RECEIPT_PRINT
  CREATE OR REPLACE EDITIONABLE TRIGGER "APPS"."XXPO_RECEIPT_PRINT" 
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
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.put_line ('Problem in retriving the data from the back end');
END;
/
SHOW ERRORS;
ALTER TRIGGER "APPS"."XXPO_RECEIPT_PRINT" ENABLE
