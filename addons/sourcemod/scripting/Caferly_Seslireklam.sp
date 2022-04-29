#pragma semicolon 1
#pragma newdecls required
#include <sourcemod> 
#include <sdktools_sound>
#include <sdktools_stringtables>

Database
	hDatabase; 

ArrayList
	hArray;

Menu
	hMenu[2];
	
Handle
	hAdvertTimer;
	
ConVar
	cvEnable,
	cvAdvertTime,
	cvMySQL;

bool
	bEnableSound[MAXPLAYERS+1]; 
	
float
	fVol[MAXPLAYERS+1];

char
	sSqlInfo[3][MAXPLAYERS+1][128];
	
public Plugin myinfo =
{
	name = "Sesli Reklamlar MAPPAZARI",
	author = "Caferly",
	description = "Sesli reklam",
	version = "1.1",
	url = "http://www.mappazari.xyz/ https://yougamearea.com"
};

public void OnPluginStart()
{
	ReloadClients();
	hArray = new ArrayList(ByteCountToCells(256));
	
	cvEnable = CreateConVar("sm_seslireklam", "1", "0 Yaparsanız pasif olur 1 yaparsanız aktif");
	cvAdvertTime = CreateConVar("sm_seslireklam_sure", "200", "Sesli reklamların kaç saniyede bir geleceğini belirler.");
	cvMySQL = CreateConVar("sm_seslireklam_mysql", "1", "1 yaparsan mysql açıyo işte 0 yaparsan kapıyo");

	AutoExecConfig(true, "seslireklam");
	
	//Database.Connect(ConnectCallBack, "seslireklam_sqlite");
	RequestFrame(DatabaseConnect);
	
	LoadAdvSounds();
	CreatMenuEnable();
	CreatMenuVal();
	
	RegConsoleCmd("sm_sk", CmdVoiceMenu);
}

public void DatabaseConnect(any data)
{
	if(cvMySQL.BoolValue)
	{
		Database.Connect(ConnectCallBack, "seslireklam");		
	}
	else
	{
		Database.Connect(ConnectCallBackSqlite, "seslireklam");		
	}
}

void ReloadClients()
{
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i))
	{
		fVol[i] = 1.0;
		bEnableSound[i] = true;
	}
}

public Action CmdVoiceMenu(int client, any argc)
{
	if(!client || IsFakeClient(client))
		return Plugin_Continue;
		
	hMenu[0].Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled; 
}

void CreatMenuEnable()
{
	hMenu[0] = new Menu(VoiceMenu);
	hMenu[0].SetTitle("▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬\n   ★ Sesli Reklam - Ayarlar ★\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬");
	
	hMenu[0].AddItem("item1", "Aç/Kapat [√]");
	hMenu[0].AddItem("item2", "Sesi Değiştir [♫]");
}

void CreatMenuVal()
{
	hMenu[1] = new Menu(ValMenu);
	hMenu[1].SetTitle("▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬\n   ★ Sesli Reklam - Ses Ayarları ★\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬");
	
	hMenu[1].AddItem("item1", "Ses Seviyesi 100 [♫]");
	hMenu[1].AddItem("item2", "Ses Seviyesi 80 [♫]");
	hMenu[1].AddItem("item3", "Ses Seviyesi 60 [♫]");
	hMenu[1].AddItem("item4", "Ses Seviyesi 40 [♫]");
	hMenu[1].AddItem("item5", "Ses Seviyesi 20 [♫]");
	hMenu[1].AddItem("item6", "Ses Seviyesi 0 [♫]");
}

public int VoiceMenu(Menu hMenuLocal, MenuAction action, int client, int iItem)
{
	if(action == MenuAction_Select)
	{
		switch(iItem)
		{
			case 0:
			{
				char sQuery[512], sSteam[32];
				GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam), true);
				if(bEnableSound[client] == true)
				{
					bEnableSound[client] = false;
					PrintToChat(client, "Sesli reklamların oynatılması devre dışı bırakıldı!");
					FormatEx(sQuery, sizeof(sQuery), "UPDATE `seslireklam` SET `enable_sound` = '%s' WHERE `steam_id` = '%s';", "0", sSteam);
				}
				else
				{
					bEnableSound[client] = true;
					PrintToChat(client, "Sesli reklam etkin !");
					FormatEx(sQuery, sizeof(sQuery), "UPDATE `seslireklam` SET `enable_sound` = '%s' WHERE `steam_id` = '%s';", "1", sSteam);
				}
				hDatabase.Query(SQL_Callback_CheckErrorMenu, sQuery);
			}
			case 1:
			{
				hMenu[1].Display(client, 25);
			}
		}
	}
}

public void SQL_Callback_CheckErrorMenu(Database hDatabaseLocal, DBResultSet results, const char[] szError, any data)
{
	if(szError[0])
	{
		LogError("SQL_Callback_CheckError: %s", szError);
	}
}

