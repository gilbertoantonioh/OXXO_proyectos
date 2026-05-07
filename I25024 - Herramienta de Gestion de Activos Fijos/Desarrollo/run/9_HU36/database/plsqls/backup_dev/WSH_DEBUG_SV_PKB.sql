create or replace PACKAGE BODY WSH_DEBUG_SV as
/* $Header: WSHDEBGB.pls 120.2 2007/08/06 13:40:03 ueshanka noship $ */
/*==========================  WSH_core_sv  ============================*/

g_debug_flag BOOLEAN := FALSE;  -- used only by old debugger code.
g_RunMode	VARCHAR2(30);
--g_DebugMode	NUMBER;
g_DebugCount	NUMBER := 0;

--g_Debug		BOOLEAN := fnd_api.to_boolean(fnd_profile.value ('WSH_DEBUG_MODE'));
--g_Debug		BOOLEAN := NULL;
g_Profiler	BOOLEAN := fnd_api.to_boolean(fnd_profile.value ('WSH_PROFILER_ENABLED'));
g_file_prefix Varchar2(100) := fnd_profile.value('WSH_DEBUG_FILE_PREFIX');

g_Level		NUMBER;
g_Module        VARCHAR2(32767);
g_DebugAll	BOOLEAN := FALSE;

g_user_name     VARCHAR2(200);
g_session_id    NUMBER;
g_run_id        NUMBER;
g_dbms_profiler binary_integer;

g_Debugger_initialized		BOOLEAN := FALSE;
g_inv_dbg_file varchar2(32767);
g_oe_dbg_file varchar2(32767);

g_VersionStack t_CallStack;
g_PkgStack t_CallStack;

g_indent  VARCHAR2(500);

g_file_bak VARCHAR2(32767);
g_dir_bak VARCHAR2(32767);

/*===========================================================================

  PROCEDURE NAME:	level_defined

===========================================================================*/
FUNCTION level_defined(x_Level IN NUMBER)
RETURN BOOLEAN
IS

BEGIN
  IF g_Level <= x_Level THEN
     RETURN(TRUE);
  END IF;
  RETURN(FALSE);

EXCEPTION
  WHEN OTHERS THEN
--dbg_file.log('err in level_defined:'||substrb(sqlerrm,1,200));
  RETURN(FALSE);
END level_defined;


/*===========================================================================

  PROCEDURE NAME:	tstart

===========================================================================*/
PROCEDURE  tstart(x_Marker IN VARCHAR2)
IS
  v_Position    NUMBER := 0;
BEGIN
  IF wsh_debug_interface.g_Debug THEN
    FOR v_Count IN 1..g_TimeStack.COUNT LOOP
      IF g_TimeStack(v_Count).Marker = x_Marker THEN
        v_Position := v_Count;
        EXIT;
      END IF;
    END LOOP;
    IF v_Position = 0 THEN
      v_Position := g_TimeStack.COUNT + 1;
      g_TimeStack(v_Position).Marker := x_Marker;
      g_TimeStack(v_Position).TotalTime := 0;
      g_TimeStack(v_Position).CallCount := 0;
    END IF;
    g_TimeStack(v_Position).Time := dbms_utility.get_time;
    g_TimeStack(v_Position).CallCount := g_TimeStack(v_Position).CallCount + 1;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
--dbg_file.log('err in tstart:'||substrb(sqlerrm,1,200));
        wsh_debug_interface.g_Debug := FALSE;
	--raise;
END tstart;

/*===========================================================================
  PROCEDURE NAME:	tstop
===========================================================================*/
PROCEDURE  tstop(x_Marker IN VARCHAR2)
IS
BEGIN
  IF wsh_debug_interface.g_Debug THEN
    FOR v_Count IN 1..g_TimeStack.COUNT LOOP
      IF g_TimeStack(v_Count).Marker = x_Marker THEN
        g_TimeStack(v_Count).TotalTime := g_TimeStack(v_Count).TotalTime +
                                          ((( dbms_utility.get_time -
                                          g_TimeStack(v_Count).Time)/100));
        EXIT;
      END IF;
    END LOOP;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
        wsh_debug_interface.g_Debug := FALSE;
	--raise;
END tstop;

/*===========================================================================
  FUNCTION NAME:	tprint
===========================================================================*/
FUNCTION  tprint(x_Marker IN VARCHAR2) RETURN VARCHAR2
IS
BEGIN
  IF wsh_debug_interface.g_Debug THEN
    FOR v_Count IN 1..g_TimeStack.COUNT LOOP
      IF g_TimeStack(v_Count).Marker = x_Marker THEN
        RETURN(ROUND(((dbms_utility.get_time - g_TimeStack(v_Count).Time)/100),2)||' seconds');

      END IF;
    END LOOP;
    RETURN(NULL);
  END IF;
EXCEPTION
  WHEN OTHERS THEN
        wsh_debug_interface.g_Debug := FALSE;
	--raise;
END tprint;

/*===========================================================================
  PROCEDURE NAME:	tdump
===========================================================================*/
--PROCEDURE  tdump(x_Context IN VARCHAR2 DEFAULT NULL)
PROCEDURE  tdump(x_Context IN VARCHAR2)
IS
BEGIN
  IF wsh_debug_interface.g_Debug THEN
    --write_output(make_space||'Time Dump ('||x_Context||')');
    FOR v_Count IN 1..g_TimeStack.COUNT LOOP
      write_output(make_space||g_TimeStack(v_Count).Marker||' : '||
                   g_TimeStack(v_Count).CallCount||' calls : '||
                   ROUND(g_TimeStack(v_Count).TotalTime,2)||' seconds');
    END LOOP;
    g_TimeStack.DELETE;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
        wsh_debug_interface.g_Debug := FALSE;
	--raise;
END tdump;

PROCEDURE print_mesg(x_Mesg IN VARCHAR2)
IS
BEGIN

      --dbg_file.log(x_mesg);

   IF  ( nvl(g_RunMode,'!') = 'CONC' ) 
   THEN
     FND_FILE.put_line(FND_FILE.LOG, x_Mesg);
   ELSE
     utl_file.put_line(g_FileHandle, x_Mesg);
     utl_file.fflush(g_FileHandle);
   END IF;

EXCEPTION
/*
  when utl_file.read_error then
      --dbg_file.log('err in print_mesg:'||'read_error');
  when utl_file.write_error then
      --dbg_file.log('err in print_mesg:'||'write_error');
  when utl_file.invalid_operation then
      --dbg_file.log('err in print_mesg:'||'invalid op');
  when utl_file.invalid_filehandle then
      dbg_file.log('err in print_mesg:'||'invalid filehandle');
dbg_file.log('err in print_mesg-1:'||substrb(x_mesg,1,200));
dbg_file.log('err in print_mesg-2:'||substrb(x_mesg,201,200));
dbg_file.log('err in print_mesg-3:'||substrb(x_mesg,401,200));
dbg_file.log('err in print_mesg-4:'||substrb(x_mesg,601,200));
dbg_file.log('err in print_mesg-5:'||substrb(x_mesg,801,200));
  when utl_file.internal_error then
      dbg_file.log('err in print_mesg:'||'internal_error ');
  */
  WHEN OTHERS THEN
--dbg_file.log('err in print_mesgrunmode:'||g_runmode);
--dbg_file.log('err in print_mesg:'||sqlcode);
--dbg_file.log('err in print_mesg:'||substrb(sqlerrm,1,200));
--dbg_file.log('err in print_mesg-1:'||substrb(x_mesg,1,200));
--dbg_file.log('err in print_mesg-2:'||substrb(x_mesg,201,200));
--dbg_file.log('err in print_mesg-3:'||substrb(x_mesg,401,200));
--dbg_file.log('err in print_mesg-4:'||substrb(x_mesg,601,200));
--dbg_file.log('err in print_mesg-5:'||substrb(x_mesg,801,200));
        wsh_debug_interface.g_Debug := FALSE;
END print_mesg;

/*===========================================================================

  PROCEDURE NAME:	write_output

===========================================================================*/
PROCEDURE write_output(x_Line IN VARCHAR2)
IS
  l_debug_msg	VARCHAR2(2000);
  v_MesgSize    NUMBER;
  v_Mesg        VARCHAR2(32767);
BEGIN
  v_MesgSize := LENGTHB(x_Line);
  IF v_MesgSize > 500 THEN
    v_Mesg := x_Line;
    WHILE v_MesgSize > 500 loop
      l_debug_msg := SUBSTRB(v_Mesg,1,500);
      v_Mesg := g_indent || SUBSTRB(v_Mesg,501);
      v_MesgSize := LENGTHB(v_Mesg);
      print_mesg(l_debug_msg);
    END LOOP;
    IF v_MesgSize BETWEEN 1 AND  500 THEN
      print_mesg(v_Mesg);
    END IF;
  ELSE
    l_debug_msg := x_line;
    print_mesg(l_debug_msg);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
