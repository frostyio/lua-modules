-- frosty
-- 09 - 01 - 2020

local string_pack = {_version = "1"};

-- used for special parsing
local special = ("27"):char();
-- unsortable item holder
local unsortable = special .. "NONSTRING";
-- number key holder
local number_key = special .. "NUMBERKEY";

-- json stuff

local HttpService = game:GetService("HttpService");

local json = {
	encode = function(str) return HttpService:JSONEncode(str) end,
	decode = function(str) return HttpService:JSONDecode(str) end
};

-- util stuff

local util = {};
do
	function util.index_all(self, index_func)
		local tbl = {};
		for key, value in pairs(self) do
			self[key] = nil;
			if type(value) == "table" then
				local k = index_func(key, value);
				tbl[k] = util.index_all(value, index_func);
			else
				local k, v = index_func(key, value);
				tbl[k] = v;
			end
		end
		return tbl;
	end
end

-- gets the items that cannot be encrypted as a string
local allowed_types = {
	"string", "number", "boolean", "nil", "table"
};
local function get_non_stringable(arguments)
	local non_stringable = {};
	
	local stringable = util.index_all(arguments, function(key, value)
		local type1, type2 = typeof(key), typeof(value);
		
		local is_good1, is_good2 = table.find(allowed_types, type1),
		table.find(allowed_types, type2);
		
		local return_key, return_value = key, value;
		
		if not is_good1 then
			return_key = unsortable;	
			table.insert(non_stringable, key);
		end
		if not is_good2 then
			return_value = unsortable;
			table.insert(non_stringable, value);
		end
		
		--return return_key, return_value;
		
		if type(return_key) == "number" and return_key ~= unsortable then
			return tostring(return_key), {return_value, number_key};
		end
		
		return return_key, return_value;
	end);
	
	return stringable, non_stringable;
end

-- packs the arguments into a single string
local function pack_string(arguments)
	local stringable, non_stringable = get_non_stringable(arguments);
	
	return json.encode(stringable), non_stringable;
end

-- unpack the string into the correct table
local function unpack_string(stringable_json, non_stringable)
	local stringable = json.decode(stringable_json);
	
	local recursive_unpack; function recursive_unpack(stringable)
		local new_table = {};
		
		for a, b in pairs(stringable) do
			-- convert keys that use to be numbers back into numbers		
			if type(b) == "table" and b[2] == number_key then
				a, b = tonumber(a), b[1];
			end
			
			-- get non-stringable item from table
			if a == unsortable then
				a = table.remove(non_stringable, 1);
			end
			if b == unsortable then
				b = table.remove(non_stringable, 1);
			end
			
			-- check through nested tables
			if type(a) == "table" then
				a = recursive_unpack(a);
			end
			if type(b) == "table" then
				b = recursive_unpack(b);
			end
			
			-- assign in new table
			new_table[a] = b;
		end
		
		return new_table;
	end
	
	return recursive_unpack(stringable);
end

string_pack.pack = pack_string;
string_pack.unpack = unpack_string;

return string_pack;
