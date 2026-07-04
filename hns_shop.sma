#include <amxmodx>
#include <fakemeta>

#pragma semicolon 1

/* Hide'n'Seek Shop 
 *    by xPaw & Grim
 * 
 *  Credits:
 *    Grim - for original code/Godmode Key actviation - added pcvars
 *    Ven  - His tutorial for Player Spawn
 */

#define VERSION "2.0"

#define fm_get_user_money(%1)	get_pdata_int( %1, 115 )
#define fm_create_entity(%1)	engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, %1))

#define MAX_CLIENTS 32

enum Color {
	NORMAL = 1,	// clients scr_concolor cvar color
	GREEN,		// Green
	TEAM_COLOR,	// Red, grey, blue
	GREY,		// grey
	RED,		// Red
	BLUE,		// Blue
};

new TeamName[][] = {
	"",
	"TERRORIST",
	"CT",
	"SPECTATOR"
};
	

// Pcvars
new plugin_on, silentcost, stealthcost, noflashcost, hpcost, armorcost, grenadecost, gravitycost, speedcost, godmodecost;
new allowsilent, allowstealth, allownoflash, allowhp, allowarmor, allowgrenade, allowgravity, allowspeed, allowgodmode;
new usersilent[33], userstealth[33], usernoflash[33], userhp[33], userarmor[33], usergrenade[33], usergravity[33], userspeed[33];
new hpcvar, armorcvar, menu, hasspeed[33], hassilent[33], gotgodmode[33], hasgodmode[33], mess[33], mess2[33];
new g_msgScreenFade, g_msgMoney, grenade[32], last;

new Float:g_gametime, g_owner;
new Float:g_gametime2;

new bool:g_bPlayerNonSpawnEvent[MAX_CLIENTS + 1];
new bool:g_track_enemy;
new bool:g_track[33];

new g_iFwFmClientCommandPost;
new g_sync_check_data;

public plugin_init() {
	register_plugin("HnS Shop", VERSION, "xPaw & Grim");
	register_cvar("hns_shop_version", VERSION, FCVAR_SERVER);
	set_cvar_string("hns_shop_version", VERSION);

	// Player Spawn
	register_event("ResetHUD", "fwEvResetHUD", "b");
	register_event("TextMsg", "fwEvGameWillRestartIn", "a", "2=#Game_will_restart_in");
	register_clcmd("fullupdate", "fwCmdClFullupdate");

	// Events
	register_event("DeathMsg", "eDeath", "a");
	register_event("CurWeapon", "speed_on", "be");
	register_event("ScreenFade", "eventFlash", "be", "4=255", "5=255", "6=255", "7>199");
	register_event("TextMsg", "fire_in_the_hole", "b", "2&#Game_radio", "4&#Fire_in_the_hole");
	register_event("TextMsg", "fire_in_the_hole2", "b", "3&#Game_radio", "5&#Fire_in_the_hole");
	register_event("99", "grenade_throw", "b");

	// Pcvars
	plugin_on	= register_cvar("hns_shop", "1");
	silentcost	= register_cvar("hns_shop_silentcost",		"4500");
	stealthcost	= register_cvar("hns_shop_stealthcost",		"9500");
	noflashcost	= register_cvar("hns_shop_noflashcost",		"8000");
	grenadecost	= register_cvar("hns_shop_grenadecost",		"1500");
	gravitycost	= register_cvar("hns_shop_gravitycost",		"13000");
	speedcost	= register_cvar("hns_shop_speedcost",		"7000");
	hpcost		= register_cvar("hns_shop_hpcost",		"8000");
	armorcost	= register_cvar("hns_shop_armorcost",		"6000");
	godmodecost	= register_cvar("hns_shop_godmodecost",		"16000");
	hpcvar		= register_cvar("hns_shop_hpcvar",		"150");
	armorcvar	= register_cvar("hns_shop_armorcvar",		"150");
	allowsilent	= register_cvar("hns_shop_allowsilent",		"1");
	allowstealth	= register_cvar("hns_shop_allowstealth",	"1");
	allownoflash	= register_cvar("hns_shop_allownoflash",	"1");
	allowgrenade	= register_cvar("hns_shop_allowgrenade",	"1");
	allowgravity	= register_cvar("hns_shop_allowgravity",	"1");
	allowspeed	= register_cvar("hns_shop_allowspeed",		"1");
	allowhp		= register_cvar("hns_shop_allowhp",		"1");
	allowarmor	= register_cvar("hns_shop_allowarmor",		"1");
	allowgodmode	= register_cvar("hns_shop_allowgodmode",	"1");

	// Clcmds
	register_clcmd("say /hnsshop",	"show_hnsmenu");
	register_clcmd("say /shop",	"show_hnsmenu");
	register_clcmd("say hnsshop",	"show_hnsmenu");
	register_clcmd("say shop",	"show_hnsmenu");

	// Menu
	menu = register_menuid("Hide'n'Seek Shop");
	register_menucmd(menu, 1023, "hnsshop");
	
	// Forwards
	register_forward(FM_EmitSound,"fw_emitsound"); 
	register_forward(FM_CmdStart, "fwd_FM_CmdStart_pre", 0);
	

	// Tasks
	set_task( 2.0, "bad_fix2",_,_,_, "b" );
	set_task( 100.0, "advert",_,_,_, "b" );
	
	g_msgScreenFade = get_user_msgid("ScreenFade");
	g_msgMoney = get_user_msgid("Money");
}