--dbg_file.log('err in write_output:'||substrb(sqlerrm,1,200));
        wsh_debug_interface.g_Debug := FALSE;
END write_output;

/*===========================================================================
  FUNCTION NAME:	make_space
===========================================================================*/
FUNCTION make_space(x_Mode IN NUMBER := 0)
RETURN VARCHAR2
IS
  v_Temp	VARCHAR2(500);
BEGIN

  v_Temp := RPAD(' ',2*(g_CallStack.COUNT - 1), ' ');
  IF x_Mode  = 0 AND g_CallStack.COUNT > 0 THEN
    v_Temp := v_Temp||'  ';
  END IF;
  v_temp := SUBSTRB(v_temp,1,450);
  g_indent := v_Temp;
  RETURN(v_Temp);

EXCEPTION
  WHEN OTHERS THEN
--dbg_file.log('err in make_space:'||substrb(sqlerrm,1,200));
        wsh_debug_interface.g_Debug := FALSE;
END make_space;

/*===========================================================================
  PROCEDURE NAME:	logmsg

  DESCRIPTION:   	This procedure prints string followed by a boolean
			Does not require level and always prints.


===========================================================================*/
--PROCEDURE logmsg(x_Module IN VARCHAR2, x_Text IN VARCHAR2, x_Level IN NUMBER DEFAULT C_STMT_LEVEL)
PROCEDURE logmsg(x_Module IN VARCHAR2, x_Text IN VARCHAR2, x_Level IN NUMBER)
IS
BEGIN
  IF wsh_debug_interface.g_Debug THEN
    IF upper(x_Module) like g_Module  AND ( g_DebugAll OR level_defined(x_Level) )
    THEN
	-- changed to fix bug 2743947
	-- replacing occurences of g_miss_char in string
	-- by text "FND_API.G_MISS_CHAR"

        write_output( make_space
		     || REPLACE
			  (
			    x_Text,
			    FND_API.G_MISS_CHAR,
			    'FND_API.G_MISS_CHAR'
			  )
		     );
    END IF;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
        wsh_debug_interface.g_Debug := FALSE;
	--raise;
END logmsg;

/*===========================================================================

  PROCEDURE NAME:	log - string

===========================================================================*/
--PROCEDURE log(x_Module IN VARCHAR2, x_Text IN VARCHAR2, x_Value IN VARCHAR2 := NULL, x_Level IN NUMBER DEFAULT C_STMT_LEVEL)
PROCEDURE log(x_Module IN VARCHAR2, x_Text IN VARCHAR2, x_Value IN VARCHAR2 := NULL, x_Level IN NUMBER)
IS
  --v_NullValue	VARCHAR2(10) := 'is NULL';
  v_MISS_CHAR	VARCHAR2(30) := 'is FND_API.G_MISS_CHAR';
BEGIN
  IF wsh_debug_interface.g_Debug 
  THEN
    IF (upper(x_Module) like g_Module  AND ( g_DebugAll OR level_defined(x_Level) ) )
	THEN
      IF x_Value IS NULL THEN
        write_output(make_space||x_Text||C_DELIMITER);
      ELSIF x_Value = FND_API.G_MISS_CHAR THEN
        write_output(make_space||x_Text||C_DELIMITER||v_MISS_CHAR);
      ELSE
        write_output(make_space||x_Text||C_DELIMITER||x_Value);
      END IF;
    END IF;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
        wsh_debug_interface.g_Debug := FALSE;
	--raise;
END log;

/*===========================================================================
  PROCEDURE NAME:	log

  DESCRIPTION:   	This procedure prints string followed by a number


===========================================================================*/
--PROCEDURE log(x_Module IN VARCHAR2, x_Text IN VARCHAR2, x_Value IN NUMBER, x_Level IN NUMBER DEFAULT C_STMT_LEVEL)
PROCEDURE log(x_Module IN VARCHAR2, x_Text IN VARCHAR2, x_Value IN NUMBER, x_Level IN NUMBER)
IS

  v_NullValue	VARCHAR2(10) := 'is NULL';
  v_MISS_NUM	VARCHAR2(30) := 'is FND_API.G_MISS_NUM';
BEGIN
  IF wsh_debug_interface.g_Debug 
  THEN
    IF (upper(x_Module) like g_Module  AND ( g_DebugAll OR level_defined(x_Level) ) )
	THEN
      IF x_Value IS NULL THEN
        write_output(make_space||x_Text||C_DELIMITER||v_NullValue);
      ELSIF x_Value = FND_API.G_MISS_NUM THEN
        write_output(make_space||x_Text||C_DELIMITER||v_MISS_NUM);
      ELSE
        write_output(make_space||x_Text||C_DELIMITER||x_Value);
      END IF;
    END IF;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
        wsh_debug_interface.g_Debug := FALSE;
	--raise;
END log;

/*===========================================================================
  PROCEDURE NAME:	log

  DESCRIPTION:   	This procedure prints string followed by a date


===========================================================================*/
--PROCEDURE log(x_Module IN VARCHAR2, x_Text IN VARCHAR2, x_Value IN DATE, x_Level IN NUMBER DEFAULT C_STMT_LEVEL, x_Mask IN VARCHAR2 := 'DD-MON-YYYY HH:MI:SS PM')
PROCEDURE log(x_Module IN VARCHAR2, x_Text IN VARCHAR2, x_Value IN DATE, x_Level IN NUMBER, x_Mask IN VARCHAR2 := 'MM/DD/YYYY HH:MI:SS PM')
IS

  v_NullValue	VARCHAR2(10) := 'is NULL';
  v_MISS_DATE	VARCHAR2(30) := 'is FND_API.G_MISS_DATE';
BEGIN
  IF wsh_debug_interface.g_Debug 
  THEN
    IF (upper(x_Module) like g_Module  AND ( g_DebugAll OR level_defined(x_Level) ))
	THEN
      IF x_Value IS NULL THEN
        write_output(make_space||x_Text||C_DELIMITER||v_NullValue);
      ELSIF x_Value = FND_API.G_MISS_DATE THEN
        write_output(make_space||x_Text||C_DELIMITER||v_MISS_DATE);
      ELSE
      --write_output(make_space||x_Text||C_DELIMITER||x_Value);
        write_output(make_space||x_Text||C_DELIMITER||TO_CHAR(x_Value, x_Mask));
      END IF;
    END IF;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
        wsh_debug_interface.g_Debug := FALSE;
	--raise;
END log;

/*===========================================================================
  PROCEDURE NAME:	log

  DESCRIPTION:   	This procedure prints string followed by a boolean

===========================================================================*/
--PROCEDURE log(x_Module IN VARCHAR2, x_Text IN VARCHAR2, x_Value IN BOOLEAN, x_Level IN NUMBER DEFAULT C_STMT_LEVEL)
PROCEDURE log(x_Module IN VARCHAR2, x_Text IN VARCHAR2, x_Value IN BOOLEAN, x_Level IN NUMBER)
IS

  v_Value       VARCHAR2(10);
  v_NullValue	VARCHAR2(10) := 'is NULL';
BEGIN
  IF wsh_debug_interface.g_Debug 
  THEN
    IF (upper(x_Module) like g_Module  AND ( g_DebugAll OR level_defined(x_Level) ))
	THEN
      IF x_Value IS NULL THEN
        v_Value := v_NullValue;
      ELSIF x_Value THEN
        v_Value := 'TRUE';
      ELSE
        v_Value := 'FALSE';
      END IF;
        write_output(make_space||x_Text||C_DELIMITER||v_Value);
    END IF;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
        wsh_debug_interface.g_Debug := FALSE;
	--raise;
END log;

/*===========================================================================
  FUNCTION NAME:	get_file_name

===========================================================================*/
FUNCTION  get_file_name
RETURN VARCHAR2
IS

  v_file_name 	VARCHAR2(255);
  v_suffix 	VARCHAR2(100);