public int ValMenu(Menu hMenuLocal, MenuAction action, int client, int iItem)
{
	if(action == MenuAction_Select)
	{
		char sQuery[512], sSteam[32];
		GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam), true);
		
		switch(iItem)
		{
			case 0:
			{
				fVol[client] = 1.0;
				PrintToChat(client, "Belirlenen :  Ses Seviyesi в [100%]");
				FloatToString(fVol[client], sSqlInfo[1][client], sizeof(sSqlInfo[]));
				FormatEx(sQuery, sizeof(sQuery), "UPDATE `seslireklam` SET `volume` = '%s' WHERE `steam_id` = '%s';", sSqlInfo[1][client], sSteam);
				hDatabase.Query(SQL_Callback_CheckError, sQuery);
			}
			case 1:
			{
				fVol[client] = 0.8;
				PrintToChat(client, "Belirlenen :  Ses Seviyesi в [80%]");
				FloatToString(fVol[client], sSqlInfo[1][client], sizeof(sSqlInfo[]));
				FormatEx(sQuery, sizeof(sQuery), "UPDATE `seslireklam` SET `volume` = '%s' WHERE `steam_id` = '%s';", sSqlInfo[1][client], sSteam);
				hDatabase.Query(SQL_Callback_CheckError, sQuery);
			}
			case 2:
			{
				fVol[client] = 0.6;
				PrintToChat(client, "Belirlenen :  Ses Seviyesi в [60%]");
				FloatToString(fVol[client], sSqlInfo[1][client], sizeof(sSqlInfo[]));
				FormatEx(sQuery, sizeof(sQuery), "UPDATE `seslireklam` SET `volume` = '%s' WHERE `steam_id` = '%s';", sSqlInfo[1][client], sSteam);
				hDatabase.Query(SQL_Callback_CheckError, sQuery);
			}
			case 3:
			{
				fVol[client] = 0.4;
				PrintToChat(client, "Belirlenen :  Ses Seviyesi в [40%]");
				FloatToString(fVol[client], sSqlInfo[1][client], sizeof(sSqlInfo[]));
				FormatEx(sQuery, sizeof(sQuery), "UPDATE `seslireklam` SET `volume` = '%s' WHERE `steam_id` = '%s';", sSqlInfo[1][client], sSteam);
				hDatabase.Query(SQL_Callback_CheckError, sQuery);
			}
			case 4:
			{
				fVol[client] = 0.2;
				PrintToChat(client, "Belirlenen :  Ses Seviyesi в [20%]");
				FloatToString(fVol[client], sSqlInfo[1][client], sizeof(sSqlInfo[]));
				FormatEx(sQuery, sizeof(sQuery), "UPDATE `seslireklam` SET `volume` = '%s' WHERE `steam_id` = '%s';", sSqlInfo[1][client], sSteam);
				hDatabase.Query(SQL_Callback_CheckError, sQuery);
			}
			case 5:
			{
				fVol[client] = 0.0;
				PrintToChat(client, "Звук был отключен [0%] !");
				FloatToString(fVol[client], sSqlInfo[1][client], sizeof(sSqlInfo[]));
				FormatEx(sQuery, sizeof(sQuery), "UPDATE `seslireklam` SET `volume` = '%s' WHERE `steam_id` = '%s';", sSqlInfo[1][client], sSteam);
				hDatabase.Query(SQL_Callback_CheckError, sQuery);
			}
		}
	}
}

public void SQL_Callback_CheckError(Database hDatabaseLocal, DBResultSet results, const char[] szError, any data)
{
	if(szError[0])
	{
		LogError("SQL_Callback_CheckError: %s", szError);
	}
}

