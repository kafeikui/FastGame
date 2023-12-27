import Web3 from "web3";
import { MAX_CARD_ID } from "../constants/card_constant";
import {
  getLevelAndId,
  getBuffDesc,
  getRoundBuffName,
  getCard as getDictCard,
} from "./card";

const MAX_ROUND = 60;
export const Actionable = {
  Normal: 0,
  Continuous: 1,
  Stop: 2,
  Jump: 3,
};
export const DamageResult = {
  Dodge: 0,
  Normal: 1,
  Crit: 2,
  Absorb: 3,
};
export const IdentityType = {
  Self: 0,
  Enemy: 1,
};
const FightResult = {
  AttackerWin: 0,
  DefenderWin: 1,
  Continue: 2,
};

let web3 = new Web3();
let applyPassiveCardCallback;
let triggerRoundBuffCallback;
let handleRoundBuffCallback;
let applyBuffCallback;
let applyTimedBuffCallback;
let handleDamageCallback;
let preCastCardCallback;
let postCastCardCallback;
let addBuffCallback;

export function setCallback(
  applyPassiveCard,
  triggerRoundBuff,
  handleRoundBuff,
  applyBuff,
  applyTimedBuff,
  handleDamage,
  preCastCard,
  postCastCard,
  addBuff
) {
  applyPassiveCardCallback = applyPassiveCard;
  triggerRoundBuffCallback = triggerRoundBuff;
  handleRoundBuffCallback = handleRoundBuff;
  applyBuffCallback = applyBuff;
  applyTimedBuffCallback = applyTimedBuff;
  handleDamageCallback = handleDamage;
  preCastCardCallback = preCastCard;
  postCastCardCallback = postCastCard;
  addBuffCallback = addBuff;
}

class Card {
  constructor(id, available) {
    this.id = id;
    this.available = available;
  }
}

class Buff {
  constructor(id, positive, duration, barrier) {
    this.id = id;
    this.positive = positive;
    this.duration = duration;
    this.barrier = barrier;
    this.description = () => getBuffDesc(this.id, this.duration, this.barrier);
  }
}

class RoundState {
  constructor(round, aAction, randomness) {
    this.round = round;
    this.aAction = aAction;
    this.randomness = randomness;
  }
}

export class PlayerState {
  constructor(
    identityType,
    sequenceIndex,
    health,
    maxHealth,
    damage,
    hitRate,
    dodgeRate,
    critRate,
    critDamage,
    damageReduction,
    damageIncrease,
    actionable,
    buffCount,
    buffs
  ) {
    this.identityType = identityType;
    this.sequenceIndex = sequenceIndex;
    this.health = health;
    this.maxHealth = maxHealth;
    this.damage = damage;
    this.hitRate = hitRate;
    this.dodgeRate = dodgeRate;
    this.critRate = critRate;
    this.critDamage = critDamage;
    this.damageReduction = damageReduction;
    this.damageIncrease = damageIncrease;
    this.actionable = actionable;
    this.buffCount = buffCount;
    this.buffs = buffs;
  }

  static placeholder(identityType) {
    return new PlayerState(
      identityType,
      0,
      12000,
      12000,
      600,
      100,
      10,
      10,
      200,
      100,
      100,
      Actionable.Normal,
      0,
      []
    );
  }

  static buildPlayerState(identityType, maxHealth, damage) {
    return new PlayerState(
      identityType,
      0,
      maxHealth,
      maxHealth,
      damage,
      100,
      10,
      10,
      200,
      100,
      100,
      Actionable.Normal,
      0,
      []
    );
  }
}

export async function fight(a, b, aSequence, bSequence, aFirst, randomness) {
  let aCards = prepareCards(aSequence);
  let bCards = prepareCards(bSequence);
  applyPassiveCard(a, aCards);
  await applyPassiveCardCallback(a);
  applyPassiveCard(b, bCards);
  await applyPassiveCardCallback(b);

  let state = new RoundState(0, aFirst, randomness);
  let res;

  // a and b take turns to cast card from round-robin sequence
  for (;;) {
    if (state.aAction) {
      console.log("a as attacker");
      res = await executeRound(state, a, b, aCards, aFirst);
      if (res != FightResult.Continue) {
        return res == FightResult.AttackerWin;
      }
      state.aAction = false;
    } else {
      console.log("b as attacker");
      res = await executeRound(state, b, a, bCards, aFirst);
      if (res != FightResult.Continue) {
        return res == FightResult.DefenderWin;
      }
      state.aAction = true;
    }
  }
}

