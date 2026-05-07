---
description: "Use when: developing Oracle EBS components for OXXO, including PL/SQL, forms, reports, XML Publisher, OAF, and database objects. Follow FCTI_ARM_Estandar Desarrollo Oracle EBS Rev. 3 standards."
applyTo: "I25024 - Herramienta de Gestion de Activos Fijos/**"
---

# Instrucciones para desarrollo Oracle EBS en OXXO

## Objetivo
Generar y revisar artefactos de desarrollo Oracle EBS para OXXO siguiendo los estándares de `FCTI_ARM_Estandar Desarrollo Oracle EBS Rev. 3`.

## 1. Reglas generales
- Seguir estándares Oracle EBS Rel. 12.2 y políticas internas OXXO.
- Usar prefijos de proyecto `XX` y código de módulo: por ejemplo `XXFC`, `XXCO`, `XXOG`, `XXCB`, `XXFH`, `XXMWF`.
- Documentar cada objeto con su esquema, autor, versión, fecha y descripción.
- Mantener la consistencia entre scripts, objetos y directorios.

## 2. Base de datos
### 2.1 Nombres y esquemas
- Objetos personalizados deben crearse bajo esquema `XX*` y referenciarse desde `APPS` con sinónimos privados.
- Prefijo de objeto debe ser `<Proyecto>_<Módulo>_...`.

### 2.2 Tablas
- Nombres: `<Proyecto>_<Módulo>_<Descripción>[_ALL/_GT/_TEMP]`.
- Máximo 29 caracteres para tablas normalizadas.
- Primary key constraint: `<Nombre_Tabla>_PK` si cabe.
- Incluir columnas de auditoría:
  - `CREATION_DATE`
  - `CREATED_BY`
  - `LAST_UPDATE_DATE`
  - `LAST_UPDATED_BY`
  - `LAST_UPDATE_LOGIN`
- Tablespace de datos: `APPS_TS_TX_DATA`.
- Tablespace de índices: `APPS_TS_TX_IDX`.
- Scripts:
  - tabla: `<Dueño>_<NombreTabla>_TBL.sql`
  - alter: `<Dueño>_<NombreTabla>_..._ALT.sql`
  - sinónimo: `<Dueño>_<NombreTabla>_SYN.sql`
  - grants: `<Dueño>_<NombreTabla>_<Usuario>_GRN.sql`

### 2.3 Tablas temporales
- Usar `GLOBAL TEMPORARY TABLE`.
- Crear sinónimo `APPS` hacia la tabla.

### 2.4 Tablas multi-org
- Agregar política `ORG_SEC`.
- Consultar la nota Metalink `420787.1`.

### 2.5 Vistas
- Nombres: `<Proyecto>_<Módulo>_<Descripción>[_V/_MV]`.
- Vistas multi-org no llevan `_V`.
- Dueño preferido: `APPS`.
- Scripts:
  - vista: `<Dueño>_<NombreVista>_VW.sql`
  - sinónimo: `<Dueño>_<NombreVista>_SYN.sql`
  - grants: `<Dueño>_<NombreVista>_<Usuario>_GRN.sql`

### 2.6 Vistas materializadas
- Crear vista lógica con sufijo `#`.
- Ejecutar `AD_ZD_MVIEW.UPGRADE(<esquema>, <nombre>)`.
- No usar funciones almacenadas en la vista lógica.

### 2.7 Índices
- Nombres:
  - únicos: `<Nombre_Tabla>_U1`, `<Nombre_Tabla>_U2`
  - no únicos: `<Nombre_Tabla>_NU1`
- Scripts: `<Dueño>_<NombreIndice>_IDX.sql`

### 2.8 Secuencias
- Nombre: `<Nombre_Tabla>_S`.
- Usar `NO CACHE`.
- Scripts:
  - secuencia: `<Dueño>_<NombreSecuencia>_SEQ.sql`
  - sinónimo: `<Dueño>_<NombreSecuencia>_SYN.sql`
  - grants: `<Dueño>_<NombreTabla>_<Usuario>_GRN.sql`

### 2.9 Otros objetos de BD
- Tipos: `<Proyecto>_<Módulo>_<Descripción>_TYP`.
- Scripts: `<Dueño>_<NombreTipo>_TYP.sql`.

## 3. PL/SQL
### 3.1 Estilo y convenciones
- No usar tabs; usar espacios.
- Indentación de 3 espacios.
- Usar paquetes siempre que sea posible.
- Paquetes con nombre: `<Proyecto>_<Módulo>_<Descripción>_PKG`.
- Procedimientos: `<Proyecto>_<Módulo>_<Descripción>_PRC`.
- Funciones: `<Proyecto>_<Módulo>_<Descripción>_FNC`.
- Triggers: `<Proyecto>_<Módulo>_<Descripción>_<Tiempo><Evento>`.

