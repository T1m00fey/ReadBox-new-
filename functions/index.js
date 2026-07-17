/* ──────────────────────────── импорты ──────────────────────────── */
import { initializeApp }         from "firebase-admin/app";
import { getAuth }               from "firebase-admin/auth";
import {
  getFirestore,
  FieldValue
}                                from "firebase-admin/firestore";
import { getMessaging }          from "firebase-admin/messaging";
import {
  onDocumentCreated,
  onDocumentUpdated
}                                from "firebase-functions/v2/firestore";
import { onRequest }             from "firebase-functions/v2/https";
import { onSchedule }            from "firebase-functions/v2/scheduler";
import { defineSecret }          from "firebase-functions/params";
import { logger }                from "firebase-functions";
import { getStorage }            from "firebase-admin/storage"; // ← НОВОЕ
import { XMLParser }             from "fast-xml-parser";
import sharp                     from "sharp";

/* ─────────────────────── инициализация SDK ─────────────────────── */
initializeApp();
const db = getFirestore();
const NEWSAPIAI_API_KEY = defineSecret("NEWSAPIAI_API_KEY");
const CURRENTS_API_KEY = defineSecret("CURRENTS_API_KEY");
const NEWSAPIORG_API_KEY = defineSecret("NEWSAPIORG_API_KEY");
const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");

const WORLD_NEWS_BLACKLIST = [
  // Добавляйте сюда домены, которые не должны попадать в мировую ленту.
  // Для блокировки всей доменной зоны используйте запись с точкой, например ".ua".
  ".ua",
  "bbc.com",
  "bbc.co.uk",
  "currenttime.tv",
  "dw.com",
  "euronews.com",
  "golosameriki.com",
  "meduza.io",
  "rferl.org",
  "svoboda.org",
  "voanews.com",
  "objectiv.tv",
  "unian.net",
  "ru.krymr.com",
  "svobodanews.ru",
  "korrespondent.net",
  "from-ua.org",
  "tvrain.ru",
  "gs.by"
];

const WORLD_NEWS_CATEGORY_URIS = [
  "news/Business",
  "news/Technology",
  "news/Science"
];
const CURRENTS_WORLD_NEWS_CATEGORIES = [
  "economy_business_finance",
  "science_technology"
];

const WORLD_NEWS_MAX_STORED = 240;
const WORLD_NEWS_TRANSLATION_MODEL = "gpt-5.4-mini";
const EVENT_REGISTRY_WORLD_NEWS_LIMIT = 60;
const CURRENTS_WORLD_NEWS_LIMIT = 40;
const EN_AGGREGATOR_MIX_LIMIT = 12;
const RU_EVENT_REGISTRY_BURST = 10;
const RU_CURRENTS_BURST = 7;
const RU_TRANSLATED_BURST = 3;
const RU_WORLD_NEWS_MAX_COUNT = 100;
const NEWSAPIORG_WORLD_NEWS_LIMIT = 24;
const NASA_JPL_WORLD_NEWS_LIMIT = 16;
const USGS_WORLD_NEWS_LIMIT = 14;
const NOAA_WORLD_NEWS_LIMIT = 14;
const THE_CONVERSATION_WORLD_NEWS_LIMIT = 90;
const NSF_WORLD_NEWS_LIMIT = 12;
const NIST_WORLD_NEWS_LIMIT = 12;
const TECHCRUNCH_WORLD_NEWS_LIMIT = 110;
const ARS_TECHNICA_WORLD_NEWS_LIMIT = 95;
const NASA_JPL_FEED_URL = "https://www.jpl.nasa.gov/feeds/news/";
const NASA_BREAKING_NEWS_FEED_URL = "https://www.nasa.gov/rss/dyn/breaking_news.rss";
const USGS_FEED_URL = "https://www.usgs.gov/rss.xml?path=/news/featured-stories";
const USGS_SNIPPETS_FEED_URL = "https://www.usgs.gov/rss.xml?path=/news/science-snippets";
const NOAA_FEED_URL = "https://oceanservice.noaa.gov/rss/nosnews.xml";
const NOAA_NEWSROOM_FEED_URL = "https://oceanservice.noaa.gov/rss/nosnewsroom.xml";
const THE_CONVERSATION_FEED_URL = "https://theconversation.com/us/feeds/articles.atom";
const NSF_NEWS_FEED_URL = "https://www.nsf.gov/rss/rss_www_news.xml";
const NIST_NEWS_FEED_URL = "https://www.nist.gov/news-events/news/rss.xml";
const TECHCRUNCH_FEED_URL = "https://techcrunch.com/feed/";
const ARS_TECHNICA_FEED_URL = "https://feeds.arstechnica.com/arstechnica/index";
const NEWSAPIORG_EVERYTHING_URL = "https://newsapi.org/v2/everything";
const NEWSAPIORG_WORLD_QUERIES = [
  "\"artificial intelligence\" OR AI OR robotics",
  "\"space exploration\" OR astronomy OR satellite",
  "\"scientific discovery\" OR research breakthrough",
  "\"consumer technology\" OR gadgets OR smartphone",
  "\"startup innovation\" OR venture capital OR founders",
  "\"entertainment industry\" OR streaming OR film technology"
];
const BLOCKED_SOURCE_LOCATION_CODES = new Set(["ua"]);
const BLOCKED_SOURCE_LOCATION_KEYWORDS = [
  "ukraine",
  "ukraina",
  "украина"
];
const RU_POLITICAL_WORLD_NEWS_KEYWORDS = [
  "политик",
  "политика",
  "президент",
  "премьер",
  "правительств",
  "госдум",
  "дума",
  "кремл",
  "мид",
  "минобороны",
  "нато",
  "санкц",
  "депутат",
  "законопроект",
  "выбор",
  "переговор",
  "армия",
  "военн",
  "боев",
  "фронт",
  "ракет",
  "удар",
  "обстрел",
  "дрон",
  "беспилот"
];
const RU_TRANSLATABLE_WORLD_NEWS_PROVIDERS = new Set([
  "techcrunch",
  "arstechnica",
  "theconversation",
  "nasajpl",
  "nasa",
  "usgs",
  "noaa",
  "nsf",
  "nist"
]);
const xmlParser = new XMLParser({
  ignoreAttributes: false,
  attributeNamePrefix: ""
});

async function detectFirstMediaEmoji(articleId, mediaCount, mediaVersion) {
  const v = mediaVersion ?? 1;
  const bucket = getStorage().bucket();

  // Для нового формата (v2) без медиа вообще не ищем ничего
  if (v === 2 && (!mediaCount || mediaCount <= 0)) {
    return "";
  }

  try {
    if (v === 2) {
      // новый формат...

      const previewFile = bucket.file(`images/${articleId}_0_preview.jpg`);
      const [previewExists] = await previewFile.exists();
      if (previewExists) return "📹 ";

      const videoFile = bucket.file(`images/${articleId}_0.mp4`);
      const [videoExists] = await videoFile.exists();
      if (videoExists) return "📹 ";

      const imageFile = bucket.file(`images/${articleId}_0.jpg`);
      const [imageExists] = await imageFile.exists();
      if (imageExists) return "📷 ";
    } else {
      // СТАРЫЙ формат: images/{id}.jpg / .mp4
      const videoFile = bucket.file(`images/${articleId}.mp4`);
      const [videoExists] = await videoFile.exists();
      if (videoExists) return "📹 ";

      const imageFile = bucket.file(`images/${articleId}.jpg`);
      const [imageExists] = await imageFile.exists();
      if (imageExists) return "📷 ";
    }
  } catch (err) {
    logger.error("⚠️ detectFirstMediaEmoji error", err);
  }

  return "";
}

/* ─────────── helper: токены пользователя по документу ─────────── */

function collectTokensFromUserDoc(doc) {
  const d = doc.data();
  const tokens = [];

  if (d.fcm_tokens && typeof d.fcm_tokens === "object") {
    tokens.push(...Object.keys(d.fcm_tokens));
  }
  if (typeof d.fcm_token === "string" && d.fcm_token.length) {
    tokens.push(d.fcm_token);
  }

  return tokens;
}

function normalizeLikedPosts(value) {
  if (!value) return [];
  if (Array.isArray(value)) return value.filter(Boolean);
  if (typeof value === "object") return Object.keys(value);
  return [];
}

function normalizeSubscribes(value) {
  if (!value) return [];
  if (Array.isArray(value)) return value.filter(Boolean);
  if (typeof value === "object") return Object.keys(value);
  return [];
}

function normalizeLanguage(value) {
  try {
    const normalized = String(value || "")
      .trim()
      .toLowerCase();

    return normalized === "ru" ? "ru" : "en";
  } catch (err) {
    logger.error("⚠️ normalizeLanguage error", err);
    return "en";
  }
}

function getUserOriginalLanguage(userData) {
  return normalizeLanguage(userData?.original_language);
}

function getPremiumPublicationBody(language) {
  return language === "ru"
    ? "Публикация в Read+"
    : "Publication in Read+";
}

function getLikedArticleBody(language, isShortPost, shortTitle) {
  const baseText = language === "ru"
    ? (isShortPost ? "оценил(а) вашу публикацию" : "оценил(а) вашу статью")
    : (isShortPost ? "liked your post" : "liked your article");

  return shortTitle.length > 0
    ? `${baseText} “${shortTitle}”`
    : baseText;
}

function getSubscribedBody(language) {
  return language === "ru"
    ? "подписался(-ась) на вас"
    : "subscribed to you";
}

function getCommentedArticleBody(language, isShortPost, shortTitle) {
  const baseText = language === "ru"
    ? (isShortPost ? "прокомментировал(а) вашу публикацию" : "прокомментировал(а) вашу статью")
    : (isShortPost ? "commented on your post" : "commented on your article");

  return shortTitle.length > 0
    ? `${baseText} “${shortTitle}”`
    : baseText;
}

function getCommentReplyBody(language, shortTitle) {
  const baseText = language === "ru"
    ? "ответил(а) на ваш комментарий"
    : "replied to your comment";

  return shortTitle.length > 0
    ? `${baseText} “${shortTitle}”`
    : baseText;
}

function sanitizeGeneratedValue(value) {
  return String(value || "")
    .replace(/\r\n/g, "\n")
    .trim();
}

function buildWorldNewsCollectionName(language) {
  return language === "ru"
    ? "world_news_ru"
    : "world_news_en";
}

function buildWorldNewsDocId(url) {
  return Buffer.from(String(url || ""), "utf8").toString("base64url").slice(0, 500);
}

async function createInAppNotification({
  userId,
  type,
  actorId = "",
  postId = ""
}) {
  const normalizedUserId = sanitizeGeneratedValue(userId);
  if (!normalizedUserId) {
    return;
  }

  const ref = db.collection("notifications").doc();
  const expiresAt = new Date(Date.now() + 14 * 24 * 60 * 60 * 1000);

  const data = {
    user_id: normalizedUserId,
    type: sanitizeGeneratedValue(type),
    actor_id: sanitizeGeneratedValue(actorId),
    post_id: sanitizeGeneratedValue(postId),
    date_created: FieldValue.serverTimestamp(),
    expires_at: expiresAt,
    is_read: false
  };

  await ref.set(data);
}

function firstNonEmptyString(...values) {
  for (const value of values.flat(Infinity)) {
    const normalized = sanitizeGeneratedValue(value);

    if (normalized) {
      return normalized;
    }
  }

  return "";
}

function stripHtml(value) {
  return sanitizeGeneratedValue(value)
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1")
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;/gi, " ")
    .replace(/&amp;/gi, "&")
    .replace(/&quot;/gi, "\"")
    .replace(/&#39;/gi, "'")
    .replace(/\s+/g, " ")
    .trim();
}

function stripNewsApiContentSuffix(value) {
  return sanitizeGeneratedValue(value)
    .replace(/\s*\[\+\d+\schars\]\s*$/i, "")
    .trim();
}

function mapWorldNewsArticle(language, article, provider = "eventregistry") {
  const url = firstNonEmptyString(article?.url, article?.link);
  const title = firstNonEmptyString(article?.title);

  if (!url || !title) {
    return null;
  }

  const description = provider === "currents"
    ? firstNonEmptyString(article?.description)
    : "";
  const content = provider === "currents"
    ? firstNonEmptyString(article?.description)
    : firstNonEmptyString(
      article?.body,
      article?.content,
      article?.description,
      article?.summary,
      article?.excerpt
    );
  const imageURL = firstNonEmptyString(
    article?.image,
    article?.media,
    article?.image_url,
    article?.thumbnail
  );
  const sourceName = firstNonEmptyString(
    article?.source_name,
    article?.source?.title,
    article?.author,
    article?.source,
    article?.clean_url,
    article?.domain_url
  );
  const domainURL = firstNonEmptyString(
    article?.domain_url,
    article?.source?.uri,
    article?.source,
    normalizeDomain(url)
  );
  const publishedAtRaw = firstNonEmptyString(
    article?.dateTimePub,
    article?.dateTime,
    article?.published,
    article?.published_date,
    article?.published_at,
    article?.publishedAt
  );

  return {
    id: buildWorldNewsDocId(url),
    provider,
    language,
    title,
    description,
    content,
    url,
    image_url: imageURL,
    source_name: sourceName,
    domain_url: domainURL,
    published_at: publishedAtRaw ? new Date(publishedAtRaw) : new Date()
  };
}

