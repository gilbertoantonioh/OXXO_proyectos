SET DEFINE OFF
SET SERVEROUTPUT ON 
PROMPT Eliminando Programas Concurrentes 


BEGIN

   APPS.FND_PROGRAM.DELETE_PROGRAM('XXFA_SN_WSH_TRIPS','XXFC');
   APPS.FND_PROGRAM.DELETE_PROGRAM('XXFA_SN_WSH_PURGE_TRIPS','XXFC');

   COMMIT;
   
   dbms_output.put_line('Se elimino el programa concurrente XXFA_SN_WSH_TRIPS' );
   dbms_output.put_line('Se elimino el programa concurrente XXFA_SN_WSH_PURGE_TRIPS' );

EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      dbms_output.put_line('Error al eliminar concurrentes ' || SQLERRM);

END;
/
