SET DEFINE OFF;
PROMPT PACKAGE BODY XXFA_SN_TRIPS_PKG
CREATE OR REPLACE PACKAGE BODY APPS.XXFA_SN_TRIPS_PKG 
AS 
   /********************************************************************************************
   * Modulo : XXFA_SN_TRIPS_PKG
   * Autor : Gilberto Hernandez (Hexaware) 
   * Version : 1.0
   * Fecha : 12/Dic/2025
   * Descripcion : Table Handler para la tabla xxfc.xxfa_sn_trips
   *
   * Ejecutado Por :
   *
   * Ejecuciones :
   *
   * Modificado Por                 Fecha         Codigo          Descripcion
   * -------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Dic/2025   CHG0135992      Version Inicial
   * Gilberto Hernandez (Hexaware)  16/Ene/2026   CHG0137347      Agregar las columnas prl_oracle_cr_superior, prl_oracle_cr, prl_requistor_full_name, prh_solicitud_inversion
   ********************************************************************************************/


   /********************************************************************************************
   Modulo : lock_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 12/Dic/2025
   Descripcion : Lock Row sobre la tabla xxfc.xxfa_sn_trips
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Dic/2025   CHG0135992      Version Inicial
   * Gilberto Hernandez (Hexaware)  16/Ene/2026   CHG0137347      Agregar las columnas prl_oracle_cr_superior, prl_oracle_cr, prl_requistor_full_name, prh_solicitud_inversion
   ********************************************************************************************/


   /*--------------------------lock_row-------------------------*/
   PROCEDURE lock_row (p_rowid ROWID
           , p_SN_TRIP_DETAIL_ID IN NUMBER
           , p_SN_TRIP_ID IN NUMBER
           , p_WST_TRIP_ID IN NUMBER
           , p_WST_TRIP_NAME IN VARCHAR2
           , p_MSI_ITEM_NUMBER IN VARCHAR2
           , p_MSI_ITEM_DESCRIPTION IN VARCHAR2
           , p_WDD_SHIPPED_QUANTITY IN NUMBER
           , p_OOH_HEADER_ID IN NUMBER
           , p_OOH_ORDER_NUMBER IN NUMBER
           , p_OOL_LINE_ID IN NUMBER
           , p_SHIP_CONFIRM_FLAG IN VARCHAR2
           , p_WND_CONFIRM_DATE IN DATE
           , p_WT_STATUS_CODE IN VARCHAR2
           , p_WDD_RELEASED_STATUS IN VARCHAR2
		   , p_PRL_ORACLE_CR_SUPERIOR IN VARCHAR2
		   , p_PRL_ORACLE_CR IN VARCHAR2
		   , p_PRL_REQUISTOR_FULL_NAME IN VARCHAR2
		   , p_PRH_SOLICITUD_INVERSION IN VARCHAR2
           , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
       
       CURSOR c IS SELECT 
           SN_TRIP_DETAIL_ID
           , SN_TRIP_ID
           , WST_TRIP_ID
           , WST_TRIP_NAME
           , MSI_ITEM_NUMBER
           , MSI_ITEM_DESCRIPTION
           , WDD_SHIPPED_QUANTITY
           , OOH_HEADER_ID
           , OOH_ORDER_NUMBER
           , OOL_LINE_ID
           , SHIP_CONFIRM_FLAG
           , WND_CONFIRM_DATE
           , WT_STATUS_CODE
           , WDD_RELEASED_STATUS
		   , PRL_ORACLE_CR_SUPERIOR 
		   , PRL_ORACLE_CR
		   , PRL_REQUISTOR_FULL_NAME
		   , PRH_SOLICITUD_INVERSION
           FROM XXFA_SN_TRIPS
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
           x_errors := 'THE RECORD WITH ROWID = ' || p_rowid || ' NO LONGER EXISTS IN TABLE XXFA_SN_TRIPS';
       ELSIF (NOT (((recinfo.SN_TRIP_DETAIL_ID = p_SN_TRIP_DETAIL_ID) OR (recinfo.SN_TRIP_DETAIL_ID IS NULL AND p_SN_TRIP_DETAIL_ID IS NULL))
               AND ((recinfo.SN_TRIP_ID = p_SN_TRIP_ID) OR (recinfo.SN_TRIP_ID IS NULL AND p_SN_TRIP_ID IS NULL))
               AND ((recinfo.WST_TRIP_ID = p_WST_TRIP_ID) OR (recinfo.WST_TRIP_ID IS NULL AND p_WST_TRIP_ID IS NULL))
               AND ((recinfo.WST_TRIP_NAME = p_WST_TRIP_NAME) OR (recinfo.WST_TRIP_NAME IS NULL AND p_WST_TRIP_NAME IS NULL))
               AND ((recinfo.MSI_ITEM_NUMBER = p_MSI_ITEM_NUMBER) OR (recinfo.MSI_ITEM_NUMBER IS NULL AND p_MSI_ITEM_NUMBER IS NULL))
               AND ((recinfo.MSI_ITEM_DESCRIPTION = p_MSI_ITEM_DESCRIPTION) OR (recinfo.MSI_ITEM_DESCRIPTION IS NULL AND p_MSI_ITEM_DESCRIPTION IS NULL))
               AND ((recinfo.WDD_SHIPPED_QUANTITY = p_WDD_SHIPPED_QUANTITY) OR (recinfo.WDD_SHIPPED_QUANTITY IS NULL AND p_WDD_SHIPPED_QUANTITY IS NULL))
               AND ((recinfo.OOH_HEADER_ID = p_OOH_HEADER_ID) OR (recinfo.OOH_HEADER_ID IS NULL AND p_OOH_HEADER_ID IS NULL))
               AND ((recinfo.OOH_ORDER_NUMBER = p_OOH_ORDER_NUMBER) OR (recinfo.OOH_ORDER_NUMBER IS NULL AND p_OOH_ORDER_NUMBER IS NULL))
               AND ((recinfo.OOL_LINE_ID = p_OOL_LINE_ID) OR (recinfo.OOL_LINE_ID IS NULL AND p_OOL_LINE_ID IS NULL))
               AND ((recinfo.SHIP_CONFIRM_FLAG = p_SHIP_CONFIRM_FLAG) OR (recinfo.SHIP_CONFIRM_FLAG IS NULL AND p_SHIP_CONFIRM_FLAG IS NULL))
               AND ((recinfo.WND_CONFIRM_DATE = p_WND_CONFIRM_DATE) OR (recinfo.WND_CONFIRM_DATE IS NULL AND p_WND_CONFIRM_DATE IS NULL))
               AND ((recinfo.WT_STATUS_CODE = p_WT_STATUS_CODE) OR (recinfo.WT_STATUS_CODE IS NULL AND p_WT_STATUS_CODE IS NULL))
               AND ((recinfo.WDD_RELEASED_STATUS = p_WDD_RELEASED_STATUS) OR (recinfo.WDD_RELEASED_STATUS IS NULL AND p_WDD_RELEASED_STATUS IS NULL))
			   AND ((recinfo.PRL_ORACLE_CR_SUPERIOR = p_PRL_ORACLE_CR_SUPERIOR) OR (recinfo.PRL_ORACLE_CR_SUPERIOR IS NULL AND p_PRL_ORACLE_CR_SUPERIOR IS NULL))
			   AND ((recinfo.PRL_ORACLE_CR = p_PRL_ORACLE_CR) OR (recinfo.PRL_ORACLE_CR IS NULL AND p_PRL_ORACLE_CR IS NULL))
			   AND ((recinfo.PRL_REQUISTOR_FULL_NAME = p_PRL_REQUISTOR_FULL_NAME) OR (recinfo.PRL_REQUISTOR_FULL_NAME IS NULL AND p_PRL_REQUISTOR_FULL_NAME IS NULL))
               AND ((recinfo.PRH_SOLICITUD_INVERSION = p_PRH_SOLICITUD_INVERSION) OR (recinfo.PRH_SOLICITUD_INVERSION IS NULL AND p_PRH_SOLICITUD_INVERSION IS NULL))			   
			   )) THEN
           x_retcode := 2;
           x_errors := 'THE RECORD WITH ROWID = ' || p_rowid || ' IN TABLE XXFA_SN_TRIPS HAS CHANGED.';
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
   Fecha : 12/Dic/2025
   Descripcion : Lock Row sobre la tabla xxfc.xxfa_sn_trips
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Dic/2025   CHG0135992      Version Inicial
   * Gilberto Hernandez (Hexaware)  16/Ene/2026   CHG0137347      Agregar las columnas prl_oracle_cr_superior, prl_oracle_cr, prl_requistor_full_name, prh_solicitud_inversion
   ********************************************************************************************/
   /*--------------------------lock_row-------------------------*/
   PROCEDURE lock_row (p_rowid ROWID
           , p_XxfaSnTrips XXFA_SN_TRIPS%ROWTYPE
           , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
       
   BEGIN
       lock_row(p_rowid
           , p_XxfaSnTrips.SN_TRIP_DETAIL_ID
           , p_XxfaSnTrips.SN_TRIP_ID
           , p_XxfaSnTrips.WST_TRIP_ID
           , p_XxfaSnTrips.WST_TRIP_NAME
           , p_XxfaSnTrips.MSI_ITEM_NUMBER
           , p_XxfaSnTrips.MSI_ITEM_DESCRIPTION
           , p_XxfaSnTrips.WDD_SHIPPED_QUANTITY
           , p_XxfaSnTrips.OOH_HEADER_ID
           , p_XxfaSnTrips.OOH_ORDER_NUMBER
           , p_XxfaSnTrips.OOL_LINE_ID
           , p_XxfaSnTrips.SHIP_CONFIRM_FLAG
           , p_XxfaSnTrips.WND_CONFIRM_DATE
           , p_XxfaSnTrips.WT_STATUS_CODE
           , p_XxfaSnTrips.WDD_RELEASED_STATUS
		   , p_XxfaSnTrips.PRL_ORACLE_CR_SUPERIOR
		   , p_XxfaSnTrips.PRL_ORACLE_CR
		   , p_XxfaSnTrips.PRL_REQUISTOR_FULL_NAME
		   , p_XxfaSnTrips.PRH_SOLICITUD_INVERSION
           , x_errors, x_retcode);
   END lock_row;

   /********************************************************************************************
   Modulo : update_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 12/Dic/2025
   Descripcion : Update Row sobre la tabla xxfc.xxfa_sn_trips
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Dic/2025   CHG0135992      Version Inicial
   * Gilberto Hernandez (Hexaware)  16/Ene/2026   CHG0137347      Agregar las columnas prl_oracle_cr_superior, prl_oracle_cr, prl_requistor_full_name, prh_solicitud_inversion
   ********************************************************************************************/
   /*--------------------------update_row-------------------------*/
   PROCEDURE update_row (p_SN_TRIP_DETAIL_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
           , p_SN_TRIP_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
           , p_WST_TRIP_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
           , p_WST_TRIP_NAME IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
           , p_MSI_ITEM_NUMBER IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
           , p_MSI_ITEM_DESCRIPTION IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
           , p_WDD_SHIPPED_QUANTITY IN NUMBER DEFAULT FND_API.G_MISS_NUM
           , p_OOH_HEADER_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
           , p_OOH_ORDER_NUMBER IN NUMBER DEFAULT FND_API.G_MISS_NUM
           , p_OOL_LINE_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
           , p_SHIP_CONFIRM_FLAG IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
           , p_WND_CONFIRM_DATE IN DATE DEFAULT FND_API.G_MISS_DATE
           , p_WT_STATUS_CODE IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
           , p_WDD_RELEASED_STATUS IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
		   , p_PRL_ORACLE_CR_SUPERIOR IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
		   , p_PRL_ORACLE_CR IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
		   , p_PRL_REQUISTOR_FULL_NAME IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
           , p_PRH_SOLICITUD_INVERSION IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR		   
           , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
       
   BEGIN
       x_errors := '';
       UPDATE XXFA_SN_TRIPS SET SN_TRIP_DETAIL_ID = DECODE(p_SN_TRIP_DETAIL_ID, FND_API.G_MISS_NUM, SN_TRIP_DETAIL_ID, p_SN_TRIP_DETAIL_ID)
           , SN_TRIP_ID = DECODE(p_SN_TRIP_ID, FND_API.G_MISS_NUM, SN_TRIP_ID, p_SN_TRIP_ID)
           , WST_TRIP_ID = DECODE(p_WST_TRIP_ID, FND_API.G_MISS_NUM, WST_TRIP_ID, p_WST_TRIP_ID)
           , WST_TRIP_NAME = DECODE(p_WST_TRIP_NAME, FND_API.G_MISS_CHAR, WST_TRIP_NAME, p_WST_TRIP_NAME)
           , MSI_ITEM_NUMBER = DECODE(p_MSI_ITEM_NUMBER, FND_API.G_MISS_CHAR, MSI_ITEM_NUMBER, p_MSI_ITEM_NUMBER)
           , MSI_ITEM_DESCRIPTION = DECODE(p_MSI_ITEM_DESCRIPTION, FND_API.G_MISS_CHAR, MSI_ITEM_DESCRIPTION, p_MSI_ITEM_DESCRIPTION)
           , WDD_SHIPPED_QUANTITY = DECODE(p_WDD_SHIPPED_QUANTITY, FND_API.G_MISS_NUM, WDD_SHIPPED_QUANTITY, p_WDD_SHIPPED_QUANTITY)
           , OOH_HEADER_ID = DECODE(p_OOH_HEADER_ID, FND_API.G_MISS_NUM, OOH_HEADER_ID, p_OOH_HEADER_ID)
           , OOH_ORDER_NUMBER = DECODE(p_OOH_ORDER_NUMBER, FND_API.G_MISS_NUM, OOH_ORDER_NUMBER, p_OOH_ORDER_NUMBER)
           , OOL_LINE_ID = DECODE(p_OOL_LINE_ID, FND_API.G_MISS_NUM, OOL_LINE_ID, p_OOL_LINE_ID)
           , SHIP_CONFIRM_FLAG = DECODE(p_SHIP_CONFIRM_FLAG, FND_API.G_MISS_CHAR, SHIP_CONFIRM_FLAG, p_SHIP_CONFIRM_FLAG)
           , WND_CONFIRM_DATE = DECODE(p_WND_CONFIRM_DATE, FND_API.G_MISS_DATE, WND_CONFIRM_DATE, p_WND_CONFIRM_DATE)
           , WT_STATUS_CODE = DECODE(p_WT_STATUS_CODE, FND_API.G_MISS_CHAR, WT_STATUS_CODE, p_WT_STATUS_CODE)
           , WDD_RELEASED_STATUS = DECODE(p_WDD_RELEASED_STATUS, FND_API.G_MISS_CHAR, WDD_RELEASED_STATUS, p_WDD_RELEASED_STATUS)
		   , PRL_ORACLE_CR_SUPERIOR = DECODE(p_PRL_ORACLE_CR_SUPERIOR, FND_API.G_MISS_CHAR, PRL_ORACLE_CR_SUPERIOR, p_PRL_ORACLE_CR_SUPERIOR)
		   , PRL_ORACLE_CR = DECODE(p_PRL_ORACLE_CR, FND_API.G_MISS_CHAR, PRL_ORACLE_CR, p_PRL_ORACLE_CR)
		   , PRL_REQUISTOR_FULL_NAME = DECODE(p_PRL_REQUISTOR_FULL_NAME, FND_API.G_MISS_CHAR, PRL_REQUISTOR_FULL_NAME, p_PRL_REQUISTOR_FULL_NAME)
		   , PRH_SOLICITUD_INVERSION = DECODE(p_PRH_SOLICITUD_INVERSION, FND_API.G_MISS_CHAR, PRH_SOLICITUD_INVERSION, p_PRH_SOLICITUD_INVERSION)
           , LAST_UPDATE_LOGIN = FND_PROFILE.value('LOGIN_ID')
           , LAST_UPDATE_DATE = SYSDATE
           , LAST_UPDATED_BY = FND_PROFILE.value('USER_ID')
       WHERE SN_TRIP_DETAIL_ID = p_SN_TRIP_DETAIL_ID;
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
   Fecha : 12/Dic/2025
   Descripcion : Update Row sobre la tabla xxfc.xxfa_sn_trips
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Dic/2025   CHG0135992      Version Inicial
   * Gilberto Hernandez (Hexaware)  16/Ene/2026   CHG0137347      Agregar las columnas prl_oracle_cr_superior, prl_oracle_cr, prl_requistor_full_name, prh_solicitud_inversion
   ********************************************************************************************/
   /*--------------------------update_row-------------------------*/
   PROCEDURE update_row (p_XxfaSnTrips XXFA_SN_TRIPS%ROWTYPE
           , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
       
   BEGIN
       update_row(p_XxfaSnTrips.SN_TRIP_DETAIL_ID
           , p_XxfaSnTrips.SN_TRIP_ID
           , p_XxfaSnTrips.WST_TRIP_ID
           , p_XxfaSnTrips.WST_TRIP_NAME
           , p_XxfaSnTrips.MSI_ITEM_NUMBER
           , p_XxfaSnTrips.MSI_ITEM_DESCRIPTION
           , p_XxfaSnTrips.WDD_SHIPPED_QUANTITY
           , p_XxfaSnTrips.OOH_HEADER_ID
           , p_XxfaSnTrips.OOH_ORDER_NUMBER
           , p_XxfaSnTrips.OOL_LINE_ID
           , p_XxfaSnTrips.SHIP_CONFIRM_FLAG
           , p_XxfaSnTrips.WND_CONFIRM_DATE
           , p_XxfaSnTrips.WT_STATUS_CODE
           , p_XxfaSnTrips.WDD_RELEASED_STATUS
		   , p_XxfaSnTrips.PRL_ORACLE_CR_SUPERIOR
		   , p_XxfaSnTrips.PRL_ORACLE_CR
		   , p_XxfaSnTrips.PRL_REQUISTOR_FULL_NAME
		   , p_XxfaSnTrips.PRH_SOLICITUD_INVERSION
           , x_errors, x_retcode);
   END update_row;

   /********************************************************************************************
   Modulo : insert_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 12/Dic/2025
   Descripcion : Insert Row sobre la tabla xxfc.xxfa_sn_trips
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Dic/2025   CHG0135992      Version Inicial
   * Gilberto Hernandez (Hexaware)  16/Ene/2026   CHG0137347      Agregar las columnas prl_oracle_cr_superior, prl_oracle_cr, prl_requistor_full_name, prh_solicitud_inversion
   ********************************************************************************************/
   /*--------------------------insert_row-------------------------*/
   PROCEDURE insert_row(x_rowid OUT ROWID
           , p_SN_TRIP_ID IN NUMBER
           , p_WST_TRIP_ID IN NUMBER
           , p_WST_TRIP_NAME IN VARCHAR2
           , p_MSI_ITEM_NUMBER IN VARCHAR2
           , p_MSI_ITEM_DESCRIPTION IN VARCHAR2
           , p_WDD_SHIPPED_QUANTITY IN NUMBER
           , p_OOH_HEADER_ID IN NUMBER
           , p_OOH_ORDER_NUMBER IN NUMBER
           , p_OOL_LINE_ID IN NUMBER
           , p_SHIP_CONFIRM_FLAG IN VARCHAR2
           , p_WND_CONFIRM_DATE IN DATE
           , p_WT_STATUS_CODE IN VARCHAR2
           , p_WDD_RELEASED_STATUS IN VARCHAR2
		   , p_PRL_ORACLE_CR_SUPERIOR IN VARCHAR2
		   , p_PRL_ORACLE_CR IN VARCHAR2
		   , p_PRL_REQUISTOR_FULL_NAME IN VARCHAR2
		   , p_PRH_SOLICITUD_INVERSION IN VARCHAR2
           , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
       
   BEGIN
       x_errors := '';
       INSERT INTO XXFA_SN_TRIPS(
             SN_TRIP_ID
           , WST_TRIP_ID
           , WST_TRIP_NAME
           , MSI_ITEM_NUMBER
           , MSI_ITEM_DESCRIPTION
           , WDD_SHIPPED_QUANTITY
           , OOH_HEADER_ID
           , OOH_ORDER_NUMBER
           , OOL_LINE_ID
           , SHIP_CONFIRM_FLAG
           , WND_CONFIRM_DATE
           , WT_STATUS_CODE
           , WDD_RELEASED_STATUS
           , PRL_ORACLE_CR_SUPERIOR
           , PRL_ORACLE_CR
           , PRL_REQUISTOR_FULL_NAME
		   , PRH_SOLICITUD_INVERSION
           , LAST_UPDATE_LOGIN
           , CREATION_DATE
           , CREATED_BY
           , LAST_UPDATE_DATE
           , LAST_UPDATED_BY) VALUES (
             p_SN_TRIP_ID
           , p_WST_TRIP_ID
           , p_WST_TRIP_NAME
           , p_MSI_ITEM_NUMBER
           , p_MSI_ITEM_DESCRIPTION
           , p_WDD_SHIPPED_QUANTITY
           , p_OOH_HEADER_ID
           , p_OOH_ORDER_NUMBER
           , p_OOL_LINE_ID
           , p_SHIP_CONFIRM_FLAG
           , p_WND_CONFIRM_DATE
           , p_WT_STATUS_CODE
           , p_WDD_RELEASED_STATUS
           , p_PRL_ORACLE_CR_SUPERIOR
           , p_PRL_ORACLE_CR
           , p_PRL_REQUISTOR_FULL_NAME
		   , p_PRH_SOLICITUD_INVERSION
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
   Fecha : 12/Dic/2025
   Descripcion : Insert Row sobre la tabla xxfc.xxfa_sn_trips
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Dic/2025   CHG0135992      Version Inicial
   * Gilberto Hernandez (Hexaware)  16/Ene/2026   CHG0137347      Agregar las columnas prl_oracle_cr_superior, prl_oracle_cr, prl_requistor_full_name, prh_solicitud_inversion
   ********************************************************************************************/
   /*--------------------------insert_row-------------------------*/
   PROCEDURE insert_row(x_rowid OUT ROWID
           , p_XxfaSnTrips XXFA_SN_TRIPS%ROWTYPE
           , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
       
   BEGIN
       insert_row(x_rowid 
           , p_XxfaSnTrips.SN_TRIP_ID
           , p_XxfaSnTrips.WST_TRIP_ID
           , p_XxfaSnTrips.WST_TRIP_NAME
           , p_XxfaSnTrips.MSI_ITEM_NUMBER
           , p_XxfaSnTrips.MSI_ITEM_DESCRIPTION
           , p_XxfaSnTrips.WDD_SHIPPED_QUANTITY
           , p_XxfaSnTrips.OOH_HEADER_ID
           , p_XxfaSnTrips.OOH_ORDER_NUMBER
           , p_XxfaSnTrips.OOL_LINE_ID
           , p_XxfaSnTrips.SHIP_CONFIRM_FLAG
           , p_XxfaSnTrips.WND_CONFIRM_DATE
           , p_XxfaSnTrips.WT_STATUS_CODE
           , p_XxfaSnTrips.WDD_RELEASED_STATUS
		   , p_XxfaSnTrips.PRL_ORACLE_CR_SUPERIOR
		   , p_XxfaSnTrips.PRL_ORACLE_CR
		   , p_XxfaSnTrips.PRL_REQUISTOR_FULL_NAME
		   , p_XxfaSnTrips.PRH_SOLICITUD_INVERSION
           , x_errors, x_retcode);
   END insert_row;

   /********************************************************************************************
   Modulo : delete_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 12/Dic/2025
   Descripcion : Delete Row sobre la tabla xxfc.xxfa_sn_trips
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Dic/2025   CHG0135992      Version Inicial
   ********************************************************************************************/
   /*--------------------------delete_row-------------------------*/
   PROCEDURE delete_row (p_SN_TRIP_DETAIL_ID IN NUMBER
           , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
       
   BEGIN
       x_errors := '';
       DELETE FROM XXFA_SN_TRIPS
       WHERE SN_TRIP_DETAIL_ID = p_SN_TRIP_DETAIL_ID;
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
   Fecha : 12/Dic/2025
   Descripcion : Delete Row sobre la tabla xxfc.xxfa_sn_trips
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Dic/2025   CHG0135992      Version Inicial
   ********************************************************************************************/
   /*--------------------------delete_row-------------------------*/
   PROCEDURE delete_row (p_XxfaSnTrips XXFA_SN_TRIPS%ROWTYPE
           , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
       
   BEGIN
       delete_row(p_XxfaSnTrips.SN_TRIP_DETAIL_ID
           , x_errors, x_retcode);
   END delete_row;


END XXFA_SN_TRIPS_PKG;
/
SHOW ERRORS;