public void ConnectCallBack(Database hDB, const char[] szError, any data)
{
	if (hDB == null || szError[0])
	{
		SetFailState("Veritabanı Bağlantısı: %s", szError);
		return;
	}
	
	char sQuery[512];
	hDatabase = hDB;
	SQL_LockDatabase(hDatabase);

	FormatEx(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `seslireklam` (\
		`id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT ,\
		`steam_id` VARCHAR(32) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,\
		`enable_sound` VARCHAR(32) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,\
		`volume` VARCHAR(32) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,\
		UNIQUE `id` (`id`)) ENGINE = MyISAM CHARSET=utf8 COLLATE utf8_general_ci;");
	
	hDatabase.Query(SQL_Callback_Select, sQuery);

	SQL_UnlockDatabase(hDatabase);
	hDatabase.SetCharset("utf8");
}

public void ConnectCallBackSqlite(Database hDB, const char[] szError, any data)
{
	if (hDB == null || szError[0])
	{
		SetFailState("Veritabanı Bağlantısı: %s", szError);
		return;
	}
	
	char sQuery[512];
	hDatabase = hDB;
	SQL_LockDatabase(hDatabase);

	FormatEx(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `seslireklam` (\
		`id` INTEGER PRIMARY KEY,\
		`steam_id` VARCHAR(32),\
		`enable_sound` VARCHAR(32),\
		`volume` VARCHAR(32));");
	
	hDatabase.Query(SQL_Callback_Select, sQuery);

	SQL_UnlockDatabase(hDatabase);
	hDatabase.SetCharset("utf8");
}

public void SQL_Callback_Select(Database hDatabaseLocal, DBResultSet results, const char[] sError, any iUserID)
{
	if(sError[0])
	{
		LogError("SQL_Callback_SelectClient: %s", sError);
		return;
	}
}

public void OnClientPostAdminCheck(int client)
{
	if(!IsFakeClient(client))
	{
		char sQuery[512], sSteam[32];
		GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));
		FormatEx(sQuery, sizeof(sQuery), "SELECT `enable_sound`, `volume` FROM `seslireklam` WHERE `steam_id` = '%s';", sSteam);	
		hDatabase.Query(SQL_Callback_SelectClient, sQuery, GetClientUserId(client)); 
	}
}

public void SQL_Callback_SelectClient(Database hDatabaseLocal, DBResultSet hResults, const char[] sError, any iUserID)
{
	if(sError[0])
	{
		LogError("SQL_Callback_SelectClient: %s", sError);
		return;
	}
	
	int client = GetClientOfUserId(iUserID);
	if(client)
	{
		char sQuery[512], sSteam[32];
		GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));

		if(hResults.FetchRow())
		{
			
			hResults.FetchString(0, sSqlInfo[0][client], sizeof(sSqlInfo[]));
			bEnableSound[client] = view_as<bool>(StringToInt(sSqlInfo[0][client]));		
			
			
			hResults.FetchString(1, sSqlInfo[1][client], sizeof(sSqlInfo[]));
			fVol[client] = StringToFloat(sSqlInfo[1][client]);
			
			sSqlInfo[2][client] = sSteam;
		}
		else
		{
			sSqlInfo[0][client] = "1";
			bEnableSound[client] = true;
			sSqlInfo[1][client] = "100.0";
			fVol[client] = 1.0;
			FormatEx(sQuery, sizeof(sQuery), "INSERT INTO `seslireklam` (`steam_id`, `enable_sound`, `volume`) VALUES ('%s', '%s', '%s');", sSteam, sSqlInfo[0][client], sSqlInfo[1][client]);
			hDatabase.Query(SQL_Callback_CreateClient, sQuery, GetClientUserId(client));
		}
	}
}

public void SQL_Callback_CreateClient(Database hDatabaseLocal, DBResultSet results, const char[] szError, any iUserID)
{
	if(szError[0])
	{
		LogError("SQL_Callback_CreateClient: %s", szError);
		return;
	}
}

void LoadAdvSounds()
{
	hArray.Clear();
	char sConfigFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sConfigFile, sizeof(sConfigFile), "configs/sesli_reklam.cfg");
	
	if(!FileExists(sConfigFile))
		LogMessage("sesli_reklam.ini Dosyası Bulunamadı !");
	else
	{
		Handle hFile = OpenFile(sConfigFile, "r");
		char sBuffer[2][256];
		while(!IsEndOfFile(hFile))	
		{
			ReadFileLine(hFile, sBuffer[0], sizeof(sBuffer[]));	
			TrimString(sBuffer[0]);	
			
			if(sBuffer[0][0] == '/' || sBuffer[0][0] == '\0')
				continue;

			hArray.PushString(sBuffer[0]);
			
			Format(sBuffer[1], sizeof(sBuffer[]), "sound/%s", sBuffer[0]);
			AddFileToDownloadsTable(sBuffer[1]);
			if(sBuffer[0][0]) PrecacheSound(sBuffer[0], true);
 		}
		CloseHandle(hFile);
	}
}

public void OnMapStart()
{
	if(!cvEnable.BoolValue)
		return;
	LoadAdvSounds();
	hAdvertTimer = CreateTimer(cvAdvertTime.FloatValue, PlayVoiceAdv);
}

public Action PlayVoiceAdv(Handle timer)
{
	if(!cvEnable.BoolValue)
		return;
		
	hAdvertTimer = CreateTimer(cvAdvertTime.FloatValue, PlayVoiceAdv);

	int iRnd = GetRandomInt(0, GetArraySize(hArray) - 1);
	char sSoundList[256];

	GetArrayString(hArray, iRnd, sSoundList, sizeof(sSoundList));

	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i))
	{
		bEnableSound[i] = view_as<bool>(StringToInt(sSqlInfo[0][i]));
		fVol[i] = StringToFloat(sSqlInfo[1][i]);
		if(bEnableSound[i] == true)
			EmitSoundToClient(i, sSoundList, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, fVol[i]);
	}
}

public void OnMapEnd()
{
	delete hAdvertTimer;
}