BEGIN
       IF WSH_DEBUG_INTERFACE.g_file IS NOT NULL
       THEN
	   RETURN(WSH_DEBUG_INTERFACE.g_file);
       END IF;
       --
       --
       IF g_session_id is NULL THEN
         g_session_id :=  userenv('SESSIONID');
       END IF;
       --
       fnd_profile.get('WSH_DEBUG_FILE_PREFIX',g_file_prefix);
       --
       IF g_file_prefix IS NULL THEN
         IF ( g_user_name is null ) THEN
           g_user_name := lower(FND_GLOBAL.user_name);
         END IF;
         IF ( g_user_name is null ) THEN
           g_user_name := 'dbuser:' || lower(USER);
         END IF;
         v_suffix := g_user_name || '_' || g_session_id;
         v_file_name := C_PREFIX || '_' || v_suffix || C_SUFFIX;
         RETURN v_file_name;
       ELSE
         v_file_name := g_file_prefix || '_' || g_session_id || C_SUFFIX;
         RETURN v_file_name;
       END IF;

EXCEPTION
  WHEN OTHERS THEN
    --IF utl_file.is_open(g_FileHandle) THEN
      --utl_file.fclose(g_FileHandle);
    --END IF;
    wsh_debug_interface.g_Debug := FALSE;

END get_file_name;

/*===========================================================================
  PROCEDURE NAME:	start_dbg

===========================================================================*/
PROCEDURE  start_dbg( x_Module IN VARCHAR2  , p_otherApp_debug in boolean)
IS
  v_DebugMode	NUMBER;
  v_Directory   VARCHAR2(80);
  v_Status	NUMBER;
  v_debug_enabled VARCHAR2(1);
  v_otherapp_dir VARCHAR2(255);
  v_otherapp_file VARCHAR2(60);
  l_return_status VARCHAR2(1);
  l_sql_string    VARCHAR2(20000);
  l_run_comment  VARCHAR2(32767):=' ';
  l_run_comment1  VARCHAR2(100):=' ';
  l_newFile       BOOLEAN := FALSE;
  l_module        VARCHAR2(32767);
  --bug 5682690 - local variables added
  l_chr_debug_enabled VARCHAR2(80);
  l_chr_debug_enabled_code VARCHAR2(30):=fnd_profile.value('WSH_DEBUG_MODE');
  l_chr_debug_level VARCHAR2(80);
  l_chr_debug_level_code VARCHAR2(30):=fnd_profile.value('WSH_DEBUG_LEVEL');

BEGIN
 IF NOT(g_debugger_initialized)
 THEN
    fnd_profile.get('WSH_DEBUG_MODULE',l_module);
    g_Module      := UPPER(l_module) || '%' ;
    --
    fnd_profile.get('WSH_DEBUG_LEVEL', g_level);
    g_Profiler    := fnd_api.to_boolean(fnd_profile.value ('WSH_PROFILER_ENABLED'));
    --
    fnd_profile.get('WSH_DEBUG_LOG_DIRECTORY',g_dir);
    --
    --
    IF ( nvl(fnd_global.conc_request_id, -1)  > 0 ) THEN
         g_RunMode     := 'CONC';
	 l_run_comment := 'l' || fnd_global.conc_request_id || '.req' ;
         l_newFile     := TRUE;
      --dbg_file.log('set new file true');
	 g_dir         := NVL(g_dir,'X');
    ELSE
         g_RunMode     := 'ONLINE';
         g_File        := get_file_name;
	 l_run_comment := g_file;
    END IF;

    --bug 6215206: For ITM Asyn process even if its frm concurrent process,
    --generate new debug log file for printing debug messages
    if g_RunMode = 'CONC' and
       WSH_DEBUG_SV.G_ITM_ASYN_PROC
    then
        g_RunMode := 'ONLINE';
        g_File        := get_file_name;
        l_run_comment := g_file;
    end if;
    --End of fix for bug 6215206
    --
    --
    --get_debug_levels(g_Level);
    IF wsh_debug_interface.g_Debug AND level_defined(C_PERF_LEVEL) THEN
       g_DebugAll := TRUE; -- so that we do not have to modify other procedures.
    END IF;
    --
    --
    l_newFile := FALSE;
    --
  IF ( nvl(g_File_bak,'!')  <> nvl(g_File,'!')
       OR
       nvl(g_Dir_bak, '!')  <> nvl(g_Dir,'!')
     )
  THEN
  --dbg_file.log('new file name');
     IF wsh_debug_interface.g_Debug THEN
       IF  g_RunMode <> 'CONC'
       THEN
         IF g_dir IS NOT NULL
         THEN
	   IF utl_file.is_open(wsh_debug_interface.g_file_handle)
	   then
              g_FileHandle :=  wsh_debug_interface.g_file_handle;
	   else
              g_FileHandle := utl_file.fopen(g_Dir, g_File, 'a');
	   end if;
	   /*
	 --
	 -- Do not remove the following line
	 -- it is done as a workaround for a bug in utl_file.
	 -- if we open it once and same file is opened
	 -- by other program (e.g. OM/INV), it overwrites portion of the file
	 --
         g_FileHandle := utl_file.fopen(g_Dir, g_File, 'a');
	 */

           g_File_bak := g_File;
           g_Dir_bak := g_Dir;
	   l_newFile := TRUE;
         ELSE
	   wsh_debug_interface.g_debug := FALSE;
	 END IF;
       END IF;
     END IF;
  END IF;
  --
  --
  IF  g_RunMode <> 'CONC'
  AND g_dir IS NOT NULL
  AND NOT(utl_file.is_open(g_FileHandle))
  THEN
         g_FileHandle := utl_file.fopen(g_Dir, g_File, 'a');
  END IF;
    --
    --
   IF g_Profiler THEN

	 l_run_comment1 := LOWER( NVL(FND_GLOBAL.user_name,USER) );
	 --
         l_sql_string:= 'begin
                          dbms_profiler.start_profiler(run_comment =>:1,run_comment1 =>:2,run_number =>:3);
                         end;
                        ';
	 --
	 BEGIN
             EXECUTE IMMEDIATE l_sql_string
	     USING l_run_comment,l_run_comment1,OUT g_run_id;

             print_mesg( 'Profiler Run Number is ==> ' || g_run_id);
	 EXCEPTION
	     when others then
	       null;
	 END;
    ELSE
	g_run_id := NULL;
    END IF;
  --
  --
 IF g_dir IS NOT NULL
 AND ( l_newFile  OR p_otherApp_debug)
 THEN
  print_mesg('Starting WSH Debugger ==> ' || TO_CHAR(sysdate, 'MM/DD/YYYY HH:MI:SS PM') || ',Session ID='||userenv('sessionid') );
  --
  --bug 5682690 - printing wsh debug profiles

   IF l_chr_debug_enabled_code IS NOT NULL THEN

      SELECT meaning
      INTO   l_chr_debug_enabled
      FROM   fnd_lookup_values_vl
      WHERE  lookup_type = 'WSH_DEBUG_ENABLED'
      AND    lookup_code = l_chr_debug_enabled_code;

    ELSE

      l_chr_debug_enabled:=NULL;

    END IF;

   IF l_chr_debug_level_code IS NOT NULL THEN

      SELECT meaning
      INTO   l_chr_debug_level
      FROM   fnd_lookup_values_vl
      WHERE  lookup_type = 'WSH_DEBUG_LEVELS'
      AND    lookup_code = l_chr_debug_level_code;

    ELSE

      l_chr_debug_level:=NULL;

    END IF;

  print_mesg('The following are the current Shipping related debug settings:');
  print_mesg('  OM: Debug Level ==> '|| fnd_profile.value('ONT_DEBUG_LEVEL'));
  print_mesg('  INV: Debug Level ==> '|| fnd_profile.value('INV_DEBUG_LEVEL'));
  print_mesg('  WSH: Debug Enabled ==> '|| l_chr_debug_enabled);
  print_mesg('  WSH: Debug File Prefix ==> '|| fnd_profile.value('WSH_DEBUG_FILE_PREFIX'));
  print_mesg('  WSH: Debug Level ==> '|| l_chr_debug_level);
  print_mesg('  WSH: Debug Log Directory ==> '|| fnd_profile.value('WSH_DEBUG_LOG_DIRECTORY'));
  print_mesg('  WSH: Debug Module ==> '|| fnd_profile.value('WSH_DEBUG_MODULE'));
  print_mesg(' ');
  --
  /*
  IF  ( nvl(g_RunMode,FND_API.G_MISS_CHAR) <> 'CONC' ) THEN
    log(x_Module,'File Name',g_File,C_UNEXPEC_ERR_LEVEL);
  END IF;
  */
  --
  IF WSH_DEBUG_INTERFACE.g_file IS NULL
  THEN
      Start_Other_App_Debug(
        p_application           => 'OE' ,
        x_debug_directory       => v_otherapp_dir,
        x_debug_file            => v_otherapp_file,
        x_return_status         => l_return_status);
      Start_Other_App_Debug(
        p_application           => 'INV' ,
        x_debug_directory       => v_otherapp_dir,
        x_debug_file            => v_otherapp_file,
        x_return_status         => l_return_status);
      --
      -- need to set new_file = true for conc. mode
      --print_mesg('OE Debug File ==> '  || g_oe_dbg_file);
      --print_mesg('INV Debug File ==> ' || g_inv_dbg_file);
  END IF;
 END IF;
 g_Debugger_initialized		:= TRUE;
 END IF;

