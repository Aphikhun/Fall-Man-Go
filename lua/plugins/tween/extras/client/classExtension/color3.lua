local Color3 = Color3

local function new(r, g, b)
    r = math.min(math.max(r, 0), 1)
    g = math.min(math.max(g, 0), 1)
    b = math.min(math.max(b, 0), 1)
    return Color3.new(r, g, b)
end

local function calc(left, right, operator)
    if type(left) == "number" then
        return new(operator(left, right.r), operator(left, right.g), operator(left, right.b))
    elseif type(right) == "number" then
        return new(operator(left.r, right), operator(left.g, right), operator(left.b, right))
    else
        return new(operator(left.r, right.r), operator(left.g, right.g), operator(left.b, right.b))
    end
end

function Color3.__add(left, right)
    return calc(left, right, function(l, r)
        return l + r
    end)
end

function Color3.__sub(left, right)
    return calc(left, right, function(l, r)
        return l - r
    end)
end

function Color3.__mul(left, right)
    return calc(left, right, function(l, r)
        return l * r
    end)
end

function Color3.__div(left, right)
    return calc(left, right, function(l, r)
        return l / r
    end)
end

function Color3.__unm(self)
    return self * -1
end