function getErrorDetails(error) {
  if (!error) {
    return "unknown-error";
  }

  const parts = [
    error?.message,
    error?.cause?.message,
    error?.code,
    error?.cause?.code,
    error?.errno,
    error?.cause?.errno
  ]
    .map((value) => sanitizeGeneratedValue(value))
    .filter(Boolean);

  return parts.length ? parts.join(" | ") : "unknown-error";
}

function buildWorldNewsTranslationPrompt(article) {
  const title = sanitizeGeneratedValue(article?.title);
  const description = sanitizeGeneratedValue(article?.description);
  const content = sanitizeGeneratedValue(article?.content).slice(0, 6000);

  return [
    "Translate this news item from English to Russian.",
    "Return valid JSON only with keys: title, description, content.",
    "Rules:",
    "- Preserve facts, names, and numbers.",
    "- Do not invent details.",
    "- Use natural Russian suitable for a news feed.",
    "- If a field is empty, return an empty string for that field.",
    "",
    `title: ${title || ""}`,
    `description: ${description || ""}`,
    `content: ${content || ""}`
  ].join("\n");
}

function sortWorldNewsArticlesByDate(articles) {
  return [...articles].sort(
    (left, right) => normalizeNewsDate(right.published_at) - normalizeNewsDate(left.published_at)
  );
}

function uniqueWorldNewsArticles(articles) {
  return Array.from(
    new Map(
      articles
        .filter((article) => article?.id)
        .map((article) => [article.id, article])
    ).values()
  );
}

function mixWorldNewsArticles({
  primaryArticles,
  secondaryArticles,
  primaryBurst = 3,
  secondaryBurst = 1,
  maxCount = 100
}) {
  const primary = [...primaryArticles];
  const secondary = [...secondaryArticles];
  const mixed = [];

  while ((primary.length || secondary.length) && mixed.length < maxCount) {
    for (let index = 0; index < primaryBurst && primary.length && mixed.length < maxCount; index += 1) {
      mixed.push(primary.shift());
    }

    for (let index = 0; index < secondaryBurst && secondary.length && mixed.length < maxCount; index += 1) {
      mixed.push(secondary.shift());
    }

    if (!primary.length && secondary.length) {
      mixed.push(...secondary.splice(0, maxCount - mixed.length));
    }

    if (!secondary.length && primary.length) {
      mixed.push(...primary.splice(0, maxCount - mixed.length));
    }
  }

  return uniqueWorldNewsArticles(mixed).slice(0, maxCount);
}

function mixThreeWorldNewsArticleGroups({
  primaryArticles,
  secondaryArticles,
  tertiaryArticles,
  primaryBurst = 1,
  secondaryBurst = 1,
  tertiaryBurst = 1,
  maxCount = 100
}) {
  const primary = [...primaryArticles];
  const secondary = [...secondaryArticles];
  const tertiary = [...tertiaryArticles];
  const mixed = [];

  while ((primary.length || secondary.length || tertiary.length) && mixed.length < maxCount) {
    for (let index = 0; index < primaryBurst && primary.length && mixed.length < maxCount; index += 1) {
      mixed.push(primary.shift());
    }

    for (let index = 0; index < secondaryBurst && secondary.length && mixed.length < maxCount; index += 1) {
      mixed.push(secondary.shift());
    }

    for (let index = 0; index < tertiaryBurst && tertiary.length && mixed.length < maxCount; index += 1) {
      mixed.push(tertiary.shift());
    }

    if (!primary.length && !secondary.length && tertiary.length) {
      mixed.push(...tertiary.splice(0, maxCount - mixed.length));
    }

    if (!primary.length && !tertiary.length && secondary.length) {
      mixed.push(...secondary.splice(0, maxCount - mixed.length));
    }

    if (!secondary.length && !tertiary.length && primary.length) {
      mixed.push(...primary.splice(0, maxCount - mixed.length));
    }

    if (!primary.length && secondary.length && tertiary.length) {
      mixed.push(...secondary.splice(0, Math.min(secondary.length, maxCount - mixed.length)));
      mixed.push(...tertiary.splice(0, Math.min(tertiary.length, maxCount - mixed.length)));
    }

    if (!secondary.length && primary.length && tertiary.length) {
      mixed.push(...primary.splice(0, Math.min(primary.length, maxCount - mixed.length)));
      mixed.push(...tertiary.splice(0, Math.min(tertiary.length, maxCount - mixed.length)));
    }

    if (!tertiary.length && primary.length && secondary.length) {
      mixed.push(...primary.splice(0, Math.min(primary.length, maxCount - mixed.length)));
      mixed.push(...secondary.splice(0, Math.min(secondary.length, maxCount - mixed.length)));
    }
  }

  return uniqueWorldNewsArticles(mixed).slice(0, maxCount);
}

function normalizeNewsDate(value) {
  if (value instanceof Date) {
    return value;
  }

  if (value && typeof value.toDate === "function") {
    try {
      return value.toDate();
    } catch (error) {
      logger.error("⚠️ normalizeNewsDate toDate error", error);
    }
  }

  const parsedDate = new Date(value);

  return Number.isNaN(parsedDate.getTime()) ? new Date(0) : parsedDate;
}

function normalizeDomain(value) {
  const normalized = sanitizeGeneratedValue(value)
    .toLowerCase()
    .replace(/^https?:\/\//, "")
    .replace(/^www\./, "")
    .split("/")[0]
    .split("?")[0]
    .split("#")[0];

  return normalized;
}

function getArticleDomain(article) {
  const candidates = [
    article?.domain_url,
    article?.clean_url,
    article?.link,
    article?.url
  ];

  for (const candidate of candidates) {
    const normalized = normalizeDomain(candidate);

    if (normalized) {
      return normalized;
    }
  }

  return "";
}

function getArticleSourceLocationValues(article) {
  const candidates = [
    article?.sourceLocationUri,
    article?.source?.location,
    article?.source?.location?.uri,
    article?.source?.location?.wikiUri,
    article?.source?.location?.label,
    article?.source?.location?.title,
    article?.source?.location?.country,
    article?.source?.location?.countryCode,
    article?.source?.location?.countryUri,
    article?.source?.country,
    article?.source?.countryCode,
    article?.source?.countryUri
  ].flat(Infinity);

  return candidates
    .map((value) => sanitizeGeneratedValue(value))
    .filter(Boolean);
}

function getWorldNewsBlacklist() {
  return WORLD_NEWS_BLACKLIST
    .map((domain) => normalizeDomain(domain))
    .filter(Boolean);
}

function isWorldNewsArticleBlockedBySourceLocation(article) {
  return getArticleSourceLocationValues(article).some((value) => {
    const normalizedValue = value.toLowerCase();

    if (BLOCKED_SOURCE_LOCATION_CODES.has(normalizedValue)) {
      return true;
    }

    return BLOCKED_SOURCE_LOCATION_KEYWORDS.some((keyword) => normalizedValue.includes(keyword));
  });
}

function isWorldNewsArticleBlocked(article) {
  if (isWorldNewsArticleBlockedBySourceLocation(article)) {
    return true;
  }

  const domain = getArticleDomain(article);

  if (!domain) {
    return false;
  }

  return getWorldNewsBlacklist().some((blockedDomain) => {
    if (blockedDomain.startsWith(".")) {
      const suffix = blockedDomain.slice(1);
      return domain === suffix || domain.endsWith(blockedDomain);
    }

    return domain === blockedDomain || domain.endsWith(`.${blockedDomain}`);
  });
}

function isRuPoliticalWorldNewsArticle(article) {
  const combinedText = [
    article?.title,
    article?.description,
    article?.content,
    article?.source_name
  ]
    .map((value) => sanitizeGeneratedValue(value).toLowerCase())
    .join(" ");

  if (!combinedText) {
    return false;
  }

  return RU_POLITICAL_WORLD_NEWS_KEYWORDS.some((keyword) => combinedText.includes(keyword));
}

async function translateWorldNewsArticleToRussian(article) {
  const apiKey = sanitizeGeneratedValue(OPENAI_API_KEY.value());

  if (!apiKey) {
    logger.warn("⚠️ OpenAI API key is missing, skipping RU news translation");
    return null;
  }

  const prompt = buildWorldNewsTranslationPrompt(article);

  let response;
  let payload;

  try {
    response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model: WORLD_NEWS_TRANSLATION_MODEL,
        messages: [
          {
            role: "developer",
            content: "You translate news content into Russian and return valid JSON only."
          },
          {
            role: "user",
            content: prompt
          }
        ],
        response_format: {
          type: "json_object"
        }
      })
    });
    payload = await response.json();
  } catch (error) {
    logger.error(`❌ OpenAI RU world news translation failed [${article?.id}]`, error);
    throw new Error(`openai-world-news-translation-failed: ${getErrorDetails(error)}`);
  }

  if (!response.ok) {
    logger.error("❌ OpenAI RU world news translation error", payload);
    throw new Error(
      firstNonEmptyString(
        payload?.error?.message,
        payload?.message,
        payload?.detail
      ) || `openai-world-news-status-${response.status}`
    );
  }

  const translatedContent = sanitizeGeneratedValue(
    payload?.choices?.[0]?.message?.content
  );

  if (!translatedContent) {
    throw new Error("empty-openai-world-news-translation");
  }

  let parsed;

  try {
    parsed = JSON.parse(translatedContent);
  } catch (error) {
    logger.error("❌ OpenAI RU world news translation JSON parse error", error, translatedContent);
    throw new Error("invalid-openai-world-news-translation-json");
  }

  return {
    ...article,
    language: "ru",
    title: sanitizeGeneratedValue(parsed?.title) || sanitizeGeneratedValue(article?.title),
    description: sanitizeGeneratedValue(parsed?.description),
    content: sanitizeGeneratedValue(parsed?.content) || sanitizeGeneratedValue(parsed?.description),
    translated_from_language: "en"
  };
}

async function translateWorldNewsArticlesToRussian(articles) {
  const translationCandidates = articles
    .filter((article) => RU_TRANSLATABLE_WORLD_NEWS_PROVIDERS.has(article?.provider))
    .slice(0, 40);

  if (!translationCandidates.length) {
    return [];
  }

  const results = await Promise.allSettled(
    translationCandidates.map((article) => translateWorldNewsArticleToRussian(article))
  );

  return results
    .filter((result) => result.status === "fulfilled" && result.value)
    .map((result) => result.value);
}

function getBearerToken(req) {
  const header = req.headers.authorization || "";

  if (!header.startsWith("Bearer ")) {
    return "";
  }

  return header.slice("Bearer ".length).trim();
}

async function verifyRequestUser(req) {
  const token = getBearerToken(req);

  if (!token) {
    throw new Error("missing-auth-token");
  }

  return getAuth().verifyIdToken(token);
}

function parseRssItems(payload) {
  const parsed = xmlParser.parse(payload);

  if (Array.isArray(parsed?.rss?.channel?.item)) {
    return parsed.rss.channel.item;
  }

  if (parsed?.rss?.channel?.item) {
    return [parsed.rss.channel.item];
  }

  if (Array.isArray(parsed?.feed?.entry)) {
    return parsed.feed.entry;
  }

  if (parsed?.feed?.entry) {
    return [parsed.feed.entry];
  }

  return [];
}

function mapNasaJplRssItem(item) {
  const linkValue = Array.isArray(item?.link)
    ? firstNonEmptyString(...item.link.map((entry) => entry?.href || entry))
    : firstNonEmptyString(item?.link?.href, item?.link);
  const title = stripHtml(firstNonEmptyString(item?.title, item?.["title#text"]));

  if (!linkValue || !title) {
    return null;
  }

  const description = stripHtml(
    firstNonEmptyString(
      item?.description,
      item?.summary
    )
  );
  const content = stripHtml(
    firstNonEmptyString(
      item?.["content:encoded"],
      item?.content,
      item?.summary,
      item?.description
    )
  );
  const imageURL = firstNonEmptyString(
    item?.enclosure?.url,
    item?.["media:content"]?.url,
    item?.["media:thumbnail"]?.url
  );
  const publishedAtRaw = firstNonEmptyString(
    item?.pubDate,
    item?.published,
    item?.updated
  );

  return {
    id: buildWorldNewsDocId(linkValue),
    provider: "nasajpl",
    language: "en",
    title,
    description,
    content,
    url: linkValue,
    image_url: imageURL,
    source_name: "NASA JPL",
    domain_url: "jpl.nasa.gov",
    published_at: publishedAtRaw ? new Date(publishedAtRaw) : new Date()
  };
}