EXCEPTION
  WHEN OTHERS THEN
    --IF utl_file.is_open(g_FileHandle) THEN
      --utl_file.fclose(g_FileHandle);
    --END IF;
--dbg_file.log('err in start_dbg:'||substrb(sqlerrm,1,200));
    wsh_debug_interface.g_Debug := FALSE;

END start_dbg;

/*===========================================================================
  PROCEDURE NAME:	stop_dbg
===========================================================================*/
PROCEDURE  stop_dbg( x_Module IN VARCHAR2 , p_otherApp_debug in boolean )
IS
  v_Status 	NUMBER;
  l_return_status VARCHAR2(1);
  v_debug_separator VARCHAR2(255) := '*****************************************************';
  v_debug_summary   VARCHAR2(255) := '************Summary of Shipping API Calls************';
  l_sql_string   VARCHAR2(20000);
BEGIN
  --log(x_Module,'Stopping WSH Debugger',sysdate,C_UNEXPEC_ERR_LEVEL);
  IF g_TimeStack.COUNT <> 0 THEN
    print_mesg(v_debug_summary);
    wsh_debug_sv.tdump;
    print_mesg(v_debug_separator);
  END IF;
  IF g_run_id IS NOT NULL THEN

    BEGIN
       l_sql_string:= 'begin
                          dbms_profiler.flush_data;
                          dbms_profiler.stop_profiler;
                        end;
                        ';

       EXECUTE IMMEDIATE l_sql_string;
    EXCEPTION
       when others then null;
    END;

    g_run_id := NULL;
  END IF;
  g_TimeStack.DELETE;
  g_oe_dbg_file := NULL;
  g_inv_dbg_file := NULL;

  IF p_otherApp_debug
  THEN
    if utl_file.is_open(g_FileHandle)
    then
        --dbg_file.log('closing file');
        utl_file.fclose(g_FileHandle);
        --g_fileHandle := NULL;
    end if;
  END IF;
  --
  --
  IF WSH_DEBUG_INTERFACE.g_file IS NULL
  AND p_otherApp_Debug
  THEN
      stop_Other_App_Debug(
        p_application           => 'OE' ,
        x_return_status         => l_return_status);
      stop_Other_App_Debug(
        p_application           => 'INV' ,
        x_return_status         => l_return_status);
  END IF;
  --
  --
  g_debugger_initialized := FALSE;
  /*
  wsh_debug_interface.g_Debug := FALSE;
  g_DebugAll := FALSE;
  IF utl_file.is_open(g_FileHandle) THEN
    utl_file.fclose(g_FileHandle);
  END IF;
  */
EXCEPTION
  WHEN OTHERS THEN
--dbg_file.log('err in stop_dbg:'||substrb(sqlerrm,1,200));
  wsh_debug_interface.g_Debug := FALSE;
END stop_dbg;

/*===========================================================================
  FUNCTION NAME:	get_pkg_version

  DESCRIPTION:   	This function returns the version of the package body

===========================================================================*/

FUNCTION get_pkg_version(x_Package IN VARCHAR2)
RETURN VARCHAR2
IS
i NUMBER;
v_Version VARCHAR2(100);
v_Header  VARCHAR2(32767);
BEGIN

  IF nvl(x_Package, 'WSH') <> 'WSH' THEN
    IF g_PkgStack.COUNT <> 0 THEN
      FOR i IN 1..g_PkgStack.COUNT LOOP
         IF x_Package = g_PkgStack(i) THEN
           RETURN g_VersionStack(i);
         END IF;
      END LOOP;
    END IF;
    select text
    into   v_Header
    from   all_source
    where  name  = x_Package
    and    owner = UPPER(USER)
    and    line  = 2
    and    type  ='PACKAGE BODY';
    --and    text  like '%$Head%';
    v_Header  := ltrim(SUBSTRB(v_Header,INSTRB(v_Header,':',1,1)+1),' ');
    v_Version := SUBSTRB(v_Header,1 ,INSTRB(v_Header, ' ',1,2) -1 );
    g_VersionStack(g_VersionStack.COUNT +1) := v_Version;
    g_PkgStack(g_PkgStack.COUNT +1) := x_Package;
    RETURN v_Version;
  ELSE
    RETURN NULL;
  END IF;

EXCEPTION
  when others then
  RETURN NULL;
END get_pkg_version;

/*===========================================================================

  PROCEDURE NAME:	push

===========================================================================*/
PROCEDURE push(x_Module IN VARCHAR2)
IS
  v_Name       VARCHAR2(255);
  v_Pkg        VARCHAR2(80);
BEGIN
--dbg_file.log('x_module='||x_module);
--dbg_file.log('g_debugcount='||g_debugCount);
  IF  g_DebugCount = 0 THEN
    --
        wsh_debug_interface.g_Debug       := is_debug_enabled;
	--
	--
	IF wsh_debug_interface.g_debug
	THEN
            --dbg_file.log('wsh_debug_interface.g_debug is true');
            start_dbg(x_Module,FALSE);
	--ELSE
         --   stop_dbg(x_Module,TRUE);
	END IF;
    --
  END IF;
  --
  --
  g_DebugCount := g_DebugCount + 1;
  --
  --
  IF wsh_debug_interface.g_Debug THEN
--dbg_file.log('wsh_debug_interface.g_debug is true-1');
    IF ( upper(x_Module) like g_Module ) THEN
      IF g_DebugAll OR level_defined(C_PROC_LEVEL) THEN
        v_Name :=  UPPER(SUBSTRB (x_Module,INSTRB(x_Module, '.',1,2) + 1));
        v_Pkg  := UPPER(SUBSTRB (v_Name,1,INSTRB(v_Name,'.',1,1)-1));
        g_CallStack(g_CallStack.COUNT) := v_Name;
--dbg_file.log('calling tstart');
        tstart(v_Name);
--dbg_file.log('calling write');
        write_output(make_space(1)||'Entering '||v_Name|| ' ('||get_pkg_version(v_Pkg)||')'||' ('||TO_CHAR(sysdate,'MM/DD/YYYY HH:MI:SS PM')||')');
--dbg_file.log('after write');
      END IF;
    END IF;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
--dbg_file.log('err in push:'||substrb(sqlerrm,1,200));
        wsh_debug_interface.g_Debug := FALSE;
	--raise;
END push;

/*===========================================================================

  PROCEDURE NAME:	pop

===========================================================================*/
PROCEDURE pop(x_Module IN VARCHAR2, x_Context IN VARCHAR2 := NULL)
IS

  v_Name       VARCHAR2(255);
  v_message    VARCHAR2(32767);

BEGIN

  g_DebugCount := g_DebugCount - 1;
  --
  IF wsh_debug_interface.g_Debug THEN
    IF ( upper(x_Module) like g_Module  ) THEN
      IF g_DebugAll OR level_defined(C_PROC_LEVEL) THEN

        v_Name := UPPER(SUBSTRB (x_Module,INSTRB(x_Module, '.',1,2) + 1));
	--
	v_message := make_space(1)
		     || 'Exiting '
		     || v_Name;
        --
        IF x_Context IS NOT NULL THEN
	   v_message := v_message
		        || ' - '
			||x_Context ;
        END IF;
	v_message := v_message
	             || ' ('
                     || TO_CHAR(sysdate,'MM/DD/YYYY HH:MI:SS PM')
	             || ',  '
	             || tprint(v_Name)
	             || ')';
	--
	--
        tstop(v_Name);
	write_output(v_message);
	--
	IF ( g_callStack.count > 0 )
	THEN
            g_CallStack.DELETE(g_CallStack.COUNT-1);
	END IF;
      END IF;
    END IF;
  END IF;
  --
      IF g_DebugCount = 0 THEN
        stop_dbg(x_Module, false);
      END IF;

EXCEPTION
  WHEN OTHERS THEN
--dbg_file.log('err in pop:'||substrb(sqlerrm,1,200));
        wsh_debug_interface.g_Debug := FALSE;

END pop;

/*===========================================================================

PROCEDURE NAME:	start_wsh_debugger

DESCRIPTION	This procedure is used to turn on the Shipping Debugger by other
	        products

============================================================================*/
--FUNCTION start_wsh_debugger ( x_Level IN NUMBER)
--RETURN VARCHAR2
PROCEDURE start_debugger
	    (
	      x_file_name OUT NOCOPY  VARCHAR2,
	      x_return_status OUT NOCOPY  VARCHAR2,
	      x_msg_count     OUT NOCOPY  NUMBER,
	      x_msg_data      OUT NOCOPY  VARCHAR2
	    )
