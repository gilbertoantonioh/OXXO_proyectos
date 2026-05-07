SET DEFINE OFF
SET SERVEROUTPUT ON 
PROMPT DELETE MAPEO VARIO XXFA_EBS_SN - EBS_SN_VIAJES_COMP
BEGIN

   DELETE xxfc_mapeos_varios
   WHERE  tipo_mapeo = 'XXFA_EBS_SN'
   AND    entrada    = 'EBS_SN_VIAJES_COMP'
   ;

   COMMIT;
EXCEPTION 
   WHEN OTHERS THEN
      ROLLBACK;
      dbms_output.put_line('Eror al eliminar registro en tabla de Mapeos Varios  XXFA_EBS_SN-EBS_SN_VIAJES_COMP: '||SQLERRM);      
END;   
/