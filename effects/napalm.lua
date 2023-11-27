local function GetPloomPos(pos)
	return {
	  air                = true,
	  class              = [[CExpGenSpawner]],
	  count              = 1,
	  ground             = true,
	  water              = true,
	  properties = {
		delay              = [[0]],
		explosiongenerator = [[custom:napalmfireball_480_small]],
		pos                = pos,
	  },
	}
end

local function GeneratePositionInSphere(radius, exponent)
	return table.concat ({
		-- #0 RADIUS: radius - rand(radius^(1/exponent))^exponent
		"r" .. tostring(radius ^ (1 / exponent)) .. " p" .. exponent .. " y0 -1 x0 " .. radius .. " y0",

		-- #1 ANGLE (theta): rand(tau) - pi
		"r" .. math.tau .. " " .. (- math.pi) .. " y1",

		-- #2 "A": rand(1)
		"r1 y2",

		-- #3 XZMULT = sin(phi) = sin(2 * arcsin(sqrt(A))) = 2*sqrt(1 - A) * sqrt(A) = sqrt(1-A) * sqrt(4A)
		"-1 x2 1 p0.5 y3 4 x2 p0.5 x3 y3",

		-- X = cos(ANGLE) * RADIUS * XZMULT
		-- cos(ANGLE) = sin(ANGLE + pi/2)
		"a1 " .. (math.pi / 2) .. " s1 x0 x3,",

		-- Y = (2A - 1) * RADIUS
		"2 x2 -1 x0,",

		-- Z = sin(ANGLE) * RADIUS * XZMULT
		"a1 s1 x0 x3"
	}, ' ')
end

local function GeneratePositionInCircle(radius, exponent, height)
	return table.concat ({
		-- #0 RADIUS: radius - rand(radius^(1/exponent))^exponent
		"r" .. tostring(radius ^ (1 / exponent)) .. " p" .. exponent .. " y0 -1 x0 " .. radius .. " y0",

		-- #1 ANGLE: rand(tau) - pi
		"r" .. math.tau .. " " .. (- math.pi) .. " y1",

		-- X: cos(ANGLE) * RADIUS
		-- cos(ANGLE) == sin(ANGLE + pi/2)
		"a1 " .. (math.pi / 2) .. " s1 x0,",

		-- Y: height
		height .. ",",

		-- Z: sin(ANGLE) * RADIUS
		"a1 s1 x0"
	}, ' ')
end

local function GenerateEmitVector()
	return table.concat ({
		-- #0: ANGLE: rand(tau) - pi
		"r" .. math.tau .. " " .. (- math.pi) .. " y0",

		-- #1 "A": rand(1)
		"r1 y1",

		-- #2 XZMULT = sin(phi) = sin(2 * arcsin(sqrt(A))) = 2*sqrt(1 - A) * sqrt(A) = sqrt(1-A) * sqrt(4A)
		"-1 x1 1 p0.5 y2 4 x1 p0.5 x2 y2",

		-- X = cos(ANGLE) * XZMULT
		-- cos(ANGLE) = sin(ANGLE + pi/2)
		"a0 " .. (math.pi / 2) .. " s1 x2,",

		-- Y = 2A - 1
		"2 x2 -1,",

		-- Z = sin(ANGLE) * XZMULT
		"a0 s1 x2"
	}, ' ')
end

