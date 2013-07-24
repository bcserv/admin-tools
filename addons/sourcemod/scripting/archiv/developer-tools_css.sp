/*****************************************************************


C O M P I L E   O P T I O N S


*****************************************************************/
// enforce semicolons after each code statement
#pragma semicolon 1

/*****************************************************************


P L U G I N   I N C L U D E S


*****************************************************************/
#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <smlib/pluginmanager>


/*****************************************************************


P L U G I N   I N F O


*****************************************************************/
#define PLUGIN_NAME				"Developer Tools"
#define PLUGIN_TAG				"sm"
#define PLUGIN_PRINT_PREFIX		"[SM] "
#define PLUGIN_AUTHOR			"Chanz"
#define PLUGIN_DESCRIPTION		"developer tools, to debug varius things."
#define PLUGIN_VERSION 			"1.0.0"
#define PLUGIN_URL				"http://www.mannisfunhouse.eu/"

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

/*****************************************************************


		P L U G I N   D E F I N E S


*****************************************************************/
#define THINK_INTERVAL 0.2
#define PRINT_SEPERATOR "---------------------------------------------------------------------------------------------------------------"

/*****************************************************************


		G L O B A L   V A R S


*****************************************************************/
//Use a good notation, constants for arrays, initialize everything that has nothing to do with clients!
//If you use something which requires client index init it within the function Client_InitVars (look below)
//Example: Bad: "decl servertime" Good: "new g_iServerTime = 0"
//Example client settings: Bad: "decl saveclientname[33][32] Good: "new g_szClientName[MAXPLAYERS+1][MAX_NAME_LENGTH];" -> later in Client_InitVars: GetClientName(client,g_szClientName,sizeof(g_szClientName));

new bool:g_bClient_PointActivated[MAXPLAYERS+1];
new Float:g_flClient_PointSize[MAXPLAYERS+1];

//Models
new g_iSprite_Beam = -1;
//new g_iSprite_Halo = -1;
//new g_iSprite_Glow = -1;

