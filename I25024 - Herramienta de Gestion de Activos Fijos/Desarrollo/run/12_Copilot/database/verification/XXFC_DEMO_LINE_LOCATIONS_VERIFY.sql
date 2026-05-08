SET DEFINE OFF;
PROMPT Verification Script for XXFC_DEMO_LINE_LOCATIONS

-- Check if table exists
SELECT 'Table XXFC_DEMO_LINE_LOCATIONS' AS object_type, COUNT(*) AS count
FROM user_tables
WHERE table_name = 'XXFC_DEMO_LINE_LOCATIONS';

-- Check if sequence exists
SELECT 'Sequence' AS object_type, COUNT(*) AS count
FROM user_sequences
WHERE sequence_name = 'XXFC_XXFC_DEMO_LINE_LOCATIONS_S';

-- Check if APPS synonym exists
SELECT 'APPS Synonym' AS object_type, COUNT(*) AS count
FROM user_synonyms
WHERE synonym_name = 'XXFC_DEMO_LINE_LOCATIONS'
  AND TABLE_OWNER = 'APPS';

-- Check if APPSVIEW synonym exists
SELECT 'APPSVIEW Synonym' AS object_type, COUNT(*) AS count
FROM dba_synonyms
WHERE synonym_name = 'XXFC_DEMO_LINE_LOCATIONS'
  AND OWNER = 'APPSVIEW';

-- Check grants to APPS
SELECT 'APPS Grants' AS object_type, COUNT(*) AS count
FROM user_tab_privs
WHERE table_name = 'XXFC_DEMO_LINE_LOCATIONS'
  AND GRANTEE = 'APPS';

-- Check PL/SQL package
SELECT 'Package Spec' AS object_type, COUNT(*) AS count
FROM user_source
WHERE type = 'PACKAGE'
  AND name = 'XXFC_DEMO_LINE_LOCATIONS_PKG'
  AND line = 1;

SELECT 'Package Body' AS object_type, COUNT(*) AS count
FROM user_source
WHERE type = 'PACKAGE BODY'
  AND name = 'XXFC_DEMO_LINE_LOCATIONS_PKG'
  AND line = 1;