SET DEFINE OFF
SET SERVEROUTPUT ON 
PROMPT Eliminando Juegos de Valores
BEGIN
   FND_FLEX_VAL_API.DELETE_VALUESET('XXFA_SN_VIAJES_DEPURA_DIAS_RESGUARDO');
   COMMIT;
	
   dbms_output.put_line('Se elimino el juego de valores XXFA_SN_VIAJES_DEPURA_DIAS_RESGUARDO' );
  
EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK; 
      dbms_output.put_line('Error al eliminar juego de valores ' || SQLERRM);

END;
/