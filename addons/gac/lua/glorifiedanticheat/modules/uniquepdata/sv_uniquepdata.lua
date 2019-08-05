local _FindMetaTable = FindMetaTable
local _Format = Format
local _sql_Query = sql.Query
local _sql_QueryValue = sql.QueryValue
local _SQLStr = SQLStr

local plyMeta = _FindMetaTable( "Player" )

if( !plyMeta ) then return end

if ( !sql.TableExists( "playerupdata" ) ) then
	_sql_Query( "CREATE TABLE IF NOT EXISTS playerupdata ( infoid TEXT NOT NULL PRIMARY KEY, value TEXT );" )
end

function plyMeta:SetUPDataGAC( name, value )
	name = _Format( "%s[%s]", self:SteamID64(), name )
    _sql_Query( "REPLACE INTO playerupdata ( infoid, value ) VALUES ( " .. _SQLStr( name ) .. ", " .. _SQLStr( value ) .. " )" )
end

function plyMeta:GetUPDataGAC( name, default )
	name = _Format( "%s[%s]", self:SteamID64(), name )
    local val = _sql_QueryValue( "SELECT value FROM playerupdata WHERE infoid = " .. _SQLStr( name ) .. " LIMIT 1" )
	if ( val == nil ) then return default end

	return val
end

function GetUPDataGACSID64( name, steamId, default )
	name = _Format( "%s[%s]", steamId, name )
    local val = _sql_QueryValue( "SELECT value FROM playerupdata WHERE infoid = " .. _SQLStr( name ) .. " LIMIT 1" )
	if ( val == nil ) then return default end

	return val
end