local cegs = {
  ["napalm_phoenix"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 1,
      flashsize          = 108,
      ttl                = 75,
      color = {
        [1]  = 0.7,
        [2]  = 0.3,
        [3]  = 0.1,
      },
    },
    redploom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 6,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:NAPALMFIREBALL_75]],
        pos                = [[-20 r40, 30, -20 r40]],
      },
    },
  },
  ["napalm_koda"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 1,
      flashsize          = 120,
      ttl                = 480,
      color = {
        [1]  = 0.7,
        [2]  = 0.3,
        [3]  = 0.1,
      },
    },
    bigredploom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:napalmfireball_480_main]],
        pos                = [[0 0 0]],
      },
    },
    redploom_1 = GetPloomPos([[ 0 r10,  0 r10,  0 r10]]),
    redploom_2 = GetPloomPos([[ 42 r10,  35 r10,  0  r10]]),
    redploom_3 = GetPloomPos([[-42 r10,  35 r10,  0  r10]]),
    redploom_6 = GetPloomPos([[ 0  r10,  35 r10,  42 r10]]),
    redploom_7 = GetPloomPos([[ 0  r10,  35 r10, -42 r10]]),
  },
  ["napalm_pyro"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 1,
      flashsize          = 128,
      ttl                = 440,
      color = {
        [1]  = 0.7,
        [2]  = 0.3,
        [3]  = 0.1,
      },
    },
    redploom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 9,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 i40]],
        explosiongenerator = [[custom:NAPALMFIREBALL_200]],
        pos                = [[-35 r70, 30, -35 r70]],
      },
    },
  },
  ["napalm_koda_small_long"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 1,
      flashsize          = 32,
      ttl                = 440,
      color = {
        [1]  = 0.7,
        [2]  = 0.3,
        [3]  = 0.1,
      },
    },
    redploom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 8,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 i40]],
        explosiongenerator = [[custom:NAPALMFIREBALL_200]],
        pos                = [[-8 r16, 20, -8 16]],
      },
    },
  },
  ["napalm_infernal"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 1,
      flashsize          = 110,
      ttl                = 330,
      color = {
        [1]  = 0.7,
        [2]  = 0.3,
        [3]  = 0.1,
      },
    },
    redploom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 6,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 i40]],
        explosiongenerator = [[custom:NAPALMFIREBALL_200]],
        pos                = [[-30 r60, 30, -30 r60]],
      },
    },
  },
  ["napalm_missile"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 0.8,
      flashsize          = 512,
      ttl                = 1400,
      color = {
        [1]  = 0.7,
        [2]  = 0.3,
        [3]  = 0.1,
      },
    },
    redploom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 25,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:NAPALMFIREBALL_600]],
        pos                = GeneratePositionInCircle(200, 2, 30),
      },
    },
    redploom_long = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 200,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:NAPALMFIREBALL_1400]],
        pos                = GeneratePositionInSphere(200, 4),
      },
    },
  },

  ["napalm_drp"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 0.8,
      flashsize          = 640,
      ttl                = 450,
      color = {
        [1]  = 0.7,
        [2]  = 0.3,
        [3]  = 0.1,
      },
    },
    redploom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 25,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:NAPALMFIREBALL_200]],
        pos                = GeneratePositionInCircle(300, 2, 30),
      },
    },
    redploom_long = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 200,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:NAPALMFIREBALL_450]],
        pos                = GeneratePositionInSphere(300, 4),
      },
    },
  },

  ["napalm_firewalker"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 0.8,
      flashsize          = 256,
      ttl                = 500,
      color = {
        [1]  = 0.7,
        [2]  = 0.3,
        [3]  = 0.1,
      },
    },
    redploom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 10,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:NAPALMFIREBALL_200]],
        pos                = GeneratePositionInCircle(100, 2, 30),
      },
    },
    redploom_long = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 45,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:NAPALMFIREBALL_600]],
        pos                = GeneratePositionInSphere(100, 3),
      },
    },
  },

  ["napalm_firewalker_small"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 1,
      flashsize          = 64,
      ttl                = 480,
      color = {
        [1]  = 0.7,
        [2]  = 0.3,
        [3]  = 0.1,
      },
    },
    redploom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 8,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 i40]],
        explosiongenerator = [[custom:NAPALMFIREBALL_450]],
        pos                = [[-20 r40, 30, -20 r40]],
      },
    },
  },

  ["napalm_koda_small"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 1,
      flashsize          = 52,
      ttl                = 60,
      color = {
        [1]  = 0.7,
        [2]  = 0.3,
        [3]  = 0.1,
      },
    },
    redploom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 i10]],
        explosiongenerator = [[custom:NAPALMFIREBALL_45]],
        pos                = [[-10 r10, 25, -10 r10]],
      },
    },
  },

  ["napalm_gunshipbomb"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 1,
      flashsize          = 135,
      ttl                = 480,
      color = {
        [1]  = 0.7,
        [2]  = 0.3,
        [3]  = 0.1,
      },
    },
    bigredploom_short = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:napalmfireball_600_main_short]],
        pos                = [[0 12 0]],
      },
    },
    bigredploom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:napalmfireball_600_main]],
        pos                = [[0 12 0]],
      },
    },
    redploom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 2,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:napalmfireball_600_big]],
        pos                = [[0 12 0]],
      },
    },
  },

  ["napalm_hellfire"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 0.8,
      flashsize          = 256,
      ttl                = 500,
      color = {
        [1]  = 0.7,
        [2]  = 0.3,
        [3]  = 0.1,
      },
    },
    redploom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 10,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:NAPALMFIREBALL_600]],
        pos                = GeneratePositionInCircle(100, 2, 30),
      },
    },
    redploom_long = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 45,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:NAPALMFIREBALL_1400]],
        pos                = GeneratePositionInSphere(100, 3),
      },
    },
  },

  -- Fireball particles of various lifetimes
  ["napalmfireball_200"] = {
    rocks = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.97,
        colormap           = [[0 0 0 0.001   .6 .6 .6 0.03     .6 .6 .6 0.02    .6 .6 .6 0.02   0 0 0 0.01]],
        directional        = false,
        emitrot            = 60,
        emitrotspread      = 30,
        emitvector         = GenerateEmitVector(),
        gravity            = [[0.001 r-0.002, 0.001 r0.002, 0.001 r-0.002]],
        numparticles       = 2,
        particlelife       = 60,
        particlelifespread = 140,
        particlesize       = 30,
        particlesizespread = 10,
        particlespeed      = 0.5,
        particlespeedspread = 1.0,
        pos                = [[-10 r20, 0, -10 r20]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[fireball]],
      },
    },
  },
  -- A version of Sak's effect
  ["firewalker_impact"] = {
    usedefaultexplosions = false,
	redground = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 22,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 r20 i20]],
        explosiongenerator = [[custom:redground]],
        pos                = [[20 r-40, -100, 20 r-40]],
      },
    },
    redploom_long = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 50,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 i9]],
        explosiongenerator = [[custom:NAPALMFIREBALL_firewalker]],
        pos                = [[100 r-200, 5, 100 r-200]],
      },
    },
  },
  ["redground"] = {
      groundflash = {
      flashalpha         = 0.7,
      flashsize          = 200,
      ttl                = 100,
      color = {
        [1]  = 0.7,
        [2]  = 0.3,
        [3]  = 0.1,
      },
    },
  },
  ["napalmfireball_firewalker"] = {
    rocks = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.5,
        colormap           = [[0 0 0 0.01   .6 .6 .6 0.1     .6 .6 .6 0.1     0 0 0 0.01]],
        directional        = false,
        emitrot            = 90,
        emitrotspread      = 90,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0.001 r-0.002, 0.3 r0.6, 0.001 r-0.002]],
        numparticles       = 2,
        particlelife       = 50,	--minimum particle lifetime in frames
        particlelifespread = 50,	--max value of random lifetime added to each particle's lifetime
        particlesize       = 30,
        particlesizespread = 10,
        particlespeed      = 0.8,
        particlespeedspread = 1.2,
        pos                = [[10 r-20, 0, 10 r-20]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[fireball]],
      },
    },
  },
}

