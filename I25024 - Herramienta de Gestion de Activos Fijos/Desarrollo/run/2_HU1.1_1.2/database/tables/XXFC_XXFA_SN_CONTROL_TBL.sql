SET DEFINE OFF;
PROMPT CREATE TABLE xxfc.xxfa_sn_control
CREATE TABLE xxfc.xxfa_sn_control (
data_control_id                 NUMBER DEFAULT XXFC.xxfa_sn_control_s.NEXTVAL NOT NULL, 
data_source_id                  NUMBER,    
data_source_code                VARCHAR2(240),   
data_file_name                  VARCHAR2(240),                            
creation_date                   DATE DEFAULT SYSDATE,
created_by                      NUMBER DEFAULT -1,
last_update_date                DATE DEFAULT SYSDATE,
last_updated_by                 NUMBER DEFAULT -1,
last_update_login               NUMBER DEFAULT -1
)
TABLESPACE APPS_TS_TX_DATA
;

GRANT ALL ON xxfc.xxfa_sn_control TO apps WITH GRANT OPTION;