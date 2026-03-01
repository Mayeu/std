// Populate the sidebar
//
// This is a script, and not included directly in the page, to control the total size of the book.
// The TOC contains an entry for each page, so if each page includes a copy of the TOC,
// the total size of the page becomes O(n**2).
class MDBookSidebarScrollbox extends HTMLElement {
    constructor() {
        super();
    }
    connectedCallback() {
        this.innerHTML = '<ol class="chapter"><li class="chapter-item expanded affix "><a href="index.html">Introduction</a></li><li class="chapter-item expanded affix "><a href="ARCHITECTURE.html">Design &amp; Architecture</a></li><li class="chapter-item expanded affix "><a href="PITCH.html">Sales Pitch</a></li><li class="chapter-item expanded affix "><a href="COMPARE.html">Comparisions</a></li><li class="chapter-item expanded affix "><a href="ROADMAP.html">Roadmap</a></li><li class="chapter-item expanded affix "><li class="part-title">Tutorials</li><li class="chapter-item expanded "><a href="tutorials/walk-in-the-park.html"><strong aria-hidden="true">1.</strong> A walk in the park</a></li><li class="chapter-item expanded "><a href="tutorials/hello-world/index.html"><strong aria-hidden="true">2.</strong> Hello World</a></li><li class="chapter-item expanded "><a href="tutorials/hello-moon/index.html"><strong aria-hidden="true">3.</strong> Hello Moon</a></li><li class="chapter-item expanded affix "><li class="part-title">How-To Guides</li><li class="chapter-item expanded "><a href="guides/growing-cells.html"><strong aria-hidden="true">4.</strong> Growing Cells</a></li><li class="chapter-item expanded "><a href="guides/incl.html"><strong aria-hidden="true">5.</strong> Include Filter</a></li><li class="chapter-item expanded "><a href="guides/envrc.html"><strong aria-hidden="true">6.</strong> Setup .envrc</a></li><li class="chapter-item expanded affix "><li class="part-title">Explanation</li><li class="chapter-item expanded "><a href="explain/why-nix.html"><strong aria-hidden="true">7.</strong> Why nix?</a></li><li class="chapter-item expanded "><a href="explain/why-std.html"><strong aria-hidden="true">8.</strong> Why std?</a></li><li class="chapter-item expanded "><a href="explain/architecture-decision-records/index.html"><strong aria-hidden="true">9.</strong> Architecture Decisions</a></li><li class="chapter-item expanded affix "><li class="part-title">Patterns</li><li class="chapter-item expanded "><a href="patterns/four-packaging-layers.html"><strong aria-hidden="true">10.</strong> The 4 Packaging Layers</a></li><li class="chapter-item expanded "><a href="patterns/ci-cd-10000-feet.html"><strong aria-hidden="true">11.</strong> CI/CD — 10000ft flight height</a></li><li class="chapter-item expanded affix "><li class="part-title">Templates</li><li class="chapter-item expanded "><a href="templates/minimal.html"><strong aria-hidden="true">12.</strong> Minimal</a></li><li class="chapter-item expanded "><a href="templates/rust.html"><strong aria-hidden="true">13.</strong> Rust</a></li><li class="chapter-item expanded affix "><li class="part-title">Reference</li><li class="chapter-item expanded "><a href="reference/cli.html"><strong aria-hidden="true">14.</strong> TUI/CLI</a></li><li class="chapter-item expanded "><a href="reference/conventions.html"><strong aria-hidden="true">15.</strong> Conventions</a></li><li class="chapter-item expanded "><a href="reference/deprecations.html"><strong aria-hidden="true">16.</strong> Deprecations</a></li><li class="chapter-item expanded "><a href="reference/blocktypes.html"><strong aria-hidden="true">17.</strong> Builtin Block Types</a></li><li class="chapter-item expanded "><a href="reference/lib.html"><strong aria-hidden="true">18.</strong> Cell: lib</a></li><li class="chapter-item expanded "><a href="reference/std.html"><strong aria-hidden="true">19.</strong> Cell: std</a></li><li class="chapter-item expanded "><a href="glossary.html"><strong aria-hidden="true">20.</strong> Glossary</a></li></ol>';
        // Set the current, active page, and reveal it if it's hidden
        let current_page = document.location.href.toString().split("#")[0].split("?")[0];
        if (current_page.endsWith("/")) {
            current_page += "index.html";
        }
        var links = Array.prototype.slice.call(this.querySelectorAll("a"));
        var l = links.length;
        for (var i = 0; i < l; ++i) {
            var link = links[i];
            var href = link.getAttribute("href");
            if (href && !href.startsWith("#") && !/^(?:[a-z+]+:)?\/\//.test(href)) {
                link.href = path_to_root + href;
            }
            // The "index" page is supposed to alias the first chapter in the book.
            if (link.href === current_page || (i === 0 && path_to_root === "" && current_page.endsWith("/index.html"))) {
                link.classList.add("active");
                var parent = link.parentElement;
                if (parent && parent.classList.contains("chapter-item")) {
                    parent.classList.add("expanded");
                }
                while (parent) {
                    if (parent.tagName === "LI" && parent.previousElementSibling) {
                        if (parent.previousElementSibling.classList.contains("chapter-item")) {
                            parent.previousElementSibling.classList.add("expanded");
                        }
                    }
                    parent = parent.parentElement;
                }
            }
        }
        // Track and set sidebar scroll position
        this.addEventListener('click', function(e) {
            if (e.target.tagName === 'A') {
                sessionStorage.setItem('sidebar-scroll', this.scrollTop);
            }
        }, { passive: true });
        var sidebarScrollTop = sessionStorage.getItem('sidebar-scroll');
        sessionStorage.removeItem('sidebar-scroll');
        if (sidebarScrollTop) {
            // preserve sidebar scroll position when navigating via links within sidebar
            this.scrollTop = sidebarScrollTop;
        } else {
            // scroll sidebar to current active section when navigating via "next/previous chapter" buttons
            var activeSection = document.querySelector('#sidebar .active');
            if (activeSection) {
                activeSection.scrollIntoView({ block: 'center' });
            }
        }
        // Toggle buttons
        var sidebarAnchorToggles = document.querySelectorAll('#sidebar a.toggle');
        function toggleSection(ev) {
            ev.currentTarget.parentElement.classList.toggle('expanded');
        }
        Array.from(sidebarAnchorToggles).forEach(function (el) {
            el.addEventListener('click', toggleSection);
        });
    }
}
window.customElements.define("mdbook-sidebar-scrollbox", MDBookSidebarScrollbox);
