import urllib.request
import json

URL = "https://lidoouszbcutddwrxbgy.supabase.co/rest/v1/planograms?select=*"
HEADERS = {
    "apikey": "sb_publishable_X11_v94UKdMch6EBFq1eyA_9jGIJuD8",
    "Authorization": "Bearer sb_publishable_X11_v94UKdMch6EBFq1eyA_9jGIJuD8"
}

req = urllib.request.Request(URL, headers=HEADERS)
try:
    with urllib.request.urlopen(req) as response:
        planograms = json.loads(response.read().decode())
        
        # Group by name
        grouped = {}
        for p in planograms:
            grouped.setdefault(p["name"], []).append(p)
            
        for name, items in grouped.items():
            # Sort by created_at
            items.sort(key=lambda x: x["created_at"])
            # Keep the first one, delete the rest
            to_delete = items[1:]
            for item in to_delete:
                del_url = f"https://lidoouszbcutddwrxbgy.supabase.co/rest/v1/planograms?id=eq.{item['id']}"
                del_req = urllib.request.Request(del_url, headers=HEADERS, method="DELETE")
                try:
                    urllib.request.urlopen(del_req)
                    print(f"Deleted duplicate: {item['name']} ({item['id']})")
                except Exception as e:
                    print(f"Failed to delete {item['id']}: {e}")
                    
except Exception as e:
    print(f"Error: {e}")
