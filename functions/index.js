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

/* ─────────────────────── инициализация SDK ─────────────────────── */
initializeApp();
const db = getFirestore();

/* ─────────────── helper: рассылаем пуш подписчикам ─────────────── */
async function pushToSubscribers({ authorUid, authorName, articleId, title }) {
  /* 1. uid-ы подписчиков автора */
  const usersSnap = await db.collection("users")
    .where("subscribes", "array-contains", authorUid)
    .get();
  if (usersSnap.empty) {
    logger.info("📭 Подписчиков нет");
    return;
  }

  /* 2. собираем FCM-токены */
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
    logger.info("🔇 У подписчиков нет токенов");
    return;
  }

  /* 3. отправляем */
  const rsp = await getMessaging().sendEachForMulticast({
    tokens,
    notification: {
      title: authorName,        // ← заголовок пуша = имя автора
      body:  title ?? "",       // ← тело пуша = титул статьи
    },
    data: { articleId, authorUid },
  });
  logger.info(`✅ Успешно: ${rsp.successCount} / ${tokens.length}`);

  /* 4. чистим битые токены */
  const dead = rsp.responses
    .map((r, i) =>
      !r.success &&
      ["messaging/invalid-registration-token",
       "messaging/registration-token-not-registered"].includes(r.error?.code)
        ? tokens[i]
        : null
    )
    .filter(Boolean);

  if (dead.length) {
    const batch = db.batch();
    usersSnap.forEach((doc) => {
      const upd = {};
      dead.forEach((t) => {
        if (doc.data().fcm_tokens?.[t])
          upd[`fcm_tokens.${t}`] = FieldValue.delete();
        if (doc.data().fcm_token === t)
          upd["fcm_token"] = FieldValue.delete();
      });
      if (Object.keys(upd).length) batch.update(doc.ref, upd);
    });
    await batch.commit();
    logger.info(`🗑 Удалено битых токенов: ${dead.length}`);
  }
}

/* ───────────── функция 1: новая статья ───────────── */
export const notifyNewPost = onDocumentCreated(
  "articles/{id}",
  async (event) => {
    const article = event.data?.data();
    if (!article) return;

    /* пропускаем архивные */
    if (article.is_archive) return;

    const authorUid  = article.author_id;
    const articleId  = event.params.id;

    /* имя автора */
    let authorName = "Автор";
    const doc = await db.collection("users").doc(authorUid).get();
    if (doc.exists) {
      const d = doc.data();
      authorName = d.author_name;
    }

    logger.info(`🆕 Новая статья ${articleId}`);

    await pushToSubscribers({
      authorUid,
      authorName,
      articleId,
      title: article.title
    });
  }
);

/* ─────── функция 2: статья вытащена из архива ────── */
export const notifyUnarchivedPost = onDocumentUpdated(
  "articles/{id}",
  async (event) => {
    const before = event.data?.before?.data();
    const after  = event.data?.after?.data();
    if (!before || !after) return;

    /* условие: было в архиве → стало активной */
    const wasArchived = !!before.is_archive;
    const nowArchived = !!after.is_archive;
    if (!wasArchived || nowArchived) return;          // не тот случай

    const authorUid  = after.author_id;
    const articleId  = event.params.id;

    /* имя автора */
    let authorName = "Автор";
    const doc = await db.collection("users").doc(authorUid).get();
    if (doc.exists) {
      const d = doc.data();
      authorName = d.author_name;
    }

    logger.info(`♻️ Статья ${articleId} восстановлена из архива`);

    await pushToSubscribers({
      authorUid,
      authorName,
      articleId,
      title: after.title
    });
  }
);
