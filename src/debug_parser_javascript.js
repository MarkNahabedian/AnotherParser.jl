
function toggle_visibility(element) {
    if (element.style.display == "none") {
        element.style.display = "block";
    } else {
        element.style.display = "none";
    }
    // console.log("toggled ", element, "to", element.style.display);
}

function log_index_click_handler(event) {
    if (event instanceof PointerEvent) {
        // When we want to add other mouse actions:
        // event.shiftKey, event.ctrlKey, event.altKey, event.metaKey
        if (event.target.classList.contains("log-index")) {
            event.target.closest(".level").querySelectorAll(":scope > .level").forEach((element, index) => {
                toggle_visibility(element);
            });
        }
    }
}

document.addEventListener('DOMContentLoaded', (event) => {
    // console.log('DOM fully loaded and parsed');
    document.querySelector("body").addEventListener("click", (event) => {
        log_index_click_handler(event);
    });
});