IS
  v_dir_separator VARCHAR2(1);
  l_debug_file varchar2(32767);
BEGIN

  fnd_profile.get('WSH_DEBUG_LOG_DIRECTORY',g_dir);
  --
  IF g_Dir IS NOT NULL THEN
    fnd_profile.put('WSH_DEBUG_MODE','T');
    --fnd_profile.put('WSH_DEBUG_MODULE','%');
    --fnd_profile.put('WSH_DEBUG_LEVEL',to_char(x_Level));
    IF (instrb(g_Dir,'/') > 0 ) THEN
      v_dir_separator := '/';
    ELSE
      v_dir_separator := '\';
    END IF;
    --
    --
    wsh_debug_interface.g_debug := TRUE;
    --
    start_dbg('',TRUE);

    l_Debug_File := g_Dir || v_dir_separator|| g_file; --get_file_name;
    x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;
  ELSE
    x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
    FND_MESSAGE.SET_NAME('WSH','WSH_DEBUG_DIR_NULL_ERROR');
    WSH_UTIL_CORE.ADD_MESSAGE(WSH_UTIL_CORE.G_RET_STS_ERROR);
  END IF;
  --
  --
  x_file_name := l_debug_file;
  --
  --
  FND_MSG_PUB.Count_And_Get
    (
      p_count => x_msg_count,
      p_data => x_msg_data,
      p_encoded => FND_API.G_FALSE
    );

EXCEPTION
  WHEN OTHERS THEN

    WSH_UTIL_CORE.default_handler(WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR);
    x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
  FND_MSG_PUB.Count_And_Get
    (
      p_count => x_msg_count,
      p_data => x_msg_data,
      p_encoded => FND_API.G_FALSE
    );
    --RETURN(l_debug_file);
END start_debugger;


/*===========================================================================

PROCEDURE NAME:	stop_wsh_debugger

DESCRIPTION	This procedure is used to turn off the Shipping Debugger by other
	        products

============================================================================*/
PROCEDURE stop_debugger
IS
  v_dir_separator VARCHAR2(1);
  l_debug_file varchar2(32767);
BEGIN

    --IF NVL(wsh_debug_interface.g_debug,FALSE)
    --THEN
       --stop_dbg('', true);
       stop_dbg('', false);
    --END IF;
    --
    fnd_profile.put('WSH_DEBUG_MODE','F');
    --
    wsh_debug_interface.g_debug := FALSE;

EXCEPTION
  WHEN OTHERS THEN
     wsh_debug_interface.g_debug:= FALSE;
END stop_debugger;



/*===========================================================================
FUNCTION NAME:	is_debug_enabled

DESCRIPTION:   	This function returns TRUE if debug is
                enabled.

===========================================================================*/

FUNCTION is_debug_enabled RETURN BOOLEAN
IS

  v_debug_enabled varchar2(100);

BEGIN

  IF wsh_debug_interface.g_debug IS NOT NULL
  THEN
     RETURN(wsh_debug_interface.g_debug);
  END IF;
  --
  fnd_profile.get('WSH_DEBUG_MODE',v_debug_enabled);
  IF nvl(v_debug_enabled,'!') = 'T' THEN
    wsh_debug_interface.g_debug := TRUE;
    RETURN TRUE;
  ELSIF nvl(v_debug_enabled,'!') = 'F' THEN
    wsh_debug_interface.g_debug := FALSE;
    RETURN FALSE;
  ELSIF to_number(v_debug_enabled) >= 0  THEN
    wsh_debug_interface.g_debug := TRUE;
    RETURN TRUE;
  ELSE
    wsh_debug_interface.g_debug := FALSE;
    RETURN FALSE;
  END IF;
  RETURN FALSE;

EXCEPTION
when others then
RETURN FALSE;
END is_debug_enabled;


/*===========================================================================

PROCEDURE Start_Other_App_Debug

===========================================================================*/

PROCEDURE Start_Other_App_Debug(
		p_application		IN VARCHAR2,
		x_debug_directory	OUT NOCOPY  VARCHAR2,
		x_debug_file		OUT NOCOPY  VARCHAR2,
		x_return_status		OUT NOCOPY  VARCHAR2)
IS

  v_inv_dbg_file varchar2(255);
  v_dir_separator varchar2(1);
  v_inv_trace_on number := 0;
  v_oe_dbg_level number := 0;
  v_return_flag boolean := FALSE;
BEGIN
  x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;
  --
  --dbg_file.log('start other app debugger-app='||p_application||'dir='||g_dir||'file='||g_file);
  IF (p_application = 'OE') THEN
       oe_debug_pub.start_ont_debugger(g_dir, g_file, g_filehandle);
  ELSIF ( p_application = 'INV' ) THEN
       INV_DEBUG_INTERFACE.start_inv_debugger(g_dir, g_file, g_filehandle);
  END IF;
  --
  /*
  IF (p_application = 'OE') THEN
    FND_PROFILE.get('ONT_DEBUG_LEVEL',v_oe_dbg_level);
    IF nvl(v_oe_dbg_level, 0) = 0 THEN
      v_oe_dbg_level := 5;
    END IF;
    OE_DEBUG_PUB.G_DEBUG_LEVEL:=	v_oe_dbg_level;
    FND_PROFILE.get('OE_DEBUG_LOG_DIRECTORY',x_debug_directory);
    IF x_debug_directory is null THEN
      x_debug_directory := g_Dir;
      fnd_profile.put('OE_DEBUG_LOG_DIRECTORY',g_Dir);
    END IF;
    x_debug_file 		:= oe_debug_pub.Set_Debug_Mode('FILE');
    g_oe_dbg_file := x_debug_file;
    --log(g_Module,'OE Debug File',x_debug_file,C_STMT_LEVEL);
  ELSIF ( p_application = 'INV' ) THEN
    fnd_profile.get('INV_DEBUG_TRACE', v_inv_trace_on) ;
    fnd_profile.get('INV_DEBUG_FILE', v_inv_dbg_file) ;
    IF ( v_inv_trace_on IN (2,0) ) THEN
      fnd_profile.put('INV_DEBUG_TRACE','1');
    END IF;
    IF v_inv_dbg_file IS NULL THEN
      IF g_file_prefix IS NULL THEN
        v_inv_dbg_file := 'inv_' || substrb(g_File, 5);
      ELSE
        v_inv_dbg_file := 'inv_' || g_File;
      END IF;
      IF (instrb(g_Dir,'/') > 0 ) THEN
        v_dir_separator := '/';
        v_inv_dbg_file := g_Dir || v_dir_separator|| v_inv_dbg_file;
      ELSE
        v_dir_separator := '\';
        v_inv_dbg_file := g_Dir || v_dir_separator|| v_inv_dbg_file;
      END IF;
    END IF;
    fnd_profile.put('INV_DEBUG_FILE',v_inv_dbg_file);
    fnd_profile.put('INV_DEBUG_LEVEL',C_UNEXPEC_ERR_LEVEL);
    g_inv_dbg_file := v_inv_dbg_file;
    --log(g_Module,'INV Debug File',v_inv_dbg_file,C_STMT_LEVEL);
  END IF;
  */

EXCEPTION
WHEN Others THEN
x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;

END Start_Other_App_Debug;
/*===========================================================================

PROCEDURE Stop_Other_App_Debug

===========================================================================*/
PROCEDURE Stop_Other_App_Debug(
		p_application		IN VARCHAR2,
		x_return_status		OUT NOCOPY  VARCHAR2) IS

BEGIN
  x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;
  --
  IF (p_application = 'OE') THEN
       oe_debug_pub.stop_ont_debugger;
  ELSIF ( p_application = 'INV' ) THEN
       INV_DEBUG_INTERFACE.stop_inv_debugger;
  END IF;
  --
  /*
  IF (p_application = 'OE') THEN
    OE_DEBUG_PUB.DEBUG_OFF;
  END IF;
  */

EXCEPTION
  WHEN Others THEN
    x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
END Stop_Other_App_Debug;


/********* The APIs below are maintained only for backward compatibility.
These should not be called directly from any APIs. ****************/


/*===========================================================================

PROCEDURE append_other_dbg_file

===========================================================================*/
PROCEDURE append_other_dbg_file( p_source_file_directory     IN VARCHAR2,
                                 p_source_file_name          IN VARCHAR2,
                                 p_target_file_directory     IN VARCHAR2,
                                 p_target_file_name          IN VARCHAR2,
                                 x_return_status             OUT NOCOPY  BOOLEAN)
