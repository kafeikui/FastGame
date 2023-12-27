// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import {Test} from "forge-std/Test.sol";
// contract GameFight is Test {
library GameFight {
    uint32 public constant MAX_CARD_ID = 27;
    uint32 public constant MAX_ROUND = 60;

    // uint32[] public LOW_QUALITY_CARD_IDS = [2, 3, 4, 10, 18, 20, 22, 24, 25];
    // uint32[] public MIDDLE_QUALITY_CARD_IDS = [1, 6, 7, 12, 13, 14, 21, 23, 27];
    // uint32[] public HIGH_QUALITY_CARD_IDS = [5, 8, 9, 11, 15, 16, 17, 19, 26];

    enum Actionable {
        Normal,
        Continuous,
        Stop,
        Jump
    }

    enum FightResult {
        AttackerWin,
        DefenderWin,
        Continue
    }

    enum CardQuality {
        Low,
        Middle,
        High
    }

    struct Card {
        uint32 id;
        uint8 available;
    }

    struct Buff {
        uint32 id;
        bool positive;
        uint8 duration;
        uint32 barrier;
    }

    struct PlayerState {
        uint256 sequenceIndex;
        uint32 health;
        uint32 maxHealth;
        uint32 damage;
        uint32 hitRate;
        uint32 dodgeRate;
        uint32 critRate;
        uint32 critDamage;
        uint32 damageReduction;
        uint32 damageIncrease;
        Actionable actionable;
        uint32 buffCount;
        Buff[] buffs;
    }

    struct RoundState {
        uint32 round;
        bool aAction;
        uint256 randomness;
    }

    function getCardIdsByUpperQuality(uint256 quality) public pure returns (uint32[] memory cardIds) {
        return getCardIdsByUpperQuality(_parseCardQuality(quality));
    }

    function getCardIdsByQuality(uint256 quality) public pure returns (uint32[] memory) {
        return getCardIdsByQuality(_parseCardQuality(quality));
    }

    function getCardIdsByQuality(CardQuality quality) public pure returns (uint32[] memory cardIds) {
        if (quality == CardQuality.Low) {
            cardIds = new uint32[](9);
            cardIds[0] = 2;
            cardIds[1] = 3;
            cardIds[2] = 4;
            cardIds[3] = 10;
            cardIds[4] = 18;
            cardIds[5] = 20;
            cardIds[6] = 22;
            cardIds[7] = 24;
            cardIds[8] = 25;
        } else if (quality == CardQuality.Middle) {
            cardIds = new uint32[](9);
            cardIds[0] = 1;
            cardIds[1] = 6;
            cardIds[2] = 7;
            cardIds[3] = 12;
            cardIds[4] = 13;
            cardIds[5] = 14;
            cardIds[6] = 21;
            cardIds[7] = 23;
            cardIds[8] = 27;
        } else if (quality == CardQuality.High) {
            cardIds = new uint32[](9);
            cardIds[0] = 5;
            cardIds[1] = 8;
            cardIds[2] = 9;
            cardIds[3] = 11;
            cardIds[4] = 15;
            cardIds[5] = 16;
            cardIds[6] = 17;
            cardIds[7] = 19;
            cardIds[8] = 26;
        }
    }

    function getCardIdsByUpperQuality(CardQuality quality) public pure returns (uint32[] memory cardIds) {
        if (quality == CardQuality.Low) {
            return getCardIdsByQuality(CardQuality.Low);
        } else if (quality == CardQuality.Middle) {
            cardIds = new uint32[](18);
            cardIds[0] = 2;
            cardIds[1] = 3;
            cardIds[2] = 4;
            cardIds[3] = 10;
            cardIds[4] = 18;
            cardIds[5] = 20;
            cardIds[6] = 22;
            cardIds[7] = 24;
            cardIds[8] = 25;
            cardIds[9] = 1;
            cardIds[10] = 6;
            cardIds[11] = 7;
            cardIds[12] = 12;
            cardIds[13] = 13;
            cardIds[14] = 14;
            cardIds[15] = 21;
            cardIds[16] = 23;
            cardIds[17] = 27;
        } else if (quality == CardQuality.High) {
            cardIds = new uint32[](27);
            for (uint256 i = 0; i < 27; i++) {
                cardIds[i] = uint32(i + 1);
            }
        }
    }

    function getCardQuality(uint32 cardId) public pure returns (CardQuality quality) {
        (, uint32 id) = _getLevelAndId(cardId);
        if (id == 2 || id == 3 || id == 4 || id == 10 || id == 18 || id == 20 || id == 22 || id == 24 || id == 25) {
            return CardQuality.Low;
        } else if (
            id == 1 || id == 6 || id == 7 || id == 12 || id == 13 || id == 14 || id == 21 || id == 23 || id == 27
        ) {
            return CardQuality.Middle;
        } else if (
            id == 5 || id == 8 || id == 9 || id == 11 || id == 15 || id == 16 || id == 17 || id == 19 || id == 26
        ) {
            return CardQuality.High;
        }
    }

    function fight(
        PlayerState memory a,
        PlayerState memory b,
        uint32[] memory aSequence,
        uint32[] memory bSequence,
        bool aFirst,
        uint256 randomness
    ) public pure returns (bool aWin) {
        Card[] memory aCards = _prepareCards(aSequence);
        Card[] memory bCards = _prepareCards(bSequence);
        _applyPassiveCard(a, aCards);
        _applyPassiveCard(b, bCards);

        RoundState memory state = RoundState(0, aFirst, randomness);
        FightResult res;

        // a and b take turns to cast card from round-robin sequence
        for (;;) {
            if (state.aAction) {
                // emit log_string("a as attacker");
                res = _executeRound(state, a, b, aCards, aFirst);
                if (res != FightResult.Continue) {
                    return res == FightResult.AttackerWin;
                }
                state.aAction = false;
            } else {
                // emit log_string("b as attacker");
                res = _executeRound(state, b, a, bCards, aFirst);
                if (res != FightResult.Continue) {
                    return res == FightResult.DefenderWin;
                }
                state.aAction = true;
            }
        }
    }

    function _executeRound(
        RoundState memory state,
        PlayerState memory attacker,
        PlayerState memory defender,
        Card[] memory attackerSequence,
        bool aFirst
    ) internal pure returns (FightResult res) {
        do {
            // emit log_named_uint("round", state.round);
            if (state.round >= MAX_ROUND) {
                return _forceEnd(attacker, defender, aFirst);
            }
            if (attacker.actionable == Actionable.Continuous) {
                attacker.actionable = Actionable.Normal;
            }
            _triggerRoundBuff(attacker, defender);
            res = _checkEnd(attacker, defender);
            if (res != FightResult.Continue) {
                return res;
            }
            Card memory card = Card(0, 1);
            if (attacker.actionable == Actionable.Jump) {
                attacker.sequenceIndex = (attacker.sequenceIndex + 1) % attackerSequence.length;
                card = attackerSequence[attacker.sequenceIndex];
                attacker.actionable = Actionable.Normal;
            } else if (attacker.actionable == Actionable.Normal) {
                card = attackerSequence[attacker.sequenceIndex];
            }
            _castCard(card, attacker, defender, state.randomness);
            // emit log_named_uint("after cast, defender.health", defender.health);
            res = _checkEnd(attacker, defender);
            if (res != FightResult.Continue) {
                return res;
            }
            if (attacker.actionable != Actionable.Stop) {
                attacker.sequenceIndex = (attacker.sequenceIndex + 1) % attackerSequence.length;
            } else {
                attacker.actionable = Actionable.Normal;
            }
            state.randomness = uint256(keccak256(abi.encode(state.randomness)));
            state.round++;
            // emit log_string("---------------------------------");
        } while (attacker.actionable == Actionable.Continuous);

        return FightResult.Continue;
    }

    function _checkEnd(PlayerState memory attacker, PlayerState memory defender) internal pure returns (FightResult) {
        return attacker.health == 0
            ? FightResult.DefenderWin
            : defender.health == 0 ? FightResult.AttackerWin : FightResult.Continue;
    }

    function _forceEnd(PlayerState memory attacker, PlayerState memory defender, bool aFirst)
        internal
        pure
        returns (FightResult)
    {
        return attacker.health == defender.health
            ? (aFirst ? FightResult.DefenderWin : FightResult.AttackerWin)
            : attacker.health > defender.health ? FightResult.AttackerWin : FightResult.DefenderWin;
    }

    // Buff with the same id will be replaced
    function _addBuff(PlayerState memory state, Buff memory buff) internal pure {
        for (uint256 i = 0; i < state.buffCount; i++) {
            if (state.buffs[i].duration > 0 && state.buffs[i].id % MAX_CARD_ID == buff.id % MAX_CARD_ID) {
                state.buffs[i].duration = 0;
                break;
            }
        }
        state.buffs[state.buffCount] = buff;
        state.buffCount++;
    }

    function _removeBuff(PlayerState memory state, uint256 count, bool positive) internal pure {
        for (uint256 i = 0; i < state.buffCount; i++) {
            if (state.buffs[i].positive == positive && state.buffs[i].duration > 0) {
                state.buffs[i].duration = 0;
                count--;
                if (count == 0) {
                    return;
                }
            }
        }
    }

    function _removeBuff(PlayerState memory state, uint32 buffId) internal pure returns (bool) {
        for (uint256 i = 0; i < state.buffCount; i++) {
            if (state.buffs[i].duration > 0 && state.buffs[i].id % MAX_CARD_ID == buffId % MAX_CARD_ID) {
                state.buffs[i].duration = 0;
                return true;
            }
        }
        return false;
    }

    function _handleDamage(PlayerState memory self, PlayerState memory enemy, uint32 damage, uint256 randomness)
        internal
        pure
        returns (uint32)
    {
        PlayerState memory buffedEnemy = _applyBuff(enemy, false);
        Buff[] memory barriers = new Buff[](8);
        uint256 barrierCount;
        // cauculate absolute dodge and barriers
        for (uint256 i = 0; i < enemy.buffCount; i++) {
            if (enemy.buffs[i].duration == 0) {
                continue;
            }
            uint32 id = enemy.buffs[i].id % (MAX_CARD_ID + 1);

            if (id == 18) {
                enemy.buffs[i].duration--;
                return 0;
            } else if (id == 15) {
                // for now only one buff can get barrier
                barriers[0] = enemy.buffs[i];
                barrierCount++;
            }
        }

        PlayerState memory buffedSelf = _applyBuff(self, true);

        if (buffedSelf.hitRate >= randomness % 100 + buffedEnemy.dodgeRate) {
            damage = damage * buffedSelf.damageIncrease * buffedEnemy.damageReduction / 10000;
            if (buffedSelf.critRate >= uint256(keccak256(abi.encode(randomness))) % 100) {
                damage = damage * buffedSelf.critDamage / 100;
                // emit log_named_uint("crit! damage", damage);
            }
            // absorb damage by barrier
            for (uint256 i = 0; i < barrierCount; i++) {
                if (barriers[i].barrier >= damage) {
                    barriers[i].barrier -= damage;
                    return 0;
                } else {
                    damage -= barriers[i].barrier;
                    barriers[i].barrier = 0;
                    barriers[i].duration = 0;
                }
            }
            enemy.health = enemy.health > damage ? enemy.health - damage : 0;
            return damage;
        }
        // emit log_named_uint("dodge! damage", 0);

        return 0;
    }

    function _prepareCards(uint32[] memory cardIds) internal pure returns (Card[] memory) {
        Card[] memory cards = new Card[](cardIds.length);
        for (uint256 i = 0; i < cardIds.length; i++) {
            cards[i] = _getCard(cardIds[i]);
        }
        return cards;
    }

    function _getCard(uint32 cardId) internal pure returns (Card memory) {
        (uint8 level, uint32 id) = _getLevelAndId(cardId);
        if (id == 6 || id == 23 || id == 26) {
            return Card(cardId, level);
        }
        return Card(cardId, 99);
    }

    function _castCard(Card memory card, PlayerState memory self, PlayerState memory enemy, uint256 randomness)
        internal
        pure
    {
        uint32 cardId = card.id;
        (uint8 level, uint32 id) = _getLevelAndId(cardId);
        // cast card id from 0 to 28
        if (id == 0) {
            _handleDamage(self, enemy, self.damage, randomness);
        } else if (id == 1) {
            _handleDamage(self, enemy, enemy.maxHealth / 20, randomness);
            if (level == 1) {
                Buff memory buff = Buff(cardId, false, 2, 0);
                _addBuff(enemy, buff);
            } else if (level == 2) {
                Buff memory buff = Buff(cardId, false, 3, 0);
                _addBuff(enemy, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, false, 4, 0);
                _addBuff(enemy, buff);
            }
        } else if (id == 2) {
            _countDownRoundBuff(self);
            if (level == 1) {
                Buff memory buff = Buff(cardId, false, 2, 0);
                _addBuff(enemy, buff);
            } else if (level == 2) {
                Buff memory buff = Buff(cardId, false, 2, 0);
                _addBuff(enemy, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, false, 3, 0);
                _addBuff(enemy, buff);
            }
        } else if (id == 3) {
            _handleDamage(self, enemy, self.damage, randomness);
            if (level == 1) {
                Buff memory buff = Buff(cardId, false, 2, 0);
                _addBuff(enemy, buff);
            } else if (level == 2) {
                Buff memory buff = Buff(cardId, false, 3, 0);
                _addBuff(enemy, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, false, 4, 0);
                _addBuff(enemy, buff);
            }
        } else if (id == 4) {
            _countDownRoundBuff(self);
            if (level == 1) {
                Buff memory buff = Buff(cardId, true, 2, 0);
                _addBuff(self, buff);
            } else if (level == 2) {
                Buff memory buff = Buff(cardId, true, 3, 0);
                _addBuff(self, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, true, 5, 0);
                _addBuff(self, buff);
            }
        } else if (id == 5) {
            _countDownRoundBuff(self);
            self.actionable = Actionable.Continuous;
            Buff memory buff = Buff(cardId, true, 1, 0);
            _addBuff(self, buff);
        } else if (id == 6) {
            if (card.available > 0) {
                _countDownRoundBuff(self);
                card.available--;
                self.actionable = Actionable.Continuous;
            } else {
                _handleDamage(self, enemy, self.damage, randomness);
            }
        } else if (id == 7) {
            if (level == 1) {
                _handleDamage(self, enemy, self.damage, randomness);
                Buff memory buff = Buff(cardId, false, 1, 0);
                _addBuff(enemy, buff);
            } else if (level == 2) {
                _handleDamage(self, enemy, self.damage, randomness);
                Buff memory buff = Buff(cardId, false, 2, 0);
                _addBuff(enemy, buff);
            } else if (level == 3) {
                _handleDamage(self, enemy, self.damage * 2, randomness);
                Buff memory buff = Buff(cardId, false, 3, 0);
                _addBuff(enemy, buff);
            }
        } else if (id == 8) {
            if (level == 1) {
                _handleDamage(
                    self,
                    enemy,
                    2 * self.damage + 2 * self.damage * (self.maxHealth - self.health) / self.maxHealth,
                    randomness
                );
            } else if (level == 2) {
                _handleDamage(
                    self,
                    enemy,
                    2 * self.damage + 4 * self.damage * (self.maxHealth - self.health) / self.maxHealth,
                    randomness
                );
            } else if (level == 3) {
                _handleDamage(
                    self,
                    enemy,
                    2 * self.damage + 6 * self.damage * (self.maxHealth - self.health) / self.maxHealth,
                    randomness
                );
            }
        } else if (id == 9) {
            _countDownRoundBuff(self);
            if (level == 1) {
                _removeBuff(enemy, 1, true);
            } else if (level == 2) {
                _removeBuff(enemy, 2, true);
            } else if (level == 3) {
                _removeBuff(enemy, 3, true);
            }
        } else if (id == 10) {
            _countDownRoundBuff(self);
            if (level == 1) {
                Buff memory buff = Buff(cardId, false, 2, 0);
                _addBuff(enemy, buff);
            } else if (level == 2) {
                Buff memory buff = Buff(cardId, false, 3, 0);
                _addBuff(enemy, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, false, 5, 0);
                _addBuff(enemy, buff);
            }
        } else if (id == 11) {
            uint32 damage;
            if (level == 1) {
                damage = _handleDamage(self, enemy, self.damage * 2, randomness);
            } else if (level == 2) {
                damage = _handleDamage(self, enemy, self.damage * 3, randomness);
            } else if (level == 3) {
                damage = _handleDamage(self, enemy, self.damage * 4, randomness);
            }
            if (damage > 0) {
                self.health = (self.health + damage) > self.maxHealth ? self.maxHealth : (self.health + damage);
            }
        } else if (id == 12) {
            uint32 damage;
            if (level == 1) {
                damage = _removeBuff(enemy, 12) ? self.damage * 4 : self.damage;
            } else if (level == 2) {
                damage = _removeBuff(enemy, 12) ? self.damage * 6 : (self.damage * 2);
            } else if (level == 3) {
                damage = _removeBuff(enemy, 12) ? self.damage * 8 : (self.damage * 3);
            }
            _handleDamage(self, enemy, damage, randomness);
        } else if (id == 13) {
            _countDownRoundBuff(self);
            if (level == 1) {
                Buff memory buff = Buff(cardId, true, 2, 0);
                _addBuff(self, buff);
            } else if (level == 2) {
                Buff memory buff = Buff(cardId, true, 2, 0);
                _addBuff(self, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, true, 3, 0);
                _addBuff(self, buff);
            }
        } else if (id == 14) {
            _countDownRoundBuff(self);
            if (level == 1) {
                _removeBuff(self, 1, false);
                Buff memory buff = Buff(cardId, true, 1, 0);
                _addBuff(self, buff);
            } else if (level == 2) {
                _removeBuff(self, 1, false);
                Buff memory buff = Buff(cardId, true, 2, 0);
                _addBuff(self, buff);
            } else if (level == 3) {
                _removeBuff(self, 2, false);
                Buff memory buff = Buff(cardId, true, 3, 0);
                _addBuff(self, buff);
            }
        } else if (id == 15) {
            _countDownRoundBuff(self);
            if (level == 1) {
                Buff memory buff = Buff(cardId, true, 3, self.maxHealth * 3 / 10);
                _addBuff(self, buff);
            } else if (level == 2) {
                Buff memory buff = Buff(cardId, true, 4, self.maxHealth * 4 / 10);
                _addBuff(self, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, true, 5, self.maxHealth * 5 / 10);
                _addBuff(self, buff);
            }
        } else if (id == 16) {
            _countDownRoundBuff(self);
            if (level == 1) {
                Buff memory buff = Buff(cardId, true, 2, 0);
                _addBuff(self, buff);
            } else if (level == 2) {
                Buff memory buff = Buff(cardId, true, 2, 0);
                _addBuff(self, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, true, 2, 0);
                _addBuff(self, buff);
            }
        } else if (id == 17) {
            _countDownRoundBuff(self);
            if (level == 1) {
                Buff memory buff = Buff(cardId, false, 2, 0);
                _addBuff(enemy, buff);
            } else if (level == 2) {
                Buff memory buff = Buff(cardId, false, 3, 0);
                _addBuff(enemy, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, false, 4, 0);
                _addBuff(enemy, buff);
            }
        } else if (id == 18) {
            _handleDamage(self, enemy, self.damage * 2, randomness);
            if (level == 2) {
                Buff memory buff = Buff(cardId, false, 1, 0);
                _addBuff(enemy, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, false, 2, 0);
                _addBuff(enemy, buff);
            }
        } else if (id == 19) {
            _handleDamage(self, enemy, self.damage, randomness);
        } else if (id == 20) {
            _countDownRoundBuff(self);
            if (level == 1) {
                Buff memory buff = Buff(cardId, true, 1, 0);
                _addBuff(self, buff);
            } else if (level == 2) {
                Buff memory buff = Buff(cardId, true, 2, 0);
                _addBuff(self, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, true, 3, 0);
                _addBuff(self, buff);
            }
        } else if (id == 21) {
            _countDownRoundBuff(self);
            if (level == 1) {
                Buff memory buff = Buff(cardId, true, 2, 0);
                _addBuff(self, buff);
            } else if (level == 2) {
                Buff memory buff = Buff(cardId, true, 2, 0);
                _addBuff(self, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, true, 3, 0);
                _addBuff(self, buff);
            }
        } else if (id == 22) {
            _countDownRoundBuff(self);
            if (level == 1) {
                Buff memory buff = Buff(cardId, true, 3, 0);
                _addBuff(self, buff);
            } else if (level == 2) {
                Buff memory buff = Buff(cardId, true, 4, 0);
                _addBuff(self, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, true, 5, 0);
                _addBuff(self, buff);
            }
        } else if (id == 23) {
            if (card.available > 0) {
                _countDownRoundBuff(self);
                card.available--;
                enemy.actionable = Actionable.Jump;
            } else {
                _handleDamage(self, enemy, self.damage, randomness);
            }
        } else if (id == 24) {
            _countDownRoundBuff(self);
            uint32 heal;
            if (level == 1) {
                heal = self.maxHealth / 10;
            } else if (level == 2) {
                heal = self.maxHealth * 2 / 10;
            } else if (level == 3) {
                heal = self.maxHealth * 3 / 10;
            }
            self.health = (self.health + heal) > self.maxHealth ? self.maxHealth : (self.health + heal);
        } else if (id == 25) {
            uint32 originalHitRate = self.hitRate;

            if (level == 1) {
                self.hitRate = self.hitRate > 30 ? self.hitRate - 30 : 0;
                _handleDamage(self, enemy, self.damage * 3, randomness);
            } else if (level == 2) {
                self.hitRate = self.hitRate > 20 ? self.hitRate - 20 : 0;
                _handleDamage(self, enemy, self.damage * 4, randomness);
            } else if (level == 3) {
                self.hitRate = self.hitRate > 10 ? self.hitRate - 10 : 0;
                _handleDamage(self, enemy, self.damage * 5, randomness);
            }
            self.hitRate = originalHitRate;
        } else if (id == 26) {
            if (card.available > 0) {
                _countDownRoundBuff(self);
                card.available--;
                enemy.actionable = Actionable.Stop;
            } else {
                _handleDamage(self, enemy, self.damage, randomness);
            }
        } else if (id == 27) {
            _countDownRoundBuff(self);
            if (level == 1) {
                Buff memory buff = Buff(cardId, false, 3, 0);
                _addBuff(enemy, buff);
            } else if (level == 2) {
                Buff memory buff = Buff(cardId, false, 4, 0);
                _addBuff(enemy, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, false, 5, 0);
                _addBuff(enemy, buff);
            }
        }
    }

    function _triggerRoundBuff(PlayerState memory self, PlayerState memory enemy) internal pure {
        for (uint256 i = 0; i < self.buffCount; i++) {
            if (self.buffs[i].duration == 0) {
                continue;
            }

            (uint8 level, uint32 id) = _getLevelAndId(self.buffs[i].id);
            if (id == 1) {
                uint32 damage;
                if (level == 1) {
                    damage = enemy.damage;
                } else if (level == 2) {
                    damage = enemy.damage;
                } else if (level == 3) {
                    damage = enemy.damage * 3 / 2;
                }
                self.health = self.health > damage ? self.health - damage : 0;
            } else if (id == 3) {
                uint32 damage;
                if (level == 1) {
                    damage = self.health * 3 / 100;
                } else if (level == 2) {
                    damage = self.health * 4 / 100;
                } else if (level == 3) {
                    damage = self.health * 5 / 100;
                }
                self.health = self.health > damage ? self.health - damage : 0;
            } else if (id == 7) {
                uint32 damage;
                if (level == 1) {
                    damage = enemy.damage / 2;
                } else if (level == 2) {
                    damage = enemy.damage * 4 / 5;
                } else if (level == 3) {
                    damage = enemy.damage;
                }
                self.health = self.health > damage ? self.health - damage : 0;
            } else if (id == 17) {
                uint32 damage;
                if (level == 1) {
                    damage = self.maxHealth * 6 / 100;
                } else if (level == 2) {
                    damage = self.maxHealth * 8 / 100;
                } else if (level == 3) {
                    damage = self.maxHealth / 10;
                }
                self.health = self.health > damage ? self.health - damage : 0;
            } else if (id == 22) {
                uint32 health;
                if (level == 1) {
                    health = self.maxHealth * 4 / 100;
                } else if (level == 2) {
                    health = self.maxHealth * 6 / 100;
                } else if (level == 3) {
                    health = self.maxHealth * 8 / 100;
                }
                self.health = self.health + health > self.maxHealth ? self.maxHealth : self.health + health;
            }
        }
    }

    function _applyPassiveCard(PlayerState memory self, Card[] memory cards) internal pure {
        for (uint256 i = 0; i < cards.length; i++) {
            (uint8 level, uint32 id) = _getLevelAndId(cards[i].id);
            if (id == 19) {
                if (level == 1) {
                    self.damage = self.damage * 3 / 2;
                } else if (level == 2) {
                    self.damage = self.damage * 18 / 10;
                } else if (level == 3) {
                    self.damage = self.damage * 2;
                }
            }
        }
    }

    function _applyBuff(PlayerState memory self, bool countDownBuff) internal pure returns (PlayerState memory) {
        PlayerState memory buffed = PlayerState(
            0,
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
            new Buff[](0)
        );

        for (uint256 i = 0; i < self.buffCount; i++) {
            if (self.buffs[i].duration == 0) {
                continue;
            }

            (uint8 level, uint32 id) = _getLevelAndId(self.buffs[i].id);
            if (id == 2) {
                if (level == 1) {
                    buffed.damageIncrease = buffed.damageIncrease * 9 / 10;
                } else if (level == 2) {
                    buffed.damageIncrease = buffed.damageIncrease * 85 / 100;
                } else if (level == 3) {
                    buffed.damageIncrease = buffed.damageIncrease * 70 / 100;
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
                    buffed.damageReduction = buffed.damageReduction * 8 / 10;
                } else if (level == 2) {
                    buffed.damageReduction = buffed.damageReduction * 8 / 10;
                } else if (level == 3) {
                    buffed.damageReduction = buffed.damageReduction * 7 / 10;
                }
            } else if (id == 14) {
                if (level == 1) {
                    buffed.damageIncrease = buffed.damageIncrease * 11 / 10;
                } else if (level == 2) {
                    buffed.damageIncrease = buffed.damageIncrease * 12 / 10;
                } else if (level == 3) {
                    buffed.damageIncrease = buffed.damageIncrease * 13 / 10;
                }
            } else if (id == 16) {
                if (level == 1) {
                    buffed.damageReduction = buffed.damageReduction / 2;
                } else if (level == 2) {
                    buffed.damageReduction = buffed.damageReduction * 3 / 10;
                } else if (level == 3) {
                    buffed.damageReduction = buffed.damageReduction / 10;
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
                    buffed.damageIncrease = buffed.damageIncrease * (100 - 10 * (4 - self.buffs[i].duration)) / 100;
                } else if (level == 2) {
                    buffed.damageIncrease = buffed.damageIncrease * (100 - 10 * (5 - self.buffs[i].duration)) / 100;
                } else if (level == 3) {
                    buffed.damageIncrease = buffed.damageIncrease * (100 - 10 * (6 - self.buffs[i].duration)) / 100;
                }
            }

            if (id != 18 && countDownBuff) {
                self.buffs[i].duration--;
            }
        }

        return buffed;
    }

    function _getLevelAndId(uint32 cardId) internal pure returns (uint8 level, uint32 id) {
        return (uint8(cardId / (MAX_CARD_ID + 1)) + 1, cardId % (MAX_CARD_ID + 1));
    }

    function _countDownRoundBuff(PlayerState memory self) internal pure {
        // count down round-based buff duration except for one-time buff
        for (uint256 i = 0; i < self.buffCount; i++) {
            if (self.buffs[i].duration == 0) {
                continue;
            }
            (, uint32 id) = _getLevelAndId(self.buffs[i].id);
            if (id != 18) {
                self.buffs[i].duration--;
            }
        }
    }

    function _parseCardQuality(uint256 qualityNum) internal pure returns (CardQuality quality) {
        if (qualityNum == 0) {
            return CardQuality.Low;
        } else if (qualityNum == 1) {
            return CardQuality.Middle;
        } else if (qualityNum == 2) {
            return CardQuality.High;
        }
    }
}
