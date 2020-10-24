local create, new;
do
	local classes, class_children = {}, {};
	
	local classModel = {
		is = function(self, class)
			return class_children[self] == class or false;
		end
	};
	classModel.__index = classModel;
	
	function create(class)
	    return function(data)
			if type(data.private) ~= "table" then return error("'private' has to be a table", 2) end;
			if type(data.public) ~= "table" then return error("'public' has to be a table", 2) end;
			
			data.public = setmetatable(data.public, classModel);
	
			data.private.__index = data.private;
			data.public.__index = data.public;
			data.public.__tostring = function() return class end;
			data.public.__metatable = function() return "Cannot edit " .. class end;
	        local this = {constructor = data.constructor, private = data.private, public = data.public};
	
	        classes[class] = this;
	    end
	end
	function new(class)
	    local parent = assert(classes[class], "Invalid class");
	    local public = setmetatable({}, parent.public);
		local self = {private = setmetatable({}, class.private), public = public};
		class_children[public] = class;
	    
	    if parent.constructor then
	        return function(...)
				parent.constructor(self, ...);
				return public;
	        end
	    end
	
	    return public;
	end

end

create("Vector"){
    constructor = function(self, x, y, z)
        self.private.x = x;
        self.private.y = y;
		self.private.z = z;
    end,
    private = {
        x = 0, y = 0, z = 0
    },
    public = {
       h = "hi"
    }
}

local vec = new("Vector")(5, 10, 0);
print(vec:is("Vector"));

return create;
