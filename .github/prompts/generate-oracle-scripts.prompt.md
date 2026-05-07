---
name: generate-oracle-scripts
description: "Generate complementary Oracle EBS scripts from a table script: grants, sequences (if applicable), AD_ZD upgrade, PL/SQL table handler package, and table creation confirmation."
parameters:
  - name: table_script
    description: "The SQL script content for the table creation (e.g., XXFC_AR_CUST_PROFILES_ALL_TBL.sql)."
    required: true
  - name: project_prefix
    description: "The project prefix (e.g., XXFC)."
    required: true
  - name: module_code
    description: "The module code (e.g., AR)."
    required: true
  - name: table_name
    description: "The full table name (e.g., XXFC_AR_CUST_PROFILES_ALL)."
    required: true
  - name: has_sequence
    description: "Does the table need a sequence for primary key? (yes/no)"
    required: true
---

# Generate Oracle EBS Complementary Scripts

Based on the provided table creation script, generate the following complementary scripts following Oracle EBS standards for OXXO:

1. **Grants Script**: `<Dueño>_<NombreTabla>_GRN.sql` - Grant permissions to APPS and other users.
2. **Sequence Script** (if applicable): `<Dueño>_<NombreSecuencia>_SEQ.sql` - Create sequence if the table has a numeric primary key.
3. **AD_ZD Upgrade Script**: Script to execute AD_ZD_TABLE.UPGRADE for the table.
4. **PL/SQL Table Handler Package**: `<Proyecto>_<Modulo>_<Tabla>_PKG.pks` and `.pkb` - Package with procedures for insert, update, delete, and select operations.
5. **Table Upgrade Confirmation**: Script to patch the table if needed.

Use the following inputs:
- Table Script: {table_script}
- Project Prefix: {project_prefix}
- Module Code: {module_code}
- Table Name: {table_name}
- Has Sequence: {has_sequence}

Ensure all scripts follow the naming conventions and include proper headers, comments, and error handling as per the Oracle EBS standards.

Output each script in a separate code block with the filename as header.