public client_connect( id ) {
	usersilent[id]	= 0;
	userstealth[id]	= 0;
	usernoflash[id]	= 0;
	userhp[id]	= 0;
	userarmor[id]	= 0;
	usergrenade[id]	= 0;
	usergravity[id]	= 0;
	userspeed[id]	= 0;
	gotgodmode[id]	= 0;
	hasgodmode[id]	= 0;
	hasspeed[id]	= 0;
	hassilent[id]	= 0;
	mess[id]	= 0;
	mess2[id]	= 0;
}

public client_disconnect( id ) {
	usersilent[id]	= 0;
	userstealth[id]	= 0;
	usernoflash[id]	= 0;
	userhp[id]	= 0;
	userarmor[id]	= 0;
	usergrenade[id]	= 0;
	usergravity[id]	= 0;
	userspeed[id]	= 0;
	gotgodmode[id]	= 0;
	hasgodmode[id]	= 0;
	hasspeed[id]	= 0;
	hassilent[id]	= 0;
	mess[id]	= 0;
	mess2[id]	= 0;
} 

public speed_on( id )
	if(is_user_alive(id))
		if(hasspeed[id])
			fm_set_user_maxspeed(id, 320.0);

// Advert
public advert() {
	new g_Maxplayers;
	g_Maxplayers = get_maxplayers();
	
	for(new i=1; i<=g_Maxplayers; i++)
		if(is_user_connected(i))
			ColorChat(i, RED, "^x01[AMXX]^x04 This server is using^x03 Hide'n'Seek Shop^x04, Type^x03 /hnsshop^x04 or^x03 /shop");
}

public fwd_FM_CmdStart_pre( id, uc_handle, random_seed ) {
		if(!is_user_alive(id))
			return FMRES_IGNORED;
	
		if(hassilent[id] > 0)
			set_pev(id, pev_flTimeStepSound, 999);

		static button;
		button = get_uc(uc_handle, UC_Buttons);
		if(button & IN_RELOAD) {
			if(get_pcvar_num(allowgodmode) == 1)
				return FMRES_IGNORED;
			
			if(!gotgodmode[id]) {	
				if(!mess[id]) {
					ColorChat(id, RED, "^x04[Hide'n'Seek Shop]^x01 You need to buy godmode first!");
					mess[id]++;
					set_task(3.0, "remove_mess", id);
					return FMRES_IGNORED;
				}
				return FMRES_IGNORED;
			}
			
			if(hasgodmode[id] > 0) {
				if(!mess[id]) {
					ColorChat(id, RED, "^x04[Hide'n'Seek Shop]^x01 Your godmode is already activated!");
					mess[id]++;
					set_task(3.0, "remove_mess", id);
					return FMRES_IGNORED;
				}
				return FMRES_IGNORED;
			}
        
			gotgodmode[id] = 0;
			hasgodmode[id]++;
			fm_set_user_godmode(id, 1);
			if(get_user_team(id) == 1)
				fm_set_user_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderTransAlpha, 255);
			else if(get_user_team(id) == 2)
				fm_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 255, kRenderTransAlpha, 255);
			
			set_task(5.0, "remove_godmode", id);
		
			if(!mess[id]) {
				ColorChat(id, RED, "^x04[Hide'n'Seek Shop]^x01 Your godmode is now active!");
				mess[id]++;
				set_task(3.0, "remove_mess", id);
			} 
			return FMRES_SUPERCEDE;
		} 
		return FMRES_IGNORED;
}


