BCS = BCS or {}

local BCS_Tooltip = getglobal("BetterCharacterStatsTooltip") or CreateFrame("GameTooltip", "BetterCharacterStatsTooltip", nil, "GameTooltipTemplate")
local BCS_Prefix = "BetterCharacterStatsTooltip"
BCS_Tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

local L = BCS["L"]

local strfind = strfind
local tonumber = tonumber
local tinsert = tinsert

local function tContains(table, item)
	local index = 1
	while table[index] do
		if ( item == table[index] ) then
			return 1
		end
		index = index + 1
	end
	return nil
end

local Cache_GetHitRating_Tab, Cache_GetHitRating_Talent
function BCS:GetHitRating()
	local Hit_Set_Bonus = {}
	local hit = 0;
	local MAX_INVENTORY_SLOTS = 19;
	
	for slot=0, MAX_INVENTORY_SLOTS do
		local hasItem = BCS_Tooltip:SetInventoryItem("player", slot)
		if hasItem then
			local MAX_LINES = BCS_Tooltip:NumLines()
			local SET_NAME = nil
			
			for line=1, MAX_LINES do
				local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
				if left:GetText() then
					local _,_, value = strfind(left:GetText(), L["Equip: Improves your chance to hit by (%d)%%."])
					if value then
						hit = hit + tonumber(value)
					end
					_,_, value = strfind(left:GetText(), L["/Hit %+(%d+)"])
					if value then
						hit = hit + tonumber(value)
					end
					_,_, value = strfind(left:GetText(), "(.+) %(%d/%d%)")
					if value then
						SET_NAME = value
					end
					_,_, value = strfind(left:GetText(), L["^Set: Improves your chance to hit by (%d)%%."])
					if value and SET_NAME and not tContains(Hit_Set_Bonus, SET_NAME) then
						tinsert(Hit_Set_Bonus, SET_NAME)
						hit = hit + tonumber(value)
						line = MAX_LINES
					end
				end
			end
			
		end
	end

	-- buffs
	-- http://blue.cardplace.com/cache/wow-dungeons/624230.htm
	-- 32 buffs max
	for i=0, 31 do
		if GetPlayerBuff(i) > -1 then
			BCS_Tooltip:SetPlayerBuff(i)
			local MAX_LINES = BCS_Tooltip:NumLines()
				
			for line=1, MAX_LINES do
				local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
				if left:GetText() then
					local _,_, value = strfind(left:GetText(), L["Chance to hit increased by (%d)%%."])
					if value then
						hit = hit + tonumber(value)
					end
				end
			end
		end
	end
	
	local MAX_TABS = GetNumTalentTabs()
	
	-- speedup
	if Cache_GetHitRating_Tab and Cache_GetHitRating_Talent then
		BCS_Tooltip:SetTalent(Cache_GetHitRating_Tab, Cache_GetHitRating_Talent)
		local MAX_LINES = BCS_Tooltip:NumLines()
		
		for line=1, MAX_LINES do
			local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
			if left:GetText() then
				local _,_, value = strfind(left:GetText(), L["Increases your chance to hit with melee weapons by (%d)%%."])
				local name, iconTexture, tier, column, rank, maxRank, isExceptional, meetsPrereq = GetTalentInfo(Cache_GetHitRating_Tab, Cache_GetHitRating_Talent)
				if value and rank > 0 then
					hit = hit + tonumber(value)
					line = MAX_LINES
				end
			end
		end
		
		return hit
	end
	
	for tab=1, MAX_TABS do
		local MAX_TALENTS = GetNumTalents(tab)
		
		for talent=1, MAX_TALENTS do
			BCS_Tooltip:SetTalent(tab, talent);
			local MAX_LINES = BCS_Tooltip:NumLines()
			
			for line=1, MAX_LINES do
				local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
				if left:GetText() then
					local _,_, value = strfind(left:GetText(), L["Increases your chance to hit with melee weapons by (%d)%%."])
					local name, iconTexture, tier, column, rank, maxRank, isExceptional, meetsPrereq = GetTalentInfo(tab, talent)
					if value and rank > 0 then
						hit = hit + tonumber(value)
						
						Cache_GetHitRating_Tab = tab
						Cache_GetHitRating_Talent = talent
						
						line = MAX_LINES
						talent = MAX_TALENTS
						tab = MAX_TABS
					end
				end	
			end
			
		end
	end
	
	return hit
