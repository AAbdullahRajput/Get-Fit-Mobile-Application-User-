import requests, json, time

API_KEY = "9zcvZYN4XaOTFvwUNIiZ5IaBCm2fAo2wj2NJdon23NKGopW4VXAeC86f"

videos_needed = [
    {"id": "018c6d8c-2ada-494e-b630-c31283d22260", "query": "street workout calisthenics"},
    {"id": "0236d741-f601-4ba7-8def-18a25a207423", "query": "bodybuilding drop set gym"},
    {"id": "030ead9d-49fb-4984-9411-f8bb6c1ace68", "query": "zumba dance class"},
    {"id": "276e66ba-2c89-451b-ba02-095d8487df00", "query": "sprint running track"},
    {"id": "348c6cf2-c732-4edd-8e73-146fd4437974", "query": "postnatal core exercise woman"},
    {"id": "34b9ff0f-e975-4fc4-a169-a36b31107612", "query": "pigeon pose hip stretch yoga"},
    {"id": "386483a9-d52d-4718-b068-2bcf7b55c723", "query": "barre inner thigh workout"},
    {"id": "3fabb0d8-c64b-41dc-b7da-520b4959e4be", "query": "pilates spine stretch mat"},
    {"id": "4b285eef-7b81-41af-a099-a69bfb50dedd", "query": "yin yoga stretch floor"},
    {"id": "5395c8db-0e3c-4472-97ea-5813a8dfd3b3", "query": "latin dance salsa"},
    {"id": "54968f6d-be96-4246-b363-214e49eef540", "query": "sun salutation yoga flow"},
    {"id": "5b0bdb97-9443-432b-a18a-e5c76c5a6192", "query": "pregnant woman exercise stretch"},
    {"id": "5bd508e2-65b0-4a3b-82ab-aed4fe57d9c8", "query": "push pull legs gym workout"},
    {"id": "5ed62fd0-9bdb-4311-a0c4-91cc223b5acf", "query": "meal prep healthy containers"},
    {"id": "60f45f3e-a7b2-4134-b0ba-d0ab250a701c", "query": "box jump plyometric training"},
    {"id": "6285c281-c87a-4323-8dc0-9ada0622afe6", "query": "l sit core calisthenics"},
    {"id": "6a8ef0ef-c7e6-43c7-adfc-4e36ceecfa81", "query": "marathon runners race"},
    {"id": "77d22b41-f22c-43d2-8c03-7e35a95703d0", "query": "jogging outdoor easy run"},
    {"id": "794c4c73-936b-414a-945a-a80e67d6f0f1", "query": "boxing heavy bag punching"},
    {"id": "7c9ca5e7-3e26-4cfe-8366-2e30a985fa08", "query": "bodybuilding competition stage"},
    {"id": "7e1c0057-8684-4b9d-ab1f-3bee7c7668c1", "query": "muscle up pull up bar"},
    {"id": "87307838-af6c-44af-8971-2e17e2b04bd8", "query": "ballet barre plie"},
    {"id": "8ca20e0c-a7b2-492d-bdba-434c7b243705", "query": "pilates reformer studio"},
    {"id": "8e590c99-26eb-4df1-86da-57194cac244a", "query": "boxing slip defense training"},
    {"id": "8eb0b2d1-cbbc-4243-a9ce-ded8858415c1", "query": "breathing meditation pranayama"},
    {"id": "8fc85814-74f5-4397-8c1d-9d3196d56b69", "query": "pelvic floor exercise woman"},
    {"id": "9731993a-3b57-4607-b1de-d626735032a3", "query": "hiit burpees workout"},
    {"id": "98abf95e-a7b4-46cf-b59d-b9f68ff41716", "query": "jump rope double under"},
    {"id": "9f5a7950-0e79-4e13-974b-ae89b12c9946", "query": "sleep rest relax bedroom"},
    {"id": "a1000000-0000-0000-0000-000000000001", "query": "strength training barbell gym"},
    {"id": "a1000000-0000-0000-0000-000000000002", "query": "squat exercise gym form"},
    {"id": "a1000000-0000-0000-0000-000000000003", "query": "chest shoulder workout gym"},
    {"id": "a1000000-0000-0000-0000-000000000004", "query": "plank core stability workout"},
    {"id": "a1000000-0000-0000-0000-000000000005", "query": "stretching mobility recovery"},
    {"id": "a3c0b944-60da-456c-9344-8dc744784363", "query": "agility shuttle run drill"},
    {"id": "a5541e29-d860-48b5-abc6-68e79abd3538", "query": "kettlebell turkish get up"},
    {"id": "ac5522d8-e4f8-4551-9f9d-9439089cf3b5", "query": "nutrition label food"},
    {"id": "ae1be162-66ab-4a7f-94b2-3211cf785e4a", "query": "agility ladder footwork drill"},
    {"id": "b2ec5f11-899a-486b-8277-2852f32a0f9f", "query": "boxing jab cross stance"},
    {"id": "b633f5bf-fe88-4d7a-9fb0-55a698d14215", "query": "posture stretch office desk"},
    {"id": "c4e0e5ad-4d1d-4c32-a804-8130d287a4dc", "query": "crossfit thruster pull up"},
    {"id": "ce700a70-8c41-4ef4-b2ba-3196dcf4b1aa", "query": "olympic weightlifting clean jerk"},
    {"id": "d26b3487-94f3-44ab-a304-aea18e9d760d", "query": "kettlebell swing exercise"},
    {"id": "e40c9836-eed5-4bd3-88f4-0e5746bf18d4", "query": "handstand wall gymnastics"},
    {"id": "ea26cd2c-b20f-4134-8f40-dd6622145999", "query": "pilates hundred ab workout"},
    {"id": "ef6a36c6-c29c-4d45-9104-dbaf010958ce", "query": "heart rate monitor cardio"},
    {"id": "f9228ac6-f01f-45a1-a37d-e20efe8fb55c", "query": "morning mobility stretch flow"},
]

def get_video_url(query):
    url = "https://api.pexels.com/videos/search"
    params = {"query": query, "per_page": 5, "min_duration": 15}
    headers = {"Authorization": API_KEY}
    try:
        resp = requests.get(url, params=params, headers=headers, timeout=15)
        resp.raise_for_status()
        data = resp.json()
        for video in data.get("videos", []):
            files = sorted(video.get("video_files", []), key=lambda f: 0 if f.get("quality") == "hd" else 1)
            for f in files:
                if f.get("file_type") == "video/mp4":
                    return f["link"]
    except Exception as e:
        print(f"  ERROR: {e}")
    return None

def main():
    results = {}
    for v in videos_needed:
        url = get_video_url(v["query"])
        results[v["id"]] = url
        print(f"[{'OK' if url else 'FAIL'}] {v['id'][:8]}  {v['query']}")
        time.sleep(0.5)

    lines = []
    for vid, url in results.items():
        if url:
            safe_url = url.replace("'", "''")
            lines.append(f"UPDATE yoga_sessions SET video_url = '{safe_url}' WHERE id = '{vid}';")
        else:
            lines.append(f"-- FAILED: {vid}")

    with open("update_videos.sql", "w") as f:
        f.write("\n".join(lines))

    print(f"\nDone. {sum(1 for v in results.values() if v)}/{len(results)} fetched.")
    print("SQL saved to update_videos.sql")

main()