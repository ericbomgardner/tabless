import json
import os
import re
import sys

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

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python generate_blocklists.py <input_file>")
        sys.exit(1)
    convert_disconnect_to_content_blocker(sys.argv[1])
