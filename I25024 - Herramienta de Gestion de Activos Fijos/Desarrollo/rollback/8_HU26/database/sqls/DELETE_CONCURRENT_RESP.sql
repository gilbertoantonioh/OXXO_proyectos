SET DEFINE OFF
SET SERVEROUTPUT ON 
PROMPT Eliminando Programas Concurrentes 


BEGIN

   APPS.FND_PROGRAM.DELETE_PROGRAM('XXFA_SN_RCV_DATA','XXFC');

   COMMIT;
   
   dbms_output.put_line('Se elimino el programa concurrente XXFA_SN_RCV_DATA' );


EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      dbms_output.put_line('Error al eliminar concurrentes ' || SQLERRM);

END;
/
