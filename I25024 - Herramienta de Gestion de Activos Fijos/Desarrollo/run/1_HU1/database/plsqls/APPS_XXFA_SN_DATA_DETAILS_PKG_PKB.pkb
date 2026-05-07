SET DEFINE OFF;
PROMPT PACKAGE BODY XXFA_SN_DATA_DETAILS_PKG
CREATE OR REPLACE PACKAGE BODY APPS.xxfa_sn_data_details_pkg AS 
   /********************************************************************************************
   * Modulo : XXFA_SN_DATA_DETAILS_PKG
   * Autor : Gilberto Hernandez (Hexaware) 
   * Version : 1.0
   * Fecha : 12/Ago/2025
   * Descripcion : Table Handler para la tabla xxfc.xxfa_sn_data_details
   *
   * Ejecutado Por :
   *
   * Ejecuciones :
   *
   * Modificado Por                 Fecha         Codigo          Descripcion
   * -------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Ago/2025   CHG0101033      Version Inicial
   ********************************************************************************************/

    /*-----------------------------------------------------------------------------
     *----------------STORED PROCEDURES FOR XxfaSnDataDetails---------------
     *-----------------------------------------------------------------------------*/

   /********************************************************************************************
   Modulo : lock_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 12/Ago/2025
   Descripcion : Lock Row sobre la tabla xxfc.xxfa_sn_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Ago/2025   CHG0101033      Version Inicial
   ********************************************************************************************/
    /*--------------------------lock_row-------------------------*/
   PROCEDURE lock_row (p_rowid ROWID
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
            , p_FA_ITEM_SEQUENCE IN NUMBER
            , p_RCV_INVOICE_NUM IN VARCHAR2
            , p_AP_INVOICE_UUID IN VARCHAR2
            , p_RCV_PO_HEADER_ID IN NUMBER
            , p_POH_PO_NUMBER IN VARCHAR2
            , p_POH_PO_DATE IN DATE
            , p_RCV_PO_RELEASE_ID IN NUMBER
			, p_PRA_RELEASE_NUM IN NUMBER
            , p_RCV_PO_LINE_ID IN NUMBER
            , p_POL_PO_LINE_NUM IN NUMBER
            , p_RCV_PO_LINE_LOCATION_ID IN NUMBER
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
            , p_ASSET_BADGEABLE IN VARCHAR2
            , p_FAA_MANUFACTURER_NAME IN VARCHAR2
            , p_FAA_MODEL_NUMBER IN VARCHAR2
            , p_FAA_SERIAL_NUMBER IN VARCHAR2
            , p_PRL_REQUISITION_LINE_ID IN NUMBER
            , p_PRL_ORACLE_CR IN VARCHAR2
            , p_PRL_ORACLE_CR_SUPERIOR IN VARCHAR2
            , p_MCR_ORACLE_EF IN VARCHAR2
            , p_OOH_HEADER_ID IN NUMBER
            , p_OOH_ORDER_NUMBER IN NUMBER
            , p_MMT_TRANSACTION_ID IN NUMBER
            , p_MMT_CREATION_DATE IN DATE
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
        
        CURSOR c IS SELECT 
            DATA_DETAIL_ID
            , RCV_TRANSACTION_ID
            , RCV_DESTINATION_TYPE_CODE
            , RCV_TRANSACTION_DATE
            , RCV_PRIMARY_UNIT_OF_MEASURE
            , RCV_SHIPMENT_HEADER_ID
            , RSH_RECEIPT_NUM
            , RCV_SHIPMENT_LINE_ID
            , RSL_SHIPMENT_LINE_NUM
            , RSL_ITEM_ID
            , MSI_ITEM_NUMBER
            , MSI_USE_TYPE
            , RSL_ITEM_DESCRIPTION
            , FA_ITEM_SEQUENCE
            , RCV_INVOICE_NUM
            , AP_INVOICE_UUID
            , RCV_PO_HEADER_ID
            , POH_PO_NUMBER
            , POH_PO_DATE
            , RCV_PO_RELEASE_ID
			, PRA_RELEASE_NUM
            , RCV_PO_LINE_ID
            , POL_PO_LINE_NUM
            , RCV_PO_LINE_LOCATION_ID
            , RCV_PO_UNIT_PRICE
            , RCV_CURRENCY_CODE
            , RCV_CURRENCY_CONVERSION_RATE
            , RCV_CURRENCY_CONVERSION_DATE
            , RCV_VENDOR_ID
            , ASU_VENDOR_NUMBER
            , ASU_VENDOR_NAME
            , RCV_VENDOR_SITE_ID
            , ASS_VENDOR_SITE_CODE
            , RCV_INV_ORGANIZATION_ID
            , MTL_INV_ORGANIZATION_CODE
            , POH_ORG_ID
            , HOU_ORG_CODE
            , FAA_ASSET_ID
            , FAA_ASSET_NUMBER
            , FAA_TAG_NUMBER
            , FAA_ASSET_CATEGORY_ID
            , FCB_ASSET_CATEG_SEG_CONCAT
            , ASSET_BADGEABLE
            , FAA_MANUFACTURER_NAME
            , FAA_MODEL_NUMBER
            , FAA_SERIAL_NUMBER
            , PRL_REQUISITION_LINE_ID
            , PRL_ORACLE_CR
            , PRL_ORACLE_CR_SUPERIOR
            , MCR_ORACLE_EF
            , OOH_HEADER_ID
            , OOH_ORDER_NUMBER
            , MMT_TRANSACTION_ID
			, MMT_CREATION_DATE
            FROM XXFA_SN_DATA_DETAILS
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
            x_errors := 'THE RECORD WITH ROWID = ' || p_rowid || ' NO LONGER EXISTS IN TABLE XXFA_SN_DATA_DETAILS';
        ELSIF (NOT (((recinfo.DATA_DETAIL_ID = p_DATA_DETAIL_ID) OR (recinfo.DATA_DETAIL_ID IS NULL AND p_DATA_DETAIL_ID IS NULL))
                AND ((recinfo.RCV_TRANSACTION_ID = p_RCV_TRANSACTION_ID) OR (recinfo.RCV_TRANSACTION_ID IS NULL AND p_RCV_TRANSACTION_ID IS NULL))
                AND ((recinfo.RCV_DESTINATION_TYPE_CODE = p_RCV_DESTINATION_TYPE_CODE) OR (recinfo.RCV_DESTINATION_TYPE_CODE IS NULL AND p_RCV_DESTINATION_TYPE_CODE IS NULL))
                AND ((recinfo.RCV_TRANSACTION_DATE = p_RCV_TRANSACTION_DATE) OR (recinfo.RCV_TRANSACTION_DATE IS NULL AND p_RCV_TRANSACTION_DATE IS NULL))
                AND ((recinfo.RCV_PRIMARY_UNIT_OF_MEASURE = p_RCV_PRIMARY_UNIT_OF_MEASURE) OR (recinfo.RCV_PRIMARY_UNIT_OF_MEASURE IS NULL AND p_RCV_PRIMARY_UNIT_OF_MEASURE IS NULL))
                AND ((recinfo.RCV_SHIPMENT_HEADER_ID = p_RCV_SHIPMENT_HEADER_ID) OR (recinfo.RCV_SHIPMENT_HEADER_ID IS NULL AND p_RCV_SHIPMENT_HEADER_ID IS NULL))
                AND ((recinfo.RSH_RECEIPT_NUM = p_RSH_RECEIPT_NUM) OR (recinfo.RSH_RECEIPT_NUM IS NULL AND p_RSH_RECEIPT_NUM IS NULL))
                AND ((recinfo.RCV_SHIPMENT_LINE_ID = p_RCV_SHIPMENT_LINE_ID) OR (recinfo.RCV_SHIPMENT_LINE_ID IS NULL AND p_RCV_SHIPMENT_LINE_ID IS NULL))
                AND ((recinfo.RSL_SHIPMENT_LINE_NUM = p_RSL_SHIPMENT_LINE_NUM) OR (recinfo.RSL_SHIPMENT_LINE_NUM IS NULL AND p_RSL_SHIPMENT_LINE_NUM IS NULL))
                AND ((recinfo.RSL_ITEM_ID = p_RSL_ITEM_ID) OR (recinfo.RSL_ITEM_ID IS NULL AND p_RSL_ITEM_ID IS NULL))
                AND ((recinfo.MSI_ITEM_NUMBER = p_MSI_ITEM_NUMBER) OR (recinfo.MSI_ITEM_NUMBER IS NULL AND p_MSI_ITEM_NUMBER IS NULL))
                AND ((recinfo.MSI_USE_TYPE = p_MSI_USE_TYPE) OR (recinfo.MSI_USE_TYPE IS NULL AND p_MSI_USE_TYPE IS NULL))
                AND ((recinfo.RSL_ITEM_DESCRIPTION = p_RSL_ITEM_DESCRIPTION) OR (recinfo.RSL_ITEM_DESCRIPTION IS NULL AND p_RSL_ITEM_DESCRIPTION IS NULL))
                AND ((recinfo.FA_ITEM_SEQUENCE = p_FA_ITEM_SEQUENCE) OR (recinfo.FA_ITEM_SEQUENCE IS NULL AND p_FA_ITEM_SEQUENCE IS NULL))
                AND ((recinfo.RCV_INVOICE_NUM = p_RCV_INVOICE_NUM) OR (recinfo.RCV_INVOICE_NUM IS NULL AND p_RCV_INVOICE_NUM IS NULL))
                AND ((recinfo.AP_INVOICE_UUID = p_AP_INVOICE_UUID) OR (recinfo.AP_INVOICE_UUID IS NULL AND p_AP_INVOICE_UUID IS NULL))
                AND ((recinfo.RCV_PO_HEADER_ID = p_RCV_PO_HEADER_ID) OR (recinfo.RCV_PO_HEADER_ID IS NULL AND p_RCV_PO_HEADER_ID IS NULL))
                AND ((recinfo.POH_PO_NUMBER = p_POH_PO_NUMBER) OR (recinfo.POH_PO_NUMBER IS NULL AND p_POH_PO_NUMBER IS NULL))
                AND ((recinfo.POH_PO_DATE = p_POH_PO_DATE) OR (recinfo.POH_PO_DATE IS NULL AND p_POH_PO_DATE IS NULL))
                AND ((recinfo.RCV_PO_RELEASE_ID = p_RCV_PO_RELEASE_ID) OR (recinfo.RCV_PO_RELEASE_ID IS NULL AND p_RCV_PO_RELEASE_ID IS NULL))
				AND ((recinfo.PRA_RELEASE_NUM = p_PRA_RELEASE_NUM) OR (recinfo.PRA_RELEASE_NUM IS NULL AND p_PRA_RELEASE_NUM IS NULL))
                AND ((recinfo.RCV_PO_LINE_ID = p_RCV_PO_LINE_ID) OR (recinfo.RCV_PO_LINE_ID IS NULL AND p_RCV_PO_LINE_ID IS NULL))
                AND ((recinfo.POL_PO_LINE_NUM = p_POL_PO_LINE_NUM) OR (recinfo.POL_PO_LINE_NUM IS NULL AND p_POL_PO_LINE_NUM IS NULL))
                AND ((recinfo.RCV_PO_LINE_LOCATION_ID = p_RCV_PO_LINE_LOCATION_ID) OR (recinfo.RCV_PO_LINE_LOCATION_ID IS NULL AND p_RCV_PO_LINE_LOCATION_ID IS NULL))
                AND ((recinfo.RCV_PO_UNIT_PRICE = p_RCV_PO_UNIT_PRICE) OR (recinfo.RCV_PO_UNIT_PRICE IS NULL AND p_RCV_PO_UNIT_PRICE IS NULL))
                AND ((recinfo.RCV_CURRENCY_CODE = p_RCV_CURRENCY_CODE) OR (recinfo.RCV_CURRENCY_CODE IS NULL AND p_RCV_CURRENCY_CODE IS NULL))
                AND ((recinfo.RCV_CURRENCY_CONVERSION_RATE = p_RCV_CURRENCY_CONVERSION_RATE) OR (recinfo.RCV_CURRENCY_CONVERSION_RATE IS NULL AND p_RCV_CURRENCY_CONVERSION_RATE IS NULL))
                AND ((recinfo.RCV_CURRENCY_CONVERSION_DATE = p_RCV_CURRENCY_CONVERSION_DATE) OR (recinfo.RCV_CURRENCY_CONVERSION_DATE IS NULL AND p_RCV_CURRENCY_CONVERSION_DATE IS NULL))
                AND ((recinfo.RCV_VENDOR_ID = p_RCV_VENDOR_ID) OR (recinfo.RCV_VENDOR_ID IS NULL AND p_RCV_VENDOR_ID IS NULL))
                AND ((recinfo.ASU_VENDOR_NUMBER = p_ASU_VENDOR_NUMBER) OR (recinfo.ASU_VENDOR_NUMBER IS NULL AND p_ASU_VENDOR_NUMBER IS NULL))
                AND ((recinfo.ASU_VENDOR_NAME = p_ASU_VENDOR_NAME) OR (recinfo.ASU_VENDOR_NAME IS NULL AND p_ASU_VENDOR_NAME IS NULL))
                AND ((recinfo.RCV_VENDOR_SITE_ID = p_RCV_VENDOR_SITE_ID) OR (recinfo.RCV_VENDOR_SITE_ID IS NULL AND p_RCV_VENDOR_SITE_ID IS NULL))
                AND ((recinfo.ASS_VENDOR_SITE_CODE = p_ASS_VENDOR_SITE_CODE) OR (recinfo.ASS_VENDOR_SITE_CODE IS NULL AND p_ASS_VENDOR_SITE_CODE IS NULL))
                AND ((recinfo.RCV_INV_ORGANIZATION_ID = p_RCV_INV_ORGANIZATION_ID) OR (recinfo.RCV_INV_ORGANIZATION_ID IS NULL AND p_RCV_INV_ORGANIZATION_ID IS NULL))
                AND ((recinfo.MTL_INV_ORGANIZATION_CODE = p_MTL_INV_ORGANIZATION_CODE) OR (recinfo.MTL_INV_ORGANIZATION_CODE IS NULL AND p_MTL_INV_ORGANIZATION_CODE IS NULL))
                AND ((recinfo.POH_ORG_ID = p_POH_ORG_ID) OR (recinfo.POH_ORG_ID IS NULL AND p_POH_ORG_ID IS NULL))
                AND ((recinfo.HOU_ORG_CODE = p_HOU_ORG_CODE) OR (recinfo.HOU_ORG_CODE IS NULL AND p_HOU_ORG_CODE IS NULL))
                AND ((recinfo.FAA_ASSET_ID = p_FAA_ASSET_ID) OR (recinfo.FAA_ASSET_ID IS NULL AND p_FAA_ASSET_ID IS NULL))
                AND ((recinfo.FAA_ASSET_NUMBER = p_FAA_ASSET_NUMBER) OR (recinfo.FAA_ASSET_NUMBER IS NULL AND p_FAA_ASSET_NUMBER IS NULL))
                AND ((recinfo.FAA_TAG_NUMBER = p_FAA_TAG_NUMBER) OR (recinfo.FAA_TAG_NUMBER IS NULL AND p_FAA_TAG_NUMBER IS NULL))
                AND ((recinfo.FAA_ASSET_CATEGORY_ID = p_FAA_ASSET_CATEGORY_ID) OR (recinfo.FAA_ASSET_CATEGORY_ID IS NULL AND p_FAA_ASSET_CATEGORY_ID IS NULL))
                AND ((recinfo.FCB_ASSET_CATEG_SEG_CONCAT = p_FCB_ASSET_CATEG_SEG_CONCAT) OR (recinfo.FCB_ASSET_CATEG_SEG_CONCAT IS NULL AND p_FCB_ASSET_CATEG_SEG_CONCAT IS NULL))
                AND ((recinfo.ASSET_BADGEABLE = p_ASSET_BADGEABLE) OR (recinfo.ASSET_BADGEABLE IS NULL AND p_ASSET_BADGEABLE IS NULL))
                AND ((recinfo.FAA_MANUFACTURER_NAME = p_FAA_MANUFACTURER_NAME) OR (recinfo.FAA_MANUFACTURER_NAME IS NULL AND p_FAA_MANUFACTURER_NAME IS NULL))
                AND ((recinfo.FAA_MODEL_NUMBER = p_FAA_MODEL_NUMBER) OR (recinfo.FAA_MODEL_NUMBER IS NULL AND p_FAA_MODEL_NUMBER IS NULL))
                AND ((recinfo.FAA_SERIAL_NUMBER = p_FAA_SERIAL_NUMBER) OR (recinfo.FAA_SERIAL_NUMBER IS NULL AND p_FAA_SERIAL_NUMBER IS NULL))
                AND ((recinfo.PRL_REQUISITION_LINE_ID = p_PRL_REQUISITION_LINE_ID) OR (recinfo.PRL_REQUISITION_LINE_ID IS NULL AND p_PRL_REQUISITION_LINE_ID IS NULL))
                AND ((recinfo.PRL_ORACLE_CR = p_PRL_ORACLE_CR) OR (recinfo.PRL_ORACLE_CR IS NULL AND p_PRL_ORACLE_CR IS NULL))
                AND ((recinfo.PRL_ORACLE_CR_SUPERIOR = p_PRL_ORACLE_CR_SUPERIOR) OR (recinfo.PRL_ORACLE_CR_SUPERIOR IS NULL AND p_PRL_ORACLE_CR_SUPERIOR IS NULL))
                AND ((recinfo.MCR_ORACLE_EF = p_MCR_ORACLE_EF) OR (recinfo.MCR_ORACLE_EF IS NULL AND p_MCR_ORACLE_EF IS NULL))
                AND ((recinfo.OOH_HEADER_ID = p_OOH_HEADER_ID) OR (recinfo.OOH_HEADER_ID IS NULL AND p_OOH_HEADER_ID IS NULL))
                AND ((recinfo.OOH_ORDER_NUMBER = p_OOH_ORDER_NUMBER) OR (recinfo.OOH_ORDER_NUMBER IS NULL AND p_OOH_ORDER_NUMBER IS NULL))
                AND ((recinfo.MMT_TRANSACTION_ID = p_MMT_TRANSACTION_ID) OR (recinfo.MMT_TRANSACTION_ID IS NULL AND p_MMT_TRANSACTION_ID IS NULL))
				AND ((recinfo.MMT_CREATION_DATE = p_MMT_CREATION_DATE) OR (recinfo.MMT_CREATION_DATE IS NULL AND p_MMT_CREATION_DATE IS NULL))
				)) THEN
            x_retcode := 2;
            x_errors := 'THE RECORD WITH ROWID = ' || p_rowid || ' IN TABLE XXFA_SN_DATA_DETAILS HAS CHANGED.';
        END IF;
        CLOSE c;
   EXCEPTION
      WHEN OTHERS 
	  THEN
         x_retcode := 2;
         x_errors := SQLERRM;
   END lock_row;


   /********************************************************************************************
   Modulo : lock_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 12/Ago/2025
   Descripcion : Lock Row sobre la tabla xxfc.xxfa_sn_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Ago/2025   CHG0101033      Version Inicial
   ********************************************************************************************/
    /*--------------------------lock_row-------------------------*/
   PROCEDURE lock_row (p_rowid ROWID
            , p_XxfaSnDataDetails XXFA_SN_DATA_DETAILS%ROWTYPE
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
        
    BEGIN
        lock_row(p_rowid
            , p_XxfaSnDataDetails.DATA_DETAIL_ID
            , p_XxfaSnDataDetails.RCV_TRANSACTION_ID
            , p_XxfaSnDataDetails.RCV_DESTINATION_TYPE_CODE
            , p_XxfaSnDataDetails.RCV_TRANSACTION_DATE
            , p_XxfaSnDataDetails.RCV_PRIMARY_UNIT_OF_MEASURE
            , p_XxfaSnDataDetails.RCV_SHIPMENT_HEADER_ID
            , p_XxfaSnDataDetails.RSH_RECEIPT_NUM
            , p_XxfaSnDataDetails.RCV_SHIPMENT_LINE_ID
            , p_XxfaSnDataDetails.RSL_SHIPMENT_LINE_NUM
            , p_XxfaSnDataDetails.RSL_ITEM_ID
            , p_XxfaSnDataDetails.MSI_ITEM_NUMBER
            , p_XxfaSnDataDetails.MSI_USE_TYPE
            , p_XxfaSnDataDetails.RSL_ITEM_DESCRIPTION
            , p_XxfaSnDataDetails.FA_ITEM_SEQUENCE
            , p_XxfaSnDataDetails.RCV_INVOICE_NUM
            , p_XxfaSnDataDetails.AP_INVOICE_UUID
            , p_XxfaSnDataDetails.RCV_PO_HEADER_ID
            , p_XxfaSnDataDetails.POH_PO_NUMBER
            , p_XxfaSnDataDetails.POH_PO_DATE
            , p_XxfaSnDataDetails.RCV_PO_RELEASE_ID
			, p_XxfaSnDataDetails.PRA_RELEASE_NUM
            , p_XxfaSnDataDetails.RCV_PO_LINE_ID
            , p_XxfaSnDataDetails.POL_PO_LINE_NUM
            , p_XxfaSnDataDetails.RCV_PO_LINE_LOCATION_ID
            , p_XxfaSnDataDetails.RCV_PO_UNIT_PRICE
            , p_XxfaSnDataDetails.RCV_CURRENCY_CODE
            , p_XxfaSnDataDetails.RCV_CURRENCY_CONVERSION_RATE
            , p_XxfaSnDataDetails.RCV_CURRENCY_CONVERSION_DATE
            , p_XxfaSnDataDetails.RCV_VENDOR_ID
            , p_XxfaSnDataDetails.ASU_VENDOR_NUMBER
            , p_XxfaSnDataDetails.ASU_VENDOR_NAME
            , p_XxfaSnDataDetails.RCV_VENDOR_SITE_ID
            , p_XxfaSnDataDetails.ASS_VENDOR_SITE_CODE
            , p_XxfaSnDataDetails.RCV_INV_ORGANIZATION_ID
            , p_XxfaSnDataDetails.MTL_INV_ORGANIZATION_CODE
            , p_XxfaSnDataDetails.POH_ORG_ID
            , p_XxfaSnDataDetails.HOU_ORG_CODE
            , p_XxfaSnDataDetails.FAA_ASSET_ID
            , p_XxfaSnDataDetails.FAA_ASSET_NUMBER
            , p_XxfaSnDataDetails.FAA_TAG_NUMBER
            , p_XxfaSnDataDetails.FAA_ASSET_CATEGORY_ID
            , p_XxfaSnDataDetails.FCB_ASSET_CATEG_SEG_CONCAT
            , p_XxfaSnDataDetails.ASSET_BADGEABLE
            , p_XxfaSnDataDetails.FAA_MANUFACTURER_NAME
            , p_XxfaSnDataDetails.FAA_MODEL_NUMBER
            , p_XxfaSnDataDetails.FAA_SERIAL_NUMBER
            , p_XxfaSnDataDetails.PRL_REQUISITION_LINE_ID
            , p_XxfaSnDataDetails.PRL_ORACLE_CR
            , p_XxfaSnDataDetails.PRL_ORACLE_CR_SUPERIOR
            , p_XxfaSnDataDetails.MCR_ORACLE_EF
            , p_XxfaSnDataDetails.OOH_HEADER_ID
            , p_XxfaSnDataDetails.OOH_ORDER_NUMBER
            , p_XxfaSnDataDetails.MMT_TRANSACTION_ID
            , p_XxfaSnDataDetails.MMT_CREATION_DATE
            , x_errors, x_retcode);
   END lock_row;


   /********************************************************************************************
   Modulo : update_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 12/Ago/2025
   Descripcion : Update Row sobre la tabla xxfc.xxfa_sn_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Ago/2025   CHG0101033      Version Inicial
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
            , p_FA_ITEM_SEQUENCE IN NUMBER DEFAULT FND_API.G_MISS_NUM
            , p_RCV_INVOICE_NUM IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
            , p_AP_INVOICE_UUID IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
            , p_RCV_PO_HEADER_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
            , p_POH_PO_NUMBER IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
            , p_POH_PO_DATE IN DATE DEFAULT FND_API.G_MISS_DATE
            , p_RCV_PO_RELEASE_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
			, p_PRA_RELEASE_NUM IN NUMBER DEFAULT FND_API.G_MISS_NUM
            , p_RCV_PO_LINE_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
            , p_POL_PO_LINE_NUM IN NUMBER DEFAULT FND_API.G_MISS_NUM
            , p_RCV_PO_LINE_LOCATION_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
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
            , p_ASSET_BADGEABLE IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
            , p_FAA_MANUFACTURER_NAME IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
            , p_FAA_MODEL_NUMBER IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
            , p_FAA_SERIAL_NUMBER IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
            , p_PRL_REQUISITION_LINE_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
            , p_PRL_ORACLE_CR IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
            , p_PRL_ORACLE_CR_SUPERIOR IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
            , p_MCR_ORACLE_EF IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
            , p_OOH_HEADER_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
            , p_OOH_ORDER_NUMBER IN NUMBER DEFAULT FND_API.G_MISS_NUM
            , p_MMT_TRANSACTION_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
            , p_MMT_CREATION_DATE IN DATE DEFAULT FND_API.G_MISS_DATE
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
        
    BEGIN
        x_errors := '';
        UPDATE XXFA_SN_DATA_DETAILS SET DATA_DETAIL_ID = DECODE(p_DATA_DETAIL_ID, FND_API.G_MISS_NUM, DATA_DETAIL_ID, p_DATA_DETAIL_ID)
            , RCV_TRANSACTION_ID = DECODE(p_RCV_TRANSACTION_ID, FND_API.G_MISS_NUM, RCV_TRANSACTION_ID, p_RCV_TRANSACTION_ID)
            , RCV_DESTINATION_TYPE_CODE = DECODE(p_RCV_DESTINATION_TYPE_CODE, FND_API.G_MISS_CHAR, RCV_DESTINATION_TYPE_CODE, p_RCV_DESTINATION_TYPE_CODE)
            , RCV_TRANSACTION_DATE = DECODE(p_RCV_TRANSACTION_DATE, FND_API.G_MISS_DATE, RCV_TRANSACTION_DATE, p_RCV_TRANSACTION_DATE)
            , RCV_PRIMARY_UNIT_OF_MEASURE = DECODE(p_RCV_PRIMARY_UNIT_OF_MEASURE, FND_API.G_MISS_CHAR, RCV_PRIMARY_UNIT_OF_MEASURE, p_RCV_PRIMARY_UNIT_OF_MEASURE)
            , RCV_SHIPMENT_HEADER_ID = DECODE(p_RCV_SHIPMENT_HEADER_ID, FND_API.G_MISS_NUM, RCV_SHIPMENT_HEADER_ID, p_RCV_SHIPMENT_HEADER_ID)
            , RSH_RECEIPT_NUM = DECODE(p_RSH_RECEIPT_NUM, FND_API.G_MISS_CHAR, RSH_RECEIPT_NUM, p_RSH_RECEIPT_NUM)
            , RCV_SHIPMENT_LINE_ID = DECODE(p_RCV_SHIPMENT_LINE_ID, FND_API.G_MISS_NUM, RCV_SHIPMENT_LINE_ID, p_RCV_SHIPMENT_LINE_ID)
            , RSL_SHIPMENT_LINE_NUM = DECODE(p_RSL_SHIPMENT_LINE_NUM, FND_API.G_MISS_NUM, RSL_SHIPMENT_LINE_NUM, p_RSL_SHIPMENT_LINE_NUM)
            , RSL_ITEM_ID = DECODE(p_RSL_ITEM_ID, FND_API.G_MISS_NUM, RSL_ITEM_ID, p_RSL_ITEM_ID)
            , MSI_ITEM_NUMBER = DECODE(p_MSI_ITEM_NUMBER, FND_API.G_MISS_CHAR, MSI_ITEM_NUMBER, p_MSI_ITEM_NUMBER)
            , MSI_USE_TYPE = DECODE(p_MSI_USE_TYPE, FND_API.G_MISS_CHAR, MSI_USE_TYPE, p_MSI_USE_TYPE)
            , RSL_ITEM_DESCRIPTION = DECODE(p_RSL_ITEM_DESCRIPTION, FND_API.G_MISS_CHAR, RSL_ITEM_DESCRIPTION, p_RSL_ITEM_DESCRIPTION)
            , FA_ITEM_SEQUENCE = DECODE(p_FA_ITEM_SEQUENCE, FND_API.G_MISS_NUM, FA_ITEM_SEQUENCE, p_FA_ITEM_SEQUENCE)
            , RCV_INVOICE_NUM = DECODE(p_RCV_INVOICE_NUM, FND_API.G_MISS_CHAR, RCV_INVOICE_NUM, p_RCV_INVOICE_NUM)
            , AP_INVOICE_UUID = DECODE(p_AP_INVOICE_UUID, FND_API.G_MISS_CHAR, AP_INVOICE_UUID, p_AP_INVOICE_UUID)
            , RCV_PO_HEADER_ID = DECODE(p_RCV_PO_HEADER_ID, FND_API.G_MISS_NUM, RCV_PO_HEADER_ID, p_RCV_PO_HEADER_ID)
            , POH_PO_NUMBER = DECODE(p_POH_PO_NUMBER, FND_API.G_MISS_CHAR, POH_PO_NUMBER, p_POH_PO_NUMBER)
            , POH_PO_DATE = DECODE(p_POH_PO_DATE, FND_API.G_MISS_DATE, POH_PO_DATE, p_POH_PO_DATE)
            , RCV_PO_RELEASE_ID = DECODE(p_RCV_PO_RELEASE_ID, FND_API.G_MISS_NUM, RCV_PO_RELEASE_ID, p_RCV_PO_RELEASE_ID)
			, PRA_RELEASE_NUM = DECODE(p_PRA_RELEASE_NUM, FND_API.G_MISS_NUM, PRA_RELEASE_NUM, p_PRA_RELEASE_NUM)
            , RCV_PO_LINE_ID = DECODE(p_RCV_PO_LINE_ID, FND_API.G_MISS_NUM, RCV_PO_LINE_ID, p_RCV_PO_LINE_ID)
            , POL_PO_LINE_NUM = DECODE(p_POL_PO_LINE_NUM, FND_API.G_MISS_NUM, POL_PO_LINE_NUM, p_POL_PO_LINE_NUM)
            , RCV_PO_LINE_LOCATION_ID = DECODE(p_RCV_PO_LINE_LOCATION_ID, FND_API.G_MISS_NUM, RCV_PO_LINE_LOCATION_ID, p_RCV_PO_LINE_LOCATION_ID)
            , RCV_PO_UNIT_PRICE = DECODE(p_RCV_PO_UNIT_PRICE, FND_API.G_MISS_NUM, RCV_PO_UNIT_PRICE, p_RCV_PO_UNIT_PRICE)
            , RCV_CURRENCY_CODE = DECODE(p_RCV_CURRENCY_CODE, FND_API.G_MISS_CHAR, RCV_CURRENCY_CODE, p_RCV_CURRENCY_CODE)
            , RCV_CURRENCY_CONVERSION_RATE = DECODE(p_RCV_CURRENCY_CONVERSION_RATE, FND_API.G_MISS_NUM, RCV_CURRENCY_CONVERSION_RATE, p_RCV_CURRENCY_CONVERSION_RATE)
            , RCV_CURRENCY_CONVERSION_DATE = DECODE(p_RCV_CURRENCY_CONVERSION_DATE, FND_API.G_MISS_DATE, RCV_CURRENCY_CONVERSION_DATE, p_RCV_CURRENCY_CONVERSION_DATE)
            , RCV_VENDOR_ID = DECODE(p_RCV_VENDOR_ID, FND_API.G_MISS_NUM, RCV_VENDOR_ID, p_RCV_VENDOR_ID)
            , ASU_VENDOR_NUMBER = DECODE(p_ASU_VENDOR_NUMBER, FND_API.G_MISS_CHAR, ASU_VENDOR_NUMBER, p_ASU_VENDOR_NUMBER)
            , ASU_VENDOR_NAME = DECODE(p_ASU_VENDOR_NAME, FND_API.G_MISS_CHAR, ASU_VENDOR_NAME, p_ASU_VENDOR_NAME)
            , RCV_VENDOR_SITE_ID = DECODE(p_RCV_VENDOR_SITE_ID, FND_API.G_MISS_NUM, RCV_VENDOR_SITE_ID, p_RCV_VENDOR_SITE_ID)
            , ASS_VENDOR_SITE_CODE = DECODE(p_ASS_VENDOR_SITE_CODE, FND_API.G_MISS_CHAR, ASS_VENDOR_SITE_CODE, p_ASS_VENDOR_SITE_CODE)
            , RCV_INV_ORGANIZATION_ID = DECODE(p_RCV_INV_ORGANIZATION_ID, FND_API.G_MISS_NUM, RCV_INV_ORGANIZATION_ID, p_RCV_INV_ORGANIZATION_ID)
            , MTL_INV_ORGANIZATION_CODE = DECODE(p_MTL_INV_ORGANIZATION_CODE, FND_API.G_MISS_CHAR, MTL_INV_ORGANIZATION_CODE, p_MTL_INV_ORGANIZATION_CODE)
            , POH_ORG_ID = DECODE(p_POH_ORG_ID, FND_API.G_MISS_NUM, POH_ORG_ID, p_POH_ORG_ID)
            , HOU_ORG_CODE = DECODE(p_HOU_ORG_CODE, FND_API.G_MISS_CHAR, HOU_ORG_CODE, p_HOU_ORG_CODE)
            , FAA_ASSET_ID = DECODE(p_FAA_ASSET_ID, FND_API.G_MISS_NUM, FAA_ASSET_ID, p_FAA_ASSET_ID)
            , FAA_ASSET_NUMBER = DECODE(p_FAA_ASSET_NUMBER, FND_API.G_MISS_CHAR, FAA_ASSET_NUMBER, p_FAA_ASSET_NUMBER)
            , FAA_TAG_NUMBER = DECODE(p_FAA_TAG_NUMBER, FND_API.G_MISS_CHAR, FAA_TAG_NUMBER, p_FAA_TAG_NUMBER)
            , FAA_ASSET_CATEGORY_ID = DECODE(p_FAA_ASSET_CATEGORY_ID, FND_API.G_MISS_NUM, FAA_ASSET_CATEGORY_ID, p_FAA_ASSET_CATEGORY_ID)
            , FCB_ASSET_CATEG_SEG_CONCAT = DECODE(p_FCB_ASSET_CATEG_SEG_CONCAT, FND_API.G_MISS_CHAR, FCB_ASSET_CATEG_SEG_CONCAT, p_FCB_ASSET_CATEG_SEG_CONCAT)
            , ASSET_BADGEABLE = DECODE(p_ASSET_BADGEABLE, FND_API.G_MISS_CHAR, ASSET_BADGEABLE, p_ASSET_BADGEABLE)
            , FAA_MANUFACTURER_NAME = DECODE(p_FAA_MANUFACTURER_NAME, FND_API.G_MISS_CHAR, FAA_MANUFACTURER_NAME, p_FAA_MANUFACTURER_NAME)
            , FAA_MODEL_NUMBER = DECODE(p_FAA_MODEL_NUMBER, FND_API.G_MISS_CHAR, FAA_MODEL_NUMBER, p_FAA_MODEL_NUMBER)
            , FAA_SERIAL_NUMBER = DECODE(p_FAA_SERIAL_NUMBER, FND_API.G_MISS_CHAR, FAA_SERIAL_NUMBER, p_FAA_SERIAL_NUMBER)
            , PRL_REQUISITION_LINE_ID = DECODE(p_PRL_REQUISITION_LINE_ID, FND_API.G_MISS_NUM, PRL_REQUISITION_LINE_ID, p_PRL_REQUISITION_LINE_ID)
            , PRL_ORACLE_CR = DECODE(p_PRL_ORACLE_CR, FND_API.G_MISS_CHAR, PRL_ORACLE_CR, p_PRL_ORACLE_CR)
            , PRL_ORACLE_CR_SUPERIOR = DECODE(p_PRL_ORACLE_CR_SUPERIOR, FND_API.G_MISS_CHAR, PRL_ORACLE_CR_SUPERIOR, p_PRL_ORACLE_CR_SUPERIOR)
            , MCR_ORACLE_EF = DECODE(p_MCR_ORACLE_EF, FND_API.G_MISS_CHAR, MCR_ORACLE_EF, p_MCR_ORACLE_EF)
            , OOH_HEADER_ID = DECODE(p_OOH_HEADER_ID, FND_API.G_MISS_NUM, OOH_HEADER_ID, p_OOH_HEADER_ID)
            , OOH_ORDER_NUMBER = DECODE(p_OOH_ORDER_NUMBER, FND_API.G_MISS_NUM, OOH_ORDER_NUMBER, p_OOH_ORDER_NUMBER)
            , MMT_TRANSACTION_ID = DECODE(p_MMT_TRANSACTION_ID, FND_API.G_MISS_NUM, MMT_TRANSACTION_ID, p_MMT_TRANSACTION_ID)
			, MMT_CREATION_DATE = DECODE(p_MMT_CREATION_DATE, FND_API.G_MISS_DATE, MMT_CREATION_DATE, p_MMT_CREATION_DATE)
            , LAST_UPDATE_LOGIN = FND_PROFILE.value('LOGIN_ID')
            , LAST_UPDATE_DATE = SYSDATE
            , LAST_UPDATED_BY = FND_PROFILE.value('USER_ID')
        WHERE DATA_DETAIL_ID = p_DATA_DETAIL_ID;
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
   Fecha : 12/Ago/2025
   Descripcion : Update Row sobre la tabla xxfc.xxfa_sn_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Ago/2025   CHG0101033      Version Inicial
   ********************************************************************************************/
    /*--------------------------update_row-------------------------*/
   PROCEDURE update_row (p_XxfaSnDataDetails XXFA_SN_DATA_DETAILS%ROWTYPE
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
        
    BEGIN
        update_row(p_XxfaSnDataDetails.DATA_DETAIL_ID
            , p_XxfaSnDataDetails.RCV_TRANSACTION_ID
            , p_XxfaSnDataDetails.RCV_DESTINATION_TYPE_CODE
            , p_XxfaSnDataDetails.RCV_TRANSACTION_DATE
            , p_XxfaSnDataDetails.RCV_PRIMARY_UNIT_OF_MEASURE
            , p_XxfaSnDataDetails.RCV_SHIPMENT_HEADER_ID
            , p_XxfaSnDataDetails.RSH_RECEIPT_NUM
            , p_XxfaSnDataDetails.RCV_SHIPMENT_LINE_ID
            , p_XxfaSnDataDetails.RSL_SHIPMENT_LINE_NUM
            , p_XxfaSnDataDetails.RSL_ITEM_ID
            , p_XxfaSnDataDetails.MSI_ITEM_NUMBER
            , p_XxfaSnDataDetails.MSI_USE_TYPE
            , p_XxfaSnDataDetails.RSL_ITEM_DESCRIPTION
            , p_XxfaSnDataDetails.FA_ITEM_SEQUENCE
            , p_XxfaSnDataDetails.RCV_INVOICE_NUM
            , p_XxfaSnDataDetails.AP_INVOICE_UUID
            , p_XxfaSnDataDetails.RCV_PO_HEADER_ID
            , p_XxfaSnDataDetails.POH_PO_NUMBER
            , p_XxfaSnDataDetails.POH_PO_DATE
            , p_XxfaSnDataDetails.RCV_PO_RELEASE_ID
			, p_XxfaSnDataDetails.PRA_RELEASE_NUM
            , p_XxfaSnDataDetails.RCV_PO_LINE_ID
            , p_XxfaSnDataDetails.POL_PO_LINE_NUM
            , p_XxfaSnDataDetails.RCV_PO_LINE_LOCATION_ID
            , p_XxfaSnDataDetails.RCV_PO_UNIT_PRICE
            , p_XxfaSnDataDetails.RCV_CURRENCY_CODE
            , p_XxfaSnDataDetails.RCV_CURRENCY_CONVERSION_RATE
            , p_XxfaSnDataDetails.RCV_CURRENCY_CONVERSION_DATE
            , p_XxfaSnDataDetails.RCV_VENDOR_ID
            , p_XxfaSnDataDetails.ASU_VENDOR_NUMBER
            , p_XxfaSnDataDetails.ASU_VENDOR_NAME
            , p_XxfaSnDataDetails.RCV_VENDOR_SITE_ID
            , p_XxfaSnDataDetails.ASS_VENDOR_SITE_CODE
            , p_XxfaSnDataDetails.RCV_INV_ORGANIZATION_ID
            , p_XxfaSnDataDetails.MTL_INV_ORGANIZATION_CODE
            , p_XxfaSnDataDetails.POH_ORG_ID
            , p_XxfaSnDataDetails.HOU_ORG_CODE
            , p_XxfaSnDataDetails.FAA_ASSET_ID
            , p_XxfaSnDataDetails.FAA_ASSET_NUMBER
            , p_XxfaSnDataDetails.FAA_TAG_NUMBER
            , p_XxfaSnDataDetails.FAA_ASSET_CATEGORY_ID
            , p_XxfaSnDataDetails.FCB_ASSET_CATEG_SEG_CONCAT
            , p_XxfaSnDataDetails.ASSET_BADGEABLE
            , p_XxfaSnDataDetails.FAA_MANUFACTURER_NAME
            , p_XxfaSnDataDetails.FAA_MODEL_NUMBER
            , p_XxfaSnDataDetails.FAA_SERIAL_NUMBER
            , p_XxfaSnDataDetails.PRL_REQUISITION_LINE_ID
            , p_XxfaSnDataDetails.PRL_ORACLE_CR
            , p_XxfaSnDataDetails.PRL_ORACLE_CR_SUPERIOR
            , p_XxfaSnDataDetails.MCR_ORACLE_EF
            , p_XxfaSnDataDetails.OOH_HEADER_ID
            , p_XxfaSnDataDetails.OOH_ORDER_NUMBER
            , p_XxfaSnDataDetails.MMT_TRANSACTION_ID
            , p_XxfaSnDataDetails.MMT_CREATION_DATE
            , x_errors, x_retcode);
   END update_row;

   /********************************************************************************************
   Modulo : insert_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 12/Ago/2025
   Descripcion : Insert Row sobre la tabla xxfc.xxfa_sn_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Ago/2025   CHG0101033      Version Inicial
   ********************************************************************************************/
    /*--------------------------insert_row-------------------------*/
   PROCEDURE insert_row(x_rowid OUT ROWID
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
            , p_FA_ITEM_SEQUENCE IN NUMBER
            , p_RCV_INVOICE_NUM IN VARCHAR2
            , p_AP_INVOICE_UUID IN VARCHAR2
            , p_RCV_PO_HEADER_ID IN NUMBER
            , p_POH_PO_NUMBER IN VARCHAR2
            , p_POH_PO_DATE IN DATE
            , p_RCV_PO_RELEASE_ID IN NUMBER
			, p_PRA_RELEASE_NUM IN NUMBER  
            , p_RCV_PO_LINE_ID IN NUMBER
            , p_POL_PO_LINE_NUM IN NUMBER
            , p_RCV_PO_LINE_LOCATION_ID IN NUMBER
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
            , p_ASSET_BADGEABLE IN VARCHAR2
            , p_FAA_MANUFACTURER_NAME IN VARCHAR2
            , p_FAA_MODEL_NUMBER IN VARCHAR2
            , p_FAA_SERIAL_NUMBER IN VARCHAR2
            , p_PRL_REQUISITION_LINE_ID IN NUMBER
            , p_PRL_ORACLE_CR IN VARCHAR2
            , p_PRL_ORACLE_CR_SUPERIOR IN VARCHAR2
            , p_MCR_ORACLE_EF IN VARCHAR2
            , p_OOH_HEADER_ID IN NUMBER
            , p_OOH_ORDER_NUMBER IN NUMBER
            , p_MMT_TRANSACTION_ID IN NUMBER
			, p_MMT_CREATION_DATE IN DATE
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
        
    BEGIN
        x_errors := '';
        INSERT INTO XXFA_SN_DATA_DETAILS(RCV_TRANSACTION_ID
            , RCV_DESTINATION_TYPE_CODE
            , RCV_TRANSACTION_DATE
            , RCV_PRIMARY_UNIT_OF_MEASURE
            , RCV_SHIPMENT_HEADER_ID
            , RSH_RECEIPT_NUM
            , RCV_SHIPMENT_LINE_ID
            , RSL_SHIPMENT_LINE_NUM
            , RSL_ITEM_ID
            , MSI_ITEM_NUMBER
            , MSI_USE_TYPE
            , RSL_ITEM_DESCRIPTION
            , FA_ITEM_SEQUENCE
            , RCV_INVOICE_NUM
            , AP_INVOICE_UUID
            , RCV_PO_HEADER_ID
            , POH_PO_NUMBER
            , POH_PO_DATE
            , RCV_PO_RELEASE_ID
			, PRA_RELEASE_NUM
            , RCV_PO_LINE_ID
            , POL_PO_LINE_NUM
            , RCV_PO_LINE_LOCATION_ID
            , RCV_PO_UNIT_PRICE
            , RCV_CURRENCY_CODE
            , RCV_CURRENCY_CONVERSION_RATE
            , RCV_CURRENCY_CONVERSION_DATE
            , RCV_VENDOR_ID
            , ASU_VENDOR_NUMBER
            , ASU_VENDOR_NAME
            , RCV_VENDOR_SITE_ID
            , ASS_VENDOR_SITE_CODE
            , RCV_INV_ORGANIZATION_ID
            , MTL_INV_ORGANIZATION_CODE
            , POH_ORG_ID
            , HOU_ORG_CODE
            , FAA_ASSET_ID
            , FAA_ASSET_NUMBER
            , FAA_TAG_NUMBER
            , FAA_ASSET_CATEGORY_ID
            , FCB_ASSET_CATEG_SEG_CONCAT
            , ASSET_BADGEABLE
            , FAA_MANUFACTURER_NAME
            , FAA_MODEL_NUMBER
            , FAA_SERIAL_NUMBER
            , PRL_REQUISITION_LINE_ID
            , PRL_ORACLE_CR
            , PRL_ORACLE_CR_SUPERIOR
            , MCR_ORACLE_EF
            , OOH_HEADER_ID
            , OOH_ORDER_NUMBER
            , MMT_TRANSACTION_ID
            , MMT_CREATION_DATE
            , LAST_UPDATE_LOGIN
            , CREATION_DATE
            , CREATED_BY
            , LAST_UPDATE_DATE
            , LAST_UPDATED_BY) VALUES (p_RCV_TRANSACTION_ID
            , p_RCV_DESTINATION_TYPE_CODE
            , p_RCV_TRANSACTION_DATE
            , p_RCV_PRIMARY_UNIT_OF_MEASURE
            , p_RCV_SHIPMENT_HEADER_ID
            , p_RSH_RECEIPT_NUM
            , p_RCV_SHIPMENT_LINE_ID
            , p_RSL_SHIPMENT_LINE_NUM
            , p_RSL_ITEM_ID
            , p_MSI_ITEM_NUMBER
            , p_MSI_USE_TYPE
            , p_RSL_ITEM_DESCRIPTION
            , p_FA_ITEM_SEQUENCE
            , p_RCV_INVOICE_NUM
            , p_AP_INVOICE_UUID
            , p_RCV_PO_HEADER_ID
            , p_POH_PO_NUMBER
            , p_POH_PO_DATE
            , p_RCV_PO_RELEASE_ID
			, p_PRA_RELEASE_NUM 
            , p_RCV_PO_LINE_ID
            , p_POL_PO_LINE_NUM
            , p_RCV_PO_LINE_LOCATION_ID
            , p_RCV_PO_UNIT_PRICE
            , p_RCV_CURRENCY_CODE
            , p_RCV_CURRENCY_CONVERSION_RATE
            , p_RCV_CURRENCY_CONVERSION_DATE
            , p_RCV_VENDOR_ID
            , p_ASU_VENDOR_NUMBER
            , p_ASU_VENDOR_NAME
            , p_RCV_VENDOR_SITE_ID
            , p_ASS_VENDOR_SITE_CODE
            , p_RCV_INV_ORGANIZATION_ID
            , p_MTL_INV_ORGANIZATION_CODE
            , p_POH_ORG_ID
            , p_HOU_ORG_CODE
            , p_FAA_ASSET_ID
            , p_FAA_ASSET_NUMBER
            , p_FAA_TAG_NUMBER
            , p_FAA_ASSET_CATEGORY_ID
            , p_FCB_ASSET_CATEG_SEG_CONCAT
            , p_ASSET_BADGEABLE
            , p_FAA_MANUFACTURER_NAME
            , p_FAA_MODEL_NUMBER
            , p_FAA_SERIAL_NUMBER
            , p_PRL_REQUISITION_LINE_ID
            , p_PRL_ORACLE_CR
            , p_PRL_ORACLE_CR_SUPERIOR
            , p_MCR_ORACLE_EF
            , p_OOH_HEADER_ID
            , p_OOH_ORDER_NUMBER
            , p_MMT_TRANSACTION_ID
			, p_MMT_CREATION_DATE
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
   Fecha : 12/Ago/2025
   Descripcion : Insert Row sobre la tabla xxfc.xxfa_sn_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Ago/2025   CHG0101033      Version Inicial
   ********************************************************************************************/
    /*--------------------------insert_row-------------------------*/
   PROCEDURE insert_row(x_rowid OUT ROWID
            , p_XxfaSnDataDetails XXFA_SN_DATA_DETAILS%ROWTYPE
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
        
    BEGIN
        insert_row(x_rowid 
            , p_XxfaSnDataDetails.RCV_TRANSACTION_ID
            , p_XxfaSnDataDetails.RCV_DESTINATION_TYPE_CODE
            , p_XxfaSnDataDetails.RCV_TRANSACTION_DATE
            , p_XxfaSnDataDetails.RCV_PRIMARY_UNIT_OF_MEASURE
            , p_XxfaSnDataDetails.RCV_SHIPMENT_HEADER_ID
            , p_XxfaSnDataDetails.RSH_RECEIPT_NUM
            , p_XxfaSnDataDetails.RCV_SHIPMENT_LINE_ID
            , p_XxfaSnDataDetails.RSL_SHIPMENT_LINE_NUM
            , p_XxfaSnDataDetails.RSL_ITEM_ID
            , p_XxfaSnDataDetails.MSI_ITEM_NUMBER
            , p_XxfaSnDataDetails.MSI_USE_TYPE
            , p_XxfaSnDataDetails.RSL_ITEM_DESCRIPTION
            , p_XxfaSnDataDetails.FA_ITEM_SEQUENCE
            , p_XxfaSnDataDetails.RCV_INVOICE_NUM
            , p_XxfaSnDataDetails.AP_INVOICE_UUID
            , p_XxfaSnDataDetails.RCV_PO_HEADER_ID
            , p_XxfaSnDataDetails.POH_PO_NUMBER
            , p_XxfaSnDataDetails.POH_PO_DATE
            , p_XxfaSnDataDetails.RCV_PO_RELEASE_ID
			, p_XxfaSnDataDetails.PRA_RELEASE_NUM
            , p_XxfaSnDataDetails.RCV_PO_LINE_ID
            , p_XxfaSnDataDetails.POL_PO_LINE_NUM
            , p_XxfaSnDataDetails.RCV_PO_LINE_LOCATION_ID
            , p_XxfaSnDataDetails.RCV_PO_UNIT_PRICE
            , p_XxfaSnDataDetails.RCV_CURRENCY_CODE
            , p_XxfaSnDataDetails.RCV_CURRENCY_CONVERSION_RATE
            , p_XxfaSnDataDetails.RCV_CURRENCY_CONVERSION_DATE
            , p_XxfaSnDataDetails.RCV_VENDOR_ID
            , p_XxfaSnDataDetails.ASU_VENDOR_NUMBER
            , p_XxfaSnDataDetails.ASU_VENDOR_NAME
            , p_XxfaSnDataDetails.RCV_VENDOR_SITE_ID
            , p_XxfaSnDataDetails.ASS_VENDOR_SITE_CODE
            , p_XxfaSnDataDetails.RCV_INV_ORGANIZATION_ID
            , p_XxfaSnDataDetails.MTL_INV_ORGANIZATION_CODE
            , p_XxfaSnDataDetails.POH_ORG_ID
            , p_XxfaSnDataDetails.HOU_ORG_CODE
            , p_XxfaSnDataDetails.FAA_ASSET_ID
            , p_XxfaSnDataDetails.FAA_ASSET_NUMBER
            , p_XxfaSnDataDetails.FAA_TAG_NUMBER
            , p_XxfaSnDataDetails.FAA_ASSET_CATEGORY_ID
            , p_XxfaSnDataDetails.FCB_ASSET_CATEG_SEG_CONCAT
            , p_XxfaSnDataDetails.ASSET_BADGEABLE
            , p_XxfaSnDataDetails.FAA_MANUFACTURER_NAME
            , p_XxfaSnDataDetails.FAA_MODEL_NUMBER
            , p_XxfaSnDataDetails.FAA_SERIAL_NUMBER
            , p_XxfaSnDataDetails.PRL_REQUISITION_LINE_ID
            , p_XxfaSnDataDetails.PRL_ORACLE_CR
            , p_XxfaSnDataDetails.PRL_ORACLE_CR_SUPERIOR
            , p_XxfaSnDataDetails.MCR_ORACLE_EF
            , p_XxfaSnDataDetails.OOH_HEADER_ID
            , p_XxfaSnDataDetails.OOH_ORDER_NUMBER
            , p_XxfaSnDataDetails.MMT_TRANSACTION_ID
            , p_XxfaSnDataDetails.MMT_CREATION_DATE
            , x_errors, x_retcode);
   END insert_row;

   /********************************************************************************************
   Modulo : delete_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 12/Ago/2025
   Descripcion : Insert Row sobre la tabla xxfc.xxfa_sn_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Ago/2025   CHG0101033      Version Inicial
   ********************************************************************************************/
    /*--------------------------delete_row-------------------------*/
   PROCEDURE delete_row (p_DATA_DETAIL_ID IN NUMBER
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
        
    BEGIN
        x_errors := '';
        DELETE FROM XXFA_SN_DATA_DETAILS
        WHERE DATA_DETAIL_ID = p_DATA_DETAIL_ID;
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
   Fecha : 12/Ago/2025
   Descripcion : Insert Row sobre la tabla xxfc.xxfa_sn_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Ago/2025   CHG0101033      Version Inicial
   ********************************************************************************************/
    /*--------------------------delete_row-------------------------*/
   PROCEDURE delete_row (p_XxfaSnDataDetails XXFA_SN_DATA_DETAILS%ROWTYPE
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
        
    BEGIN
        delete_row(p_XxfaSnDataDetails.DATA_DETAIL_ID
            , x_errors, x_retcode);
   END delete_row;


END xxfa_sn_data_details_pkg;
/
SHOW ERRORS;
