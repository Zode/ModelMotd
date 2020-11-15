ModelMotd modelmotd;

void ModelMotd_Call()
{
	modelmotd.RegisterExpansion(modelmotd);
}

class ModelMotd : AFBaseClass
{
	void ExpansionInfo()
	{
		this.AuthorName = "Zode";
		this.ExpansionName = "ModelMOTD";
		this.ShortName = "MM";
	}
	
	void ExpansionInit()
	{
		g_Hooks.RegisterHook(Hooks::Player::PlayerSpawn, @ModelMotd::PlayerSpawn);
		g_Hooks.RegisterHook(Hooks::Player::PlayerPreThink, @ModelMotd::PlayerPreThink);
		@ModelMotd::cvarenabled = CCVar("modelmotd_enable", 1, "0/1 disable/enable modelmotd", ConCommandFlag::AdminOnly, @ModelMotd::cvarenabledCB);
	}
	
	void MapInit()
	{
		ModelMotd::data.resize(0);
		
		for(int i = 0; i < g_Engine.maxClients; i++)
		{
			ModelMotd::MotdData mdata;
			mdata.hasSpawned = false;
			mdata.isVisible = false;
			ModelMotd::data.insertLast(mdata);
		}
	
		g_Game.PrecacheGeneric(ModelMotd::songPath);
		
		g_CustomEntityFuncs.RegisterCustomEntity( "ModelMotd::weapon_modelmotd", "weapon_modelmotd" );
		g_ItemRegistry.RegisterWeapon( "weapon_modelmotd", "mm" );
		g_Game.PrecacheOther("weapon_modelmotd");
		g_Game.PrecacheGeneric("sprites/mm/weapon_modelmotd.txt");
	}
	
	void PlayerDisconnectEvent(CBasePlayer@ pUser)
	{
		ModelMotd::MotdData mdata;
		mdata.hasSpawned = false;
		mdata.isVisible = false;
		ModelMotd::data[pUser.entindex()] = mdata;
	}
}

namespace ModelMotd
{
	class MotdData
	{
		bool hasSpawned = false;
		bool isVisible = false;
	}

	const string modelPath = "models/mm/dance.mdl";
	const string songPath = "sound/mm/bass.mp3";
	array<MotdData> data;
	CCVar@ cvarenabled;
	
	void cvarenabledCB(CCVar@ cvar, const string &in sOld, float fOld)
	{
		if(cvar.GetInt() < 0)
			cvar.SetInt(0);
		if(cvar.GetInt() > 1)
			cvar.SetInt(1);
	}
	
	void StuffCmd(edict_t@ edict, string cmd)
	{
		NetworkMessage msg(MSG_ONE, NetworkMessages::SVC_STUFFTEXT, edict);
			msg.WriteString(cmd);
		msg.End();
	}
	
	HookReturnCode PlayerSpawn(CBasePlayer@ pPlayer)
	{
		if(!modelmotd.Running) return HOOK_CONTINUE;
		if(!AFBase::IsSafe()) return HOOK_CONTINUE;
		if(cvarenabled.GetInt() == 0) return HOOK_CONTINUE;
		
		MotdData@ mdata = data[pPlayer.entindex()-1];
		if(mdata.hasSpawned) return HOOK_CONTINUE;
		
		mdata.hasSpawned = true;
		mdata.isVisible = true;
		data[pPlayer.entindex()-1] = mdata;
		
		EHandle player = pPlayer;
		g_Scheduler.SetTimeout("PostSpawn", 0.01f, player);
		
		return HOOK_CONTINUE;
	}
	
	void PostSpawn(EHandle player)
	{
		if(!player) return;
		CBasePlayer@ pPlayer = cast<CBasePlayer@>(cast<CBaseEntity@>(player));
		pPlayer.m_iHideHUD = 0;
		pPlayer.GiveNamedItem("weapon_modelmotd");
		pPlayer.SelectItem("weapon_modelmotd");
		
		StuffCmd(pPlayer.edict(), "mp3 loop \""+songPath+"\"");
	}
	
	HookReturnCode PlayerPreThink(CBasePlayer@ pPlayer, uint &out magicnumbers)
	{
		if(!AFBase::IsSafe()) return HOOK_CONTINUE;
		if(cvarenabled.GetInt() == 0) return HOOK_CONTINUE;
		
		MotdData@ mdata = data[pPlayer.entindex()-1];
		if(!mdata.isVisible) return HOOK_CONTINUE;
		
		if(pPlayer.pev.button > 0)
		{
			mdata.isVisible = false;
			pPlayer.m_iHideHUD = 0;
			CBasePlayerItem@ pItem = pPlayer.HasNamedPlayerItem("weapon_modelmotd");
			if(pItem !is null) pPlayer.RemovePlayerItem(pItem);
			
			data[pPlayer.entindex()-1] = mdata;
			//StuffCmd(pPlayer.edict(), "cd fadeout"); <- fades mp3 away but is blocked in stufftext
			StuffCmd(pPlayer.edict(), "mp3 stop");
			
			return HOOK_CONTINUE;
		}
		
		return HOOK_CONTINUE;
	}
	
	// weapon
	class weapon_modelmotd : ScriptBasePlayerWeaponEntity
	{
		void Spawn()
		{
			self.Precache();
			g_EntityFuncs.SetModel(self, self.GetW_Model("models/w_crowbar.mdl"));
			self.m_iClip			= -1;
			self.FallInit();
		}
		
		void Precache()
		{
			self.PrecacheCustomModels();
			g_Game.PrecacheModel(modelPath);
			g_Game.PrecacheModel("models/w_crowbar.mdl");
			g_Game.PrecacheModel("models/p_crowbar.mdl");
		}
		
		bool GetItemInfo(ItemInfo& out info)
		{
			info.iMaxAmmo1		= -1;
			info.iMaxAmmo2		= -1;
			info.iMaxClip		= WEAPON_NOCLIP;
			info.iSlot			= 0;
			info.iPosition		= 0;
			info.iFlags 		= 0;
			info.iWeight		= 0;
			return true;
		}
		
		bool AddToPlayer(CBasePlayer@ pPlayer)
		{
			return BaseClass.AddToPlayer(pPlayer);
		}
		
		bool Deploy()
		{
			return self.DefaultDeploy(self.GetV_Model(modelPath), self.GetP_Model("models/p_crowbar.mdl"), 0, "crowbar");
		}
		
		void Holster(int skip = 0)
		{
			BaseClass.Holster(skip);
		}
		
		CBasePlayerItem@ DropItem()
		{
			return null;
		}
		
		void WeaponIdle()
		{
			return;
		}
		
		void PrimaryAttack()
		{
			return;
		}
	}
}