end

function BCS:GetSpellHitRating()
	local hit = 0
	local hit_fire = 0
	local hit_frost = 0
	local hit_arcane = 0
	local hit_shadow = 0
	
	-- scan gear
	local MAX_INVENTORY_SLOTS = 19
	for slot=0, MAX_INVENTORY_SLOTS do
		local hasItem = BCS_Tooltip:SetInventoryItem("player", slot)
		
		if hasItem then
			local MAX_LINES = BCS_Tooltip:NumLines()
			
			for line=1, MAX_LINES do
				local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
				
				if left:GetText() then
					
					local _,_, value = strfind(left:GetText(), L["Equip: Improves your chance to hit with spells by (%d)%%."])
					if value then
						hit = hit + tonumber(value)
					end
					_,_, value = strfind(left:GetText(), L["/Spell Hit %+(%d+)"])
					if value then
						hit = hit + tonumber(value)
					end
				end
			end
		
		end
	end
	
	-- scan talents
	local MAX_TABS = GetNumTalentTabs()
	
	for tab=1, MAX_TABS do
		local MAX_TALENTS = GetNumTalents(tab)
		
		for talent=1, MAX_TALENTS do
			BCS_Tooltip:SetTalent(tab, talent)
			local MAX_LINES = BCS_Tooltip:NumLines()
			
			for line=1, MAX_LINES do
				local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
				if left:GetText() then
					-- Mage
					-- Elemental Precision
					local _,_, value = strfind(left:GetText(), L["Reduces the chance that the opponent can resist your Frost and Fire spells by (%d)%%."])
					local name, iconTexture, tier, column, rank, maxRank, isExceptional, meetsPrereq = GetTalentInfo(tab, talent)
					if value and rank > 0 then
						hit_fire = hit_fire + tonumber(value)
						hit_frost = hit_frost + tonumber(value)
						line = MAX_LINES
					end
					
					-- Arcane Focus
					_,_, value = strfind(left:GetText(), L["Reduces the chance that the opponent can resist your Arcane spells by (%d+)%%."])
					local name, iconTexture, tier, column, rank, maxRank, isExceptional, meetsPrereq = GetTalentInfo(tab, talent)
					if value and rank > 0 then
						hit_arcane = hit_arcane + tonumber(value)
						line = MAX_LINES
					end
					
					-- Priest
					-- Shadow Focus
					_,_, value = strfind(left:GetText(), L["Reduces your target's chance to resist your Shadow spells by (%d+)%%."])
					local name, iconTexture, tier, column, rank, maxRank, isExceptional, meetsPrereq = GetTalentInfo(tab, talent)
					if value and rank > 0 then
						hit_shadow = hit_shadow + tonumber(value)
						line = MAX_LINES
					end
				end	
			end
			
		end
	end
	
	return hit, hit_fire, hit_frost, hit_arcane, hit_shadow
end

local Cache_GetCritChance_SpellID, Cache_GetCritChance_BookType, Cache_GetCritChance_Line
function BCS:GetCritChance()
	local crit = 0
	
	-- speedup
	if Cache_GetCritChance_SpellID and Cache_GetCritChance_BookType and Cache_GetCritChance_Line then
	
		BCS_Tooltip:SetSpell(Cache_GetCritChance_SpellID, Cache_GetCritChance_BookType)
		local left = getglobal(BCS_Prefix .. "TextLeft" .. Cache_GetCritChance_Line)
		if left:GetText() then
			local _,_, value = strfind(left:GetText(), L["([%d.]+)%% chance to crit"])
			if value then
				crit = crit + tonumber(value)
			end
		end
		
		return crit
	end
	
	local MAX_TABS = GetNumSpellTabs()
	
	for tab=1, MAX_TABS do
		local name, texture, offset, numSpells = GetSpellTabInfo(tab)
		
		for spell=1, numSpells do
			local currentPage = ceil(spell/SPELLS_PER_PAGE)
			local SpellID = spell + offset + ( SPELLS_PER_PAGE * (currentPage - 1))

			BCS_Tooltip:SetSpell(SpellID, BOOKTYPE_SPELL)
			local MAX_LINES = BCS_Tooltip:NumLines()
			
			for line=1, MAX_LINES do
				local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
				if left:GetText() then
					local _,_, value = strfind(left:GetText(), L["([%d.]+)%% chance to crit"])
					if value then
						crit = crit + tonumber(value)
						
						Cache_GetCritChance_SpellID = SpellID
						Cache_GetCritChance_BookType = BOOKTYPE_SPELL
						Cache_GetCritChance_Line = line
						
						line = MAX_LINES
						spell = numSpells
						tab = MAX_TABS
					end
				end
			end
			
		end
	end
	
	return crit
