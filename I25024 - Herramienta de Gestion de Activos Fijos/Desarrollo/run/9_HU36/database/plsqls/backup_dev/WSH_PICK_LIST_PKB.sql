create or replace PACKAGE BODY WSH_PICK_LIST AS
/* $Header: WSHPGSLB.pls 120.64.12020000.8 2013/04/26 10:49:30 lkuchibh ship $ */


g_hash_base NUMBER := 1;
g_hash_size NUMBER := power(2, 25);


--
-- Package
--  WSH_PICK_LIST
--
-- Purpose
--   This package does the following:
--   - Generate selection list
--   - Call Move Order APIs to create reservations and to print Pick Slips
--

   --Recode attributes of Demand Table
-- HW OPMCONV - Added qty2
   TYPE demRecTyp IS RECORD (
          demand_source_header_id NUMBER,
          demand_source_line_id   NUMBER,
          subinventory_code VARCHAR2(10),
          locator_id  NUMBER,
          reserved_quantity NUMBER,
          reserved_quantity2 NUMBER);

   TYPE demRecTabTyp IS TABLE OF demRecTyp INDEX BY BINARY_INTEGER;

   --
   --  VARIABLES

   -- Description: Constant to distinguish CONCURRENT request from
   -- ONLINE request
   G_CONC_REQ VARCHAR2(1) := FND_API.G_TRUE;


   -- Following globals are needed by online_release API to pass back to the Pick Release Form
   G_ONLINE_PICK_RELEASE_PHASE  VARCHAR2(30) := null;
   -- Possible values are - START, MOVE_ORDER_LINES,SUCCESS
   -- MOVE_ORDER_LINES is used by Form to give a different message if Process
   -- fails after successfull call to Inv_Move_Order_Pub.Create_Move_Order_Lines

   G_ONLINE_PICK_RELEASE_RESULT  VARCHAR2(1) := 'F';
   -- Possible values are S(Success) and F(failure)

   G_ONLINE_PICK_RELEASE_SKIP VARCHAR2(1) := 'N';
   --

   G_PKG_NAME CONSTANT VARCHAR2(50) := 'WSH_PICK_LIST';

   g_demand_table demRecTabTyp;

   -- Global Variables
   g_trolin_tbl              INV_MOVE_ORDER_PUB.Trolin_Tbl_Type;
   g_trolin_delivery_ids     WSH_UTIL_CORE.Id_Tab_Type;
   g_order_number            NUMBER;
   g_del_detail_ids          WSH_PICK_LIST.DelDetTabTyp;
   g_exp_pick_release_stat   Inv_Express_Pick_Pub.P_Pick_Release_Status_Tbl;

   -- X-dock, declare package level global variables
   g_allocation_method       WSH_PICKING_BATCHES.ALLOCATION_METHOD%TYPE;
   g_xdock_delivery_ids      WSH_UTIL_CORE.Id_Tab_Type; -- used for X-dock only
   g_xdock_detail_ids        WSH_PICK_LIST.DelDetTabTyp; -- used for X-dock only

/**************************
-- X-dock
-- Description: This function is called from create_move_order_lines and
--              Release_Batch API.
--              Create_move_order_lines is called from Release_Batch_Sub
--              which in turn is called from Release_Batch API, but could
--              also be called from SRS program.
--              This function will replace the multiple calls made in the
--              code to check for g_allocation_method being not 'Crossdock'
--              and provides a single point of maintenance
--
--FUNCTION check_allocation_method RETURN VARCHAR2; -- Spec not required
g_valid_allocation  VARCHAR2(1);
-- Need to be nullified for each organization
FUNCTION check_allocation_method RETURN VARCHAR2 IS

BEGIN
  IF g_valid_allocation IS NULL THEN
    IF g_allocation_method IN (WSH_PICK_LIST.C_INVENTORY_ONLY,
                               WSH_PICK_LIST.C_PRIORITIZE_CROSSDOCK,
                               WSH_PICK_LIST.C_PRIORITIZE_INVENTORY) THEN
      g_valid_allocation := 'Y';
    ELSE
      g_valid_allocation := 'N';
    END IF;
  END IF;
  RETURN g_valid_allocation;

END;
****************************/

-- Start of comments
-- API name : Init_Pick_Release
-- Type     : Private
-- Pre-reqs : None.
-- Procedure: This API calls WSH_PR_CRITERIA.Init API to initialize global variables
-- Parameters :
-- IN:
--      p_batch_id            IN  Batch Id.
--      p_worker_id           IN  Worker Id.
-- OUT:
--      x_return_status       OUT NOCOPY  Return Status.
-- End of comments
PROCEDURE Init_Pick_Release(
      p_batch_id                        IN      NUMBER,
      p_worker_id                       IN      NUMBER,
      x_return_status                   OUT NOCOPY VARCHAR2)
IS
  --
  l_debug_on BOOLEAN;
  l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'INIT_PICK_RELEASE';
  --
BEGIN

  x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

  l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
  IF l_debug_on IS NULL THEN
     l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
  END IF;

  IF l_debug_on THEN
     WSH_DEBUG_SV.push(l_module_name);
     WSH_DEBUG_SV.log(l_module_name,'P_BATCH_ID ',P_BATCH_ID);
     WSH_DEBUG_SV.log(l_module_name,'P_WORKER_ID ',P_WORKER_ID);
     WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_PR_CRITERIA.INIT',WSH_DEBUG_SV.C_PROC_LEVEL);
  END IF;

  WSH_PR_CRITERIA.Init( p_batch_id   => p_batch_id,
                        p_worker_id  => p_worker_id,
                        x_api_status => x_return_status);

  IF (x_return_status = WSH_UTIL_CORE.G_RET_STS_SUCCESS) THEN
     --
     IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,  'INITIALIZATION SUCCESSFUL ');
     END IF;
     --
  ELSIF (x_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) OR (x_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR) THEN
     WSH_UTIL_CORE.PrintMsg('Error occurred in WSH_PR_CRITERIA.Init');
     --
     IF l_debug_on THEN
        WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:INIT');
     END IF;
     --
     RETURN; -- back to calling API
  END IF;

  WSH_PICK_LIST.G_BATCH_ID := p_batch_id;

  BEGIN --{
   --Get the seeded document set id
   SELECT WRS.REPORT_SET_ID
   INTO   WSH_PICK_LIST.G_SEED_DOC_SET
   FROM   WSH_REPORT_SET_LINES WRSL,
          WSH_REPORT_SETS WRS
   WHERE  WRS.NAME = 'Pick Slip Report'
   AND    WRS.REPORT_SET_ID = WRSL.REPORT_SET_ID ;
   --
   IF l_debug_on THEN
       WSH_DEBUG_SV.logmsg(l_module_name,  'SEEDED PICK RELEASE DOCUMENT SET IS '||WSH_PICK_LIST.G_SEED_DOC_SET  );
   END IF;
   --
   EXCEPTION
     --
     WHEN NO_DATA_FOUND THEN
       --
       WSH_PICK_LIST.G_SEED_DOC_SET := NULL;
       --
       IF l_debug_on THEN
         WSH_DEBUG_SV.logmsg(l_module_name,  'SEEDED PICK RELEASE DOCUMENT SET NOT FOUND');
       END IF;
       --
     WHEN TOO_MANY_ROWS THEN
       --
       WSH_PICK_LIST.G_SEED_DOC_SET := NULL;
       --
       IF l_debug_on THEN
         WSH_DEBUG_SV.logmsg(l_module_name, 'SEEDED PICK RELEASE DOCUMENT SET HAS > 1 REPORT. IGNORING...');
       END IF;
  END; --}

  -- X-dock, populate the package globals
  g_allocation_method := WSH_PR_CRITERIA.g_allocation_method;

  IF l_debug_on THEN
     WSH_DEBUG_SV.pop(l_module_name);
  END IF;

EXCEPTION
      --
      WHEN OTHERS THEN
         x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
         IF l_debug_on THEN
            WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '
                                || SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
            WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
         END IF;
         --
END Init_Pick_Release;


-- Start of comments
-- API name : Get_Org_Params
-- Type     : Private
-- Pre-reqs : None.
-- Procedure: This API gets all Organization related parameters
-- Parameters :
-- IN:
--      p_organization_id     IN  Organization Id.
-- OUT:
--      x_org_info            OUT NOCOPY  Organization Info.
--      x_return_status       OUT NOCOPY  Return Status.
-- End of comments
PROCEDURE Get_Org_Params(
      p_organization_id                IN      NUMBER,
      x_org_info                       OUT NOCOPY WSH_PICK_LIST.Org_Params_Rec,
      x_return_status                  OUT NOCOPY VARCHAR2)
IS

  --Cursor to get inventory pick confirmed required flag.
  CURSOR get_default_confirm(c_org_id IN NUMBER) IS
  SELECT DECODE(MO_PICK_CONFIRM_REQUIRED, 2, 'Y', 'N')
  FROM   MTL_PARAMETERS
  WHERE  ORGANIZATION_ID = c_org_id;

  l_default_pickconfirm  VARCHAR2(1);
  l_init_rules           VARCHAR2(1) := FND_API.G_FALSE;
  l_param_info           WSH_SHIPPING_PARAMS_PVT.Parameter_Rec_Typ;
  l_express_pick_profile VARCHAR2(1);

  l_debug_on BOOLEAN;
  l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'GET_ORG_PARAMS';

BEGIN

  x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

  l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
  IF l_debug_on IS NULL THEN
     l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
  END IF;

  IF l_debug_on THEN
     WSH_DEBUG_SV.push(l_module_name);
     WSH_DEBUG_SV.log(l_module_name,'P_ORGANIZATION_ID ',P_ORGANIZATION_ID);
     WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_SHIPPING_PARAMS_PVT.Get',WSH_DEBUG_SV.C_PROC_LEVEL);
  END IF;

  -- 10. Getting Organization Parameters
  WSH_SHIPPING_PARAMS_PVT.Get(
            p_organization_id => p_organization_id,
            x_param_info      => l_param_info,
            x_return_status   => x_return_status);

  IF l_debug_on THEN
     WSH_DEBUG_SV.log(l_module_name,'Return Status After Calling WSH_SHIPPING_PARAMS_PVT.Get',x_return_status);
  END IF;

  -- 20. Using NVL function for possible null values
  l_param_info.PRINT_PICK_SLIP_MODE          := NVL(l_param_info.PRINT_PICK_SLIP_MODE, 'E');
  l_param_info.AUTOCREATE_DELIVERIES_FLAG    := NVL(l_param_info.AUTOCREATE_DELIVERIES_FLAG, 'N');
  l_param_info.ENFORCE_SHIP_SET_AND_SMC      := NVL(l_param_info.ENFORCE_SHIP_SET_AND_SMC, 'N');
  l_param_info.APPENDING_LIMIT               := NVL(l_param_info.APPENDING_LIMIT, 'N');

  IF l_param_info.APPENDING_LIMIT <> 'N' THEN
     l_param_info.APPENDING_LIMIT := 'Y';
  END IF;

  OPEN  get_default_confirm(p_organization_id);
  FETCH get_default_confirm INTO l_default_pickconfirm;
  CLOSE get_default_confirm;

  IF l_debug_on THEN
     WSH_DEBUG_SV.log(l_module_name,  'DEFAULTS FOR ORGANIZATION', P_ORGANIZATION_ID);
     WSH_DEBUG_SV.log(l_module_name,  ' PICK SLIP MODE', L_PARAM_INFO.PRINT_PICK_SLIP_MODE);
     WSH_DEBUG_SV.log(l_module_name,  ' AUTO DETAIL', L_PARAM_INFO.AUTODETAIL_PR_FLAG);
     WSH_DEBUG_SV.log(l_module_name,  ' AUTO PICK CONFIRM', L_DEFAULT_PICKCONFIRM);
     WSH_DEBUG_SV.log(l_module_name,  ' AUTOCREATE DEL', L_PARAM_INFO.AUTOCREATE_DELIVERIES_FLAG);
     WSH_DEBUG_SV.log(l_module_name,  ' STAGING SUBINVENTORY', L_PARAM_INFO.DEFAULT_STAGE_SUBINVENTORY);
     WSH_DEBUG_SV.log(l_module_name,  ' STAGING LOCATOR ID', L_PARAM_INFO.DEFAULT_STAGE_LOCATOR_ID);
     WSH_DEBUG_SV.log(l_module_name,  ' PICK SEQ RULE ID', L_PARAM_INFO.PICK_SEQUENCE_RULE_ID);
     WSH_DEBUG_SV.log(l_module_name,  ' PICK GROUPING RULE ID', L_PARAM_INFO.PICK_GROUPING_RULE_ID);
     WSH_DEBUG_SV.log(l_module_name,  ' ENFORCE SHIP SET AND SMC', L_PARAM_INFO.ENFORCE_SHIP_SET_AND_SMC);
     WSH_DEBUG_SV.log(l_module_name,  ' PICK RELEASE DOCUMENT SET ID', L_PARAM_INFO.PICK_RELEASE_REPORT_SET_ID);
     WSH_DEBUG_SV.log(l_module_name,  ' TASK PLANNING FLAG', L_PARAM_INFO.TASK_PLANNING_FLAG);
     WSH_DEBUG_SV.log(l_module_name,  ' Use Header Flag', L_PARAM_INFO.AUTOCREATE_DEL_ORDERS_FLAG);
     WSH_DEBUG_SV.log(l_module_name,  ' Ship Confirm Rule ID', L_PARAM_INFO.SHIP_CONFIRM_RULE_ID);
     WSH_DEBUG_SV.log(l_module_name,  ' Append Flag', L_PARAM_INFO.APPENDING_LIMIT);
     WSH_DEBUG_SV.log(l_module_name,  ' Auto Pack Level ', L_PARAM_INFO.AUTOPACK_LEVEL);
     WSH_DEBUG_SV.log(l_module_name,  ' Auto Apply Routing Rules ', L_PARAM_INFO.AUTO_APPLY_ROUTING_RULES);
     WSH_DEBUG_SV.log(l_module_name,  ' Auto Calculate Freight Rates after Delivery Creation '
                                   , L_PARAM_INFO.AUTO_CALC_FGT_RATE_CR_DEL);
     --bug# 6689448 (replenishment project)
     WSH_DEBUG_SV.log(l_module_name,  'dynamic replenishment flag', L_PARAM_INFO.DYNAMIC_REPLENISHMENT_FLAG);
  END IF;

  -- 30. Deriving Actual Values
  x_org_info.autodetail_flag       := NVL(WSH_PR_CRITERIA.g_autodetail_flag, l_param_info.autodetail_pr_flag);
  x_org_info.auto_pick_confirm     := NVL(WSH_PR_CRITERIA.g_auto_pick_confirm_flag, l_default_pickconfirm);
  x_org_info.autocreate_deliveries := NVL(WSH_PR_CRITERIA.g_autocreate_deliveries,
                                                              l_param_info.autocreate_deliveries_flag); --bug 4556414
  x_org_info.pick_seq_rule_id      := NVL(WSH_PR_CRITERIA.g_pick_seq_rule_id, l_param_info.pick_sequence_rule_id);
  x_org_info.pick_grouping_rule_id := NVL(WSH_PR_CRITERIA.g_pick_grouping_rule_id, l_param_info.pick_grouping_rule_id);
  x_org_info.autopack_level        := NVL(WSH_PR_CRITERIA.g_autopack_level, l_param_info.autopack_level);
  -- rlanka : Pack J Enhancement
  --
  -- LSP PROJECT : Use_header_flag value defaulting (from org/client defaults) has been moved to the calling API
  --          WSH_DELIVERY_AUTOCREATE.Find_Matching_Groups/Create_Hash and hence just passing
  --          the original value to the calling API.
  --x_org_info.use_header_flag       := NVL(WSH_PR_CRITERIA.g_acDelivCriteria, l_param_info.autocreate_del_orders_flag); --bug 4556414
  x_org_info.use_header_flag       := WSH_PR_CRITERIA.g_acDelivCriteria;
  -- LSP PROJECT : end
  x_org_info.append_flag           := l_param_info.appending_limit;
  x_org_info.print_pick_slip_mode  := l_param_info.print_pick_slip_mode;
  x_org_info.enforce_ship_set_and_smc  := l_param_info.enforce_ship_set_and_smc;

  x_org_info.auto_apply_routing_rules   := l_param_info.auto_apply_routing_rules;
  x_org_info.auto_calc_fgt_rate_cr_del  := l_param_info.auto_calc_fgt_rate_cr_del;

  IF l_debug_on THEN
     WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_UTIL_VALIDATE.CHECK_WMS_ORG',WSH_DEBUG_SV.C_PROC_LEVEL);
  END IF;

  x_org_info.wms_org := WSH_UTIL_VALIDATE.CHECK_WMS_ORG(p_organization_id);
  IF (x_org_info.wms_org = 'Y') THEN

     IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,  P_ORGANIZATION_ID || ' IS WMS ENABLED ORGANIZATION'  );
     END IF;

     --task_planning_flag is default of Release criteria or organization default.
     x_org_info.task_planning_flag := NVL(WSH_PR_CRITERIA.g_task_planning_flag, NVL(l_param_info.task_planning_flag, 'N'));
     IF x_org_info.task_planning_flag = 'Y' THEN
        x_org_info.auto_pick_confirm := 'N';
     END IF;

     --bug# 6689448 (replenishment project):
     x_org_info.dynamic_replenishment_flag := NVL(WSH_PR_CRITERIA.g_dynamic_replenishment_flag, NVL(l_param_info.dynamic_replenishment_flag, 'N'));
  ELSE
     x_org_info.task_planning_flag := 'N';
     x_org_info.dynamic_replenishment_flag := 'N';
  END IF;

  -- Bug 3316645: For only Non-WMS orgs, default the Subinventory and Locator from either
  -- Pick Release Criteria or the Shipping Parameters defaults
  -- For WMS, the default will be from the Pick Release Criteria entered only
  IF (x_org_info.wms_org = 'N') THEN
    x_org_info.to_subinventory := NVL(WSH_PR_CRITERIA.g_to_subinventory, l_param_info.default_stage_subinventory);

    -- Following IF condition added for Bug 4199614,(FP Bug-4225169)
    -- Default locator in Org. Shipping Parameters will be assigned to To_Locator
    -- only if default subinventory in Org. Shipping Parameters and subinventory
    -- entered in Pick Release form are same.
    -- Modified IF condition for bug 4363740.
    -- If Subinventory entered in Pick Release form is NULL, then copy Subinventory
    -- and Locator from Org. Shipping Parameters.
    IF  (l_param_info.default_stage_subinventory = x_org_info.to_subinventory) THEN
      x_org_info.to_locator         := NVL(WSH_PR_CRITERIA.g_to_locator, l_param_info.default_stage_locator_id);
    ELSE
      x_org_info.to_locator         := WSH_PR_CRITERIA.g_to_locator;
    END IF;

  ELSE
     x_org_info.to_subinventory    := WSH_PR_CRITERIA.g_to_subinventory;
     x_org_info.to_locator         := WSH_PR_CRITERIA.g_to_locator;
  END IF;

  IF ( NVL(WSH_PR_CRITERIA.g_doc_set_id,-1) <> -1 ) THEN
     x_org_info.doc_set_id := WSH_PR_CRITERIA.g_doc_set_id;
  ELSE
     x_org_info.doc_set_id := l_param_info.pick_release_report_set_id;
  END IF;

  IF x_org_info.append_flag = 'N' or x_org_info.auto_pick_confirm = 'Y' THEN
     x_org_info.append_flag := 'N';
  ELSE
     x_org_info.append_flag := NVL(WSH_PR_CRITERIA.g_append_flag, x_org_info.append_flag);
  END IF;

  IF l_debug_on THEN
     WSH_DEBUG_SV.log(l_module_name,  'ACTUAL PARAMETERS THAT WILL BE USED');
     WSH_DEBUG_SV.log(l_module_name,  ' AUTO DETAIL', X_ORG_INFO.AUTODETAIL_FLAG);
     WSH_DEBUG_SV.log(l_module_name,  ' AUTO PICK CONFIRM', X_ORG_INFO.AUTO_PICK_CONFIRM);
     WSH_DEBUG_SV.log(l_module_name,  ' AUTOCREATE DELIVERIES', X_ORG_INFO.AUTOCREATE_DELIVERIES);
     WSH_DEBUG_SV.log(l_module_name,  ' STAGING SUBINVENTORY', X_ORG_INFO.TO_SUBINVENTORY);
     WSH_DEBUG_SV.log(l_module_name,  ' STAGING LOCATOR ID', X_ORG_INFO.TO_LOCATOR);
     WSH_DEBUG_SV.log(l_module_name,  ' PICK SEQ RULE ID', X_ORG_INFO.PICK_SEQ_RULE_ID);
     WSH_DEBUG_SV.log(l_module_name,  ' PICK GROUPING RULE ID', X_ORG_INFO.PICK_GROUPING_RULE_ID);
     WSH_DEBUG_SV.log(l_module_name,  ' ENFORCE SHIP SET AND SMC', X_ORG_INFO.ENFORCE_SHIP_SET_AND_SMC);
     WSH_DEBUG_SV.log(l_module_name,  ' PICK RELEASE DOCUMENT SET ID', X_ORG_INFO.DOC_SET_ID);
     WSH_DEBUG_SV.log(l_module_name,  ' TASK PLANNING FLAG', X_ORG_INFO.TASK_PLANNING_FLAG);
     WSH_DEBUG_SV.log(l_module_name,  ' USE HEADER FLAG', X_ORG_INFO.USE_HEADER_FLAG);
     WSH_DEBUG_SV.log(l_module_name,  ' APPEND FLAG', X_ORG_INFO.APPEND_FLAG);
     WSH_DEBUG_SV.log(l_module_name,  ' AUTO PACK LEVEL ', X_ORG_INFO.AUTOPACK_LEVEL);
     --bug# 6689448 (replenishment project)
     WSH_DEBUG_SV.log(l_module_name,  ' DYNAMIC REPLENISHMENT FLAG ', X_ORG_INFO.DYNAMIC_REPLENISHMENT_FLAG);
  END IF;

  x_org_info.express_pick_flag := 'N';

  l_express_pick_profile := NVL(FND_PROFILE.VALUE('WSH_EXPRESS_PICK'), 'N');
  IF l_debug_on THEN
     WSH_DEBUG_SV.logmsg(l_module_name,'Profile WSH_EXPRESS_PICK value '||l_express_pick_profile);
  END IF;

  -- 40. Express Pickup only if Profile is yes AND Have prior reservation AND Ato Pick Confirm select as Yes.
  IF l_express_pick_profile = 'Y' THEN
     IF x_org_info.wms_org = 'N' AND WSH_PR_CRITERIA.g_existing_rsvs_only_flag = 'Y'
     AND x_org_info.auto_pick_confirm = 'Y' THEN
        x_org_info.express_pick_flag := 'Y';
        IF l_debug_on THEN
           WSH_DEBUG_SV.logmsg(l_module_name,'*** Enabling Express Pick. SMCs will not be picked ***');
        END IF;
     ELSE
        IF l_debug_on THEN
           WSH_DEBUG_SV.logmsg(l_module_name,'*** Disabling Express Pick ***');
        END IF;
     END IF;
   -- Bug 4775539
           WSH_PR_CRITERIA.g_honor_pick_from := 'Y';
	  --Get the honor pick from profile value default is Y.
             WSH_PR_CRITERIA.g_honor_pick_from := NVL(FND_PROFILE.VALUE('WSH_HONOR_PICK_FROM'), 'Y');
      END IF;

  -- 50. Check to see if rules need to be initialized for organization
  IF (l_init_rules = FND_API.G_FALSE OR WSH_PR_CRITERIA.g_pick_grouping_rule_id IS NULL
  OR WSH_PR_CRITERIA.g_pick_seq_rule_id IS NULL) THEN --{
      IF l_debug_on THEN
         WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_PR_CRITERIA.Init_Rules',WSH_DEBUG_SV.C_PROC_LEVEL);
      END IF;

      WSH_PR_CRITERIA.Init_Rules(x_org_info.pick_seq_rule_id, x_org_info.pick_grouping_rule_id, x_return_status);
      IF (x_return_status = WSH_UTIL_CORE.G_RET_STS_SUCCESS) THEN

         IF l_debug_on THEN
            WSH_DEBUG_SV.logmsg(l_module_name,  'INITIALIZATION OF RULES SUCESSFUL');
         END IF;

      ELSIF (x_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) OR (x_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR) THEN
         WSH_UTIL_CORE.PrintMsg('Error occurred in WSH_PR_CRITERIA.Init_Rules');

         IF l_debug_on THEN
           WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:INIT_RULES');
           RETURN; -- back to calling API
         END IF;
      END IF;

  END IF; --}

  IF l_debug_on THEN
     WSH_DEBUG_SV.pop(l_module_name);
  END IF;


EXCEPTION
      --
      WHEN OTHERS THEN
         IF get_default_confirm%ISOPEN THEN
            CLOSE get_default_confirm;
         END IF;
         x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
         IF l_debug_on THEN
            WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '
                                || SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
            WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
         END IF;

END Get_Org_Params;

-- Start of comments
-- API name : Spawn_Workers
-- Type     : Private
-- Pre-reqs : None.
-- Procedure: This API spawns child requests based on input parameters.
-- Parameters :
-- IN:
--      p_batch_id            IN  Batch Id.
--      p_num_requests        IN  Number of child requests.
--      p_mode                IN  Mode.
--      p_req_status          IN  Current Request Status (0 - Success, 1 - Warning).
--      p_log_level           IN  Set the debug log level.
-- OUT:
--      x_return_status       OUT NOCOPY  Return Status.
-- End of comments
PROCEDURE Spawn_Workers(
      p_batch_id                        IN      NUMBER,
      p_num_requests                    IN      NUMBER,
      p_mode                            IN      VARCHAR2,
      p_req_status                      IN      VARCHAR2,
      p_log_level                       IN      NUMBER,
      x_return_status                   OUT NOCOPY VARCHAR2)
IS

  l_debug_on BOOLEAN;
  l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'SPAWN_WORKERS';

  l_request_id NUMBER;

BEGIN

  x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

  l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
  IF l_debug_on IS NULL THEN
     l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
  END IF;

  IF l_debug_on THEN
     WSH_DEBUG_SV.push(l_module_name);
     WSH_DEBUG_SV.log(l_module_name,'P_BATCH_ID ',P_BATCH_ID);
     WSH_DEBUG_SV.log(l_module_name,'P_NUM_REQUESTS ',P_NUM_REQUESTS);
     WSH_DEBUG_SV.log(l_module_name,'P_MODE ',P_MODE);
     WSH_DEBUG_SV.log(l_module_name,'P_REQ_STATUS ',P_REQ_STATUS);
     WSH_DEBUG_SV.log(l_module_name,'P_LOG_LEVEL',P_LOG_LEVEL);
  END IF;

  IF p_mode IN ('PICK','PICK-SS','PS') THEN
  --{
     FOR i IN 1..p_num_requests LOOP
         IF l_debug_on THEN
            WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit FND_REQUEST.Submit_Request',WSH_DEBUG_SV.C_PROC_LEVEL);
            WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
         END IF;
         l_request_id := FND_REQUEST.Submit_Request(
                                                      application => 'WSH',
                                                      program     => 'WSHPSGL_SUB',
                                                      description => '',
                                                      start_time  => '',
                                                      sub_request => TRUE,       -- Child Request
                                                      argument1   => p_batch_id,
                                                      argument2   => i,          -- Worker ID
                                                      argument3   => p_mode,
                                                      argument4   => p_log_level
                                                   );
         IF l_request_id = 0 THEN
            -- If request submission failed, exit with error.
            IF l_debug_on THEN
               WSH_DEBUG_SV.logmsg(l_module_name,'Request submission failed for Worker '||i);
               WSH_DEBUG_SV.pop(l_module_name);
            END IF;
            x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
            RETURN;
         ELSE
            IF l_debug_on THEN
               WSH_DEBUG_SV.logmsg(l_module_name,'Request '||l_request_id||' submitted successfully');
            END IF;
         END IF;
     END LOOP;
  --}
  END IF;

  IF l_debug_on THEN
     WSH_DEBUG_SV.logmsg(l_module_name,'Setting Parent Request to pause');
  END IF;
  FND_CONC_GLOBAL.Set_Req_Globals ( Conc_Status => 'PAUSED', Request_Data => p_batch_id ||':'|| p_req_status
                                                                             ||':'|| p_mode );

  IF l_debug_on THEN
     WSH_DEBUG_SV.pop(l_module_name);
  END IF;

EXCEPTION
      --
      WHEN OTHERS THEN
         x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
         IF l_debug_on THEN
            WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '
                                || SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
            WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
         END IF;

END Spawn_Workers;


-- Start of comments
-- API name : Print_Docs
-- Type     : Private
-- Pre-reqs : None.
-- Procedure: This API will print all Documents that are part of Pick Release Document Set
--            and the Pick Slip Report.
-- Parameters :
-- IN:
--      p_batch_id                  IN  Pick Release Batch Id.
--      p_organization_id           IN  Organization Id.
--      p_print_ps                  IN  Print Pick Slip Report.
--      p_ps_mode                   IN  Pick Slip Printing Mode , Valid Values I/E.
--      p_doc_set_id                IN  Pick Release Document Set.
--      p_batch_name                IN  Batch Name.
--      p_order_number              IN  Order Number.
-- OUT:
--      x_return_status             OUT NOCOPY  Return Status.
-- End of comments
PROCEDURE Print_docs(
     p_batch_id         IN  NUMBER,
     p_organization_id  IN  NUMBER,
     p_print_ps         IN  VARCHAR2,
     p_ps_mode          IN  VARCHAR2,
     p_doc_set_id       IN  NUMBER,
     p_batch_name       IN  VARCHAR2,
     p_order_number     IN  NUMBER,
     x_return_status    OUT NOCOPY VARCHAR2
) IS

  CURSOR c_get_printers IS
  SELECT distinct printer_name,conc_program_name
  FROM   wsh_pr_workers
  WHERE  batch_id = p_batch_id
  AND    organization_id = p_organization_id
  AND    type = 'PRINTER';

  CURSOR c_order_number(l_header_id NUMBER) IS
  SELECT source_header_number
  FROM   wsh_delivery_details
  WHERE  source_header_id = l_header_id
  AND    rownum = 1;

  l_debug_on    BOOLEAN;
  l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'Print_Docs';

  l_document_info WSH_DOCUMENT_SETS.document_set_tab_type;
  l_null_ids      WSH_UTIL_CORE.Id_Tab_Type;
  l_return_status VARCHAR2(1);
  l_message       VARCHAR2(2000);
  l_order_number  VARCHAR2(30);

BEGIN
  l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
  IF l_debug_on IS NULL THEN
     l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
  END IF;

  IF l_debug_on THEN
     WSH_DEBUG_SV.push(l_module_name);
     WSH_DEBUG_SV.log(l_module_name,'P_BATCH_ID',P_BATCH_ID);
     WSH_DEBUG_SV.log(l_module_name,'P_ORGANIZATION_ID',P_ORGANIZATION_ID);
     WSH_DEBUG_SV.log(l_module_name,'P_PRINT_PS',P_PRINT_PS);
     WSH_DEBUG_SV.log(l_module_name,'P_PS_MODE',P_PS_MODE);
     WSH_DEBUG_SV.log(l_module_name,'P_DOC_SET_ID',P_DOC_SET_ID);
     WSH_DEBUG_SV.log(l_module_name,'P_BATCH_NAME',P_BATCH_NAME);
     WSH_DEBUG_SV.log(l_module_name,'P_ORDER_NUMBER',P_ORDER_NUMBER);
  END IF;
  x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

  WSH_INV_INTEGRATION_GRP.G_PRINTERTAB.delete;

  FOR crec in c_get_printers LOOP
      WSH_INV_INTEGRATION_GRP.G_PRINTERTAB(WSH_INV_INTEGRATION_GRP.G_PRINTERTAB.COUNT+1).printer_name := crec.printer_name;
      WSH_INV_INTEGRATION_GRP.G_PRINTERTAB(WSH_INV_INTEGRATION_GRP.G_PRINTERTAB.COUNT).conc_program_name := crec.conc_program_name;
    --
    IF l_debug_on THEN
       WSH_DEBUG_SV.logmsg(l_module_name,  'Calling Print_Document_sets for crec.printer_name  ' || crec.printer_name );
        WSH_DEBUG_SV.logmsg(l_module_name,  'Calling Print_Document_sets for crec.conc_program_name  ' || crec.conc_program_name );
   END IF ;
   --
  END LOOP;

  IF p_print_ps = 'Y' THEN
  --{
     IF l_debug_on THEN
        WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
        WSH_DEBUG_SV.logmsg(l_module_name,  'PRINT PICK SLIP REPORT'  );
        WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_PR_PICK_SLIP_NUMBER.PRINT_PICK_SLIP'
                                         ,WSH_DEBUG_SV.C_PROC_LEVEL);
     END IF;
     WSH_PR_PICK_SLIP_NUMBER.Print_Pick_Slip (
                                               p_report_set_id   => WSH_PICK_LIST.G_SEED_DOC_SET,
                                               p_organization_id => p_organization_id,
                                               p_order_header_id => WSH_PR_CRITERIA.g_order_header_id,
                                               p_ps_mode         => p_ps_mode,
                                               p_batch_id        => p_batch_id,
                                               x_api_status      => l_return_status,
                                               x_error_message   => l_message );
     IF l_debug_on THEN
       WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
     END IF;
     IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR)
     OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) THEN
         WSH_UTIL_CORE.PrintMsg('Warning: Cannot Print Report(s)');
         WSH_UTIL_CORE.PrintMsg(l_message);
         x_return_status := l_return_status;
     ELSE
         IF l_debug_on THEN
            WSH_DEBUG_SV.logmsg(l_module_name,  'PRINT PICK SLIP SUCCESSFUL'  );
         END IF;
      END IF;
  --}
  END IF;

  -- Bug 7347232 Deleting the Printer (set at Subinv or Org level) which was selected by INV for Seeded Pick Slip Report
  -- Printer selected by INV should not be used for Document set other than Seeded Pick Slip Report
 -- bugfix 13384185
  --WSH_INV_INTEGRATION_GRP.G_PRINTERTAB.delete;

  IF (p_doc_set_id <> -1 ) THEN
  --{
      IF l_debug_on THEN
         WSH_DEBUG_SV.logmsg(l_module_name,  '* PRINT DOCUMENT SET AFTER FINISHING PRINTING PICK SLIP REPORTS'  );
      END IF;
      l_document_info(1).p_report_set_id := p_doc_set_id;
      l_document_info(1).p_request_id    := FND_GLOBAL.CONC_REQUEST_ID;
      -- bug 2367043: p_move_order range should use l_batch_name, not id.
      l_document_info(1).p_move_order_h  := p_batch_name;
      l_document_info(1).p_move_order_l  := p_batch_name;
      IF (NVL(WSH_PR_CRITERIA.g_trip_id,0) > 0) THEN
          l_document_info(1).p_trip_id      := WSH_PR_CRITERIA.g_trip_id;
          l_document_info(1).p_trip_id_high := WSH_PR_CRITERIA.g_trip_id;
          l_document_info(1).p_trip_id_low  := WSH_PR_CRITERIA.g_trip_id;
      ELSIF (NVL(WSH_PR_CRITERIA.g_trip_stop_id,0) > 0) THEN
          l_document_info(1).p_trip_stop_id := WSH_PR_CRITERIA.g_trip_stop_id;
      ELSIF (NVL(WSH_PR_CRITERIA.g_delivery_id,0) > 0) THEN
          l_document_info(1).p_delivery_id := WSH_PR_CRITERIA.g_delivery_id;
          l_document_info(1).p_delivery_id_high := WSH_PR_CRITERIA.g_delivery_id;
          l_document_info(1).p_delivery_id_low  := WSH_PR_CRITERIA.g_delivery_id;
      ELSIF (NVL(WSH_PR_CRITERIA.g_order_header_id,0) > 0) THEN
          OPEN  c_order_number(WSH_PR_CRITERIA.g_order_header_id);
          FETCH c_order_number INTO l_order_number;
          CLOSE c_order_number;
          l_document_info(1).p_order_num_high := l_order_number;
          l_document_info(1).p_order_num_low  := l_order_number;
          --Bugfix 3604021 added code to pass the order type id
          l_document_info(1).p_order_type_id := WSH_PR_CRITERIA.g_order_type_id;
          l_document_info(1).p_transaction_type_id := WSH_PR_CRITERIA.g_order_type_id;
      END IF;

      IF l_debug_on THEN
         WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_DOCUMENT_SETS.PRINT_DOCUMENT_SETS'
                                           ,WSH_DEBUG_SV.C_PROC_LEVEL);
      END IF;
      ---------------------------------------------------------
      --  For printing the Document Sets for Pick Release ,
      --  only l_document_info should be passed to the
      --  Print_Document_Sets API
      --  l_document_info contains the parameters used for
      --  launching Pick Release (Refer bug 2565768)
      ---------------------------------------------------------
      l_null_ids.delete; -- ensure that the table is empty since no ids should be passed

      WSH_DOCUMENT_SETS.Print_Document_Sets (
                                              p_report_set_id       => p_doc_set_id,
                                              p_organization_id     => p_organization_id,
                                              p_trip_ids            => l_null_ids,
                                              p_stop_ids            => l_null_ids,
                                              p_delivery_ids        => l_null_ids,
                                              p_document_param_info => l_document_info,
                                              x_return_status       => l_return_status );
      IF l_debug_on THEN
         WSH_DEBUG_SV.logmsg(l_module_name,  '* END PRINT DOCUMENT SET '  );
      END IF;
      IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR)
      OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) THEN
          WSH_UTIL_CORE.PrintMsg('Warning: Cannot Print Document Set, when count=0 ');
          WSH_UTIL_CORE.PrintMsg(l_message);
          x_return_status := l_return_status;
      ELSE
          IF l_debug_on THEN
             WSH_DEBUG_SV.logmsg(l_module_name,  'PRINT DOCUMENT SET SUCCESSFUL '  );
          END IF;
      END IF;
  --}
  END IF;

  fnd_msg_pub.delete_msg(); -- Clear Msg Buffer

  IF l_debug_on THEN
     WSH_DEBUG_SV.logmsg(l_module_name,'x_return_status '||x_return_status);
     WSH_DEBUG_SV.pop(l_module_name);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
       x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
       IF l_debug_on THEN
          WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '
                              || SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
          WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
       END IF;
END Print_docs;

-- Start of comments
-- API name : Create_Move_Order_Lines
-- Type     : Private
-- Pre-reqs : None.
-- Procedure: This API will initialize Move Order Line table and then
--            call Inventory's Move Order Line API. In case of
--            Express Pick, it will call Inventory's Express Pick API
-- Parameters :
-- IN:
--      p_batch_id                  IN  Batch Id.
--      p_worker_id                 IN  Worker Id.
--      p_organization_id           IN  Organization Id.
--      p_mo_header_id              IN  Move Order Header Id.
--      p_wms_flag                  IN  Org is WMS Enabled or not, Valid Values Y/N.
--      p_auto_pick_confirm         IN  Auto Pick Confirm Flag, Valid Values Y/N.
--      p_express_pick_flag         IN  Express Pick Enabled or not, Valid Values Y/N.
--      p_pick_slip_grouping_rule   IN  Pick Slip Grouping Rule Id.
--      p_to_subinventory           IN  Staging Subinventory
--      p_to_locator                IN  Staging Locator
-- IN OUT:
--      x_curr_count                IN OUT NOCOPY  Counter for Move Order Line Number
-- OUT:
--      x_return_status             OUT NOCOPY  Return Status.
-- End of comments
PROCEDURE Create_Move_Order_Lines(
      p_batch_id                     IN      NUMBER,
      p_worker_id                    IN      NUMBER,
      p_organization_id              IN      NUMBER,
      p_mo_header_id                 IN      NUMBER,
      p_wms_flag                     IN      VARCHAR2,
      p_auto_pick_confirm            IN      VARCHAR2,
      p_express_pick_flag            IN      VARCHAR2,
      p_pick_slip_grouping_rule      IN      NUMBER,
      p_to_subinventory              IN      VARCHAR2,
      p_to_locator                   IN      VARCHAR2,
      p_use_header_flag              IN      WSH_SHIPPING_PARAMETERS.AUTOCREATE_DEL_ORDERS_PR_FLAG%TYPE, -- bug 8623544
      x_curr_count                   IN OUT NOCOPY   NUMBER,
      x_return_status                OUT NOCOPY VARCHAR2)
IS

  --Cursor to get the Trip stop id associated with the PickUp Stop of delivery detail line.
  CURSOR get_dd_pup_trip_stop(v_org_id IN NUMBER, v_dd_id NUMBER) IS
  SELECT wts.STOP_ID
  FROM   wsh_trips wt, wsh_trip_stops wts, wsh_delivery_assignments_v wda,
         wsh_delivery_legs wdl, wsh_delivery_details wdd
  WHERE  wdd.delivery_detail_id = v_dd_id
  AND    wdd.organization_id    = v_org_id
  AND    wda.delivery_detail_id = wdd.delivery_detail_id
  AND    wdl.delivery_id        = wda.delivery_id
  AND    wts.stop_id            = wdl.pick_up_stop_id
  AND    wts.trip_id            = wt.trip_id;

  -- Workflow Change
  CURSOR c_get_picked_lines_count (c_delivery_detail_id NUMBER) IS
  SELECT count (wdd.delivery_detail_id), delivery_id
  FROM   wsh_delivery_details wdd, wsh_delivery_assignments_v wda
  WHERE  wdd.delivery_detail_id = wda.delivery_detail_id
  AND    wda.delivery_id = (  SELECT delivery_id
                              FROM wsh_delivery_assignments_v
                              WHERE delivery_detail_id = c_delivery_detail_id )
  AND    wdd.released_status NOT IN ('R', 'X', 'N')
  AND    wdd.pickable_flag = 'Y'
  AND    wdd.container_flag = 'N'
  GROUP  BY delivery_id;
  -- Workflow Change


  TYPE Stops_Ids_Rec IS RECORD ( Staging_Subinventory    VARCHAR2(10),
                                 Staging_Lane_Id         NUMBER        );

  TYPE Stops_Ids_Tbl IS TABLE OF Stops_Ids_Rec INDEX BY BINARY_INTEGER;

  l_Stops_Ids_Tbl		 Stops_Ids_Tbl;

  l_debug_on BOOLEAN;
  l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'CREATE_MOVE_ORDER_LINES';

  i                              NUMBER;
  l_count                        NUMBER;
  l_count_x_relstatus_details    NUMBER;
  l_temp_trolin_rec              INV_MOVE_ORDER_PUB.Trolin_Rec_Type;
  l_trolin_tbl                   INV_MOVE_ORDER_PUB.Trolin_Tbl_Type;
  l_trolin_val_tbl               INV_MOVE_ORDER_PUB.Trolin_Val_Tbl_Type;
  l_rel_delivery_detail_id 	 WSH_UTIL_CORE.Id_Tab_Type;
  l_dummy_rsv_tbl                INV_RESERVATION_GLOBAL.Mtl_Reservation_Tbl_Type;

  -- WMS
  l_attr_tab                      WSH_DELIVERY_AUTOCREATE.Grp_attr_tab_type;
  l_group_tab                     WSH_DELIVERY_AUTOCREATE.Grp_attr_tab_type;
  l_action_rec                    WSH_DELIVERY_AUTOCREATE.Action_rec_type;
  l_target_rec                    WSH_DELIVERY_AUTOCREATE.Grp_attr_rec_type;
  l_matched_entities              WSH_UTIL_CORE.id_tab_type;
  l_out_rec                       WSH_DELIVERY_AUTOCREATE.Out_rec_type;
  l_dd_pup_stop_id               NUMBER;
  x_wms_return_status            VARCHAR2(1);
  x_wms_msg_count                NUMBER;
  x_wms_msg_data                 VARCHAR2(2000);
  x_wms_stg_ln_id                NUMBER;
  x_wms_sub_code                 VARCHAR2(10);

  l_user_id                      NUMBER;
  l_login_id                     NUMBER;
  l_date                         DATE;
  l_api_version_number           NUMBER := 1.0;
  l_msg_count                    NUMBER;
  l_msg_data                     VARCHAR2(2000);
  l_commit                       VARCHAR2(1) := FND_API.G_FALSE;
  l_return_status                VARCHAR2(1);
  l_request_id                   NUMBER;
  l_item_name                    VARCHAR2(2000);
  l_message                      VARCHAR2(2000);
  l_message1                     VARCHAR2(2000);
  l_exception_name           WSH_EXCEPTION_DEFINITIONS_TL.EXCEPTION_NAME%TYPE;
  l_exception_return_status      VARCHAR2(30);
  l_exception_msg_count          NUMBER;
  l_exception_msg_data           VARCHAR2(4000) := NULL;
  l_dummy_exception_id           NUMBER;

  -- DBI Project
  l_detail_tab                   WSH_UTIL_CORE.Id_Tab_Type;
  l_dbi_rs                       VARCHAR2(1);               -- DBI Project
  l_dd_txn_id                    NUMBER;            -- DBI Project
  l_txn_return_status            VARCHAR2(1);       -- DBI Project

  -- Workflow Change
  l_count_picked_lines NUMBER;
  l_delv_id NUMBER;
  l_wf_rs VARCHAR2(1); --Pick to POD WF Project

  l_del_detail_id   WSH_PICK_LIST.DelDetTabTyp;
  j NUMBER;

   --bug  7171766
   l_match_found BOOLEAN;
   l_group_match_seq_tbl    WSH_PICK_LIST.group_match_seq_tab_type;
   K NUMBER ;
   --Added for Standalone project Changes
   l_standalone_mode                VARCHAR2(1);

BEGIN

  x_return_status     := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

  l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
  IF l_debug_on IS NULL THEN
     l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
  END IF;

  l_standalone_mode := WMS_DEPLOY.wms_deployment_mode; -- Standalone project Changes Start

  IF l_debug_on THEN
     WSH_DEBUG_SV.push(l_module_name);
     WSH_DEBUG_SV.log(l_module_name,'P_BATCH_ID',P_BATCH_ID);
     WSH_DEBUG_SV.log(l_module_name,'P_WORKER_ID',P_WORKER_ID);
     WSH_DEBUG_SV.log(l_module_name,'P_ORGANIZATION_ID',P_ORGANIZATION_ID);
     WSH_DEBUG_SV.log(l_module_name,'P_MO_HEADER_ID',P_MO_HEADER_ID);
     WSH_DEBUG_SV.log(l_module_name,'P_WMS_FLAG',P_WMS_FLAG);
     WSH_DEBUG_SV.log(l_module_name,'P_AUTO_PICK_CONFIRM',P_AUTO_PICK_CONFIRM);
     WSH_DEBUG_SV.log(l_module_name,'P_EXPRESS_PICK_FLAG',P_EXPRESS_PICK_FLAG);
     WSH_DEBUG_SV.log(l_module_name,'P_PICK_SLIP_GROUPING_RULE',P_PICK_SLIP_GROUPING_RULE);
     WSH_DEBUG_SV.log(l_module_name,'P_TO_SUBINVENTORY',P_TO_SUBINVENTORY);
     WSH_DEBUG_SV.log(l_module_name,'P_TO_LOCATOR',P_TO_LOCATOR);
     WSH_DEBUG_SV.log(l_module_name,'l_standalone_mode',l_standalone_mode);
  END IF;

  -- Clear move order lines tables
  g_trolin_tbl.delete;
  l_trolin_val_tbl.delete;
  g_trolin_delivery_ids.delete;
  g_del_detail_ids.delete;
  l_rel_delivery_detail_id.delete;
  l_count := 0;
  l_count_x_relstatus_details := 0;

  g_xdock_delivery_ids.delete;
  g_xdock_detail_ids.delete;

  l_user_id  := WSH_PR_CRITERIA.g_user_id;
  l_login_id := WSH_PR_CRITERIA.g_login_id;
  l_date     := SYSDATE;

  -- X-dock
  -- Call to WMS API to process lines for X-dock
  IF g_allocation_method IN (WSH_PICK_LIST.C_CROSSDOCK_ONLY, WSH_PICK_LIST.C_PRIORITIZE_CROSSDOCK) THEN --{
    IF l_debug_on THEN
      WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
      WSH_DEBUG_SV.log(l_module_name,'Release Table Count',wsh_pr_criteria.release_table.count);
      WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit '||'WMS_XDOCK_PEGGING_PUB.PLANNED_CROSS_DOCK',WSH_DEBUG_SV.C_PROC_LEVEL);
    END IF;

    -- Parameters description :
    -- P_DEL_DETAIL_ID (g_xdock_detail_ids) :contains the list of delivery details which have been
    --                    successfully planned for X-dock
    -- P_TROLIN_DELIVERY_IDS (g_xdock_delivery_ids) : Matches index with p_del_detail_id and stores
    --                    delivery ids for the delivery details(derived from release_table)
    -- P_WSH_RELEASE_TABLE(wsh_pr_criteria.release_table) : IN/OUT variable, in case of splitting
    --                    of delivery details new records will be added to p_wsh_release_table
    --
    WMS_Xdock_Pegging_Pub.Planned_Cross_Dock
      (p_api_version         => l_api_version_number,
       p_init_msg_list       => fnd_api.g_false,
       p_commit              => l_commit,
       p_batch_id            => p_batch_id,
       p_wsh_release_table   => wsh_pr_criteria.release_table,
       p_trolin_delivery_ids => g_xdock_delivery_ids,
       p_del_detail_id       => g_xdock_detail_ids,
       x_return_status       => l_return_status,
       x_msg_count           => l_msg_count,
       x_msg_data            => l_msg_data
      );
    IF l_debug_on THEN
      WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
      WSH_DEBUG_SV.log(l_module_name,'After Calling WMS API-Planned_Cross_Dock',l_return_status);
      WSH_DEBUG_SV.log(l_module_name,'Release Table Count',wsh_pr_criteria.release_table.count);
      WSH_DEBUG_SV.log(l_module_name,'G_XDOCK_DELIVERY_IDS Table Count',g_xdock_delivery_ids.count);
      WSH_DEBUG_SV.log(l_module_name,'G_XDOCK_DETAIL_IDS Table Count',g_xdock_detail_ids.count);
    END IF;

    IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR)
        OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) THEN--{
      x_return_status := l_return_status;
      WSH_UTIL_CORE.PrintMsg('Error occurred in WMS API Planned_Cross_Dock');
      IF l_debug_on THEN
        WSH_DEBUG_SV.pop(l_module_name);
      END IF;
      -- the parent API handles the errors raised from create_move_order_lines
      RETURN;
    ELSIF l_return_status = WSH_UTIL_CORE.G_RET_STS_WARNING THEN
      x_return_status := l_return_status;
      WSH_UTIL_CORE.PrintMsg('Warning returned from WMS API Planned_Cross_Dock');
      IF g_xdock_detail_ids.count <> wsh_pr_criteria.release_table.count THEN --{
        --there is atleast one delivery detail which was not crossdocked
        --Need to log exception for that delivery detail
        --WMS Crossdock API will set the released_status to 'S' for lines which are
        --crossdocked
        FOR i in WSH_PR_CRITERIA.release_table.FIRST..WSH_PR_CRITERIA.release_table.LAST
        LOOP
        IF WSH_PR_CRITERIA.release_table(i).released_status IN ('R','B','X') THEN --{

          IF WSH_PR_CRITERIA.release_table(i).non_reservable_flag = 'Y' THEN
            l_exception_name := 'WSH_PICK_XDOCK_NR';  -- ECO 5220234
          ELSE
            l_exception_name := 'WSH_PICK_XDOCK';
          END IF;

          FND_MESSAGE.SET_NAME('WSH', l_exception_name);
          l_message := FND_MESSAGE.GET;
          l_exception_return_status := NULL;
          l_exception_msg_count := NULL;
          l_exception_msg_data := NULL;
          l_dummy_exception_id := NULL;
          IF l_debug_on THEN
            WSH_DEBUG_SV.logmsg(l_module_name,
                        'Log exception for Detail, id- '
                        ||WSH_PR_CRITERIA.release_table(i).delivery_detail_id
                        || ', ' || l_exception_name);
          END IF;

          wsh_xc_util.log_exception(
            p_api_version            => 1.0,
            p_logging_entity         => 'SHIPPER',
            p_logging_entity_id      => FND_GLOBAL.USER_ID,
            p_exception_name         => l_exception_name,
            p_message                => l_message,
            p_inventory_item_id      => WSH_PR_CRITERIA.release_table(i).inventory_item_id,
            p_logged_at_location_id  => WSH_PR_CRITERIA.release_table(i).ship_from_location_id,
            p_exception_location_id  => WSH_PR_CRITERIA.release_table(i).ship_from_location_id,
            p_request_id             => l_request_id,
            p_batch_id               => WSH_PICK_LIST.g_batch_id,
            p_delivery_detail_id     => WSH_PR_CRITERIA.release_table(i).delivery_detail_id,
            x_return_status          => l_exception_return_status,
            x_msg_count              => l_exception_msg_count,
            x_msg_data               => l_exception_msg_data,
            x_exception_id           => l_dummy_exception_id);

          IF l_debug_on THEN
            WSH_DEBUG_SV.logmsg(l_module_name,  'LOGGED EXCEPTION '||L_DUMMY_EXCEPTION_ID  );
          END IF;
        END IF; --}
        END LOOP;
      END IF; --}
    END IF;--}

  END IF; --}
  --  end of X-dock related call

  -- If p_num_workers in Release_Batch api is 1 and WMS Org, then Generate Grouping Ids for the lines
  -- X-dock,cartonization is not applicable for X-dock only mode
  IF p_worker_id IS NULL AND WSH_PICK_LIST.G_NUM_WORKERS = 1 AND p_wms_flag = 'Y'
  AND WSH_PR_CRITERIA.release_table.count > 0
  AND g_allocation_method IN (WSH_PICK_LIST.C_INVENTORY_ONLY,
                              WSH_PICK_LIST.C_PRIORITIZE_CROSSDOCK,
                              WSH_PICK_LIST.C_PRIORITIZE_INVENTORY)
  THEN --{
     IF l_debug_on THEN
        WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
     END IF;
     l_attr_tab.delete;
     FOR i in 1.. WSH_PR_CRITERIA.release_table.count LOOP
         l_attr_tab(i).entity_id := WSH_PR_CRITERIA.release_table(i).delivery_detail_id;
         l_attr_tab(i).entity_type := 'DELIVERY_DETAIL';
       IF WSH_PR_CRITERIA.release_table(i).released_status = 'S' THEN
         -- delivery detail is X-docked, pass flag to ignore this line for grouping
         IF l_debug_on THEN
           WSH_DEBUG_SV.log(l_module_name,'X-docked Detail id-', WSH_PR_CRITERIA.release_table(i).delivery_detail_id);
         END IF;
         l_attr_tab(i).is_xdocked_flag := 'Y';
       END IF;
     END LOOP;
     -- LSP PROJECT : Use_header_flag value defaulting (from org/client defaults) has been moved to the calling API
     --          WSH_DELIVERY_AUTOCREATE.Find_Matching_Groups/Create_Hash and to recognize the change
     --          passing action code as 'MATCH_GROUPS_AT_PICK' instead of 'MATCH_GROUPS'.
     l_action_rec.action := 'MATCH_GROUPS_AT_PICK';
     -- LSP PROJECT : end
     l_action_rec.group_by_header_flag := p_use_header_flag ; --bug 8623544

     WSH_DELIVERY_AUTOCREATE.Find_Matching_Groups(
                                                   p_attr_tab => l_attr_tab,
                                                   p_action_rec => l_action_rec,
                                                   p_target_rec => l_target_rec,
                                                   p_group_tab => l_group_tab,
                                                   x_matched_entities => l_matched_entities,
                                                   x_out_rec => l_out_rec,
                                                   x_return_status => l_return_status);

     IF l_debug_on THEN
        WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
        WSH_DEBUG_SV.log(l_module_name,'WSH_DELIVERY_AUTOCREATE.Find_Matching_Groups l_return_status',l_return_status);
     END IF;
     IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR)
     OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) THEN
         x_return_status := l_return_status;
         WSH_UTIL_CORE.PrintMsg('Error occurred in WSH_DELIVERY_AUTOCREATE.Find_Matching_Groups');
         IF l_debug_on THEN
            WSH_DEBUG_SV.pop(l_module_name);
         END IF;
         RETURN;
     END IF;
  END IF; --}

  -- X-dock
  -- Populate trolin_tbl only for these allocation methods, this call is not
  -- required for X-dock only
  IF g_allocation_method IN (WSH_PICK_LIST.C_INVENTORY_ONLY,
                              WSH_PICK_LIST.C_PRIORITIZE_CROSSDOCK,
                              WSH_PICK_LIST.C_PRIORITIZE_INVENTORY) THEN
  --{

    -- Print before the loop
    IF l_debug_on THEN
      WSH_DEBUG_SV.log(l_module_name, 'ALLOCATION METHOD', g_allocation_method);
    END IF;

  --bug 7171766
  l_group_match_seq_tbl.delete;

  -- Looping through Release Table
  FOR i in 1..WSH_PR_CRITERIA.release_table.count LOOP
  --{
      IF l_debug_on THEN
         WSH_DEBUG_SV.log(l_module_name, 'PROCESSING DELIVERY DETAIL', WSH_PR_CRITERIA.RELEASE_TABLE(I).DELIVERY_DETAIL_ID);
      END IF;
      IF (nvl(g_order_number, 0) <> WSH_PR_CRITERIA.release_table(i).source_header_number) THEN
          g_order_number := WSH_PR_CRITERIA.release_table(i).source_header_number;
      END IF;
      IF l_debug_on THEN
        WSH_DEBUG_SV.log(l_module_name, 'Released Status of Detail', WSH_PR_CRITERIA.RELEASE_TABLE(I).RELEASED_STATUS);
      END IF;
      IF (WSH_PR_CRITERIA.release_table(i).released_status = 'X') THEN
      --{
         IF l_debug_on THEN
            WSH_DEBUG_SV.logmsg(l_module_name,'IGNORING NON-TRANSACTABLE LINE FOR MOVE ORDER LINE CREATION');
         END IF;
         l_count_x_relstatus_details := l_count_x_relstatus_details + 1;
         l_rel_delivery_detail_id(l_count_x_relstatus_details):= WSH_PR_CRITERIA.release_table(i).delivery_detail_id;
      --}
      -- X-dock, X-dock lines which have been processed above
      -- will have released status of S
      ELSIF (WSH_PR_CRITERIA.release_table(i).released_status = WSH_DELIVERY_DETAILS_PKG.C_RELEASED_TO_WAREHOUSE) THEN --{
         IF l_debug_on THEN
            WSH_DEBUG_SV.logmsg(l_module_name,'IGNORING PLANNED X-DOCK LINE FOR MOVE ORDER LINE CREATION');
         END IF;
      --}
      ELSE
      --{
      --
         l_count := l_count + 1;
         g_del_detail_ids(l_count)       := WSH_PR_CRITERIA.release_table(i).delivery_detail_id;
         g_trolin_delivery_ids(l_count) := WSH_PR_CRITERIA.release_table(i).delivery_id;
         g_trolin_tbl(l_count).line_number := WSH_PR_CRITERIA.release_table(i).line_number;
         g_trolin_tbl(l_count).txn_source_line_detail_id := WSH_PR_CRITERIA.release_table(i).delivery_detail_id;
         g_trolin_tbl(l_count).created_by         := l_user_id;
         g_trolin_tbl(l_count).creation_date      := l_date;
         g_trolin_tbl(l_count).last_updated_by    := l_user_id;
         g_trolin_tbl(l_count).last_update_date   := l_date;
         g_trolin_tbl(l_count).last_update_login  := l_login_id;
         g_trolin_tbl(l_count).header_id          := p_mo_header_id;
         --Bug8683087 passing mtl_sales_order header_id
 	 g_trolin_tbl(l_count).txn_source_id      := WSH_PR_CRITERIA.release_table(i).demand_source_header_id;
         g_trolin_tbl(l_count).txn_source_line_id := WSH_PR_CRITERIA.release_table(i).source_line_id;
         g_trolin_tbl(l_count).organization_id    := p_organization_id;
         g_trolin_tbl(l_count).date_required      := WSH_PR_CRITERIA.release_table(i).date_scheduled;
         IF ((WSH_PR_CRITERIA.release_table(i).from_sub is NOT NULL) AND (WSH_PR_CRITERIA.g_from_subinventory IS NULL)) THEN
              g_trolin_tbl(l_count).from_subinventory_code := WSH_PR_CRITERIA.release_table(i).from_sub;
              -- Standalone project Changes : Begin
              -- LSP PROJECT : consider LSP mode also.
              IF (l_standalone_mode = 'D' OR (l_standalone_mode = 'L' AND WSH_PR_CRITERIA.release_table(i).client_id IS NOT NULL)) THEN
                 g_trolin_tbl(l_count).from_locator_id        := WSH_PR_CRITERIA.release_table(i).from_locator;
              END IF;
         ELSE
              g_trolin_tbl(l_count).from_subinventory_code := WSH_PR_CRITERIA.g_from_subinventory;
              -- Standalone project Changes
              -- wdd's loc id should be considered when released with pick from sub and no pick from loc
              --
              -- LSP PROJECT : consider LSP mode also.
              IF ((l_standalone_mode = 'D' OR (l_standalone_mode = 'L' AND WSH_PR_CRITERIA.release_table(i).client_id IS NOT NULL)) AND WSH_PR_CRITERIA.g_from_locator IS NULL) THEN
                 IF (g_trolin_tbl(l_count).from_subinventory_code = WSH_PR_CRITERIA.g_from_subinventory) THEN
                     g_trolin_tbl(l_count).from_locator_id        := WSH_PR_CRITERIA.release_table(i).from_locator;
                 ELSE
                     g_trolin_tbl(l_count).from_locator_id        := NULL;
                 END IF;
              ELSE
                 g_trolin_tbl(l_count).from_locator_id        := WSH_PR_CRITERIA.g_from_locator;
              END IF;
         END IF;
         -- Standalone project Changes
         -- LSP PROJECT : consider LSP mode also.
         IF (l_standalone_mode = 'D' OR (l_standalone_mode = 'L' AND WSH_PR_CRITERIA.release_table(i).client_id IS NOT NULL)) THEN
            g_trolin_tbl(l_count).revision   := WSH_PR_CRITERIA.release_table(i).revision;
            g_trolin_tbl(l_count).lot_number := WSH_PR_CRITERIA.release_table(i).lot_number;
         END IF;
         g_trolin_tbl(l_count).to_subinventory_code := p_to_subinventory;
         g_trolin_tbl(l_count).to_locator_id        := p_to_locator;
         --
         IF l_debug_on THEN
             WSH_DEBUG_SV.logmsg(l_module_name,  'DD id : '||g_del_detail_ids(l_count) );
             WSH_DEBUG_SV.logmsg(l_module_name,  'from sub : '||g_trolin_tbl(l_count).from_subinventory_code );
             WSH_DEBUG_SV.logmsg(l_module_name,  'from loc : '||g_trolin_tbl(l_count).from_locator_id );
             WSH_DEBUG_SV.logmsg(l_module_name,  'rev : '||g_trolin_tbl(l_count).revision );
             WSH_DEBUG_SV.logmsg(l_module_name,  'lot : '||g_trolin_tbl(l_count).lot_number );
         END IF;
         --- Standalone project Changes: end

         -- If p_num_workers in Release_Batch api is 1 and WMS Org, then populate Carton Grouping Ids for the lines
         IF p_worker_id IS NULL AND WSH_PICK_LIST.G_NUM_WORKERS = 1 AND p_wms_flag = 'Y' THEN
	 --{
	      --bug 7171766
              l_match_found :=FALSE;

	      IF l_group_match_seq_tbl.count > 0 THEN
	      --{
		k:= l_group_match_seq_tbl.FIRST;  --Bugfix 10236089
		   WHILE k IS NOT NULL LOOP  --Bugfix 10236089
		   --{
		       IF l_attr_tab(i).group_id = l_group_match_seq_tbl(k).match_group_id THEN
		       --{
			   l_group_match_seq_tbl(i).delivery_group_id := l_group_match_seq_tbl(k).delivery_group_id ;
			   l_match_found := TRUE;
			   EXIT;
		       --}
		       End IF;
		   k:=l_group_match_seq_tbl.NEXT(k);  --Bugfix 10236089
		   --}
		   END LOOP;
	      --}
	      END IF ;

	      IF NOT l_match_found THEN
	      --{
		  l_group_match_seq_tbl(i).match_group_id :=l_attr_tab(i).group_id;
		  select WSH_DELIVERY_GROUP_S.nextval into l_group_match_seq_tbl(i).delivery_group_id from dual;
	      --}
	      End IF;

            IF l_debug_on THEN
               WSH_DEBUG_SV.logmsg(l_module_name,  'CARTON GROUPING ID : '||l_group_match_seq_tbl(i).delivery_group_id );
            END IF;

            g_trolin_tbl(l_count).carton_grouping_id := l_group_match_seq_tbl(i).delivery_group_id ;

         --}
         END IF;

         -- Get Staging Subinventory and Staging Lane for WMS Organization
         IF (p_wms_flag = 'Y') AND (WSH_PR_CRITERIA.release_table(i).delivery_detail_id IS NOT NULL) THEN
         --{
            OPEN get_dd_pup_trip_stop ( p_organization_id, WSH_PR_CRITERIA.release_table(i).delivery_detail_id );
            FETCH get_dd_pup_trip_stop INTO l_dd_pup_stop_id;
            IF get_dd_pup_trip_stop%NOTFOUND THEN
               IF l_debug_on THEN
                  WSH_DEBUG_SV.logmsg(l_module_name, 'DELIVERY DETAIL '||
                                    WSH_PR_CRITERIA.RELEASE_TABLE(I).DELIVERY_DETAIL_ID|| ' NOT ASSOCIATED TO ANY TRIP'  );
               END IF;
            ELSE
            --{
               -- If Stop_id already exists in Staging Table, use table values
               IF l_Stops_Ids_Tbl.EXISTS(l_dd_pup_stop_id) THEN
                  g_trolin_tbl(l_count).to_subinventory_code := l_Stops_Ids_Tbl(l_dd_pup_stop_id).Staging_Subinventory;
                  g_trolin_tbl(l_count).to_locator_id        := l_Stops_Ids_Tbl(l_dd_pup_stop_id).Staging_Lane_Id;
               ELSE
               --{
                  IF l_debug_on THEN
                     WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit '||
                                     'WMS_TRIPSTOPS_STAGELANES_PUB.GET_STGLN_FOR_TRIPSTOP',WSH_DEBUG_SV.C_PROC_LEVEL);
                  END IF;
                  x_wms_return_status := NULL;
                  WMS_TRIPSTOPS_STAGELANES_PUB.get_stgln_for_tripstop (
                                                                        p_org_id        => p_organization_id,
                                                                        p_trip_stop     => l_dd_pup_stop_id,
                                                                        x_stg_ln_id     => x_wms_stg_ln_id,
                                                                        x_sub_code      => x_wms_sub_code,
                                                                        x_return_status => x_wms_return_status,
                                                                        x_msg_count     => x_wms_msg_count,
                                                                        x_msg_data      => x_wms_msg_data);
                  IF l_debug_on THEN
                     WSH_DEBUG_SV.logmsg(l_module_name, 'WMS - RELATED VARIABLES ');
                     WSH_DEBUG_SV.logmsg(l_module_name, 'WMS - DD ID :'||WSH_PR_CRITERIA.RELEASE_TABLE(I).DELIVERY_DETAIL_ID);
                     WSH_DEBUG_SV.logmsg(l_module_name, 'WMS - PUP-STOPID :' || L_DD_PUP_STOP_ID);
                     WSH_DEBUG_SV.logmsg(l_module_name, 'WMS - RETN. STATUS :' || X_WMS_RETURN_STATUS);
                     WSH_DEBUG_SV.logmsg(l_module_name, 'WMS - STG. LN ID :' || X_WMS_STG_LN_ID);
                     WSH_DEBUG_SV.logmsg(l_module_name, 'WMS - STG. SUB :' || X_WMS_SUB_CODE);
                  END IF;
                  IF ( x_wms_return_status = WSH_UTIL_CORE.G_RET_STS_SUCCESS ) THEN
                             --  AND x_wms_sub_code IS NOT NULL) THEN
                       g_trolin_tbl(l_count).to_subinventory_code           := x_wms_sub_code;
                       g_trolin_tbl(l_count).to_locator_id                  := x_wms_stg_ln_id;
                       l_Stops_Ids_Tbl(l_dd_pup_stop_id).Staging_Subinventory := x_wms_sub_code;
                       l_Stops_Ids_Tbl(l_dd_pup_stop_id).Staging_Lane_Id      := x_wms_stg_ln_id;
                  END IF;
               --}
               END IF;
            --}
            END IF;
            CLOSE get_dd_pup_trip_stop;
         --}
         END IF;

         g_trolin_tbl(l_count).project_id         := WSH_PR_CRITERIA.release_table(i).project_id;
         g_trolin_tbl(l_count).task_id            := WSH_PR_CRITERIA.release_table(i).task_id;
         g_trolin_tbl(l_count).inventory_item_id  := WSH_PR_CRITERIA.release_table(i).inventory_item_id;
         g_trolin_tbl(l_count).ship_set_id        := WSH_PR_CRITERIA.release_table(i).ship_set_id;
         g_trolin_tbl(l_count).ship_model_id      := WSH_PR_CRITERIA.release_table(i).top_model_line_id;
         g_trolin_tbl(l_count).model_quantity     := WSH_PR_CRITERIA.release_table(i).top_model_quantity;
         IF l_debug_on THEN
            WSH_DEBUG_SV.logmsg(l_module_name, 'Line Number '||G_TROLIN_TBL(L_COUNT).LINE_NUMBER||
                                               ' MOVE ORDER SHIP SET '||G_TROLIN_TBL(L_COUNT).SHIP_SET_ID ||
                                               ' MODEL ID '||G_TROLIN_TBL( L_COUNT).SHIP_MODEL_ID || ' MODEL QTY '
                                               ||G_TROLIN_TBL(L_COUNT).MODEL_QUANTITY  );
         END IF;
         g_trolin_tbl(l_count).quantity           := WSH_PR_CRITERIA.release_table(i).requested_quantity;
         g_trolin_tbl(l_count).secondary_quantity := TO_NUMBER(WSH_PR_CRITERIA.release_table(i).requested_quantity2);
         g_trolin_tbl(l_count).uom_code           := WSH_PR_CRITERIA.release_table(i).requested_quantity_uom;
         g_trolin_tbl(l_count).secondary_uom      := WSH_PR_CRITERIA.release_table(i).requested_quantity_UOM2;
         g_trolin_tbl(l_count).grade_code         := WSH_PR_CRITERIA.release_table(i).preferred_grade;
         g_trolin_tbl(l_count).line_status        := INV_Globals.G_TO_STATUS_PREAPPROVED;
         g_trolin_tbl(l_count).unit_number        := WSH_PR_CRITERIA.release_table(i).unit_number;
         -- Transaction type is different for internal orders
         IF (WSH_PR_CRITERIA.release_table(i).source_doc_type = 10) THEN
             g_trolin_tbl(l_count).transaction_type_id := INV_GLOBALS.G_TYPE_INTERNAL_ORDER_STGXFR;
         ELSE
             g_trolin_tbl(l_count).transaction_type_id := INV_GLOBALS.G_TYPE_TRANSFER_ORDER_STGXFR;
         END IF;

         -- No need to create move order line for backordered line
         IF (WSH_PR_CRITERIA.release_table(i).move_order_line_id IS NOT NULL) THEN
             g_trolin_tbl(l_count).line_id := WSH_PR_CRITERIA.release_table(i).move_order_line_id;
             -- The quantity for the Backordered line should be the same as the original quantity
             IF l_debug_on THEN
                WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit INV_TROLIN_UTIL.QUERY_ROW',WSH_DEBUG_SV.C_PROC_LEVEL);
             END IF;
             l_temp_trolin_rec := INV_Trolin_Util.Query_Row( p_line_id => g_trolin_tbl(l_count).line_id );
             g_trolin_tbl(l_count).quantity := l_temp_trolin_rec.quantity;
             g_trolin_tbl(l_count).operation := INV_GLOBALS.G_OPR_UPDATE;
         ELSE
             g_trolin_tbl(l_count).operation := INV_GLOBALS.G_OPR_CREATE;
         END IF;
      --}
      END IF; -- released_status X
  --}
  END LOOP;

  END IF; --}

  --{
  -- Bulk Update all Non-Transactable lines as Staged
  IF (l_count_x_relstatus_details > 0) THEN
      FOR i IN 1..l_count_x_relstatus_details LOOP
         UPDATE wsh_delivery_details
         SET    released_status   = 'Y',
                batch_id          = p_batch_id,
                last_updated_by   = l_user_id,
                last_update_date  = l_date,
                last_update_login = l_login_id
         WHERE  delivery_detail_id = l_rel_delivery_detail_id(i);

         --Raise Event : Pick To Pod Workflow
         WSH_WF_STD.Raise_Event(
                                 p_entity_type => 'LINE',
                                 p_entity_id => l_rel_delivery_detail_id(i) ,
                                 p_event => 'oracle.apps.wsh.line.gen.staged' ,
                                 --p_parameters IN wf_parameter_list_t DEFAULT NULL,
                                 p_organization_id => p_organization_id,
                                 x_return_status => l_wf_rs ) ;

          IF l_debug_on THEN
             WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
             wsh_debug_sv.log(l_module_name,'Return Status After Calling WSH_WF_STD.Raise_Event',l_wf_rs);
          END IF;
          --Done Raise Event: Pick To Pod Workflow
      END LOOP;

      -- Update of wsh_delivery_details where released_status is changed, call DBI API after the update.
      IF l_debug_on THEN
         WSH_DEBUG_SV.log(l_module_name,'Calling DBI API.Detail Count-',l_rel_delivery_detail_id.count);
      END IF;
      WSH_INTEGRATION.DBI_Update_Detail_Log (
                                                 p_delivery_detail_id_tab => l_rel_delivery_detail_id,
                                                 p_dml_type               => 'UPDATE',
                                                 x_return_status          => l_dbi_rs );
      IF l_debug_on THEN
         WSH_DEBUG_SV.log(l_module_name,'Return Status after DBI Call-',l_dbi_rs);
      END IF;
      IF l_dbi_rs = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR THEN
         WSH_UTIL_CORE.PrintMsg('Error occurred in WSH_INTEGRATION.DBI_Update_Detail_Log');
         x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
         IF l_debug_on THEN
            WSH_DEBUG_SV.pop(l_module_name);
         END IF;
         RETURN;
      END IF;
      IF l_debug_on THEN
         WSH_DEBUG_SV.log(l_module_name,'l_count_x_relstatus_details updated ',l_count_x_relstatus_details);
      END IF;
  END IF;
  --}

  -- Move Order Lines Creation
  IF (g_trolin_tbl.count > 0)  THEN
  --{
     IF p_express_pick_flag = 'N' THEN
     --{
        IF l_debug_on THEN
           WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit INV_MOVE_ORDER_PUB.CREATE_MOVE_ORDER_LINES',
                                              WSH_DEBUG_SV.C_PROC_LEVEL);
           WSH_DEBUG_SV.log(l_module_name, 'G_TROLIN_TBL.COUNT',G_TROLIN_TBL.COUNT);
           WSH_DEBUG_SV.log(l_module_name, 'Current Time is ',SYSDATE);
        END IF;
        Inv_Move_Order_Pub.Create_Move_Order_Lines
                    (
                       p_api_version_number  => l_api_version_number,
                       p_init_msg_list       => FND_API.G_FALSE,
                       p_return_values       => FND_API.G_TRUE,
                       p_commit              => l_commit,
                       p_trolin_tbl          => g_trolin_tbl,
                       p_trolin_val_tbl      => l_trolin_val_tbl,
                       p_validation_flag     => 'N', -- Inventory will skip most validations and assume Shipping validates them
                       x_trolin_tbl          => g_trolin_tbl,
                       x_trolin_val_tbl      => l_trolin_val_tbl,
                       x_return_status       => l_return_status,
                       x_msg_count           => l_msg_count,
                       x_msg_data            => l_msg_data
                      );
        IF l_debug_on THEN
           WSH_DEBUG_SV.log(l_module_name, 'Current Time is ',SYSDATE);
           WSH_DEBUG_SV.log(l_module_name, 'Return status from INV API', l_return_status);
           WSH_DEBUG_SV.log(l_module_name, 'l_msg_count', l_msg_count);
           WSH_DEBUG_SV.log(l_module_name, 'l_msg_data', l_msg_data);
        END IF;
        IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR) OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) THEN
        --{
           WSH_UTIL_CORE.PrintMsg('Error occurred in Inv_Move_Order_Pub.Create_Move_Order_Lines');
           FOR i in 1..l_msg_count LOOP
               l_message := fnd_msg_pub.get(i,'F');
               l_message := replace(l_message,chr(0),' ');
               WSH_UTIL_CORE.PrintMsg(l_message);
           END LOOP;
           fnd_msg_pub.delete_msg();
           IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR) THEN
           --{
              WSH_UTIL_CORE.PrintMsg('Unexpected error from Inv_Move_Order_Pub.Create_Move_Order_Lines. Exiting');
              x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
              IF l_debug_on THEN
                 WSH_DEBUG_SV.pop(l_module_name);
              END IF;
              RETURN;
           --}
           ELSE
           --{
              WSH_UTIL_CORE.PrintMsg('Create Move Order Lines Partially Successful');
              x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
  	      IF l_debug_on THEN
  	         WSH_DEBUG_SV.logmsg(l_module_name, 'Create Move Order Lines Partially Successful');
  	         WSH_DEBUG_SV.logmsg(l_module_name, 'Remove lines that errored out in INV');
  	      END IF;
              -- Bug 2522935 : Error in MO line creation for Ship Sets causes Released to Warehouse lines
              -- Delete all the Lines which had the return status as error from Inventory's Move Order Line API
              FOR i in 1..g_trolin_tbl.count LOOP
                  IF g_trolin_tbl(i).return_status = WSH_UTIL_CORE.G_RET_STS_ERROR THEN
                     WSH_UTIL_CORE.PrintMsg('Delete Line '||g_trolin_tbl(i).line_id);
  	             IF l_debug_on THEN
  	        	WSH_DEBUG_SV.log(l_module_name, 'Deleting line', g_trolin_tbl(i).line_id);
                     END IF;
                     g_trolin_tbl.delete(i);
                     l_trolin_val_tbl.delete(i);
                     g_del_detail_ids.delete(i);
                     g_trolin_delivery_ids.delete(i);
                  END IF;
              END LOOP;
              WSH_UTIL_CORE.PrintMsg('After deleting lines, Trolin Table count '||g_del_detail_ids.count);
              IF l_debug_on THEN
  	         WSH_DEBUG_SV.log(l_module_name, 'g_del_detail_ids.count', g_del_detail_ids.count);
              END IF;
           --}
           END IF;
        --}
        ELSIF (l_return_status = WSH_UTIL_CORE.G_RET_STS_SUCCESS) THEN
        --{
           G_ONLINE_PICK_RELEASE_PHASE := 'MOVE_ORDER_LINES';
           IF l_debug_on THEN
              WSH_DEBUG_SV.logmsg(l_module_name,  'CREATED MO LINES SUCESSFULLY');
  	      WSH_DEBUG_SV.log(l_module_name, 'g_del_detail_ids.count', g_del_detail_ids.count);
           END IF;
        --}
        END IF;
     --}
     ELSE -- l_express_pick_flag =
     --{
        IF l_debug_on THEN
           WSH_DEBUG_SV.logmsg(l_module_name,'============');
           WSH_DEBUG_SV.logmsg(l_module_name,'Express Pick');
           WSH_DEBUG_SV.logmsg(l_module_name,'============');
           WSH_DEBUG_SV.logmsg(l_module_name,'Calling Inv_Express_Pick_Pub.Pick_Release with COUNT:'||G_TROLIN_TBL.COUNT  );
           WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit Inv_Express_Pick_Pub.Pick_Release',WSH_DEBUG_SV.C_PROC_LEVEL);
        END IF;
        WSH_PICK_LIST.G_AUTO_PICK_CONFIRM := 'Y';
        Inv_Express_Pick_Pub.Pick_Release (
                    p_api_version            => l_api_version_number,
                    p_init_msg_list          => FND_API.G_TRUE,
                    p_commit                 => l_commit,
                    p_mo_line_tbl            => g_trolin_tbl,
                    p_grouping_rule_id       => p_pick_slip_grouping_rule,
                    p_reservations_tbl       => l_dummy_rsv_tbl,
                    p_allow_partial_pick     => FND_API.G_TRUE,
                    p_pick_release_status_tbl=> g_exp_pick_release_stat,
                    x_return_status          => l_return_status,
                    x_msg_count              => l_msg_count,
                    x_msg_data               => l_msg_data);
        IF l_debug_on THEN
           WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
           WSH_DEBUG_SV.log(l_module_name,'Inv_Express_Pick_Pub.Pick_Release l_return_status',l_return_status);
        END IF;
        IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR) OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) THEN
        --{
           WSH_UTIL_CORE.PrintMsg('Error occurred in Inv_Express_Pick_Pub.Pick_Release');
           FOR i in 1..l_msg_count LOOP
               l_message := fnd_msg_pub.get(i,'F');
               l_message := replace(l_message,chr(0),' ');
               WSH_UTIL_CORE.PrintMsg(l_message);
               IF (i = 1) THEN
                   l_message1 := l_message;
               END IF;
           END LOOP;
           fnd_msg_pub.delete_msg();
           IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR) THEN
           --{
              WSH_UTIL_CORE.PrintMsg('Unexpected error from Inv_Express_Pick_Pub.Pick_Release. Exiting');
              x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
              IF l_debug_on THEN
                 WSH_DEBUG_SV.pop(l_module_name);
              END IF;
              RETURN;
           --}
           ELSE
           --{
              ROLLBACK TO BEF_MOVE_ORDER_LINE_CREATE;
              WSH_UTIL_CORE.PrintMsg('Express Pick Release Returned Expected Error');
              x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
              l_request_id := fnd_global.conc_request_id;
              IF (l_request_id <> -1 OR G_BATCH_ID IS NOT NULL ) THEN
              --{
                 FOR i in 1 .. WSH_PR_CRITERIA.release_table.count LOOP
                     IF l_debug_on THEN
                        WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_UTIL_CORE.GET_ITEM_NAME',WSH_DEBUG_SV.C_PROC_LEVEL);
                     END IF;
                     l_item_name := WSH_UTIL_CORE.Get_Item_Name(WSH_PR_CRITERIA.release_table(i).inventory_item_id,
                                                                WSH_PR_CRITERIA.release_table(i).organization_id);
                     FND_MESSAGE.SET_NAME('WSH','WSH_INV_EXPECTED_ERROR');
                     FND_MESSAGE.SET_TOKEN('ITEM',l_item_name);
                     FND_MESSAGE.SET_TOKEN('ORDER',WSH_PR_CRITERIA.release_table(i).source_header_number);
                     FND_MESSAGE.SET_TOKEN('INVMESSAGE',l_message1);
                     l_message := FND_MESSAGE.GET;
                     l_exception_return_status := NULL;
                     l_exception_msg_count := NULL;
                     l_exception_msg_data := NULL;
                     l_dummy_exception_id := NULL;
                     IF l_debug_on THEN
                        WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_XC_UTIL.LOG_EXCEPTION',WSH_DEBUG_SV.C_PROC_LEVEL);
                     END IF;
                     WSH_XC_UTIL.Log_Exception(
                              p_api_version             => 1.0,
                              p_logging_entity          => 'SHIPPER',
                              p_logging_entity_id       => FND_GLOBAL.USER_ID,
                              p_exception_name          => 'WSH_INV_EXPECTED_ERROR',
                              p_message                 => l_message,
                              p_inventory_item_id       => WSH_PR_CRITERIA.release_table(i).inventory_item_id,
                              p_logged_at_location_id   => WSH_PR_CRITERIA.release_table(i).ship_from_location_id,
                              p_exception_location_id   => WSH_PR_CRITERIA.release_table(i).ship_from_location_id,
                              p_request_id              => l_request_id,
                              p_batch_id                => WSH_PICK_LIST.g_batch_id,
                              x_return_status           => l_exception_return_status,
                              x_msg_count               => l_exception_msg_count,
                              x_msg_data                => l_exception_msg_data,
                              x_exception_id            => l_dummy_exception_id);
                     IF l_debug_on THEN
                        WSH_DEBUG_SV.logmsg(l_module_name,  'LOGGED EXCEPTION '||L_DUMMY_EXCEPTION_ID  );
                     END IF;
                 END LOOP;
              --}
              END IF;
           --}
           END IF;
        --}
        END IF;

        IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_SUCCESS) THEN
        --{
            /* INV will always pass 'delivery_detail_id' in the record structure and this will be in the same
               order as passed by shipping.
               1. If a dd is completely picked and the dd is Staged using only 1 reservation
                  then INV should pass pick_status 'S' and split_delivery_id null
               2. If a dd is completely picked and the dd is Staged using more than 1 reservation
                  then INV should pass pick_status 'S' and split_delivery_id for all split details. Also
                  INV should pass another record with pick_status 'S'.
               3. If a dd is partially picked and the dd is Staged using only 1 reservation
                  then INV should pass pick_status 'S' and split_delivery_id for split detail. Also
                  INV should pass another record with pick_status 'P' with split_delivery_id null.
               4. If a dd is partially picked and the dd is Staged using more than 1 reservation
                  then INV should pass pick_status 'S' and split_delivery_id for all split details. Also
                  INV should pass another record with pick_status 'P' with split_delivery_id null
               5. If a dd is completely ignored(say it has only org level reservation or it has partial detail
                  reservation and is in ship set)
                  then INV will pass pick_status 'F' and split_delivery_id  null.
               6. If a dd is completely ignored because other line in ship set couldn't be fulfilled
                  then INV will pass pick_status 'I' and split_delivery_id  null.
            */
            IF l_debug_on THEN
               FOR i IN g_exp_pick_release_stat.FIRST..g_exp_pick_release_stat.LAST LOOP
                   WSH_DEBUG_SV.logmsg(l_module_name,i||' '||g_exp_pick_release_stat(i).delivery_detail_id||
                                         ' '||g_exp_pick_release_stat(i).pick_status||
                                         ' '||g_exp_pick_release_stat(i).split_delivery_id);
               END LOOP;
            END IF;
        --}
        END IF;
     --}
     END IF;
  --}
  END IF; -- g_trolin_tbl.count > 0

  x_curr_count := x_curr_count + WSH_PR_CRITERIA.release_table.count ;

  -- Save Move Order Line IDs into Delivery Details table
  IF p_express_pick_flag = 'N' THEN
  --{
     -- Bug 2522935 : Error in MO line creation for Ship Sets causes Released to Warehouse lines
     i :=  g_trolin_tbl.FIRST;
     l_detail_tab.delete; -- DBI Project
     WHILE i IS NOT NULL LOOP
     --{
        --Bug 5645615: Since we are deleting lines with error status, get the next index before we might delete the line.
        j := g_trolin_tbl.NEXT(i);
        BEGIN
          IF (g_trolin_tbl(i).return_status =  WSH_UTIL_CORE.G_RET_STS_SUCCESS) THEN
              IF l_debug_on THEN
                 WSH_DEBUG_SV.logmsg(l_module_name,  'UPDATE WITH TROLIN.LINE_ID ' || G_TROLIN_TBL(I).LINE_ID  );
              END IF;
              UPDATE wsh_delivery_details
              SET    move_order_line_id = g_trolin_tbl(i).line_id,
                     released_status = WSH_DELIVERY_DETAILS_PKG.C_RELEASED_TO_WAREHOUSE,
                     batch_id   = p_batch_id,
                     last_updated_by = l_user_id,
                     last_update_date   = l_date,
                     last_update_login  = l_login_id,
                     replenishment_status = NULL    -- bug# 6719369 (replenishment project)
              WHERE  delivery_detail_id = g_del_detail_ids(i);

	      l_detail_tab(l_detail_tab.count+1) := g_del_detail_ids(i); -- DBI Project
              --DBI
              WSH_DD_TXNS_PVT.create_dd_txn_from_dd  (
                                                       p_delivery_detail_id => g_del_detail_ids(i),
                                                       x_dd_txn_id => l_dd_txn_id,
                                                       x_return_status =>l_txn_return_status);
              IF (l_txn_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS) THEN
                  x_return_status := l_txn_return_status;
                  WSH_UTIL_CORE.PrintMsg('Error occurred in WSH_DD_TXNS_PVT.create_dd_txn_from_dd');
                  IF l_debug_on THEN
                     WSH_DEBUG_SV.pop(l_module_name);
                  END IF;
                  RETURN;
              END IF;
              --DBI

              --Raise Event : Pick To Pod Workflow
              WSH_WF_STD.Raise_Event(
                                      p_entity_type => 'LINE',
                                      p_entity_id => g_del_detail_ids(i) ,
                                      p_event => 'oracle.apps.wsh.line.gen.releasedtowarehouse' ,
                                      --p_parameters IN wf_parameter_list_t DEFAULT NULL,
                                      p_organization_id => p_organization_id,
                                      x_return_status => l_wf_rs ) ;
              IF l_debug_on THEN
                 WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
                 wsh_debug_sv.log(l_module_name,'Return Status After Calling WSH_WF_STD.Raise_Event',l_wf_rs);
              END IF;

              OPEN c_get_picked_lines_count( g_del_detail_ids(i) );
              FETCH c_get_picked_lines_count INTO l_count_picked_lines, l_delv_id ;
              IF (c_get_picked_lines_count%FOUND) THEN
                  IF ( l_count_picked_lines=1) THEN --If it is the first line in a delivery to be released
                       WSH_WF_STD.Raise_Event(
                                               p_entity_type => 'DELIVERY',
                                               p_entity_id => l_delv_id ,
                                               p_event => 'oracle.apps.wsh.delivery.pik.pickinitiated' ,
                                               p_organization_id => p_organization_id,
                                               x_return_status => l_wf_rs ) ;
                       IF l_debug_on THEN
                          WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
                          wsh_debug_sv.log(l_module_name,'Return Status After Calling WSH_WF_STD.Raise_Event',l_wf_rs);
                       END IF;
                  END IF;
              END IF;
              CLOSE c_get_picked_lines_count;
              --Done Raise Event : Pick To Pod Workflow

          ELSE
              WSH_UTIL_CORE.PrintMsg('Could not Create Move Order Line for Delivery Detail '||g_del_detail_ids(i));
              -- Bug 5645615: Delete all the lines with return status error.
              IF g_trolin_tbl(i).return_status = WSH_UTIL_CORE.G_RET_STS_ERROR THEN
                 WSH_UTIL_CORE.PrintMsg('Delete Line '||g_trolin_tbl(i).line_id);
                 IF l_debug_on THEN
                    WSH_DEBUG_SV.log(l_module_name, 'Deleting trolin line', g_trolin_tbl(i).line_id);
                    WSH_DEBUG_SV.log(l_module_name, 'Deleting detail line', g_del_detail_ids(i));
                 END IF;
                 g_trolin_tbl.delete(i);
                 l_trolin_val_tbl.delete(i);
                 g_del_detail_ids.delete(i);
                 g_trolin_delivery_ids.delete(i);
              END IF;

          END IF;
        EXCEPTION
          WHEN no_data_found THEN
               WSH_UTIL_CORE.PrintMsg('Delivery detail line not found: '|| WSH_PR_CRITERIA.release_table(i).delivery_detail_id);
               x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
               IF l_debug_on THEN
                  WSH_DEBUG_SV.pop(l_module_name);
               END IF;
               RETURN;
          WHEN others THEN
               WSH_UTIL_CORE.PrintMsg('Cannot update delivery detail: ' || WSH_PR_CRITERIA.release_table(i).delivery_detail_id);
               x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
               IF l_debug_on THEN
                  WSH_DEBUG_SV.pop(l_module_name);
               END IF;
               RETURN;
        END;
        i := j;
     --}
     END LOOP;
     IF l_debug_on THEN
        WSH_DEBUG_SV.log(l_module_name, 'g_trolin_tbl.count', g_trolin_tbl.count);
        WSH_DEBUG_SV.log(l_module_name, 'g_del_detail_ids.count', g_del_detail_ids.count);
     END IF;

     -- Update of wsh_delivery_details where released_status is changed, call DBI API after the update.
     IF l_debug_on THEN
        WSH_DEBUG_SV.log(l_module_name,'Calling DBI API.Detail count',l_detail_tab.count);
     END IF;
     WSH_INTEGRATION.DBI_Update_Detail_Log (
                                             p_delivery_detail_id_tab => l_detail_tab,
                                             p_dml_type               => 'UPDATE',
                                             x_return_status          => l_dbi_rs );
     IF l_debug_on THEN
        WSH_DEBUG_SV.log(l_module_name,'Return Status after DBI Call-',l_dbi_rs);
     END IF;
     IF l_dbi_rs = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR THEN
        x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
        WSH_UTIL_CORE.PrintMsg('Error occurred in WSH_INTEGRATION.DBI_Update_Detail_Log');
	IF l_debug_on THEN
           WSH_DEBUG_SV.pop(l_module_name);
        END IF;
	RETURN;
     END IF;
  --}
  END IF;

  IF l_debug_on THEN
     WSH_DEBUG_SV.pop(l_module_name);
  END IF;

EXCEPTION
      WHEN OTHERS THEN
         IF get_dd_pup_trip_stop%ISOPEN THEN
            CLOSE get_dd_pup_trip_stop;
         END IF;
         x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
         IF l_debug_on THEN
            WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '
                                || SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
            WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
         END IF;

END Create_Move_Order_Lines;


-- Start of comments
-- API name : Autocreate_Deliveries
-- Type     : Private
-- Pre-reqs : None.
-- Procedure: This API will append deliveries and call Autocreate_Deliveries to
--            create deliveries
-- Parameters :
-- IN:
--      p_append_flag               IN  Append Flag, Valid Values Y/N.
--      p_use_header_flag           IN  Deliveries should be unique for each order, Valid Values Y/N.
--      p_del_details_tbl           IN  Table of Delivery Details for Delivery creation.
-- OUT:
--      x_return_status             OUT NOCOPY  Return Status.
-- End of comments
PROCEDURE Autocreate_Deliveries(
      p_append_flag                  IN      VARCHAR2,
      p_use_header_flag              IN      VARCHAR2,
      p_del_details_tbl              IN      WSH_UTIL_CORE.Id_Tab_Type,
      x_return_status                OUT NOCOPY VARCHAR2)
IS

  CURSOR del_cur(c_dlvy_id NUMBER) IS
  SELECT ship_method_code, intmed_ship_to_location_id
  FROM   wsh_new_deliveries
  WHERE  delivery_id = c_dlvy_id;

  l_del_details_tbl   WSH_UTIL_CORE.Id_Tab_Type;
  l_grouping_tbl      WSH_UTIL_CORE.Id_Tab_Type;
  l_delivery_ids_tbl  WSH_UTIL_CORE.Id_Tab_Type;
  i                   NUMBER;
  j                   NUMBER;
  l_msg_count         NUMBER;
  l_msg_data          VARCHAR2(2000);
  l_return_status     VARCHAR2(1);

  --Compatibility Changes
  l_cc_validate_result          VARCHAR2(1);
  l_cc_failed_records           WSH_FTE_COMP_CONSTRAINT_PKG.failed_line_tab_type;
  l_cc_line_groups              WSH_FTE_COMP_CONSTRAINT_PKG.line_group_tab_type;
  l_cc_group_info               WSH_FTE_COMP_CONSTRAINT_PKG.cc_group_tab_type;
  b_cc_linefailed               BOOLEAN;
  b_cc_groupidexists            BOOLEAN;
  l_id_tab_temp                 WSH_UTIL_CORE.Id_Tab_Type;
  l_del_details_tbl_temp        WSH_UTIL_CORE.Id_Tab_Type;
  l_cc_count_success            NUMBER;
  l_cc_count_group_ids          NUMBER;
  l_cc_count_rec                NUMBER;
  l_cc_group_ids                WSH_UTIL_CORE.Id_Tab_Type;
  l_cc_upd_dlvy_intmed_ship_to  VARCHAR2(1);
  l_cc_upd_dlvy_ship_method     VARCHAR2(1);
  l_cc_dlvy_intmed_ship_to      NUMBER;
  l_cc_dlvy_ship_method         VARCHAR2(30);
  l_num_errors                  NUMBER;
  l_num_warnings                NUMBER;
  l_cc_del_rows                 WSH_UTIL_CORE.Id_Tab_Type;
  l_cc_grouping_rows            WSH_UTIL_CORE.Id_Tab_Type;
  l_cc_return_status            VARCHAR2(1);
  l_cc_count_del_rows           NUMBER;
  l_cc_count_grouping_rows      NUMBER;
  --dummy tables for calling validate_constraint_main
  l_cc_del_attr_tab             WSH_NEW_DELIVERIES_PVT.Delivery_Attr_Tbl_Type;
  l_cc_det_attr_tab             WSH_GLBL_VAR_STRCT_GRP.Delivery_Details_Attr_Tbl_Type;
  l_cc_trip_attr_tab            WSH_TRIPS_PVT.Trip_Attr_Tbl_Type;
  l_cc_stop_attr_tab            WSH_TRIP_STOPS_PVT.Stop_Attr_Tbl_Type;
  l_cc_in_ids                   WSH_UTIL_CORE.Id_Tab_Type;
  l_cc_fail_ids                 WSH_UTIL_CORE.Id_Tab_Type;
  -- deliveryMerge
  l_appended_det_tbl              WSH_DELIVERY_DETAILS_UTILITIES.delivery_assignment_rec_tbl;
  l_unappended_det_tbl            WSH_UTIL_CORE.Id_Tab_Type;
  l_default_ship_confirm_rule_id  NUMBER := NULL;
  l_appended_del_tbl              WSH_UTIL_CORE.Id_Tab_Type;
  l_tmp_del_tbl                   WSH_UTIL_CORE.Id_Tab_Type;
  --
  l_debug_on BOOLEAN;
  l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'AUTOCREATE_DELIVERIES';
  --

BEGIN

  l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
  IF l_debug_on IS NULL
  THEN
    l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
  END IF;

  IF l_debug_on THEN
     WSH_DEBUG_SV.push(l_module_name);
     WSH_DEBUG_SV.log(l_module_name,'P_APPEND_FLAG',P_APPEND_FLAG);
     WSH_DEBUG_SV.log(l_module_name,'P_USE_HEADER_FLAG',P_USE_HEADER_FLAG);
     WSH_DEBUG_SV.log(l_module_name,'P_DEL_DETAILS_TBL.COUNT',P_DEL_DETAILS_TBL.COUNT);
  END IF;

  x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

  l_del_details_tbl := p_del_details_tbl;
  l_appended_del_tbl.delete;

  -- Check whether we have eligible lines to autocreate
  IF (l_del_details_tbl.count > 0) THEN
  --{
     --Compatibility Changes
     IF wsh_util_core.fte_is_installed = 'Y' THEN
     --{
        l_cc_line_groups.delete;
        l_cc_group_info.delete;
        l_cc_failed_records.delete;
        IF l_debug_on THEN
           WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_FTE_COMP_CONSTRAINT_PKG.validate_constraint_main' ,WSH_DEBUG_SV.C_PROC_LEVEL);
           WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
        END IF;
        WSH_FTE_COMP_CONSTRAINT_PKG.validate_constraint_main (
                                                               p_api_version_number =>  1.0,
                                                               p_init_msg_list      =>  FND_API.G_FALSE,
                                                               p_entity_type        =>  'L',
                                                               p_target_id          =>  null,
                                                               p_action_code        =>  'AUTOCREATE-DEL',
                                                               p_del_attr_tab       =>  l_cc_del_attr_tab,
                                                               p_det_attr_tab       =>  l_cc_det_attr_tab,
                                                               p_trip_attr_tab      =>  l_cc_trip_attr_tab,
                                                               p_stop_attr_tab      =>  l_cc_stop_attr_tab,
                                                               p_in_ids             =>  l_del_details_tbl,
                                                               x_fail_ids           =>  l_cc_fail_ids,
                                                               x_validate_result    =>  l_cc_validate_result,
                                                               x_failed_lines       =>  l_cc_failed_records,
                                                               x_line_groups        =>  l_cc_line_groups,
                                                               x_group_info         =>  l_cc_group_info,
                                                               x_msg_count          =>  l_msg_count,
                                                               x_msg_data           =>  l_msg_data,
                                                               x_return_status      =>  l_return_status );
        IF l_debug_on THEN
           WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
           WSH_DEBUG_SV.log(l_module_name,'Return Status After Calling validate_constraint_main',l_return_status);
           WSH_DEBUG_SV.log(l_module_name,'validate_result After Calling validate_constraint_main'
                                         ,l_cc_validate_result);
           WSH_DEBUG_SV.log(l_module_name,'msg_count After Calling validate_constraint_main',l_msg_count);
           WSH_DEBUG_SV.log(l_module_name,'msg_data After Calling validate_constraint_main',l_msg_data);
           WSH_DEBUG_SV.log(l_module_name,'fail_ids count After Calling validate_constraint_main'
                                         ,l_cc_failed_records.COUNT);
           WSH_DEBUG_SV.log(l_module_name,'l_cc_line_groups.count count After Calling validate_constraint_main'
                                         ,l_cc_line_groups.COUNT);
           WSH_DEBUG_SV.log(l_module_name,'group_info count After Calling validate_constraint_main'
                                         ,l_cc_group_info.COUNT);
        END IF;
        IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR) THEN
        --{
            x_return_status := l_return_status;
            WSH_UTIL_CORE.PrintMsg('Error occurred in WSH_FTE_COMP_CONSTRAINT_PKG.validate_constraint_main');
            IF l_debug_on THEN
               WSH_DEBUG_SV.pop(l_module_name);
            END IF;
            RETURN;
        --}
        END IF;

        IF l_cc_line_groups.COUNT > 0 AND l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR THEN
        --{
           --set return_status as warning
           IF l_cc_failed_records.COUNT <> l_del_details_tbl.COUNT THEN
              l_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
           END IF;

           --1. get the group ids by which the constraints API has grouped the lines
           l_cc_count_group_ids := 1;
           FOR i in l_cc_line_groups.FIRST..l_cc_line_groups.LAST LOOP
               b_cc_groupidexists := FALSE;
               IF l_cc_group_ids.COUNT > 0 THEN
                  FOR j in l_cc_group_ids.FIRST..l_cc_group_ids.LAST LOOP
                      IF (l_cc_line_groups(i).line_group_id = l_cc_group_ids(j)) THEN
                          b_cc_groupidexists := TRUE;
                      END IF;
                  END LOOP;
               END IF;
               IF (NOT(b_cc_groupidexists)) THEN
                   l_cc_group_ids(l_cc_count_group_ids) := l_cc_line_groups(i).line_group_id;
                   l_cc_count_group_ids := l_cc_count_group_ids+1;
               END IF;
           END LOOP;

           --2. from the group id table above, loop thru lines table to get the lines which belong
           --to each group and call autocreate_trip for each group
           FOR i in l_cc_group_ids.FIRST..l_cc_group_ids.LAST LOOP
           --{
               l_id_tab_temp.delete;
               l_cc_count_rec := 1;
               FOR j in l_cc_line_groups.FIRST..l_cc_line_groups.LAST LOOP
                   IF l_cc_line_groups(j).line_group_id = l_cc_group_ids(i) THEN
                      l_id_tab_temp(l_cc_count_rec) := l_cc_line_groups(j).entity_line_id;
                      l_cc_count_rec := l_cc_count_rec+1;
                   END IF;
               END LOOP;
               --{
               IF l_debug_on THEN
                  WSH_DEBUG_SV.log(l_module_name,'det. tab count: '|| l_id_tab_temp.count);
                  WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_DELIVERY_DETAILS_UTILITIES.Append_to_Deliveries' ,WSH_DEBUG_SV.C_PROC_LEVEL);
                  WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
               END IF;
               WSH_DELIVERY_DETAILS_UTILITIES.Append_to_Deliveries (
                            p_delivery_detail_tbl     => l_id_tab_temp,
                            p_append_flag             => p_append_flag,
                            p_group_by_header         => p_use_header_flag,
                            p_commit                  => FND_API.G_FALSE,
                            p_lock_rows               => FND_API.G_FALSE,
                            p_check_fte_compatibility => FND_API.G_FALSE,
                            x_appended_det_tbl        => l_appended_det_tbl,
                            x_unappended_det_tbl      => l_unappended_det_tbl,
                            x_appended_del_tbl        => l_tmp_del_tbl,
                            x_return_status           => l_return_status );
               IF l_debug_on THEN
                  WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
                  WSH_DEBUG_SV.log(l_module_name,'Return status from Append_to_Deliveries is: ',l_return_status );
               END IF;
               IF l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR
               OR l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR THEN
                  x_return_status := l_return_status;
                  WSH_UTIL_CORE.PrintMsg('Error occurred in WSH_DELIVERY_DETAILS_UTILITIES.Append_to_Deliveries');
                  IF l_debug_on THEN
                     WSH_DEBUG_SV.pop(l_module_name);
                  END IF;
                  RETURN;
               END IF;
               --}

               -- deliveryMerge, collect appended deliveries
               IF l_appended_del_tbl.COUNT = 0 THEN
                  l_appended_del_tbl := l_tmp_del_tbl;
               ELSE
                  IF l_tmp_del_tbl.COUNT > 0 THEN
                     FOR i in l_tmp_del_tbl.FIRST..l_tmp_del_tbl.LAST LOOP
                         l_appended_del_tbl(l_appended_del_tbl.count+1) := l_tmp_del_tbl(i);
                     END LOOP;
                  END IF;
               END IF;

               l_id_tab_temp.delete;
               l_id_tab_temp := l_unappended_det_tbl;

               IF l_debug_on THEN
                  WSH_DEBUG_SV.log(l_module_name,'id_tab_temp count ',l_id_tab_temp.COUNT);
                  WSH_DEBUG_SV.log(l_module_name,'det. tab count: '|| l_del_details_tbl.count);
                  WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_DELIVERY_AUTOCREATE.AUTOCREATE_DELIVERIES',WSH_DEBUG_SV.C_PROC_LEVEL);
                  WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
               END IF;
               --{
               IF l_id_tab_temp.count > 0 THEN
                  WSH_DELIVERY_AUTOCREATE.Autocreate_Deliveries (
                               p_line_rows         =>  l_id_tab_temp,
                               p_init_flag         =>  'Y',  -- Should refresh the PL/SQL tables for compatibility
                               p_pick_release_flag =>  'N',
                               x_del_rows          =>  l_delivery_ids_tbl,
                               x_grouping_rows     =>  l_grouping_tbl,
                               x_return_status     =>  l_cc_return_status );
                  IF l_debug_on THEN
                     WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
                     WSH_DEBUG_SV.log(l_module_name,'WSH_DELIVERY_AUTOCREATE.Autocreate_Deliveries l_cc_return_status',l_cc_return_status);
                  END IF;

                  -- set the intermediate ship to, ship method to null if group rec from constraint validation
                  -- has these as 'N'
                  l_cc_upd_dlvy_intmed_ship_to := 'Y';
                  l_cc_upd_dlvy_ship_method    := 'Y';
                  IF l_cc_group_info.COUNT > 0 THEN
                     FOR j in l_cc_group_info.FIRST..l_cc_group_info.LAST LOOP
                         IF l_cc_group_info(j).line_group_id = l_cc_group_ids(i) THEN
                            l_cc_upd_dlvy_intmed_ship_to := l_cc_group_info(j).upd_dlvy_intmed_ship_to;
                            l_cc_upd_dlvy_ship_method := l_cc_group_info(j).upd_dlvy_ship_method;
                         END IF;
                     END LOOP;
                  END IF;

                  IF l_debug_on THEN
                     WSH_DEBUG_SV.log(l_module_name,'l_cc_upd_dlvy_intmed_ship_to ',l_cc_upd_dlvy_intmed_ship_to);
                     WSH_DEBUG_SV.log(l_module_name,'l_cc_upd_dlvy_ship_method ',l_cc_upd_dlvy_ship_method);
                     WSH_DEBUG_SV.log(l_module_name,'l_delivery_ids_tbl.COUNT ',l_delivery_ids_tbl.COUNT);
                     WSH_DEBUG_SV.log(l_module_name,'l_grouping_tbl.COUNT ',l_grouping_tbl.COUNT);
                     WSH_DEBUG_SV.log(l_module_name,'l_cc_return_status ',l_cc_return_status);
                  END IF;

                  IF l_cc_upd_dlvy_intmed_ship_to = 'N' OR l_cc_upd_dlvy_ship_method = 'N' THEN
                     IF l_delivery_ids_tbl.COUNT > 0 THEN
                        FOR i in l_delivery_ids_tbl.FIRST..l_delivery_ids_tbl.LAST LOOP
                            FOR delcurtemp in del_cur(l_delivery_ids_tbl(i)) LOOP
                                l_cc_dlvy_intmed_ship_to := delcurtemp.INTMED_SHIP_TO_LOCATION_ID;
                                l_cc_dlvy_ship_method := delcurtemp.SHIP_METHOD_CODE;
                                IF l_cc_upd_dlvy_intmed_ship_to = 'N' and l_cc_dlvy_intmed_ship_to IS NOT NULL THEN
                                   UPDATE wsh_new_deliveries
                                   SET    intmed_ship_to_location_id = NULL
                                   WHERE  delivery_id                = l_delivery_ids_tbl(i);
                                END IF;
                                --IF l_cc_upd_dlvy_ship_method = 'N' and l_cc_dlvy_ship_method IS NOT NULL THEN
                                IF l_cc_upd_dlvy_ship_method = 'N' THEN

                                   --OTM R12, this update is FTE part of code, OTM flow will not go through here

                                   UPDATE wsh_new_deliveries
                                   SET    ship_method_code  = NULL,
                                          carrier_id        = NULL,
                                          mode_of_transport = NULL,
                                          service_level     = NULL
                                   WHERE  delivery_id       = l_delivery_ids_tbl(i);
                                END IF;
                            END LOOP;
                        END LOOP;
                     END IF;
                  END IF;
                  -- set the intermediate ship to, ship method to null if group rec from constraint
                  -- validation has these as 'N'

                  IF l_cc_del_rows.COUNT=0 THEN
                     l_cc_del_rows := l_delivery_ids_tbl;
                  ELSE
                     l_cc_count_del_rows := l_cc_del_rows.COUNT;
                     IF l_delivery_ids_tbl.COUNT > 0 THEN
                        FOR i in l_delivery_ids_tbl.FIRST..l_delivery_ids_tbl.LAST LOOP
                            l_cc_del_rows(l_cc_count_del_rows+i) := l_delivery_ids_tbl(i);
                        END LOOP;
                     END IF;
                  END IF;

                  IF l_cc_grouping_rows.COUNT = 0 THEN
                     l_cc_grouping_rows := l_grouping_tbl;
                  ELSE
                     l_cc_count_grouping_rows := l_cc_grouping_rows.COUNT;
                     IF l_grouping_tbl.COUNT > 0 THEN
                        FOR i in l_grouping_tbl.FIRST..l_grouping_tbl.LAST LOOP
                            l_cc_grouping_rows(l_cc_count_grouping_rows+i) := l_grouping_tbl(i);
                        END LOOP;
                     END IF;
                  END IF;

                  IF (l_cc_return_status IS NOT NULL AND l_cc_return_status IN
                  (WSH_UTIL_CORE.G_RET_STS_ERROR, WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR)) THEN
                      l_return_status := l_cc_return_status;
                  ELSIF (l_cc_return_status IS NOT NULL AND l_cc_return_status = WSH_UTIL_CORE.G_RET_STS_WARNING
                  AND l_return_status = WSH_UTIL_CORE.G_RET_STS_SUCCESS) THEN
                      l_return_status := l_cc_return_status;
                  ELSE
                      l_cc_return_status := l_return_status;
                  END IF;
               END IF;
               --}
           --}
           END LOOP;

           l_delivery_ids_tbl := l_cc_del_rows;
           l_grouping_tbl     := l_cc_grouping_rows;

           IF l_debug_on THEN
              WSH_DEBUG_SV.log(l_module_name,'l_delivery_ids_tbl.COUNT after loop ',l_delivery_ids_tbl.COUNT);
              WSH_DEBUG_SV.log(l_module_name,'l_grouping_tbl.COUNT after loop',l_grouping_tbl.COUNT);
           END IF;
           IF l_cc_return_status IS NOT NULL THEN
              l_return_status := l_cc_return_status;
           END IF;
        --}

        ELSE -- validate_status is succese implies no failed lines so call autocreate_del directly
        --{
           -- deliveryMerge
           IF l_debug_on THEN
              WSH_DEBUG_SV.log(l_module_name,'det. tab count: '|| l_del_details_tbl.count);
              WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_DELIVERY_DETAILS_UTILITIES.Append_to_Deliveries' ,WSH_DEBUG_SV.C_PROC_LEVEL);
              WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
           END IF;
           WSH_DELIVERY_DETAILS_UTILITIES.Append_to_Deliveries(
                         p_delivery_detail_tbl     => l_del_details_tbl,
                         p_append_flag             => p_append_flag,
                         p_group_by_header         => p_use_header_flag,
                         p_commit                  => FND_API.G_FALSE,
                         p_lock_rows               => FND_API.G_FALSE,
                         p_check_fte_compatibility => FND_API.G_FALSE,
                         x_appended_det_tbl        => l_appended_det_tbl,
                         x_unappended_det_tbl      => l_unappended_det_tbl,
                         x_appended_del_tbl        => l_appended_del_tbl,
                         x_return_status           => l_return_status);
           IF l_debug_on THEN
              WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
              WSH_DEBUG_SV.log(l_module_name,'Return status from Append_to_Deliveries is',l_return_status );
           END IF;
           IF l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR
           OR l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR THEN
              x_return_status := l_return_status;
              WSH_UTIL_CORE.PrintMsg('Error occurred in WSH_DELIVERY_DETAILS_UTILITIES.Append_to_Deliveries');
              IF l_debug_on THEN
                 WSH_DEBUG_SV.pop(l_module_name);
              END IF;
              RETURN;
           END IF;

           l_del_details_tbl.delete;
           l_del_details_tbl := l_unappended_det_tbl;

           IF l_debug_on THEN
              WSH_DEBUG_SV.log(l_module_name,'det. tab count: '|| l_del_details_tbl.count);
              WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_DELIVERY_AUTOCREATE.AUTOCREATE_DELIVERIES',WSH_DEBUG_SV.C_PROC_LEVEL);
              WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
           END IF;

           IF  l_del_details_tbl.count > 0 THEN
           --{
              WSH_DELIVERY_AUTOCREATE.Autocreate_Deliveries (
                            p_line_rows         =>  l_del_details_tbl,
                            p_init_flag         =>  'N',  -- Should not refresh the PL/SQL tables
                            p_pick_release_flag =>  p_use_header_flag,
                            x_del_rows          =>  l_delivery_ids_tbl,
                            x_grouping_rows     =>  l_grouping_tbl,
                            x_return_status     =>  l_return_status
                             );

              IF l_debug_on THEN
                 WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
                 WSH_DEBUG_SV.log(l_module_name,'WSH_DELIVERY_AUTOCREATE.Autocreate_Deliveries l_return_status',l_return_status);
              END IF;

              -- set the intermediate ship to, ship method to null if group rec from constraint
              -- validation has these as 'N'
              IF l_cc_group_info.COUNT > 0 THEN
              --{
                 l_cc_upd_dlvy_intmed_ship_to := 'Y';
                 l_cc_upd_dlvy_ship_method    := 'Y';
                 l_cc_upd_dlvy_intmed_ship_to := l_cc_group_info(1).upd_dlvy_intmed_ship_to;
                 l_cc_upd_dlvy_ship_method    := l_cc_group_info(1).upd_dlvy_ship_method;

                 IF l_debug_on THEN
                    WSH_DEBUG_SV.log(l_module_name,'l_cc_upd_dlvy_intmed_ship_to ',l_cc_upd_dlvy_intmed_ship_to);
                    WSH_DEBUG_SV.log(l_module_name,'l_cc_upd_dlvy_ship_method ',l_cc_upd_dlvy_ship_method);
                    WSH_DEBUG_SV.log(l_module_name,'l_delivery_ids_tbl.COUNT ',l_delivery_ids_tbl.COUNT);
                 END IF;

                 IF l_cc_upd_dlvy_intmed_ship_to = 'N' OR l_cc_upd_dlvy_ship_method = 'N' THEN
                    IF l_delivery_ids_tbl.COUNT > 0 THEN
                       FOR i in l_delivery_ids_tbl.FIRST..l_delivery_ids_tbl.LAST LOOP
                           FOR delcurtemp in del_cur(l_delivery_ids_tbl(i)) LOOP
                               l_cc_dlvy_intmed_ship_to := delcurtemp.INTMED_SHIP_TO_LOCATION_ID;
                               l_cc_dlvy_ship_method    := delcurtemp.SHIP_METHOD_CODE;
                               IF l_cc_upd_dlvy_intmed_ship_to = 'N' and l_cc_dlvy_intmed_ship_to IS NOT NULL THEN
                                  UPDATE wsh_new_deliveries
                                  SET    intmed_ship_to_location_id = NULL
                                  WHERE  delivery_id                = l_delivery_ids_tbl(i);
                               END IF;
                               --IF l_cc_upd_dlvy_ship_method = 'N' and l_cc_dlvy_ship_method IS NOT NULL THEN
                               IF l_cc_upd_dlvy_ship_method = 'N' THEN

                                  --OTM R12, this update is FTE part of code, OTM flow will not go through here

                                  UPDATE wsh_new_deliveries
                                  SET    ship_method_code  = NULL,
                                         carrier_id        = NULL,
                                         mode_of_transport = NULL,
                                         service_level     = NULL
                                  WHERE  delivery_id       = l_delivery_ids_tbl(i);
                               END IF;
                           END LOOP;
                       END LOOP;
                    END IF;
                 END IF;
              --}
              END IF;

           --}
           END IF;

        --}
        END IF;--line_groups is not null

     --}
     ELSE -- fte not installed
     --{
        -- deliveryMerge
        IF l_debug_on THEN
           WSH_DEBUG_SV.log(l_module_name,'det. tab count: '|| l_del_details_tbl.count);
           WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_DELIVERY_DETAILS_UTILITIES.Append_to_Deliveries' ,WSH_DEBUG_SV.C_PROC_LEVEL);
           WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
        END IF;

        WSH_DELIVERY_DETAILS_UTILITIES.Append_to_Deliveries(
                      p_delivery_detail_tbl     => l_del_details_tbl,
                      p_append_flag             => p_append_flag,
                      p_group_by_header         => p_use_header_flag,
                      p_commit                  => FND_API.G_FALSE,
                      p_lock_rows               => FND_API.G_FALSE,
                      p_check_fte_compatibility => FND_API.G_FALSE,
                      x_appended_det_tbl        => l_appended_det_tbl,
                      x_unappended_det_tbl      => l_unappended_det_tbl,
                      x_appended_del_tbl        => l_appended_del_tbl,
                      x_return_status           => l_return_status);

        IF l_debug_on THEN
           WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
           WSH_DEBUG_SV.log(l_module_name,'Return status from Append_to_Deliveries is: ',l_return_status );
        END IF;

        IF l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR OR
        l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR THEN
        --{
           x_return_status := l_return_status;
           WSH_UTIL_CORE.PrintMsg('Error occurred in WSH_DELIVERY_DETAILS_UTILITIES.Append_to_Deliveries');
           IF l_debug_on THEN
              WSH_DEBUG_SV.pop(l_module_name);
           END IF;
           RETURN;
        --}
        END IF;

        l_del_details_tbl.delete;
        l_del_details_tbl := l_unappended_det_tbl;

        IF l_debug_on THEN
           WSH_DEBUG_SV.log(l_module_name,'det. tab count: '|| l_del_details_tbl.count);
           WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_DELIVERY_AUTOCREATE.AUTOCREATE_DELIVERIES',WSH_DEBUG_SV.C_PROC_LEVEL);
           WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
        END IF;

        IF l_del_details_tbl.count > 0 THEN
        --{
           WSH_DELIVERY_AUTOCREATE.Autocreate_Deliveries (
                        p_line_rows         =>  l_del_details_tbl,
                        p_init_flag         =>  'N',  -- Should not refresh the PL/SQL tables
                        p_pick_release_flag =>  p_use_header_flag,
                        x_del_rows          =>  l_delivery_ids_tbl,
                        x_grouping_rows     =>  l_grouping_tbl,
                        x_return_status     =>  l_return_status
                         );
           IF l_debug_on THEN
              WSH_DEBUG_SV.log(l_module_name,'WSH_DELIVERY_AUTOCREATE.Autocreate_Deliveries l_return_status',l_return_status);
              WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
           END IF;

           IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR)
           OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) THEN
               x_return_status := l_return_status;
               WSH_UTIL_CORE.PrintMsg('Error occurred in WSH_DELIVERY_AUTOCREATE.Autocreate_Deliveries');
               IF l_debug_on THEN
                  WSH_DEBUG_SV.pop(l_module_name);
               END IF;
               RETURN;
           END IF;
        --}
        END IF;
     --}
     END IF;

  --}
  ELSE
     WSH_UTIL_CORE.printMsg('No eligible lines to autocreate deliveries');
  END IF;

  IF l_debug_on THEN
     WSH_DEBUG_SV.pop(l_module_name);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
       x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
       IF l_debug_on THEN
          WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '
                                || SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
          WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
       END IF;

END Autocreate_Deliveries;

-- Start of comments
-- API name : Release_Batch_Sub
-- Type     : Public
-- Pre-reqs : None.
-- Procedure: This is core api to pick release a batch, api does
--            1. Gets initializes batch criteria.
--            2. Select details lines based on release criteria.
--            3. Calls Inventory Move Order api for allocation and pick confirmation.
--            4. Create/Appened deliveries, pack or ship confirmed based on release criteria.
--            5. Print document sets.
-- Parameters :
-- IN:
--      p_batch_id            IN  Batch Id.
--      p_worker_id           IN  Worker Id.
--      p_mode                IN  Mode.
--      p_log_level           IN  Set the debug log level.
-- OUT:
--      errbuf       OUT NOCOPY  Error message.
--      retcode      OUT NOCOPY  Error Code 1:Successs, 2:Warning and 3:Error.
-- End of comments
PROCEDURE Release_Batch_Sub(
      errbuf                            OUT NOCOPY      VARCHAR2,
      retcode                           OUT NOCOPY      VARCHAR2,
      p_batch_id                        IN      NUMBER,
      p_worker_id                       IN      NUMBER,
      p_mode                            IN      VARCHAR2,
      p_log_level                       IN      NUMBER  DEFAULT 0
   ) IS

  -- get distinct organization - move order header from worker table
  CURSOR  get_org_mo_hdr(c_batch_id IN NUMBER) IS
  SELECT  DISTINCT ORGANIZATION_ID, MO_HEADER_ID
  FROM    WSH_PR_WORKERS
  WHERE   BATCH_ID = c_batch_id
  AND     PROCESSED = 'N'
  ORDER BY ORGANIZATION_ID;

  -- get delivery information for auto ship and auto pack
  CURSOR  c_get_del IS
  SELECT  pa_sc_batch_id, delivery_id, organization_id, pickup_location_id, ap_level, sc_rule_id,ROWID -- Bug # 9369504 : added rowid
  FROM    wsh_pr_workers
  WHERE   batch_id = p_batch_id
  AND     type = 'PS'
  ORDER   BY 1,3,2;

  CURSOR get_sc_batch(c_batch_id IN NUMBER) IS
  SELECT ship_confirm_rule_id, creation_date
  FROM   wsh_picking_batches
  WHERE  batch_id = c_batch_id;

  --
  l_ship_confirm_rule_rec   WSH_BATCH_PROCESS.G_GET_SHIP_CONFIRM_RULE%ROWTYPE;
  l_ship_confirm_rule_id          NUMBER;
  l_batch_creation_date           DATE;
  l_del_details_tbl               WSH_UTIL_CORE.Id_Tab_Type;
  l_curr_count                    NUMBER;
  l_return_status                 VARCHAR2(1);
  l_completion_status             VARCHAR2(30);
  e_Return                        EXCEPTION;
  l_temp                          BOOLEAN;
  l_dummy                         VARCHAR2(1);
  l_rec_found                     BOOLEAN;
  l_msg_count                     NUMBER;
  l_msg_data                      VARCHAR2(2000);
  l_commit                        VARCHAR2(1) := FND_API.G_FALSE;
  l_request_id                    NUMBER;
  l_item_name                     VARCHAR2(2000);
  l_api_version_number            NUMBER := 1.0;
  l_message                       VARCHAR2(2000);
  l_message1                      VARCHAR2(2000);
  l_exception_return_status       VARCHAR2(30);
  l_exception_msg_count           NUMBER;
  l_exception_msg_data            VARCHAR2(4000) := NULL;
  l_dummy_exception_id            NUMBER;
  l_counter                       NUMBER := 0;
  l_total_detailed_count          NUMBER := 0;
  l_detail_count                  NUMBER := 0;
  l_del_pack_count                NUMBER := 0;
  l_del_sc_count                  NUMBER := 0;
  l_packed_results_success        NUMBER := 0;
  l_packed_results_warning        NUMBER := 0;
  l_packed_results_failure        NUMBER := 0;
  l_confirmed_results_success     NUMBER := 0;
  l_confirmed_results_warning     NUMBER := 0;
  l_confirmed_results_failure     NUMBER := 0;
  i                               NUMBER;
  j                               NUMBER;
  l_prev_detail_id                NUMBER;
  l_prev_sc_rule_id               NUMBER;
  --
  l_done_flag                     VARCHAR2(1);
  l_pick_release_stat             INV_PICK_RELEASE_PUB.INV_Release_Status_Tbl_Type;
  l_mmtt_tbl                      INV_MO_LINE_DETAIL_UTIL.G_MMTT_Tbl_Type;
  l_org_info                      WSH_PICK_LIST.Org_Params_Rec;
  l_tmp_rel_status                VARCHAR2(1);
  --
  l_auto_pick_confirm_num         NUMBER;
  l_plan_tasks                    BOOLEAN;
  l_skip_cartonization            BOOLEAN;
  l_pr_batch_size                 NUMBER;
  --
  l_continue_create_del VARCHAR2(1); -- bug # 8915460
  l_debug_on BOOLEAN;
  l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'RELEASE_BATCH_SUB';
  --

BEGIN

  SAVEPOINT s_Release_Batch_Sub_sf;

  -- If this is a worker, then it is a concurrent request
  IF p_worker_id IS NOT NULL THEN
     G_CONC_REQ := FND_API.G_TRUE;
  END IF;

  IF G_CONC_REQ = FND_API.G_TRUE AND p_worker_id IS NOT NULL THEN
     WSH_UTIL_CORE.Enable_Concurrent_Log_Print;
     IF p_log_level IS NOT NULL  THEN   -- log level fix
        WSH_UTIL_CORE.Set_Log_Level(p_log_level);
        WSH_UTIL_CORE.PrintMsg('p_log_level is ' || to_char(p_log_level));
     END IF;
  END IF;

  l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
  IF l_debug_on IS NULL
  THEN
    l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
  END IF;

  l_completion_status := 'NORMAL';

  IF l_debug_on THEN
     WSH_DEBUG_SV.push(l_module_name);
     WSH_DEBUG_SV.log(l_module_name,'P_BATCH_ID',P_BATCH_ID);
     WSH_DEBUG_SV.log(l_module_name,'P_WORKER_ID',P_WORKER_ID);
     WSH_DEBUG_SV.log(l_module_name,'P_MODE',P_MODE);
     WSH_DEBUG_SV.log(l_module_name,'P_LOG_LEVEL',P_LOG_LEVEL);
  END IF;

  -- If worker_id is present, set Global variable as Parallel Pick Release and Parallel Pick Slips
  IF p_worker_id IS NOT NULL THEN
     WSH_PICK_LIST.G_PICK_REL_PARALLEL  := TRUE;
     IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,'Pick Release Mode is Parallel ');
     END IF;
  END IF;

  -- 10. For p_mode = 'PICK' / 'PICK-SS'
  --{
  IF p_mode IN ('PICK','PICK-SS') THEN

     IF p_worker_id IS NOT NULL THEN --{
        -- 10.10 Calling Init_Pick_Release API to initialize global variables in WSH_PR_CRITERIA package
        --       and also set Batch_Id and Seeded Pick Release Document Set
        IF l_debug_on THEN
              WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit INIT_PICK_RELEASE',WSH_DEBUG_SV.C_PROC_LEVEL);
        END IF;
        Init_Pick_Release( p_batch_id      => p_batch_id,
                           p_worker_id     => p_worker_id,
                           x_return_status => l_return_status);
        IF l_debug_on THEN
           WSH_DEBUG_SV.log(l_module_name,'INIT_PICK_RELEASE l_return_status',l_return_status);
        END IF;

        IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR)
        OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR) THEN
            WSH_UTIL_CORE.PrintMsg('Error occurred in Init_Pick_Release');
            RAISE e_return;
        END IF;
     END IF; --}

     -- Clear Demand Table
     g_demand_table.delete;

     WSH_PR_CRITERIA.g_credit_check_option := WSH_CUSTOM_PUB.Credit_Check_Details_Option;

     -- Determine Pick Release Batch Size based on Profile
     --Bug 5137504 Handling if Batch size is set to value less than 1 or is aphanumeric
     BEGIN
     l_pr_batch_size := TO_NUMBER(FND_PROFILE.VALUE('WSH_PICK_RELEASE_BATCH_SIZE'));
     IF l_pr_batch_size IS NULL OR l_pr_batch_size < 1 THEN
        l_pr_batch_size := 50;
     ELSIF l_pr_batch_size > 1000 THEN
        l_pr_batch_size := 1000;
     END IF;
     l_pr_batch_size := ROUND(l_pr_batch_size);
     EXCEPTION
     WHEN value_error THEN
     l_pr_batch_size :=50;
     WHEN INVALID_NUMBER THEN
     l_pr_batch_size :=50;
     END;
     -- MAX_LINES should never be less than 3 or else infinite loop will occur.
     IF l_pr_batch_size IS NOT NULL THEN
        WSH_PR_CRITERIA.MAX_LINES := l_pr_batch_size;
     END IF;

     -- MAX_LINES should never be less than 3 or greater than 1000
     IF WSH_PR_CRITERIA.MAX_LINES < 3 THEN
        WSH_PR_CRITERIA.MAX_LINES := 3;
     END IF;

     IF WSH_PR_CRITERIA.MAX_LINES > 1000 THEN
        WSH_PR_CRITERIA.MAX_LINES := 1000;
     END IF;

     IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,  'MAX_LINES IS ' || TO_CHAR(WSH_PR_CRITERIA.MAX_LINES));
     END IF;

     -- 10.20 Looping thru Organization-Move Order Header Combination
     FOR batch_rec IN get_org_mo_hdr(p_batch_id) LOOP
     --{
         IF l_debug_on THEN
            WSH_DEBUG_SV.logmsg(l_module_name,'**** Processing Organization '||BATCH_REC.ORGANIZATION_ID||
                                              ' Move Order Header Id '||BATCH_REC.MO_HEADER_ID||' ****');
         END IF;

         -- 10.20.10 Clear the Global PL/SQL Tables for printers.
         WSH_INV_INTEGRATION_GRP.G_PRINTERTAB.delete ;
         WSH_INV_INTEGRATION_GRP.G_ORGTAB.delete ;
         WSH_INV_INTEGRATION_GRP.G_ORGSUBTAB.delete ;

         -- Set count for release rows to 0
         l_curr_count           := 0;
         l_done_flag            := FND_API.G_FALSE;
         l_total_detailed_count := 0;

         -- Reset the Non-Reservable Item Flag as 'N'
         WSH_PR_CRITERIA.g_nonreservable_item := 'N';

         -- 10.20.20 Getting Organization Parameters
         --{
         IF l_debug_on THEN
            WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit GET_ORG_PARAMS',WSH_DEBUG_SV.C_PROC_LEVEL);
         END IF;
         Get_Org_Params( p_organization_id => batch_rec.organization_id,
                         x_org_info        => l_org_info,
                         x_return_status   => l_return_status);
         IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR) THEN
             WSH_UTIL_CORE.PrintMsg('Error occurred in Get_Org_Params');
             RAISE e_return;
         END IF;
         --}

         -- 10.20.30 Initialize the cursor to fetch Worker Records
         --{
         IF l_debug_on THEN
            WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_PR_CRITERIA.GET_WORKER_RECORDS',WSH_DEBUG_SV.C_PROC_LEVEL);
         END IF;
         WSH_PR_CRITERIA.Get_Worker_Records (
                                              p_mode              => p_mode,
                                              p_batch_id          => p_batch_id,
                                              p_organization_id   => batch_rec.organization_id,
                                              x_api_status        => l_return_status );
         IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR) THEN
             WSH_UTIL_CORE.PrintMsg('Error occurred in Get_Worker_Records');
             RAISE e_return;
         END IF;
         --}
         l_continue_create_del := 'Y'; -- bug # 8915460 :
         -- 10.20.40 Get all lines for Organization-Item Combination and process them
         WHILE (l_done_flag = FND_API.G_FALSE) LOOP
         --{
            -- 10.20.40.10 Select a number of order lines at a time
            --{
            IF l_debug_on THEN
               WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_PR_CRITERIA.Get_Lines',WSH_DEBUG_SV.C_PROC_LEVEL);
               WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
            END IF;
            WSH_PR_CRITERIA.Get_Lines(
                                       p_enforce_ship_set_and_smc => l_org_info.enforce_ship_set_and_smc,
                                       p_wms_flag                 => l_org_info.wms_org,
                                       p_express_pick_flag        => l_org_info.express_pick_flag,
                                       p_batch_id                 => p_batch_id,
                                       x_done_flag                => l_done_flag,
                                       x_api_status               => l_return_status );
            IF l_debug_on THEN
              WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
              WSH_DEBUG_SV.log(l_module_name,'WSH_PR_CRITERIA.Get_Lines l_return_status',l_return_status);
            END IF;
            IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR)
            OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) THEN
               WSH_UTIL_CORE.PrintMsg('Error occurred in WSH_PR_CRITERIA.Get_Lines');
               RAISE e_return;
            ELSIF (l_return_status = WSH_UTIL_CORE.G_RET_STS_WARNING) THEN
               G_ONLINE_PICK_RELEASE_SKIP := 'Y';
               l_completion_status := 'WARNING';
               IF l_debug_on THEN
                  WSH_DEBUG_SV.log(l_Module_name, 'WSH_PR_CRITERIA.Get_Lines returned with warning');
               END IF;
            END IF;
            --}

            -- If there are no more lines to be processed, then go for Next Org-Move Order Combo
            IF WSH_PR_CRITERIA.release_table.count = 0 THEN
               GOTO NEXT_ORG_MO_WORKER;
            END IF;

            -- Savepoint to rollback for any error during pick release API
            SAVEPOINT BEF_MOVE_ORDER_LINE_CREATE;

            IF l_debug_on THEN
               WSH_DEBUG_SV.log(l_module_name, 'l_curr_count',L_CURR_COUNT);
            END IF;

            -- 10.20.40.20 Calling Move Order Line API
            --{
            IF l_debug_on THEN
               WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_PICK_LIST.Create_Move_Order_Lines'
                                                 ,WSH_DEBUG_SV.C_PROC_LEVEL);
               WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
            END IF;
            Create_Move_Order_Lines (
                                      p_batch_id                     => p_batch_id,
                                      p_worker_id                    => p_worker_id,
                                      p_organization_id              => batch_rec.organization_id,
                                      p_mo_header_id                 => batch_rec.mo_header_id,
                                      p_wms_flag                     => l_org_info.wms_org,
                                      p_auto_pick_confirm            => l_org_info.auto_pick_confirm,
                                      p_express_pick_flag            => l_org_info.express_pick_flag,
                                      p_pick_slip_grouping_rule      => l_org_info.pick_grouping_rule_id,
                                      p_to_subinventory              => l_org_info.to_subinventory,
                                      p_to_locator                   => l_org_info.to_locator,
				      p_use_header_flag              => l_org_info.use_header_flag, -- bug 8623544
                                      x_curr_count                   => l_curr_count,
                                      x_return_status                => l_return_status
                                    );
            IF l_debug_on THEN
              WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
              WSH_DEBUG_SV.log(l_module_name,'WSH_PICK_LIST.Create_Move_Order_Lines l_return_status' ,l_return_status);
            END IF;
            IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR)
            OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) THEN
               WSH_UTIL_CORE.PrintMsg('Error occurred in WSH_PICK_LIST.Create_Move_Order_Lines');
               RAISE e_return;
            ELSIF l_return_status = WSH_UTIL_CORE.G_RET_STS_WARNING THEN
               IF l_completion_status = 'NORMAL' THEN
                 l_completion_status := 'WARNING';
               END IF;
               IF l_debug_on THEN
                 WSH_DEBUG_SV.log(l_Module_name, 'Create_Move_Order_Lines returned with warning');
               END IF;
            END IF;
            --}

            -- Autocreate Deliveries is done, if any of following conditions are met:
            -- 1) If it is worker, then check if Pick Slip Printing Mode is Immediate
            --    or Delivery is part of Pick Slip Grouping Rule
            -- 2) If it is not worker and parameter p_num_workers in Release_Batch API > 1
            --    and if Pick Slip Printing Mode is Immediate or Delivery is part of Pick Slip Grouping Rule
            -- 3) If it is not worker and parameter p_num_workers in Release_Batch API = 1
            --{
            IF (p_worker_id IS NOT NULL AND (WSH_PR_CRITERIA.g_use_delivery_ps = 'Y' OR l_org_info.print_pick_slip_mode = 'I')) OR
               (p_worker_id IS NULL AND WSH_PICK_LIST.G_NUM_WORKERS > 1 AND (WSH_PR_CRITERIA.g_use_delivery_ps = 'Y'
                                                                          OR l_org_info.print_pick_slip_mode = 'I')) OR
               (p_worker_id IS NULL AND WSH_PICK_LIST.G_NUM_WORKERS = 1) THEN
               -- bug # 8915460 : Added l_continue_create_del
               IF ((l_org_info.autocreate_deliveries = 'Y') AND (WSH_PR_CRITERIA.g_trip_id = 0)
               AND (WSH_PR_CRITERIA.g_delivery_id = 0) AND (WSH_PR_CRITERIA.release_table.count > 0)
               AND l_continue_create_del = 'Y' )THEN
               --{
                  IF l_debug_on THEN
                     WSH_DEBUG_SV.logmsg(l_module_name,  '==================='  );
                     WSH_DEBUG_SV.logmsg(l_module_name,  'AUTOCREATE DELIVERY'  );
                     WSH_DEBUG_SV.logmsg(l_module_name,  '==================='  );
                  END IF;
                  -- Clear delivery detail IDs from table
                  l_del_details_tbl.delete;
                  -- Populate table with delivery detail IDs
                  l_detail_count := 1;
                  IF l_org_info.express_pick_flag = 'N' THEN
                  --{
                     i := g_del_detail_ids.FIRST;
                     -- Populate all Transactable Lines which are not assigned to a Delivery
                     WHILE i is NOT NULL LOOP
                           IF g_trolin_delivery_ids(i) IS NULL THEN
                              l_del_details_tbl(l_detail_count) := g_del_detail_ids(i);
                              l_detail_count := l_detail_count + 1;
                           END IF;
                           i := g_del_detail_ids.NEXT(i);
                     END LOOP;
                     -- Populate all Non Transactable Lines which are not assigned to a Delivery
                     FOR i IN 1..WSH_PR_CRITERIA.release_table.count LOOP
                         IF WSH_PR_CRITERIA.release_table(i).released_status = 'X' AND
                            WSH_PR_CRITERIA.release_table(i).delivery_id IS NULL THEN
                            l_del_details_tbl(l_detail_count) := WSH_PR_CRITERIA.release_table(i).delivery_detail_id;
                            l_detail_count := l_detail_count + 1;
                         END IF;
                     END LOOP;
                     -- Populate all X-dock Lines which are not assigned to a Delivery
                     i := g_xdock_detail_ids.FIRST;
                     WHILE i is NOT NULL LOOP
                           IF g_xdock_delivery_ids(i) IS NULL THEN
                              l_del_details_tbl(l_detail_count) := g_xdock_detail_ids(i);
                              l_detail_count := l_detail_count + 1;
                           END IF;
                           i := g_xdock_detail_ids.NEXT(i);
                     END LOOP;

                  --}
                  ELSE -- l_express_pick_flag =
                  --{
                     l_detail_count := 1;
                     l_prev_detail_id := NULL;
                     FOR i in g_exp_pick_release_stat.FIRST..g_exp_pick_release_stat.LAST LOOP
                         IF NVL(l_prev_detail_id,-99) <> g_exp_pick_release_stat(i).delivery_detail_id THEN
                            IF l_prev_detail_id is null THEN
                               j := g_del_detail_ids.FIRST;
                            ELSE
                               j := g_del_detail_ids.NEXT(j);
                            END IF;
                         END IF;
                         IF l_debug_on THEN
                            WSH_DEBUG_SV.logmsg(l_module_name,i||' Exp Org DD= '
                                         ||g_exp_pick_release_stat(i).delivery_detail_id|| ' j= '||j
                                         ||' Org DD '||g_del_detail_ids(j)||' Trolin Del '||g_trolin_delivery_ids(j));
                         END IF;
                         IF (g_exp_pick_release_stat(i).delivery_detail_id = g_del_detail_ids(j)
                         AND g_trolin_delivery_ids(j) is NULL) THEN
                             IF g_exp_pick_release_stat(i).pick_status in ('S') THEN
                                IF g_exp_pick_release_stat(i).split_delivery_id IS NOT NULL THEN
                                   l_del_details_tbl(l_detail_count) := g_exp_pick_release_stat(i).split_delivery_id;
                                   l_detail_count := l_detail_count + 1;
                                ELSE
                                   l_del_details_tbl(l_detail_count) := g_exp_pick_release_stat(i).delivery_detail_id;
                                   l_detail_count := l_detail_count + 1;
                                END IF;
                             END IF;
                         END IF;

                         l_prev_detail_id := g_exp_pick_release_stat(i).delivery_detail_id;
                     END LOOP;
                  --}
                  END IF;
                  IF l_debug_on THEN
                     WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_PICK_LIST.Autocreate_Deliveries'
                                                 ,WSH_DEBUG_SV.C_PROC_LEVEL);
                     WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
                  END IF;
                  Autocreate_Deliveries (
                                          p_append_flag         => l_org_info.append_flag,
                                          p_use_header_flag     => l_org_info.use_header_flag,
                                          p_del_details_tbl     => l_del_details_tbl,
                                          x_return_status       => l_return_status
                                        );
                  IF l_debug_on THEN
                     WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
                     WSH_DEBUG_SV.log(l_module_name,'WSH_PICK_LIST.Autocreate_Deliveries l_return_status'
                                                ,l_return_status);
                  END IF;
                  IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR)
                  OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) THEN
                     WSH_UTIL_CORE.PrintMsg('Error occurred in WSH_PICK_LIST.Autocreate_Deliveries');
                     RAISE e_return;
                  END IF;
                  -- bug # 8915460 : When pick release is performed by specifying deliery detail id/containerDDId
                  --                then auto create delivery can be performed only once because
                  --                 i) all details are assigned to same container(incase of containerDD as a parameter).
                  --                 ii) Single delivery detail id incase deliveydetailid as a parameter
                  IF ( l_del_details_tbl.COUNT > 0 AND NVL(WSH_PR_CRITERIA.g_del_detail_id,0) = -2 ) THEN
                  --{
                    l_continue_create_del := 'N';
                  --}
                  END IF;
               END IF;
               --}
            END IF;
            --}

            -- Call FTE Load Tender and Issue Commit for Concurrent Express Pick Release
            IF l_org_info.express_pick_flag = 'Y' AND ( G_CONC_REQ = FND_API.G_TRUE ) THEN --{
		    IF NOT(WSH_UTIL_CORE.G_CALL_FTE_LOAD_TENDER_API) THEN
		       IF l_debug_on THEN
			     WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_UTIL_CORE.Process_stops_for_load_tender',WSH_DEBUG_SV.C_PROC_LEVEL);
		       END IF;
		       WSH_UTIL_CORE.Process_stops_for_load_tender (
                                                                     p_reset_flags   => FALSE,
							             x_return_status => l_return_status );
		       IF l_debug_on THEN
		    	    WSH_DEBUG_SV.log(l_module_name,'l_return_status',l_return_status);
		       END IF;
                       IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR)
                       OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR) THEN
                           WSH_UTIL_CORE.PrintMsg('Error occurred in WSH_UTIL_CORE.Process_stops_for_load_tender');
                           RAISE e_return;
                       ELSIF l_return_status = WSH_UTIL_CORE.G_RET_STS_WARNING THEN
                           IF l_completion_status = 'NORMAL' THEN
                              l_completion_status := 'WARNING';
                           END IF;
                       END IF;
	            END IF;
                    IF l_debug_on THEN
                       WSH_DEBUG_SV.logmsg(l_module_name,  'Commiting...');
                    END IF;
                    COMMIT;
            END IF; --}

            -- Autodetailing Logic
            -- X-dock, no need to add filter for allocation_method in I,X,N only
            -- as g_trolin_tbl is populated only for these allocation methods
            IF l_org_info.express_pick_flag = 'N' AND (l_org_info.autodetail_flag =  'Y')
            AND (g_trolin_tbl.count > 0) THEN
            --{
                  IF l_org_info.auto_pick_confirm = 'Y' THEN
                     l_auto_pick_confirm_num := 1;
                  ELSE
                     l_auto_pick_confirm_num := 2;
                  END IF;
                  IF l_org_info.task_planning_flag = 'Y' THEN
                     l_plan_tasks := TRUE;
                     l_auto_pick_confirm_num := 2;
                     l_org_info.auto_pick_confirm := 'N';
                  ELSE
                     l_plan_tasks := FALSE;
                  END IF;

                  -- If Parallel process, then Cartonization is done in Parent Process
                  -- Else done here
                  IF WSH_PICK_LIST.G_PICK_REL_PARALLEL THEN
                     l_skip_cartonization := TRUE;
                     l_plan_tasks         := TRUE;
                  ELSE
                     l_skip_cartonization := FALSE;
                  END IF;

                  IF l_debug_on THEN
                     WSH_DEBUG_SV.logmsg(l_module_name,  '=========='  );
                     WSH_DEBUG_SV.logmsg(l_module_name,  'AUTODETAIL'  );
                     WSH_DEBUG_SV.logmsg(l_module_name,  '=========='  );
                     WSH_DEBUG_SV.logmsg(l_module_name, 'G_TROLIN_TBL.COUNT '||G_TROLIN_TBL.COUNT
                                                   ||'  G_ALLOCATION_METHOD :'||G_ALLOCATION_METHOD);
                     WSH_DEBUG_SV.log(l_module_name, 'l_auto_pick_confirm_num',l_auto_pick_confirm_num);
                     IF l_plan_tasks THEN
                        WSH_DEBUG_SV.logmsg(l_module_name, 'l_plan_tasks is TRUE');
                     ELSE
                        WSH_DEBUG_SV.logmsg(l_module_name, 'l_plan_tasks is FALSE');
                     END IF;
                     IF l_skip_cartonization THEN
                        WSH_DEBUG_SV.logmsg(l_module_name, 'l_skip_cartonization is TRUE');
                     ELSE
                        WSH_DEBUG_SV.logmsg(l_module_name, 'l_skip_cartonization is FALSE');
                     END IF;
                     WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
                     WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit INV_PICK_RELEASE_PUB.PICK_RELEASE',
                                         WSH_DEBUG_SV.C_PROC_LEVEL);
                  END IF;
                  -- X-dock
                  -- add parameters for X-dock
                  -- P_DEL_DETAIL_ID (g_xdock_detail_ids) :contains the list of delivery
                  --     details which have been  successfully planned for X-dock
                  -- P_TROLIN_DELIVERY_IDS (g_xdock_delivery_ids) : Matches index with
                  --     p_del_detail_id and stores delivery ids for the delivery
                  --     details(derived from release_table)
                  -- P_WSH_RELEASE_TABLE(wsh_pr_criteria.release_table) : IN/OUT variable,
                  --     in case of splitting of delivery details  new records will be added
                  --     to p_wsh_release_table
                  --bug# 6689448 (replenishment project): added the parameter P_dynamic_replenishment_flag
                  INV_Pick_Release_Pub.Pick_Release
                    (p_api_version         => l_api_version_number,
                     p_init_msg_list       => fnd_api.g_true,
                     p_commit              => l_commit,
                     p_mo_line_tbl         => g_trolin_tbl,
                     p_auto_pick_confirm   => l_auto_pick_confirm_num,
                     p_plan_tasks          => l_plan_tasks,
                     p_dynamic_replenishment => l_org_info.dynamic_replenishment_flag,
                     p_grouping_rule_id    => l_org_info.pick_grouping_rule_id,
                     p_skip_cartonization  => l_skip_cartonization,
                     p_wsh_release_table   => wsh_pr_criteria.release_table,
                     p_trolin_delivery_ids => g_xdock_delivery_ids,
                     p_del_detail_id       => g_xdock_detail_ids,
                     x_pick_release_status => l_pick_release_stat,
                     x_return_status       => l_return_status,
                     x_msg_count           => l_msg_count,
                     x_msg_data            => l_msg_data);

                  IF l_debug_on THEN
                     WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
                     WSH_DEBUG_SV.log(l_module_name,'INV_Pick_Release_Pub.Pick_Release l_return_status',
                                      l_return_status);
                  END IF;
                  IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR)
                  OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) THEN
                  --{
                     WSH_UTIL_CORE.PrintMsg('Error occurred in Inv_Pick_Release_Pub.Pick_Release');
                     FOR i in 1..l_msg_count LOOP
                         l_message := fnd_msg_pub.get(i,'F');
                         l_message := replace(l_message,chr(0),' ');
                         WSH_UTIL_CORE.PrintMsg(l_message);
                         IF (i = 1) THEN
                            l_message1 := l_message;
                         END IF;
                     END LOOP;
                     l_completion_status := 'WARNING';
                     fnd_msg_pub.delete_msg();
                     IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR) THEN
                        WSH_UTIL_CORE.PrintMsg('Unexpected error from INV_Pick_Release_Pub.Pick_Release. Exiting');
                        RAISE e_return;
                     ELSE
                     --{
                        ROLLBACK TO BEF_MOVE_ORDER_LINE_CREATE;
                        WSH_UTIL_CORE.PrintMsg('Auto Detailing Returned Expected Error');
                        l_request_id := fnd_global.conc_request_id;
                        IF (l_request_id <> -1 OR G_BATCH_ID IS NOT NULL ) THEN
                        --{
                           FOR i in 1 .. WSH_PR_CRITERIA.release_table.count
                           LOOP
                              IF l_debug_on THEN
                                 WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_UTIL_CORE.GET_ITEM_NAME',WSH_DEBUG_SV.C_PROC_LEVEL);
                              END IF;
                              l_item_name := WSH_UTIL_CORE.Get_Item_Name(
                                                    WSH_PR_CRITERIA.release_table(i).inventory_item_id,
                                                    WSH_PR_CRITERIA.release_table(i).organization_id);
                              FND_MESSAGE.SET_NAME('WSH','WSH_INV_EXPECTED_ERROR');
                              FND_MESSAGE.SET_TOKEN('ITEM',l_item_name);
                              FND_MESSAGE.SET_TOKEN('ORDER',WSH_PR_CRITERIA.release_table(i).source_header_number);
                              FND_MESSAGE.SET_TOKEN('INVMESSAGE',l_message1);
                              l_message := FND_MESSAGE.GET;
                              l_exception_return_status := NULL;
                              l_exception_msg_count := NULL;
                              l_exception_msg_data := NULL;
                              l_dummy_exception_id := NULL;
                              IF l_debug_on THEN
                                 WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_XC_UTIL.LOG_EXCEPTION'
                                                         ,WSH_DEBUG_SV.C_PROC_LEVEL);
                              END IF;
                              wsh_xc_util.log_exception(
                                  p_api_version   => 1.0,
                                  p_logging_entity  => 'SHIPPER',
                                  p_logging_entity_id => FND_GLOBAL.USER_ID,
                                  p_exception_name  => 'WSH_INV_EXPECTED_ERROR',
                                  p_message   => l_message,
                                  p_inventory_item_id => WSH_PR_CRITERIA.release_table(i).inventory_item_id,
                                  p_logged_at_location_id   => WSH_PR_CRITERIA.release_table(i).ship_from_location_id,
                                  p_exception_location_id   => WSH_PR_CRITERIA.release_table(i).ship_from_location_id,
                                  p_request_id  => l_request_id,
                                  p_batch_id  => WSH_PICK_LIST.g_batch_id,
                                  x_return_status   => l_exception_return_status,
                                  x_msg_count   => l_exception_msg_count,
                                  x_msg_data  => l_exception_msg_data,
                                  x_exception_id  => l_dummy_exception_id);
                              IF l_debug_on THEN
                                 WSH_DEBUG_SV.logmsg(l_module_name,  'LOGGED EXCEPTION '||L_DUMMY_EXCEPTION_ID  );
                              END IF;
                           END LOOP;
                        --}
                        END IF;
                     --}
                     END IF;
                  --}
                  END IF;
            --}
            -- For Auto Detail = No, set the Detailed Count to 1 always
            -- This is required so that we know that atleast 1 record was picked
            ELSIF l_org_info.express_pick_flag = 'N' AND (l_org_info.autodetail_flag =  'N')
            AND (g_trolin_tbl.count > 0) THEN

                 l_total_detailed_count := 1;
            END IF;


            -- Printing Pick Slips in Immediate Mode
            IF l_org_info.express_pick_flag = 'N' AND (l_org_info.autodetail_flag =  'Y')
            AND (g_trolin_tbl.count > 0) THEN
            --{
                  IF ( G_CONC_REQ = FND_API.G_TRUE ) THEN
                  --{
                     IF NOT(WSH_UTIL_CORE.G_CALL_FTE_LOAD_TENDER_API) THEN
                        IF l_debug_on THEN
                           WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_UTIL_CORE.Process_stops_for_load_tender',WSH_DEBUG_SV.C_PROC_LEVEL);
                        END IF;
                        WSH_UTIL_CORE.Process_stops_for_load_tender(
                                                                     p_reset_flags   => FALSE,
				                                     x_return_status => l_tmp_rel_status );
                        IF l_debug_on THEN
                           WSH_DEBUG_SV.log(l_module_name,'l_tmp_rel_status',l_tmp_rel_status);
                        END IF;
                        IF (l_tmp_rel_status = WSH_UTIL_CORE.G_RET_STS_ERROR)
                        OR (l_tmp_rel_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR) THEN
                            WSH_UTIL_CORE.PrintMsg('Error occurred in WSH_UTIL_CORE.Process_stops_for_load_tender');
                            RAISE e_return;
                        ELSIF l_tmp_rel_status = WSH_UTIL_CORE.G_RET_STS_WARNING THEN
                            IF l_completion_status = 'NORMAL' THEN
                               l_completion_status := 'WARNING';
                            END IF;
                        END IF;
                     END IF;
                  --}
                  END IF;

                  IF ((l_return_status = WSH_UTIL_CORE.G_RET_STS_SUCCESS)
                  OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR)) THEN
                  --{
                     FOR i in 1..l_pick_release_stat.count LOOP
                         IF l_debug_on THEN
                            WSH_DEBUG_SV.logmsg(l_module_name,
                               'MOVE ORDER LINE ID: '
                               || L_PICK_RELEASE_STAT(I).MO_LINE_ID
                               || ' RELEASE STATUS: '
                               || L_PICK_RELEASE_STAT(I).RETURN_STATUS
                               || ' DETAIL REC COUNT: '
                               || L_PICK_RELEASE_STAT(I).DETAIL_REC_COUNT  );
                         END IF;
                         IF l_pick_release_stat(i).detail_rec_count = 0 THEN
                            l_counter := g_trolin_tbl.FIRST ;
                            WHILE l_counter is NOT NULL LOOP
                               IF (g_trolin_tbl(l_counter).line_id = l_pick_release_stat(i).mo_line_id) THEN
                                  IF l_debug_on THEN
                                     WSH_DEBUG_SV.logmsg(l_module_name,  'REMOVING MOVE ORDER LINE '
                                                         ||L_PICK_RELEASE_STAT(I).MO_LINE_ID  );
                                  END IF;
                                  g_trolin_tbl.DELETE(l_counter);
                               END IF;
                               l_counter := g_trolin_tbl.NEXT(l_counter);
                            END LOOP;
                            l_pick_release_stat.DELETE(i);
                         END IF;
                     END LOOP;
                  --}
                  END IF;
                  IF ( G_CONC_REQ = FND_API.G_TRUE ) THEN
                       IF l_debug_on THEN
                          WSH_DEBUG_SV.logmsg(l_module_name,  'Commiting...');
                       END IF;
                       COMMIT;
                  END IF;

                  -- If Pick Slip Print Mode is Immediate for Non-WMS Orgs
                  -- OR Pick Slip Print Mode is Immediate and Cartonization is done before Allocation for WMS Orgs
                  IF (l_org_info.print_pick_slip_mode = 'I') AND (l_org_info.wms_org = 'N' OR
                  (l_org_info.wms_org = 'Y' AND p_worker_id IS NULL AND WSH_PICK_LIST.G_NUM_WORKERS = 1)) THEN
                  --{
                     IF (WSH_PR_PICK_SLIP_NUMBER.g_print_ps_table.COUNT > 0) THEN
                     --{
                        IF l_debug_on THEN
                             WSH_DEBUG_SV.logmsg(l_module_name,  'PRINTING PICK SLIPS IN IMMEDIATE MODE...'  );
                        END IF;
                        FOR i in WSH_PR_PICK_SLIP_NUMBER.g_print_ps_table.FIRST ..
                                                     WSH_PR_PICK_SLIP_NUMBER.g_print_ps_table.LAST
                        LOOP
                          IF l_debug_on THEN
                             WSH_DEBUG_SV.logmsg(l_module_name,  ' === PRINTING PICK SLIP '
                                                 ||WSH_PR_PICK_SLIP_NUMBER.G_PRINT_PS_TABLE ( I ) ||' ==='  );
                             WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_PR_PICK_SLIP_NUMBER.PRINT_PICK_SLIP',WSH_DEBUG_SV.C_PROC_LEVEL);
                          END IF;
                          WSH_PR_PICK_SLIP_NUMBER.Print_Pick_Slip(
                             p_pick_slip_number => WSH_PR_PICK_SLIP_NUMBER.g_print_ps_table(i),
                             p_report_set_id    => WSH_PICK_LIST.G_SEED_DOC_SET,
                             p_organization_id  => batch_rec.organization_id,
                             p_ps_mode          => 'I',
                             x_api_status       => l_return_status,
                             x_error_message    => l_message );
                          IF l_debug_on THEN
                             WSH_DEBUG_SV.log(l_module_name,'WSH_PR_PICK_SLIP_NUMBER.Print_Pick_Slip l_return_status'
                                                           ,l_return_status);
                             WSH_DEBUG_SV.log(l_module_name,'WSH_PR_PICK_SLIP_NUMBER.Print_Pick_Slip l_message'
                                                           ,l_message);
                          END IF;
                          IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR)
                          OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) THEN
                              WSH_UTIL_CORE.PrintMsg('** Warning: Cannot Print Pick Slip **');
                              WSH_UTIL_CORE.PrintMsg(l_message);
                              l_completion_status := 'WARNING';
                          END IF;
                        END LOOP;
                     --}
                     ELSE
                        IF l_debug_on THEN
                           WSH_DEBUG_SV.logmsg(l_module_name,  'NO PICK SLIPS TO PRINT'  );
                        END IF;
                     END IF;
                     WSH_PR_PICK_SLIP_NUMBER.g_print_ps_table.DELETE;
                  --}
                  END IF;

                  l_total_detailed_count := l_total_detailed_count + l_pick_release_stat.count ;
            --}
            ELSIF l_org_info.express_pick_flag = 'N' AND (l_org_info.autodetail_flag =  'N') THEN
                  -- Need to add this commit for scenarios where Auto Allocate is No and, if number of lines is
                  -- greater than Pick Release Batch size
	          IF ( G_CONC_REQ = FND_API.G_TRUE ) THEN
                     IF l_debug_on THEN
                        WSH_DEBUG_SV.logmsg(l_module_name,  'Commiting...');
                     END IF;
	             COMMIT;
	          END IF;
            END IF;

            fnd_msg_pub.delete_msg(); -- Clear Msg Buffer

            -- Auto Pick Confirm
            IF l_org_info.express_pick_flag = 'N' AND l_org_info.auto_pick_confirm = 'Y'
            AND l_pick_release_stat.count > 0 THEN
            --{
               WSH_PICK_LIST.G_AUTO_PICK_CONFIRM := 'Y';
               --{
               IF l_debug_on THEN
                  WSH_DEBUG_SV.logmsg(l_module_name,  '================='  );
                  WSH_DEBUG_SV.logmsg(l_module_name,  'AUTO PICK CONFIRM'  );
                  WSH_DEBUG_SV.logmsg(l_module_name,  '================='  );
                  WSH_DEBUG_SV.logmsg(l_module_name, 'G_TROLIN_TBL.COUNT '||G_TROLIN_TBL.COUNT
                                                   ||'  G_ALLOCATION_METHOD :'||G_ALLOCATION_METHOD);
                  WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
                  WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit INV_PICK_WAVE_PICK_CONFIRM_PUB.PICK_CONFIRM',WSH_DEBUG_SV.C_PROC_LEVEL);
               END IF;
               INV_Pick_Wave_Pick_Confirm_PUB.Pick_Confirm
                 (p_api_version_number => l_api_version_number,
                  p_init_msg_list      => FND_API.G_TRUE,
                  p_commit             => l_commit,
                  p_move_order_type    => INV_GLOBALS.G_MOVE_ORDER_PICK_WAVE,
                  p_transaction_mode   => 1,
                  p_trolin_tbl         => g_trolin_tbl,
                  p_mold_tbl           => l_mmtt_tbl,
                  x_mmtt_tbl           => l_mmtt_tbl,
                  x_trolin_tbl         => g_trolin_tbl,
                  x_return_status      => l_return_status,
                  x_msg_count          => l_msg_count,
                  x_msg_data           => l_msg_data
                 );
               IF l_debug_on THEN
                  WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
                  WSH_DEBUG_SV.log(l_module_name,'INV_Pick_Wave_Pick_Confirm_PUB.Pick_Confirm l_return_status',l_return_status);
               END IF;
               --}
               IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR)
               OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) THEN
               --{
                  WSH_UTIL_CORE.PrintMsg('Error occurred in INV_Pick_Wave_Pick_Confirm_PUB.Pick_Confirm');
                  FOR i in 1..l_msg_count LOOP
                      l_message := fnd_msg_pub.get(i,'F');
                      l_message := replace(l_message,chr(0),' ');
                      WSH_UTIL_CORE.PrintMsg(l_message);
                  END LOOP;
                  l_completion_status := 'WARNING';
                  fnd_msg_pub.delete_msg();
                  IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR) THEN
                      WSH_UTIL_CORE.PrintMsg('Unexpected error. Exiting');
		      --Bug 4906830
		      IF ( G_CONC_REQ = FND_API.G_TRUE ) THEN
                        l_temp := FND_CONCURRENT.SET_COMPLETION_STATUS('ERROR','');
                        errbuf := 'Unexpected error. Exiting';
                        retcode := '2';
                      ELSE
                        G_ONLINE_PICK_RELEASE_PHASE :='START';
                      END IF;
		      --Bug 4906830
                      RAISE e_return;
                  ELSE
                      WSH_UTIL_CORE.PrintMsg('Pick Confirm Partially Sucessful');
                  END IF;
               --}
               ELSIF (l_return_status = WSH_UTIL_CORE.G_RET_STS_SUCCESS) THEN
                  IF l_debug_on THEN
                     WSH_DEBUG_SV.logmsg(l_module_name,  'PICK CONFIRM SUCESSFUL'  );
                  END IF;
               END IF;

	       IF ( G_CONC_REQ = FND_API.G_TRUE ) THEN
               --{
  	            IF NOT(WSH_UTIL_CORE.G_CALL_FTE_LOAD_TENDER_API) THEN
		       IF l_debug_on THEN
		 	  WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_UTIL_CORE.Process_stops_for_load_tender',WSH_DEBUG_SV.C_PROC_LEVEL);
		       END IF;
		       WSH_UTIL_CORE.Process_stops_for_load_tender ( p_reset_flags   => FALSE,
							             x_return_status => l_return_status );
		       IF l_debug_on THEN
		   	  WSH_DEBUG_SV.log(l_module_name,'l_return_status',l_return_status);
		       END IF;
                       IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR)
                       OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR) THEN
                           WSH_UTIL_CORE.PrintMsg('Error occurred in WSH_UTIL_CORE.Process_stops_for_load_tender');
                           RAISE e_return;
                       ELSIF l_return_status = WSH_UTIL_CORE.G_RET_STS_WARNING THEN
                           IF l_completion_status = 'NORMAL' THEN
                              l_completion_status := 'WARNING';
                           END IF;
                       END IF;
		    END IF;
                    IF l_debug_on THEN
                       WSH_DEBUG_SV.logmsg(l_module_name,  'Commiting...');
                    END IF;
		    COMMIT;
	       END IF; --}
            --}
            END IF; /* Confirm Logic */


            -- Clear the table of move order line records for next loop
            g_trolin_tbl.delete;
            l_pick_release_stat.delete;

         --}
         END LOOP;

         -- Bug 9953872 - Need to update detailed_count in WSH_PR_WORKERS table,
         -- so that move order header is NOT deleted in specific case where last
         -- batch of lines picked are ignored (say if all the lines are part of
         -- ship set and if there are some more lines in OM that are not interfaced
         -- yet to shipping).
         -- Next Organization - Move Order Header Combination
         <<NEXT_ORG_MO_WORKER>>
         -- { Next Org MO Worker
         -- Increment worker record 'DOC' with records detailed count
         --{
         IF WSH_PR_CRITERIA.g_nonreservable_item = 'Y' and l_total_detailed_count = 0 THEN
            l_total_detailed_count := 1;
         END IF;
         IF l_total_detailed_count > 0 THEN

            UPDATE WSH_PR_WORKERS
            SET    detailed_count   = detailed_count + l_total_detailed_count
            WHERE  batch_id         = WSH_PICK_LIST.G_BATCH_ID
            AND    organization_id  = batch_rec.organization_id
            AND    type             = 'DOC';
            --
            IF l_debug_on THEN
               WSH_DEBUG_SV.log(l_module_name, 'No of rows updated for type DOC with detailed_count ' || l_total_detailed_count, sql%rowcount);
            END IF;
            --
         END IF;
         --}

         -- Insert printer record into worker table for pick slip printing on specific printers
         --{
         IF WSH_INV_INTEGRATION_GRP.G_PRINTERTAB.COUNT > 0 THEN
            FOR i in 1..WSH_INV_INTEGRATION_GRP.G_PRINTERTAB.COUNT LOOP
                IF WSH_INV_INTEGRATION_GRP.G_PRINTERTAB(i).printer_name IS NOT null THEN
                   INSERT INTO WSH_PR_WORKERS (
                                                batch_id,
                                                type,
                                                organization_id,
                                                printer_name,
						conc_program_name
                                              )
                                      SELECT
                                                WSH_PICK_LIST.G_BATCH_ID,
                                                'PRINTER',
                                                batch_rec.organization_id,
                                                WSH_INV_INTEGRATION_GRP.G_PRINTERTAB(i).printer_name,
                                                WSH_INV_INTEGRATION_GRP.G_PRINTERTAB(i).conc_program_name
                                      FROM dual
                                      WHERE NOT EXISTS (
                                                         SELECT 'x'
                                                         FROM   wsh_pr_workers
                                                         WHERE  batch_id = WSH_PICK_LIST.G_BATCH_ID
                                                         AND    type = 'PRINTER'
                                                         AND    organization_id = batch_rec.organization_id
                                                         AND    printer_name = WSH_INV_INTEGRATION_GRP.G_PRINTERTAB(i).printer_name
							 AND    conc_program_name=WSH_INV_INTEGRATION_GRP.G_PRINTERTAB(i).conc_program_name);
                END IF;
            END LOOP;
         END IF;
         --}

	 IF ( G_CONC_REQ = FND_API.G_TRUE ) THEN
            IF l_debug_on THEN
               WSH_DEBUG_SV.logmsg(l_module_name,  'Commiting...');
            END IF;
	    COMMIT;
	 END IF;
         -- } Next Org MO Worker

     --}
     END LOOP;

     -- Set Completion Status
     -- Completion status to warning for error backordered.
     IF ( G_BACKORDERED ) AND l_completion_status <> 'ERROR' THEN
        l_completion_status := 'WARNING';
     END IF;

     WSH_UTIL_CORE.PrintMsg('Picking in Release_Batch_Sub is completed');

  END IF;
  --}

  -- 20. For p_mode = 'PS'
  --{
  IF p_mode = 'PS' THEN

     FOR crec in c_get_del LOOP
     --{
         l_rec_found := FALSE;
         DECLARE
           worker_row_locked exception;
           PRAGMA EXCEPTION_INIT(worker_row_locked, -54);
         BEGIN
           IF l_debug_on THEN
              WSH_DEBUG_SV.logmsg(l_module_name,'Getting lock for Del '||crec.delivery_id);
           END IF;
           -- Bug # 9369504 : Added rowid in the where clause.
           SELECT 'x'
           INTO   l_dummy
           FROM   wsh_pr_workers
           WHERE  rowid = crec.rowid
           AND    processed = 'N'
           FOR    UPDATE NOWAIT;
           l_rec_found := TRUE;

           UPDATE wsh_pr_workers
           SET    processed = 'Y'
           WHERE  rowid= crec.rowid;

         EXCEPTION
           WHEN NO_DATA_FOUND THEN
             l_rec_found := FALSE;
           WHEN WORKER_ROW_LOCKED THEN
             l_rec_found := FALSE;
         END;

         IF l_rec_found THEN
         --{
            IF crec.ap_level > 0 THEN
            --{
               IF l_debug_on THEN
                  WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_BATCH_PROCESS.Auto_Pack_A_Delivery'
                                                    ,WSH_DEBUG_SV.C_PROC_LEVEL);
               END IF;
               l_del_pack_count := l_del_pack_count + 1;
               WSH_BATCH_PROCESS.Auto_Pack_A_Delivery (
                                                        p_delivery_id     => crec.delivery_id,
                                                        p_ap_batch_id     => crec.PA_SC_BATCH_ID,
                                                        p_auto_pack_level => crec.ap_level,
                                                        p_log_level       => p_log_level,
                                                        x_return_status   => l_return_status
                                                      );
               IF l_return_status = WSH_UTIL_CORE.G_RET_STS_SUCCESS THEN
                  l_packed_results_success := l_packed_results_success + 1;
               ELSIF l_return_status = WSH_UTIL_CORE.G_RET_STS_WARNING   THEN
                  l_packed_results_warning := l_packed_results_warning + 1;
                  WSH_BATCH_PROCESS.log_batch_messages (
                                                         crec.PA_SC_BATCH_ID,
                                                         crec.delivery_id,
                                                         NULL,
                                                         crec.PICKUP_LOCATION_ID,
                                                         'W' );
               ELSE
                  l_packed_results_failure := l_packed_results_failure + 1;
                  WSH_BATCH_PROCESS.log_batch_messages (
                                                         crec.PA_SC_BATCH_ID,
                                                         crec.delivery_id,
                                                         NULL,
                                                         crec.PICKUP_LOCATION_ID,
                                                         'E' );
               END IF;
            --}
            END IF;

            IF l_debug_on THEN
               WSH_DEBUG_SV.log(l_module_name,'sc_rule_id',crec.sc_rule_id);
            END IF;

            IF crec.sc_rule_id IS NOT NULL THEN
            --{
               DECLARE
                 WSH_MISSING_SC_BATCH EXCEPTION;
                 WSH_MISSING_SC_RULE EXCEPTION;
               BEGIN
                 l_del_sc_count := l_del_sc_count + 1;
                 IF crec.sc_rule_id <> nvl(l_prev_sc_rule_id,-99) THEN
                 --{
                    OPEN WSH_BATCH_PROCESS.G_GET_SHIP_CONFIRM_RULE(crec.sc_rule_id);
                    FETCH WSH_BATCH_PROCESS.G_GET_SHIP_CONFIRM_RULE
                       INTO l_ship_confirm_rule_rec;
                    IF WSH_BATCH_PROCESS.G_GET_SHIP_CONFIRM_RULE%NOTFOUND THEN
                       CLOSE WSH_BATCH_PROCESS.G_GET_SHIP_CONFIRM_RULE;
                       RAISE WSH_MISSING_SC_RULE;
                    ELSE
                       CLOSE WSH_BATCH_PROCESS.G_GET_SHIP_CONFIRM_RULE;
                    END IF;
                    l_prev_sc_rule_id := crec.sc_rule_id;
                 --}
                 END IF;

                 --{
                 IF l_debug_on THEN
                    WSH_DEBUG_SV.logmsg(l_module_name, 'Calling program unit WSH_BATCH_PROCESS.Ship_Confirm_A_Delivery');
                 END IF;
                 WSH_BATCH_PROCESS.Ship_Confirm_A_Delivery (
                         p_delivery_id            => crec.delivery_id,
                         p_sc_batch_id            => crec.pa_sc_batch_id,
                         p_ship_confirm_rule_rec  => l_ship_confirm_rule_rec,
                         p_log_level              => p_log_level,
                         p_actual_departure_date  => WSH_PR_CRITERIA.g_actual_departure_date,
                         x_return_status          => l_return_status
                        );
                 IF l_return_status = WSH_UTIL_CORE.G_RET_STS_SUCCESS THEN
                    l_confirmed_results_success := l_confirmed_results_success + 1;
                 ELSIF l_return_status = WSH_UTIL_CORE.G_RET_STS_WARNING   THEN
                    l_confirmed_results_warning := l_confirmed_results_warning + 1;
                    WSH_BATCH_PROCESS.log_batch_messages (
                                                           crec.PA_SC_BATCH_ID,
                                                           crec.delivery_id,
                                                           NULL,
                                                           crec.PICKUP_LOCATION_ID,
                                                           'W' );
                 ELSE
                    l_confirmed_results_failure := l_confirmed_results_failure + 1;
                    WSH_BATCH_PROCESS.log_batch_messages (
                                                           crec.PA_SC_BATCH_ID,
                                                           crec.delivery_id,
                                                           NULL,
                                                           crec.PICKUP_LOCATION_ID,
                                                           'E' );
                 END IF;
                 --}
               EXCEPTION
                 WHEN WSH_MISSING_SC_RULE THEN
                   WSH_UTIL_CORE.PrintMsg('ERROR: Failed to find the ship confirm rule ');
                   l_confirmed_results_failure := l_confirmed_results_failure + 1;
               END;
            --}
            END IF;

         --}
         END IF;

     --}
     END LOOP;

     IF l_debug_on THEN
        WSH_DEBUG_SV.log(l_module_name,'l_completion_status ', l_completion_status);
        WSH_DEBUG_SV.logmsg(l_module_name,'l_del_pack_count '||l_del_pack_count
                                    ||' l_packed_results_success '||l_packed_results_success
                                    ||' l_del_sc_count '||l_del_sc_count
                                    ||' l_confirmed_results_success '||l_confirmed_results_success);
     END IF;
     IF l_completion_status = 'NORMAL' THEN
        IF (l_del_pack_count > 0 AND l_packed_results_success <> l_del_pack_count)
        OR (l_del_sc_count > 0 AND l_confirmed_results_success <> l_del_sc_count) THEN
            l_completion_status := 'WARNING';
        END IF;
     END IF;

  END IF;
  --}

  --{ Online Message
  IF (l_completion_status = 'WARNING') THEN
      G_ONLINE_PICK_RELEASE_RESULT := 'W';
  ELSE
      G_ONLINE_PICK_RELEASE_RESULT := 'S';
      G_ONLINE_PICK_RELEASE_PHASE := 'SUCCESS';
  END IF;

  IF G_CONC_REQ = FND_API.G_TRUE THEN
     -- Set the completion status only in the case of Child Request
     -- If this is done as part of Parent Process, this setting will cause program to stop without doing
     -- any further processing
     IF p_worker_id is not null then
        l_temp := FND_CONCURRENT.SET_COMPLETION_STATUS(l_completion_status,'');
     END IF;

     IF l_completion_status = 'NORMAL' THEN
        retcode := '0';
     ELSIF l_completion_status = 'WARNING' THEN
        retcode := '1';
     ELSE
        retcode := '2';
     END IF;
  END IF;
  --}

  IF l_debug_on THEN
     WSH_DEBUG_SV.logmsg(l_module_name,'ERRBUF :'||errbuf ||' RETCODE :'||retcode||' l_completion_status :'||l_completion_status);
     WSH_DEBUG_SV.pop(l_module_name);
  END IF;

EXCEPTION
  WHEN e_return THEN

      --Bug 5355135
      IF G_CONC_REQ = FND_API.G_TRUE THEN
         ROLLBACK;
      ELSE
         ROLLBACK TO s_Release_Batch_Sub_sf;
      END IF;

      WSH_UTIL_CORE.PrintMsg('SQLCODE: '||sqlcode||' SQLERRM: '||sqlerrm);
      WSH_UTIL_CORE.PrintMsg('Exception occurred in WSH_PICK_LIST.Release_Batch_Sub');
      IF G_CONC_REQ = FND_API.G_TRUE THEN
         -- Set the completion status only in the case of Child Request
         -- If this is done as part of Parent Process, this setting will cause program to stop without doing
         -- any further processing
         IF p_worker_id is not null then
            l_temp := FND_CONCURRENT.SET_COMPLETION_STATUS('ERROR','');
         END IF;
         errbuf := 'Exception occurred in WSH_PICK_LIST';
         retcode := '2';
      END IF;
      G_ONLINE_PICK_RELEASE_RESULT := 'F';
      IF l_debug_on THEN
         WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:E_RETURN');
      END IF;
  WHEN OTHERS THEN
      --Bug 5355135
      IF G_CONC_REQ = FND_API.G_TRUE THEN
         ROLLBACK;
      ELSE
         ROLLBACK TO s_Release_Batch_Sub_sf;
      END IF;

      WSH_UTIL_CORE.PrintMsg('SQLCODE: '||sqlcode||' SQLERRM: '||sqlerrm);
      WSH_UTIL_CORE.PrintMsg('Exception occurred in WSH_PICK_LIST.Release_Batch_Sub');
      IF G_CONC_REQ = FND_API.G_TRUE THEN
         -- Set the completion status only in the case of Child Request
         -- If this is done as part of Parent Process, this setting will cause program to stop without doing
         -- any further processing
         IF p_worker_id is not null then
            l_temp := FND_CONCURRENT.SET_COMPLETION_STATUS('ERROR','');
         END IF;
         errbuf := 'Exception occurred in WSH_PICK_LIST';
         retcode := '2';
      END IF;
      G_ONLINE_PICK_RELEASE_RESULT := 'F';
      IF l_debug_on THEN
         WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '
                                           || SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
         WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
      END IF;

END Release_Batch_Sub;


-- Start of comments
-- API name : Release_Batch
-- Type     : Public
-- Pre-reqs : None.
-- Procedure: This is core api to pick release a batch, api does
--            1. Gets initializes batch criteria.
--            2. Select details lines based on release criteria.
--            3. Calls Inventory Move Order api for allocation and pick confirmation.
--            4. Create/Appened deliveries, pack or ship confirmed based on release criteria.
--            5. Print document sets.
-- Parameters :
-- IN:
--      p_batch_id            IN  Batch Id.
--      p_log_level           IN  Set the debug log level.
--      p_num_workers         IN  Number of workers
-- OUT:
--      errbuf       OUT NOCOPY  Error message.
--      retcode      OUT NOCOPY  Error Code 1:Successs, 2:Warning and 3:Error.
-- End of comments
PROCEDURE Release_Batch (
          errbuf    OUT NOCOPY   VARCHAR2,
          retcode OUT NOCOPY   VARCHAR2,
          p_batch_id  IN  NUMBER,
          p_log_level  IN   NUMBER DEFAULT 0, 
          p_num_workers IN  NUMBER
           ) IS
          record_locked  EXCEPTION;
          PRAGMA EXCEPTION_INIT(record_locked, -54);


          -- Cursor to select organization ids when no
          -- organization is specified in the picking batch
          -- Only one select statement will be executed

          -- Added DISTINCT for the first 2 queries to fix Bug 1644985
           CURSOR get_orgs(v_trip_id   IN NUMBER,
            v_trip_stop_id  IN NUMBER,
            v_from_loc_id   IN NUMBER,
            v_delivery_id   IN NUMBER,
            v_order_hdr_id  IN NUMBER,
            v_del_detail_id IN NUMBER,
            v_batch_id  IN NUMBER,
	    v_fromSchDate IN DATE,
	    v_ToSchDate   IN DATE,
            v_FromReqDate IN DATE,
	    v_ToReqDate	  IN DATE
          ) IS
          SELECT DISTINCT WND.ORGANIZATION_ID
          FROM   WSH_NEW_DELIVERIES WND,
           WSH_DELIVERY_LEGS WLG,
           WSH_TRIP_STOPS WTS
          WHERE  WTS.TRIP_ID   = v_trip_id
          AND WTS.STOP_ID = WLG.PICK_UP_STOP_ID
          AND WLG.DELIVERY_ID  = WND.DELIVERY_ID
          AND nvl(WND.SHIPMENT_DIRECTION , 'O') IN ('O', 'IO')   -- J Inbound Logistics
          AND v_trip_stop_id = 0
          AND v_delivery_id = 0
          AND v_order_hdr_id = 0
          -- Bug 11669468: Included -2 in IN clause
          AND v_del_detail_id in (0,-1,-2)
          AND (v_from_loc_id = -1
          OR WND.ORGANIZATION_ID IN (SELECT organization_id
               FROM   hr_organization_units hr,
              wsh_locations wl
              WHERE wl.wsh_location_id = v_from_loc_id
              AND wl.location_source_code = 'HR'
              AND wl.source_location_id =
                 hr.location_id))
          UNION ALL
          SELECT DISTINCT WND.ORGANIZATION_ID
          FROM   WSH_NEW_DELIVERIES WND,
           WSH_DELIVERY_LEGS WLG,
           WSH_TRIP_STOPS WTS
          WHERE  WTS.STOP_ID  = WLG.PICK_UP_STOP_ID
          AND WLG.DELIVERY_ID  = WND.DELIVERY_ID
          AND WTS.STOP_ID = v_trip_stop_id
          AND nvl(WND.SHIPMENT_DIRECTION , 'O') IN ('O', 'IO')   -- J Inbound Logistics
          AND v_delivery_id = 0
          AND v_order_hdr_id = 0
          -- Bug 11669468: Included -2 in IN clause
          AND v_del_detail_id in (0,-1,-2)
          UNION ALL
          SELECT WND.ORGANIZATION_ID
          FROM   WSH_NEW_DELIVERIES WND
          WHERE  WND.DELIVERY_ID = v_delivery_id
          AND nvl(WND.SHIPMENT_DIRECTION , 'O') IN ('O', 'IO')   -- J Inbound Logistics
          UNION ALL
          SELECT DISTINCT ORGANIZATION_ID
          FROM   WSH_DELIVERY_DETAILS
          WHERE  SOURCE_CODE = 'OE'
          AND    RELEASED_STATUS IN ('R', 'B', 'X') -- Added For Bug-2722194 (Non-Assigned and
                                               -- Ready to release Lines -> Base Bug-2687090)
          AND SOURCE_HEADER_ID = v_order_hdr_id
          -- Bug 11669468: Included -2 in IN clause
          AND v_del_detail_id  in (0,-1,-2)
          AND v_delivery_id = 0
          UNION ALL
          SELECT DISTINCT ORGANIZATION_ID
          FROM WSH_DELIVERY_DETAILS
          WHERE DELIVERY_DETAIL_ID =   v_del_detail_id
          AND nvl(LINE_DIRECTION , 'O') IN ('O', 'IO')   -- J Inbound Logistics
          AND  v_delivery_id  = 0
          UNION ALL
          SELECT DISTINCT WDD.ORGANIZATION_ID
          FROM WSH_DELIVERY_DETAILS WDD
          WHERE  v_delivery_id  = 0
          AND nvl(WDD.LINE_DIRECTION , 'O') IN ('O', 'IO')   -- J Inbound Logistics
          -- Bug 11669468: Included -2 in IN clause
          AND v_del_detail_id  in (0, -1,-2)
          AND  WDD.BATCH_ID =   v_batch_id;

          --Cursor to get ship confirm rule and Packing level.
          CURSOR get_pack_ship_groups(v_batch_id in number) IS
          SELECT wsp.ship_confirm_rule_id, wsp.autopack_level
          FROM   wsh_shipping_parameters wsp, wsh_delivery_details wdd
          WHERE  wdd.batch_id = v_batch_id
          AND    wsp.organization_id = wdd.organization_id
          GROUP  BY wsp.ship_confirm_rule_id, wsp.autopack_level;

          TYPE group_details_rec_tab_type IS TABLE OF get_pack_ship_groups%ROWTYPE INDEX BY BINARY_INTEGER;

          --Cursor to get delivery detail attributes for ship confirm rule and Packing level.
          CURSOR get_dels_in_group(v_batch_id in number, v_sc_rule_id in number, v_ap_level in number) IS
          SELECT DISTINCT wda.delivery_id, wdd.organization_id,
	         wdd.ship_from_location_id
          FROM   wsh_delivery_assignments_v wda, wsh_delivery_details wdd,
                 wsh_shipping_parameters wsp
          WHERE  wdd.batch_id = v_batch_id
          AND    wdd.delivery_detail_id = wda.delivery_detail_id
          AND    wdd.organization_id = wsp.organization_id
          AND    NVL(wsp.ship_confirm_rule_id, 0) = NVL(v_sc_rule_id, 0)
          AND    NVL(wsp.autopack_level, 0) = NVL(v_ap_level, 0)
          AND    NVL(wdd.LINE_DIRECTION , 'O') IN ('O', 'IO');   -- J Inbound Logistics

          --Cursor to get delivery detail attributes for batch_id.
          CURSOR get_dels_in_batch(v_batch_id in number) IS
          SELECT DISTINCT wda.delivery_id, wdd.organization_id,
                 wdd.ship_from_location_id
          FROM   wsh_delivery_assignments_v wda, wsh_delivery_details wdd
          WHERE  wdd.batch_id = v_batch_id
          AND    wdd.delivery_detail_id = wda.delivery_detail_id
          AND    NVL(wdd.LINE_DIRECTION , 'O') IN ('O', 'IO');   -- J Inbound Logistics

          l_group_details_rec_tab   group_details_rec_tab_type;

          -- Sort the organization ids to prevent processing of duplicate organization ids
          CURSOR c_distinct_organization_id IS
          SELECT distinct id FROM wsh_tmp;

          CURSOR c_get_backordered_details(l_batch_id NUMBER) IS
          SELECT wdd.delivery_detail_id, wda.delivery_id, wda.parent_delivery_detail_id, wdd.organization_id,
                 wdd.line_direction, wdd.gross_weight, wdd.net_weight, wdd.volume,
                 wnd.planned_flag, wnd.batch_id
          FROM   wsh_delivery_details wdd,
                 wsh_delivery_assignments_v wda,
                 wsh_new_deliveries wnd
          WHERE  wdd.batch_id = l_batch_id
          AND    wdd.delivery_detail_id = wda.delivery_detail_id
          AND    wdd.released_status = 'B'
          AND    wdd.replenishment_status IS NULL  -- replenishment2, select only back order delivery lines.
          AND    wda.delivery_id = wnd.delivery_id(+);

          l_backorder_rec_tbl    WSH_USA_INV_PVT.Back_Det_Rec_Tbl;

          CURSOR c_batch_orgs(l_batch_id NUMBER) IS
          SELECT organization_id
          FROM   wsh_pr_workers
          WHERE  batch_id = l_batch_id
          AND    type = 'DOC';

          CURSOR c_get_unassigned_details(l_batch_id NUMBER, l_organization_id NUMBER) IS
          SELECT wdd.delivery_detail_id
          FROM   wsh_delivery_details wdd,
                 wsh_delivery_assignments_v wda
          WHERE  wdd.batch_id = l_batch_id
          AND    wdd.released_status in ('S','Y')
          AND    wdd.delivery_detail_id = wda.delivery_detail_id
          AND    wdd.organization_id = l_organization_id
          AND    wda.delivery_id IS NULL;

          -- get total worker records for Pick Release
          CURSOR c_tot_worker_records(l_batch_id NUMBER) is
          SELECT COUNT(*)
          FROM   wsh_pr_workers
          WHERE  batch_id = l_batch_id
          AND    type = 'PICK'
          AND    PROCESSED = 'N';

          CURSOR c_sum_worker(l_batch_id NUMBER) is
          SELECT organization_id, mo_header_id, DETAILED_COUNT tot_detailed
          FROM   wsh_pr_workers
          WHERE  batch_id = l_batch_id
          AND    type = 'DOC'
          ORDER  BY organization_id;

          CURSOR c_defer_interface(l_batch_id NUMBER) is
          SELECT DISTINCT wpr.pa_sc_batch_id, wscr.ac_defer_interface_flag
          FROM   wsh_pr_workers wpr,
                 wsh_ship_confirm_rules wscr
          WHERE  wpr.batch_id = l_batch_id
          AND    wpr.type = 'PS'
          AND    wpr.sc_rule_id = wscr.SHIP_CONFIRM_RULE_ID
          AND    NVL(EFFECTIVE_START_DATE, sysdate) <= sysdate
          AND    NVL(EFFECTIVE_END_DATE, sysdate ) >= sysdate;

          CURSOR c_close_trip(l_pickrel_batch_id NUMBER) is
          SELECT DISTINCT wpr.batch_id, wpb.creation_date,
                 wscr.ac_close_trip_flag, wscr.ac_intransit_flag
          FROM   wsh_picking_batches wpb, wsh_ship_confirm_rules wscr, wsh_pr_workers wpr
          WHERE  wpr.batch_id = l_pickrel_batch_id
          AND    wpr.type = 'PS'
          AND    wpb.batch_id = wpr.pa_sc_batch_id
          AND    wpb.ship_confirm_rule_id = wscr.ship_confirm_rule_id
          AND    NVL(wscr.EFFECTIVE_START_DATE, sysdate) <= sysdate
          AND    NVL(wscr.EFFECTIVE_END_DATE, sysdate ) >= sysdate;

          CURSOR get_pick_up_stops (c_sc_batch_id NUMBER)  IS
          SELECT DISTINCT wtp.trip_id, wst.stop_sequence_number,
                 wst.stop_id, wst.stop_location_id
          FROM wsh_new_deliveries wnd,
               wsh_delivery_legs  wlg,
               wsh_trip_stops  wst,
               wsh_trips      wtp
          WHERE wnd.delivery_id = wlg.delivery_id AND
                wlg.pick_up_stop_id = wst.stop_id AND
                wnd.status_code = 'CO' AND
                wnd.batch_id = c_sc_batch_id AND
                wtp.trip_id = wst.trip_id AND
                wst.status_code = 'OP' AND
                NOT EXISTS (
                select '1' from wsh_exceptions we where
                we.delivery_id = wnd.delivery_id AND
                we.severity = 'ERROR' AND
                we.status = 'OPEN' AND
                we.EXCEPTION_NAME = 'WSH_SC_REQ_EXPORT_COMPL')
          ORDER BY wtp.trip_id, wst.stop_sequence_number, wst.stop_id ;


          CURSOR get_all_stops (c_sc_batch_id NUMBER) IS
          SELECT  wtp.trip_id, wst.stop_sequence_number, wst.stop_id ,
                  wst.stop_location_id
          FROM wsh_new_deliveries wnd,
               wsh_delivery_legs  wlg,
               wsh_trip_stops  wst,
               wsh_trips      wtp
          WHERE wnd.delivery_id = wlg.delivery_id and
                wlg.pick_up_stop_id = wst.stop_id and
                wnd.status_code = 'CO' and
                wnd.batch_id = c_sc_batch_id and
                wst.trip_id = wtp.trip_id and
                wst.status_code = 'OP' AND
          NOT EXISTS (
                select '1' from wsh_exceptions we where
                we.delivery_id = wnd.delivery_id AND
                we.severity = 'ERROR' AND
                we.status = 'OPEN' AND
                we.EXCEPTION_NAME = 'WSH_SC_REQ_EXPORT_COMPL')
          UNION (
          SELECT wtp2.trip_id, wst2.stop_sequence_number,
                 wst2.stop_id, wst2.stop_location_id
          FROM wsh_new_deliveries wnd2,
               wsh_delivery_legs  wlg2,
               wsh_trip_stops  wst2,
               wsh_trips      wtp2
          WHERE wnd2.delivery_id = wlg2.delivery_id and
                wlg2.drop_off_stop_id = wst2.stop_id and
                wnd2.status_code = 'CO' and
                wnd2.batch_id = c_sc_batch_id and
                wst2.trip_id = wtp2.trip_id and
                wst2.status_code = 'OP' AND
          NOT EXISTS (
                select '1' from wsh_exceptions we where
                we.delivery_id = wnd2.delivery_id AND
                we.severity = 'ERROR' AND
                we.status = 'OPEN' AND
                we.EXCEPTION_NAME = 'WSH_SC_REQ_EXPORT_COMPL'))
          ORDER BY 1, 2, 3;


          CURSOR c_batch_stop(l_batch_id NUMBER) IS
          SELECT wts.stop_id
          FROM   wsh_trip_stops    wts,
                 wsh_delivery_legs  wdl,
                 wsh_new_deliveries wnd,
                 wsh_picking_batches wpb
          WHERE p_batch_id IS NOT NULL
          AND   wnd.batch_id    = l_batch_id
          AND   wdl.delivery_id = wnd.delivery_id
          AND   wts.stop_id     = wdl.pick_up_stop_id
          AND   wts.stop_location_id = wnd.initial_pickup_location_id
          AND   wpb.batch_id = wnd.batch_id
          AND   wts.status_code = 'CL'
          AND   rownum = 1;

          CURSOR c_batch_unplanned_del(l_batch_id NUMBER) IS
          SELECT DISTINCT wda.delivery_id
          FROM   wsh_delivery_details wdd,
                 wsh_delivery_assignments_v wda,
                 wsh_new_deliveries wnd,
                 wsh_shipping_parameters wsp
          WHERE  wdd.delivery_detail_id = wda.delivery_detail_id
          AND    wdd.batch_id = l_batch_id
          AND    wdd.released_status = 'Y'
          AND    wda.delivery_id = wnd.delivery_id
          AND    wda.delivery_id IS NOT NULL
          AND    wnd.planned_flag = 'N'
          AND    wnd.organization_id = wsp.organization_id
          AND    NVL(wsp.appending_limit, 'N') <> 'N';

          CURSOR c_ap_batch(l_batch_id NUMBER) IS
          SELECT DISTINCT pa_sc_batch_id
          FROM   wsh_pr_workers
          WHERE  batch_id = l_batch_id
          AND    type = 'PS'
          AND    NVL(ap_level,0) > 0;

          CURSOR c_wms_orgs (l_batch_id NUMBER) IS
          SELECT organization_id, mo_header_id
          FROM   wsh_pr_workers
          WHERE  batch_id  = l_batch_id
          AND    type  = 'WMS'
          AND    processed = 'N'      --WMS High Vol Support, Added this AND cond and ORDER BY clause
          ORDER BY organization_id;

          -- X-dock changes to only select which have been released to warehouse from Inventory
          CURSOR c_wms_details (l_batch_id NUMBER, l_organization_id NUMBER, l_mo_header_id NUMBER) IS
          SELECT wdd.delivery_detail_id, wdd.move_order_line_id
          FROM   wsh_delivery_details wdd,
                 mtl_txn_request_lines mtrl,
                 mtl_txn_request_headers mtrh
          WHERE  wdd.batch_id         = l_batch_id
          AND    wdd.organization_id  = l_organization_id
          AND    wdd.move_order_line_id IS NOT NULL
          AND    wdd.move_order_line_id = mtrl.line_id
          AND    mtrl.header_id = mtrh.header_id
          AND    mtrh.header_id = l_mo_header_id
          AND    mtrh.move_order_type <> 6
          AND    wdd.released_status  = WSH_DELIVERY_DETAILS_PKG.C_RELEASED_TO_WAREHOUSE; -- auto pick confirm = 'N' for these lines


          CURSOR c_dels_in_batch(l_batch_id NUMBER, p_organization_id NUMBER) IS
          SELECT delivery_id
          FROM   wsh_new_deliveries
          WHERE  batch_id = l_batch_id
          AND    organization_id = p_organization_id;

          CURSOR c_get_location(p_delivery_id NUMBER) IS
          SELECT initial_pickup_location_id
          FROM   wsh_new_deliveries
          WHERE  delivery_id  = p_delivery_id;

          CURSOR c_requests (p_parent_request_id NUMBER) IS
          SELECT request_id
          FROM   FND_CONCURRENT_REQUESTS
          WHERE  parent_request_id = p_parent_request_id
          AND    NVL(is_sub_request, 'N') = 'Y';

          CURSOR c_is_psgr_del(p_psgr_id NUMBER) IS
          select NVL(wpgr.delivery_flag, 'N')
          from  wsh_pick_grouping_rules wpgr
          where  wpgr.pick_grouping_rule_id = p_psgr_id
          and    sysdate between trunc(nvl(wpgr.start_date_active, sysdate)) and
                                          nvl(wpgr.end_date_active, trunc(sysdate)+1);

          CURSOR c_is_print_ps_mode_I IS
          select wsp.organization_id
          from wsh_shipping_parameters wsp, wsh_tmp wt
          where wt.id = wsp.organization_id
          and wsp.print_pick_slip_mode = 'I'
          and rownum = 1;

          CURSOR c_is_print_ps_mode_I_for_org(p_org_id NUMBER) IS
          select wsp.organization_id
          from wsh_shipping_parameters wsp
          where wsp.organization_id = p_org_id
          and wsp.print_pick_slip_mode = 'I';

          CURSOR c_prnt_PS_mode_PS_grp IS
          select wsp.organization_id
          from wsh_shipping_parameters wsp, wsh_tmp wt
          where wt.id = wsp.organization_id
          and (wsp.print_pick_slip_mode = 'I'
          OR exists
          (select '1'
          from  wsh_pick_grouping_rules wpgr
          where  wpgr.pick_grouping_rule_id = wsp.pick_grouping_rule_id
          and    sysdate between trunc(nvl(wpgr.start_date_active, sysdate)) and
                                          nvl(wpgr.end_date_active, trunc(sysdate)+1)
          AND wpgr.delivery_flag = 'Y'))
          AND rownum = 1;

          CURSOR c_prnt_PS_mode_PS_grp_for_org (p_org_id NUMBER) IS
          select wsp.organization_id
          from wsh_shipping_parameters wsp
          where wsp.organization_id = p_org_id
          and (wsp.print_pick_slip_mode = 'I'
          OR exists
          (select '1'
          from  wsh_pick_grouping_rules wpgr
          where  wpgr.pick_grouping_rule_id = wsp.pick_grouping_rule_id
          and    sysdate between trunc(nvl(wpgr.start_date_active, sysdate)) and
                                          nvl(wpgr.end_date_active, trunc(sysdate)+1)
          AND wpgr.delivery_flag = 'Y'));

          --bug# 6689448 (replenishment project) : needs to pass replenishment requested lines to WMS
          CURSOR get_replenish_orgs(c_batch_id NUMBER) IS
          SELECT DISTINCT organization_id
          FROM wsh_delivery_details
          WHERE  released_status = 'B'
          AND    replenishment_status = 'R'
          AND    batch_id = c_batch_id;


          l_return_status VARCHAR2(1);
          l_completion_status VARCHAR2(30);
          l_temp    BOOLEAN;
          l_trohdr_rec              INV_MOVE_ORDER_PUB.Trohdr_Rec_Type;
          l_empty_trohdr_rec  INV_MOVE_ORDER_PUB.Trohdr_Rec_Type;
          l_trohdr_val_rec  INV_MOVE_ORDER_PUB.Trohdr_Val_Rec_Type;
          l_empty_trohdr_val_rec  INV_MOVE_ORDER_PUB.Trohdr_Val_Rec_Type;
          l_trolin_tbl                   INV_MOVE_ORDER_PUB.Trolin_Tbl_Type;
          l_trolin_val_tbl               INV_MOVE_ORDER_PUB.Trolin_Val_Tbl_Type;
          l_api_version_number   NUMBER := 1.0;
          l_msg_count   NUMBER;
          l_msg_data  VARCHAR2(2000);
          l_commit  VARCHAR2(1) := FND_API.G_FALSE;
          l_delivery_id   NUMBER;
          l_trip_id   NUMBER;
          l_trip_stop_id  NUMBER;
          l_ship_from_loc_id  NUMBER;
          l_source_header_id  NUMBER;
          l_delivery_detail_id  NUMBER;
          l_to_subinventory VARCHAR2(10);
          l_to_locator  NUMBER;
          l_fromSchDate  DATE;
          l_toSchDate    DATE;
          l_fromReqDate  DATE;
          l_toReqDate    DATE;
          l_tmp_org_id NUMBER;
          l_psgr_delivery_flag VARCHAR2(1);

	  TYPE organization_tab_type IS TABLE OF NUMBER index by BINARY_INTEGER ;
	  l_organization_tab            organization_tab_type;
          l_distinct_organization_tab   organization_tab_type;
          l_dummy_tab                   organization_tab_type;
          l_dummy1_tab                  organization_tab_type;

          l_index NUMBER;
	  l_organization_id NUMBER;

          l_user_id   NUMBER;
          l_login_id  NUMBER;
          l_date    DATE;
          l_message   VARCHAR2(2000);
          l_rowid   VARCHAR2(30);
          l_curr_count   NUMBER;
          l_batch_name  VARCHAR2(30);
          l_task_planning_flag  WSH_PICKING_BATCHES.task_planning_flag%TYPE;
          l_init_rules  VARCHAR2(1) := FND_API.G_FALSE;
          l_print_cursor_flag  VARCHAR2(1);
          l_pr_worker_rec_count NUMBER := 0;
          l_counter   NUMBER := 0;
          l_count NUMBER := 0;
          l_del_batch_id  NUMBER;
          l_del_batch_name  VARCHAR2(30);
          l_tmp_row_id  VARCHAR2(2000);
          l_delivery_ids  WSH_UTIL_CORE.Id_Tab_Type;
          l_request_id NUMBER;
          l_item_name VARCHAR2(2000);
          l_message1   VARCHAR2(2000);
          l_exception_return_status  VARCHAR2(30);
          l_exception_msg_count   NUMBER;
          l_exception_msg_data   VARCHAR2(4000) := NULL;
          l_dummy_exception_id   NUMBER;
          l_warehouse_type   VARCHAR2(10);
          l_temp_num     NUMBER;
          l_del_ids_tab  wsh_util_core.id_tab_type;   -- empty table of delivery ids

          i   NUMBER;
          j   NUMBER;

          l_ps_delivery_tab         WSH_UTIL_CORE.Id_Tab_Type;
          l_ps_org_tab              WSH_UTIL_CORE.Id_Tab_Type;
          l_ps_pick_loc_tab         WSH_UTIL_CORE.Id_Tab_Type;
          l_ap_batch_id             NUMBER;
          l_sc_id_tab               WSH_UTIL_CORE.Id_Tab_Type;
          l_interface_stop_id       NUMBER;
          l_batch_creation_date     DATE := NULL;
          l_ac_close_trip_flag      VARCHAR2(1);
          l_ac_intransit_flag       VARCHAR2(1);
          l_stop_sequence_number    NUMBER;
          l_stop_id                 NUMBER;
          l_stop_location_id        NUMBER;
          l_stops_to_close          WSH_UTIL_CORE.Id_Tab_Type;
          l_stop_location_ids       WSH_UTIL_CORE.Id_Tab_Type;
          l_stops_sc_ids            WSH_UTIL_CORE.Id_Tab_Type;
          l_closing_stop_success    NUMBER := 0;
          l_closing_stop_failure    NUMBER := 0;
          l_closing_stop_warning    NUMBER := 0;
          l_lock_error              VARCHAR2(1);

          l_act_ap_level            NUMBER;
          l_ap_level                NUMBER;
          l_act_ap_flag             VARCHAR2(1);
          l_ap_flag                 VARCHAR2(1);
          l_sc_rule_id              NUMBER;
          l_group_nums              NUMBER;
          l_del_count               NUMBER;
          l_grp_count               NUMBER;
          --
          l_debug_on                BOOLEAN;
          l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'RELEASE_BATCH';
          --
          l_num_workers             NUMBER;
          l_tot_worker_records      NUMBER;
          l_tot_smc_records         NUMBER;
          l_tot_dd_records          NUMBER;
          l_worker_records          NUMBER;
          l_smc_records             NUMBER;
          l_dd_records              NUMBER;
          l_org_info                WSH_PICK_LIST.Org_Params_Rec;
          l_org_info_tbl            WSH_PICK_LIST.Org_Params_Rec_Tbl;
          l_detail_cfetch           NUMBER;
          l_detail_pfetch           NUMBER;
          l_del_details_tbl         WSH_UTIL_CORE.Id_Tab_Type;
          l_mo_lines_tbl            INV_MOVE_ORDER_PUB.Num_Tbl_Type;
          l_carton_grouping_tbl     INV_MOVE_ORDER_PUB.Num_Tbl_Type;
          l_print_ps                VARCHAR2(1);
          l_phase                   VARCHAR2(100);
          l_status                  VARCHAR2(100);
          l_dev_phase               VARCHAR2(100);
          l_dev_status              VARCHAR2(100);
          l_child_req_ids           WSH_UTIL_CORE.Id_Tab_Type;
          l_this_request            NUMBER;
          l_dummy                   BOOLEAN;
          l_errors                  NUMBER := 0;
          l_warnings                NUMBER := 0;
          l_pr_batch_size           NUMBER;

          l_attr_tab                WSH_DELIVERY_AUTOCREATE.Grp_attr_tab_type;
          l_group_tab               WSH_DELIVERY_AUTOCREATE.Grp_attr_tab_type;
          l_action_rec              WSH_DELIVERY_AUTOCREATE.Action_rec_type;
          l_target_rec              WSH_DELIVERY_AUTOCREATE.Grp_attr_rec_type;
          l_matched_entities        WSH_UTIL_CORE.id_tab_type;
          l_out_rec                 WSH_DELIVERY_AUTOCREATE.Out_rec_type;

	  l_check_dcp               NUMBER;
          l_in_param_rec            WSH_FTE_INTEGRATION.rate_del_in_param_rec;
          l_out_param_rec           WSH_FTE_INTEGRATION.rate_del_out_param_rec;
          l_rate_dels_tab           WSH_UTIL_CORE.Id_Tab_Type;

          l_excp_location_id        NUMBER;

          l_api_session_name CONSTANT VARCHAR2(150) := G_PKG_NAME ||'.' || l_module_name;
          l_reset_flags             BOOLEAN;
          e_return                  EXCEPTION;

          l_request_data            VARCHAR2(30);
          l_mode                    VARCHAR2(30);
          l_retcode                 VARCHAR2(10);
          l_errbuf                  VARCHAR2(2000);

	  --bug 7171766
          l_match_found BOOLEAN;
          l_group_match_seq_tbl    WSH_PICK_LIST.group_match_seq_tab_type;
          K NUMBER ;
	  l_org_complete           VARCHAR2(1);         --WMS High Vol Support
          v_wms_org_rec            c_wms_orgs%ROWTYPE;  --WMS High Vol Support


BEGIN
  SAVEPOINT s_Release_Batch_sp;

  -- 10. Load Tendering Initializations
  IF WSH_UTIL_CORE.G_START_OF_SESSION_API is null THEN
     WSH_UTIL_CORE.G_START_OF_SESSION_API     := l_api_session_name;
     WSH_UTIL_CORE.G_CALL_FTE_LOAD_TENDER_API := FALSE;
  END IF;

  -- 20. DCP Checks
  l_check_dcp := WSH_DCP_PVT.G_CHECK_DCP;
  IF l_check_dcp IS NULL THEN
     l_check_dcp := wsh_dcp_pvt.is_dcp_enabled;
  END IF;

  --Set global for DCP checks
  --Since pick release does dcp check at the end, group apis need not do the same check.
  IF NVL(l_check_dcp, -99) IN (1,2) THEN
     WSH_DCP_PVT.G_CALL_DCP_CHECK := 'N';
  END IF;
  
  -- 30. Logging Settings
  IF G_CONC_REQ = FND_API.G_TRUE 
  THEN
     WSH_UTIL_CORE.Enable_Concurrent_Log_Print;
     IF p_log_level IS NOT NULL  THEN
        WSH_UTIL_CORE.Set_Log_Level(p_log_level);
        WSH_UTIL_CORE.PrintMsg('p_log_level is ' || to_char(p_log_level));
     END IF;

  END IF;
  l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
  

  
  IF l_debug_on IS NULL
  THEN
    l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
  END IF;
  IF l_debug_on THEN
     WSH_DEBUG_SV.push(l_module_name);
     WSH_DEBUG_SV.log(l_module_name,'P_BATCH_ID',P_BATCH_ID);
     WSH_DEBUG_SV.log(l_module_name,'P_LOG_LEVEL',P_LOG_LEVEL);
     WSH_DEBUG_SV.log(l_module_name,'P_NUM_WORKERS',P_NUM_WORKERS);
  END IF;

  -- Set Online Pick Release Result
  -- 40. Initialized  pick release phase to Start.
  G_ONLINE_PICK_RELEASE_PHASE := 'START';
  G_BACKORDERED := FALSE;
  G_ONLINE_PICK_RELEASE_SKIP := 'N';
  G_NUM_WORKERS := NVL(P_NUM_WORKERS, 1);
  IF G_NUM_WORKERS = 1 THEN
     G_PICK_REL_PARALLEL := FALSE;
  END IF;

  l_completion_status := 'NORMAL';
  -- Bug 5222079
  -- Clear the pick slip number table
  --
  IF l_debug_on THEN
     WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_PR_PICK_SLIP_NUMBER.DELETE_PS_TBL',WSH_DEBUG_SV.C_PROC_LEVEL);
  END IF;
  --
  WSH_PR_PICK_SLIP_NUMBER.Delete_ps_tbl (x_api_status => l_return_status,
                                         x_error_message => l_message);
  IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR)
     OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) THEN
  --{
     WSH_UTIL_CORE.PrintMsg('Error occurred in WSH_PR_PICK_SLIP_NUMBER.Delete_ps_tbl');
     RAISE e_return;
  END IF; --}
  -- end bug 5222079

  -- Read the Value from REQUEST_DATA. Based on this value, we will know
  -- if the Process is restarted after child processes are complete
  -- The format of Request_Data is 'Batch_id:Request_Status:Mode', where
  -- Batch_id is the Pick Release Batch, Request_Status is either 0 (Success) or 1 (Warning)
  -- and Mode is either of the following values.
  -- Valid Values :
  -- 1) NULL    : Implies First Time or Single Worker Mode
  -- 2) PICK-SS : Resuming Parent Process after Child Processes for SMCs/Ship Sets have completed
  -- 3) PICK    : Resuming Parent Process after Child Processes for Standard Items have completed
  -- 4) PS      : Resuming Parent Process after Child Processes for Pack and Ship have completed
  -- Parent process will always be restarted after child processes complete
  l_request_data := FND_CONC_GLOBAL.Request_Data;
  l_mode         := SUBSTR(l_request_data, INSTR(l_request_data,':',1,2)+1, LENGTH(l_request_data));

  -- Check for current request status from request_data
  -- Set the Backorder Flag to denote that Current Request Status need to be as Warning
  IF l_request_data IS NOT NULL AND SUBSTR(l_request_data, INSTR(l_request_data,':',1,1)+1, 1) = 1 THEN
     G_BACKORDERED := TRUE;
  END IF;

  -- 50. Any other initializations
  -- Set flag to print cursor information
  l_print_cursor_flag := 'Y';

  IF l_debug_on THEN
     WSH_DEBUG_SV.log(l_module_name,'l_mode ',l_mode);
  END IF;

  IF l_mode IS NULL THEN
     IF l_debug_on THEN
        WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
        select count(*) into l_temp_num from wsh_Delivery_details where batch_id = p_batch_id;
        WSH_DEBUG_SV.log(l_module_name,'DDs for batch ',l_temp_num);
        WSH_DEBUG_SV.log(l_module_name,'G_NUM_WORKERS ',G_NUM_WORKERS);
     END IF;
  END IF;

  -- 60. Calling Init_Pick_Release API to initialize global variables in WSH_PR_CRITERIA package
  --     and also set Batch_Id and Seeded Pick Release Document Set
  IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit INIT_PICK_RELEASE',WSH_DEBUG_SV.C_PROC_LEVEL);
  END IF;
  Init_Pick_Release( p_batch_id      => p_batch_id,
                     p_worker_id     => NULL,
                     x_return_status => l_return_status);

  IF l_debug_on THEN
     WSH_DEBUG_SV.log(l_module_name,'INIT_PICK_RELEASE l_return_status',l_return_status);
     select count(*) into l_temp_num from wsh_Delivery_details where batch_id = p_batch_id;
     WSH_DEBUG_SV.log(l_module_name,'DDs for batch ',l_temp_num);
     WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
  END IF;

  IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR) THEN
     WSH_UTIL_CORE.PrintMsg('Error occurred in Init_Pick_Release');
     RAISE e_return;
  END IF;

  -- 70. Initializations for local variables

  -- Set values selected in criteria package
  l_user_id            := WSH_PR_CRITERIA.g_user_id;
  l_login_id           := WSH_PR_CRITERIA.g_login_id;
  l_date               := SYSDATE;
  l_organization_id    := WSH_PR_CRITERIA.g_organization_id;
  l_trip_id            := WSH_PR_CRITERIA.g_trip_id;
  l_trip_stop_id       := WSH_PR_CRITERIA.g_trip_stop_id;
  l_ship_from_loc_id   := WSH_PR_CRITERIA.g_ship_from_loc_id;
  l_delivery_id        := WSH_PR_CRITERIA.g_delivery_id;
  l_source_header_id   := WSH_PR_CRITERIA.g_order_header_id;
  l_delivery_detail_id := WSH_PR_CRITERIA.g_del_detail_id;
  l_batch_name         := WSH_PR_CRITERIA.g_batch_name;
  l_task_planning_flag := WSH_PR_CRITERIA.g_task_planning_flag;
  l_fromSchDate        := WSH_PR_CRITERIA.g_FROM_SCHED_SHIP_DATE;
  l_toSchDate          := WSH_PR_CRITERIA.G_TO_SCHED_SHIP_DATE;
  l_FromReqDate        := WSH_PR_CRITERIA.G_FROM_REQUEST_DATE;
  l_ToReqDate          := WSH_PR_CRITERIA.G_TO_REQUEST_DATE;

  -- 80. Fetching Organization(s).
  IF l_organization_id IS NULL THEN --{
        IF l_mode IS NULL THEN --{
        -- Parent Process
	   OPEN  get_orgs(l_trip_id, l_trip_stop_id, l_ship_from_loc_id,
	   	          l_delivery_id, l_source_header_id,
                 	  l_delivery_detail_id, p_batch_id,
		          l_fromSchDate, l_toSchDate, l_FromReqDate, l_toReqDate);
	   FETCH get_orgs BULK COLLECT INTO l_organization_tab;
	   CLOSE get_orgs;
        ELSE
        -- Organization records can be obtained from worker table as original cursor cannot be reused
           OPEN  c_batch_orgs(p_batch_id);
           FETCH c_batch_orgs BULK COLLECT INTO l_organization_tab;
           CLOSE c_batch_orgs;
        END IF; --}

	IF l_debug_on THEN
           WSH_DEBUG_SV.log(l_module_name,  'Number of Organizations',l_organization_tab.count);
	END IF;
	IF l_organization_tab.COUNT = 0 THEN
	   WSH_UTIL_CORE.PrintMsg('No organization found. Cannot Pick Release.');
	   RAISE e_return;
	END IF;
  --}
  ELSE
	-- Need to initialize the table , when l_organization_id is not NULL
        --Cursor get_orgs is not opened.
	l_organization_tab(1) := l_organization_id;
	IF l_debug_on THEN
	   WSH_DEBUG_SV.log(l_module_name,  'Number of Organizations',l_organization_tab.count);
	END IF;
  END IF;

  -- 80. Sorting for Distinct records of Organizations
  IF l_organization_tab.count > 1 AND l_mode IS NULL THEN --{
    IF l_debug_on THEN
      WSH_DEBUG_SV.log(l_module_name,'Count is more than 1 : ',l_organization_tab.count);
    END IF;
    DELETE FROM wsh_tmp;

    FORALL i IN l_organization_tab.FIRST..l_organization_tab.LAST
      INSERT INTO wsh_tmp (id) VALUES(l_organization_tab(i));

    OPEN c_distinct_organization_id;
    FETCH c_distinct_organization_id BULK COLLECT INTO l_distinct_organization_tab;
    CLOSE c_distinct_organization_id;

    IF l_debug_on THEN
      WSH_DEBUG_SV.log(l_module_name,'Distinct Count : ',l_distinct_organization_tab.count);
      WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
      WSH_DEBUG_SV.log(l_module_name,'G_NUM_WORKERS ',G_NUM_WORKERS);
    END IF;


    -- Bug 5247554: Force the number of workers to be 1 if the pick slip grouping criteria includes
    -- delivery or print pick slip mode is immediate.

    IF l_debug_on THEN
       WSH_DEBUG_SV.log(l_module_name,'WSH_PR_CRITERIA.g_pick_grouping_rule_id ',WSH_PR_CRITERIA.g_pick_grouping_rule_id);
       WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
       WSH_DEBUG_SV.log(l_module_name,'G_NUM_WORKERS ',G_NUM_WORKERS);
    END IF;
    IF WSH_PR_CRITERIA.g_pick_grouping_rule_id IS NOT NULL THEN
       OPEN c_is_psgr_del(WSH_PR_CRITERIA.g_pick_grouping_rule_id);
       FETCH c_is_psgr_del INTO l_psgr_delivery_flag;
       CLOSE c_is_psgr_del;

       IF l_psgr_delivery_flag = 'Y' THEN
          G_NUM_WORKERS := 1;
          G_PICK_REL_PARALLEL := FALSE;
          IF l_debug_on THEN
             WSH_DEBUG_SV.log(l_module_name,'l_psgr_delivery_flag',l_psgr_delivery_flag);
             WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
             WSH_DEBUG_SV.log(l_module_name,'G_NUM_WORKERS ',G_NUM_WORKERS);
          END IF;
       ELSE
          OPEN c_is_print_ps_mode_I;
          FETCH c_is_print_ps_mode_I INTO l_tmp_org_id;
          IF c_is_print_ps_mode_I%FOUND THEN
             G_NUM_WORKERS := 1;
             G_PICK_REL_PARALLEL := FALSE;
          END IF;
          CLOSE c_is_print_ps_mode_I;
          IF l_debug_on THEN
             WSH_DEBUG_SV.log(l_module_name,'l_psgr_delivery_flag',l_psgr_delivery_flag);
             WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
             WSH_DEBUG_SV.log(l_module_name,'G_NUM_WORKERS ',G_NUM_WORKERS);
          END IF;
       END IF;
    ELSE
       OPEN c_prnt_PS_mode_PS_grp;
       FETCH c_prnt_PS_mode_PS_grp INTO l_tmp_org_id;
       IF c_prnt_PS_mode_PS_grp%FOUND THEN
          G_NUM_WORKERS := 1;
          G_PICK_REL_PARALLEL := FALSE;
       END IF;
       CLOSE c_prnt_PS_mode_PS_grp;
       IF l_debug_on THEN
          WSH_DEBUG_SV.log(l_module_name,'l_psgr_delivery_flag',l_psgr_delivery_flag);
          WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
          WSH_DEBUG_SV.log(l_module_name,'G_NUM_WORKERS ',G_NUM_WORKERS);
       END IF;
    END IF;

    -- END  Bug 5247554.

    DELETE FROM wsh_tmp;

    l_organization_tab.delete;
    l_organization_tab := l_distinct_organization_tab;
  ELSIF l_organization_tab.count = 1 AND l_mode IS NULL THEN

     -- Bug 5247554: Force the number of workers to be 1 if the pick slip grouping criteria includes
     -- delivery or print pick slip mode is immediate.
    IF l_debug_on THEN
       WSH_DEBUG_SV.log(l_module_name,'WSH_PR_CRITERIA.g_pick_grouping_rule_id ',WSH_PR_CRITERIA.g_pick_grouping_rule_id);
       WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
       WSH_DEBUG_SV.log(l_module_name,'G_NUM_WORKERS ',G_NUM_WORKERS);
    END IF;
    IF WSH_PR_CRITERIA.g_pick_grouping_rule_id IS NOT NULL THEN
       OPEN c_is_psgr_del(WSH_PR_CRITERIA.g_pick_grouping_rule_id);
       FETCH c_is_psgr_del INTO l_psgr_delivery_flag;
       CLOSE c_is_psgr_del;

       IF l_psgr_delivery_flag = 'Y' THEN
          G_NUM_WORKERS := 1;
          G_PICK_REL_PARALLEL := FALSE;
          IF l_debug_on THEN
             WSH_DEBUG_SV.log(l_module_name,'l_psgr_delivery_flag ',l_psgr_delivery_flag);
             WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
             WSH_DEBUG_SV.log(l_module_name,'G_NUM_WORKERS ',G_NUM_WORKERS);
          END IF;
       ELSE
          OPEN c_is_print_ps_mode_I_for_org(l_organization_tab(1));
          FETCH c_is_print_ps_mode_I_for_org INTO l_tmp_org_id;
          IF c_is_print_ps_mode_I_for_org%FOUND THEN
             G_NUM_WORKERS := 1;
             G_PICK_REL_PARALLEL := FALSE;
          END IF;
          CLOSE c_is_print_ps_mode_I_for_org;
          IF l_debug_on THEN
             WSH_DEBUG_SV.log(l_module_name,'l_psgr_delivery_flag ',l_psgr_delivery_flag);
             WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
             WSH_DEBUG_SV.log(l_module_name,'G_NUM_WORKERS ',G_NUM_WORKERS);
          END IF;
       END IF;
    ELSE
       OPEN c_prnt_PS_mode_PS_grp_for_org(l_organization_tab(1));
       FETCH c_prnt_PS_mode_PS_grp_for_org INTO l_tmp_org_id;
       IF c_prnt_PS_mode_PS_grp_for_org%FOUND THEN
          G_NUM_WORKERS := 1;
          G_PICK_REL_PARALLEL := FALSE;
       END IF;
       CLOSE c_prnt_PS_mode_PS_grp_for_org;
       IF l_debug_on THEN
          WSH_DEBUG_SV.log(l_module_name,'WSH_PR_CRITERIA.g_use_delivery_ps ',WSH_PR_CRITERIA.g_use_delivery_ps);
          WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
          WSH_DEBUG_SV.log(l_module_name,'G_NUM_WORKERS ',G_NUM_WORKERS);
       END IF;
    END IF;

    -- END  Bug 5247554.

  END IF; --}

  -- 90. Loop through each organization and create a Move Order
  --     Header and calculate workers records
  l_tot_worker_records := 0; -- total worker records
  l_tot_smc_records    := 0; -- total smc worker count
  l_tot_dd_records     := 0; -- total details count

  FOR idx in l_organization_tab.FIRST..l_organization_tab.LAST LOOP  --{

      l_organization_id := l_organization_tab(idx);

      -- 90.1 Clear the Global PL/SQL Tables for printers.
      WSH_INV_INTEGRATION_GRP.G_PRINTERTAB.delete ;
      WSH_INV_INTEGRATION_GRP.G_ORGTAB.delete ;
      WSH_INV_INTEGRATION_GRP.G_ORGSUBTAB.delete ;

      IF l_debug_on THEN
	 WSH_DEBUG_SV.logmsg(l_module_name, '********************************************');
         WSH_DEBUG_SV.logmsg(l_module_name, 'Processing Org ' || l_organization_id);
      END IF;

      IF l_mode IS NULL THEN --{

         -- 90.2 : Reinitialize dd count and worker count for each Organization
         l_worker_records := 0; -- worker records for single org
         l_smc_records    := 0; -- smc worker count for single org
         l_dd_records     := 0; -- details count for single org


         -- 90.3 Get the Warehouse type.
         l_warehouse_type := WSH_EXTERNAL_INTERFACE_SV.Get_Warehouse_Type(
            p_organization_id => l_organization_id,
            p_event_key => NULL,
            x_return_status   => l_return_status);
         IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_SUCCESS) THEN --{
             IF l_debug_on THEN
                WSH_DEBUG_SV.log(l_module_name, 'Org Type', L_WAREHOUSE_TYPE  );
             END IF;

             --- TPW - Distributed Organization Changes
             --IF l_warehouse_type = 'TPW' THEN
             IF l_warehouse_type in ( 'TPW', 'TW2' ) THEN
                IF l_debug_on THEN
                   WSH_DEBUG_SV.logmsg(l_module_name,'SKIPPING TPW ORGANIZATION (PICKING IS NOT SUPPORTED)');
                END IF;
                GOTO next_organization;
             END IF;
         --}
         ELSIF (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) OR
               (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR) THEN --{

                WSH_UTIL_CORE.PrintMsg('Error occurred in WSH_EXTERNAL_INTERFACE_SV.Get_Warehouse_Type');
                RAISE e_return;

         END IF;  --}

      END IF; --}

      -- 90.4 Getting Organization Parameters
      IF l_debug_on THEN
         WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit GET_ORG_PARAMS',WSH_DEBUG_SV.C_PROC_LEVEL);
      END IF;
      Get_Org_Params ( p_organization_id => l_organization_id,
                       x_org_info        => l_org_info,
                       x_return_status   => l_return_status);
      IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) OR
         (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR) THEN
          IF l_debug_on THEN
             WSH_DEBUG_SV.logmsg(l_module_name, 'Error occurred in Get_Org_Params');
          END IF;
          RAISE e_return;
      END IF;

      -- Table of Organizations Related Info
      -- This is used in Autocreate Deliveries in Parent Process
      l_org_info_tbl(l_organization_id).autocreate_deliveries     := l_org_info.autocreate_deliveries;
      l_org_info_tbl(l_organization_id).autodetail_flag           := l_org_info.autodetail_flag;
      l_org_info_tbl(l_organization_id).append_flag               := l_org_info.append_flag;
      l_org_info_tbl(l_organization_id).print_pick_slip_mode      := l_org_info.print_pick_slip_mode;
      l_org_info_tbl(l_organization_id).pick_grouping_rule_id     := l_org_info.pick_grouping_rule_id;
      l_org_info_tbl(l_organization_id).doc_set_id                := l_org_info.doc_set_id;
      l_org_info_tbl(l_organization_id).use_header_flag           := l_org_info.use_header_flag;
      l_org_info_tbl(l_organization_id).auto_apply_routing_rules  := l_org_info.auto_apply_routing_rules;
      l_org_info_tbl(l_organization_id).auto_calc_fgt_rate_cr_del := l_org_info.auto_calc_fgt_rate_cr_del;
      l_org_info_tbl(l_organization_id).task_planning_flag        := l_org_info.task_planning_flag;
      l_org_info_tbl(l_organization_id).express_pick_flag         := l_org_info.express_pick_flag;
      l_org_info_tbl(l_organization_id).wms_org                   := l_org_info.wms_org;
      --bug# 6689448 (replenishment project)
      l_org_info_tbl(l_organization_id).pick_seq_rule_id          := l_org_info.pick_seq_rule_id;



      IF l_mode IS NULL THEN --{
          -- 90.5 Clear move order header records
          l_trohdr_rec     := l_empty_trohdr_rec;
          l_trohdr_val_rec := l_empty_trohdr_val_rec;

          -- 90.6 Insert values into record for Create Move Order Header
          l_trohdr_rec.created_by       := l_user_id;
          l_trohdr_rec.creation_date    := l_date;
          l_trohdr_rec.last_updated_by  := l_user_id;
          l_trohdr_rec.last_update_date := l_date;
          l_trohdr_rec.last_update_login := l_login_id;
          l_trohdr_rec.organization_id  := l_organization_id;
          l_trohdr_rec.grouping_rule_id := l_org_info.pick_grouping_rule_id;
          l_trohdr_rec.move_order_type  := INV_GLOBALS.G_MOVE_ORDER_PICK_WAVE;
          l_trohdr_rec.transaction_type_id := NULL;
          l_trohdr_rec.operation        := INV_GLOBALS.G_OPR_CREATE;
          l_trohdr_rec.header_status    :=  INV_Globals.G_TO_STATUS_PREAPPROVED;
          l_trohdr_rec.request_number   := l_batch_name;

          -- 90.7 Create Move Order Header
          IF l_debug_on THEN
             WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit INV_MOVE_ORDER_PUB.CREATE_MOVE_ORDER_HEADER',WSH_DEBUG_SV.C_PROC_LEVEL);
             WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
          END IF;

          Inv_Move_Order_Pub.Create_Move_Order_Header
              (
                p_api_version_number => l_api_version_number,
                p_init_msg_list      => FND_API.G_FALSE,
                p_return_values      => FND_API.G_TRUE,
                p_commit             => l_commit,
                p_trohdr_rec         => l_trohdr_rec,
                p_trohdr_val_rec     => l_trohdr_val_rec,
                x_trohdr_rec         => l_trohdr_rec,
                x_trohdr_val_rec     => l_trohdr_val_rec,
                x_return_status      => l_return_status,
                x_msg_count          => l_msg_count,
                x_msg_data           => l_msg_data
              );

          IF l_debug_on THEN
             WSH_DEBUG_SV.log(l_module_name,'Inv_Move_Order_Pub.Create_Move_Order_Header l_return_status',l_return_status);
             WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
          END IF;

          IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR)
          OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) THEN --{

              WSH_UTIL_CORE.PrintMsg('Error occurred in Inv_Move_Order_Pub.Create_Move_Order_Header');
              FOR i in 1..l_msg_count LOOP
                  l_message := fnd_msg_pub.get(i,'F');
                  l_message := replace(l_message,chr(0),' ');
                  WSH_UTIL_CORE.PrintMsg(l_message);
              END LOOP;
              fnd_msg_pub.delete_msg();
              RAISE e_return;
          --}
          ELSIF (l_return_status = WSH_UTIL_CORE.G_RET_STS_SUCCESS) THEN
              IF l_debug_on THEN
                 WSH_DEBUG_SV.logmsg(l_module_name,  'Created MO Header '||TO_CHAR(L_TROHDR_REC.HEADER_ID)||' Sucessfully'  );
              END IF;
          END IF;

          -- 90.8 Data should be committed only in case of a concurrent request.
          --      Data should not be commited if its ONLINE/From PUBLIC API.
          --      In case of Online data is committed from Pick Release form.
          IF ( G_CONC_REQ = FND_API.G_TRUE ) THEN
	       IF NOT(WSH_UTIL_CORE.G_CALL_FTE_LOAD_TENDER_API) THEN
		  IF l_debug_on THEN
		     WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_UTIL_CORE.Process_stops_for_load_tender',WSH_DEBUG_SV.C_PROC_LEVEL);
		  END IF;
		  WSH_UTIL_CORE.Process_stops_for_load_tender ( p_reset_flags   => FALSE,
						                x_return_status => l_return_status);

		  IF l_debug_on THEN
		     WSH_DEBUG_SV.log(l_module_name,'l_return_status',l_return_status);
		  END IF;
                  IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) OR
                     (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR) THEN
                      WSH_UTIL_CORE.PrintMsg('Error occurred in WSH_UTIL_CORE.Process_stops_for_load_tender');
                      RAISE e_return;
                  ELSIF l_return_status = WSH_UTIL_CORE.G_RET_STS_WARNING THEN
                      IF l_completion_status = 'NORMAL' THEN
                         l_completion_status := 'WARNING';
                      END IF;
                  END IF;
	       END IF;
               IF l_debug_on THEN
                  WSH_DEBUG_SV.logmsg(l_module_name,  'Commiting...');
               END IF;
               COMMIT; -- commit for move order header creation
          END IF;

          -- 90.9 For WMS org with auto pick confirm as 'N', insert 'WMS' rec type in worker table
          IF l_org_info.wms_org = 'Y' AND l_org_info.auto_pick_confirm = 'N' THEN --{
             BEGIN
               INSERT INTO WSH_PR_WORKERS (
                 BATCH_ID,
                 TYPE,
                 MO_HEADER_ID,
                 ORGANIZATION_ID,
                 PROCESSED)
               VALUES (
                 p_batch_id,
                 'WMS',
                 l_trohdr_rec.header_id,
                 l_organization_id,
                 'N');

             EXCEPTION
               WHEN OTHERS THEN
                 WSH_UTIL_CORE.PrintMsg('Error occurred in trying to insert WMS rec type in worker table');
                 RAISE e_return;
             END;
          END IF; --}

          -- 90.10 Depending on number of workers call either insert 1 record in
          --       worker table or call init_cursor api to insert worker records
          -- Bug 5247554: Changed NVL(p_num_workers,1) to NVL(g_num_workers,1) in the below IF.
            IF NVL(g_num_workers,1) <= 1 THEN --{
               BEGIN
                 INSERT INTO WSH_PR_WORKERS (
                   BATCH_ID,
                   TYPE,
                   MO_HEADER_ID,
                   MO_START_LINE_NUMBER,
                   ORGANIZATION_ID,
                   PROCESSED)
                 VALUES (
                   p_batch_id,
                   'PICK',
                   l_trohdr_rec.header_id,
                   1, -- initialize to 1 for move order line number
                   l_organization_id,
                   'N');

                 l_tot_worker_records := l_tot_worker_records + 1;
                 l_tot_smc_records    := 0;

               EXCEPTION

                 WHEN OTHERS THEN
                   WSH_UTIL_CORE.PrintMsg('Error occurred in trying to insert PICK rec type in worker table');
                   RAISE e_return;
               END; --}

            ELSE --{

               IF l_debug_on THEN
                  WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_PR_CRITERIA.Init_Cursor',
                                                    WSH_DEBUG_SV.C_PROC_LEVEL);
                  WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
               END IF;

               WSH_PR_CRITERIA.Init_Cursor(
                 p_organization_id          => l_organization_id,
                 p_mode                     => 'SUMMARY', -- insert in worker table
                 p_wms_org                  => l_org_info.wms_org,
                 p_mo_header_id             => l_trohdr_rec.header_id,
                 p_inv_item_id              => NULL,
                 p_enforce_ship_set_and_smc => l_org_info.enforce_ship_set_and_smc,
                 p_print_flag               => l_print_cursor_flag,
                 p_express_pick             => l_org_info.express_pick_flag,
                 p_batch_id		    => p_batch_id,
                 x_worker_count             => l_worker_records,
                 x_smc_worker_count         => l_smc_records,
                 x_dd_count                 => l_dd_records,
	         x_api_status               => l_return_status);

               IF l_debug_on THEN
	    	  WSH_DEBUG_SV.log(l_module_name, 'WSH_PR_CRITERIA.Init_Cursor l_return_status',l_return_status);
                  WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
               END IF;

               IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR)
                  OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) THEN
                  WSH_UTIL_CORE.PrintMsg('Error occurred in WSH_PR_CRITERIA.Init_Cursor');
                  RAISE e_return;
               END IF;

               l_tot_worker_records := l_tot_worker_records + NVL(l_worker_records,0);
               l_tot_smc_records    := l_tot_smc_records + NVL(l_smc_records,0);
               l_tot_dd_records     := l_tot_dd_records + l_dd_records;

            END IF; --}

          -- 90.11 Insert DOC rec type in worker table
            BEGIN --{
              INSERT INTO WSH_PR_WORKERS (
                BATCH_ID,
                TYPE,
                MO_HEADER_ID,
                ORGANIZATION_ID,
                DETAILED_COUNT,
                PROCESSED)
              VALUES (
                p_batch_id,
                'DOC',
                l_trohdr_rec.header_id,
                l_organization_id,
                0,
                'N');

            EXCEPTION
              WHEN OTHERS THEN
                WSH_UTIL_CORE.PrintMsg('Error occurred in trying to insert DOC rec type in worker table');
                RAISE e_return;
            END; --}

      END IF; -- l_mode is null --}

      -- 940/945 disallow picking of TPW org
      <<next_organization>>
      NULL;

  END LOOP; -- end of Organization Loop }

  -- For 'PICK-SS' request data, get the number of worker records again
  -- so that it can be processed for p_mode as 'PICK'
  IF NVL(l_mode,'X') = 'PICK-SS' THEN --{
     OPEN  c_tot_worker_records(p_batch_id);
     FETCH c_tot_worker_records INTO l_tot_worker_records;
     IF    c_tot_worker_records%NOTFOUND THEN
           l_tot_worker_records := 0;
     END IF;
     CLOSE c_tot_worker_records;

     -- Since PICK-SS spawned workers, then set Pick Slip Mode as Parallel
     G_PICK_REL_PARALLEL := TRUE;
  END IF; --}

  -- Print log messages only if request is not resuming from Regular Pick or Pack/Ship Mode
  IF NVL(l_mode,'X') NOT IN ('PICK', 'PS') THEN --{
     IF l_debug_on THEN
        WSH_DEBUG_SV.log(l_module_name,'l_tot_worker_records ',l_tot_worker_records);
        WSH_DEBUG_SV.log(l_module_name,'l_tot_smc_records ',l_tot_smc_records);
        WSH_DEBUG_SV.log(l_module_name,'l_tot_dd_records ',l_tot_dd_records);
        WSH_DEBUG_SV.log(l_module_name,'Run Ship Sets / SMCs in Parallel ',WSH_CUSTOM_PUB.Run_PR_SMC_SS_Parallel);
     END IF;
  END IF; --}

  -- 100. Calculate Actual number of worker requests to be spawned
  -- For SMCs/Ship Sets not running in Parallel
  IF (l_mode is NULL) AND (l_tot_smc_records >= 1) AND (WSH_CUSTOM_PUB.Run_PR_SMC_SS_Parallel = 'N')
  THEN --{
     -- Number of Child processes
     l_num_workers := LEAST(l_tot_smc_records, NVL(g_num_workers,1));

     IF l_num_workers > 1 THEN --{
        IF l_debug_on THEN
           WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit Spawn_Workers for PICK-SS', WSH_DEBUG_SV.C_PROC_LEVEL);
        END IF;
        Spawn_Workers (
                        p_batch_id      => p_batch_id,
                        p_num_requests  => l_num_workers,
                        p_mode          => 'PICK-SS',
                        p_req_status    => 0, -- First time Request Status is success (0)
                        p_log_level     => p_log_level,
                        x_return_status => l_return_status );
        IF l_debug_on THEN
           WSH_DEBUG_SV.log(l_module_name, 'Spawn_Workers l_return_status',l_return_status);
        END IF;
        IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR)
        OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) THEN
            WSH_UTIL_CORE.PrintMsg('Error occurred in Spawn_Workers for PICK-SS');
            RAISE e_return;
        ELSE
            -- This is required as we do not need to process rest of the code till
            -- workers complete
            GOTO End_Release_Batch;
        END IF;
        --}
     ELSE
        -- For Single Worker Mode, call Release_Batch_Sub api directly {
        -- If there will be spawning of workers for Regular Items, then set Pick Slip Mode as Parallel
        IF LEAST(l_tot_worker_records - l_tot_smc_records, NVL(g_num_workers,1)) > 1 THEN
           G_PICK_REL_PARALLEL := TRUE;
        END IF;
        IF l_debug_on THEN
           IF G_PICK_REL_PARALLEL THEN
              WSH_DEBUG_SV.logmsg(l_module_name,'Pick Release Mode is Parallel ');
           ELSE
              WSH_DEBUG_SV.logmsg(l_module_name,'Pick Release Mode is Single Worker Mode ');
           END IF;
           WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit Release_Batch_Sub', WSH_DEBUG_SV.C_PROC_LEVEL);
        END IF;
        l_retcode := NULL;
        l_errbuf  := NULL;
        Release_Batch_Sub (
                         errbuf       => l_errbuf,
                         retcode      => l_retcode,
                         p_batch_id   => p_batch_id,
                         p_worker_id  => NULL,
                         p_mode       => 'PICK-SS',
                         p_log_level  => p_log_level );
        IF l_debug_on THEN
           WSH_DEBUG_SV.logmsg(l_module_name, 'Return from Release_Batch_Sub');
           WSH_DEBUG_SV.log(l_module_name, 'retcode',l_retcode);
           WSH_DEBUG_SV.log(l_module_name, 'errbuf',l_errbuf);
        END IF;
        IF l_retcode = 2 THEN
           WSH_UTIL_CORE.PrintMsg('Error occurred in Release_Batch_Sub');
           RAISE e_return;
        ELSIF l_retcode = 1 THEN
           G_BACKORDERED := TRUE; -- To set the request status as Warning
        ELSIF l_retcode IS NULL THEN -- Online Process
          IF G_ONLINE_PICK_RELEASE_RESULT = 'W' THEN
            G_BACKORDERED := TRUE; -- To set the request status as Warning
          ELSIF G_ONLINE_PICK_RELEASE_RESULT = 'F' THEN
            WSH_UTIL_CORE.PrintMsg('Error in Online Release_batch_sub');
            RAISE e_return;
          END IF;
        END IF;
     END IF; --}
  END IF; --}

  -- For all Regular Items and Ship Sets/SMCs in Parallel
  IF ((l_mode is NULL) OR (l_mode = 'PICK-SS')) AND (l_tot_worker_records >= 1) THEN
  --{
     IF l_mode IS NULL AND (WSH_CUSTOM_PUB.Run_PR_SMC_SS_Parallel = 'N')
     THEN
        l_tot_worker_records := l_tot_worker_records - NVL(l_tot_smc_records,0);
     END IF;

     -- Number of Child processes
     l_num_workers := LEAST(l_tot_worker_records, NVL(g_num_workers,1));

     IF l_num_workers > 1 THEN --{
        -- 100.2 Spawn requests for all Items
        IF l_debug_on THEN
           WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit Spawn_Workers for PICK', WSH_DEBUG_SV.C_PROC_LEVEL);
        END IF;
        Spawn_Workers (
                        p_batch_id      => p_batch_id,
                        p_num_requests  => l_num_workers,
                        p_mode          => 'PICK',
                        p_req_status    => NVL(l_retcode,0), -- Current Request Status
                        p_log_level     => p_log_level,
                        x_return_status => l_return_status );
        IF l_debug_on THEN
           WSH_DEBUG_SV.log(l_module_name, 'Spawn_Workers l_return_status',l_return_status);
        END IF;
        IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR)
        OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) THEN
            WSH_UTIL_CORE.PrintMsg('Error occurred in Spawn_Workers for PICK');
            RAISE e_return;
        ELSE
            -- This is required as we do not need to process rest of the code till
            -- workers complete
            GOTO End_Release_Batch;
        END IF;
      --}
      ELSIF l_num_workers = 1 THEN
        -- For Single Worker Mode, call Release_Batch_Sub api directly {
        IF l_debug_on THEN
           IF G_PICK_REL_PARALLEL THEN
              WSH_DEBUG_SV.logmsg(l_module_name,'Pick Release Mode is Parallel ');
           ELSE
              WSH_DEBUG_SV.logmsg(l_module_name,'Pick Release Mode is Single Worker Mode ');
           END IF;
           WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit Release_Batch_Sub', WSH_DEBUG_SV.C_PROC_LEVEL);
        END IF;
        l_retcode := NULL;
        l_errbuf  := NULL;
        Release_Batch_Sub (
                         errbuf       => l_errbuf,
                         retcode      => l_retcode,
                         p_batch_id   => p_batch_id,
                         p_worker_id  => NULL,
                         p_mode       => 'PICK',
                         p_log_level  => p_log_level );
        IF l_debug_on THEN
           WSH_DEBUG_SV.logmsg(l_module_name, 'Return from Release_Batch_Sub');
           WSH_DEBUG_SV.log(l_module_name, 'retcode',l_retcode);
           WSH_DEBUG_SV.log(l_module_name, 'errbuf',l_errbuf);
        END IF;
        IF l_retcode = 2 THEN
           WSH_UTIL_CORE.PrintMsg('Error occurred in Release_Batch_Sub');
           RAISE e_return;
        ELSIF l_retcode = 1 THEN
           G_BACKORDERED := TRUE; -- To set the request status as Warning
        ELSIF l_retcode IS NULL THEN -- Online Process
          IF G_ONLINE_PICK_RELEASE_RESULT = 'W' THEN
            G_BACKORDERED := TRUE; -- To set the request status as Warning
          ELSIF G_ONLINE_PICK_RELEASE_RESULT = 'F' THEN
            WSH_UTIL_CORE.PrintMsg('Error in Online Release_batch_sub');
            RAISE e_return;
          END IF;
        END IF;
      END IF; --}
  END IF; --}

  IF (l_mode IS NULL OR l_mode IN ('PICK-SS','PICK','OPA','TTA','LABEL'))  --WMS High Vol Support, Added modes OPA, TTA and LABEL
  AND (l_completion_status <> 'ERROR') THEN --{

     --Bug 5137504 Handling if Batch size is set to value less than 1 or is aphanumeric
     BEGIN
     l_pr_batch_size := TO_NUMBER(FND_PROFILE.VALUE('WSH_PICK_RELEASE_BATCH_SIZE'));
     IF l_pr_batch_size IS NULL OR l_pr_batch_size < 1 THEN
        l_pr_batch_size := 50;
     ELSIF l_pr_batch_size > 1000 THEN
        l_pr_batch_size := 1000;
     END IF;
     l_pr_batch_size := ROUND(l_pr_batch_size);
     EXCEPTION
     WHEN value_error THEN
     l_pr_batch_size :=50;
     WHEN INVALID_NUMBER THEN
     l_pr_batch_size :=50;
     END;

     IF l_debug_on THEN
        WSH_DEBUG_SV.log(l_module_name,'l_pr_batch_size ',l_pr_batch_size);
     END IF;

     IF l_mode IN ('PICK-SS','PICK') THEN --{
        -- Unassign Backordered details from Delivery/Container
        l_detail_pfetch := 0;
        l_detail_cfetch := 0;
        l_errors    := 0;
        OPEN c_get_backordered_details(p_batch_id);
        LOOP --{
          FETCH c_get_backordered_details BULK COLLECT INTO l_backorder_rec_tbl LIMIT l_pr_batch_size;
          l_detail_cfetch := c_get_backordered_details%ROWCOUNT - l_detail_pfetch;
          EXIT WHEN (l_detail_cfetch = 0);
          IF l_debug_on THEN
             WSH_DEBUG_SV.log(l_module_name,'Number of backordered lines ',l_backorder_rec_tbl.COUNT);
             WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_USA_INV_PVT.Unassign_Backordered_Details',WSH_DEBUG_SV.C_PROC_LEVEL);
          END IF;
          WSH_USA_INV_PVT.Unassign_Backordered_Details(
                                                        p_backorder_rec_tbl => l_backorder_rec_tbl,
                                                        p_org_info_tbl      => l_org_info_tbl,
                                                        x_return_status     => l_return_status);
          IF l_debug_on THEN
             WSH_DEBUG_SV.log(l_module_name,'WSH_USA_INV_PVT.Unassign_Backordered_Details l_return_status' ,l_return_status);
          END IF;
          IF l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR THEN
             WSH_UTIL_CORE.PrintMsg('Unexpected Error occurred in WSH_USA_INV_PVT.Unassign_Backordered_Details');
             RAISE e_return;
          ELSIF l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR THEN
             l_errors := l_errors + 1;
          END IF;
          l_detail_pfetch := c_get_backordered_details%ROWCOUNT;
          IF ( G_CONC_REQ = FND_API.G_TRUE ) THEN
               IF l_debug_on THEN
                  WSH_DEBUG_SV.logmsg(l_module_name,  'Commiting...');
               END IF;
               COMMIT;
          END IF;
        END LOOP; --}
        CLOSE c_get_backordered_details;

        -- If there are any Errors encountered, stop processing immediately
        IF l_errors > 0 THEN
           WSH_UTIL_CORE.PrintMsg('Error occurred in WSH_USA_INV_PVT.Unassign_Backordered_Details');
           RAISE e_return;
        END IF;
     END IF; --}

     -- Unassign empty containers for deliveries that are unassigned during backodering
     IF g_unassigned_delivery_ids.COUNT > 0 AND (l_mode IS NULL OR l_mode IN ('PICK-SS','PICK')) THEN --WMS High Vol Support, Added AND cond
        IF l_debug_on THEN
           WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_DELIVERY_AUTOCREATE.unassign_empty_containers',WSH_DEBUG_SV.C_PROC_LEVEL);
        END IF;
        WSH_DELIVERY_AUTOCREATE.Unassign_Empty_Containers(g_unassigned_delivery_ids,l_return_status);
        IF l_debug_on THEN
           WSH_DEBUG_SV.log(l_module_name,'WSH_DELIVERY_AUTOCREATE.unassign_empty_containers l_return_status',l_return_status);
        END IF;
        IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR) THEN
            l_completion_status := 'WARNING';
        END IF;
     END IF;

     -- Autocreate Deliveries only if G_NUM_WORKERS > 1
     -- Otherwise it would have been done before Allocation in Release_Batch_Sub
     IF WSH_PICK_LIST.G_NUM_WORKERS > 1 THEN --{
      IF l_mode IS NULL OR l_mode IN ('PICK-SS','PICK') THEN --{   --WMS High Vol Support, Added IF condition
        -- Call Autocreate Deliveries for the Batch
        -- Loop thru all Organization - Details that are not assigned to any deliveries
        IF l_debug_on THEN
           WSH_DEBUG_SV.logmsg(l_module_name,  '==================='  );
           WSH_DEBUG_SV.logmsg(l_module_name,  'AUTOCREATE DELIVERY'  );
           WSH_DEBUG_SV.logmsg(l_module_name,  '==================='  );
           WSH_DEBUG_SV.logmsg(l_module_name,'Trip '||WSH_PR_CRITERIA.g_trip_id||
                                             ' Del '||WSH_PR_CRITERIA.g_delivery_id);
           WSH_DEBUG_SV.logmsg(l_module_name,'Del Pick Slip Grouping '||WSH_PR_CRITERIA.g_use_delivery_ps);
        END IF;

        FOR crec in c_batch_orgs(p_batch_id) LOOP --{

            IF l_debug_on THEN
               WSH_DEBUG_SV.logmsg(l_module_name,'Org '||crec.organization_id||' Auto Create Del Flag '
                                  ||l_org_info_tbl(crec.organization_id).autocreate_deliveries
                                  ||' Pick Slip Mode '||l_org_info_tbl(crec.organization_id).print_pick_slip_mode);
            END IF;
            -- Create deliveries only if Pick Slip Mode is 'End' and Delivery is not Part of Grouping
            -- Rule and Autocreate deliveries is Yes.
            IF l_org_info_tbl(crec.organization_id).autocreate_deliveries = 'Y'
            AND WSH_PR_CRITERIA.g_trip_id = 0 AND WSH_PR_CRITERIA.g_delivery_id = 0
            AND WSH_PR_CRITERIA.g_use_delivery_ps = 'N'
            AND l_org_info_tbl(crec.organization_id).print_pick_slip_mode = 'E' THEN --{
               l_del_details_tbl.delete;
               l_detail_pfetch := 0;
               l_detail_cfetch := 0;
               OPEN c_get_unassigned_details(p_batch_id, crec.organization_id);
               LOOP --{
                  FETCH c_get_unassigned_details BULK COLLECT INTO l_del_details_tbl LIMIT l_pr_batch_size;
                  l_detail_cfetch := c_get_unassigned_details%ROWCOUNT - l_detail_pfetch;
                  EXIT WHEN (l_detail_cfetch = 0);
                  IF l_debug_on THEN
                     WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_PICK_LIST.Autocreate_Deliveries'
                                                         ,WSH_DEBUG_SV.C_PROC_LEVEL);
                     WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
                  END IF;
                  Autocreate_Deliveries (
                                          p_append_flag       => l_org_info_tbl(crec.organization_id).append_flag,
                                          p_use_header_flag   => l_org_info_tbl(crec.organization_id).use_header_flag,
                                          p_del_details_tbl   => l_del_details_tbl,
                                          x_return_status     => l_return_status
                                        );
                  IF l_debug_on THEN
                     WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
                     WSH_DEBUG_SV.log(l_module_name,'WSH_PICK_LIST.Autocreate_Deliveries l_return_status'
                                                     ,l_return_status);
                  END IF;
                  IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR)
                  OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) THEN
                      WSH_UTIL_CORE.PrintMsg('Error occurred in WSH_PICK_LIST.Autocreate_Deliveries');
                      RAISE e_return;
                  END IF;
                  -- bug # 8915460 : When pick release is performed by specifying deliery detail id/containerDDId
                  --                 then auto create delivery can be performed only once because
                  --                 i) all details are assigned to same container(incase of containerDD as a parameter).
                  --                 ii) Single delivery detail id incase deliveydetailid as a parameter
                  EXIT WHEN (NVL(WSH_PR_CRITERIA.g_del_detail_id,0) = -2);

                  l_detail_pfetch := c_get_unassigned_details%ROWCOUNT;

               END LOOP; --}
               CLOSE c_get_unassigned_details;
            END IF; --}
        END LOOP; --}
      END IF; --}  --WMS High Vol Support
     END IF; --}

     -- Code for Carrier Selections needs to be added here ...
    IF l_mode IS NULL OR l_mode IN ('PICK-SS','PICK') THEN --{  --WMS High Vol Support, Added IF cond
     IF (p_batch_id is not null) THEN --{
        -- Check the shipping parameter for "auto select carrier", if this is
        -- on then FTE must be installed and carrier selction is requested
        i := l_org_info_tbl.FIRST;
        WHILE i IS NOT NULL LOOP --{
           IF NVL(l_org_info_tbl(i).AUTO_APPLY_ROUTING_RULES, 'N') = 'D' THEN --{
              -- Oh Yeah!! Carrier selection is a go - lets rock and roll!
              -- Call the Carrier Selection Processing Procedure with the batch id
              --
              -- make sure the table is empty
              --
              l_del_ids_tab.DELETE;
              IF l_debug_on THEN
                 WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_NEW_DELIVERY_ACTIONS.PROCESS_CARRIER_SELECTION',WSH_DEBUG_SV.C_PROC_LEVEL);
              END IF;
              WSH_NEW_DELIVERY_ACTIONS.PROCESS_CARRIER_SELECTION (
                                                                   p_delivery_id_tab => l_del_ids_tab,
                                                                   p_batch_id        => p_batch_id,
                                                                   p_form_flag       => 'N',
                                                                   p_caller          => 'WSH_PICK_RELEASE',
                                                                   p_organization_id => i, -- Organization_id
                                                                   x_return_message  => l_message,
                                                                   x_return_status   => l_return_status );
              IF (l_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS) THEN
                 IF l_debug_on THEN
                    WSH_DEBUG_SV.logmsg(l_module_name,  'ERROR OR WARNING OCCURRED WHILE PROCESSING CARRIER SELECTION ( PICK SLIP ) '  );
                 END IF;
              END IF;
              WSH_UTIL_CORE.add_message(l_return_status);
           --}
           END IF;

           -- Bug 3714834: If there are more lines to be picked than the pick release batch size
           -- we autocreate del for the first batch and then keep assigning the consequent lines.
           -- So we need to rate the delivery after all the lines have been picked, not during auto
           -- creation of delivery.
           IF l_org_info_tbl(i).auto_calc_fgt_rate_cr_del = 'Y' THEN --{
              OPEN  c_dels_in_batch (p_batch_id , i);
              FETCH c_dels_in_batch BULK COLLECT into l_rate_dels_tab;
              CLOSE c_dels_in_batch;

              IF l_rate_dels_tab.count > 0 THEN --{
                 l_in_param_rec.delivery_id_list := l_rate_dels_tab;
                 l_in_param_rec.action := 'RATE';
                 l_in_param_rec.seq_tender_flag := 'Y';

                 IF l_debug_on THEN
                    WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_FTE_INTEGRATION.Rate_Delivery',WSH_DEBUG_SV.C_PROC_LEVEL);
                 END IF;
                 WSH_FTE_INTEGRATION.Rate_Delivery (
                                                     p_api_version      => 1.0,
                                                     p_init_msg_list    => FND_API.G_FALSE,
                                                     p_commit           => FND_API.G_FALSE,
                                                     p_in_param_rec     => l_in_param_rec,
                                                     x_out_param_rec    => l_out_param_rec,
                                                     x_return_status    => l_return_status,
                                                     x_msg_count        => l_msg_count,
                                                     x_msg_data         => l_msg_data );
                 IF l_debug_on THEN
                    WSH_DEBUG_SV.log(l_module_name,'Return Status from WSH_FTE_INTEGRATION.Rate_Delivery',l_return_status);
                 END IF;
                 IF l_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS THEN --{
                    IF l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR THEN
                       WSH_UTIL_CORE.PrintMsg('Error occurred in WSH_FTE_INTEGRATION.Rate_Delivery');
                       RAISE e_return;
                    ELSE
                       j := l_out_param_rec.failed_delivery_id_list.FIRST;
                       WHILE j is not NULL LOOP
                         OPEN c_get_location(l_out_param_rec.failed_delivery_id_list(j));
                         FETCH c_get_location INTO l_excp_location_id;
                         CLOSE c_get_location;
                         FND_MESSAGE.SET_NAME('WSH', 'WSH_RATE_CREATE_DEL');
                         FND_MESSAGE.SET_TOKEN('DELIVERY_ID',to_char(l_out_param_rec.failed_delivery_id_list(j)));
                         l_message := FND_MESSAGE.Get;
                         l_dummy_exception_id := NULL;
                         wsh_xc_util.log_exception(
                            p_api_version           => 1.0,
                            x_return_status         => l_return_status,
                            x_msg_count             => l_exception_msg_count,
                            x_msg_data              => l_exception_msg_data,
                            x_exception_id          => l_dummy_exception_id,
                            p_exception_location_id => l_excp_location_id,
                            p_logged_at_location_id => l_excp_location_id,
                            p_logging_entity        => 'SHIPPER',
                            p_logging_entity_id     => FND_GLOBAL.USER_ID,
                            p_exception_name        => 'WSH_RATE_CREATE_DEL',
                            p_message               => substrb(l_message,1,2000),
                            p_delivery_id           => l_out_param_rec.failed_delivery_id_list(j),
                            p_batch_id              => p_batch_id,
                            p_request_id            => fnd_global.conc_request_id );
                         j := l_out_param_rec.failed_delivery_id_list.NEXT(j);
                       END LOOP;
                    END IF;
                 END IF; --}
              END IF; --}
           END IF; --}
           i := l_org_info_tbl.NEXT(i);
        END LOOP; --}
       END IF; --}  --WMS High Vol Support
     END IF; --}

     -- Delivery Merge For Pre-existing / Appended Deliveries
     IF g_assigned_del_tbl.COUNT > 0 AND (l_mode IS NULL OR l_mode IN ('PICK-SS','PICK')) THEN --{ --WMS High Vol Support, Added AND cond
        IF l_debug_on THEN
           WSH_DEBUG_SV.log(l_module_name,'g_assigned_del_tbl.COUNT', g_assigned_del_tbl.COUNT);
           WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_NEW_DELIVERY_ACTIONS.Adjust_Planned_Flag',WSH_DEBUG_SV.C_PROC_LEVEL);
        END IF;
        WSH_NEW_DELIVERY_ACTIONS.Adjust_Planned_Flag (
                                                       p_delivery_ids          => g_assigned_del_tbl,
                                                       p_caller                => 'WSH_DLMG',
                                                       p_force_appending_limit => 'N',
                                                       p_call_lcss             => 'Y',
                                                       x_return_status         => l_return_status );
        IF l_debug_on THEN
           WSH_DEBUG_SV.log(l_module_name,'Adjust_Planned_Flag returns ',l_return_status);
        END IF;
        IF l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR
        OR l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR THEN
           WSH_UTIL_CORE.PrintMsg('Error occurred in WSH_NEW_DELIVERY_ACTIONS.Adjust_Planned_Flag');
           RAISE e_Return;
        END IF;
     END IF; --}

     -- Get all New Deliveries for Delivery Merge
    IF l_mode IS NULL OR l_mode IN ('PICK-SS','PICK') THEN --{  --WMS High Vol Support, Added IF cond
     l_detail_cfetch := 0;
     l_detail_pfetch := 0;
     OPEN c_batch_unplanned_del(p_batch_id); --{
     LOOP
        FETCH c_batch_unplanned_del BULK COLLECT INTO l_delivery_ids LIMIT l_pr_batch_size;
        l_detail_cfetch := c_batch_unplanned_del%ROWCOUNT - l_detail_pfetch;
        EXIT WHEN (l_detail_cfetch = 0);
        IF l_debug_on THEN
           WSH_DEBUG_SV.log(l_module_name,'l_delivery_ids.COUNT', l_delivery_ids.COUNT);
           WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_NEW_DELIVERY_ACTIONS.Adjust_Planned_Flag',WSH_DEBUG_SV.C_PROC_LEVEL);
        END IF;
        WSH_NEW_DELIVERY_ACTIONS.Adjust_Planned_Flag (
                                                        p_delivery_ids          => l_delivery_ids,
                                                        p_caller                => 'WSH_DLMG',
                                                        p_force_appending_limit => 'N',
                                                        p_call_lcss             => 'Y',
                                                        x_return_status         => l_return_status );
        IF l_debug_on THEN
           WSH_DEBUG_SV.log(l_module_name,'Adjust_Planned_Flag returns ',l_return_status);
        END IF;
        IF l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR
        OR l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR THEN
           WSH_UTIL_CORE.PrintMsg('Error occurred in WSH_NEW_DELIVERY_ACTIONS.Adjust_Planned_Flag');
           RAISE e_Return;
        END IF;
        l_detail_pfetch := c_batch_unplanned_del%ROWCOUNT;
     END LOOP; --}
    END IF; --}  --WMS High Vol Support

     IF ( G_CONC_REQ = FND_API.G_TRUE ) THEN
          IF l_debug_on THEN
             WSH_DEBUG_SV.logmsg(l_module_name,  'Commiting...');
          END IF;
          COMMIT;
     END IF;

     -- WMS Cartonization is done only if p_num_workers in Release_Batch is > 1
     IF ( WSH_PICK_LIST.G_NUM_WORKERS > 1 )
     -- X-dock
     -- Need to add check to ensure delivery detail is not X-docked
     -- either MOL is null or MOL is not null and move order type = PUTAWAY
     AND g_allocation_method IN (WSH_PICK_LIST.C_INVENTORY_ONLY,
                              WSH_PICK_LIST.C_PRIORITIZE_CROSSDOCK,
                              WSH_PICK_LIST.C_PRIORITIZE_INVENTORY) THEN
        --{
       IF l_mode IN ('PICK-SS','PICK') THEN --{  --WMS High Vol Support, Added IF cond
        FOR crec IN c_wms_orgs(p_batch_id) LOOP --{
           IF l_org_info_tbl(crec.organization_id).auto_pick_confirm = 'Y' THEN
              IF l_debug_on THEN
                 WSH_DEBUG_SV.logmsg(l_module_name,'Skipping Cartonization as Auto Pick Confirm is Yes for Org :'||crec.organization_id);
              END IF;
              GOTO SKIP_WMS_ORG;
           END IF;
           l_del_details_tbl.delete;
           l_mo_lines_tbl.delete;
           l_carton_grouping_tbl.delete;
           -- X-dock changes to only select Rel. to warehouse lines from Inventory
           OPEN c_wms_details(p_batch_id, crec.organization_id, crec.mo_header_id);
           --LOOP --{   --WMS High Vol Support, Commented
              FETCH c_wms_details BULK COLLECT INTO l_del_details_tbl, l_mo_lines_tbl;  --LIMIT l_pr_batch_size;   --WMS High Vol Support, Removed LIMIT
              --l_detail_cfetch := c_wms_details%ROWCOUNT - l_detail_pfetch;  --WMS High Vol Support, Commented
              --EXIT WHEN (l_detail_cfetch = 0);  --WMS High Vol Support, Commented
              CLOSE c_wms_details;  --WMS High Vol Support
              -- Generate Carton Grouping Ids
              l_attr_tab.delete;
              FOR i in 1.. l_del_details_tbl.COUNT LOOP
                  l_attr_tab(i).entity_id   := l_del_details_tbl(i);
                  l_attr_tab(i).entity_type := 'DELIVERY_DETAIL';
              END LOOP;
              l_action_rec.action := 'MATCH_GROUPS';
	      l_action_rec.group_by_header_flag := l_org_info_tbl(crec.organization_id).use_header_flag ; --bug 8623544

              IF l_debug_on THEN
                 WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_DELIVERY_AUTOCREATE.Find_Matching_Groups'
                                                      ,WSH_DEBUG_SV.C_PROC_LEVEL);
                 WSH_DEBUG_SV.log(l_module_name,'l_attr_tab.COUNT ',l_attr_tab.COUNT);
                 WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
              END IF;
              WSH_DELIVERY_AUTOCREATE.Find_Matching_Groups (
                                                              p_attr_tab         => l_attr_tab,
                                                              p_action_rec       => l_action_rec,
                                                              p_target_rec       => l_target_rec,
                                                              p_group_tab        => l_group_tab,
                                                              x_matched_entities => l_matched_entities,
                                                              x_out_rec          => l_out_rec,
                                                              x_return_status    => l_return_status );
              IF l_debug_on THEN
                 WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
                 WSH_DEBUG_SV.log(l_module_name,'WSH_DELIVERY_AUTOCREATE.Find_Matching_Groups l_return_status'
                                               ,l_return_status);
              END IF;
              IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR)
              OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) THEN
                  WSH_UTIL_CORE.PrintMsg('Error occurred in WSH_DELIVERY_AUTOCREATE.Find_Matching_Groups');
                  RAISE e_return;
              END IF;

             --bug 7171766
              l_group_match_seq_tbl.delete;

              FOR i in 1.. l_attr_tab.count LOOP
              --{
                  l_match_found :=FALSE;
                  IF l_group_match_seq_tbl.count > 0 THEN
                  --{
                      FOR k in l_group_match_seq_tbl.FIRST..l_group_match_seq_tbl.LAST LOOP
	              --{
                          IF l_attr_tab(i).group_id = l_group_match_seq_tbl(k).match_group_id THEN
                          --{
                              l_group_match_seq_tbl(i).delivery_group_id := l_group_match_seq_tbl(k).delivery_group_id ;
			      l_match_found := TRUE;
		              EXIT;
	                  --}
                          End IF;
		      --}
		      END LOOP;
	          --}
		 END IF ;

		 IF NOT l_match_found THEN
		 --{
	             l_group_match_seq_tbl(i).match_group_id :=l_attr_tab(i).group_id;
	             select WSH_DELIVERY_GROUP_S.nextval into l_group_match_seq_tbl(i).delivery_group_id  from dual;
                 --}
	         End IF;

	         l_carton_grouping_tbl(l_carton_grouping_tbl.COUNT+1) := l_group_match_seq_tbl(i).delivery_group_id;
              --}
	      END LOOP;
             --bug 7171766 till here

              IF l_debug_on THEN
                 WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit INV_MOVE_ORDER_PUB.Stamp_Cart_Id'
                                                      ,WSH_DEBUG_SV.C_PROC_LEVEL);
                 WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
              END IF;
              INV_MOVE_ORDER_PUB.Stamp_Cart_Id (
                                                 p_validation_level    => FND_API.G_VALID_LEVEL_FULL,
                                                 p_carton_grouping_tbl => l_carton_grouping_tbl,
                                                 p_move_order_line_tbl => l_mo_lines_tbl );
              IF l_debug_on THEN
                 WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
                 WSH_DEBUG_SV.logmsg(l_module_name,'Return from program unit INV_MOVE_ORDER_PUB.Stamp_Cart_Id');
              END IF;

           <<SKIP_WMS_ORG>>
           NULL;

        END LOOP; --}
     END IF; --}

     --WMS High Vol Support Starts
     IF l_mode IN ('PICK-SS','PICK','OPA','TTA','LABEL') THEN --{
           LOOP --{
              OPEN c_wms_orgs(p_batch_id);
              FETCH c_wms_orgs INTO v_wms_org_rec;
              EXIT WHEN c_wms_orgs%NOTFOUND;
              CLOSE c_wms_orgs;

              l_org_complete := 'Y';
              IF l_org_info_tbl(v_wms_org_rec.organization_id).auto_pick_confirm = 'Y' THEN
                 IF l_debug_on THEN
                    WSH_DEBUG_SV.logmsg(l_module_name,'Skipping Find_Matching_Groups as Auto Pick Confirm is Yes for Org :'||v_wms_org_rec.organization_id);
                 END IF;
                 GOTO SKIP_WMS_POSTALLOC;
              END IF;

              -- Call to WMS Cartonize API
              IF l_debug_on THEN
                 WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WMS_POST_ALLOCATION.launch'
                                    ,WSH_DEBUG_SV.C_PROC_LEVEL);
                 WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
              END IF;
              WMS_POST_ALLOCATION.launch (
                               p_organization_id      => v_wms_org_rec.organization_id,
                               p_mo_header_id         => v_wms_org_rec.mo_header_id,
                               p_batch_id             => p_batch_id,
                               p_num_workers          => WSH_PICK_LIST.G_NUM_WORKERS,
                               p_auto_pick_confirm    => l_org_info_tbl(v_wms_org_rec.organization_id).auto_pick_confirm,
                               p_wsh_status           => NVL(l_retcode,0), -- Current Request Status
                               p_wsh_mode             => l_mode,
                               p_grouping_rule_id     => l_org_info_tbl(v_wms_org_rec.organization_id).pick_grouping_rule_id,
                               p_allow_partial_pick   => FND_API.G_TRUE,
                               p_plan_tasks           => l_org_info_tbl(l_organization_id).task_planning_flag,
                               x_return_status        => l_return_status,
                               x_org_complete         => l_org_complete);
              IF l_debug_on THEN
                 WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
                 WSH_DEBUG_SV.log(l_module_name,'Return status from WMS_POST_ALLOCATION.launch ', l_return_status);
              END IF;
              IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR)
              OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) THEN
                  WSH_UTIL_CORE.PrintMsg('Error occurred in WMS_POST_ALLOCATION.launch');
                  RAISE e_return;
              END IF;

              <<SKIP_WMS_POSTALLOC>>
              IF NVL(l_org_complete,'Y') = 'Y' THEN
                 UPDATE wsh_pr_workers
                    SET processed = 'Y'
                  WHERE batch_id = p_batch_id
                    AND organization_id = v_wms_org_rec.organization_id
                    AND type = 'WMS';

		 l_mode := 'PICK'; --WMS High Vol Support
                 COMMIT;
              ELSE
                 -- WMS post-allocation API spawned child requests, so the parent request
                 -- is being PAUSED.
                 GOTO End_Release_Batch;
              END IF;
           END LOOP; --}
           IF c_wms_orgs%ISOPEN THEN
              CLOSE c_wms_orgs;
           END IF;
           -- Restore mode after all WMS post-allocation processing is completed
           IF l_mode IN ('OPA','TTA','LABEL') THEN
              l_mode := 'PICK';
           END IF;
        END IF; --}
     END IF; --}
     --WMS High Vol Support Ends

     -- Print Pick Slips / Pick Release Document Set
     FOR crec in c_sum_worker(p_batch_id) LOOP --{
        IF l_debug_on THEN
           WSH_DEBUG_SV.logmsg(l_module_name,'Printing Documents for Organization '||crec.organization_id);
           WSH_DEBUG_SV.logmsg(l_module_name,  'TOTAL DETAILED COUNT IS '||crec.tot_detailed);
           WSH_DEBUG_SV.logmsg(l_module_name,  'Seeded Pick Slip Document Set '||WSH_PICK_LIST.G_SEED_DOC_SET);
           WSH_DEBUG_SV.logmsg(l_module_name,  'Pick Release Document Set '||l_org_info_tbl(crec.organization_id).doc_set_id);
        END IF;
        l_print_ps := 'N';
        IF crec.tot_detailed > 0 AND WSH_PICK_LIST.G_SEED_DOC_SET IS NOT NULL AND
           l_org_info_tbl(crec.organization_id).express_pick_flag = 'N' AND
           l_org_info_tbl(crec.organization_id).autodetail_flag = 'Y' THEN
               l_print_ps := 'Y';
        END IF;
        IF (l_print_ps = 'Y') OR (l_org_info_tbl(crec.organization_id).doc_set_id <> -1) THEN
           IF l_debug_on THEN
              WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_PICK_LIST.Print_Docs'
                                               ,WSH_DEBUG_SV.C_PROC_LEVEL);
           END IF;
           Print_docs (
                        p_batch_id         => p_batch_id,
                        p_organization_id  => crec.organization_id,
                        p_print_ps         => l_print_ps,
                        p_ps_mode          => l_org_info_tbl(crec.organization_id).print_pick_slip_mode,
                        p_doc_set_id       => l_org_info_tbl(crec.organization_id).doc_set_id,
                        p_batch_name       => l_batch_name,
                        p_order_number     => NULL, -- this will be derived in Print_Docs API itself
                        x_return_status    => l_return_status );
           IF l_return_status in (WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR, WSH_UTIL_CORE.G_RET_STS_ERROR) THEN
             l_completion_status := 'WARNING';
           END IF;
        END IF;
        -- No records detailed, so delete Move Order Header for Organization
        IF crec.tot_detailed = 0 THEN --{
           IF l_debug_on THEN
              WSH_DEBUG_SV.logmsg(l_module_name,  'NO LINES SELECTED FOR ORG ' ||TO_CHAR(crec.organization_id));
              WSH_DEBUG_SV.logmsg(l_module_name,  'DELETE MOVE ORDER HEADER'  );
           END IF;
           -- Clear move order header/line records
           l_trohdr_rec := l_empty_trohdr_rec;
           l_trohdr_val_rec := l_empty_trohdr_val_rec;
           l_trohdr_rec.header_id := crec.mo_header_id;
           l_trohdr_rec.operation := INV_GLOBALS.G_OPR_DELETE;
           l_trolin_tbl.delete;
           l_trolin_val_tbl.delete;
           IF l_debug_on THEN
              WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit INV_MOVE_ORDER_PUB.PROCESS_MOVE_ORDER'
                                               ,WSH_DEBUG_SV.C_PROC_LEVEL);
           END IF;
           Inv_Move_Order_Pub.Process_Move_Order (
                                                   p_api_version_number => l_api_version_number,
                                                   p_init_msg_list      => FND_API.G_FALSE,
                                                   p_return_values      => FND_API.G_TRUE,
                                                   p_commit             => l_commit,
                                                   p_trohdr_rec         => l_trohdr_rec,
                                                   x_trohdr_rec         => l_trohdr_rec,
                                                   x_trohdr_val_rec     => l_trohdr_val_rec,
                                                   x_trolin_tbl         => l_trolin_tbl,
                                                   x_trolin_val_tbl     => l_trolin_val_tbl,
                                                   x_return_status      => l_return_status,
                                                   x_msg_count          => l_msg_count,
                                                   x_msg_data           => l_msg_data );
           IF l_debug_on THEN
              WSH_DEBUG_SV.log(l_module_name,'Inv_Move_Order_Pub.Process_Move_Order l_return_status'
                                            ,l_return_status);
           END IF;
           IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR)
           OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) THEN
               WSH_UTIL_CORE.PrintMsg('Error occurred in Inv_Move_Order_Pub.Process_Move_Order');
               FOR i in 1..l_msg_count LOOP
                   l_message := fnd_msg_pub.get(i,'F');
                   l_message := replace(l_message,chr(0),' ');
                   WSH_UTIL_CORE.PrintMsg(l_message);
                END LOOP;
                fnd_msg_pub.delete_msg();
                RAISE e_return;
           END IF;
        END IF; --}
     END LOOP; --}

     -- Delete empty deliveries
     IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_DELIVERY_AUTOCREATE.Delete_Empty_Deliveries' ,WSH_DEBUG_SV.C_PROC_LEVEL);
     END IF;
     WSH_DELIVERY_AUTOCREATE.Delete_Empty_Deliveries(g_batch_id,l_return_status);
     IF l_debug_on THEN
        WSH_DEBUG_SV.log(l_module_name,'WSH_DELIVERY_AUTOCREATE.Delete_Empty_Deliveries l_return_status',l_return_status);
     END IF;
     IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR) THEN
         l_completion_status := 'WARNING';
     END IF;

     -- Reset delivery batch id.
     UPDATE wsh_new_deliveries
     SET    batch_id = NULL
     WHERE  batch_id = g_batch_id;

     --Bug 3433645 :Automated Shipping Failing for Order with Huge Delivery Lines
     --Batch ID set to NULL for all the children of Containers that did not get Pick Released.

     --bug# 6689448 (replenishment project):  should not update batch_id value on the replenishment
     -- requested delivery detail lines.
     UPDATE wsh_delivery_details
     SET    batch_id = NULL
     WHERE  batch_id = g_batch_id
     AND    ( (released_status in ('R','X'))
               OR ( released_status = 'B' and nvl(REPLENISHMENT_STATUS,'C') <> 'R') );

     --bug# 6689448 (replenishment project): begin
     -- At the end of the pick release process, submit 'Dynamic Replenishment' concurrent
     -- request for each WMS org where atleast one detail is in replenishment requested status.
     FOR crec IN get_replenish_orgs(g_batch_id) LOOP
     --{
         IF l_debug_on THEN
             WSH_DEBUG_SV.log(l_module_name,'Submitting dynamic replenishment conc. request for the org: ',crec.organization_id);
         END IF;
         l_request_id := FND_REQUEST.Submit_Request(
                                                      application => 'WMS',
                                                      program     => 'WMSDYREPL',
                                                      description => '',
                                                      start_time  => '',
                                                      argument1   => g_batch_id,   -- pick release batch_id
                                                      argument2   => crec.organization_id,
                                                      argument3   => l_org_info_tbl(crec.organization_id).task_planning_flag,-- task planning flag
                                                      argument4   => l_org_info_tbl(crec.organization_id).pick_seq_rule_id  --     pick sequence rule
                                               );
         IF l_debug_on THEN
             WSH_DEBUG_SV.log(l_module_name,'request Id: ',l_request_id);
         END IF;
     --}
     END LOOP;
     --bug# 6689448 (replenishment project): end

     G_BATCH_ID := NULL;

     IF l_mode IS NULL THEN --{
        -- Completion status to warning for error backordered.
        IF ( G_BACKORDERED ) AND l_completion_status <> 'ERROR' THEN
             l_completion_status := 'WARNING';
        END IF;

     --}
     ELSE --{
        --set the l_completion_status based on the other programs
        FND_PROFILE.Get('CONC_REQUEST_ID', l_this_request);
        OPEN  c_requests(l_this_request);
        FETCH c_requests BULK COLLECT INTO l_child_req_ids;
        CLOSE c_requests;
        l_errors   := 0;
        l_warnings := 0;
        j := l_child_req_ids.FIRST;
        WHILE j IS NOT NULL LOOP
           l_dev_status := NULL;
           l_dummy := FND_CONCURRENT.get_request_status(
                                     request_id => l_child_req_ids(j),
                                     phase      => l_phase,
                                     status     => l_status,
                                     dev_phase  => l_dev_phase,
                                     dev_status => l_dev_status,
                                     message    => l_message);

           IF l_dev_status = 'WARNING' THEN
              l_warnings:= l_warnings + 1;
           ELSIF l_dev_status <> 'NORMAL' THEN
              l_errors := l_errors + 1;
           END IF;
           IF l_debug_on THEN
              WSH_DEBUG_SV.logmsg(l_module_name,'Child Request id :' ||l_child_req_ids(j)||' Status :'||l_dev_status);
           END IF;

           FND_MESSAGE.SET_NAME('WSH','WSH_CHILD_REQ_STATUS');
           FND_MESSAGE.SET_TOKEN('REQ_ID', to_char(l_child_req_ids(j)));
           FND_MESSAGE.SET_TOKEN('STATUS', l_status);
           WSH_UTIL_CORE.PrintMsg(FND_MESSAGE.GET);
           j := l_child_req_ids.NEXT(j);
        END LOOP;

        IF ( G_BACKORDERED ) THEN
             l_warnings:= l_warnings + 1;
        END IF;

        IF l_errors = 0  AND l_warnings = 0 THEN
           l_completion_status := 'NORMAL';
        ELSIF (l_errors > 0 ) THEN
           l_completion_status := 'ERROR';
        ELSE
           l_completion_status := 'WARNING';
        END IF;
     END IF; --}

     WSH_UTIL_CORE.PrintMsg('Pick selection is completed');

     -- Set Online Pick Release Result
     -- Warning Mesg. for Online
     IF (l_completion_status = 'WARNING') THEN
         G_ONLINE_PICK_RELEASE_RESULT := 'W';
     ELSE
         G_ONLINE_PICK_RELEASE_RESULT := 'S';
         G_ONLINE_PICK_RELEASE_PHASE := 'SUCCESS';
     END IF;

     IF G_CONC_REQ = FND_API.G_TRUE THEN
        IF l_completion_status = 'NORMAL' THEN
           errbuf := 'Pick selection completed successfully';
        ELSIF l_completion_status = 'WARNING' THEN
           errbuf := 'Pick selection is completed with warning';
        ELSE
           errbuf := 'Pick selection is completed with error';
        END IF;
     END IF;

     IF l_debug_on THEN
        WSH_DEBUG_SV.log(l_module_name,'l_completion_status',l_completion_status);
     END IF;

     IF ( G_CONC_REQ = FND_API.G_TRUE ) THEN
          IF l_debug_on THEN
             WSH_DEBUG_SV.logmsg(l_module_name,  'Commiting...');
          END IF;
          COMMIT;
     END IF;

  END IF; --}

  -- If pick released successfully see if we want to autopack/shipconfirm
  IF ((G_CONC_REQ = FND_API.G_TRUE AND l_completion_status <> 'ERROR') OR
       G_ONLINE_PICK_RELEASE_RESULT IN ('S', 'W'))
  AND (WSH_PR_CRITERIA.g_autopack_flag = 'Y' OR WSH_PR_CRITERIA.g_non_picking_flag in  ('P', 'S') OR
       WSH_PR_CRITERIA.g_auto_ship_confirm_rule_id IS NOT NULL)
  AND (l_mode IS NULL OR l_mode IN ('PICK-SS','PICK')) THEN
  --{
     IF l_debug_on THEN
        WSH_DEBUG_SV.log(l_module_name,'NON PICKFLAG',WSH_PR_CRITERIA.g_non_picking_flag);
     END IF;
     -- this is from Pick Release Form, hence only 1 record
     IF WSH_PR_CRITERIA.g_non_picking_flag IS NULL THEN
        l_ap_level    := WSH_PR_CRITERIA.g_autopack_level;
        l_ap_flag     := WSH_PR_CRITERIA.g_autopack_flag;
        l_sc_rule_id  := WSH_PR_CRITERIA.g_auto_ship_confirm_rule_id;
        IF l_debug_on THEN
           WSH_DEBUG_SV.log(l_module_name,'L_AP_LEVEL', l_ap_level);
           WSH_DEBUG_SV.log(l_module_name,'L_AP_FLAG', l_ap_flag);
           WSH_DEBUG_SV.log(l_module_name,'L_SC_RULE', l_sc_rule_id);
        END IF;
     END IF;

     IF WSH_PR_CRITERIA.g_non_picking_flag in  ('P', 'S') THEN
     --{
        -- see if PR batch created for Pick, (Pack,) and Ship through STF
        -- if yes, group into batches by SC Rules, AP level
        l_grp_count := 0;
        OPEN get_pack_ship_groups(p_batch_id);
        LOOP
          l_grp_count := l_grp_count + 1;
          FETCH get_pack_ship_groups into l_group_details_rec_tab(l_grp_count);
          EXIT WHEN get_pack_ship_groups%NOTFOUND;
        END LOOP;
        CLOSE get_pack_ship_groups;

        l_group_nums := l_group_details_rec_tab.count;

        IF l_debug_on THEN
           WSH_DEBUG_SV.log(l_module_name,'l_group_nums', l_group_nums);
        END IF;

        IF l_group_nums = 1 THEN
        --{
           -- if only one group, no need to create child batches.
           -- we can pack/ship this group using the same PR batch.
           l_ap_level    := l_group_details_rec_tab(l_group_details_rec_tab.FIRST).autopack_level;
           l_sc_rule_id  := l_group_details_rec_tab(l_group_details_rec_tab.FIRST).ship_confirm_rule_id;
           IF NVL(l_ap_level, 0) > 0 THEN
              l_ap_flag  :=  'Y';
           END IF;
           IF l_debug_on THEN
              WSH_DEBUG_SV.log(l_module_name,'l_ap_level', l_ap_level);
           END IF;
        --}
        ELSIF (l_group_nums > 1) THEN
        --{
           IF l_debug_on THEN
              WSH_DEBUG_SV.log(l_module_name,'l_group_nums > 1',l_group_nums);
           END IF;
           -- loop through each group creating child batch.
           -- and then pack/ship it.
           FOR i in l_group_details_rec_tab.FIRST..l_group_details_rec_tab.LAST LOOP
           --{
               l_ap_level := l_group_details_rec_tab(i).autopack_level;
               l_sc_rule_id  := l_group_details_rec_tab(i).ship_confirm_rule_id;
               IF NVL(l_ap_level, 0) > 0 THEN
                  l_ap_flag :=  'Y';
               END IF;
               IF l_debug_on THEN
                  WSH_DEBUG_SV.log(l_module_name,'ELSE l_ap_level', l_ap_level);
               END IF;
               l_del_count := 1;
               OPEN get_dels_in_group(p_batch_id, l_sc_rule_id, l_ap_level);
               LOOP
                 -- group all the deliveries that go into a child batch
                 -- to be packed/shipped together.
                 FETCH get_dels_in_group INTO l_ps_delivery_tab(l_del_count),
                                              l_ps_org_tab(l_del_count),
                                              l_ps_pick_loc_tab(l_del_count);
                 EXIT when get_dels_in_group%NOTFOUND;
                 l_del_count := l_del_count + 1;
               END LOOP;
               IF get_dels_in_group%ISOPEN THEN
                  CLOSE get_dels_in_group;
               END IF;
               IF l_debug_on THEN
                  WSH_DEBUG_SV.log(l_module_name,'BEFORE INSERTING l_ap_level', l_ap_level);
               END IF;

               -- Autopack should be set only if Non Pick Flag as 'P' and AP Level is set
               IF WSH_PR_CRITERIA.g_non_picking_flag = 'P' AND NVL(l_ap_level,0) > 0 THEN
                  l_act_ap_level := NVL(l_ap_level,0);
               ELSIF WSH_PR_CRITERIA.g_non_picking_flag = 'P' AND NVL(l_ap_level,0) = 0 THEN
                  IF G_CONC_REQ = FND_API.G_TRUE THEN
                     WSH_UTIL_CORE.PrintMsg('** Warning : Autopack Option is No for the organization - Packing action not performed **');
                  END IF;
                  l_act_ap_level := 0;
               ELSE
                  l_act_ap_level := 0;
               END IF;
               IF l_act_ap_level = 0 THEN
                  l_act_ap_flag := 'N';
               ELSE
                  l_act_ap_flag := 'Y';
               END IF;

               -- create pack/ship batch for this group.
               l_del_batch_id := NULL;
               l_del_batch_name := NULL;

               WSH_PICKING_BATCHES_PKG.Insert_Row (
                                                    X_Rowid     => l_tmp_row_id,
                                                    X_Batch_Id   => l_del_batch_id,
                                                    P_Creation_Date   => NULL,
                                                    P_Created_By => NULL,
                                                    P_Last_Update_Date => NULL,
                                                    P_Last_Updated_By   => NULL,
                                                    P_Last_Update_Login   => NULL,
                                                    X_Name   => l_del_batch_name,
                                                    P_Backorders_Only_Flag  => NULL,
                                                    P_Document_Set_Id   => NULL,
                                                    P_Existing_Rsvs_Only_Flag => NULL,
                                                    P_Shipment_Priority_Code   => NULL,
                                                    P_Ship_Method_Code => NULL,
                                                    P_Customer_Id   => NULL,
                                                    P_Order_Header_Id   => NULL,
                                                    P_Ship_Set_Number   => NULL,
                                                    P_Inventory_Item_Id   => NULL,
                                                    P_Order_Type_Id   => NULL,
                                                    P_From_Requested_Date   => NULL,
                                                    P_To_Requested_Date   => NULL,
                                                    P_From_Scheduled_Ship_Date   => NULL,
                                                    P_To_Scheduled_Ship_Date   => NULL,
                                                    P_Ship_To_Location_Id   => NULL,
                                                    P_Ship_From_Location_Id   => NULL,
                                                    P_Trip_Id   => NULL,
                                                    P_Delivery_Id    => NULL,
                                                    P_Include_Planned_Lines   => NULL,
                                                    P_Pick_Grouping_Rule_Id   => NULL,
                                                    P_pick_sequence_rule_id   => NULL,
                                                    P_Autocreate_Delivery_Flag   => NULL,
                                                    P_Attribute_Category  => NULL,
                                                    P_Attribute1 => NULL,
                                                    P_Attribute2 => NULL,
                                                    P_Attribute3 => NULL,
                                                    P_Attribute4 => NULL,
                                                    P_Attribute5 => NULL,
                                                    P_Attribute6 => NULL,
                                                    P_Attribute7 => NULL,
                                                    P_Attribute8 => NULL,
                                                    P_Attribute9 => NULL,
                                                    P_Attribute10   => NULL,
                                                    P_Attribute11   => NULL,
                                                    P_Attribute12   => NULL,
                                                    P_Attribute13   => NULL,
                                                    P_Attribute14   => NULL,
                                                    P_Attribute15=> NULL,
                                                    P_Autodetail_Pr_Flag  => NULL,
                                                    P_Carrier_Id=> NULL,
                                                    P_Trip_Stop_Id=> NULL,
                                                    P_Default_stage_subinventory => NULL,
                                                    P_Default_stage_locator_id   => NULL,
                                                    P_Pick_from_subinventory   => NULL,
                                                    P_Pick_from_locator_id  => NULL,
                                                    P_Auto_pick_confirm_flag   => NULL,
                                                    P_Delivery_Detail_ID  => NULL,
                                                    P_Project_ID=> NULL,
                                                    P_Task_ID=> NULL,
                                                    P_Organization_Id   => NULL,
                                                    P_Ship_Confirm_Rule_Id  => l_sc_rule_id,
                                                    P_Autopack_Flag=> l_act_ap_flag,
                                                    P_Autopack_Level=> l_act_ap_level,
                                                    P_TASK_PLANNING_FLAG=> NULL,
                                                    P_Non_Picking_Flag => 'Y',
            	                                      /* Enhancement */
	                                            p_RegionID	=> NULL,
            	                                    p_ZoneID	=> NULL,
            	                                    p_categoryID	=> NULL,
                                                    p_categorySetID => NULL,
                                                    p_acDelivCriteria => NULL,
	                                            p_RelSubinventory => NULL,
            	                                      -- deliveryMerge
            	                                    p_append_flag => 'N',
                                                    p_task_priority => NULL,
                                                    p_allocation_method => NULL,
                                                    p_crossdock_criteria_id => NULL,
                                                    p_client_id             => NULL -- LSP PROJECT
                                                 );

               -- Bulk Insert
               FORALL i in 1..l_ps_delivery_tab.COUNT
                      INSERT INTO WSH_PR_WORKERS (
                                                   BATCH_ID,
                                                   TYPE,
                                                   PA_SC_BATCH_ID,
                                                   DELIVERY_ID,
                                                   ORGANIZATION_ID,
                                                   PICKUP_LOCATION_ID,
                                                   AP_LEVEL,
                                                   SC_RULE_ID,
                                                   PROCESSED
                                                 )
                                          VALUES (
                                                   p_batch_id,
                                                   'PS',
                                                   l_del_batch_id,
                                                   l_ps_delivery_tab(i),
                                                   l_ps_org_tab(i),
                                                   l_ps_pick_loc_tab(i),
                                                   l_act_ap_level,
                                                   l_sc_rule_id,
                                                   'N'
                                                 );
               l_pr_worker_rec_count := l_pr_worker_rec_count + SQL%ROWCOUNT;
           --}
           END LOOP;
        --}
        END IF;
     --}
     END IF;

     IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,'Flags: l_ap_level='||l_ap_level||', Autopack flag='||WSH_PR_CRITERIA.g_autopack_flag);
     END IF;
     -- if only one (sc rules/ap level) group for all pickreleased lines,
     -- or picking/packing/shipping through PR form or STF for deliveries,
     -- no need to spawn seperate batches. use existing PR batch.
     IF (l_group_nums = 1)  OR (WSH_PR_CRITERIA.g_auto_ship_confirm_rule_id IS NOT NULL)
     OR (WSH_PR_CRITERIA.g_autopack_flag = 'Y') THEN
     --{
        IF l_debug_on THEN
           WSH_DEBUG_SV.logmsg(l_module_name,'l_ap_level='||l_ap_level||', Autopack flag='||WSH_PR_CRITERIA.g_autopack_flag||l_group_nums);
        END IF;

        -- Autopack should be set only if Non Pick Flag as 'P' or if Pick Release Criteria has Autopack specified
        IF (WSH_PR_CRITERIA.g_autopack_flag = 'Y')
        OR (NVL(l_ap_level,0) > 0 AND WSH_PR_CRITERIA.g_non_picking_flag = 'P') THEN
            l_act_ap_level := NVL(l_ap_level,0);
        ELSIF WSH_PR_CRITERIA.g_non_picking_flag = 'P' AND NVL(l_ap_level,0) = 0 THEN
            IF G_CONC_REQ = FND_API.G_TRUE THEN
               WSH_UTIL_CORE.PrintMsg('** Warning : Autopack Option is No for the organization - Packing action not performed **');
            END IF;
            l_act_ap_level := 0;
        ELSE
            l_act_ap_level := 0;
        END IF;

        IF l_group_nums = 1 THEN
           -- if for one group of details through STF, then update
           -- PR batch to be a packing/shipping batch as well.
           UPDATE wsh_picking_batches
           SET    ship_confirm_rule_id = l_sc_rule_id,
                  autopack_flag  = DECODE(l_act_ap_level,0,'N','Y'),
                  autopack_level = l_act_ap_level
           WHERE  batch_id = p_batch_id;
        END IF;

        l_del_count := 1;
        OPEN get_dels_in_batch(p_batch_id);
        LOOP
          -- group all the deliveries for the batch to be
          -- packed/shipped together.
          FETCH get_dels_in_batch INTO l_ps_delivery_tab(l_del_count),
                                       l_ps_org_tab(l_del_count),
                                       l_ps_pick_loc_tab(l_del_count);
          EXIT WHEN get_dels_in_batch%NOTFOUND;
          l_del_count := l_del_count + 1;
        END LOOP;
        IF get_dels_in_batch%ISOPEN THEN
           CLOSE get_dels_in_batch;
        END IF;

        IF l_debug_on THEN
           WSH_DEBUG_SV.logmsg(l_module_name,'Flags again: l_ap_level='||l_ap_level||', Autopack flag='||WSH_PR_CRITERIA.g_autopack_flag||l_group_nums);
        END IF;

        -- Bulk Insert
        FORALL i in 1..l_ps_delivery_tab.COUNT
               INSERT INTO WSH_PR_WORKERS (
                                           BATCH_ID,
                                           TYPE,
                                           PA_SC_BATCH_ID,
                                           DELIVERY_ID,
                                           ORGANIZATION_ID,
                                           PICKUP_LOCATION_ID,
                                           AP_LEVEL,
                                           SC_RULE_ID,
                                           PROCESSED
                                         )
                                  VALUES (
                                           p_batch_id,
                                           'PS',
                                           p_batch_id,
                                           l_ps_delivery_tab(i),
                                           l_ps_org_tab(i),
                                           l_ps_pick_loc_tab(i),
                                           l_act_ap_level,
                                           l_sc_rule_id,
                                           'N'
                                         );
        l_pr_worker_rec_count := l_pr_worker_rec_count + SQL%ROWCOUNT;
     --}
     END IF;

     IF l_pr_worker_rec_count = 0 THEN
        IF l_debug_on THEN
           WSH_DEBUG_SV.logmsg(l_module_name,'No eligible records to Pack and Ship');
        END IF;
     ELSE
        IF l_debug_on THEN
           WSH_DEBUG_SV.logmsg(l_module_name,'Total number of eligible records to Pack and Ship : '|| l_pr_worker_rec_count);
        END IF;
     --{
        l_num_workers := LEAST(l_pr_worker_rec_count, NVL(g_num_workers,1));
        IF l_num_workers > 1 THEN
        --{
           IF l_debug_on THEN
              WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit Spawn_Workers for PS',
                                  WSH_DEBUG_SV.C_PROC_LEVEL);
           END IF;
           -- If the current status is Warning, pass the value as 1, else pass value as 0
           IF ( G_BACKORDERED ) THEN
              l_retcode := 1;
           ELSE
              l_retcode := 0;
           END IF;
           Spawn_Workers (
                           p_batch_id      => p_batch_id,
                           p_num_requests  => l_num_workers,
                           p_mode          => 'PS',
                           p_req_status    => l_retcode,
                           p_log_level     => p_log_level,
                           x_return_status => l_return_status );
           IF l_debug_on THEN
              WSH_DEBUG_SV.log(l_module_name, 'Spawn_Workers l_return_status',l_return_status);
           END IF;
           IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR)
           OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) THEN
               WSH_UTIL_CORE.PrintMsg('Error occurred in Spawn_Workers for PS');
               RAISE e_return;
           ELSE
               -- After pausing parent process, we need to skip rest of the code
               -- till all workers complete and parent process restarts
               GOTO End_Release_Batch;
           END IF;
        --}
        ELSE
        --{
           IF l_debug_on THEN
              WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit Release_Batch_Sub'
                                  , WSH_DEBUG_SV.C_PROC_LEVEL);
           END IF;
           l_retcode := NULL;
           l_errbuf  := NULL;
           Release_Batch_Sub (
                            errbuf       => l_errbuf,
                            retcode      => l_retcode,
                            p_batch_id   => p_batch_id,
                            p_worker_id  => NULL,
                            p_mode       => 'PS',
                            p_log_level  => p_log_level );
           IF l_debug_on THEN
              WSH_DEBUG_SV.logmsg(l_module_name, 'Return from Release_Batch_Sub');
              WSH_DEBUG_SV.log(l_module_name, 'retcode',l_retcode);
              WSH_DEBUG_SV.log(l_module_name, 'errbuf',l_errbuf);
           END IF;
           IF l_retcode = 2 THEN
              WSH_UTIL_CORE.PrintMsg('Error occurred in Release_Batch_Sub');
              RAISE e_return;
           ELSIF l_retcode IS NULL AND
                 G_ONLINE_PICK_RELEASE_RESULT = 'F' THEN
             WSH_UTIL_CORE.PrintMsg('Error in Online Release_batch_sub');
             RAISE e_return;
           END IF;
        --}
        END IF;
     --}
     END IF;
  --}
  END IF; -- Pack/Ship Grouping

  WSH_UTIL_CORE.PrintDateTime;

  IF ((G_CONC_REQ = FND_API.G_TRUE AND l_completion_status <> 'ERROR') OR
       G_ONLINE_PICK_RELEASE_RESULT IN ('S', 'W'))
  AND (WSH_PR_CRITERIA.g_autopack_flag = 'Y' OR WSH_PR_CRITERIA.g_non_picking_flag in  ('P', 'S') OR
       WSH_PR_CRITERIA.g_auto_ship_confirm_rule_id IS NOT NULL) THEN --{
     -- Get all Trip Stops for setting Trip to In-Transit or Closed
     --{
     l_sc_id_tab.delete;
     OPEN  c_close_trip(p_batch_id);
     LOOP
       FETCH c_close_trip INTO l_sc_id_tab(l_sc_id_tab.COUNT+1), l_batch_creation_date,
                               l_ac_close_trip_flag, l_ac_intransit_flag;
       EXIT WHEN c_close_trip%NOTFOUND;
       IF l_ac_close_trip_flag = 'Y' THEN
          OPEN get_all_stops(l_sc_id_tab(l_sc_id_tab.COUNT));
          LOOP
            FETCH get_all_stops into l_trip_id, l_stop_sequence_number, l_stop_id, l_stop_location_id ;
            EXIT WHEN get_all_stops%NOTFOUND;
            l_stops_to_close(l_stops_to_close.COUNT+1)       := l_stop_id;
            l_stop_location_ids(l_stop_location_ids.COUNT+1) := l_stop_location_id;
            l_stops_sc_ids(l_stops_sc_ids.COUNT+1)      := l_sc_id_tab(l_sc_id_tab.COUNT);
          END LOOP;
          CLOSE get_all_stops;

       ELSIF l_ac_intransit_flag = 'Y' THEN
          OPEN get_pick_up_stops(l_sc_id_tab(l_sc_id_tab.COUNT));
          LOOP
            FETCH get_pick_up_stops into l_trip_id, l_stop_sequence_number, l_stop_id, l_stop_location_id;
            EXIT WHEN get_pick_up_stops%NOTFOUND;
            l_stops_to_close(l_stops_to_close.COUNT+1)       := l_stop_id;
            l_stop_location_ids(l_stop_location_ids.COUNT+1) := l_stop_location_id;
            l_stops_sc_ids(l_stops_sc_ids.COUNT+1)      := l_sc_id_tab(l_sc_id_tab.COUNT);
          END LOOP;
          CLOSE get_pick_up_stops;
       END IF;
     END LOOP;
     CLOSE c_close_trip;
     IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,'l_stops_to_close.COUNT '||l_stops_to_close.COUNT);
     END IF;
     --}

     IF l_stops_to_close.count > 0 THEN
     --{
        IF l_debug_on THEN
           WSH_DEBUG_SV.logmsg(l_module_name, 'Closing stops');
        END IF;
        FOR i in 1..l_stops_to_close.count LOOP
        --{
           IF l_debug_on THEN
            WSH_DEBUG_SV.logmsg(l_module_name, 'Calling program unit WSH_BATCH_PROCESS.Close_A_Stop');
           END IF;
           WSH_BATCH_PROCESS.Close_A_Stop (
             p_stop_id    => l_stops_to_close(i),
             p_actual_date => NVL(WSH_PR_CRITERIA.g_actual_departure_date, SYSDATE),
             p_defer_interface_flag => 'Y',
             x_return_status        => l_return_status );

           IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_SUCCESS) THEN
               IF l_debug_on THEN
                  WSH_DEBUG_SV.log(l_module_name,'Successfully closed stop',l_stops_to_close(i));
               END IF;
               l_closing_stop_success := l_closing_stop_success + 1;
           ELSIF (l_return_status = WSH_UTIL_CORE.G_RET_STS_WARNING) THEN
               IF l_debug_on THEN
                  WSH_DEBUG_SV.log(l_module_name,'Trip stop ', l_stops_to_close(i) ||' is closed with warnings');
               END IF;
               l_closing_stop_warning := l_closing_stop_warning + 1;
               WSH_BATCH_PROCESS.log_batch_messages(l_stops_sc_ids(i), NULL , l_stops_to_close(i) ,
                                                    l_stop_location_ids(i), NULL);
           ELSE
               IF l_debug_on THEN
                  WSH_DEBUG_SV.log(l_module_name,'Failed to close stop ', l_stops_to_close(i));
               END IF;
               l_closing_stop_failure := l_closing_stop_failure + 1;
               WSH_BATCH_PROCESS.log_batch_messages(l_stops_sc_ids(i), NULL , l_stops_to_close(i) ,
                                                    l_stop_location_ids(i), NULL);
           END IF;
           IF l_debug_on THEN
              WSH_DEBUG_SV.logmsg(l_module_name,  'Commiting...');
           END IF;
           COMMIT;
        --}
        END LOOP;
        --
        IF l_debug_on THEN
           WSH_DEBUG_SV.logmsg(l_module_name,'Successfully closed '|| l_closing_stop_success
                                        ||' stops' );
           WSH_DEBUG_SV.logmsg(l_module_name,'Closed '|| l_closing_stop_warning
                                        ||' stops with warnings' );
           WSH_DEBUG_SV.logmsg(l_module_name,'Failed to close '|| l_closing_stop_failure
                                        ||' stops');
        END IF;
     --}
     ELSE
        IF l_debug_on THEN
           WSH_DEBUG_SV.log(l_module_name, 'No stops to close');
        END IF;
     END IF;

     WSH_UTIL_CORE.PrintDateTime;

     -- Submit ITS for Batch
     FOR crec in c_defer_interface(p_batch_id) LOOP
     --{
         IF crec.ac_defer_interface_flag = 'N'  AND l_closing_stop_success > 0
         THEN
         --{
            l_interface_stop_id := 0;
            -- added cursor to check if interface is necessary
            OPEN c_batch_stop (crec.pa_sc_batch_id);
            FETCH c_batch_stop INTO l_interface_stop_id;
            CLOSE c_batch_stop;
            --
            IF l_interface_stop_id <> 0 THEN
               l_request_id := FND_REQUEST.submit_Request (
                                                            'WSH', 'WSHINTERFACE', '', '', FALSE,
                                                            'ALL', '', '', p_log_level, crec.pa_sc_batch_id);
               IF l_request_id = 0 THEN
                  NULL;
               ELSE
                  IF l_debug_on THEN
                     WSH_DEBUG_SV.logmsg(l_module_name,  'Commiting...');
                  END IF;
                  COMMIT;
                  WSH_UTIL_CORE.PrintMsg('Interface request submitted for stops, request ID: '||to_char(l_request_id));
               END IF;
            END IF;
         --}
         END IF;
     --}
     END LOOP;

     -- Submit Auto Pack Report
     --{
     OPEN c_ap_batch(p_batch_id);
     LOOP
       FETCH c_ap_batch INTO l_ap_batch_id;
       EXIT WHEN c_ap_batch%NOTFOUND;
       l_request_id := FND_REQUEST.Submit_Request (
                                                    'WSH',
                                                    'WSHRDAPK','Auto Pack Report',NULL,FALSE
                                                    ,l_ap_batch_id,'','','','','','','','',''
                                                    ,'','','','','','','AP','','',''
                                                    ,'','','','','','','','','',''
                                                    ,'','','','','','','','','',''
                                                    ,'','','','','','','','','',''
                                                    ,'','','','','','','','','',''
                                                    ,'','','','','','','','','',''
                                                    ,'','','','','','','','','',''
                                                    ,'','','','','','','','','',''
                                                    ,'','','','','','','','','','' );
       IF l_debug_on THEN
          WSH_DEBUG_SV.logmsg(l_module_name,  'Commiting...');
       END IF;
       COMMIT;
     END LOOP;
     CLOSE c_ap_batch;
     WSH_UTIL_CORE.PrintDateTime;
     --}

     -- Submit Auto Ship Confirm Report
     --{
     IF l_sc_id_tab.COUNT > 0 THEN
        IF l_debug_on THEN
           WSH_DEBUG_SV.logmsg(l_module_name, 'Submitting Auto Ship Confirm Report');
           WSH_DEBUG_SV.log(l_module_name, 'l_sc_id_tab.COUNT', l_sc_id_tab.COUNT);
        END IF;
        WSH_UTIL_CORE.PrintDateTime;
        FOR i in l_sc_id_tab.FIRST..l_sc_id_tab.LAST
        LOOP
            l_request_id := FND_REQUEST.Submit_Request (
                                                         'WSH',
                                                         'WSHRDASC','Auto Ship Confirm Report',NULL,FALSE
                                                         ,l_sc_id_tab(i),'','','','','','','','',''
                                                         ,'','','','','','','','SC','',''
                                                         ,'','','','','','','','','',''
                                                         ,'','','','','','','','','',''
                                                         ,'','','','','','','','','',''
                                                         ,'','','','','','','','','',''
                                                         ,'','','','','','','','','',''
                                                         ,'','','','','','','','','',''
                                                         ,'','','','','','','','','',''
                                                         ,'','','','','','','','','','' );
            IF l_debug_on THEN
               WSH_DEBUG_SV.logmsg(l_module_name,  'Commiting...');
            END IF;
            COMMIT;
        END LOOP;
     END IF;
     WSH_UTIL_CORE.PrintDateTime;
     --}

     IF l_mode = 'PS' THEN --{
        --set the l_completion_status based on the other programs
        FND_PROFILE.Get('CONC_REQUEST_ID', l_this_request);
        OPEN  c_requests(l_this_request);
        FETCH c_requests BULK COLLECT INTO l_child_req_ids;
        CLOSE c_requests;
        l_errors   := 0;
        l_warnings := 0;
        j := l_child_req_ids.FIRST;
        WHILE j IS NOT NULL LOOP
           l_dev_status := NULL;
           l_dummy := FND_CONCURRENT.get_request_status(
                                     request_id => l_child_req_ids(j),
                                     phase      => l_phase,
                                     status     => l_status,
                                     dev_phase  => l_dev_phase,
                                     dev_status => l_dev_status,
                                     message    => l_message);

           IF l_dev_status = 'WARNING' THEN
              l_warnings:= l_warnings + 1;
           ELSIF l_dev_status <> 'NORMAL' THEN
              l_errors := l_errors + 1;
           END IF;
           IF l_debug_on THEN
              WSH_DEBUG_SV.logmsg(l_module_name,'Child Request id :' ||l_child_req_ids(j)||' Status :'||l_dev_status);
           END IF;

           FND_MESSAGE.SET_NAME('WSH','WSH_CHILD_REQ_STATUS');
           FND_MESSAGE.SET_TOKEN('REQ_ID', to_char(l_child_req_ids(j)));
           FND_MESSAGE.SET_TOKEN('STATUS', l_status);
           WSH_UTIL_CORE.PrintMsg(FND_MESSAGE.GET);
           j := l_child_req_ids.NEXT(j);
        END LOOP;

        IF ( G_BACKORDERED ) THEN
             l_warnings:= l_warnings + 1;
        END IF;

        IF l_errors = 0  AND l_warnings = 0 THEN
           l_completion_status := 'NORMAL';
        ELSIF (l_errors > 0 ) THEN
           l_completion_status := 'ERROR';
        ELSE
           l_completion_status := 'WARNING';
        END IF;
     END IF; --}

  --}
  END IF; -- Close Stops / Run ITS / Run Auto Pack and Auto Ship Confirm Reports

  --{
  -- Delete records from Worker Table and Credit Check table
  DELETE FROM wsh_pr_workers
  WHERE  batch_id = p_batch_id;

  DELETE FROM wsh_pr_header_holds
  WHERE  batch_id = p_batch_id;

  -- Call Inventory API to delete pick slip numbers from table as Inventory stores the numbers
  -- in physical table in case of Parallel Pick Release mode
  IF l_debug_on THEN
     WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
     WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_PR_PICK_SLIP_NUMBER.delete_pick_slip_numbers' ,WSH_DEBUG_SV.C_PROC_LEVEL);
  END IF;
  WSH_PR_PICK_SLIP_NUMBER.Delete_Pick_Slip_Numbers ( p_batch_id => p_batch_id );
  IF l_debug_on THEN
     WSH_DEBUG_SV.logmsg(l_module_name,'Return from WSH_PR_PICK_SLIP_NUMBER.delete_pick_slip_numbers');
     WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
  END IF;
  --}

  IF G_CONC_REQ = FND_API.G_TRUE THEN
     l_temp := FND_CONCURRENT.SET_COMPLETION_STATUS(l_completion_status,'');
     IF l_completion_status = 'NORMAL' THEN
        retcode := '0';
     ELSIF l_completion_status = 'WARNING' THEN
        retcode := '1';
     ELSE
        retcode := '2';
     END IF;
  END IF;

  -- Call to DCP if profile is turned on.
  BEGIN --{
     IF l_debug_on THEN
        WSH_DEBUG_SV.log(l_module_name, 'l_check_dcp', l_check_dcp);
     END IF;
     IF NVL(l_check_dcp, -99) IN (1,2) THEN
        IF l_debug_on THEN
           WSH_DEBUG_SV.LOGMSG(L_MODULE_NAME, 'CALLING DCP ');
        END IF;
        WSH_DCP_PVT.Check_Pick_Release(p_batch_id => p_batch_id);
     END IF;
  EXCEPTION
     WHEN wsh_dcp_pvt.data_inconsistency_exception THEN
          IF l_debug_on THEN
             WSH_DEBUG_SV.logmsg(l_module_name,'data_inconsistency_exception');
          END IF;
     WHEN OTHERS THEN
          IF l_debug_on THEN
             WSH_DEBUG_SV.logmsg(l_module_name,'When Others');
          END IF;
  END; --}

  --

  SAVEPOINT S_CALL_FTE_LOAD_TENDER_API_SP;

  IF  UPPER(WSH_UTIL_CORE.G_START_OF_SESSION_API)  = UPPER(l_api_session_name) THEN
  --{
     IF NOT(WSH_UTIL_CORE.G_CALL_FTE_LOAD_TENDER_API) THEN
        IF l_debug_on THEN
           WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_UTIL_CORE.Process_stops_for_load_tender'
                                            ,WSH_DEBUG_SV.C_PROC_LEVEL);
        END IF;
        WSH_UTIL_CORE.Process_stops_for_load_tender (
                                                     p_reset_flags   => TRUE,
                                                     x_return_status => l_return_status );
        IF l_debug_on THEN
           WSH_DEBUG_SV.log(l_module_name,'l_return_status',l_return_status);
        END IF;
        IF (l_return_status = WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR)
        OR (l_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR) THEN
            IF G_CONC_REQ = FND_API.G_TRUE THEN
               l_completion_status := 'ERROR';
               l_temp := FND_CONCURRENT.SET_COMPLETION_STATUS(l_completion_status,'');
               errbuf := 'Pick selection is completed with error';
               retcode := '2';
               ROLLBACK;
            ELSE
               G_ONLINE_PICK_RELEASE_RESULT := 'F';
               ROLLBACK TO S_CALL_FTE_LOAD_TENDER_API_SP;
            END IF;

        ELSIF l_return_status = WSH_UTIL_CORE.G_RET_STS_WARNING THEN
            IF G_CONC_REQ = FND_API.G_TRUE THEN
               IF l_completion_status = 'NORMAL' THEN
                  l_completion_status := 'WARNING';
                  l_temp := FND_CONCURRENT.SET_COMPLETION_STATUS(l_completion_status,'');
                  errbuf := 'Pick selection is completed with warning';
                  retcode := '1';
               END IF;
            ELSE
               IF l_completion_status = 'S' THEN
                  G_ONLINE_PICK_RELEASE_RESULT := 'W';
               END IF;
            END IF;
        END IF;
     END IF;
  --}
  END IF;

  << End_Release_Batch >>

--
 IF l_debug_on THEN
    WSH_DEBUG_SV.logmsg(l_module_name,'ERRBUF :'||errbuf ||' RETCODE :'||retcode);
    WSH_DEBUG_SV.pop(l_module_name);
 END IF;
--

EXCEPTION
   WHEN e_return THEN

      --Bug 5355135
      -- Since we rollback to savepoint do not use this exception if
      -- a commit or rollback has happened for on-line mode

      IF ( G_CONC_REQ = FND_API.G_TRUE ) THEN
         ROLLBACK;
      ELSE
         ROLLBACK TO s_Release_Batch_sp;
      END IF;

      WSH_UTIL_CORE.PrintMsg('SQLCODE: '||sqlcode||' SQLERRM: '||sqlerrm);
      WSH_UTIL_CORE.PrintMsg('Exception occurred in WSH_PICK_LIST');
      IF get_orgs%ISOPEN THEN
         CLOSE get_orgs;
      END IF;
      IF get_pack_ship_groups%ISOPEN THEN
         CLOSE get_pack_ship_groups;
      END IF;
      IF get_dels_in_group%ISOPEN THEN
         CLOSE get_dels_in_group;
      END IF;
      IF get_dels_in_batch%ISOPEN THEN
         CLOSE get_dels_in_batch;
      END IF;
      IF c_distinct_organization_id%ISOPEN THEN
         CLOSE c_distinct_organization_id;
      END IF;
      IF c_batch_orgs%ISOPEN THEN
         CLOSE c_batch_orgs;
      END IF;
      IF c_get_backordered_details%ISOPEN THEN
         CLOSE c_get_backordered_details;
      END IF;
      IF c_get_unassigned_details%ISOPEN THEN
         CLOSE c_get_unassigned_details;
      END IF;
      IF c_tot_worker_records%ISOPEN THEN
         CLOSE c_tot_worker_records;
      END IF;
      IF c_sum_worker%ISOPEN THEN
         CLOSE c_sum_worker;
      END IF;
      IF c_defer_interface%ISOPEN THEN
         CLOSE c_defer_interface;
      END IF;
      IF c_close_trip%ISOPEN THEN
         CLOSE c_close_trip;
      END IF;
      IF get_pick_up_stops%ISOPEN THEN
         CLOSE get_pick_up_stops;
      END IF;
      IF get_all_stops%ISOPEN THEN
         CLOSE get_all_stops;
      END IF;
      IF c_batch_stop%ISOPEN THEN
         CLOSE c_batch_stop;
      END IF;
      IF c_batch_unplanned_del%ISOPEN THEN
         CLOSE c_batch_unplanned_del;
      END IF;
      IF c_ap_batch%ISOPEN THEN
         CLOSE c_ap_batch;
      END IF;
      IF c_wms_orgs%ISOPEN THEN
         CLOSE c_wms_orgs;
      END IF;
      IF c_wms_details%ISOPEN THEN
         CLOSE c_wms_details;
      END IF;
      IF c_dels_in_batch%ISOPEN THEN
         CLOSE c_dels_in_batch;
      END IF;
      IF c_get_location%ISOPEN THEN
         CLOSE c_get_location;
      END IF;
      IF c_requests%ISOPEN THEN
         CLOSE c_requests;
      END IF;
      IF G_CONC_REQ = FND_API.G_TRUE THEN
         l_temp := FND_CONCURRENT.SET_COMPLETION_STATUS('ERROR','');
         errbuf := 'Exception occurred in WSH_PICK_LIST';
         retcode := '2';
      END IF;
      G_ONLINE_PICK_RELEASE_RESULT := 'F';
      IF  upper(WSH_UTIL_CORE.G_START_OF_SESSION_API)  = upper(l_api_session_name) THEN
	  IF NOT(WSH_UTIL_CORE.G_CALL_FTE_LOAD_TENDER_API) THEN
	     IF l_debug_on THEN
	        WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_UTIL_CORE.Reset_stops_for_load_tender',WSH_DEBUG_SV.C_PROC_LEVEL);
	     END IF;
	     WSH_UTIL_CORE.Reset_stops_for_load_tender(p_reset_flags   => TRUE,
							   x_return_status => l_return_status);
	     IF l_debug_on THEN
	        WSH_DEBUG_SV.log(l_module_name,'l_return_status',l_return_status);
	     END IF;
	  END IF;
      END IF;
      --
      IF l_debug_on THEN
         WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:E_RETURN');
      END IF;
      --
   WHEN OTHERS THEN
      --
      ROLLBACK;
      WSH_UTIL_CORE.PrintMsg('SQLCODE: '||sqlcode||' SQLERRM: '||sqlerrm);
      WSH_UTIL_CORE.PrintMsg('Exception occurred in WSH_PICK_LIST');
      IF get_orgs%ISOPEN THEN
         CLOSE get_orgs;
      END IF;
      IF get_pack_ship_groups%ISOPEN THEN
         CLOSE get_pack_ship_groups;
      END IF;
      IF get_dels_in_group%ISOPEN THEN
         CLOSE get_dels_in_group;
      END IF;
      IF get_dels_in_batch%ISOPEN THEN
         CLOSE get_dels_in_batch;
      END IF;
      IF c_distinct_organization_id%ISOPEN THEN
         CLOSE c_distinct_organization_id;
      END IF;
      IF c_batch_orgs%ISOPEN THEN
         CLOSE c_batch_orgs;
      END IF;
      IF c_get_backordered_details%ISOPEN THEN
         CLOSE c_get_backordered_details;
      END IF;
      IF c_get_unassigned_details%ISOPEN THEN
         CLOSE c_get_unassigned_details;
      END IF;
      IF c_tot_worker_records%ISOPEN THEN
         CLOSE c_tot_worker_records;
      END IF;
      IF c_sum_worker%ISOPEN THEN
         CLOSE c_sum_worker;
      END IF;
      IF c_defer_interface%ISOPEN THEN
         CLOSE c_defer_interface;
      END IF;
      IF c_close_trip%ISOPEN THEN
         CLOSE c_close_trip;
      END IF;
      IF get_pick_up_stops%ISOPEN THEN
         CLOSE get_pick_up_stops;
      END IF;
      IF get_all_stops%ISOPEN THEN
         CLOSE get_all_stops;
      END IF;
      IF c_batch_stop%ISOPEN THEN
         CLOSE c_batch_stop;
      END IF;
      IF c_batch_unplanned_del%ISOPEN THEN
         CLOSE c_batch_unplanned_del;
      END IF;
      IF c_ap_batch%ISOPEN THEN
         CLOSE c_ap_batch;
      END IF;
      IF c_wms_orgs%ISOPEN THEN
         CLOSE c_wms_orgs;
      END IF;
      IF c_wms_details%ISOPEN THEN
         CLOSE c_wms_details;
      END IF;
      IF c_dels_in_batch%ISOPEN THEN
         CLOSE c_dels_in_batch;
      END IF;
      IF c_get_location%ISOPEN THEN
         CLOSE c_get_location;
      END IF;
      IF c_requests%ISOPEN THEN
         CLOSE c_requests;
      END IF;
      IF G_CONC_REQ = FND_API.G_TRUE THEN
         l_temp := FND_CONCURRENT.SET_COMPLETION_STATUS('ERROR','');
         errbuf := 'Exception occurred in WSH_PICK_LIST';
         retcode := '2';
      END IF;
      G_ONLINE_PICK_RELEASE_RESULT := 'F';
      IF  upper(WSH_UTIL_CORE.G_START_OF_SESSION_API)  = upper(l_api_session_name) THEN
          IF NOT(WSH_UTIL_CORE.G_CALL_FTE_LOAD_TENDER_API) THEN
             IF l_debug_on THEN
                WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_UTIL_CORE.Reset_stops_for_load_tender',WSH_DEBUG_SV.C_PROC_LEVEL);
             END IF;
             WSH_UTIL_CORE.Reset_stops_for_load_tender(p_reset_flags   => TRUE,
                                                           x_return_status => l_return_status);
             IF l_debug_on THEN
                WSH_DEBUG_SV.log(l_module_name,'l_return_status',l_return_status);
             END IF;
          END IF;
      END IF;
      --
      IF l_debug_on THEN
         WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured.
                           Oracle error message is '|| SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
         WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
      END IF;
      --
END Release_Batch;



-- Start of comments
-- API name : Release_Batch_SRS
-- Type     : Public
-- Pre-reqs : None.
-- Procedure: This procedure gets the defaults from Shipping Parameters and
--            generate the batch id.  It saves to the picking batch table and
--            call Release_Batch. It is called from Pick Release SRS.
-- Parameters :
-- IN:
--      p_batch_prefix        IN  Batch Id.
--      p_rule_id             IN  Rule Id.
--      p_log_level           IN  Set the debug log level.
--      p_num_workers         IN  Number of workers
-- OUT:
--      errbuf       OUT NOCOPY  Error message.
--      retcode      OUT NOCOPY  Error Code 1:Successs, 2:Warning and 3:Error.
-- End of comments
PROCEDURE Release_Batch_SRS (
      errbuf    OUT NOCOPY   VARCHAR2,
      retcode    OUT NOCOPY   VARCHAR2,
      p_rule_id  IN   NUMBER,
      p_batch_prefix  IN   VARCHAR2,
      p_log_level  IN   NUMBER, -- Commented as per GSCC Standards DEFAULT FND_API.G_MISS_NUM  log level fix
      p_ship_confirm_rule_id IN NUMBER,
      p_actual_departure_date IN VARCHAR2,
      p_num_workers IN  NUMBER
       ) IS

	--
        l_batch_name  VARCHAR2(30);
        l_batch_id  NUMBER;
        l_user_id   NUMBER;
        l_login_id   NUMBER;
        l_ret_code  BOOLEAN;
        l_rowid  VARCHAR2(100);
        --
        l_debug_on BOOLEAN;
        l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'RELEASE_BATCH_SRS';
        --
	-- rlanka : Pack J Enhancement
        --Cursor to get picking rule info
	CURSOR c_RuleInfo(p_ruleID IN NUMBER) IS
        --BUG#3330869
	SELECT	name,    --Added bug 7316707
	        organization_id,
		sch_start_days,
		sch_start_hours,
		sch_end_days,
		sch_end_hours,
		req_start_days,
		req_start_hours,
		req_end_days,
		req_end_hours,
		from_scheduled_ship_date,
		to_scheduled_ship_date,
		from_requested_date,
		to_requested_date,
		backorders_only_flag,
		document_set_id,
		existing_rsvs_only_flag,
		shipment_priority_code,
		order_header_id,
		order_type_id,
		ship_from_location_id,
		ship_method_code,
	 	customer_id,
	 	ship_to_location_id,
	 	pick_from_subinventory,
	 	pick_from_locator_id,
	 	default_stage_subinventory,
	 	default_stage_locator_id,
	 	autodetail_pr_flag,
	 	auto_pick_confirm_flag,
	 	ship_set_number,
	 	inventory_item_id,
	 	pick_grouping_rule_id,
	 	pick_sequence_rule_id,
	 	project_id,
	 	task_id,
	 	include_planned_lines,
	 	autocreate_delivery_flag,
	 	ship_confirm_rule_id,
	 	autopack_flag,
	 	autopack_level,
	 	task_planning_flag,
	 	region_id,
	 	zone_id,
	 	category_id,
	 	category_set_id,
	 	ac_delivery_criteria,
		rel_subinventory,
		allocation_method,    --  X-dock
		crossdock_criteria_id, -- X-dock
		append_flag,    --Bug 8225893
		task_priority,
                client_id,  -- LSP PROJECT
		dynamic_replenishment_flag --Bug 10306215: Dynamic replenishment project missing code
        FROM wsh_picking_rules
        WHERE picking_rule_id = p_ruleID
        AND sysdate BETWEEN NVL(start_date_active, SYSDATE) AND NVL(END_DATE_ACTIVE, SYSDATE+1);

        --Cursor to get calendar code
        CURSOR c_CalCode(p_orgID NUMBER) IS
        SELECT calendar_code
        FROM wsh_calendar_assignments
        WHERE calendar_type = 'SHIPPING' AND
        organization_id = p_orgID AND
        enabled_flag = 'Y';
        --
        l_schStartDate	DATE;
        l_schEndDate	DATE;
        l_reqStartDate	DATE;
        l_reqEndDate	DATE;
        v_RuleInfo	c_RuleInfo%ROWTYPE;
        v_CalCode	VARCHAR2(10);
        --
        l_actual_departure_date DATE;
        l_request_data          VARCHAR2(30);
        l_mode                  VARCHAR2(30);
        --
        WSH_NO_FUTURE_SHIPDATE  EXCEPTION;
BEGIN
   -- Fetch user and login information
   --
   WSH_UTIL_CORE.Enable_Concurrent_Log_Print;
   --
   IF p_log_level IS NOT NULL THEN   -- log level fix
      WSH_UTIL_CORE.Set_Log_Level(p_log_level);
      WSH_UTIL_CORE.PrintMsg('p_log_level is ' || to_char(p_log_level));
   END IF;
   --
   l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
   --
   IF l_debug_on IS NULL
   THEN
     l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
   END IF;

   -- Read the Value from REQUEST_DATA. Based on this value, we will know
   -- if the Process is restarted after child processes are complete
   -- The format of Request_Data is 'Batch_id:Request_Status:Mode', where
   -- Batch_id is the Pick Release Batch, Request_Status is either 0 (Success) or 1 (Warning)
   -- and Mode is either of the following values.
   -- Valid Values :
   -- 1) NULL    : Implies First Time or Single Worker Mode
   -- 2) PICK-SS : Resuming Parent Process after Child Processes for SMCs/Ship Sets have completed
   -- 3) PICK    : Resuming Parent Process after Child Processes for Standard Items have completed
   -- 4) PS      : Resuming Parent Process after Child Processes for Pack and Ship have completed
   -- Parent process will always be restarted after child processes complete
   l_request_data := FND_CONC_GLOBAL.Request_Data;
   l_mode         := SUBSTR(l_request_data, INSTR(l_request_data,':',1,2)+1, LENGTH(l_request_data));

   IF l_debug_on THEN
      WSH_DEBUG_SV.push(l_module_name);
      WSH_DEBUG_SV.log(l_module_name,'P_RULE_ID',P_RULE_ID);
      WSH_DEBUG_SV.log(l_module_name,'P_BATCH_PREFIX',P_BATCH_PREFIX);
      WSH_DEBUG_SV.log(l_module_name,'P_LOG_LEVEL',P_LOG_LEVEL);
      WSH_DEBUG_SV.log(l_module_name,'P_NUM_WORKERS',P_NUM_WORKERS);
      WSH_DEBUG_SV.log(l_module_name,'p_Ship_confirm_rule_id',
                       p_ship_confirm_rule_id);
      WSH_DEBUG_SV.log(l_module_name,'p_Actual_Departure_date',
                       p_actual_departure_date);
      WSH_DEBUG_SV.log(l_module_name,'l_mode',l_mode);
   END IF;

   IF l_mode IS NULL THEN --{

      l_user_id := FND_GLOBAL.USER_ID;
      l_login_id := FND_GLOBAL.CONC_LOGIN_ID;
      l_actual_departure_date := FND_DATE.CANONICAL_TO_DATE(p_actual_departure_date);

      IF (l_actual_departure_date IS NOT NULL) THEN
          IF NOT WSH_UTIL_CORE.ValidateActualDepartureDate(p_ship_confirm_rule_id, l_actual_departure_date) THEN
              raise WSH_NO_FUTURE_SHIPDATE;
          END IF;
      END IF;
      --
      -- rlanka : Pack J Enhancement
      -- common cursor to check existence of rule and also to fetch rule info
      --
      OPEN c_RuleInfo(p_rule_id);
      FETCH c_RuleInfo INTO v_RuleInfo;
      --
      IF c_RuleInfo%NOTFOUND THEN
       --
       WSH_UTIL_CORE.PrintMsg('Rule ' || p_rule_id || ' does not exist or has expired');
       CLOSE c_RuleInfo;
       --
       IF l_debug_on THEN
         wsh_Debug_sv.pop(l_module_name);
       END IF;
       --
       RETURN;
       --
      END IF;
      --
      IF c_RuleInfo%ISOPEN THEN
       CLOSE c_RuleInfo;
      END IF;

      --
      -- rlanka : Pack J Enhancement
      -- Get Calendar code
      OPEN c_CalCode(v_RuleInfo.organization_id);
      FETCH c_CalCode INTO v_CalCode;
      CLOSE c_CalCode;
      --
      IF l_debug_on THEN
        wsh_debug_sv.log(l_module_name, 'Org ID for Rule', v_RuleInfo.organization_id);
        wsh_debug_sv.log(l_module_name, 'v_calCode', v_CalCode);
        wsh_debug_sv.log(l_module_name, 'sch_start_days', v_RuleInfo.sch_start_days);
        wsh_debug_sv.log(l_module_name, 'sch_start_hours', v_RuleInfo.sch_start_hours);
        wsh_debug_sv.log(l_module_name, 'sch_end_days', v_RuleInfo.sch_end_days);
        wsh_debug_sv.log(l_module_name, 'sch_end_hours', v_RuleInfo.sch_end_hours);
        wsh_debug_sv.log(l_module_name, 'req_start_days', v_RuleInfo.req_start_days);
        wsh_debug_sv.log(l_module_name, 'req_start_hours', v_RuleInfo.req_start_hours);
        wsh_debug_sv.log(l_module_name, 'req_end_days', v_RuleInfo.req_end_days);
        wsh_debug_sv.log(l_module_name, 'req_end_hours', v_RuleInfo.req_end_hours);
        wsh_Debug_sv.log(l_module_name, 'from_scheduled_ship_date', v_RuleInfo.from_scheduled_ship_date);
        wsh_Debug_sv.log(l_module_name, 'to_scheduled_ship_date', v_RuleInfo.to_scheduled_ship_date);
        wsh_Debug_sv.log(l_module_name, 'from_requested_date', v_RuleInfo.from_requested_date);
        wsh_Debug_sv.log(l_module_name, 'to_requested_date', v_RuleInfo.to_requested_date);
        wsh_Debug_sv.log(l_module_name, 'Allocation_Method', v_RuleInfo.allocation_method); -- X-dock
        wsh_Debug_sv.log(l_module_name, 'Crossdock_Criteria_id', v_RuleInfo.crossdock_criteria_id); --X-dock
	  wsh_Debug_sv.log(l_module_name, 'Dynamic_Replenishment_Flag', v_RuleInfo.dynamic_replenishment_flag); --Bug 10306215
      --
      END IF;
      --
      IF v_RuleInfo.sch_start_days IS NOT NULL THEN
        --Detrmine the working days
        CalcWorkingDay(v_RuleInfo.organization_id,v_RuleInfo.name, v_RuleInfo.sch_start_days, v_RuleInfo.sch_start_hours,
   		    v_CalCode, l_schStartDate); --Added  v_RuleInfo.name bug 7316707
      END IF;
      --
      IF v_RuleInfo.sch_end_days IS NOT NULL THEN
        CalcWorkingDay(v_RuleInfo.organization_id,v_RuleInfo.name, v_RuleInfo.sch_end_days, v_RuleInfo.sch_end_hours,
   		    v_CalCode, l_schEndDate);   --Added  v_RuleInfo.name bug 7316707
      END IF;
      --
      IF v_RuleInfo.req_start_days IS NOT NULL THEN
        --Detrmine the working days
        CalcWorkingDay(NULL,NULL, v_RuleInfo.req_start_days, v_RuleInfo.req_start_hours,
   		    v_CalCode, l_reqStartDate);   --Added  NULL bug 7316707
      END IF;
      --
      IF v_RuleInfo.req_end_days IS NOT NULL THEN
        --Detrmine the working days
        CalcWorkingDay(NULL,NULL, v_RuleInfo.req_end_days, v_RuleInfo.req_end_hours,
   		    v_CalCode, l_reqEndDate);   --Added  NULL bug 7316707
      END IF;
      --
      l_schStartDate := NVL(l_schStartDate, v_RuleInfo.from_scheduled_ship_date);
      l_schEndDate := NVL(l_schEndDate, v_RuleInfo.to_scheduled_ship_date);
      l_reqStartDate := NVL(l_reqStartDate, v_RuleInfo.from_requested_date);
      l_reqEndDate := NVL(l_reqEndDate, v_RuleInfo.to_requested_date);
      --
      IF l_debug_on THEN
        wsh_debug_sv.log(l_module_name, 'calc. scheduled ship start date', l_schStartDate);
        wsh_debug_sv.log(l_module_name, 'calc. scheduled ship end date', l_schEndDate);
        wsh_debug_sv.log(l_module_name, 'calc. requested start date', l_reqStartDate);
        wsh_debug_sv.log(l_module_name, 'calc. requested end date', l_reqEndDate);
      END IF;
      --
      IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_PICKING_BATCHES_PKG.INSERT_ROW',WSH_DEBUG_SV.C_PROC_LEVEL);
      END IF;

      -- bug5117876, insert statement is replace with the following call
      WSH_PICKING_BATCHES_PKG.Insert_Row(
          X_Rowid                   => l_rowid,
          X_Batch_Id                => l_batch_id,
          P_Creation_Date           => SYSDATE,
          P_Created_By              => l_user_id,
          P_Last_Update_Date        => SYSDATE,
          P_Last_Updated_By         => l_user_id,
          P_Last_Update_Login       => l_login_id,
          P_batch_name_prefix       => p_batch_prefix,
          X_Name                    => l_batch_name,
          P_Backorders_Only_Flag    => v_RuleInfo.BACKORDERS_ONLY_FLAG,
          P_Document_Set_Id         => v_RuleInfo.DOCUMENT_SET_ID,
          P_Existing_Rsvs_Only_Flag => NVL(v_RuleInfo.EXISTING_RSVS_ONLY_FLAG, 'N'),
          P_Shipment_Priority_Code  => v_RuleInfo.SHIPMENT_PRIORITY_CODE,
          P_Ship_Method_Code        => v_RuleInfo.SHIP_METHOD_CODE,
          P_Customer_Id             => v_RuleInfo.CUSTOMER_ID,
          P_Order_Header_Id         => v_RuleInfo.ORDER_HEADER_ID,
          P_Ship_Set_Number         => v_RuleInfo.SHIP_SET_NUMBER,
          P_Inventory_Item_Id       => v_RuleInfo.INVENTORY_ITEM_ID,
          P_Order_Type_Id           => v_RuleInfo.ORDER_TYPE_ID,
          P_From_Requested_Date     => l_reqStartDate,
          P_To_Requested_Date       => l_reqEndDate,
          P_From_Scheduled_Ship_Date => l_schStartDate,
          P_To_Scheduled_Ship_Date   => l_schEndDate,
          P_Ship_To_Location_Id      => v_RuleInfo.SHIP_TO_LOCATION_ID,
          P_Ship_From_Location_Id    => v_RuleInfo.SHIP_FROM_LOCATION_ID,
          P_Trip_Id                  => NULL,
          P_Delivery_Id              => NULL,
          P_Include_Planned_Lines    => v_RuleInfo.INCLUDE_PLANNED_LINES,
          P_Pick_Grouping_Rule_Id    => v_RuleInfo.PICK_GROUPING_RULE_ID,
          P_pick_sequence_rule_id    => v_RuleInfo.PICK_SEQUENCE_RULE_ID,
          P_Autocreate_Delivery_Flag => v_RuleInfo.AUTOCREATE_DELIVERY_FLAG,
          P_Attribute_Category       => NULL,
          P_Attribute1               => NULL,
          P_Attribute2               => NULL,
          P_Attribute3               => NULL,
          P_Attribute4               => NULL,
          P_Attribute5               => NULL,
          P_Attribute6               => NULL,
          P_Attribute7               => NULL,
          P_Attribute8               => NULL,
          P_Attribute9               => NULL,
          P_Attribute10              => NULL,
          P_Attribute11              => NULL,
          P_Attribute12              => NULL,
          P_Attribute13              => NULL,
          P_Attribute14              => NULL,
          P_Attribute15              => NULL,
          P_Autodetail_Pr_Flag       => v_RuleInfo.AUTODETAIL_PR_FLAG,
          P_Carrier_Id               => NULL,
          P_Trip_Stop_Id             => NULL,
          P_Default_stage_subinventory => v_RuleInfo.DEFAULT_STAGE_SUBINVENTORY,
          P_Default_stage_locator_id => v_RuleInfo.DEFAULT_STAGE_LOCATOR_ID,
          P_Pick_from_subinventory   => v_RuleInfo.PICK_FROM_SUBINVENTORY,
          P_Pick_from_locator_id     => v_RuleInfo.PICK_FROM_LOCATOR_ID,
          P_Auto_pick_confirm_flag   => v_RuleInfo.AUTO_PICK_CONFIRM_FLAG,
          P_Delivery_Detail_ID       => NULL,
          P_Project_ID               => v_RuleInfo.PROJECT_ID,
          P_Task_ID                  => v_RuleInfo.TASK_ID,
          P_Organization_Id          => v_RuleInfo.ORGANIZATION_ID,
          P_Ship_Confirm_Rule_Id     => v_RuleInfo.SHIP_CONFIRM_RULE_ID,
          P_Autopack_Flag            => v_RuleInfo.AUTOPACK_FLAG,
          P_Autopack_Level           => v_RuleInfo.AUTOPACK_LEVEL,
          P_Task_Planning_Flag       => v_RuleInfo.TASK_PLANNING_FLAG,
          p_regionID                 => v_RuleInfo.REGION_ID,
          p_zoneId                   => v_RuleInfo.ZONE_ID,
          p_categoryID               => v_RuleInfo.CATEGORY_ID,
          p_categorySetID            => v_RuleInfo.CATEGORY_SET_ID,
          p_acDelivCriteria          => v_RuleInfo.AC_DELIVERY_CRITERIA,
          p_RelSubinventory          => v_RuleInfo.REL_SUBINVENTORY,
          p_actual_departure_date    => l_actual_departure_date,
          p_allocation_method        => nvl(v_RuleInfo.ALLOCATION_METHOD,'I'),
          p_crossdock_criteria_id    => v_RuleInfo.CROSSDOCK_CRITERIA_ID,
          p_append_flag              => v_RuleInfo.APPEND_FLAG,   --Bug 8225893,
          p_task_priority            => v_RuleInfo.TASK_PRIORITY,
          p_client_id                => v_RuleInfo.CLIENT_ID, -- LSP PROJECT
          p_dynamic_replenishment_flag => v_RuleInfo.DYNAMIC_REPLENISHMENT_FLAG); --Bug 10306215
      --
      IF l_debug_on THEN
        WSH_DEBUG_SV.log(l_module_name, 'BATCH NAME ', L_BATCH_NAME);
        WSH_DEBUG_SV.log(l_module_name, 'BATCH_ID ', L_BATCH_ID);
      END IF;
      --

   ELSE
      -- Return from worker process
      l_batch_id := SUBSTR(l_request_data, 1, INSTR(l_request_data,':',1,1)-1);

   END IF; --}

   --Pick Release the batch
   Release_Batch(errbuf, retcode, l_batch_id,p_log_level, NVL(p_num_workers,1));  -- log level fix
   --
   IF l_debug_on THEN
      WSH_DEBUG_SV.log(l_module_name,'ERRBUF',errbuf);
      WSH_DEBUG_SV.log(l_module_name,'RETCODE',retcode);
      WSH_DEBUG_SV.pop(l_module_name);
   END IF;
   --
EXCEPTION
      --

      WHEN WSH_NO_FUTURE_SHIPDATE THEN

          WSH_UTIL_CORE.PrintMsg('No Lines were selected for Ship Confirmation because Allow Future Ship Date Parameter is disabled and Actual Ship Date is greater than current system date');
          l_ret_code := FND_CONCURRENT.SET_COMPLETION_STATUS('WARNING','Release_Batch_SRS');
          errbuf := 'Pick Selection List Generation SRS completed with warning';
          retcode := '1';
          IF l_debug_on THEN
              WSH_DEBUG_SV.pop(l_module_name);
          END IF;

      WHEN OTHERS THEN
	 --
         IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
            FND_MSG_PUB.Add_Exc_Msg( 'WSH_PICK_LIST', 'Release_Batch_SRS' );
         END IF;
	 --
         IF G_CONC_REQ = FND_API.G_TRUE THEN
             l_ret_code := FND_CONCURRENT.SET_COMPLETION_STATUS('ERROR','');
             errbuf := 'Exception occurred in Release_Batch_SRS';
             retcode := '2';
         END IF;
         --
         IF l_debug_on THEN
            WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '|| SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
            WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
         END IF;
            --
END Release_Batch_SRS;


-- Start of comments
-- API name : Online_Release
-- Type     : Public
-- Pre-reqs : None.
-- Procedure: This procedure calls Release_Batch based on batch id passed,
--            this is call from Release Sales Order from in online mode.
-- Parameters :
-- IN:
--      p_batch_id            IN  Batch Id.
-- OUT:
--      p_pick_result     OUT NOCOPY  Pick Release Phase, Valid value 'START','MOVE ORDER LINE','SUCCESS'.
--      p_pick_phase      OUT NOCOPY  Pick Release Result,Valid value Success,Warning,Error
--      p_pick_skip       OUT NOCOPY  If Pick Release has been skip, valid value Y/N.
-- End of comments
PROCEDURE Online_Release (
       p_batch_id  IN   NUMBER,
       p_pick_result   OUT NOCOPY   VARCHAR2,
       p_pick_phase  OUT NOCOPY   VARCHAR2,
       p_pick_skip   OUT NOCOPY   VARCHAR2	/*2432800*/
        ) IS
        l_dummy1 VARCHAR2(300);
        l_dummy2 VARCHAR2(1);
        --
        l_debug_on BOOLEAN;
        l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'ONLINE_RELEASE';
        --
BEGIN
   --
   l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
   --
   IF l_debug_on IS NULL
   THEN
     l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
   END IF;
   --
   IF l_debug_on THEN
     WSH_DEBUG_SV.push(l_module_name);
     WSH_DEBUG_SV.log(l_module_name,'P_BATCH_ID',P_BATCH_ID);
   END IF;
   --
   G_CONC_REQ := FND_API.G_FALSE;
   Release_Batch(l_dummy1,l_dummy2,p_batch_id, p_num_workers => 1);
   p_pick_phase :=  G_ONLINE_PICK_RELEASE_PHASE  ;
   p_pick_result := G_ONLINE_PICK_RELEASE_RESULT ;
   p_pick_skip := G_ONLINE_PICK_RELEASE_SKIP;	/*2432800*/
   --
   IF l_debug_on THEN
   WSH_DEBUG_SV.pop(l_module_name);
   END IF;
   --
END Online_Release;



-- Start of comments
-- API name : Launch_Pick_Release
-- Type     : Public
-- Pre-reqs : None.
-- Procedure: API to launch pick Release process based on input entity passed. Api dose
--            1. Get the Entity name for the passed entity
--            2. Get the entity status.
--            3. Create picking batch by calling WSH_PICKING_BATCHES_PKG.Insert_Row.
--            4. Update the detail lines with batch id.
--            5. Submit request to release batch created by calling WSH_PICKING_BATCHES_PKG.Submit_Release_Request
-- Parameters :
-- IN:
--      p_trip_ids            IN  Trip id.
--      p_stop_ids            IN  Stop Id.
--      p_delivery_ids        IN  Delivery id.
--      p_detail_ids          IN  Delivery detail Id.
--      p_auto_pack_ship      IN  SC - Auto Ship Confirm after Pick Release
--                                PS - Auto Pack and Ship Confirm after Pick Release.
-- OUT:
--      x_return_status     OUT NOCOPY  Standard to output api status.
--      x_request_ids       OUT NOCOPY  Request ID of concurrent program.
-- End of comments
-- bug# 6719369 (replenishment project): For dynamic replenishment case, WMS passes the delivery detail ids as well as
-- the picking batch id value. In this case it shoud create a new batch by taking the attribute values from the old batch
-- information.
PROCEDURE Launch_Pick_Release(
  p_trip_ids   IN  WSH_UTIL_CORE.Id_Tab_Type,
  p_stop_ids   IN  WSH_UTIL_CORE.Id_Tab_Type,
  p_delivery_ids   IN  WSH_UTIL_CORE.Id_Tab_Type,
  p_detail_ids   IN  WSH_UTIL_CORE.Id_Tab_Type,
  x_request_ids  OUT NOCOPY  WSH_UTIL_CORE.Id_Tab_Type,
  p_auto_pack_ship  IN VARCHAR2 DEFAULT NULL,
  p_batch_id        IN NUMBER   DEFAULT NULL, -- bug# 6719369 (replenishment project)
  x_return_status   OUT NOCOPY  VARCHAR2
  ) IS

   --Cursor to get container attributes.
   CURSOR get_container(l_del_detail_id IN VARCHAR2) IS
   SELECT container_name, container_flag , organization_id
   FROM   WSH_DELIVERY_DETAILS
   WHERE  delivery_detail_id = l_del_detail_id;

   --Cursor to get trip status.
   CURSOR check_trip(c_trip_id IN NUMBER) IS
   select status_code from wsh_trips
   where trip_id = c_trip_id;

   --Cursor to get stop status.
   CURSOR check_stop(c_stop_id IN NUMBER) IS
   select status_code from wsh_trip_stops
   where stop_id = c_stop_id;

   --Cursor to get delivery attributes.
   CURSOR check_delivery(c_delivery_id IN NUMBER) IS
   select status_code, organization_id from wsh_new_deliveries
   where delivery_id = c_delivery_id;

   CURSOR check_detail (c_delivery_detail_id IN NUMBER) IS
   select released_status from wsh_delivery_details
   where delivery_detail_id = c_delivery_detail_id;

   --Cursor to validate auto packing.
   CURSOR check_detail_for_AP (c_batch_id IN NUMBER) IS
   select distinct p.organization_id
   from wsh_delivery_details d, wsh_shipping_parameters p
   where d.organization_id = p.organization_id
   and NVL(p.autopack_level,0) = 0
   and d.batch_id = c_batch_id;


   --Cursor to validate ship confirm.
   CURSOR check_detail_for_SC (c_batch_id IN NUMBER) IS
   select distinct p.organization_id, p.ship_confirm_rule_id,
                   p.autocreate_deliveries_flag, m.mo_pick_confirm_required
   from wsh_delivery_details d, wsh_shipping_parameters p, mtl_parameters m
   where d.organization_id = p.organization_id and
   m.organization_id = d.organization_id
   and (ship_confirm_rule_id IS NULL
   or NVL(p.autocreate_deliveries_flag, 'N') <> 'Y'
   or NVL(m.mo_pick_confirm_required,0) <> 2)
   and d.batch_id = c_batch_id;

   --Cursor to check unassign delivery for an batch.
   CURSOR check_unassigned_dels(c_org_id IN NUMBER, c_batch_id IN NUMBER) IS
   select 1 from wsh_delivery_assignments_v a, wsh_delivery_details d
   where  d.organization_id = c_org_id
   and d.batch_id = c_batch_id
   and d.delivery_detail_id = a.delivery_detail_id
   and a.delivery_id is null
   and rownum = 1;

   --Cursor to check inventory pick confirm requried flag.
   CURSOR pick_confirm_required_for_del(c_org_id IN NUMBER) IS
   select mo_pick_confirm_required
   from mtl_parameters
   where organization_id = c_org_id;

   --OTM R12, this cursor is found if detail is not assigned to delivery
   --and include for planning
   CURSOR c_is_detail_assigned(p_detail_id IN NUMBER) IS
     SELECT 1
     FROM   wsh_delivery_assignments wda,
            wsh_delivery_details wdd
     WHERE  wda.delivery_detail_id = p_detail_id
     AND    wda.delivery_detail_id = wdd.delivery_detail_id
     AND    wda.delivery_id IS NULL
     AND    NVL(wdd.ignore_for_planning, 'N') = 'N';
   --

   CURSOR c_batch_info(x_batch_id NUMBER) IS
   SELECT
     Document_Set_Id,
     Include_Planned_Lines,
     Pick_Grouping_Rule_Id,
     Pick_Sequence_Rule_Id,
     Autocreate_Delivery_Flag,
     Attribute_Category,
     Attribute1,
     Attribute2,
     Attribute3,
     Attribute4,
     Attribute5,
     Attribute6,
     Attribute7,
     Attribute8,
     Attribute9,
     Attribute10,
     Attribute11,
     Attribute12,
     Attribute13,
     Attribute14,
     Attribute15,
     Autodetail_Pr_Flag,
     Default_Stage_Subinventory,
     Default_Stage_Locator_Id,
     Pick_From_Subinventory,
     Pick_From_locator_Id,
     Auto_Pick_Confirm_Flag,
     Organization_Id,
     Ship_Confirm_Rule_Id,
     Autopack_Flag,
     Autopack_Level,
     Task_Planning_Flag,
     ac_Delivery_Criteria,
     append_flag,
     task_priority,
     actual_departure_date,
     allocation_method,
     crossdock_criteria_id,
     Non_Picking_Flag,
     dynamic_replenishment_flag,
     Order_Header_Id,
     Order_Type_Id,
     Existing_Rsvs_Only_Flag,
     client_id -- LSP PROJECT
   FROM wsh_picking_batches
   WHERE batch_id = x_batch_id;

   l_batch_rec   c_batch_info%ROWTYPE;

   type del_params_cache is record(
              organization_id        NUMBER,
              ship_confirm_rule_id   NUMBER,
              autopack_level         NUMBER,
              autopack_flag          VARCHAR2(1),
              task_planning_flag     VARCHAR2(1));

   type del_params_cache_tab is table of del_params_cache INDEX BY BINARY_INTEGER;

   l_del_org_params_cache_tab  del_params_cache_tab;

   l_rowid  VARCHAR2(100);
   l_batch_id  NUMBER;
   l_batch_name  VARCHAR2(30);
   l_index   NUMBER;
   l_trip_id   NUMBER;
   l_stop_id   NUMBER;
   l_delivery_id   NUMBER;
   l_detail_id   NUMBER;
   l_name    VARCHAR2(100);
   l_type    VARCHAR2(30);
   l_entity_id   NUMBER;
   l_container_flag  VARCHAR2(1);
   l_entity_status VARCHAR2(2);
   l_count_fail  NUMBER := 0;
   l_count_succ  NUMBER := 0;
   l_temp_autopack_level   NUMBER;
   l_ship_confirm_rule_id   NUMBER;
   l_autopack_level   NUMBER := NULL;
   l_autopack_flag  VARCHAR2(1) := NULL;
   l_autocreate_del_flag  VARCHAR2(1);
   l_pickconfirm_required NUMBER;
   l_del_org NUMBER;
   l_det_org NUMBER;
   l_param_info   WSH_SHIPPING_PARAMS_PVT.Parameter_Rec_Typ;
   l_return_status   VARCHAR2(1);
   l_task_planning_flag   VARCHAR2(1) := NULL;
   l_non_picking_flag   VARCHAR2(1) := NULL;
   l_warn_org   NUMBER;
   l_num_warn   NUMBER := 0;
   l_org_name   VARCHAR2(240);
   l_assigned   NUMBER;
   l_cached_flag VARCHAR2(1);
   j  NUMBER := 0;

   --OTM R12
   l_detail_ids       WSH_UTIL_CORE.Id_Tab_Type;
   i                  NUMBER;
   l_counter          NUMBER;
   l_result           NUMBER;
   l_gc3_is_installed VARCHAR2(1);
   api_return_fail    EXCEPTION;
   --
   INVALID_RELEASED_STATUS EXCEPTION;
   INVALID_ENTITY_STATUS   EXCEPTION;
   --
   l_debug_on BOOLEAN;
   --
   l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'LAUNCH_PICK_RELEASE';
   --
   l_log_level NUMBER:=0;

BEGIN
   --
   l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
   --
   IF l_debug_on IS NULL
   THEN
     l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
   END IF;
   --
   IF l_debug_on THEN
      WSH_DEBUG_SV.push(l_module_name);
      WSH_DEBUG_SV.log(l_module_name,'TRIP_IDS.COUNT',p_trip_ids.count);
      WSH_DEBUG_SV.log(l_module_name,'STOP_IDS.COUNT',p_stop_ids.count);
      WSH_DEBUG_SV.log(l_module_name,'DELIVERY_IDS.COUNT',p_delivery_ids.count);
      WSH_DEBUG_SV.log(l_module_name,'DETAIL_IDS.COUNT',p_detail_ids.count);
      l_log_level := 1;
   END IF;

   --OTM R12
   --include for planning delivery lines will all be
   --set to ignore for planning
   l_gc3_is_installed := WSH_UTIL_CORE.G_GC3_IS_INSTALLED; -- this is global variable

   IF l_gc3_is_installed IS NULL THEN
     l_gc3_is_installed := WSH_UTIL_CORE.GC3_IS_INSTALLED; -- this is actual function
   END IF;

   IF (p_detail_ids.COUNT > 0
       AND p_auto_pack_ship IS NOT NULL
       AND l_gc3_is_installed = 'Y') THEN

     i := p_detail_ids.FIRST;
     l_counter := 1;

     WHILE i IS NOT NULL LOOP

       OPEN c_is_detail_assigned(p_detail_ids(i));
       FETCH c_is_detail_assigned INTO l_result;

       -- Only for unassigned include for planning delivery lines, flip the flag
       IF (c_is_detail_assigned%FOUND) THEN
         l_detail_ids(l_counter) := p_detail_ids(i);
         l_counter := l_counter + 1;
       END IF;

       CLOSE c_is_detail_assigned;

       i := p_detail_ids.NEXT(i);

     END LOOP;

     IF l_debug_on THEN
       WSH_DEBUG_SV.log(l_module_name,'COUNT FOR THE DETAIL_IDS TO IGNORE PLAN',l_detail_ids.COUNT);
     END IF;

     IF (l_detail_ids.COUNT > 0) THEN

       WSH_TP_RELEASE.change_ignoreplan_status
         (p_entity        => 'DLVB',
          p_in_ids        => l_detail_ids,
          p_action_code   => 'IGNORE_PLAN',
          x_return_status => l_return_status);

       IF l_debug_on THEN
         wsh_debug_sv.log(l_module_name,'Return Status After Calling change_ignoreplan_status ',l_return_status);
       END IF;

       IF (l_return_status IN (WSH_UTIL_CORE.G_RET_STS_ERROR, WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR)) THEN

         --
         IF l_debug_on THEN
           WSH_DEBUG_SV.logmsg(l_module_name,'ERROR IN WSH_TP_RELEASE.CHANGE_IGNOREPLAN_STATUS');
         END IF;
         --
         RAISE api_return_fail;

       ELSIF (l_return_status = WSH_UTIL_CORE.G_RET_STS_WARNING) THEN
         l_num_warn := l_num_warn + 1;
       END IF;

     END IF;
   END IF;
   --END OTM R12

   --
   IF (p_trip_ids.COUNT > 0) THEN
      -- Get the index to the first ID
      l_index := p_trip_ids.FIRST;
      l_trip_id := p_trip_ids(l_index);
      l_type := 'Trip';
      --
      l_name :=  WSH_TRIPS_PVT.Get_Name(l_trip_id);
   ELSIF (p_stop_ids.COUNT > 0) THEN
      l_index := p_stop_ids.FIRST;
      l_stop_id := p_stop_ids(l_index);
      --
      l_name := WSH_TRIP_STOPS_PVT.Get_Name(l_stop_id);
      l_type := 'Stop';
   ELSIF (p_delivery_ids.COUNT > 0) THEN
      l_index := p_delivery_ids.FIRST;
      l_delivery_id := p_delivery_ids(l_index);
      --
      l_name := WSH_NEW_DELIVERIES_PVT.Get_Name(l_delivery_id);
      l_type := 'Delivery';
   ELSIF (p_detail_ids.COUNT > 0) THEN
      l_index := p_detail_ids.FIRST;
      l_detail_id := p_detail_ids(l_index);

      -- Determine if releasing a line or a container
      OPEN get_container(l_detail_id);
      FETCH get_container INTO l_name, l_container_flag, l_det_org;
      CLOSE get_container;
      IF l_container_flag = 'N' THEN
         l_name := to_char(l_detail_id);
         l_type := 'Line ID';
      ELSE
         l_type := 'Container';
      END IF;
      l_detail_id := -1;

      IF p_auto_pack_ship IS NOT NULL THEN


         IF p_auto_pack_ship = 'PS' THEN

            l_non_picking_flag  := 'P';

         ELSIF p_auto_pack_ship = 'SC' THEN

             l_non_picking_flag  := 'S';

         END IF;

         IF l_debug_on THEN
            WSH_DEBUG_SV.log(l_module_name,'ship_confirm_rule_id',l_param_info.ship_confirm_rule_id);
         END IF;
      END IF;
   ELSE
       --Non of pick release entity passed.
       x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
       FND_MESSAGE.SET_NAME('WSH','WSH_PR_NULL_IDS');
       WSH_UTIL_CORE.Add_Message(x_return_status);
       IF l_debug_on THEN
          WSH_DEBUG_SV.pop(l_module_name);
       END IF;
       --
       ROLLBACK; -- 2746314
       RETURN;
   END IF;

   LOOP
   --{
      --Get the entity status.

      IF l_type = 'Trip' THEN
        OPEN check_trip(l_trip_id);
        FETCH check_trip INTO l_entity_status;
        CLOSE check_trip;

      ELSIF l_type = 'Stop' THEN
        OPEN check_stop(l_stop_id);
        FETCH check_stop INTO l_entity_status;
        CLOSE check_stop;

      ELSIF l_type = 'Delivery' THEN
        OPEN check_delivery(l_delivery_id);
        FETCH check_delivery INTO l_entity_status, l_del_org;
        CLOSE check_delivery;

        l_cached_flag := 'N';
        FOR i in 1..l_del_org_params_cache_tab.count LOOP
          IF l_del_org_params_cache_tab(i).organization_id = l_del_org THEN
             l_cached_flag := 'Y';
             j := i;
             EXIT;
          END IF;

        END LOOP;

        IF l_cached_flag = 'Y' THEN

           l_task_planning_flag := l_del_org_params_cache_tab(j).task_planning_flag;
           l_ship_confirm_rule_id := l_del_org_params_cache_tab(j).ship_confirm_rule_id;
           l_autopack_level := l_del_org_params_cache_tab(j).autopack_level;
           l_autopack_flag  := l_del_org_params_cache_tab(j).autopack_flag;

        ELSE

           j := l_del_org_params_cache_tab.count + 1;

           l_del_org_params_cache_tab(j).organization_id := l_del_org;

           WSH_SHIPPING_PARAMS_PVT.Get(p_organization_id => l_del_org,
                                       x_param_info  => l_param_info,
                                       x_return_status   => l_return_status);
           l_task_planning_flag := l_param_info.task_planning_flag;
           l_del_org_params_cache_tab(j).task_planning_flag := l_task_planning_flag;


           IF p_auto_pack_ship IS NOT NULL THEN

             OPEN pick_confirm_required_for_del(l_del_org);
             FETCH pick_confirm_required_for_del into l_pickconfirm_required;
             CLOSE pick_confirm_required_for_del;

             IF l_pickconfirm_required <> 2 THEN
                l_org_name := WSH_UTIL_CORE.Get_Org_Name(l_del_org);
                -- set warning for org
                FND_MESSAGE.SET_NAME('WSH','WSH_NO_AUTOPICK_FOR_ORG');
                FND_MESSAGE.SET_TOKEN('ORG_NAME',l_org_name);
                x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
                WSH_UTIL_CORE.Add_Message(x_return_status);
                l_num_warn := l_num_warn + 1;
             END IF;

              -- always ship when action is pick,ship or pick,pack,ship
              l_ship_confirm_rule_id := l_param_info.ship_confirm_rule_id;
              l_del_org_params_cache_tab(j).ship_confirm_rule_id := l_ship_confirm_rule_id;

              IF l_ship_confirm_rule_id IS NULL THEN
                l_org_name := WSH_UTIL_CORE.Get_Org_Name(l_del_org);
                -- set warning for org
                FND_MESSAGE.SET_NAME('WSH','WSH_NO_SC_RULE_FOR_ORG');
                FND_MESSAGE.SET_TOKEN('ORG_NAME',l_org_name);
                x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
                WSH_UTIL_CORE.Add_Message(x_return_status);
                l_num_warn := l_num_warn + 1;
              END IF;

              IF p_auto_pack_ship = 'PS' THEN

                l_autopack_level := l_param_info.autopack_level;
                l_del_org_params_cache_tab(j).autopack_level := l_autopack_level;
                l_autopack_flag  := 'Y';
                l_del_org_params_cache_tab(j).autopack_flag := l_autopack_flag;

                IF NVL(l_autopack_level,0) = 0 THEN
                  l_org_name := WSH_UTIL_CORE.Get_Org_Name(l_del_org);
                   -- set warning for org
                  FND_MESSAGE.SET_NAME('WSH','WSH_NO_AP_LEVEL_FOR_ORG');
                  FND_MESSAGE.SET_TOKEN('ORG_NAME',l_org_name);
                  x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
                  WSH_UTIL_CORE.Add_Message(x_return_status);
                  l_num_warn := l_num_warn + 1;
               END IF;
             END IF;
           END IF;
        END IF;

      END IF;

      --bug# 6719369 (replenishment project) (begin) : For dynamic replenishment case, WMS passes the delivery detail ids as well as
      -- the picking batch id value. In this case it shoud create a new batch by taking the attribute values from the old batch
      -- information.

      -- Initialize batch id and name to null
      -- New batch name and id will be generated
      l_batch_id := '';
      l_batch_name := '';
      --
      IF p_batch_id is not null THEN
      --{
          OPEN  c_batch_info(p_batch_id);
          FETCH c_batch_info INTO l_batch_rec;
	  IF c_batch_info%NOTFOUND THEN
          --{
              IF l_debug_on THEN
                  wsh_Debug_sv.log(l_module_name, 'dynamic replenishment (WMS), Invalid batch Id', p_batch_id);
		  WSH_DEBUG_SV.pop(l_module_name);
              END IF;
	      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
	      CLOSE c_batch_info;
              RETURN;
          --}
          END IF;
          CLOSE c_batch_info;
          --
	  IF l_debug_on THEN
              WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_PICKING_BATCHES_PKG.INSERT_ROW',WSH_DEBUG_SV.C_PROC_LEVEL);
          END IF;
          --
          WSH_PICKING_BATCHES_PKG.Insert_Row(
          X_Rowid   => l_rowid,
          X_Batch_Id     => l_batch_id,
          P_Creation_Date => NULL,
          P_Created_By   => NULL,
          P_Last_Update_Date   => NULL,
          P_Last_Updated_By  => NULL,
          P_Last_Update_Login  => NULL,
          X_Name     => l_batch_name,
          P_Backorders_Only_Flag   => 'M',  -- consider only replenishment completed delivery detail lines.
          P_Document_Set_Id  => l_batch_rec.Document_Set_Id,
          P_Existing_Rsvs_Only_Flag => l_batch_rec.Existing_Rsvs_Only_Flag,
          P_Shipment_Priority_Code   => NULL,
          P_Ship_Method_Code   => NULL,
          P_Customer_Id => NULL,
          P_Order_Header_Id  => l_batch_rec.Order_Header_Id,
          P_Ship_Set_Number  => NULL,
          P_Inventory_Item_Id  => NULL,
          P_Order_Type_Id => l_batch_rec.Order_Type_Id,
          P_From_Requested_Date   => NULL,
          P_To_Requested_Date  => NULL,
          P_From_Scheduled_Ship_Date   => NULL,
          P_To_Scheduled_Ship_Date   => NULL,
          P_Ship_To_Location_Id   => NULL,
          P_Ship_From_Location_Id   => NULL,
          P_Trip_Id => NULL,
          P_Delivery_Id  => NULL,
          P_Include_Planned_Lines   => 'Y',   -- Bug 6908504 (replenishment
-- project): Replenishment Completed dd's may be associated to deliveries.
          P_Pick_Grouping_Rule_Id   => l_batch_rec.Pick_Grouping_Rule_Id,
          P_pick_sequence_rule_id   => l_batch_rec.pick_sequence_rule_id,
          P_Autocreate_Delivery_Flag   => l_batch_rec.Autocreate_Delivery_Flag,
          P_Attribute_Category   => l_batch_rec.Attribute_Category,
          P_Attribute1   => l_batch_rec.Attribute1,
          P_Attribute2   => l_batch_rec.Attribute2,
          P_Attribute3   => l_batch_rec.Attribute3,
          P_Attribute4   => l_batch_rec.Attribute4,
          P_Attribute5   => l_batch_rec.Attribute5,
          P_Attribute6   => l_batch_rec.Attribute6,
          P_Attribute7   => l_batch_rec.Attribute7,
          P_Attribute8   => l_batch_rec.Attribute8,
          P_Attribute9   => l_batch_rec.Attribute9,
          P_Attribute10 => l_batch_rec.Attribute10,
          P_Attribute11 => l_batch_rec.Attribute11,
          P_Attribute12 => l_batch_rec.Attribute12,
          P_Attribute13 => l_batch_rec.Attribute13,
          P_Attribute14 => l_batch_rec.Attribute14,
          P_Attribute15 => l_batch_rec.Attribute15,
          P_Autodetail_Pr_Flag   => l_batch_rec.Autodetail_Pr_Flag,
          P_Carrier_Id   => NULL,
          P_Trip_Stop_Id   => NULL,
          P_Default_stage_subinventory => l_batch_rec.Default_stage_subinventory,
          P_Default_stage_locator_id   => l_batch_rec.Default_stage_locator_id,
          P_Pick_from_subinventory   => l_batch_rec.Pick_from_subinventory,
          P_Pick_from_locator_id   => l_batch_rec.Pick_from_locator_id ,
          P_Auto_pick_confirm_flag   => l_batch_rec.Auto_pick_confirm_flag,
          P_Delivery_Detail_ID   => -1,
          P_Project_ID   => NULL,
          P_Task_ID => NULL,
          P_Organization_Id  => l_batch_rec.Organization_Id,
          P_Ship_Confirm_Rule_Id   => l_batch_rec.ship_confirm_rule_id,
          P_Autopack_Flag => l_batch_rec.autopack_flag,
          P_Autopack_Level   => l_batch_rec.autopack_level,
          P_TASK_PLANNING_FLAG   => l_batch_rec.task_planning_flag,
          P_Non_Picking_Flag   => l_batch_rec.non_picking_flag,
	  /* Enhancement */
	  p_RegionID	=> NULL,
	  p_ZoneID	=> NULL,
	  p_categoryID	=> NULL,
          p_categorySetID => NULL,
          p_acDelivCriteria => l_batch_rec.ac_Delivery_Criteria,
	  p_RelSubinventory => NULL,
	  -- deliveryMerge
	  p_append_flag => l_batch_rec.append_flag,
          p_task_priority => l_batch_rec.task_priority,
          p_actual_departure_date => l_batch_rec.actual_departure_date,
          p_allocation_method => l_batch_rec.allocation_method,
          p_crossdock_criteria_id => l_batch_rec.crossdock_criteria_id,
	  P_dynamic_replenishment_flag => l_batch_rec.dynamic_replenishment_flag,
          p_selected_batch_id          => p_batch_id,  --Bug# 8492625  :Need to store the original picking batch id value.
          p_client_id              => l_batch_rec.client_id -- LSP PROJECT
           );
          --
      ELSE
          --
          --
          IF l_debug_on THEN
              WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_PICKING_BATCHES_PKG.INSERT_ROW',WSH_DEBUG_SV.C_PROC_LEVEL);
          END IF;
          --
          WSH_PICKING_BATCHES_PKG.Insert_Row(
          X_Rowid   => l_rowid,
          X_Batch_Id     => l_batch_id,
          P_Creation_Date => NULL,
          P_Created_By   => NULL,
          P_Last_Update_Date   => NULL,
          P_Last_Updated_By  => NULL,
          P_Last_Update_Login  => NULL,
          X_Name     => l_batch_name,
          P_Backorders_Only_Flag   => 'I',
          P_Document_Set_Id  => NULL,
          P_Existing_Rsvs_Only_Flag => NULL,
          P_Shipment_Priority_Code   => NULL,
          P_Ship_Method_Code   => NULL,
          P_Customer_Id => NULL,
          P_Order_Header_Id  => NULL,
          P_Ship_Set_Number  => NULL,
          P_Inventory_Item_Id  => NULL,
          P_Order_Type_Id => NULL,
          P_From_Requested_Date   => NULL,
          P_To_Requested_Date  => NULL,
          P_From_Scheduled_Ship_Date   => NULL,
          P_To_Scheduled_Ship_Date   => NULL,
          P_Ship_To_Location_Id   => NULL,
          P_Ship_From_Location_Id   => NULL,
          P_Trip_Id => l_trip_id,
          P_Delivery_Id  => l_delivery_id,
          P_Include_Planned_Lines   => 'Y',
          P_Pick_Grouping_Rule_Id   => NULL,
          P_pick_sequence_rule_id   => NULL,
          P_Autocreate_Delivery_Flag   => NULL,
          P_Attribute_Category   => NULL,
          P_Attribute1   => NULL,
          P_Attribute2   => NULL,
          P_Attribute3   => NULL,
          P_Attribute4   => NULL,
          P_Attribute5   => NULL,
          P_Attribute6   => NULL,
          P_Attribute7   => NULL,
          P_Attribute8   => NULL,
          P_Attribute9   => NULL,
          P_Attribute10 => NULL,
          P_Attribute11 => NULL,
          P_Attribute12 => NULL,
          P_Attribute13 => NULL,
          P_Attribute14 => NULL,
          P_Attribute15 => NULL,
          P_Autodetail_Pr_Flag   => NULL,
          P_Carrier_Id   => NULL,
          P_Trip_Stop_Id   => l_stop_id,
          P_Default_stage_subinventory => NULL,
          P_Default_stage_locator_id   => NULL,
          P_Pick_from_subinventory   => NULL,
          P_Pick_from_locator_id   => NULL,
          P_Auto_pick_confirm_flag   => NULL,
          P_Delivery_Detail_ID   => l_detail_id,
          P_Project_ID   => NULL,
          P_Task_ID => NULL,
          P_Organization_Id  => NULL,
          P_Ship_Confirm_Rule_Id   => l_ship_confirm_rule_id,
          P_Autopack_Flag => l_autopack_flag,
          P_Autopack_Level   => l_autopack_level,
          P_TASK_PLANNING_FLAG   => l_task_planning_flag,
          P_Non_Picking_Flag   => l_Non_Picking_Flag,
	  /* Enhancement */
	  p_RegionID	=> NULL,
	  p_ZoneID	=> NULL,
	  p_categoryID	=> NULL,
          p_categorySetID => NULL,
          p_acDelivCriteria => NULL,
	  p_RelSubinventory => NULL,
	  -- deliveryMerge
	  p_append_flag => 'N',
          p_task_priority => NULL,
          p_actual_departure_date => NULL,
          p_allocation_method => 'I', --X-dock
          p_crossdock_criteria_id => NULL, -- X-dock
          p_client_id             => NULL -- LSP PROJECT
          );
      --}
      END IF;
      --bug# 6719369 (replenishment project): end

      IF p_detail_ids.count > 0 THEN
            --Update the detail lines with batch id.
            FORALL i in 1..p_detail_ids.count
            update wsh_delivery_details
            set batch_id = l_batch_id
            where released_status in ('R', 'B', 'X')
            and   nvl(replenishment_status,'C') = 'C'  --bug# 6719369 (replenishment project)
            and delivery_detail_id = p_detail_ids(i);

            IF sql%notfound then
	       l_detail_id := p_detail_ids(1); --Bug#: 2870731
               IF l_debug_on THEN
                 for i in 1..p_detail_ids.count loop
                    WSH_DEBUG_SV.logmsg(l_module_name,'Unreleased delivery_detail -> '||p_detail_ids(i),WSH_DEBUG_SV.C_PROC_LEVEL);
                 end loop;
               END IF;
               RAISE INVALID_RELEASED_STATUS;
            END IF;

            IF l_debug_on THEN
               for i in 1..p_detail_ids.count loop
                  WSH_DEBUG_SV.logmsg(l_module_name,'updating delivery_detail '||p_detail_ids(i) ||' with batch '||l_batch_id,WSH_DEBUG_SV.C_PROC_LEVEL);
               end loop;

            END IF;

            IF p_auto_pack_ship in ('SC', 'PS') THEN
               OPEN check_detail_for_SC (l_batch_id);
               LOOP

                FETCH check_detail_for_SC into  l_warn_org, l_ship_confirm_rule_id,
                                                l_autocreate_del_flag, l_pickconfirm_required;
                EXIT when check_detail_for_SC%NOTFOUND;
                l_org_name := WSH_UTIL_CORE.Get_Org_Name(l_warn_org);
                -- set warning for org
                IF l_ship_confirm_rule_id IS NULL THEN
                  FND_MESSAGE.SET_NAME('WSH','WSH_NO_SC_RULE_FOR_ORG');
                  FND_MESSAGE.SET_TOKEN('ORG_NAME',l_org_name);
                  x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
                  WSH_UTIL_CORE.Add_Message(x_return_status);
                  l_num_warn := l_num_warn + 1;
                END IF;
                IF NVL(l_pickconfirm_required,0) <> 2 THEN
                  FND_MESSAGE.SET_NAME('WSH','WSH_NO_AUTOPICK_FOR_ORG');
                  FND_MESSAGE.SET_TOKEN('ORG_NAME',l_org_name);
                  x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
                  WSH_UTIL_CORE.Add_Message(x_return_status);
                  l_num_warn := l_num_warn + 1;
                END IF;
                IF NVL(l_autocreate_del_flag, 'N') <> 'Y' THEN
                  OPEN check_unassigned_dels(l_warn_org, l_batch_id);
                  FETCH check_unassigned_dels INTO l_assigned;
                  IF check_unassigned_dels%FOUND THEN
                     FND_MESSAGE.SET_NAME('WSH','WSH_NO_DELS_FOR_ORG');
                     FND_MESSAGE.SET_TOKEN('ORG_NAME',l_org_name);
                     x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
                     WSH_UTIL_CORE.Add_Message(x_return_status);
                     l_num_warn := l_num_warn + 1;
                   END IF;
                   CLOSE check_unassigned_dels;
                 END IF;
               END LOOP;
               IF check_detail_for_SC%isopen THEN
                 CLOSE check_detail_for_SC;
               END IF;
            END IF;
            IF p_auto_pack_ship = 'PS' THEN
               OPEN check_detail_for_AP (l_batch_id);
               LOOP
                 FETCH check_detail_for_AP into l_warn_org;
                 EXIT when check_detail_for_AP%NOTFOUND;
                 -- set message for org
                 l_org_name := WSH_UTIL_CORE.Get_Org_Name(l_warn_org);
                 FND_MESSAGE.SET_NAME('WSH','WSH_NO_AP_LEVEL_FOR_ORG');
                 FND_MESSAGE.SET_TOKEN('ORG_NAME',l_org_name);
                 x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
                 WSH_UTIL_CORE.Add_Message(x_return_status);
                 l_num_warn := l_num_warn + 1;
               END LOOP;
               IF check_detail_for_AP%isopen THEN
                 CLOSE check_detail_for_AP;
               END IF;
            END IF;
      END IF;


      IF l_debug_on THEN
         WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_PICKING_BATCHES_PKG.SUBMIT_RELEASE_REQUEST',WSH_DEBUG_SV.C_PROC_LEVEL);
      END IF;
      --Submit request to release batch created.
      x_request_ids(l_index) := WSH_PICKING_BATCHES_PKG.Submit_Release_Request(
                                                                               p_batch_id    =>  l_batch_id,
                                                                               p_log_level   =>  l_log_level,
                                                                               p_num_workers =>  1, -- Always 1
                                                                               p_commit      =>  'N');
      IF (x_request_ids(l_index) = 0) THEN
         x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
         FND_MESSAGE.SET_NAME('WSH','WSH_PR_LAUNCH_FAILED');
         FND_MESSAGE.SET_TOKEN('RELEASE_TYPE',l_type);
         FND_MESSAGE.SET_TOKEN('NAME',l_name);
         WSH_UTIL_CORE.Add_Message(x_return_status);
         l_count_fail := l_count_fail + 1;
      ELSE
         x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;
         FND_MESSAGE.SET_NAME('WSH','WSH_PR_LAUNCH_SUCCESS');
        --change for Bug#3379553
        -- FND_MESSAGE.SET_TOKEN('RELEASE_TYPE',l_type);
        -- FND_MESSAGE.SET_TOKEN('NAME',l_name);
        --End of change for Bug#3379553
         FND_MESSAGE.SET_TOKEN('REQUEST_ID', to_char(x_request_ids(l_index)));
         WSH_UTIL_CORE.Add_Message(x_return_status);
         l_count_succ := l_count_succ + 1;
      END IF;

      IF l_trip_id IS NOT NULL THEN
         EXIT WHEN l_index = p_trip_ids.LAST;
         l_index := p_trip_ids.NEXT(l_index);
         l_trip_id := p_trip_ids(l_index);
         --
         IF l_debug_on THEN
           WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_TRIPS_PVT.GET_NAME',WSH_DEBUG_SV.C_PROC_LEVEL);
         END IF;
            --
            l_name := WSH_TRIPS_PVT.Get_Name(l_trip_id);
      ELSIF l_stop_id IS NOT NULL THEN
            EXIT WHEN l_index = p_stop_ids.LAST;
            l_index := p_stop_ids.NEXT(l_index);
            l_stop_id := p_stop_ids(l_index);
            --
            IF l_debug_on THEN
              WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_TRIP_STOPS_PVT.GET_NAME',WSH_DEBUG_SV.C_PROC_LEVEL);
            END IF;
            --
            l_name := WSH_TRIP_STOPS_PVT.Get_Name(l_stop_id);
      ELSIF l_delivery_id IS NOT NULL THEN
            EXIT WHEN l_index = p_delivery_ids.LAST;
            l_index := p_delivery_ids.NEXT(l_index);
            l_delivery_id := p_delivery_ids(l_index);
            --
            IF l_debug_on THEN
              WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_NEW_DELIVERIES_PVT.GET_NAME',WSH_DEBUG_SV.C_PROC_LEVEL);
            END IF;
            --
            l_name := WSH_NEW_DELIVERIES_PVT.Get_Name(l_delivery_id);
      ELSE
            EXIT;  -- Only one loop when launching pick release for delivery details.
      END IF;

   --}
   END LOOP;

   IF l_count_fail > 0 THEN
      x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
   END IF;



   -- Summary message
   FND_MESSAGE.SET_NAME('WSH','WSH_PR_LAUNCH_SUMMARY');
   FND_MESSAGE.SET_TOKEN('SUCCESS',to_char(l_count_succ));
   FND_MESSAGE.SET_TOKEN('FAIL',to_char(l_count_fail));
   WSH_UTIL_CORE.Add_Message(x_return_status);

   IF ((l_num_warn > 0) and (x_return_status = WSH_UTIL_CORE.G_RET_STS_SUCCESS)) THEN

      x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
      FND_MESSAGE.SET_NAME('WSH','WSH_QS_LAUNCH_SUMMARY');
      WSH_UTIL_CORE.Add_Message(x_return_status);

   END IF;
   --
   IF l_debug_on THEN
     WSH_DEBUG_SV.pop(l_module_name);
   END IF;
   --
EXCEPTION
    --OTM R12
    WHEN api_return_fail THEN
      x_return_status := l_return_status;
      IF l_debug_on THEN
        WSH_DEBUG_SV.log(l_module_name, 'x_return_status', x_return_status);
        WSH_DEBUG_SV.pop(l_module_name);
      END IF;
    --END OTM R12

    WHEN INVALID_RELEASED_STATUS THEN
          --OTM R12
          IF (c_is_detail_assigned%ISOPEN) THEN
            CLOSE c_is_detail_assigned;
          END IF;
          --

          x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
          FND_MESSAGE.SET_NAME('WSH','WSH_PR_INVALID_DETAIL');
          FND_MESSAGE.SET_TOKEN('detail',to_char(l_detail_id));
          WSH_UTIL_CORE.Add_Message(x_return_status);
          --
          -- Debug Statements
          --
          IF l_debug_on THEN
          WSH_DEBUG_SV.logmsg(l_module_name,'INVALID_RELEASED_STATUS exception has occured.',WSH_DEBUG_SV.C_EXCEP_LEVEL);
          WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:INVALID_RELEASED_STATUS');
          END IF;
          --
          return;

    WHEN INVALID_ENTITY_STATUS THEN
          --OTM R12
          IF (c_is_detail_assigned%ISOPEN) THEN
            CLOSE c_is_detail_assigned;
          END IF;
          --

          x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
          FND_MESSAGE.SET_NAME('WSH','WSH_PR_INVALID_ENTITY');
          FND_MESSAGE.SET_TOKEN('entity_type',lower(l_type));
          IF l_type = 'Trip' THEN
             l_entity_id := l_trip_id;
          ELSIF l_type = 'Stop' THEN
             l_entity_id := l_stop_id;
          ELSIF l_type = 'Delivery' THEN
             l_entity_id := l_delivery_id;
          END IF;
          FND_MESSAGE.SET_TOKEN('entity_id',l_entity_id);
          WSH_UTIL_CORE.Add_Message(x_return_status);
          --
          -- Debug Statements
          --
          IF l_debug_on THEN
             WSH_DEBUG_SV.logmsg(l_module_name,'INVALID_ENTITY_STATUS exception has occured.',WSH_DEBUG_SV.C_EXCEP_LEVEL);
             WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:INVALID_ENTITY_STATUS');
          END IF;
          --
          return;

    WHEN Others THEN
         --OTM R12
         IF (c_is_detail_assigned%ISOPEN) THEN
           CLOSE c_is_detail_assigned;
         END IF;
         --

         WSH_UTIL_CORE.Default_Handler('WSH_PICK_LIST.Launch_Pick_Release');
         x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
         IF check_detail_for_SC%ISOPEN THEN
            CLOSE check_detail_for_SC;
         END IF;
         IF check_detail_for_AP%ISOPEN THEN
            CLOSE check_detail_for_AP;
         END IF;
         IF get_container%ISOPEN THEN
          CLOSE get_container;
         END IF;
         IF pick_confirm_required_for_del%ISOPEN THEN
            CLOSE pick_confirm_required_for_del;
         END IF;
         IF check_unassigned_dels%ISOPEN THEN
          CLOSE check_unassigned_dels;
         END IF;
         --
         -- Debug Statements
         --
         IF l_debug_on THEN
         WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '|| SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
         WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
         END IF;
         --
END Launch_Pick_Release;

-- Start of comments
-- API name : Calculate_Reservations
-- Type     : Public
-- Pre-reqs : None.
-- Procedure: API to calculate the Reservations quantity, api does
--            1. Scan through global demand table and find out if reservation exists for input header and line.
--            2. If not fetch the reservation from inventory reservation table.
--            3. Calculate the reservation quantity (Primary and Secondary).
-- Parameters :
-- IN:
--      p_demand_source_header_id        IN  Demand hedaer id.
--      p_demand_source_line_id          IN  Demand line id.
--      p_requested_quantity             IN  Requested Quantity.
--      p_requested_quantity_uom         IN  Requested Quantity UOM.
--      p_src_requested_quantity_uom     IN  Source Requested Quantity UOM.
--      p_src_requested_quantity         IN  Source Requested Quantity.
--      p_src_requested_quantity2        IN  Source Secondary Requested Quantity.
--      p_inv_item_id                    IN  Item Id.
--      p_requested_quantity2            IN  Secondary Requested Quantity.
--      p_caller                         IN  Caller (WMS or NULL)
-- OUT:
--      x_fulfill_base  OUT NOCOPY Fulfillment Base.
--      x_result        OUT NOCOPY Reservations quantity.
--      x_result2       OUT NOCOPY Secondary Reservations quantity.
-- End of comments
-- HW OPMCONV - Added parameter p_requested_quantity2
--Bug 4775539 added four IN parameters

PROCEDURE Calculate_Reservations(
    p_demand_source_header_id IN NUMBER,
    p_demand_source_line_id   IN NUMBER,
    p_requested_quantity IN NUMBER,
    -- Bug 4775539
    p_requested_quantity_uom     IN VARCHAR2,
    p_src_requested_quantity_uom IN VARCHAR2,
    p_src_requested_quantity     IN NUMBER,
    -- muom
    p_src_requested_quantity2    IN NUMBER,
    p_inv_item_id                IN NUMBER,
    p_requested_quantity2 IN NUMBER default NULL,
    p_caller              IN VARCHAR2 default NULL,
    -- muom
    x_fulfill_base OUT NOCOPY VARCHAR2,
    x_result  OUT NOCOPY  NUMBER,
    x_result2 OUT NOCOPY  NUMBER) IS

   --Cursor to get the reservation quantity from inventory table.
   CURSOR reservation_quantity(c_demand_source_header_id IN NUMBER,
			       c_demand_source_line_id IN NUMBER) is
-- HW OPMCONV - Added qty2
   SELECT  SUM(mr.primary_reservation_quantity - nvl(mr.detailed_quantity,0)),
          SUM(mr.SECONDARY_RESERVATION_QUANTITY - nvl(mr.SECONDARY_DETAILED_QUANTITY,0))
   FROM   mtl_reservations mr
   WHERE  mr.demand_source_header_id = c_demand_source_header_id
   AND mr.demand_source_line_id   = c_demand_source_line_id
   AND nvl(mr.subinventory_code, nvl(WSH_PR_CRITERIA.g_from_subinventory,'-99')) = nvl(WSH_PR_CRITERIA.g_from_subinventory,nvl(mr.subinventory_code,'-99'))
   AND nvl(mr.locator_id, nvl(WSH_PR_CRITERIA.g_from_locator,'-99')) = nvl(WSH_PR_CRITERIA.g_from_locator,nvl(mr.locator_id,-99))
   AND nvl(mr.staged_flag, 'N') <> 'Y'
   AND mr.primary_reservation_quantity - nvl(mr.detailed_quantity,0) > 0
   AND mr.demand_source_type_id IN (2,8) -- Bug 4046748
   AND mr.supply_source_type_id = 13; -- Bug 4046748;

   -- Bug 4775539
   CURSOR discard_reservation_quantity(
            c_demand_source_header_id IN NUMBER,
	    c_demand_source_line_id IN NUMBER) is
   SELECT SUM(mr.primary_reservation_quantity - nvl(mr.detailed_quantity,0)),
          SUM(mr.SECONDARY_RESERVATION_QUANTITY - nvl(mr.SECONDARY_DETAILED_QUANTITY,0))
   FROM   mtl_reservations mr
   WHERE  mr.demand_source_header_id = c_demand_source_header_id
   AND    mr.demand_source_line_id   = c_demand_source_line_id
   AND ((nvl(mr.staged_flag, 'N') <> 'Y'
        AND (nvl(mr.subinventory_code, nvl(WSH_PR_CRITERIA.g_from_subinventory,'-99')) <> nvl(WSH_PR_CRITERIA.g_from_subinventory,nvl(mr.subinventory_code,'-99'))
             OR  nvl(mr.locator_id, nvl(WSH_PR_CRITERIA.g_from_locator,-99)) <> nvl(WSH_PR_CRITERIA.g_from_locator,nvl(mr.locator_id,-99))))
      OR (nvl(mr.staged_flag, 'N') = 'Y'))
   AND mr.primary_reservation_quantity - nvl(mr.detailed_quantity,0) > 0
   AND mr.demand_source_type_id IN (2,8)
   AND mr.supply_source_type_id = 13;

   l_total_requested_quantity number;
   --Variable added for bug 6459193
   l_unallocated_quantity     number;

   l_demand_exists BOOLEAN;
   l_reservation_quantity NUMBER := 0;
-- HW OPMCONV - Added qty2
   l_reservation_quantity2 NUMBER := 0;
   --
   l_debug_on BOOLEAN;
   l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'CALCULATE_RESERVATIONS';
   --
   l_hash_string      VARCHAR2(1000) := NULL;
   l_hash_value       NUMBER;
   l_hash_exists      BOOLEAN;
   -- muom
   l_fulfill_base     varchar2(1);
   l_total_requested_quantity2 number;
   l_unallocated_quantity2 number;

BEGIN
   --
   l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
   --
   IF l_debug_on IS NULL THEN
     l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
   END IF;
   --
   IF l_debug_on THEN
      WSH_DEBUG_SV.push(l_module_name);
      WSH_DEBUG_SV.log(l_module_name,'P_DEMAND_SOURCE_HEADER_ID',P_DEMAND_SOURCE_HEADER_ID);
      WSH_DEBUG_SV.log(l_module_name,'P_DEMAND_SOURCE_LINE_ID',P_DEMAND_SOURCE_LINE_ID);
      WSH_DEBUG_SV.log(l_module_name,'P_REQUESTED_QUANTITY',P_REQUESTED_QUANTITY);
-- HW OPMCONV - Added requested_qty2
      WSH_DEBUG_SV.log(l_module_name,'P_REQUESTED_QUANTITY2',P_REQUESTED_QUANTITY2);
      -- Bug 4775539
      WSH_DEBUG_SV.log(l_module_name,'P_REQUESTED_QUANTITY_UOM',P_REQUESTED_QUANTITY_UOM);
      WSH_DEBUG_SV.log(l_module_name,'P_SRC_REQUESTED_QUANTITY_UOM',P_SRC_REQUESTED_QUANTITY_UOM);
      WSH_DEBUG_SV.log(l_module_name,'P_SRC_REQUESTED_QUANTITY',P_SRC_REQUESTED_QUANTITY);
      -- muom
      WSH_DEBUG_SV.log(l_module_name,'P_SRC_REQUESTED_QUANTITY2',P_SRC_REQUESTED_QUANTITY2);
      WSH_DEBUG_SV.log(l_module_name,'P_CALLER',P_CALLER);
      WSH_DEBUG_SV.log(l_module_name,'P_INV_ITEM_ID',P_INV_ITEM_ID);
   END IF;
   --
   l_demand_exists := FALSE;
   l_hash_exists   := FALSE;
   --
   -- muom
   IF WSH_UTIL_CORE.Get_Line_Fulfillment_Base('OE', p_demand_source_line_id) = 'S' THEN
     l_fulfill_base := 'S';
   ELSE
     l_fulfill_base := 'P';
   END IF;
   x_fulfill_base := l_fulfill_base;
   --
   l_hash_string := to_char(p_demand_source_header_id)||'-'||to_char(p_demand_source_line_id) ;
   IF WSH_PR_CRITERIA.g_from_subinventory IS NOT NULL THEN
      l_hash_string := l_hash_string ||'-'|| WSH_PR_CRITERIA.g_from_subinventory;
   END IF;
   IF WSH_PR_CRITERIA.g_from_locator IS NOT NULL THEN
      l_hash_string := l_hash_string ||'-'|| to_char(WSH_PR_CRITERIA.g_from_locator);
   END IF;
   -- Generating new hash values
   l_hash_value := dbms_utility.get_hash_value (
                                                 name => l_hash_string,
                                                 base => g_hash_base,
                                                 hash_size => g_hash_size );

   IF l_debug_on THEN
      WSH_DEBUG_SV.logmsg(l_module_name, 'L_HASH_STRING :'||l_hash_string||' , L_HASH_VALUE :'||l_hash_value);
   END IF;

   --Scan through global demand table and find out if reservation exists for input header and line.
   WHILE NOT l_hash_exists LOOP
     IF g_demand_table.EXISTS(l_hash_value) THEN
        IF ((g_demand_table(l_hash_value).demand_source_header_id = p_demand_source_header_id) AND
            (g_demand_table(l_hash_value).demand_source_line_id = p_demand_source_line_id  ) AND
            (nvl(g_demand_table(l_hash_value).subinventory_code,'-99') = nvl(WSH_PR_CRITERIA.g_from_subinventory,'-99')) AND
            (nvl(g_demand_table(l_hash_value).locator_id,-99) = nvl(WSH_PR_CRITERIA.g_from_locator,-99))) THEN
           l_demand_exists := TRUE;
           --
           IF l_debug_on THEN
              WSH_DEBUG_SV.logmsg(l_module_name,  'FOUND THE RESERVATION DETAILS'  );
              WSH_DEBUG_SV.log(l_module_name,'L_HASH_VALUE',L_HASH_VALUE);
           END IF;
           --
           EXIT;
        ELSE
           -- Hash value exists but attributes do not match
           -- Increment the hash value and check again
           l_hash_value := l_hash_value + 1;
        END IF;
     ELSE
        -- Hash value does not exist, so this is a new hash value
        l_hash_exists := TRUE;
        IF l_debug_on THEN
           WSH_DEBUG_SV.log(l_module_name,'L_HASH_VALUE',L_HASH_VALUE);
        END IF;
     END IF;
   END LOOP;
   --

   IF (not l_demand_exists) THEN --{
   -- Bug 4775539
      IF (WSH_PR_CRITERIA.g_existing_rsvs_only_flag = 'Y') THEN
      --Get the reservation details for header and line.
      IF l_debug_on THEN
         WSH_DEBUG_SV.logmsg(l_module_name,  'FETCHING RESERVATION DETAILS'  );
      END IF;
      --
      OPEN  reservation_quantity(p_demand_source_header_id, p_demand_source_line_id);
      FETCH reservation_quantity
-- HW OPMCONV -Added qty2
      INTO  l_reservation_quantity, l_reservation_quantity2;
      CLOSE reservation_quantity;

      IF (l_reservation_quantity IS NULL) THEN
         l_reservation_quantity := 0;
-- HW OPMCONV - Added qty2
         l_reservation_quantity2 := 0;
      END IF;

       -- Bug 4775539

        --Start of fix for bug 6459193
        IF ( l_reservation_quantity > 0 ) THEN
           SELECT sum(wdd.requested_quantity)
                  -- muom
                  ,sum(wdd.requested_quantity2)
           INTO   l_unallocated_quantity
                  -- muom
                  ,l_unallocated_quantity2
           FROM   wsh_delivery_details wdd
           WHERE  wdd.released_status = 'S'
           AND    wdd.source_code = 'OE'
           AND    wdd.source_line_id = p_demand_source_line_id
           AND    NOT EXISTS
                ( SELECT 'X'
                  FROM   mtl_material_transactions_temp mmtt
                  WHERE  mmtt.move_order_line_id = wdd.move_order_line_id );

           --
           IF l_debug_on THEN
              -- muom
              WSH_DEBUG_SV.logmsg(l_module_name,  'RESERVATION QUANTITY '||l_reservation_quantity||' RESERVATION QUANTITY2 '||l_reservation_quantity2 );
              WSH_DEBUG_SV.logmsg(l_module_name,  'UNALLOCATED QUANTITY '||l_unallocated_quantity||' UNALLOCATED QUANTITY2 '||l_unallocated_quantity2 );
           END IF;
           --
           l_reservation_quantity := l_reservation_quantity - nvl(l_unallocated_quantity, 0);
           --To Make sure that reservation quantity is NOT less than Zero
           IF ( l_reservation_quantity < 0 ) THEN
              l_reservation_quantity := 0;
           END IF;
           -- muom
           l_reservation_quantity2 := l_reservation_quantity2 - nvl(l_unallocated_quantity2, 0);
           IF ( l_reservation_quantity2 < 0 ) THEN
              l_reservation_quantity2 := 0;
           END IF;
        END IF;
        --End of fix for bug 6459193
      ELSE

        IF p_requested_quantity_uom <> p_src_requested_quantity_uom THEN
          l_total_requested_quantity :=
             WSH_WV_UTILS.Convert_UOM(
	       From_uom => p_src_requested_quantity_uom,
	       To_uom   => p_requested_quantity_uom,
	       Quantity => p_src_requested_quantity,
	       Item_id  => p_inv_item_id);
        ELSE
          l_total_requested_quantity := round(p_src_requested_quantity,WSH_UTIL_CORE.C_MAX_DECIMAL_DIGITS_INV); --Bugfix 8557457
        END IF;
        -- muom
        l_total_requested_quantity2 := p_src_requested_quantity2;

        IF l_debug_on THEN --Bugfix 8557457
           WSH_DEBUG_SV.logmsg(l_module_name,'L_TOTAL_REQUESTED_QUANTITY '||l_total_requested_quantity);
        END IF;


        --Get the other reservation details for header and line.
        IF l_debug_on THEN
           WSH_DEBUG_SV.logmsg(l_module_name,  'FETCHING OTHER RESERVATION DETAILS'  );
           WSH_DEBUG_SV.logmsg(l_module_name,  'WSH_PR_CRITERIA.g_from_subinventory '||WSH_PR_CRITERIA.g_from_subinventory);
           WSH_DEBUG_SV.logmsg(l_module_name,  'WSH_PR_CRITERIA.g_from_locator '||WSH_PR_CRITERIA.g_from_locator);
        END IF;
        --
        OPEN  discard_reservation_quantity(p_demand_source_header_id, p_demand_source_line_id);
        FETCH discard_reservation_quantity
        INTO  l_reservation_quantity,l_reservation_quantity2;
        CLOSE discard_reservation_quantity;

        -- muom
        IF (l_fulfill_base = 'P' and l_reservation_quantity IS NULL) OR (l_fulfill_base = 'S' and l_reservation_quantity2 IS NULL) THEN
           l_reservation_quantity := 0;
	    l_reservation_quantity2 := 0;
        END IF;
               l_reservation_quantity := l_total_requested_quantity - l_reservation_quantity;
               -- muom
               l_reservation_quantity2 := l_total_requested_quantity2 - l_reservation_quantity2;
      END IF;
      --
      --Store reservation details in global demand table.
      g_demand_table(l_hash_value).demand_source_header_id := p_demand_source_header_id;
      g_demand_table(l_hash_value).demand_source_line_id   := p_demand_source_line_id;
      g_demand_table(l_hash_value).subinventory_code := WSH_PR_CRITERIA.g_from_subinventory;
      g_demand_table(l_hash_value).locator_id  := WSH_PR_CRITERIA.g_from_locator;
      g_demand_table(l_hash_value).reserved_quantity := l_reservation_quantity;
-- HW OPMCONV - Added qty2
      g_demand_table(l_hash_value).reserved_quantity2 := l_reservation_quantity2;
      --
      IF l_debug_on THEN
         WSH_DEBUG_SV.logmsg(l_module_name,  'RESERVED QTY AVAILABLE IS '||L_RESERVATION_QUANTITY  );
-- HW OPMCONV - print qty2
         WSH_DEBUG_SV.logmsg(l_module_name,  'RESERVED QTY2 AVAILABLE IS '||L_RESERVATION_QUANTITY2  );
      END IF;
      --
      IF (g_demand_table(l_hash_value).reserved_quantity < 0) THEN
         g_demand_table(l_hash_value).reserved_quantity := 0;
      END IF;
      -- muom
      IF (g_demand_table(l_hash_value).reserved_quantity2 < 0) THEN
         g_demand_table(l_hash_value).reserved_quantity2 := 0;
      END IF;
      --
   END IF; --}
   --
   -- muom
   IF p_caller = 'WMS' and l_fulfill_base = 'S' THEN
      /* Wave Planning is out of scope for Multi-UOM changes in WMS. Hence, WMS wants this api to calculate values based on primary fulfillment always */
      l_fulfill_base := 'P';
      IF l_debug_on THEN
         WSH_DEBUG_SV.logmsg(l_module_name,  'Call is from WMS Wave Planning. Temporarily changing fulfillment base to '||l_fulfill_base);
      END IF;
   END IF;

   IF (l_fulfill_base = 'P' and g_demand_table(l_hash_value).reserved_quantity = 0) OR (l_fulfill_base = 'S' and g_demand_table(l_hash_value).reserved_quantity2 = 0) THEN  --Bugfix 16663056
      x_result := 0;
-- HW OPMCONV - Added x_result2
      x_result2 := 0;
    ELSIF ((l_fulfill_base = 'P') and ((g_demand_table(l_hash_value).reserved_quantity > 0) AND (g_demand_table(l_hash_value).reserved_quantity < p_requested_quantity))) OR
          ((l_fulfill_base = 'S') and ((g_demand_table(l_hash_value).reserved_quantity2 > 0) AND (g_demand_table(l_hash_value).reserved_quantity2 < p_requested_quantity2))) THEN
      x_result := g_demand_table(l_hash_value).reserved_quantity;
      x_result2:= g_demand_table(l_hash_value).reserved_quantity2;
      g_demand_table(l_hash_value).reserved_quantity := 0;
      g_demand_table(l_hash_value).reserved_quantity2 := 0;
    ELSE
      x_result := p_requested_quantity;
-- HW OPMCONV - Added x_result2
      x_result2 := p_requested_quantity2;
      g_demand_table(l_hash_value).reserved_quantity := g_demand_table(l_hash_value).reserved_quantity - p_requested_quantity;
-- HW OPMCONV - Added qty2
      g_demand_table(l_hash_value).reserved_quantity2 := g_demand_table(l_hash_value).reserved_quantity2 - p_requested_quantity2;
   END IF;
   --
   IF l_debug_on THEN
      -- muom
      WSH_DEBUG_SV.logmsg(l_module_name,  'FULFILL BASE IS '||X_FULFILL_BASE  );
      WSH_DEBUG_SV.logmsg(l_module_name,  'RESERVED QTY AVAILABLE '||X_RESULT  );
-- HW OPMCONV - Print qty2
      WSH_DEBUG_SV.logmsg(l_module_name,  'RESERVED QTY2 AVAILABLE '||X_RESULT2  );
      WSH_DEBUG_SV.pop(l_module_name);
   END IF;
   --
   return;
   --
END Calculate_Reservations;

-- muom for Overloading (WMS)- Wave Planning
-- Start of comments
-- API name : Calculate_Reservations
-- Type     : Public
-- Pre-reqs : None.
-- Procedure: API to calculate the Reservations quantity, api does
--            1. Scan through global demand table and find out if reservation exists for input header and line.
--            2. If not fetch the reservation from inventory reservation table.
--            3. Calculate the reservation quantity (Primary and Secondary).
-- Parameters :
-- IN:
--      p_demand_source_header_id        IN  Demand hedaer id.
--      p_demand_source_line_id          IN  Demand line id.
--      p_requested_quantity             IN  Requested Quantity.
--      p_requested_quantity_uom         IN  Requested Quantity UOM.
--      p_src_requested_quantity_uom     IN  Source Requested Quantity UOM.
--      p_src_requested_quantity         IN  Source Requested Quantity.
--      p_inv_item_id                    IN  Item Id.
--      p_requested_quantity2            IN  Secondary Requested Quantity.
-- OUT:
--      x_result        OUT NOCOPY Reservations quantity.
--      x_result2       OUT NOCOPY Secondary Reservations quantity.
-- End of comments
PROCEDURE Calculate_Reservations(
    p_demand_source_header_id IN NUMBER,
    p_demand_source_line_id   IN NUMBER,
    p_requested_quantity IN NUMBER,
    -- Bug 4775539
    p_requested_quantity_uom     IN VARCHAR2,
    p_src_requested_quantity_uom IN VARCHAR2,
    p_src_requested_quantity     IN NUMBER,
    p_inv_item_id                IN NUMBER,
    p_requested_quantity2 IN NUMBER default NULL,
    x_result  OUT NOCOPY  NUMBER,
    x_result2 OUT NOCOPY  NUMBER) IS

   --
   l_debug_on BOOLEAN;
   l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'CALCULATE_RESERVATIONS1';
   --
   l_fulfill_base               varchar2(1):= NULL;
   l_src_requested_quantity2    NUMBER :=0;
   l_result                   NUMBER;
   l_result2                  NUMBER;

BEGIN
   --
   l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
   --
   IF l_debug_on IS NULL THEN
     l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
   END IF;
   --
   IF l_debug_on THEN
      WSH_DEBUG_SV.push(l_module_name);
      WSH_DEBUG_SV.log(l_module_name,'muom: P_DEMAND_SOURCE_HEADER_ID',P_DEMAND_SOURCE_HEADER_ID);
      WSH_DEBUG_SV.log(l_module_name,'P_DEMAND_SOURCE_LINE_ID',P_DEMAND_SOURCE_LINE_ID);
      WSH_DEBUG_SV.log(l_module_name,'P_REQUESTED_QUANTITY',P_REQUESTED_QUANTITY);
      WSH_DEBUG_SV.log(l_module_name,'P_REQUESTED_QUANTITY2',P_REQUESTED_QUANTITY2);
      WSH_DEBUG_SV.log(l_module_name,'P_REQUESTED_QUANTITY_UOM',P_REQUESTED_QUANTITY_UOM);
      WSH_DEBUG_SV.log(l_module_name,'P_SRC_REQUESTED_QUANTITY_UOM',P_SRC_REQUESTED_QUANTITY_UOM);
      WSH_DEBUG_SV.log(l_module_name,'P_SRC_REQUESTED_QUANTITY',P_SRC_REQUESTED_QUANTITY);
      WSH_DEBUG_SV.log(l_module_name,'P_INV_ITEM_ID',P_INV_ITEM_ID);
   END IF;
   --
   l_src_requested_quantity2    := 0;
   l_fulfill_base               := NULL;

   BEGIN
     SELECT src_requested_quantity2
     INTO   l_src_requested_quantity2
     FROM   wsh_delivery_details
     WHERE  source_code = 'OE'
     AND    source_line_id = p_demand_source_line_id
     AND    released_status <> 'D'
     AND    rownum = 1;
   EXCEPTION
     WHEN others then
       l_src_requested_quantity2 := 0;
   END;

   Calculate_Reservations(
                  p_demand_source_header_id    => p_demand_source_header_id,
                  p_demand_source_line_id      => p_demand_source_line_id,
                  p_requested_quantity         => p_requested_quantity,
                  p_requested_quantity_uom     => p_requested_quantity_uom,
                  p_src_requested_quantity_uom => p_src_requested_quantity_uom,
                  p_src_requested_quantity     => p_src_requested_quantity,
                  p_src_requested_quantity2    => l_src_requested_quantity2,
                  p_inv_item_id                => p_inv_item_id,
  		  p_requested_quantity2        => p_requested_quantity2,
                  p_caller                     => 'WMS',
                  x_fulfill_base               => l_fulfill_base,
		  x_result                     => l_result,
		  x_result2                    => l_result2);

   X_RESULT  := l_result;
   X_RESULT2 := l_result2;
   --
   IF l_debug_on THEN
      WSH_DEBUG_SV.logmsg(l_module_name,  'RESERVED QTY AVAILABLE '||l_result  );
      WSH_DEBUG_SV.logmsg(l_module_name,  'RESERVED QTY2 AVAILABLE '||l_result2  );
      WSH_DEBUG_SV.pop(l_module_name);
   END IF;
   --
   return;
   --
END Calculate_Reservations;

-- Start of comments
-- API name : CalcWorkingDay
-- Type     : Public
-- Pre-reqs : None.
-- Procedure: This procedure uses the shipping calendar to determine
--            the next (or) prior working day.  Used if the picking rule has dynamic date components.
-- Parameters :
-- IN:
--      p_orgID            IN  Organization Id.
--      p_days             IN  Days in Number 1-31.
--      p_Time             IN  Time.
--      p_CalCode          IN  Shipping Calender Code.
-- OUT:
--      x_date       OUT NOCOPY Working days date.
-- End of comments
PROCEDURE CalcWorkingDay(p_orgID 	IN NUMBER,
                         p_PickRule     IN VARCHAR2,
			 p_days 	IN NUMBER,
			 p_Time 	IN NUMBER,
                         p_CalCode 	IN VARCHAR2,
			 x_date 	IN OUT NOCOPY DATE) IS
   --
   v_Trials     NUMBER;
   j            NUMBER := 0;
   v_Err        NUMBER;
   v_Msg        VARCHAR2(100);
   v_WorkDay    BOOLEAN := FALSE;
   v_Date       DATE;
   v_Hrs        NUMBER;
   v_Min        NUMBER;
   v_Sec        NUMBER;
   v_TimeChar   VARCHAR2(10);
   v_DateChar   VARCHAR2(50);

    --Added in bug 7316707
    v_org_code   VARCHAR2(50);
    e_return EXCEPTION;

    CURSOR get_org_code (org_id IN NUMBER)
    IS
    SELECT organization_code
    FROM
      ORG_ORGANIZATION_DEFINITIONS
    WHERE organization_id = org_id;
    --bug 7316707 till here

   --
   l_debug_on	BOOLEAN;
   l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.CalcWorkingDay';

   --BUG# 13655114
   l_server_timezone varchar2(50);
   l_client_timezone varchar2(50);
   l_client_time DATE;
   --
BEGIN
  --
  l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
  --
  IF l_debug_on IS NULL
  THEN
    l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
  END IF;
  --
  IF l_debug_on THEN
    WSH_DEBUG_SV.push(l_module_name);
    WSH_DEBUG_SV.log(l_module_name, 'p_orgID', p_orgID);
    WSH_DEBUG_SV.log(l_module_name, 'p_calCode', p_calCode);
    WSH_DEBUG_SV.log(l_module_name, 'p_Time', p_Time);
    WSH_DEBUG_SV.log(l_module_name, 'p_days', p_days);
  END IF;
  --
  v_Hrs := TRUNC(p_Time / 3600);
  v_Min := TRUNC((p_Time - (v_Hrs * 3600))/60);
  v_Sec := p_Time - (v_Hrs * 3600) - (v_Min * 60);
  v_TimeChar := v_Hrs || ':' || v_Min || ':' || v_Sec;

  --BUG# 13655114
  l_server_timezone := fnd_timezones.get_server_timezone_code;
  l_client_timezone := fnd_timezones.get_client_timezone_code;
  l_client_time := fnd_timezone_pub.adjust_datetime (sysdate,l_server_timezone,l_client_timezone);
  --
  IF l_debug_on THEN
   WSH_DEBUG_SV.log(l_module_name, 'v_Hrs', v_Hrs);
   WSH_DEBUG_SV.log(l_module_name, 'v_Min', v_Min);
   WSH_DEBUG_SV.log(l_module_name, 'v_Sec', v_Sec);
   WSH_DEBUG_SV.log(l_module_name, 'v_TimeChar', v_TimeChar);
   wsh_debug_sv.log(l_module_name, 'l_server_timezone', l_server_timezone);
   wsh_debug_sv.log(l_module_name, 'l_client_timezoene', l_client_timezone);
   wsh_debug_sv.log(l_module_name, 'sysdate', sysdate);
   wsh_debug_sv.log(l_module_name, 'l_client_time', l_client_time);
  END IF;
  --
  -- Cannot apply calendar without knowing warehouse.
  -- So, just perform simple date arithmetic.
  --
  IF p_orgId IS NULL OR p_CalCode IS NULL THEN
      --BUG# 13655114
      v_DateChar := to_char((TRUNC(l_client_time) + p_Days), 'DD/MM/YYYY') || ' ' || v_TimeChar;
      v_Date := to_date(v_DateChar, 'DD/MM/YYYY HH24:MI:SS');
	  x_Date := fnd_timezone_pub.adjust_datetime (v_Date,l_client_timezone, l_server_timezone);

      --
      IF l_debug_on THEN
	    wsh_debug_sv.log(l_module_name, 'x_Date', x_Date);
        wsh_debug_sv.pop(l_module_name);
      END IF;
      --
      RETURN;
  END IF;
  --
  v_Trials := ABS(p_days);
  --BUG# 13655114
  v_DateChar := to_char(TRUNC(l_client_time), 'DD/MM/YYYY') || ' ' || v_TimeChar;
  v_Date   := to_date(v_DateChar, 'DD/MM/YYYY HH24:MI:SS');
  --
  IF l_debug_on THEN
   wsh_debug_sv.log(l_module_name, 'v_Trials', v_Trials);
   wsh_debug_sv.log(l_module_name, 'v_DateChar', v_DateChar);
   wsh_debug_sv.log(l_module_name, 'v_Date', v_Date);
  END IF;
  --
  WHILE j < v_Trials LOOP
   --
   IF p_Days < 0 THEN
    v_Date := v_Date - 1;
   ELSE
    v_Date := v_Date + 1;
   END IF;
   --
   BOM_CALENDAR_API_BK.Check_Working_Day(p_CalCode,v_Date, v_WorkDay,v_Err,v_Msg);
   --
   --bug 7316707 handle error returned by API
   IF v_Err = -1 THEN
   --{

        OPEN get_org_code(p_orgId);
        FETCH get_org_code
        INTO  v_org_code;
        CLOSE get_org_code;
        v_Date := null;
        FND_MESSAGE.SET_NAME('WSH','WSH_NO_CALENDAR_DATE');
        FND_MESSAGE.SET_TOKEN('NAME',p_PickRule);
        FND_MESSAGE.SET_TOKEN('CALENDAR',p_CalCode);
        FND_MESSAGE.SET_TOKEN('WAREHOUSE',v_org_code);
        wsh_util_core.add_message(WSH_UTIL_CORE.G_RET_STS_ERROR,l_module_name);
        RAISE e_return;
        EXIT;

   --}
   END IF;
   --bug 7316707 till here

   IF v_WorkDay THEN
      j := j + 1;
   END IF;
   --
  END LOOP;
  --
  --BUG# 13655114
  x_Date := fnd_timezone_pub.adjust_datetime (v_Date,l_client_timezone, l_server_timezone);
  --
  IF l_debug_on THEN
    wsh_debug_sv.log(l_module_name, 'x_Date', x_Date);
    wsh_debug_sv.pop(l_module_name);
  END IF;
  --
END CalcWorkingDay;
END WSH_PICK_LIST;