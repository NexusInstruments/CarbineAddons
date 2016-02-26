-----------------------------------------------------------------------------------------------
-- Client Lua Script for BankViewer
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Apollo"
require "Window"
require "Money"
require "AccountItemLib"
require "StorefrontLib"

local BankViewer = {}
local knBagBoxSize = 50
local knSaveVersion = 1

function BankViewer:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    return o
end

function BankViewer:Init()
    Apollo.RegisterAddon(self)
end

function BankViewer:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("BankViewer.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 
end

function BankViewer:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end
	
	Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	self:OnWindowManagementReady()

	Apollo.RegisterEventHandler("HideBank", "HideBank", self)
	Apollo.RegisterEventHandler("ShowBank", "Initialize", self)
    Apollo.RegisterEventHandler("ToggleBank", "Initialize", self)
	Apollo.RegisterEventHandler("CloseVendorWindow", "OnCloseVendorWindow", self)
	Apollo.RegisterEventHandler("CharacterEntitlementUpdate", "OnEntitlementUpdate", self)
	Apollo.RegisterEventHandler("AccountEntitlementUpdate", "OnEntitlementUpdate", self)
	Apollo.RegisterEventHandler("StoreLinksRefresh",						"RefreshStoreLink", self)
	Apollo.RegisterEventHandler("PersonaUpdateCharacterStats", "RefreshBagCount", self)

	self.timerNewBagPurchasedAlert = ApolloTimer.Create(12.0, false, "OnBankViewer_NewBagPurchasedAlert", self)
	self.timerNewBagPurchasedAlert:Stop()


end

function BankViewer:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("Bank_Header")})
end

function BankViewer:Initialize()
	if self.wndMain and self.wndMain:IsValid() then
		self.wndMain:Close()
		self.wndMain:Destroy()
		self.wndMain = nil
	end

	self.wndMain = Apollo.LoadForm("BankViewer.xml", "BankViewerForm", nil, self)
	local nLeft, nTop, nRight, nBottom = self.wndMain:GetOriginalLocation():GetOffsets()
	self.nFirstEverWidth = nRight - nLeft
	self.wndMain:SetSizingMinimum(self.nFirstEverWidth, 280)
	
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = Apollo.GetString("Bank_Header"), nSaveVersion = 2})
	
	self:RefreshStoreLink() -- Check store link and build the display accordingly
end

function BankViewer:Build()
	local nNumBagSlots = GameLib.GetNumBankBagSlots()

	self.wndMain:FindChild("ConfigureBagsContainer"):DestroyChildren()

	-- Configure Screen
	for idx = 1, GameLib.knMaxBankBagSlots do
		if not self.bStoreLinkValid and idx > nNumBagSlots then
			break
		end
		local idBag = idx + 20
		local wndCurr = Apollo.LoadForm(self.xmlDoc, "BankSlot", self.wndMain:FindChild("ConfigureBagsContainer"), self)
		local wndBagBtn = Apollo.LoadForm(self.xmlDoc, "BagBtn"..idBag, wndCurr:FindChild("BankSlotFrame"), self)
		if wndBagBtn:GetItem() then
			wndCurr:FindChild("BagCount"):SetText(wndBagBtn:GetItem():GetBagSlots())
		end
		wndCurr:FindChild("BagCount"):SetData(wndBagBtn)
		wndCurr:FindChild("NewBagPurchasedAlert"):Show(false, true)
		wndBagBtn:Enable(idx <= nNumBagSlots)
		
		if idx > nNumBagSlots + 1 then
			wndCurr:FindChild("BagLocked"):Show(true)
			wndCurr:SetTooltip(Apollo.GetString("Bank_LockedTooltip"))
		elseif idx > nNumBagSlots then
			wndCurr:FindChild("MTXUnlock"):Show(true)
			wndCurr:SetTooltip(Apollo.GetString("Bank_LockedTooltip"))
		else
			wndCurr:SetTooltip(Apollo.GetString("Bank_SlotTooltip"))
		end
	end
	self.wndMain:FindChild("ConfigureBagsContainer"):ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.Middle)

	-- Resize
	self:ResizeBankSlots()
end

function BankViewer:RefreshBagCount()
	if not self.wndMain or not self.wndMain:IsValid() or not self.wndMain:IsShown() then
		return
	end

	for key, wndCurr in pairs(self.wndMain:FindChild("ConfigureBagsContainer"):GetChildren()) do
		local wndBagBtn = wndCurr:FindChild("BagCount"):GetData()
		if wndBagBtn and wndBagBtn:GetItem() then
			wndCurr:FindChild("BagCount"):SetText(wndBagBtn:GetItem():GetBagSlots())
		elseif wndBagBtn then
			wndCurr:FindChild("BagCount"):SetText("")
		end
	end
end

function BankViewer:OnWindowClosed()
	Event_CancelBanking()
	
	self:HideBank()
end

function BankViewer:OnCloseVendorWindow()
	self:HideBank()
end

function BankViewer:HideBank()
	if self.wndMain and self.wndMain:IsValid() then
		local wndMain = self.wndMain
		self.wndMain = nil
		wndMain:Close()
		wndMain:Destroy()
	end
end

function BankViewer:ResizeBankSlots()
	if not self.wndMain or not self.wndMain:IsValid() or not self.wndMain:IsShown() then
		return
	end

	local nNumberOfBoxesPerRow = math.floor(self.wndMain:FindChild("MainBagWindow"):GetWidth() / knBagBoxSize)
	self.wndMain:FindChild("MainBagWindow"):SetBoxesPerRow(nNumberOfBoxesPerRow)

	-- Labels
	self:RefreshBagCount()
end

function BankViewer:OnBankViewerCloseBtn()
	self:HideBank()
end

function BankViewer:OnBankViewer_NewBagPurchasedAlert() -- handler for timerNewBagPurchasedAlert -- hide new bag purchased alert when it triggers
	if self.wndMain and self.wndMain:IsValid() then
		for idx, wndCurr in pairs(self.wndMain:FindChild("ConfigureBagsContainer"):GetChildren()) do
			wndCurr:FindChild("NewBagPurchasedAlert"):Show(false)
		end
		self.wndMain:FindChild("BankTitleText"):SetText(Apollo.GetString("Bank_Header"))
	end
end

function BankViewer:OnEntitlementUpdate(tEntitlement)
	if self.wndMain and tEntitlement.nEntitlementId == AccountItemLib.CodeEnumEntitlement.ExtraBankSlots then
		self.wndMain:FindChild("BankTitleText"):SetText(Apollo.GetString("Bank_BuySuccess"))
		self.timerNewBagPurchasedAlert:Start()
		self:Build()
	end
end

function BankViewer:RefreshStoreLink()
	self.bStoreLinkValid = StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.BankSlots)
	if self.wndMain and self.wndMain:IsValid() then
		self:Build()
	end
end

function BankViewer:UnlockMoreBankSlots()
	StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.BankSlots)
end

function BankViewer:OnGenerateTooltip(wndControl, wndHandler, tType, item)
	if wndControl ~= wndHandler then return end
	wndControl:SetTooltipDoc(nil)
	if item ~= nil then
		local itemEquipped = item:GetEquippedItemForItemType()
		Tooltip.GetItemTooltipForm(self, wndControl, item, {bPrimary = true, bSelling = false, itemCompare = itemEquipped})
	end
end

local BankViewerInst = BankViewer:new()
BankViewerInst:Init()
