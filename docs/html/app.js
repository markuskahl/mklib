/**
 * mklib Documentation Web Application
 * Single Page App Navigation, Search, Multilingual (DE/EN), Theme Switching & Interactive A* Simulator
 */

document.addEventListener('DOMContentLoaded', () => {
  initLanguage();
  initNavigation();
  initTheme();
  initSearch();
  initCodeCopy();
  initAStarSimulator();
});

/* ==========================================================================
   Language Switching (i18n: DE / EN)
   ========================================================================== */
let currentLang = 'de';

const i18nStrings = {
  de: {
    title: 'mklib — Vollständige Dokumentation & API-Referenz',
    searchPlaceholder: 'Klasse, Methode oder Feld suchen...',
    themeToggle: 'Thema wechseln',
    mobileMenu: 'Menü öffnen',
    copied: 'Kopiert!',
    copy: 'Kopieren',
    navIntro: 'Einführung',
    navModules: 'Kern-Module & Klassen',
    navOverview: 'Übersicht & API-Matrix',
    navGettingStarted: 'Schnellstart',
    navLdtkGuide: 'LDtk Guide & Felder',
    navState: 'State Management',
    navLayers: 'Layer System',
    navEntities: 'Entities & Sprites',
    navAnimation: 'Animationen & Makros',
    navPhysics: 'Physik & Sensoren',
    navPathfinding: 'Pathfinding & A*',
    navLighting: 'GPU Lighting System',
    navEffects: 'Shader & Post-Processing',
    navToolsMath: 'Tools & Mathematik',
    goalChar: 'Z'
  },
  en: {
    title: 'mklib — Complete Documentation & API Reference',
    searchPlaceholder: 'Search class, method, or field...',
    themeToggle: 'Toggle theme',
    mobileMenu: 'Open menu',
    copied: 'Copied!',
    copy: 'Copy',
    navIntro: 'Introduction',
    navModules: 'Core Modules & Classes',
    navOverview: 'Overview & API Matrix',
    navGettingStarted: 'Quick Start',
    navLdtkGuide: 'LDtk Guide & Fields',
    navState: 'State Management',
    navLayers: 'Layer System',
    navEntities: 'Entities & Sprites',
    navAnimation: 'Animations & Macros',
    navPhysics: 'Physics & Sensors',
    navPathfinding: 'Pathfinding & A*',
    navLighting: 'GPU Lighting System',
    navEffects: 'Shaders & Post-Processing',
    navToolsMath: 'Tools & Mathematics',
    goalChar: 'G'
  }
};

function initLanguage() {
  const savedLang = localStorage.getItem('mklib-lang') || 'de';
  setLanguage(savedLang);

  document.querySelectorAll('.lang-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      const lang = btn.getAttribute('data-set-lang');
      if (lang) {
        setLanguage(lang);
      }
    });
  });
}

function setLanguage(lang) {
  currentLang = lang === 'en' ? 'en' : 'de';
  document.documentElement.setAttribute('lang', currentLang);
  localStorage.setItem('mklib-lang', currentLang);

  // Update button active state
  document.querySelectorAll('.lang-btn').forEach(btn => {
    if (btn.getAttribute('data-set-lang') === currentLang) {
      btn.classList.add('active');
    } else {
      btn.classList.remove('active');
    }
  });

  const t = i18nStrings[currentLang];
  document.title = t.title;

  const searchInput = document.getElementById('docs-search');
  if (searchInput) {
    searchInput.placeholder = t.searchPlaceholder;
  }

  const themeToggle = document.getElementById('theme-toggle');
  if (themeToggle) {
    themeToggle.title = t.themeToggle;
  }

  const mobileBtn = document.querySelector('.mobile-menu-btn');
  if (mobileBtn) {
    mobileBtn.setAttribute('aria-label', t.mobileMenu);
  }

  // Update data-de / data-en elements
  document.querySelectorAll('[data-de][data-en]').forEach(el => {
    const txt = el.getAttribute(`data-${currentLang}`);
    if (txt) {
      if (el.tagName === 'INPUT') el.placeholder = txt;
      else el.textContent = txt;
    }
  });

  // Re-render A* simulator if initialized
  if (window.renderAStarSimulator) {
    window.renderAStarSimulator();
  }
}

/* ==========================================================================
   Navigation & Multi-Page Link Support
   ========================================================================== */
