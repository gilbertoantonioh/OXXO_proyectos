SET DEFINE OFF;
PROMPT PACKAGE SPEC XXFC_DEMO_LINES_PKG
CREATE OR REPLACE PACKAGE apps.xxfc_demo_lines_pkg AS

   /********************************************************************************************
   * Modulo : XXFC_DEMO_LINES_PKG
   * Autor : Gilberto Hernandez (Hexaware)
   * Version : 1.0
   * Fecha : 07/May/2026
   * Descripcion : Table Handler para la tabla xxfc.xxFC_demo_lines
   *
   * Modificado Por                 Fecha         Change Order    Descripcion
   * -----------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  07/May/2026   CHOXXXXX        Creacion del Archivo
   ********************************************************************************************/

   /********************************************************************************************
   Modulo : lock_row
   Autor : Gilberto Hernandez (Hexaware)
   Fecha : 07/May/2026
   Descripcion : Lock Row sobre la tabla xxfc.xxFC_demo_lines
   Modificado Por                 Fecha         Change Order    Descripcion
   -----------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  07/May/2026   CHOXXXXX        Creacion del Archivo
   ********************************************************************************************/
   PROCEDURE lock_row (p_rowid ROWID
            , p_DEMO_LINE_ID IN NUMBER
            , p_DEMO_ID IN NUMBER
            , p_DEMO_LINE_NUMBER IN NUMBER
            , p_CREATION_DATE IN DATE
            , p_CREATED_BY IN VARCHAR2
            , p_LAST_UPDATE_DATE IN DATE
            , p_LAST_UPDATED_BY IN VARCHAR2
            , p_LAST_UPDATE_LOGIN IN VARCHAR2
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : lock_row
   Autor : Gilberto Hernandez (Hexaware)
   Fecha : 07/May/2026
   Descripcion : Lock Row sobre la tabla xxfc.xxFC_demo_lines
   Modificado Por                 Fecha         Change Order    Descripcion
   -----------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  07/May/2026   CHOXXXXX        Creacion del Archivo
   ********************************************************************************************/
   PROCEDURE lock_row (p_rowid ROWID
           , p_XxfcDemoLines XXFC_DEMO_LINES%ROWTYPE
           , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : update_row
   Autor : Gilberto Hernandez (Hexaware)
   Fecha : 07/May/2026
   Descripcion : Update Row sobre la tabla xxfc.xxFC_demo_lines
   Modificado Por                 Fecha         Change Order    Descripcion
   -----------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  07/May/2026   CHOXXXXX        Creacion del Archivo
   ********************************************************************************************/
   PROCEDURE update_row (p_DEMO_LINE_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
            , p_DEMO_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
            , p_DEMO_LINE_NUMBER IN NUMBER DEFAULT FND_API.G_MISS_NUM
            , p_CREATION_DATE IN DATE DEFAULT FND_API.G_MISS_DATE
            , p_CREATED_BY IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
            , p_LAST_UPDATE_DATE IN DATE DEFAULT FND_API.G_MISS_DATE
            , p_LAST_UPDATED_BY IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
            , p_LAST_UPDATE_LOGIN IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : update_row
   Autor : Gilberto Hernandez (Hexaware)
   Fecha : 07/May/2026
   Descripcion : Update Row sobre la tabla xxfc.xxFC_demo_lines
   Modificado Por                 Fecha         Change Order    Descripcion
   -----------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  07/May/2026   CHOXXXXX        Creacion del Archivo
   ********************************************************************************************/
   PROCEDURE update_row (p_XxfcDemoLines XXFC_DEMO_LINES%ROWTYPE
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : insert_row
   Autor : Gilberto Hernandez (Hexaware)
   Fecha : 07/May/2026
   Descripcion : Insert Row sobre la tabla xxfc.xxFC_demo_lines
   Modificado Por                 Fecha         Change Order    Descripcion
   -----------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  07/May/2026   CHOXXXXX        Creacion del Archivo
   ********************************************************************************************/
   PROCEDURE insert_row(x_rowid OUT ROWID
            , p_DEMO_LINE_ID IN NUMBER
            , p_DEMO_ID IN NUMBER
            , p_DEMO_LINE_NUMBER IN NUMBER
            , p_CREATION_DATE IN DATE DEFAULT SYSDATE
            , p_CREATED_BY IN VARCHAR2 DEFAULT USER
            , p_LAST_UPDATE_DATE IN DATE DEFAULT SYSDATE
            , p_LAST_UPDATED_BY IN VARCHAR2 DEFAULT USER
            , p_LAST_UPDATE_LOGIN IN VARCHAR2 DEFAULT NULL
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : insert_row
   Autor : Gilberto Hernandez (Hexaware)
   Fecha : 07/May/2026
   Descripcion : Insert Row sobre la tabla xxfc.xxFC_demo_lines
   Modificado Por                 Fecha         Change Order    Descripcion
   -----------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  07/May/2026   CHOXXXXX        Creacion del Archivo
   ********************************************************************************************/
   PROCEDURE insert_row(x_rowid OUT ROWID
            , p_XxfcDemoLines XXFC_DEMO_LINES%ROWTYPE
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : delete_row
   Autor : Gilberto Hernandez (Hexaware)
   Fecha : 07/May/2026
   Descripcion : Delete Row sobre la tabla xxfc.xxFC_demo_lines
   Modificado Por                 Fecha         Change Order    Descripcion
   -----------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  07/May/2026   CHOXXXXX        Creacion del Archivo
   ********************************************************************************************/
   PROCEDURE delete_row (p_DEMO_LINE_ID IN NUMBER
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

   /********************************************************************************************
   Modulo : delete_row
   Autor : Gilberto Hernandez (Hexaware)
   Fecha : 07/May/2026
   Descripcion : Delete Row sobre la tabla xxfc.xxFC_demo_lines
   Modificado Por                 Fecha         Change Order    Descripcion
   -----------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  07/May/2026   CHOXXXXX        Creacion del Archivo
   ********************************************************************************************/
   PROCEDURE delete_row (p_XxfcDemoLines XXFC_DEMO_LINES%ROWTYPE
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER);

END apps.xxfc_demo_lines_pkg;
/
SHOW ERRORS;
