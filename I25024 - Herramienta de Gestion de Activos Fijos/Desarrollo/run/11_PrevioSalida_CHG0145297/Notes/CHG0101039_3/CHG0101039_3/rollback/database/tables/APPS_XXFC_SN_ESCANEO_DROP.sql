DECLARE
   X_DROPPED VARCHAR2(2000);
BEGIN
   ad_zd_table.DROP_TABLE (
              X_TABLE_OWNER    => 'XXFC',
              X_TABLE_NAME     => 'XXFC_SN_ESCANEO',
              X_DROP_STMT      => 'DROP TABLE XXFC.XXFC_SN_ESCANEO CASCADE CONSTRAINTS',
              X_UPD_STMT       => '',
              X_DROPPED        =>  X_DROPPED);
   DBMS_OUTPUT.PUT_LINE('X_DROPPED '||X_DROPPED);
END;
/
