/***************************************************************************************

	Copyright (C) 2012 BCServ (plugins@bcserv.eu)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
	
***************************************************************************************/

/***************************************************************************************


	C O M P I L E   O P T I O N S


***************************************************************************************/
// enforce semicolons after each code statement
#pragma semicolon 1

/***************************************************************************************


	P L U G I N   I N C L U D E S


***************************************************************************************/
#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <smlib/pluginmanager>
#include <regex>

#undef REQUIRE_EXTENSIONS
#include <cstrike>

/***************************************************************************************


	P L U G I N   I N F O


***************************************************************************************/
public Plugin:myinfo = {
	name 						= "Admin Tools",
	author 						= "Chanz, Berni",
	description 				= "Collection of mighty admin commands",
	version 					= "1.4",
	url 						= "http://bcserv.eu/"
}

/***************************************************************************************


	P L U G I N   D E F I N E S


***************************************************************************************/
#define FAST_THINK_INTERVAL 0.2
#define PRINT_SEPERATOR "---------------------------------------------------------------------------------------------------------------"

#define MAX_EVENTS 64
	
#define EVENT_COMMAND_HOOK_MODE EventHookMode_Pre

#define COMMAND_ALIAS_DESCRIPTION "This is a custom generated alias command by Admin-Tools"

#define MAX_BEAM_DURATION 25.0 // 25 is max
/***************************************************************************************


	G L O B A L   E N U M S


***************************************************************************************/
enum DATATYPE {
	
	DATATYPE_UNKNOWEN = -1,
	DATATYPE_INT = 0,
	DATATYPE_FLOAT,
	DATATYPE_STRING
};

enum ACCESS_TYPE {
	ACCESS_TYPE_NONE = -1,
	ACCESS_TYPE_ANYONE = 0,
	ACCESS_TYPE_FLAG,
	ACCESS_TYPE_COMMAND,
	ACCESS_TYPE_GROUP
};

/***************************************************************************************


	G L O B A L   V A R S


***************************************************************************************/
// Server Variables


// Plugin Internal Variables


// Console Variables
// new Handle:g_cvarEnable 					= INVALID_HANDLE;
new Handle:g_cvarMpTimelimit = INVALID_HANDLE;

// Console Variables: Runtime Optimizers
// new g_iPlugin_Enable 					= 1;


// Timers

// Events
new Handle:g_hEvent_ToArray = INVALID_HANDLE;
new Handle:g_hEvent_KeyList = INVALID_HANDLE;

// Library Load Checks
new bool:g_bExtensionCstrikeLoaded = false; // Whether the cstrike extension is loaded or not

// Game Variables
new Handle:g_hGame_EventKeyList = INVALID_HANDLE;
new EngineVersion:g_evEngine_Version = Engine_Unknown; // Guessed SDK version

// Map Variables
new g_iSprite_LaserBeam = -1;
new g_iMap_SpawnPoints[MAX_TEAMS];

// Client Variables
new bool:g_bClient_PointActivated[MAXPLAYERS+1];
new Float:g_flClient_PointSize[MAXPLAYERS+1];
new bool:g_bClient_IsBuried[MAXPLAYERS+1];

// M i s c

// Alias Command To Data Mapping
new Handle:g_hAlias_ToDataPack = INVALID_HANDLE;


/***************************************************************************************


	F O R W A R D   P U B L I C S


***************************************************************************************/
public OnPluginStart()
{
	// Initialization for SMLib
	PluginManager_Initialize("admin-tools", "[SM] ", false, false);
	
	// Translations
	LoadTranslations("common.phrases");
	
	
	// Command Hooks (AddCommandListener) (If the command already exists, like the command kill, then hook it!)
	
	
	// Register New Commands (PluginManager_RegConsoleCmd) (If the command doesn't exist, hook it here)
	
	
	// Register Admin Commands (PluginManager_RegAdminCmd)
	RegisterAdminTools();
	RegisterDeveloperTools();
	
	// Cvars: Create a global handle variable.
	// g_cvarEnable = PluginManager_CreateConVar("enable", "1", "Enables or disables this plugin");
	
	
	// Hook ConVar Change
	// HookConVarChange(g_cvarEnable, ConVarChange_Enable);
	

	// Find ConVar
	g_cvarMpTimelimit = FindConVar("mp_timelimit");
	
	// Event Hooks


	// Library
	
	
	/* Features
	if(CanTestFeatures()){
		
	}
	*/
	
	// Create ADT Arrays
	g_hEvent_KeyList = CreateArray(MAX_NAME_LENGTH);

	// Tries
	g_hEvent_ToArray = CreateTrie();
	g_hGame_EventKeyList = CreateTrie();
	g_hAlias_ToDataPack = CreateTrie();
	
	// Timers
	CreateTimer(FAST_THINK_INTERVAL,Timer_FastThink,INVALID_HANDLE,TIMER_REPEAT);
	
	// Parse Events
	ParseEventKVCheck("resource/gameevents.res");
	ParseEventKVCheck("resource/serverevents.res");
	ParseEventKVCheck("resource/hltvevents.res");
	ParseEventKVCheck("resource/replayevents.res");
	ParseEventKVCheck("resource/modevents.res");

	// Feature detection
	g_evEngine_Version = GetEngineVersion();

	// Check if the extension is loaded

	if (GetExtensionFileStatus("game.cstrike.ext") == 1) {
		g_bExtensionCstrikeLoaded = true;
	}
}

