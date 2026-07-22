const copy = {
    ru: {
        kicker: "Laynor",
        shot1Title: "Пишите проще.<br>В любом приложении.",
        shot1Text: "AI-помощник прямо в вашей клавиатуре.",
        shot2Title: "Из наброска —<br>в готовый текст.",
        shot2Text: "Laynor перепишет мысль естественно и по-человечески.",
        shot3Title: "Без ошибок.<br>Без переписывания.",
        shot3Text: "Исправляет орфографию и пунктуацию, сохраняя ваши слова.",
        shot4Title: "Любая задача.<br>Одной командой.",
        shot4Text: "Сократите, переведите или подготовьте ответ своими словами.",
        shot5Title: "Всегда там,<br>где вы пишете.",
        shot5Text: "Сообщения, почта, заметки и другие приложения.",
        rewrite: "Переписать",
        correct: "Исправить",
        space: "пробел",
        customCommand: "Своя команда",
        addMockup: "Добавить макет телефона",
        tapHint: "PNG с телефоном и скриншотом"
    },
    en: {
        kicker: "Laynor",
        shot1Title: "Write better.<br>In every app.",
        shot1Text: "Your AI assistant, right inside the keyboard.",
        shot2Title: "From rough idea<br>to ready-to-send.",
        shot2Text: "Laynor rewrites your draft in clear, natural language.",
        shot3Title: "Fix mistakes.<br>Keep your voice.",
        shot3Text: "Corrects spelling and punctuation without changing your words.",
        shot4Title: "Any task.<br>One command.",
        shot4Text: "Make it shorter, translate it, or prepare the perfect reply.",
        shot5Title: "Right where<br>you write.",
        shot5Text: "Messages, email, notes, and all your other apps.",
        rewrite: "Rewrite",
        correct: "Correct",
        space: "space",
        customCommand: "Custom command",
        addMockup: "Add phone mockup",
        tapHint: "PNG with the phone and app screen"
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

const wrappers = [...document.querySelectorAll(".shot-wrapper")];
const languageSelect = document.getElementById("languageSelect");
const clearButton = document.getElementById("clearButton");

languageSelect.addEventListener("change", () => applyLanguage(languageSelect.value));
clearButton.addEventListener("click", clearScreenshots);
document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && document.body.classList.contains("export-mode")) closeExport();
});

wrappers.forEach((wrapper) => {
    const device = wrapper.querySelector(".artwork-frame");
    const input = wrapper.querySelector(".file-input");
    const image = wrapper.querySelector(".uploaded-screen");

    if (device) {
        device.addEventListener("click", () => input.click());
        wrapper.querySelector(".upload-button").addEventListener("click", () => input.click());
        input.addEventListener("change", () => setImage(input.files[0], device, image));

        device.addEventListener("dragover", (event) => {
            event.preventDefault();
            device.classList.add("is-dragging");
        });
        device.addEventListener("dragleave", () => device.classList.remove("is-dragging"));
        device.addEventListener("drop", (event) => {
            event.preventDefault();
            device.classList.remove("is-dragging");
            setImage(event.dataTransfer.files[0], device, image);
        });
    }

    wrapper.querySelector(".export-button").addEventListener("click", (event) => exportCard(wrapper, event.currentTarget));
});

applyLanguage(navigator.language.toLowerCase().startsWith("ru") ? "ru" : "en");

function applyLanguage(language) {
    const locale = copy[language] ? language : "en";
    document.documentElement.lang = locale;
    languageSelect.value = locale;
    document.querySelectorAll("[data-copy]").forEach((element) => {
        element.innerHTML = copy[locale][element.dataset.copy];
    });
    updateKeyboardLayout(locale);
}

function updateKeyboardLayout(locale) {
    document.querySelectorAll("[data-key-row]").forEach((row) => {
        const keys = keyboardLayouts[locale][Number(row.dataset.keyRow)];
        row.querySelectorAll("span").forEach((key, index) => {
            key.textContent = keys[index];
        });
    });
}

