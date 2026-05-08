SET DEFINE OFF;
PROMPT Create PL/SQL Package Specification for XXFC_DEMO_LINE_LOCATIONS

CREATE OR REPLACE PACKAGE xxfc.xxfc_demo_line_locations_pkg
AS
/*
||=====================================================================||
|| Package       : XXFC_DEMO_LINE_LOCATIONS_PKG                        ||
|| Version       : 1.0                                                 ||
|| Author        : Copilot Agent                                       ||
|| Creation Date : 08-MAY-2026                                         ||
||                                                                      ||
|| Description   : Package for managing XXFC_DEMO_LINE_LOCATIONS table ||
||                 operations (insert, update, delete, select).        ||
||                                                                      ||
|| Modification History:                                               ||
|| Version  Date        Author  Description                            ||
|| -------  ----------  ------  -----------------------------------    ||
|| 1.0      08-MAY-26   COPILOT Initial version                        ||
||=====================================================================||
*/

  -- Procedure to insert a new location
  PROCEDURE insert_location
  (
    p_demo_line_id      IN xxfc.xxfc_demo_line_locations.demo_line_id%TYPE,
    p_demo_id           IN xxfc.xxfc_demo_line_locations.demo_id%TYPE,
    p_location_code     IN xxfc.xxfc_demo_line_locations.location_code%TYPE,
    p_demo_location_id  OUT xxfc.xxfc_demo_line_locations.demo_location_id%TYPE
  );

  -- Procedure to update an existing location
  PROCEDURE update_location
  (
    p_demo_location_id  IN xxfc.xxfc_demo_line_locations.demo_location_id%TYPE,
    p_demo_line_id      IN xxfc.xxfc_demo_line_locations.demo_line_id%TYPE,
    p_demo_id           IN xxfc.xxfc_demo_line_locations.demo_id%TYPE,
    p_location_code     IN xxfc.xxfc_demo_line_locations.location_code%TYPE
  );

  -- Procedure to delete a location
  PROCEDURE delete_location
  (
    p_demo_location_id  IN xxfc.xxfc_demo_line_locations.demo_location_id%TYPE
  );

  -- Function to retrieve location details
  FUNCTION get_location_details
  (
    p_demo_location_id  IN xxfc.xxfc_demo_line_locations.demo_location_id%TYPE
  )
  RETURN SYS_REFCURSOR;

END xxfc_demo_line_locations_pkg;
/