public OnMapStart()
{
	// hax against valvefail (thx psychonic for fix)
	if (g_evEngine_Version == Engine_SourceSDK2007){
		SetConVarString(Plugin_VersionCvar, Plugin_Version);
	}

	if (g_evEngine_Version == Engine_Left4Dead2){
		
		g_iSprite_LaserBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
		//g_iSprite_Halo = PrecacheModel("materials/sprites/glow01.vmt");
	}
	else {
		
		g_iSprite_LaserBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
		//g_iSprite_Halo = PrecacheModel("materials/sprites/halo01.vmt");
	}

	ClearEvents();

	CreateTimer(1.0, Timer_LateMapStart, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
}

public OnConfigsExecuted()
{
	// Set your ConVar runtime optimizers here
	// g_iPlugin_Enable = GetConVarInt(g_cvarEnable);
	
	// Mind: this is only here for late load, since on map change or server start, there isn't any client.
	// Remove it if you don't need it.
	Client_InitializeAll();
}

public OnClientPutInServer(client)
{
	Client_Initialize(client);
}

public OnClientPostAdminCheck(client)
{
	Client_Initialize(client);
}

/**************************************************************************************


	C A L L B A C K   F U N C T I O N S


**************************************************************************************/
// Filters players out
public bool:TraceFilter_FilterPlayer(entity, contentsMask){
	
	return entity > MaxClients || !entity;
}

/**************************************************************************************

	T I M E R S

**************************************************************************************/
public Action:Timer_FastThink(Handle:timer){
	
	new Float:eyePos[3];
	new Float:aimPos[3];
	
	LOOP_CLIENTS(client,CLIENTFILTER_INGAMEAUTH){
		
		if(g_bClient_PointActivated[client]){
			
			GetClientEyePosition(client,eyePos);
			Client_GetCrossHairAimPos(client,aimPos);
			
			//TE_SetupGlowSprite(aimPos, g_iSprite_Glow, THINK_INTERVAL, 0.1, 255);
			//TE_SendToAll();
			
			//PrintToChat(client,"eyepos[0]: %f; eyepos[1]: %f; eyepos[2]: %f;",eyePos[0],eyePos[1],eyePos[2]);	
			//PrintToChat(client,"spriteIndex: %d",g_iSprite_Beam);
			
			TE_SetupBeamPoints(eyePos, aimPos, g_iSprite_LaserBeam, 0, 0, 0, FAST_THINK_INTERVAL, g_flClient_PointSize[client]/2, g_flClient_PointSize[client], 1, 0.0, {255,0,0,255}, 0);
			TE_SendToAll();
		}
	}
}

public Action:Timer_LateMapStart(Handle:timer){
	
	g_iMap_SpawnPoints[TEAM_ONE] = GetSpawnPointCount(TEAM_ONE);
	g_iMap_SpawnPoints[TEAM_TWO] = GetSpawnPointCount(TEAM_TWO);
	return Plugin_Continue;
}

public Action:Timer_Future(Handle:timer, Handle:dataPack)
{
	
	// DataPack:
	// int clientUserId or 0 if its the server
	// float countdown
	// int repeat
	// string command
	ResetPack(dataPack);
	new userId = ReadPackCell(dataPack);
	new client = -1;
	if (userId <= 0) {
		client = 0;
	}
	else {
		client = GetClientOfUserId(userId);
		if (!Client_IsValid(client)) {
			return Plugin_Handled;
		}
	}
	
	new Float:countdown = ReadPackFloat(dataPack);
	new repeat = ReadPackCell(dataPack);
	new String:commands[192];
	ReadPackString(dataPack, commands, sizeof(commands));
	
	if (client == 0) {
		ServerCommand(commands);
	}
	else {
		FakeClientCommandEx(client, commands);
	}
	
	// if repeat is 0 do it infinitly. 
	// if its bigger than 0 decrement it and check if it got zero or lower, then set it to -1.
	// if repeat is -1 there is no next move
	if (repeat > 0) {
		
		repeat--;
		
		if (repeat <= 0) {
			repeat = -1;
		}
	}
	
	if (repeat != -1) {
		
		// DataPack:
		// int clientUserId or 0 if its the server
		// float countdown
		// int repeat
		// string command
		new Handle:nextDataPack = INVALID_HANDLE;
		CreateDataTimer(countdown, Timer_Future, nextDataPack, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(nextDataPack, userId);
		WritePackFloat(nextDataPack, countdown);
		WritePackCell(nextDataPack, repeat);
		WritePackString(nextDataPack, commands);
	}
	return Plugin_Handled;
}
/**************************************************************************************

	C O N  V A R  C H A N G E

**************************************************************************************/
/* Example Callback Con Var Change
public ConVarChange_Enable(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_iPlugin_Enable = StringToInt(newVal);
}
*/


/**************************************************************************************

	C O M M A N D S

**************************************************************************************/
/**************************************************************************************
	A D M I N   T O O L S :   I N V I S I B L E
**************************************************************************************/
public Action:Command_Event(client, args) {

	if (args < 2) {
		
		decl String:command[MAX_NAME_LENGTH];
		GetCmdArg(0,command,sizeof(command));
		ReplyToCommand(client, "%sUsage: %s <event[/count]> <command>", Plugin_Tag, command);
		return Plugin_Handled;
	}

	decl String:arg1[MAX_NAME_LENGTH], String:buffers[2][MAX_NAME_LENGTH];
	GetCmdArg(1, arg1, sizeof(arg1));
	ExplodeString(arg1, "/", buffers, sizeof(buffers), sizeof(buffers[]));
	
	new bool:executeNow = (StrContains(buffers[0], "now", false) == 0);
	
	new Handle:commandArray = INVALID_HANDLE;
	if (!executeNow) {

		// Hook it only once
		if (!GetTrieValue(g_hEvent_ToArray, buffers[0], commandArray)) {
			
			if (!PluginManager_HookEvent(buffers[0], Event_CommandEvent, EVENT_COMMAND_HOOK_MODE, false)) {

				ReplyToCommand(client, "%sEvent %s is invalid", Plugin_Tag, buffers[0]);
				return Plugin_Handled;
			}

			PushArrayString(g_hEvent_KeyList, buffers[0]);
			commandArray = CreateArray();
			SetTrieValue(g_hEvent_ToArray, buffers[0], commandArray);
		}
	}

	decl String:argString[192];
	GetCmdArgString(argString,sizeof(argString));
	ReplaceStringEx(argString,sizeof(argString),arg1,"", -1, -1,false);
	String_Trim(argString,argString,sizeof(argString), " \t\r\n\"");

	if(argString[0] == '\0'){
		ReplyToCommand(client, "%sThe parameter 'command' seems to be invalid", Plugin_Tag);
		return Plugin_Handled;
	}
	
	if (executeNow) {
		
		if(client == 0){
			ServerCommand(argString);
		}
		else {
			FakeClientCommand(client,argString);
		}
		LogAction(client, -1, "\"%L\" hooks \"%s\" to event \"%s\"", client, argString, buffers[0]);
		AdminToolsShowActivity(client, Plugin_Tag, "Hooking \"%s\" to event \"%s\"", argString, buffers[0]);
		return Plugin_Handled;
	}
	
	// DataPack:
	// int OwnerUserId
	// int count
	// String command (raw)
	new Handle:dataPack = CreateDataPack();
	WritePackCell(dataPack, (client == 0) ? 0 : GetClientUserId(client));
	WritePackCell(dataPack, (buffers[1][0] == '\0') ? -1 : StringToInt(buffers[1]));
	WritePackString(dataPack, argString);

	PushArrayCell(commandArray, dataPack);

	LogAction(client, -1, "\"%L\" hooks \"%s\" to event \"%s\"", client, argString, buffers[0]);
	AdminToolsShowActivity(client, Plugin_Tag, "Hooking \"%s\" to event \"%s\"", argString, buffers[0]);
	return Plugin_Handled;
}

public Action:Command_Alias(client, args) {
	
	// Goal product:
	// sm_alias sm_balanceteams_roundstart sm_balanceteams server sm_event round_start/1 sm_balanceteams
	// sm_balanceteams_roundstart
	
	if (args < 4) {
		
		decl String:command[MAX_NAME_LENGTH];
		GetCmdArg(0,command,sizeof(command));
		ReplyToCommand(client, "%sUsage: %s <alias_command> <access> <server|client> <commands>", Plugin_Tag, command);
		ReplyToCommand(client, "%s\t alias_command: the new name of the commands", Plugin_Tag);
		ReplyToCommand(client, "%s\t access: 'anyone' OR 'a'-'z' OR a admin group OR a command to read the flag from", Plugin_Tag);
		ReplyToCommand(client, "%s\t server|client: where the command is executed. (s=server; c=client)", Plugin_Tag);
		ReplyToCommand(client, "%s\t commands: all the commands that should be executed. Use #num or @num to parse parameters from the alias (see example#3).", Plugin_Tag);
		ReplyToCommand(client, "");
		ReplyToCommand(client, "%s\t Example#1: sm_alias sm_hilfe  anyone  client sm_help", Plugin_Tag);
		ReplyToCommand(client, "%s\t Example#2: sm_alias sm_slapme sm_slap client sm_slap @me", Plugin_Tag);
		ReplyToCommand(client, "%s\t Example#3: sm_alias sm_kill   z       client sm_slay @1", Plugin_Tag);
		return Plugin_Handled;
	}

	decl String:arg1[MAX_NAME_LENGTH], String:arg2[MAX_NAME_LENGTH], String:arg3[7];
	// alias_name
	GetCmdArg(1, arg1, sizeof(arg1));
	// access
	GetCmdArg(2, arg2, sizeof(arg2));
	// where to exec: server or client
	GetCmdArg(3, arg3, sizeof(arg3));
	
	new AdminFlag:adminFlag;
	new ACCESS_TYPE:accessType = ACCESS_TYPE_NONE;
	if (StrEqual(arg2, "anyone", false)) {
		// valid anyone
		accessType = ACCESS_TYPE_ANYONE;
	}
	else if (arg2[1] == '\0' && FindFlagByChar(arg2[0], adminFlag)) {
		// valid flag
		accessType = ACCESS_TYPE_FLAG;
	}
	else if (GetCommandFlags(arg2) != INVALID_FCVAR_FLAGS) {
		// valid command
		accessType = ACCESS_TYPE_COMMAND;
	}
	else if (FindAdmGroup(arg2) != INVALID_GROUP_ID) {
		// valid group
		accessType = ACCESS_TYPE_GROUP;
	}
	else {
		ReplyToCommand(client, "%sThe parameter 'access' seems to be invalid", Plugin_Tag);
		return Plugin_Handled;
	}
	// since the access parameter is valid continue...
	
	new bool:serverExecute = false;
	if (arg3[0] == 's' || StrContains(arg3, "server", false) == 0) {
		serverExecute = true;
	}
	else if (arg3[0] == 'c' || StrContains(arg3, "client", false) == 0) {
		serverExecute = false;
	}
	else {
		ReplyToCommand(client, "%sThe parameter 'server|client' must only be server OR client", Plugin_Tag);
		return Plugin_Handled;
	}
	
	// using 3*MAX_NAME_LENGTH because arg1 to arg3 are being removed:
	decl String:argString[192+3*MAX_NAME_LENGTH];
	GetCmdArgString(argString,sizeof(argString));
	ReplaceStringEx(argString,sizeof(argString),arg1,"", -1, -1,false);
	ReplaceStringEx(argString,sizeof(argString),arg2,"", -1, -1,false);
	ReplaceStringEx(argString,sizeof(argString),arg3,"", -1, -1,false);
	String_Trim(argString,argString,sizeof(argString), " \t\r\n\"");

	if(argString[0] == '\0'){
		ReplyToCommand(client, "%sThe parameter 'commands' seems to be invalid", Plugin_Tag);
		return Plugin_Handled;
	}
	
	new Handle:dataPack = INVALID_HANDLE;
	if (GetTrieValue(g_hAlias_ToDataPack, arg1, dataPack)) {
		// alias already exists but may have changed -> rebuild datapack
		if (dataPack != INVALID_HANDLE) {
			CloseHandle(dataPack);
			dataPack = INVALID_HANDLE;
		}
		// DataPack:
		// int accessType
		// String access
		// int serverExecute
		// String command (raw)
		dataPack = CreateDataPack();
		WritePackCell(dataPack, _:accessType);
		WritePackString(dataPack, arg2);
		WritePackCell(dataPack, serverExecute);
		WritePackString(dataPack, argString);
		SetTrieValue(g_hAlias_ToDataPack, arg1, dataPack);
	}
	else {
		// DataPack:
		// int accessType
		// String access
		// int serverExecute
		// String command (raw)
		dataPack = CreateDataPack();
		WritePackCell(dataPack, _:accessType);
		WritePackString(dataPack, arg2);
		WritePackCell(dataPack, serverExecute);
		WritePackString(dataPack, argString);
		if (!SetTrieValue(g_hAlias_ToDataPack, arg1, dataPack, false)) {
			LogError("alias command should be new but isn't in g_hAlias_ToDataPack");
			return Plugin_Handled;
		}
		
		// Reg our command only once
		PluginManager_RegConsoleCmd(arg1, Command_AliasUse, COMMAND_ALIAS_DESCRIPTION);
	}

	LogAction(client, -1, "\"%L\" created alias \"%s\" to wrap \"%s\"", client, arg1, argString);
	AdminToolsShowActivity(client, Plugin_Tag, "Created alias \"%s\" to wrap \"%s\"", arg1, argString);
	return Plugin_Handled;
}
public Action:Command_AliasUse(client, args) {
	
	decl String:command[MAX_NAME_LENGTH];
	GetCmdArg(0,command,sizeof(command));
	
	new Handle:dataPack = INVALID_HANDLE;
	if (!GetTrieValue(g_hAlias_ToDataPack, command, dataPack)) {
		LogError("Can't find command '%s' in g_hAlias_ToDataPack", command);
		return Plugin_Continue;
	}
	
	// DataPack:
	// int accessType
	// String access
	// int serverExecute
	// String commands (raw)
	new ACCESS_TYPE:accessType = ACCESS_TYPE_NONE;
	new String:access[MAX_NAME_LENGTH];
	new bool:serverExecute = false;
	new String:commands[192];
	
	ResetPack(dataPack);
	accessType = ACCESS_TYPE:ReadPackCell(dataPack);
	ReadPackString(dataPack, access, sizeof(access));
	serverExecute = bool:ReadPackCell(dataPack);
	ReadPackString(dataPack, commands, sizeof(commands));
	
	
	new bool:hasAccess = false;
	new AdminFlag:adminFlag = AdminFlag:-1;

	if (client == 0) {
		hasAccess = true;
	}
	else {
		switch(accessType){

			case ACCESS_TYPE_ANYONE:{
				
				hasAccess = true;
			}
			case ACCESS_TYPE_FLAG:{

				if (!FindFlagByChar(access[0], adminFlag)) {

					LogError("accessType is ACCESS_TYPE_FLAG, but access[0] contains no valid flag char");
					return Plugin_Continue;
				}
				hasAccess = Client_HasAdminFlags(client, FlagToBit(adminFlag));
			}
			case ACCESS_TYPE_COMMAND:{
				
				hasAccess = CheckCommandAccess(client, access, ADMFLAG_ROOT);
			}
			case ACCESS_TYPE_GROUP:{
				
				new AdminId:adminId = GetUserAdmin(client);
				if (adminId != INVALID_ADMIN_ID && AdminInheritGroup(adminId, FindAdmGroup(access))) {
					
					hasAccess = true;
				}
			}
			default:{
				LogError("accessType is invalid (%d)",accessType);
				return Plugin_Continue;
			}
		}
	}
	
	if (hasAccess == false) {
		// TODO: Replace with translation
		ReplyToCommand(client, "%sYou do not have access to this command.", Plugin_Tag);
		return Plugin_Handled;
	}
	
	// replace @num or "#num" at the arguments
	decl String:buffer[MAX_NAME_LENGTH];
	new String:search[6];
	for (new i=1; i<=args; i++) {
		
		GetCmdArg(i, buffer, sizeof(buffer));
		
		Format(search, sizeof(search), "@%i", i);
		ReplaceString(commands, sizeof(commands), search, buffer, false);
		
		Format(search, sizeof(search), "#%i", i);
		Format(buffer, sizeof(buffer), "\"%s\"", buffer);
		ReplaceString(commands, sizeof(commands), search, buffer, false);
	}
	
	if (serverExecute == true || client == 0) {
		ServerCommandChainable(commands);
	}
	else {
		FakeClientCommandChainable(client, commands);
	}
	
	LogAction(client, -1, "\"%L\" uses alias '%s' which unwraps to '%s'", client, command, commands);
	AdminToolsShowActivity(client, Plugin_Tag, "Uses alias %s", command);
	return Plugin_Handled;
}

public Action:Command_Future(client, args)
{
	if (args < 2) {
		
		decl String:command[MAX_NAME_LENGTH];
		GetCmdArg(0,command,sizeof(command));
		ReplyToCommand(client, "%sUsage: %s <countdown in seconds> <repeat for n times (0=infinte)> <commands>", Plugin_Tag, command);
		return Plugin_Handled;
	}

	decl String:arg1[11], String:arg2[11];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	new Float:countdown = -1.0;
	if (!String_IsNumeric(arg1) || (countdown = StringToFloat(arg1)) <= 0) {
		ReplyToCommand(client, "%sThe parameter 'countdown in seconds' must be a number greater than 0", Plugin_Tag);
		return Plugin_Handled;
	}
	
	new repeat = -1;
	if (!String_IsNumeric(arg2) || (repeat = StringToInt(arg2)) < 0) {
		ReplyToCommand(client, "%sThe parameter 'repeat for n times (0=infinte)' must be a number greater than or equal to 0", Plugin_Tag);
		return Plugin_Handled;
	}
	
	// using +2*11 because arg1 and arg2 are being removed:
	decl String:argString[192+2*11];
	GetCmdArgString(argString,sizeof(argString));
	ReplaceStringEx(argString,sizeof(argString),arg1,"", -1, -1,false);
	ReplaceStringEx(argString,sizeof(argString),arg2,"", -1, -1,false);
	String_Trim(argString,argString,sizeof(argString), " \t\r\n\"");
	
	if(argString[0] == '\0'){
		ReplyToCommand(client, "%sThe parameter 'commands' seems to be invalid", Plugin_Tag);
		return Plugin_Handled;
	}
	
	// DataPack:
	// int clientUserId or 0 if its the server
	// float countdown
	// int repeat
	// string command
	new Handle:dataPack = INVALID_HANDLE;
	CreateDataTimer(countdown, Timer_Future, dataPack, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(dataPack, client == 0 ? 0 : GetClientUserId(client));
	WritePackFloat(dataPack, countdown);
	WritePackCell(dataPack, repeat);
	WritePackString(dataPack, argString);
	
	LogAction(client, -1, "\"%L\" time travels the command '%s' into %.2f seconds into the future with %d repeats", client, argString, countdown, repeat);
	AdminToolsShowActivity(client, Plugin_Tag, "Sends '%s' %d seconds into the future with %d repeats", argString, countdown, repeat);
	return Plugin_Handled;
}

/**************************************************************************************
	A D M I N   T O O L S :   V I S I B L E
**************************************************************************************/
public Action:Command_Health(client, args) {
	
	if (args != 2 && args != 1) {
		
		decl String:command[MAX_NAME_LENGTH];
		GetCmdArg(0,command,sizeof(command));
		ReplyToCommand(client, "%sUsage: %s <target> <[+|-]value>",Plugin_Tag,command);
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH], String:arg2[8];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS+1];
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
		ReplyToTargetError(client,target_count);
		return Plugin_Handled;
	}
	
	if(args == 1){
		
		LogAction(client, -1, "\"%L\" has seen health of target %s", client, target);
		AdminToolsShowActivity(client, Plugin_Tag, "Showing health of target %s", target);

		for (new i=0; i<target_count; ++i) {
			
			ReplyToCommand(client, "%sTarget health is %d", Plugin_Tag, GetClientHealth(target_list[i]));
		}
		
		return Plugin_Handled;
	}
	
	GetCmdArg(2, arg2, sizeof(arg2));
	new health = StringToInt(arg2);
	
	if (arg2[0] == '-' || arg2[0] == '+') {
		
		for (new i=0; i<target_count; ++i) {
			
			Entity_SetHealth(target_list[i], GetClientHealth(target_list[i])+health, true, true);
		}
	}
	else {
		
		for (new i=0; i<target_count; ++i) {
			
			Entity_SetHealth(target_list[i], health, true, true);
		}
	}
	
	LogAction(client, -1, "\"%L\" sets health to %d for target %s", client, health, target);
	AdminToolsShowActivity(client, Plugin_Tag, "Set health to %d for target %s", health, target);
	return Plugin_Handled;
}

public Action:Command_MaxHealth(client, args) {

	if (args != 2 && args != 1) {
		
		decl String:command[MAX_NAME_LENGTH];
		GetCmdArg(0,command,sizeof(command));
		ReplyToCommand(client, "%sUsage: %s <target> <[+|-]value>",Plugin_Tag,command);
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH], String:arg2[8];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS+1];
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
		ReplyToTargetError(client,target_count);
		return Plugin_Handled;
	}
	
	if(args == 1){
		
		LogAction(client, -1, "\"%L\" has seen max health of target %s", client, target);
		AdminToolsShowActivity(client, Plugin_Tag, "Showing max health of target %s", target);

		for (new i=0; i<target_count; ++i) {
			
			ReplyToCommand(client, "%sTarget max health is %d", Plugin_Tag, Entity_GetMaxHealth(target_list[i]));
		}
		
		return Plugin_Handled;
	}
	
	GetCmdArg(2, arg2, sizeof(arg2));
	new health = StringToInt(arg2);
	
	if (arg2[0] == '-' || arg2[0] == '+') {
		
		for (new i=0; i<target_count; ++i) {
			
			Entity_SetMaxHealth(target_list[i], Entity_GetMaxHealth(target_list[i])+health);
		}
	}
	else {
		
		for (new i=0; i<target_count; ++i) {
			
			Entity_SetMaxHealth(target_list[i], health);
		}
	}
	
	LogAction(client, -1, "\"%L\" sets health to %d for target %s", client, health, target);
	AdminToolsShowActivity(client, Plugin_Tag, "Set health to %d for target %s", health, target);
	return Plugin_Handled;
}