function initNavigation() {
  const sidebar = document.querySelector('.sidebar');
  const mobileBtn = document.querySelector('.mobile-menu-btn');

  // Determine current page filename (e.g. "state.html" or "index.html")
  const path = window.location.pathname;
  let currentPage = path.substring(path.lastIndexOf('/') + 1);
  if (!currentPage || currentPage === '') currentPage = 'index.html';

  // Highlight active sidebar navigation item
  document.querySelectorAll('.nav-item').forEach(item => {
    const link = item.querySelector('a');
    if (!link) return;
    const href = link.getAttribute('href') || '';
    if (href === currentPage || (currentPage === 'index.html' && (href === './' || href === 'index.html'))) {
      item.classList.add('active');
    } else {
      item.classList.remove('active');
    }
  });

  // Mobile menu toggle
  if (mobileBtn && sidebar) {
    mobileBtn.addEventListener('click', () => {
      sidebar.classList.toggle('open');
    });

    // Close on click outside on mobile
    document.addEventListener('click', (e) => {
      if (sidebar.classList.contains('open') && !sidebar.contains(e.target) && !mobileBtn.contains(e.target)) {
        sidebar.classList.remove('open');
      }
    });
  }
}

/* ==========================================================================
   Theme Switching (Dark / Light)
   ========================================================================== */
function initTheme() {
  const themeToggle = document.getElementById('theme-toggle');
  const savedTheme = localStorage.getItem('mklib-theme') || 'dark';

  document.documentElement.setAttribute('data-theme', savedTheme);
  updateThemeIcon(savedTheme);

  if (themeToggle) {
    themeToggle.addEventListener('click', () => {
      const currentTheme = document.documentElement.getAttribute('data-theme');
      const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
      document.documentElement.setAttribute('data-theme', newTheme);
      localStorage.setItem('mklib-theme', newTheme);
      updateThemeIcon(newTheme);
    });
  }
}

function updateThemeIcon(theme) {
  const themeToggle = document.getElementById('theme-toggle');
  if (!themeToggle) return;
  themeToggle.innerHTML = theme === 'dark'
    ? '<span style="font-size: 1.1rem;">☀️</span>'
    : '<span style="font-size: 1.1rem;">🌙</span>';
}

/* ==========================================================================
   Code Copy Button
   ========================================================================== */
function initCodeCopy() {
  document.querySelectorAll('pre code').forEach((codeBlock) => {
    const pre = codeBlock.parentElement;
    if (!pre || pre.querySelector('.copy-btn')) return;

    const copyBtn = document.createElement('button');
    copyBtn.className = 'copy-btn';
    copyBtn.textContent = i18nStrings[currentLang]?.copy || 'Kopieren';
    copyBtn.title = 'In die Zwischenablage kopieren';

    copyBtn.addEventListener('click', async () => {
      const code = codeBlock.innerText;
      try {
        await navigator.clipboard.writeText(code);
        copyBtn.textContent = i18nStrings[currentLang]?.copied || 'Kopiert!';
        copyBtn.classList.add('copied');
        setTimeout(() => {
          copyBtn.textContent = i18nStrings[currentLang]?.copy || 'Kopieren';
          copyBtn.classList.remove('copied');
        }, 2000);
      } catch (err) {
        console.error('Failed to copy text: ', err);
      }
    });

    pre.style.position = 'relative';
    pre.appendChild(copyBtn);
  });
}

/* ==========================================================================
   Search Functionality (Global Autocomplete & In-Page Table Filter)
   ========================================================================== */