async function executeRound(
  state,
  attacker,
  defender,
  attackerSequence,
  aFirst
) {
  let res;
  do {
    console.log("round", state.round);
    if (state.round >= MAX_ROUND) {
      return forceEnd(attacker, defender, aFirst);
    }
    if (attacker.actionable == Actionable.Continuous) {
      attacker.actionable = Actionable.Normal;
    }
    await triggerRoundBuff(attacker, defender);
    await triggerRoundBuffCallback(attacker, state.round);
    res = checkEnd(attacker, defender);
    if (res != FightResult.Continue) {
      return res;
    }
    let card = new Card(0, 1);
    if (attacker.actionable == Actionable.Jump) {
      attacker.sequenceIndex =
        (attacker.sequenceIndex + 1) % attackerSequence.length;
      card = attackerSequence[attacker.sequenceIndex];
      attacker.actionable = Actionable.Normal;
    } else if (attacker.actionable == Actionable.Normal) {
      card = attackerSequence[attacker.sequenceIndex];
    }
    await preCastCardCallback(attacker.sequenceIndex, attacker, defender);
    await castCard(card, attacker, defender, state.randomness);
    await postCastCardCallback(attacker.sequenceIndex, attacker, defender);
    console.log("after cast, defender.health", defender.health);
    res = checkEnd(attacker, defender);
    if (res != FightResult.Continue) {
      return res;
    }
    if (attacker.actionable != Actionable.Stop) {
      attacker.sequenceIndex =
        (attacker.sequenceIndex + 1) % attackerSequence.length;
    } else {
      attacker.actionable = Actionable.Normal;
    }
    state.randomness = web3.utils.toBN(
      web3.utils.soliditySha3(state.randomness)
    );
    state.round++;
    console.log("---------------------------------");
  } while (attacker.actionable == Actionable.Continuous);

  return FightResult.Continue;
}

function checkEnd(attacker, defender) {
  return attacker.health == 0
    ? FightResult.DefenderWin
    : defender.health == 0
    ? FightResult.AttackerWin
    : FightResult.Continue;
}

function forceEnd(attacker, defender, aFirst) {
  return attacker.health == defender.health
    ? aFirst
      ? FightResult.DefenderWin
      : FightResult.AttackerWin
    : attacker.health > defender.health
    ? FightResult.AttackerWin
    : FightResult.DefenderWin;
}

// Buff with the same id will be replaced
async function addBuff(state, buff) {
  for (let i = 0; i < state.buffCount; i++) {
    if (
      state.buffs[i].duration > 0 &&
      state.buffs[i].id % MAX_CARD_ID == buff.id % MAX_CARD_ID
    ) {
      state.buffs[i].duration = 0;
      break;
    }
  }
  state.buffs[state.buffCount] = buff;
  state.buffCount++;
  await addBuffCallback(state, buff);
}

function removeBuff() {
  if (arguments.length === 2) {
    return removeBuff2(arguments[0], arguments[1]);
  } else if (arguments.length === 3) {
    return removeBuff3(arguments[0], arguments[1], arguments[2]);
  }
}

function removeBuff3(state, count, positive) {
  for (let i = 0; i < state.buffCount; i++) {
    if (state.buffs[i].positive == positive && state.buffs[i].duration > 0) {
      state.buffs[i].duration = 0;
      count--;
      if (count == 0) {
        return;
      }
    }
  }
}

function removeBuff2(state, buffId) {
  for (let i = 0; i < state.buffCount; i++) {
    if (
      state.buffs[i].duration > 0 &&
      state.buffs[i].id % MAX_CARD_ID == buffId % MAX_CARD_ID
    ) {
      state.buffs[i].duration = 0;
      return true;
    }
  }
  return false;
}

