import { MAX_CARD_ID } from "../constants/card_constant";
import Web3 from "web3";

export const LOW_QUALITY_CARD_IDS = [2, 3, 4, 10, 18, 20, 22, 24, 25];
export const MIDDLE_QUALITY_CARD_IDS = [1, 6, 7, 12, 13, 14, 21, 23, 27];
export const HIGH_QUALITY_CARD_IDS = [5, 8, 9, 11, 15, 16, 17, 19, 26];

export const BuffType = {
  None: 0,
  Buff: 1,
  Debuff: 2,
  TimedBuff: 3,
  Passive: 4,
};

export const SectType = {
  Attack: 0,
  Defense: 1,
  Enhance: 2,
  Weaken: 3,
};

export const QualityType = {
  Low: 1,
  Middle: 2,
  High: 3,
};

let web3 = new Web3();

class Card {
  constructor(
    id,
    level,
    sect,
    quality,
    name,
    pic,
    desc,
    buff_desc = "",
    buff_type = BuffType.None,
    continue_turns = 0,
    available_times = 99,
    continuous_action = false
  ) {
    this.id = id;
    this.level = level;
    this.sect = sect;
    this.quality = quality;
    this.name = name;
    this.pic = pic;
    this.desc = desc;
    this.buff_desc = buff_desc;
    this.buff_type = buff_type;
    this.continue_turns = continue_turns;
    this.available_times = available_times;
    this.continuous_action = continuous_action;
    this.picked = false;
  }
}

export function repeatedDraw(seed, fromCards, count) {
  let chosenIds = [];
  for (let i = 0; i < count; i++) {
    let index = parseInt(
      web3.utils
        .toBN(web3.utils.soliditySha3(seed, i))
        .mod(web3.utils.toBN(fromCards.length))
        .toNumber()
    );
    chosenIds[i] = fromCards[index];
  }
  return chosenIds;
}

