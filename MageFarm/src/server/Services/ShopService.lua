-- Robux purchases: game passes and developer products.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local ShopService = {}

local MAX_RECEIPTS = 50

function ShopService.init(GameService)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		for _, pass in ipairs(Config.GamePasses) do
			if pass.id ~= 0 and pass.id == passId then
				GameService.grantPass(player, pass.key)
			end
		end
	end)

	MarketplaceService.ProcessReceipt = function(info)
		local player = Players:GetPlayerByUserId(info.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local s = GameService.getSession(player)
		if not s then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local receipts = s.data.receipts
		if table.find(receipts, info.PurchaseId) then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		local product
		for _, p in ipairs(Config.Products) do
			if p.id ~= 0 and p.id == info.ProductId then
				product = p
				break
			end
		end
		if not product then
			warn("[ShopService] Unknown product id", info.ProductId)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		if not GameService.grantProduct(player, product.key) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		table.insert(receipts, info.PurchaseId)
		while #receipts > MAX_RECEIPTS do
			table.remove(receipts, 1)
		end
		GameService.save(player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return ShopService
