import os
import re
import shutil

DOCS_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'docs')
HTML_DIR = os.path.join(DOCS_DIR, 'html')
INDEX_PATH = os.path.join(HTML_DIR, 'index.html')
BACKUP_PATH = os.path.join(HTML_DIR, 'index.html.bak')

SECTION_MAP = {
    'overview': ('index.html', 'Übersicht & API-Matrix', 'Overview & API Matrix', '📖'),
    'getting-started': ('getting-started.html', 'Schnellstart & Setup', 'Quick Start & Setup', '🚀'),
    'ldtk-guide': ('ldtk-guide.html', 'LDtk Guide & Felder', 'LDtk Guide & Fields', '🗺️'),
    'state': ('state.html', 'State Management', 'State Management', '🎮'),
    'layers': ('layers.html', 'Layer System', 'Layer System', '📑'),
    'entities': ('entities.html', 'Entities & Sprites', 'Entities & Sprites', '👾'),
    'save': ('save.html', 'Save & Persistence', 'Save & Persistence', '💾'),
    'animation': ('animation.html', 'Animationen & Makros', 'Animations & Macros', '🎬'),
    'physics': ('physics.html', 'Physik & Sensoren', 'Physics & Sensors', '⚡'),
    'pathfinding': ('pathfinding.html', 'Pathfinding & A*', 'Pathfinding & A*', '🧭'),
    'lighting': ('lighting.html', 'GPU Lighting System', 'GPU Lighting System', '💡'),
    'effects': ('effects.html', 'Shader & Effekte', 'Shaders & Effects', '🎨'),
    'tools-math': ('tools-math.html', 'Tools & Mathematik', 'Tools & Mathematics', '📐')
}

LINK_REPLACEMENTS = {
    f'href="#{sec_id}"': f'href="{info[0]}"' for sec_id, info in SECTION_MAP.items()
}
# Also replace any href="#overview" with index.html
LINK_REPLACEMENTS['href="#overview"'] = 'href="index.html"'

def convert_internal_links(html_text):
    for old_link, new_link in LINK_REPLACEMENTS.items():
        html_text = html_text.replace(old_link, new_link)
    return html_text

def main():
    os.makedirs(HTML_DIR, exist_ok=True)
    source_file = BACKUP_PATH if os.path.exists(BACKUP_PATH) else INDEX_PATH
    print(f"Reading source content from {source_file}...")
    with open(source_file, 'r', encoding='utf-8') as f:
        full_content = f.read()

    # Create backup if not exists
    if not os.path.exists(BACKUP_PATH):
        print(f"Creating backup at {BACKUP_PATH}...")
        shutil.copyfile(INDEX_PATH, BACKUP_PATH)

    # 1. Extract Head (up to </head>)
    head_match = re.search(r'^(<!DOCTYPE html>.*?<head>.*?</head>)', full_content, re.DOTALL)
    if not head_match:
        raise ValueError("Could not find <head> section!")
    raw_head = head_match.group(1)

    # 2. Extract Body Top up to <main class="main-content">
    body_top_match = re.search(r'</head>\s*<body>(.*?)<main class="main-content">', full_content, re.DOTALL)
    if not body_top_match:
        raise ValueError("Could not find body top and sidebar!")
    body_top = body_top_match.group(1)

    # Convert logo link in top-header
    body_top = body_top.replace('href="#overview"', 'href="index.html"')

    # 3. Extract Footer (<main> closing to </html>)
    footer_match = re.search(r'</main>\s*(</div>\s*<script src="app.js"></script>\s*</body>\s*</html>)', full_content, re.DOTALL)
    if not footer_match:
        raise ValueError("Could not find footer section!")
    body_bottom = footer_match.group(1)

    # 4. Extract all <section id="...">...</section>
    section_pattern = re.compile(r'(<section\s+id="([^"]+)"\s+class="doc-section[^"]*">.*?</section>)', re.DOTALL)
    sections = {}
    for match in section_pattern.finditer(full_content):
        sec_tag = match.group(1)
        sec_id = match.group(2)
        sections[sec_id] = sec_tag

    print(f"Found {len(sections)} sections: {list(sections.keys())}")

    missing_sections = set(SECTION_MAP.keys()) - set(sections.keys())
    if missing_sections:
        print(f"WARNING: Missing sections in HTML: {missing_sections}")

    # 5. Generate each file
    for sec_id, (filename, title_de, title_en, icon) in SECTION_MAP.items():
        if sec_id not in sections:
            print(f"Skipping {sec_id} (not found in content)")
            continue

        page_path = os.path.join(HTML_DIR, filename)

        # Page-specific title
        page_title = f"{title_de} — mklib Dokumentation" if sec_id != 'overview' else "mklib — Vollständige Dokumentation & API-Referenz"
        page_head = re.sub(r'<title>.*?</title>', f'<title>{page_title}</title>', raw_head)

        # Build sidebar for this page with active item
        page_sidebar = body_top
        # Convert all sidebar links from href="#xyz" to href="xyz.html"
        for s_id, s_info in SECTION_MAP.items():
            page_sidebar = page_sidebar.replace(f'href="#{s_id}"', f'href="{s_info[0]}"')

        # Clear existing active classes in sidebar nav-items
        page_sidebar = re.sub(r'<li class="nav-item active">', '<li class="nav-item">', page_sidebar)

        # Set active class for current page
        target_link = f'href="{filename}"'
        page_sidebar = page_sidebar.replace(f'<li class="nav-item"><a {target_link}', f'<li class="nav-item active"><a {target_link}')

        # Prepare section content: ensure class="doc-section active"
        sec_content = sections[sec_id]
        sec_content = re.sub(r'class="doc-section[^"]*"', 'class="doc-section active"', sec_content)

        # Convert in-page links
        sec_content = convert_internal_links(sec_content)

        # Assemble full document
        page_html = f"""{page_head}
<body>{page_sidebar}<main class="main-content">
      <!-- Section: {sec_id} -->
{sec_content}
    </main>
  {body_bottom}
"""

        with open(page_path, 'w', encoding='utf-8') as f:
            f.write(page_html)

        line_count = len(page_html.splitlines())
        size_kb = len(page_html.encode('utf-8')) / 1024
        print(f"  -> Generated docs/html/{filename} ({line_count} lines, {size_kb:.1f} KB)")

    print("\nAll 13 modular HTML documents successfully generated!")

if __name__ == '__main__':
    main()
