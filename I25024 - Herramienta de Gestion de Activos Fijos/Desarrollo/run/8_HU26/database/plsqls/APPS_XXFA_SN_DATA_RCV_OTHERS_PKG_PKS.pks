SET DEFINE OFF;
PROMPT PACKAGE XXFA_SN_DATA_RCV_OTHERS_PKG
CREATE OR REPLACE PACKAGE APPS.XXFA_SN_DATA_RCV_OTHERS_PKG 
AS 
   /********************************************************************************************
   * Modulo : XXFA_SN_DATA_RCV_OTHERS_PKG
   * Autor : Gilberto Hernandez (Hexaware) 
   * Version : 1.0
   * Fecha : 12/Feb/2026
   * Descripcion : Table Handler para la tabla xxfc.xxfa_sn_data_rcv_others
   *
   * Ejecutado Por :
   *
   * Ejecuciones :
   *
   * Modificado Por                 Fecha         Codigo          Descripcion
   * -------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Feb/2026   CHG0140503      Version Inicial
   ********************************************************************************************/


   /********************************************************************************************
   Modulo : lock_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 12/Feb/2026
   Descripcion : Lock Row sobre la tabla xxfc.xxfa_sn_data_rcv_others
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Feb/2026   CHG0140503      Version Inicial
   ********************************************************************************************/


	/*--------------------------lock_row-------------------------*/
	PROCEDURE lock_row (p_rowid ROWID
			,p_DATA_RCV_OTHER_ID IN NUMBER
			, p_RCV_TRANSACTION_ID IN NUMBER
			, p_SN_TRANSACTION_ID IN NUMBER
			, p_RCV_SOURCE_CODE IN VARCHAR2
			, p_RCV_DESTINATION_TYPE_CODE IN VARCHAR2
			, p_RCV_TRANSACTION_DATE IN DATE
			, p_RCV_PRIMARY_UNIT_OF_MEASURE IN VARCHAR2
			, p_RCV_SHIPMENT_HEADER_ID IN NUMBER
			, p_RSH_RECEIPT_NUM IN VARCHAR2
			, p_RCV_SHIPMENT_LINE_ID IN NUMBER
			, p_RSL_SHIPMENT_LINE_NUM IN NUMBER
			, p_RSL_ITEM_ID IN NUMBER
			, p_MSI_ITEM_NUMBER IN VARCHAR2
			, p_MSI_USE_TYPE IN VARCHAR2
			, p_MSI_FA_CODE IN VARCHAR2
			, p_RSL_ITEM_DESCRIPTION IN VARCHAR2
			, p_MSI_SAT_CODE IN VARCHAR2
			, p_MSI_ASSET_BADGEABLE_FLAG IN VARCHAR2
			, p_MSI_ASSET_SERIABLE_FLAG IN VARCHAR2
			, p_MSI_CFDI_USE IN VARCHAR2
			, p_MIC_ITEM_CATEGORY_ID IN NUMBER
			, p_MIC_ITEM_CATEG_SEG_CONCAT IN VARCHAR2
			, p_MIC_ITEM_CATEG_FAM IN VARCHAR2
			, p_MIC_ITEM_CATEG_SUBFAM IN VARCHAR2
			, p_FAA_ASSET_CATEGORY_ID IN NUMBER
			, p_FCB_ASSET_CATEG_DESCR IN VARCHAR2
			, p_FCB_ASSET_CATEG_SEG_CONCAT IN VARCHAR2
			, p_FCB_ASSET_CATEG IN VARCHAR2
			, p_FCB_ASSET_SUBCATEG IN VARCHAR2
			, p_FCB_ASSET_CATEG_FAM IN VARCHAR2
			, p_FCB_ASSET_CATEG_FAKEY IN VARCHAR2
			, p_RCV_QUANTITY IN NUMBER
			, p_RCV_PO_UNIT_PRICE IN NUMBER
			, p_RCV_CURRENCY_CODE IN VARCHAR2
			, p_RCV_CURRENCY_CONVERSION_RATE IN NUMBER
			, p_RCV_CURRENCY_CONVERSION_DATE IN DATE
			, p_AP_ORG_COMPANY_NAME IN VARCHAR2
			, p_AP_ORG_COMPANY_RFC IN VARCHAR2
			, p_POL_ORACLE_CIA IN VARCHAR2
			, p_POL_ORACLE_EF IN VARCHAR2
			, p_POL_ORACLE_CR_SUPERIOR IN VARCHAR2
			, p_POL_RETEK_DISTRITO IN NUMBER
			, p_POL_ORACLE_CR IN VARCHAR2
			, p_RCV_PO_HEADER_ID IN NUMBER
			, p_POH_PO_NUMBER IN VARCHAR2
			, p_POH_PO_DATE IN DATE
			, p_RCV_PO_RELEASE_ID IN NUMBER
			, p_PRA_RELEASE_NUM IN NUMBER
			, p_RCV_PO_LINE_ID IN NUMBER
			, p_POL_PO_LINE_NUM IN NUMBER
			, p_RCV_VENDOR_ID IN NUMBER
			, p_ASU_VENDOR_NUMBER IN VARCHAR2
			, p_ASU_VENDOR_NAME IN VARCHAR2
			, p_RCV_VENDOR_SITE_ID IN NUMBER
			, p_ASS_VENDOR_SITE_CODE IN VARCHAR2
			, p_RCV_INV_ORGANIZATION_ID IN NUMBER
			, p_MTL_INV_ORGANIZATION_CODE IN VARCHAR2
			, p_POH_ORG_ID IN NUMBER
			, p_HOU_ORG_CODE IN VARCHAR2
			, p_RCV_INVOICE_NUM IN VARCHAR2
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : lock_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 12/Feb/2026
   Descripcion : Lock Row sobre la tabla xxfc.xxfa_sn_data_rcv_others
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Feb/2026   CHG0140503      Version Inicial
   ********************************************************************************************/
	/*--------------------------lock_row-------------------------*/
	PROCEDURE lock_row (p_rowid ROWID
			, p_XxfaSnDataRcvOthers XXFA_SN_DATA_RCV_OTHERS%ROWTYPE
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : update_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 12/Feb/2026
   Descripcion : Update Row sobre la tabla xxfc.xxfa_sn_data_rcv_others
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Feb/2026   CHG0140503      Version Inicial
   ********************************************************************************************/
	/*--------------------------update_row-------------------------*/
	PROCEDURE update_row (p_DATA_RCV_OTHER_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_RCV_TRANSACTION_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_SN_TRANSACTION_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_RCV_SOURCE_CODE IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_RCV_DESTINATION_TYPE_CODE IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_RCV_TRANSACTION_DATE IN DATE DEFAULT FND_API.G_MISS_DATE
			, p_RCV_PRIMARY_UNIT_OF_MEASURE IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_RCV_SHIPMENT_HEADER_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_RSH_RECEIPT_NUM IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_RCV_SHIPMENT_LINE_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_RSL_SHIPMENT_LINE_NUM IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_RSL_ITEM_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_MSI_ITEM_NUMBER IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_MSI_USE_TYPE IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_MSI_FA_CODE IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_RSL_ITEM_DESCRIPTION IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_MSI_SAT_CODE IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_MSI_ASSET_BADGEABLE_FLAG IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_MSI_ASSET_SERIABLE_FLAG IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_MSI_CFDI_USE IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_MIC_ITEM_CATEGORY_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_MIC_ITEM_CATEG_SEG_CONCAT IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_MIC_ITEM_CATEG_FAM IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_MIC_ITEM_CATEG_SUBFAM IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_FAA_ASSET_CATEGORY_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_FCB_ASSET_CATEG_DESCR IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_FCB_ASSET_CATEG_SEG_CONCAT IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_FCB_ASSET_CATEG IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_FCB_ASSET_SUBCATEG IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_FCB_ASSET_CATEG_FAM IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_FCB_ASSET_CATEG_FAKEY IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_RCV_QUANTITY IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_RCV_PO_UNIT_PRICE IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_RCV_CURRENCY_CODE IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_RCV_CURRENCY_CONVERSION_RATE IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_RCV_CURRENCY_CONVERSION_DATE IN DATE DEFAULT FND_API.G_MISS_DATE
			, p_AP_ORG_COMPANY_NAME IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_AP_ORG_COMPANY_RFC IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_POL_ORACLE_CIA IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_POL_ORACLE_EF IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_POL_ORACLE_CR_SUPERIOR IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_POL_RETEK_DISTRITO IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_POL_ORACLE_CR IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_RCV_PO_HEADER_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_POH_PO_NUMBER IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_POH_PO_DATE IN DATE DEFAULT FND_API.G_MISS_DATE
			, p_RCV_PO_RELEASE_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_PRA_RELEASE_NUM IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_RCV_PO_LINE_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_POL_PO_LINE_NUM IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_RCV_VENDOR_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_ASU_VENDOR_NUMBER IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_ASU_VENDOR_NAME IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_RCV_VENDOR_SITE_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_ASS_VENDOR_SITE_CODE IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_RCV_INV_ORGANIZATION_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_MTL_INV_ORGANIZATION_CODE IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_POH_ORG_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_HOU_ORG_CODE IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_RCV_INVOICE_NUM IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : update_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 12/Feb/2026
   Descripcion : Update Row sobre la tabla xxfc.xxfa_sn_data_rcv_others
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Feb/2026   CHG0140503      Version Inicial
   ********************************************************************************************/
	/*--------------------------update_row-------------------------*/
	PROCEDURE update_row ( p_XxfaSnDataRcvOthers XXFA_SN_DATA_RCV_OTHERS%ROWTYPE
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : insert_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 12/Feb/2026
   Descripcion : Insert Row sobre la tabla xxfc.xxfa_sn_data_rcv_others
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Feb/2026   CHG0140503      Version Inicial
   ********************************************************************************************/
	/*--------------------------insert_row-------------------------*/
	PROCEDURE insert_row(x_rowid OUT ROWID
			, p_DATA_RCV_OTHER_ID IN NUMBER
			, p_RCV_TRANSACTION_ID IN NUMBER
			, p_SN_TRANSACTION_ID IN NUMBER
			, p_RCV_SOURCE_CODE IN VARCHAR2
			, p_RCV_DESTINATION_TYPE_CODE IN VARCHAR2
			, p_RCV_TRANSACTION_DATE IN DATE
			, p_RCV_PRIMARY_UNIT_OF_MEASURE IN VARCHAR2
			, p_RCV_SHIPMENT_HEADER_ID IN NUMBER
			, p_RSH_RECEIPT_NUM IN VARCHAR2
			, p_RCV_SHIPMENT_LINE_ID IN NUMBER
			, p_RSL_SHIPMENT_LINE_NUM IN NUMBER
			, p_RSL_ITEM_ID IN NUMBER
			, p_MSI_ITEM_NUMBER IN VARCHAR2
			, p_MSI_USE_TYPE IN VARCHAR2
			, p_MSI_FA_CODE IN VARCHAR2
			, p_RSL_ITEM_DESCRIPTION IN VARCHAR2
			, p_MSI_SAT_CODE IN VARCHAR2
			, p_MSI_ASSET_BADGEABLE_FLAG IN VARCHAR2
			, p_MSI_ASSET_SERIABLE_FLAG IN VARCHAR2
			, p_MSI_CFDI_USE IN VARCHAR2
			, p_MIC_ITEM_CATEGORY_ID IN NUMBER
			, p_MIC_ITEM_CATEG_SEG_CONCAT IN VARCHAR2
			, p_MIC_ITEM_CATEG_FAM IN VARCHAR2
			, p_MIC_ITEM_CATEG_SUBFAM IN VARCHAR2
			, p_FAA_ASSET_CATEGORY_ID IN NUMBER
			, p_FCB_ASSET_CATEG_DESCR IN VARCHAR2
			, p_FCB_ASSET_CATEG_SEG_CONCAT IN VARCHAR2
			, p_FCB_ASSET_CATEG IN VARCHAR2
			, p_FCB_ASSET_SUBCATEG IN VARCHAR2
			, p_FCB_ASSET_CATEG_FAM IN VARCHAR2
			, p_FCB_ASSET_CATEG_FAKEY IN VARCHAR2
			, p_RCV_QUANTITY IN NUMBER
			, p_RCV_PO_UNIT_PRICE IN NUMBER
			, p_RCV_CURRENCY_CODE IN VARCHAR2
			, p_RCV_CURRENCY_CONVERSION_RATE IN NUMBER
			, p_RCV_CURRENCY_CONVERSION_DATE IN DATE
			, p_AP_ORG_COMPANY_NAME IN VARCHAR2
			, p_AP_ORG_COMPANY_RFC IN VARCHAR2
			, p_POL_ORACLE_CIA IN VARCHAR2
			, p_POL_ORACLE_EF IN VARCHAR2
			, p_POL_ORACLE_CR_SUPERIOR IN VARCHAR2
			, p_POL_RETEK_DISTRITO IN NUMBER
			, p_POL_ORACLE_CR IN VARCHAR2
			, p_RCV_PO_HEADER_ID IN NUMBER
			, p_POH_PO_NUMBER IN VARCHAR2
			, p_POH_PO_DATE IN DATE
			, p_RCV_PO_RELEASE_ID IN NUMBER
			, p_PRA_RELEASE_NUM IN NUMBER
			, p_RCV_PO_LINE_ID IN NUMBER
			, p_POL_PO_LINE_NUM IN NUMBER
			, p_RCV_VENDOR_ID IN NUMBER
			, p_ASU_VENDOR_NUMBER IN VARCHAR2
			, p_ASU_VENDOR_NAME IN VARCHAR2
			, p_RCV_VENDOR_SITE_ID IN NUMBER
			, p_ASS_VENDOR_SITE_CODE IN VARCHAR2
			, p_RCV_INV_ORGANIZATION_ID IN NUMBER
			, p_MTL_INV_ORGANIZATION_CODE IN VARCHAR2
			, p_POH_ORG_ID IN NUMBER
			, p_HOU_ORG_CODE IN VARCHAR2
			, p_RCV_INVOICE_NUM IN VARCHAR2
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : insert_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 12/Feb/2026
   Descripcion : Insert Row sobre la tabla xxfc.xxfa_sn_data_rcv_others
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Feb/2026   CHG0140503      Version Inicial
   ********************************************************************************************/
	/*--------------------------insert_row-------------------------*/
	PROCEDURE insert_row(x_rowid OUT ROWID
			, p_XxfaSnDataRcvOthers XXFA_SN_DATA_RCV_OTHERS%ROWTYPE
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : delete_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 12/Feb/2026
   Descripcion : Delete Row sobre la tabla xxfc.xxfa_sn_data_rcv_others
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Feb/2026   CHG0140503      Version Inicial
   ********************************************************************************************/
	/*--------------------------delete_row-------------------------*/
	PROCEDURE delete_row ( p_DATA_RCV_OTHER_ID IN NUMBER
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);
			
   /********************************************************************************************
   Modulo : delete_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 12/Feb/2026
   Descripcion : Delete Row sobre la tabla xxfc.xxfa_sn_data_rcv_others
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Feb/2026   CHG0140503      Version Inicial
   ********************************************************************************************/
	/*--------------------------delete_row-------------------------*/
	PROCEDURE delete_row (p_XxfaSnDataRcvOthers XXFA_SN_DATA_RCV_OTHERS%ROWTYPE
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);			
END XXFA_SN_DATA_RCV_OTHERS_PKG;
/
SHOW ERRORS;