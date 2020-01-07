modules = { "local" : [
    "rtl",
    "modules",
] }

if action == "synthesis":
    modules["local"].append("syn/common")
