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
    navState: 'State Management',
    navLayers: 'Layer System',
    navEntities: 'Entities & Sprites',
    navAnimation: 'Animationen & Makros',
    navPhysics: 'Physik & Sensoren',
    navPathfinding: 'Pathfinding & A*',
    navLighting: 'GPU Lighting System',
    navEffects: 'Wasser & Wellen-Shader',
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
    navState: 'State Management',
    navLayers: 'Layer System',
    navEntities: 'Entities & Sprites',
    navAnimation: 'Animations & Macros',
    navPhysics: 'Physics & Sensors',
    navPathfinding: 'Pathfinding & A*',
    navLighting: 'GPU Lighting System',
    navEffects: 'Water & Wave Shaders',
    navToolsMath: 'Tools & Mathematics',
    goalChar: 'G'
  }
};

function initLanguage() {
  const savedLang = localStorage.getItem('mklib-lang') || 'de';
  setLanguage(savedLang);

  document.querySelectorAll('.lang-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      const lang = btn.getAttribute('data-lang');
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
    if (btn.getAttribute('data-lang') === currentLang) {
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
   Navigation & Section Switching
   ========================================================================== */
function initNavigation() {
  const navItems = document.querySelectorAll('.nav-item a, .nav-page-btn');
  const sections = document.querySelectorAll('.doc-section');
  const sidebar = document.querySelector('.sidebar');
  const mobileBtn = document.querySelector('.mobile-menu-btn');

  function showSection(sectionId) {
    if (!sectionId || sectionId === '#') sectionId = 'overview';
    sectionId = sectionId.replace('#', '');

    let found = false;
    sections.forEach(sec => {
      if (sec.id === sectionId) {
        sec.classList.add('active');
        found = true;
      } else {
        sec.classList.remove('active');
      }
    });

    if (!found && sections.length > 0) {
      sections[0].classList.add('active');
      sectionId = sections[0].id;
    }

    // Update active nav link
    document.querySelectorAll('.nav-item').forEach(item => {
      const link = item.querySelector('a');
      if (link && link.getAttribute('href') === `#${sectionId}`) {
        item.classList.add('active');
      } else {
        item.classList.remove('active');
      }
    });

    // Close mobile menu if open
    if (sidebar && sidebar.classList.contains('open')) {
      sidebar.classList.remove('open');
    }

    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  // Intercept nav clicks
  document.addEventListener('click', (e) => {
    const link = e.target.closest('a[href^="#"]');
    if (link) {
      const href = link.getAttribute('href');
      if (href && href.startsWith('#')) {
        e.preventDefault();
        history.pushState(null, '', href);
        showSection(href);
      }
    }
  });

  // Mobile menu toggle
  if (mobileBtn && sidebar) {
    mobileBtn.addEventListener('click', () => {
      sidebar.classList.toggle('open');
    });
  }

  // Handle back/forward navigation
  window.addEventListener('popstate', () => {
    showSection(window.location.hash);
  });

  // Load initial section from hash or default to overview
  showSection(window.location.hash);
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
   Search Functionality
   ========================================================================== */
function initSearch() {
  const searchInput = document.getElementById('docs-search');
  if (!searchInput) return;

  searchInput.addEventListener('input', (e) => {
    const query = e.target.value.toLowerCase().trim();
    const navItems = document.querySelectorAll('.nav-item');

    if (!query) {
      navItems.forEach(item => item.style.display = '');
      document.querySelectorAll('.api-table tbody tr').forEach(row => row.style.display = '');
      return;
    }

    // Check which sections have matching content (class names, methods, properties)
    const sectionMatchMap = new Map();
    document.querySelectorAll('.doc-section').forEach(sec => {
      const secText = sec.textContent.toLowerCase();
      sectionMatchMap.set(sec.id, secText.includes(query));
    });

    navItems.forEach(item => {
      const link = item.querySelector('a');
      const href = link?.getAttribute('href') || '';
      const secId = href.replace('#', '');
      const itemText = item.textContent.toLowerCase();

      if (itemText.includes(query) || href.includes(query) || sectionMatchMap.get(secId)) {
        item.style.display = '';
      } else {
        item.style.display = 'none';
      }
    });

    // Also filter table rows within the active section
    document.querySelectorAll('.api-table tbody tr').forEach(row => {
      const rowText = row.textContent.toLowerCase();
      if (!query || rowText.includes(query)) {
        row.style.display = '';
      } else {
        row.style.display = 'none';
      }
    });
  });

  searchInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
      const firstVisible = document.querySelector('.nav-item:not([style*="display: none"]) a');
      if (firstVisible) {
        firstVisible.click();
      }
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
