// Pillar Seer — R90 sprint 2 LifeParagraphService (시그니처 확장).
//
// 운세의신 17 카테고리 인생 분류 paragraph lookup. LifeCategory enum 17 entry =
//   13 일반 카테고리 (string) + 3 성별 분기 카테고리 (sub-object {M, F}) + 1 conclusion_self.
// 일주 1 종당 paragraph 총량 = 13 + 3 × 2 + 1 = 20 paragraph string.
//
// R88 sprint 4 ~ R89 까지 = `paragraphStatic({dayPillar, category, gender})` 단일 signature.
//
// R89 결함 (사용자 verbatim):
//   "원래 사주는 일주로만 봐?? 내 사주가 곧 평생사주인데 왜 신묘일주만 말하지??"
//   → 같은 신묘 일주여도 다른 사주 anchor (월령/십성/격국/5행) 가 다르면 본문도 달라야 함.
//
// R90 sprint 2 새 signature (사용자 mandate):
//   `paragraph({saju: SajuResult, category, gender})` — SajuResult 전체 받음.
//   내부에서 base paragraph (sprint 1 prefix 제거된 60 일주 DB)
//     + fragment 1~2 (LifeCategoryFragmentService sprint 3) 결합.
//
// 호환성:
//   - 기존 `paragraphStatic({dayPillar, ...})` = deprecated 표시 + 그대로 작동 (base 만 반환).
//   - 모든 caller (LifeOverviewService / SelfConclusionService / result_screen) 는
//     sprint 5 sweep 에서 새 signature 로 마이그레이션.
//
// 저장소: assets/data/life_paragraphs.json
//   schema:
//     {
//       "갑자": {
//         "early_life": "초년운 paragraph (해요체, 80~400자)",
//         "mid_life": "...",
//         ...
//         "innate_character": { "M": "...", "F": "..." },
//         "love_fate":        { "M": "...", "F": "..." },
//         "affection":        { "M": "...", "F": "..." },
//         "conclusion_self": "..."
//       },
//       "을축": { ... },
//       ...
//     }
//
// gender null fallback = M paragraph 우선 (단순 결정, spec 2.2.b 채택).

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/saju_result.dart';
import 'life_category_fragment_service.dart';
import 'natural_prose_joiner.dart';

/// R88 sprint 4 — 17 카테고리 + conclusion_self enum.
/// 카테고리 ordinal 은 운세의신 인생 분류 구조 + 사용자 mandate 의 화면 순서를 따름.
enum LifeCategory {
  earlyLife,
  midLife,
  lateLife,
  health,
  constitution,
  social,
  socialPersonality,
  personality,
  innateTendency,
  innateCharacter, // 성별 분기
  loveFate, // 성별 분기
  affection, // 성별 분기
  wealth,
  wealthGather,
  wealthLossPrevent,
  wealthInvest,
  conclusionSelf,
}

/// LifeCategory → JSON key 매핑.
String lifeCategoryKey(LifeCategory cat) {
  switch (cat) {
    case LifeCategory.earlyLife:
      return 'early_life';
    case LifeCategory.midLife:
      return 'mid_life';
    case LifeCategory.lateLife:
      return 'late_life';
    case LifeCategory.health:
      return 'health';
    case LifeCategory.constitution:
      return 'constitution';
    case LifeCategory.social:
      return 'social';
    case LifeCategory.socialPersonality:
      return 'social_personality';
    case LifeCategory.personality:
      return 'personality';
    case LifeCategory.innateTendency:
      return 'innate_tendency';
    case LifeCategory.innateCharacter:
      return 'innate_character';
    case LifeCategory.loveFate:
      return 'love_fate';
    case LifeCategory.affection:
      return 'affection';
    case LifeCategory.wealth:
      return 'wealth';
    case LifeCategory.wealthGather:
      return 'wealth_gather';
    case LifeCategory.wealthLossPrevent:
      return 'wealth_loss_prevent';
    case LifeCategory.wealthInvest:
      return 'wealth_invest';
    case LifeCategory.conclusionSelf:
      return 'conclusion_self';
  }
}

/// 성별 분기 카테고리 set — JSON 안에서 {M, F} sub-object 로 저장.
const Set<LifeCategory> kGenderSplitCategories = {
  LifeCategory.innateCharacter,
  LifeCategory.loveFate,
  LifeCategory.affection,
};

// ──────────── R107 — 영어 모드 카테고리 본문 (일간별 개인화) ────────────
//
// life_paragraphs.json 은 한국어 전용(En 필드 0)이라 1MB JSON 을 영어로 복제하지
// 않고, service 안에서 영어 carrier 를 보관한다. 한국어 schema/id 불변.
//
// R106 까지: `kLifeCategoryBodyEn` = 17 generic 문자열 — 모든 영어 사용자 동일.
// R107 (사용자 mandate): 한국어 life_paragraphs.json 의 일간 10 stem entry 가
//   일주별 개인화인데 영어만 개인화 0 이던 갭을 일소. 일간 10 × 17 카테고리 =
//   170 본문으로 확장. 각 본문은 한국어 stem entry 의 영어판 — 새 사주 주장·창작 0.
//
// 키 방식: 외층 = 천간 한자('甲'/'乙'/...) — SajuResult.dayMaster / dayPillar.chunGan
//   과 동일 키라 변환 없이 lookup. 내층 = LifeCategory enum.
//
// v5 voice: 단정 금지(tends to / can / often), 메타 금지(chart/element/stem/branch
// 까지만 허용 — saju 주체 노출 X), 자연 구어 영어(번역체·헤드라인체 금지).
// 같은 일간 17 카테고리에 동일 도입 scaffold·반복 문구 0 (한국어 중복 버그 재발 금지).