public Action:Command_Armor(client, args) {
	
	if (args != 2 && args != 1) {
		
		decl String:command[MAX_NAME_LENGTH];
		GetCmdArg(0,command,sizeof(command));
		ReplyToCommand(client, "%sUsage: %s <target> <[+|-]value>",Plugin_Tag,command);
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH], String:arg2[8];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS+1];
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
		ReplyToTargetError(client,target_count);
		return Plugin_Handled;
	}
	
	if(args == 1){
		
		LogAction(client, -1, "\"%L\" has seen armor of target %s", client, target);
		AdminToolsShowActivity(client, Plugin_Tag, "Showing armor of target %s", target);

		for (new i=0; i<target_count; ++i) {
			
			ReplyToCommand(client, "%sTarget armor is %d",Plugin_Tag,Client_GetArmor(target_list[i]));
		}
		return Plugin_Handled;
	}

	GetCmdArg(2, arg2, sizeof(arg2));
	new armor = StringToInt(arg2);
	
	if (arg2[0] == '-' || arg2[0] == '+') {
		
		for (new i=0; i<target_count; ++i) {
			
			new newArmor = Client_GetArmor(target_list[i])+armor;
			Client_SetArmor(target_list[i], newArmor);

			// For those games with Helmets (CSS, CSGO) we add a Helmet as soon the client has more than 1 armor points
			if(IsValidDataMap(target_list[i],"m_bHasHelmet")){
				SetEntProp(target_list[i], Prop_Send, "m_bHasHelmet", newArmor ? 1 : 0);
			}
		}
	}
	else {
		
		for (new i=0; i<target_count; ++i) {
			
			Client_SetArmor(target_list[i], armor);

			// For those games with Helmets (CSS, CSGO) we add a Helmet as soon the client has more than 1 armor points
			if(IsValidDataMap(target_list[i],"m_bHasHelmet")){
				SetEntProp(target_list[i], Prop_Send, "m_bHasHelmet", armor ? 1 : 0);
			}
		}
	}

	LogAction(client, -1, "\"%L\" sets armor to %d for target %s", client, armor, target);
	AdminToolsShowActivity(client, Plugin_Tag, "Set armor to %d for target %s", armor, target);
	return Plugin_Handled;
}

public Action:Command_Score(client, args) {
	
	if (args != 2) {
		
		decl String:command[MAX_NAME_LENGTH];
		GetCmdArg(0,command,sizeof(command));
		ReplyToCommand(client, "%sUsage: %s <target> <[+|-]value>",Plugin_Tag,command);
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH], String:arg2[11];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS+1];
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
		ReplyToTargetError(client,target_count);
		return Plugin_Handled;
	}
	
	GetCmdArg(2, arg2, sizeof(arg2));
	new score = StringToInt(arg2);
	
	if (arg2[0] == '-' || arg2[0] == '+') {
		
		for (new i=0; i<target_count; ++i) {
			
			Client_SetScore(target_list[i], Client_GetScore(target_list[i])+score);
		}
	}
	else {
		
		for (new i=0; i<target_count; ++i) {
			
			Client_SetScore(target_list[i], score);
		}
	}
	
	LogAction(client, -1, "\"%L\" sets score to %d for target %s", client, score, target);
	AdminToolsShowActivity(client, Plugin_Tag, "Set score to %d for target %s", score, target);
	return Plugin_Handled;
}

public Action:Command_Deaths(client, args) {

	if (args != 2) {
		
		decl String:command[MAX_NAME_LENGTH];
		GetCmdArg(0,command,sizeof(command));
		ReplyToCommand(client, "%sUsage: %s <target> <[+|-]value>",Plugin_Tag,command);
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH], String:arg2[11];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS+1];
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
		ReplyToTargetError(client,target_count);
		return Plugin_Handled;
	}
	
	GetCmdArg(2, arg2, sizeof(arg2));
	new deaths = StringToInt(arg2);
	
	if (arg2[0] == '-' || arg2[0] == '+') {
		
		for (new i=0; i<target_count; ++i) {
			
			Client_SetDeaths(target_list[i], Client_GetDeaths(target_list[i])+deaths);
		}
	}
	else {
		
		for (new i=0; i<target_count; ++i) {
			
			Client_SetDeaths(target_list[i], deaths);
		}
	}
	
	LogAction(client, -1, "\"%L\" sets deaths to %d for target %s", client, deaths, target);
	AdminToolsShowActivity(client, Plugin_Tag, "Set deaths to %d for target %s", deaths, target);
	return Plugin_Handled;
}

public Action:Command_Connect(client, args) {

	decl String:command[MAX_NAME_LENGTH];
	GetCmdArg(0,command,sizeof(command));

	if (args < 2) {
		ReplyToCommand(client, "%sUsage: %s <target> <ip:port>",Plugin_Tag,command);
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH], String:address[40];
	GetCmdArg(1, target, sizeof(target));
	GetCmdArgString(address,sizeof(address));
	ReplaceStringEx(address,sizeof(address),target,"", -1, -1,false);
	String_Trim(address,address,sizeof(address));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS+1];
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

		ReplyToTargetError(client,target_count);
		return Plugin_Handled;
	}
	
	for (new i=0; i<target_count; ++i) {

		DisplayAskConnectBox(target_list[i], 15.0, address);
	}

	LogAction(client, -1, "\"%L\" displays connect box with ip %s to target %s", client, address, target);
	AdminToolsShowActivity(client, Plugin_Tag, "Displaying connect box with ip %s to target %s", address, target);
	return Plugin_Handled;
}
public Action:Command_Exec(client, args)
{
	decl String:command[MAX_NAME_LENGTH];
	GetCmdArg(0,command,sizeof(command));

	if (args < 2) {
		
		ReplyToCommand(client, "%sUsage: %s <target> <cmd...>",Plugin_Tag,command);
		return Plugin_Handled;
	}

	decl String:target[MAX_TARGET_LENGTH], String:execCommand[128];
	GetCmdArg(1, target, sizeof(target));

	// Get the 2. argument as full string to avoid the need of "" for the 2. argument
	GetCmdArgString(execCommand, sizeof(execCommand));
	ReplaceStringEx(execCommand,sizeof(execCommand),target,"", -1, -1,false);
	String_Trim(execCommand,execCommand,sizeof(execCommand), " \t\r\n\"");
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS+1];
	decl bool:tn_is_ml;
	
	new target_count = ProcessTargetString(
		target,
		client,
		target_list,
		sizeof(target_list),
		COMMAND_FILTER_CONNECTED,
		target_name,
		sizeof(target_name),
		tn_is_ml
	);
	
	if (target_count <= 0) {

		ReplyToTargetError(client,target_count);
		return Plugin_Handled;
	}
	
	for (new i=0; i<target_count; ++i) {

		ClientCommand(target_list[i], execCommand);
	}

	LogAction(client, -1, "\"%L\" executes command '%s' on target %s", client, execCommand, target);
	AdminToolsShowActivity(client, Plugin_Tag, "Execute command '%s' on target %s", execCommand, target);
	return Plugin_Handled;
}
public Action:Command_FExec(client, args)
{
	decl String:command[MAX_NAME_LENGTH];
	GetCmdArg(0,command,sizeof(command));

	if (args < 2) {
		
		ReplyToCommand(client, "%sUsage: %s <target> <cmd...>",Plugin_Tag,command);
		return Plugin_Handled;
	}

	decl String:target[MAX_TARGET_LENGTH], String:execCommand[128];
	GetCmdArg(1, target, sizeof(target));
	
	// Get the 2. argument as full string to avoid the need of "" for the 2. argument
	GetCmdArgString(execCommand, sizeof(execCommand));
	ReplaceStringEx(execCommand, sizeof(execCommand), target, "", -1, -1, false);
	String_Trim(execCommand,execCommand,sizeof(execCommand), " \t\r\n\"");
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS+1];
	decl bool:tn_is_ml;
	
	new target_count = ProcessTargetString(
		target,
		client,
		target_list,
		sizeof(target_list),
		COMMAND_FILTER_CONNECTED,
		target_name,
		sizeof(target_name),
		tn_is_ml
	);
	
	if (target_count <= 0) {

		ReplyToTargetError(client,target_count);
		return Plugin_Handled;
	}
	
	for (new i=0; i<target_count; ++i) {

		FakeClientCommand(target_list[i], execCommand);
	}

	LogAction(client, -1, "\"%L\" fake executes command '%s' on target %s", client, execCommand, target);
	AdminToolsShowActivity(client, Plugin_Tag, "Fake execute command '%s' on target %s", execCommand, target);
	return Plugin_Handled;
}
public Action:Command_RenderMode(client, args) {
	
	if (args != 2) {
		
		decl String:command[MAX_NAME_LENGTH];
		GetCmdArg(0,command,sizeof(command));
		ReplyToCommand(client, "%sUsage: %s <target> <mode>",Plugin_Tag,command);
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH], String:arg2[11];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS+1];
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

		new aimTarget = -1;

		if(StrEqual(target,"@aim",false)){

			aimTarget = GetClientAimTarget(client,false);
		}

		// target is not @aim or aimTarget is invalid
		if(!Entity_IsValid(aimTarget)){

			ReplyToTargetError(client,target_count);
			return Plugin_Handled;
		}
		else {

			// Since the aimTarget is valid we override the normal target system
			target_count = 1;
			target_list[0] = aimTarget;
		}
	}
	
	GetCmdArg(2, arg2, sizeof(arg2));
	new renderMode = StringToInt(arg2);
	
	for (new i=0; i<target_count; ++i) {
		
		SetEntityRenderMode(target_list[i], RenderMode:renderMode);
	}
	LogAction(client, -1, "\"%L\" sets render mode to %d for target %s", client, renderMode, target);
	AdminToolsShowActivity(client, Plugin_Tag, "Set render mode to %d for target %s", renderMode, target);

	return Plugin_Handled;
}

public Action:Command_RenderFx(client, args) {
	
	if (args != 2) {
		
		decl String:command[MAX_NAME_LENGTH];
		GetCmdArg(0,command,sizeof(command));
		ReplyToCommand(client, "%sUsage: %s <target> <fx-number>",Plugin_Tag,command);
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH], String:arg2[11];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS+1];
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

		new aimTarget = -1;

		if(StrEqual(target,"@aim",false)){

			aimTarget = GetClientAimTarget(client,false);
		}

		// target is not @aim or aimTarget is invalid
		if(!Entity_IsValid(aimTarget)){

			ReplyToTargetError(client,target_count);
			return Plugin_Handled;
		}
		else {

			// Since the aimTarget is valid we override the normal target system
			target_count = 1;
			target_list[0] = aimTarget;
		}
	}
	
	GetCmdArg(2, arg2, sizeof(arg2));
	new fxNumber = StringToInt(arg2);
	
	for (new i=0; i<target_count; ++i) {
		
		SetEntityRenderFx(target_list[i], RenderFx:fxNumber);
	}
	LogAction(client, -1, "\"%L\" sets render fx to %d for target %s", client, fxNumber, target);
	AdminToolsShowActivity(client, Plugin_Tag, "Set render fx to %d for target %s", fxNumber, target);

	return Plugin_Handled;
}
public Action:Command_RenderColor(client, args) {

	if (args < 1) {
		
		decl String:command[MAX_NAME_LENGTH];
		GetCmdArg(0,command,sizeof(command));
		ReplyToCommand(client, "%sUsage: %s <target> <red=0:255|?> <green=0:255|?> <blue=0:255|?> [alpha=0:255|?] or",Plugin_Tag,command);
		ReplyToCommand(client, "%sUsage: %s <target> <alpha=0:255|?> or",Plugin_Tag,command);
		ReplyToCommand(client, "%sUsage: %s <target> // Default/Normal Render Color",Plugin_Tag,command);
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS+1];
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

		new aimTarget = -1;

		if(StrEqual(target,"@aim",false)){

			aimTarget = GetClientAimTarget(client,false);
		}

		// target is not @aim or aimTarget is invalid
		if(!Entity_IsValid(aimTarget)){

			ReplyToTargetError(client,target_count);
			return Plugin_Handled;
		}
		else {

			// Since the aimTarget is valid we override the normal target system
			target_count = 1;
			target_list[0] = aimTarget;
		}
	}

	decl String:arg2[11], String:arg3[11], String:arg4[11], String:arg5[11];
	
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	GetCmdArg(4, arg4, sizeof(arg4));
	GetCmdArg(5, arg5, sizeof(arg5));

	if(arg3[0] == '\0' && arg4[0] == '\0' && arg5[0] == '\0'){
		strcopy(arg5,sizeof(arg5),arg2);
		arg2[0] = '\0';
	}

	new param1 = arg2[0]=='?' ? Math_GetRandomInt(0,255) : Math_Clamp(arg2[0]=='\0' ? 255 : StringToInt(arg2),0,255);
	new param2 = arg3[0]=='?' ? Math_GetRandomInt(0,255) : Math_Clamp(arg3[0]=='\0' ? 255 : StringToInt(arg3),0,255);
	new param3 = arg4[0]=='?' ? Math_GetRandomInt(0,255) : Math_Clamp(arg4[0]=='\0' ? 255 : StringToInt(arg4),0,255);
	new param4 = arg5[0]=='?' ? Math_GetRandomInt(0,255) : Math_Clamp(arg5[0]=='\0' ? 255 : StringToInt(arg5),0,255);
	
	for (new i=0; i<target_count; ++i) {
		
		SetEntityRenderColor(target_list[i], param1, param2, param3, param4);
	}
	LogAction(client, -1, "\"%L\" sets render color to (%d,%d,%d,%d) for target %s", client, param1, param2, param3, param4, target);
	AdminToolsShowActivity(client, Plugin_Tag, "Set render color to (%d,%d,%d,%d) for target %s", param1, param2, param3, param4, target);

	return Plugin_Handled;
}
public Action:Command_Firstperson(client, args) {

	if (args != 1) {
		
		decl String:command[MAX_NAME_LENGTH];
		GetCmdArg(0,command,sizeof(command));
		ReplyToCommand(client, "%sUsage: %s <target>",Plugin_Tag,command);
		return Plugin_Handled;
	}

	decl String:target[MAX_TARGET_LENGTH];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS+1];
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
		ReplyToTargetError(client,target_count);
		return Plugin_Handled;
	}
	
	for (new i=0; i<target_count; ++i) {
		
		SetThirdPersonMode(target_list[i], false);
	}

	LogAction(client, -1, "\"%L\" sets firstperson camera for target %s", client, target);
	AdminToolsShowActivity(client, Plugin_Tag, "Set firstperson for target %s", target);
	return Plugin_Handled;
}