async function fetchEventRegistryWorldNews(language) {
  const apiKey = sanitizeGeneratedValue(NEWSAPIAI_API_KEY.value());

  if (!apiKey) {
    logger.warn(`⚠️ NewsAPI.ai API key is missing, skipping Event Registry sync [${language}]`);
    return [];
  }

  let response;
  let payload;

  try {
    response = await fetch("https://eventregistry.org/api/v1/article/getArticles", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        resultType: "articles",
        lang: normalizeLanguage(language) === "ru" ? "rus" : "eng",
        categoryUri: WORLD_NEWS_CATEGORY_URIS,
        dataType: ["news"],
        articlesSortBy: "date",
        articlesPage: 1,
        apiKey
      })
    });
    payload = await response.json();
  } catch (error) {
    logger.error(`❌ NewsAPI.ai fetch failed [${language}]`, error);
    throw new Error(`newsapiai-fetch-failed: ${getErrorDetails(error)}`);
  }

  if (!response.ok) {
    logger.error(`❌ NewsAPI.ai error [${language}]`, payload);
    throw new Error(
      firstNonEmptyString(
        payload?.message,
        payload?.detail,
        payload?.status,
        payload?.error
      ) || `newsapiai-status-${response.status}`
    );
  }

  if (!Array.isArray(payload?.articles?.results)) {
    throw new Error("invalid-newsapiai-response");
  }

  return payload.articles.results
    .filter((article) => !isWorldNewsArticleBlocked(article))
    .map((article) => mapWorldNewsArticle(language, article, "eventregistry"))
    .filter(Boolean)
    .slice(0, EVENT_REGISTRY_WORLD_NEWS_LIMIT);
}

async function fetchCurrentsWorldNews(language) {
  const apiKey = sanitizeGeneratedValue(CURRENTS_API_KEY.value());

  if (!apiKey) {
    logger.warn(`⚠️ Currents API key is missing, skipping Currents sync [${language}]`);
    return [];
  }

  const params = new URLSearchParams({
    language: normalizeLanguage(language),
    type: "1",
    page_number: "1",
    page_size: "30",
    apiKey
  });
  CURRENTS_WORLD_NEWS_CATEGORIES.forEach((category) => {
    params.append("category", category);
  });

  let response;
  let payload;

  try {
    response = await fetch(`https://api.currentsapi.services/v2/latest-news?${params.toString()}`);
    payload = await response.json();
  } catch (error) {
    logger.error(`❌ Currents fetch failed [${language}]`, error);
    throw new Error(`currents-fetch-failed: ${getErrorDetails(error)}`);
  }

  if (!response.ok || payload?.status === "error") {
    logger.error(`❌ Currents error [${language}]`, payload);
    throw new Error(
      firstNonEmptyString(
        payload?.message,
        payload?.detail,
        payload?.status
      ) || `currents-status-${response.status}`
    );
  }

  if (!Array.isArray(payload?.news)) {
    throw new Error("invalid-currents-response");
  }

  return payload.news
    .filter((article) => !isWorldNewsArticleBlocked(article))
    .map((article) => mapWorldNewsArticle(language, article, "currents"))
    .filter(Boolean)
    .slice(0, CURRENTS_WORLD_NEWS_LIMIT);
}

function mapNewsApiOrgArticle(language, article) {
  const url = firstNonEmptyString(article?.url);
  const title = firstNonEmptyString(article?.title);

  if (!url || !title) {
    return null;
  }

  const description = sanitizeGeneratedValue(article?.description);
  const content = stripNewsApiContentSuffix(
    firstNonEmptyString(article?.content, article?.description)
  );

  return {
    id: buildWorldNewsDocId(url),
    provider: "newsapiorg",
    language,
    title,
    description,
    content,
    url,
    image_url: sanitizeGeneratedValue(article?.urlToImage),
    source_name: firstNonEmptyString(article?.source?.name, "News API"),
    domain_url: normalizeDomain(url),
    published_at: firstNonEmptyString(article?.publishedAt)
      ? new Date(article.publishedAt)
      : new Date()
  };
}

async function fetchNewsApiOrgWorldNews(language) {
  const apiKey = sanitizeGeneratedValue(NEWSAPIORG_API_KEY.value());

  if (!apiKey) {
    logger.warn(`⚠️ NewsAPI.org API key is missing, skipping NewsAPI.org sync [${language}]`);
    return [];
  }

  const normalizedLanguage = normalizeLanguage(language);

  if (normalizedLanguage !== "en") {
    return [];
  }

  const queryResults = await Promise.allSettled(
    NEWSAPIORG_WORLD_QUERIES.map(async (query) => {
      const params = new URLSearchParams({
        q: query,
        language: "en",
        sortBy: "publishedAt",
        pageSize: "12",
        apiKey
      });

      let response;
      let payload;

      try {
        response = await fetch(`${NEWSAPIORG_EVERYTHING_URL}?${params.toString()}`);
        payload = await response.json();
      } catch (error) {
        logger.error(`❌ NewsAPI.org fetch failed [${language}] [${query}]`, error);
        throw new Error(
          `newsapiorg-fetch-failed [${language}] [${query}] -> ${NEWSAPIORG_EVERYTHING_URL}: ${getErrorDetails(error)}`
        );
      }

      if (!response.ok || payload?.status === "error") {
        logger.error(`❌ NewsAPI.org error [${language}] [${query}]`, payload);
        throw new Error(
          firstNonEmptyString(
            payload?.message,
            payload?.code,
            payload?.status
          ) || `newsapiorg-status-${response.status}`
        );
      }

      if (!Array.isArray(payload?.articles)) {
        throw new Error("invalid-newsapiorg-response");
      }

      return payload.articles
        .filter((article) => !isWorldNewsArticleBlocked(article))
        .map((article) => mapNewsApiOrgArticle(normalizedLanguage, article))
        .filter(Boolean);
    })
  );

  const successfulResults = queryResults
    .filter((result) => result.status === "fulfilled")
    .flatMap((result) => result.value);

  if (successfulResults.length === 0) {
    const firstRejected = queryResults.find((result) => result.status === "rejected");
    throw firstRejected?.reason ?? new Error("newsapiorg-fetch-failed");
  }

  return Array.from(
    new Map(successfulResults.map((article) => [article.id, article])).values()
  )
    .sort((left, right) => normalizeNewsDate(right.published_at) - normalizeNewsDate(left.published_at))
    .slice(0, NEWSAPIORG_WORLD_NEWS_LIMIT);
}

async function fetchNasaJplWorldNews() {
  let response;
  let payload;

  try {
    response = await fetch(NASA_JPL_FEED_URL);
    payload = await response.text();
  } catch (error) {
    logger.error("❌ NASA JPL RSS fetch failed", error);
    throw new Error(`nasajpl-fetch-failed: ${getErrorDetails(error)}`);
  }

  if (!response.ok) {
    throw new Error(`nasajpl-status-${response.status}`);
  }

  return parseRssItems(payload)
    .map((item) => mapNasaJplRssItem(item))
    .filter(Boolean)
    .slice(0, NASA_JPL_WORLD_NEWS_LIMIT);
}

function mapGenericRssWorldNewsItem(item, config) {
  const linkValue = Array.isArray(item?.link)
    ? firstNonEmptyString(...item.link.map((entry) => entry?.href || entry))
    : firstNonEmptyString(item?.link?.href, item?.link, item?.guid);
  const title = stripHtml(firstNonEmptyString(item?.title, item?.["title#text"]));

  if (!linkValue || !title) {
    return null;
  }

  const description = stripHtml(
    firstNonEmptyString(
      item?.description,
      item?.summary,
      item?.content,
      item?.["content:encoded"]
    )
  );
  const content = stripHtml(
    firstNonEmptyString(
      item?.["content:encoded"],
      item?.content,
      item?.summary,
      item?.description
    )
  );
  const imageURL = firstNonEmptyString(
    item?.enclosure?.url,
    item?.["media:content"]?.url,
    item?.["media:thumbnail"]?.url
  );
  const publishedAtRaw = firstNonEmptyString(
    item?.pubDate,
    item?.published,
    item?.updated
  );

  return {
    id: buildWorldNewsDocId(linkValue),
    provider: config.provider,
    language: normalizeLanguage(config.language),
    title,
    description,
    content,
    url: linkValue,
    image_url: imageURL,
    source_name: config.sourceName,
    domain_url: config.domain,
    published_at: publishedAtRaw ? new Date(publishedAtRaw) : new Date()
  };
}

async function fetchRssWorldNews(feedURL, config) {
  let response;
  let payload;

  try {
    response = await fetch(feedURL);
    payload = await response.text();
  } catch (error) {
    logger.error(`❌ ${config.sourceName} RSS fetch failed`, error);
    throw new Error(`${config.provider}-fetch-failed: ${getErrorDetails(error)}`);
  }

  if (!response.ok) {
    throw new Error(`${config.provider}-status-${response.status}`);
  }

  return parseRssItems(payload)
    .map((item) => mapGenericRssWorldNewsItem(item, config))
    .filter(Boolean)
    .slice(0, config.limit);
}

async function fetchRuTranslationSourceArticles() {
  const results = await Promise.allSettled([
    fetchRssWorldNews(TECHCRUNCH_FEED_URL, {
      provider: "techcrunch",
      sourceName: "TechCrunch",
      domain: "techcrunch.com",
      limit: TECHCRUNCH_WORLD_NEWS_LIMIT
    }),
    fetchRssWorldNews(ARS_TECHNICA_FEED_URL, {
      provider: "arstechnica",
      sourceName: "Ars Technica",
      domain: "arstechnica.com",
      limit: ARS_TECHNICA_WORLD_NEWS_LIMIT
    }),
    fetchRssWorldNews(THE_CONVERSATION_FEED_URL, {
      provider: "theconversation",
      sourceName: "The Conversation",
      domain: "theconversation.com",
      limit: THE_CONVERSATION_WORLD_NEWS_LIMIT
    }),
    fetchRssWorldNews(NSF_NEWS_FEED_URL, {
      provider: "nsf",
      sourceName: "NSF",
      domain: "nsf.gov",
      limit: 10
    }),
    fetchRssWorldNews(NIST_NEWS_FEED_URL, {
      provider: "nist",
      sourceName: "NIST",
      domain: "nist.gov",
      limit: 10
    }),
    fetchNasaJplWorldNews(),
    fetchRssWorldNews(NASA_BREAKING_NEWS_FEED_URL, {
      provider: "nasa",
      sourceName: "NASA",
      domain: "nasa.gov",
      limit: 6
    }),
    fetchRssWorldNews(USGS_FEED_URL, {
      provider: "usgs",
      sourceName: "USGS",
      domain: "usgs.gov",
      limit: 8
    }),
    fetchRssWorldNews(USGS_SNIPPETS_FEED_URL, {
      provider: "usgs",
      sourceName: "USGS",
      domain: "usgs.gov",
      limit: 6
    }),
    fetchRssWorldNews(NOAA_FEED_URL, {
      provider: "noaa",
      sourceName: "NOAA",
      domain: "noaa.gov",
      limit: 8
    }),
    fetchRssWorldNews(NOAA_NEWSROOM_FEED_URL, {
      provider: "noaa",
      sourceName: "NOAA",
      domain: "noaa.gov",
      limit: 6
    })
  ]);

  const successfulResults = results
    .filter((result) => result.status === "fulfilled")
    .flatMap((result) => result.value);

  return sortWorldNewsArticlesByDate(uniqueWorldNewsArticles(successfulResults));
}

async function fetchWorldNews(language, existingIds = new Set()) {
  const normalizedLanguage = normalizeLanguage(language);

  if (normalizedLanguage === "ru") {
    const ruResults = await Promise.allSettled([
      fetchEventRegistryWorldNews(normalizedLanguage)
    ]);

    const successfulRuResults = ruResults
      .filter((result) => result.status === "fulfilled")
      .flatMap((result) => result.value)
      .filter((article) => !isRuPoliticalWorldNewsArticle(article));

    if (successfulRuResults.length === 0) {
      const firstRejected = ruResults.find((result) => result.status === "rejected");
      throw firstRejected?.reason ?? new Error("world-news-fetch-failed");
    }

    const translatedRuArticles = await translateWorldNewsArticlesToRussian(
      (await fetchRuTranslationSourceArticles())
        .filter((article) => !existingIds.has(article?.id))
    );

    const translatedSorted = sortWorldNewsArticlesByDate(
      translatedRuArticles.filter((article) => article?.id && !existingIds.has(article.id))
    );

    const eventRegistrySorted = sortWorldNewsArticlesByDate(
      successfulRuResults.filter((article) => article?.provider === "eventregistry")
    );

    return mixWorldNewsArticles({
      primaryArticles: eventRegistrySorted,
      secondaryArticles: translatedSorted,
      primaryBurst: 5,
      secondaryBurst: 2,
      maxCount: RU_WORLD_NEWS_MAX_COUNT
    });
  }

  if (normalizedLanguage !== "en") {
    return [];
  }

  const results = await Promise.allSettled([
    fetchEventRegistryWorldNews(normalizedLanguage)
  ]);

  const successfulResults = results
      .filter((result) => result.status === "fulfilled")
      .flatMap((result) => result.value);

  if (successfulResults.length === 0) {
    const firstRejected = results.find((result) => result.status === "rejected");
    throw firstRejected?.reason ?? new Error("world-news-fetch-failed");
  }

  return sortWorldNewsArticlesByDate(uniqueWorldNewsArticles(successfulResults)).slice(0, 220);
}

