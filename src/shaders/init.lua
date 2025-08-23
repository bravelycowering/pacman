local crt = love.graphics.newShader("shaders/crt.glsl")
crt:send("distortionFactor", { 1.05, 1.05 })
crt:send("scaleFactor", { 1.05, 1.05 })
crt:send("feather", 0.1)
crt:send("featheropacity", 0.25)

return { crt }