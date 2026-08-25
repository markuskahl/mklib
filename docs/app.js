/**
 * mklib Documentation Web Application
 * Single Page App Navigation, Search, Theme Switching & Interactive A* Simulator
 */

document.addEventListener('DOMContentLoaded', () => {
  initNavigation();
  initTheme();
  initSearch();
  initCodeCopy();
  initAStarSimulator();
});

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
    if (sidebar) sidebar.classList.remove('open');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  // Handle URL hash changes
  window.addEventListener('hashchange', () => {
    showSection(window.location.hash);
  });

  // Handle link clicks
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', (e) => {
      const targetId = anchor.getAttribute('href');
      if (targetId && targetId !== '#') {
        e.preventDefault();
        window.location.hash = targetId;
        showSection(targetId);
      }
    });
  });

  // Mobile menu button
  if (mobileBtn && sidebar) {
    mobileBtn.addEventListener('click', () => {
      sidebar.classList.toggle('open');
    });
  }

  // Initial load
  showSection(window.location.hash || 'overview');
}

/* ==========================================================================
   Theme Switching (Dark / Light)
   ========================================================================== */
function initTheme() {
  const themeToggle = document.getElementById('theme-toggle');
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  const savedTheme = localStorage.getItem('mklib-theme') || (prefersDark ? 'dark' : 'dark');

  document.documentElement.setAttribute('data-theme', savedTheme);
  updateThemeIcon(savedTheme);

  if (themeToggle) {
    themeToggle.addEventListener('click', () => {
      const current = document.documentElement.getAttribute('data-theme');
      const next = current === 'light' ? 'dark' : 'light';
      document.documentElement.setAttribute('data-theme', next);
      localStorage.setItem('mklib-theme', next);
      updateThemeIcon(next);
    });
  }

  function updateThemeIcon(theme) {
    if (!themeToggle) return;
    themeToggle.innerHTML = theme === 'light' ? '🌙' : '☀️';
    themeToggle.setAttribute('title', theme === 'light' ? 'Dunkles Thema aktivieren' : 'Helles Thema aktivieren');
  }
}

/* ==========================================================================
   Code Copy Button
   ========================================================================== */
function initCodeCopy() {
  document.querySelectorAll('.code-box').forEach(box => {
    const copyBtn = box.querySelector('.copy-btn');
    const codeElem = box.querySelector('pre code') || box.querySelector('pre');

    if (copyBtn && codeElem) {
      copyBtn.addEventListener('click', async () => {
        try {
          await navigator.clipboard.writeText(codeElem.innerText);
          const originalText = copyBtn.innerHTML;
          copyBtn.innerHTML = '✓ Kopiert!';
          copyBtn.style.borderColor = 'var(--accent-emerald)';
          copyBtn.style.color = 'var(--accent-emerald)';

          setTimeout(() => {
            copyBtn.innerHTML = originalText;
            copyBtn.style.borderColor = '';
            copyBtn.style.color = '';
          }, 2000);
        } catch (err) {
          console.error('Failed to copy code: ', err);
        }
      });
    }
  });
}

/* ==========================================================================
   Quick Search Filter & Deep Search
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

  // Canvas Mouse Interactions
  function getCellCoords(e) {
    const rect = canvas.getBoundingClientRect();
    const x = Math.floor((e.clientX - rect.left) / cellSize);
    const y = Math.floor((e.clientY - rect.top) / cellSize);
    return {
      x: Math.max(0, Math.min(cols - 1, x)),
      y: Math.max(0, Math.min(rows - 1, y))
    };
  }

  canvas.addEventListener('mousedown', (e) => {
    isDragging = true;
    const { x, y } = getCellCoords(e);

    if (x === start.x && y === start.y) {
      dragMode = 'start';
    } else if (x === goal.x && y === goal.y) {
      dragMode = 'goal';
    } else {
      dragMode = grid[y][x] === 1 ? 'erase' : 'draw';
      grid[y][x] = dragMode === 'draw' ? 1 : 0;
    }

    computePath();
    render();
  });

  window.addEventListener('mouseup', () => {
    isDragging = false;
    dragMode = null;
  });

  canvas.addEventListener('mousemove', (e) => {
    if (!isDragging) return;
    const { x, y } = getCellCoords(e);

    if (dragMode === 'start') {
      if (grid[y][x] !== 1 && !(x === goal.x && y === goal.y)) {
        start = { x, y };
      }
    } else if (dragMode === 'goal') {
      if (grid[y][x] !== 1 && !(x === start.x && y === start.y)) {
        goal = { x, y };
      }
    } else if (dragMode === 'draw') {
      if (!(x === start.x && y === start.y) && !(x === goal.x && y === goal.y)) {
        grid[y][x] = 1;
      }
    } else if (dragMode === 'erase') {
      grid[y][x] = 0;
    }

    computePath();
    render();
  });

  function generateRandomMaze() {
    grid = Array.from({ length: rows }, () => Array(cols).fill(0));
    for (let r = 0; r < rows; r++) {
      for (let c = 0; c < cols; c++) {
        if (Math.random() < 0.28) {
          if (!(c === start.x && r === start.y) && !(c === goal.x && r === goal.y)) {
            grid[r][c] = 1;
          }
        }
      }
    }
  }

  // A* Pathfinding Logic matching mklib.path.AStar
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

    const dxList = allowDiagonal ? [0, 1, 0, -1, 1, 1, -1, -1] : [0, 1, 0, -1];
    const dyList = allowDiagonal ? [-1, 0, 1, 0, -1, 1, 1, -1] : [-1, 0, 1, 0];
    const costList = allowDiagonal ? [1, 1, 1, 1, SQRT2, SQRT2, SQRT2, SQRT2] : [1, 1, 1, 1];

    while (openList.length > 0) {
      // Find lowest F score
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
        return;
      }

      for (let i = 0; i < dxList.length; i++) {
        const nx = current.x + dxList[i];
        const ny = current.y + dyList[i];
        const nKey = `${nx},${ny}`;

        if (!isAreaWalkable(nx, ny, agentSpan)) continue;
        if (closedSet.has(nKey)) continue;

        // Prevent corner cutting in diagonal mode
        if (allowDiagonal && i >= 4) {
          if (!isAreaWalkable(current.x + dxList[i], current.y, agentSpan) ||
              !isAreaWalkable(current.x, current.y + dyList[i], agentSpan)) {
            continue;
          }
        }

        const tentativeG = current.g + costList[i];
        const neighbor = getNode(nx, ny);

        const inOpen = openList.includes(neighbor);
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

  // Render Grid, Walls, Path & Endpoints
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
    ctx.fillText('Z', gx + gDim / 2, gy + gDim / 2);
  }

  // Initial calculation
  computePath();
  render();
}