export function getCard(id) {
  let [level, primaryId] = getLevelAndId(id);
  let debuff_value = 0;
  let buff_value = 0;
  let value = 0;
  let turns = 0;
  switch (primaryId) {
    case 1:
      debuff_value = level == 3 ? 150 : level == 2 ? 100 : 100;
      turns = level == 3 ? 4 : level == 2 ? 3 : 2;
      return new Card(
        id,
        level,
        SectType.Weaken,
        QualityType.Middle,
        "利刃突袭",
        "/images/skill/1.png",
        "造成对方最大生命值5%伤害",
        `造成我方基础伤害${debuff_value}%`,
        BuffType.Debuff,
        turns
      );
    case 2:
      debuff_value = level == 3 ? 30 : level == 2 ? 15 : 10;
      turns = level == 3 ? 3 : level == 2 ? 2 : 2;
      return new Card(
        id,
        level,
        SectType.Weaken,
        QualityType.Low,
        "黑雾笼罩",
        "/images/skill/2.png",
        "",
        `对方造成伤害-${debuff_value}%`,
        BuffType.Debuff,
        turns
      );
    case 3:
      debuff_value = level == 3 ? 5 : level == 2 ? 4 : 3;
      turns = level == 3 ? 4 : level == 2 ? 3 : 2;
      return new Card(
        id,
        level,
        SectType.Weaken,
        QualityType.Low,
        "荆棘缠身",
        "/images/skill/3.png",
        "造成基础伤害",
        `对方损失当前生命值${debuff_value}%`,
        BuffType.Debuff,
        turns
      );
    case 4:
      buff_value = level == 3 ? 40 : level == 2 ? 20 : 10;
      turns = level == 3 ? 5 : level == 2 ? 3 : 2;
      return new Card(
        id,
        level,
        SectType.Attack,
        QualityType.Low,
        "高爆准备",
        "/images/skill/4.png",
        "",
        `己方暴击率+${buff_value}%`,
        BuffType.Buff,
        turns
      );
    case 5:
      buff_value = level == 3 ? 30 : level == 2 ? 20 : 10;
      return new Card(
        id,
        level,
        SectType.Enhance,
        QualityType.High,
        "高效迭代",
        "/images/skill/5.png",
        "",
        `己方命中率+${buff_value}%`,
        BuffType.Buff,
        1,
        99,
        true
      );
    case 6:
      value = level == 3 ? 3 : level == 2 ? 2 : 1;
      return new Card(
        id,
        level,
        SectType.Enhance,
        QualityType.Middle,
        "快速冷却",
        "/images/skill/6.png",
        "",
        "",
        BuffType.None,
        0,
        value,
        true
      );
    case 7:
      value = level == 3 ? 2 : level == 2 ? 1 : 1;
      turns = level == 3 ? 3 : level == 2 ? 2 : 1;
      debuff_value = level == 3 ? 100 : level == 2 ? 80 : 50;
      return new Card(
        id,
        level,
        SectType.Attack,
        QualityType.Middle,
        "致命点燃",
        "/images/skill/7.png",
        `造成${value}倍基础伤害`,
        `对方损失我方基础伤害${debuff_value}%`,
        BuffType.Debuff,
        turns
      );
    case 8:
      value = level == 3 ? 6 : level == 2 ? 4 : 2;
      return new Card(
        id,
        level,
        SectType.Attack,
        QualityType.High,
        "一击制胜",
        "/images/skill/8.png",
        `造成(2+${value}*己方损失生命值比例)倍基础伤害`
      );
    case 9:
      value = level == 3 ? 3 : level == 2 ? 2 : 1;
      return new Card(
        id,
        level,
        SectType.Weaken,
        QualityType.High,
        "晕头转向",
        "/images/skill/9.png",
        `移除对方${value}个buff`
      );
    case 10:
      debuff_value = level == 3 ? 40 : level == 2 ? 20 : 10;
      turns = level == 3 ? 5 : level == 2 ? 3 : 2;
      return new Card(
        id,
        level,
        SectType.Defense,
        QualityType.Low,
        "天降蛛网",
        "/images/skill/10.png",
        "",
        `对方命中率-${debuff_value}%`,
        BuffType.Debuff,
        turns
      );
    case 11:
      value = level == 3 ? 4 : level == 2 ? 3 : 2;
      return new Card(
        id,
        level,
        SectType.Attack,
        QualityType.High,
        "嗜血攻击",
        "/images/skill/11.png",
        `造成${value}倍基础伤害并回复我方对应生命值`
      );
    case 12:
      value = level == 3 ? 3 : level == 2 ? 2 : 1;
      debuff_value = level == 3 ? 5 : level == 2 ? 4 : 3;
      return new Card(
        id,
        level,
        SectType.Attack,
        QualityType.Middle,
        "烈火炮击",
        "/images/skill/12.png",
        `造成${value}倍基础伤害，若存在点燃状态则取消并额外造成${debuff_value}倍基础伤害`
      );
    case 13:
      buff_value = level == 3 ? 30 : level == 2 ? 20 : 20;
      turns = level == 3 ? 4 : level == 2 ? 3 : 2;
      return new Card(
        id,
        level,
        SectType.Defense,
        QualityType.Middle,
        "寒冰护甲",
        "/images/skill/13.png",
        "",
        `己方受到伤害-${buff_value}%`,
        BuffType.Buff,
        turns
      );
    case 14:
      value = level == 3 ? 2 : level == 2 ? 1 : 1;
      buff_value = level == 3 ? 30 : level == 2 ? 20 : 10;
      turns = level == 3 ? 3 : level == 2 ? 2 : 1;
      return new Card(
        id,
        level,
        SectType.Enhance,
        QualityType.Middle,
        "更新换代",
        "/images/skill/14.png",
        `移除己方${value}个debuff`,
        `己方造成伤害+${buff_value}%`,
        BuffType.Buff,
        turns
      );
    case 15:
      buff_value = level == 3 ? 50 : level == 2 ? 40 : 30;
      turns = level == 3 ? 5 : level == 2 ? 4 : 3;
      return new Card(
        id,
        level,
        SectType.Defense,
        QualityType.High,
        "坚固巨网",
        "/images/skill/15.png",
        ``,
        `设置一个屏障，共抵挡我方最大生命值${buff_value}%的直接伤害`,
        BuffType.Buff,
        turns
      );
    case 16:
      buff_value = level == 3 ? 90 : level == 2 ? 70 : 50;
      turns = level == 3 ? 2 : level == 2 ? 2 : 2;
      return new Card(
        id,
        level,
        SectType.Defense,
        QualityType.High,
        "钢铁之躯",
        "/images/skill/16.png",
        ``,
        `己方受到伤害-${buff_value}%`,
        BuffType.Buff,
        turns
      );
    case 17:
      debuff_value = level == 3 ? 10 : level == 2 ? 8 : 6;
      turns = level == 3 ? 4 : level == 2 ? 3 : 2;
      return new Card(
        id,
        level,
        SectType.Weaken,
        QualityType.High,
        "陷阱密布",
        "/images/skill/17.png",
        ``,
        `对方损失最大生命值${debuff_value}%`,
        BuffType.Debuff,
        turns
      );
    case 18:
      turns = level == 3 ? 2 : level == 2 ? 1 : 0;
      return new Card(
        id,
        level,
        SectType.Defense,
        QualityType.Low,
        "掩护打击",
        "/images/skill/18.png",
        `造成2倍基础伤害`,
        `必定闪避`,
        BuffType.TimedBuff,
        turns
      );
    case 19:
      buff_value = level == 3 ? 100 : level == 2 ? 80 : 50;
      return new Card(
        id,
        level,
        SectType.Enhance,
        QualityType.High,
        "整备筹谋",
        "/images/skill/19.png",
        `造成基础伤害`,
        `携带时基础伤害提高${buff_value}%`,
        BuffType.Passive,
        99
      );
    case 20:
      buff_value = level == 3 ? 50 : level == 2 ? 30 : 20;
      turns = level == 3 ? 3 : level == 2 ? 2 : 1;
      return new Card(
        id,
        level,
        SectType.Enhance,
        QualityType.Low,
        "集中精神",
        "/images/skill/20.png",
        ``,
        `己方命中率+${buff_value}%`,
        BuffType.Buff,
        turns
      );
    case 21:
      buff_value = level == 3 ? 30 : level == 2 ? 20 : 10;
      turns = level == 3 ? 3 : level == 2 ? 2 : 2;
      return new Card(
        id,
        level,
        SectType.Defense,
        QualityType.Middle,
        "高速运动",
        "/images/skill/21.png",
        ``,
        `己方闪避率+${buff_value}%`,
        BuffType.Buff,
        turns
      );
    case 22:
      buff_value = level == 3 ? 8 : level == 2 ? 6 : 4;
      turns = level == 3 ? 5 : level == 2 ? 4 : 3;
      return new Card(
        id,
        level,
        SectType.Enhance,
        QualityType.Low,
        "持续维修",
        "/images/skill/22.png",
        ``,
        `己方回复最大生命值${buff_value}%`,
        BuffType.Buff,
        turns
      );
    case 23:
      value = level == 3 ? 3 : level == 2 ? 2 : 1;
      return new Card(
        id,
        level,
        SectType.Weaken,
        QualityType.Middle,
        "震撼炸弹",
        "/images/skill/23.png",
        `强制对手跳过序列中下个行动`,
        ``,
        BuffType.None,
        0,
        value
      );
    case 24:
      value = level == 3 ? 30 : level == 2 ? 20 : 10;
      return new Card(
        id,
        level,
        SectType.Enhance,
        QualityType.Low,
        "战斗急救",
        "/images/skill/24.png",
        `回复最大生命值${value}%`
      );
    case 25:
      value = level == 3 ? 5 : level == 2 ? 4 : 3;
      debuff_value = level == 3 ? 10 : level == 2 ? 20 : 30;
      return new Card(
        id,
        level,
        SectType.Attack,
        QualityType.Low,
        "疯狂攻击",
        "/images/skill/25.png",
        `造成${value}倍基础伤害，己方命中率-${debuff_value}%`,
        ``,
        BuffType.None
      );
    case 26:
      value = level == 3 ? 3 : level == 2 ? 2 : 1;
      return new Card(
        id,
        level,
        SectType.Weaken,
        QualityType.High,
        "精神枷锁",
        "/images/skill/26.png",
        `强制对方普通攻击`,
        ``,
        BuffType.None,
        0,
        value
      );
    case 27:
      turns = level == 3 ? 5 : level == 2 ? 4 : 3;
      return new Card(
        id,
        level,
        SectType.Defense,
        QualityType.Middle,
        "危险泥沼",
        "/images/skill/27.png",
        ``,
        `对方造成伤害-10%*已持续回合数`,
        BuffType.Debuff,
        turns
      );
    default:
      return new Card(
        0,
        1,
        SectType.Attack,
        QualityType.Low,
        "普通攻击",
        "/images/skill/0.png",
        "造成基础伤害"
      );
  }
}

