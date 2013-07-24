
#include <sourcemod>
#include <sdktools>

#define AUTOLOAD_EXTENSIONS
#undef REQUIRE_EXTENSIONS

#define FFADE_IN			0x0001		// Just here so we don't pass 0 into the function
#define FFADE_OUT			0x0002		// Fade out (not in)
#define FFADE_MODULATE		0x0004		// Modulate (don't blend)
#define FFADE_STAYOUT		0x0008		// ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE			0x0010		// Purges all other fades, replacing them with this one

public Plugin:myinfo =  {
	name = "Admin Tools",
	author = "Berni",
	description = "",
	version = "0.1",
	url = "http://manni.ice-gfx.com/forum"
}

public OnPluginStart() {
	
	RegAdminCmd("sm_getclosestentity", Command_GetClosestEntity, ADMFLAG_ROOT);
	RegAdminCmd("sm_dumpentites", Command_DumpEntities, ADMFLAG_ROOT);
	RegAdminCmd("sm_setmovetype", Command_SetMoveType, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_extinguish", Command_Extinguish, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_setlightstyle", Command_SetLightStyle, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_teleporter", Command_Teleporter, ADMFLAG_ROOT);
	RegAdminCmd("sm_health", Command_Health, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_suitpower", Command_SuitPower, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_allweapons", Command_AllWeapons, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_shake", Command_Shake, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_spray", Command_Spray, ADMFLAG_CUSTOM4);
	//RegAdminCmd("sm_removespray", Command_RemoveSpray, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_setscore", Command_SetScore, ADMFLAG_ROOT);
	RegAdminCmd("sm_setdeaths", Command_SetDeaths, ADMFLAG_ROOT);
	RegAdminCmd("sm_setteamscore", Command_SetTeamScore, ADMFLAG_ROOT);
	RegAdminCmd("sm_setdatamapvalue", Command_SetDataMapValue, ADMFLAG_ROOT);
	RegAdminCmd("sm_getdatamapvalue", Command_GetDataMapValue, ADMFLAG_ROOT);
	RegAdminCmd("sm_getdatamapvaluevector", Command_GetDataMapValueVector, ADMFLAG_ROOT);
	RegAdminCmd("sm_rendermode", Command_SetRenderMode, ADMFLAG_ROOT);
	RegAdminCmd("sm_renderfx", Command_SetRenderFx, ADMFLAG_ROOT);
	RegAdminCmd("sm_website", Command_Website, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_connectbox", Command_ConnectBox, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_fexec", Command_FakeExecute, ADMFLAG_CUSTOM4);
	//RegAdminCmd("sm_cancelintermission", Command_CancelIntermission, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_firstperson", Command_Firstperson, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_thirdperson", Command_Thirdperson, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_testweapons", Command_TestWeapons, ADMFLAG_ROOT);
	RegAdminCmd("sm_testglow", Command_TestGlow, ADMFLAG_ROOT);
	RegAdminCmd("sm_reloadmap", Command_ReloadMap, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_listentities", Command_ListEntities, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_closestentity", Command_ClosestEntity, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_godent", Command_GodEnt, ADMFLAG_CUSTOM4);
	//RegAdminCmd("sm_cleanupmap2",		Command_CleanUpMap2, ADMFLAG_ROOT);
	RegAdminCmd("sm_freeze2",		Command_Freeze2, ADMFLAG_ROOT);
	RegAdminCmd("sm_unfreeze2",		Command_Unfreeze2, ADMFLAG_ROOT);
	RegAdminCmd("sm_debugvehicle",	Command_DebugVehicle, ADMFLAG_ROOT);
	RegAdminCmd("sm_puzzle",	Command_Puzzle, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_addoutput", Command_Addoutput, ADMFLAG_ROOT, "like ent_fire someentity addoutput 'wait 1'");
	RegAdminCmd("sm_fadein", Command_FadeIn, ADMFLAG_ROOT);
	RegAdminCmd("sm_fadeout", Command_FadeOut, ADMFLAG_ROOT);
	RegAdminCmd("sm_spawnent", Command_SpawnEnt, ADMFLAG_ROOT);
	RegAdminCmd("sm_spawnent", Command_SpawnEnt, ADMFLAG_ROOT);
	RegAdminCmd("sm_removeadmin", Command_RemoveAdmin, ADMFLAG_CUSTOM4);
	
	
	//HookUserMessage(GetUserMessageId("TextMsg"), MsgHook_TextMsg, true);
	//HookUserMessage(GetUserMessageId("SayText"), MsgHook_TextMsg, true);
	//HookUserMessage(GetUserMessageId("SayText2"), MsgHook_TextMsg, true);
	
	// Teleporter
	
	//HookEntityOutput("trigger_teleport", "OnStartTouch", Teleport_OnTrigger);
	//HookEntityOutput("logic_relay", "OnTrigger", LogicRelay_OnTrigger);
	
	//AddPlayerRunCommandHook(PlayerRunCommand);
	
	HookEvent("player_spawn", Event_Spawn);
	
	LoadTranslations("common.phrases");
}

public Action:Command_RemoveAdmin(client, args) {
	
	new AdminId:adminId = GetUserAdmin(client);
	
	RemoveAdmin(adminId);
	
	ReplyToCommand(client, "Your admin has been removed ! sm_reloadadmins to regain your admin rights.");
	
	return Plugin_Handled;
}

public Action:Command_SpawnEnt(client, args) {
	
	if (args <= 1) {
		return Plugin_Handled;
	}
	
	decl String:class[32];
	
	GetCmdArg(1, class, sizeof(class));
	
	new entity = CreateEntityByName(class);
	
	decl Float:pos[3];
	GetClientAimTargetEx(client, pos);
	
	if (args == 2) {
		decl String:model[PLATFORM_MAX_PATH];
		GetCmdArg(2, model, sizeof(model));
		PrecacheModel(model, true);
		DispatchKeyValue(entity, "model", model);
	}
	
	
	ActivateEntity(entity);
	DispatchSpawn(entity);
	
	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
	
	return Plugin_Handled;
}

public Event_Spawn(Handle:event, const String:name[], bool:broadcast) {
	
	decl String:map[128];
	GetCurrentMap(map, sizeof(map));
	
	if (StrEqual(map, "dm_357", false)) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		CreateTimer(0.1, Timer_PlayerSpawnDelayed, client);
	}
}

public Action:Timer_PlayerSpawnDelayed(Handle:timer, any:client) {
	
	if (!IsClientInGame(client)) {
		return Plugin_Continue;
	}
		
	new ammoOffset = FindSendPropOffs("CBasePlayer", "m_iAmmo");
	SetEntData(client, ammoOffset+16, 999, 4, true);
	GivePlayerWeapon(client, "weapon_357");
	
	return Plugin_Continue;
}

Addoutput(entity, String:output[]){
	SetVariantString(output);
	AcceptEntityInput(entity, "addoutput");
}

FindEntityByName(String:name[]) {
	
	decl String:m_iName[128];
	
	new maxEntities = GetMaxEntities();
	for (new entity=0; entity<maxEntities; ++entity) {
		
		if (IsValidEntity(entity)) {
			
			GetEntPropString(entity, Prop_Data, "m_iName", m_iName, sizeof(m_iName));
			
			if (StrEqual(name, m_iName, false)) {
				
				return entity;
			}
		}
	}
	
	return -1;
}

public Action:Command_Puzzle(client, args) {
	
	if(args == 0) {
		decl String:command[32];
		GetCmdArg(0, command, sizeof(command));
		
		ReplyToCommand(client, "[RP] Usage: %s <command>", command);
		return Plugin_Handled;
	}
	
	decl String:param[256];
	
	GetCmdArg(1, param, sizeof(param));
	
	if (StrEqual(param, "reset4wins", false)) {
		
		new entity = FindEntityByName("Recalltext3");
		if (entity != -1) {
			AcceptEntityInput(entity, "Display", client, client);
		}
		
		entity = FindEntityByName("ice2");
		if (entity != -1) {
			AcceptEntityInputDelayed(entity, "Kill", 0.5, client, client);
		}
		
		entity = FindEntityByName("Recall3");
		if (entity != -1) {
			AcceptEntityInputDelayed(entity, "ForceSpawn", 2.5, client, client);
		}
	}

	return Plugin_Handled;
}

AcceptEntityInputDelayed(dest, const String:input[], Float:delay=0.0, activator=-1, caller=-1, outputid=0) {
	
	new Handle:dp = INVALID_HANDLE;
	
	CreateDataTimer(delay, Timer_DelayedEntityInput, dp);
	
	WritePackCell(dp, dest);
	WritePackString(dp, input);
	WritePackCell(dp, activator);
	WritePackCell(dp, caller);
	WritePackCell(dp, outputid);
	
	ResetPack(dp);
}

public Action:Timer_DelayedEntityInput(Handle:timer, Handle:dp) {
	
	decl String:input[256];
	
	new dest = ReadPackCell(dp);
	ReadPackString(dp, input, sizeof(input));
	new activator = ReadPackCell(dp);
	new caller = ReadPackCell(dp);
	new outputid = ReadPackCell(dp);
	
	AcceptEntityInput(dest, input, activator,caller, outputid);
}

public Action:Command_Addoutput(client, args) {
	
	if(args == 0) {
		decl String:command[32];
		GetCmdArg(0, command, sizeof(command));
		
		ReplyToCommand(client, "[RP] Usage: %s <command>", command);
		return Plugin_Handled;
	}
	
	new String:commandline[255];
	new String:temp[255];
	new entity = GetClientAimTarget(client, false);
	
	for(new i=1;i<(args+1);i++){
		GetCmdArg(i, temp, sizeof(temp));
		StrCat(commandline, sizeof(commandline), temp);
		StrCat(commandline, sizeof(commandline), " ");
		//PrintToChat(client, "pos: %d - jobname: %s", i, jobname);
	}
	
	if(IsValidEntity(entity)){
		Addoutput(entity, commandline);
		ReplyToCommand(client, "[RP] Executed addoutput upon the entity you're looking at");
	}
	else {
		
		ReplyToCommand(client, "[RP] no entity where you are looking at");
	}
	return Plugin_Handled;
}


public Action:PlayerRunCommand(client, command_number, &Float:forwardmove, &Float:sidemove, &Float:upmove, &buttons, impulse, &weaponselect, &weaponsubtype, &mousedx, &mousedy) {
	
	new off_PlayerAmmo = FindSendPropOffs("CBasePlayer", "m_iAmmo");
	new weapon = GetEntDataEnt2(client, FindSendPropInfo("CHL2MP_Player", "m_hActiveWeapon"));
	SetEntPropFloat(weapon, Prop_Data, "m_flNextPrimaryAttack", 1.0);
	SetEntPropFloat(weapon, Prop_Data, "m_flNextSecondaryAttack", 1.0);
	SetEntProp(weapon, Prop_Data, "m_iClip1", 999);
	for(new i=0;i<80;i++){
		SetEntData(client, off_PlayerAmmo+i, 999, 4, true);
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	
	MarkNativeAsOptional("CleanUpMap");
	
	return APLRes_Success;
}

public Action:Command_DebugVehicle(client, args) {
	
	new m_hVehicle = GetEntDataEnt2(client, FindSendPropOffs("CBasePlayer", "m_hVehicle"));

	PrintToChat(client, "[Debug] m_hVehicle: %d", m_hVehicle);
}

/*public Action:Command_CleanUpMap2(client, args) {
	
	ReplyToCommand(client, "\x04[Entityspawner] Cleaning up map...");
	CleanUpMap();
	ReplyToCommand(client, "\x04[Entityrestore] Cleaning up map done !");
	
	return Plugin_Handled;
}*/

public Action:Command_GodEnt(client, args) {
	
	new entity = GetClientAimTarget(client, false);
	
	if (entity == -1) {
		ReplyToCommand(client, "\x04[SM] Error: No entity found where you are looking at !");
		
		return Plugin_Handled;
	}
	
	SetEntProp(entity, Prop_Data, "m_takedamage", 0, 1);
	
	ReplyToCommand(client, "\x04[SM] Entity %d is now undestroyable !", entity);
	
	return Plugin_Handled;
}

/*public Action:OnPhysGunPickUp(client, &entity) {
	
	PrintToChatAll("Debug: %N %d", client, entity);
	
	return Plugin_Continue;
}

public Action:OnPhysGunPickUp2(client, &entity, &masslimit, &sizeLimit) {
	masslimit = 99999;
	
	return Plugin_Continue;
}*/

public Action:Command_ReloadMap(client, args) {
	
	decl String:mapName[64];
	GetCurrentMap(mapName, sizeof(mapName));
	ServerCommand("changelevel %s", mapName);
	
	return Plugin_Handled;
}

stock set_rendering(index, RenderFx:fx=RENDERFX_NONE, r=255, g=255, b=255, RenderMode:render=RENDER_NORMAL, amount=255)
{
	new RenderOffs = FindSendPropOffs("CBasePlayer", "m_clrRender");

	SetEntProp(index, Prop_Send, "m_nRenderFX", _:fx, 1);
	SetEntProp(index, Prop_Send, "m_nRenderMode", _:render, 1);	
	SetEntData(index, RenderOffs, r, 1, true);
	SetEntData(index, RenderOffs + 1, g, 1, true);
	SetEntData(index, RenderOffs + 2, b, 1, true);
	SetEntData(index, RenderOffs + 3, amount, 1, true);	
}

public Action:Command_TestGlow(client, args) {
	new entity = GetClientAimTarget(client);
	
	set_rendering(entity, RENDERFX_GLOWSHELL, 255,0,0, RENDER_GLOW, 127);
	
	PrintToChatAll("\x04Set glow of player %N");

	return Plugin_Handled;
}

public Action:Command_ListEntities(client, args) {
	
	if (args == 0) {
		ReplyToCommand(client, "\x04[SM] Usage: sm_listentities <classname>");
		return Plugin_Handled;
	}
	
	decl String:arg1[64];
	decl String:modelName[PLATFORM_MAX_PATH], String:className[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	new maxEntities = GetMaxEntities();
	for (new entity=0; entity<maxEntities; ++entity) {
				
		if (IsValidEntity(entity)) {
			GetEntPropString(entity, Prop_Data, "m_ModelName", modelName, sizeof(modelName));

			if (StrContains(modelName, arg1) == 0) {
				ReplyToCommand(client, "Index: %d model: %s", entity, modelName);
			}
			
			GetEdictClassname(entity, className, sizeof(className));

			if (StrContains(modelName, arg1) == 0) {
				ReplyToCommand(client, "Index: %d class: %s", entity, className);
			}
		}
	}

	
	return Plugin_Handled;
}

public Action:Command_ClosestEntity(client, args) {
	
	decl Float:clientOrigin[3], Float:entityOrigin[3];
	
	GetClientAbsOrigin(client, clientOrigin);
	
	new closestEntity = 0, Float:distance = 99999.0;
	
	new maxEntities = GetMaxEntities();
	for (new entity=MAXPLAYERS+1; entity<maxEntities; ++entity) {
				
		if (IsValidEntity(entity)) {

			new Float:entDistance = GetVectorDistance(clientOrigin, entityOrigin);
		
			if (entDistance < distance) {
				closestEntity = entity;
				distance = entDistance;
			}
		}
	}
	
	decl String:class[64], String:modelName[PLATFORM_MAX_PATH];
	
	GetEdictClassname(closestEntity, class, sizeof(class));
	GetEntPropString(closestEntity, Prop_Data, "m_ModelName", modelName, sizeof(modelName));
	
	ReplyToCommand(client, "\x04Closest Entity: Index: %d class: %s model: %s", closestEntity, class, modelName);
	
	return Plugin_Handled;
}

public Action:Command_TestWeapons(client, args) {
	
	decl String:class[64];
	
	for (new i=0; i<100; ++i) {
		new weapon = GetPlayerWeaponSlot(client, i);
		
		if (weapon != -1) {
			GetEntityNetClass(weapon, class, sizeof(class));
			ReplyToCommand(client, "Debug: Slot: %d Weapon: %s", i, class);
		}
	}
	
	return Plugin_Handled;
}

public OnClientAuthorized(client, const String:auth[]) {
}

/*public Action:Command_CancelIntermission(client, args) {
	CancelIntermission();
	new Handle:mp_timelimit = FindConVar("mp_timelimit");
	SetConVarInt(mp_timelimit, GetConVarInt(mp_timelimit)+5);
	
	new iMaxClients = GetMaxClients();
	for (new player=1; player<iMaxClients; ++player) {
	
		if (IsClientInGame(player)) {
			new m_fFlags = GetEntProp(player, Prop_Send, "m_fFlags");
			m_fFlags &= ~(1<<5);
			SetEntProp(player, Prop_Send, "m_fFlags", m_fFlags);
			
			ShowVGUIPanel(client, "scores", INVALID_HANDLE, false);
		}
	}
	
	PrintToChatAll("\x04[SM] Mapchange has been cancelled... the game continues");
	
	return Plugin_Handled;
}*/

public Action:Command_Freeze2(client, args) {
	if (args < 1) {
		ReplyToCommand(client, "\x04[SM] \x01Usage: sm_freeze <target>");
		
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl bool:tn_is_ml;
	
	new target_count = ProcessTargetString(
			target,
			client,
			target_list,
			sizeof(target_list),
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml
	);
	
	if (target_count <= 0) {
		ReplyToCommand(client, "\x04[SM] \x01 Error: no valid targets found");
		
		return Plugin_Handled;
	}
	
	new m_fFlags;
	
	for (new i=0; i<target_count; ++i) {
		m_fFlags = GetEntProp(target_list[i], Prop_Send, "m_fFlags");
		m_fFlags |= 1<<5;
		SetEntProp(target_list[i], Prop_Send, "m_fFlags", m_fFlags);
	}
	
	LogAction(client, -1, "\"%L\" freezed target %s", client, target);
	ShowActivity2(client, "[SM] ", "freezed target %s", target);
	
	return Plugin_Handled;
}

public Action:Command_Unfreeze2(client, args) {
	if (args < 1) {
		ReplyToCommand(client, "\x04[SM] \x01Usage: sm_unfreeze <target>");
		
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl bool:tn_is_ml;
	
	new target_count = ProcessTargetString(
			target,
			client,
			target_list,
			sizeof(target_list),
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml
	);
	
	if (target_count <= 0) {
		ReplyToCommand(client, "\x04[SM] \x01 Error: no valid targets found");
		
		return Plugin_Handled;
	}
	
	new m_fFlags;
	
	for (new i=0; i<target_count; ++i) {
		m_fFlags = GetEntProp(target_list[i], Prop_Send, "m_fFlags");
		m_fFlags &= ~1<<5;
		SetEntProp(target_list[i], Prop_Send, "m_fFlags", m_fFlags);
	}
	
	LogAction(client, -1, "\"%L\" unfreezed target %s", client, target);
	ShowActivity2(client, "[SM] ", "unfreezed target %s", target);
	
	return Plugin_Handled;
}

public LogicRelay_OnTrigger(const String:output[], caller, activator, Float:delay) {
	PrintToChatAdmins("\x04[SM] logic_relay triggered by %d !", activator);
}

public Action:Command_DumpEntities(client, args) {
	decl String:netClass[256], String:edictClass[256];
	
	for (new i=0; i<=GetMaxEntities(); i++) {
		if(IsValidEntity(i) && GetEntityNetClass(i, netClass, sizeof(netClass))) {
			GetEdictClassname(i, edictClass, sizeof(edictClass));
			
			if (StrEqual(edictClass, "trigger_teleport")) {
				AcceptEntityInput(i, "enable");
			}
			
			ReplyToCommand(client, "EdictClass: %s NetClass: %s", edictClass, netClass);
		}
	}
	
}

public Action:Command_SetMoveType(client, args) {
	
	if (args < 1) {
		PrintToChat(client, "\x04[SM] Usage: sm_setmovetype <movetype>");
		
		return Plugin_Handled;
	}
	
	new String:arg[8];
	
	GetCmdArg(1, arg, sizeof(arg));
	new movetype = StringToInt(arg, sizeof(arg));
	
	new entity = GetClientAimTarget(client, false);
	
	if (entity > 0) {
		SetEntityMoveType(entity, MoveType:movetype);
	}	
	
	
	return Plugin_Handled;
}

public Action:Command_SetRenderMode(client, args) {
	
	if (args < 1) {
		PrintToChat(client, "\x04[SM] Usage: sm_setrendermode <rendermode>");
		
		return Plugin_Handled;
	}
	
	new String:arg[8];
	
	GetCmdArg(1, arg, sizeof(arg));
	new rendermode = StringToInt(arg, sizeof(arg));
	
	new entity = GetClientAimTarget(client, false);
	
	if (entity > 0) {
		SetEntityRenderMode(entity, RenderMode:rendermode);
	}	
	
	
	return Plugin_Handled;
}

public Action:Command_SetRenderFx(client, args) {
	
	if (args < 1) {
		PrintToChat(client, "\x04[SM] Usage: sm_setrenderfx <num>");
		
		return Plugin_Handled;
	}
	
	new String:arg[8];
	
	GetCmdArg(1, arg, sizeof(arg));
	new num = StringToInt(arg, sizeof(arg));
	
	new entity = GetClientAimTarget(client, false);
	
	if (entity > 0) {
		SetEntityRenderFx(entity, RenderFx:num);
	}	
	
	
	return Plugin_Handled;
}

public PrintToChatAdmins(String:format[], any:...) {
	new String:buffer[192];
	
	VFormat(buffer, sizeof(buffer), format, 2);
	
	new iMaxClients = GetMaxClients();
	
	for (new client=1; client<iMaxClients; ++client) {
		
		if (IsClientInGame(client)) {
			new AdminId:aid = GetUserAdmin(client);
			
			if (aid != INVALID_ADMIN_ID && GetAdminFlag(aid, Admin_Generic)) {
				PrintToChat(client, buffer);
				
			}
		}
		
	}
}

public GetClosestEntity(client) {
	decl Float:vec_player[3], Float:vec[3];
	new Float:distance;
	new closestEnt = -1;
	//decl String:edictClass[256];
	
	GetClientAbsOrigin(client, vec_player);
	
	for (new i=1; i<=GetMaxEntities(); i++) {
		if(IsValidEntity(i) && i != client) {
			if (GetEntSendPropOffs(i, "m_vecOrigin") == -1) {
				continue;
			}
			
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", vec);

			
			/*GetEdictClassname(i, edictClass, sizeof(edictClass));
			
			if (StrEqual(edictClass, "team_manager")) {
			continue;
			}*/
			
			new Float:dist = GetVectorDistance(vec_player, vec);
			
			if (distance == 0.0 || dist < distance) {
				distance = dist;
				closestEnt = i;
			}
		}
	}
	
	return closestEnt;
}


public GetClosestEntityByClassName(client, String:className[]) {
	decl Float:vec_player[3], Float:vec[3];
	new Float:distance;
	new teleporter = -1, entity = -1;
	GetClientAbsOrigin(client, vec_player);
	
	while ((entity = FindEntityByClassname(entity, className)) != -1) {
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vec);
		
		new Float:dist = GetVectorDistance(vec_player, vec);
		
		if (distance == 0.0 || dist < distance) {
			distance = dist;
			teleporter = entity;
		}
	}
	
	return teleporter;
}

public Action:Command_GetClosestEntity(client, args) {
	decl String:netClass[256], String:edictClass[256], String:model[PLATFORM_MAX_PATH];
	
	new entity = GetClosestEntity(client);
	
	GetEntityNetClass(entity, netClass, sizeof(netClass));
	GetEdictClassname(entity, edictClass, sizeof(edictClass));
	GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
	
	ReplyToCommand(client, "EdictClass: %s NetClass: %s Model: %s", edictClass, netClass, model);
	
	/*if (strcmp(edictClass, "weapon_meelee")) {
		decl String:m_strMapSetScriptName[256];
		GetEntPropString(entity, Prop_Data, "m_strMapSetScriptName", m_strMapSetScriptName, sizeof(m_strMapSetScriptName));
		new m_nViewModelIndex = GetEntProp(entity, Prop_Data, "m_nViewModelIndex");
		new Float:m_fMinRange1 = GetEntPropFloat(entity, Prop_Data, "m_fMinRange1");
		new Float:m_fMinRange2 = GetEntPropFloat(entity, Prop_Data, "m_fMinRange2");
		new Float:m_fMaxRange1 = GetEntPropFloat(entity, Prop_Data, "m_fMaxRange1");
		new Float:m_fMaxRange2 = GetEntPropFloat(entity, Prop_Data, "m_fMaxRange2");
		ReplyToCommand(client, "m_strMapSetScriptName: %s m_nViewModelIndex: %d m_fMinRange1: %f m_fMinRange2: %f m_fMaxRange1: %f m_fMaxRange2: %f", m_strMapSetScriptName, m_nViewModelIndex, m_fMinRange1, m_fMinRange2, m_fMaxRange1, m_fMaxRange2);
	}*/
	
}

public Action:Command_Teleporter(client, args) {
	if (args != 1) {
		ReplyToCommand(client, "\x04[SM] Usage: sm_teleporter <input>");
		
		return Plugin_Handled;
	}
	
	new teleporter = GetClosestEntityByClassName(client, "trigger_teleport");
	
	if (teleporter > 0) {
		
		new String:strArg[192];
		
		GetCmdArg(1, strArg, sizeof(strArg));
		
		AcceptEntityInput(teleporter, strArg);
		
		ReplyToCommand(client, "\x04[SM] Teleporter-Input: %s", strArg);
	}
	else {
		ReplyToCommand(client, "\x04[SM] No teleporter found");
	}
	
	return Plugin_Handled;
}

public Teleport_OnTrigger(const String:output[], caller, activator, Float:delay) {
	//PrintToChatAdmins("Debug: caller: %d activator: %d", caller, activator);
	
	/*if (GetAdminFlag(GetUserAdmin(activator), Admin_Root)) {
	PrintToChat(activator, "\x04[SM] Debug: Teleporter triggered");
	}*/
}

public Action:Command_Health(client, args) {
	if (args != 2) {
		ReplyToCommand(client, "\x04[SM] \x01Usage: sm_health <target> <value>");
		
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH], String:arg2[8];
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	new health = StringToInt(arg2);
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl bool:tn_is_ml;
	
	new target_count = ProcessTargetString(
			target,
			client,
			target_list,
			sizeof(target_list),
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml
	);
	
	if (target_count <= 0) {
		ReplyToCommand(client, "\x04[SM] \x01 Error: no valid targets found");
		
		return Plugin_Handled;
	}
	
	for (new i=0; i<target_count; ++i) {
		SetEntProp(target_list[i], Prop_Send, "m_iHealth", health, 1);
		SetEntProp(target_list[i], Prop_Data, "m_iHealth", health, 1);
	}
	
	LogAction(client, -1, "\"%L\" sets health to %d for target %s", client, health, target);
	ShowActivity2(client, "[SM] ", "sets healths to %d for target %s", health, target);
	
	return Plugin_Handled;
}

public Action:Command_Extinguish(client, args) {
	if (args != 1) {
		ReplyToCommand(client, "\x04[SM] \x01Usage: sm_extinguish <target>>");
		
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl bool:tn_is_ml;
	
	new target_count = ProcessTargetString(
			target,
			client,
			target_list,
			sizeof(target_list),
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml
	);
	
	if (target_count <= 0) {
		ReplyToCommand(client, "\x04[SM] \x01 Error: no valid targets found");
		
		return Plugin_Handled;
	}
	else {
		for (new i=0; i<target_count; ++i) {
			ExtinguishEntity(target_list[i]);
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_SetLightStyle(client, args) {
	if (args != 1) {
		ReplyToCommand(client, "\x04[SM] \x01Usage: sm_setlightstyle <style>");
		
		return Plugin_Handled;
	}
	
	decl String:arg[8];
	GetCmdArg(1, arg, sizeof(arg));
	
	SetLightStyle(0, arg);
	
	LogAction(client, -1, "\"%L\" set the Lightstyle to \"%s\"", client, arg);
	ShowActivity2(client, "[SM] ", "set the Lightstyle to %s", arg);
	
	return Plugin_Handled;
}

public Action:Command_SuitPower(client, args) {
	if (args != 2) {
		ReplyToCommand(client, "\x04[SM] \x01Usage: sm_suitpower <target> <value>");
		
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH], String:arg2[8];
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	new suitpower = StringToInt(arg2);
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl bool:tn_is_ml;
	
	new target_count = ProcessTargetString(
			target,
			client,
			target_list,
			sizeof(target_list),
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml
	);
	
	if (target_count <= 0) {
		ReplyToCommand(client, "\x04[SM] \x01 Error: no valid targets found");
		
		return Plugin_Handled;
	}
	
	/*new Handle:msg = StartMessage("Battery", target_list, target_count, USERMSG_BLOCKHOOKS);
	BfWriteShort(msg, suitpower);
	EndMessage();*/
	for (new i=0; i<target_count; ++i) {
		SetEntProp(target_list[i], Prop_Data, "m_ArmorValue", suitpower, 1);
	}
	
	LogAction(client, -1, "\"%L\" set suitpower to %d on target %s", client, suitpower, target);
	ShowActivity2(client, "[SM] ", "set suitpower to %d on target %s", suitpower, target);
	
	return Plugin_Handled;
}

stock GivePlayerWeapon(client, String:weapon[]) {
	new ent_weapon = GivePlayerItem(client, weapon);
	
	return ent_weapon;
}

public Action:Command_AllWeapons(client, args) {
	if (args < 1) {
		ReplyToCommand(client, "\x04[SM] \x01Usage: sm_allweapons <target>");
		
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl bool:tn_is_ml;
	
	new target_count = ProcessTargetString(
	target,
	client,
	target_list,
	sizeof(target_list),
	COMMAND_FILTER_ALIVE,
	target_name,
	sizeof(target_name),
	tn_is_ml
	);
	
	if (target_count <= 0) {
		ReplyToCommand(client, "\x04[SM] \x01 Error: no valid targets found");
		
		return Plugin_Handled;
	}
	
	for (new i=0; i<target_count; ++i) {
		
		new ammooffset = FindSendPropOffs("CBasePlayer", "m_iAmmo");
		
		for (new n=0; n<=100; n+=4) {
		SetEntData(target_list[i], ammooffset+n, 999, 4, true); // AR2
		SetEntData(target_list[i], ammooffset+n, 999, 4, true); // AlyxGun
		SetEntData(target_list[i], ammooffset+n, 999, 4, true); // Pistol
		SetEntData(target_list[i], ammooffset+n, 999, 4, true); // SMG1
		SetEntData(target_list[i], ammooffset+n, 999, 4, true); // 357
		SetEntData(target_list[i], ammooffset+n, 999, 4, true); // XBowBolt
		SetEntData(target_list[i], ammooffset+n, 999, 4, true); // Buckshot
		SetEntData(target_list[i], ammooffset+n, 999, 4, true); // RPG_Round
		SetEntData(target_list[i], ammooffset+n, 999, 4, true); // SMG1_Grenade
		SetEntData(target_list[i], ammooffset+n, 999, 4, true); // SniperRound
		SetEntData(target_list[i], ammooffset+n, 999, 4, true); // SniperPenetratedRound
		SetEntData(target_list[i], ammooffset+n, 999, 4, true); // Grenade
		SetEntData(target_list[i], ammooffset+n, 999, 4, true); // Thumper
		SetEntData(target_list[i], ammooffset+n, 999, 4, true); // Gravity
		SetEntData(target_list[i], ammooffset+n, 999, 4, true); // Battery
		SetEntData(target_list[i], ammooffset+n, 999, 4, true); // GaussEnergy
		SetEntData(target_list[i], ammooffset+n, 999, 4, true); // CombineCannon
		SetEntData(target_list[i], ammooffset+n, 999, 4, true); // AirboatGun
		SetEntData(target_list[i], ammooffset+n, 999, 4, true); // StriderMinigun
		SetEntData(target_list[i], ammooffset+n, 999, 4, true); // StriderMinigunDirect
		SetEntData(target_list[i], ammooffset+n, 999, 4, true); // HelicopterGun
		SetEntData(target_list[i], ammooffset+n, 999, 4, true); // AR2AltFire
		SetEntData(target_list[i], ammooffset+n, 999, 4, true); // Grenade
		SetEntData(target_list[i], ammooffset+n, 999, 4, true); // Hopwire
		SetEntData(target_list[i], ammooffset+n, 999, 4, true); // CombineHeavyCannon
		}
		
		GivePlayerWeapon(target_list[i], "weapon_stunstick");
		GivePlayerWeapon(target_list[i], "weapon_smg1");
		GivePlayerWeapon(target_list[i], "weapon_frag");
		GivePlayerWeapon(target_list[i], "weapon_crowbar");
		GivePlayerWeapon(target_list[i], "weapon_pistol");
		GivePlayerWeapon(target_list[i], "weapon_ar2");
		GivePlayerWeapon(target_list[i], "weapon_shotgun");
		GivePlayerWeapon(target_list[i], "weapon_physcannon");
		GivePlayerWeapon(target_list[i], "weapon_bugbait");
		GivePlayerWeapon(target_list[i], "weapon_rpg");
		GivePlayerWeapon(target_list[i], "weapon_357");
		GivePlayerWeapon(target_list[i], "weapon_crossbow");
		//GivePlayerWeapon(target_list[i], "weapon_cubemap");
		GivePlayerWeapon(target_list[i], "weapon_slam");
		
	}
	
	LogAction(client, -1, "\"%L\" gives all weapons to %s", client, target);
	ShowActivity2(client, "[SM] ", "gives all weapons to %s", target);
	
	return Plugin_Handled;
}

#define	SHAKE_START					0			// Starts the screen shake for all players within the radius.
#define	SHAKE_STOP					1			// Stops the screen shake for all players within the radius.
#define	SHAKE_AMPLITUDE				2			// Modifies the amplitude of an active screen shake for all players within the radius.
#define	SHAKE_FREQUENCY				3			// Modifies the frequency of an active screen shake for all players within the radius.
#define	SHAKE_START_RUMBLEONLY		4			// Starts a shake effect that only rumbles the controller, no screen effect.
#define	SHAKE_START_NORUMBLE		5			// Starts a shake that does NOT rumble the controller.

public Action:Command_Shake(client, args) {
	if (args == 0) {
		ReplyToCommand(client, "\x04[SM] \x01Usage: sm_shake <target> <amplitude>");
		
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH];
	GetCmdArg(1, target, sizeof(target));
	
	
	new Float:shakepower = 100.0;
	
	if (args == 2) {
		decl String:arg2[8];
		GetCmdArg(2, arg2, sizeof(arg2));
		shakepower = StringToFloat(arg2);
	}
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl bool:tn_is_ml;
	
	new target_count = ProcessTargetString(
			target,
			client,
			target_list,
			sizeof(target_list),
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml
	);
	
	if (target_count <= 0) {
		ReplyToCommand(client, "\x04[SM] \x01 Error: no valid targets found");
		
		return Plugin_Handled;
	}
	
	new Handle:msg = StartMessage("Shake", target_list, target_count, USERMSG_BLOCKHOOKS);
	BfWriteByte(msg, SHAKE_START);	// Shake Command
	BfWriteFloat(msg, shakepower);		// shake magnitude/amplitude
	BfWriteFloat(msg, 150.0);		// shake noise frequency
	BfWriteFloat(msg, 3.0);			// shake lasts this long
	EndMessage();
	
	return Plugin_Handled;
}

public GetClientAimTargetEx(client, Float:pos[3]) {
	if(client < 1) {
		return -1;
	}

	decl Float:vAngles[3], Float:vOrigin[3];
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID_BRUSHONLY, RayType_Infinite, TraceEntityFilterPlayer);
	
	if(TR_DidHit(trace)){
		
		TR_GetEndPosition(pos, trace);
		
		new entity = TR_GetEntityIndex(trace);
		
		CloseHandle(trace);
		
		return entity;
	}
	
	CloseHandle(trace);
	
	return -1;
}


public bool:TraceEntityFilterPlayer(entity, contentsMask) {
	return entity > MAXPLAYERS;
}

public Action:Command_Spray(client, args) {
	
	new target;
	
	if (args == 1) {
		decl String:arg[MAX_NAME_LENGTH];
		GetCmdArg(1, arg, sizeof(arg));
		
		target = FindTarget(client, arg, false, false);
		
		if (!target) {
			ReplyToCommand(client, "[SM] Error: Invalid player name");
			return Plugin_Handled;
		}
		
	}
	else {
		target=client;
	}
	
	
	new Float:vEyeAngles[3], Float:vAbsOrigin[3], Float:vEyePosition[3], Float:vForward[3], Float:vEndPoint[3], Float:vEndPos[3];
	
	GetClientEyePosition(client, vEyePosition);
	GetClientEyeAngles(client, vEyeAngles);
	GetClientAbsOrigin(client, vAbsOrigin);
	
	GetAngleVectors(vEyeAngles, vForward, NULL_VECTOR, NULL_VECTOR);
	
	for (new axis=0; axis<sizeof(vEndPoint); ++axis) {
		vEndPoint[axis] = vEyePosition[axis] + vForward[axis] * 512.0;
	}
	
	new Handle:trace = TR_TraceRayFilterEx(vEyePosition, vEndPoint, MASK_SOLID_BRUSHONLY, RayType_EndPoint, TraceEntityFilterPlayer);
	
	if(TR_DidHit(trace)){
		TR_GetEndPosition(vEndPos, trace);
		
		new traceEntIndex = TR_GetEntityIndex();
		
		TE_Start("Player Decal");
		TE_WriteVector("m_vecOrigin", vEndPos);
		TE_WriteNum("m_nEntity", traceEntIndex);
		TE_WriteNum("m_nPlayer", target);
		TE_SendToAll();
		
		EmitSoundToAll("misc/sprayer.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.6);
		
		PrintToChat(client, "\x04[SM] Spray sprayed !");
	}
	else {
		PrintToChat(client, "\x04[SM] Error: No Solid entity found !");
	}
	
	CloseHandle(trace);
	
	return Plugin_Handled;
}

/*public Action:Command_RemoveSpray(client, args) {
new target;

if (args == 1) {
decl String:arg[MAX_NAME_LENGTH];
GetCmdArg(1, arg, sizeof(arg));

target = FindTarget(client, arg, false, false);

if (!target) {
ReplyToCommand(client, "[SM] Error: Invalid player name");
return Plugin_Handled;
}

}
else {
target=client;
}

new Float:vEndPos[3];

TE_Start("Player Decal");
TE_WriteVector("m_vecOrigin", vEndPos);
TE_WriteNum("m_nEntity", 0);
TE_WriteNum("m_nPlayer", target);
TE_SendToAll();

return Plugin_Handled;
}*/

public Action:Command_SetScore(client, args) {
	if (args != 2) {
		ReplyToCommand(client, "\x04[SM] \x01Usage: sm_setscore <target> <value>");
		
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH], String:arg2[8];
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	new frags = StringToInt(arg2);
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl bool:tn_is_ml;
	
	new target_count = ProcessTargetString(
			target,
			client,
			target_list,
			sizeof(target_list),
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml
	);
	
	if (target_count <= 0) {
		ReplyToCommand(client, "\x04[SM] \x01 Error: no valid targets found");
		
		return Plugin_Handled;
	}
	
	for (new i=0; i<target_count; ++i) {
		SetEntProp(target_list[i], Prop_Data, "m_iFrags", frags, 1);
	}
	
	LogAction(client, -1, "\"%L\" sets score of target %s to %d", client, target, frags);
	ShowActivity2(client, "[SM] ", "sets score of target %s to %d", target, frags);
	
	return Plugin_Handled;
}

public Action:Command_SetDeaths(client, args) {
	if (args != 2) {
		ReplyToCommand(client, "\x04[SM] \x01Usage: sm_setdeaths <target> <value>");
		
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH], String:arg2[8];
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	new deaths = StringToInt(arg2);
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl bool:tn_is_ml;
	
	new target_count = ProcessTargetString(
			target,
			client,
			target_list,
			sizeof(target_list),
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml
	);
	
	if (target_count <= 0) {
		ReplyToCommand(client, "\x04[SM] \x01 Error: no valid targets found");
		
		return Plugin_Handled;
	}
	
	for (new i=0; i<target_count; ++i) {
		SetEntProp(target_list[i], Prop_Data, "m_iDeaths", deaths, 1);
	}
	
	LogAction(client, -1, "\"%L\" sets deaths of target %s to %d", client, target, deaths);
	ShowActivity2(client, "[SM] ", "sets deaths of target %s to %d", target, deaths);
	
	return Plugin_Handled;
}

public bool:_SetTeamScore(client, index, value) {
	
	new team = MAXPLAYERS + 1;
	
	team = FindEntityByClassname(-1, "team_manager");
	
	while (team != -1) {
		
		if (GetEntProp(team, Prop_Send, "m_iTeamNum", 1) == index) {
			
			SetEntProp(team, Prop_Send, "m_iScore", value, 4);
			ChangeEdictState(team, GetEntSendPropOffs(team, "m_iScore"));
			
			return true;
		}
		
		team = FindEntityByClassname(team, "team_manager");
	}
	
	return false;
}

public Action:Command_SetTeamScore(client, args) {
	
	if (args != 2) {
		ReplyToCommand(client, "\x04[SM] \x01Usage: sm_setteamscore <team> <value>");
		
		return Plugin_Handled;
	}
	
	decl String:str_team[8], String:arg2[8];
	GetCmdArg(1, str_team, sizeof(str_team));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	new team = StringToInt(str_team);
	new teamscore = StringToInt(arg2);
	
	_SetTeamScore(client, team, teamscore);
	
	LogAction(client, -1, "\"%L\" sets team score of team %d to %d", client, team, teamscore);
	ShowActivity2(client, "[SM] ", "sets teamscore of team %d to %d", team, teamscore);
	
	
	return Plugin_Handled;
}

public Action:Command_SetDataMapValue(client, args) {
	if (args != 3) {
		ReplyToCommand(client, "\x04[SM] \x01Usage: sm_setdatamapvalue <target> <offset> <value>");
		
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH], String:offset[64], String:str_value[8];
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, offset, sizeof(offset));
	GetCmdArg(3, str_value, sizeof(str_value));
	
	new value = StringToInt(str_value);
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl bool:tn_is_ml;
	
	new target_count = ProcessTargetString(
			target,
			client,
			target_list,
			sizeof(target_list),
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml
	);
	
	if (target_count <= 0) {
		ReplyToCommand(client, "\x04[SM] \x01 Error: no valid targets found");
		
		return Plugin_Handled;
	}
	
	for (new i=0; i<target_count; ++i) {
		SetEntProp(target_list[i], Prop_Data, offset, value, 1);
	}
	
	return Plugin_Handled;
}

public Action:Command_GetDataMapValue(client, args) {
	if (args != 2) {
		ReplyToCommand(client, "\x04[SM] \x01Usage: sm_setdatamapvalue <target> <offset>");
		
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH], String:offset[64];
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, offset, sizeof(offset));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl bool:tn_is_ml;
	
	new target_count = ProcessTargetString(
			target,
			client,
			target_list,
			sizeof(target_list),
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml
	);
	
	if (target_count <= 0) {
		ReplyToCommand(client, "\x04[SM] \x01 Error: no valid targets found");
		
		return Plugin_Handled;
	}
	
	for (new i=0; i<target_count; ++i) {
		new value = GetEntProp(target_list[i], Prop_Data, offset, 1);
		
		ReplyToCommand(client, "\x04[SM] Entity: %d Offset: %d Value: %d", target_list[i], offset, value);
	}
	
	return Plugin_Handled;
}

public Action:Command_GetDataMapValueVector(client, args) {
	if (args != 2) {
		ReplyToCommand(client, "\x04[SM] \x01Usage: sm_setdatamapvalue <target> <offset>");
		
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH], String:offset[64];
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, offset, sizeof(offset));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl bool:tn_is_ml;
	
	new target_count = ProcessTargetString(
			target,
			client,
			target_list,
			sizeof(target_list),
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml
	);
	
	if (target_count <= 0) {
		ReplyToCommand(client, "\x04[SM] \x01 Error: no valid targets found");
		
		return Plugin_Handled;
	}
	
	decl Float:value[3];
	
	for (new i=0; i<target_count; ++i) {
		GetEntPropVector(target_list[i], Prop_Data, offset, value);
		
		ReplyToCommand(client, "\x04[SM] Entity: %d Offset: %d Value: %f %f %f", target_list[i], offset, value[0], value[1], value[2]);
	}
	
	return Plugin_Handled;
}

public Action:Command_Website(client, args) {
	if (args != 2) {
		ReplyToCommand(client, "\x04[SM] \x01Usage: sm_website <target> address");
		
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH], String:website[64];
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, website, sizeof(website));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl bool:tn_is_ml;
	
	new target_count = ProcessTargetString(
			target,
			client,
			target_list,
			sizeof(target_list),
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml
	);
	
	if (target_count <= 0) {
		ReplyToCommand(client, "\x04[SM] \x01 Error: no valid targets found");
		
		return Plugin_Handled;
	}
	
	for (new i=0; i<target_count; ++i) {
		ShowMOTDPanel(target_list[i], website, website, MOTDPANEL_TYPE_URL);
	}
	
	return Plugin_Handled;
}

public Action:Command_ConnectBox(client, args) {
	if (args != 2) {
		ReplyToCommand(client, "\x04[SM] \x01Usage: sm_connectBox <target> IP:port");
		
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH], String:address[64];
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, address, sizeof(address));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl bool:tn_is_ml;
	
	new target_count = ProcessTargetString(
			target,
			client,
			target_list,
			sizeof(target_list),
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml
	);
	
	if (target_count <= 0) {
		ReplyToCommand(client, "\x04[SM] \x01 Error: no valid targets found");
		
		return Plugin_Handled;
	}
	
	for (new i=0; i<target_count; ++i) {
		DisplayAskConnectBox(target_list[i], 10.0, address);
	}
	
	return Plugin_Handled;
}

public Action:Command_FakeExecute(client, args) {
	if (args != 2) {
		ReplyToCommand(client, "\x04[SM] \x01Usage: sm_fexec <target> <command>");
		
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH], String:command[64];
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, command, sizeof(command));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl bool:tn_is_ml;
	
	new target_count = ProcessTargetString(
			target,
			client,
			target_list,
			sizeof(target_list),
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml
	);
	
	if (target_count <= 0) {
		ReplyToCommand(client, "\x04[SM] \x01 Error: no valid targets found");
		
		return Plugin_Handled;
	}
	
	for (new i=0; i<target_count; ++i) {
		FakeClientCommand(target_list[i], command);
	}
	
	return Plugin_Handled;
}

public Action:Command_Firstperson(client, args) {
	if (client == 0) return Plugin_Handled;
	
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
	
	ReplyToCommand(client, "[SM] Firstperson mode enabled for you");
	
	return Plugin_Handled;	
}

public Action:Command_Thirdperson(client, args) {
	if (client == 0) return Plugin_Handled;
	
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
	
	ReplyToCommand(client, "[SM] Thirdperson mode enabled for you");
	
	return Plugin_Handled;
}

public GetClientAimTarget2(client) {
	new Float:vEyeAngles[3], Float:vAbsAngles[3], Float:vAbsOrigin[3], Float:vEyePosition[3], Float:vForward[3], Float:vEndPoint[3], Float:vEndPos[3];
	
	GetClientEyePosition(client, vEyePosition);
	GetClientEyeAngles(client, vEyeAngles);
	GetClientAbsAngles(client, vAbsAngles);
	GetClientAbsOrigin(client, vAbsOrigin);
	
	GetAngleVectors(vEyeAngles, vForward, NULL_VECTOR, NULL_VECTOR);
	
	for (new axis=0; axis<sizeof(vEndPoint); ++axis) {
		vEndPoint[axis] = vEyePosition[axis] + vForward[axis] * 1024.0;
	}
	
	new Handle:trace = TR_TraceRayFilterEx(vEyePosition, vEndPoint, MASK_ALL, RayType_Infinite, TraceEntityFilterPlayer);
	
	if(TR_DidHit(trace)){
		TR_GetEndPosition(vEndPos, trace);
		
		return TR_GetEntityIndex(trace);
	}
	
	return -1;
}

public Action:Command_FadeIn(client, args) {
	
	decl String:arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	new alpha = StringToInt(arg1);

	FadeClientScreen(client, 10, FFADE_IN | FFADE_PURGE, 255, 255, 255, alpha);
	ReplyToCommand(client, "Faded !");
	
	return Plugin_Handled;
}

public Action:Command_FadeOut(client, args) {	
	decl String:arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	new alpha = StringToInt(arg1);

	FadeClientScreen(client, 0, FFADE_STAYOUT | FFADE_PURGE, 0, 0, 0, alpha);
	ReplyToCommand(client, "Faded !");
	
	return Plugin_Handled;
}

FadeClientScreen(client, duration, mode, r=0, g=0, b=0, a=255) {

	new Handle:msg = StartMessageOne("Fade", client);
	BfWriteShort(msg, duration);	// Fade duration
	BfWriteShort(msg, -1);			// Fade hold time
	BfWriteShort(msg, mode);		// What to do
	BfWriteByte(msg, r);			// Color R
	BfWriteByte(msg, g);			// Color G
	BfWriteByte(msg, b);			// Color B
	BfWriteByte(msg, a);			// Color Alpha
	EndMessage();
}