// User Spawn event
public fwEvResetHUD( id ) {
        if (!is_user_alive(id))
                return;
 
        if (g_bPlayerNonSpawnEvent[id]) {
                g_bPlayerNonSpawnEvent[id] = false;
                return;
        }
 
        fwPlayerSpawn(id);
}
 
public fwEvGameWillRestartIn() {
        static iPlayers[32], iPlayersNum, i;
        get_players(iPlayers, iPlayersNum, "a");
        for (i = 0; i < iPlayersNum; ++i)
                g_bPlayerNonSpawnEvent[iPlayers[i]] = true;
}
 
public fwCmdClFullupdate( id ) {
        g_bPlayerNonSpawnEvent[id] = true;
        static const szFwFmClientCommandPost[] = "fwFmClientCommandPost";
        g_iFwFmClientCommandPost = register_forward(FM_ClientCommand, szFwFmClientCommandPost, 1);
        return PLUGIN_CONTINUE;
}
 
public fwFmClientCommandPost( id ) {
        unregister_forward(FM_ClientCommand, g_iFwFmClientCommandPost, 1);
        g_bPlayerNonSpawnEvent[id] = false;
        return FMRES_HANDLED;
}
 
public fwPlayerSpawn( id ) {
	if(!is_user_alive(id))
		return PLUGIN_HANDLED;
	
	if(get_pcvar_num(plugin_on) == 1) {
		set_pev(id, pev_flTimeStepSound, 400);
		fm_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255);
		fm_set_user_health(id, 100);
		fm_set_user_armor(id, 0);
		fm_set_user_gravity(id, 1.0);
		usersilent[id]	= 0;
		userstealth[id]	= 0;
		usernoflash[id]	= 0;
		userhp[id]	= 0;
		userarmor[id]	= 0;
		usergrenade[id]	= 0;
		usergravity[id]	= 0;
		userspeed[id]	= 0;
		hassilent[id]	= 0;
	}
	return PLUGIN_HANDLED;
}  

// User Death event
public eDeath( id ) {
	new victem = read_data(2);
		
	usersilent[victem]	= 0;
	userstealth[victem]	= 0;
	usernoflash[victem]	= 0;
	userhp[victem]		= 0;
	userarmor[victem]	= 0;
	usergrenade[victem]	= 0; 
	usergravity[victem]	= 0;
	userspeed[victem]	= 0;
	hasspeed[victem]	= 0;
	hasgodmode[victem]	= 0;
	hassilent[victem]	= 0;
}

// Showing menu
public show_hnsmenu( id ) {
	if(get_pcvar_num(plugin_on) == 1) {
		new szBuffer[512], iLen;

		iLen = formatex(szBuffer, sizeof szBuffer - 1, "\rHide'n'Seek Shop\w^n^n");
		iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\r1. \wSilent Walk - \y%d$^n", get_pcvar_num(silentcost));
		iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\r2. \wStealth \r(20 seconds) - \y%d$^n", get_pcvar_num(stealthcost));
		iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\r3. \wNo Flash Blinding - \y%d$^n", get_pcvar_num(noflashcost));
		iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\r4. \w%d HP - \y%d$^n", get_pcvar_num(hpcvar), get_pcvar_num(hpcost));
		iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\r5. \w%d Armor - \y%d$^n", get_pcvar_num(armorcvar), get_pcvar_num(armorcost));
		iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\r6. \wHE Grenade - \y%d$^n", get_pcvar_num(grenadecost));
		iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\r7. \wGravity \r(10 seconds) - \y%d$^n", get_pcvar_num(gravitycost));   
		iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\r8. \wFaster Speed \r(25 seconds) - \y%d$^n", get_pcvar_num(speedcost));
		iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\r9. \wGodmode \d(key activation) \r(5 seconds) - \y%d$^n^n", get_pcvar_num(godmodecost));
		iLen += formatex(szBuffer[iLen], (sizeof szBuffer - 1) - iLen, "\r0. \wExit"); 

		new iKeys = ( 1<<0 | 1<<1 | 1<<2 | 1<<3 | 1<<4 | 1<<5 | 1<<6 | 1<<7 | 1<< 8 | 1<<9 );
		show_menu(id, iKeys, szBuffer, -1, "Hide'n'Seek Shop");
	} else
		ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 Shop has been disabled.");
	return PLUGIN_HANDLED;
}

