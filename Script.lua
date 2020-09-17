-- Script v1.0 by forgetaz (forgetaz@outlook.com)
-- This work is licensed under GNU General Public License v2.0.

function Initialize()
	-- Load a base module and Get Global Util
	Util = dofile(SKIN:MakePathAbsolute('Util.lua'))
	-- Load modules and Union tables to Util and override
	Util:Union(dofile(SKIN:MakePathAbsolute('Qreki.lua')))
	Util:Union(dofile(SKIN:MakePathAbsolute('RokuyouCalendar.lua')))

	--set Util.RokuyouStyles
	Util.RokuyouColors[0] = 'RokuyouStyle|TaianStyle'
	Util.RokuyouColors[1] = 'RokuyouStyle|SyakkouStyle'
	Util.RokuyouColors[2] = 'RokuyouStyle|SensyouStyle'
	Util.RokuyouColors[3] = 'RokuyouStyle|TomobikiStyle'
	Util.RokuyouColors[4] = 'RokuyouStyle|SenpuStyle'
	Util.RokuyouColors[5] = 'RokuyouStyle|ButumetuStyle'
	--get Variables
	for i = 1, 7 do
		table.insert(Util.Dows, i, Util:getValue('Week'..i..'Text'))
	end
	Util.ContainerWidth = Util:getValue('ContainerWidth', 700)
	Util.DaySizeRatio = Util:getValue('DaySizeRatio',0.98)
	Util.GoldenRatio = Util:getValue('GoldenRatio',1.618)
	Util.CellPadding = Util:toInt(Util:getValue('CellPadding',10))
	Util.ContainerPaddingLeft = Util:toInt(Util:getValue('ContainerPaddingLeft', 10))
	--Calc Size
	Util.CellWidth = Util:toInt(Util.ContainerWidth* Util.DaySizeRatio  / 7)
	Util.CellX = Util:toInt(Util.ContainerWidth/7*Util.DaySizeRatio/2 + Util.ContainerPaddingLeft)
	local tmp = Util:toInt(Util.ContainerWidth / Util.GoldenRatio/8)
	Util.CellY = Util:toInt(tmp*2+Util:getValue('ContainerPaddingTop', 10)+Util:getValue('ContainerPaddingBottom', 10))
	Util.CellHeight = Util:toInt(tmp*2/3)
	Util.RokuyouCellHeight = Util:toInt(tmp/3)
end

function Update()
    if Util.CriticalError > 0 then
        Util:CloseSkin()
    end
	--Check Flg
	if SELF:GetOption('Stop') == '1' then
		return
	end
	--Check Update
	if Util:SetCurrentDate(SELF:GetOption('curYear'), SELF:GetOption('curMonth')) ~= true then
		return
	end
	--Create
    Util:CreateCalendar()
end
