unitDef = {
  unitname               = [[a_shiplightcarrier]],
  name                   = [[Mistral]],
  description            = [[Aircraft Carrier (Bombardment) & Anti-Nuke]],
  acceleration           = 0.0354,
  activateWhenBuilt      = true,
  brakeRate              = 0.0466,
  buildCostEnergy        = 600,
  buildCostMetal         = 600,
  builder                = true,
  buildPic               = [[ARMCARRY.png]],
  buildTime              = 600,
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
    description_de = [[Flugzeugträger (Bomber) & Anti-Nuke]],
    description_fr = [[Porte-Avion Bombardier & Anti-Nuke]],
    description_pl = [[Lotniskowiec z tarcza antyrakietowa]],
    helptext       = [[The most versatile ship on the high seas, the carrier serves several functions. It is equipped with cruise missiles for long range bombardment. Its anti-missile system safeguards the fleet from the threat of nuclear missiles, and it also serves as a mobile repair base for friendly aircraft. Perhaps most notably, the carrier provides its own complement of surface attack drones to engage targets.]],
    helptext_de    = [[Das vielseitigste Schiff auf hoher See, der Träger bietet verschiedenste Funktionen. Er ist mit Marschflugkörpern für weitreichendes Bombardement ausgerüstet. Sein antinukleares System schützt die Flotte vor Atomraketen. Außerdem dient es auch als mobile Reperaturbasis für befreundete Flugzeuge. Vielleicht am nennenswertesten: der Träger besitzt sein eigenes Geschwader an Kampfdrohnen.]],
    helptext_fr    = [[C'est le plus polyvalent des Navires possibles, le Reef peut tirer des missiles de croisicre longue portée pour des frappes chirurgicales, tirer des antimissiles pour contrer tout missile nucléaire, servir de station de réparation et de rechargement pour les planeurs alliés ou encore utiliser ses nombreux drones.]],
    helptext_pl    = [[Najbardziej wielozadaniowy sposrod okretow. Posiada rakiety dalekiego zasiegu i tarcze antyrakietowa, a jego pokład sluzy jako stacja naprawy i dozbrajania samolotow. Ponadto jest w stanie automatycznie produkowac wlasne drony bojowe.]],
	midposoffset   = [[0 -10 0]],
    modelradius    = [[30]],
	priority_misc = 2, -- High
  },

  --energyUse              = 1.5,
  explodeAs              = [[BIG_UNITEX]],
  floater                = true,
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[a_shiplightcarrier]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  maxDamage              = 7500,
  maxVelocity            = 2.75,
  minCloakDistance       = 75,
  movementClass          = [[BOAT4]],
  objectName             = [[a_shiplightcarrier.3do]],
  script                 = [[a_shiplightcarrier.lua]],
  --radarDistance          = 1200,
  --radarEmitHeight        = 100,
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

	-- see \luarules\configs\drone_defs.lua
	
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
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[a_shiplightcarrier_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4b.s3o]],
    },

  },

}

return lowerkeys({ a_shiplightcarrier = unitDef })
