SET DEFINE OFF;
PROMPT PACKAGE BODY XXFA_SN_CONTROL_PKG
CREATE OR REPLACE PACKAGE BODY APPS.XXFA_SN_CONTROL_PKG AS 

   /********************************************************************************************
   * Modulo : XXFA_SN_CONTROL_PKG
   * Autor : Gilberto Hernandez (Hexaware) 
   * Version : 1.0
   * Fecha : 15/Sep/2025
   * Descripcion : Table Handler para la tabla xxfc.xxfa_sn_control
   *
   * Ejecutado Por :
   *
   * Ejecuciones :
   *
   * Modificado Por                 Fecha         Codigo          Descripcion
   * -------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Version Inicial
   ********************************************************************************************/


   /********************************************************************************************
   Modulo : lock_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 15/Sep/2025
   Descripcion : Lock Row sobre la tabla xxfc.xxfa_sn_control
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Version Inicial
   ********************************************************************************************/
	/*--------------------------lock_row-------------------------*/
	PROCEDURE lock_row (p_rowid ROWID
			, p_DATA_CONTROL_ID IN NUMBER
			, p_DATA_SOURCE_ID IN NUMBER
			, p_DATA_SOURCE_CODE IN VARCHAR2
			, p_DATA_FILE_NAME IN VARCHAR2
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
		
		CURSOR c IS SELECT 
			DATA_CONTROL_ID
			, DATA_SOURCE_ID
			, DATA_SOURCE_CODE
			, DATA_FILE_NAME
			FROM XXFA_SN_CONTROL
			WHERE ROWID = p_rowid
			FOR UPDATE NOWAIT;
		recinfo c%ROWTYPE;
	BEGIN
		x_errors := '';
		x_retcode := 0;
		OPEN c;
		FETCH c INTO recinfo;
		IF (c%NOTFOUND) THEN
			x_retcode := 2;
			x_errors := 'THE RECORD WITH ROWID = ' || p_rowid || ' NO LONGER EXISTS IN TABLE XXFA_SN_CONTROL';
		ELSIF (NOT (((recinfo.DATA_CONTROL_ID = p_DATA_CONTROL_ID) OR (recinfo.DATA_CONTROL_ID IS NULL AND p_DATA_CONTROL_ID IS NULL))
				AND ((recinfo.DATA_SOURCE_ID = p_DATA_SOURCE_ID) OR (recinfo.DATA_SOURCE_ID IS NULL AND p_DATA_SOURCE_ID IS NULL))
				AND ((recinfo.DATA_SOURCE_CODE = p_DATA_SOURCE_CODE) OR (recinfo.DATA_SOURCE_CODE IS NULL AND p_DATA_SOURCE_CODE IS NULL))
				AND ((recinfo.DATA_FILE_NAME = p_DATA_FILE_NAME) OR (recinfo.DATA_FILE_NAME IS NULL AND p_DATA_FILE_NAME IS NULL)))) THEN
			x_retcode := 2;
			x_errors := 'THE RECORD WITH ROWID = ' || p_rowid || ' IN TABLE XXFA_SN_CONTROL HAS CHANGED.';
		END IF;
		CLOSE c;
	EXCEPTION
		WHEN OTHERS THEN
			x_retcode := 2;
			x_errors := SQLERRM;
	END lock_row;

   /********************************************************************************************
   Modulo : lock_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 15/Sep/2025
   Descripcion : Lock Row sobre la tabla xxfc.xxfa_sn_control
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Version Inicial
   ********************************************************************************************/

	/*--------------------------lock_row-------------------------*/
	PROCEDURE lock_row (p_rowid ROWID
			, p_XxfaSnControl XXFA_SN_CONTROL%ROWTYPE
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
		
	BEGIN
		lock_row(p_rowid
			, p_XxfaSnControl.DATA_CONTROL_ID
			, p_XxfaSnControl.DATA_SOURCE_ID
			, p_XxfaSnControl.DATA_SOURCE_CODE
			, p_XxfaSnControl.DATA_FILE_NAME
			, x_errors, x_retcode);
	END lock_row;

   /********************************************************************************************
   Modulo : update_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 15/Sep/2025
   Descripcion : Update Row sobre la tabla xxfc.xxfa_sn_control
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Version Inicial
   ********************************************************************************************/
	/*--------------------------update_row-------------------------*/
	PROCEDURE update_row (p_DATA_CONTROL_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_DATA_SOURCE_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_DATA_SOURCE_CODE IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_DATA_FILE_NAME IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
		
	BEGIN
		x_errors := '';
		UPDATE XXFA_SN_CONTROL SET DATA_CONTROL_ID = DECODE(p_DATA_CONTROL_ID, FND_API.G_MISS_NUM, DATA_CONTROL_ID, p_DATA_CONTROL_ID)
			, DATA_SOURCE_ID = DECODE(p_DATA_SOURCE_ID, FND_API.G_MISS_NUM, DATA_SOURCE_ID, p_DATA_SOURCE_ID)
			, DATA_SOURCE_CODE = DECODE(p_DATA_SOURCE_CODE, FND_API.G_MISS_CHAR, DATA_SOURCE_CODE, p_DATA_SOURCE_CODE)
			, DATA_FILE_NAME = DECODE(p_DATA_FILE_NAME, FND_API.G_MISS_CHAR, DATA_FILE_NAME, p_DATA_FILE_NAME)
			, LAST_UPDATE_LOGIN = FND_PROFILE.value('LOGIN_ID')
			, LAST_UPDATE_DATE = SYSDATE
			, LAST_UPDATED_BY = FND_PROFILE.value('USER_ID')
		WHERE DATA_CONTROL_ID = p_DATA_CONTROL_ID;
		x_retcode := 0;
		--COMMIT;
	EXCEPTION
		WHEN OTHERS THEN
			x_errors := SQLERRM;
			x_retcode := 2;
	END update_row;

   /********************************************************************************************
   Modulo : update_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 15/Sep/2025
   Descripcion : Update Row sobre la tabla xxfc.xxfa_sn_control
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Version Inicial
   ********************************************************************************************/
	/*--------------------------update_row-------------------------*/
	PROCEDURE update_row (p_XxfaSnControl XXFA_SN_CONTROL%ROWTYPE
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
		
	BEGIN
		update_row(p_XxfaSnControl.DATA_CONTROL_ID
			, p_XxfaSnControl.DATA_SOURCE_ID
			, p_XxfaSnControl.DATA_SOURCE_CODE
			, p_XxfaSnControl.DATA_FILE_NAME
			, x_errors, x_retcode);
	END update_row;

   /********************************************************************************************
   Modulo : insert_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 15/Sep/2025
   Descripcion : Insert Row sobre la tabla xxfc.xxfa_sn_control
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Version Inicial
   ********************************************************************************************/
	/*--------------------------insert_row-------------------------*/
	PROCEDURE insert_row(x_rowid OUT ROWID
			, p_DATA_CONTROL_ID IN NUMBER
			, p_DATA_SOURCE_ID IN NUMBER
			, p_DATA_SOURCE_CODE IN VARCHAR2
			, p_DATA_FILE_NAME IN VARCHAR2
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
		
	BEGIN
		x_errors := '';
		INSERT INTO XXFA_SN_CONTROL(DATA_CONTROL_ID
			, DATA_SOURCE_ID
			, DATA_SOURCE_CODE
			, DATA_FILE_NAME
			, LAST_UPDATE_LOGIN
			, CREATION_DATE
			, CREATED_BY
			, LAST_UPDATE_DATE
			, LAST_UPDATED_BY) VALUES (p_DATA_CONTROL_ID
			, p_DATA_SOURCE_ID
			, p_DATA_SOURCE_CODE
			, p_DATA_FILE_NAME
			, FND_PROFILE.value('LOGIN_ID')
			, SYSDATE
			, FND_PROFILE.value('USER_ID')
			, SYSDATE
			, FND_PROFILE.value('USER_ID')) RETURNING ROWID INTO x_rowid;
		x_retcode := 0;
		--COMMIT;
	EXCEPTION
		WHEN OTHERS THEN
			x_errors := SQLERRM;
			x_retcode := 2;
	END insert_row;

   /********************************************************************************************
   Modulo : insert_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 15/Sep/2025
   Descripcion : Insert Row sobre la tabla xxfc.xxfa_sn_control
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Version Inicial
   ********************************************************************************************/
	/*--------------------------insert_row-------------------------*/
	PROCEDURE insert_row(x_rowid OUT ROWID
			, p_XxfaSnControl XXFA_SN_CONTROL%ROWTYPE
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
		
	BEGIN
		insert_row(x_rowid 
			, p_XxfaSnControl.DATA_CONTROL_ID
			, p_XxfaSnControl.DATA_SOURCE_ID
			, p_XxfaSnControl.DATA_SOURCE_CODE
			, p_XxfaSnControl.DATA_FILE_NAME
			, x_errors, x_retcode);
	END insert_row;

   /********************************************************************************************
   Modulo : delete_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 15/Sep/2025
   Descripcion : Delete Row sobre la tabla xxfc.xxfa_sn_control
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Version Inicial
   ********************************************************************************************/
	/*--------------------------delete_row-------------------------*/
	PROCEDURE delete_row (p_DATA_CONTROL_ID IN NUMBER
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
		
	BEGIN
		x_errors := '';
		DELETE FROM XXFA_SN_CONTROL
		WHERE DATA_CONTROL_ID = p_DATA_CONTROL_ID;
		x_retcode := 0;
		--COMMIT;
	EXCEPTION
		WHEN OTHERS THEN
			x_errors := SQLERRM;
			x_retcode := 2;
	END delete_row;

   /********************************************************************************************
   Modulo : delete_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 15/Sep/2025
   Descripcion : Delete Row sobre la tabla xxfc.xxfa_sn_control
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Version Inicial
   ********************************************************************************************/
	/*--------------------------delete_row-------------------------*/
	PROCEDURE delete_row (p_XxfaSnControl XXFA_SN_CONTROL%ROWTYPE
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
		
	BEGIN
		delete_row(p_XxfaSnControl.DATA_CONTROL_ID
			, x_errors, x_retcode);
	END delete_row;


END XXFA_SN_CONTROL_PKG;
/
SHOW ERRORS;