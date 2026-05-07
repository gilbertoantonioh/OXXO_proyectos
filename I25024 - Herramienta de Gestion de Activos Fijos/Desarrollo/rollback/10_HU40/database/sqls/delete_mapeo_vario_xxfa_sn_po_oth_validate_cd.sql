SET DEFINE OFF
SET SERVEROUTPUT ON 
PROMPT ELIMINA XXFC_MAPEOS_VARIOS XXFA_SN_PO_OTH_VALIDATE_CD

DECLARE

   ln_Salida          NUMBER;
   lv_Cadena          VARCHAR2(250);
   ln_MapeoIdSuperior NUMBER;
   
BEGIN   
   DELETE XXFC_MAPEOS_VARIOS
   WHERE  tipo_mapeo = 'XXFA_SN_PO_OTH_VALIDATE_CD'
   ;

   
   COMMIT;
   
EXCEPTION
   WHEN OTHERS THEN
      dbms_output.put_line('Error inesperado al eliminar mapeo. Detalle: ' || SQLERRM);
      
      ROLLBACK;
      
END;
/