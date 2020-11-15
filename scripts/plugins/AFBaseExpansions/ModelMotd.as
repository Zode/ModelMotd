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
	}
	
	void MapInit()
	{
		ModelMotd::data.resize(0);
		
		for(int i = 0; i < g_Engine.maxClients; i++)
		{
			ModelMotd::MotdData mdata;
			mdata.hasSpawned = false;
			mdata.isVisible = false;
			mdata.oldView = "";
			ModelMotd::data.insertLast(mdata);
		}
	
		g_Game.PrecacheModel(ModelMotd::modelPath);
		g_Game.PrecacheGeneric(ModelMotd::songPath);
	}
	
	void PlayerDisconnectEvent(CBasePlayer@ pUser)
	{
		ModelMotd::MotdData mdata;
		mdata.hasSpawned = false;
		mdata.isVisible = false;
		mdata.oldView = "";
		ModelMotd::data[pUser.entindex()] = mdata;
	}
}

namespace ModelMotd
{
	class MotdData
	{
		string oldView = "";
		bool hasSpawned = false;
		bool isVisible = false;
	}

	const string modelPath = "models/mm/dance.mdl";
	const string songPath = "sound/mm/bass.mp3";
	array<MotdData> data;
	
	void StuffCmd(edict_t@ edict, string cmd)
	{
		NetworkMessage msg(MSG_ONE, NetworkMessages::SVC_STUFFTEXT, edict);
			msg.WriteString(cmd);
		msg.End();
	}
	
	HookReturnCode PlayerSpawn(CBasePlayer@ pPlayer)
	{
		if(!modelmotd.Running) return HOOK_CONTINUE;
		
		MotdData@ mdata = data[pPlayer.entindex()-1];
		if(mdata.hasSpawned) return HOOK_CONTINUE;
		
		mdata.oldView = pPlayer.pev.viewmodel;
		mdata.hasSpawned = true;
		mdata.isVisible = true;
		data[pPlayer.entindex()-1] = mdata;
		
		pPlayer.pev.viewmodel = modelPath;
		pPlayer.m_iHideHUD = 1;
		
		StuffCmd(pPlayer.edict(), "mp3 loop \""+songPath+"\"");
		
		return HOOK_CONTINUE;
	}
	
	HookReturnCode PlayerPreThink(CBasePlayer@ pPlayer, uint &out magicnumbers)
	{
		if(!AFBase::IsSafe()) return HOOK_CONTINUE;
		
		MotdData@ mdata = data[pPlayer.entindex()-1];
		if(!mdata.isVisible) return HOOK_CONTINUE;
		
		if(pPlayer.pev.button > 0)
		{
			mdata.isVisible = false;
			pPlayer.pev.viewmodel = mdata.oldView;
			pPlayer.m_iHideHUD = 0;
			data[pPlayer.entindex()-1] = mdata;
			//StuffCmd(pPlayer.edict(), "cd fadeout"); <- fades mp3 away but is blocked in stufftext
			StuffCmd(pPlayer.edict(), "mp3 stop");
			
			return HOOK_CONTINUE;
		}
		
		return HOOK_CONTINUE;
	}
}