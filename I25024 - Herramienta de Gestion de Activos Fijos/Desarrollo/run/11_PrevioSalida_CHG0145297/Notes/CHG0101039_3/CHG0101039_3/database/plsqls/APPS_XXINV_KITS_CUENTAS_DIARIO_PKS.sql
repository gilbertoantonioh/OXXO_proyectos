create or replace PACKAGE      XXINV_KITS_CUENTAS_DIARIO AS

/***
Object Name : XXINV_KITS_CUENTAS_DIARIO
Type        : Package
Purpose     : Integracion de Kits y cuentas en base a las salidas de almacen que hubo durante el dia

Pre-reqs : None.
Parameters :

    errbuf IN OUT VARCHAR2
   ,retcode IN OUT VARCHAR2
   ,p_org_id IN NUMBER


   Notes :
           **** COMPILE in apps     ******

   revisions:
   ver        date           author                  description
   ---------  -----------    ----------------------  ------------------------------------
   1.         18.Junio.2010  Juan Pedro Carrera      1. se redise�a el proceso para que que arme los kits y cuentas en el momento de
                                                         transaccionar la salida, en vez de hacerlo en la creacion del move order.

***/

 PROCEDURE main(errbuf         OUT VARCHAR2,
                retcode        OUT VARCHAR2,
                p_org_id       IN  NUMBER,
                p_fecha        IN  VARCHAR2);

PROCEDURE CHECK_ITEM_ACCOUNT(P_ITEM_ID IN NUMBER,
                             P_ORGANIZATION_ID IN NUMBER,
                             P_ORACLE_EF IN VARCHAR2,
        P_ORACLE_CR IN OUT VARCHAR2,
        P_CUENTA OUT VARCHAR2,
        PR_LINE_ID IN NUMBER,
        PR_HEADER_ID IN NUMBER
        );

PROCEDURE CREATE_CODE_COMBINATION(P_SEGMENT1 IN VARCHAR2,
          P_SEGMENT2 IN VARCHAR2,
          P_SEGMENT3 IN VARCHAR2,
          P_SEGMENT4 IN VARCHAR2,
          P_CODE_COMBINATION_ID OUT NUMBER,
          P_RET_CODE OUT VARCHAR2,
          P_ERR_BUF  OUT VARCHAR2
          );


--FUNCTION PARENT_EXISTS(P_PARENT VARCHAR2,P_ATTRIBUTE4 VARCHAR2)RETURN VARCHAR2;
FUNCTION BUSCA_REQUIS_CR(P_REQ_LINE NUMBER)RETURN VARCHAR2;
FUNCTION BUSCA_REQUIS_CR_SUP(P_REQ_LINE NUMBER)RETURN VARCHAR2;
FUNCTION BUSCA_REQUIS_EF(P_REQ_LINE NUMBER)RETURN VARCHAR2;

   /********************************************************************************************
   * Modulo      : pre_xxinv_mat_trx_temp_prc
   * Autor       : Martin Verdeja Linares
   * Fecha       : Agosto 2025
   * Descripcion : Para actualizar el precio de compra en la tabla xxinv_material_trx_temp
   * Modificado Por        	Fecha           	Codigo      Descripcion
   ---------------------------------------------------------------------------------------------
   * Martin Verdeja L.   Septiembre 2025	  CHG0101039    Para actualizar el precio de compra
   *                                                        
   *
   ********************************************************************************************/
   PROCEDURE pre_xxinv_mat_trx_temp_prc (pd_date IN DATE, pv_retcode IN OUT VARCHAR2);


   /********************************************************************************************
   * Modulo      : get_viaje_fnc
   * Autor       : Martin Verdeja Linares
   * Fecha       : Septiembre 2025
   * Descripcion : Para obtener el numero de viaje
   * Modificado Por        	Fecha           	Codigo      Descripcion
   ---------------------------------------------------------------------------------------------
   * Martin Verdeja L.   Septiembre 2025	  CHG0101039    Para obtener el numero de viaje
   *                                                        
   *
   ********************************************************************************************/   
   FUNCTION get_viaje_fnc (
      p_header_id      IN   VARCHAR2 DEFAULT NULL
    , p_line_id        IN   VARCHAR2 DEFAULT NULL
   )
      RETURN NUMBER;


   /********************************************************************************************
   * Modulo      : procesa_info_articulo_prc
   * Autor       : Martin Verdeja Linares
   * Fecha       : Agosto 2025
   * Descripcion : Procedimiento para obtener el precio de compra o el numero de placa de un articulo
   * Modificado Por        	Fecha           	Codigo      Descripcion
   ---------------------------------------------------------------------------------------------
   * Martin Verdeja L.      Agosto 2025		  CHG0101039    Para actualizar el precio de compra
   *                                                        y el numero de placa del activo
   *
   ********************************************************************************************/
   PROCEDURE procesa_info_articulo_prc (
               pd_creation_date     IN DATE);

   /********************************************************************************************
   * Modulo      : reagrupa_info_prc
   * Autor       : Martin Verdeja Linares
   * Fecha       : Septiembre 2025
   * Descripcion : Procedimiento que reagrupa la informacion de transacciones
   * Modificado Por        	Fecha           	Codigo      Descripcion
   ---------------------------------------------------------------------------------------------
   * Martin Verdeja L.      Septiembre 2025	   CHG0101039    Reagrupa la informacion de transacciones
   *
   ********************************************************************************************/
   PROCEDURE reagrupa_info_prc (
               pd_creation_date     IN DATE);

END;
/