CREATE OR REPLACE PACKAGE BODY XXFA_SN_CONTROL_PKG AS 


	/*-----------------------------------------------------------------------------
	 *----------------STORED PROCEDURES FOR XxfaSnControl---------------
	 *-----------------------------------------------------------------------------*/


	/*--------------------------lock_row-------------------------*/
	PROCEDURE lock_row (p_rowid ROWID
			, p_DATA_CONTROL_ID IN NUMBER
			, p_DATA_SOURCE_ID IN VARCHAR2
			, p_DATA_SOURCE_CODE IN NUMBER
			, p_DATA_FILE_NAME IN NUMBER
			, p_LAST_UPDATE_LOGIN IN NUMBER
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
		
		CURSOR c IS SELECT 
			DATA_CONTROL_ID
			, DATA_SOURCE_ID
			, DATA_SOURCE_CODE
			, DATA_FILE_NAME
			, LAST_UPDATE_LOGIN
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
				AND ((recinfo.DATA_FILE_NAME = p_DATA_FILE_NAME) OR (recinfo.DATA_FILE_NAME IS NULL AND p_DATA_FILE_NAME IS NULL))
				AND ((recinfo.LAST_UPDATE_LOGIN = p_LAST_UPDATE_LOGIN) OR (recinfo.LAST_UPDATE_LOGIN IS NULL AND p_LAST_UPDATE_LOGIN IS NULL)))) THEN
			x_retcode := 2;
			x_errors := 'THE RECORD WITH ROWID = ' || p_rowid || ' IN TABLE XXFA_SN_CONTROL HAS CHANGED.';
		END IF;
		CLOSE c;
	EXCEPTION
		WHEN OTHERS THEN
			x_retcode := 2;
			x_errors := SQLERRM;
	END lock_row;


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
			, p_XxfaSnControl.LAST_UPDATE_LOGIN
			, x_errors, x_retcode);
	END lock_row;


	/*--------------------------update_row-------------------------*/
	PROCEDURE update_row (p_DATA_CONTROL_ID IN NUMBER DEFAULT FT_COMMON.G_MISS_NUMBER
			, p_DATA_SOURCE_ID IN VARCHAR2 DEFAULT FT_COMMON.G_MISS_VARCHAR2
			, p_DATA_SOURCE_CODE IN NUMBER DEFAULT FT_COMMON.G_MISS_NUMBER
			, p_DATA_FILE_NAME IN NUMBER DEFAULT FT_COMMON.G_MISS_NUMBER
			, p_LAST_UPDATE_LOGIN IN NUMBER DEFAULT FT_COMMON.G_MISS_NUMBER
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
		
	BEGIN
		x_errors := '';
		UPDATE XXFA_SN_CONTROL SET DATA_CONTROL_ID = DECODE(p_DATA_CONTROL_ID, FT_COMMON.G_MISS_NUMBER, DATA_CONTROL_ID, p_DATA_CONTROL_ID)
			, DATA_SOURCE_ID = DECODE(p_DATA_SOURCE_ID, FT_COMMON.G_MISS_VARCHAR2, DATA_SOURCE_ID, p_DATA_SOURCE_ID)
			, DATA_SOURCE_CODE = DECODE(p_DATA_SOURCE_CODE, FT_COMMON.G_MISS_NUMBER, DATA_SOURCE_CODE, p_DATA_SOURCE_CODE)
			, DATA_FILE_NAME = DECODE(p_DATA_FILE_NAME, FT_COMMON.G_MISS_NUMBER, DATA_FILE_NAME, p_DATA_FILE_NAME)
			, LAST_UPDATE_LOGIN = DECODE(p_LAST_UPDATE_LOGIN, FT_COMMON.G_MISS_NUMBER, LAST_UPDATE_LOGIN, p_LAST_UPDATE_LOGIN)
			, LAST_UPDATE_DATE = SYSDATE
			, LAST_UPDATED_BY = USER
		WHERE DATA_CONTROL_ID = p_DATA_CONTROL_ID;
		x_retcode := 0;
		COMMIT;
	EXCEPTION
		WHEN OTHERS THEN
			x_errors := SQLERRM;
			x_retcode := 2;
	END update_row;


	/*--------------------------update_row-------------------------*/
	PROCEDURE update_row (p_XxfaSnControl XXFA_SN_CONTROL%ROWTYPE
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
		
	BEGIN
		update_row(p_XxfaSnControl.DATA_CONTROL_ID
			, p_XxfaSnControl.DATA_SOURCE_ID
			, p_XxfaSnControl.DATA_SOURCE_CODE
			, p_XxfaSnControl.DATA_FILE_NAME
			, p_XxfaSnControl.LAST_UPDATE_LOGIN
			, x_errors, x_retcode);
	END update_row;


	/*--------------------------insert_row-------------------------*/
	PROCEDURE insert_row(x_rowid OUT ROWID
			, p_DATA_CONTROL_ID IN NUMBER
			, p_DATA_SOURCE_ID IN VARCHAR2
			, p_DATA_SOURCE_CODE IN NUMBER
			, p_DATA_FILE_NAME IN NUMBER
			, p_LAST_UPDATE_LOGIN IN NUMBER
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
			, p_LAST_UPDATE_LOGIN
			, SYSDATE
			, USER
			, SYSDATE
			, USER) RETURNING ROWID INTO x_rowid;
		x_retcode := 0;
		COMMIT;
	EXCEPTION
		WHEN OTHERS THEN
			x_errors := SQLERRM;
			x_retcode := 2;
	END insert_row;


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
			, p_XxfaSnControl.LAST_UPDATE_LOGIN
			, x_errors, x_retcode);
	END insert_row;


	/*--------------------------delete_row-------------------------*/
	PROCEDURE delete_row (p_DATA_CONTROL_ID IN NUMBER
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
		
	BEGIN
		x_errors := '';
		DELETE FROM XXFA_SN_CONTROL
		WHERE DATA_CONTROL_ID = p_DATA_CONTROL_ID;
		x_retcode := 0;
		COMMIT;
	EXCEPTION
		WHEN OTHERS THEN
			x_errors := SQLERRM;
			x_retcode := 2;
	END delete_row;


	/*--------------------------delete_row-------------------------*/
	PROCEDURE delete_row (p_XxfaSnControl XXFA_SN_CONTROL%ROWTYPE
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
		
	BEGIN
		delete_row(p_XxfaSnControl.DATA_CONTROL_ID
			, x_errors, x_retcode);
	END delete_row;


END XXFA_SN_CONTROL_PKG;
/
CREATE PUBLIC SYNONYM XXFA_SN_CONTROL_PKG FOR XXFA_SN_CONTROL_PKG;
/
