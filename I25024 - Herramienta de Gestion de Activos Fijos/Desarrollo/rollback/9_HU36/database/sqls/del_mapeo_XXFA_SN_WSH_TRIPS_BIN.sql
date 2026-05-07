SET DEFINE OFF
SET SERVEROUTPUT ON 
PROMPT DELETE MAPEO VARIO XXFA_SN_WSH_TRIPS_BIN
DECLARE

   ln_salida   NUMBER;
   lv_cadena   VARCHAR2(4000);
BEGIN

   DELETE xxfc_mapeos_varios
   WHERE  tipo_mapeo = 'XXFA_SN_WSH_TRIPS_BIN'
   ;

      
   COMMIT;
  
EXCEPTION
   WHEN OTHERS THEN
      dbms_output.put_line('Error inesperado al eliminar mapeo XXFA_SN_WSH_TRIPS_BIN. Detalle: ' || SQLERRM);
      ROLLBACK;
END;
/