end

local Cache_GetRangedCritChance_Tab, Cache_GetRangedCritChance_Talent, Cache_GetRangedCritChance_Line
function BCS:GetRangedCritChance()
	local crit = BCS:GetCritChance()
	
	if Cache_GetRangedCritChance_Tab and Cache_GetRangedCritChance_Talent and Cache_GetRangedCritChance_Line then
		BCS_Tooltip:SetTalent(Cache_GetRangedCritChance_Tab, Cache_GetRangedCritChance_Talent)
		local left = getglobal(BCS_Prefix .. "TextLeft" .. Cache_GetRangedCritChance_Line)
		
		if left:GetText() then
			local _,_, value = strfind(left:GetText(), L["Increases your critical strike chance with ranged weapons by (%d)%%."])
			local name, iconTexture, tier, column, rank, maxRank, isExceptional, meetsPrereq = GetTalentInfo(Cache_GetRangedCritChance_Tab, Cache_GetRangedCritChance_Talent)
			if value and rank > 0 then
				crit = crit + tonumber(value)
			end
		end
	
		return crit
	end
	
	local MAX_TABS = GetNumTalentTabs()
	
	for tab=1, MAX_TABS do
		local MAX_TALENTS = GetNumTalents(tab)
		
		for talent=1, MAX_TALENTS do
			BCS_Tooltip:SetTalent(tab, talent);
			local MAX_LINES = BCS_Tooltip:NumLines()
			
			for line=1, MAX_LINES do
				local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
				if left:GetText() then
					local _,_, value = strfind(left:GetText(), L["Increases your critical strike chance with ranged weapons by (%d)%%."])
					local name, iconTexture, tier, column, rank, maxRank, isExceptional, meetsPrereq = GetTalentInfo(tab, talent)
					if value and rank > 0 then
						crit = crit + tonumber(value)
						
						line = MAX_LINES
						talent = MAX_TALENTS
						tab = MAX_TABS
					end
				end
			end
			
		end
	end
	
	return crit
end

function BCS:GetSpellCritChance()
	-- school crit: most likely never
	local Crit_Set_Bonus = {}
	local spellCrit = 0;
	local _, intelect = UnitStat("player", 4)
	local _, class = UnitClass("player")
	
	-- values from theorycraft / http://wow.allakhazam.com/forum.html?forum=21&mid=1157230638252681707
	if class == "MAGE" then
		spellCrit = 0.2 + (intelect / 59.5)
	elseif class == "WARLOCK" then
		spellCrit = 1.7 + (intelect / 60.6)
	elseif class == "PRIEST" then
		spellCrit = 0.8 + (intelect / 59.56)
	elseif class == "DRUID" then
		spellCrit = 1.8 + (intelect / 60)
	elseif class == "SHAMAN" then
		spellCrit = 1.8 + (intelect / 59.2)
	elseif class == "PALADIN" then
		spellCrit = intelect / 29.5
	end
	
	local MAX_INVENTORY_SLOTS = 19
	
	for slot=0, MAX_INVENTORY_SLOTS do
		local hasItem = BCS_Tooltip:SetInventoryItem("player", slot)
		
		if hasItem then
			local SET_NAME = nil
			
			for line=1, BCS_Tooltip:NumLines() do
				local left = getglobal(BCS_Prefix .. "TextLeft" .. line)

				if left:GetText() then
					local _,_, value = strfind(left:GetText(), L["Equip: Improves your chance to get a critical strike with spells by (%d)%%."])
					if value then
						spellCrit = spellCrit + tonumber(value)
					end
					
					_,_, value = strfind(left:GetText(), "(.+) %(%d/%d%)")
					if value then
						SET_NAME = value
					end

					_, _, value = strfind(left:GetText(), L["^Set: Improves your chance to get a critical strike with spells by (%d)%%."])
					if value and SET_NAME and not tContains(Crit_Set_Bonus, SET_NAME) then
						tinsert(Crit_Set_Bonus, SET_NAME)
						spellCrit = spellCrit + tonumber(value)
					end

				end
			end
		end
		
	end
	
	return spellCrit