const SEARCH_INDEX = [
  { name: 'State<TLevel>', type: 'Klasse', module: 'mklib.state', url: 'state.html', desc: 'Typisierter LDtk- & Nape-Basis-State mit automatischem Lifecycle' },
  { name: 'TileLayer', type: 'Klasse', module: 'mklib.layer', url: 'layers.html', desc: 'Performante Kachelebenen-Darstellung aus LDtk' },
  { name: 'EntityLayer', type: 'Klasse', module: 'mklib.layer', url: 'layers.html', desc: 'Dynamische Reflection-Instanziierung aller Level-Entities' },
  { name: 'EntityLayerSource', type: 'Typedef', module: 'mklib.layer', url: 'layers.html', desc: 'Typisierter Entity-Layer-Provider aus LDtk-Generaten' },
  { name: 'EntitySprite', type: 'Klasse', module: 'mklib.entity', url: 'entities.html', desc: 'Erweitertes FlxSprite mit LDtk Custom-Field-Zugriff' },
  { name: 'EntityNapeSprite', type: 'Klasse', module: 'mklib.entity', url: 'entities.html', desc: 'EntitySprite mit integriertem Nape-Physikkörper und Sensor' },
  { name: 'SaveManager', type: 'Klasse', module: 'mklib.save', url: 'save.html', desc: 'Zentrales Speichersystem mit Checkpoints, Spielzeit und Level-Snapshots' },
  { name: 'ISaveable', type: 'Interface', module: 'mklib.save', url: 'save.html', desc: 'Schnittstelle für automatische Entity-Persistenz' },
  { name: 'CheckpointMeta', type: 'Typedef', module: 'mklib.save', url: 'save.html', desc: 'Metadaten für Spielstände und Checkpoint-Slots' },
  { name: 'AnimationBuilder', type: 'Makro', module: 'mklib.macro', url: 'animation.html', desc: 'Compile-Time-Makro zur automatischen Animation-Datenbankerzeugung' },
  { name: 'FrameConfig', type: 'Typedef', module: 'mklib.animation', url: 'animation.html', desc: 'Konfiguration für Spritesheet-Frames und Animationen' },
  { name: 'Listener', type: 'Klasse', module: 'mklib.physic', url: 'physics.html', desc: '13 spezialisierte Nape Kollisions- und Sensor-Listener' },
  { name: 'ShapeBuilder', type: 'Klasse', module: 'mklib.physic', url: 'physics.html', desc: 'Generiert Nape-Polygon-Shapes direkt aus Bitmap/Spritesheets' },
  { name: 'Tags', type: 'Klasse', module: 'mklib.tools', url: 'physics.html', desc: 'String-basierte Nape CbType-Verwaltung' },
  { name: 'NavGrid', type: 'Klasse', module: 'mklib.path', url: 'pathfinding.html', desc: '2D-Wegfindungsraster mit Koordinatenumrechnung und Hindernissen' },
  { name: 'NavGridBuilder', type: 'Klasse', module: 'mklib.path', url: 'pathfinding.html', desc: 'Baut automatisch NavGrids aus LDtk IntGrid oder Tiles' },
  { name: 'AStar', type: 'Klasse', module: 'mklib.path', url: 'pathfinding.html', desc: 'High-Performance 2D A*-Algorithmus mit Pfadglättung' },
  { name: 'GridPoint', type: 'Klasse', module: 'mklib.path', url: 'pathfinding.html', desc: '2D-Rasterpunkt mit Koordinatenvergleich' },
  { name: 'LightingSystem', type: 'Klasse', module: 'mklib.light', url: 'lighting.html', desc: 'GPU-Shader Multi-Light-System mit weichen Schatten und Occludern' },
  { name: 'Light', type: 'Klasse', module: 'mklib.light', url: 'lighting.html', desc: 'Dynamische GPU-Lichtquelle mit Zielverfolgung und Frustum-Culling' },
  { name: 'SpotLight', type: 'Klasse', module: 'mklib.light', url: 'lighting.html', desc: 'Gerichteter Scheinwerfer mit Abstrahlwinkel und Fokus' },
  { name: 'TorchLight', type: 'Klasse', module: 'mklib.light', url: 'lighting.html', desc: 'Flackernde Fackellichtquelle mit Multi-Harmonik' },
  { name: 'GlowLight', type: 'Klasse', module: 'mklib.light', url: 'lighting.html', desc: 'Pulsierendes Aura- und Kristalllicht' },
  { name: 'PointLight', type: 'Klasse', module: 'mklib.light', url: 'lighting.html', desc: '360-Grad Rundumlichtquelle mit Kernradius' },
  { name: 'DirectionalLight', type: 'Klasse', module: 'mklib.light', url: 'lighting.html', desc: 'Globales Sonnen-/Mond- und Umgebungslicht' },
  { name: 'CrtShader', type: 'Klasse', module: 'mklib.effect', url: 'effects.html', desc: 'Retro-Arcade CRT Post-Processing Shader mit Scanlines & Krümmung' },
  { name: 'HazardLiquidShader', type: 'Klasse', module: 'mklib.effect', url: 'effects.html', desc: 'Prozeduraler GPU-Flüssigkeitsshader für Lava, Säure und Schleim' },
  { name: 'HazardLiquidPlane', type: 'Klasse', module: 'mklib.effect', url: 'effects.html', desc: 'FlxSprite-Flüssigkeitsebene mit Schaden über Zeit' },
  { name: 'HazardLiquidType', type: 'Enum', module: 'mklib.effect', url: 'effects.html', desc: 'Vordefinierte Flüssigkeitstypen: LAVA, ACID_SLIME, TOXIC_WATER' },
  { name: 'WaterReflectionShader', type: 'Klasse', module: 'mklib.effect', url: 'effects.html', desc: 'Echtzeit-Wasserspiegelung mit Wellenverzerrung und Gischt' },
  { name: 'WaterReflectionPlane', type: 'Klasse', module: 'mklib.effect', url: 'effects.html', desc: 'Spiegelungsebene für Wasserflächen im Level' },
  { name: 'EntityWaterReflection', type: 'Klasse', module: 'mklib.effect', url: 'effects.html', desc: 'Dynamische Wasserspiegelung für einzelne Spielfiguren' },
  { name: 'AspectRatio', type: 'Klasse', module: 'mklib.tools', url: 'tools-math.html', desc: 'Dynamische Viewport- und Seitenverhältnisskalierung' },
  { name: 'GamepadHelper', type: 'Klasse', module: 'mklib.tools', url: 'tools-math.html', desc: 'Controller-Vibrations- und Rumble-Steuerung' },
  { name: 'MathTool', type: 'Klasse', module: 'mklib.math', url: 'tools-math.html', desc: 'Mathematische Hilfsfunktionen (z. B. floatFix)' },
  { name: 'LDtk Guide & Workflow', type: 'Thema', module: 'ldtk', url: 'ldtk-guide.html', desc: 'LDtk-Editor Einrichtung, Custom Fields, Enums und Layer' },
  { name: 'Schnellstart & Installation', type: 'Thema', module: 'setup', url: 'getting-started.html', desc: 'Project.xml, HaxeFlixel-Einbindung und Bootstrapping' },
  { name: 'Übersicht & API-Matrix', type: 'Thema', module: 'mklib', url: 'index.html', desc: 'Vollständige Matrix aller 32 Klassen und Module' }
];

