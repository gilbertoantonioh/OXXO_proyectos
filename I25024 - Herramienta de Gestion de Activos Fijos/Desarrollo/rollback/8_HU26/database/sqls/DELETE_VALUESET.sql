SET DEFINE OFF
SET SERVEROUTPUT ON 
PROMPT Eliminando Juegos de Valores
BEGIN
   FND_FLEX_VAL_API.DELETE_VALUESET('XXFA_SN_RCV_OTROS_DEPURA_DIAS_RESGUARDO');
   FND_FLEX_VAL_API.DELETE_VALUESET('XXFC_RCV_FA_ORIGENES_VS');   
   COMMIT;
	
   dbms_output.put_line('Se elimino el juego de valores XXFA_SN_RCV_OTROS_DEPURA_DIAS_RESGUARDO' );
   dbms_output.put_line('Se elimino el juego de valores XXFC_RCV_FA_ORIGENES_VS' );
	
EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK; 
      dbms_output.put_line('Error al eliminar juego de valores ' || SQLERRM);

END;
/