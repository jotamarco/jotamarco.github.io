/* Interactions for the redesigned site (layout: modern).
   Only the Publications page needs JavaScript; every page works without it. */
(function () {
  "use strict";

  function toast(msg) {
    var t = document.getElementById("toast");
    if (!t) return;
    t.textContent = msg;
    t.classList.add("show");
    setTimeout(function () { t.classList.remove("show"); }, 1600);
  }

  var list = document.getElementById("publist");
  if (!list) return;

  var $ = function (s) { return document.querySelector(s); };
  var $$ = function (s) { return Array.prototype.slice.call(document.querySelectorAll(s)); };
  var input = $("#pub-q"), count = $("#pub-n"), empty = $("#pub-empty");
  var items = $$("#publist .pub");
  var groups = $$("#publist .yeargroup");
  var total = items.length;

  // Keep the original HTML of the searchable parts so highlights can be reset.
  items.forEach(function (li) {
    li._parts = [".t", ".a", ".v"].map(function (s) { var el = li.querySelector(s); return { el: el, html: el.innerHTML }; });
    li._text = (li.textContent + " " + li.closest(".yeargroup").dataset.year).toLowerCase().replace(/\s+/g, " ");
  });

  var params = new URLSearchParams(location.search);
  var st = { q: params.get("q") || "", type: params.get("type") || "all", topic: params.get("topic") || "all" };
  input.value = st.q;

  function escRe(s) { return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"); }
  function highlight(html, q) {
    if (!q) return html;
    var re = new RegExp("(" + escRe(q) + ")", "gi");
    return html.replace(/(<[^>]+>)|([^<]+)/g, function (m, tag, txt) { return tag ? tag : txt.replace(re, "<mark>$1</mark>"); });
  }

  function syncUrl() {
    var p = new URLSearchParams();
    if (st.q) p.set("q", st.q);
    if (st.type !== "all") p.set("type", st.type);
    if (st.topic !== "all") p.set("topic", st.topic);
    var qs = p.toString();
    history.replaceState(null, "", location.pathname + (qs ? "?" + qs : "") + location.hash);
  }

  function render() {
    $$("[data-type]").forEach(function (b) { if (b.tagName === "BUTTON") b.classList.toggle("on", b.dataset.type === st.type); });
    $$("[data-topic]").forEach(function (b) { if (b.tagName === "BUTTON") b.classList.toggle("on", b.dataset.topic === st.topic); });
    var q = st.q.toLowerCase(), shown = 0;
    items.forEach(function (li) {
      var ok = (st.type === "all" || li.dataset.type === st.type) &&
               (st.topic === "all" || (" " + li.dataset.topics + " ").indexOf(" " + st.topic + " ") >= 0) &&
               (!q || li._text.indexOf(q) >= 0);
      li.classList.toggle("hide", !ok);
      li._parts.forEach(function (p) { p.el.innerHTML = ok ? highlight(p.html, st.q) : p.html; });
      if (ok) shown++;
    });
    groups.forEach(function (g) {
      var n = g.querySelectorAll(".pub:not(.hide)").length;
      g.classList.toggle("hide", n === 0);
      g.querySelector(".count").textContent = n + (n === 1 ? " item" : " items");
    });
    count.textContent = shown === total ? count.dataset.default : "Showing " + shown + " of " + total + " items";
    empty.hidden = shown !== 0;
    syncUrl();
  }

  input.addEventListener("input", function () { st.q = input.value.trim(); render(); });
  $$("button[data-type]").forEach(function (b) { b.addEventListener("click", function () { st.type = b.dataset.type; render(); }); });
  $$("button[data-topic]").forEach(function (b) { b.addEventListener("click", function () { st.topic = b.dataset.topic; render(); }); });
  $("#pub-reset").addEventListener("click", function (e) {
    e.preventDefault(); st = { q: "", type: "all", topic: "all" }; input.value = ""; render();
  });

  // Year jumps: scroll below the sticky toolbar.
  $$("[data-jump]").forEach(function (a) {
    a.addEventListener("click", function (e) {
      e.preventDefault();
      var g = document.querySelector('.yeargroup[data-year="' + a.dataset.jump + '"]');
      if (!g || g.classList.contains("hide")) { toast("No items from " + a.dataset.jump + " match the current filters"); return; }
      var offset = window.innerWidth > 700 ? $(".toolbar").offsetHeight + 70 : 20;
      window.scrollTo({ top: g.getBoundingClientRect().top + window.scrollY - offset, behavior: "smooth" });
    });
  });

  // BibTeX: copy the entry to the clipboard.
  list.addEventListener("click", function (e) {
    var b = e.target.closest("[data-cite]");
    if (!b) return;
    var txt = b.dataset.cite;
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(txt).then(function () { toast("BibTeX copied"); }, function () { window.prompt("Copy BibTeX:", txt); });
    } else {
      window.prompt("Copy BibTeX:", txt);
    }
  });

  render();
})();