async function mergeWorldNewsCollection(language, articles) {
  const collectionName = buildWorldNewsCollectionName(language);
  const collectionRef = db.collection(collectionName);
  const existingSnapshot = await collectionRef.get();
  const existingArticlesById = new Map();

  for (const document of existingSnapshot.docs) {
    const data = document.data();
    const id = sanitizeGeneratedValue(data?.id || document.id);

    if (!id) {
      continue;
    }

    existingArticlesById.set(id, {
      id,
      provider: sanitizeGeneratedValue(data?.provider),
      language,
      title: sanitizeGeneratedValue(data?.title),
      description: sanitizeGeneratedValue(data?.description),
      content: sanitizeGeneratedValue(data?.content),
      url: sanitizeGeneratedValue(data?.url),
      image_url: sanitizeGeneratedValue(data?.image_url),
      source_name: sanitizeGeneratedValue(data?.source_name),
      domain_url: sanitizeGeneratedValue(data?.domain_url),
      published_at: normalizeNewsDate(data?.published_at)
    });
  }

  const freshArticles = uniqueWorldNewsArticles(
    articles.map((article) => {
      const id = article?.id;

      if (!id) {
        return null;
      }

      return {
        id,
        provider: sanitizeGeneratedValue(article?.provider),
        language,
        title: sanitizeGeneratedValue(article?.title),
        description: sanitizeGeneratedValue(article?.description),
        content: sanitizeGeneratedValue(article?.content),
        url: sanitizeGeneratedValue(article?.url),
        image_url: sanitizeGeneratedValue(article?.image_url),
        source_name: sanitizeGeneratedValue(article?.source_name),
        domain_url: sanitizeGeneratedValue(article?.domain_url),
        published_at: article?.published_at instanceof Date
          ? article.published_at
          : normalizeNewsDate(article?.published_at)
      };
    }).filter(Boolean)
  );

  const freshIds = new Set(freshArticles.map((article) => article.id));
  const existingTail = sortWorldNewsArticlesByDate(
    Array.from(existingArticlesById.values()).filter((article) => !freshIds.has(article.id))
  );

  const mergedArticles = [...freshArticles, ...existingTail]
    .slice(0, WORLD_NEWS_MAX_STORED);

  const idsToKeep = new Set(mergedArticles.map((article) => article.id));

  let writeBatch = db.batch();
  let operations = 0;

  mergedArticles.forEach((article, index) => {
    const id = article?.id;

    if (!id) {
      return;
    }

    const ref = collectionRef.doc(id);

    writeBatch.set(ref, {
      id,
      provider: sanitizeGeneratedValue(article?.provider),
      language,
      title: sanitizeGeneratedValue(article?.title),
      description: sanitizeGeneratedValue(article?.description),
      content: sanitizeGeneratedValue(article?.content),
      url: sanitizeGeneratedValue(article?.url),
      image_url: sanitizeGeneratedValue(article?.image_url),
      source_name: sanitizeGeneratedValue(article?.source_name),
      domain_url: sanitizeGeneratedValue(article?.domain_url),
      published_at: article?.published_at instanceof Date
        ? article.published_at
        : normalizeNewsDate(article?.published_at),
      sort_index: index,
      updated_at: FieldValue.serverTimestamp()
    });

    operations += 1;
  });

  for (const document of existingSnapshot.docs) {
    if (idsToKeep.has(document.id)) {
      continue;
    }

    writeBatch.delete(document.ref);
    operations += 1;

    if (operations === 400) {
      await writeBatch.commit();
      writeBatch = db.batch();
      operations = 0;
    }
  }

  if (operations > 0) {
    await writeBatch.commit();
  }
}

async function getExistingWorldNewsIds(language) {
  const snapshot = await db.collection(buildWorldNewsCollectionName(language)).get();

  return new Set(
    snapshot.docs
      .map((document) => sanitizeGeneratedValue(document.data()?.id || document.id))
      .filter(Boolean)
  );
}

async function syncWorldNewsLanguage(language) {
  const existingIds = language === "ru"
    ? await getExistingWorldNewsIds(language)
    : new Set();
  const articles = await fetchWorldNews(language, existingIds);
  await mergeWorldNewsCollection(language, articles);

  logger.info(`📰 Synced world news [${language}] count=${articles.length}`);
}

export const syncWorldNews = onSchedule(
  {
    schedule: "every 30 minutes",
    timeZone: "Etc/UTC",
    secrets: [NEWSAPIAI_API_KEY, OPENAI_API_KEY]
  },
  async () => {
    logger.info("📰 syncWorldNews skipped");
  }
);

export const syncWorldNewsNow = onRequest(
  {
    cors: true,
    secrets: [NEWSAPIAI_API_KEY, OPENAI_API_KEY]
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "method-not-allowed" });
      return;
    }

    try {
      await verifyRequestUser(req);

      res.status(200).json({
        ok: true,
        disabled: true
      });
    } catch (error) {
      logger.error("❌ syncWorldNewsNow failed", error);

      res.status(500).json({
        error: error instanceof Error ? error.message : "unknown-error"
      });
    }
  }
);

function buildFirebaseStorageUrl(bucketName, objectName, token) {
  const encodedObjectName = encodeURIComponent(objectName);
  return `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodedObjectName}?alt=media&token=${token}`;
}

async function getPublicFileUrlIfExists(file) {
  const [exists] = await file.exists();

  if (!exists) {
    return null;
  }

  const [metadata] = await file.getMetadata();
  const bucketName = metadata.bucket || file.bucket.name;
  const objectName = metadata.name || file.name;
  const tokens = String(
    metadata.metadata?.firebaseStorageDownloadTokens || ""
  )
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);

  if (bucketName && objectName && tokens.length > 0) {
    return buildFirebaseStorageUrl(bucketName, objectName, tokens[0]);
  }

  try {
    const [signedUrl] = await file.getSignedUrl({
      action: "read",
      expires: "2100-01-01"
    });

    return signedUrl;
  } catch (error) {
    logger.error("❌ Could not build public URL for file", {
      file: file.name,
      error: error instanceof Error ? error.message : String(error)
    });
  }

  return null;
}

async function buildPublicPostMedia(articleId, mediaCount, mediaVersion) {
  const bucket = getStorage().bucket();
  const media = [];
  const normalizedCount = Number(mediaCount) > 0 ? Number(mediaCount) : 0;
  const version = Number(mediaVersion) || 1;

  if (normalizedCount > 0) {
    for (let i = 0; i < normalizedCount; i += 1) {
      const imagePath = `images/${articleId}_${i}.jpg`;
      const videoPath = `images/${articleId}_${i}.mp4`;
      const previewPath = `images/${articleId}_${i}_preview.jpg`;

      const imageUrl = await getPublicFileUrlIfExists(bucket.file(imagePath));

      if (imageUrl) {
        media.push({
          type: "image",
          url: imageUrl
        });
        continue;
      }

      const videoUrl = await getPublicFileUrlIfExists(bucket.file(videoPath));

      if (!videoUrl) {
        continue;
      }

      const previewUrl = await getPublicFileUrlIfExists(bucket.file(previewPath));

      media.push({
        type: "video",
        url: videoUrl,
        previewUrl: previewUrl || ""
      });
    }

    return media;
  }

  if (version === 1) {
    const legacyImageUrl = await getPublicFileUrlIfExists(
      bucket.file(`images/${articleId}.jpg`)
    );

    if (legacyImageUrl) {
      return [
        {
          type: "image",
          url: legacyImageUrl
        }
      ];
    }

    const legacyVideoUrl = await getPublicFileUrlIfExists(
      bucket.file(`images/${articleId}.mp4`)
    );

    if (legacyVideoUrl) {
      return [
        {
          type: "video",
          url: legacyVideoUrl,
          previewUrl: ""
        }
      ];
    }
  }

  return media;
}

async function buildPublicPostPreviewUrl(articleId, mediaCount, mediaVersion) {
  const bucket = getStorage().bucket();
  const normalizedCount = Number(mediaCount) > 0 ? Number(mediaCount) : 0;
  const version = Number(mediaVersion) || 1;

  if (normalizedCount > 0) {
    const imageUrl = await getPublicFileUrlIfExists(
      bucket.file(`images/${articleId}_0.jpg`)
    );

    if (imageUrl) {
      return imageUrl;
    }

    return await getPublicFileUrlIfExists(
      bucket.file(`images/${articleId}_0_preview.jpg`)
    ) || "";
  }

  if (version === 1) {
    return await getPublicFileUrlIfExists(
      bucket.file(`images/${articleId}.jpg`)
    ) || "";
  }

  return "";
}

