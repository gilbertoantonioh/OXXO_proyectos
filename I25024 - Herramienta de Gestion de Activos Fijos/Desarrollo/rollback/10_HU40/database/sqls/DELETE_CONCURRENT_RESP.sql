SET DEFINE OFF
SET SERVEROUTPUT ON 
PROMPT Eliminando Programas Concurrentes 


BEGIN

   APPS.FND_PROGRAM.DELETE_PROGRAM('XXFA_SN_PO_OTH_VALIDATE_CD','XXFC');

   COMMIT;
   
   dbms_output.put_line('Se elimino el programa concurrente XXFA_SN_PO_OTH_VALIDATE_CD' );


EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      dbms_output.put_line('Error al eliminar concurrentes ' || SQLERRM);

END;
/
