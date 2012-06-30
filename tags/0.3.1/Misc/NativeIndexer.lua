-- ***************************************************************************************************************************************************
-- * Misc/NativeIndexer.lua                                                                                                                          *
-- ***************************************************************************************************************************************************
-- * Search tree that allows to index the auctionDB in the same way that the native auction searcher                                                 *
-- ***************************************************************************************************************************************************
-- * 0.4.0  / 2012.05.31 / Baanano: Rewritten AuctionTree.lua                                                                                        *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local Rarities = { sellable = 1, [""] = 2, common = 2, uncommon = 3, rare = 4, epic = 5, relic = 6, transcendant = 7, quest = 8, }

function InternalInterface.Utility.BuildNativeIndexer()
	local nativeIndexer = {}
	
	nativeIndexer.auctionIDs = {}
	nativeIndexer.searchTree = {}
	
	function nativeIndexer:AddAuction(itemType, auctionID, callings, rarity, level, category, name, price)
		name = name:upper()
		rarity = Rarities[rarity] or 0
		
		for calling in pairs(callings) do
			self.searchTree[calling] = self.searchTree[calling] or {}
			self.searchTree[calling][rarity] = self.searchTree[calling][rarity] or {}
			self.searchTree[calling][rarity][level] = self.searchTree[calling][rarity][level] or {}
			self.searchTree[calling][rarity][level][category] = self.searchTree[calling][rarity][level][category] or {}
			self.searchTree[calling][rarity][level][category][name] = self.searchTree[calling][rarity][level][category][name] or {}
			self.searchTree[calling][rarity][level][category][name][price] = self.searchTree[calling][rarity][level][category][name][price] or {}
			self.searchTree[calling][rarity][level][category][name][price][auctionID] = itemType
		end
		
		self.auctionIDs[auctionID] = itemType
	end
	
	function nativeIndexer:RemoveAuction(auctionID, callings, rarity, level, category, name, price)
		if not self.auctionIDs[auctionID] then return end
		
		name = name:upper()
		rarity = Rarities[rarity] or 0
		
		for calling in pairs(callings) do
			self.searchTree[calling][rarity][level][category][name][price][auctionID] = nil
		end
		
		self.auctionIDs[auctionID] = nil
	end
	
	function nativeIndexer:Search(calling, rarity, levelMin, levelMax, category, priceMin, priceMax, name)
		local results = {}
		
		name = name and name:upper() or nil
		rarity = rarity and Rarities[rarity] or nil
		
		for callingName, callingSubtree in pairs(self.searchTree) do
			if not calling or calling == callingName then
				for rarityName, raritySubtree in pairs(callingSubtree) do
					if not rarity or rarity <= rarityName then
						for level, levelSubtree in pairs(raritySubtree) do
							if (not levelMin or level >= levelMin) and (not levelMax or level <= levelMax) then
								for categoryName, categorySubtree in pairs(levelSubtree) do
									if not category or categoryName:find(category) then
										for itemName, nameSubtree in pairs(categorySubtree) do
											if not name or itemName:find(name) then
												for price, priceSubtree in pairs(nameSubtree) do
													if (not priceMin or price >= priceMin) and (not priceMax or price <= priceMax) then
														for auctionID, itemType in pairs(priceSubtree) do
															results[auctionID] = itemType
														end
													end
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
		
		return results
	end
	
	function nativeIndexer:GetItemTypes(auctionIDs)
		local results = {}

		for auctionID in pairs(auctionIDs) do
			results[auctionID] = self.auctionIDs[auctionID]
		end
		
		return results
	end
	
	return nativeIndexer
end