public Action:Command_Thirdperson(client, args) {

	if (args != 1) {
		
		decl String:command[MAX_NAME_LENGTH];
		GetCmdArg(0,command,sizeof(command));
		ReplyToCommand(client, "%sUsage: %s <target>",Plugin_Tag,command);
		return Plugin_Handled;
	}

	decl String:target[MAX_TARGET_LENGTH];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS+1];
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
		ReplyToTargetError(client,target_count);
		return Plugin_Handled;
	}
	
	for (new i=0; i<target_count; ++i) {
		
		SetThirdPersonMode(target_list[i], true);
	}

	LogAction(client, -1, "\"%L\" sets thirdperson camera for target %s", client, target);
	AdminToolsShowActivity(client, Plugin_Tag, "Set thirdperson for target %s", target);
	return Plugin_Handled;
}
public Action:Command_AddOutput(client, args) {
	
	if (args < 1) {
		
		decl String:command[MAX_NAME_LENGTH];
		GetCmdArg(0,command,sizeof(command));
		ReplyToCommand(client, "%sUsage: %s <command>",Plugin_Tag,command);
		return Plugin_Handled;
	}

	decl Float:eyeOrigin[3], Float:eyeAngles[3];
	GetClientEyePosition(client,eyeOrigin);
	GetClientEyeAngles(client,eyeAngles);

	new Handle:trace = TR_TraceRayFilterEx(eyeOrigin, eyeAngles, MASK_VISIBLE, RayType_Infinite,TraceFilter_FilterPlayer);
	new entity = TR_GetEntityIndex(trace);
	CloseHandle(trace);

	if(!Entity_IsValid(entity)){

		ReplyToCommand(client,"%sInvalid aim target",Plugin_Tag);
		return Plugin_Handled;
	}

	decl String:argString[128], String:classname[MAX_NAME_LENGTH];
	GetCmdArgString(argString,sizeof(argString));
	Entity_GetClassName(entity,classname,sizeof(classname));

	LogAction(client, -1, "\"%L\" adding the ouput '%s' to the entity '%s' with id: %d", client, argString, classname, entity);
	AdminToolsShowActivity(client, Plugin_Tag, "Adding the ouput '%s' to the entity '%s'", argString, classname);

	Entity_AddOutput(entity,argString);
	return Plugin_Handled;
}

public Action:Command_Remove(client, args){

	new entity = -1;
	decl Float:eyeOrigin[3], Float:eyeAngles[3], Float:endPoint[3];
	
	if (client != 0) {
		GetClientEyePosition(client,eyeOrigin);
		GetClientEyeAngles(client,eyeAngles);
	}
	
	if (args == 0) {
		
		new Handle:trace = TR_TraceRayFilterEx(eyeOrigin, eyeAngles, MASK_VISIBLE, RayType_Infinite, TraceFilter_FilterPlayer);
		entity = TR_GetEntityIndex(trace);
		TR_GetEndPosition(endPoint, trace);
		//PrintToChat(client, "setpos %f %f %f", endPoint[0],endPoint[1],endPoint[2]);
		CloseHandle(trace);
		
		if(entity == 0 || !Entity_IsValid(entity)){
		
			ReplyToCommand(client,"%sInvalid aim target (%d)",Plugin_Tag,entity);
			return Plugin_Handled;
		}
	}
	else if (args == 1){
		
		new String:arg1[11];
		GetCmdArg(1, arg1, sizeof(arg1));
		
		new hammerid = StringToInt(arg1);
		
		if (hammerid > 0) {
			entity = Entity_FindByHammerId(hammerid);
		}
		
		if(entity == 0 || !Entity_IsValid(entity)){
		
			ReplyToCommand(client,"%sCan't find entity with hammerid: %d",Plugin_Tag,hammerid);
			return Plugin_Handled;
		}
		
		Entity_GetAbsOrigin(entity, endPoint);
	}
	else if (args == 3) {
		
		new String:arg1[17], String:arg2[17], String:arg3[17];
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		GetCmdArg(3, arg3, sizeof(arg3));
		
		endPoint[0] = StringToFloat(arg1);
		endPoint[1] = StringToFloat(arg2);
		endPoint[2] = StringToFloat(arg3);
		
		entity = Edict_GetClosest(endPoint);
		
		if(entity == 0 || !Entity_IsValid(entity)){
		
			ReplyToCommand(client,"%sCan't find entity at position: %f %f %f", Plugin_Tag, endPoint[0], endPoint[1], endPoint[2]);
			return Plugin_Handled;
		}
	}
	else {
		
		decl String:command[MAX_NAME_LENGTH];
		GetCmdArg(0,command,sizeof(command));
		ReplyToCommand(client, "%sInvalid argument count",Plugin_Tag);
		ReplyToCommand(client, "%sUsage: %s [entity hammer id]",Plugin_Tag,command);
		return Plugin_Handled;
	}
	
	decl String:classname[MAX_NAME_LENGTH];
	Entity_GetClassName(entity,classname,sizeof(classname));

	LogAction(client, -1, "\"%L\" removing the entity '%s' with id: %d", client, classname, entity);
	AdminToolsShowActivity(client, Plugin_Tag, "Removing the entity '%s'", classname);
	
	if (client != 0) {
		eyeOrigin[2] -= 5.0;
		TE_SetupBeamPoints(eyeOrigin, endPoint, g_iSprite_LaserBeam, 0, 0, 0, 0.45, 5.0, 0.1, 1, 0.0, {255,0,0,255}, 0);
		
		if (IsPlayerAlive(client)) {
			TE_SendToAll();
		}
		else {
			TE_SendToClient(client);
		}
		Effect_FadeOut(entity,true,true);
	}
	else {
		Entity_Kill(entity);
	}
	return Plugin_Handled;
}

public Action:Command_Input(client, args) {

	if (args < 1) {
		
		decl String:command[MAX_NAME_LENGTH];
		GetCmdArg(0,command,sizeof(command));
		ReplyToCommand(client, "%sUsage: %s <command>",Plugin_Tag,command);
		return Plugin_Handled;
	}

	decl Float:eyeOrigin[3], Float:eyeAngles[3];
	GetClientEyePosition(client,eyeOrigin);
	GetClientEyeAngles(client,eyeAngles);

	new Handle:trace = TR_TraceRayFilterEx(eyeOrigin, eyeAngles, MASK_VISIBLE, RayType_Infinite,TraceFilter_FilterPlayer);
	new entity = TR_GetEntityIndex(trace);
	CloseHandle(trace);

	if(entity == 0 || !Entity_IsValid(entity)){

		ReplyToCommand(client,"%sInvalid aim target",Plugin_Tag);
		return Plugin_Handled;
	}

	decl String:argString[128], String:classname[MAX_NAME_LENGTH];
	GetCmdArgString(argString,sizeof(argString));
	Entity_GetClassName(entity,classname,sizeof(classname));

	LogAction(client, -1, "\"%L\" sending the input '%s' to the entity '%s' with id: %d", client, argString, classname, entity);
	AdminToolsShowActivity(client, Plugin_Tag, "Sending the input '%s' to the entity '%s'", argString, classname);

	AcceptEntityInput(entity,argString);
	return Plugin_Handled;
}

public Action:Command_Disarm(client, args) {

	if (args < 1) {

		decl String:command[MAX_NAME_LENGTH];
		GetCmdArg(0,command,sizeof(command));
		ReplyToCommand(client, "%sUsage: %s <target>",Plugin_Tag,command);
		return Plugin_Handled;
	}

	decl String:target[MAX_TARGET_LENGTH];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS+1];
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

		ReplyToTargetError(client,target_count);
		return Plugin_Handled;
	}

	for (new i=0; i<target_count; ++i) {
		if (g_evEngine_Version == Engine_CSS && g_bExtensionCstrikeLoaded) {
			LOOP_CLIENTWEAPONS(target_list[i],weapon,index) {
				CS_DropWeapon(target_list[i],weapon,false,true);
				Entity_Kill(weapon);
			}
		}
		else {
			Client_RemoveAllWeapons(target_list[i]);
		}
	}

	LogAction(client, -1, "\"%L\" removed all weapons from target %s", client, target);
	AdminToolsShowActivity(client, Plugin_Tag, "Removed all weapons from target %s", target);
	return Plugin_Handled;
}

public Action:Command_Give(client, args) {

	if (args < 2) {
		
		decl String:command[MAX_NAME_LENGTH];
		GetCmdArg(0,command,sizeof(command));
		ReplyToCommand(client, "%sUsage: %s <target> <item/weapon>",Plugin_Tag,command);
		return Plugin_Handled;
	}

	decl String:target[MAX_TARGET_LENGTH];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS+1];
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

		ReplyToTargetError(client,target_count);
		return Plugin_Handled;
	}

	decl String:weapon[MAX_TARGET_LENGTH];
	GetCmdArg(2, weapon, sizeof(weapon));
	
	for (new i=0; i<target_count; ++i) {

		if(GivePlayerItem(target_list[i],weapon) == -1){

			if(StrContains(weapon,"weapon_",false) != 0){
				Format(weapon,sizeof(weapon),"weapon_%s",weapon);
				i--;
			}
			else {
				ReplyToCommand(client, "%sInvalid item/weapon",Plugin_Tag);
				return Plugin_Handled;
			}
		}
	}

	LogAction(client, -1, "\"%L\" gave weapon '%s' to target %s", client, weapon, target);
	AdminToolsShowActivity(client, Plugin_Tag, "Given weapon '%s' to target %s", weapon, target);
	return Plugin_Handled;
}

public Action:Command_Respawn(client, args) {

	decl String:command[MAX_NAME_LENGTH];
	GetCmdArg(0,command,sizeof(command));

	if (args < 1) {
		
		ReplyToCommand(client, "%sUsage: %s <target>",Plugin_Tag,command);
		return Plugin_Handled;
	}

	decl String:target[MAX_TARGET_LENGTH];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS+1];
	decl bool:tn_is_ml;
	
	new target_count = ProcessTargetString(
		target,
		client,
		target_list,
		sizeof(target_list),
		COMMAND_FILTER_CONNECTED,
		target_name,
		sizeof(target_name),
		tn_is_ml
	);

	for (new i=0; i<target_count; ++i) {

		if(!Client_IsValid(target_list[i]) || GetClientTeam(target_list[i]) <= 1){

			new j = i;
			for (; j+1<target_count; ++j) {
				target_list[j] = target_list[j+1];
			}
			target_list[j+1] = -1;
			target_count--;
		}
	}
	
	if (target_count <= 0) {

		ReplyToTargetError(client,target_count);
		return Plugin_Handled;
	}
	
	for (new i=0; i<target_count; ++i) {

		RespawnPlayer(target_list[i]);
	}

	LogAction(client, -1, "\"%L\" respawned target %s", client, target);
	AdminToolsShowActivity(client, Plugin_Tag, "Respawned target %s", target);
	return Plugin_Handled;
}
public Action:Command_Team(client, args) {

	if (args != 2) {
		
		decl String:command[MAX_NAME_LENGTH];
		GetCmdArg(0,command,sizeof(command));
		ReplyToCommand(client, "%sUsage: %s <target> <teamname|teamid>",Plugin_Tag,command);
		return Plugin_Handled;
	}

	decl String:target[MAX_TARGET_LENGTH];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS+1];
	decl bool:tn_is_ml;
	
	new target_count = ProcessTargetString(
		target,
		client,
		target_list,
		sizeof(target_list),
		COMMAND_FILTER_CONNECTED,
		target_name,
		sizeof(target_name),
		tn_is_ml
	);
	
	if (target_count <= 0) {

		ReplyToTargetError(client,target_count);
		return Plugin_Handled;
	}

	decl String:arg2[MAX_NAME_LENGTH];
	GetCmdArg(2, arg2, sizeof(arg2));
	new team = String_IsNumeric(arg2) ? StringToInt(arg2) : FindTeamByName(arg2);

	decl String:teamName[MAX_NAME_LENGTH];
	GetTeamName(team,teamName,sizeof(teamName));

	for (new i=0; i<target_count; ++i) {

		if(!SwitchTeam(target_list[i], team)){
		
			ReplyToCommand(client, "%sInvalid Team",Plugin_Tag);
			return Plugin_Handled;
		}
	}

	LogAction(client, -1, "\"%L\" changed team to %s of target %s", client, teamName, target);
	AdminToolsShowActivity(client, Plugin_Tag, "Changed team to %s of target %s", teamName, target);
	return Plugin_Handled;
}
public Action:Command_God(client, args) {

	if (!Math_IsInBounds(args,1,2)) {
		
		decl String:command[MAX_NAME_LENGTH];
		GetCmdArg(0,command,sizeof(command));
		ReplyToCommand(client, "%sUsage: %s <target> [0|1]",Plugin_Tag,command);
		return Plugin_Handled;
	}

	decl String:target[MAX_TARGET_LENGTH];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS+1];
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

		ReplyToTargetError(client,target_count);
		return Plugin_Handled;
	}

	new setSwitch = -1;

	if (args > 1) {

		decl String:arg2[MAX_NAME_LENGTH];
		GetCmdArg(2, arg2, sizeof(arg2));
		setSwitch = StringToInt(arg2);
	}

	if(!Math_IsInBounds(setSwitch,-1,1)){

		ReplyToCommand(client, "%sThe 2. parameter is out of bounds.",Plugin_Tag);
		return Plugin_Handled;
	}

	for (new i=0; i<target_count; ++i) {

		switch(setSwitch){

			case -1:{
				Entity_SetTakeDamage(target_list[i], (Entity_GetTakeDamage(target_list[i]) == DAMAGE_YES) ? DAMAGE_NO : DAMAGE_YES);
			}
			case 0:{
				Entity_SetTakeDamage(target_list[i], DAMAGE_YES);
			}
			case 1:{
				Entity_SetTakeDamage(target_list[i], DAMAGE_NO);
			}
		}
	}

	if(setSwitch == -1){
		LogAction(client, -1, "\"%L\" toggled god mode for target %s", client, target);
		AdminToolsShowActivity(client, Plugin_Tag, "Toggling god mode for target %s", target);
	}
	else {
		LogAction(client, -1, "\"%L\" switched god mode to %d for target %s", client, setSwitch, target);
		AdminToolsShowActivity(client, Plugin_Tag, "Switching god mode to %d for target %s", setSwitch, target);
	}
	return Plugin_Handled;
}