IS
  x_source_file             utl_file.file_type;
  x_target_file             utl_file.file_type;
  x_line             VARCHAR2(512)      := NULL;
begin
  NULL;
  /*
  x_source_file := utl_file.fopen(p_source_file_directory, p_source_file_name, 'R');
  x_target_file := utl_file.fopen(p_target_file_directory, p_target_file_name, 'A');
  x_line := '******** Attaching the contents of other app debug ********';
  utl_file.put_line(x_target_file, x_line);
  x_line := 'Debug file =>' || p_source_file_name;
  utl_file.put_line(x_target_file, x_line);
  LOOP
    utl_file.get_line(x_source_file, x_line);
    utl_file.Put_line(x_target_file, x_line);
  END LOOP;
  utl_file.fclose(x_source_file);
  utl_file.fclose(x_target_file);
  x_return_status := TRUE;
  */

EXCEPTION
  WHEN utl_file.invalid_operation THEN
    utl_file.fclose(x_source_file);
    utl_file.fclose(x_target_file);
    x_return_status :=FALSE;
  WHEN utl_file.read_error THEN
    utl_file.fclose(x_source_file);
    utl_file.fclose(x_target_file);
    x_return_status :=FALSE;
  WHEN utl_file.invalid_mode THEN
    utl_file.fclose(x_source_file);
    utl_file.fclose(x_target_file);
    x_return_status :=FALSE;
  WHEN utl_file.invalid_filehandle THEN
    utl_file.fclose(x_source_file);
    utl_file.fclose(x_target_file);
    x_return_status :=FALSE;
  WHEN utl_file.internal_error THEN
    utl_file.fclose(x_source_file);
    utl_file.fclose(x_target_file);
    x_return_status :=FALSE;
  WHEN OTHERS THEN
    x_return_status :=FALSE;
    END append_other_dbg_file;

/*===========================================================================
  PROCEDURE NAME:	tstart

===========================================================================*/
PROCEDURE  tstart(x_Level IN NUMBER, x_Marker IN VARCHAR2)
IS

  v_Context	VARCHAR2(100);
  v_Position    NUMBER := 0;

BEGIN

  IF wsh_debug_interface.g_Debug THEN
    IF g_DebugAll OR level_defined(x_Level) THEN
      FOR v_Count IN 1..g_TimeStack.COUNT LOOP
        IF g_TimeStack(v_Count).Marker = UPPER(x_Marker) THEN
          v_Position := v_Count;
          EXIT;
        END IF;
      END LOOP;
      IF v_Position = 0 THEN
        v_Position := g_TimeStack.COUNT + 1;
        g_TimeStack(v_Position).Marker := UPPER(x_Marker);
        g_TimeStack(v_Position).TotalTime := 0;
        g_TimeStack(v_Position).CallCount := 0;
      END IF;
      g_TimeStack(v_Position).Time := dbms_utility.get_time;
      g_TimeStack(v_Position).CallCount := g_TimeStack(v_Position).CallCount + 1
;

    END IF;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
        wsh_debug_interface.g_Debug := FALSE;
	--raise;

END tstart;


/*===========================================================================

  PROCEDURE NAME:	tstop

===========================================================================*/
PROCEDURE  tstop(x_Level IN NUMBER, x_Marker IN VARCHAR2)
IS

  v_Context	VARCHAR2(100);

BEGIN

  IF wsh_debug_interface.g_Debug THEN
    IF g_DebugAll OR level_defined(x_Level) THEN
      FOR v_Count IN 1..g_TimeStack.COUNT LOOP
        IF g_TimeStack(v_Count).Marker = UPPER(x_Marker) THEN
          g_TimeStack(v_Count).TotalTime := g_TimeStack(v_Count).TotalTime +
                                            ((( dbms_utility.get_time -
                                            g_TimeStack(v_Count).Time)/100));
          EXIT;
        END IF;
      END LOOP;
    END IF;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
        wsh_debug_interface.g_Debug := FALSE;
	--raise;

END tstop;

/*===========================================================================

  PROCEDURE NAME:	tdump

===========================================================================*/
--PROCEDURE  tdump(x_Level IN NUMBER, x_Context IN VARCHAR2 DEFAULT NULL)
PROCEDURE  tdump(x_Level IN NUMBER, x_Context IN VARCHAR2)
IS


BEGIN


  IF wsh_debug_interface.g_Debug THEN
    IF g_DebugAll OR level_defined(x_Level) THEN
      --write_output(make_space||'Time Dump ('||x_Context||')');
      FOR v_Count IN 1..g_TimeStack.COUNT LOOP
        write_output(make_space||g_TimeStack(v_Count).Marker||' : '||
                     g_TimeStack(v_Count).CallCount||' calls : '||
                     ROUND(g_TimeStack(v_Count).TotalTime,2)||' seconds');
      END LOOP;
      g_TimeStack.DELETE;
    END IF;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
        wsh_debug_interface.g_Debug := FALSE;
	--raise;
END tdump;



/*===========================================================================

  PROCEDURE NAME:	start_time

===========================================================================*/
PROCEDURE  start_time(x_Level IN NUMBER, x_Marker IN VARCHAR2, x_Context IN VARCHAR2 := NULL)

IS

  v_Context	VARCHAR2(100);
  v_Position    NUMBER := 0;

BEGIN

  IF wsh_debug_interface.g_Debug THEN
    IF g_DebugAll OR level_defined(x_Level) THEN
      FOR v_Count IN 1..g_TimeStack.COUNT LOOP
        IF g_TimeStack(v_Count).Marker = UPPER(x_Marker) THEN
          v_Position := v_Count;
          EXIT;
        END IF;
      END LOOP;
      IF v_Position = 0 THEN
        v_Position := g_TimeStack.COUNT + 1;
        g_TimeStack(v_Position).Marker := UPPER(x_Marker);
        g_TimeStack(v_Position).TotalTime := 0;
        g_TimeStack(v_Position).CallCount := 0;
      END IF;
      g_TimeStack(v_Position).Time := dbms_utility.get_time;
      v_Context := x_Context;
      IF v_Context IS NOT NULL THEN
        v_Context := ': '||v_Context;
      END IF;
      write_output(make_space||'Start Timing ('||UPPER(x_Marker)||')'|| v_Context);

    END IF;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
        wsh_debug_interface.g_Debug := FALSE;
	--raise;

END start_time;


/*===========================================================================

  PROCEDURE NAME:	start_time

===========================================================================*/
PROCEDURE  start_time(x_Marker IN VARCHAR2, x_Context IN VARCHAR2 := NULL)
IS

  v_Context	VARCHAR2(100);
  v_Position    NUMBER := 0;

BEGIN

  IF wsh_debug_interface.g_Debug THEN
    FOR v_Count IN 1..g_TimeStack.COUNT LOOP
      IF g_TimeStack(v_Count).Marker = UPPER(x_Marker) THEN
        v_Position := v_Count;
        EXIT;
      END IF;
    END LOOP;
    IF v_Position = 0 THEN
      v_Position := g_TimeStack.COUNT + 1;
      g_TimeStack(v_Position).Marker := UPPER(x_Marker);
      g_TimeStack(v_Position).TotalTime := 0;
      g_TimeStack(v_Position).CallCount := 0;
    END IF;
    g_TimeStack(v_Position).Time := dbms_utility.get_time;
    v_Context := x_Context;
    IF v_Context IS NOT NULL THEN
      v_Context := ': '||v_Context;
    END IF;
    write_output(make_space||'Start Timing ('||UPPER(x_Marker)||')'|| v_Context);

  END IF;

EXCEPTION
  WHEN OTHERS THEN
        wsh_debug_interface.g_Debug := FALSE;
	--raise;

END start_time;


/*===========================================================================

  PROCEDURE NAME:	stop_time

===========================================================================*/
PROCEDURE  stop_time(x_Level IN NUMBER, x_Marker IN VARCHAR2, x_Context IN VARCHAR2 := NULL)

IS

  v_Context	VARCHAR2(100);

BEGIN

  IF wsh_debug_interface.g_Debug THEN
    IF g_DebugAll OR level_defined(x_Level) THEN
      FOR v_Count IN 1..g_TimeStack.COUNT LOOP
        IF g_TimeStack(v_Count).Marker = UPPER(x_Marker) THEN
          v_Context := x_Context;
          IF v_Context IS NULL THEN
            v_Context := C_DELIMITER;
          ELSE
            v_Context := ': '||v_Context ||C_DELIMITER;
          END IF;
          write_output(make_space||'End Timing ('||UPPER(x_Marker)||')'|| v_Context ||
          ((dbms_utility.get_time - g_TimeStack(v_Count).Time)/100) ||' seconds');