function escapeHtml(value) {
  return String(value || "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function stripMarkdownForSeo(value) {
  return sanitizeGeneratedValue(value)
    .replace(/!\[([^\]]*)\]\(([^)]+)\)/g, " $1 ")
    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, " $1 ")
    .replace(/[`*_>#-]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function truncateText(value, maxLength = 160) {
  const normalized = sanitizeGeneratedValue(value);

  if (!normalized) {
    return "";
  }

  if (normalized.length <= maxLength) {
    return normalized;
  }

  return `${normalized.slice(0, maxLength).trimEnd()}…`;
}

function buildPublicPostCanonicalUrl(postId) {
  return `https://readbox.online/posts/?index=${encodeURIComponent(postId)}`;
}

function buildPublicPostCardUrl(postId) {
  return `https://readbox.online/posts/card.php?index=${encodeURIComponent(postId)}&v=6`;
}

function escapeSvg(value) {
  return escapeHtml(value).replace(/\n/g, " ");
}

function wrapCardTitle(value, maxCharacters, maxLines) {
  const words = stripMarkdownForSeo(value).split(" ").filter(Boolean);
  const lines = [];
  let currentLine = "";

  for (const word of words) {
    const candidate = currentLine ? `${currentLine} ${word}` : word;

    if (candidate.length <= maxCharacters) {
      currentLine = candidate;
      continue;
    }

    if (currentLine) {
      lines.push(currentLine);
    }

    currentLine = word;

    if (lines.length === maxLines) {
      break;
    }
  }

  if (currentLine && lines.length < maxLines) {
    lines.push(currentLine);
  }

  if (words.join(" ").length > lines.join(" ").length && lines.length > 0) {
    lines[lines.length - 1] = `${lines[lines.length - 1].replace(/[.…]+$/, "")}…`;
  }

  return lines;
}

async function imageUrlToDataUri(url) {
  if (!url) {
    return "";
  }

  try {
    const response = await fetch(url);

    if (!response.ok) {
      return "";
    }

    const buffer = Buffer.from(await response.arrayBuffer());
    const image = await sharp(buffer)
      .rotate()
      .jpeg({ quality: 86 })
      .toBuffer();

    return `data:image/jpeg;base64,${image.toString("base64")}`;
  } catch {
    return "";
  }
}

async function imageUrlToCardAsset(url) {
  if (!url) {
    return { dataUri: "", width: 0, height: 0 };
  }

  try {
    const response = await fetch(url);

    if (!response.ok) {
      return { dataUri: "", width: 0, height: 0 };
    }

    const buffer = Buffer.from(await response.arrayBuffer());
    const image = sharp(buffer).rotate();
    const metadata = await image.metadata();
    const normalized = await image
      .jpeg({ quality: 88 })
      .toBuffer();

    return {
      dataUri: `data:image/jpeg;base64,${normalized.toString("base64")}`,
      width: Number(metadata.width || 0),
      height: Number(metadata.height || 0)
    };
  } catch {
    return { dataUri: "", width: 0, height: 0 };
  }
}

function getPublicPostCardDisplayText(post) {
  return stripMarkdownForSeo(post?.title || "");
}

function getPublicPostCardArticleLabel(language) {
  return language === "ru" ? "СТАТЬЯ" : "ARTICLE";
}

function getPublicPostCardExpandLabel(language) {
  return language === "ru" ? "Развернуть ↓" : "Expand ↓";
}

function getPublicPostCardRussianPlural(value, one, few, many) {
  const mod100 = value % 100;
  const mod10 = value % 10;

  if (mod100 >= 11 && mod100 <= 14) {
    return many;
  }

  if (mod10 === 1) {
    return one;
  }

  if (mod10 >= 2 && mod10 <= 4) {
    return few;
  }

  return many;
}

function formatPublicPostCardDate(value, language) {
  if (!value) {
    return "";
  }

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {
    return "";
  }

  const seconds = Math.max(0, Math.floor((Date.now() - date.getTime()) / 1000));

  if (seconds < 3600) {
    const minutes = Math.max(1, Math.floor(seconds / 60));
    return language === "ru"
      ? `${minutes} ${getPublicPostCardRussianPlural(minutes, "минуту", "минуты", "минут")} назад`
      : `${minutes} minute${minutes === 1 ? "" : "s"} ago`;
  }

  if (seconds < 86400) {
    const hours = Math.floor(seconds / 3600);
    return language === "ru"
      ? `${hours} ${getPublicPostCardRussianPlural(hours, "час", "часа", "часов")} назад`
      : `${hours} hour${hours === 1 ? "" : "s"} ago`;
  }

  if (seconds < 31 * 86400) {
    const days = Math.floor(seconds / 86400);
    return language === "ru"
      ? `${days} ${getPublicPostCardRussianPlural(days, "день", "дня", "дней")} назад`
      : `${days} day${days === 1 ? "" : "s"} ago`;
  }

  return new Intl.DateTimeFormat(language === "ru" ? "ru-RU" : "en-US", {
    day: "numeric",
    month: "short",
    year: date.getFullYear() === new Date().getFullYear() ? undefined : "2-digit"
  }).format(date);
}

function buildPublicPostCardTextTspans(lines, x, y, lineHeight) {
  return lines.map((line, index) => (
    `<tspan x="${x}" y="${y + index * lineHeight}">${escapeSvg(line)}</tspan>`
  )).join("");
}

function buildPublicPostCardMediaImage(asset, x, y, width, height) {
  if (!asset?.dataUri) {
    return "";
  }

  return [
    `<rect x="${x}" y="${y}" width="${width}" height="${height}" rx="34" fill="#ececef"/>`,
    `<image href="${asset.dataUri}" x="${x}" y="${y}" width="${width}" height="${height}" preserveAspectRatio="xMidYMid slice" clip-path="url(#mediaClip)"/>`
  ].join("\n  ");
}

async function buildPublicPostCardSvg(post) {
  const firstMedia = post.media?.[0];
  const mediaUrl = firstMedia?.type === "video"
    ? firstMedia.previewUrl
    : firstMedia?.url;
  const [avatarDataUri, mediaAsset] = await Promise.all([
    imageUrlToDataUri(post.avatarUrl),
    imageUrlToCardAsset(mediaUrl)
  ]);

  const hasMedia = !!mediaAsset.dataUri;
  const cardText = getPublicPostCardDisplayText(post);
  const isShortPost = post.isShortPost === true;
  const authorName = escapeSvg(truncateText(post.authorName || "ReadBox author", 28));
  const language = normalizeLanguage(post.originalLanguage || "en");
  const date = formatPublicPostCardDate(post.dateCreated, language);
  const mediaPosition = Number(post.mediaPosition || 0);

  const cardW = 920;
  const cardH = 560;
  const cardX = (1200 - cardW) / 2;
  const cardY = 36;
  const innerX = cardX + 40;
  const innerW = cardW - 80;
  const cardBottom = cardY + cardH;
  const textFontSize = 38;
  const textLineHeight = 46;
  const headerY = cardY + 38;
  const headerBottom = cardY + 138;

  let textY = 0;
  let mediaY = 0;
  let mediaH = 0;
  let maxTextLines = hasMedia ? 2 : 5;

  if (hasMedia) {
    if (mediaPosition === 1) {
      textY = headerBottom + 42;
      maxTextLines = 2;
      mediaY = cardText ? textY + textLineHeight * maxTextLines + 28 : headerBottom + 18;
      mediaH = Math.max(220, cardBottom - mediaY - 38);
    } else {
      mediaY = headerBottom + 18;
      mediaH = cardText ? 310 : cardBottom - mediaY - 38;
      textY = mediaY + mediaH + 44;
      maxTextLines = isShortPost ? 1 : 2;
    }
  } else {
    textY = headerBottom + 42;
    maxTextLines = isShortPost ? 4 : 5;
  }

  const textLines = cardText
    ? wrapCardTitle(cardText, 43, maxTextLines)
    : [];
  const isTextTrimmed = cardText && stripMarkdownForSeo(cardText).length > textLines.join(" ").length;
  const textTspans = buildPublicPostCardTextTspans(textLines, innerX, textY, textLineHeight);
  const mediaImage = hasMedia
    ? buildPublicPostCardMediaImage(mediaAsset, innerX, mediaY, innerW, mediaH)
    : "";
  const mediaCounter = Array.isArray(post.media) && post.media.length > 1
    ? `<rect x="${innerX + innerW - 92}" y="${mediaY + 14}" width="70" height="36" rx="18" fill="#111111" fill-opacity="0.72"/><text x="${innerX + innerW - 57}" y="${mediaY + 39}" text-anchor="middle" fill="#ffffff" font-family="Arial, Helvetica, sans-serif" font-size="19" font-weight="500">1 / ${post.media.length}</text>`
    : "";
  const videoIcon = hasMedia && firstMedia?.type === "video"
    ? `<circle cx="${innerX + innerW / 2}" cy="${mediaY + mediaH / 2}" r="42" fill="#000000" fill-opacity="0.55"/><path d="M${innerX + innerW / 2 - 11} ${mediaY + mediaH / 2 - 22} L${innerX + innerW / 2 + 23} ${mediaY + mediaH / 2} L${innerX + innerW / 2 - 11} ${mediaY + mediaH / 2 + 22} Z" fill="#ffffff"/>`
    : "";
  const expandLabel = isTextTrimmed
    ? `<text x="${innerX + innerW - 8}" y="${cardBottom - 24}" text-anchor="end" fill="#8a8a8a" font-family="Arial, Helvetica, sans-serif" font-size="28">${escapeSvg(getPublicPostCardExpandLabel(language))}</text>`
    : "";
  const articleBadge = !isShortPost
    ? `<rect x="${cardX + cardW - 178}" y="${headerY + 16}" width="122" height="46" rx="11" fill="#c7c7cc"/><text x="${cardX + cardW - 117}" y="${headerY + 48}" text-anchor="middle" fill="#f2f2f7" font-family="Arial, Helvetica, sans-serif" font-size="22">${escapeSvg(getPublicPostCardArticleLabel(language))}</text>`
    : "";
  const resolvedAuthorTextX = avatarDataUri ? innerX + 96 : innerX;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630">
  <defs>
    <linearGradient id="pageBackground" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#f2f2f7"/>
      <stop offset="0.45" stop-color="#f5f5f5"/>
      <stop offset="0.75" stop-color="#ffffff"/>
      <stop offset="1" stop-color="#f2f2f7"/>
    </linearGradient>
    <filter id="cardShadow" x="-10%" y="-10%" width="120%" height="130%">
      <feDropShadow dx="0" dy="14" stdDeviation="14" flood-color="#000000" flood-opacity="0.10"/>
    </filter>
    <clipPath id="avatarClip"><circle cx="${innerX + 40}" cy="${headerY + 40}" r="40"/></clipPath>
    <clipPath id="mediaClip"><rect x="${innerX}" y="${mediaY}" width="${innerW}" height="${mediaH}" rx="34"/></clipPath>
  </defs>

  <rect width="1200" height="630" fill="url(#pageBackground)"/>

  <rect x="${cardX}" y="${cardY}" width="${cardW}" height="${cardH}" rx="50" fill="#f9f9fa" stroke="#ececef" stroke-width="6" filter="url(#cardShadow)"/>

  ${avatarDataUri
    ? `<image href="${avatarDataUri}" x="${innerX}" y="${headerY}" width="80" height="80" preserveAspectRatio="xMidYMid slice" clip-path="url(#avatarClip)"/>`
    : ""}

  <text x="${resolvedAuthorTextX}" y="${headerY + 34}" fill="#161616" font-family="Arial, Helvetica, sans-serif" font-size="32" font-weight="600">${authorName}</text>
  <text x="${resolvedAuthorTextX}" y="${headerY + 68}" fill="#777777" font-family="Arial, Helvetica, sans-serif" font-size="22">${escapeSvg(date)}</text>
  ${articleBadge}

  ${mediaImage}
  ${mediaCounter}
  ${videoIcon}

  <text fill="#171717" font-family="Arial, Helvetica, sans-serif" font-size="${textFontSize}" font-weight="400">${textTspans}</text>
  ${expandLabel}
</svg>`;
}

function buildPublicPostDescription(post) {
  const title = sanitizeGeneratedValue(post?.title);
  const text = stripMarkdownForSeo(post?.text);
  const source = firstNonEmptyString(text, title, "ReadBox");
  return truncateText(source, 170);
}

function buildPublicPostSeoHeadline(post) {
  if (post?.isShortPost) {
    return sanitizeGeneratedValue(post?.authorName) || "ReadBox";
  }

  const rawTitle = stripMarkdownForSeo(post?.title);

  if (!rawTitle) {
    return "ReadBox";
  }

  return truncateText(rawTitle, 160);
}

function buildPublicPostTitle(post) {
  const seoHeadline = buildPublicPostSeoHeadline(post);
  return seoHeadline ? `${seoHeadline} | ReadBox` : "ReadBox";
}

function formatPostDateForJsonLd(value) {
  const normalized = sanitizeGeneratedValue(value);
  return normalized || new Date().toISOString();
}

function renderPublicPostContentHtml(text) {
  const escaped = escapeHtml(text || "").replace(/\r\n/g, "\n");

  if (!escaped.trim()) {
    return "";
  }

  const html = escaped
    .replace(/!\[([^\]]*)\]\((https?:\/\/[^\s)]+)\)/g, '<figure><img src="$2" alt="$1"></figure>')
    .replace(/\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)/g, '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>')
    .replace(/^(#{1,6})\s+(.*?)\s*#*\s*$/gm, (_, hashes, content) => {
      const level = Math.min(hashes.length, 3);
      return `<h${level}>${content}</h${level}>`;
    })
    .replace(/\*\*([\s\S]+?)\*\*/g, "<strong>$1</strong>")
    .replace(/\*(.+?)\*/g, "<em>$1</em>")
    .replace(/`([^`]+)`/g, "<code>$1</code>");

  return html
    .split(/\n{2,}/)
    .map((block) => {
      const trimmed = block.trim();

      if (!trimmed) {
        return "";
      }

      if (/^<h[1-3]>/.test(trimmed) || /^<figure>/.test(trimmed)) {
        return trimmed;
      }

      if (/^(- |\* )/m.test(trimmed)) {
        const items = trimmed
          .split("\n")
          .filter((line) => /^(- |\* )/.test(line))
          .map((line) => `<li>${line.replace(/^(- |\* )/, "")}</li>`)
          .join("");

        return `<ul>${items}</ul>`;
      }

      return `<p>${trimmed.replace(/\n/g, "<br>")}</p>`;
    })
    .join("\n");
}

function renderPublicPostMediaSectionHtml(media) {
  if (!Array.isArray(media) || media.length === 0) {
    return "";
  }

  if (media.length === 1) {
    const item = media[0];

    if (item?.type === "video") {
      return `<section class="hero-media"><div class="single-media"><video src="${escapeHtml(item.url)}" controls playsinline preload="metadata"${item.previewUrl ? ` poster="${escapeHtml(item.previewUrl)}"` : ""}></video></div></section>`;
    }

    return `<section class="hero-media"><div class="single-media"><img src="${escapeHtml(item?.url || "")}" alt="ReadBox media"></div></section>`;
  }

  const slides = media.map((item) => {
    if (item?.type === "video") {
      return `<div class="media-slide"><video src="${escapeHtml(item.url)}" controls playsinline preload="metadata"${item.previewUrl ? ` poster="${escapeHtml(item.previewUrl)}"` : ""}></video></div>`;
    }

    return `<div class="media-slide"><img src="${escapeHtml(item?.url || "")}" alt="ReadBox media"></div>`;
  }).join("");

  return `<section class="hero-media"><div class="media-carousel"><div class="media-track">${slides}</div><div class="media-counter">1 / ${media.length}</div></div></section>`;
}

function buildPublicPostJsonLd(post, canonicalUrl, imageUrl) {
  const seoHeadline = buildPublicPostSeoHeadline(post);
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": post.isShortPost ? "Article" : "NewsArticle",
    headline: seoHeadline || "ReadBox",
    datePublished: formatPostDateForJsonLd(post.dateCreated),
    dateModified: formatPostDateForJsonLd(post.dateCreated),
    mainEntityOfPage: canonicalUrl,
    author: {
      "@type": "Person",
      name: sanitizeGeneratedValue(post.authorName) || "ReadBox author",
      url: `https://readbox.online/authors/?index=${encodeURIComponent(post.authorId || "")}`
    },
    publisher: {
      "@type": "Organization",
      name: "ReadBox",
      logo: {
        "@type": "ImageObject",
        url: "https://readbox.online/images/readbox_logo.png"
      }
    }
  };

  if (imageUrl) {
    jsonLd.image = [imageUrl];
  }

  return JSON.stringify(jsonLd);
}

function buildRenderedPublicPostHtml(post) {
  const canonicalUrl = buildPublicPostCanonicalUrl(post.id);
  const description = buildPublicPostDescription(post);
  const title = buildPublicPostTitle(post);
  const seoHeadline = buildPublicPostSeoHeadline(post);
  const contentImageUrl = post.media?.find((item) => item?.type === "image")?.url
    || post.media?.find((item) => item?.type === "video" && item?.previewUrl)?.previewUrl
    || "https://readbox.online/images/readbox_logo.png";
  const socialImageUrl = buildPublicPostCardUrl(post.id);
  const contentHtml = renderPublicPostContentHtml(post.text);
  const jsonLd = buildPublicPostJsonLd(post, canonicalUrl, contentImageUrl);
  const authorName = escapeHtml(post.authorName || "ReadBox author");
  const postTitle = escapeHtml(post.title || "ReadBox");
  const postLanguage = normalizeLanguage(post.originalLanguage || "en");
  const publishedDate = escapeHtml(post.dateCreated
    ? new Date(post.dateCreated).toLocaleDateString(postLanguage === "ru" ? "ru-RU" : "en-US", {
      year: "numeric",
      month: "long",
      day: "numeric"
    })
    : "");
  const isShortPost = post.isShortPost === true;
  const postClass = isShortPost ? "post is-post" : "post is-article";
  const postTypeLabel = isShortPost ? "POST" : "ARTICLE";
  const mediaHtml = renderPublicPostMediaSectionHtml(post.media || []);
  const checkmarkHtml = post.isCheckmark
    ? '<img class="checkmark" src="https://readbox.online/images/checkmark.webp" alt="Verified">'
    : "";
  const avatarHtml = post.avatarUrl
    ? `<img class="author-avatar-image" src="${escapeHtml(post.avatarUrl)}" alt="${authorName}">`
    : escapeHtml((post.authorName || "R").trim().charAt(0).toUpperCase() || "R");
  const openInAppLabel = postLanguage === "ru" ? "Читать в приложении" : "Read in the app";
  const appStoreUrl = "https://apps.apple.com/ru/app/readbox-%D1%81%D1%82%D0%B0%D1%82%D1%8C%D0%B8-%D0%B8-%D0%B8-%D0%B8%D1%81%D1%82%D0%BE%D1%80%D0%B8%D0%B8/id6745975985";

  let headerInnerHtml = `
                <div class="author-row">
                    <div class="author-avatar">${avatarHtml}</div>

                    <div class="author-meta">
                        <div class="author-name-row">
                            <span class="author-name">${authorName}</span>
                            ${checkmarkHtml}
                        </div>

                        <div class="meta-row">
                            <span class="meta-badge">${postTypeLabel}</span>
                            <span class="meta-date">${publishedDate}</span>
                        </div>
                    </div>
                </div>
            `;

  let contentBeforeFooter = "";

  if (isShortPost && Number(post.mediaPosition || 0) === 0) {
    headerInnerHtml += `${mediaHtml}
                <h1 class="post-title">${postTitle}</h1>`;
    contentBeforeFooter = `<section class="post-content">${contentHtml}</section>`;
  } else if (Number(post.mediaPosition || 0) === 1) {
    headerInnerHtml += `<h1 class="post-title">${postTitle}</h1>`;
    contentBeforeFooter = `<section class="post-content">${contentHtml}</section>${mediaHtml}`;
  } else {
    headerInnerHtml += `<h1 class="post-title">${postTitle}</h1>`;
    contentBeforeFooter = `${mediaHtml}<section class="post-content">${contentHtml}</section>`;
  }

  return `<!DOCTYPE html>
<html lang="${escapeHtml(postLanguage)}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${escapeHtml(title)}</title>
  <meta name="description" content="${escapeHtml(description)}">
  <meta name="color-scheme" content="light dark">
  <meta name="theme-color" content="#ffffff" media="(prefers-color-scheme: light)">
  <meta name="theme-color" content="#111111" media="(prefers-color-scheme: dark)">
  <link rel="icon" href="https://readbox.online/images/favicon.ico?v=3" sizes="any">
  <link rel="icon" type="image/svg+xml" href="https://readbox.online/images/favicon.svg?v=3">
  <link rel="icon" type="image/png" sizes="96x96" href="https://readbox.online/images/favicon-96x96.png?v=3">
  <link rel="apple-touch-icon" sizes="180x180" href="https://readbox.online/images/apple-touch-icon.png?v=3">
  <link rel="manifest" href="https://readbox.online/images/site.webmanifest?v=3">
  <link rel="stylesheet" href="https://readbox.online/posts/post.css?v=34">
  <link rel="canonical" href="${escapeHtml(canonicalUrl)}">
  <meta property="og:type" content="article">
  <meta property="og:site_name" content="ReadBox">
  <meta property="og:title" content="${escapeHtml(seoHeadline || "ReadBox")}">
  <meta property="og:description" content="${escapeHtml(description)}">
  <meta property="og:url" content="${escapeHtml(canonicalUrl)}">
  <meta property="og:image" content="${escapeHtml(socialImageUrl)}">
  <meta property="og:image:secure_url" content="${escapeHtml(socialImageUrl)}">
  <meta property="og:image:type" content="image/png">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta property="og:image:alt" content="${escapeHtml(seoHeadline || "ReadBox")}">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${escapeHtml(seoHeadline || "ReadBox")}">
  <meta name="twitter:description" content="${escapeHtml(description)}">
  <meta name="twitter:image" content="${escapeHtml(socialImageUrl)}">
  <script type="application/ld+json">${jsonLd}</script>
</head>
<body>
  <main class="page">
    <a class="brand" href="https://readbox.online/">
      <img src="https://readbox.online/images/readbox_logo.png" alt="ReadBox" class="brand-logo">
      <span class="brand-name">ReadBox</span>
    </a>

    <article class="${postClass}">
      <header class="post-header">
${headerInnerHtml}
      </header>

      ${contentBeforeFooter}

      <footer class="post-footer">
        <a class="app-button" href="${escapeHtml(appStoreUrl)}" target="_blank" rel="noopener noreferrer">${escapeHtml(openInAppLabel)}</a>
      </footer>
    </article>
  </main>
</body>
</html>`;
}

async function loadPublicPostData(index) {
  const articleRef = db.collection("articles").doc(index);
  const articleSnap = await articleRef.get();

  if (!articleSnap.exists) {
    return { statusCode: 404, error: "post-not-found", post: null };
  }

  const article = articleSnap.data() || {};

  if (article.is_archive === true || article.is_draft === true) {
    return { statusCode: 404, error: "post-not-found", post: null };
  }

  if (article.is_premium_post === true) {
    return { statusCode: 403, error: "premium-post", post: null };
  }

  const authorId = typeof article.author_id === "string" ? article.author_id : "";
  let authorName = "ReadBox author";
  let isCheckmark = false;
  let avatarUrl = "";

  if (authorId) {
    const userSnap = await db.collection("users").doc(authorId).get();

    if (userSnap.exists) {
      const userData = userSnap.data() || {};
      authorName = typeof userData.name === "string" && userData.name.trim()
        ? userData.name.trim()
        : authorName;
      isCheckmark = !!userData.is_checkmark;
    }

    avatarUrl = await getPublicFileUrlIfExists(
      getStorage().bucket().file(`avatars/${authorId}.jpg`)
    ) || "";
  }

  const mediaURLs = Array.isArray(article.media_URLs)
    ? article.media_URLs.filter((item) => typeof item === "string" && item.trim())
    : [];
  const media = await buildPublicPostMedia(index, article.media_count, article.media_version);
  const dateCreated = article.date_created?.toDate
    ? article.date_created.toDate().toISOString()
    : null;

  return {
    statusCode: 200,
    error: null,
    post: {
      id: index,
      title: typeof article.title === "string" ? article.title : "",
      text: typeof article.text === "string" ? article.text : "",
      authorId,
      authorName,
      avatarUrl,
      isCheckmark,
      isShortPost: !!article.is_short_post,
      mediaPosition: Number(article.media_position || 0),
      likesCount: Number(article.likes_count || 0),
      viewsCount: Number(article.views_count || 0),
      dateCreated,
      mediaURLs,
      media,
      originalLanguage: normalizeLanguage(article.original_language)
    }
  };
}

/* ─────────────── helper: рассылаем пуш подписчикам ─────────────── */
async function pushToSubscribers({
  authorUid,
  authorName,
  articleId,
  title,
  isPremiumPost,
  mediaCount,
  mediaVersion
}) {
  // ищем пользователей, у которых автор в subscribes
  const usersSnap = await db.collection("users")
    .where("subscribes", "array-contains", authorUid)
    .get();

  if (usersSnap.empty) {
    logger.info("📭 Подписчиков нет");
    return;
  }

  const languageByToken = new Map();

  usersSnap.forEach((doc) => {
    const language = getUserOriginalLanguage(doc.data());
    const tokens = collectTokensFromUserDoc(doc);

    tokens.forEach((token) => {
      const currentLanguage = languageByToken.get(token);

      if (!currentLanguage || currentLanguage !== "ru") {
        languageByToken.set(token, language);
      }
    });
  });

  const tokensByLanguage = {
    ru: new Set(),
    en: new Set()
  };

  languageByToken.forEach((language, token) => {
    tokensByLanguage[language].add(token);
  });

  const totalTokens =
    tokensByLanguage.ru.size +
    tokensByLanguage.en.size;

  logger.info(
    `🌐 Push language split for ${articleId}: ru=${tokensByLanguage.ru.size}, en=${tokensByLanguage.en.size}`
  );

  if (!totalTokens) {
    logger.info("🔇 У подписчиков нет FCM-токенов");
    return;
  }

  // эмодзи по первому медиа
  const emoji = await detectFirstMediaEmoji(articleId, mediaCount, mediaVersion);

  let totalSuccessCount = 0;

  for (const language of ["ru", "en"]) {
    const tokens = [...tokensByLanguage[language]];

    if (!tokens.length) {
      continue;
    }

    const body = isPremiumPost
      ? getPremiumPublicationBody(language)
      : `${emoji}${title ?? ""}`;

    const msg = {
      tokens,
      notification: {
        title: authorName,
        body
      },
      data: {
        type: "new_post",
        route: "article",
        articleId,
        authorId: authorUid
      }
    };

    const rsp = await getMessaging().sendEachForMulticast(msg);
    totalSuccessCount += rsp.successCount;

    logger.info(
      `✅ Pushed new article ${articleId} [${language}]: ${rsp.successCount}/${tokens.length} success`
    );
  }

  logger.info(
    `✅ Total pushed new article ${articleId}: ${totalSuccessCount}/${totalTokens} success`
  );
}

const RECENT_POST_PUSH_LOOKBACK_HOURS = 48;
const RECENT_POST_PUSH_FETCH_LIMIT = 120;
const RECENT_POST_PUSH_HISTORY_TTL_DAYS = 14;

function getFallbackRecentPostTitle(language) {
  return language === "ru"
    ? "Новое в ReadBox"
    : "New on ReadBox";
}

function getRecentPostPushHeading(language, isShortPost) {
  if (language === "ru") {
    return isShortPost
      ? "Свежий пост в ReadBox"
      : "Новая статья в ReadBox";
  }

  return isShortPost
    ? "Fresh post on ReadBox"
    : "New article on ReadBox";
}

function buildRecentPostPushNotification({
  language,
  isShortPost,
  authorName,
  title,
  emoji,
  style = "editorial"
}) {
  const normalizedAuthorName = sanitizeGeneratedValue(authorName) || "ReadBox";
  const normalizedTitle = shortenPushText(
    firstNonEmptyString(title, getFallbackRecentPostTitle(language)),
    90
  );
  const normalizedEmoji = sanitizeGeneratedValue(emoji);

  if (style === "classic") {
    return {
      title: normalizedAuthorName,
      body: shortenPushText(`${normalizedEmoji}${normalizedTitle}`.trim(), 120)
    };
  }

  return {
    title: getRecentPostPushHeading(language, isShortPost),
    body: shortenPushText(
      `${normalizedAuthorName} · ${normalizedEmoji}${normalizedTitle}`.trim(),
      120
    )
  };
}

function shortenPushText(value, maxLength = 90) {
  const normalized = sanitizeGeneratedValue(value);

  if (!normalized) {
    return "";
  }

  if (normalized.length <= maxLength) {
    return normalized;
  }

  return `${normalized.slice(0, maxLength).trimEnd()}…`;
}

function getDateMillis(value) {
  if (!value) {
    return 0;
  }

  if (typeof value.toMillis === "function") {
    return value.toMillis();
  }

  if (typeof value.toDate === "function") {
    return value.toDate().getTime();
  }

  if (value instanceof Date) {
    return value.getTime();
  }

  const parsed = new Date(value).getTime();
  return Number.isFinite(parsed) ? parsed : 0;
}

function scoreRecentPostForPush(article) {
  const createdAtMs = getDateMillis(article.date_created);
  const ageHours = createdAtMs > 0
    ? (Date.now() - createdAtMs) / (1000 * 60 * 60)
    : 999;

  const likes = Number(article.likes_count || 0);
  const views = Number(article.views_count || 0);
  const mediaCount = Number(article.media_count || 0);
  const isShortPost = article.is_short_post === true;

  let score = 0;

  score += Math.max(0, 80 - ageHours);
  score += likes * 8;
  score += Math.min(views, 500) * 0.25;
  score += mediaCount > 0 ? 18 : 0;
  score += isShortPost ? 6 : 0;

  return score;
}

async function wasRecentPostPushSent(articleId, language) {
  const campaignId = articleId;
  const campaignSnap = await db.collection("push_campaigns").doc(campaignId).get();
  return campaignSnap.exists;
}

async function markRecentPostPushSent({
  articleId,
  language,
  title,
  authorId
}) {
  const campaignId = articleId;
  const expiresAt = new Date(Date.now() + RECENT_POST_PUSH_HISTORY_TTL_DAYS * 24 * 60 * 60 * 1000);

  await db.collection("push_campaigns").doc(campaignId).set({
    language,
    author_id: sanitizeGeneratedValue(authorId),
    title: shortenPushText(title, 120),
    sent_at: FieldValue.serverTimestamp(),
    expires_at: expiresAt
  });
}

async function pickRecentPostPushCandidate(language) {
  const snapshot = await db.collection("articles")
    .orderBy("date_created", "desc")
    .limit(RECENT_POST_PUSH_FETCH_LIMIT)
    .get();

  if (snapshot.empty) {
    return null;
  }

  const lookbackMs = RECENT_POST_PUSH_LOOKBACK_HOURS * 60 * 60 * 1000;
  const minCreatedAt = Date.now() - lookbackMs;

  let bestCandidate = null;
  let bestScore = -Infinity;

  for (const doc of snapshot.docs) {
    const article = doc.data() || {};
    const articleLanguage = normalizeLanguage(article.original_language);
    const createdAtMs = getDateMillis(article.date_created);

    if (articleLanguage !== language) {
      continue;
    }

    if (article.is_draft === true || article.is_archive === true || article.is_premium_post === true) {
      continue;
    }

    if (!createdAtMs || createdAtMs < minCreatedAt) {
      continue;
    }

    const articleId = sanitizeGeneratedValue(doc.id);
    if (!articleId) {
      continue;
    }

    if (await wasRecentPostPushSent(articleId, language)) {
      continue;
    }

    const score = scoreRecentPostForPush(article);

    if (score > bestScore) {
      bestScore = score;
      bestCandidate = {
        id: articleId,
        data: article,
        score
      };
    }
  }

  return bestCandidate;
}

async function sendRecentPostTopicPush(language, options = {}) {
  const style = options.style === "classic" ? "classic" : "editorial";
  const candidate = await pickRecentPostPushCandidate(language);

  if (!candidate) {
    logger.info(`📭 No recent post push candidate for [${language}]`);
    return;
  }

  const article = candidate.data;
  const articleId = candidate.id;
  const authorUid = sanitizeGeneratedValue(article.author_id);

  let authorName = "ReadBox";
  if (authorUid) {
    try {
      const authorDoc = await db.collection("users").doc(authorUid).get();
      if (authorDoc.exists) {
        authorName = sanitizeGeneratedValue(authorDoc.data()?.name) || authorName;
      }
    } catch (error) {
      logger.error(`❌ Failed to read author ${authorUid} for recent post push`, error);
    }
  }

  const title = shortenPushText(
    firstNonEmptyString(article.title, getFallbackRecentPostTitle(language)),
    90
  );
  const isShortPost = article.is_short_post === true;
  const emoji = await detectFirstMediaEmoji(
    articleId,
    Number(article.media_count || 0),
    Number(article.media_version || 0)
  );
  const notification = buildRecentPostPushNotification({
    language,
    isShortPost,
    authorName,
    title,
    emoji,
    style
  });

  const response = await getMessaging().send({
    topic: language,
    notification,
    data: {
      type: "new_post",
      route: "article",
      articleId,
      authorId: authorUid,
      push_style: style
    }
  });

  await markRecentPostPushSent({
    articleId,
    language,
    title,
    authorId: authorUid
  });

  logger.info(
    `🚀 Sent recent post topic push [${language}] style=${style} article=${articleId} score=${candidate.score} response=${response}`
  );
}

export const sendRecentPostsTopicPushesRu = onSchedule(
  {
    schedule: "0 11,16,21 * * *",
    timeZone: "Europe/Samara"
  },
  async () => {
    await sendRecentPostTopicPush("ru");
  }
);

export const sendRecentPostsTopicPushesClassicRu = onSchedule(
  {
    schedule: "0 14 * * *",
    timeZone: "Europe/Samara"
  },
  async () => {
    await sendRecentPostTopicPush("ru", { style: "classic" });
  }
);

export const sendRecentPostsTopicPushesEn = onSchedule(
  {
    schedule: "0 18,23,4 * * *",
    timeZone: "Europe/Samara"
  },
  async () => {
    await sendRecentPostTopicPush("en");
  }
);

export const sendRecentPostsTopicPushesClassicEn = onSchedule(
  {
    schedule: "0 21 * * *",
    timeZone: "Europe/Samara"
  },
  async () => {
    await sendRecentPostTopicPush("en", { style: "classic" });
  }
);

export const sendRecentPostsTopicPushesNow = onRequest(
  {
    cors: true
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "method-not-allowed" });
      return;
    }

    try {
      const requestedLanguage = normalizeLanguage(req.query.lang || req.body?.lang || "all");
      const requestedStyle = String(req.query.style || req.body?.style || "editorial")
        .trim()
        .toLowerCase();
      const style = requestedStyle === "classic" ? "classic" : "editorial";
      const shouldSendAll = ["all", ""].includes(
        String(req.query.lang || req.body?.lang || "all").trim().toLowerCase()
      );

      if (shouldSendAll) {
        await sendRecentPostTopicPush("ru", { style });
        await sendRecentPostTopicPush("en", { style });

        res.status(200).json({
          ok: true,
          languages: ["ru", "en"],
          style
        });
        return;
      }

      await sendRecentPostTopicPush(requestedLanguage, { style });

      res.status(200).json({
        ok: true,
        language: requestedLanguage,
        style
      });
    } catch (error) {
      logger.error("❌ sendRecentPostsTopicPushesNow failed", error);

      res.status(500).json({
        error: error instanceof Error ? error.message : "unknown-error"
      });
    }
  }
);

