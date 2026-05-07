SET DEFINE OFF;
PROMPT PACKAGE BODY XXFC_DEMOS_PKG
CREATE OR REPLACE PACKAGE BODY apps.xxfc_demos_pkg AS

   /********************************************************************************************
   * Modulo : XXFC_DEMOS_PKG
   * Autor : Gilberto Hernandez (Hexaware)
   * Version : 1.0
   * Fecha : 07/May/2026
   * Descripcion : Table Handler para la tabla xxfc.xxFC_demos
   *
   * Modificado Por                 Fecha         Change Order    Descripcion
   * -----------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  07/May/2026   CHOXXXXX        Creacion del Archivo
   ********************************************************************************************/

   /********************************************************************************************
   Modulo : lock_row
   Autor : Gilberto Hernandez (Hexaware)
   Fecha : 07/May/2026
   Descripcion : Lock Row sobre la tabla xxfc.xxFC_demos
   Modificado Por                 Fecha         Change Order    Descripcion
   -----------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  07/May/2026   CHOXXXXX        Creacion del Archivo
   ********************************************************************************************/
   PROCEDURE lock_row (p_rowid ROWID
            , p_DEMO_ID IN NUMBER
            , p_DEMO_NAME IN VARCHAR2
            , p_CREATION_DATE IN DATE
            , p_CREATED_BY IN VARCHAR2
            , p_LAST_UPDATE_DATE IN DATE
            , p_LAST_UPDATED_BY IN VARCHAR2
            , p_LAST_UPDATE_LOGIN IN VARCHAR2
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
        recinfo XXFC_DEMOS%ROWTYPE;
    BEGIN
        x_errors := '';
        x_retcode := 0;
        SELECT DEMO_ID, DEMO_NAME, CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY, LAST_UPDATE_LOGIN
          INTO recinfo.DEMO_ID, recinfo.DEMO_NAME, recinfo.CREATION_DATE, recinfo.CREATED_BY, recinfo.LAST_UPDATE_DATE, recinfo.LAST_UPDATED_BY, recinfo.LAST_UPDATE_LOGIN
          FROM XXFC_DEMOS
         WHERE ROWID = p_rowid
           FOR UPDATE NOWAIT;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
         x_retcode := 2;
         x_errors := 'THE RECORD WITH ROWID = ' || p_rowid || ' NO LONGER EXISTS IN TABLE XXFC_DEMOS';
      WHEN OTHERS THEN
         x_retcode := 2;
         x_errors := SQLERRM;
    END lock_row;

   /********************************************************************************************
   Modulo : lock_row
   Autor : Gilberto Hernandez (Hexaware)
   Fecha : 07/May/2026
   Descripcion : Lock Row sobre la tabla xxfc.xxFC_demos
   Modificado Por                 Fecha         Change Order    Descripcion
   -----------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  07/May/2026   CHOXXXXX        Creacion del Archivo
   ********************************************************************************************/
   PROCEDURE lock_row (p_rowid ROWID
           , p_XxfcDemos XXFC_DEMOS%ROWTYPE
           , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
        recinfo XXFC_DEMOS%ROWTYPE;
    BEGIN
        x_errors := '';
        x_retcode := 0;
        SELECT *
          INTO recinfo
          FROM XXFC_DEMOS
         WHERE ROWID = p_rowid
           FOR UPDATE NOWAIT;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
         x_retcode := 2;
         x_errors := 'THE RECORD WITH ROWID = ' || p_rowid || ' NO LONGER EXISTS IN TABLE XXFC_DEMOS';
      WHEN OTHERS THEN
         x_retcode := 2;
         x_errors := SQLERRM;
    END lock_row;

   /********************************************************************************************
   Modulo : update_row
   Autor : Gilberto Hernandez (Hexaware)
   Fecha : 07/May/2026
   Descripcion : Update Row sobre la tabla xxfc.xxFC_demos
   Modificado Por                 Fecha         Change Order    Descripcion
   -----------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  07/May/2026   CHOXXXXX        Creacion del Archivo
   ********************************************************************************************/
   PROCEDURE update_row (p_DEMO_ID IN NUMBER DEFAULT FND_API.G_MISS_NUM
            , p_DEMO_NAME IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
            , p_CREATION_DATE IN DATE DEFAULT FND_API.G_MISS_DATE
            , p_CREATED_BY IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
            , p_LAST_UPDATE_DATE IN DATE DEFAULT FND_API.G_MISS_DATE
            , p_LAST_UPDATED_BY IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
            , p_LAST_UPDATE_LOGIN IN VARCHAR2 DEFAULT FND_API.G_MISS_CHAR
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
    BEGIN
        x_errors := '';
        x_retcode := 0;
        UPDATE XXFC_DEMOS
           SET DEMO_NAME = NVL(p_DEMO_NAME, DEMO_NAME),
               CREATION_DATE = NVL(p_CREATION_DATE, CREATION_DATE),
               CREATED_BY = NVL(p_CREATED_BY, CREATED_BY),
               LAST_UPDATE_DATE = NVL(p_LAST_UPDATE_DATE, LAST_UPDATE_DATE),
               LAST_UPDATED_BY = NVL(p_LAST_UPDATED_BY, LAST_UPDATED_BY),
               LAST_UPDATE_LOGIN = NVL(p_LAST_UPDATE_LOGIN, LAST_UPDATE_LOGIN)
         WHERE DEMO_ID = p_DEMO_ID;
        IF SQL%ROWCOUNT = 0 THEN
           x_retcode := 2;
           x_errors := 'NO ROW UPDATED FOR DEMO_ID = ' || p_DEMO_ID;
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
   Descripcion : Update Row sobre la tabla xxfc.xxFC_demos
   Modificado Por                 Fecha         Change Order    Descripcion
   -----------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  07/May/2026   CHOXXXXX        Creacion del Archivo
   ********************************************************************************************/
   PROCEDURE update_row (p_XxfcDemos XXFC_DEMOS%ROWTYPE
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
    BEGIN
        x_errors := '';
        x_retcode := 0;
        UPDATE XXFC_DEMOS
           SET DEMO_NAME = p_XxfcDemos.DEMO_NAME,
               CREATION_DATE = p_XxfcDemos.CREATION_DATE,
               CREATED_BY = p_XxfcDemos.CREATED_BY,
               LAST_UPDATE_DATE = p_XxfcDemos.LAST_UPDATE_DATE,
               LAST_UPDATED_BY = p_XxfcDemos.LAST_UPDATED_BY,
               LAST_UPDATE_LOGIN = p_XxfcDemos.LAST_UPDATE_LOGIN
         WHERE DEMO_ID = p_XxfcDemos.DEMO_ID;
        IF SQL%ROWCOUNT = 0 THEN
           x_retcode := 2;
           x_errors := 'NO ROW UPDATED FOR DEMO_ID = ' || p_XxfcDemos.DEMO_ID;
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
   Descripcion : Insert Row sobre la tabla xxfc.xxFC_demos
   Modificado Por                 Fecha         Change Order    Descripcion
   -----------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  07/May/2026   CHOXXXXX        Creacion del Archivo
   ********************************************************************************************/
   PROCEDURE insert_row(x_rowid OUT ROWID
            , p_DEMO_ID IN NUMBER
            , p_DEMO_NAME IN VARCHAR2
            , p_CREATION_DATE IN DATE DEFAULT SYSDATE
            , p_CREATED_BY IN VARCHAR2 DEFAULT USER
            , p_LAST_UPDATE_DATE IN DATE DEFAULT SYSDATE
            , p_LAST_UPDATED_BY IN VARCHAR2 DEFAULT USER
            , p_LAST_UPDATE_LOGIN IN VARCHAR2 DEFAULT NULL
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
    BEGIN
        x_errors := '';
        x_retcode := 0;
        INSERT INTO XXFC_DEMOS (DEMO_ID, DEMO_NAME, CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY, LAST_UPDATE_LOGIN)
        VALUES (p_DEMO_ID, p_DEMO_NAME, p_CREATION_DATE, p_CREATED_BY, p_LAST_UPDATE_DATE, p_LAST_UPDATED_BY, p_LAST_UPDATE_LOGIN)
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
   Descripcion : Insert Row sobre la tabla xxfc.xxFC_demos
   Modificado Por                 Fecha         Change Order    Descripcion
   -----------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  07/May/2026   CHOXXXXX        Creacion del Archivo
   ********************************************************************************************/
   PROCEDURE insert_row(x_rowid OUT ROWID
            , p_XxfcDemos XXFC_DEMOS%ROWTYPE
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
    BEGIN
        x_errors := '';
        x_retcode := 0;
        INSERT INTO XXFC_DEMOS (DEMO_ID, DEMO_NAME, CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY, LAST_UPDATE_LOGIN)
        VALUES (p_XxfcDemos.DEMO_ID, p_XxfcDemos.DEMO_NAME, p_XxfcDemos.CREATION_DATE, p_XxfcDemos.CREATED_BY, p_XxfcDemos.LAST_UPDATE_DATE, p_XxfcDemos.LAST_UPDATED_BY, p_XxfcDemos.LAST_UPDATE_LOGIN)
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
   Descripcion : Delete Row sobre la tabla xxfc.xxFC_demos
   Modificado Por                 Fecha         Change Order    Descripcion
   -----------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  07/May/2026   CHOXXXXX        Creacion del Archivo
   ********************************************************************************************/
   PROCEDURE delete_row (p_DEMO_ID IN NUMBER
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
    BEGIN
        x_errors := '';
        x_retcode := 0;
        DELETE FROM XXFC_DEMOS
         WHERE DEMO_ID = p_DEMO_ID;
        IF SQL%ROWCOUNT = 0 THEN
           x_retcode := 2;
           x_errors := 'NO ROW DELETED FOR DEMO_ID = ' || p_DEMO_ID;
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
   Descripcion : Delete Row sobre la tabla xxfc.xxFC_demos
   Modificado Por                 Fecha         Change Order    Descripcion
   -----------------------------------------------------------------------------------------------
   * Gilberto Hernandez (Hexaware)  07/May/2026   CHOXXXXX        Creacion del Archivo
   ********************************************************************************************/
   PROCEDURE delete_row (p_XxfcDemos XXFC_DEMOS%ROWTYPE
            , x_errors IN OUT VARCHAR2, x_retcode IN OUT NUMBER) IS
    BEGIN
        x_errors := '';
        x_retcode := 0;
        DELETE FROM XXFC_DEMOS
         WHERE DEMO_ID = p_XxfcDemos.DEMO_ID;
        IF SQL%ROWCOUNT = 0 THEN
           x_retcode := 2;
           x_errors := 'NO ROW DELETED FOR DEMO_ID = ' || p_XxfcDemos.DEMO_ID;
        END IF;
    EXCEPTION
      WHEN OTHERS THEN
         x_retcode := 2;
         x_errors := SQLERRM;
    END delete_row;

END apps.xxfc_demos_pkg;
/
SHOW ERRORS;
