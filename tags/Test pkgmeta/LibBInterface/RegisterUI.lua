local frameConstructors = 
{
	BPanel			= Library.LibBInterface.BPanel,
	BShadowedText	= Library.LibBInterface.BShadowedText,
	BMoneyDisplay	= Library.LibBInterface.BMoneyDisplay,
	BMoneySelector	= Library.LibBInterface.BMoneySelector,
	BSlider			= Library.LibBInterface.BSlider,
	BDataGrid		= Library.LibBInterface.BDataGrid,
	BWindow			= Library.LibBInterface.BWindow,
}

local oldCreateFrame = UI.CreateFrame
function UI.CreateFrame(type, name, parent)
	local constructor = frameConstructors[type]
	
	if constructor then
		return constructor(name, parent)
	else
		return oldCreateFrame(type, name, parent)
	end
end
