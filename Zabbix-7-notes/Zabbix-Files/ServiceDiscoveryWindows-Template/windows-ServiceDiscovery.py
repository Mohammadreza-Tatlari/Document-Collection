import sys
import json
import subprocess

def get_windows_services():
    """Retrieves a list of enabled Windows services."""

    try:
        # Use PowerShell to get service information.  This is more robust than tasklist.
        powershell_command = "Get-Service | Where-Object {$_.Status -eq 'Running' -or $_.StartType -ne 'Disabled'} | Select-Object -ExpandProperty Name"
        result = subprocess.run(['powershell', '-Command', powershell_command], capture_output=True, text=True, check=True)
        services_output = result.stdout

    except subprocess.CalledProcessError as e:
        print(f"Error executing PowerShell command: {e}")
        print(f"Stderr: {e.stderr}") # Print stderr for debugging
        return []
    except FileNotFoundError:
      print("PowerShell not found. Please ensure it's available in your system's PATH.")
      return []

    services = services_output.strip().splitlines()
    discovery_list = []
    for service_name in services:
        discovery_list.append({"{#SERVICE}": service_name.strip()})  # Remove leading/trailing spaces


    return discovery_list


if __name__ == "__main__":
    discovery_data = get_windows_services()
    #print(json.dumps({"data": discovery_data}))
    print(json.dumps(discovery_data))
    sys.stdout.flush() # Important for Zabbix discovery