// Shop actions
public hnsshop( id, key ) {
	switch( key ) {
		case 0: // Silent Footsteps
		{
			if(!is_user_alive(id)) {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You need to be alive!");
				return PLUGIN_HANDLED;  
			}
			if(usersilent[id] > 0) {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You already own this item!");
				return PLUGIN_HANDLED;
			}
			if(get_pcvar_num(allowsilent) == 0) {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 This item is disabled.");
				return PLUGIN_HANDLED;
			}
	
			new money = fm_get_user_money(id);
			new cost = get_pcvar_num(silentcost);
	
			if(money > cost || money == cost) {
				set_pev(id, pev_flTimeStepSound, 999);
				fm_set_user_money(id, money - cost);
				usersilent[id]++;
				hassilent[id]++;
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You purchased^x03 Silent Footsteps,^x04 now enemy cant hear you.");
			} else {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You need more^x04 money^x01 to buy this!");
			}
		}
		case 1: // Stealth Suit
		{
			if(!is_user_alive(id)) {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You need to be alive!");
				return PLUGIN_HANDLED;
			}
			if(userstealth[id] > 0) {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You already own this item!");
				return PLUGIN_HANDLED;
			}
			if(get_pcvar_num(allowstealth) == 0) {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 This item is disabled.");
				return PLUGIN_HANDLED;
			}
	
			new money = fm_get_user_money(id);
			new cost = get_pcvar_num(stealthcost);
	
			if(money > cost || money == cost) {
				fm_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 15);
				fm_set_user_money(id, money - cost);
				userstealth[id]++;
				set_task(20.0, "remove_stealth", id);
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You purchased^x03 Stealth Suit,^x04 now you are invisible for 20 seconds.") ;
			} else {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You need more^x04 money^x01 to buy this!");
			}
		}
		case 2: // NoFlash Blinding
		{
			if(!is_user_alive(id)) {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You need to be alive!");
				return PLUGIN_HANDLED;
			}
			if(usernoflash[id] > 0) {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You already own this item!");
				return PLUGIN_HANDLED;
			}
			if(get_pcvar_num(allownoflash) == 0) {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 This item is disabled.");
				return PLUGIN_HANDLED;
			}
	
			new money = fm_get_user_money(id);
			new cost = get_pcvar_num(noflashcost);
	
			if(money > cost || money == cost) {
				fm_set_user_money(id, money - cost);
				usernoflash[id]++;
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You purchased^x03 NoFlash Blinding.");
			} else {  
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You need more^x04 money^x01 to buy this!");
			} 
		}
		case 3: // HP
		{
			if(!is_user_alive(id)) {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You need to be alive!");
				return PLUGIN_HANDLED;
			}
			if(userhp[id] > 0) {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You already own this item!");
				return PLUGIN_HANDLED;
			}
			if(get_pcvar_num(allowhp) == 0) {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 This item is disabled.");
				return PLUGIN_HANDLED;
			}
	
			new money = fm_get_user_money(id);
			new cost = get_pcvar_num(hpcost);
	
			if(money > cost || money == cost) {
				new health = get_pcvar_num(hpcvar);
				fm_set_user_money(id, money - cost);
				fm_set_user_health(id, health);
				userhp[id]++;
				client_cmd(id, "spk items/medshot4");
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You purchased^x03 %d HP.", get_pcvar_num(hpcvar));
			} else {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You need more^x04 money^x01 to buy this!");
			}
		}
		case 4: // Armor
		{
			if(!is_user_alive(id)) {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You need to be alive!");
				return PLUGIN_HANDLED;
			}
			if(userarmor[id] > 0) {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You already own this item!");
				return PLUGIN_HANDLED;
			}
			if(get_pcvar_num(allowarmor) == 0) {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 This item is disabled.");
				return PLUGIN_HANDLED;
			}
	
			new money = fm_get_user_money(id);
			new cost = get_pcvar_num(armorcost);
		
			if(money > cost || money == cost) {
				new armor = get_pcvar_num(armorcvar);
				fm_set_user_money(id, money - cost);
				fm_set_user_armor(id, armor);
				userarmor[id]++;
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You purchased^x03 %d Armor.", get_pcvar_num(armorcvar));
			} else {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You need more^x04 money^x01 to buy this!");
			}
		}
		case 5: // HE Grenade
		{
			if(!is_user_alive(id)) {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You need to be alive!");
				return PLUGIN_HANDLED;
			}
			if(usergrenade[id] > 0) {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You already own this item!");
				return PLUGIN_HANDLED;
			}
			if(get_pcvar_num(allowgrenade) == 0) {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 This item is disabled.");
				return PLUGIN_HANDLED;
			}
	
			new money = fm_get_user_money(id);
			new cost = get_pcvar_num(grenadecost);
	
			if(money > cost || money == cost) {
				fm_set_user_money(id, money - cost);
				fm_give_item(id, "weapon_hegrenade");
				usergrenade[id]++;
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You purchased an^x03 HE-Grenade.");
			} else {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You need more^x04 money^x01 to buy this!");
			}
		}
		case 6: // Gravity
		{
			if(!is_user_alive(id)) {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You need to be alive!");
				return PLUGIN_HANDLED;
			}
			if(usergravity[id] > 0) {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You already own this item!");
				return PLUGIN_HANDLED;
			}
			if(get_pcvar_num(allowgravity) == 0) {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 This item is disabled.");
				return PLUGIN_HANDLED;
			}
	
			new money = fm_get_user_money(id);
			new cost = get_pcvar_num(gravitycost);
		
			if(money > cost || money == cost) {
				fm_set_user_money(id, money - cost);
				fm_set_user_gravity(id, 0.63);
				usergravity[id]++;
				set_task(10.0, "remove_gravity", id);
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You purchased^x03 Gravity^x04 for 10 seconds.");
			} else {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You need more^x04 money^x01 to buy this!");
			}
		}
		case 7: // Faster Speed
		{
			if(!is_user_alive(id)) {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You need to be alive!");
				return PLUGIN_HANDLED; 
			}
			if(userspeed[id] > 0) {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You already own this item!");
				return PLUGIN_HANDLED;
			}
			if(get_pcvar_num(allowspeed) == 0) {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 This item is disabled.");
				return PLUGIN_HANDLED;
			}
	
			new money = fm_get_user_money(id);
			new cost = get_pcvar_num(speedcost);
	
			if(money > cost || money == cost) {
				fm_set_user_money(id, money - cost);
				userspeed[id]++;
				hasspeed[id]++;
				fm_set_user_maxspeed(id, 320.0);
				set_task(25.0, "remove_speed", id);
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You purchased^x03 Faster speed.");
			} else {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You need more^x04 money^x01 to buy this!");
			}
		}
		case 8: // Godmode
		{
			if(!is_user_alive(id)) {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You need to be alive!");
				return PLUGIN_HANDLED; 
			}
			if(gotgodmode[id] > 0) {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You already own this item!");
				return PLUGIN_HANDLED;
			}
			if(get_pcvar_num(allowgodmode) == 0) {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 This item is disabled.");
				return PLUGIN_HANDLED;
			}
		
			new money = fm_get_user_money(id);
			new cost = get_pcvar_num(godmodecost);
		 
			if(money > cost || money == cost) {
				gotgodmode[id]++;
				fm_set_user_money(id, money - cost);
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You purchased^x03 Godmode,^x04 Press R(Reload)^x01 to activate it.");
			} else {
				ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You need more^x04 money^x01 to buy this!");
			}
		}
		case 9: // Exit
			return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}

