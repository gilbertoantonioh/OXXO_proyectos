SET DEFINE OFF
SET SERVEROUTPUT ON 
PROMPT ELIMINA MAPEO VARIO XXFA_SN_WSH_PURGE_TRIPS
DECLARE

   ln_salida   NUMBER;
   lv_cadena   VARCHAR2(4000);
   
   

BEGIN
   delete xxfc_mapeos_varios
   where tipo_mapeo = 'XXFA_SN_WSH_PURGE_TRIPS'
   ;
      
   COMMIT;
   
   dbms_output.put_line('Se elimina tipo de mapeo XXFA_SN_WSH_PURGE_TRIPS ');  
EXCEPTION
   WHEN OTHERS THEN
      dbms_output.put_line('Error inesperado al eliminar tipo de mapeo XXFA_SN_WSH_PURGE_TRIPS. Detalle: ' || SQLERRM);
      ROLLBACK;
END;
/