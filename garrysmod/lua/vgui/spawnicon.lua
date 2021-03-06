
local PANEL = {}

AccessorFunc( PANEL, "m_strModelName",	"ModelName" )
AccessorFunc( PANEL, "m_iSkin",			"SkinID" )
AccessorFunc( PANEL, "m_strBodyGroups",	"BodyGroup" )
AccessorFunc( PANEL, "m_strIconName",	"IconName" )

function PANEL:Init()

	self:SetDoubleClickingEnabled( false )
	self:SetText( "" )

	self.Icon = vgui.Create( "ModelImage", self )
	self.Icon:SetMouseInputEnabled( false )
	self.Icon:SetKeyboardInputEnabled( false )

	self:SetSize( 64, 64 )

	self.m_strBodyGroups = "000000000"

end

function PANEL:DoRightClick()

	local pCanvas = self:GetSelectionCanvas()
	if ( IsValid( pCanvas ) && pCanvas:NumSelectedChildren() > 0 ) then
		return hook.Run( "SpawnlistOpenGenericMenu", pCanvas )
	end

	self:OpenMenu()
end

function PANEL:DoClick()
end

function PANEL:OpenMenu()
end

function PANEL:Paint( w, h )

	self.OverlayFade = math.Clamp( ( self.OverlayFade or 0 ) - RealFrameTime() * 640 * 2, 0, 255 )

	if ( dragndrop.IsDragging() || !self:IsHovered() ) then return end

	self.OverlayFade = math.Clamp( self.OverlayFade + RealFrameTime() * 640 * 8, 0, 255 )

end

local border = 4
local border_w = 5
local matHover = Material( "gui/sm_hover.png", "nocull" )
local boxHover = GWEN.CreateTextureBorder( border, border, 64 - border * 2, 64 - border * 2, border_w, border_w, border_w, border_w, matHover )

function PANEL:PaintOver( w, h )

	if ( self.OverlayFade > 0 ) then
		boxHover( 0, 0, w, h, Color( 255, 255, 255, self.OverlayFade ) )
	end

	self:DrawSelections()

end

function PANEL:PerformLayout()

	if ( self:IsDown() && !self.Dragging ) then
		self.Icon:StretchToParent( 6, 6, 6, 6 )
	else
		self.Icon:StretchToParent( 0, 0, 0, 0 )
	end

end

function PANEL:OnSizeChanged( newW, newH )
	self.Icon:SetSize( newW, newH )
end

function PANEL:SetSpawnIcon( name )
	self.m_strIconName = name
	self.Icon:SetSpawnIcon( name )
end

function PANEL:SetBodyGroup( k, v )

	if ( k < 0 ) then return end
	if ( k > 9 ) then return end
	if ( v < 0 ) then return end
	if ( v > 9 ) then return end

	self.m_strBodyGroups = self.m_strBodyGroups:SetChar( k + 1, v )

end

function PANEL:SetModel( mdl, iSkin, BodyGroups )

	if ( !mdl ) then debug.Trace() return end

	self:SetModelName( mdl )
	self:SetSkinID( iSkin or 0 )

	if ( tostring( BodyGroups ):len() != 9 ) then
		BodyGroups = "000000000"
	end

	self.m_strBodyGroups = BodyGroups

	self.Icon:SetModel( mdl, iSkin, BodyGroups )

	if ( iSkin && iSkin > 0 ) then
		self:SetTooltip( Format( "%s (Skin %i)", mdl, iSkin + 1 ) )
	else
		self:SetTooltip( Format( "%s", mdl ) )
	end

end

function PANEL:RebuildSpawnIcon()

	self.Icon:RebuildSpawnIcon()

end

function PANEL:RebuildSpawnIconEx( t )

	self.Icon:RebuildSpawnIconEx( t )

end

function PANEL:ToTable( bigtable )

	local tab = {}

	tab.type = "model"
	tab.model = self:GetModelName()

	if ( self:GetSkinID() != 0 ) then
		tab.skin = self:GetSkinID()
	end

	if ( self:GetBodyGroup() != "000000000" ) then
		tab.body = "B" .. self:GetBodyGroup()
	end

	if ( self:GetWide() != 64 ) then
		tab.wide = self:GetWide()
	end

	if ( self:GetTall() != 64 ) then
		tab.tall = self:GetTall()
	end

	table.insert( bigtable, tab )

end

function PANEL:Copy()

	local copy = vgui.Create( "SpawnIcon", self:GetParent() )
	copy:SetModel( self:GetModelName(), self:GetSkinID() )
	copy:CopyBase( self )
	copy.DoClick = self.DoClick
	copy.OpenMenu = self.OpenMenu

	return copy

end

-- Icon has been editied, they changed the skin
-- what should we do?
function PANEL:SkinChanged( i )

	-- Change the skin, and change the model
	-- this way we can edit the spawnmenu....
	self:SetSkinID( i )
	self:SetModel( self:GetModelName(), self:GetSkinID(), self:GetBodyGroup() )

end

function PANEL:BodyGroupChanged( k, v )

	self:SetBodyGroup( k, v )
	self:SetModel( self:GetModelName(), self:GetSkinID(), self:GetBodyGroup() )