async function handleRoundBuffDamage(state, buffName, value, isHeal) {
  if (isHeal) {
    state.health =
      state.health + value > state.maxHealth
        ? state.maxHealth
        : state.health + value;
  } else {
    state.health = state.health > value ? state.health - value : 0;
  }
  await handleRoundBuffCallback(state, buffName, value, isHeal);
}

async function handleDamage(card, self, enemy, damage, randomness) {
  let cardName = getDictCard(card.id).name;
  let buffedEnemy = applyBuff(enemy, false);
  await applyBuffCallback(enemy);
  let barriers = [];
  let barrierCount = 0;
  // cauculate absolute dodge and barriers
  for (let i = 0; i < enemy.buffCount; i++) {
    if (enemy.buffs[i].duration == 0) {
      continue;
    }
    let id = enemy.buffs[i].id % (MAX_CARD_ID + 1);

    if (id == 18) {
      enemy.buffs[i].duration--;
      await applyTimedBuffCallback(enemy);
      await handleDamageCallback(cardName, enemy, DamageResult.Dodge, 0);
      return 0;
    } else if (id == 15) {
      // for now only one buff can get barrier
      barriers[0] = enemy.buffs[i];
      barrierCount++;
    }
  }

  let buffedSelf = applyBuff(self, true);
  await applyBuffCallback(self);

  let damageResult = DamageResult.Normal;
  if (
    buffedSelf.hitRate >=
    parseInt(randomness.mod(web3.utils.toBN(100)).toNumber()) +
      buffedEnemy.dodgeRate
  ) {
    damage = parseInt(
      (damage * buffedSelf.damageIncrease * buffedEnemy.damageReduction) / 10000
    );
    if (
      buffedSelf.critRate >=
      parseInt(
        web3.utils
          .toBN(web3.utils.soliditySha3(randomness))
          .mod(web3.utils.toBN(100))
          .toNumber()
      )
    ) {
      damage = parseInt((damage * buffedSelf.critDamage) / 100);
      damageResult = DamageResult.Crit;
      console.log("crit! damage", damage);
    }
    // absorb damage by barrier
    for (let i = 0; i < barrierCount; i++) {
      if (barriers[i].barrier >= damage) {
        barriers[i].barrier -= damage;
        //TODO: handle different barrier
        console.log("absorb! damage", damage);
        await handleDamageCallback(
          cardName,
          enemy,
          DamageResult.Absorb,
          damage
        );
        return 0;
      } else {
        damage -= barriers[i].barrier;
        barriers[i].barrier = 0;
        barriers[i].duration = 0;
      }
    }
    enemy.health = enemy.health > damage ? enemy.health - damage : 0;
    await handleDamageCallback(cardName, enemy, damageResult, damage);
    return damage;
  }
  console.log("dodge! damage", 0);
  await handleDamageCallback(cardName, enemy, DamageResult.Dodge, 0);
  return 0;
}

function prepareCards(cardIds) {
  let cards = [];
  for (let i = 0; i < cardIds.length; i++) {
    cards[i] = getCard(cardIds[i]);
  }
  return cards;
}

function getCard(cardId) {
  let [level, id] = getLevelAndId(cardId);
  if (id == 6 || id == 23 || id == 26) {
    return new Card(cardId, level);
  }
  return new Card(cardId, 99);
}

