"""Generate images for a seephone batch JSON using FLUX.1-schnell.

Usage: python generate_batch.py <path-to-batch.json>
"""
import sys, json, time, argparse
from pathlib import Path
import torch
from diffusers import FluxPipeline

REPO_ROOT = Path(__file__).resolve().parent.parent
MODEL_ID = "black-forest-labs/FLUX.1-schnell"


def round16(x):
    return max(16, ((x + 8) // 16) * 16)


def parse_size(s, default=(1024, 1024)):
    if not s:
        return default
    try:
        w, h = s.lower().split("x")
        return int(w), int(h)
    except Exception:
        return default


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("batch_json")
    args = ap.parse_args()

    bj = json.loads(Path(args.batch_json).read_text(encoding="utf-8"))
    batch_id = bj["batch_id"]
    items = bj["items"]
    default_size = parse_size(bj.get("size_default"), (1024, 1024))
    out_dir = REPO_ROOT / "raw-images" / f"batch_{batch_id}"
    out_dir.mkdir(parents=True, exist_ok=True)

    print(f"[load] {MODEL_ID} (bf16, cpu-offload) ...", flush=True)
    t0 = time.time()
    pipe = FluxPipeline.from_pretrained(MODEL_ID, torch_dtype=torch.bfloat16)
    pipe.enable_model_cpu_offload()
    print(f"[load] ready in {time.time()-t0:.1f}s", flush=True)

    log = []
    for i, item in enumerate(items, 1):
        iid = item["id"]
        prompt = item["prompt"]
        w, h = parse_size(item.get("size"), default_size)
        gw, gh = round16(w), round16(h)
        out_path = out_dir / f"{iid}.png"
        print(f"[{i}/{len(items)}] {iid}  src={w}x{h}  gen={gw}x{gh}", flush=True)
        t1 = time.time()
        gen = torch.Generator("cpu").manual_seed(42 + i)
        img = pipe(
            prompt=prompt,
            width=gw, height=gh,
            num_inference_steps=4,
            guidance_scale=0.0,
            max_sequence_length=256,
            generator=gen,
        ).images[0]
        if (gw, gh) != (w, h):
            img = img.resize((w, h))
        img.save(out_path)
        dt = time.time() - t1
        print(f"      saved {out_path.relative_to(REPO_ROOT)} ({dt:.1f}s)", flush=True)
        log.append({
            "id": iid,
            "file": str(out_path.relative_to(REPO_ROOT)).replace("\\", "/"),
            "size": f"{w}x{h}",
            "gen_size": f"{gw}x{gh}",
            "seconds": round(dt, 1),
        })

    summary_path = out_dir / "_generation_log.json"
    summary_path.write_text(json.dumps({
        "batch_id": batch_id,
        "model": MODEL_ID,
        "steps": 4,
        "guidance": 0.0,
        "dtype": "bfloat16",
        "items": log,
    }, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[done] log -> {summary_path.relative_to(REPO_ROOT)}", flush=True)


if __name__ == "__main__":
    main()
