local _, InternalInterface = ...

local Rarities = { sellable = 1, [""] = 2, uncommon = 3, rare = 4, epic = 5, relic = 6, trascendant = 7, quest = 8, }

function InternalInterface.Utility.BuildAuctionTree()
	local auctionTree = {}
	
	auctionTree.auctionIDs = {}
	auctionTree.searchTree = {}
	
	function auctionTree:AddAuction(itemType, auctionID, rbe, callings, rarity, level, category, name, price)
		name = name:upper()
		rarity = Rarities[rarity] or 0
		
		self.searchTree[rbe] = self.searchTree[rbe] or {}
		for calling in pairs(callings) do
			self.searchTree[rbe][calling] = self.searchTree[rbe][calling] or {}
			self.searchTree[rbe][calling][rarity] = self.searchTree[rbe][calling][rarity] or {}
			self.searchTree[rbe][calling][rarity][level] = self.searchTree[rbe][calling][rarity][level] or {}
			self.searchTree[rbe][calling][rarity][level][category] = self.searchTree[rbe][calling][rarity][level][category] or {}
			self.searchTree[rbe][calling][rarity][level][category][name] = self.searchTree[rbe][calling][rarity][level][category][name] or {}
			self.searchTree[rbe][calling][rarity][level][category][name][price] = self.searchTree[rbe][calling][rarity][level][category][name][price] or {}
			self.searchTree[rbe][calling][rarity][level][category][name][price][auctionID] = itemType
		end
		
		self.auctionIDs[auctionID] = itemType
	end
	
	function auctionTree:RemoveAuction(auctionID, rbe, callings, rarity, level, category, name, price)
		if not self.auctionIDs[auctionID] then return end
		
		name = name:upper()
		rarity = Rarities[rarity] or 0
		
		for calling in pairs(callings) do
			self.searchTree[rbe][calling][rarity][level][category][name][price][auctionID] = nil
		end
		
		self.auctionIDs[auctionID] = nil
	end
	
	function auctionTree:Search(rbe, calling, rarity, levelMin, levelMax, category, priceMin, priceMax, name)
		local results = {}
		
		name = name and name:upper() or nil
		rarity = rarity and Rarities[rarity] or nil
		
		for rbeName, rbeSubtree in pairs(self.searchTree) do
			if not rbe or rbe == rbeName then
				for callingName, callingSubtree in pairs(rbeSubtree) do
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
			end
		end
		
		return results
	end
	
	return auctionTree
end