export function getBuffDesc(id, duration, barrier) {
  let [level, primaryId] = getLevelAndId(id);
  let debuff_value = 0;
  let buff_value = 0;
  let value = 0;
  let turns = 0;
  switch (primaryId) {
    case 1:
      debuff_value = level == 3 ? 150 : level == 2 ? 100 : 100;
      return `利刃突袭: 受到对方基础伤害${debuff_value}%`;
    case 2:
      debuff_value = level == 3 ? 30 : level == 2 ? 15 : 10;
      return `黑雾笼罩：造成伤害-${debuff_value}%`;
    case 3:
      debuff_value = level == 3 ? 5 : level == 2 ? 4 : 3;
      return `荆棘缠身: 损失当前生命值${debuff_value}%`;
    case 4:
      buff_value = level == 3 ? 40 : level == 2 ? 20 : 10;
      return `高爆准备: 暴击率+${buff_value}%`;
    case 5:
      buff_value = level == 3 ? 30 : level == 2 ? 20 : 10;
      return `高效迭代: 命中率+${buff_value}%`;
    case 7:
      debuff_value = level == 3 ? 100 : level == 2 ? 80 : 50;
      return `致命点燃: 损失对方基础伤害${debuff_value}%`;
    case 10:
      debuff_value = level == 3 ? 40 : level == 2 ? 20 : 10;
      return `天降蛛网: 命中率-${debuff_value}%`;
    case 13:
      buff_value = level == 3 ? 30 : level == 2 ? 20 : 20;
      return `寒冰护甲: 受到伤害-${buff_value}%`;
    case 14:
      buff_value = level == 3 ? 30 : level == 2 ? 20 : 10;
      return `更新换代: 造成伤害+${buff_value}%`;
    case 15:
      buff_value = level == 3 ? 50 : level == 2 ? 40 : 30;
      return `坚固巨网: 抵挡我方最大生命值${buff_value}%的直接伤害, 当前剩余${barrier}`;
    case 16:
      buff_value = level == 3 ? 90 : level == 2 ? 70 : 50;
      return `钢铁之躯: 受到伤害-${buff_value}%`;
    case 17:
      debuff_value = level == 3 ? 10 : level == 2 ? 8 : 6;
      return `陷阱密布: 损失最大生命值${debuff_value}%`;
    case 18:
      return `掩护打击: 必定闪避`;
    case 20:
      buff_value = level == 3 ? 50 : level == 2 ? 30 : 20;
      return `集中精神: 命中率+${buff_value}%`;
    case 21:
      buff_value = level == 3 ? 30 : level == 2 ? 20 : 10;
      return `高速运动: 闪避率+${buff_value}%`;
    case 22:
      buff_value = level == 3 ? 8 : level == 2 ? 6 : 4;
      return `持续维修: 回复最大生命值${buff_value}%`;
    case 27:
      turns = level == 3 ? 5 : level == 2 ? 4 : 3;
      return `危险泥沼: 造成伤害-10%*${turns + 1 - duration}`;
    default:
      return `unknown buff desc`;
  }
}

export function getRoundBuffName(id) {
  let [_level, primaryId] = getLevelAndId(id);
  switch (primaryId) {
    case 1:
      return `利刃突袭`;
    case 2:
      return `黑雾笼罩`;
    case 3:
      return `荆棘缠身`;
    case 4:
      return `高爆准备`;
    case 5:
      return `高效迭代`;
    case 7:
      return `致命点燃`;
    case 10:
      return `天降蛛网`;
    case 13:
      return `寒冰护甲`;
    case 14:
      return `更新换代`;
    case 15:
      return `坚固巨网`;
    case 16:
      return `钢铁之躯`;
    case 17:
      return `陷阱密布`;
    case 18:
      return `掩护打击`;
    case 20:
      return `集中精神`;
    case 21:
      return `高速运动`;
    case 22:
      return `持续维修`;
    case 27:
      return `危险泥沼`;
    default:
      return `unknown buff name`;
  }
}

export function getLevelAndId(cardId) {
  return [parseInt(cardId / (MAX_CARD_ID + 1)) + 1, cardId % (MAX_CARD_ID + 1)];
}
