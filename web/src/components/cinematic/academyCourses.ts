export type AcademyCourse = {
  id: string;
  title: string;
  level: string;
  blurb: string;
  /** Accent for title / panel so course changes are obvious */
  color: string;
  soft: string;
};

/** TechRen Academy curriculum — shown one-by-one while the section is pinned. */
export const academyCourses: AcademyCourse[] = [
  {
    id: "python-turtle",
    title: "Python (Turtle)",
    level: "Beginner · Kids & teens",
    color: "#4ADE80",
    soft: "rgba(74, 222, 128, 0.14)",
    blurb:
      "Draw, play, and think like a coder. Turtle graphics make Python feel visual from day one — loops, functions, and creativity without the scare.",
  },
  {
    id: "scratch",
    title: "Scratch",
    level: "Beginner · Block coding",
    color: "#FBBF24",
    soft: "rgba(251, 191, 36, 0.14)",
    blurb:
      "Drag-and-drop storytelling and games. Perfect first step into logic, events, and problem-solving before typing real code.",
  },
  {
    id: "arduino",
    title: "Arduino",
    level: "Maker · Hardware",
    color: "#38BDF8",
    soft: "rgba(56, 189, 248, 0.14)",
    blurb:
      "Lights, sensors, motors — build real gadgets. Students connect code to the physical world and learn electronics basics hands-on.",
  },
  {
    id: "html",
    title: "HTML",
    level: "Web · Foundations",
    color: "#FB923C",
    soft: "rgba(251, 146, 60, 0.14)",
    blurb:
      "Structure every webpage. Headings, links, images, and semantic layout — the skeleton of everything on the internet.",
  },
  {
    id: "css",
    title: "CSS",
    level: "Web · Style",
    color: "#60A5FA",
    soft: "rgba(96, 165, 250, 0.14)",
    blurb:
      "Make it look sharp. Colors, layouts, responsive design, and polish so sites feel modern on phone and desktop.",
  },
  {
    id: "sass",
    title: "Sass",
    level: "Web · Advanced style",
    color: "#F472B6",
    soft: "rgba(244, 114, 182, 0.14)",
    blurb:
      "Write CSS smarter: variables, nesting, and reusable mixins. Cleaner stylesheets for bigger projects.",
  },
  {
    id: "bootstrap",
    title: "Bootstrap",
    level: "Web · Rapid UI",
    color: "#A78BFA",
    soft: "rgba(167, 139, 250, 0.14)",
    blurb:
      "Ship layouts faster with a battle-tested grid and components. Great for dashboards and school project UIs.",
  },
  {
    id: "javascript",
    title: "JavaScript",
    level: "Web · Interactivity",
    color: "#FACC15",
    soft: "rgba(250, 204, 21, 0.16)",
    blurb:
      "Bring pages alive — clicks, forms, APIs, and logic. The language of the browser and the gateway to modern apps.",
  },
  {
    id: "react",
    title: "React.js",
    level: "Frontend · Components",
    color: "#22D3EE",
    soft: "rgba(34, 211, 238, 0.14)",
    blurb:
      "Build real interfaces with components, state, and hooks. How modern products like TechRen EDU are structured.",
  },
  {
    id: "node",
    title: "Node.js",
    level: "Backend · Servers",
    color: "#86EFAC",
    soft: "rgba(134, 239, 172, 0.14)",
    blurb:
      "JavaScript on the server. APIs, auth, and data flow — the engine behind apps that save and sync student work.",
  },
  {
    id: "python-advanced",
    title: "Python (Advanced)",
    level: "Intermediate · Pro code",
    color: "#34D399",
    soft: "rgba(52, 211, 153, 0.14)",
    blurb:
      "Beyond Turtle: data structures, OOP, files, and real scripts. Prep for automation, AI basics, and backend work.",
  },
  {
    id: "game-dev",
    title: "Game Dev",
    level: "Creative · Projects",
    color: "#E879F9",
    soft: "rgba(232, 121, 249, 0.14)",
    blurb:
      "Design playable worlds — mechanics, levels, and polish. Students ship small games and learn systems thinking.",
  },
  {
    id: "mongodb",
    title: "MongoDB",
    level: "Data · NoSQL",
    color: "#4ADE80",
    soft: "rgba(74, 222, 128, 0.12)",
    blurb:
      "Store flexible documents at scale. How modern apps keep users, progress, and campus data organized.",
  },
  {
    id: "fastapi",
    title: "FastAPI",
    level: "Backend · Python APIs",
    color: "#2DD4BF",
    soft: "rgba(45, 212, 191, 0.14)",
    blurb:
      "Fast, typed Python APIs. Build endpoints that power mobile/web apps with clean docs and modern patterns.",
  },
  {
    id: "english",
    title: "English",
    level: "Language · Campus",
    color: "#F87171",
    soft: "rgba(248, 113, 113, 0.14)",
    blurb:
      "Words, sentences, and listening for real school progress — the language track TechRen EDU is built around.",
  },
  {
    id: "computer-science",
    title: "Computer Science",
    level: "Foundations · Theory",
    color: "#818CF8",
    soft: "rgba(129, 140, 248, 0.16)",
    blurb:
      "How computers think: algorithms, binary, networks, and problem-solving. The big picture behind every stack.",
  },
];
