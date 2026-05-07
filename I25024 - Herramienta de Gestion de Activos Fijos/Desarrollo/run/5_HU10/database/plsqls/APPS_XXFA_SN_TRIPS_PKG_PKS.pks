SET DEFINE OFF;
PROMPT PACKAGE XXFA_SN_TRIPS_PKG
CREATE OR REPLACE PACKAGE APPS.XXFA_SN_TRIPS_PKG AS 
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
   ********************************************************************************************/


   /********************************************************************************************
   Modulo : lock_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 12/Dic/2025
   Descripcion : Lock Row sobre la tabla xxfc.xxfa_sn_trips
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Dic/2025   CHG0135992      Version Inicial
   ********************************************************************************************/
   /*--------------------------lock_row-------------------------*/
   PROCEDURE lock_row (p_rowid ROWID
           ,p_SN_TRIP_DETAIL_ID IN NUMBER
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
           , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : lock_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 12/Dic/2025
   Descripcion : Lock Row sobre la tabla xxfc.xxfa_sn_trips
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Dic/2025   CHG0135992      Version Inicial
   ********************************************************************************************/
   /*--------------------------lock_row-------------------------*/
   PROCEDURE lock_row (p_rowid ROWID
           , p_XxfaSnTrips XXFA_SN_TRIPS%ROWTYPE
           , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : update_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 12/Dic/2025
   Descripcion : Update Row sobre la tabla xxfc.xxfa_sn_trips
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Dic/2025   CHG0135992      Version Inicial
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
           , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : update_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 12/Dic/2025
   Descripcion : Update Row sobre la tabla xxfc.xxfa_sn_trips
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Dic/2025   CHG0135992      Version Inicial
   ********************************************************************************************/
   /*--------------------------update_row-------------------------*/
   PROCEDURE update_row (p_XxfaSnTrips XXFA_SN_TRIPS%ROWTYPE
           , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : insert_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 12/Dic/2025
   Descripcion : Insert Row sobre la tabla xxfc.xxfa_sn_trips
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Dic/2025   CHG0135992      Version Inicial
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
           , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : insert_row
   Autor : Gilberto Hernandez (Hexaware) 
   Fecha : 12/Dic/2025
   Descripcion : Insert Row sobre la tabla xxfc.xxfa_sn_trips
   Modificado Por       Fecha                    Codigo          Descripcion
   --------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  12/Dic/2025   CHG0135992      Version Inicial
   ********************************************************************************************/
   /*--------------------------insert_row-------------------------*/
   PROCEDURE insert_row(x_rowid OUT ROWID
           , p_XxfaSnTrips XXFA_SN_TRIPS%ROWTYPE
           , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

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
           , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

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
           , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);
END XXFA_SN_TRIPS_PKG;
/
SHOW ERRORS