SET DEFINE OFF
SET SERVEROUTPUT ON 
PROMPT DELETE MAPEO VARIO XXFA_EBS_SN - EBS_SN_DIRECTOS
DECLARE
   ln_salida   NUMBER;
   lv_cadena   VARCHAR2(4000);
BEGIN

   DELETE xxfc_mapeos_varios
   WHERE  tipo_mapeo = 'XXFA_EBS_SN'
   AND    entrada    = 'EBS_SN_DIRECTOS'
   ;

   dbms_output.put_line('Se borra registro en tabla de Mapeos Varios  XXFA_EBS_SN-EBS_SN_DIRECTOS');

EXCEPTION 
   WHEN OTHERS THEN
      ROLLBACK;
      dbms_output.put_line('Eror al borra registro en tabla de Mapeos Varios  XXFA_EBS_SN-EBS_SN_DIRECTOS: '||SQLERRM);      
END;   
/