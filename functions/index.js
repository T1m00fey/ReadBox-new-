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
import { defineSecret, defineString } from "firebase-functions/params";
import { logger }                from "firebase-functions";
import { getStorage }            from "firebase-admin/storage"; // ← НОВОЕ

/* ─────────────────────── инициализация SDK ─────────────────────── */
initializeApp();
const db = getFirestore();
const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");
const OPENAI_MODEL = defineString("OPENAI_MODEL", {
  default: "gpt-4o-mini"
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

function normalizePublicationType(value) {
  return String(value || "").trim().toLowerCase() === "article"
    ? "article"
    : "post";
}

function sanitizeGeneratedValue(value) {
  return String(value || "")
    .replace(/\r\n/g, "\n")
    .trim();
}

function sanitizeTopicList(value) {
  if (!Array.isArray(value)) {
    return [];
  }

  const normalized = value
    .map((item) => sanitizeGeneratedValue(item))
    .filter(Boolean)
    .slice(0, 8);

  return [...new Set(normalized)];
}

function mergeTopicLists(existingTopics, newTopics, maxCount = 8) {
  return [...new Set([
    ...sanitizeTopicList(newTopics),
    ...sanitizeTopicList(existingTopics)
  ])].slice(0, maxCount);
}

function extractTopicCandidateFromPost(post) {
  const title = sanitizeGeneratedValue(post?.title);

  if (title) {
    return title.slice(0, 80);
  }

  const text = sanitizeGeneratedValue(post?.text);

  if (!text) {
    return "";
  }

  const sentence = text
    .split(/[.!?\n]/)
    .map((item) => sanitizeGeneratedValue(item))
    .find(Boolean);

  return sanitizeGeneratedValue(sentence).slice(0, 80);
}

function buildRecentPostSnippet(post, index) {
  const title = sanitizeGeneratedValue(post?.title);
  const text = sanitizeGeneratedValue(post?.text).slice(0, 400);
  const kind = post?.is_short_post ? "post" : "article";

  return [
    `#${index + 1}`,
    `type: ${kind}`,
    `title: ${title || "No title"}`,
    `text: ${text || "No text"}`
  ].join("\n");
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

function buildGenerationPrompt({
  publicationType,
  language,
  title,
  text,
  authorName,
  recentTopics,
  tone
}) {
  const languageLabel = language === "ru" ? "Russian" : "English";
  const safeTitle = sanitizeGeneratedValue(title);
  const safeText = String(text || "").trim();
  const safeAuthorName = sanitizeGeneratedValue(authorName) || "ReadBox author";
  const safeTone = sanitizeGeneratedValue(tone);
  const topicsText = sanitizeTopicList(recentTopics)
    .map((topic) => `- ${topic}`)
    .join("\n");

  if (publicationType === "article") {
    return `
Generate an original ${languageLabel} article draft for a ReadBox author.

Author name: ${safeAuthorName}
Author tone: ${safeTone || "No saved tone. Keep the style modern, expressive, and natural."}
Recent topics:
${topicsText || "- No saved topics yet"}
Current title or topic: ${safeTitle || "No title provided. Pick a strong modern topic yourself."}
Current text: ${safeText || "No current text provided. Generate the full draft from scratch."}

Requirements:
- Return valid JSON only.
- JSON keys: "title" and "text".
- "title" must be a concise strong article title.
- "text" must be a complete readable article in markdown-friendly plain text.
- No code fences.
- Keep the structure natural with paragraphs.
- Do not mention that the text was generated by AI.
- Keep the tone aligned with the saved author tone.
- Prefer a fresh angle and avoid repeating the recent topics too literally.
- Make the article substantial but not too long.
`.trim();
  }

  return `
Generate an original ${languageLabel} short post draft for a ReadBox author.

Author name: ${safeAuthorName}
Author tone: ${safeTone || "No saved tone. Keep the style lively, direct, and natural."}
Recent topics:
${topicsText || "- No saved topics yet"}
Current idea or draft: ${safeText || safeTitle || "No input provided. Pick a fresh topic yourself."}

Requirements:
- Return valid JSON only.
- JSON keys: "title" and "text".
- "title" must be an empty string.
- "text" must be a short post ready to publish.
- Keep it concise, natural, engaging, and not generic.
- Use the saved tone.
- Do not simply paraphrase the input. Expand it into a fresh post.
- Avoid repeating the recent topics too literally.
- No hashtags unless they are truly necessary.
- No code fences.
- Do not mention that the text was generated by AI.
`.trim();
}

function buildAuthorMemoryPrompt({
  language,
  authorName,
  recentPosts
}) {
  const languageLabel = language === "ru" ? "Russian" : "English";
  const safeAuthorName = sanitizeGeneratedValue(authorName) || "ReadBox author";
  const postsText = recentPosts
    .map((post, index) => buildRecentPostSnippet(post, index))
    .join("\n\n");

  return `
Analyze the recent published content of a ReadBox author.

Author name: ${safeAuthorName}
Content language: ${languageLabel}

Recent publications:
${postsText || "No recent publications"}

Requirements:
- Return valid JSON only.
- JSON keys: "recentTopics" and "tone".
- "recentTopics" must be an array of 3 to 8 short topic phrases describing what the author has been posting about lately.
- "tone" must be one short natural phrase describing the author's writing tone.
- Focus on what is actually visible in the recent posts, not generic assumptions.
- Do not mention AI.
- Keep the result concise and useful for future content generation.
`.trim();
}

async function requestOpenAIDraft({
  publicationType,
  language,
  title,
  text,
  authorName,
  recentTopics,
  tone
}) {
  const apiKey = OPENAI_API_KEY.value();

  if (!apiKey) {
    throw new Error("missing-openai-api-key");
  }

  const model = OPENAI_MODEL.value() || "gpt-4o-mini";
  const prompt = buildGenerationPrompt({
    publicationType,
    language,
    title,
    text,
    authorName,
    recentTopics,
    tone
  });

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      model,
      response_format: {
        type: "json_object"
      },
      messages: [
        {
          role: "system",
          content: "You write original publication drafts for ReadBox. Always answer with valid JSON only."
        },
        {
          role: "user",
          content: prompt
        }
      ]
    })
  });

  const payload = await response.json();

  if (!response.ok) {
    logger.error("❌ OpenAI error", payload);
    throw new Error(payload?.error?.message || "openai-request-failed");
  }

  const content = payload?.choices?.[0]?.message?.content;

  if (!content) {
    throw new Error("empty-openai-response");
  }

  let parsed;

  try {
    parsed = JSON.parse(content);
  } catch (err) {
    logger.error("❌ OpenAI JSON parse error", err, content);
    throw new Error("invalid-openai-json");
  }

  return {
    title: sanitizeGeneratedValue(parsed?.title),
    text: sanitizeGeneratedValue(parsed?.text)
  };
}