/* ───────────── функция: новая статья ───────────── */
export const notifyNewPost = onDocumentCreated(
  "articles/{articleId}",
  async (event) => {
    const snap = event.data;
    if (!snap || !snap.exists) {
      logger.warn("notifyNewPost: empty snapshot");
      return;
    }

    const articleId = event.params.articleId;
    const data = snap.data();

    if (!data) {
      logger.warn(`notifyNewPost: no data for ${articleId}`);
      return;
    }

    // не шлём пуши по черновикам / архиву
    if (data.is_draft || data.is_archive) {
      logger.info(`notifyNewPost: ${articleId} is draft/archive, skip`);
      return;
    }

    const authorUid = data.author_id;
    if (!authorUid) {
      logger.warn(`notifyNewPost: no author_uid for ${articleId}`);
      return;
    }

    const userDoc = await db.collection("users").doc(authorUid).get();
    const user = userDoc.data() || {};
    const authorName = user.name || "ReadBox";

    const title =
      data.title ||
      "ReadBox";
    const isPremiumPost = data.is_premium_post === true;

    const mediaCount = data.media_count ?? 0;
    const mediaVersion = data.media_version ?? 1;

    await pushToSubscribers({
      authorUid,
      authorName,
      articleId,
      title,
      isPremiumPost,
      mediaCount,
      mediaVersion
    });
  }
);