async function castCard(card, self, enemy, randomness) {
  let cardId = card.id;
  let [level, id] = getLevelAndId(cardId);
  if (id == 0) {
    await handleDamage(card, self, enemy, self.damage, randomness);
  } else if (id == 1) {
    await handleDamage(
      card,
      self,
      enemy,
      parseInt(enemy.maxHealth / 20),
      randomness
    );
    if (level == 1) {
      let buff = new Buff(cardId, false, 2, 0);
      await addBuff(enemy, buff);
    } else if (level == 2) {
      let buff = new Buff(cardId, false, 3, 0);
      await addBuff(enemy, buff);
    } else if (level == 3) {
      let buff = new Buff(cardId, false, 4, 0);
      await addBuff(enemy, buff);
    }
  } else if (id == 2) {
    countDownRoundBuff(self);
    if (level == 1) {
      let buff = new Buff(cardId, false, 2, 0);
      await addBuff(enemy, buff);
    } else if (level == 2) {
      let buff = new Buff(cardId, false, 2, 0);
      await addBuff(enemy, buff);
    } else if (level == 3) {
      let buff = new Buff(cardId, false, 3, 0);
      await addBuff(enemy, buff);
    }
  } else if (id == 3) {
    await handleDamage(card, self, enemy, self.damage, randomness);
    if (level == 1) {
      let buff = new Buff(cardId, false, 2, 0);
      await addBuff(enemy, buff);
    } else if (level == 2) {
      let buff = new Buff(cardId, false, 3, 0);
      await addBuff(enemy, buff);
    } else if (level == 3) {
      let buff = new Buff(cardId, false, 4, 0);
      await addBuff(enemy, buff);
    }
  } else if (id == 4) {
    countDownRoundBuff(self);
    if (level == 1) {
      let buff = new Buff(cardId, true, 2, 0);
      await addBuff(self, buff);
    } else if (level == 2) {
      let buff = new Buff(cardId, true, 3, 0);
      await addBuff(self, buff);
    } else if (level == 3) {
      let buff = new Buff(cardId, true, 5, 0);
      await addBuff(self, buff);
    }
  } else if (id == 5) {
    countDownRoundBuff(self);
    self.actionable = Actionable.Continuous;
    let buff = new Buff(cardId, true, 1, 0);
    await addBuff(self, buff);
  } else if (id == 6) {
    if (card.available > 0) {
      countDownRoundBuff(self);
      card.available--;
      self.actionable = Actionable.Continuous;
    } else {
      await handleDamage(card, self, enemy, self.damage, randomness);
    }
  } else if (id == 7) {
    if (level == 1) {
      await handleDamage(card, self, enemy, self.damage, randomness);
      let buff = new Buff(cardId, false, 1, 0);
      await addBuff(enemy, buff);
    } else if (level == 2) {
      await handleDamage(card, self, enemy, self.damage, randomness);
      let buff = new Buff(cardId, false, 2, 0);
      await addBuff(enemy, buff);
    } else if (level == 3) {
      await handleDamage(card, self, enemy, self.damage * 2, randomness);
      let buff = new Buff(cardId, false, 3, 0);
      await addBuff(enemy, buff);
    }
  } else if (id == 8) {
    if (level == 1) {
      await handleDamage(
        card,
        self,
        enemy,
        2 * self.damage +
          parseInt(
            (2 * self.damage * (self.maxHealth - self.health)) / self.maxHealth
          ),
        randomness
      );
    } else if (level == 2) {
      await handleDamage(
        card,
        self,
        enemy,
        2 * self.damage +
          parseInt(
            (4 * self.damage * (self.maxHealth - self.health)) / self.maxHealth
          ),
        randomness
      );
    } else if (level == 3) {
      await handleDamage(
        card,
        self,
        enemy,
        2 * self.damage +
          parseInt(
            (6 * self.damage * (self.maxHealth - self.health)) / self.maxHealth
          ),
        randomness
      );
    }
  } else if (id == 9) {
    countDownRoundBuff(self);
    if (level == 1) {
      removeBuff(enemy, 1, true);
    } else if (level == 2) {
      removeBuff(enemy, 2, true);
    } else if (level == 3) {
      removeBuff(enemy, 3, true);
    }
  } else if (id == 10) {
    countDownRoundBuff(self);
    if (level == 1) {
      let buff = new Buff(cardId, false, 2, 0);
      await addBuff(enemy, buff);
    } else if (level == 2) {
      let buff = new Buff(cardId, false, 3, 0);
      await addBuff(enemy, buff);
    } else if (level == 3) {
      let buff = new Buff(cardId, false, 5, 0);
      await addBuff(enemy, buff);
    }
  } else if (id == 11) {
    let damage;
    if (level == 1) {
      damage = await handleDamage(
        card,
        self,
        enemy,
        self.damage * 2,
        randomness
      );
    } else if (level == 2) {
      damage = await handleDamage(
        card,
        self,
        enemy,
        self.damage * 3,
        randomness
      );
    } else if (level == 3) {
      damage = await handleDamage(
        card,
        self,
        enemy,
        self.damage * 4,
        randomness
      );
    }
    if (damage > 0) {
      self.health =
        self.health + damage > self.maxHealth
          ? self.maxHealth
          : self.health + damage;
    }
  } else if (id == 12) {
    let damage;
    if (level == 1) {
      damage = removeBuff(enemy, 12) ? self.damage * 4 : self.damage;
    } else if (level == 2) {
      damage = removeBuff(enemy, 12) ? self.damage * 6 : self.damage * 2;
    } else if (level == 3) {
      damage = removeBuff(enemy, 12) ? self.damage * 8 : self.damage * 3;
    }
    await handleDamage(card, self, enemy, damage, randomness);
  } else if (id == 13) {
    countDownRoundBuff(self);
    if (level == 1) {
      let buff = new Buff(cardId, true, 2, 0);
      await addBuff(self, buff);
    } else if (level == 2) {
      let buff = new Buff(cardId, true, 2, 0);
      await addBuff(self, buff);
    } else if (level == 3) {
      let buff = new Buff(cardId, true, 3, 0);
      await addBuff(self, buff);
    }
  } else if (id == 14) {
    countDownRoundBuff(self);
    if (level == 1) {
      removeBuff(self, 1, false);
      let buff = new Buff(cardId, true, 1, 0);
      await addBuff(self, buff);
    } else if (level == 2) {
      removeBuff(self, 1, false);
      let buff = new Buff(cardId, true, 2, 0);
      await addBuff(self, buff);
    } else if (level == 3) {
      removeBuff(self, 2, false);
      let buff = new Buff(cardId, true, 3, 0);
      await addBuff(self, buff);
    }
  } else if (id == 15) {
    countDownRoundBuff(self);
    if (level == 1) {
      let buff = new Buff(cardId, true, 3, parseInt((self.maxHealth * 3) / 10));
      await addBuff(self, buff);
    } else if (level == 2) {
      let buff = new Buff(cardId, true, 4, parseInt((self.maxHealth * 4) / 10));
      await addBuff(self, buff);
    } else if (level == 3) {
      let buff = new Buff(cardId, true, 5, parseInt((self.maxHealth * 5) / 10));
      await addBuff(self, buff);
    }
  } else if (id == 16) {
    countDownRoundBuff(self);
    if (level == 1) {
      let buff = new Buff(cardId, true, 2, 0);
      await addBuff(self, buff);
    } else if (level == 2) {
      let buff = new Buff(cardId, true, 2, 0);
      await addBuff(self, buff);
    } else if (level == 3) {
      let buff = new Buff(cardId, true, 2, 0);
      await addBuff(self, buff);
    }
  } else if (id == 17) {
    countDownRoundBuff(self);
    if (level == 1) {
      let buff = new Buff(cardId, false, 2, 0);
      await addBuff(enemy, buff);
    } else if (level == 2) {
      let buff = new Buff(cardId, false, 3, 0);
      await addBuff(enemy, buff);
    } else if (level == 3) {
      let buff = new Buff(cardId, false, 4, 0);
      await addBuff(enemy, buff);
    }
  } else if (id == 18) {
    await handleDamage(card, self, enemy, self.damage * 2, randomness);
    if (level == 2) {
      let buff = new Buff(cardId, false, 1, 0);
      await addBuff(enemy, buff);
    } else if (level == 3) {
      let buff = new Buff(cardId, false, 2, 0);
      await addBuff(enemy, buff);
    }
  } else if (id == 19) {
    await handleDamage(card, self, enemy, self.damage, randomness);
  } else if (id == 20) {
    countDownRoundBuff(self);
    if (level == 1) {
      let buff = new Buff(cardId, true, 1, 0);
      await addBuff(self, buff);
    } else if (level == 2) {
      let buff = new Buff(cardId, true, 2, 0);
      await addBuff(self, buff);
    } else if (level == 3) {
      let buff = new Buff(cardId, true, 3, 0);
      await addBuff(self, buff);
    }
  } else if (id == 21) {
    countDownRoundBuff(self);
    if (level == 1) {
      let buff = new Buff(cardId, true, 2, 0);
      await addBuff(self, buff);
    } else if (level == 2) {
      let buff = new Buff(cardId, true, 2, 0);
      await addBuff(self, buff);
    } else if (level == 3) {
      let buff = new Buff(cardId, true, 3, 0);
      await addBuff(self, buff);
    }
  } else if (id == 22) {
    countDownRoundBuff(self);
    if (level == 1) {
      let buff = new Buff(cardId, true, 3, 0);
      await addBuff(self, buff);
    } else if (level == 2) {
      let buff = new Buff(cardId, true, 4, 0);
      await addBuff(self, buff);
    } else if (level == 3) {
      let buff = new Buff(cardId, true, 5, 0);
      await addBuff(self, buff);
    }
  } else if (id == 23) {
    if (card.available > 0) {
      countDownRoundBuff(self);
      card.available--;
      enemy.actionable = Actionable.Jump;
    } else {
      await handleDamage(card, self, enemy, self.damage, randomness);
    }
  } else if (id == 24) {
    countDownRoundBuff(self);
    let heal;
    if (level == 1) {
      heal = parseInt(self.maxHealth / 10);
    } else if (level == 2) {
      heal = parseInt((self.maxHealth * 2) / 10);
    } else if (level == 3) {
      heal = parseInt((self.maxHealth * 3) / 10);
    }
    self.health =
      self.health + heal > self.maxHealth ? self.maxHealth : self.health + heal;
  } else if (id == 25) {
    let originalHitRate = self.hitRate;
    if (level == 1) {
      self.hitRate = self.hitRate > 30 ? self.hitRate - 30 : 0;
      await handleDamage(card, self, enemy, self.damage * 3, randomness);
    } else if (level == 2) {
      self.hitRate = self.hitRate > 20 ? self.hitRate - 20 : 0;
      await handleDamage(card, self, enemy, self.damage * 4, randomness);
    } else if (level == 3) {
      self.hitRate = self.hitRate > 10 ? self.hitRate - 10 : 0;
      await handleDamage(card, self, enemy, self.damage * 5, randomness);
    }
    self.hitRate = originalHitRate;
  } else if (id == 26) {
    if (card.available > 0) {
      countDownRoundBuff(self);
      card.available--;
      enemy.actionable = Actionable.Stop;
    } else {
      await handleDamage(card, self, enemy, self.damage, randomness);
    }
  } else if (id == 27) {
    countDownRoundBuff(self);
    if (level == 1) {
      let buff = new Buff(cardId, false, 3, 0);
      await addBuff(enemy, buff);
    } else if (level == 2) {
      let buff = new Buff(cardId, false, 4, 0);
      await addBuff(enemy, buff);
    } else if (level == 3) {
      let buff = new Buff(cardId, false, 5, 0);
      await addBuff(enemy, buff);
    }
  }
}

