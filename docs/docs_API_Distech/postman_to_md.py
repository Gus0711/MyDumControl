#!/usr/bin/env python3
"""Convert the Distech ECLYPSE Postman collections into compact Markdown for humans and AI.

Usage: python3 postman_to_md.py   (run from anywhere, writes next to this script)
"""
import json
import re
import shutil
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT_V1 = HERE / "v1"
OUT_V2 = HERE / "v2"

MAX_STRING = 200       # longer JSON strings are cut
MAX_ARRAY = 3          # longer JSON arrays keep only the first items
MAX_KEYS = 12          # larger JSON objects keep only the first keys
MAX_DEPTH = 6          # deeper JSON is replaced by "…"
MAX_JSON = 4000        # formatted JSON examples are cut after this
MAX_RAW = 1500         # non-JSON bodies / responses are cut after this
MAX_RESPONSE = 1500

URL_PREFIXES = [
    ("{{Scheme}}://{{Hostname}}{{BasePath}}", ""),
    ("{{Scheme}}://{{Hostname}}/api/rest/v2", ""),
    ("{{scheme}}://{{ip_address}}:{{port}}/api/rest/v1", ""),
    ("{{Scheme}}://{{Hostname}}", "https://<hôte>"),
]
# Example values that look like credentials are masked in the generated Markdown
SECRET_FIELD = re.compile(
    r"^(pass(word)?|secret|client[-_]?secret|(access[-_]?|refresh[-_]?)?token|(api|access|private|shared[-_]?access)[-_]?key|psk)$", re.I
)
SECRET_INLINE = re.compile(r"((?:SharedAccessKey|AccountKey|password|pwd)=)[^;&\s\"]+", re.I)


def mask(text: str) -> str:
    return SECRET_INLINE.sub(r"\1<masqué>", text)
SKIPPED_HEADERS = {"content-type", "authorization", "accept"}


def slugify(name: str) -> str:
    s = re.sub(r"[^\w\s-]", "", name).strip()
    return re.sub(r"[\s]+", "-", s)


def iter_requests(item, path):
    """Yield (folder_path, request_item) for every request under item."""
    if "item" in item:
        for child in item["item"]:
            yield from iter_requests(child, path + [item["name"]])
    else:
        yield path, item


def shrink(value, depth=0):
    """Cut long strings, arrays, objects and deep nesting so huge example payloads stay readable."""
    if isinstance(value, str):
        value = mask(value)
        return value[:60] + f"…({len(value)} caractères)" if len(value) > MAX_STRING else value
    if isinstance(value, (list, dict)) and depth >= MAX_DEPTH:
        return "…"
    if isinstance(value, list):
        out = [shrink(v, depth + 1) for v in value[:MAX_ARRAY]]
        if len(value) > MAX_ARRAY:
            out.append(f"… {len(value) - MAX_ARRAY} autres éléments")
        return out
    if isinstance(value, dict):
        keys = list(value)
        out = {
            k: "<masqué>" if SECRET_FIELD.search(k) and isinstance(value[k], str) and value[k] else shrink(value[k], depth + 1)
            for k in keys[:MAX_KEYS]
        }
        if len(keys) > MAX_KEYS:
            out["…"] = f"{len(keys) - MAX_KEYS} autres clés ({', '.join(keys[MAX_KEYS:MAX_KEYS + 5])}…)"
        return out
    return value


def format_payload(raw: str, limit: int) -> tuple[str, str]:
    """Return (language, text) for a body or response example."""
    raw = raw.strip()
    try:
        data = json.loads(raw)
        text = json.dumps(shrink(data), indent=2, ensure_ascii=False)
        if len(text) > MAX_JSON:
            text = text[:MAX_JSON] + f"\n…(exemple tronqué, {len(text)} caractères une fois réduit)"
        return "json", text
    except (json.JSONDecodeError, ValueError):
        text = raw if len(raw) <= limit else raw[:limit] + f"\n…(tronqué, {len(raw)} caractères)"
        return "", mask(text)


def request_url(req) -> str:
    url = req.get("url", "")
    raw = url.get("raw", "") if isinstance(url, dict) else url
    for prefix, repl in URL_PREFIXES:
        if raw.startswith(prefix):
            return repl + raw[len(prefix):] or "/"
    return raw


def render_request(item) -> list[str]:
    req = item["request"]
    lines = [f"#### {item['name']}", f"`{req.get('method', 'GET')} {mask(request_url(req))}`", ""]

    desc = (req.get("description") or "").strip()
    if isinstance(req.get("description"), dict):
        desc = (req["description"].get("content") or "").strip()
    if desc:
        lines += [desc, ""]

    headers = [h for h in req.get("header", []) if h.get("key", "").lower() not in SKIPPED_HEADERS and not h.get("disabled")]
    if headers:
        lines += ["En-têtes : " + ", ".join(f"`{h['key']}: {h.get('value', '')}`" for h in headers), ""]

    body = req.get("body") or {}
    if body.get("mode") == "raw" and body.get("raw", "").strip():
        lang, text = format_payload(body["raw"], MAX_RAW)
        lines += ["Corps :", f"```{lang}", text, "```", ""]
    elif body.get("mode") in ("urlencoded", "formdata"):
        fields = [f"`{f['key']}`" for f in body.get(body["mode"], []) if not f.get("disabled")]
        if fields:
            lines += [f"Corps ({body['mode']}) : " + ", ".join(fields), ""]

    for resp in (item.get("response") or [])[:1]:
        if resp.get("body"):
            lang, text = format_payload(resp["body"], MAX_RESPONSE)
            status = f" ({resp.get('code', '')} {resp.get('status', '')})".rstrip(" ()") + ")" if resp.get("code") else ""
            lines += [f"Exemple de réponse{status} :", f"```{lang}", text, "```", ""]
    return lines


