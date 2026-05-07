SET DEFINE OFF;
PROMPT PACKAGE XXFA_SN_FE_DATA_DETAILS_PKG
CREATE OR REPLACE PACKAGE APPS.XXFA_SN_FE_DATA_DETAILS_PKG AS 

   /********************************************************************************************
   * Modulo : XXFA_SN_FE_DATA_DETAILS_PKG
   * Autor : Gilberto Hernandez (Hexaware) 
   * Version : 1.0
   * Fecha : 15/Sep/2025
   * Descripcion : Table Handler para la tabla xxfc.xxfa_sn_fe_data_details
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
   Descripcion : Lock Row sobre la tabla xxfc.xxfa_sn_fe_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Version Inicial
   ********************************************************************************************/
	/*--------------------------lock_row-------------------------*/
	PROCEDURE lock_row (p_rowid ROWID
			,p_FE_DATA_DETAIL_ID IN NUMBER
			, p_RCV_INVOICE_NUM IN VARCHAR2
			, p_RCV_PO_HEADER_ID IN NUMBER
			, p_POH_ORG_ID IN NUMBER
			, p_AP_ORG_COMPANY_RFC IN VARCHAR2
			, p_AP_ORG_COMPANY_NAME IN VARCHAR2
			, p_RCV_VENDOR_ID IN NUMBER
			, p_ASU_VENDOR_NUMBER IN VARCHAR2
			, p_ASU_VENDOR_NAME IN VARCHAR2
			, p_RSL_ITEM_ID IN NUMBER
			, p_MSI_ITEM_NUMBER IN VARCHAR2
			, p_RCV_SHIPMENT_HEADER_ID IN NUMBER
			, p_RSH_RECEIPT_NUM IN VARCHAR2
			, p_RCV_SHIPMENT_LINE_ID IN NUMBER
			, p_RSL_ITEM_DESCRIPTION IN VARCHAR2
			, p_RCV_QUANTITY IN NUMBER
			, p_RCV_TRANSACTION_ID IN NUMBER
			, p_RCV_PO_UNIT_PRICE IN NUMBER
			, p_RCV_CURRENCY_CODE IN VARCHAR2
			, p_RCV_CURRENCY_CONVERSION_RATE IN NUMBER
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : lock_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 15/Sep/2025
   Descripcion : Lock Row sobre la tabla xxfc.xxfa_sn_fe_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Version Inicial
   ********************************************************************************************/

	/*--------------------------lock_row-------------------------*/
	PROCEDURE lock_row (p_rowid ROWID
			, p_XxfaSnFeDataDetails XXFA_SN_FE_DATA_DETAILS%ROWTYPE
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);


   /********************************************************************************************
   Modulo : update_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 15/Sep/2025
   Descripcion : Update Row sobre la tabla xxfc.xxfa_sn_fe_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Version Inicial
   ********************************************************************************************/
	/*--------------------------update_row-------------------------*/
	PROCEDURE update_row (p_FE_DATA_DETAIL_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_RCV_INVOICE_NUM IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_RCV_PO_HEADER_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_POH_ORG_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_AP_ORG_COMPANY_RFC IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_AP_ORG_COMPANY_NAME IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_RCV_VENDOR_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_ASU_VENDOR_NUMBER IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_ASU_VENDOR_NAME IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_RSL_ITEM_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_MSI_ITEM_NUMBER IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_RCV_SHIPMENT_HEADER_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_RSH_RECEIPT_NUM IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_RCV_SHIPMENT_LINE_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_RSL_ITEM_DESCRIPTION IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_RCV_QUANTITY IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_RCV_TRANSACTION_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_RCV_PO_UNIT_PRICE IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_RCV_CURRENCY_CODE IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_RCV_CURRENCY_CONVERSION_RATE IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : update_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 15/Sep/2025
   Descripcion : Update Row sobre la tabla xxfc.xxfa_sn_fe_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Version Inicial
   ********************************************************************************************/
	/*--------------------------update_row-------------------------*/
	PROCEDURE update_row (p_XxfaSnFeDataDetails XXFA_SN_FE_DATA_DETAILS%ROWTYPE
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : insert_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 15/Sep/2025
   Descripcion : Insert Row sobre la tabla xxfc.xxfa_sn_fe_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Version Inicial
   ********************************************************************************************/
	/*--------------------------insert_row-------------------------*/
	PROCEDURE insert_row(x_rowid OUT ROWID
			, p_FE_DATA_DETAIL_ID IN NUMBER
			, p_RCV_INVOICE_NUM IN VARCHAR2
			, p_RCV_PO_HEADER_ID IN NUMBER
			, p_POH_ORG_ID IN NUMBER
			, p_AP_ORG_COMPANY_RFC IN VARCHAR2
			, p_AP_ORG_COMPANY_NAME IN VARCHAR2
			, p_RCV_VENDOR_ID IN NUMBER
			, p_ASU_VENDOR_NUMBER IN VARCHAR2
			, p_ASU_VENDOR_NAME IN VARCHAR2
			, p_RSL_ITEM_ID IN NUMBER
			, p_MSI_ITEM_NUMBER IN VARCHAR2
			, p_RCV_SHIPMENT_HEADER_ID IN NUMBER
			, p_RSH_RECEIPT_NUM IN VARCHAR2
			, p_RCV_SHIPMENT_LINE_ID IN NUMBER
			, p_RSL_ITEM_DESCRIPTION IN VARCHAR2
			, p_RCV_QUANTITY IN NUMBER
			, p_RCV_TRANSACTION_ID IN NUMBER
			, p_RCV_PO_UNIT_PRICE IN NUMBER
			, p_RCV_CURRENCY_CODE IN VARCHAR2
			, p_RCV_CURRENCY_CONVERSION_RATE IN NUMBER
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : insert_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 15/Sep/2025
   Descripcion : Insert Row sobre la tabla xxfc.xxfa_sn_fe_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Version Inicial
   ********************************************************************************************/
	/*--------------------------insert_row-------------------------*/
	PROCEDURE insert_row(x_rowid OUT ROWID
			, p_XxfaSnFeDataDetails XXFA_SN_FE_DATA_DETAILS%ROWTYPE
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : delete_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 15/Sep/2025
   Descripcion : Delete Row sobre la tabla xxfc.xxfa_sn_fe_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Version Inicial
   ********************************************************************************************/
	/*--------------------------delete_row-------------------------*/
	PROCEDURE delete_row (p_FE_DATA_DETAIL_ID IN NUMBER
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : delete_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 15/Sep/2025
   Descripcion : Delete Row sobre la tabla xxfc.xxfa_sn_fe_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Version Inicial
   ********************************************************************************************/
	/*--------------------------delete_row-------------------------*/
	PROCEDURE delete_row (p_XxfaSnFeDataDetails XXFA_SN_FE_DATA_DETAILS%ROWTYPE
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);
END XXFA_SN_FE_DATA_DETAILS_PKG;
/
SHOW ERRORS;