public Action:Command_Speed(client, args) {

	if (args != 2) {
		
		decl String:command[MAX_NAME_LENGTH];
		GetCmdArg(0,command,sizeof(command));
		ReplyToCommand(client, "%sUsage: %s <target> <[+|-]multiplier>",Plugin_Tag,command);
		return Plugin_Handled;
	}

	decl String:target[MAX_TARGET_LENGTH];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS+1];
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

		ReplyToTargetError(client,target_count);
		return Plugin_Handled;
	}

	decl String:arg2[MAX_NAME_LENGTH];
	GetCmdArg(2, arg2, sizeof(arg2));
	new Float:value = StringToFloat(arg2);

	if (arg2[0] == '-' || arg2[0] == '+') {
		
		for (new i=0; i<target_count; ++i) {
			
			SetEntPropFloat(target_list[i], Prop_Data, "m_flLaggedMovementValue", GetEntPropFloat(target_list[i], Prop_Data, "m_flLaggedMovementValue")+value);
		}
	}
	else {
		
		for (new i=0; i<target_count; ++i) {
			
			SetEntPropFloat(target_list[i], Prop_Data, "m_flLaggedMovementValue", value);
		}
	}

	
	LogAction(client, -1, "\"%L\" sets speed to %f for target %s", client, value, target);
	AdminToolsShowActivity(client, Plugin_Tag, "Setting speed to %f for target %s", value, target);
	return Plugin_Handled;
}

public Action:Command_Freeze(client, args) {

	if (!Math_IsInBounds(args,1,2)) {
		
		decl String:command[MAX_NAME_LENGTH];
		GetCmdArg(0,command,sizeof(command));
		ReplyToCommand(client, "%sUsage: %s <target> [0(=disable)|1(=movement)|2(=movement+view)]",Plugin_Tag,command);
		return Plugin_Handled;
	}

	decl String:target[MAX_TARGET_LENGTH];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS+1];
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

		ReplyToTargetError(client,target_count);
		return Plugin_Handled;
	}

	new setSwitch = -1;

	if (args > 1) {

		decl String:arg2[MAX_NAME_LENGTH];
		GetCmdArg(2, arg2, sizeof(arg2));
		setSwitch = StringToInt(arg2);
	}

	if(!Math_IsInBounds(setSwitch,-1,2)){

		ReplyToCommand(client, "%sThe 2. parameter is out of bounds.",Plugin_Tag);
		return Plugin_Handled;
	}

	for (new i=0; i<target_count; ++i) {

		switch(setSwitch){

			case -1:{
				
				Entity_RemoveFlags(target_list[i],FL_ATCONTROLS);

				if(GetEntityMoveType(target_list[i]) == MOVETYPE_WALK){
					SetEntityMoveType(target_list[i], MOVETYPE_NONE);
				}
				else {
					SetEntityMoveType(target_list[i], MOVETYPE_WALK);
					TeleportEntityRelative(target_list[i], Float:{0.0, 0.0, 10.0}, NULL_VECTOR, NULL_VECTOR);
				}

			}
			case 0:{
				Entity_RemoveFlags(target_list[i],FL_ATCONTROLS);
				SetEntityMoveType(target_list[i], MOVETYPE_WALK);
				TeleportEntityRelative(target_list[i], Float:{0.0, 0.0, 10.0}, NULL_VECTOR, NULL_VECTOR);
			}
			case 1:{
				Entity_RemoveFlags(target_list[i],FL_ATCONTROLS);
				SetEntityMoveType(target_list[i], MOVETYPE_NONE);
			}
			case 2:{
				Entity_AddFlags(target_list[i],FL_ATCONTROLS);
				SetEntityMoveType(target_list[i], MOVETYPE_NONE);
			}
		}
	}

	if(setSwitch == -1){
		LogAction(client, -1, "\"%L\" toggled god mode for target %s", client, target);
		AdminToolsShowActivity(client, Plugin_Tag, "Toggling god mode for target %s", target);
	}
	else {
		LogAction(client, -1, "\"%L\" switched god mode to %d for target %s", client, setSwitch, target);
		AdminToolsShowActivity(client, Plugin_Tag, "Switching god mode to %d for target %s", setSwitch, target);
	}
	return Plugin_Handled;
}

public Action:Command_Bury(client, args) {

	if (!Math_IsInBounds(args,1,2)) {
		
		decl String:command[MAX_NAME_LENGTH];
		GetCmdArg(0,command,sizeof(command));
		ReplyToCommand(client, "%sUsage: %s <target> [0|1]",Plugin_Tag,command);
		return Plugin_Handled;
	}

	decl String:target[MAX_TARGET_LENGTH];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS+1];
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

		ReplyToTargetError(client,target_count);
		return Plugin_Handled;
	}

	new setSwitch = -1;

	if (args > 1) {

		decl String:arg2[MAX_NAME_LENGTH];
		GetCmdArg(2, arg2, sizeof(arg2));
		setSwitch = StringToInt(arg2);
	}

	if(!Math_IsInBounds(setSwitch,-1,1)){

		ReplyToCommand(client, "%sThe 2. parameter is out of bounds.",Plugin_Tag);
		return Plugin_Handled;
	}

	for (new i=0; i<target_count; ++i) {

		switch(setSwitch){

			case -1:{
				BuryClient(target_list[i], !g_bClient_IsBuried[target_list[i]]);
			}
			case 0:{
				BuryClient(target_list[i], false);
			}
			case 1:{
				BuryClient(target_list[i], true);
			}
		}
	}

	if(setSwitch == -1){
		LogAction(client, -1, "\"%L\" toggled bury punishment for target %s", client, target);
		AdminToolsShowActivity(client, Plugin_Tag, "Toggling bury punishment for target %s", target);
	}
	else {
		LogAction(client, -1, "\"%L\" switched bury punishment to %d for target %s", client, setSwitch, target);
		AdminToolsShowActivity(client, Plugin_Tag, "Switching bury punishment to %d for target %s", setSwitch, target);
	}
	return Plugin_Handled;
}

public Action:Command_Money(client, args) {
	
	if (!Math_IsInBounds(args,1,2)) {
		
		decl String:command[MAX_NAME_LENGTH];
		GetCmdArg(0,command,sizeof(command));
		ReplyToCommand(client, "%sUsage: %s <target> [[+|-]value]",Plugin_Tag,command);
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH], String:arg2[8];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS+1];
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
		ReplyToTargetError(client,target_count);
		return Plugin_Handled;
	}
	
	if(args == 1){
		
		LogAction(client, -1, "\"%L\" has seen money of target %s", client, target);
		AdminToolsShowActivity(client, Plugin_Tag, "Showing money of target %s", target);

		for (new i=0; i<target_count; ++i) {
			
			ReplyToCommand(client, "%s%N money is %d", Plugin_Tag, client, Client_GetMoney(target_list[i]));
		}
		
		return Plugin_Handled;
	}
	else {
		
		GetCmdArg(2, arg2, sizeof(arg2));
		new money = StringToInt(arg2);
		
		if (arg2[0] == '-' || arg2[0] == '+') {
			
			for (new i=0; i<target_count; ++i) {
				
				Client_SetMoney(target_list[i], Client_GetMoney(target_list[i])+money);
			}
		}
		else {
			
			for (new i=0; i<target_count; ++i) {
				
				Client_SetMoney(target_list[i], money);
			}
		}
		
		LogAction(client, -1, "\"%L\" sets money to %d for target %s", client, money, target);
		AdminToolsShowActivity(client, Plugin_Tag, "Set money to %d for target %s", money, target);
	}
	return Plugin_Handled;
}

public Action:Command_KSay(client, args) {

	if (args < 3) {
		
		decl String:command[MAX_NAME_LENGTH];
		GetCmdArg(0,command,sizeof(command));
		ReplyToCommand(client, "%sUsage: %s <target> <duration> <text>",Plugin_Tag,command);
		return Plugin_Handled;
	}
	
	decl String:target[MAX_TARGET_LENGTH];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS+1];
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
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	decl String:arg2[11];
	GetCmdArg(2, arg2, sizeof(arg2));
	new Float:duration = StringToFloat(arg2);
	if (duration <= 0.0) {
		ReplyToCommand(client, "%sThe parameter 'duration' seems to be invalid", Plugin_Tag);
		return Plugin_Handled;
	}

	// using 11+MAX_TARGET_LENGTH because target and arg2 are being removed:
	decl String:argString[192+11+MAX_TARGET_LENGTH];
	GetCmdArgString(argString, sizeof(argString));

	// Replace all the escaped \n with actual \n.
	ReplaceStringEx(argString, sizeof(argString), "\\n", "\n", -1, -1, false);

	// Remove the first and second argument.
	ReplaceStringEx(argString,sizeof(argString),target,"", -1, -1, false);
	ReplaceStringEx(argString,sizeof(argString),arg2,"", -1, -1, false);
	String_Trim(argString,argString,sizeof(argString), " \t\"");

	if(argString[0] == '\0'){
		ReplyToCommand(client, "%sThe parameter 'text' seems to be invalid", Plugin_Tag);
		return Plugin_Handled;
	}
	
	LogAction(client, -1, "\"%L\" triggered sm_ksay, target: %s, duration %.1f (text  %s)", client, target, duration, argString);
	AdminToolsShowActivity(client, Plugin_Tag, "triggered sm_ksay, target: %s, duration %.1f (text  %s)", target, duration, argString);

	// Datapack:
	// Float duration
	// String: text
	// int number of targets
	// int all targets
	// int ...
	new Handle:dataPack = CreateDataPack();
	WritePackFloat(dataPack, duration);
	WritePackString(dataPack, argString);
	WritePackCell(dataPack, sizeof(target_count));
	for (new i=0; i<target_count; ++i) {
		WritePackCell(dataPack, target_list[i]);
	}
	
	// Direct call because we want to display the message and then wait a second.
	Timer_KSay(INVALID_HANDLE, dataPack);
	return Plugin_Handled;
}

