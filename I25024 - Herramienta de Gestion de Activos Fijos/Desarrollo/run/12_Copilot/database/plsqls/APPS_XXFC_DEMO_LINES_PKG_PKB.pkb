SET DEFINE OFF;
PROMPT PACKAGE BODY XXFC_DEMO_LINES_PKG
CREATE OR REPLACE PACKAGE BODY apps.xxfc_demo_lines_pkg AS

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
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
        recinfo XXFC_DEMO_LINES%ROWTYPE;
    BEGIN
        x_errors := '';
        x_retcode := 0;
        SELECT DEMO_LINE_ID, DEMO_ID, DEMO_LINE_NUMBER, CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY, LAST_UPDATE_LOGIN
          INTO recinfo.DEMO_LINE_ID, recinfo.DEMO_ID, recinfo.DEMO_LINE_NUMBER, recinfo.CREATION_DATE, recinfo.CREATED_BY, recinfo.LAST_UPDATE_DATE, recinfo.LAST_UPDATED_BY, recinfo.LAST_UPDATE_LOGIN
          FROM XXFC_DEMO_LINES
         WHERE ROWID = p_rowid
           FOR UPDATE NOWAIT;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
         x_retcode := 2;
         x_errors := 'THE RECORD WITH ROWID = ' || p_rowid || ' NO LONGER EXISTS IN TABLE XXFC_DEMO_LINES';
      WHEN OTHERS THEN
         x_retcode := 2;
         x_errors := SQLERRM;
    END lock_row;

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
           , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
        recinfo XXFC_DEMO_LINES%ROWTYPE;
    BEGIN
        x_errors := '';
        x_retcode := 0;
        SELECT *
          INTO recinfo
          FROM XXFC_DEMO_LINES
         WHERE ROWID = p_rowid
           FOR UPDATE NOWAIT;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
         x_retcode := 2;
         x_errors := 'THE RECORD WITH ROWID = ' || p_rowid || ' NO LONGER EXISTS IN TABLE XXFC_DEMO_LINES';
      WHEN OTHERS THEN
         x_retcode := 2;
         x_errors := SQLERRM;
    END lock_row;

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
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
    BEGIN
        x_errors := '';
        x_retcode := 0;
        UPDATE XXFC_DEMO_LINES
           SET DEMO_ID = NVL(p_DEMO_ID, DEMO_ID),
               DEMO_LINE_NUMBER = NVL(p_DEMO_LINE_NUMBER, DEMO_LINE_NUMBER),
               CREATION_DATE = NVL(p_CREATION_DATE, CREATION_DATE),
               CREATED_BY = NVL(p_CREATED_BY, CREATED_BY),
               LAST_UPDATE_DATE = NVL(p_LAST_UPDATE_DATE, LAST_UPDATE_DATE),
               LAST_UPDATED_BY = NVL(p_LAST_UPDATED_BY, LAST_UPDATED_BY),
               LAST_UPDATE_LOGIN = NVL(p_LAST_UPDATE_LOGIN, LAST_UPDATE_LOGIN)
         WHERE DEMO_LINE_ID = p_DEMO_LINE_ID;
        IF SQL%ROWCOUNT = 0 THEN
           x_retcode := 2;
           x_errors := 'NO ROW UPDATED FOR DEMO_LINE_ID = ' || p_DEMO_LINE_ID;
        END IF;
    EXCEPTION
      WHEN OTHERS THEN
         x_retcode := 2;
         x_errors := SQLERRM;
    END update_row;

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
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
    BEGIN
        x_errors := '';
        x_retcode := 0;
        UPDATE XXFC_DEMO_LINES
           SET DEMO_ID = p_XxfcDemoLines.DEMO_ID,
               DEMO_LINE_NUMBER = p_XxfcDemoLines.DEMO_LINE_NUMBER,
               CREATION_DATE = p_XxfcDemoLines.CREATION_DATE,
               CREATED_BY = p_XxfcDemoLines.CREATED_BY,
               LAST_UPDATE_DATE = p_XxfcDemoLines.LAST_UPDATE_DATE,
               LAST_UPDATED_BY = p_XxfcDemoLines.LAST_UPDATED_BY,
               LAST_UPDATE_LOGIN = p_XxfcDemoLines.LAST_UPDATE_LOGIN
         WHERE DEMO_LINE_ID = p_XxfcDemoLines.DEMO_LINE_ID;
        IF SQL%ROWCOUNT = 0 THEN
           x_retcode := 2;
           x_errors := 'NO ROW UPDATED FOR DEMO_LINE_ID = ' || p_XxfcDemoLines.DEMO_LINE_ID;
        END IF;
    EXCEPTION
      WHEN OTHERS THEN
         x_retcode := 2;
         x_errors := SQLERRM;
    END update_row;

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
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
    BEGIN
        x_errors := '';
        x_retcode := 0;
        INSERT INTO XXFC_DEMO_LINES (DEMO_LINE_ID, DEMO_ID, DEMO_LINE_NUMBER, CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY, LAST_UPDATE_LOGIN)
        VALUES (p_DEMO_LINE_ID, p_DEMO_ID, p_DEMO_LINE_NUMBER, p_CREATION_DATE, p_CREATED_BY, p_LAST_UPDATE_DATE, p_LAST_UPDATED_BY, p_LAST_UPDATE_LOGIN)
        RETURNING ROWID INTO x_rowid;
    EXCEPTION
      WHEN OTHERS THEN
         x_retcode := 2;
         x_errors := SQLERRM;
    END insert_row;

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
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
    BEGIN
        x_errors := '';
        x_retcode := 0;
        INSERT INTO XXFC_DEMO_LINES (DEMO_LINE_ID, DEMO_ID, DEMO_LINE_NUMBER, CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY, LAST_UPDATE_LOGIN)
        VALUES (p_XxfcDemoLines.DEMO_LINE_ID, p_XxfcDemoLines.DEMO_ID, p_XxfcDemoLines.DEMO_LINE_NUMBER, p_XxfcDemoLines.CREATION_DATE, p_XxfcDemoLines.CREATED_BY, p_XxfcDemoLines.LAST_UPDATE_DATE, p_XxfcDemoLines.LAST_UPDATED_BY, p_XxfcDemoLines.LAST_UPDATE_LOGIN)
        RETURNING ROWID INTO x_rowid;
    EXCEPTION
      WHEN OTHERS THEN
         x_retcode := 2;
         x_errors := SQLERRM;
    END insert_row;

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
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
    BEGIN
        x_errors := '';
        x_retcode := 0;
        DELETE FROM XXFC_DEMO_LINES
         WHERE DEMO_LINE_ID = p_DEMO_LINE_ID;
        IF SQL%ROWCOUNT = 0 THEN
           x_retcode := 2;
           x_errors := 'NO ROW DELETED FOR DEMO_LINE_ID = ' || p_DEMO_LINE_ID;
        END IF;
    EXCEPTION
      WHEN OTHERS THEN
         x_retcode := 2;
         x_errors := SQLERRM;
    END delete_row;

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
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
    BEGIN
        x_errors := '';
        x_retcode := 0;
        DELETE FROM XXFC_DEMO_LINES
         WHERE DEMO_LINE_ID = p_XxfcDemoLines.DEMO_LINE_ID;
        IF SQL%ROWCOUNT = 0 THEN
           x_retcode := 2;
           x_errors := 'NO ROW DELETED FOR DEMO_LINE_ID = ' || p_XxfcDemoLines.DEMO_LINE_ID;
        END IF;
    EXCEPTION
      WHEN OTHERS THEN
         x_retcode := 2;
         x_errors := SQLERRM;
    END delete_row;

END apps.xxfc_demo_lines_pkg;
/

SHOW ERRORS;
/
SHOW ERRORS;
