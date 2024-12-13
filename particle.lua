Particle = {}
Particle.__index = Particle

function Particle:create(position)
    local particle = {}
    setmetatable(particle, Particle)
    particle.position = position
    particle.acceleration = Vector:create(0, 0)
    particle.velocity = Vector:create(math.random(-400, 400) / 100, math.random(-1000, -600) / 100)
    particle.maxlife = 200
    particle.lifespan = math.random(50, particle.maxlife)
    particle.texture = love.graphics.newImage("assets/light.png")
    return particle
end

function Particle:update()
    self.velocity:add(self.acceleration)
    self.position:add(self.velocity)
    self.lifespan = self.lifespan - 1
end

function Particle:applyForce(force)
    self.acceleration:add(force)
end

function Particle:draw(red, green, blue)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(red, green, blue, self.lifespan / self.maxlife)
    love.graphics.draw(self.texture, self.position.x, self.position.y)
    love.graphics.setColor(r, g, b, a)
end

function Particle:isDead()
    if self.lifespan <= 0 then
        return true
    end
    return false
end

ParticleSystem = {}
ParticleSystem.__index = ParticleSystem

function ParticleSystem:create(origin, n, cls)
    local system = {}
    setmetatable(system, ParticleSystem)
    system.origin = origin
    system.n = n or 10
    system.index = 1
    system.cls = cls or Particle
    system.particles = {}
    return system
end

function ParticleSystem:createParticle()
    return self.cls:create(self.origin:copy())
end

function ParticleSystem:update()
    if #self.particles < self.n then
        self.particles[self.index] = self:createParticle()
        self.index = self.index + 1
    end
    for k, v in pairs(self.particles) do
        if v:isDead() then
            self.particles[k] = self:createParticle()
        end
        v:update()
    end
end

function ParticleSystem:final_update()
    for k, v in pairs(self.particles) do
        v:update()
    end
end

function ParticleSystem:applyForce(force)
    for k, v in pairs(self.particles) do
        v:applyForce(force)
    end
end

function ParticleSystem:draw(red, green, blue)
    for k, v in pairs(self.particles) do
        v:draw(red, green, blue)
    end
end