function initSearch() {
  const searchInput = document.getElementById('docs-search');
  const searchContainer = document.querySelector('.header-search');
  if (!searchInput || !searchContainer) return;

  // Create dropdown element
  let dropdown = searchContainer.querySelector('.search-dropdown');
  if (!dropdown) {
    dropdown = document.createElement('div');
    dropdown.className = 'search-dropdown';
    searchContainer.appendChild(dropdown);
  }

  let activeIndex = -1;

  function renderDropdown(matches) {
    if (matches.length === 0) {
      dropdown.innerHTML = `<div class="search-no-results">${currentLang === 'en' ? 'No matching classes or topics found' : 'Keine passenden Klassen oder Themen gefunden'}</div>`;
      dropdown.classList.add('open');
      activeIndex = -1;
      return;
    }

    dropdown.innerHTML = matches.map((item, idx) => `
      <a href="${item.url}" class="search-item ${idx === activeIndex ? 'active' : ''}" data-idx="${idx}">
        <div class="search-item-top">
          <span class="search-item-name">${item.name}</span>
          <span class="search-item-badge">${item.type}</span>
        </div>
        <div class="search-item-desc">${item.desc}</div>
      </a>
    `).join('');
    dropdown.classList.add('open');
  }

  function closeDropdown() {
    dropdown.classList.remove('open');
    dropdown.innerHTML = '';
    activeIndex = -1;
  }

  searchInput.addEventListener('input', (e) => {
    const query = e.target.value.toLowerCase().trim();

    if (!query) {
      closeDropdown();
      // Reset table row filter
      document.querySelectorAll('.api-table tbody tr').forEach(row => row.style.display = '');
      return;
    }

    // Filter index
    const matches = SEARCH_INDEX.filter(item =>
      item.name.toLowerCase().includes(query) ||
      item.module.toLowerCase().includes(query) ||
      item.desc.toLowerCase().includes(query)
    ).slice(0, 8);

    renderDropdown(matches);

    // Also filter tables on current page
    document.querySelectorAll('.api-table tbody tr').forEach(row => {
      const rowText = row.textContent.toLowerCase();
      row.style.display = rowText.includes(query) ? '' : 'none';
    });
  });

  searchInput.addEventListener('keydown', (e) => {
    const items = dropdown.querySelectorAll('.search-item');
    if (!dropdown.classList.contains('open') || items.length === 0) return;

    if (e.key === 'ArrowDown') {
      e.preventDefault();
      activeIndex = (activeIndex + 1) % items.length;
      updateActiveItem(items);
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      activeIndex = (activeIndex - 1 + items.length) % items.length;
      updateActiveItem(items);
    } else if (e.key === 'Enter') {
      e.preventDefault();
      if (activeIndex >= 0 && activeIndex < items.length) {
        items[activeIndex].click();
      } else if (items.length > 0) {
        items[0].click();
      }
    } else if (e.key === 'Escape') {
      closeDropdown();
    }
  });

  function updateActiveItem(items) {
    items.forEach((item, idx) => {
      if (idx === activeIndex) {
        item.classList.add('active');
        item.scrollIntoView({ block: 'nearest' });
      } else {
        item.classList.remove('active');
      }
    });
  }

  // Close when clicking outside
  document.addEventListener('click', (e) => {
    if (!searchContainer.contains(e.target)) {
      closeDropdown();
    }
  });
}