async function requestAuthorMemorySummary({
  language,
  authorName,
  recentPosts
}) {
  const apiKey = OPENAI_API_KEY.value();

  if (!apiKey) {
    throw new Error("missing-openai-api-key");
  }

  const model = OPENAI_MODEL.value() || "gpt-4o-mini";
  const prompt = buildAuthorMemoryPrompt({
    language,
    authorName,
    recentPosts
  });

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      model,
      response_format: {
        type: "json_object"
      },
      messages: [
        {
          role: "system",
          content: "You analyze a ReadBox author's recent publications and return concise author memory as valid JSON only."
        },
        {
          role: "user",
          content: prompt
        }
      ]
    })
  });

  const payload = await response.json();

  if (!response.ok) {
    logger.error("❌ OpenAI memory error", payload);
    throw new Error(payload?.error?.message || "openai-memory-request-failed");
  }

  const content = payload?.choices?.[0]?.message?.content;

  if (!content) {
    throw new Error("empty-openai-memory-response");
  }

  let parsed;

  try {
    parsed = JSON.parse(content);
  } catch (err) {
    logger.error("❌ OpenAI memory JSON parse error", err, content);
    throw new Error("invalid-openai-memory-json");
  }

  return {
    recentTopics: sanitizeTopicList(parsed?.recentTopics),
    tone: sanitizeGeneratedValue(parsed?.tone)
  };
}

