unitDef = {
  unitname               = [[shiplightcarrier]],
  name                   = [[Sirocco]],
  description            = [[TODO]],
  acceleration           = 0.0354,
  activateWhenBuilt      = true,
  brakeRate              = 0.0466,
  buildCostEnergy        = 800,
  buildCostMetal         = 800,
  builder                = true,
  buildPic               = [[ARMCARRY.png]],
  buildTime              = 800,
  canAssist              = false,
  canMove                = true,
  canReclaim             = false,
  canRepair              = false,
  canRestore             = false,
  cantBeTransported      = true,
  category               = [[SHIP]],
  CollisionSphereScale   = 0.6,
  collisionVolumeOffsets = [[-1 10 0]],
  collisionVolumeScales  = [[40 35 130]],
  collisionVolumeTest	 = 1,
  collisionVolumeType    = [[box]],
  corpse                 = [[DEAD]],

  customParams           = {
    --pad_count = 9,
    helptext       = [[TODO]],
	midposoffset   = [[0 -10 0]],
    modelradius    = [[30]],
	priority_misc = 2, -- High
  },

  energyUse              = 1.5,
  explodeAs              = [[BIG_UNITEX]],
  floater                = true,
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[shipcarrier]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  maxDamage              = 2000,
  maxVelocity            = 2.0,
  minCloakDistance       = 75,
  movementClass          = [[BOAT4]],
  objectName             = [[shiplightcarrier.3do]],
  script                 = [[shiplightcarrier.lua]],
  radarEmitHeight        = 100,
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],
  showNanoSpray          = false,
  sightDistance          = 660,
  sonarDistance          = 660,
  turninplace            = 0,
  turnRate               = 233,
  waterline              = 10,

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
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 6,
      footprintZ       = 6,
      object           = [[shiplightcarrier_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 6,
      footprintZ       = 6,
      object           = [[debris4x4b.s3o]],
    },

  },

}

return lowerkeys({ shiplightcarrier = unitDef })
