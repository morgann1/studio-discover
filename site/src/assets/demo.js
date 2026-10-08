// Plays each demo stage on a loop while it is in view. The script only sets the widget's width
// and the data attributes that CSS uses to pick a view and send a wave through it. Without it, or
// with reduced motion, the HTML stays on the final frame.
const narrow = matchMedia("(max-width: 719px)");

function animate(stage) {
  const demo = stage.querySelector(".demo");
  const win = demo.querySelector(".win");
  const cursor = demo.querySelector(".cursor");
  const caption = stage.querySelector(".caption");

  const set = (name, value) =>
    value === undefined
      ? demo.removeAttribute(`data-${name}`)
      : demo.setAttribute(`data-${name}`, value);
  const resize = (width) => win.style.setProperty("--w", `${width}px`);
  const wave = () => set("wave", demo.dataset.wave === "1" ? "0" : "1");
  // The pointer's tip sits 4px in and 2px down from its corner.
  const moveTo = ([x, y]) => (cursor.style.transform = `translate(${x - 4}px, ${y - 2}px)`);

  // Each child of a list is a line, numbered so the wave reaches it in turn.
  for (const list of demo.querySelectorAll(".side, .view, .menu")) {
    [...list.children].forEach((line, i) => {
      line.classList.add("line");
      line.style.setProperty("--i", i);
    });
  }

  // The centre of an element inside the widget, in the demo's own unscaled pixels.
  function centerOf(selector) {
    const box = demo.getBoundingClientRect();
    const scale = box.width / demo.offsetWidth;
    const rect = demo.querySelector(selector).getBoundingClientRect();
    return [
      (rect.left + rect.width / 2 - box.left) / scale,
      (rect.top + rect.height / 2 - box.top) / scale,
    ];
  }

  // The window is centred, so its right edge moves half as far as its width changes.
  const edgeOf = (width) => [(demo.offsetWidth + width) / 2 - 3, 300];

  // A click is a press and a release 100ms apart. `then` runs on release.
  const click = (then) => [
    [600, () => set("cursor", "click")],
    [100, () => (set("cursor", "shown"), then())],
  ];

  // The pointer goes to the window's edge `lead` ms after the previous step, then drags it. The
  // wave goes through as the layout crosses the breakpoint.
  const drag = (lead, from, to) => [
    [lead, () => moveTo(edgeOf(from))],
    [700, () => (set("dragging", ""), resize(to), moveTo(edgeOf(to)))],
    [400, wave],
    [1300, () => set("dragging")],
  ];

  // Each scene is a caption and its steps, as [milliseconds after the previous step, change].
  // Wide scenes resize the widget, so the docked script on narrow screens skips them.
  const scenes = [
    { caption: "Browse Wally, pesde, and Nevermore from one place.", steps: [[0, () => {}]] },
    {
      caption: "Docked, the sidebar folds into the title.",
      wide: true,
      steps: [[2500, () => set("cursor", "shown")], ...drag(500, 960, 342)],
    },
    {
      caption: "Switch locations from the title.",
      steps: [
        [700, () => (set("cursor", "shown"), moveTo(centerOf(".title")))],
        ...click(() => set("menu", "")),
      ],
    },
    {
      caption: "See what's installed in this place.",
      steps: [
        [800, () => moveTo(centerOf(".menu .loc"))],
        ...click(() => (set("menu"), set("location", "installed"))),
      ],
    },
    {
      caption: "Update everything at once.",
      steps: [
        [1300, () => moveTo(centerOf(".alert .button"))],
        ...click(() => set("progress", "running")),
        [2400, () => (set("progress", "done"), set("notice", ""), wave())],
        [300, () => moveTo([demo.offsetWidth * 0.75, 400])],
      ],
    },
    {
      caption: "It follows Studio's theme.",
      steps: [
        [1500, () => set("theme", "light")],
        [2000, () => set("notice")],
      ],
    },
    {
      caption: "Expanded, everything gets its own column.",
      wide: true,
      steps: drag(2000, 342, 960),
    },
    {
      caption: "Every install can be undone with Ctrl+Z.",
      steps: [
        [700, () => set("cursor")],
        [3000, () => {}],
      ],
    },
  ];

  // The first frame. The first play cuts to it; a loop fades the theme back.
  function reset(instant) {
    if (instant) set("instant", "");
    set("theme", "dark");
    set("location", "wally");
    set("progress", "idle");
    set("notice");
    set("menu");
    set("dragging");
    set("cursor");
    resize(narrow.matches ? 342 : 960);
    moveTo([demo.offsetWidth * 0.8, 440]);
    // Reading layout here makes the browser apply the reset before transitions come back.
    demo.getBoundingClientRect();
    set("instant");
    wave();
  }

  // A flat list of [time, change], with each scene's caption set on its first step.
  function timeline() {
    let time = 0;
    return scenes
      .filter((scene) => !(scene.wide && narrow.matches))
      .flatMap((scene) =>
        scene.steps.map(([wait, step], i) => [
          (time += wait),
          i === 0 ? () => ((caption.textContent = scene.caption), step()) : step,
        ]),
      );
  }

  let plan = [];
  let next = 0;
  let clock = 0;
  let resumedAt = 0;
  let running = false;
  let inView = false;
  let timer;

  function play(instant) {
    reset(instant);
    plan = timeline();
    next = 0;
    clock = 0;
    resumedAt = performance.now();
    run();
  }

  function run() {
    if (next === plan.length) {
      play(false);
      return;
    }

    const [time, step] = plan[next];
    timer = setTimeout(
      () => {
        clock = time;
        resumedAt = performance.now();
        next += 1;
        step();
        run();
      },
      time - clock - (performance.now() - resumedAt),
    );
  }

  // The loop holds its place while the stage is out of view or the tab is hidden.
  function update() {
    const shouldRun = inView && !document.hidden;
    if (shouldRun === running) return;

    running = shouldRun;
    if (!running) {
      clearTimeout(timer);
      clock += performance.now() - resumedAt;
    } else if (plan.length === 0) {
      play(true);
    } else {
      resumedAt = performance.now();
      run();
    }
  }

  document.addEventListener("visibilitychange", update);
  new IntersectionObserver(
    (entries) => {
      inView = entries[entries.length - 1].isIntersecting;
      update();
    },
    { threshold: 0.5 },
  ).observe(stage.querySelector(".frame"));
}

if (!matchMedia("(prefers-reduced-motion: reduce)").matches) {
  document.querySelectorAll(".stage").forEach(animate);
}