def render_file(title: str, intro: str, folder) -> tuple[str, int, list[str]]:
    """Render one Markdown file for a folder. Returns (text, request_count, subfolders)."""
    lines = [f"# {title}", "", intro, ""]
    count = 0
    current = None
    for path, item in iter_requests(folder, []):
        section = " › ".join(path[1:]) or folder["name"]
        if section != current:
            lines += [f"## {section}", ""]
            current = section
        lines += render_request(item)
        count += 1
    subfolders = [c["name"] for c in folder.get("item", []) if "item" in c]
    return "\n".join(lines).rstrip() + "\n", count, subfolders


def main():
    for d in (OUT_V1, OUT_V2):
        if d.exists():
            shutil.rmtree(d)
        d.mkdir()

    index_rows_v2, index_rows_v1 = [], []
    v2_intro = "Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md)."

    # --- V2 ---
    v2 = json.loads((HERE / "API-V2.postman_collection.json").read_text())
    root = v2["item"][0]  # "Rest API V2"
    general = {"name": "Général", "item": []}
    for section in root["item"]:
        if section["name"] == "Services" and len(list(iter_requests(section, []))) > 1:
            for service in section["item"]:
                text, n, subs = render_file(f"API V2 — {service['name']}", v2_intro, service)
                if n == 0:
                    continue
                fname = f"{slugify(service['name'])}.md"
                (OUT_V2 / fname).write_text(text)
                index_rows_v2.append((service["name"], f"v2/{fname}", n, subs))
        else:
            general["item"].append(section)
    text, n, subs = render_file(
        "API V2 — Général",
        v2_intro + " Authentification, version, requêtes groupées (batch) et exemples de `$select` / filtres.",
        general,
    )
    (OUT_V2 / "00-General.md").write_text(text)
    index_rows_v2.insert(0, ("Général (auth, version, batch, $select, filtres)", "v2/00-General.md", n, subs))

    # --- V1 ---
    v1 = json.loads((HERE / "API-V1.postman_collection.json").read_text())
    for section in v1["item"]:
        text, n, subs = render_file(
            f"API V1 — {section['name']}",
            "Chemins relatifs à `https://<hôte>/api/rest/v1`. Auth : Basic. API legacy, préférer la V2. Voir [INDEX](../INDEX.md).",
            section,
        )
        fname = f"{slugify(section['name'])}.md"
        (OUT_V1 / fname).write_text(text)
        index_rows_v1.append((section["name"], f"v1/{fname}", n, subs))

    # --- Index ---
    def table(rows):
        out = ["| Domaine | Fichier | Requêtes | Sous-parties |", "|---|---|---|---|"]
        for name, path, n, subs in rows:
            out.append(f"| {name} | [{path}]({path}) | {n} | {', '.join(subs)} |")
        return out

    total_v2 = sum(r[2] for r in index_rows_v2)
    total_v1 = sum(r[2] for r in index_rows_v1)
    index = [
        "# API Distech ECLYPSE — index",
        "",
        "Référence compacte générée depuis les collections Postman officielles "
        "(`API-V2.postman_collection.json`, `API-V1.postman_collection.json`) par `postman_to_md.py`. "
        "Ne pas modifier les fichiers `v1/` et `v2/` à la main : relancer `python3 postman_to_md.py`.",
        "",
        "## Conventions",
        "",
        "- **URL de base V2** : `https://<hôte>/api/rest/v2` (variable Postman `{{BasePath}}`). Les chemins des fichiers `v2/` sont relatifs à cette base.",
        "- **URL de base V1** : `https://<hôte>/api/rest/v1` (legacy, contrôleurs anciens).",
        "- **Version de l'API** : `GET https://<hôte>/api/rest`.",
        "- **Authentification** : HTTP Basic (identifiants du contrôleur) sur toutes les requêtes. "
        "Jeton possible via `POST https://<hôte>/auth/local/token` (voir [v2/00-General.md](v2/00-General.md)).",
        "- **Lecture** : `GET` ; **écriture** : `POST` avec un corps JSON partiel (seuls les champs envoyés sont modifiés) ; "
        "`PUT` pour créer/remplacer ; `DELETE` pour supprimer.",
        "- **Les nombres dans les chemins sont des exemples** (ex. `devices/210066/objects/binary-values/11` = device BACnet 210066, instance 11). "
        "Les noms d'objets BACnet sont en kebab-case : `analog-values`, `binary-inputs`, `multi-state-values`…",
        "- **Sélection de champs (`$select`)**, imbricable : "
        "`GET /services/bacnet/local/objects?$select=analog-values($select=*($select=object-name,present-value))`. "
        "`*` = tous les éléments d'une collection. Plusieurs `$select` se combinent avec `&`. Exemples complets dans [v2/00-General.md](v2/00-General.md).",
        "- **Exemples de corps** : les longues chaînes et listes sont tronquées (`…(N caractères)`, `… N autres éléments`).",
        "",
        f"## API V2 ({total_v2} requêtes)",
        "",
        *table(index_rows_v2),
        "",
        f"## API V1 ({total_v1} requêtes)",
        "",
        *table(index_rows_v1),
        "",
    ]
    (HERE / "INDEX.md").write_text("\n".join(index))
    print(f"V2: {total_v2} requests in {len(index_rows_v2)} files, V1: {total_v1} requests")


if __name__ == "__main__":
    main()
