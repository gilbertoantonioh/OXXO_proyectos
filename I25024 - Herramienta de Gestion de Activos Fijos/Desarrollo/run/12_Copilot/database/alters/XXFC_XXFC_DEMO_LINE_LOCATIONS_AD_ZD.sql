SET DEFINE OFF;
PROMPT Execute AD_ZD Table Upgrade for xxfc_demo_line_locations

BEGIN
  AD_ZD_TABLE.UPGRADE('XXFC', 'XXFC_DEMO_LINE_LOCATIONS');
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Table XXFC_DEMO_LINE_LOCATIONS upgraded successfully.');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error upgrading table: ' || SQLERRM);
    ROLLBACK;
END;
/