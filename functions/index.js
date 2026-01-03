/* ──────────────────────────── импорты ──────────────────────────── */
import { initializeApp }         from "firebase-admin/app";
import {
  getFirestore,
  FieldValue
}                                from "firebase-admin/firestore";
import { getMessaging }          from "firebase-admin/messaging";
import {
  onDocumentCreated,
  onDocumentUpdated
}                                from "firebase-functions/v2/firestore";
import { logger }                from "firebase-functions";
import { getStorage }            from "firebase-admin/storage"; // ← НОВОЕ

/* ─────────────────────── инициализация SDK ─────────────────────── */
initializeApp();
const db = getFirestore();

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

/* ─────────────── helper: рассылаем пуш подписчикам ─────────────── */
async function pushToSubscribers({
  authorUid,
  authorName,
  articleId,
  title,
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

  // собираем все токены
  const tokens = [];
  usersSnap.forEach((doc) => {
    const d = doc.data();
    if (d.fcm_tokens && typeof d.fcm_tokens === "object") {
      tokens.push(...Object.keys(d.fcm_tokens));
    }
    if (typeof d.fcm_token === "string" && d.fcm_token.length) {
      tokens.push(d.fcm_token);
    }
  });

  if (!tokens.length) {
    logger.info("🔇 У подписчиков нет FCM-токенов");
    return;
  }

  // эмодзи по первому медиа
  const emoji = await detectFirstMediaEmoji(articleId, mediaCount, mediaVersion);
  const body = `${emoji}${title ?? ""}`;

  const msg = {
    tokens,
    notification: {
      title: authorName,
      body
      // image НЕ отправляем
    },
    data: {
      articleId
      // никаких imageUrl / fallbackImageUrl
    }
    // ВАЖНО: не ставим "mutable-content": 1,
    // чтобы не дергать NotificationService extension
  };

  const rsp = await getMessaging().sendEachForMulticast(msg);
  logger.info(
    `✅ Pushed new article ${articleId}: ${rsp.successCount}/${tokens.length} success`
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

    const mediaCount = data.media_count ?? 0;
    const mediaVersion = data.media_version ?? 1;

    await pushToSubscribers({
      authorUid,
      authorName,
      articleId,
      title,
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

      const mediaCount = after.media_count ?? 0;
      const mediaVersion = after.media_version ?? 1;

      await pushToSubscribers({
        authorUid,
        authorName,
        articleId,
        title,
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

        // --- формируем текст пуша (EN) ---
        const rawTitle = (article.title || "").trim();
        const maxLen = 40;
        let shortTitle = rawTitle;
        if (shortTitle.length > maxLen) {
          shortTitle = shortTitle.slice(0, maxLen).trimEnd() + "…";
        }

        const isShortPost = !!article.is_short_post;
        const baseText = isShortPost
          ? "liked your post"
          : "liked your article";

        let body;
        if (shortTitle.length > 0) {
          body = `${baseText} “${shortTitle}”`;
        } else {
          body = baseText;
        }

        const rsp = await getMessaging().sendEachForMulticast({
          tokens,
          notification: {
            title: likerName,   // 👈 в заголовке имя лайкнувшего
            body
          },
          data: {
            type: "post_liked",
            articleId,
            likerId
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
          `👍 Like: article ${articleId}, author ${authorUid}, liked by ${likerId}, sent ${rsp.successCount}/${tokens.length}`
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

        const body = "subscribed to you";

        const rsp = await getMessaging().sendEachForMulticast({
          tokens,
          notification: {
            title: subscriberName,   // 👈 в заголовке имя подписчика
            body                     // 👈 тело на английском
          },
          data: {
            type: "user_subscribed",
            subscriberId
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
          `👤 Subscription: author ${authorUid}, subscriber ${subscriberId}, sent ${rsp.successCount}/${tokens.length}`
        );

      } catch (e) {
        logger.error("❌ Error while handling subscription:", e);
      }
    }
  }
);