// Remove Gravity
public remove_gravity( id ) {
	fm_set_user_gravity(id, 1.0);
	ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 Your gravity now is normal.");
}  

// Remove Stealth
public remove_stealth( id ) {
	fm_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255);
	ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 You are^x03 visible^x01 like others.");
}

// Remove Speed
public remove_speed( id ) {
	fm_set_user_maxspeed(id, 250.0);
	hasspeed[id] = 0;
	ColorChat(id, BLUE, "^x04[Hide'n'Seek Shop]^x01 Your speed is normal now.");
}

// Remove Godmode
public remove_godmode( id ) {
	hasgodmode[id] = 0;
	fm_set_user_godmode(id, 0);
	if(!mess2[id]) {
		ColorChat(id, RED, "^x04[Hide'n'Seek Shop]^x01 You dont have godmode anymore.");
		mess2[id]++;
		fm_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255);
		set_task(3.0, "remove_mess2", id);
	}
}

public remove_mess( id )		mess[id]	= 0;
public remove_mess2( id )	mess2[id]	= 0;

/// NoFlash Blinding - Start
public bad_fix2() {
	new Float:gametime = get_gametime();
	if(gametime - g_gametime2 > 2.5)
		for(new i = 0; i < 32; i++)
			grenade[i] = 0;
}

