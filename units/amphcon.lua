unitDef = {
  unitname            = [[amphcon]],
  name                = [[Clam]],
  description         = [[Amphibious  Construction/Resurrection Bot, Builds at 9 m/s]],
  acceleration        = 0.4,
  activateWhenBuilt	  = true,
  brakeRate           = 0.25,
  buildCostEnergy     = 210,
  buildCostMetal      = 210,
  buildDistance       = 120,
  builder             = true,

  buildoptions        = {
  },

  buildPic            = [[amphcon.png]],
  buildTime           = 130,
  canAssist           = true,
  canBuild            = true,
  canMove             = true,
  canPatrol           = true,
  canreclamate        = [[1]],
  canResurrect        = true,
  canstop             = [[1]],
  category            = [[LAND UNARMED]],
  corpse              = [[DEAD]],

  customParams        = {
    --description_bp = [[Robô de construç?o e ressurreiç?o, constrói a 6 m/s]],
    --description_es = [[Robot de Construccion/Resurrección, Construye a 6 m/s]],
    --description_fr = [[Robot de Construction/Resurrection, Construit ? 6 m/s]],
    --description_it = [[Robot da Costruzzione/Risurrezione, Costruisce a 6 m/s]],
	--description_de = [[Konstruktions-/Wiederbelebungsroboter, Baut mit 6 M/s]],
    helptext       = [[The Clam is a sturdy constructor that can build, reclaim or resurrect in the deep sea as well as it does on land.]]
    --helptext_fr    = [[Le Necro tient son nom de sa facult?, comme tous les constructeurs de sa faction, ? r?ssuciter les carcasses du champ de bataille. La Resurrection ne consomme que de l'?nergie, et d?pends du co?t de l'unit? originelle.]],
	--helptext_de    = [[Der Necro ist ein ziemlich normaler Konstruktionsroboter mit einem Vorteil: er kann Leichen wiederbeleben. Zu 120% der ursprünglichen Energiekosten bekommst du eine so gut wie neue Einheit wiederzurück.]],
  },

  energyMake          = 0.225,
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[builder]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  mass                = 132,
  maxDamage           = 1300,
  maxSlope            = 36,
  maxVelocity         = 1.7,
  maxWaterDepth       = 5000,
  metalMake           = 0.225,
  minCloakDistance    = 75,
  movementClass       = [[AKBOT2]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName          = [[amphcon.s3o]],
  resurrectSpeed      = 5,
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],
  showNanoSpray       = false,
  script			  = [[amphcon.lua]],
  side                = [[CORE]],
  sightDistance       = 375,
  sonarDistance		  = 400,
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ChickenTrackPointy]],
  trackWidth          = 22,
  terraformSpeed      = 450,
  turnRate            = 1000,
  upright             = false,
  workerTime          = 9,

  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Clam]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 1300,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 84,
      object           = [[conbot_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 84,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

    HEAP  = {
      description      = [[Debris - Clam]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1300,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 42,
      object           = [[debris2x2a.s3o]],
      reclaimable      = true,
      reclaimTime      = 42,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ amphcon = unitDef })