end

vgui.Register( "SpawnIcon", PANEL, "DButton" )

--
-- Action on creating a model from the spawnlist
--

spawnmenu.AddContentType( "model", function( container, obj )

	local icon = vgui.Create( "SpawnIcon", container )

	if ( obj.body ) then
		obj.body = string.Trim( tostring(obj.body), "B" )
	end

	if ( obj.wide ) then
		icon:SetWide( obj.wide )
	end

	if ( obj.tall ) then
		icon:SetTall( obj.tall )
	end

	icon:InvalidateLayout( true )

	icon:SetModel( obj.model, obj.skin or 0, obj.body )

	icon:SetTooltip( string.Replace( string.GetFileFromFilename( obj.model ), ".mdl", "" ) )

	icon.DoClick = function( s ) surface.PlaySound( "ui/buttonclickrelease.wav") RunConsoleCommand( "gm_spawn", s:GetModelName(), s:GetSkinID() or 0, s:GetBodyGroup() or "" ) end
	icon.OpenMenu = function( icon )

		local menu = DermaMenu()
		menu:AddOption( "#spawnmenu.menu.copy", function() SetClipboardText( string.gsub( obj.model, "\\", "/" ) ) end ):SetIcon( "icon16/page_copy.png" )
		menu:AddOption( "#spawnmenu.menu.spawn_with_toolgun", function() RunConsoleCommand( "gmod_tool", "creator" ) RunConsoleCommand( "creator_type", "4" ) RunConsoleCommand( "creator_name", obj.model ) end ):SetIcon( "icon16/brick_add.png" )

		local submenu, submenu_opt = menu:AddSubMenu( "Re-Render", function() icon:RebuildSpawnIcon() end )
		submenu_opt:SetIcon( "icon16/picture_save.png" )
		submenu:AddOption( "This Icon", function() icon:RebuildSpawnIcon() end ):SetIcon( "icon16/picture.png" )
		submenu:AddOption( "All Icons", function() container:RebuildAll() end ):SetIcon( "icon16/pictures.png" )

		menu:AddOption( "Edit Icon", function()

			local editor = vgui.Create( "IconEditor" )
			editor:SetIcon( icon )
			editor:Refresh()
			editor:MakePopup()
			editor:Center()

		end ):SetIcon( "icon16/pencil.png" )

		local ChangeIconSize = function( w, h )

			icon:SetSize( w, h )
			icon:InvalidateLayout( true )
			container:OnModified()
			container:Layout()
			icon:SetModel( obj.model, obj.skin or 0, obj.body )

		end

		local submenu_r, submenu_r_option = menu:AddSubMenu( "Resize", function() end )
		submenu_r_option:SetIcon( "icon16/arrow_out.png" )

		submenu_r:AddOption( "64 x 64 (default)", function() ChangeIconSize( 64, 64 ) end )
		submenu_r:AddOption( "64 x 128", function() ChangeIconSize( 64, 128 ) end )
		submenu_r:AddOption( "64 x 256", function() ChangeIconSize( 64, 256 ) end )
		submenu_r:AddOption( "64 x 512", function() ChangeIconSize( 64, 512 ) end )
		submenu_r:AddSpacer()
		submenu_r:AddOption( "128 x 64", function() ChangeIconSize( 128, 64 ) end )
		submenu_r:AddOption( "128 x 128", function() ChangeIconSize( 128, 128 ) end )
		submenu_r:AddOption( "128 x 256", function() ChangeIconSize( 128, 256 ) end )
		submenu_r:AddOption( "128 x 512", function() ChangeIconSize( 128, 512 ) end )
		submenu_r:AddSpacer()
		submenu_r:AddOption( "256 x 64", function() ChangeIconSize( 256, 64 ) end )
		submenu_r:AddOption( "256 x 128", function() ChangeIconSize( 256, 128 ) end )
		submenu_r:AddOption( "256 x 256", function() ChangeIconSize( 256, 256 ) end )
		submenu_r:AddOption( "256 x 512", function() ChangeIconSize( 256, 512 ) end )
		submenu_r:AddSpacer()
		submenu_r:AddOption( "512 x 64", function() ChangeIconSize( 512, 64 ) end )
		submenu_r:AddOption( "512 x 128", function() ChangeIconSize( 512, 128 ) end )
		submenu_r:AddOption( "512 x 256", function() ChangeIconSize( 512, 256 ) end )
		submenu_r:AddOption( "512 x 512", function() ChangeIconSize( 512, 512 ) end )

		menu:AddSpacer()
		menu:AddOption( "#spawnmenu.menu.delete", function() icon:Remove() hook.Run( "SpawnlistContentChanged" ) end ):SetIcon( "icon16/bin_closed.png" )
		menu:Open()

	end

	icon:InvalidateLayout( true )

	if ( IsValid( container ) ) then
		container:Add( icon )
	end

/*
	if ( iSkin != 0 ) then return end

	local iSkinCount = NumModelSkins( strModel )
	if ( iSkinCount <= 1 ) then return end

	for i=1, iSkinCount-1, 1 do

		self:AddModel( strModel, i )

	end
*/

	return icon

end )