function setImage(file, device, image) {
    if (!file || !file.type.startsWith("image/")) return;
    const reader = new FileReader();
    reader.addEventListener("load", () => {
        image.src = reader.result;
        device.classList.add("has-image");
    });
    reader.readAsDataURL(file);
}

function clearScreenshots() {
    wrappers.forEach((wrapper) => {
        wrapper.querySelector(".artwork-frame")?.classList.remove("has-image");
        wrapper.querySelector(".uploaded-screen")?.removeAttribute("src");
        wrapper.querySelector(".file-input").value = "";
    });
}

function closeExport() {
    document.body.classList.remove("export-mode");
    wrappers.forEach((item) => item.classList.remove("exporting"));
}

async function exportCard(wrapper, button) {
    const originalLabel = button.textContent;
    button.disabled = true;
    button.textContent = languageSelect.value === "ru" ? "Экспорт…" : "Exporting…";

    try {
        wrappers.forEach((item) => item.classList.toggle("exporting", item === wrapper));
        document.body.classList.add("export-mode");
        await nextPaint();

        const source = wrapper.querySelector(".store-shot");
        const clone = source.cloneNode(true);
        await inlineImages(source, clone);
        inlineStyles(source, clone);
        clone.style.width = "1320px";
        clone.style.height = "2868px";
        clone.style.borderRadius = "0";
        clone.style.boxShadow = "none";

        const markup = new XMLSerializer().serializeToString(clone);
        const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="1320" height="2868"><foreignObject width="100%" height="100%"><div xmlns="http://www.w3.org/1999/xhtml" style="width:1320px;height:2868px;background:#fff">${markup}</div></foreignObject></svg>`;
        const blob = new Blob([svg], { type: "image/svg+xml;charset=utf-8" });
        const url = URL.createObjectURL(blob);
        const renderedImage = await loadImage(url);
        URL.revokeObjectURL(url);

        const canvas = document.createElement("canvas");
        canvas.width = 1320;
        canvas.height = 2868;
        const context = canvas.getContext("2d");
        context.fillStyle = "#ffffff";
        context.fillRect(0, 0, canvas.width, canvas.height);
        context.drawImage(renderedImage, 0, 0, canvas.width, canvas.height);

        const download = document.createElement("a");
        const number = wrapper.querySelector(".store-shot").dataset.shot;
        download.download = `laynor-${languageSelect.value}-${number}-1320x2868.png`;
        download.href = canvas.toDataURL("image/png", 1);
        download.click();
    } catch (error) {
        console.error(error);
        alert(languageSelect.value === "ru" ? "Не удалось экспортировать карточку. Попробуйте ещё раз в Chrome или Safari." : "Could not export this card. Please try again in Chrome or Safari.");
    } finally {
        closeExport();
        button.disabled = false;
        button.textContent = originalLabel;
    }
}

function inlineStyles(source, clone) {
    const sourceNodes = [source, ...source.querySelectorAll("*")];
    const cloneNodes = [clone, ...clone.querySelectorAll("*")];
    sourceNodes.forEach((node, index) => {
        const computed = getComputedStyle(node);
        for (const property of computed) {
            cloneNodes[index].style.setProperty(property, computed.getPropertyValue(property), computed.getPropertyPriority(property));
        }
    });
}

async function inlineImages(source, clone) {
    const sourceImages = [...source.querySelectorAll("img")];
    const cloneImages = [...clone.querySelectorAll("img")];
    await Promise.all(sourceImages.map(async (image, index) => {
        if (!image.src || image.src.startsWith("data:")) return;
        const response = await fetch(image.src);
        const blob = await response.blob();
        cloneImages[index].src = await blobToDataURL(blob);
    }));
}

function blobToDataURL(blob) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => resolve(reader.result);
        reader.onerror = reject;
        reader.readAsDataURL(blob);
    });
}

function loadImage(url) {
    return new Promise((resolve, reject) => {
        const image = new Image();
        image.onload = () => resolve(image);
        image.onerror = reject;
        image.src = url;
    });
}

function nextPaint() {
    return new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)));
}
