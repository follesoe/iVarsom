#!/usr/bin/env python3
"""Download and combine Norwegian and Swedish avalanche region polygons into GeoJSON."""

import json
import urllib.request
import os

SWEDEN_OFFSET = 100000
OUTPUT_PATH = os.path.join(os.path.dirname(__file__), "..", "iVarsom", "Resources", "regions.geojson")

NVE_URL = "https://api01.nve.no/hydrology/forecast/avalanche/v6.3.0/api/Region/10"
SWEDEN_WFS_URL = (
    "https://nvgis.naturvardsverket.se/geoserver/lavinprognoser/ows"
    "?service=WFS&version=1.0.0&request=GetFeature"
    "&typeName=lavinprognoser:main_locations&outputFormat=application/json"
    "&srsName=EPSG:4326"
)


def fetch_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": "iVarsom/1.0"})
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())


def parse_nve_polygon(polygon_str):
    """Parse NVE polygon string 'lat,lon lat,lon ...' into GeoJSON [lon, lat] ring."""
    ring = []
    for pair in polygon_str.strip().split():
        lat_str, lon_str = pair.split(",")
        ring.append([float(lon_str), float(lat_str)])
    if ring and ring[0] != ring[-1]:
        ring.append(ring[0])
    return ring


def fetch_norway_features():
    data = fetch_json(NVE_URL)
    features = []
    for region in data:
        region_id = region["Id"]
        name = region["Name"]
        polygons = region.get("Polygon", [])
        if not polygons:
            continue
        rings = [parse_nve_polygon(p) for p in polygons if p]
        if not rings:
            continue
        if len(rings) == 1:
            geometry = {"type": "Polygon", "coordinates": rings}
        else:
            geometry = {"type": "MultiPolygon", "coordinates": [[r] for r in rings]}
        features.append({
            "type": "Feature",
            "properties": {"id": region_id, "name": name, "country": "norway"},
            "geometry": geometry,
        })
    return features


def fetch_sweden_features():
    data = fetch_json(SWEDEN_WFS_URL)
    features = []
    for feature in data.get("features", []):
        props = feature.get("properties", {})
        area_id = props.get("id")
        name = props.get("label", "")
        if area_id is None:
            continue
        synthetic_id = area_id + SWEDEN_OFFSET
        geometry = feature.get("geometry")
        if not geometry:
            continue
        features.append({
            "type": "Feature",
            "properties": {"id": synthetic_id, "name": name, "country": "sweden"},
            "geometry": geometry,
        })
    return features


def main():
    print("Fetching Norwegian regions...")
    norway = fetch_norway_features()
    print(f"  Got {len(norway)} Norwegian regions")

    print("Fetching Swedish regions...")
    sweden = fetch_sweden_features()
    print(f"  Got {len(sweden)} Swedish regions")

    collection = {
        "type": "FeatureCollection",
        "features": norway + sweden,
    }

    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    with open(OUTPUT_PATH, "w") as f:
        json.dump(collection, f, indent=2)

    print(f"Wrote {len(collection['features'])} features to {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
