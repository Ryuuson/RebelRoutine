export interface TraitDefinition {
  key: string;
  label: string;
  color: string;
  icon: string;
}

export interface TraitHit {
  key: string;
  label: string;
  points: number;
}

export interface TraitAnalysis {
  summary: string;
  hits: TraitHit[];
}

export interface TraitAnalyzer {
  analyze(action: string): Promise<TraitAnalysis>;
}

export const TRAIT_DEFINITIONS: TraitDefinition[] = [
  { key: 'knowledge', label: '知识', color: '#F5C400', icon: 'knowledge' },
  { key: 'proficiency', label: '灵巧', color: '#F5C400', icon: 'proficiency' },
  { key: 'charm', label: '魅力', color: '#F5C400', icon: 'charm' },
  { key: 'kindness', label: '体贴', color: '#F5C400', icon: 'kindness' },
  { key: 'health', label: '健康', color: '#F5C400', icon: 'guts' }
];

interface KeywordRule {
  words: string[];
  keys: string[];
}

const KEYWORD_RULES: KeywordRule[] = [
  { words: ['阅读', '读书', '读 ', '笔记', '知识', '学习', '复习', '研究', '课程', '看展'], keys: ['knowledge'] },
  { words: ['帮助', '帮忙', '照顾', '陪伴', '倾听', '安慰', '关心', '志愿', '义工', '捐赠', '探望', '照料', '喂猫', '喂狗', '浇花'], keys: ['kindness'] },
  { words: ['焊', '修理', '制作', '装配', '编程', '调试', '画图', '手工'], keys: ['proficiency'] },
  { words: ['家务', '做饭', '洗衣', '打扫', '整理房间', '整理书桌', '整理衣柜', '收拾'], keys: ['health', 'proficiency'] },
  { words: ['运动', '跑步', '健身', '训练', '爬山', '锻炼', '拉伸', '早睡', '冥想'], keys: ['health'] },
  { words: ['沟通', '聊天', '聚会', '演讲', '分享', '道歉'], keys: ['charm'] }
];

// 未保存 awardedTraits 的旧记录使用新增体贴前的规则回溯获分。
const LEGACY_KEYWORD_RULES: KeywordRule[] = [
  { words: ['阅读', '学习', '复习', '研究', '课程', '看展'], keys: ['knowledge'] },
  { words: ['焊', '修理', '制作', '装配', '编程', '调试', '画图', '手工'], keys: ['proficiency'] },
  { words: ['家务', '做饭', '洗衣', '打扫', '整理', '照顾', '收拾'], keys: ['health', 'proficiency'] },
  { words: ['运动', '跑步', '健身', '训练', '爬山', '锻炼', '拉伸', '早睡', '冥想'], keys: ['health'] },
  { words: ['沟通', '聊天', '聚会', '演讲', '帮助', '陪伴', '倾听', '分享', '道歉'], keys: ['charm'] }
];

/** Offline fallback. Replace this class with an HTTP-backed implementation later. */
export class LocalTraitAnalyzer implements TraitAnalyzer {
  async analyze(action: string): Promise<TraitAnalysis> {
    return this.analyzeWithRules(action, KEYWORD_RULES);
  }

  async analyzeLegacy(action: string): Promise<TraitAnalysis> {
    return this.analyzeWithRules(action, LEGACY_KEYWORD_RULES);
  }

  private analyzeWithRules(action: string, rules: KeywordRule[]): TraitAnalysis {
    const hits: TraitHit[] = [];
    rules.forEach((rule: KeywordRule) => {
      if (rule.words.some((word: string) => action.includes(word))) {
        rule.keys.forEach((key: string) => {
          if (hits.length >= 2) {
            return;
          }
          const definition = TRAIT_DEFINITIONS.find((item: TraitDefinition) => item.key === key);
          if (definition && !hits.some((hit: TraitHit) => hit.key === key)) {
            hits.push({ key, label: definition.label, points: 1 });
          }
        });
      }
    });

    // 没识别到就【不给分】。
    // 原来这里兜底白送第一个维度，导致输入任意文字（哪怕 "none"）都会涨知识。
    if (hits.length === 0) {
      return { summary: '没认出这是什么，换个说法', hits: [] };
    }
    return {
      summary: `识别到 ${hits.map((hit: TraitHit) => hit.label).join(' / ')}`,
      hits
    };
  }
}