/// 일간 10 × 17 카테고리 = 170 영어 본문.
/// 외층 키 = 천간 한자, 내층 키 = LifeCategory.
const Map<String, Map<LifeCategory, String>> kLifeCategoryBodyEnByStem = {
  // ── 甲 (gap) — 큰 나무, 곧게 뻗는 시작 ──
  '甲': {
    LifeCategory.earlyLife:
        'Even as a kid you tend to grow straight toward whatever catches your eye, '
        'and you often reach for new things a beat sooner than the people around you.',
    LifeCategory.midLife:
        'Through your thirties and forties the field you love tends to come into focus, '
        'and people can start to remember you by one clear keyword that is fully your own.',
    LifeCategory.lateLife:
        'Later on you tend to shine less by standing on the big stage yourself and more by '
        'looking after the people coming up behind you, and their growth can quietly steady your name.',
    LifeCategory.health:
        'When you overthink, your shoulders and neck tend to feel it first, and your stomach can '
        'be a little sensitive, so going easy on spicy food and caffeine usually helps.',
    LifeCategory.constitution:
        'Drinking water often and keeping a warm cup of tea nearby tends to suit you, '
        'and leafy greens can lift your condition fast while very salty meals often come back as puffiness.',
    LifeCategory.social:
        'You tend to draw people by the direction you move in rather than by being loud, '
        'though since your own heading runs strong, pausing to hear one more opinion can help.',
    LifeCategory.socialPersonality:
        'In a group you rarely push from above; instead people tend to fall in behind the path you take, '
        'and you often end up the one who sets the heading early.',
    LifeCategory.personality:
        'Your pride runs firm, so once you decide something you tend not to bend, '
        'and when you are upset you usually say it on the spot rather than letting it sit.',
    LifeCategory.innateTendency:
        'Being tied to one fixed spot can feel stifling to you, and your energy tends to wake up '
        'on a new challenge or a road you have never walked, by the fastest route rather than the slow loop.',
    LifeCategory.innateCharacter:
        'You tend to carry a natural weight that makes people see you as a leader without you commanding anyone, '
        'and a steady pride paired with deep loyalty often shows in how you treat close friends.',
    LifeCategory.loveFate:
        'Early in a relationship you can be drawn to someone warm who meets your quick tempo '
        'while gently slowing you down, and being seen exactly as you are tends to matter to you.',
    LifeCategory.affection:
        'In a lasting bond the bright early tension tends to settle into everyday give and take, '
        'and looking after someone — and being looked after — can feel natural to you.',
    LifeCategory.wealth:
        'Money tends to flow better from work you started yourself than from sitting still, '
        'and a bigger sum can arrive in one go rather than trickling in.',
    LifeCategory.wealthGather:
        'Since you find it hard not to spend what is in hand, moving a set amount into a separate '
        'account the moment it arrives tends to let savings build on their own.',
    LifeCategory.wealthLossPrevent:
        'Your biggest leak tends to be buying on the spot when a mood or a crowd carries you, '
        'so a simple 24-hour hold before any large purchase can protect you well.',
    LifeCategory.wealthInvest:
        'Spreading rather than putting everything in one place tends to fit you, '
        'and a longer horizon usually suits you more than chasing short, unfamiliar tips from friends.',
    LifeCategory.conclusionSelf:
        'In one line, growing straight toward what you choose is your core colour, '
        'and the loyalty that shows as people get closer tends to make them want to stay.',
  },
  // ── 乙 (eul) — 덩굴·풀, 유연하고 끈질김 ──
  '乙': {
    LifeCategory.earlyLife:
        'As a child you tend to settle into unfamiliar places slowly but surely, '
        'and you can hold onto what you love for a long time, the way a fan stays loyal.',
    LifeCategory.midLife:
        'Through your thirties and forties you tend to climb by laying a path like a vine '
        'rather than shooting up all at once, keeping your own pace even when others tug at it.',
    LifeCategory.lateLife:
        'Later on, tending a few easy relationships for the long haul tends to suit you '
        'more than forcing your circle wider, and small steady joys can keep your heart warm.',
    LifeCategory.health:
        'Pushing too hard tends to show on you quickly, so building rest into your day matters, '
        'and checking in on your condition often can keep things from slipping.',
    LifeCategory.constitution:
        'You tend to feel stronger in places with a little room to breathe than in cold or stuffy ones, '
        'and a quiet, surviving toughness can be your charm even when you look small.',
    LifeCategory.social:
        'You tend to read the room and say the needed thing without a sharp tone, '
        'though bending too far for others can drain you, so keeping a gentle line helps.',
    LifeCategory.socialPersonality:
        'In a group you tend to be the one who smooths the mood quietly, '
        'and people can lean on you because you rarely make things heavier than they are.',
    LifeCategory.personality:
        'You may say you are fine on the surface while a lot is turning over inside, '
        'and you tend to stick to what you love until skill grows almost without you noticing.',
    LifeCategory.innateTendency:
        'Your instinct tends to choose flexibility first — bending around an obstacle rather than '
        'colliding with it — and that supple persistence is closer to your nature than force.',
    LifeCategory.innateCharacter:
        'At your core you tend to carry a soft but unbreakable thread, '
        'and that gentle endurance often shows most in how patiently you stay with the people you care for.',
    LifeCategory.loveFate:
        'Attraction tends to grow on you gradually, and you can be drawn to someone steady '
        'who gives your quiet inner world room rather than rushing it.',
    LifeCategory.affection:
        'In a lasting relationship you tend to show care through patient, repeated small gestures, '
        'though saying what you actually feel out loud can matter more than you expect.',
    LifeCategory.wealth:
        'Buying something the moment it looks pretty tends to lighten your wallet fast, '
        'so naming a budget first can keep the satisfaction while trimming the strain.',
    LifeCategory.wealthGather:
        'Saving tends to work for you when it is small and regular, '
        'and watching a modest amount add up steadily can feel quietly rewarding.',
    LifeCategory.wealthLossPrevent:
        'Money can slip away through goods bought on impulse, '
        'so deciding a limit before you shop tends to guard you better than willpower alone.',
    LifeCategory.wealthInvest:
        'A slow, steady approach tends to suit you, and you usually do better staying with what you '
        'understand than jumping into a fast trend on someone else\'s word.',
    LifeCategory.conclusionSelf:
        'In one line, supple persistence is your core colour, '
        'and the way you quietly outlast hard moments tends to be your real strength.',
  },
  // ── 丙 (byeong) — 태양, 환한 표현 ──
  '丙': {
    LifeCategory.earlyLife:
        'As a kid you tend to move the moment you want something, '
        'so praise can come fast, and now and then a rush can land you in trouble too.',
    LifeCategory.midLife:
        'Through your thirties and forties speaking or leading in front of people tends to suit you, '
        'and your presence can grow large, like a lead vocal on stage.',
    LifeCategory.lateLife:
        'Later on the ties you built when young tend to stay with you, '
        'and sharing what you love can keep your heart bright if you ease up on stubbornness a little.',
    LifeCategory.health:
        'Cutting sleep short or holding feelings in too long tends to pile up fatigue quickly, '
        'so water, rest, and a light walk can cool you down well.',
    LifeCategory.constitution:
        'Your energy tends to run hot, so things that cool and settle you — enough water, shade, '
        'a calm pause — usually suit you better than pushing through heat.',
    LifeCategory.social:
        'You tend to warm up any room you walk into, '
        'and people can be drawn to the open, easy brightness you carry without trying.',
    LifeCategory.socialPersonality:
        'In a group you tend to be the spark that lifts the mood, '
        'and people often look to you to set a lively tone when things go flat.',
    LifeCategory.personality:
        'Praise tends to send your energy straight up, while being ignored can cool you fast, '
        'and a real wish to be recognised runs strong in you.',
    LifeCategory.innateTendency:
        'Your instinct tends to reach for expression — showing what you feel rather than hiding it — '
        'and shining openly is closer to your nature than holding back.',
    LifeCategory.innateCharacter:
        'At your core you tend to carry a warm, lighting-up quality, '
        'and that openness often shows most in how readily you cheer the people around you.',
    LifeCategory.loveFate:
        'When you fall for someone it tends to show fast and bright, '
        'and you can be drawn to a person who responds warmly and matches your open energy.',
    LifeCategory.affection:
        'In a lasting relationship you tend to give affection openly, '
        'though remembering to also listen quietly can keep the warmth balanced both ways.',
    LifeCategory.wealth:
        'Money tends to move toward pretty things, fun, and plans with friends, '
        'so setting a clear standard first can make your spending feel steadier.',
    LifeCategory.wealthGather:
        'Saving tends to work when you make it visible and a little fun, '
        'and a clear goal you can picture often keeps you putting money aside.',
    LifeCategory.wealthLossPrevent:
        'Spending tends to climb when your mood is high, '
        'so a short pause before a purchase can keep an excited moment from emptying your wallet.',
    LifeCategory.wealthInvest:
        'A bright idea can pull you in fast, so checking it against a calm standard '
        'tends to suit you better than acting on the first spark of excitement.',
    LifeCategory.conclusionSelf:
        'In one line, a warm lighting-up presence is your core colour, '
        'and the energy you bring into a room tends to be what people remember.',
  },
  // ── 丁 (jeong) — 촛불, 섬세하게 챙김 ──
  '丁': {
    LifeCategory.earlyLife:
        'As a child you tend to watch quietly in new places, '
        'and once you feel safe, a warm humour and a sharp eye can show your presence quickly.',
    LifeCategory.midLife:
        'Through your thirties and forties you tend to care for people at just the right moment '
        'rather than pushing forward, and trust can build slowly and solidly around you.',
    LifeCategory.lateLife:
        'Later on you tend to become a quiet comfort to those around you, like a song that lingers, '
        'and protecting your own calm space can keep you steady.',
    LifeCategory.health:
        'Keeping an unhurried rhythm of sleep, meals, and rest tends to make your warm energy last, '
        'so steering clear of situations that leave you feeling cold can help.',
    LifeCategory.constitution:
        'Your energy tends to be fine but easily moved, so a warm, gentle daily rhythm '
        'usually suits you more than extremes of cold or strain.',
    LifeCategory.social:
        'You tend to read feelings closely and offer just the right small kindness, '
        'and people can feel safe opening up around your quiet attentiveness.',
    LifeCategory.socialPersonality:
        'In a group you tend to be the one who notices who is left out, '
        'and that gentle awareness often makes you the steadying presence people rely on.',
    LifeCategory.personality:
        'When you like someone you tend to carry that feeling for a long time, '
        'and you usually show it through warm action rather than light, passing words.',
    LifeCategory.innateTendency:
        'Your instinct tends to reach for delicate care — sensing what is needed and tending it quietly — '
        'and that fine attentiveness is closer to your nature than bold display.',
    LifeCategory.innateCharacter:
        'At your core you tend to carry a small, steady warmth, '
        'and it often shows most in the careful, lasting way you look after the people close to you.',
    LifeCategory.loveFate:
        'Attraction tends to begin quietly for you and deepen over time, '
        'and you can be drawn to someone whose warmth feels genuine rather than flashy.',
    LifeCategory.affection:
        'In a lasting relationship you tend to show love through steady, thoughtful gestures, '
        'and that quiet consistency can mean more to you than grand moments.',
    LifeCategory.wealth:
        'Spending tends to follow your feelings, so when emotions run high your wallet can too, '
        'and keeping mood and money a little separate usually helps.',
    LifeCategory.wealthGather:
        'Saving tends to suit you when it is gentle and regular, '
        'and a small amount set aside without pressure can quietly add up over time.',
    LifeCategory.wealthLossPrevent:
        'A short pause before you spend tends to be one of your best habits, '
        'since it can catch the purchases that are really about how you feel that day.',
    LifeCategory.wealthInvest:
        'A calm, measured approach tends to suit you, '
        'and stepping back to check a decision when your feelings are stirred usually protects you well.',
    LifeCategory.conclusionSelf:
        'In one line, a delicate, lasting warmth is your core colour, '
        'and the careful way you tend the people you love tends to be your quiet strength.',
  },
  // ── 戊 (mu) — 큰 산, 든든한 중심 ──
  '戊': {
    LifeCategory.earlyLife:
        'As a kid you tend not to wobble even when your friend group keeps shifting, '
        'and a feeling you settle on can stay with you for quite a while.',
    LifeCategory.midLife:
        'Through your thirties and forties a slow early tempo can make you feel behind at first, '
        'but the experience you stack tends to harden into a presence that holds.',
    LifeCategory.lateLife:
        'Later on, because you do not rattle easily, family and close friends tend to come to you '
        'when things get hard, though letting yourself off the habit of long patience can help.',
    LifeCategory.health:
        'You tend to show fatigue late, so it can pile up unnoticed and then hit all at once, '
        'and catching your body\'s signals early usually serves you better than pushing through.',
    LifeCategory.constitution:
        'Your build tends to be sturdy and slow to react, so steady routines suit you, '
        'and noticing small changes before they grow can keep that strength reliable.',
    LifeCategory.social:
        'People tend to feel at ease beside you because you stay even, '
        'and you can be the dependable centre a group quietly settles around.',
    LifeCategory.socialPersonality:
        'In a group you tend to take the role that keeps everyone steady, '
        'and others often turn to you when something needs a calm, unhurried hand.',
    LifeCategory.personality:
        'You tend to keep a clear inner line and rarely change your word, '
        'and you often look after close friends for a long time, even if your pace runs slow.',
    LifeCategory.innateTendency:
        'Your instinct tends to reach for steadiness — holding the centre rather than chasing the new — '
        'and being a fixed point others can rely on is closer to your nature.',
    LifeCategory.innateCharacter:
        'At your core you tend to carry the quiet weight of a mountain, '
        'and that grounded steadiness often shows most in how reliably you stand by the people close to you.',
    LifeCategory.loveFate:
        'Attraction tends to build slowly for you, and you can be drawn to someone steady '
        'whose feelings, like yours, are not easily shaken.',
    LifeCategory.affection:
        'In a lasting relationship you tend to show care through dependable, unchanging presence, '
        'though saying your feelings out loud can matter more than you assume.',
    LifeCategory.wealth:
        'You tend to have a real talent for stacking and holding, so a plan once set tends to last, '
        'though staying open to a new chance now and then can serve you well.',
    LifeCategory.wealthGather:
        'Saving tends to come naturally to you, '
        'and a steady, low-drama habit of setting money aside can grow into something solid.',
    LifeCategory.wealthLossPrevent:
        'Your money tends to be safe from impulse, '
        'so the main thing to watch is missing a fair chance by holding on a little too tightly.',
    LifeCategory.wealthInvest:
        'A patient, long approach tends to suit you well, '
        'and trusting your steady pace usually serves you better than reacting to short swings.',
    LifeCategory.conclusionSelf:
        'In one line, a grounded steadiness is your core colour, '
        'and the way people lean on you in hard moments tends to be your quiet strength.',
  },
  // ── 己 (gi) — 비옥한 밭, 실속 있는 포용 ──
  '己': {
    LifeCategory.earlyLife:
        'As a child you tend to feel settled when you build a familiar place step by step '
        'rather than standing out, and the friendships you make can last once they take.',
    LifeCategory.midLife:
        'Through your thirties and forties you tend to make results by widening a familiar field '
        'rather than switching direction sharply, and your knack for caring for people can shine.',
    LifeCategory.lateLife:
        'Later on a comfortable life and warm time with close people tend to matter more than big ambition, '
        'and laughing for years with the right few can feel like enough.',
    LifeCategory.health:
        'When your eating and sleeping rhythm slips your condition tends to sag quickly, '
        'and a light, regular walk usually suits you well.',
    LifeCategory.constitution:
        'Your build tends to respond well to regular meals and calm routine, '
        'and gentle, steady movement usually serves you better than sudden hard effort.',
    LifeCategory.social:
        'You tend to be the warm, easy presence a group gathers around, '
        'and people can trust you because you look after the small things others miss.',
    LifeCategory.socialPersonality:
        'In a group you tend to be the one who quietly keeps everyone comfortable, '
        'and that caretaking instinct often makes you the heart people return to.',
    LifeCategory.personality:
        'You tend to watch a situation and move slowly rather than jumping in, '
        'and since you can put your own feelings last while minding others, checking in with yourself helps.',
    LifeCategory.innateTendency:
        'Your instinct tends to reach for practical grounding — building something solid and useful — '
        'and a quiet, down-to-earth steadiness is closer to your nature than show.',
    LifeCategory.innateCharacter:
        'At your core you tend to carry the giving calm of fertile soil, '
        'and that supportive warmth often shows most in how you hold space for the people near you.',
    LifeCategory.loveFate:
        'Attraction tends to grow on you slowly through comfort and trust, '
        'and you can be drawn to someone whose steady, easy presence feels like home.',
    LifeCategory.affection:
        'In a lasting relationship you tend to give care generously and quietly, '
        'though remembering to voice your own needs can keep things fair on both sides.',
    LifeCategory.wealth:
        'You tend to weigh where money is really needed rather than spending on impulse, '
        'and tracking even small amounts can turn saving into something that feels rewarding.',
    LifeCategory.wealthGather:
        'Saving tends to suit you when it is steady and low-key, '
        'and a small fixed habit can quietly grow your sense of security.',
    LifeCategory.wealthLossPrevent:
        'Your money tends to be fairly safe, '
        'so the main thing to watch is spending too readily on others when you mean to be kind.',
    LifeCategory.wealthInvest:
        'A careful, gradual approach tends to suit you, '
        'and sticking with what you have looked into usually serves you better than a quick leap.',
    LifeCategory.conclusionSelf:
        'In one line, a practical, giving steadiness is your core colour, '
        'and the warm, easy space you make for people tends to be your quiet strength.',
  },
  // ── 庚 (gyeong) — 도끼·쇠, 단호한 결단 ──
  '庚': {
    LifeCategory.earlyLife:
        'As a kid you may find rules stuffy, yet you tend to quietly look out for weaker friends, '
        'and a blade-like focus means that once you lock onto something you dig in to the end.',
    LifeCategory.midLife:
        'Through your thirties and forties you tend not to be easily swayed, though you can look stubborn, '
        'and a goal you set tends to be one you carry through like a final stage pose.',
    LifeCategory.lateLife:
        'Later on you tend to keep a few people you can trust for a long time rather than a wide circle, '
        'and looking at what you protected rather than regretting old choices can steady you.',
    LifeCategory.health:
        'Rather than holding strain in and bursting at once, you tend to do better booking rest in advance, '
        'and reading your body\'s signals often instead of forcing a verdict can help.',
    LifeCategory.constitution:
        'Your build tends to run firm, so watching for the buildup of held tension matters, '
        'and a planned release of strain usually suits you better than enduring it silently.',
    LifeCategory.social:
        'You tend to shine in tricky situations because you cannot let a wrong thing pass as right, '
        'though insisting only your standard is correct can leave you a little isolated.',
    LifeCategory.socialPersonality:
        'In a group you tend to be the one who calls things clearly and cuts through hesitation, '
        'and people often rely on you when a firm decision is needed.',
    LifeCategory.personality:
        'You tend to find it hard to accept what is wrong as right, '
        'which makes you sharp in difficult moments, though softening your edges keeps people close.',
    LifeCategory.innateTendency:
        'Your instinct tends to reach for decisive cuts — choosing cleanly and moving on — '
        'and a clear, no-blur judgement is closer to your nature than drawn-out hesitation.',
    LifeCategory.innateCharacter:
        'At your core you tend to carry the firm edge of tempered metal, '
        'and that decisive strength often shows most in how loyally you protect what you have chosen.',
    LifeCategory.loveFate:
        'Attraction tends to be clear-cut for you once you feel it, '
        'and you can be drawn to someone honest and direct who does not play games.',
    LifeCategory.affection:
        'In a lasting relationship you tend to show care through dependability and plain honesty, '
        'though softening how you phrase things can let your warmth come through more.',
    LifeCategory.wealth:
        'You tend to spend only when there is a reason, '
        'though pride can prompt a large outlay now and then, so setting a standard in advance helps.',
    LifeCategory.wealthGather:
        'Saving tends to work for you when it is rule-based and clear, '
        'and a fixed system you can follow without debate usually adds up well.',
    LifeCategory.wealthLossPrevent:
        'Your main leak tends to be a pride-driven large purchase, '
        'so deciding limits before the moment can keep that impulse in check.',
    LifeCategory.wealthInvest:
        'A clear-rule, decisive approach tends to suit you, '
        'and sticking to a plan you set in advance usually serves you better than reacting to noise.',
    LifeCategory.conclusionSelf:
        'In one line, clean and decisive judgement is your core colour, '
        'and the loyal way you guard what you have chosen tends to be your real strength.',
  },
  // ── 辛 (sin) — 보석, 세련된 기준 ──
  '辛': {
    LifeCategory.earlyLife:
        'As a child you tend not to just follow the crowd, '
        'choosing instead what is pretty, sharp, or fits your own standard.',
    LifeCategory.midLife:
        'Through your thirties and forties your skill tends to come alive where details matter '
        'rather than where things are waved through, though pride can make asking for help hard.',
    LifeCategory.lateLife:
        'Later on people may come to you for advice more often, '
        'and saying it gently rather than too bluntly tends to keep that closeness warm.',
    LifeCategory.health:
        'Getting by on cut sleep tends to cost you more than it seems, '
        'so treating water, rest, and light stretching as a pretty routine can help you keep it.',
    LifeCategory.constitution:
        'Your build tends to be refined and a little sensitive, so a clean, well-kept routine '
        'usually suits you better than rough overexertion.',
    LifeCategory.social:
        'You tend to be valued for a precise eye and a sense of taste, '
        'and people can trust your read when something needs to be judged carefully.',
    LifeCategory.socialPersonality:
        'In a group you tend to be the one who lifts the quality of what everyone does, '
        'and that careful standard often makes others look to you for a final check.',
    LifeCategory.personality:
        'You tend to want to do things well, so a result you are not happy with can keep nagging at you, '
        'even when you act unbothered on the outside.',
    LifeCategory.innateTendency:
        'Your instinct tends to reach for a clear standard — refining and choosing precisely — '
        'and a sharp sense of quality is closer to your nature than rough approximation.',
    LifeCategory.innateCharacter:
        'At your core you tend to carry the cut clarity of a polished gem, '
        'and that refined precision often shows most in how thoughtfully you treat the people you value.',
    LifeCategory.loveFate:
        'Attraction tends to follow your own standard rather than the crowd, '
        'and you can be drawn to someone who feels genuine and meets the bar you quietly hold.',
    LifeCategory.affection:
        'In a lasting relationship you tend to show care through thoughtful, well-judged gestures, '
        'though easing up on a high standard now and then keeps the bond relaxed.',
    LifeCategory.wealth:
        'Your strengths tend to pay off in fields that need an eye and judgement — '
        'design, beauty, content, analysis, planning — though a low mood can prompt impulse buys.',
    LifeCategory.wealthGather:
        'Saving tends to work when it feels well-kept and tidy, '
        'and treating it as a clean routine you take pride in usually keeps it going.',
    LifeCategory.wealthLossPrevent:
        'Your main leak tends to be a purchase made when your mood drops, '
        'so noticing that pattern and pausing first can protect you well.',
    LifeCategory.wealthInvest:
        'A precise, well-researched approach tends to suit you, '
        'and judging by clear facts rather than mood usually serves you better.',
    LifeCategory.conclusionSelf:
        'In one line, a refined, precise standard is your core colour, '
        'and your eye for quality tends to be the strength people come to rely on.',
  },
  // ── 壬 (im) — 큰 강·바다, 넓은 흐름 ──
  '壬': {
    LifeCategory.earlyLife:
        'As a kid you tend to catch trends fast and pick up the key point quickly, '
        'though your interest can be wide enough to scatter your attention.',
    LifeCategory.midLife:
        'Through your thirties and forties a wide early curiosity can look unfocused at first, '
        'but in time you tend to read people and shifting situations well.',
    LifeCategory.lateLife:
        'Later on you tend to keep the openness to take in new culture, music, and people '
        'rather than clinging to old ways, which can keep your circle lively.',
    LifeCategory.health:
        'A broken rhythm from late nights or long screen time tends to drop your condition fast, '
        'so keeping at least your sleeping hour as a fixed routine can help.',
    LifeCategory.constitution:
        'Your build tends to flow and adapt, so a steady rhythm anchors you, '
        'and protecting regular sleep usually matters more for you than for most.',
    LifeCategory.social:
        'You tend to move easily between different people and settings, '
        'and that adaptable, wide-angle ease can make you a natural connector.',
    LifeCategory.socialPersonality:
        'In a group you tend to be the one who bridges different sides, '
        'and people often rely on you to read the wider mood and keep things flowing.',
    LifeCategory.personality:
        'You tend to take a friend\'s worries in more deeply than expected, '
        'though with many options a decision can come slow, so narrowing the field early helps.',
    LifeCategory.innateTendency:
        'Your instinct tends to reach for movement and flow — adapting rather than fixing in place — '
        'and a wide, shifting curiosity is closer to your nature than a narrow groove.',
    LifeCategory.innateCharacter:
        'At your core you tend to carry the wide view of a broad river, '
        'and that open, taking-it-all-in nature often shows most in how easily you understand people.',
    LifeCategory.loveFate:
        'Attraction tends to be easy to spark for you, '
        'and you can be drawn to someone interesting who keeps your wide curiosity engaged.',
    LifeCategory.affection:
        'In a lasting relationship you tend to keep things fresh and open, '
        'though steadying into a dependable rhythm can deepen the bond over time.',
    LifeCategory.wealth:
        'Your possibilities tend to grow wherever you connect with information, people, movement, '
        'content, language, and trends, more than through plain repetition.',
    LifeCategory.wealthGather:
        'Saving tends to work when you make it automatic, '
        'since a fixed transfer can keep money aside even when your attention is elsewhere.',
    LifeCategory.wealthLossPrevent:
        'Money can slip away across many small, scattered interests, '
        'so a simple monthly review of where it went tends to protect you well.',
    LifeCategory.wealthInvest:
        'A broad, well-spread approach tends to suit you, '
        'and resisting the pull of every new trend usually serves you better than chasing each one.',
    LifeCategory.conclusionSelf:
        'In one line, a wide, flowing adaptability is your core colour, '
        'and the way you read people and change tends to be your real strength.',
  },
  // ── 癸 (gye) — 이슬·옹달샘, 깊은 직관 ──
  '癸': {
    LifeCategory.earlyLife:
        'As a child you tend to sense a shift in mood quickly '
        'and hold onto a scene that stayed with you, with a deep warmth showing once you grow close.',
    LifeCategory.midLife:
        'Through your thirties and forties you tend to speak and move precisely at the needed moment '
        'rather than standing out fast, like a quietly skilled member with a steady presence.',
    LifeCategory.lateLife:
        'Later on you tend to guide by gently wrapping around people rather than pushing hard, '
        'and protecting your own quiet time can keep you comfortable.',
    LifeCategory.health:
        'When sleep is short or tension builds, your energy tends to sag easily, '
        'so a warm daily rhythm and enough rest usually suit you well.',
    LifeCategory.constitution:
        'Your build tends to be sensitive and easily moved, so warmth and gentle routine anchor you, '
        'and enough rest usually serves you better than strain.',
    LifeCategory.social:
        'You tend to pick up on what others feel without it being said, '
        'and that quiet sensitivity can make people feel genuinely understood around you.',
    LifeCategory.socialPersonality:
        'In a group you tend to be the one who notices the unspoken mood, '
        'and that perceptiveness often makes you the gentle steadying presence others trust.',
    LifeCategory.personality:
        'You tend to be good at reading other people\'s hearts, '
        'and even when you look calm on the outside, a rich playlist of feeling can be turning inside.',
    LifeCategory.innateTendency:
        'Your instinct tends to reach for intuition — sensing before reasoning — '
        'and a deep, quiet perceptiveness is closer to your nature than loud, direct push.',
    LifeCategory.innateCharacter:
        'At your core you tend to carry the seeping depth of a clear spring, '
        'and that intuitive warmth often shows most in how gently you understand the people close to you.',
    LifeCategory.loveFate:
        'Attraction tends to begin quietly and run deep for you, '
        'and you can be drawn to someone whose feeling you can sense as genuine.',
    LifeCategory.affection:
        'In a lasting relationship you tend to show care through quiet, perceptive attention, '
        'though saying plainly what you sense and feel can keep things clear between you.',
    LifeCategory.wealth:
        'Impulse spending can show up when your feelings are stirred, '
        'so a habit of recording and comparing tends to guard your wallet well.',
    LifeCategory.wealthGather:
        'Saving tends to suit you when it is gentle and out of sight, '
        'and a quiet automatic habit can let an amount build without testing your willpower.',
    LifeCategory.wealthLossPrevent:
        'Your main leak tends to be a purchase made when your mood is unsettled, '
        'so a short pause to check how you feel first can protect you well.',
    LifeCategory.wealthInvest:
        'A calm, well-noted approach tends to suit you, '
        'and stepping back when your feelings are stirred usually serves you better than acting on them.',
    LifeCategory.conclusionSelf:
        'In one line, a deep, intuitive sensitivity is your core colour, '
        'and the way you quietly understand people tends to be your real strength.',
  },
};

