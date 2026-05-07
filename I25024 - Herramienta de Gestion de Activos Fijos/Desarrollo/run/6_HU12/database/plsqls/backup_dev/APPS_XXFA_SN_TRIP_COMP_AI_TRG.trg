SET DEFINE OFF;
PROMPT TRIGGER XXFA_SN_TRIP_COMP_AI ON XXFC.xxfc_inv_firma_salidas
CREATE OR REPLACE TRIGGER APPS.XXFA_SN_TRIP_COMP_AI
AFTER INSERT 
ON "XXFC"."XXFC_INV_FIRMA_SALIDAS"
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
   /********************************************************************************************
   * Modulo : XXFA_SN_TRIP_COMP_AI
   * Autor : Oscar Medina (Hexaware) 
   * Version : 1.0
   * Fecha : 08/Ene/2026
   * Descripcion : Trigger para inserta la informacion de los transportistas de los envios firmados en 
   * la tabla staging xxfa_sn_trip_comp
   *
   * Ejecutado Por :
   *
   * Ejecuciones :
   *
   * Modificado Por                 Fecha         Codigo          Descripcion
   * -------------------------------------------------------------------------------------------
   * Oscar Medina (Hexaware)        08/Ene/2026   CHG0137347      Version Inicial
   ********************************************************************************************/
DECLARE
   ln_ship_from_org_id  NUMBER;
   PRAGMA AUTONOMOUS_TRANSACTION;   
BEGIN
   BEGIN
      SELECT    organization_id
      INTO      ln_ship_from_org_id
      FROM      xxfc_inv_header_salidas_v
      WHERE     header_id = :NEW.transaction_set_id
      AND       move_order = :NEW.transaction_source_id;
   EXCEPTION
   -- Si no encuentra datos, simplemente salimos del trigger inmediatamente.
      WHEN OTHERS
          THEN
             RETURN;
   END;
   -- Inserta una nueva fila en xxfa_sn_trip_comp usando los datos de la fila recién insertada en la tabla de origen
    INSERT INTO xxfc.xxfa_sn_trip_comp (
        wst_trip_name,
        freight_name,
        carrier_name,
        plate_number,
        inv_org_unit,
        attribute1,
        attribute2,
        attribute3,
        attribute4,
        attribute5,
        created_by,
        last_updated_by,
        last_update_login
    ) VALUES (
        :NEW.transaction_source_id,    
        :NEW.nombre_fletera,    
        :NEW.nombre_transportista, 
        :NEW.no_placa,            
        ln_ship_from_org_id,          
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        :NEW.created_by,
        :NEW.last_updated_by,
        :NEW.last_update_login
    );

   COMMIT; 
EXCEPTION
   WHEN OTHERS THEN
      -- En caso de alguna falla no levantar ninguna excepcion 
	  NULL;
END;
/
SHOW ERRORS;