
local plyMeta = FindMetaTable( "Player" )

if( !plyMeta ) then return end

if ( !sql.TableExists( "playerupdata" ) ) then
	sql.Query( "CREATE TABLE IF NOT EXISTS playerupdata ( infoid TEXT NOT NULL PRIMARY KEY, value TEXT );" )
end

function plyMeta:SetUPDataGAC( name, value )
	name = Format( "%s[%s]", self:SteamID64(), name )
    sql.Query( "REPLACE INTO playerupdata ( infoid, value ) VALUES ( " .. SQLStr( name ) .. ", " .. SQLStr( value ) .. " )" )
end

function plyMeta:GetUPDataGAC( name, default )
	name = Format( "%s[%s]", self:SteamID64(), name )
    local val = sql.QueryValue( "SELECT value FROM playerupdata WHERE infoid = " .. SQLStr( name ) .. " LIMIT 1" )
	if ( val == nil ) then return default end

	return val
end

function GetUPDataGACSID64( name, steamId, default )
	name = Format( "%s[%s]", steamId, name )
    local val = sql.QueryValue( "SELECT value FROM playerupdata WHERE infoid = " .. SQLStr( name ) .. " LIMIT 1" )
	if ( val == nil ) then return default end

	return val
end