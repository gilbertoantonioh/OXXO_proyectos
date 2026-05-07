SET DEFINE OFF
SET SERVEROUTPUT ON 
PROMPT Eliminando Opciones de Perfil
BEGIN
   FND_PROFILE_OPTIONS_PKG.DELETE_ROW('XXFC_RCV_FA_ORIGENES');
   COMMIT;
	
   dbms_output.put_line('Se elimino el el perfil XXFC_RCV_FA_ORIGENES' );
EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK; 
      dbms_output.put_line('Error al eliminar opcion de perfil ' || SQLERRM);

END;
/