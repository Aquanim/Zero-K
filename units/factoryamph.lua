unitDef = {
  unitname         = [[factoryamph]],
  name             = [[Amphibious Operations Plant]],
  description      = [[Produces Amphibious Bots and Subs, Builds at 6 m/s]],
  acceleration     = 0,
  bmcode           = [[0]],
  brakeRate        = 0,
  buildCostEnergy  = 550,
  buildCostMetal   = 550,
  builder          = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 8,
  buildingGroundDecalSizeY      = 7,
  buildingGroundDecalType       = [[factoryjump_aoplane.dds]],  

  buildoptions     = {
    [[amphcon]],
	[[amphraider3]],
	[[amphraider2]],
	[[amphfloater]],
	[[amphriot]],	
	[[amphassault]],
	[[amphaa]],
	[[amphtele]],
  },

  buildPic         = [[factoryamph.png]],
  buildTime        = 550,
  canMove          = true,
  canPatrol        = true,
  canstop          = [[1]],
  category         = [[UNARMED SINK]],
  --collisionVolumeOffsets = [[0 0 0]],
  --collisionVolumeScales  = [[120 45 120]],
  collisionVolumeTest    = 1,
  --collisionVolumeType    = [[box]],
  corpse           = [[DEAD]],

  customParams     = {
    --description_de = [[Produziert Aerogleiter, Baut mit 6 M/s]],
    helptext       = [[The Amphibious  Operations Plant builds amphibious bots and submarines (when underwater), providing an alternative approach to land/sea warfare.]],
	--helptext_de    = [[Die Amphibious Operations Platform ist schnell und t�dlich und er�ffnet dir die M�glichkeit Wasser und Boden gleichzeitig zu �berqueren und somit deinen Gegner geschickt zu �berlisten. Wichtigste Einheiten: Halberd, Mace, Penetrator]],
    sortName = [[8]],
  },

  energyMake       = 0.225,
  energyUse        = 0,
  explodeAs        = [[LARGE_BUILDINGEX]],
  footprintX       = 7,
  footprintZ       = 7,
  iconType         = [[facamph]],
  idleAutoHeal     = 5,
  idleTime         = 1800,
  mass             = 324,
  maxDamage        = 4000,
  maxSlope         = 15,
  maxVelocity      = 0,
  metalMake        = 0.225,
  minCloakDistance = 150,
  noAutoFire       = false,
  objectName       = [[factory2.s3o]],
  seismicSignature = 4,
  selfDestructAs   = [[LARGE_BUILDINGEX]],
  showNanoSpray    = false,
  side             = [[ARM]],
  sightDistance    = 273,
  turnRate         = 0,
  workerTime       = 6,
  yardMap          = [[ooooooo ooooooo ooooooo ccccccc ccccccc ccccccc ccccccc]],

  featureDefs      = {

    DEAD  = {
      description      = [[Wreckage - Amphibious Operations Plant]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 4000,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 8,
      footprintZ       = 7,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 220,
      object           = [[ARMFHP_DEAD.s3o]],
      reclaimable      = true,
      reclaimTime      = 220,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Amphibious Operations Plant]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 4000,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 8,
      footprintZ       = 7,
      hitdensity       = [[100]],
      metal            = 110,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 110,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ factoryamph = unitDef })