### 3.2 Prefijos de variables
- `c_` para constantes
- `l_` para variables locales
- `g_` para variables globales
- `p_` para parámetros de entrada
- `x` para parámetros OUT
- Tipos:
  - `n` Number
  - `v` Varchar2
  - `d` Date
  - `b` Boolean
  - `e` Exception
  - `i` Integer
  - `r` Raw
  - `cl` CLOB
  - `bl` BLOB
  - `xml` XMLType
  - `tbl` Table
  - `rec` Record
  - `typ` Type
  - `cur` Cursor

### 3.3 Cabecera de programa
Debe incluir:
- Módulo
- Autor completo
- Versión
- Fecha (DD-MON-YYYY)
- Descripción
- Ejecutado por
- Historial de modificaciones

### 3.4 Mensajes y errores
- Usar `FND_MESSAGE` y `APP_EXCEPTION.RAISE_EXCEPTION` para errores esperados.
- Mensajes en inglés para runtime, pero con texto en castellano para traducción.
- Formato recomendado: `<Texto del Mensaje> - (Debug Information: Module=&MODULE, Value Id=&VALUE_ID - &SQLERRM)`.

### 3.5 SQL en PL/SQL
- Aliases claros.
- Cada columna y condición en línea separada.
- No usar SQL inline sin necesidad.

### 3.6 Utilería AD_ZD
- `AD_ZD.GRANT_PRIVS(...)`
- `AD_ZD.REVOKE_PRIVS(...)`
- `AD_ZD_TABLE.UPGRADE(...)`
- `AD_ZD_TABLE.PATCH(...)`
- `AD_ZD_TABLE.DOWNGRADE(...)`
- `AD_ZD_MVIEW.UPGRADE(...)`

## 4. Oracle Forms
- Usar solo en excepciones.
- Seguir plantilla `APSTAND.fmb`.
- En `PRE-FORM`, llamar a `FND_STANDARD.FORM_INFO`.

## 5. Oracle Reports
- Preferir XML Publisher.
- Si se usa Oracle Reports, ejecutar `SRW.USER_EXIT('FND SRWINIT')` y `SRW.USER_EXIT('FND SRWEXIT')`.

## 6. Oracle XML Publisher
- Nombrar objetos de reporte con el prefijo de proyecto y módulo.
- Plantilla de datos: `<AbreviaturaConcurrente>.xml`.
- Plantilla de formato: `<AbreviaturaConcurrente>.rtf`.
- Datos y formato deben mapear los nombres en el concurrente y en los parámetros.

## 7. Oracle Workflow
- Trabajar localmente con `.wft` y luego cargar en BD.
- No efectuar commits en los procedimientos llamados por workflow.
- Naming de workflow con prefijo de proyecto.

## 8. OAF
### 8.1 Requisito
- Todas las nuevas pantallas deben desarrollarse en OAF.

### 8.2 Estructura de paquetes
- Base: `oxxo.oracle.apps.<proyecto>.<aplicacion>...`
- Subpaquetes: `webui`, `server`, `common.webui`, `common.server`, `schema`, `attributesets`.
- Componentes:
  - Páginas: `*PG`
  - Controllers: `*CO`
  - Regiones: `*RN`
  - ViewObjects: `*VO`
  - EntityObjects: `*EO`
  - ViewLinks: `*VL`
  - ApplicationModules: `*AM`
  - Javascript: `*JS`
  - AttributeSets: `*AS`

### 8.3 Mensajes
- Usar diccionario de mensajes, no strings hardcode.
- Ejemplo: `throw new OAException("XXFC", "XXFC_CRES_RUBROS_NO_INFO");`

### 8.4 Conexiones JDBC
- Desde ApplicationModule: `getOADBTransaction().getJdbcConnection()`.
- No cerrar la conexión directamente.

## 9. Directorios y despliegue
- Mantener estructura clara en `database` y `application`.
- En `database`: `alters`, `grants`, `indexes`, `plsqls`, `sequences`, `sqls`, `synonyms`, `tables`, `views`.
- En OAF: `JAVA_TOP/oxxo/oracle/apps/<proyecto>/<modulo>/webui` y `/server`.
- Usar instalador hot patch versión 3.1 para despliegues.

## 10. Seguridad y Usabilidad
- Aplicar control de acceso por roles y seguridad por datos.
- Usar nombres de responsabilidades y objetos con prefijo de proyecto.
- Seguir guías de usabilidad OAF y branding OXXO.

## 11. Entregables
- Scripts SQL ordenados por tipo.
- Paquetes PL/SQL con spec y body separados.
- Plantillas XML Publisher y reportes OAF en sus rutas correctas.
- Archivo de instalación con orden claro de ejecución.
- Documentación de pruebas unitarias.

## 12. Nota para Copilot
- Priorizar consistencia de nombres, esquemas y directorios.
- Generar objetos usando las convenciones formales descritas.
- Revisar siempre que `APPS` referencie sinónimos y no tablas directas en código PL/SQL/Forms.
- Para cada nuevo objeto DB, crear scripts separados y respetar el esquema de instalación.