async function triggerRoundBuff(self, enemy) {
  for (let i = 0; i < self.buffCount; i++) {
    if (self.buffs[i].duration == 0) {
      continue;
    }

    let [level, id] = getLevelAndId(self.buffs[i].id);
    if (id == 1) {
      let damage;
      if (level == 1) {
        damage = enemy.damage;
      } else if (level == 2) {
        damage = enemy.damage;
      } else if (level == 3) {
        damage = parseInt((enemy.damage * 3) / 2);
      }
      await handleRoundBuffDamage(self, getRoundBuffName(id), damage, false);
    } else if (id == 3) {
      let damage;
      if (level == 1) {
        damage = parseInt((self.health * 3) / 100);
      } else if (level == 2) {
        damage = parseInt((self.health * 4) / 100);
      } else if (level == 3) {
        damage = parseInt((self.health * 5) / 100);
      }
      await handleRoundBuffDamage(self, getRoundBuffName(id), damage, false);
    } else if (id == 7) {
      let damage;
      if (level == 1) {
        damage = parseInt(enemy.damage / 2);
      } else if (level == 2) {
        damage = parseInt((enemy.damage * 4) / 5);
      } else if (level == 3) {
        damage = enemy.damage;
      }
      await handleRoundBuffDamage(self, getRoundBuffName(id), damage, false);
    } else if (id == 17) {
      let damage;
      if (level == 1) {
        damage = parseInt((self.maxHealth * 6) / 100);
      } else if (level == 2) {
        damage = parseInt((self.maxHealth * 8) / 100);
      } else if (level == 3) {
        damage = parseInt(self.maxHealth / 10);
      }
      await handleRoundBuffDamage(self, getRoundBuffName(id), damage, false);
    } else if (id == 22) {
      let health;
      if (level == 1) {
        health = parseInt((self.maxHealth * 4) / 100);
      } else if (level == 2) {
        health = parseInt((self.maxHealth * 6) / 100);
      } else if (level == 3) {
        health = parseInt((self.maxHealth * 8) / 100);
      }
      await handleRoundBuffDamage(self, getRoundBuffName(id), health, true);
    }
  }
}