/// R107 — 일간 hanja 키 fallback chain.
/// SajuResult.dayMaster 가 한자가 아닌 변형(한글 등)으로 올 경우 대비.
const Map<String, String> _stemAliasToHanja = {
  '갑': '甲', '을': '乙', '병': '丙', '정': '丁', '무': '戊',
  '기': '己', '경': '庚', '신': '辛', '임': '壬', '계': '癸',
  'gap': '甲', 'eul': '乙', 'byeong': '丙', 'jeong': '丁', 'mu': '戊',
  'gi': '己', 'gyeong': '庚', 'sin': '辛', 'im': '壬', 'gye': '癸',
};

/// R107 — 일간 키 정규화 (한자 우선, alias fallback).
String _normalizeStemKey(String stem) {
  if (kLifeCategoryBodyEnByStem.containsKey(stem)) return stem;
  return _stemAliasToHanja[stem] ?? stem;
}

/// R106 호환 carrier — 일간 무관 generic 영어 본문 (개인화 lookup 실패 시 fallback).
/// R107 부터 메인 경로는 `categoryBodyEnFor(stem, category)`.
const Map<LifeCategory, String> kLifeCategoryBodyEn = {
  LifeCategory.earlyLife:
      'In your earlier years you tend to take in your surroundings closely before you act, '
      'and the habits you pick up young can quietly shape the direction you grow toward.',
  LifeCategory.midLife:
      'Through your middle years your own pace tends to settle, and both your work and your closer '
      'relationships can find a steadier rhythm if you let them build rather than rushing them.',
  LifeCategory.lateLife:
      'In your later years a calmer, more grounded charm tends to come through, and the experience '
      'you have gathered can make you someone other people lean on.',
  LifeCategory.health:
      'Your energy tends to hold steady when your daily rhythm stays even, so regular sleep and small, '
      'consistent movement can do more for you than any sudden big effort.',
  LifeCategory.constitution:
      'Your body tends to respond well to warmth and steadiness, so gentle, regular routines usually '
      'suit you better than extremes, and a short pause when you feel stretched can go a long way.',
  LifeCategory.social:
      'Out in the wider world you tend to be seen as dependable, and you can shine most in settings '
      'where people trust you to hold things together.',
  LifeCategory.socialPersonality:
      'Within a group you tend to take on the role that keeps everyone steady, and people often turn '
      'to you when something needs a calm hand.',
  LifeCategory.personality:
      'Day to day you tend to be the kind of person friends describe as level and easy to be around, '
      'and that even temper is quietly one of your strengths.',
  LifeCategory.innateTendency:
      'Close to instinct, you tend to reach for steadiness first, and even without thinking about it '
      'you often look for the dependable path.',
  LifeCategory.innateCharacter:
      'At your core you tend to carry a quiet weight that others can rely on, and that grounded nature '
      'shows up most clearly in how you treat the people close to you.',
  LifeCategory.loveFate:
      'When attraction begins for you it tends to build gradually rather than all at once, and you can '
      'be drawn to people who feel genuine and steady.',
  LifeCategory.affection:
      'In a lasting relationship you tend to show care through steadiness and small daily gestures, '
      'and that consistency can matter more to you than grand moments.',
  LifeCategory.wealth:
      'Money tends to come to you through steady, accumulating effort rather than sudden windfalls, '
      'so a patient long arc usually serves you better than chasing a fast result.',
  LifeCategory.wealthGather:
      'Saving suits you when it is regular and low-drama, so setting a fixed amount aside each month '
      'tends to feel natural and quietly add up.',
  LifeCategory.wealthLossPrevent:
      'Money can slip away through impulse or pressure from others, so a short pause before any large '
      'spend tends to protect you well.',
  LifeCategory.wealthInvest:
      'A measured, steady approach to investing tends to suit you more than an aggressive one, so '
      'building slowly and avoiding sudden big bets usually fits you best.',
  LifeCategory.conclusionSelf:
      'Taken all together, you tend to be someone steady and genuine, and being exactly who you are '
      'is quietly your strongest draw.',
};

