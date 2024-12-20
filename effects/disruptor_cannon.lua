return {
	["disruptor_cannon_muzzle"] = {
		alwaysvisible        = false,
		usedefaultexplosions = false,
		shaft                = {
			air        = true,
			class      = [[CBitmapMuzzleFlame]],
			count      = 1,
			ground     = true,
			underwater = 1,
			water      = true,
			properties = {
				colormap     = [[0.9 0.7 0.9 0.01 0.5 0.1 0.8 0.01 0 0 0 0.01]],
				dir          = [[dir]],
				frontoffset  = 0,
				fronttexture = [[muzzlefront]],
				length       = 24,
				sidetexture  = [[muzzleside]],
				size         = 16,
				sizegrowth   = -0.5,
				ttl          = 16,
			},
		},
	},
	["disruptortrail"]          = {
		alwaysvisible        = false,
		usedefaultexplosions = false,
		head                 = {
			class      = [[CSimpleParticleSystem]],
			count      = 1,
			ground     = true,
			air        = true,
			unit       = true,
			water      = true,
			underwater = true,
			properties = {
				airdrag             = 0.99,
				alwaysvisible       = false,
				colormap            = [[1 1 1 0.05   0.01 0.005 0.02 0.01]],
				directional         = true,
				emitrotspread       = 0,
				emitvector          = [[dir]],
				gravity             = [[0 0 0]];
				numparticles        = 3,
				particlelife        = 3,
				particlelifespread  = 0,
				particlesize        = 10,
				particlesizespread  = 1,
				particlespeed       = 0.9,
				particlespeedspread = 0.02,
				pos                 = [[0 0 0]],
				sizegrowth          = 0,
				sizemod             = 0.7,
				texture             = [[pinknovaexplo]],
			},
		},
		shaft                = {
			air        = true,
			class      = [[CBitmapMuzzleFlame]],
			count      = 1,
			ground     = true,
			underwater = 1,
			water      = true,
			properties = {
				colormap     = [[0.9 0.5 0.9 0.01 0.5 0.1 0.8 0.01 0 0 0 0.01]],
				dir          = [[dir]],
				frontoffset  = 0,
				fronttexture = [[null]],
				length       = -3,
				sidetexture  = [[plasma3]],
				size         = 6,
				sizegrowth   = -0.3,
				ttl          = 6,
			},
		},
		shaftFront             = {
			air        = true,
			class      = [[CBitmapMuzzleFlame]],
			count      = 1,
			ground     = true,
			underwater = 1,
			water      = true,
			properties = {
				colormap     = [[0.9 0.5 0.9 0.01 0.5 0.1 0.8 0.01 0 0 0 0.01]],
				dir          = [[dir]],
				frontoffset  = 0,
				fronttexture = [[null]],
				length       = 1.4,
				sidetexture  = [[plasma3]],
				size         = 6,
				sizegrowth   = -0.3,
				ttl          = 6,
			},
		},
		sparks               = {
			class      = [[CSimpleParticleSystem]],
			count      = 1,
			ground     = true,
			air        = true,
			unit       = true,
			water      = true,
			underwater = true,
			properties = {
				airdrag             = 0.7,
				alwaysvisible       = false,
				colormap            = [[1 0.25 1 0.05   0.01 0.005 0.02 0.01]],
				directional         = true,
				emitrotspread       = 0.1,
				emitvector          = [[dir]],
				gravity             = [[0 -0.01 0]];
				numparticles        = 1,
				particlelife        = 20,
				particlelifespread  = 10,
				particlesize        = 1,
				particlesizespread  = 0.5,
				particlespeed       = -1,
				particlespeedspread = 0.2,
				pos                 = [[-2r4 -2r4 -2r4]],
				sizegrowth          = 0,
				sizemod             = 0.95,
				texture             = [[pinknovaexplo]],
			},
		},
	},
	purple_missile_trail = {
		usedefaultexplosions = false,
	spikes = {
      air                = true,
      class              = [[explspike]],
      count              = 4,
      ground             = true,
      water              = true,
      properties = {
        alpha              = 1,
        alphadecay         = 0.25,
        color              = [[0.8, 0, 0.8]],
        dir                = [[-6 r12,-6 r12,-6 r12]],
        length             = 26,
        width              = 16,
      },
    },
    smoke_front = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.8,
        colormap           = [[0.8 0.6 0.8 0.4 0.3 0.1 0.3 0.6 0.0 0.0 0.0 0.01]],
        directional        = false,
        emitrot            = 0,
        emitrotspread      = 50,
        emitvector         = [[dir]],
        gravity            = [[0.05 r-0.1, 0.05 r-0.1, 0.05 r-0.1]],
        numparticles       = 2,
        particlelife       = 20,
        particlelifespread = 0,
        particlesize       = 8,
        particlesizespread = 2,
        particlespeed      = 10,
        particlespeedspread = -4,
        pos                = [[0, 1, 3]],
        sizegrowth         = 1.5,
        sizemod            = 1.0,
        texture            = [[smoke]],
      },
    },
		glow = {
			air                = true,
			class              = [[explspike]],
			count              = 12,
			ground             = true,
			water              = true,
			properties = {
				alpha              = 1,
				alphadecay         = 0.125,
				alwaysvisible      = false,
				color              = [[1,0.2,1]],
				dir                = [[-4 r8, -4 r8, -4 r8]],
				length             = 5,
				lengthgrowth       = 1.02,
				width              = 8,
			},
		},
		white = {
			air                = true,
			class              = [[explspike]],
			count              = 2,
			ground             = true,
			water              = true,
			properties = {
				alpha              = 1,
				alphadecay         = 0.125,
				alwaysvisible      = false,
				color              = [[1,1,1]],
				dir                = [[-2 r4, -2 r4, -2 r4]],
				length             = 3,
				lengthgrowth       = 1.01,
				width              = 4,
			},
		},
		shaft                = {
			air        = true,
			class      = [[CBitmapMuzzleFlame]],
			count      = 1,
			ground     = true,
			underwater = 1,
			water      = true,
			properties = {
				colormap     = [[0.9 0.5 0.9 0.01 0.5 0.1 0.8 0.01 0 0 0 0.01]],
				dir          = [[dir]],
				frontoffset  = 0,
				fronttexture = [[null]],
				length       = -50,
				sidetexture  = [[plasma3]],
				size         = 12,
				sizegrowth   = -0.3,
				ttl          = 18,
			},
		},
	},
}