function applyPassiveCard(self, cards) {
  for (let i = 0; i < cards.length; i++) {
    let [level, id] = getLevelAndId(cards[i].id);
    if (id == 19) {
      if (level == 1) {
        self.damage = parseInt((self.damage * 3) / 2);
      } else if (level == 2) {
        self.damage = parseInt((self.damage * 18) / 10);
      } else if (level == 3) {
        self.damage = self.damage * 2;
      }
    }
  }
}

export function applyBuff(self, countDownBuff) {
  let buffed = new PlayerState(
    self.identityType,
    self.sequenceIndex,
    self.health,
    self.maxHealth,
    self.damage,
    self.hitRate,
    self.dodgeRate,
    self.critRate,
    self.critDamage,
    self.damageReduction,
    self.damageIncrease,
    self.actionable,
    0,
    []
  );

  for (let i = 0; i < self.buffCount; i++) {
    if (self.buffs[i].duration == 0) {
      continue;
    }

    let [level, id] = getLevelAndId(self.buffs[i].id);
    if (id == 2) {
      if (level == 1) {
        buffed.damageIncrease = parseInt((buffed.damageIncrease * 9) / 10);
      } else if (level == 2) {
        buffed.damageIncrease = parseInt((buffed.damageIncrease * 85) / 100);
      } else if (level == 3) {
        buffed.damageIncrease = parseInt((buffed.damageIncrease * 70) / 100);
      }
    } else if (id == 4) {
      if (level == 1) {
        buffed.critRate += 10;
      } else if (level == 2) {
        buffed.critRate += 20;
      } else if (level == 3) {
        buffed.critRate += 40;
      }
    } else if (id == 10) {
      if (level == 1) {
        buffed.hitRate = buffed.hitRate > 10 ? buffed.hitRate - 10 : 0;
      } else if (level == 2) {
        buffed.hitRate = buffed.hitRate > 20 ? buffed.hitRate - 20 : 0;
      } else if (level == 3) {
        buffed.hitRate = buffed.hitRate > 40 ? buffed.hitRate - 40 : 0;
      }
    } else if (id == 13) {
      if (level == 1) {
        buffed.damageReduction = parseInt((buffed.damageReduction * 8) / 10);
      } else if (level == 2) {
        buffed.damageReduction = parseInt((buffed.damageReduction * 8) / 10);
      } else if (level == 3) {
        buffed.damageReduction = parseInt((buffed.damageReduction * 7) / 10);
      }
    } else if (id == 14) {
      if (level == 1) {
        buffed.damageIncrease = parseInt((buffed.damageIncrease * 11) / 10);
      } else if (level == 2) {
        buffed.damageIncrease = parseInt((buffed.damageIncrease * 12) / 10);
      } else if (level == 3) {
        buffed.damageIncrease = parseInt((buffed.damageIncrease * 13) / 10);
      }
    } else if (id == 16) {
      if (level == 1) {
        buffed.damageReduction = parseInt(buffed.damageReduction / 2);
      } else if (level == 2) {
        buffed.damageReduction = parseInt((buffed.damageReduction * 3) / 10);
      } else if (level == 3) {
        buffed.damageReduction = parseInt(buffed.damageReduction / 10);
      }
    } else if (id == 20) {
      if (level == 1) {
        buffed.hitRate += 20;
      } else if (level == 2) {
        buffed.hitRate += 30;
      } else if (level == 3) {
        buffed.hitRate += 50;
      }
    } else if (id == 21) {
      if (level == 1) {
        buffed.dodgeRate += 10;
      } else if (level == 2) {
        buffed.dodgeRate += 20;
      } else if (level == 3) {
        buffed.dodgeRate += 30;
      }
    } else if (id == 27) {
      if (level == 1) {
        buffed.damageIncrease = parseInt(
          (buffed.damageIncrease * (100 - 10 * (4 - self.buffs[i].duration))) /
            100
        );
      } else if (level == 2) {
        buffed.damageIncrease = parseInt(
          (buffed.damageIncrease * (100 - 10 * (5 - self.buffs[i].duration))) /
            100
        );
      } else if (level == 3) {
        buffed.damageIncrease = parseInt(
          (buffed.damageIncrease * (100 - 10 * (6 - self.buffs[i].duration))) /
            100
        );
      }
    }
    // count down round-based buff duration except for one-time buff
    if (id != 18 && countDownBuff) {
      self.buffs[i].duration--;
    }
  }

  return buffed;
}