/// 17 카테고리 영어 섹션 제목 (raw key 노출 방지).
const Map<String, String> kLifeCategoryTitleEn = {
  'early_life': 'Early Life',
  'mid_life': 'Middle Years',
  'late_life': 'Later Years',
  'health': 'Health',
  'constitution': 'Constitution',
  'social': 'Social Life',
  'social_personality': 'Social Self',
  'personality': 'Personality',
  'innate_tendency': 'Innate Tendency',
  'innate_character': 'Innate Character',
  'love_fate': 'Romance',
  'affection': 'Affection',
  'wealth': 'Wealth',
  'wealth_gather': 'Saving',
  'wealth_loss_prevent': 'Guarding Wealth',
  'wealth_invest': 'Investing',
  'conclusion_self': 'Who Am I',
};

/// JSON key → 영어 카테고리 제목.
String lifeCategoryTitleEn(String key) =>
    kLifeCategoryTitleEn[key] ?? key.replaceAll('_', ' ');

class LifeParagraphService {
  static const _path = 'assets/data/life_paragraphs.json';
  static Map<String, dynamic>? _cache;

  /// 사용자 mandate (R88 spec sprint 4 verbatim) 호환 — `LifeParagraphService().paragraph(...)`.
  /// 인스턴스 method 와 static method 둘 다 동일 동작.
  const LifeParagraphService();

