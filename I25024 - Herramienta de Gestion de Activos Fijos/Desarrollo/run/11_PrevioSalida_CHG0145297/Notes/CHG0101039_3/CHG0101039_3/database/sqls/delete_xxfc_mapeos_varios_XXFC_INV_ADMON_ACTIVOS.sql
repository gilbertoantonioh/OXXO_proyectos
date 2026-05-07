SET DEFINE OFF
SET SERVEROUTPUT ON 
PROMPT BORRA XXFC_MAPEOS_VARIOS XXFC_INV_ADMON_ACTIVOS

  
BEGIN   
   DELETE XXFC_MAPEOS_VARIOS
   WHERE  tipo_mapeo = 'XXFC_INV_ADMON_ACTIVOS'
   ;   
   
   COMMIT;      
   
    dbms_output.put_line('Se borra mapeo XXFC_INV_ADMON_ACTIVOS'); 

   
EXCEPTION
   WHEN OTHERS THEN
      dbms_output.put_line('Error inesperado al borrar mapeo. Detalle: ' || SQLERRM);
      
      ROLLBACK;
      
END;
/

SHOW ERRORS;
/
   