end

function BCS:GetSpellPower(school)
	if school then
		if not L["Equip: Increases damage done by "..school.." spells and effects by up to (%d+)."] then return -1 end
		local spellPower = 0;
		local MAX_INVENTORY_SLOTS = 19
		
		for slot=0, MAX_INVENTORY_SLOTS do
			local hasItem = BCS_Tooltip:SetInventoryItem("player", slot)
			
			if hasItem then
				for line=1, BCS_Tooltip:NumLines() do
					local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
					
					if left:GetText() then
						local _,_, value = strfind(left:GetText(), L["Equip: Increases damage done by "..school.." spells and effects by up to (%d+)."])
						if value then
							spellPower = spellPower + tonumber(value)
						end
						if L[school.." Damage %+(%d+)"] then
							_,_, value = strfind(left:GetText(), L[school.." Damage %+(%d+)"])
							if value then
								spellPower = spellPower + tonumber(value)
							end
						end
					end
				end
			end
			
		end
		
		return spellPower
	else
		local spellPower = 0;
		local arcanePower = 0;
		local firePower = 0;
		local frostPower = 0;
		local holyPower = 0;
		local naturePower = 0;
		local shadowPower = 0;
		local damagePower = 0;
		local MAX_INVENTORY_SLOTS = 19
		
		local SpellPower_Set_Bonus = {}
		
		-- scan gear
		for slot=0, MAX_INVENTORY_SLOTS do
			local hasItem = BCS_Tooltip:SetInventoryItem("player", slot)
			
			if hasItem then
				local SET_NAME
				
				for line=1, BCS_Tooltip:NumLines() do
					local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
					
					if left:GetText() then
						local _,_, value = strfind(left:GetText(), L["Equip: Increases damage and healing done by magical spells and effects by up to (%d+)."])
						if value then
							spellPower = spellPower + tonumber(value)
						end
						_,_, value = strfind(left:GetText(), L["Spell Damage %+(%d+)"])
						if value then
							spellPower = spellPower + tonumber(value)
						end
						_,_, value = strfind(left:GetText(), L["^%+(%d+) Spell Damage and Healing"])
						if value then
							spellPower = spellPower + tonumber(value)
						end
						
						_,_, value = strfind(left:GetText(), L["Equip: Increases damage done by Arcane spells and effects by up to (%d+)."])
						if value then
							arcanePower = arcanePower + tonumber(value)
						end
						
						_,_, value = strfind(left:GetText(), L["Equip: Increases damage done by Fire spells and effects by up to (%d+)."])
						if value then
							firePower = firePower + tonumber(value)
						end
						_,_, value = strfind(left:GetText(), L["Fire Damage %+(%d+)"])
						if value then
							firePower = firePower + tonumber(value)
						end
						
						_,_, value = strfind(left:GetText(), L["Equip: Increases damage done by Frost spells and effects by up to (%d+)."])
						if value then
							frostPower = frostPower + tonumber(value)
						end
						_,_, value = strfind(left:GetText(), L["Frost Damage %+(%d+)"])
						if value then
							frostPower = frostPower + tonumber(value)
						end
						
						_,_, value = strfind(left:GetText(), L["Equip: Increases damage done by Holy spells and effects by up to (%d+)."])
						if value then
							holyPower = holyPower + tonumber(value)
						end
						
						_,_, value = strfind(left:GetText(), L["Equip: Increases damage done by Nature spells and effects by up to (%d+)."])
						if value then
							naturePower = naturePower + tonumber(value)
						end
						
						_,_, value = strfind(left:GetText(), L["Equip: Increases damage done by Shadow spells and effects by up to (%d+)."])
						if value then
							shadowPower = shadowPower + tonumber(value)
						end
						_,_, value = strfind(left:GetText(), L["Shadow Damage %+(%d+)"])
						if value then
							shadowPower = shadowPower + tonumber(value)
						end
						
						_,_, value = strfind(left:GetText(), "(.+) %(%d/%d%)")
						if value then
							SET_NAME = value
						end

						_, _, value = strfind(left:GetText(), L["^Set: Increases damage and healing done by magical spells and effects by up to (%d+)%."])
						if value and SET_NAME and not tContains(SpellPower_Set_Bonus, SET_NAME) then
							tinsert(SpellPower_Set_Bonus, SET_NAME)
							spellPower = spellPower + tonumber(value)
						end
						
					end
				end
			end
			
		end
		
		-- scan talents
		local MAX_TABS = GetNumTalentTabs()
		
		for tab=1, MAX_TABS do
			local MAX_TALENTS = GetNumTalents(tab)
			
			for talent=1, MAX_TALENTS do
				BCS_Tooltip:SetTalent(tab, talent)
				local MAX_LINES = BCS_Tooltip:NumLines()
				
				for line=1, MAX_LINES do
					local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
					if left:GetText() then
						-- Priest
						-- Spiritual Guidance
						local _,_, value = strfind(left:GetText(), L["Increases spell damage and healing by up to (%d+)%% of your total Spirit."])
						local name, iconTexture, tier, column, rank, maxRank, isExceptional, meetsPrereq = GetTalentInfo(tab, talent)
						if value and rank > 0 then
							local stat, effectiveStat = UnitStat("player", 5)
							spellPower = spellPower + floor(((tonumber(value) / 100) * effectiveStat))
							
							-- nothing more is currenlty supported, break out of the loops
							line = MAX_LINES
							talent = MAX_TALENTS
							tab = MAX_TABS
						end
					end	
				end
				
			end
		end
		
		
		-- buffs
		-- http://blue.cardplace.com/cache/wow-dungeons/624230.htm
		-- 32 buffs max
		for i=0, 31 do
			if GetPlayerBuff(i) > -1 then
				BCS_Tooltip:SetPlayerBuff(i)
				local MAX_LINES = BCS_Tooltip:NumLines()
					
				for line=1, MAX_LINES do
					local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
					if left:GetText() then
						local _,_, value = strfind(left:GetText(), L["Magical damage dealt is increased by up to (%d+)."])
						if value then
							spellPower = spellPower + tonumber(value)
							damagePower = damagePower + tonumber(value)
						end
					end
				end
			end
		end
		
		local secondaryPower = 0
		local secondaryPowerName = ""
		
		if arcanePower > secondaryPower then
			secondaryPower = arcanePower
			secondaryPowerName = L.SPELL_SCHOOL_ARCANE
		end
		if firePower > secondaryPower then
			secondaryPower = firePower
			secondaryPowerName = L.SPELL_SCHOOL_FIRE
		end
		if frostPower > secondaryPower then
			secondaryPower = frostPower
			secondaryPowerName = L.SPELL_SCHOOL_FROST
		end
		if holyPower > secondaryPower then
			secondaryPower = holyPower
			secondaryPowerName = L.SPELL_SCHOOL_HOLY
		end
		if naturePower > secondaryPower then
			secondaryPower = naturePower
			secondaryPowerName = L.SPELL_SCHOOL_NATURE
		end
		if shadowPower > secondaryPower then
			secondaryPower = shadowPower
			secondaryPowerName = L.SPELL_SCHOOL_SHADOW
		end
		
		return spellPower, secondaryPower, secondaryPowerName, damagePower
	end
