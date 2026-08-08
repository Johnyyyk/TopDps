local function InitAlphaAnimation(self)
    local target = self.target
    if not target then
        target = self:GetRegionParent()
        self.target = target
    end

    local change = self.change
    if not change then
        change = 0
        self.change = change
    end

    local frameAlpha = target:GetAlpha()
    self.frameAlpha = frameAlpha
    self.alphaFactor = change
end

local function TidyAlphaAnimation(self)
    self.alphaFactor = nil
    self.frameAlpha = nil
end

function RpalTopDpsCheeseAlphaTemplate_OnUpdate(self)
    local progress = self:GetSmoothProgress()
    if progress ~= 0 then
        if not self.played then
            InitAlphaAnimation(self)
            self.played = 1
        end

        local frameAlpha = self.frameAlpha
        if frameAlpha then
            self.target:SetAlpha(frameAlpha + self.alphaFactor * progress)
            if progress == 1 then
                TidyAlphaAnimation(self)
            end
        end
    end
end

function RpalTopDpsCheeseAlphaTemplate_OnStop(self)
    if self.frameAlpha then
        TidyAlphaAnimation(self)
    end
    self.played = nil
end

RpalTopDpsCheeseAlphaTemplate_OnFinished = RpalTopDpsCheeseAlphaTemplate_OnStop

local function InitScaleAnimation(self)
    local target = self.target
    if not target then
        target = self:GetRegionParent()
        self.target = target
    end

    local scaleX = self.scaleX
    if not scaleX then
        scaleX = 0
        self.scaleX = scaleX
    end

    local scaleY = self.scaleY
    if not scaleY then
        scaleY = 0
        self.scaleY = scaleY
    end

    local _, _, width, height = target:GetRect()
    if not width then
        return nil
    end

    self.frameWidth = width
    self.frameHeight = height
    self.widthFactor = width * scaleX - width
    self.heightFactor = height * scaleY - height

    local parent = target:GetParent()
    local setCenter
    local numPoints = target:GetNumPoints()
    if numPoints >= 1 then
        local point, relativeTo, relativePoint, xOffset, yOffset = target:GetPoint(1)
        if numPoints == 1 and point == "CENTER" then
            setCenter = false
        else
            local index = 1
            while true do
                if relativeTo ~= parent and yOffset ~= nil then
                    local key = #self + 1
                    self[key] = point
                    self[key + 1] = relativeTo
                    self[key + 2] = relativePoint
                    self[key + 3] = xOffset
                    self[key + 4] = yOffset
                end

                index = index + 1
                if index <= numPoints then
                    point, relativeTo, relativePoint, xOffset, yOffset = target:GetPoint(index)
                else
                    break
                end
            end

            target:ClearAllPoints()
            setCenter = true
        end
    else
        setCenter = true
    end

    if setCenter then
        local x, y = target:GetCenter()
        local parentX, parentY = parent:GetCenter()
        target:SetPoint("CENTER", x - parentX, y - parentY)
    end

    return 1
end

local function TidyScaleAnimation(self)
    local target = self.target
    if #self ~= 0 then
        target:ClearAllPoints()
        local index
        for index = 1, #self, 5 do
            target:SetPoint(self[index], self[index + 1], self[index + 2], self[index + 3], self[index + 4])
            self[index] = nil
            self[index + 1] = nil
            self[index + 2] = nil
            self[index + 3] = nil
            self[index + 4] = nil
        end
    end

    self.widthFactor = nil
    self.heightFactor = nil
    self.frameWidth = nil
    self.frameHeight = nil
end

function RpalTopDpsCheeseScaleTemplate_OnUpdate(self)
    local progress = self:GetSmoothProgress()
    if progress ~= 0 then
        if not self.played then
            if InitScaleAnimation(self) then
                self.played = 1
            end
        end

        local frameWidth = self.frameWidth
        if frameWidth then
            self.target:SetSize(
                frameWidth + self.widthFactor * progress,
                self.frameHeight + self.heightFactor * progress
            )
            if progress == 1 then
                TidyScaleAnimation(self)
            end
        end
    end
end

function RpalTopDpsCheeseScaleTemplate_OnStop(self)
    if self.frameWidth then
        TidyScaleAnimation(self)
    end
    self.played = nil
end

RpalTopDpsCheeseScaleTemplate_OnFinished = RpalTopDpsCheeseScaleTemplate_OnStop