/* ==========================================================================
   Interactive A* Pathfinding Visualizer
   ========================================================================== */
function initAStarSimulator() {
  const canvas = document.getElementById('astar-canvas');
  if (!canvas) return;

  const ctx = canvas.getContext('2d');
  const cols = 24;
  const rows = 14;
  const cellSize = 24;

  canvas.width = cols * cellSize;
  canvas.height = rows * cellSize;

  // Grid data: 0 = free, 1 = obstacle
  let grid = Array.from({ length: rows }, () => Array(cols).fill(0));
  let start = { x: 2, y: 7 };
  let goal = { x: 21, y: 7 };
  let path = [];
  let isDragging = false;
  let dragMode = null; // 'draw', 'erase', 'start', 'goal'
  let allowDiagonal = false;
  let agentSpan = 1;

  // Controls
  const diagonalCheckbox = document.getElementById('sim-diagonal');
  const spanSelect = document.getElementById('sim-span');
  const clearBtn = document.getElementById('sim-clear');
  const mazeBtn = document.getElementById('sim-maze');

  if (diagonalCheckbox) {
    diagonalCheckbox.addEventListener('change', (e) => {
      allowDiagonal = e.target.checked;
      computePath();
      render();
    });
  }

  if (spanSelect) {
    spanSelect.addEventListener('change', (e) => {
      agentSpan = parseInt(e.target.value, 10) || 1;
      computePath();
      render();
    });
  }

  if (clearBtn) {
    clearBtn.addEventListener('click', () => {
      grid = Array.from({ length: rows }, () => Array(cols).fill(0));
      computePath();
      render();
    });
  }

  if (mazeBtn) {
    mazeBtn.addEventListener('click', () => {
      generateRandomMaze();
      computePath();
      render();
    });
  }

  function getCellCoords(e) {
    const rect = canvas.getBoundingClientRect();
    const scaleX = canvas.width / rect.width;
    const scaleY = canvas.height / rect.height;
    const x = Math.floor((e.clientX - rect.left) * scaleX / cellSize);
    const y = Math.floor((e.clientY - rect.top) * scaleY / cellSize);
    return {
      x: Math.max(0, Math.min(cols - 1, x)),
      y: Math.max(0, Math.min(rows - 1, y))
    };
  }

  canvas.addEventListener('mousedown', (e) => {
    isDragging = true;
    const cell = getCellCoords(e);

    if (cell.x >= start.x && cell.x < start.x + agentSpan && cell.y >= start.y && cell.y < start.y + agentSpan) {
      dragMode = 'start';
    } else if (cell.x >= goal.x && cell.x < goal.x + agentSpan && cell.y >= goal.y && cell.y < goal.y + agentSpan) {
      dragMode = 'goal';
    } else {
      dragMode = grid[cell.y][cell.x] === 1 ? 'erase' : 'draw';
      grid[cell.y][cell.x] = dragMode === 'draw' ? 1 : 0;
      computePath();
      render();
    }
  });

  window.addEventListener('mousemove', (e) => {
    if (!isDragging) return;
    const cell = getCellCoords(e);

    if (dragMode === 'start') {
      if (cell.x + agentSpan <= cols && cell.y + agentSpan <= rows) {
        start = { x: cell.x, y: cell.y };
        computePath();
        render();
      }
    } else if (dragMode === 'goal') {
      if (cell.x + agentSpan <= cols && cell.y + agentSpan <= rows) {
        goal = { x: cell.x, y: cell.y };
        computePath();
        render();
      }
    } else if (dragMode === 'draw' || dragMode === 'erase') {
      grid[cell.y][cell.x] = dragMode === 'draw' ? 1 : 0;
      computePath();
      render();
    }
  });

  window.addEventListener('mouseup', () => {
    isDragging = false;
    dragMode = null;
  });

  function generateRandomMaze() {
    grid = Array.from({ length: rows }, () => Array(cols).fill(0));
    for (let r = 0; r < rows; r++) {
      for (let c = 0; c < cols; c++) {
        if (Math.random() < 0.28) {
          grid[r][c] = 1;
        }
      }
    }
    // Clear start and goal areas
    for (let dy = 0; dy < 3; dy++) {
      for (let dx = 0; dx < 3; dx++) {
        if (start.y + dy < rows && start.x + dx < cols) grid[start.y + dy][start.x + dx] = 0;
        if (goal.y + dy < rows && goal.x + dx < cols) grid[goal.y + dy][goal.x + dx] = 0;
      }
    }
  }

  function computePath() {
    path = [];
    const SQRT2 = 1.41421356237;

    function isAreaWalkable(cx, cy, span) {
      if (cx < 0 || cy < 0 || cx + span > cols || cy + span > rows) return false;
      for (let dy = 0; dy < span; dy++) {
        for (let dx = 0; dx < span; dx++) {
          if (grid[cy + dy][cx + dx] !== 0) return false;
        }
      }
      return true;
    }

    if (!isAreaWalkable(goal.x, goal.y, agentSpan) || !isAreaWalkable(start.x, start.y, agentSpan)) {
      return;
    }

    if (start.x === goal.x && start.y === goal.y) {
      path = [{ x: start.x, y: start.y }];
      return;
    }

    const openList = [];
    const closedSet = new Set();
    const nodeMap = new Map();

    function getNode(x, y) {
      const key = `${x},${y}`;
      if (!nodeMap.has(key)) {
        nodeMap.set(key, { x, y, g: Infinity, h: 0, f: Infinity, parent: null });
      }
      return nodeMap.get(key);
    }

    function heuristic(x1, y1, x2, y2, diag) {
      const dx = Math.abs(x1 - x2);
      const dy = Math.abs(y1 - y2);
      if (!diag) return dx + dy;
      return dx > dy ? SQRT2 * dy + (dx - dy) : SQRT2 * dx + (dy - dx);
    }

    const startNode = getNode(start.x, start.y);
    startNode.g = 0;
    startNode.h = heuristic(start.x, start.y, goal.x, goal.y, allowDiagonal);
    startNode.f = startNode.h;
    openList.push(startNode);

    const neighbors4 = [
      { dx: 0, dy: -1, cost: 1.0 },
      { dx: 0, dy: 1, cost: 1.0 },
      { dx: -1, dy: 0, cost: 1.0 },
      { dx: 1, dy: 0, cost: 1.0 }
    ];

    const neighborsDiag = [
      { dx: -1, dy: -1, cost: SQRT2 },
      { dx: 1, dy: -1, cost: SQRT2 },
      { dx: -1, dy: 1, cost: SQRT2 },
      { dx: 1, dy: 1, cost: SQRT2 }
    ];

    while (openList.length > 0) {
      // Find node with lowest f
      let lowestIdx = 0;
      for (let i = 1; i < openList.length; i++) {
        if (openList[i].f < openList[lowestIdx].f) {
          lowestIdx = i;
        }
      }

      const current = openList.splice(lowestIdx, 1)[0];
      const currentKey = `${current.x},${current.y}`;
      closedSet.add(currentKey);

      if (current.x === goal.x && current.y === goal.y) {
        // Reconstruct path
        let curr = current;
        while (curr) {
          path.unshift({ x: curr.x, y: curr.y });
          curr = curr.parent;
        }
        break;
      }

      const neighbors = allowDiagonal ? [...neighbors4, ...neighborsDiag] : neighbors4;

      for (const n of neighbors) {
        const nx = current.x + n.dx;
        const ny = current.y + n.dy;

        if (!isAreaWalkable(nx, ny, agentSpan)) continue;

        // Diagonal corner-cutting check
        if (n.dx !== 0 && n.dy !== 0) {
          if (!isAreaWalkable(current.x + n.dx, current.y, agentSpan) || !isAreaWalkable(current.x, current.y + n.dy, agentSpan)) {
            continue;
          }
        }

        const neighborKey = `${nx},${ny}`;
        if (closedSet.has(neighborKey)) continue;

        const tentativeG = current.g + n.cost;
        const neighbor = getNode(nx, ny);

        let inOpen = openList.includes(neighbor);
        if (!inOpen || tentativeG < neighbor.g) {
          neighbor.parent = current;
          neighbor.g = tentativeG;
          neighbor.h = heuristic(nx, ny, goal.x, goal.y, allowDiagonal);
          neighbor.f = neighbor.g + neighbor.h;

          if (!inOpen) {
            openList.push(neighbor);
          }
        }
      }
    }
  }

  function render() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Draw Grid Lines & Cells
    for (let r = 0; r < rows; r++) {
      for (let c = 0; c < cols; c++) {
        const x = c * cellSize;
        const y = r * cellSize;

        if (grid[r][c] === 1) {
          // Obstacle / Wall
          ctx.fillStyle = '#334155';
          ctx.fillRect(x + 1, y + 1, cellSize - 2, cellSize - 2);
        } else {
          // Empty Cell
          ctx.fillStyle = 'rgba(15, 23, 42, 0.4)';
          ctx.fillRect(x + 1, y + 1, cellSize - 2, cellSize - 2);
        }

        // Grid Border
        ctx.strokeStyle = 'rgba(51, 65, 85, 0.35)';
        ctx.strokeRect(x, y, cellSize, cellSize);
      }
    }

    // Draw Path
    if (path.length > 1) {
      ctx.strokeStyle = '#38bdf8';
      ctx.lineWidth = 4;
      ctx.lineCap = 'round';
      ctx.lineJoin = 'round';
      ctx.shadowColor = 'rgba(56, 189, 248, 0.6)';
      ctx.shadowBlur = 10;

      ctx.beginPath();
      for (let i = 0; i < path.length; i++) {
        const px = (path[i].x + agentSpan * 0.5) * cellSize;
        const py = (path[i].y + agentSpan * 0.5) * cellSize;
        if (i === 0) ctx.moveTo(px, py);
        else ctx.lineTo(px, py);
      }
      ctx.stroke();
      ctx.shadowBlur = 0; // reset

      // Draw Path Waypoints
      ctx.fillStyle = '#818cf8';
      for (let i = 1; i < path.length - 1; i++) {
        const px = (path[i].x + agentSpan * 0.5) * cellSize;
        const py = (path[i].y + agentSpan * 0.5) * cellSize;
        ctx.beginPath();
        ctx.arc(px, py, 3, 0, Math.PI * 2);
        ctx.fill();
      }
    }

    // Draw Start (Green)
    const sx = start.x * cellSize;
    const sy = start.y * cellSize;
    const sDim = agentSpan * cellSize;
    ctx.fillStyle = '#10b981';
    ctx.beginPath();
    ctx.roundRect(sx + 2, sy + 2, sDim - 4, sDim - 4, 6);
    ctx.fill();
    ctx.fillStyle = '#ffffff';
    ctx.font = 'bold 11px sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('S', sx + sDim / 2, sy + sDim / 2);

    // Draw Goal (Red / Rose)
    const gx = goal.x * cellSize;
    const gy = goal.y * cellSize;
    const gDim = agentSpan * cellSize;
    ctx.fillStyle = '#f43f5e';
    ctx.beginPath();
    ctx.roundRect(gx + 2, gy + 2, gDim - 4, gDim - 4, 6);
    ctx.fill();
    ctx.fillStyle = '#ffffff';
    const goalLetter = i18nStrings[currentLang]?.goalChar || 'Z';
    ctx.fillText(goalLetter, gx + gDim / 2, gy + gDim / 2);
  }

  window.renderAStarSimulator = () => {
    render();
  };

  // Initial calculation
  computePath();
  render();
}