/* ───── функция: статья восстановлена из архива ───── */
export const notifyUnarchivedPost = onDocumentUpdated(
  "articles/{articleId}",
  async (event) => {
    const before = event.data.before.data();
    const after  = event.data.after.data();
    const articleId = event.params.articleId;

    if (!before || !after) {
      logger.warn(`notifyUnarchivedPost: no data for ${articleId}`);
      return;
    }

    // интересует только переход из archive -> не archive
    if (before.is_archive === true && after.is_archive === false && !after.is_draft) {
      const authorUid = after.author_id;
      if (!authorUid) {
        logger.warn(`notifyUnarchivedPost: no author_uid for ${articleId}`);
        return;
      }

      const userDoc = await db.collection("users").doc(authorUid).get();
      const user = userDoc.data() || {};
      const authorName = user.name || "ReadBox";

      const title =
        after.title ||
        "ReadBox";
      const isPremiumPost = after.is_premium_post === true;

      const mediaCount = after.media_count ?? 0;
      const mediaVersion = after.media_version ?? 1;

      await pushToSubscribers({
        authorUid,
        authorName,
        articleId,
        title,
        isPremiumPost,
        mediaCount,
        mediaVersion
      });
    }
  }
);

/* ─────────── функция: уведомление автору о новом лайке ─────────── */

export const notifyPostLiked = onDocumentUpdated(
  "users/{userId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after  = event.data?.after?.data();
    if (!before || !after) return;

    // пользователь, который лайкает
    const likerId = event.params.userId;
    const beforeLiked = normalizeLikedPosts(before.liked_posts);
    const afterLiked  = normalizeLikedPosts(after.liked_posts);

    // новые лайки: есть в after, не было в before
    const newlyLiked = afterLiked.filter(
      (id) => !beforeLiked.includes(id)
    );

    if (!newlyLiked.length) {
      return;
    }

    // имя лайкнувшего
    let likerName = "User";
    try {
      const likerDoc = await db.collection("users").doc(likerId).get();
      if (likerDoc.exists) {
        const d = likerDoc.data();
        if (d?.name) likerName = d.name.trim() || likerName;
      }
    } catch (e) {
      logger.error("❌ Error reading liker:", e);
    }

    // для каждого нового лайка шлём пуш автору поста
    for (const articleId of newlyLiked) {
      try {
        const articleSnap = await db.collection("articles").doc(articleId).get();
        if (!articleSnap.exists) continue;

        const article = articleSnap.data();
        const authorUid = article.author_id;
        if (!authorUid) continue;

        // не шлём пуш, если человек лайкнул сам себя
        if (authorUid === likerId) continue;

        await createInAppNotification({
          userId: authorUid,
          type: "post_liked",
          actorId: likerId,
          postId: articleId
        });

        // достаём автора поста
        const authorDoc = await db.collection("users").doc(authorUid).get();
        if (!authorDoc.exists) continue;

        const tokens = collectTokensFromUserDoc(authorDoc);
        if (!tokens.length) {
          logger.info(`🔇 No tokens for author ${authorUid} when liking article ${articleId}`);
          continue;
        }

        const language = getUserOriginalLanguage(authorDoc.data());

        const rawTitle = (article.title || "").trim();
        const maxLen = 40;
        let shortTitle = rawTitle;
        if (shortTitle.length > maxLen) {
          shortTitle = shortTitle.slice(0, maxLen).trimEnd() + "…";
        }

        const isShortPost = !!article.is_short_post;
        const body = getLikedArticleBody(language, isShortPost, shortTitle);

        const rsp = await getMessaging().sendEachForMulticast({
          tokens,
          notification: {
            title: likerName,   // 👈 в заголовке имя лайкнувшего
            body
          },
          data: {
            type: "post_liked",
            route: "channel",
            articleId,
            likerId,
            channelId: likerId
          },
          apns: {
            payload: {
              aps: {
                "mutable-content": 1
              }
            }
          }
        });

        logger.info(
          `👍 Like: article ${articleId}, author ${authorUid}, language ${language}, liked by ${likerId}, sent ${rsp.successCount}/${tokens.length}`
        );

      } catch (e) {
        logger.error("❌ Error while handling like:", e);
      }
    }
  }
);

/* ─────────── функция: уведомление автору о новом подписчике ─────────── */