function countDownRoundBuff(self) {
  // count down round-based buff duration except for one-time buff
  for (let i = 0; i < self.buffCount; i++) {
    if (self.buffs[i].duration == 0) {
      continue;
    }
    let [level, id] = getLevelAndId(self.buffs[i].id);
    if (id != 18) {
      self.buffs[i].duration--;
    }
  }
}

export function testSimpleFight() {
  let a = new PlayerState(
    IdentityType.Self,
    0,
    3000,
    3000,
    150,
    100,
    10,
    10,
    200,
    100,
    100,
    Actionable.Normal,
    0,
    []
  );
  let b = new PlayerState(
    IdentityType.Enemy,
    0,
    3000,
    3000,
    150,
    100,
    10,
    10,
    200,
    100,
    100,
    Actionable.Normal,
    0,
    []
  );
  let aSequence = [0, 0, 0];
  let bSequence = [0, 0, 0];
  let aFirst = true;
  let randomness = web3.utils.toBN(web3.utils.soliditySha3(42));

  let awin;
  awin = fight(a, b, aSequence, bSequence, aFirst, randomness);
  console.log("awin: ", awin);
  awin = fight(a, b, aSequence, bSequence, !aFirst, randomness);
  console.log("awin: ", awin);
}

export function testComplicatedFight() {
  let a = new PlayerState(
    IdentityType.Self,
    0,
    12000,
    12000,
    600,
    100,
    10,
    10,
    200,
    100,
    100,
    Actionable.Normal,
    0,
    []
  );
  let b = new PlayerState(
    IdentityType.Enemy,
    0,
    12000,
    12000,
    600,
    100,
    10,
    10,
    200,
    100,
    100,
    Actionable.Normal,
    0,
    []
  );
  // they are all of defense and heal sect cards of highest level which will result in a long fight
  let aSequence = [];
  aSequence[0] = 22 + 2 * (MAX_CARD_ID + 1);
  aSequence[1] = 24 + 2 * (MAX_CARD_ID + 1);
  aSequence[2] = 22 + 2 * (MAX_CARD_ID + 1);
  aSequence[3] = 24 + 2 * (MAX_CARD_ID + 1);
  aSequence[4] = 27 + 2 * (MAX_CARD_ID + 1);
  aSequence[5] = 16 + 2 * (MAX_CARD_ID + 1);
  aSequence[6] = 15 + 2 * (MAX_CARD_ID + 1);
  let bSequence = [];
  bSequence[0] = 22 + 2 * (MAX_CARD_ID + 1);
  bSequence[1] = 24 + 2 * (MAX_CARD_ID + 1);
  bSequence[2] = 27 + 2 * (MAX_CARD_ID + 1);
  bSequence[3] = 16 + 2 * (MAX_CARD_ID + 1);
  bSequence[4] = 15 + 2 * (MAX_CARD_ID + 1);
  bSequence[5] = 13 + 2 * (MAX_CARD_ID + 1);
  bSequence[6] = 10 + 2 * (MAX_CARD_ID + 1);
  let aFirst = true;
  let randomness = web3.utils.toBN(web3.utils.soliditySha3(42));

  let awin = fight(a, b, aSequence, bSequence, !aFirst, randomness);
  console.log("awin: ", awin);
}
