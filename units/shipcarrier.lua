unitDef = {
  unitname               = [[shipcarrier]],
  name                   = [[Reef]],
  description            = [[Aircraft Carrier]],
  acceleration           = 0.0354,
  activateWhenBuilt   	 = true,
  brakeRate              = 0.0466,
  buildCostEnergy        = 3500,
  buildCostMetal         = 3500,
  builder                = false,
  buildPic               = [[shipcarrier.png]],
  buildTime              = 3500,
  canMove                = true,
  cantBeTransported      = true,
  category               = [[SHIP]],
  CollisionSphereScale   = 0.6,
  collisionVolumeOffsets = [[-5 -10 0]],
  collisionVolumeScales  = [[80 80 240]],
  collisionVolumeType    = [[CylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_de = [[Flugzeugträger (Bomber)]],
    description_fr = [[Porte-Avion Bombardier]],
    helptext       = [[The Carrier provides a mobile repair/rearm pad for aircraft, and is armed with its own complement of twelve copter drones. Use the boost to construct a large number of drones in a short time.]],
	midposoffset   = [[0 -10 0]],
    modelradius    = [[50]],
	--stockpiletime  = [[60]],
	--stockpilecost  = [[600]],
	--priority_misc = 2, -- High
	--extradrawrange = 3000,
  },

  explodeAs              = [[ATOMIC_BLASTSML]],
  floater                = true,
  footprintX             = 6,
  footprintZ             = 6,
  iconType               = [[shipcarrier]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  maxDamage              = 7500,
  maxVelocity            = 2.75,
  minCloakDistance       = 75,
  minWaterDepth          = 10,
  movementClass          = [[BOAT6]],
  objectName             = [[shipcarrier.dae]],
  script                 = [[shipcarrier.lua]],
  radarEmitHeight        = 48,
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],
  sfxtypes               = {
    explosiongenerators = {
      [[custom:xamelimpact]],
      [[custom:ROACHPLOSION]],
      [[custom:shellshockflash]],
    },
  },
  showNanoSpray          = false,
  sightDistance          = 660,
  sonarDistance          = 660,
  turninplace            = 0,
  turnRate               = 233,
  waterline              = 20,

  weapons                = {

    {
      def                = [[carriertargeting]],
      badTargetCategory  = [[SINK]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },
	
  },

  weaponDefs             = {

    carriertargeting   = {
      name                    = [[Fake Targeting Weapon]],
      areaOfEffect            = 8,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 1E-06,
        planes  = 1E-06,
        subs    = 5E-08,
      },

      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      flightTime              = 1,
      impactOnly              = true,
      interceptedByShieldType = 1,
      range                   = 1600,
      reloadtime              = 1.25,
      size                    = 1E-06,
      smokeTrail              = false,

      textures                = {
        [[null]],
        [[null]],
        [[null]],
      },

      turnrate                = 1000000000,
      turret                  = true,
      weaponAcceleration      = 20000,
      weaponTimer             = 0.5,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 20000,
    },

  },

  featureDefs            = {

    DEAD  = {
      CollisionSphereScale   = 0.6,
      collisionVolumeOffsets = [[-5 -10 0]],
	  collisionVolumeScales  = [[80 80 240]],
	  collisionVolumeType    = [[CylZ]],
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 6,
      footprintZ       = 6,
      object           = [[shipcarrier_dead.dae]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 6,
      footprintZ       = 6,
      object           = [[debris4x4b.s3o]],
    },

  },

}

return lowerkeys({ shipcarrier = unitDef })
