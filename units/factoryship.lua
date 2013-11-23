unitDef = {
  unitname               = [[factoryship]],
  name                   = [[Shipyard]],
  description            = [[Produces Ships, Builds at 10 m/s]],
  acceleration           = 0,
  brakeRate              = 0,
  buildCostEnergy        = 600,
  buildCostMetal         = 600,
  builder                = true,

  buildoptions           = {
    [[shipcon]],
    [[armpt]],
    [[coresupp]],
    [[dclship]],
    [[corsub]],
    [[armroy]],
    [[corroy]],
    [[serpent]],
    [[corarch]],
    [[armtboat]],
  },

  buildPic               = [[FACTORYSHIP.png]],
  buildTime              = 600,
  canAttack              = true,
  canMove                = true,
  canPatrol              = true,
  canStop                = true,
  category               = [[UNARMED FLOAT]],
  --collisionVolumeOffsets = [[-30 0 -5]],
  --collisionVolumeScales  = [[36 36 220]],
  --collisionVolumeTest    = 1,
  --collisionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_de = [[Produziert Schiffe, Baut mit 10 M/s]],
	helptext_de    = [[Im Shipyard kannst du Schiffe jeder Art und f�r jeden Zweck bauen.]],
    sortName       = [[7]],
	--aimposoffset   = [[-30 0 -5]],
	--midposoffset   = [[0 0 0]],
	--modelradius    = [[18]],
  },

  energyMake             = 0.25,
  energyUse              = 0,
  explodeAs              = [[LARGE_BUILDINGEX]],
  footprintX             = 9,
  footprintZ             = 14,
  iconType               = [[facship]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  mass                   = 324,
  maxDamage              = 6000,
  maxSlope               = 15,
  maxVelocity            = 0,
  metalMake              = 0.25,
  minCloakDistance       = 150,
  minWaterDepth          = 15,
  objectName             = [[seafac.s3o]],
  script				 = [[factoryship.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[LARGE_BUILDINGEX]],
  showNanoSpray          = false,
  side                   = [[CORE]],
  sightDistance          = 273,
  TEDClass               = [[PLANT]],
  turnRate               = 0,
  waterline              = 0,
  workerTime             = 10,
  yardMap                = [[oocccccco oocccccco oocccccco oocccccco oocccccco oocccccco oocccccco oocccccco oocccccco oocccccco oocccccco oocccccco oocccccco oocccccco]],

  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Shipyard]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 6000,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 9,
      footprintZ       = 14,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 240,
      object           = [[seafac_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 240,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },



    HEAP  = {
      description      = [[Debris - Shipyard]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 6000,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 8,
      footprintZ       = 8,
      hitdensity       = [[100]],
      metal            = 120,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 120,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ factoryship = unitDef })
