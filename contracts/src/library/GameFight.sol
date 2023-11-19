// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library GameFight {
    uint32 public constant MAX_CARD_INDEX = 27;
    uint32 public constant MAX_ROUND = 100;

    struct Card {
        uint32 id;
        // uint8 sect;
        uint8 available;
    }

    struct Buff {
        uint32 id;
        bool positive;
        uint8 duration;
        uint32 barrier;
    }

    enum Actionable {
        Normal,
        Continuous,
        Stop,
        Jump
    }

    struct PlayerState {
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

    function fight(
        PlayerState memory a,
        PlayerState memory b,
        uint32[] memory aSequence,
        uint32[] memory bSequence,
        bool aAction,
        uint256 randomness
    ) public pure returns (bool aWin) {
        Card[] memory aCards = prepareCards(aSequence);
        Card[] memory bCards = prepareCards(bSequence);
        applyPassiveCard(a, aCards);
        applyPassiveCard(b, bCards);

        uint256 i;
        uint256 j;
        uint32 round;

        // a and b take turns to cast card from round-robin sequence
        for (;;) {
            if (aAction) {
                do {
                    if (round > MAX_ROUND) {
                        return forceEnd(a, b);
                    }
                    if (a.actionable == Actionable.Continuous) {
                        a.actionable = Actionable.Normal;
                    }
                    triggerRoundBuff(a, b);
                    if (!checkHealth(a)) {
                        return false;
                    }
                    Card memory card = Card(0, 1);
                    if (a.actionable == Actionable.Jump) {
                        i++;
                        i %= aSequence.length;
                        card = aCards[i];
                    } else if (a.actionable == Actionable.Normal) {
                        card = aCards[i];
                    }
                    castCard(card, a, b, randomness);
                    if (!checkHealth(b)) {
                        return true;
                    }
                    if (a.actionable != Actionable.Stop) {
                        i++;
                        i %= aSequence.length;
                    }
                    aAction = false;
                    randomness = uint256(keccak256(abi.encode(randomness)));
                    round++;
                } while (a.actionable == Actionable.Continuous);
            } else {
                do {
                    if (round > MAX_ROUND) {
                        return forceEnd(a, b);
                    }
                    if (b.actionable == Actionable.Continuous) {
                        b.actionable = Actionable.Normal;
                    }
                    triggerRoundBuff(b, a);
                    if (!checkHealth(b)) {
                        return true;
                    }
                    Card memory card = Card(0, 1);
                    if (b.actionable == Actionable.Jump) {
                        j++;
                        j %= bSequence.length;
                        card = bCards[j];
                    } else if (b.actionable == Actionable.Normal) {
                        card = bCards[j];
                    }
                    castCard(card, b, a, randomness);
                    if (!checkHealth(a)) {
                        return false;
                    }
                    if (b.actionable != Actionable.Stop) {
                        j++;
                        j %= bSequence.length;
                    }
                    aAction = true;
                    randomness = uint256(keccak256(abi.encode(randomness)));
                    round++;
                } while (b.actionable == Actionable.Continuous);
            }
        }
    }

    function checkHealth(PlayerState memory state) internal pure returns (bool) {
        return state.health > 0;
    }

    function forceEnd(PlayerState memory a, PlayerState memory b) internal pure returns (bool) {
        return a.health > b.health;
    }

    // Buff with the same id will be replaced
    function addBuff(PlayerState memory state, Buff memory buff) internal pure {
        for (uint256 i = 0; i < state.buffCount; i++) {
            if (state.buffs[i].id % MAX_CARD_INDEX == buff.id % MAX_CARD_INDEX) {
                state.buffs[i].duration = 0;
                break;
            }
        }
        state.buffs[state.buffCount] = buff;
        state.buffCount++;
    }

    function removeBuff(PlayerState memory state, uint256 count, bool positive) internal pure {
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

    function removeBuff(PlayerState memory state, uint32 buffId) internal pure returns (bool) {
        for (uint256 i = 0; i < state.buffCount; i++) {
            if (state.buffs[i].duration > 0 && state.buffs[i].id % MAX_CARD_INDEX == buffId % MAX_CARD_INDEX) {
                state.buffs[i].duration = 0;
                return true;
            }
        }
        return false;
    }

    function handleDamage(PlayerState memory self, PlayerState memory enemy, uint32 damage, uint256 randomness)
        internal
        pure
        returns (uint32)
    {
        PlayerState memory buffedEnemy = applyBuff(enemy);
        Buff[] memory barriers = new Buff[](8);
        uint256 barrierCount;
        // cauculate absolute dodge and barriers
        for (uint256 i = 0; i < enemy.buffCount; i++) {
            if (enemy.buffs[i].duration == 0) {
                continue;
            }
            uint32 id = enemy.buffs[i].id % MAX_CARD_INDEX;

            if (id == 18) {
                enemy.buffs[i].duration--;
                return 0;
            } else if (id == 15) {
                // for now only one buff can get barrier
                barriers[0] = enemy.buffs[i];
                barrierCount++;
            }
        }

        PlayerState memory buffedSelf = applyBuff(self);

        if (buffedSelf.hitRate >= randomness % 100 + buffedEnemy.dodgeRate) {
            damage = damage * buffedSelf.damageIncrease * buffedEnemy.damageReduction / 10000;
            if (buffedSelf.critRate >= uint256(keccak256(abi.encode(randomness))) % 100) {
                damage = damage * buffedSelf.critDamage / 100;
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

        return 0;
    }

    function prepareCards(uint32[] memory cardIds) internal pure returns (Card[] memory) {
        Card[] memory cards = new Card[](cardIds.length);
        for (uint256 i = 0; i < cardIds.length; i++) {
            cards[i] = getCard(cardIds[i]);
        }
        return cards;
    }

    function getCard(uint32 cardId) internal pure returns (Card memory) {
        (uint8 level, uint32 id) = (uint8(cardId / MAX_CARD_INDEX + 1), cardId % MAX_CARD_INDEX);
        if (id == 6 || id == 23 || id == 26) {
            return Card(cardId, level);
        }
        return Card(cardId, 99);
    }

    function castCard(Card memory card, PlayerState memory self, PlayerState memory enemy, uint256 randomness)
        internal
        pure
    {
        uint32 cardId = card.id;
        (uint8 level, uint32 id) = (uint8(cardId / MAX_CARD_INDEX + 1), cardId % MAX_CARD_INDEX);
        // cast card id from 0 to 28
        if (id == 0) {
            handleDamage(self, enemy, self.damage, randomness);
        } else if (id == 1) {
            handleDamage(self, enemy, enemy.maxHealth / 20, randomness);
            if (level == 1) {
                Buff memory buff = Buff(cardId, false, 2, 0);
                addBuff(enemy, buff);
            } else if (level == 2) {
                Buff memory buff = Buff(cardId, false, 3, 0);
                addBuff(enemy, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, false, 4, 0);
                addBuff(enemy, buff);
            }
        } else if (id == 2) {
            if (level == 1) {
                Buff memory buff = Buff(cardId, false, 2, 0);
                addBuff(enemy, buff);
            } else if (level == 2) {
                Buff memory buff = Buff(cardId, false, 2, 0);
                addBuff(enemy, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, false, 3, 0);
                addBuff(enemy, buff);
            }
        } else if (id == 3) {
            handleDamage(self, enemy, self.damage, randomness);
            if (level == 1) {
                Buff memory buff = Buff(cardId, false, 2, 0);
                addBuff(enemy, buff);
            } else if (level == 2) {
                Buff memory buff = Buff(cardId, false, 3, 0);
                addBuff(enemy, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, false, 4, 0);
                addBuff(enemy, buff);
            }
        } else if (id == 4) {
            if (level == 1) {
                Buff memory buff = Buff(cardId, true, 2, 0);
                addBuff(self, buff);
            } else if (level == 2) {
                Buff memory buff = Buff(cardId, true, 3, 0);
                addBuff(self, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, true, 5, 0);
                addBuff(self, buff);
            }
        } else if (id == 5) {
            self.actionable = Actionable.Continuous;
            Buff memory buff = Buff(cardId, true, 1, 0);
            addBuff(self, buff);
        } else if (id == 6) {
            if (card.available > 0) {
                card.available--;
                self.actionable = Actionable.Continuous;
            } else {
                handleDamage(self, enemy, self.damage, randomness);
            }
        } else if (id == 7) {
            if (level == 1) {
                handleDamage(self, enemy, self.damage, randomness);
                Buff memory buff = Buff(cardId, false, 1, 0);
                addBuff(enemy, buff);
            } else if (level == 2) {
                handleDamage(self, enemy, self.damage, randomness);
                Buff memory buff = Buff(cardId, false, 2, 0);
                addBuff(enemy, buff);
            } else if (level == 3) {
                handleDamage(self, enemy, self.damage * 2, randomness);
                Buff memory buff = Buff(cardId, false, 3, 0);
                addBuff(enemy, buff);
            }
        } else if (id == 8) {
            if (level == 1) {
                handleDamage(
                    self,
                    enemy,
                    2 * self.damage + 2 * self.damage * (self.maxHealth - self.health) / self.maxHealth,
                    randomness
                );
            } else if (level == 2) {
                handleDamage(
                    self,
                    enemy,
                    2 * self.damage + 4 * self.damage * (self.maxHealth - self.health) / self.maxHealth,
                    randomness
                );
            } else if (level == 3) {
                handleDamage(
                    self,
                    enemy,
                    2 * self.damage + 6 * self.damage * (self.maxHealth - self.health) / self.maxHealth,
                    randomness
                );
            }
        } else if (id == 9) {
            if (level == 1) {
                removeBuff(enemy, 1, true);
            } else if (level == 2) {
                removeBuff(enemy, 2, true);
            } else if (level == 3) {
                removeBuff(enemy, 3, true);
            }
        } else if (id == 10) {
            if (level == 1) {
                Buff memory buff = Buff(cardId, false, 2, 0);
                addBuff(enemy, buff);
            } else if (level == 2) {
                Buff memory buff = Buff(cardId, false, 3, 0);
                addBuff(enemy, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, false, 5, 0);
                addBuff(enemy, buff);
            }
        } else if (id == 11) {
            uint32 damage;
            if (level == 1) {
                damage = handleDamage(self, enemy, self.damage * 2, randomness);
            } else if (level == 2) {
                damage = handleDamage(self, enemy, self.damage * 3, randomness);
            } else if (level == 3) {
                damage = handleDamage(self, enemy, self.damage * 4, randomness);
            }
            if (damage > 0) {
                self.health = (self.health + damage) > self.maxHealth ? self.maxHealth : (self.health + damage);
            }
        } else if (id == 12) {
            uint32 damage;
            if (level == 1) {
                damage = removeBuff(enemy, 12) ? self.damage * 4 : self.damage;
            } else if (level == 2) {
                damage = removeBuff(enemy, 12) ? self.damage * 6 : (self.damage * 2);
            } else if (level == 3) {
                damage = removeBuff(enemy, 12) ? self.damage * 8 : (self.damage * 3);
            }
            handleDamage(self, enemy, damage, randomness);
        } else if (id == 13) {
            if (level == 1) {
                Buff memory buff = Buff(cardId, true, 2, 0);
                addBuff(self, buff);
            } else if (level == 2) {
                Buff memory buff = Buff(cardId, true, 2, 0);
                addBuff(self, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, true, 3, 0);
                addBuff(self, buff);
            }
        } else if (id == 14) {
            if (level == 1) {
                removeBuff(self, 1, false);
                Buff memory buff = Buff(cardId, true, 1, 0);
                addBuff(self, buff);
            } else if (level == 2) {
                removeBuff(self, 1, false);
                Buff memory buff = Buff(cardId, true, 2, 0);
                addBuff(self, buff);
            } else if (level == 3) {
                removeBuff(self, 2, false);
                Buff memory buff = Buff(cardId, true, 3, 0);
                addBuff(self, buff);
            }
        } else if (id == 15) {
            if (level == 1) {
                Buff memory buff = Buff(cardId, true, 3, self.maxHealth * 3 / 10);
                addBuff(self, buff);
            } else if (level == 2) {
                Buff memory buff = Buff(cardId, true, 4, self.maxHealth * 4 / 10);
                addBuff(self, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, true, 5, self.maxHealth * 5 / 10);
                addBuff(self, buff);
            }
        } else if (id == 16) {
            if (level == 1) {
                Buff memory buff = Buff(cardId, true, 2, 0);
                addBuff(self, buff);
            } else if (level == 2) {
                Buff memory buff = Buff(cardId, true, 2, 0);
                addBuff(self, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, true, 2, 0);
                addBuff(self, buff);
            }
        } else if (id == 17) {
            if (level == 1) {
                Buff memory buff = Buff(cardId, false, 2, 0);
                addBuff(enemy, buff);
            } else if (level == 2) {
                Buff memory buff = Buff(cardId, false, 3, 0);
                addBuff(enemy, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, false, 4, 0);
                addBuff(enemy, buff);
            }
        } else if (id == 18) {
            handleDamage(self, enemy, self.damage * 2, randomness);
            if (level == 2) {
                Buff memory buff = Buff(cardId, false, 1, 0);
                addBuff(enemy, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, false, 2, 0);
                addBuff(enemy, buff);
            }
        } else if (id == 19) {
            handleDamage(self, enemy, self.damage, randomness);
        } else if (id == 20) {
            if (level == 1) {
                Buff memory buff = Buff(cardId, true, 1, 0);
                addBuff(self, buff);
            } else if (level == 2) {
                Buff memory buff = Buff(cardId, true, 2, 0);
                addBuff(self, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, true, 3, 0);
                addBuff(self, buff);
            }
        } else if (id == 21) {
            if (level == 1) {
                Buff memory buff = Buff(cardId, true, 2, 0);
                addBuff(self, buff);
            } else if (level == 2) {
                Buff memory buff = Buff(cardId, true, 2, 0);
                addBuff(self, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, true, 3, 0);
                addBuff(self, buff);
            }
        } else if (id == 22) {
            if (level == 1) {
                Buff memory buff = Buff(cardId, true, 3, 0);
                addBuff(self, buff);
            } else if (level == 2) {
                Buff memory buff = Buff(cardId, true, 4, 0);
                addBuff(self, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, true, 5, 0);
                addBuff(self, buff);
            }
        } else if (id == 23) {
            if (card.available > 0) {
                card.available--;
                enemy.actionable = Actionable.Jump;
            } else {
                handleDamage(self, enemy, self.damage, randomness);
            }
        } else if (id == 24) {
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
                handleDamage(self, enemy, self.damage * 3, randomness);
            } else if (level == 2) {
                self.hitRate = self.hitRate > 20 ? self.hitRate - 20 : 0;
                handleDamage(self, enemy, self.damage * 4, randomness);
            } else if (level == 3) {
                self.hitRate = self.hitRate > 10 ? self.hitRate - 10 : 0;
                handleDamage(self, enemy, self.damage * 5, randomness);
            }
            self.hitRate = originalHitRate;
        } else if (id == 26) {
            if (card.available > 0) {
                card.available--;
                enemy.actionable = Actionable.Stop;
            } else {
                handleDamage(self, enemy, self.damage, randomness);
            }
        } else if (id == 27) {
            if (level == 1) {
                Buff memory buff = Buff(cardId, false, 3, 0);
                addBuff(enemy, buff);
            } else if (level == 2) {
                Buff memory buff = Buff(cardId, false, 4, 0);
                addBuff(enemy, buff);
            } else if (level == 3) {
                Buff memory buff = Buff(cardId, false, 5, 0);
                addBuff(enemy, buff);
            }
        }
    }

    function triggerRoundBuff(PlayerState memory self, PlayerState memory enemy) internal pure {
        for (uint256 i = 0; i < self.buffCount; i++) {
            if (self.buffs[i].duration == 0) {
                continue;
            }

            (uint8 level, uint32 id) = (uint8(self.buffs[i].id / MAX_CARD_INDEX + 1), self.buffs[i].id % MAX_CARD_INDEX);
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

    function applyPassiveCard(PlayerState memory self, Card[] memory cards) internal pure {
        for (uint256 i = 0; i < cards.length; i++) {
            (uint8 level, uint32 id) = (uint8(cards[i].id / MAX_CARD_INDEX + 1), cards[i].id % MAX_CARD_INDEX);
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

    function applyBuff(PlayerState memory self) internal pure returns (PlayerState memory) {
        PlayerState memory buffed = PlayerState(
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

            (uint8 level, uint32 id) = (uint8(self.buffs[i].id / MAX_CARD_INDEX + 1), self.buffs[i].id % MAX_CARD_INDEX);
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
            // count down round-based buff duration except for one-time buff
            if (id != 18) {
                self.buffs[i].duration--;
            }
        }

        return buffed;
    }
}