public eventFlash( id ) {
	new Float:gametime = get_gametime();
	if(gametime != g_gametime) { 
		g_owner = get_grenade_owner();
		g_gametime = gametime;
		for(new i = 0; i < 33; i++) 
			g_track[i] = false;
		g_track_enemy = false;
	}    
	if(is_user_connected(g_owner) && usernoflash[id] > 0) {
		g_track_enemy = true;

		message_begin(MSG_ONE, g_msgScreenFade, {0,0,0}, id);
		write_short(1);
		write_short(1);
		write_short(1);
		write_byte(0);
		write_byte(0);
		write_byte(0);
		write_byte(255);
		message_end();
	}
}

public flash_delay() {
	if(g_track_enemy == false) {
		for(new i = 0; i < 33; i++) {
			if(g_track[i] == true && is_user_connected(i)) {
				message_begin(MSG_ONE, g_msgScreenFade, {0,0,0}, i) ;
				write_short(1);
				write_short(1);
				write_short(1);
				write_byte(0);
				write_byte(0);
				write_byte(0);
				write_byte(255);
				message_end();
			}
		}
	}
}

public grenade_throw() {
	if(g_sync_check_data == 0)
		return PLUGIN_CONTINUE;
	g_sync_check_data--;
	if(read_datanum() < 2)
		return PLUGIN_HANDLED_MAIN;

	if(read_data(1) == 11 && (read_data(2) == 0 || read_data(2) == 1))
		add_grenade_owner(last);

	return PLUGIN_CONTINUE;
}

public fire_in_the_hole() {
	new name[32];
	read_data(3, name, 31);
	new temp_last = get_user_index(name);
	new junk;
	if((temp_last == 0) || (!is_user_connected(temp_last)))
		return PLUGIN_CONTINUE;
	if(get_user_weapon(temp_last,junk,junk) == CSW_FLASHBANG) {
		last = temp_last;
		g_sync_check_data = 2; 
	}
	return PLUGIN_CONTINUE;
}

public fire_in_the_hole2() {
	new name[32];
	read_data(4, name, 31);
	new temp_last = get_user_index(name);
	new junk;
	if((temp_last == 0) || (!is_user_connected(temp_last)))
		return PLUGIN_CONTINUE;
	if(get_user_weapon(temp_last,junk,junk) == CSW_FLASHBANG) {    
		last = temp_last;
		g_sync_check_data = 2;
	}
	return PLUGIN_CONTINUE;
}

add_grenade_owner(owner) {
	new Float:gametime = get_gametime();
	g_gametime2 = gametime;
	for(new i = 0; i < 32; i++) {
		if(grenade[i] == 0) {
			grenade[i] = owner;
			return;
		}
	}
}

get_grenade_owner() {
	new which = grenade[0];
	for(new i = 1; i < 32; i++)  
		grenade[i-1] = grenade[i];
	grenade[31] = 0;
	return which;
}

// from XxAvalanchexX "Flashbang Dynamic Light"
public fw_emitsound(entity,channel,const sample[],Float:volume,Float:attenuation,fFlags,pitch) {
	if(!equali(sample,"weapons/flashbang-1.wav") && !equali(sample,"weapons/flashbang-2.wav"))
		return FMRES_IGNORED;

	new Float:gametime = get_gametime();

	//in case no one got flashed, the sound happens after all the flashes, same game time
	if(gametime != g_gametime) {
		g_owner = get_grenade_owner();
		return FMRES_IGNORED;
	}
	return FMRES_IGNORED;
}
// NoFlash Blinding - End 

// Stocks - Start
public fm_set_user_money ( index, i_Money ) { 
	set_pdata_int ( index, 115, i_Money ); 

	message_begin ( MSG_ONE, g_msgMoney, _, index ); 
	write_long ( i_Money ); 
	write_byte ( 1 ); 
	message_end (); 
}

