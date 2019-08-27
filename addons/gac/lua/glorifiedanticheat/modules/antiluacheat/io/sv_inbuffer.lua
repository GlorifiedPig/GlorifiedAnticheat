--[[
    https://github.com/notcake/glib/blob/master/lua/glib/io/inbuffer.lua
    Cake's io.inbuffer (converted to not use constuctor)
]]
local string_char = string.char

function gAC.InBuffer()
	local self = {
		Position = 1
	}

	-- Position
	function self:GetBytesRemaining ()
		Error ("InBuffer:GetBytesRemaining : Not implemented.")
	end

	function self:GetPosition ()
		return self.Position
	end

	function self:GetSize ()
		Error ("InBuffer:GetSize : Not implemented.")
	end

	function self:IsEndOfStream ()
		Error ("InBuffer:IsEndOfStream : Not implemented.")
	end

	function self:Pin ()
		Error ("InBuffer:Pin : Not implemented.")
	end

	function self:SeekRelative (relativeSeekPos)
		Error ("InBuffer:SeekRelative : Not implemented.")
	end

	function self:SeekAbsolute (seekPos)
		Error ("InBuffer:SeekAbsolute : Not implemented.")
	end

	function self:UInt8 ()
		Error ("InBuffer:UInt8 : Not implemented.")
	end

	function self:UInt16 ()
		local low  = self:UInt8 ()
		local high = self:UInt8 ()
		return high * 0x0100 + low
	end

	function self:UInt32 ()
		local low  = self:UInt16 ()
		local high = self:UInt16 ()
		return high * 0x00010000 + low
	end

	function self:UInt64 ()
		local low  = self:UInt32 ()
		local high = self:UInt32 ()
		return high * 4294967296 + low
	end

	function self:ULEB128 ()
		local n = 0
		local factor = 1
		
		local done = false
		repeat
			local byte = self:UInt8 ()
			if byte >= 0x80 then
				byte = byte - 0x80
			else
				done = true
			end
			
			n = n + byte * factor
			factor = factor * 128
		until done
		
		return n
	end

	function self:Int8 ()
		Error ("InBuffer:Int8 : Not implemented.")
	end

	function self:Int16 ()
		local low  = self:UInt8 ()
		local high = self:Int8 ()
		return high * 0x0100 + low
	end

	function self:Int32 ()
		local low  = self:UInt16 ()
		local high = self:Int16 ()
		return high * 0x00010000 + low
	end

	function self:Int64 ()
		local low  = self:UInt32 ()
		local high = self:Int32 ()
		return high * 4294967296 + low
	end

	function self:Float ()
		local n = self:UInt32 ()
		return gAC.BitConverter.UInt32ToFloat (n)
	end

	function self:Double ()
		local low  = self:UInt32 ()
		local high = self:UInt32 ()
		return gAC.BitConverter.UInt32sToDouble (low, high)
	end

	function self:Vector ()
		local x = self:Float ()
		local y = self:Float ()
		local z = self:Float ()
		return Vector (x, y, z)
	end

	function self:Bytes (length)
		local data = ""
		for i = 1, length do
			data = data .. string_char (self:UInt8 ())
		end
		
		return data
	end

	function self:String ()
		Error ("InBuffer:String : Not implemented.")
	end

	function self:StringN8 ()
		local length = self:UInt8 ()
		return self:Bytes (length)
	end

	function self:StringN16 ()
		local length = self:UInt16 ()
		return self:Bytes (length)
	end

	function self:StringN32 ()
		local length = self:UInt32 ()
		return self:Bytes (length)
	end

	function self:StringZ ()
		local data = ""
		local c = self:UInt8 ()
		while c and c ~= 0 do
			if #data > 65536 then
				Error ("InBuffer:StringZ : String is too long, infinite loop?")
				break
			end
			
			data = data .. string_char (c)
			c = self:UInt8 ()
		end
		
		return data
	end

	function self:LongString ()
		Error ("InBuffer:LongString : Not implemented.")
	end

	function self:Boolean ()
		return self:UInt8 () ~= 0
	end
	return self
end