--          g_TimeStack.DELETE(v_Count);
          EXIT;
        END IF;
      END LOOP;
    END IF;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
        wsh_debug_interface.g_Debug := FALSE;
	--raise;

END stop_time;


/*===========================================================================

  PROCEDURE NAME:	stop_time

===========================================================================*/
PROCEDURE  stop_time(x_Marker IN VARCHAR2, x_Context IN VARCHAR2 := NULL)
IS

  v_Context	VARCHAR2(100);

BEGIN

  IF wsh_debug_interface.g_Debug THEN
    FOR v_Count IN 1..g_TimeStack.COUNT LOOP
      IF g_TimeStack(v_Count).Marker = UPPER(x_Marker) THEN
        v_Context := x_Context;
        IF v_Context IS NULL THEN
          v_Context := C_DELIMITER;
        ELSE
          v_Context := ': '||v_Context ||C_DELIMITER;
        END IF;
        write_output(make_space||'End Timing ('||UPPER(x_Marker)||')'|| v_Context ||
                     ((dbms_utility.get_time - g_TimeStack(v_Count).Time)/100)||' seconds');

--        g_TimeStack.DELETE(v_Count);
        EXIT;
      END IF;
    END LOOP;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
        wsh_debug_interface.g_Debug := FALSE;
	--raise;

END stop_time;

/*=========================================================================

FUNCTION NAME:       get_lookup_meaning

===========================================================================*/

FUNCTION get_lookup_meaning (x_lookup_type  IN VARCHAR2,
                             x_lookup_code  IN VARCHAR2)
RETURN VARCHAR2
IS

   x_progress      VARCHAR2(3) := '010';

   CURSOR c IS
     SELECT meaning
     FROM   fnd_lookups
     WHERE  lookup_type = x_lookup_type  AND
            lookup_code = x_lookup_code;
   --
   x_meaning fnd_lookups.meaning%TYPE;
   --
BEGIN
  --
  OPEN  c;
  --
  FETCH c INTO x_meaning;
  --
  RETURN x_meaning;
  --
EXCEPTION
  WHEN OTHERS THEN
    RAISE;

END get_lookup_meaning;

	/*===========================================================================

	  PROCEDURE NAME:	debug

	===========================================================================*/
	PROCEDURE  debug (x_message IN VARCHAR2)
	IS

	BEGIN
	  IF (g_debug_flag) THEN
	--    dbms_output.put_line (substr(x_message,1,255));
	    NULL;

	  END IF;

	END debug;


	/*===========================================================================

	  PROCEDURE NAME:	disable_debug

	===========================================================================*/
	PROCEDURE  disable_debug
	IS

	BEGIN

	   g_debug_flag := FALSE;

	END disable_debug;


	/*===========================================================================

	  FUNCTION NAME:	debug_enabled

	===========================================================================*/
	FUNCTION  debug_enabled
	RETURN BOOLEAN
	IS

	BEGIN

	  return(g_debug_flag);

	END debug_enabled;


	/*===========================================================================

	  PROCEDURE NAME:	enable_debug

	===========================================================================*/
	PROCEDURE  enable_debug
	IS

	BEGIN

	  g_debug_flag := TRUE;

	END enable_debug;

	/*===========================================================================

	  PROCEDURE NAME:	get_debug_levels

	===========================================================================*/
	PROCEDURE  get_debug_levels(x_Topper IN NUMBER)
	IS

	BEGIN

	  /*
	  FOR i IN 0..g_MaxLevels LOOP
	    IF POWER(2,i) > x_Topper THEN
	      g_DebugLevels(g_DebugLevels.COUNT) := POWER(2,i-1);
	      get_debug_levels(x_Topper - POWER(2,i-1));
	      EXIT;
	    ELSIF POWER(2,i) = x_Topper THEN
	      g_DebugLevels(g_DebugLevels.COUNT) := POWER(2,i);
	      EXIT;
	    END IF;
	  END LOOP;
	  */
	  NULL;

	END get_debug_levels;

	/*===========================================================================

	  PROCEDURE NAME:	print_debug_stuff

	===========================================================================*/
	PROCEDURE  print_debug_stuff
	IS

	BEGIN

	  FOR i IN 0..g_DebugLevels.COUNT - 1 LOOP
	--    dbms_output.put_line('LEVEL '||i||' = '||g_DebugLevels(i));
	    NULL;
	  END LOOP;

	END print_debug_stuff;

	/*===========================================================================

	  PROCEDURE NAME:	start_debug
				Just a Stub procedure to keep some of the WSH Packages Valid.
	===========================================================================*/
	PROCEDURE  start_debug(file_number VARCHAR2)
	IS
	BEGIN
	NULL;
	END start_debug;

	/*===========================================================================
	  PROCEDURE NAME:	stop_debug
				Just a Stub procedure to keep some of the WSH Packages Valid.
	===========================================================================*/
	PROCEDURE  stop_debug
	IS
	BEGIN
	NULL;
	END stop_debug;

	/*===========================================================================

	  PROCEDURE NAME:	dlog - string

	===========================================================================*/
	PROCEDURE  dlog(x_Level IN NUMBER, x_Text IN VARCHAR2, x_Value IN VARCHAR2 := NULL)
	IS


	BEGIN

	  log(g_Module,x_Text, x_Value,x_Level);
	/*
	  IF wsh_debug_interface.g_Debug THEN
	    IF g_DebugAll OR level_defined(x_Level) THEN
	      IF x_Value IS NULL THEN
		write_output(make_space||x_Text);
	      ELSE
		write_output(make_space||x_Text||C_DELIMITER||x_Value);
	      END IF;
	    END IF;
	  END IF;
	*/

	EXCEPTION
	  WHEN OTHERS THEN
            wsh_debug_interface.g_Debug := FALSE;
	END dlog;


	/*===========================================================================

	  PROCEDURE NAME:	dlog - number

	===========================================================================*/
	PROCEDURE  dlog(x_Level IN NUMBER, x_Text IN VARCHAR2, x_Value IN NUMBER)
	IS


	BEGIN

	  log(g_Module,x_Text, x_Value,x_Level);
	  /*
	  IF wsh_debug_interface.g_Debug THEN
	    IF g_DebugAll OR level_defined(x_Level) THEN
	      write_output(make_space||x_Text||C_DELIMITER||x_Value);
	    END IF;
	  END IF;
	  */

	EXCEPTION
	  WHEN OTHERS THEN
            wsh_debug_interface.g_Debug := FALSE;

	END dlog;


	/*===========================================================================

	  PROCEDURE NAME:	dlog - boolean

	===========================================================================*/
	PROCEDURE  dlog(x_Level IN NUMBER, x_Text IN VARCHAR2, x_Value IN BOOLEAN)
	IS

	  v_Temp	VARCHAR2(5);

	BEGIN

	  log(g_Module,x_Text, x_Value,x_Level);
	  /*
	  IF wsh_debug_interface.g_Debug THEN
	    IF g_DebugAll OR level_defined(x_Level) THEN
	      IF x_Value THEN
		v_Temp := 'TRUE';
	      ELSIF NOT x_Value THEN
		v_Temp := 'FALSE';
	      END IF;
	      write_output(make_space||x_Text||C_DELIMITER||v_Temp);
	    END IF;
	  END IF;
	  */

	EXCEPTION
	  WHEN OTHERS THEN
             wsh_debug_interface.g_Debug := FALSE;

	END dlog;


	/*===========================================================================

	  PROCEDURE NAME:	dlog - date

	===========================================================================*/
	PROCEDURE  dlog(x_Level IN NUMBER, x_Text IN VARCHAR2, x_Value IN DATE,
			x_Mask IN VARCHAR2 := 'DD-MON-YYYY HH:MI:SS PM')
	IS


	BEGIN

	  log(g_Module,x_Text, x_Value,x_Level);
	  /*
	  IF wsh_debug_interface.g_Debug THEN
	    IF g_DebugAll OR level_defined(x_Level) THEN
	      write_output(make_space||x_Text||C_DELIMITER||TO_CHAR(x_Value, x_Mask));
	    END IF;
	  END IF;
	  */

	EXCEPTION
	  WHEN OTHERS THEN
              wsh_debug_interface.g_Debug := FALSE;

	END dlog;


	/*===========================================================================

	  PROCEDURE NAME:	dlog - string

	===========================================================================*/
	PROCEDURE  dlog(x_Text IN VARCHAR2, x_Value IN VARCHAR2 := NULL)
	IS


	BEGIN

	  log(g_Module,x_Text, x_Value);
          /*
	  IF wsh_debug_interface.g_Debug THEN
	    IF x_Value IS NULL THEN
	      write_output(make_space||x_Text);
	    ELSE
	      write_output(make_space||x_Text||C_DELIMITER||x_Value);
	    END IF;
	  END IF;
	  */

	EXCEPTION
	  WHEN OTHERS THEN
              wsh_debug_interface.g_Debug := FALSE;

	END dlog;


	/*===========================================================================

	  PROCEDURE NAME:	dlog - number

	===========================================================================*/
	PROCEDURE  dlog(x_Text IN VARCHAR2, x_Value IN NUMBER)
	IS


	BEGIN

	  log(g_Module,x_Text, x_Value);
          /*
	  IF wsh_debug_interface.g_Debug THEN
	    write_output(make_space||x_Text||C_DELIMITER||x_Value);
	  END IF;
	  */

	EXCEPTION
	  WHEN OTHERS THEN
              wsh_debug_interface.g_Debug := FALSE;

	END dlog;


	/*===========================================================================

	  PROCEDURE NAME:	dlog - boolean

	===========================================================================*/
	PROCEDURE  dlog(x_Text IN VARCHAR2, x_Value IN BOOLEAN)
	IS

	  v_Temp	VARCHAR2(5);

	BEGIN

	  log(g_Module,x_Text, x_Value);
          /*
	  IF wsh_debug_interface.g_Debug THEN
	    IF x_Value THEN
	      v_Temp := 'TRUE';
	    ELSIF NOT x_Value THEN
	      v_Temp := 'FALSE';
	    END IF;
	    write_output(make_space||x_Text||C_DELIMITER||v_Temp);
	  END IF;
	  */

	EXCEPTION
	  WHEN OTHERS THEN
              wsh_debug_interface.g_Debug := FALSE;

	END dlog;


	/*===========================================================================

	  PROCEDURE NAME:	dlog - date

	===========================================================================*/
	PROCEDURE  dlog(x_Text IN VARCHAR2, x_Value IN DATE,
			x_Mask IN VARCHAR2 := 'DD-MON-YYYY HH:MI:SS PM')
	IS


	BEGIN

	  log(g_Module,x_Text, x_Value);
          /*
	  IF wsh_debug_interface.g_Debug THEN
	    write_output(make_space||x_Text||C_DELIMITER||TO_CHAR(x_Value, x_Mask));
	  END IF;
	  */

	EXCEPTION
	  WHEN OTHERS THEN
              wsh_debug_interface.g_Debug := FALSE;

	END dlog;

	/*===========================================================================

	  PROCEDURE NAME: dlogd - date, as a component of a table of records

	===========================================================================*/
	PROCEDURE  dlogd(x_Level IN NUMBER, x_Text1 IN VARCHAR2 :=NULL , x_Index IN NUMBER := NULL,

			x_Text2 IN VARCHAR2 := NULL, x_Value IN DATE := NULL)
	IS


	BEGIN

	  IF wsh_debug_interface.g_Debug THEN
	    IF g_DebugAll OR level_defined(x_Level) THEN
	      IF (x_Index IS NULL) AND (x_Text2 IS NULL) AND
		 (x_Value IS NULL) THEN
		write_output(make_space||x_Text1);
	      ELSE
		write_output(make_space||x_Text1||'('||x_Index||')'||x_Text2||C_DELIMITER||x_Value);

	      END IF;
	    END IF;
	  END IF;

	EXCEPTION
	  WHEN OTHERS THEN
              wsh_debug_interface.g_Debug := FALSE;

	END dlogd;

	/*===========================================================================

	  PROCEDURE NAME: dlogn - number, as a component of a table of records

	===========================================================================*/
	PROCEDURE  dlogn(x_Level IN NUMBER, x_Text1 IN VARCHAR2 :=NULL , x_Index IN NUMBER := NULL,

			x_Text2 IN VARCHAR2 := NULL, x_Value IN NUMBER := NULL)
	IS


	BEGIN

	  IF wsh_debug_interface.g_Debug THEN
	    IF g_DebugAll OR level_defined(x_Level) THEN
	      IF (x_Index IS NULL) AND (x_Text2 IS NULL) AND
		 (x_Value IS NULL) THEN
		write_output(make_space||x_Text1);
	      ELSE
		write_output(make_space||x_Text1||'('||x_Index||')'||x_Text2||C_DELIMITER||x_Value);

	      END IF;
	    END IF;
	  END IF;

	EXCEPTION
	  WHEN OTHERS THEN
		raise;

	END dlogn;






	PROCEDURE  push(x_Module IN VARCHAR2, x_name in varchar2)
	IS
	BEGIN
	  push(x_Module); -- for backward compatibility.
	EXCEPTION
	  WHEN OTHERS THEN
               wsh_debug_interface.g_Debug := FALSE;
	END push;

	/*===========================================================================

	  PROCEDURE NAME:	dpush

	===========================================================================*/
	PROCEDURE  dpush(x_Level IN NUMBER, x_Name IN VARCHAR2)
	IS
	  v_DebugMode	NUMBER;
	  v_Module	VARCHAR2(32767) := 'WSH.plsql.wsh.' || x_Name;
	BEGIN
	  push(v_Module); -- for backward compatibility.
	EXCEPTION
	  WHEN OTHERS THEN
               wsh_debug_interface.g_Debug := FALSE;
	END dpush;

	/*===========================================================================
	  PROCEDURE NAME:	dpush  -- Obsoleted

	===========================================================================*/
	/*
	PROCEDURE  dpush(x_Name IN VARCHAR2)
	IS
	BEGIN
	  IF wsh_debug_interface.g_Debug THEN
	    g_CallStack(g_CallStack.COUNT) := UPPER(x_Name);
	    tstart(x_Name);
	    write_output(make_space(1)||'Entering '||UPPER(x_Name)||' ('||TO_CHAR(sysdate,'MM/DD/YYYY HH24:MI')||')');

	  END IF;

	EXCEPTION
	  WHEN OTHERS THEN
		raise;

	END dpush;

	*/

