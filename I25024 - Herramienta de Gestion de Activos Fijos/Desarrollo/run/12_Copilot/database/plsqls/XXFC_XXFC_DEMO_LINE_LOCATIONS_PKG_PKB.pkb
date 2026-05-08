SET DEFINE OFF;
PROMPT Create PL/SQL Package Body for XXFC_DEMO_LINE_LOCATIONS

CREATE OR REPLACE PACKAGE BODY xxfc.xxfc_demo_line_locations_pkg
AS
/*
||=====================================================================||
|| Package Body  : XXFC_DEMO_LINE_LOCATIONS_PKG                        ||
|| Version       : 1.0                                                 ||
|| Author        : Copilot Agent                                       ||
|| Creation Date : 08-MAY-2026                                         ||
||                                                                      ||
|| Description   : Implementation of XXFC_DEMO_LINE_LOCATIONS_PKG      ||
||=====================================================================||
*/

  -- Procedure to insert a new location
  PROCEDURE insert_location
  (
    p_demo_line_id      IN xxfc.xxfc_demo_line_locations.demo_line_id%TYPE,
    p_demo_id           IN xxfc.xxfc_demo_line_locations.demo_id%TYPE,
    p_location_code     IN xxfc.xxfc_demo_line_locations.location_code%TYPE,
    p_demo_location_id  OUT xxfc.xxfc_demo_line_locations.demo_location_id%TYPE
  )
  IS
  BEGIN
    INSERT INTO xxfc.xxfc_demo_line_locations
    (
      demo_line_id,
      demo_id,
      location_code,
      created_by,
      creation_date,
      last_updated_by,
      last_update_date
    )
    VALUES
    (
      p_demo_line_id,
      p_demo_id,
      p_location_code,
      USER,
      SYSDATE,
      USER,
      SYSDATE
    )
    RETURNING demo_location_id INTO p_demo_location_id;
    
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      FND_MESSAGE.SET_NAME('FND', 'SQL_PLSQL_ERROR');
      FND_MESSAGE.SET_TOKEN('ROUTINE', 'insert_location');
      FND_MESSAGE.SET_TOKEN('ERROR', SQLERRM);
      APP_EXCEPTION.RAISE_EXCEPTION;
  END insert_location;

  -- Procedure to update an existing location
  PROCEDURE update_location
  (
    p_demo_location_id  IN xxfc.xxfc_demo_line_locations.demo_location_id%TYPE,
    p_demo_line_id      IN xxfc.xxfc_demo_line_locations.demo_line_id%TYPE,
    p_demo_id           IN xxfc.xxfc_demo_line_locations.demo_id%TYPE,
    p_location_code     IN xxfc.xxfc_demo_line_locations.location_code%TYPE
  )
  IS
  BEGIN
    UPDATE xxfc.xxfc_demo_line_locations
    SET demo_line_id = p_demo_line_id,
        demo_id = p_demo_id,
        location_code = p_location_code,
        last_updated_by = USER,
        last_update_date = SYSDATE
    WHERE demo_location_id = p_demo_location_id;
    
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      FND_MESSAGE.SET_NAME('FND', 'SQL_PLSQL_ERROR');
      FND_MESSAGE.SET_TOKEN('ROUTINE', 'update_location');
      FND_MESSAGE.SET_TOKEN('ERROR', SQLERRM);
      APP_EXCEPTION.RAISE_EXCEPTION;
  END update_location;

  -- Procedure to delete a location
  PROCEDURE delete_location
  (
    p_demo_location_id  IN xxfc.xxfc_demo_line_locations.demo_location_id%TYPE
  )
  IS
  BEGIN
    DELETE FROM xxfc.xxfc_demo_line_locations
    WHERE demo_location_id = p_demo_location_id;
    
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      FND_MESSAGE.SET_NAME('FND', 'SQL_PLSQL_ERROR');
      FND_MESSAGE.SET_TOKEN('ROUTINE', 'delete_location');
      FND_MESSAGE.SET_TOKEN('ERROR', SQLERRM);
      APP_EXCEPTION.RAISE_EXCEPTION;
  END delete_location;

  -- Function to retrieve location details
  FUNCTION get_location_details
  (
    p_demo_location_id  IN xxfc.xxfc_demo_line_locations.demo_location_id%TYPE
  )
  RETURN SYS_REFCURSOR
  IS
    lv_refcursor SYS_REFCURSOR;
  BEGIN
    OPEN lv_refcursor FOR
    SELECT demo_location_id,
           demo_line_id,
           demo_id,
           location_code,
           created_by,
           creation_date,
           last_updated_by,
           last_update_date
    FROM xxfc.xxfc_demo_line_locations
    WHERE demo_location_id = p_demo_location_id;
    
    RETURN lv_refcursor;
  EXCEPTION
    WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('FND', 'SQL_PLSQL_ERROR');
      FND_MESSAGE.SET_TOKEN('ROUTINE', 'get_location_details');
      FND_MESSAGE.SET_TOKEN('ERROR', SQLERRM);
      APP_EXCEPTION.RAISE_EXCEPTION;
  END get_location_details;

END xxfc_demo_line_locations_pkg;
/