  /// JSON 풀 lazy load (Flutter rootBundle).
  static Future<Map<String, dynamic>> _pool() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_path);
    _cache = json.decode(raw) as Map<String, dynamic>;
    return _cache!;
  }

  /// 테스트 주입용: pre-loaded map (rootBundle 우회).
  static void seedForTest(Map<String, dynamic> map) {
    _cache = map;
  }

  /// 캐시 reset — test 격리 용.
  static void resetCache() {
    _cache = null;
  }

  /// 일주 + 카테고리 + 성별 → paragraph (R88 호환 instance method).
  ///
  /// **R90 sprint 2**: 새 코드는 `paragraphForSaju(saju: ..., category: ...)`
  /// (사주 anchor 5축 fragment injection) 사용 권장.
  /// 이 method 는 R88/R89 test 호환성 유지를 위해 보존 — base lookup 만, fragment X.
  ///
  /// [dayPillar] = '갑자' / '을축' / ... / '계해' (60 일주 한국어).
  /// [category] = LifeCategory enum (17 + conclusion_self).
  /// [gender] = 'M' or 'F' or null. 성별 분기 카테고리에서만 사용.
  ///   - null + 성별 분기 카테고리 = M paragraph fallback (spec 2.2.b 채택).
  ///   - 성별 분기 X 카테고리 + gender 전달 = gender 무시.
  ///
  /// 일주 없음 → ''. 카테고리 없음 → ''.
  Future<String> paragraph({
    required String dayPillar,
    required LifeCategory category,
    String? gender,
  }) =>
      paragraphStatic(dayPillar: dayPillar, category: category, gender: gender);

  /// **R90 sprint 2 — 새 메인 method (사주 전체 + fragment injection)**.
  ///
  /// 사주 전체 + 카테고리 + 성별 → paragraph + anchor fragment 1~2 결합.
  ///
  /// 동작:
  ///   1. base paragraph = sprint 1 prefix 제거된 60 일주 DB lookup
  ///      (일주 정확 → 일간 fallback chain — 기존 R88 룰 보존).
  ///   2. fragment 1~2 = `LifeCategoryFragmentService.fragmentsFor(saju, category, gender)`
  ///      (사주 anchor 5축 — 5행압도/5행공허/월령/십성주력/격국 매트릭스).
  ///   3. 결합 = "$base $fragment1 $fragment2" (공백 1칸 join, 마침표 정합).
  ///
  /// 핵심: 같은 일주여도 사주 anchor 조합이 다르면 fragment 셋이 달라져 본문 차별화.
  ///
  /// 호출자 패턴 (sprint 5 sweep):
  /// - result_screen._CategorySectionCard → 이 method
  /// - LifeOverviewService.compose → anchor 6 직접 빌드 (이 method 미사용)
  /// - SelfConclusionService.conclude → 이 method 로 conclusion_self lookup
  Future<String> paragraphForSaju({
    required SajuResult saju,
    required LifeCategory category,
    String? gender,
  }) async {
    final dayPillarKo = _dayPillarKo(saju);
    final base = await paragraphStatic(
      dayPillar: dayPillarKo,
      category: category,
      gender: gender,
    );
    if (base.isEmpty) return '';
    final fragments = await LifeCategoryFragmentService.fragmentsFor(
      saju: saju,
      category: category,
      gender: gender,
    );
    return _mergeFragments(base, fragments);
  }

  /// `paragraphForSaju` 의 정적 alias — 헬퍼 service 가 인스턴스 없이 호출 가능.
  static Future<String> paragraphForSajuStatic({
    required SajuResult saju,
    required LifeCategory category,
    String? gender,
  }) => const LifeParagraphService().paragraphForSaju(
    saju: saju,
    category: category,
    gender: gender,
  );

  /// 기존 일주 단독 anchor signature (R88 호환).
  ///
  /// R90 사주 anchor 다층화 mandate 후로는 가능한 한 `paragraphForSajuStatic` 사용 권장.
  /// 이 method 는 LifeOverviewService 가 anchor 6 직접 빌드 시 base 본문 lookup 용으로
  /// 여전히 필요 (fragment 는 LifeOverviewService 가 별도 mount).
  static Future<String> paragraphStatic({
    required String dayPillar,
    required LifeCategory category,
    String? gender,
  }) async {
    final pool = await _pool();
    return lookup(
      pool,
      dayPillar: dayPillar,
      category: category,
      gender: gender,
    );
  }

  /// SajuResult → '신묘' 같은 한글 일주 key.
  static String _dayPillarKo(SajuResult saju) {
    const stemKo = {
      '甲': '갑',
      '乙': '을',
      '丙': '병',
      '丁': '정',
      '戊': '무',
      '己': '기',
      '庚': '경',
      '辛': '신',
      '壬': '임',
      '癸': '계',
    };
    const branchKo = {
      '子': '자',
      '丑': '축',
      '寅': '인',
      '卯': '묘',
      '辰': '진',
      '巳': '사',
      '午': '오',
      '未': '미',
      '申': '신',
      '酉': '유',
      '戌': '술',
      '亥': '해',
    };
    final s = stemKo[saju.dayPillar.chunGan] ?? saju.dayPillar.chunGan;
    final b = branchKo[saju.dayPillar.jiJi] ?? saju.dayPillar.jiJi;
    return '$s$b';
  }

  /// base paragraph 끝에 fragment 1~2 를 자연스럽게 결합.
  ///
  /// 결합 룰 (spec sprint 5):
  /// - base 가 '. ' 또는 '요.' 로 끝나면 그대로 한 칸 공백 후 fragment join.
  /// - fragment 가 마침표로 끝나지 않으면 '.' 보강.
  static String _mergeFragments(String base, List<String> fragments) {
    if (fragments.isEmpty) return base;
    return NaturalProseJoiner.append(base, fragments);
  }

  /// 동기 lookup — pool map 을 직접 인자로 받음 (LifeOverviewService / SelfConclusionService 합성 용).
  ///
  /// R88 sprint 5 fallback chain:
  ///   1. 일주 60 정확 매칭 (예: '갑자') → paragraph 반환.
  ///   2. 일주 매칭 없음 + 일주 첫 글자 (일간) base 매칭 (예: '갑') → 일간 base paragraph 반환.
  ///   3. 둘 다 없음 → ''.
  /// 일간 fallback 은 sprint 5 의 핵심 — 일주 60 batch (sprint 6) 완성 전에도 service 작동 보장.
  static String lookup(
    Map<String, dynamic> pool, {
    required String dayPillar,
    required LifeCategory category,
    String? gender,
  }) {
    final key = lifeCategoryKey(category);
    // 1. 일주 60 정확 매칭.
    final exact = pool[dayPillar];
    if (exact is Map) {
      final raw = exact[key];
      if (raw != null) {
        return _extract(raw, category: category, gender: gender);
      }
    }
    // 2. 일간 fallback — 일주 첫 글자 (예: '갑자' → '갑').
    if (dayPillar.isNotEmpty) {
      final stem = dayPillar.substring(0, 1);
      final stemEntry = pool[stem];
      if (stemEntry is Map) {
        final raw = stemEntry[key];
        if (raw != null) {
          return _extract(raw, category: category, gender: gender);
        }
      }
    }
    // 3. 매칭 없음.
    return '';
  }

  /// raw value 에서 gender 분기 적용 후 string 반환.
  /// raw 가 String 또는 Map {M, F} 둘 다 대응.
  static String _extract(
    Object raw, {
    required LifeCategory category,
    String? gender,
  }) {
    if (raw is String) return raw;
    if (raw is! Map) return raw.toString();
    // raw is Map — 성별 분기 sub-object {M, F} 가정.
    if (gender == 'F' && raw.containsKey('F')) {
      return (raw['F'] ?? '').toString();
    }
    // gender null / 'M' / 다른 값 → M fallback (spec 2.2.b).
    if (raw.containsKey('M')) return (raw['M'] ?? '').toString();
    return '';
  }

  /// **R106 P5 — 영어 모드 카테고리 본문 (일간 무관 generic)**.
  ///
  /// R107 부터는 일주별 개인화가 mandate 라 `categoryBodyEnFor(saju, category)`
  /// 또는 `categoryBodyEnForStem(stem, category)` 가 메인 경로.
  /// 이 method 는 R106 호환·일간 unknown fallback 용으로 보존.
  static String categoryBodyEn(LifeCategory category) =>
      kLifeCategoryBodyEn[category] ??
      kLifeCategoryBodyEn[LifeCategory.personality]!;

  /// **R107 — 영어 모드 카테고리 본문 (일간별 개인화)**.
  ///
  /// 사용자 일간(천간) 으로 170 맵(`kLifeCategoryBodyEnByStem`)에서 lookup.
  /// 한국어 life_paragraphs.json 의 일간 stem entry 와 동일 내용·동일 17 카테고리.
  /// 일간이 170 맵에 없으면 generic carrier(`kLifeCategoryBodyEn`)로 fallback.
  ///
  /// [stem] = 천간 한자('甲'/'乙'/...) 또는 한글/로마자 alias.
  static String categoryBodyEnForStem(String stem, LifeCategory category) {
    final key = _normalizeStemKey(stem);
    final byStem = kLifeCategoryBodyEnByStem[key];
    if (byStem != null) {
      final body = byStem[category];
      if (body != null && body.isNotEmpty) return body;
    }
    return categoryBodyEn(category);
  }

  /// `categoryBodyEnForStem` 의 SajuResult 편의 wrapper.
  /// 사용자 사주의 일간(`saju.dayPillar.chunGan`)으로 개인화 본문 반환.
  static String categoryBodyEnFor(SajuResult saju, LifeCategory category) =>
      categoryBodyEnForStem(saju.dayPillar.chunGan, category);

  /// 일주가 DB 에 있는지.
  static Future<bool> hasDayPillar(String dayPillar) async {
    final pool = await _pool();
    return pool.containsKey(dayPillar);
  }

  /// DB 에 있는 모든 일주 list.
  static Future<List<String>> availableDayPillars() async {
    final pool = await _pool();
    return pool.keys.toList();
  }
}
