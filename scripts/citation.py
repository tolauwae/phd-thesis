import re
from pybtex.database.input import bibtex

def load_bibtex_keys(bib_path):
    parser = bibtex.Parser()
    bib_data = parser.parse_file(bib_path)
    full_keys = list(bib_data.entries.keys())
    prefix_map = {}
    for key in full_keys:
        if ':' in key:
            prefix, suffix = key.split(':', 1)
            # Prioritize first match; could enhance with longest suffix or rules
            if prefix not in prefix_map:
                prefix_map[prefix] = key
    return prefix_map

def update_typst_citations(typst_text, prefix_map):
    # Update @ref citations
    def replace_at_ref(match):
        key = match.group(1)
        return f"@{prefix_map.get(key, key)}"

    # Update cite(style: "prose", <ref>) citations
    def replace_prose_cite(match):
        key = match.group(1)
        return f'cite(style: "prose", <{prefix_map.get(key, key)}>)'

    def replace_cite(match):
        key = match.group(1)
        return f'cite(<{prefix_map.get(key, key)}>'

    # Apply replacements
    typst_text = re.sub(r'@([a-zA-Z0-9:-]+)', replace_at_ref, typst_text)
    typst_text = re.sub(r'cite\(style:\s*"prose",\s*<([a-zA-Z0-9:-]+)>\)', replace_prose_cite, typst_text)
    typst_text = re.sub(r'cite\(\s*<([a-zA-Z0-9:-]+)>', replace_cite, typst_text)

    return typst_text

def main():
    typst_file = '../src/oop/oop.typ'
    bib_file = '../src/references.bib'

    # Load Typst text
    with open(typst_file, 'r', encoding='utf-8') as f:
        typst_text = f.read()

    # Load BibTeX prefix map
    prefix_map = load_bibtex_keys(bib_file)

    # Update Typst citations
    updated_text = update_typst_citations(typst_text, prefix_map)

    # Save updated Typst text
    with open(typst_file, 'w', encoding='utf-8') as f:
        f.write(updated_text)

if __name__ == "__main__":
    main()

