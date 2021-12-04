const timings = false;

function debounce(func, timeout = 30){
    let timer;
    return (...args) => {
        clearTimeout(timer);
        timer = setTimeout(() => { func.apply(this, args); }, timeout);
    };
}

function search(searchString) {
    if (timings) console.time("search");

    searchString = searchString.trim();

    if (searchString != "") {
        history.pushState(null, null, `?search=${searchString}`);
    } else {
        history.pushState(null, null, `?`);
    }

    const pkgsWithMatches = {};
    const searchTerms = (searchString == "") ? [] : searchString.split(" ");

    document.querySelectorAll(".proc").forEach(proc => {
        if (searchTerms.length == 0 || searchTerms.every(term => proc.id.includes(term))) {
            pkgsWithMatches[proc.dataset.pkg] = true;
            proc.classList.add("match");
            proc.classList.remove("hidden");
        } else {
            proc.classList.add("hidden");
            proc.classList.remove("match");
        }
    });

    document.querySelectorAll(".pkg").forEach(pkg => {
        if (pkg.id in pkgsWithMatches) {
            pkg.classList.remove("hidden");
        } else {
            pkg.classList.add("hidden");
        }
    });

    if (timings) console.timeEnd("search");
}

function clearSearch() {
    searchInput.value = "";
    search("");
}

const searchInput = document.querySelector(".search-input");

searchInput.addEventListener("input", debounce((event) => {
    search(event.target.value);
}));

document.querySelectorAll("#pkgs a").forEach(a => a.addEventListener("click", clearSearch));

window.onload = () => {
    const params = new URLSearchParams(document.location.search);
    const searchString = params.get("search");
    if (searchString) {
        searchInput.value = searchString;
    }

    search(searchInput.value);
};