/*****************************************************************


		F O R W A R D   P U B L I C S


*****************************************************************/
public OnPluginStart() {
	
	//Init for smlib
	PluginManager_Initialize("developer-tools", "[SM] ");
	
	//Command Hooks (AddCommandListener) (If the command already exists, like the command kill, then hook it!)
	
	
	//Register New Commands (RegConsoleCmd) (If the command doesn't exist, hook it here)
	
	
	//Register Admin Commands (RegAdminCmd)
	RegAdminCmd("sm_debug", 			Command_Debug, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_point", 			Command_Point, ADMFLAG_CUSTOM4);
	
	//Cvars: Create a global handle variable.
	//Example: g_cvarEnable = CreateConVarEx("enable","1","example ConVar");
	
	
	//Set your ConVar runtime optimizers here
	//Example: g_iPlugin_Enable = GetConVarInt(g_cvarEnable);
	
	//Hook ConVar Change
	
	
	//Event Hooks
	
	
	//Mind: this is only here for late load, since on map change or server start, there isn't any client.
	//Remove it if you don't need it.
	ClientAll_Initialize();
	
	CreateTimer(THINK_INTERVAL,Timer_Think,INVALID_HANDLE,TIMER_REPEAT);
}

public OnMapStart() {
	
	new sdkVersion = GuessSDKVersion();
	
	// hax against valvefail (thx psychonic for fix)
	if(sdkVersion == SOURCE_SDK_EPISODE2VALVE){
		SetConVarString(Plugin_VersionCvar, Plugin_Version);
	}
	
	if(sdkVersion == SOURCE_SDK_LEFT4DEAD2){
		
		g_iSprite_Beam = PrecacheModel("materials/sprites/laserbeam.vmt");
		//g_iSprite_Halo = PrecacheModel("materials/sprites/glow01.vmt");
	}
	else {
		
		g_iSprite_Beam = PrecacheModel("materials/sprites/laser.vmt");
		//g_iSprite_Halo = PrecacheModel("materials/sprites/halo01.vmt");
	}
	
	//g_iSprite_Glow = PrecacheModel("sprites/redglow1.vmt");
}

public OnConfigsExecuted(){
	
	ClientAll_Initialize();
}

public OnClientConnected(client){
	
	Client_Initialize(client);
}

public OnClientPostAdminCheck(client){
	
	Client_Initialize(client);
}

/****************************************************************


		C A L L B A C K   F U N C T I O N S


****************************************************************/

public Action:Command_Debug(client, args) {

	new entity = GetClientAimTarget(client, false);
	
	if (entity != -1) {
		
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
		
		//Movement
		//new MoveType:moveType = GetEntityMoveType(entity);
		
		PrintToChat(client,"%sSee console for full output",PLUGIN_PRINT_PREFIX);
		
		PrintToConsole(client,"%s",PRINT_SEPERATOR);
		
		PrintToConsole(client,"%sEntityIndex: %d Entity Reference: %d ",PLUGIN_PRINT_PREFIX,entity,entityReference);
		PrintToConsole(client,"%sNetClass::ClassName -> %s::%s",PLUGIN_PRINT_PREFIX,netClass,classname);
		
		PrintToConsole(client,"%s",PRINT_SEPERATOR);
		
		PrintToConsole(client,"%sModelIndex: %d ModelPath: \"%s\"",PLUGIN_PRINT_PREFIX,modelIndex,modelPath);
		PrintToConsole(client,"%sName: \"%s\" GlobalName: \"%s\" HammerId: %d",PLUGIN_PRINT_PREFIX,name,globalName,hammerId);
		//PrintToConsole(client,"%sSolidType: %d SolidFlag: %d MoveType: %d",PLUGIN_PRINT_PREFIX,solidType,solidFlags,moveType);
		
		PrintToConsole(client,"%s",PRINT_SEPERATOR);
		
		decl Float:origin[3];
		Entity_GetAbsOrigin(entity,origin);
		PrintToConsole(client,"%sabsOrigin: setpos %18f %18f %18f",PLUGIN_PRINT_PREFIX, origin[0], origin[1], origin[2]);
		decl Float:angles[3];
		Entity_GetAbsAngles(entity,angles);
		PrintToConsole(client,"%sabsAngles: setang %18f %18f %18f",PLUGIN_PRINT_PREFIX, angles[0], angles[1], angles[2]);
		
		PrintToConsole(client,"%s",PRINT_SEPERATOR);
		
		decl Float:mins[3], Float:maxs[3];
		Entity_GetMinSize(entity,mins);
		Entity_GetMaxSize(entity,maxs);
		PrintToConsole(client,"%sm_vecMins: %18f %18f %18f",PLUGIN_PRINT_PREFIX, mins[0], mins[1], mins[2]);
		PrintToConsole(client,"%sm_vecMaxs: %18f %18f %18f",PLUGIN_PRINT_PREFIX, maxs[0], maxs[1], maxs[2]);
		
		//target
		new String:target_Name[MAX_NAME_LENGTH];
		Entity_GetTargetName(entity,target_Name,sizeof(target_Name));
		if(target_Name[0] != '\0'){
			new target = Entity_FindByName(target_Name);
			if(Entity_IsValid(target)){
				
				new String:target_ClassName[MAX_NAME_LENGTH];
				Entity_GetClassName(target,target_ClassName,sizeof(target_ClassName));
				
				PrintToConsole(client,"%s",PRINT_SEPERATOR);
				PrintToConsole(client,"%s  This entity has a target:",PLUGIN_PRINT_PREFIX);
				PrintToConsole(client,"%s  TargetIndex: %d TargetReference: %d",PLUGIN_PRINT_PREFIX,target,EntIndexToEntRef(target));
				PrintToConsole(client,"%s  TargetName: %s TargetClassName: %s",PLUGIN_PRINT_PREFIX,target_Name,target_ClassName);
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
			PrintToConsole(client,"%s  This entity has a parent:",PLUGIN_PRINT_PREFIX);
			PrintToConsole(client,"%s  ParentIndex: %d ParentReference: %d",PLUGIN_PRINT_PREFIX,parent,EntIndexToEntRef(parent));
			PrintToConsole(client,"%s  ParentName: %s ParentClassName: %s",PLUGIN_PRINT_PREFIX,parent_Name,parent_ClassName);
		}
		
		//children (comming soon?)
		
		PrintToConsole(client,"%s",PRINT_SEPERATOR);
	}
	else {
		ReplyToCommand(client, "%sNo Entity found",PLUGIN_PRINT_PREFIX);
	}
	
	return Plugin_Handled;
}

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

public Action:Timer_Think(Handle:timer){
	
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
			
			TE_SetupBeamPoints(eyePos, aimPos, g_iSprite_Beam, 0, 0, 0, THINK_INTERVAL, g_flClient_PointSize[client]/2, g_flClient_PointSize[client], 1, 0.0, {255,0,0,255}, 0);
			TE_SendToAll();
		}
	}
}

/*****************************************************************


		P L U G I N   F U N C T I O N S


*****************************************************************/
stock bool:IsValidDataMap(entity, const String:prop[]){
	
	PrintToChatAll("FindDataMapOffs(%d,%s): %d",entity,prop,FindDataMapOffs(entity,prop));
	
	return FindDataMapOffs(entity,prop) != -1;
}

stock bool:Client_GetCrossHairAimPos(client, Float:pos[3])
{
	new Float:vAngles[3], Float:vOrigin[3];
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayers,client);
	
	if(TR_DidHit(trace)){
		
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return true;
	}
	CloseHandle(trace);
	return false;
}

public bool:TraceEntityFilterPlayers(entity, contentsMask, any:data){
	
    return entity != data;
}

stock ClientAll_Initialize(){
	
	for(new client=1;client<=MaxClients;client++){
		
		if(!IsClientInGame(client)){
			continue;
		}
		
		Client_Initialize(client);
	}
}

stock Client_Initialize(client){
	
	//Variables
	Client_InitializeVariables(client);
	
	//Functions
}

stock Client_InitializeVariables(client){
	
	//Plugin Client Vars
	g_bClient_PointActivated[client] = false;
	g_flClient_PointSize[client] = 0.1;
}

