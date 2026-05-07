DECLARE
   lv_menu_name			apps.fnd_menus.menu_name%TYPE    := '&1';
   lv_function_name     apps.fnd_form_functions_vl.function_name%TYPE    := '&2';
   lv_prompt            apps.FND_MENU_ENTRIES_TL.prompt%TYPE    := '&3';
   
   lnMenuId   NUMBER;
   
   CURSOR CFuns IS
      SELECT *
      FROM   fnd_form_functions_vl
      WHERE  function_name = lv_function_name
      ;

   CURSOR CFunsMenus (pMenuID      NUMBER,
                      pFunctionID  NUMBER) IS
      SELECT *
      FROM   fnd_menu_entries
      WHERE  menu_id = pMenuID
      AND    function_id = pFunctionID
	  AND    grant_flag  = 'Y';
      
   RFunsMenus                 CFunsMenus%ROWTYPE;
   lnEntrySequence            fnd_menu_entries.entry_sequence%TYPE;
   lvRowID                    VARCHAR2(400);
BEGIN
   SELECT menu_id
   INTO   lnMenuId
   FROM   fnd_menus
   WHERE  menu_name = lv_menu_name;
   
   dbms_output.put_line('Agregado a Funcion '||lv_function_name||' a Menu '||lv_menu_name);
   
   FOR RFuns IN CFuns LOOP
      OPEN CFunsMenus (lnMenuId,RFuns.function_id);
      FETCH CFunsMenus INTO RFunsMenus;
      
      IF CFunsMenus%NOTFOUND 
		THEN		
         SELECT MAX(entry_sequence) entry_sequence
         INTO   lnEntrySequence
         FROM   fnd_menu_entries
         WHERE  menu_id = lnMenuId;        
         
         FND_MENU_ENTRIES_PKG.INSERT_ROW
             (X_ROWID => lvRowID, --in out nocopy VARCHAR2,
              X_MENU_ID => lnMenuId, --in NUMBER,
              X_ENTRY_SEQUENCE => (lnEntrySequence + 1), -- in NUMBER,
              X_SUB_MENU_ID => NULL, -- in NUMBER,
              X_FUNCTION_ID => RFuns.function_id, -- in NUMBER,
              X_GRANT_FLAG => 'Y', -- in VARCHAR2,
              X_PROMPT => NVL(lv_prompt, RFuns.user_function_name), -- in VARCHAR2,
              X_DESCRIPTION => 'Pantalla '||RFuns.user_function_name, -- in VARCHAR2,
              X_CREATION_DATE => SYSDATE, -- IN DATE,
              X_CREATED_BY => -1, -- IN NUMBER,
              X_LAST_UPDATE_DATE => SYSDATE, -- IN DATE,
              X_LAST_UPDATED_BY => -1, -- IN NUMBER,
              X_LAST_UPDATE_LOGIN => -1 -- IN NUMBER
              );
         
			dbms_output.put_line('Funcion agregada al menu');
		   COMMIT;              
		ELSE
			dbms_output.put_line('La funcion ya existe en el menu');
      END IF;
      CLOSE CFunsMenus;
   END LOOP;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
      dbms_output.put_line('Menu no encontrado');	
   WHEN OTHERS THEN
      dbms_output.put_line('ERROR Inesperado...');
      dbms_output.put_line(SQLCODE || ' - ' || SQLERRM);	   
END;
/
