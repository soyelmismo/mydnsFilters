import sys
from concurrent.futures import ProcessPoolExecutor

def load_rules(file_path):
    """Carga las reglas desde un archivo."""
    rules = {}
    with open(file_path, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith("||") and line.endswith("^"):
                domain = line[2:-1]  # Extraer dominio (sin || y ^)
                rules[domain] = line
    return rules

def process_fragment(fragment):
    """Procesa un fragmento del archivo para deduplicar reglas."""
    rules = {}
    with open(fragment, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith("||") and line.endswith("^"):
                domain = line[2:-1]  # Extraer dominio (sin || y ^)
                # Verificar subdominios redundantes
                if not any(domain.endswith(f".{d}") for d in rules):
                    rules[domain] = line
    return rules

def deduplicate(rules):
    """Elimina subdominios redundantes."""
    domains = {rule.split('.')[0]: rule for rule in rules.values()}
    return set(domains.values())

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
