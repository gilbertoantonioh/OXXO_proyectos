SET DEFINE OFF;
PROMPT PACKAGE XXFA_SN_CONTROL_PKG
CREATE OR REPLACE PACKAGE APPS.XXFA_SN_CONTROL_PKG AS 

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
			,p_DATA_CONTROL_ID IN NUMBER
			, p_DATA_SOURCE_ID IN NUMBER
			, p_DATA_SOURCE_CODE IN VARCHAR2
			, p_DATA_FILE_NAME IN VARCHAR2
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

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
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);


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
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);


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
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

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
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

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
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

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
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);


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
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);
END XXFA_SN_CONTROL_PKG;
/
SHOW ERRORS;
