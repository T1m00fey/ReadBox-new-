const GOOGLE_ANALYTICS_ID = "G-BE9N4E068D";

window.dataLayer = window.dataLayer || [];
window.gtag = window.gtag || function () {
    window.dataLayer.push(arguments);
};

window.gtag("js", new Date());
window.gtag("config", GOOGLE_ANALYTICS_ID);

const googleTag = document.createElement("script");
googleTag.async = true;
googleTag.src = `https://www.googletagmanager.com/gtag/js?id=${GOOGLE_ANALYTICS_ID}`;
document.head.appendChild(googleTag);

const searchParams = new URLSearchParams(window.location.search);
const utm = {};

for (const name of ["utm_source", "utm_medium", "utm_campaign", "utm_content", "utm_term"]) {
    if (searchParams.get(name)) {
        utm[name] = searchParams.get(name);
    }
}

if (Object.keys(utm).length > 0) {
    sessionStorage.setItem("readbox_utm", JSON.stringify(utm));
}

function getUtm() {
    try {
        return JSON.parse(sessionStorage.getItem("readbox_utm") || "{}");
    } catch {
        return {};
    }
}

document.addEventListener("click", (event) => {
    const link = event.target.closest("a");

    if (!link || !link.href.includes("apps.apple.com")) return;

    window.gtag("event", "app_store_click", {
        link_url: link.href,
        ...getUtm()
    });
});

if (window.location.pathname.startsWith("/posts/")) {
    const postId = searchParams.get("index");

    if (postId) {
        const openedPosts = JSON.parse(sessionStorage.getItem("readbox_opened_posts") || "[]");

        if (!openedPosts.includes(postId)) {
            openedPosts.push(postId);
            sessionStorage.setItem("readbox_opened_posts", JSON.stringify(openedPosts));

            if (openedPosts.length === 2) {
                window.gtag("event", "second_publication_open", {
                    publication_id: postId,
                    ...getUtm()
                });
            }
        }
    }
}