export const notifyUserSubscribed = onDocumentUpdated(
  "users/{userId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after  = event.data?.after?.data();
    if (!before || !after) return;

    const subscriberId = event.params.userId;

    const beforeSubs = normalizeSubscribes(before.subscribes);
    const afterSubs  = normalizeSubscribes(after.subscribes);

    // новые подписки: авторы, появившиеся в subscribes
    const newlySubscribedAuthors = afterSubs.filter(
      (id) => !beforeSubs.includes(id)
    );

    if (!newlySubscribedAuthors.length) {
      return;
    }

    // имя подписчика
    let subscriberName = "User";
    try {
      const subDoc = await db.collection("users").doc(subscriberId).get();
      if (subDoc.exists) {
        const d = subDoc.data();
        if (d?.name) subscriberName = d.name.trim() || subscriberName;
      }
    } catch (e) {
      logger.error("❌ Error reading subscriber:", e);
    }

    for (const authorUid of newlySubscribedAuthors) {
      try {
        if (!authorUid || authorUid === subscriberId) continue;

        await createInAppNotification({
          userId: authorUid,
          type: "user_subscribed",
          actorId: subscriberId
        });

        const authorDoc = await db.collection("users").doc(authorUid).get();
        if (!authorDoc.exists) continue;

        const tokens = collectTokensFromUserDoc(authorDoc);
        if (!tokens.length) {
          logger.info(`🔇 No tokens for author ${authorUid} on new subscription from ${subscriberId}`);
          continue;
        }

        const language = getUserOriginalLanguage(authorDoc.data());
        const body = getSubscribedBody(language);

        const rsp = await getMessaging().sendEachForMulticast({
          tokens,
          notification: {
            title: subscriberName,   // 👈 в заголовке имя подписчика
            body                     // 👈 тело на английском
          },
          data: {
            type: "user_subscribed",
            route: "channel",
            subscriberId,
            channelId: subscriberId
          },
          apns: {
            payload: {
              aps: {
                "mutable-content": 1
              }
            }
          }
        });

        logger.info(
          `👤 Subscription: author ${authorUid}, subscriber ${subscriberId}, language ${language}, sent ${rsp.successCount}/${tokens.length}`
        );

      } catch (e) {
        logger.error("❌ Error while handling subscription:", e);
      }
    }
  }
);

export const notifyCommentAdded = onDocumentCreated(
  "commentaries/{commentId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const articleId = sanitizeGeneratedValue(data.root_post_id);
    const authorUid = sanitizeGeneratedValue(data.root_author_id);
    const commenterId = sanitizeGeneratedValue(data.author_id);

    if (!articleId || !authorUid || !commenterId || authorUid === commenterId) {
      return;
    }

    try {
      const articleSnap = await db.collection("articles").doc(articleId).get();
      let notificationUserId = authorUid;
      let notificationType = "comment_added";
      let notificationPostId = articleId;
      let article = articleSnap.exists ? (articleSnap.data() || {}) : null;

      if (article) {
        notificationUserId = authorUid;
        notificationType = "comment_added";
      } else {
        const parentCommentSnap = await db.collection("commentaries").doc(articleId).get();
        if (!parentCommentSnap.exists) return;

        const parentComment = parentCommentSnap.data() || {};
        const legacyParentCommentAuthorId = sanitizeGeneratedValue(parentComment.author_id);
        const parentArticleId = sanitizeGeneratedValue(parentComment.root_post_id);

        if (!legacyParentCommentAuthorId || legacyParentCommentAuthorId === commenterId) {
          return;
        }

        notificationUserId = legacyParentCommentAuthorId;
        notificationType = "comment_reply";
        notificationPostId = parentArticleId;

        if (parentArticleId) {
          const parentArticleSnap = await db.collection("articles").doc(parentArticleId).get();
          if (parentArticleSnap.exists) {
            article = parentArticleSnap.data() || {};
          }
        }
      }

      await createInAppNotification({
        userId: notificationUserId,
        type: notificationType,
        actorId: commenterId,
        postId: notificationPostId
      });

      const authorDoc = await db.collection("users").doc(notificationUserId).get();
      if (!authorDoc.exists) return;

      const tokens = collectTokensFromUserDoc(authorDoc);
      if (!tokens.length) {
        logger.info(`🔇 No tokens for user ${notificationUserId} on new comment target ${articleId}`);
        return;
      }

      let commenterName = "User";
      try {
        const commenterDoc = await db.collection("users").doc(commenterId).get();
        if (commenterDoc.exists) {
          const d = commenterDoc.data();
          if (d?.name) commenterName = d.name.trim() || commenterName;
        }
      } catch (e) {
        logger.error("❌ Error reading commenter:", e);
      }

      const language = getUserOriginalLanguage(authorDoc.data());
      const rawTitle = sanitizeGeneratedValue(article?.title);
      const shortTitle = rawTitle.length > 40
        ? `${rawTitle.slice(0, 40).trimEnd()}…`
        : rawTitle;
      const isShortPost = !!article?.is_short_post;
      const body = notificationType === "comment_reply"
        ? getCommentReplyBody(language, shortTitle)
        : getCommentedArticleBody(language, isShortPost, shortTitle);

      const rsp = await getMessaging().sendEachForMulticast({
        tokens,
        notification: {
          title: commenterName,
          body
        },
        data: {
          type: notificationType,
          route: "article",
          articleId: notificationPostId,
          commenterId,
          channelId: commenterId
        },
        apns: {
          payload: {
            aps: {
              "mutable-content": 1
            }
          }
        }
      });

      logger.info(
        `💬 Comment notification: target ${articleId}, user ${notificationUserId}, commenter ${commenterId}, type ${notificationType}, sent ${rsp.successCount}/${tokens.length}`
      );
    } catch (error) {
      logger.error("❌ Error while handling comment notification:", error);
    }
  }
);

export const getPublicPost = onRequest(
  {
    cors: true
  },
  async (req, res) => {
    if (req.method !== "GET") {
      res.status(405).json({ error: "method-not-allowed" });
      return;
    }

    const index = String(req.query.index || "").trim();

    if (!index) {
      res.status(400).json({ error: "missing-index" });
      return;
    }

    try {
      const result = await loadPublicPostData(index);

      if (!result.post) {
        res.status(result.statusCode).json({ error: result.error });
        return;
      }

      res.status(200).json({
        ok: true,
        post: result.post
      });
    } catch (error) {
      logger.error("❌ getPublicPost failed", error);
      res.status(500).json({ error: "internal-error" });
    }
  }
);

export const renderPublicPostCard = onRequest(
  {
    cors: true,
    memory: "512MiB",
    maxInstances: 3
  },
  async (req, res) => {
    if (req.method !== "GET") {
      res.status(405).send("method-not-allowed");
      return;
    }

    const index = String(req.query.index || "").trim();

    if (!index) {
      res.status(400).send("missing-index");
      return;
    }

    try {
      const result = await loadPublicPostData(index);

      if (!result.post) {
        res.status(result.statusCode).send(result.error || "post-not-found");
        return;
      }

      const svg = await buildPublicPostCardSvg(result.post);
      const image = await sharp(Buffer.from(svg))
        .png({ compressionLevel: 9 })
        .toBuffer();

      res.set("Content-Type", "image/png");
      res.set("Cache-Control", "public, max-age=3600, s-maxage=86400");
      res.set("X-Content-Type-Options", "nosniff");
      res.status(200).send(image);
    } catch (error) {
      logger.error("❌ renderPublicPostCard failed", error);
      res.status(500).send("internal-error");
    }
  }
);

function shuffleItems(items) {
  const result = [...items];

  for (let index = result.length - 1; index > 0; index -= 1) {
    const randomIndex = Math.floor(Math.random() * (index + 1));
    [result[index], result[randomIndex]] = [result[randomIndex], result[index]];
  }

  return result;
}

export const getHomepagePosts = onRequest(
  {
    cors: true
  },
  async (req, res) => {
    if (req.method !== "GET") {
      res.status(405).json({ error: "method-not-allowed" });
      return;
    }

    const language = normalizeLanguage(req.query.lang);

    try {
      const snapshot = await db.collection("articles")
        .orderBy("date_created", "desc")
        .limit(50)
        .get();

      const availablePosts = snapshot.docs.filter((document) => {
        const data = document.data() || {};

        return data.is_archive !== true
          && data.is_draft !== true
          && data.is_premium_post !== true
          && normalizeLanguage(data.original_language) === language
          && typeof data.author_id === "string"
          && data.author_id.trim().length > 0;
      });

      const selectedDocuments = [];
      const selectedAuthorIds = new Set();

      for (const document of shuffleItems(availablePosts)) {
        const authorId = String(document.data()?.author_id || "").trim();

        if (!authorId || selectedAuthorIds.has(authorId)) {
          continue;
        }

        selectedAuthorIds.add(authorId);
        selectedDocuments.push(document);

        if (selectedDocuments.length === 5) {
          break;
        }
      }

      const posts = await Promise.all(selectedDocuments.map(async (document) => {
        const article = document.data() || {};
        const authorId = String(article.author_id || "").trim();
        const [userSnap, avatarUrl, media] = await Promise.all([
          db.collection("users").doc(authorId).get(),
          getPublicFileUrlIfExists(
            getStorage().bucket().file(`avatars/${authorId}.jpg`)
          ).then((url) => url || ""),
          buildPublicPostMedia(
            document.id,
            article.media_count,
            article.media_version
          )
        ]);
        const userData = userSnap.exists ? userSnap.data() || {} : {};
        const previewUrl = media.find((item) => item?.type === "image")?.url
          || media.find((item) => item?.type === "video" && item?.previewUrl)?.previewUrl
          || "";

        return {
          id: document.id,
          title: typeof article.title === "string" ? article.title : "",
          text: typeof article.text === "string" ? article.text : "",
          authorId,
          authorName: typeof userData.name === "string" && userData.name.trim()
            ? userData.name.trim()
            : "ReadBox author",
          avatarUrl,
          isCheckmark: !!userData.is_checkmark,
          isShortPost: !!article.is_short_post,
          mediaPosition: Number(article.media_position || 0),
          dateCreated: article.date_created?.toDate
            ? article.date_created.toDate().toISOString()
            : null,
          previewUrl,
          media
        };
      }));

      res.set("Cache-Control", "public, max-age=300, s-maxage=900");
      res.status(200).json({ ok: true, posts });
    } catch (error) {
      logger.error("❌ getHomepagePosts failed", error);
      res.status(500).json({ error: "internal-error" });
    }
  }
);

export const renderPublicPostPage = onRequest(
  {
    cors: true
  },
  async (req, res) => {
    if (req.method !== "GET") {
      res.status(405).send("method-not-allowed");
      return;
    }

    const index = String(req.query.index || "").trim();

    if (!index) {
      res.set("X-Content-Type-Options", "nosniff");
      res.set("X-Robots-Tag", "noindex, nofollow");
      res.status(400).send("missing-index");
      return;
    }

    try {
      const result = await loadPublicPostData(index);

      if (!result.post) {
        res.set("X-Content-Type-Options", "nosniff");
        res.set("X-Robots-Tag", "noindex, nofollow");
        res.status(result.statusCode).send(result.error || "post-not-found");
        return;
      }

      res.set("Content-Type", "text/html; charset=utf-8");
      res.set("Cache-Control", "public, max-age=300");
      res.set("X-Content-Type-Options", "nosniff");
      res.status(200).send(buildRenderedPublicPostHtml(result.post));
    } catch (error) {
      logger.error("❌ renderPublicPostPage failed", error);
      res.set("X-Robots-Tag", "noindex, nofollow");
      res.status(500).send("internal-error");
    }
  }
);

export const sitemapXml = onRequest(
  {
    cors: true
  },
  async (req, res) => {
    if (req.method !== "GET") {
      res.status(405).send("method-not-allowed");
      return;
    }

    try {
      const snapshot = await db.collection("articles")
        .orderBy("date_created", "desc")
        .limit(5000)
        .get();

      const urls = snapshot.docs
        .map((document) => {
          const data = document.data() || {};

          if (data.is_archive === true || data.is_draft === true || data.is_premium_post === true) {
            return null;
          }

          const id = sanitizeGeneratedValue(document.id);
          if (!id) {
            return null;
          }

          const lastmod = data.date_created?.toDate
            ? data.date_created.toDate().toISOString()
            : null;

          return {
            loc: buildPublicPostCanonicalUrl(id),
            lastmod
          };
        })
        .filter(Boolean);

      const xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls.map((item) => `  <url>
    <loc>${escapeHtml(item.loc)}</loc>
    ${item.lastmod ? `<lastmod>${escapeHtml(item.lastmod)}</lastmod>` : ""}
  </url>`).join("\n")}
</urlset>`;

      res.set("Content-Type", "application/xml; charset=utf-8");
      res.set("Cache-Control", "public, max-age=1800");
      res.set("X-Content-Type-Options", "nosniff");
      res.status(200).send(xml);
    } catch (error) {
      logger.error("❌ sitemapXml failed", error);
      res.status(500).send("internal-error");
    }
  }
);

export const robotsTxt = onRequest(
  {
    cors: true
  },
  async (req, res) => {
    if (req.method !== "GET") {
      res.status(405).send("method-not-allowed");
      return;
    }

    res.set("Content-Type", "text/plain; charset=utf-8");
    res.set("Cache-Control", "public, max-age=1800");
    res.set("X-Content-Type-Options", "nosniff");
    res.status(200).send([
      "User-agent: *",
      "Allow: /",
      "",
      "Sitemap: https://readbox.online/sitemap.xml"
    ].join("\n"));
  }
);
