SET DEFINE OFF
SET SERVEROUTPUT ON 
PROMPT Eliminando Programas Concurrentes 


BEGIN

   APPS.FND_PROGRAM.DELETE_PROGRAM('XXFA_SN_UPD_DATDET_SETDOC_WSH','XXFC');

   COMMIT;
   
   dbms_output.put_line('Se elimino el programa concurrente XXFA_SN_UPD_DATDET_SETDOC_WSH' );

EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      dbms_output.put_line('Error al eliminar concurrentes ' || SQLERRM);

END;
/
SHOW ERRORS;