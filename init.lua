-- http://lua-users.org/wiki/SimpleRound
local function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

local Shutter = {}

function Shutter.new(image, x, y, width, height, frames, xmargin, ymargin, vertical)
  local t = {}
  t.frames = {}
  t.frame = 1

  if image then
    assert(type(x) == "number", "bad argument #1 to 'new' (number expected, got " .. type(x) .. ")")
    assert(type(y) == "number", "bad argument #2 to 'new' (number expected, got " .. type(y) .. ")")
    assert(type(width) == "number", "bad argument #3 to 'new' (number expected, got " .. type(width) .. ")")
    assert(type(height) == "number", "bad argument #4 to 'new' (number expected, got " .. type(height) .. ")")
    assert(frames == nil or type(frames) == "number", "bad argument #5 to 'new' (number expected, got " .. type(frames) .. ")")
    assert(delay == nil or type(delay) == "number", "bad argument #6 to 'new' (number expected, got " .. type(delay) .. ")")
    assert(margin == nil or type(margin) == "number", "bad argument #7 to 'new' (number expected, got " .. type(margin) .. ")")
    vertical = vertical and true

    local imgw = image:getWidth()
    local imgh = image:getHeight()

    local i = 1
    for f=1, frames do
      local j = f - (((vertical and imgh or imgw)/(vertical and height or width)) * i)
      if x + ((j * (vertical and height or width))) + ((j - 1) * (vertical and ymargin or xmargin)) > (vertical and imgh or imgw) then
        i = i + 1
        j = 1
        x = 0
      end

      local fx = (vertical and (i * width) + ((i - 1) * xmargin) or (j * width) + ((j - 1) * xmargin))
      local fy = (vertical and (j * height) + ((j - 1) * ymargin) or (i * height) + ((i - 1) * ymargin))
      Shutter.addFrame(t, {
        drawable = image,
        quad = love.graphics.newQuad(fx, fy, width, height, imgw, imgh)
      })
    end
  end
  return setmetatable(t, { __index = Shutter }
end

function Shutter:addFrame(frame)
  if type(frame) == "userdata" then
    assert(frame:typeOf("Drawable"), "bad argument #1 to 'addFrame' (drawable, table, or function expected, got " .. frame:type() .. ")")
  elseif type(frame) == "table" then
    assert(frame.drawable, "bad drawable in frame")
    assert(frame.quad == nil or type(frame.quad) == "userdata" and frame.quad:typeOf("Quad"), "bad quad in frame")
  else
    assert(type(frame) == "function", "bad argument #1 to 'addFrame' (drawable, table, or function expected, got " .. type(frame) .. ")")
  end
  table.insert(self.frames, frame)
end

function Shutter:advance(speed)
  speed = speed or 1

  assert(type(speed) == "number", "bad argument #1 to 'advance' (number expected, got " .. type(speed) .. ")")
  self.frame = self.frame + speed
end

function Shutter:getFrame()
  return self.frames[round(self.frame)]
end

function Shutter:getFrameIndex()
  return round(self.frame)
end

function Shutter:setFrameIndex(index)
  assert(type(index) == "number", "bad argument #1 to 'setFrameIndex' (number expected, got " .. type(index) .. ")")
  self.frame = index
end

function Shutter:getFrameCount()
  return #self.frames
end

function Shutter:draw(x, y, r, sx, sy, ox, oy, kx, ky)
  local frame = self:getFrame()
  local t = type(frame)
  if t == "userdata" then
    love.graphics.draw(frame, x, y, r, sx, sy, ox, oy, kx, ky)
  elseif t == "table" then
    if t.quad then
      love.graphics.draw(frame.drawable, frame.quad, x, y, r, sx, sy, ox, oy, kx, ky)
    else
      love.graphics.draw(frame.drawable, x, y, r, sx, sy, ox, oy, kx, ky)
    end
  elseif t == "function" then
    frame(self:getFrameIndex(), x, y, r, sx, sy, ox, oy, kx, ky)
  else
    error("invalid frame")
  end
end

return setmetatable(Shutter, { __call = Shutter.new }))