stock fm_get_user_godmode( index ) {
	new Float:val;
	pev(index, pev_takedamage, val);

	return (val == DAMAGE_NO);
}

stock fm_set_user_godmode( index, godmode = 0 ) {
	set_pev(index, pev_takedamage, godmode == 1 ? DAMAGE_NO : DAMAGE_AIM);

	return 1;
}

stock fm_set_user_health( index, health ) {
	health > 0 ? set_pev(index, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, index);

	return 1;
}

stock fm_set_user_rendering(index, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16) {
	return fm_set_rendering(index, fx, r, g, b, render, amount);
}

stock fm_set_user_maxspeed( index, Float:speed = -1.0 ) {
	engfunc(EngFunc_SetClientMaxspeed, index, speed);
	set_pev(index, pev_maxspeed, speed);

	return 1;
}

stock fm_set_user_armor( index, armor ) {
	set_pev(index, pev_armorvalue, float(armor));

	return 1;
}

stock fm_set_user_gravity( index, Float:gravity = 1.0 ) {
	set_pev(index, pev_gravity, gravity);

	return 1;
}

stock fm_give_item( index, const item[] ) {
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5))
		return 0;

	new ent = fm_create_entity(item);
	if (!pev_valid(ent))
		return 0;

	new Float:origin[3];
	pev(index, pev_origin, origin);
	set_pev(ent, pev_origin, origin);
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, ent);

	new save = pev(ent, pev_solid);
	dllfunc(DLLFunc_Touch, ent, index);
	if (pev(ent, pev_solid) != save)
		return ent;

	engfunc(EngFunc_RemoveEntity, ent);

	return -1;
}

stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16) {
	new Float:RenderColor[3];
	RenderColor[0] = float(r);
	RenderColor[1] = float(g);
	RenderColor[2] = float(b);

	set_pev(entity, pev_renderfx, fx);
	set_pev(entity, pev_rendercolor, RenderColor);
	set_pev(entity, pev_rendermode, render);
	set_pev(entity, pev_renderamt, float(amount));

	return 1;
}
// Stocks - End

// ColorChat - Start
ColorChat(id, Color:type, const msg[], {Float,Sql,Result,_}:...) {
	new message[256];

	switch(type) {
		case NORMAL:	message[0] = 0x01;
		case GREEN:	message[0] = 0x04;
		default:	message[0] = 0x03;
	}

	vformat(message[1], 251, msg, 4);

	// Make sure message is not longer than 192 character. Will crash the server.
	message[192] = '^0';

	new team, ColorChange, index, MSG_Type;
	
	if(id) {
		MSG_Type = MSG_ONE;
		index = id;
	} else {
		index = FindPlayer();
		MSG_Type = MSG_ALL;
	}
	
	team = get_user_team(index);
	ColorChange = ColorSelection(index, MSG_Type, type);

	ShowColorMessage(index, MSG_Type, message);
		
	if(ColorChange)
		Team_Info(index, MSG_Type, TeamName[team]);
}

ShowColorMessage(id, type, message[]) {
	static bool:saytext_used;
	static get_user_msgid_saytext;
	if(!saytext_used) {
		get_user_msgid_saytext = get_user_msgid("SayText");
		saytext_used = true;
	}
	message_begin(type, get_user_msgid_saytext, _, id);
	write_byte(id);
	write_string(message);
	message_end();	
}

Team_Info(id, type, team[]) {
	static bool:teaminfo_used;
	static get_user_msgid_teaminfo;
	if(!teaminfo_used) {
		get_user_msgid_teaminfo = get_user_msgid("TeamInfo");
		teaminfo_used = true;
	}
	message_begin(type, get_user_msgid_teaminfo, _, id);
	write_byte(id);
	write_string(team);
	message_end();

	return 1;
}

ColorSelection(index, type, Color:Type) {
	switch(Type) {
		case RED:	return Team_Info(index, type, TeamName[1]);
		case BLUE:	return Team_Info(index, type, TeamName[2]);
		case GREY:	return Team_Info(index, type, TeamName[0]);
	}

	return 0;
}

FindPlayer(){
	new i = -1;

	while(i <= get_maxplayers())
		if(is_user_connected(++i))
			return i;
	
	return -1;
}