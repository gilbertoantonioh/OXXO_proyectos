SET SERVEROUTPUT ON
SET DEFINE OFF;
PROMPT APPS.AD_ZD_TABLE.DROP_TABLE XXFA_SN_TRIPS
DECLARE
lv_dropped	VARCHAR2(100);
lv_message	VARCHAR2(100);  
BEGIN
  APPS.AD_ZD_TABLE.DROP_TABLE('XXFC', 'XXFA_SN_TRIPS', 'DROP TABLE XXFC.XXFA_SN_TRIPS',NULL,lv_dropped);
  IF lv_dropped = 'Y' THEN
    lv_message := 'DROP TABLE XXFA_SN_TRIPS EXITOSO!';
  ELSE
    lv_message := 'DROP TABLE XXFA_SN_TRIPS FALLO!';
  END IF;
  dbms_output.put_line(lv_message); 
  

exception
when others then
   dbms_output.put_line('Error en AD_ZD_TABLE.DROP_TABLE '||SUBSTR(SQLERRM,1,200)); 
END;
/