end

function BCS:GetHealingPower()
	local healPower = 0;
	local MAX_INVENTORY_SLOTS = 19
	
	for slot=0, MAX_INVENTORY_SLOTS do
		local hasItem = BCS_Tooltip:SetInventoryItem("player", slot)
		
		if hasItem then
			for line=1, BCS_Tooltip:NumLines() do
				local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
				
				if left:GetText() then
					local _,_, value = strfind(left:GetText(), L["Equip: Increases healing done by spells and effects by up to (%d+)."])
					if value then
						healPower = healPower + tonumber(value)
					end
					_,_, value = strfind(left:GetText(), L["Healing Spells %+(%d+)"])
					if value then
						healPower = healPower + tonumber(value)
					end
					_,_, value = strfind(left:GetText(), L["^%+(%d+) Healing Spells"])
					if value then
						healPower = healPower + tonumber(value)
					end
				end
			end
		end
		
	end
	
	-- buffs
	-- http://blue.cardplace.com/cache/wow-dungeons/624230.htm
	-- 32 buffs max
	for i=0, 31 do
		if GetPlayerBuff(i) > -1 then
			BCS_Tooltip:SetPlayerBuff(i)
			local MAX_LINES = BCS_Tooltip:NumLines()
				
			for line=1, MAX_LINES do
				local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
				if left:GetText() then
					local _,_, value = strfind(left:GetText(), L["Healing done by magical spells is increased by up to (%d+)."])
					if value then
						healPower = healPower + tonumber(value)
					end
				end
			end
		end
	end
	
	return healPower