async function getOrInitializeAuthorAIMemory(authorUid, fallbackAuthorName = "") {
  const userRef = db.collection("users").doc(authorUid);
  const userDoc = await userRef.get();
  const userData = userDoc.data() || {};

  const existingTopics = sanitizeTopicList(userData?.ai_recent_topics);
  const existingTone = sanitizeGeneratedValue(userData?.ai_tone);

  if (existingTopics.length && existingTone) {
    return {
      recentTopics: existingTopics,
      tone: existingTone,
      authorName: sanitizeGeneratedValue(userData?.name) || sanitizeGeneratedValue(fallbackAuthorName) || "ReadBox"
    };
  }

  const authorName = sanitizeGeneratedValue(userData?.name) || sanitizeGeneratedValue(fallbackAuthorName) || "ReadBox";
  const language = getUserOriginalLanguage(userData);

  const postsSnap = await db.collection("articles")
    .where("author_id", "==", authorUid)
    .where("is_archive", "==", false)
    .orderBy("date_created", "desc")
    .limit(12)
    .get();

  const publishedPosts = postsSnap.docs
    .map((doc) => doc.data())
    .filter((post) => !post?.is_draft);

  const nonLocalizedPosts = publishedPosts.filter(
    (post) => post?.is_localized_version !== true
  );

  const recentPosts = (nonLocalizedPosts.length ? nonLocalizedPosts : publishedPosts)
    .slice(0, 8);

  if (!recentPosts.length) {
    return {
      recentTopics: existingTopics,
      tone: existingTone,
      authorName
    };
  }

  const memory = await requestAuthorMemorySummary({
    language,
    authorName,
    recentPosts
  });

  await userRef.update({
    ai_recent_topics: memory.recentTopics,
    ai_tone: memory.tone,
    ai_memory_initialized: true,
    ai_memory_updated_at: FieldValue.serverTimestamp()
  });

  logger.info(
    `🧠 Initialized AI memory for author ${authorUid}: topics=${memory.recentTopics.length}, tone="${memory.tone}"`
  );

  return {
    recentTopics: memory.recentTopics,
    tone: memory.tone,
    authorName
  };
}

async function appendTopicToAuthorMemory(authorUid, post) {
  if (!authorUid || !post || post.is_draft || post.is_archive) {
    return;
  }

  const topic = extractTopicCandidateFromPost(post);

  if (!topic) {
    return;
  }

  try {
    const userRef = db.collection("users").doc(authorUid);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      return;
    }

    const userData = userDoc.data() || {};
    const existingTopics = sanitizeTopicList(userData?.ai_recent_topics);

    if (!existingTopics.length) {
      return;
    }

    const mergedTopics = mergeTopicLists(existingTopics, [topic]);

    if (JSON.stringify(mergedTopics) === JSON.stringify(existingTopics)) {
      return;
    }

    await userRef.update({
      ai_recent_topics: mergedTopics,
      ai_memory_updated_at: FieldValue.serverTimestamp()
    });

    logger.info(`📝 Updated author topics for ${authorUid}: ${topic}`);
  } catch (error) {
    logger.error(`❌ Failed to append topic for author ${authorUid}`, error);
  }
}

export const generatePublicationDraft = onRequest(
  {
    cors: true,
    secrets: [OPENAI_API_KEY]
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "method-not-allowed" });
      return;
    }

    try {
      const decodedToken = await verifyRequestUser(req);
      const publicationType = normalizePublicationType(req.body?.publicationType);
      const language = normalizeLanguage(req.body?.language);
      const title = req.body?.title || "";
      const text = req.body?.text || "";
      const authorName = req.body?.authorName || "";
      const memory = await getOrInitializeAuthorAIMemory(decodedToken.uid, authorName);

      logger.info(
        `✨ AI draft request: user=${decodedToken.uid}, type=${publicationType}, language=${language}`
      );

      const draft = await requestOpenAIDraft({
        publicationType,
        language,
        title,
        text,
        authorName: memory.authorName,
        recentTopics: memory.recentTopics,
        tone: memory.tone
      });

      res.status(200).json(draft);
    } catch (error) {
      logger.error("❌ generatePublicationDraft failed", error);

      const message = error instanceof Error
        ? error.message
        : "unknown-error";

      const statusCode = message === "missing-auth-token"
        ? 401
        : 500;

      res.status(statusCode).json({
        error: message
      });
    }
  }
);

export const syncAuthorTopicsOnPostCreated = onDocumentCreated(
  "articles/{articleId}",
  async (event) => {
    const data = event.data?.data();

    if (!data) {
      return;
    }

    await appendTopicToAuthorMemory(data.author_id, data);
  }
);

export const syncAuthorTopicsOnPostUpdated = onDocumentUpdated(
  "articles/{articleId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    if (!before || !after) {
      return;
    }

    const shouldUpdateTopics =
      before.title !== after.title ||
      before.text !== after.text ||
      before.is_archive !== after.is_archive ||
      before.is_draft !== after.is_draft;

    if (!shouldUpdateTopics) {
      return;
    }

    await appendTopicToAuthorMemory(after.author_id || before.author_id, after);
  }
);

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
