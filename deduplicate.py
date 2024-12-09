import sys
from concurrent.futures import ProcessPoolExecutor

class TrieNode:
    def __init__(self):
        self.children = {}
        self.is_end_of_domain = False

def insert_into_trie(root, domain):
    parts = domain.split('.')
    parts.reverse()  # Reverse to insert from top-level domain to subdomain
    current = root
    for part in parts:
        if part not in current.children:
            current.children[part] = TrieNode()
        current = current.children[part]
    current.is_end_of_domain = True

def collect_unique_domains(root, prefix, unique_rules):
    if root.is_end_of_domain:
        unique_rules.append('||' + prefix + '^')
        return  # No need to go further if we've found a complete domain
    for part, child in root.children.items():
        collect_unique_domains(child, part + '.' + prefix if prefix else part, unique_rules)

def deduplicate(rules):
    """Elimina subdominios redundantes utilizando un trie."""
    print("Iniciando deduplicación")
    root = TrieNode()
    for rule in rules:
        insert_into_trie(root, rule)
    
    unique_rules = []
    collect_unique_domains(root, '', unique_rules)
    return unique_rules

def load_rules(file_path):
    """Carga las reglas desde un archivo."""
    rules = {}
    with open(file_path, 'r') as f:
        for line in f:
            line = line.strip()
            rules[line.replace("||", "").replace("^", "")] = line
    return rules

def main(input_files, output_file):
    """Procesa y deduplica reglas usando paralelización."""
    all_rules = {}

    # Cargar todos los fragmentos en memoria
    with ProcessPoolExecutor() as executor:
        results = list(executor.map(load_rules, input_files))

    # Unir todas las reglas
    for result in results:
        all_rules.update(result)

    print(f"Cargando {len(all_rules)} reglas...")

    # Realizar la deduplicación
    unique_rules = deduplicate(all_rules)
    print(f"Reglas únicas: {len(unique_rules)}")

    # Guardar el archivo final
    with open(output_file, 'w') as f:
        for rule in sorted(unique_rules):
            f.write(rule + "\n")

    print(f"Archivo optimizado guardado en: {output_file}")

if __name__ == "__main__":
    # Archivos de entrada
    input_files = sys.argv[1:-1]
    # Archivo de salida
    output_file = sys.argv[-1]

    main(input_files, output_file)
