const translations = {
    ru: {
        pageTitle: "Laynor — AI прямо в клавиатуре",
        description: "Laynor — AI-помощник прямо в клавиатуре iPhone. Переписывайте и исправляйте текст в любом приложении.",
        eyebrow: "AI-ПОМОЩНИК ДЛЯ IPHONE",
        heroTitle: "Хороший текст.<br>В любом приложении.",
        heroDescription: "Laynor живёт прямо в клавиатуре: исправляет ошибки, переписывает черновики и помогает выразить мысль точнее.",
        seeHow: "Посмотреть, как работает",
        availability: "Скоро в App Store",
        draftLabel: "Черновик",
        draftText: "привет я наверное не успею закончить сегодня давай завтра",
        rewrite: "Переписать",
        correct: "Исправить",
        space: "пробел",
        done: "Готово",
        resultText: "Привет! Боюсь, сегодня закончить не успею. Давай перенесём на завтра?",
        statement: "Не нужно переключаться между приложениями. Выделите текст, выберите действие — и продолжайте общение.",
        featuresEyebrow: "САМОЕ НУЖНОЕ — ПОД РУКОЙ",
        featuresTitle: "Помогает писать,<br>не меняя ваш голос.",
        rewriteTitle: "Переписать",
        rewriteDescription: "Превращает набросок в естественный, понятный текст — без канцелярита и лишнего пафоса.",
        correctTitle: "Исправить",
        correctDescription: "Исправляет только орфографию и пунктуацию. Слова и смысл остаются вашими.",
        commandTitle: "Своя команда",
        commandDescription: "Скажите Laynor, что сделать с текстом: сократить, перевести или подготовить ответ.",
        stepsEyebrow: "НАЧАТЬ ЛЕГКО",
        stepsTitle: "Три шага —<br>и Laynor всегда рядом.",
        stepOneTitle: "Установите приложение",
        stepOneText: "Скачайте Laynor на iPhone.",
        stepTwoTitle: "Добавьте клавиатуру",
        stepTwoText: "Подключите её в настройках за минуту.",
        stepThreeTitle: "Пишите где угодно",
        stepThreeText: "Мессенджеры, почта, заметки и другие приложения.",
        privacyEyebrow: "ПРИВАТНОСТЬ",
        privacyTitle: "Ваш текст —<br>это ваш текст.",
        privacyText: "Laynor отправляет текст на обработку только после вашего нажатия на AI-команду. Обычный ввод с клавиатуры никуда не передаётся.",
        ctaEyebrow: "LAYNOR ДЛЯ IPHONE",
        ctaTitle: "Пишите проще.<br>Говорите точнее.",
        ctaText: "Скоро в App Store.",
        contact: "Связаться с нами",
        madeBy: "Продукт",
        privacyLink: "Конфиденциальность",
        termsLink: "Условия использования"
    },
    en: {
        pageTitle: "Laynor — AI inside your keyboard",
        description: "Laynor is an AI assistant inside your iPhone keyboard. Rewrite and correct text in any app.",
        eyebrow: "AI ASSISTANT FOR IPHONE",
        heroTitle: "Better writing.<br>In every app.",
        heroDescription: "Laynor lives inside your keyboard: it fixes mistakes, rewrites rough drafts, and helps you say exactly what you mean.",
        seeHow: "See how it works",
        availability: "Coming soon to the App Store",
        draftLabel: "Draft",
        draftText: "hey i probably won't finish this today can we do tomorrow",
        rewrite: "Rewrite",
        correct: "Correct",
        space: "space",
        done: "Done",
        resultText: "Hey! I don't think I'll finish this today. Could we move it to tomorrow?",
        statement: "No more switching between apps. Select your text, choose an action, and keep the conversation going.",
        featuresEyebrow: "EVERYTHING YOU NEED, RIGHT THERE",
        featuresTitle: "Helps you write<br>without changing your voice.",
        rewriteTitle: "Rewrite",
        rewriteDescription: "Turns a rough draft into clear, natural language — without sounding robotic or overdone.",
        correctTitle: "Correct",
        correctDescription: "Fixes spelling and punctuation only. Your words and meaning stay yours.",
        commandTitle: "Custom command",
        commandDescription: "Tell Laynor what to do: make it shorter, translate it, or help you prepare a reply.",
        stepsEyebrow: "EASY TO START",
        stepsTitle: "Three steps.<br>Laynor is always close.",
        stepOneTitle: "Install the app",
        stepOneText: "Download Laynor on your iPhone.",
        stepTwoTitle: "Add the keyboard",
        stepTwoText: "Enable it in Settings in under a minute.",
        stepThreeTitle: "Write anywhere",
        stepThreeText: "Messages, email, notes, and all your other apps.",
        privacyEyebrow: "PRIVACY",
        privacyTitle: "Your text stays<br>your text.",
        privacyText: "Laynor sends text for processing only when you tap an AI command. Everything you type normally stays on your device.",
        ctaEyebrow: "LAYNOR FOR IPHONE",
        ctaTitle: "Write simply.<br>Say it clearly.",
        ctaText: "Coming soon to the App Store.",
        contact: "Contact us",
        madeBy: "A product by",
        privacyLink: "Privacy",
        termsLink: "Terms of Use"
    }
};

const keyboardLayouts = {
    ru: [
        ["Й", "Ц", "У", "К", "Е", "Н", "Г", "Ш", "Щ", "З", "Х"],
        ["Ф", "Ы", "В", "А", "П", "Р", "О", "Л", "Д", "Ж", "Э"],
        ["⇧", "Я", "Ч", "С", "М", "И", "Т", "Ь", "Б", "Ю", "⌫"]
    ],
    en: [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "["],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L", ";", "'"],
        ["⇧", "Z", "X", "C", "V", "B", "N", "M", ",", ".", "⌫"]
    ]
};

const root = document.documentElement;
const browserLanguage = navigator.language.toLowerCase().startsWith("ru") ? "ru" : "en";

applyLanguage(browserLanguage);
observeReveals();

function applyLanguage(language) {
    const locale = translations[language] ? language : "en";
    const dictionary = translations[locale];

    root.lang = locale;
    document.title = dictionary.pageTitle;
    document.querySelector('meta[name="description"]').content = dictionary.description;
    document.querySelector('meta[property="og:title"]').content = dictionary.pageTitle;
    document.querySelector('meta[property="og:description"]').content = dictionary.description;

    document.querySelectorAll("[data-i18n]").forEach((element) => {
        const value = dictionary[element.dataset.i18n];
        if (value !== undefined) element.innerHTML = value;
    });

    updateKeyboardLayout(locale);
}

function updateKeyboardLayout(locale) {
    document.querySelectorAll("[data-key-row]").forEach((row) => {
        const values = keyboardLayouts[locale][Number(row.dataset.keyRow)];
        row.querySelectorAll("span").forEach((key, index) => {
            key.textContent = values[index];
        });
    });
}

function observeReveals() {
    const elements = [...document.querySelectorAll(".reveal")];

    if (!("IntersectionObserver" in window)) {
        elements.forEach((element) => element.classList.add("is-visible"));
        return;
    }

    elements.forEach((element) => element.classList.add("reveal-pending"));

    const observer = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
            if (!entry.isIntersecting) return;
            entry.target.classList.add("is-visible");
            observer.unobserve(entry.target);
        });
    }, { threshold: 0.12 });

    elements.forEach((element) => observer.observe(element));

    window.setTimeout(() => {
        elements.forEach((element) => element.classList.add("is-visible"));
    }, 1800);
}
