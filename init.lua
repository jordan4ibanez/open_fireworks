 --PROJECT GOALS
 --[[
 List of individual goals
 
fireworks launcher
fireworks cart launcher

fireworks go out in water

if you throw fireworks in fire group they ignite

works with open ai and open vehicles

 ]]--

--global to enable other mods/packs to utilize the ai
open_fireworks = {}


open_fireworks.register_fireworks = function(name,def)
	minetest.register_entity("open_fireworks:"..name, {
		--Do simpler definition variables for ease of use
		fireworks    = true,
		name         = "open_fireworks:"..name,
		collisionbox = {-0.25,-0.25,-0.25,0.25,0.25,0.25},
		physical     = true,
		collide_with_objects = false,
		
		--constants
		exist_time = 0, --how long a firework has existed
		yaw        = 0,
		acceleration = 5,
		
		
		--defined variables
		thrust = def.thrust,
		timer  = def.timer,
		spiral = def.spiral,
		spiral_force = def.spiral_force,
		spiral_width = def.spiral_width,
		explosion_particles = def.explosion_particles,
		explosion_radius = def.explosion_radius,
		
		--defined sounds
		boom_noise = def.boom_noise,
		launch_noise = def.launch_noise,
		
		--what fireworks do when created
		on_activate = function(self, staticdata, dtime_s)
			--immortal
			self.object:set_armor_groups({immortal = 1})
			
			--play the launch noise
			minetest.sound_play(self.launch_noise, {
				max_hear_distance = 100,
				gain = 10.0,
				object = self.object,
			})
		
			--set up the spiral force 
			if self.spiral == true and self.spiral_force > 0 then
				self.velocity = self.spiral_force
				self.spiraling = true
			else
				self.velocity = 0
			end
		
			if self.user_defined_on_activate then
				self.user_defined_on_activate(self, staticdata, dtime_s)
			end		
		end,
		--user defined function
		user_defined_on_activate = def.on_activate,
		
		--when the fireworks entity is deactivated
		get_staticdata = function(self)
			
		end,


		
		--how the fireworks collide with mobs and players
		collision = function(self)
			local pos = self.object:getpos()
			local vel = self.object:getvelocity()
			local x   = 0
			local z   = 0
			for _,object in ipairs(minetest.env:get_objects_inside_radius(pos, 1)) do
				--only collide with mobs and players
							
				--add exception if a nil entity exists around it
				if object:is_player() or (object:get_luaentity() and object:get_luaentity().mob == true and object ~= self.object) then
					local pos2 = object:getpos()
					local vec  = {x=pos.x-pos2.x, z=pos.z-pos2.z}
					--+0.5 to add player's collisionbox, could be modified to get other mobs widths
					local force = (1) - vector.distance({x=pos.x,y=0,z=pos.z}, {x=pos2.x,y=0,z=pos2.z})--don't use y to get verticle distance
										
					--modify existing value to magnetize away from mulitiple entities/players
					x = x + (vec.x * force) * 20
					z = z + (vec.z * force) * 20
				end
			end
			return({x,z})
		end,
		-- how a fireworks move around the world
		movement = function(self)
			--spiral
			if self.spiraling == true then
				self.firework_spiral(self)
			end
			
			local collide_values = self.collision(self)
			local c_x = collide_values[1]
			local c_z = collide_values[2]
			

			--move fireworks to goal velocity using acceleration for smoothness
			local vel = self.object:getvelocity()
			local x   = math.sin(self.yaw) * -self.velocity
			local z   = math.cos(self.yaw) *  self.velocity
			
			--allow fireworks to fall back down when they go out
			local gravity = -10
			
			--push firework up unless no thrust
			if self.thrust > 0 then
				gravity = self.thrust
			end
	
			if gravity == -10 then
				self.object:setacceleration({x=(x - vel.x + c_x)*self.acceleration,y=-10,z=(z - vel.z + c_z)*self.acceleration})				
			else
				self.object:setacceleration({x=(x - vel.x + c_x)*self.acceleration,y=(gravity-vel.y)*self.acceleration,z=(z - vel.z + c_z)*self.acceleration})
			end
				

		end,
		--how a firework spirals
		firework_spiral = function(self)
			self.yaw = self.yaw + self.spiral_width
			
			--prevent the yaw from becoming a rediculous intiger
			if self.yaw > math.pi*2 then
				self.yaw = self.yaw - (math.pi*2)
			end
		end,
		
		--the timer for fireworks to explode
		explode_timer = function(self,dtime)
			self.exist_time = self.exist_time + dtime
			if self.exist_time >= self.timer then --if it's at or past the timer the user defined, run explosion
				self.explode(self)
			end
		end,
		
		--the explosion
		explode = function(self)
			local pos = self.object:getpos()
			minetest.add_particlespawner({
				amount = self.explosion_particles,
				time = 0.01,
				minpos = pos,
				maxpos = pos,
				minvel = {x=-self.explosion_radius, y=-self.explosion_radius, z=-self.explosion_radius},
				maxvel = {x=self.explosion_radius, y=self.explosion_radius, z=self.explosion_radius},
				minacc = {x=0, y=0, z=0},
				maxacc = {x=0, y=0, z=0},
				minexptime = 3,
				maxexptime = 4,
				minsize = 1,
				maxsize = 2,
				collisiondetection = false,
				vertical = false,
				texture = "open_fireworks_particle.png",
			})
			minetest.sound_play(self.boom_noise, {
				pos = pos,
				max_hear_distance = 100,
				gain = 10.0,
			})
			self.object:remove()
		end,
		
			
		
		--what fireworks do on each server step
		on_step = function(self,dtime)
		
			self.movement(self)
			if self.user_defined_on_step then
				self.user_defined_on_step(self,dtime)
			end
			
			self.explode_timer(self,dtime)
		end,
		
		--a function that users can define
		user_defined_on_step = def.on_step,	
	})
	
end

open_fireworks.register_fireworks("red",{
	thrust = 10,--how much thrust a firework has
	timer  = 3,--how much time before the fireworks explode
	
	launch_noise = "tnt_ignite",--the noise a firework makes on launch
	boom_noise  = "tnt_explode",--the noise a firework makes on explode
	
	explosion_particles = 160, --how many particles there is in the explosion
	explosion_radius    = 8, --how big the explosion is
	
	spiral = false, --if a firework twirls in a spiral
	spiral_force = 30, --how fast the fireworks fly in a spiral
	spiral_width = 0.1, --how wide the spiral is
})