/*===========================================================================
	  PROCEDURE NAME:	dpop

===========================================================================*/
PROCEDURE dpop(x_Level IN NUMBER, x_Context IN VARCHAR2 := NULL)
IS
  v_Module	VARCHAR2(32767) := 'WSH.plsql.';

BEGIN

  IF g_callStack.count > 0 THEN
    v_module := v_module || g_callStack(g_callStack.count-1);
  END IF;

  pop(v_Module,x_Context); -- for backward compatibility.
  /*
  IF wsh_debug_interface.g_Debug THEN
    IF g_DebugAll OR level_defined(x_Level) THEN
      IF x_Context IS NOT NULL THEN
        write_output(make_space(1)||'Exiting '||g_CallStack(g_CallStack.COUNT-1) ||' - '||x_Context
        ||' ('||tprint(g_CallStack(g_CallStack.COUNT-1))||')');
      ELSE
        write_output(make_space(1)||'Exiting '||g_CallStack(g_CallStack.COUNT-1)||
        ' ('||tprint(g_CallStack(g_CallStack.COUNT-1))||')');
      END IF;
      tstop(g_CallStack(g_CallStack.COUNT-1));
      g_CallStack.DELETE(g_CallStack.COUNT-1);
    END IF;
  END IF;
  */
EXCEPTION
  WHEN OTHERS THEN
    wsh_debug_interface.g_Debug := FALSE;
END dpop;

/*===========================================================================
       PROCEDURE NAME:	dpop
PROCEDURE  dpop(x_Context IN VARCHAR2 := NULL)
IS
BEGIN
  IF wsh_debug_interface.g_Debug THEN
    IF x_Context IS NOT NULL THEN
      write_output(make_space(1)||'Exiting '||g_CallStack(g_CallStack.COUNT-1)||
' - '||x_Context
     ||' ('||tprint(g_CallStack(g_CallStack.COUNT-1))||')');
    ELSE
      write_output(make_space(1)||'Exiting '||g_CallStack(g_CallStack.COUNT-1)||
                     ' ('||tprint(g_CallStack(g_CallStack.COUNT-1))||')');
    END IF;
    tstop(g_CallStack(g_CallStack.COUNT-1));
    g_CallStack.DELETE(g_CallStack.COUNT-1);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    raise;
END dpop;
===========================================================================*/

/********* The API set_debug_count is created for bug 6215206 for ITM Async process.
This api should not be called directly from any other APIs. ****************/
PROCEDURE set_debug_count
IS
BEGIN
   g_DebugCount := 0;
   g_Debugger_initialized := FALSE;
END set_debug_count;

END wsh_debug_sv;