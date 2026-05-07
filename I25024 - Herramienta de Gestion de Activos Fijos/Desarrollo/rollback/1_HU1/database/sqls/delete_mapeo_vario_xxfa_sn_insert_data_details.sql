SET DEFINE OFF
SET SERVEROUTPUT ON 
PROMPT DELETE XXFC_MAPEOS_VARIOS XXFA_SN_INSERT_DATA_DETAILS

DECLARE

   ln_Salida          NUMBER;
   lv_Cadena          VARCHAR2(250);
   ln_MapeoIdSuperior NUMBER;
   
BEGIN   
   DELETE XXFC_MAPEOS_VARIOS
   WHERE  tipo_mapeo = 'XXFA_SN_INSERT_DATA_DETAILS'
   ;

   
   COMMIT;
   
EXCEPTION
   WHEN OTHERS THEN
      dbms_output.put_line('Error inesperado al borrar mapeo. Detalle: ' || SQLERRM);
      
      ROLLBACK;
      
END;
/