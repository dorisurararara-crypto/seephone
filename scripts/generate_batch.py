"""Generate images for a seephone batch JSON.

Models:
  --model klein   FLUX.2-klein-4B  (default — fast, GPU-resident on 16GB VRAM)
  --model schnell FLUX.1-schnell   (12B, requires cpu-offload, slow on 16GB)
  --model sdxl    SDXL base 1.0    (3.5B, fast)

Usage:
  python generate_batch.py <batch.json> [--model klein] [--limit N]
"""
import json, time, argparse
from pathlib import Path
import torch

REPO_ROOT = Path(__file__).resolve().parent.parent

MODELS = {
    "klein":   ("black-forest-labs/FLUX.2-klein-4B",          "Flux2KleinPipeline", {"steps": 16, "guidance": 4.0, "max_seq": 512, "offload": False}),
    "schnell": ("black-forest-labs/FLUX.1-schnell",           "FluxPipeline",       {"steps": 4,  "guidance": 0.0, "max_seq": 256, "offload": True}),
    "sdxl":    ("stabilityai/stable-diffusion-xl-base-1.0",   "StableDiffusionXLPipeline", {"steps": 30, "guidance": 7.0, "max_seq": None, "offload": False}),
}


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


def load_pipe(model_key):
    model_id, pipe_class_name, cfg = MODELS[model_key]
    import diffusers
    PipeClass = getattr(diffusers, pipe_class_name)
    print(f"[load] {model_id} via {pipe_class_name} ...", flush=True)
    t0 = time.time()
    pipe = PipeClass.from_pretrained(model_id, torch_dtype=torch.bfloat16)
    if cfg["offload"]:
        pipe.enable_model_cpu_offload()
    else:
        pipe = pipe.to("cuda")
    print(f"[load] ready in {time.time()-t0:.1f}s", flush=True)
    return pipe, cfg, model_id


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("batch_json")
    ap.add_argument("--model", choices=list(MODELS), default="klein")
    ap.add_argument("--limit", type=int, default=0, help="Generate only first N items (0 = all)")
    args = ap.parse_args()

    bj = json.loads(Path(args.batch_json).read_text(encoding="utf-8"))
    batch_id = bj["batch_id"]
    items = bj["items"]
    if args.limit > 0:
        items = items[:args.limit]
    default_size = parse_size(bj.get("size_default"), (1024, 1024))
    out_dir = REPO_ROOT / "raw-images" / f"batch_{batch_id}"
    out_dir.mkdir(parents=True, exist_ok=True)

    pipe, cfg, model_id = load_pipe(args.model)

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
        kwargs = dict(
            prompt=prompt,
            width=gw, height=gh,
            num_inference_steps=cfg["steps"],
            guidance_scale=cfg["guidance"],
            generator=gen,
        )
        if cfg["max_seq"] is not None:
            kwargs["max_sequence_length"] = cfg["max_seq"]
        img = pipe(**kwargs).images[0]
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
        "model": model_id,
        "model_key": args.model,
        "config": cfg,
        "items": log,
    }, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[done] log -> {summary_path.relative_to(REPO_ROOT)}", flush=True)


if __name__ == "__main__":
    main()
