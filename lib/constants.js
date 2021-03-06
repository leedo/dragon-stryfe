(function() {
  module.exports = {
    universeWidth: 480,
    universeHeight: 300,
    maxEnergy: 200.0,
    energyRegenRate: 0.25,
    maxTrailLength: 10,
    maxSpeed: 6,
    minSpeed: -3,
    accelRate: 0.5,
    coastSpeed: 0.5,
    decelRate: 0.02,
    brakingRate: 0.4,
    fireDistanceSquared: 1600.0,
    playerTurnRate: 0.007,
    deadlyDamage: 100,
    deathAnimationTime: 50,
    syncTimer: 25,
    maxPowerups: 2,
    powerupTimer: 400,
    maxPlayers: 5,
    fullLogs: false,
    logPrefix: "/tmp/",
    tickLength: 40
  };
}).call(this);
