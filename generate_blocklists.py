import json
import os
import re
import subprocess
import sys
import tempfile

def convert_domain_to_regex(domain):
    """Convert domain to regex pattern for WebKit content blocker."""
    # Escape dots in domain
    domain = domain.replace('.', '\\.')
    return f"^https?://([^/]+\\.)?{domain}"

def get_parent_domain(url):
    """Extract parent domain from URL."""
    if not url.startswith(('http://', 'https://')):
        url = 'http://' + url
    # Simple domain extraction - could be made more robust
    match = re.search(r'://(?:www\.)?([^/]+)', url)
    return match.group(1) if match else None

def process_category(entries, category_name):
    """Process entries in a category and convert to WebKit content blocker format."""
    rules = []
    
    for entry in entries:
        for service_name, service_data in entry.items():
            for parent_url, domains in service_data.items():
                # Skip entries marked as performance-related in cryptomining
                if isinstance(domains, dict) and domains.get("performance") == "true":
                    continue
                
                # Handle both string and list domains
                if isinstance(domains, str):
                    domains = [domains]
                elif isinstance(domains, dict):
                    domains = domains.get(next(iter(domains)), [])
                
                parent_domain = get_parent_domain(parent_url)
                
                for domain in domains:
                    if domain:  # Skip empty domains
                        rule = {
                            "action": {"type": "block"},
                            "trigger": {
                                "url-filter": convert_domain_to_regex(domain),
                                "load-type": ["third-party"]
                            }
                        }
                        
                        # Add unless-domain only if we have a valid parent domain
                        if parent_domain:
                            rule["trigger"]["unless-domain"] = [f"*{parent_domain}"]
                        
                        rules.append(rule)
    
    return rules

def convert_disconnect_to_content_blocker(input_file):
    """
    Convert Disconnect tracking prevention lists to WebKit content blocker format.
    
    Args:
        input_file: Path to the Disconnect services.json file
    """
    with open(input_file, 'r') as f:
        data = json.load(f)
    
    categories = data.get('categories', {})

    output_dir = "Blocklists/"

    # Create or clear output directory
    if os.path.exists(output_dir):
        for file in os.listdir(output_dir):
            os.remove(os.path.join(output_dir, file))
    else:
        os.makedirs(output_dir)
    
    # Process each category separately
    for category_name, entries in categories.items():
        rules = process_category(entries, category_name)
        
        # Write category-specific rules to separate files
        output_file = f"{output_dir}{category_name.lower()}.json"
        with open(output_file, 'w') as f:
            json.dump(rules, f)
        print(f"Created {output_file} with {len(rules)} rules")

# Element hiding rules with no domain (or only ~excluded domains) apply to every site
GENERIC_COSMETIC_RULE = re.compile(r'^(~[^#,]+(,~[^#,]+)*)?#[@?$]?#')
# CSS injection ("site##selector {style}") gets merged into a hiding rule that WebKit then rejects whole
CSS_INJECTION_RULE = re.compile(r'#[@?$]?#.*\{[^}]*\}\s*$')

def convert_easylist_to_content_blocker(input_file, converter_path):
    """
    Convert EasyList to WebKit content blocker format using AdGuard's ConverterTool
    (https://github.com/AdguardTeam/SafariConverterLib), skipping generic element hiding rules.

    Args:
        input_file: Path to easylist.txt
        converter_path: Path to the built ConverterTool binary
    """
    with open(input_file, 'r') as f:
        lines = [
            line for line in f
            if not line.startswith('[')
            and not GENERIC_COSMETIC_RULE.match(line)
            and not CSS_INJECTION_RULE.search(line)
        ]

    output_file = "Blocklists/easylist.json"
    with tempfile.TemporaryDirectory() as temp_dir:
        filtered_path = os.path.join(temp_dir, "easylist.txt")
        with open(filtered_path, 'w') as f:
            f.writelines(lines)
        subprocess.run([
            converter_path, "convert",
            "--safari-version", "15",
            "--input-path", filtered_path,
            "--safari-rules-json-path", output_file,
            "--advanced-blocking-rules-path", os.path.join(temp_dir, "advanced.txt"),
        ], check=True, stdout=subprocess.DEVNULL)

    with open(output_file, 'r') as f:
        print(f"Created {output_file} with {len(json.load(f))} rules")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python generate_blocklists.py <disconnect_services.json> <easylist.txt> <ConverterTool>")
        sys.exit(1)
    convert_disconnect_to_content_blocker(sys.argv[1])
    convert_easylist_to_content_blocker(sys.argv[2], sys.argv[3])