public Action:Timer_KSay(Handle:timer, any:dataPack) {

	ResetPack(dataPack);

	// If its the first run, don't subtract a second here 
	new Float:duration = ReadPackFloat(dataPack) - ((timer == INVALID_HANDLE) ? 0.0 : 1.0);
	decl String:text[192];
	ReadPackString(dataPack, text, sizeof(text));
	new target_count = ReadPackCell(dataPack);
	decl target_list[MAXPLAYERS+1];

	for (new i=0; i<target_count; ++i) {

		target_list[i] = ReadPackCell(dataPack);

		// We are done, clear the key hint box.
		if (duration <= 0.0) {
			Client_PrintKeyHintText(target_list[i], " ");
		}
		else {
			Client_PrintKeyHintText(target_list[i], text);
		}
	}

	// We are done, close the datapack.
	if (duration <= 0.0) {
		CloseHandle(dataPack);
		return Plugin_Continue;
	}

	// Don't destroy the datapack but clear it.
	ResetPack(dataPack, true);

	// Now repack the datapack for a new run.
	WritePackFloat(dataPack, duration);
	WritePackString(dataPack, text);
	WritePackCell(dataPack, sizeof(target_count));
	for (new i=0; i<target_count; ++i) {
		WritePackCell(dataPack, target_list[i]);
	}

	// Wait a second or whats left of duration, if its below a second.
	new Float:nextTick = (duration >= 1.0) ? 1.0 : duration;
	CreateTimer(nextTick, Timer_KSay, dataPack, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

/**************************************************************************************
	T E A M
**************************************************************************************/
public Action:Command_SetTeamScore(client, args) {
	
	if (args != 2) {
		
		decl String:command[MAX_NAME_LENGTH];
		GetCmdArg(0,command,sizeof(command));
		ReplyToCommand(client, "%sUsage: %s <teamname|teamid> <[+|-]value>",Plugin_Tag,command);
		return Plugin_Handled;
	}
	
	decl String:arg1[MAX_NAME_LENGTH], String:arg2[11];

	GetCmdArg(1, arg1, sizeof(arg1));
	new team = String_IsNumeric(arg1) ? StringToInt(arg1) : FindTeamByName(arg1);

	if(!Team_IsValid(team)){
		ReplyToCommand(client, "%sInvalid Team",Plugin_Tag);
		return Plugin_Handled;
	}

	GetCmdArg(2, arg2, sizeof(arg2));
	new teamscore = StringToInt(arg2);
	
	Team_SetScore(team, teamscore);
	
	LogAction(client, -1, "\"%L\" sets team score of team %d to %d", client, team, teamscore);
	AdminToolsShowActivity(client, Plugin_Tag, "Set team score of team %d to %d", team, teamscore);
	return Plugin_Handled;
}

public Action:Command_BalanceTeam(client, args) {
	
	new countOne = Team_GetClientCount(TEAM_ONE,CLIENTFILTER_INGAMEAUTH);
	new countTwo = Team_GetClientCount(TEAM_TWO,CLIENTFILTER_INGAMEAUTH);
	new switchCount = 0;
	decl String:teamName[MAX_NAME_LENGTH];
	
	if (countOne < countTwo) {
		
		GetTeamName(TEAM_ONE, teamName, sizeof(teamName));
		
		switchCount = RoundToFloor(float(countTwo - countOne) / 2.0);
		
		if(countOne + switchCount <= g_iMap_SpawnPoints[TEAM_ONE]){
			
			for(new i=0; i<switchCount; i++){
				
				new player = Client_GetRandom(CLIENTFILTER_TEAMTWO);
				SwitchTeam(player, TEAM_ONE);
			}
		}
		else {
			
			ReplyToCommand(client, "%sNot enough spawn points for team %s", Plugin_Tag, teamName);
			return Plugin_Handled;
		}
	}
	else if (countOne > countTwo) {
		
		GetTeamName(TEAM_TWO, teamName, sizeof(teamName));
		
		switchCount = RoundToFloor(float(countOne - countTwo) / 2.0);
		
		if(countTwo + switchCount <= g_iMap_SpawnPoints[TEAM_TWO]){
		
			for(new i=0; i<switchCount; i++){
				
				new player = Client_GetRandom(CLIENTFILTER_TEAMONE);
				SwitchTeam(player, TEAM_TWO);
			}
		}
		else {
			
			ReplyToCommand(client, "%sNot enough spawn points for team %s", Plugin_Tag, teamName);
			return Plugin_Handled;
		}
	}
	
	if (countOne == countTwo || switchCount == 0) {
		
		ReplyToCommand(client, "%sTeams are already even", Plugin_Tag);
		return Plugin_Handled;
	}
	
	LogAction(client, -1, "\"%L\" balances teams by switching %d players to team %s", client, switchCount, teamName);
	AdminToolsShowActivity(client, Plugin_Tag, "Balance teams by switching %d players to team %s", switchCount, teamName);
	return Plugin_Handled;
}

/**************************************************************************************
	M A P
**************************************************************************************/
public Action:Command_ReloadMap(client, args) {
	
	decl String:mapName[64];
	GetCurrentMap(mapName, sizeof(mapName));

	LogAction(client, -1, "\"%L\" reloads the map '%s'", client, mapName);
	AdminToolsShowActivity(client, Plugin_Tag, "Reloading the map '%s'", mapName);

	ServerCommand("changelevel %s", mapName);
	return Plugin_Handled;
}
public Action:Command_ExtendMap(client, args) {

	decl String:command[MAX_NAME_LENGTH];
	GetCmdArg(0,command,sizeof(command));

	if(g_cvarMpTimelimit == INVALID_HANDLE){
		ReplyToCommand(client, "%sError: \"%s\" requires the console variable \"mp_timelimit\", which can't be found",Plugin_Tag,command);
		return Plugin_Handled;
	}

	if (args != 1) {
		ReplyToCommand(client, "%sUsage: %s <[+|-]minutes>",Plugin_Tag,command);
		return Plugin_Handled;
	}
	
	decl String:argString[11];
	GetCmdArgString(argString, sizeof(argString));

	new Float:value = StringToFloat(argString);
	SetConVarFloat(g_cvarMpTimelimit, GetConVarFloat(g_cvarMpTimelimit) + value);

	decl String:mapName[64];
	GetCurrentMap(mapName, sizeof(mapName));

	decl timeleft;
	GetMapTimeLeft(timeleft);

	LogAction(client, -1, "\"%L\" extends the map '%s' by %.0f minutes", client, mapName, value);
	AdminToolsShowActivity(client, Plugin_Tag, "Extending the map '%s' by %.0f minutes", mapName, value);

	LOOP_CLIENTS(player,CLIENTFILTER_INGAMEAUTH){
		FakeClientCommand(player,"timeleft");
	}
	return Plugin_Handled;
}
/**************************************************************************************
	D E V E L O P E R   T O O L S :   I N V I S I B L E
**************************************************************************************/

public Action:Command_Debug(client, args) {

	decl String:command[MAX_NAME_LENGTH];
	GetCmdArg(0,command,sizeof(command));

	if (client == 0 && args == 0) {
		
		ReplyToCommand(client,"%sOnly ingame usable WITHOUT parameter!",Plugin_Tag);
		ReplyToCommand(client, "%sUsage: %s <hammerid>",Plugin_Tag,command);
		return Plugin_Handled;
	}
	
	decl Float:eyeOrigin[3], Float:eyeAngles[3], Float:endPoint[3];
	
	new entity = -1;
	if (args == 0) {
		
		
		GetClientEyePosition(client,eyeOrigin);
		GetClientEyeAngles(client,eyeAngles);
	
		new Handle:trace = TR_TraceRayFilterEx(eyeOrigin, eyeAngles, MASK_VISIBLE, RayType_Infinite, TraceFilter_FilterPlayer);
		entity = TR_GetEntityIndex(trace);
		TR_GetEndPosition(endPoint, trace);
		CloseHandle(trace);
		
		if(entity == 0 || !Entity_IsValid(entity)){
			
			entity = GetClientAimTarget(client, false);
		
			if(entity == 0 || !Entity_IsValid(entity)){
				
				entity = Edict_GetClosest(eyeOrigin, false, client);
				
				if(entity == 0 || !Entity_IsValid(entity)){
			
					ReplyToCommand(client,"%sNo entity found (%d)",Plugin_Tag,entity);
					return Plugin_Handled;
				}
			}
		}
	}
	else {
		
		decl String:argString[16];
		GetCmdArgString(argString, sizeof(argString));
		
		if (!String_IsNumeric(argString)) {
			ReplyToCommand(client,"%sHammer ID must be a number!",Plugin_Tag);
			ReplyToCommand(client, "%sUsage: %s [hammerid]",Plugin_Tag,command);
			return Plugin_Handled;
		}
		
		entity = Entity_FindByHammerId(StringToInt(argString));
		
		if(entity == 0 || !Entity_IsValid(entity)){
			
			ReplyToCommand(client,"%sNo entity found with hammer id: %s (%d)",Plugin_Tag,argString,entity);
			return Plugin_Handled;
		}
	}
	
	// Get Info
	new entityReference = EntIndexToEntRef(entity);
	
	decl String:classname[MAX_NAME_LENGTH];
	decl String:netClass[MAX_NAME_LENGTH];
	Entity_GetClassName(entity,classname,sizeof(classname));
	GetEntityNetClass(entity, netClass, sizeof(netClass));
	
	//model
	decl String:modelPath[PLATFORM_MAX_PATH];
	Entity_GetModel(entity,modelPath,sizeof(modelPath));
	new modelIndex = Entity_GetModelIndex(entity);
	
	new hammerId = Entity_GetHammerId(entity);
	//name
	decl String:name[MAX_NAME_LENGTH];
	decl String:globalName[MAX_NAME_LENGTH];
	Entity_GetName(entity,name,sizeof(name));
	Entity_GetGlobalName(entity,globalName,sizeof(globalName));
	
	decl Float:origin[3];
	Entity_GetAbsOrigin(entity,origin);
	decl Float:angles[3];
	if (Client_IsValid(entity)) {
		GetClientEyeAngles(entity, angles);
	}
	else {
		Entity_GetAbsAngles(entity,angles);
	}
	
	// Laser!
	if (client != 0) {
		
		eyeOrigin[2] -= 5.0;
		TE_SetupBeamPoints(eyeOrigin, origin, g_iSprite_LaserBeam, 0, 0, 0, MAX_BEAM_DURATION, 0.1, 0.01, 0, 0.001, {0,255,0,255}, 0);
		TE_SendToClient(client);
		
		Client_PrintToChat(client, false, "%s{OG}Found entity: {G}%s{OG} HammerId: {G}%d{OG}. See console for full output...",Plugin_Tag, classname, hammerId);
	}
	
	//Movement
	//new MoveType:moveType = GetEntityMoveType(entity);
	
	PrintToConsole(client,"%s",PRINT_SEPERATOR);
	PrintToConsole(client,"%s",PRINT_SEPERATOR);
	PrintToConsole(client,"%s%s::%s",Plugin_Tag,netClass,classname);
	PrintToConsole(client,"%sIndex: %d Reference: %d HammerId: %d",Plugin_Tag,entity,entityReference,hammerId);
	PrintToConsole(client,"%sName: \"%s\" GlobalName: \"%s\"",Plugin_Tag,name,globalName);
	
	PrintToConsole(client,"%s",PRINT_SEPERATOR);
	PrintToConsole(client,"%sModelIndex: %d ModelPath: \"%s\"",Plugin_Tag,modelIndex,modelPath);
	
	//PrintToConsole(client,"%sSolidType: %d SolidFlag: %d MoveType: %d",Plugin_Tag,solidType,solidFlags,moveType);
	
	PrintToConsole(client,"%s",PRINT_SEPERATOR);
	PrintToConsole(client,"%sabsOrigin: setpos %18f %18f %18f",Plugin_Tag, origin[0], origin[1], origin[2]);
	PrintToConsole(client,"%sabsAngles: setang %18f %18f %18f",Plugin_Tag, angles[0], angles[1], angles[2]);
	
	new Float:mins[3], Float:maxs[3];
	if (FindSendPropOffs(netClass, "m_vecMins") != -1) {
		
		PrintToConsole(client,"%s",PRINT_SEPERATOR);
		
		Entity_GetMinSize(entity,mins);
		Entity_GetMaxSize(entity,maxs);
		PrintToConsole(client,"%sm_vecMins: %25f %18f %18f",Plugin_Tag, mins[0], mins[1], mins[2]);
		PrintToConsole(client,"%sm_vecMaxs: %25f %18f %18f",Plugin_Tag, maxs[0], maxs[1], maxs[2]);
	}
	
	if (client != 0) {
		
		if (GetVectorLength(mins, true) == 0.0 && GetVectorLength(maxs, true) == 0.0) {
			Array_Fill(mins, sizeof(mins), -8.0);
			Array_Fill(maxs, sizeof(maxs), 8.0);
		}

		if (Client_IsValid(entity)) {

			// Players can only rotate... (or at least its model)
			new Float:playerAngles[3];
			playerAngles[0] = 0.0;
			playerAngles[1] = angles[1];
			playerAngles[2] = 0.0;

			Effect_DrawBeamBoxRotatableToClient(client, origin, mins, maxs, playerAngles, g_iSprite_LaserBeam, 0, 0, 0, MAX_BEAM_DURATION, 0.1, 0.1, 0, 0.001, { 0, 255, 0, 255 }, 0);
			
			maxs[0] += 8.0;
			maxs[1] += 8.0;
			maxs[2] += 8.0;
			Effect_DrawAxisOfRotationToClient(client, origin, playerAngles, maxs, g_iSprite_LaserBeam, 0, 0, 0, MAX_BEAM_DURATION, 0.1, 0.1, 0, 0.001, 0);
		}
		else {
			
			Effect_DrawBeamBoxRotatableToClient(client, origin, mins, maxs, angles, g_iSprite_LaserBeam, 0, 0, 0, MAX_BEAM_DURATION, 0.1, 0.1, 0, 0.001, { 0, 255, 0, 255 }, 0);
			
			maxs[0] += 8.0;
			maxs[1] += 8.0;
			maxs[2] += 8.0;
			Effect_DrawAxisOfRotationToClient(client, origin, angles, maxs, g_iSprite_LaserBeam, 0, 0, 0, MAX_BEAM_DURATION, 0.1, 0.1, 0, 0.001, 0);
		}
		/*AddVectors(origin, mins, mins);
		AddVectors(origin, maxs, maxs);

		TE_SetupBeamPoints(eyeOrigin, mins, g_iSprite_LaserBeam, 0, 0, 0, MAX_BEAM_DURATION, 0.5, 0.51, 0, 0.001, {0,255,255,255}, 0);
		TE_SendToClient(client);
		
		TE_SetupBeamPoints(eyeOrigin, maxs, g_iSprite_LaserBeam, 0, 0, 0, MAX_BEAM_DURATION, 0.5, 0.51, 0, 0.001, {255,255,0,255}, 0);
		TE_SendToClient(client);*/
	}
	
	//laserTarget
	new String:target_Name[MAX_NAME_LENGTH];
	if (FindSendPropInfo(netClass, "m_iszLaserTarget") > 0) {
		GetEntPropString(entity, Prop_Send, "m_iszLaserTarget", target_Name, sizeof(target_Name));
		if(target_Name[0] != '\0'){
			
			new target = Entity_FindByName(target_Name);
			if (Entity_IsValid(target)) {
				
				new String:target_ClassName[MAX_NAME_LENGTH];
				Entity_GetClassName(target,target_ClassName,sizeof(target_ClassName));
				
				PrintToConsole(client,"%s",PRINT_SEPERATOR);
				PrintToConsole(client,"%sThis entity has a valid m_iszLaserTarget: %s",Plugin_Tag,target_Name);
				PrintToConsole(client,"%s\tIndex: %d Reference: %d",Plugin_Tag,target,EntIndexToEntRef(target));
				PrintToConsole(client,"%s\tName: %s ClassName: %s",Plugin_Tag,target_Name,target_ClassName);
			}
			else {
				
				PrintToConsole(client,"%s",PRINT_SEPERATOR);
				PrintToConsole(client,"%sThis entity has a INVALID m_iszLaserTarget: %s",Plugin_Tag, target_Name);
			}
		}
	}
	
	//target
	if (FindDataMapOffs(entity, "m_target") != -1) {
		
		Entity_GetTargetName(entity,target_Name,sizeof(target_Name));
		if(target_Name[0] != '\0'){
			new target = Entity_FindByName(target_Name);
			if(Entity_IsValid(target)){
				
				new String:target_ClassName[MAX_NAME_LENGTH];
				Entity_GetClassName(target,target_ClassName,sizeof(target_ClassName));
				
				PrintToConsole(client,"%s",PRINT_SEPERATOR);
				PrintToConsole(client,"%sThis entity has a target: %s",Plugin_Tag, target_Name);
				PrintToConsole(client,"%s\tIndex: %d HammerId: %d",Plugin_Tag,target,Entity_GetHammerId(target));
				PrintToConsole(client,"%s\tName: %s ClassName: %s",Plugin_Tag,target_Name,target_ClassName);
			}
			else {
				
				PrintToConsole(client,"%s",PRINT_SEPERATOR);
				PrintToConsole(client,"%sThis entity has a INVALID m_target: %s",Plugin_Tag, target_Name);
			}
		}
	}
	
	//parent
	new parent = Entity_GetParent(entity);
	if(Entity_IsValid(parent)){
		
		new String:parent_Name[MAX_NAME_LENGTH];
		Entity_GetName(parent,parent_Name,sizeof(parent_Name));
		
		new String:parent_ClassName[MAX_NAME_LENGTH];
		Entity_GetClassName(parent,parent_ClassName,sizeof(parent_ClassName));
		
		PrintToConsole(client,"%s",PRINT_SEPERATOR);
		PrintToConsole(client,"%sThis entity has a parent:",Plugin_Tag);
		PrintToConsole(client,"%s\tParentIndex: %d ParentReference: %d",Plugin_Tag,parent,EntIndexToEntRef(parent));
		PrintToConsole(client,"%s\tParentName: %s ParentClassName: %s",Plugin_Tag,parent_Name,parent_ClassName);
	}
	else {
		
		PrintToConsole(client,"%s",PRINT_SEPERATOR);
		PrintToConsole(client,"%sThis entity has a INVALID m_iParent: %d",Plugin_Tag, parent);
	}
	
	//children (comming soon?)
	
	PrintToConsole(client,"%s",PRINT_SEPERATOR);
	PrintToConsole(client,"%s",PRINT_SEPERATOR);
	return Plugin_Handled;
}

/**************************************************************************************
	D E V E L O P E R   T O O L S :   V I S I B L E
**************************************************************************************/
public Action:Command_Point(client,args){
	
	g_bClient_PointActivated[client] = !g_bClient_PointActivated[client];
	
	if(args != 0){
		decl String:argString[11];
		GetCmdArgString(argString,sizeof(argString));
		g_flClient_PointSize[client] = StringToFloat(argString);
	}
	else {
		
		g_flClient_PointSize[client] = 0.1;
	}
	return Plugin_Handled;
}

/**************************************************************************************
	D E P R E C A T E D   C O M M A N D S 
**************************************************************************************/
public Action:Command_Deprecated(client,args){
	
	decl String:command[MAX_NAME_LENGTH];
	GetCmdArg(0,command,sizeof(command));

	if(StrContains(command,"entity",false) != -1){
		PrintToChat(client,"%sCommand '%s' is deprecated, please use sm_input instead!",Plugin_Tag,command);
	}

	return Plugin_Handled;
}

/**************************************************************************************

	E V E N T S

**************************************************************************************/
public Action:Event_CommandEvent(Handle:event, const String:name[], bool:dontBroadcast){

	new String:eventName[MAX_NAME_LENGTH];
	GetEventName(event, eventName, sizeof(eventName));

	new Handle:commandList = INVALID_HANDLE;
	if(GetTrieValue(g_hEvent_ToArray, eventName, commandList)){

		new sizeCommands = GetArraySize(commandList);
		for(new j=0; j<sizeCommands; j++){

			// DataPack:
			// int OwnerUserId
			// int count
			// String command (raw)
			new Handle:dataPack = GetArrayCell(commandList, j);
			ResetPack(dataPack);

			new userId = ReadPackCell(dataPack);
			new owner = -1;
			if(userId <= 0){
				owner = 0;
			}
			else {
				owner = GetClientOfUserId(userId);
			}
			
			// The admin that setup the command left, but if its the server (owner==0) then continue since the server is always online
			if (owner != 0 && !Client_IsValid(owner)) {
				
				// Remove the command
				// TODO: Check if this event can be unhooked
				RemoveFromArray(commandList, j);
				// Move the index 1 step back since the array is now smaller for the next loop
				j--;
				// Recalculate the array size
				sizeCommands = GetArraySize(commandList);
				// Close what we removed
				CloseHandle(dataPack);
				continue;
			}
			
			new count = ReadPackCell(dataPack);
			new String:command[192];
			ReadPackString(dataPack, command, sizeof(command));
			
			// Count -1 means infinite execution
			if(count != -1){
				
				// Not infinite? decrement!
				count--;
				
				// Well we reached our end so lets end this (but continue with current execution)
				if(count <= 0){
					
					RemoveFromArray(commandList, j);
					// Move the index 1 step back since the array is now smaller for the next loop
					j--;
					// Recalculate the array size
					sizeCommands = GetArraySize(commandList);
					// Close what we removed
					CloseHandle(dataPack);
				}
				else {
					// We continue, so lets close and repack the datapack
					CloseHandle(dataPack);
					
					// DataPack:
					// int OwnerUserId
					// int count
					// String command (raw)
					dataPack = CreateDataPack();
					WritePackCell(dataPack, owner);
					WritePackCell(dataPack, count);
					WritePackString(dataPack, command);
					
					// Take over the old packs position and write the handle into it
					SetArrayCell(commandList, j, dataPack);
				}
			}
			
			new Handle:regex = CompileRegex("{?[A-Za-z]+}", PCRE_CASELESS);

			if(regex == INVALID_HANDLE){
				continue;
			}
			
			new skip_text;
			new String:orginalKey[sizeof(command)];
			new String:key[sizeof(command)];

			while ((MatchRegex(regex, command[skip_text])) > 0) {

				// Pick whole string matching with expression pattern.
				if (!GetRegexSubString(regex, 0, orginalKey, sizeof(orginalKey))) {
					break;
				}
				
				String_Trim(orginalKey, key, sizeof(key), "{} \t\r\n");
				
				decl String:replacement[32];
				switch(GetEventKeyDataType(key)){
					
					case DATATYPE_INT: {
						IntToString(GetEventInt(event, key), replacement, sizeof(replacement));
					}
					case DATATYPE_FLOAT: {
						FloatToString(GetEventFloat(event, key), replacement, sizeof(replacement));	
					}
					case DATATYPE_STRING: {
						GetEventString(event, key, replacement, sizeof(replacement));
					}
					default: {
						LogError("event %s has unknowen data type for key: %s", eventName, key);
					}
				}
				
				ReplaceString(command, sizeof(command), orginalKey, replacement);

				// We do not want regex to hit the same part of the input text. Skip the first piece of input text in the next cycle.
				skip_text += StrContains(command[skip_text], orginalKey);
				skip_text += strlen(orginalKey);
			}
			CloseHandle(regex);
			
			if(owner == 0){
				ServerCommand(command);
			}
			else {
				FakeClientCommand(owner,command);
			}
		}
	}
}

/***************************************************************************************


	P L U G I N   F U N C T I O N S


***************************************************************************************/

RegisterAdminTools(){
	
	// Invisible actions which non admins can't see/notice
	PluginManager_RegAdminCmd("sm_time", Command_Future, ADMFLAG_ROOT,"Issues a command in the future");
	PluginManager_RegAdminCmd("sm_future", Command_Future, ADMFLAG_ROOT,"Issues a command in the future");
	//PluginManager_RegAdminCmd("sm_futurelist", Command_FutureList, ADMFLAG_ROOT,"Shows all commands that are issued in the future");
	PluginManager_RegAdminCmd("sm_event", Command_Event, ADMFLAG_ROOT,"Issues a command when an event is fired");
	//PluginManager_RegAdminCmd("sm_eventlist", Command_EventList, ADMFLAG_ROOT,"Shows all commands that are issued when events are fired");
	PluginManager_RegAdminCmd("sm_alias", Command_Alias, ADMFLAG_ROOT,"Creates a new alias command to shrink command chains down to a single command");
	
	// Visible actions which everyone can see/notice
	// Clients & Sometimes Entities
	PluginManager_RegAdminCmd("sm_hp", Command_Health, ADMFLAG_CUSTOM4,"Sets the health of a target");
	PluginManager_RegAdminCmd("sm_health", Command_Health, ADMFLAG_CUSTOM4,"Sets the health of a target");
	PluginManager_RegAdminCmd("sm_mhp", Command_MaxHealth, ADMFLAG_CUSTOM4,"Sets the max health of a target");
	PluginManager_RegAdminCmd("sm_maxhealth", Command_MaxHealth, ADMFLAG_CUSTOM4,"Sets the max health of a target");
	PluginManager_RegAdminCmd("sm_armor", Command_Armor, ADMFLAG_CUSTOM4,"Sets the armor of a target");
	PluginManager_RegAdminCmd("sm_armour", Command_Armor, ADMFLAG_CUSTOM4,"Sets the armor of a target");
	PluginManager_RegAdminCmd("sm_suitpower", Command_Armor, ADMFLAG_CUSTOM4,"Sets the armor of a target");
	PluginManager_RegAdminCmd("sm_score", Command_Score, ADMFLAG_CUSTOM4,"Sets the score of a target");
	PluginManager_RegAdminCmd("sm_deaths", Command_Deaths, ADMFLAG_CUSTOM4,"Sets the deaths of a target");
	PluginManager_RegAdminCmd("sm_connect", Command_Connect, ADMFLAG_CUSTOM4,"Opens a connect box which the target can accept via F3 (by default)");
	PluginManager_RegAdminCmd("sm_exec", Command_Exec,ADMFLAG_BAN,"Execute command on target");
	PluginManager_RegAdminCmd("sm_fexec", Command_FExec,ADMFLAG_BAN,"Fake-execute command on target");
	PluginManager_RegAdminCmd("sm_render", Command_RenderMode, ADMFLAG_CUSTOM4, "Sets the render mode of a target");
	PluginManager_RegAdminCmd("sm_rendermode", Command_RenderMode, ADMFLAG_CUSTOM4, "Sets the render mode of a target");
	PluginManager_RegAdminCmd("sm_fx", Command_RenderFx, ADMFLAG_CUSTOM4, "Sets the render effects (fx) of a target");
	PluginManager_RegAdminCmd("sm_renderfx", Command_RenderFx, ADMFLAG_CUSTOM4, "Sets the render effects (fx) of a target");
	PluginManager_RegAdminCmd("sm_color", Command_RenderColor, ADMFLAG_CUSTOM4, "Sets the render color of a target");
	PluginManager_RegAdminCmd("sm_rendercolor", Command_RenderColor, ADMFLAG_CUSTOM4, "Sets the render color of a target");
	PluginManager_RegAdminCmd("sm_firstperson", Command_Firstperson, ADMFLAG_CUSTOM4, "Switches target to firstperson camera");
	PluginManager_RegAdminCmd("sm_thirdperson", Command_Thirdperson, ADMFLAG_CUSTOM4, "Switches target to thirdperson camera");
	PluginManager_RegAdminCmd("sm_addoutput", Command_AddOutput, ADMFLAG_ROOT, "Adds an output to an entity. Like ent_fire <someentity> addoutput 'wait 1'");
	PluginManager_RegAdminCmd("sm_remove", Command_Remove, ADMFLAG_CUSTOM4, "Fades out and kills the aimed entity (ignores clients)");
	PluginManager_RegAdminCmd("sm_input", Command_Input, ADMFLAG_CUSTOM4, "Sends an input to an entity.");
	PluginManager_RegAdminCmd("sm_disarm", Command_Disarm, ADMFLAG_CUSTOM4, "Removes targets weapon");
	PluginManager_RegAdminCmd("sm_give", Command_Give, ADMFLAG_CUSTOM4, "Gives a item/weapon to a target");
	PluginManager_RegAdminCmd("sm_respawn", Command_Respawn, ADMFLAG_CUSTOM4, "Respawns target");
	PluginManager_RegAdminCmd("sm_team", Command_Team, ADMFLAG_CUSTOM4, "Moves the target into the given team");
	PluginManager_RegAdminCmd("sm_god", Command_God, ADMFLAG_CUSTOM4, "Set god mode for the given target");
	PluginManager_RegAdminCmd("sm_speed", Command_Speed, ADMFLAG_CUSTOM4, "Set speed for the given target");
	PluginManager_RegAdminCmd("sm_setspeed", Command_Speed, ADMFLAG_CUSTOM4, "Set speed for the given target");
	PluginManager_RegAdminCmd("sm_ice", Command_Freeze, ADMFLAG_CUSTOM4, "Freezes the given target");
	PluginManager_RegAdminCmd("sm_bury", Command_Bury, ADMFLAG_CUSTOM4, "Buries the given target");
	PluginManager_RegAdminCmd("sm_money", Command_Money, ADMFLAG_CUSTOM4, "Set money for the given target");
	PluginManager_RegAdminCmd("sm_cash", Command_Money, ADMFLAG_CUSTOM4, "Set money for the given target");
	PluginManager_RegAdminCmd("sm_ksay", Command_KSay, ADMFLAG_CUSTOM4, "Sends a message to the key hint box");
	
	// Teams
	//PluginManager_RegAdminCmd("sm_teamscore", Command_SetTeamScore, ADMFLAG_CUSTOM4, "Sets the score of the target team");
	//PluginManager_RegAdminCmd("sm_setteamscore", Command_SetTeamScore, ADMFLAG_CUSTOM4, "Sets the score of the target team");
	PluginManager_RegAdminCmd("sm_balanceteam", Command_BalanceTeam, ADMFLAG_CUSTOM4, "Balances the teams");
	PluginManager_RegAdminCmd("sm_balanceteams", Command_BalanceTeam, ADMFLAG_CUSTOM4, "Balances the teams");
	//PluginManager_RegAdminCmd("sm_mixteam", Command_ScrambleTeam, ADMFLAG_CUSTOM4, "Scrambles the teams");
	//PluginManager_RegAdminCmd("sm_scrambleteam", Command_ScrambleTeam, ADMFLAG_CUSTOM4, "Scrambles the teams");
	//PluginManager_RegAdminCmd("sm_swapteam", Command_SwapTeam, ADMFLAG_CUSTOM4, "Swaps the teams");

	// Server
	PluginManager_RegAdminCmd("sm_reloadmap", Command_ReloadMap, ADMFLAG_CUSTOM4, "Reloads the current map");
	PluginManager_RegAdminCmd("sm_extend", Command_ExtendMap, ADMFLAG_CUSTOM4, "Extends the current map");
	//PluginManager_RegAdminCmd("sm_restartround", Command_RestartRound, ADMFLAG_CUSTOM4, "Restarts the round");
	
	// Deprecated Commands
	PluginManager_RegAdminCmd("sm_entity", Command_Deprecated, ADMFLAG_CUSTOM4, "Deprecated please use sm_input");
}

RegisterDeveloperTools(){
	
	// Invisible actions which non admins can't see/notice
	PluginManager_RegAdminCmd("sm_debug", 			Command_Debug, ADMFLAG_CUSTOM4, "Shows information about the entity you're looking at");
	
	// Visible actions which everyone can see/notice
	PluginManager_RegAdminCmd("sm_point", 			Command_Point, ADMFLAG_CUSTOM4, "Creates an pointing line in the direction you're looking at");
	
}


ClearEvents(){

	// Clear from Bottom to Top
	new sizeKeys = GetArraySize(g_hEvent_KeyList);
	for(new i=0; i<sizeKeys; i++){

		new String:eventName[MAX_NAME_LENGTH];
		GetArrayString(g_hEvent_KeyList, i, eventName, sizeof(eventName));
		
		UnhookEvent(eventName, Event_CommandEvent, EVENT_COMMAND_HOOK_MODE);
		
		new Handle:commandList = INVALID_HANDLE;
		if(GetTrieValue(g_hEvent_ToArray, eventName, commandList)){

			new sizeCommands = GetArraySize(commandList);
			for(new j=0; j<sizeCommands; j++){

				// Close the DataPacks
				CloseHandle(GetArrayCell(commandList, j));
			}

			// Close the Array that contains the link to the datapacks
			CloseHandle(commandList);
		}
	}

	ClearArray(g_hEvent_KeyList);
	ClearTrie(g_hEvent_ToArray);
}

ParseEventKVCheck(const String:path[PLATFORM_MAX_PATH]){

	if (FileExists(path, true)) {
		ParseEventKV(path);
	}
	else {
		LogError("Can't find event resource file: %s", path);
	}
}

ParseEventKV(const String:sPath[PLATFORM_MAX_PATH]) {

	decl String:sBuffer[32], String:sKey[MAX_NAME_LENGTH], DATATYPE:type;
	new Handle:kv = CreateKeyValues("whatever");
	FileToKeyValues(kv, sPath);
	KvRewind(kv);
	KvGotoFirstSubKey(kv);
	
	do {
		
		if (KvGotoFirstSubKey(kv, false)) {

			do {
				
				KvGetSectionName(kv, sKey, sizeof(sKey));
				KvGetString(kv, NULL_STRING, sBuffer, sizeof(sBuffer));
				
				type = StringTypeToEnumType(sBuffer);
				if(type == DATATYPE_UNKNOWEN){
					LogError("Unknowen data type: %s for key: %s", sBuffer, sKey);
					continue;
				}
				
				SetTrieValue(g_hGame_EventKeyList, sKey, type);
				
			} while (KvGotoNextKey(kv, false));
			
			KvGoBack(kv);
		}

	} while (KvGotoNextKey(kv));
	
	CloseHandle(kv);
}

DATATYPE:StringTypeToEnumType(const String:type[]){
	
	if(StrEqual(type,"bool") || StrEqual(type,"int") || StrEqual(type,"short") || StrEqual(type,"long") || StrEqual(type,"byte")){
		return DATATYPE_INT;
	}
	else if(StrEqual(type,"float") || StrEqual(type,"double")){
		return DATATYPE_FLOAT;
	}
	else if(StrEqual(type,"string")){
		return DATATYPE_STRING;
	}
	return DATATYPE_UNKNOWEN;
}

DATATYPE:GetEventKeyDataType(const String:key[]){
	
	new DATATYPE:value = DATATYPE_UNKNOWEN;
	GetTrieValue(g_hGame_EventKeyList, key, value);
	return value;
}

AdminToolsShowActivity(client, const String:tag[], const String:format[], any:...){
	
	decl String:buffer[256];
	VFormat(buffer, sizeof(buffer), format, 4);
	
	LOOP_CLIENTS(player, CLIENTFILTER_INGAMEAUTH){
		PrintToConsole(player, "%s%N: %s", tag, client, buffer);
	}
}

bool:BuryClient(client, bool:toggle)
{
	if(toggle == g_bClient_IsBuried[client]){
		return false;
	}
	
	g_bClient_IsBuried[client] = toggle;
	
	if(toggle){
		TeleportEntityRelative(client, Float:{0.0, 0.0, -30.0}, NULL_VECTOR, NULL_VECTOR);
	}
	else {
		TeleportEntityRelative(client, Float:{0.0, 0.0, 40.0}, NULL_VECTOR, NULL_VECTOR);
	}
	return true;
}

TeleportEntityRelative(entity, const Float:origin[3], const Float:angles[3], const Float:velocity[3]){
	
	decl Float:newPosition[3], Float:newAngles[3];
	Entity_GetAbsOrigin(entity, newPosition);
	Entity_GetAbsAngles(entity, newAngles);
	
	if (GetVectorLength(origin, true) > 0.0) {
		AddVectors(newPosition, origin, newPosition);
		TeleportEntity(entity, newPosition, NULL_VECTOR, velocity);
	}
	else if (GetVectorLength(angles, true) > 0.0){
		AddVectors(newAngles, angles, newAngles);
		TeleportEntity(entity, NULL_VECTOR, newAngles, velocity);
	}
	else {
		AddVectors(newPosition, origin, newPosition);
		AddVectors(newAngles, angles, newAngles);
		TeleportEntity(entity, newPosition, newAngles, velocity);
	}
}

/***************************************************************************************

	S T O C K

***************************************************************************************/
// TODO: Improve and stuff it into smlib again:
stock SetThirdPersonMode(client, enable=true)
{
	if (enable) {
		Client_SetObserverTarget(client, 0);
		Client_SetObserverMode(client, Obs_Mode:3, false);
		Client_SetDrawViewModel(client, false);
		Client_SetFOV(client, 120);
	}
	else {
		Client_SetObserverTarget(client, -1);
		Client_SetObserverMode(client, OBS_MODE_NONE, false);
		Client_SetDrawViewModel(client, true);
		Client_SetFOV(client, 90);
	}
}


//TODO: Move to SMLib if its fully working
/**
 * Checks if the property is valid for the given entity.
 *
 * @param entity			Entity Index.
 * @param property		Property name.
 * @param type			Optional parameter to store the type.
 * @param num_bits		Optional parameter to store the number of bits the field uses.  The bit count will either be 1 (for boolean) or divisible by 8 (including 0 if unknown).
 * @return				True if valid data map, otherwise false.
 */
stock bool:IsValidDataMap(entity, const String:property[], &PropFieldType:type=PropFieldType:0, &num_bits=0)
{
	return FindDataMapOffs(entity, property, type, num_bits) != -1;
}

//TODO: Move to SMLib if its fully working
stock bool:Client_GetCrossHairAimPos(client, Float:pos[3])
{
	new Float:vAngles[3], Float:vOrigin[3];
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceFilter_FilterPlayer,client);
	
	if(TR_DidHit(trace)){
		
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return true;
	}
	CloseHandle(trace);
	return false;
}

// Maybe its a bug but commands sent that contain a simicolon (;) will result in, that only the last command will be executed...
// So this is a quick and 'dirty' fix
stock ServerCommandChainable(const String:format[], any:...){

	decl String:vFormat[192];
	VFormat(vFormat, sizeof(vFormat), format, 2);

	decl String:buffers[10][192];
	new size = ExplodeString(vFormat, ";", buffers, sizeof(buffers), sizeof(buffers[]), true);

	for (new i=0; i<size; i++) {
		String_Trim(buffers[i], buffers[i], sizeof(buffers[]), " \t\r\n");
		ServerCommand(buffers[i]);
	}
}

// Maybe its a bug but commands sent that contain a simicolon (;) will result in, that only the last command will be executed...
// So this is a quick and 'dirty' fix
stock FakeClientCommandChainable(client, const String:format[], any:...){

	decl String:vFormat[192];
	VFormat(vFormat, sizeof(vFormat), format, 3);

	decl String:buffers[10][192];
	new size = ExplodeString(vFormat, ";", buffers, sizeof(buffers), sizeof(buffers[]), true);

	for (new i=0; i<size; i++) {
		String_Trim(buffers[i], buffers[i], sizeof(buffers[]), " \t\r\n");
		FakeClientCommandEx(client, buffers[i]);
	}
}

GetSpawnPointCount(team){

	if (g_evEngine_Version != Engine_CSS || !g_bExtensionCstrikeLoaded) {
		return 0;
	}

	return CS_GetSpawnPointCount(team);
}

stock CS_GetSpawnPointCount(team)
{
	new count = 0;
	new entity = -1;

	switch (team) {
		
		case TEAM_ONE:{
			
			while ((entity = FindEntityByClassname(entity, "info_player_terrorist")) != INVALID_ENT_REFERENCE) {
				
				//PrintToServer("info_player_terrorist m_iTeamNum: %d", GetEntProp(entity, Prop_Data, "m_iTeamNum"));
				count++;
			}
		}
		case TEAM_TWO:{
			
			while ((entity = FindEntityByClassname(entity, "info_player_counterterrorist")) != INVALID_ENT_REFERENCE) {

				//PrintToServer("info_player_counterterrorist m_iTeamNum: %d", GetEntProp(entity, Prop_Data, "m_iTeamNum"));
				count++;
			}
		}
	}
	
	return count;
}

stock RespawnPlayer(client){

	if (GetEngineVersion() == Engine_CSS && g_bExtensionCstrikeLoaded) {
		// TODO Make it work in all games
		CS_RespawnPlayer(client);
	}
	else {
		ThrowError("This plugin does not support RespawnPlayer on this game");
	}
}

stock bool:SwitchTeam(client, team){
	
	// TODO Make it work in all games
	
	if(!Team_IsValid(team)){
		return false;
	}
		
	// CSS Logic:
	if(team == TEAM_UNASSIGNED){
		return false;
	}
	
	new currentTeam = GetClientTeam(client);
	
	// Join the game from unassigned or spec and don't care about what the target team is.
	if (currentTeam == TEAM_UNASSIGNED || currentTeam == TEAM_SPECTATOR) {
		
		ChangeClientTeam(client, team);

		if (g_evEngine_Version == Engine_CSS) {
			// Hide the model selection menu
			switch (team) {
				
				case CS_TEAM_T:{
					ShowVGUIPanel(client, "class_ter", INVALID_HANDLE, false);
				}
				case CS_TEAM_CT:{
					ShowVGUIPanel(client, "class_ct", INVALID_HANDLE, false);
				}
			}

			// Choose model class
			ClientCommand(client, "joinclass %d", Math_GetRandomInt(0,3));
		}
	}
	else {
		if (g_evEngine_Version != Engine_CSS
				|| !g_bExtensionCstrikeLoaded
				|| team == TEAM_SPECTATOR) {
			// Target is spec we need to change the team instead of just switching it
			ChangeClientTeam(client, team);
		}
		else {
			
			// We just switch the teams
			CS_SwitchTeam(client, team);
			
			// If he was alive respawn him, else we don't care
			if(IsPlayerAlive(client)){
				RespawnPlayer(client);
			}
		}
	}
	return true;
}

stock Client_InitializeAll()
{
	LOOP_CLIENTS (client, CLIENTFILTER_ALL) {
		
		Client_Initialize(client);
	}
}

stock Client_Initialize(client)
{
	// Variables
	Client_InitializeVariables(client);
	
	
	// Functions
	
	
	/* Functions where the player needs to be in game 
	if(!IsClientInGame(client)){
		return;
	}
	*/
}

stock Client_InitializeVariables(client)
{
	// Client Variables
	g_bClient_PointActivated[client] = false;
	g_bClient_IsBuried[client] = false;
}


