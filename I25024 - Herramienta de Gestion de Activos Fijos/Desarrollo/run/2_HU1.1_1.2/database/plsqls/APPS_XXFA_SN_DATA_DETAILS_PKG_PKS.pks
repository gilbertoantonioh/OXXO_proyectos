SET DEFINE OFF;
PROMPT PACKAGE XXFA_SN_DATA_DETAILS_PKG
CREATE OR REPLACE PACKAGE XXFA_SN_DATA_DETAILS_PKG AS 


   /********************************************************************************************
   * Modulo : XXFA_SN_DATA_DETAILS_PKG
   * Autor : Gilberto Hernandez (Hexaware) 
   * Version : 1.0
   * Fecha : 15/Sep/2025
   * Descripcion : Table Handler para la tabla xxfc.xxfa_sn_data_details
   *
   * Ejecutado Por :
   *
   * Ejecuciones :
   *
   * Modificado Por                 Fecha         Codigo          Descripcion
   * -------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Ago/2025   CHG0101033      Version Inicial
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Se complementan la tabla intermedia con nuevos atributos. 
   ********************************************************************************************/


   /********************************************************************************************
   Modulo : lock_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 15/Ago/2025
   Descripcion : Lock Row sobre la tabla xxfc.xxfa_sn_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Ago/2025   CHG0101033      Version Inicial
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Se complementan la tabla intermedia con nuevos atributos. 
   ********************************************************************************************/
	/*--------------------------lock_row-------------------------*/
	PROCEDURE lock_row (p_rowid ROWID
			,p_DATA_DETAIL_ID IN NUMBER
			, p_RCV_TRANSACTION_ID IN NUMBER
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
			, p_RSL_ITEM_DESCRIPTION IN VARCHAR2
			, p_MIC_ITEM_CATEGORY_ID IN NUMBER
			, p_MIC_ITEM_CATEG_FAM IN VARCHAR2
			, p_MIC_ITEM_CATEG_SUBFAM IN VARCHAR2
			, p_MSI_KIT_TYPE IN VARCHAR2
			, p_MSI_KIT_PRINCIPAL_FLAG IN VARCHAR2
			, p_MSI_KIT_PARENT IN VARCHAR2
			, p_MSI_ASSET_BADGEABLE_FLAG IN VARCHAR2
			, p_MSI_ASSET_SERIABLE_FLAG IN VARCHAR2
			, p_FA_ITEM_SEQUENCE IN NUMBER
			, p_RCV_INVOICE_NUM IN VARCHAR2
			, p_AP_INVOICE_UUID IN VARCHAR2
			, p_AP_ORG_COMPANY_NAME IN VARCHAR2
			, p_AP_ORG_COMPANY_RFC IN VARCHAR2
			, p_RCV_PO_HEADER_ID IN NUMBER
			, p_POH_PO_NUMBER IN VARCHAR2
			, p_POH_PO_DATE IN DATE
			, p_PRA_RELEASE_NUM IN NUMBER
			, p_RCV_PO_RELEASE_ID IN NUMBER
			, p_RCV_PO_LINE_ID IN NUMBER
			, p_POL_PO_LINE_NUM IN NUMBER
			, p_RCV_PO_LINE_LOCATION_ID IN NUMBER
			, p_RCV_QUANTITY IN NUMBER
			, p_RCV_PO_UNIT_PRICE IN NUMBER
			, p_RCV_CURRENCY_CODE IN VARCHAR2
			, p_RCV_CURRENCY_CONVERSION_RATE IN NUMBER
			, p_RCV_CURRENCY_CONVERSION_DATE IN DATE
			, p_RCV_VENDOR_ID IN NUMBER
			, p_ASU_VENDOR_NUMBER IN VARCHAR2
			, p_ASU_VENDOR_NAME IN VARCHAR2
			, p_RCV_VENDOR_SITE_ID IN NUMBER
			, p_ASS_VENDOR_SITE_CODE IN VARCHAR2
			, p_RCV_INV_ORGANIZATION_ID IN NUMBER
			, p_MTL_INV_ORGANIZATION_CODE IN VARCHAR2
			, p_POH_ORG_ID IN NUMBER
			, p_HOU_ORG_CODE IN VARCHAR2
			, p_FAA_ASSET_ID IN NUMBER
			, p_FAA_ASSET_NUMBER IN VARCHAR2
			, p_FAA_TAG_NUMBER IN VARCHAR2
			, p_FAA_ASSET_CATEGORY_ID IN NUMBER
			, p_FCB_ASSET_CATEG_SEG_CONCAT IN VARCHAR2
			, p_FCB_ASSET_CATEG_ACCT IN VARCHAR2
			, p_FCB_ASSET_CATEG_SUBACCT IN VARCHAR2
			, p_FCB_ASSET_CATEG_FAM IN VARCHAR2
			, p_FCB_ASSET_CATEG_FAKEY IN VARCHAR2
			, p_FAA_MANUFACTURER_NAME IN VARCHAR2
			, p_FAA_MODEL_NUMBER IN VARCHAR2
			, p_FAA_SERIAL_NUMBER IN VARCHAR2
			, p_FAA_DESCRIPTION IN VARCHAR2
			, p_FBK_DATE_PLACED_MM IN VARCHAR2
			, p_FBK_DATE_PLACED_YYYY IN VARCHAR2
			, p_FAA_PROPERTY_TYPE_CODE IN VARCHAR2
			, p_PRL_REQUISITION_LINE_ID IN NUMBER
			, p_PRL_ORACLE_CIA IN VARCHAR2
			, p_PRL_ORACLE_EF IN VARCHAR2
			, p_PRL_RETEK_DISTRITO IN NUMBER
			, p_PRL_ORACLE_CR IN VARCHAR2
			, p_PRL_ORACLE_CR_DESCR IN VARCHAR2
			, p_PRL_ORACLE_CR_SUPERIOR IN VARCHAR2
			, p_PRL_ORACLE_CR_SUP_DESCR IN VARCHAR2
			, p_OOH_HEADER_ID IN NUMBER
			, p_OOH_ORDER_NUMBER IN NUMBER
			, p_OOL_LINE_ID IN NUMBER
			, p_WST_TRIP_ID IN NUMBER
			, p_WST_TRIP_NAME IN VARCHAR2
			, p_MMT_TRANSACTION_ID IN NUMBER
			, p_MMT_CREATION_DATE IN DATE
			, p_SN_U_ESTATUS_ASSETS IN VARCHAR2
			, p_SN_U_ESTATUS_CONTABLE IN VARCHAR2
			, p_SN_U_ESTATUS_FACTURA IN VARCHAR2
			, p_SN_U_FOLIO_VALIDACION_FACT IN VARCHAR2
			, p_SN_U_TIPO_ERROR_FACTURA IN VARCHAR2
			, p_SN_U_FOLIO_SALIDA IN VARCHAR2
			, p_SN_U_SUBTOTAL IN NUMBER
			, p_SN_U_DESCUENTO IN NUMBER
			, p_SN_U_IMPUESTO IN VARCHAR2
			, p_SN_U_RETENCIONES IN NUMBER
			, p_SN_U_TOTAL IN NUMBER
			, p_SN_U_CLAVE_PRODUCTO_SAT IN VARCHAR2
			, p_SN_UUID_FOLIO_STAT IN VARCHAR2
			, p_SN_USO_CFDI IN VARCHAR2
			, p_SN_U_MONEDA IN VARCHAR2
			, p_SN_U_TIPO_CAMBIO IN NUMBER
			, p_SN_U_METODO_PAGO IN VARCHAR2
			, p_SN_U_FORMA_PAGO IN VARCHAR2
			, p_SN_U_REGIMENT_FISCAL IN VARCHAR2
			, p_SN_U_TIPO_COMPROBANTE IN VARCHAR2
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : lock_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 15/Ago/2025
   Descripcion : Lock Row sobre la tabla xxfc.xxfa_sn_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Ago/2025   CHG0101033      Version Inicial
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Se complementan la tabla intermedia con nuevos atributos. 
   ********************************************************************************************/
	/*--------------------------lock_row-------------------------*/
	PROCEDURE lock_row (p_rowid ROWID
			, p_XxfaSnDataDetails XXFA_SN_DATA_DETAILS%ROWTYPE
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : update_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 15/Ago/2025
   Descripcion : Update Row sobre la tabla xxfc.xxfa_sn_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Ago/2025   CHG0101033      Version Inicial
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Se complementan la tabla intermedia con nuevos atributos. 
   ********************************************************************************************/
	/*--------------------------update_row-------------------------*/
	PROCEDURE update_row (p_DATA_DETAIL_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_RCV_TRANSACTION_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
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
			, p_RSL_ITEM_DESCRIPTION IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_MIC_ITEM_CATEGORY_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_MIC_ITEM_CATEG_FAM IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_MIC_ITEM_CATEG_SUBFAM IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_MSI_KIT_TYPE IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_MSI_KIT_PRINCIPAL_FLAG IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_MSI_KIT_PARENT IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_MSI_ASSET_BADGEABLE_FLAG IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_MSI_ASSET_SERIABLE_FLAG IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_FA_ITEM_SEQUENCE IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_RCV_INVOICE_NUM IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_AP_INVOICE_UUID IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_AP_ORG_COMPANY_NAME IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_AP_ORG_COMPANY_RFC IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_RCV_PO_HEADER_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_POH_PO_NUMBER IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_POH_PO_DATE IN DATE DEFAULT FND_API.G_MISS_DATE
			, p_PRA_RELEASE_NUM IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_RCV_PO_RELEASE_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_RCV_PO_LINE_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_POL_PO_LINE_NUM IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_RCV_PO_LINE_LOCATION_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_RCV_QUANTITY IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_RCV_PO_UNIT_PRICE IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_RCV_CURRENCY_CODE IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_RCV_CURRENCY_CONVERSION_RATE IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_RCV_CURRENCY_CONVERSION_DATE IN DATE DEFAULT FND_API.G_MISS_DATE
			, p_RCV_VENDOR_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_ASU_VENDOR_NUMBER IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_ASU_VENDOR_NAME IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_RCV_VENDOR_SITE_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_ASS_VENDOR_SITE_CODE IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_RCV_INV_ORGANIZATION_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_MTL_INV_ORGANIZATION_CODE IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_POH_ORG_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_HOU_ORG_CODE IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_FAA_ASSET_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_FAA_ASSET_NUMBER IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_FAA_TAG_NUMBER IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_FAA_ASSET_CATEGORY_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_FCB_ASSET_CATEG_SEG_CONCAT IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_FCB_ASSET_CATEG_ACCT IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_FCB_ASSET_CATEG_SUBACCT IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_FCB_ASSET_CATEG_FAM IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_FCB_ASSET_CATEG_FAKEY IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_FAA_MANUFACTURER_NAME IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_FAA_MODEL_NUMBER IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_FAA_SERIAL_NUMBER IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_FAA_DESCRIPTION IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_FBK_DATE_PLACED_MM IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_FBK_DATE_PLACED_YYYY IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_FAA_PROPERTY_TYPE_CODE IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_PRL_REQUISITION_LINE_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_PRL_ORACLE_CIA IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_PRL_ORACLE_EF IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_PRL_RETEK_DISTRITO IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_PRL_ORACLE_CR IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_PRL_ORACLE_CR_DESCR IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_PRL_ORACLE_CR_SUPERIOR IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_PRL_ORACLE_CR_SUP_DESCR IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_OOH_HEADER_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_OOH_ORDER_NUMBER IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_OOL_LINE_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_WST_TRIP_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_WST_TRIP_NAME IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_MMT_TRANSACTION_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_MMT_CREATION_DATE IN DATE DEFAULT FND_API.G_MISS_DATE
			, p_SN_U_ESTATUS_ASSETS IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_SN_U_ESTATUS_CONTABLE IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_SN_U_ESTATUS_FACTURA IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_SN_U_FOLIO_VALIDACION_FACT IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_SN_U_TIPO_ERROR_FACTURA IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_SN_U_FOLIO_SALIDA IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_SN_U_SUBTOTAL IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_SN_U_DESCUENTO IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_SN_U_IMPUESTO IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_SN_U_RETENCIONES IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_SN_U_TOTAL IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_SN_U_CLAVE_PRODUCTO_SAT IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_SN_UUID_FOLIO_STAT IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_SN_USO_CFDI IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_SN_U_MONEDA IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_SN_U_TIPO_CAMBIO IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_SN_U_METODO_PAGO IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_SN_U_FORMA_PAGO IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_SN_U_REGIMENT_FISCAL IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, p_SN_U_TIPO_COMPROBANTE IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : update_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 15/Ago/2025
   Descripcion : Update Row sobre la tabla xxfc.xxfa_sn_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Ago/2025   CHG0101033      Version Inicial
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Se complementan la tabla intermedia con nuevos atributos. 
   ********************************************************************************************/
	/*--------------------------update_row-------------------------*/
	PROCEDURE update_row (p_XxfaSnDataDetails XXFA_SN_DATA_DETAILS%ROWTYPE
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : insert_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 15/Ago/2025
   Descripcion : Insert Row sobre la tabla xxfc.xxfa_sn_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Ago/2025   CHG0101033      Version Inicial
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Se complementan la tabla intermedia con nuevos atributos. 
   ********************************************************************************************/
	/*--------------------------insert_row-------------------------*/
	PROCEDURE insert_row(x_rowid OUT ROWID
			, p_DATA_DETAIL_ID IN NUMBER
			, p_RCV_TRANSACTION_ID IN NUMBER
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
			, p_RSL_ITEM_DESCRIPTION IN VARCHAR2
			, p_MIC_ITEM_CATEGORY_ID IN NUMBER
			, p_MIC_ITEM_CATEG_FAM IN VARCHAR2
			, p_MIC_ITEM_CATEG_SUBFAM IN VARCHAR2
			, p_MSI_KIT_TYPE IN VARCHAR2
			, p_MSI_KIT_PRINCIPAL_FLAG IN VARCHAR2
			, p_MSI_KIT_PARENT IN VARCHAR2
			, p_MSI_ASSET_BADGEABLE_FLAG IN VARCHAR2
			, p_MSI_ASSET_SERIABLE_FLAG IN VARCHAR2
			, p_FA_ITEM_SEQUENCE IN NUMBER
			, p_RCV_INVOICE_NUM IN VARCHAR2
			, p_AP_INVOICE_UUID IN VARCHAR2
			, p_AP_ORG_COMPANY_NAME IN VARCHAR2
			, p_AP_ORG_COMPANY_RFC IN VARCHAR2
			, p_RCV_PO_HEADER_ID IN NUMBER
			, p_POH_PO_NUMBER IN VARCHAR2
			, p_POH_PO_DATE IN DATE
			, p_PRA_RELEASE_NUM IN NUMBER
			, p_RCV_PO_RELEASE_ID IN NUMBER
			, p_RCV_PO_LINE_ID IN NUMBER
			, p_POL_PO_LINE_NUM IN NUMBER
			, p_RCV_PO_LINE_LOCATION_ID IN NUMBER
			, p_RCV_QUANTITY IN NUMBER
			, p_RCV_PO_UNIT_PRICE IN NUMBER
			, p_RCV_CURRENCY_CODE IN VARCHAR2
			, p_RCV_CURRENCY_CONVERSION_RATE IN NUMBER
			, p_RCV_CURRENCY_CONVERSION_DATE IN DATE
			, p_RCV_VENDOR_ID IN NUMBER
			, p_ASU_VENDOR_NUMBER IN VARCHAR2
			, p_ASU_VENDOR_NAME IN VARCHAR2
			, p_RCV_VENDOR_SITE_ID IN NUMBER
			, p_ASS_VENDOR_SITE_CODE IN VARCHAR2
			, p_RCV_INV_ORGANIZATION_ID IN NUMBER
			, p_MTL_INV_ORGANIZATION_CODE IN VARCHAR2
			, p_POH_ORG_ID IN NUMBER
			, p_HOU_ORG_CODE IN VARCHAR2
			, p_FAA_ASSET_ID IN NUMBER
			, p_FAA_ASSET_NUMBER IN VARCHAR2
			, p_FAA_TAG_NUMBER IN VARCHAR2
			, p_FAA_ASSET_CATEGORY_ID IN NUMBER
			, p_FCB_ASSET_CATEG_SEG_CONCAT IN VARCHAR2
			, p_FCB_ASSET_CATEG_ACCT IN VARCHAR2
			, p_FCB_ASSET_CATEG_SUBACCT IN VARCHAR2
			, p_FCB_ASSET_CATEG_FAM IN VARCHAR2
			, p_FCB_ASSET_CATEG_FAKEY IN VARCHAR2
			, p_FAA_MANUFACTURER_NAME IN VARCHAR2
			, p_FAA_MODEL_NUMBER IN VARCHAR2
			, p_FAA_SERIAL_NUMBER IN VARCHAR2
			, p_FAA_DESCRIPTION IN VARCHAR2
			, p_FBK_DATE_PLACED_MM IN VARCHAR2
			, p_FBK_DATE_PLACED_YYYY IN VARCHAR2
			, p_FAA_PROPERTY_TYPE_CODE IN VARCHAR2
			, p_PRL_REQUISITION_LINE_ID IN NUMBER
			, p_PRL_ORACLE_CIA IN VARCHAR2
			, p_PRL_ORACLE_EF IN VARCHAR2
			, p_PRL_RETEK_DISTRITO IN NUMBER
			, p_PRL_ORACLE_CR IN VARCHAR2
			, p_PRL_ORACLE_CR_DESCR IN VARCHAR2
			, p_PRL_ORACLE_CR_SUPERIOR IN VARCHAR2
			, p_PRL_ORACLE_CR_SUP_DESCR IN VARCHAR2
			, p_OOH_HEADER_ID IN NUMBER
			, p_OOH_ORDER_NUMBER IN NUMBER
			, p_OOL_LINE_ID IN NUMBER
			, p_WST_TRIP_ID IN NUMBER
			, p_WST_TRIP_NAME IN VARCHAR2
			, p_MMT_TRANSACTION_ID IN NUMBER
			, p_MMT_CREATION_DATE IN DATE
			, p_SN_U_ESTATUS_ASSETS IN VARCHAR2
			, p_SN_U_ESTATUS_CONTABLE IN VARCHAR2
			, p_SN_U_ESTATUS_FACTURA IN VARCHAR2
			, p_SN_U_FOLIO_VALIDACION_FACT IN VARCHAR2
			, p_SN_U_TIPO_ERROR_FACTURA IN VARCHAR2
			, p_SN_U_FOLIO_SALIDA IN VARCHAR2
			, p_SN_U_SUBTOTAL IN NUMBER
			, p_SN_U_DESCUENTO IN NUMBER
			, p_SN_U_IMPUESTO IN VARCHAR2
			, p_SN_U_RETENCIONES IN NUMBER
			, p_SN_U_TOTAL IN NUMBER
			, p_SN_U_CLAVE_PRODUCTO_SAT IN VARCHAR2
			, p_SN_UUID_FOLIO_STAT IN VARCHAR2
			, p_SN_USO_CFDI IN VARCHAR2
			, p_SN_U_MONEDA IN VARCHAR2
			, p_SN_U_TIPO_CAMBIO IN NUMBER
			, p_SN_U_METODO_PAGO IN VARCHAR2
			, p_SN_U_FORMA_PAGO IN VARCHAR2
			, p_SN_U_REGIMENT_FISCAL IN VARCHAR2
			, p_SN_U_TIPO_COMPROBANTE IN VARCHAR2
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : insert_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 15/Ago/2025
   Descripcion : Insert Row sobre la tabla xxfc.xxfa_sn_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Ago/2025   CHG0101033      Version Inicial
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Se complementan la tabla intermedia con nuevos atributos. 
   ********************************************************************************************/
	/*--------------------------insert_row-------------------------*/
	/*--------------------------insert_row-------------------------*/
	PROCEDURE insert_row(x_rowid OUT ROWID
			, p_XxfaSnDataDetails XXFA_SN_DATA_DETAILS%ROWTYPE
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : delete_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 15/Ago/2025
   Descripcion : Delete Row sobre la tabla xxfc.xxfa_sn_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Ago/2025   CHG0101033      Version Inicial 
   ********************************************************************************************/
	/*--------------------------delete_row-------------------------*/
	PROCEDURE delete_row (p_DATA_DETAIL_ID IN NUMBER
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : delete_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 15/Ago/2025
   Descripcion : Delete Row sobre la tabla xxfc.xxfa_sn_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Ago/2025   CHG0101033      Version Inicial
   ********************************************************************************************/
	/*--------------------------delete_row-------------------------*/
	PROCEDURE delete_row (p_XxfaSnDataDetails XXFA_SN_DATA_DETAILS%ROWTYPE
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);
END XXFA_SN_DATA_DETAILS_PKG;
/
SHOW ERRORS;