end

--[[
-- server\src\game\Object\Player.cpp
float Player::OCTRegenMPPerSpirit()
{
    float addvalue = 0.0;

    float Spirit = GetStat(STAT_SPIRIT);
    uint8 Class = getClass();

    switch (Class)
    {
        case CLASS_DRUID:   addvalue = (Spirit / 5 + 15);   break;
        case CLASS_HUNTER:  addvalue = (Spirit / 5 + 15);   break;
        case CLASS_MAGE:    addvalue = (Spirit / 4 + 12.5); break;
        case CLASS_PALADIN: addvalue = (Spirit / 5 + 15);   break;
        case CLASS_PRIEST:  addvalue = (Spirit / 4 + 12.5); break;
        case CLASS_SHAMAN:  addvalue = (Spirit / 5 + 17);   break;
        case CLASS_WARLOCK: addvalue = (Spirit / 5 + 15);   break;
    }

    addvalue /= 2.0f;   // the above addvalue are given per tick which occurs every 2 seconds, hence this divide by 2

    return addvalue;
}

void Player::UpdateManaRegen()
{
    // Mana regen from spirit
    float power_regen = OCTRegenMPPerSpirit();
    // Apply PCT bonus from SPELL_AURA_MOD_POWER_REGEN_PERCENT aura on spirit base regen
    power_regen *= GetTotalAuraMultiplierByMiscValue(SPELL_AURA_MOD_POWER_REGEN_PERCENT, POWER_MANA);

    // Mana regen from SPELL_AURA_MOD_POWER_REGEN aura
    float power_regen_mp5 = GetTotalAuraModifierByMiscValue(SPELL_AURA_MOD_POWER_REGEN, POWER_MANA) / 5.0f;

    // Set regen rate in cast state apply only on spirit based regen
    int32 modManaRegenInterrupt = GetTotalAuraModifier(SPELL_AURA_MOD_MANA_REGEN_INTERRUPT);
    if (modManaRegenInterrupt > 100)
        { modManaRegenInterrupt = 100; }

    m_modManaRegenInterrupt = power_regen_mp5 + power_regen * modManaRegenInterrupt / 100.0f;

    m_modManaRegen = power_regen_mp5 + power_regen;
}
]]

local function GetRegenMPPerSpirit()
	local addvalue = 0
	
	local stat, Spirit, posBuff, negBuff = UnitStat("player", 5)
	local lClass, class = UnitClass("player")
	
	if class == "DRUID" then
		addvalue = (Spirit / 5 + 15)
	elseif class == "HUNTER" then
		addvalue = (Spirit / 5 + 15)
	elseif class == "MAGE" then
		addvalue = (Spirit / 4 + 12.5)
	elseif class == "PALADIN" then
		addvalue = (Spirit / 5 + 15)
	elseif class == "PRIEST" then
		addvalue = (Spirit / 4 + 12.5)
	elseif class == "SHAMAN" then
		addvalue = (Spirit / 5 + 17)
	elseif class == "WARLOCK" then
		addvalue = (Spirit / 5 + 15)
	else
		return addvalue
	end
	return (addvalue / 2)
end

function BCS:GetManaRegen()
	-- to-maybe-do: apply buffs/talents
	local base, casting
	local power_regen = GetRegenMPPerSpirit()
	
	casting = power_regen / 100
	base = power_regen
	
	local mp5 = 0;
	local MAX_INVENTORY_SLOTS = 19
	
	for slot=0, MAX_INVENTORY_SLOTS do
		local hasItem = BCS_Tooltip:SetInventoryItem("player", slot)
		
		if hasItem then
			for line=1, BCS_Tooltip:NumLines() do
				local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
				
				if left:GetText() then
					local _,_, value = strfind(left:GetText(), L["^Mana Regen %+(%d+)"])
					if value then
						mp5 = mp5 + tonumber(value)
					end
					_,_, value = strfind(left:GetText(), L["Equip: Restores (%d+) mana per 5 sec."])
					if value then
						mp5 = mp5 + tonumber(value)
					end
				end
			end
		end
		
	end
	
	base = (base*5)
	casting = (casting*5)
	
	return base, casting, mp5
end