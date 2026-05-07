CREATE OR REPLACE PACKAGE XXFA_SN_CONTROL_PKG AS 


	/*-----------------------------------------------------------------------------
	 *----------------STORED PROCEDURES FOR XxfaSnControl---------------
	 *-----------------------------------------------------------------------------*/


	/*--------------------------lock_row-------------------------*/
	PROCEDURE lock_row (p_rowid ROWID
			,p_DATA_CONTROL_ID IN NUMBER
			, p_DATA_SOURCE_ID IN VARCHAR2
			, p_DATA_SOURCE_CODE IN NUMBER
			, p_DATA_FILE_NAME IN NUMBER
			, p_LAST_UPDATE_LOGIN IN NUMBER
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);


	/*--------------------------lock_row-------------------------*/
	PROCEDURE lock_row (p_rowid ROWID
			, p_XxfaSnControl XXFA_SN_CONTROL%ROWTYPE
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);


	/*--------------------------update_row-------------------------*/
	PROCEDURE update_row (p_DATA_CONTROL_ID IN NUMBER DEFAULT FT_COMMON.G_MISS_NUMBER
			, p_DATA_SOURCE_ID IN VARCHAR2 DEFAULT FT_COMMON.G_MISS_VARCHAR2
			, p_DATA_SOURCE_CODE IN NUMBER DEFAULT FT_COMMON.G_MISS_NUMBER
			, p_DATA_FILE_NAME IN NUMBER DEFAULT FT_COMMON.G_MISS_NUMBER
			, p_LAST_UPDATE_LOGIN IN NUMBER DEFAULT FT_COMMON.G_MISS_NUMBER
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);


	/*--------------------------update_row-------------------------*/
	PROCEDURE update_row (p_XxfaSnControl XXFA_SN_CONTROL%ROWTYPE
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);


	/*--------------------------insert_row-------------------------*/
	PROCEDURE insert_row(x_rowid OUT ROWID
			, p_DATA_CONTROL_ID IN NUMBER
			, p_DATA_SOURCE_ID IN VARCHAR2
			, p_DATA_SOURCE_CODE IN NUMBER
			, p_DATA_FILE_NAME IN NUMBER
			, p_LAST_UPDATE_LOGIN IN NUMBER
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);


	/*--------------------------insert_row-------------------------*/
	PROCEDURE insert_row(x_rowid OUT ROWID
			, p_XxfaSnControl XXFA_SN_CONTROL%ROWTYPE
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);


	/*--------------------------delete_row-------------------------*/
	PROCEDURE delete_row (p_DATA_CONTROL_ID IN NUMBER
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);


	/*--------------------------delete_row-------------------------*/
	PROCEDURE delete_row (p_XxfaSnControl XXFA_SN_CONTROL%ROWTYPE
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);
END XXFA_SN_CONTROL_PKG;
/