local altforms = {
   napalmfireball_60 = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
	properties = {particlelife = 50, particlelifespread = 20},
      },
    },
  },
  napalmfireball_75 = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
	properties = {particlelife = 25, particlelifespread = 50},
      },
    },
  },
  napalmfireball_450 = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
	properties = {particlelife = 150, particlelifespread = 300},
      },
    },
  },
  napalmfireball_45 = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
      properties = {
        particlelife = 35,
        particlelifespread = 12,
        particlesize       = 38,
        particlesizespread = 16,},
      },
    },
  },
  napalmfireball_450_long = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
	properties = {particlelife = 180, particlelifespread = 300},
      },
    },
  },
  napalmfireball_450_big = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
	    properties = {particlelife = 50, particlelifespread = 80, particlesize = 40, particlesizespread = 20,},
      },
    },
  },
  napalmfireball_600 = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
	properties = {particlelife = 200, particlelifespread = 400},
      },
    },
  },
  napalmfireball_600_main_short = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
		colormap   = [[0 0 0 0.002   .5 .5 .5 0.08     .5 .5 .5 0.06    .4 .4 .4 0.05   0 0 0 0.003]],
	    properties = {particlelife = 90, particlelifespread = 40, particlesize = 120, particlesizespread = 30,},
      },
    },
  },
  napalmfireball_600_main = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
		colormap   = [[0 0 0 0.002   .5 .5 .5 0.08     .5 .5 .5 0.06    .4 .4 .4 0.05   0 0 0 0.003]],
	    properties = {particlelife = 340, particlelifespread = 50, particlesize = 96, particlesizespread = 30,
        numparticles       = 1,},
      },
    },
  },
  napalmfireball_600_big = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
		colormap   = [[0 0 0 0.001   .3 .3 .3 0.01     .3 .3 .3 0.025    .2 .2 .2 0.018   0 0 0 0.001]],
	    properties = {particlelife = 585, particlelifespread = 165, particlesize = 92, particlesizespread = 30},
      },
    },
  },
  napalmfireball_480_main = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
		colormap   = [[0 0 0 0.002   .35 .35 .35 0.010     .25 .25 .25 0.08    .12 .12 .12 0.06   0 0 0 0.003]],
	    properties = {particlelife = 470, particlelifespread = 30, particlesize = 110, particlesizespread = 25,},
      },
    },
  },
  napalmfireball_480_small = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
		colormap   = [[0 0 0 0.001   .2 .2 .2 0.035     .2 .2 .2 0.025   .12 .12 .12 0.018   0 0 0 0.001]],
	    properties = {particlelife = 200, particlelifespread = 280, particlesize = 28, particlesizespread = 12,},
      },
    },
  },
  napalmfireball_750 = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
	properties = {particlelife = 250, particlelifespread = 500},
      },
    },
  },
  napalmfireball_840 = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
	properties = {particlelife = 280, particlelifespread = 560},
      },
    },
  },
  napalmfireball_1400 = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
		properties = {
		  airdrag            = 0.98,
		  colormap           = [[0 0 0 0.005   .6 .6 .6 0.015     .6 .6 .6 0.012    .6 .6 .6 0.010   0 0 0 0.005]],
		  particlelife       = 500,	--minimum particle lifetime in frames
		  particlelifespread = 900,	--max value of random lifetime added to each particle's lifetime
		  particlespeed      = 0.6,
		  particlespeedspread = 1.2,
		},
      }
    }
  },
  napalm_firewalker_long = {
    source = "napalm_firewalker",
    modifications = {
      redploom_long = {
	properties = {
	  explosiongenerator = [[custom:NAPALMFIREBALL_840]],
	},
      },
    },
  },
}

local suMergeTable = Spring.Utilities.MergeTable
for cegName, info in pairs(altforms) do
  cegs[cegName] = suMergeTable(info.modifications, cegs[info.source], true)
end

return cegs
