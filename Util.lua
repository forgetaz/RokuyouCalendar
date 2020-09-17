-- Util v1.0 by forgetaz (forgetaz@outlook.com)
-- This work is licensed under GNU General Public License v2.0.

local function Util()
    local U = {
        getCache = function(SELF, Name)
            if SELF.Name == nil then
                SELF.Name = {}
            end

            return SELF.Name
        end,
        setCache = function(SELF, Name, Data)
            SELF.Name = Data
        end,
        CloseSkin = function()
			SKIN:Bang('!DeactivateConfig')
		end,
        getMeasure = function(SELF, Name)
            return SKIN:GetMeasure(Name)
        end,
        DisableMesure = function(SELF, Name)
            SELF:getMeasure(Name):Disable()
        end,
        EnableMeasure = function(SELF, Name)
            SELF:getMeasure(Name):Enable()
        end,
        getMeter = function(SELF, Name)
            return SKIN:GetMeter(Name)
        end,
        ShowMeter = function(SELF, Name)
            SELF:getMeter(Name):Show()
        end,
        HideMeter = function(SELF, Name)
            SELF:getMeter(Name):Hide()
        end,
        setOption = function(SELF, Name, Type, Value)
            return SKIN:Bang( '!SetOption', Name, Type, Value)
        end,
        getValue = function(SELF, Name, Default)
            return SKIN:GetVariable(Name, Default)
        end,
        getMeasureValue = function(SELF, Name, Valuename)
            return SELF:getMeasure( Name ):GetValue(Valuename)
        end,
        toInt = function(SELF, Num)
            return tonumber(string.format('%d', Num))
        end,
        Union = function(SELF, Table)
            for key, Value in pairs(Table) do
            -- for key, Value in next, Table, nil do
                SELF[key] = Value
            end
        end,
    }
    return U
end

return Util()
