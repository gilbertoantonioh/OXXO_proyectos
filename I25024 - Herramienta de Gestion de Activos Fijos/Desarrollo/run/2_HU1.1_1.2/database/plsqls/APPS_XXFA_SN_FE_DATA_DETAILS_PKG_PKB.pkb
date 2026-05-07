SET DEFINE OFF;
PROMPT PACKAGE BODY XXFA_SN_FE_DATA_DETAILS_PKG
CREATE OR REPLACE PACKAGE BODY XXFA_SN_FE_DATA_DETAILS_PKG AS 

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
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
		
		CURSOR c IS SELECT 
			FE_DATA_DETAIL_ID
			, RCV_INVOICE_NUM
			, RCV_PO_HEADER_ID
			, POH_ORG_ID
			, AP_ORG_COMPANY_RFC
			, AP_ORG_COMPANY_NAME
			, RCV_VENDOR_ID
			, ASU_VENDOR_NUMBER
			, ASU_VENDOR_NAME
			, RSL_ITEM_ID
			, MSI_ITEM_NUMBER
			, RCV_SHIPMENT_HEADER_ID
			, RSH_RECEIPT_NUM
			, RCV_SHIPMENT_LINE_ID
			, RSL_ITEM_DESCRIPTION
			, RCV_QUANTITY
			, RCV_TRANSACTION_ID
			, RCV_PO_UNIT_PRICE
			, RCV_CURRENCY_CODE
			, RCV_CURRENCY_CONVERSION_RATE
			, LAST_UPDATE_LOGIN
			FROM XXFA_SN_FE_DATA_DETAILS
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
			x_errors := 'THE RECORD WITH ROWID = ' || p_rowid || ' NO LONGER EXISTS IN TABLE XXFA_SN_FE_DATA_DETAILS';
		ELSIF (NOT (((recinfo.FE_DATA_DETAIL_ID = p_FE_DATA_DETAIL_ID) OR (recinfo.FE_DATA_DETAIL_ID IS NULL AND p_FE_DATA_DETAIL_ID IS NULL))
				AND ((recinfo.RCV_INVOICE_NUM = p_RCV_INVOICE_NUM) OR (recinfo.RCV_INVOICE_NUM IS NULL AND p_RCV_INVOICE_NUM IS NULL))
				AND ((recinfo.RCV_PO_HEADER_ID = p_RCV_PO_HEADER_ID) OR (recinfo.RCV_PO_HEADER_ID IS NULL AND p_RCV_PO_HEADER_ID IS NULL))
				AND ((recinfo.POH_ORG_ID = p_POH_ORG_ID) OR (recinfo.POH_ORG_ID IS NULL AND p_POH_ORG_ID IS NULL))
				AND ((recinfo.AP_ORG_COMPANY_RFC = p_AP_ORG_COMPANY_RFC) OR (recinfo.AP_ORG_COMPANY_RFC IS NULL AND p_AP_ORG_COMPANY_RFC IS NULL))
				AND ((recinfo.AP_ORG_COMPANY_NAME = p_AP_ORG_COMPANY_NAME) OR (recinfo.AP_ORG_COMPANY_NAME IS NULL AND p_AP_ORG_COMPANY_NAME IS NULL))
				AND ((recinfo.RCV_VENDOR_ID = p_RCV_VENDOR_ID) OR (recinfo.RCV_VENDOR_ID IS NULL AND p_RCV_VENDOR_ID IS NULL))
				AND ((recinfo.ASU_VENDOR_NUMBER = p_ASU_VENDOR_NUMBER) OR (recinfo.ASU_VENDOR_NUMBER IS NULL AND p_ASU_VENDOR_NUMBER IS NULL))
				AND ((recinfo.ASU_VENDOR_NAME = p_ASU_VENDOR_NAME) OR (recinfo.ASU_VENDOR_NAME IS NULL AND p_ASU_VENDOR_NAME IS NULL))
				AND ((recinfo.RSL_ITEM_ID = p_RSL_ITEM_ID) OR (recinfo.RSL_ITEM_ID IS NULL AND p_RSL_ITEM_ID IS NULL))
				AND ((recinfo.MSI_ITEM_NUMBER = p_MSI_ITEM_NUMBER) OR (recinfo.MSI_ITEM_NUMBER IS NULL AND p_MSI_ITEM_NUMBER IS NULL))
				AND ((recinfo.RCV_SHIPMENT_HEADER_ID = p_RCV_SHIPMENT_HEADER_ID) OR (recinfo.RCV_SHIPMENT_HEADER_ID IS NULL AND p_RCV_SHIPMENT_HEADER_ID IS NULL))
				AND ((recinfo.RSH_RECEIPT_NUM = p_RSH_RECEIPT_NUM) OR (recinfo.RSH_RECEIPT_NUM IS NULL AND p_RSH_RECEIPT_NUM IS NULL))
				AND ((recinfo.RCV_SHIPMENT_LINE_ID = p_RCV_SHIPMENT_LINE_ID) OR (recinfo.RCV_SHIPMENT_LINE_ID IS NULL AND p_RCV_SHIPMENT_LINE_ID IS NULL))
				AND ((recinfo.RSL_ITEM_DESCRIPTION = p_RSL_ITEM_DESCRIPTION) OR (recinfo.RSL_ITEM_DESCRIPTION IS NULL AND p_RSL_ITEM_DESCRIPTION IS NULL))
				AND ((recinfo.RCV_QUANTITY = p_RCV_QUANTITY) OR (recinfo.RCV_QUANTITY IS NULL AND p_RCV_QUANTITY IS NULL))
				AND ((recinfo.RCV_TRANSACTION_ID = p_RCV_TRANSACTION_ID) OR (recinfo.RCV_TRANSACTION_ID IS NULL AND p_RCV_TRANSACTION_ID IS NULL))
				AND ((recinfo.RCV_PO_UNIT_PRICE = p_RCV_PO_UNIT_PRICE) OR (recinfo.RCV_PO_UNIT_PRICE IS NULL AND p_RCV_PO_UNIT_PRICE IS NULL))
				AND ((recinfo.RCV_CURRENCY_CODE = p_RCV_CURRENCY_CODE) OR (recinfo.RCV_CURRENCY_CODE IS NULL AND p_RCV_CURRENCY_CODE IS NULL))
				AND ((recinfo.RCV_CURRENCY_CONVERSION_RATE = p_RCV_CURRENCY_CONVERSION_RATE) OR (recinfo.RCV_CURRENCY_CONVERSION_RATE IS NULL AND p_RCV_CURRENCY_CONVERSION_RATE IS NULL)))) THEN
			x_retcode := 2;
			x_errors := 'THE RECORD WITH ROWID = ' || p_rowid || ' IN TABLE XXFA_SN_FE_DATA_DETAILS HAS CHANGED.';
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
   Descripcion : Lock Row sobre la tabla xxfc.xxfa_sn_fe_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Version Inicial
   ********************************************************************************************/
	/*--------------------------lock_row-------------------------*/
	PROCEDURE lock_row (p_rowid ROWID
			, p_XxfaSnFeDataDetails XXFA_SN_FE_DATA_DETAILS%ROWTYPE
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
		
	BEGIN
		lock_row(p_rowid
			, p_XxfaSnFeDataDetails.FE_DATA_DETAIL_ID
			, p_XxfaSnFeDataDetails.RCV_INVOICE_NUM
			, p_XxfaSnFeDataDetails.RCV_PO_HEADER_ID
			, p_XxfaSnFeDataDetails.POH_ORG_ID
			, p_XxfaSnFeDataDetails.AP_ORG_COMPANY_RFC
			, p_XxfaSnFeDataDetails.AP_ORG_COMPANY_NAME
			, p_XxfaSnFeDataDetails.RCV_VENDOR_ID
			, p_XxfaSnFeDataDetails.ASU_VENDOR_NUMBER
			, p_XxfaSnFeDataDetails.ASU_VENDOR_NAME
			, p_XxfaSnFeDataDetails.RSL_ITEM_ID
			, p_XxfaSnFeDataDetails.MSI_ITEM_NUMBER
			, p_XxfaSnFeDataDetails.RCV_SHIPMENT_HEADER_ID
			, p_XxfaSnFeDataDetails.RSH_RECEIPT_NUM
			, p_XxfaSnFeDataDetails.RCV_SHIPMENT_LINE_ID
			, p_XxfaSnFeDataDetails.RSL_ITEM_DESCRIPTION
			, p_XxfaSnFeDataDetails.RCV_QUANTITY
			, p_XxfaSnFeDataDetails.RCV_TRANSACTION_ID
			, p_XxfaSnFeDataDetails.RCV_PO_UNIT_PRICE
			, p_XxfaSnFeDataDetails.RCV_CURRENCY_CODE
			, p_XxfaSnFeDataDetails.RCV_CURRENCY_CONVERSION_RATE
			, x_errors, x_retcode);
	END lock_row;

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
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
		
	BEGIN
		x_errors := '';
		UPDATE XXFA_SN_FE_DATA_DETAILS SET FE_DATA_DETAIL_ID = DECODE(p_FE_DATA_DETAIL_ID, FND_API.G_MISS_NUM, FE_DATA_DETAIL_ID, p_FE_DATA_DETAIL_ID)
			, RCV_INVOICE_NUM = DECODE(p_RCV_INVOICE_NUM, FND_API.G_MISS_CHAR, RCV_INVOICE_NUM, p_RCV_INVOICE_NUM)
			, RCV_PO_HEADER_ID = DECODE(p_RCV_PO_HEADER_ID, FND_API.G_MISS_NUM, RCV_PO_HEADER_ID, p_RCV_PO_HEADER_ID)
			, POH_ORG_ID = DECODE(p_POH_ORG_ID, FND_API.G_MISS_NUM, POH_ORG_ID, p_POH_ORG_ID)
			, AP_ORG_COMPANY_RFC = DECODE(p_AP_ORG_COMPANY_RFC, FND_API.G_MISS_CHAR, AP_ORG_COMPANY_RFC, p_AP_ORG_COMPANY_RFC)
			, AP_ORG_COMPANY_NAME = DECODE(p_AP_ORG_COMPANY_NAME, FND_API.G_MISS_CHAR, AP_ORG_COMPANY_NAME, p_AP_ORG_COMPANY_NAME)
			, RCV_VENDOR_ID = DECODE(p_RCV_VENDOR_ID, FND_API.G_MISS_NUM, RCV_VENDOR_ID, p_RCV_VENDOR_ID)
			, ASU_VENDOR_NUMBER = DECODE(p_ASU_VENDOR_NUMBER, FND_API.G_MISS_CHAR, ASU_VENDOR_NUMBER, p_ASU_VENDOR_NUMBER)
			, ASU_VENDOR_NAME = DECODE(p_ASU_VENDOR_NAME, FND_API.G_MISS_CHAR, ASU_VENDOR_NAME, p_ASU_VENDOR_NAME)
			, RSL_ITEM_ID = DECODE(p_RSL_ITEM_ID, FND_API.G_MISS_NUM, RSL_ITEM_ID, p_RSL_ITEM_ID)
			, MSI_ITEM_NUMBER = DECODE(p_MSI_ITEM_NUMBER, FND_API.G_MISS_CHAR, MSI_ITEM_NUMBER, p_MSI_ITEM_NUMBER)
			, RCV_SHIPMENT_HEADER_ID = DECODE(p_RCV_SHIPMENT_HEADER_ID, FND_API.G_MISS_NUM, RCV_SHIPMENT_HEADER_ID, p_RCV_SHIPMENT_HEADER_ID)
			, RSH_RECEIPT_NUM = DECODE(p_RSH_RECEIPT_NUM, FND_API.G_MISS_CHAR, RSH_RECEIPT_NUM, p_RSH_RECEIPT_NUM)
			, RCV_SHIPMENT_LINE_ID = DECODE(p_RCV_SHIPMENT_LINE_ID, FND_API.G_MISS_NUM, RCV_SHIPMENT_LINE_ID, p_RCV_SHIPMENT_LINE_ID)
			, RSL_ITEM_DESCRIPTION = DECODE(p_RSL_ITEM_DESCRIPTION, FND_API.G_MISS_CHAR, RSL_ITEM_DESCRIPTION, p_RSL_ITEM_DESCRIPTION)
			, RCV_QUANTITY = DECODE(p_RCV_QUANTITY, FND_API.G_MISS_NUM, RCV_QUANTITY, p_RCV_QUANTITY)
			, RCV_TRANSACTION_ID = DECODE(p_RCV_TRANSACTION_ID, FND_API.G_MISS_NUM, RCV_TRANSACTION_ID, p_RCV_TRANSACTION_ID)
			, RCV_PO_UNIT_PRICE = DECODE(p_RCV_PO_UNIT_PRICE, FND_API.G_MISS_NUM, RCV_PO_UNIT_PRICE, p_RCV_PO_UNIT_PRICE)
			, RCV_CURRENCY_CODE = DECODE(p_RCV_CURRENCY_CODE, FND_API.G_MISS_CHAR, RCV_CURRENCY_CODE, p_RCV_CURRENCY_CODE)
			, RCV_CURRENCY_CONVERSION_RATE = DECODE(p_RCV_CURRENCY_CONVERSION_RATE, FND_API.G_MISS_NUM, RCV_CURRENCY_CONVERSION_RATE, p_RCV_CURRENCY_CONVERSION_RATE)
			, LAST_UPDATE_LOGIN = FND_PROFILE.value('LOGIN_ID')
			, LAST_UPDATE_DATE = SYSDATE
			, LAST_UPDATED_BY = FND_PROFILE.value('USER_ID')
		WHERE FE_DATA_DETAIL_ID = p_FE_DATA_DETAIL_ID;
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
   Descripcion : Update Row sobre la tabla xxfc.xxfa_sn_fe_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Version Inicial
   ********************************************************************************************/
	/*--------------------------update_row-------------------------*/
	PROCEDURE update_row (p_XxfaSnFeDataDetails XXFA_SN_FE_DATA_DETAILS%ROWTYPE
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
		
	BEGIN
		update_row(p_XxfaSnFeDataDetails.FE_DATA_DETAIL_ID
			, p_XxfaSnFeDataDetails.RCV_INVOICE_NUM
			, p_XxfaSnFeDataDetails.RCV_PO_HEADER_ID
			, p_XxfaSnFeDataDetails.POH_ORG_ID
			, p_XxfaSnFeDataDetails.AP_ORG_COMPANY_RFC
			, p_XxfaSnFeDataDetails.AP_ORG_COMPANY_NAME
			, p_XxfaSnFeDataDetails.RCV_VENDOR_ID
			, p_XxfaSnFeDataDetails.ASU_VENDOR_NUMBER
			, p_XxfaSnFeDataDetails.ASU_VENDOR_NAME
			, p_XxfaSnFeDataDetails.RSL_ITEM_ID
			, p_XxfaSnFeDataDetails.MSI_ITEM_NUMBER
			, p_XxfaSnFeDataDetails.RCV_SHIPMENT_HEADER_ID
			, p_XxfaSnFeDataDetails.RSH_RECEIPT_NUM
			, p_XxfaSnFeDataDetails.RCV_SHIPMENT_LINE_ID
			, p_XxfaSnFeDataDetails.RSL_ITEM_DESCRIPTION
			, p_XxfaSnFeDataDetails.RCV_QUANTITY
			, p_XxfaSnFeDataDetails.RCV_TRANSACTION_ID
			, p_XxfaSnFeDataDetails.RCV_PO_UNIT_PRICE
			, p_XxfaSnFeDataDetails.RCV_CURRENCY_CODE
			, p_XxfaSnFeDataDetails.RCV_CURRENCY_CONVERSION_RATE
			, x_errors, x_retcode);
	END update_row;

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
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
		
	BEGIN
		x_errors := '';
		INSERT INTO XXFA_SN_FE_DATA_DETAILS(FE_DATA_DETAIL_ID
			, RCV_INVOICE_NUM
			, RCV_PO_HEADER_ID
			, POH_ORG_ID
			, AP_ORG_COMPANY_RFC
			, AP_ORG_COMPANY_NAME
			, RCV_VENDOR_ID
			, ASU_VENDOR_NUMBER
			, ASU_VENDOR_NAME
			, RSL_ITEM_ID
			, MSI_ITEM_NUMBER
			, RCV_SHIPMENT_HEADER_ID
			, RSH_RECEIPT_NUM
			, RCV_SHIPMENT_LINE_ID
			, RSL_ITEM_DESCRIPTION
			, RCV_QUANTITY
			, RCV_TRANSACTION_ID
			, RCV_PO_UNIT_PRICE
			, RCV_CURRENCY_CODE
			, RCV_CURRENCY_CONVERSION_RATE
			, LAST_UPDATE_LOGIN
			, CREATION_DATE
			, CREATED_BY
			, LAST_UPDATE_DATE
			, LAST_UPDATED_BY) VALUES (p_FE_DATA_DETAIL_ID
			, p_RCV_INVOICE_NUM
			, p_RCV_PO_HEADER_ID
			, p_POH_ORG_ID
			, p_AP_ORG_COMPANY_RFC
			, p_AP_ORG_COMPANY_NAME
			, p_RCV_VENDOR_ID
			, p_ASU_VENDOR_NUMBER
			, p_ASU_VENDOR_NAME
			, p_RSL_ITEM_ID
			, p_MSI_ITEM_NUMBER
			, p_RCV_SHIPMENT_HEADER_ID
			, p_RSH_RECEIPT_NUM
			, p_RCV_SHIPMENT_LINE_ID
			, p_RSL_ITEM_DESCRIPTION
			, p_RCV_QUANTITY
			, p_RCV_TRANSACTION_ID
			, p_RCV_PO_UNIT_PRICE
			, p_RCV_CURRENCY_CODE
			, p_RCV_CURRENCY_CONVERSION_RATE
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
   Descripcion : Insert Row sobre la tabla xxfc.xxfa_sn_fe_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Version Inicial
   ********************************************************************************************/
	/*--------------------------insert_row-------------------------*/
	PROCEDURE insert_row(x_rowid OUT ROWID
			, p_XxfaSnFeDataDetails XXFA_SN_FE_DATA_DETAILS%ROWTYPE
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
		
	BEGIN
		insert_row(x_rowid 
			, p_XxfaSnFeDataDetails.FE_DATA_DETAIL_ID
			, p_XxfaSnFeDataDetails.RCV_INVOICE_NUM
			, p_XxfaSnFeDataDetails.RCV_PO_HEADER_ID
			, p_XxfaSnFeDataDetails.POH_ORG_ID
			, p_XxfaSnFeDataDetails.AP_ORG_COMPANY_RFC
			, p_XxfaSnFeDataDetails.AP_ORG_COMPANY_NAME
			, p_XxfaSnFeDataDetails.RCV_VENDOR_ID
			, p_XxfaSnFeDataDetails.ASU_VENDOR_NUMBER
			, p_XxfaSnFeDataDetails.ASU_VENDOR_NAME
			, p_XxfaSnFeDataDetails.RSL_ITEM_ID
			, p_XxfaSnFeDataDetails.MSI_ITEM_NUMBER
			, p_XxfaSnFeDataDetails.RCV_SHIPMENT_HEADER_ID
			, p_XxfaSnFeDataDetails.RSH_RECEIPT_NUM
			, p_XxfaSnFeDataDetails.RCV_SHIPMENT_LINE_ID
			, p_XxfaSnFeDataDetails.RSL_ITEM_DESCRIPTION
			, p_XxfaSnFeDataDetails.RCV_QUANTITY
			, p_XxfaSnFeDataDetails.RCV_TRANSACTION_ID
			, p_XxfaSnFeDataDetails.RCV_PO_UNIT_PRICE
			, p_XxfaSnFeDataDetails.RCV_CURRENCY_CODE
			, p_XxfaSnFeDataDetails.RCV_CURRENCY_CONVERSION_RATE
			, x_errors, x_retcode);
	END insert_row;

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
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
		
	BEGIN
		x_errors := '';
		DELETE FROM XXFA_SN_FE_DATA_DETAILS
		WHERE FE_DATA_DETAIL_ID = p_FE_DATA_DETAIL_ID;
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
   Descripcion : Delete Row sobre la tabla xxfc.xxfa_sn_fe_data_details
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  15/Sep/2025   CHG0113888      Version Inicial
   ********************************************************************************************/
	/*--------------------------delete_row-------------------------*/
	PROCEDURE delete_row (p_XxfaSnFeDataDetails XXFA_SN_FE_DATA_DETAILS%ROWTYPE
			, x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
		
	BEGIN
		delete_row(p_XxfaSnFeDataDetails.FE_DATA_DETAIL_ID
			, x_errors, x_retcode);
	END delete_row;


END XXFA_SN_FE_DATA_DETAILS_PKG;
/
SHOW ERRORS;
