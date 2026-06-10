"""Generate multiple candidate images per item for a seephone batch JSON.

Extends generate_batch.py with:
  - N candidates per item, saved as <id>_<n>.png (and _v2/_v3 suffix mode for regen rounds)
  - negative prompt support (batch-level default + per-item override)
  - transparent items: generate on plain background, then rembg -> alpha PNG
  - small sprites (<=512) generated at 1024 then downscaled for quality

Usage:
  python generate_batch_multi.py <batch.json> [--model sdxl] [--candidates 3]
                                 [--only id1,id2] [--suffix _v2] [--seed-base 1000]
"""
import json, time, argparse, io
from pathlib import Path
import torch

REPO_ROOT = Path(__file__).resolve().parent.parent

MODELS = {
    "klein":   ("black-forest-labs/FLUX.2-klein-4B",          "Flux2KleinPipeline", {"steps": 16, "guidance": 4.0, "max_seq": 512, "offload": False, "negative": False}),
    "schnell": ("black-forest-labs/FLUX.1-schnell",           "FluxPipeline",       {"steps": 4,  "guidance": 0.0, "max_seq": 256, "offload": True,  "negative": False}),
    "sdxl":    ("stabilityai/stable-diffusion-xl-base-1.0",   "StableDiffusionXLPipeline", {"steps": 30, "guidance": 7.0, "max_seq": None, "offload": False, "negative": True}),
}

# Background used when generating items that will go through rembg.
# A flat light-grey studio backdrop gives rembg a clean contrast edge.
GEN_BG_PHRASE = "isolated on plain uniform light grey studio background"
ALPHA_PHRASES = ("clean alpha background", "alpha background", "transparent background")


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
    ap.add_argument("--model", choices=list(MODELS), default="sdxl")
    ap.add_argument("--candidates", type=int, default=3)
    ap.add_argument("--only", default="", help="comma-separated item ids to generate")
    ap.add_argument("--suffix", default="", help="appended after candidate number, e.g. _v2 -> id_1_v2.png")
    ap.add_argument("--seed-base", type=int, default=42)
    ap.add_argument("--prompt-override", default="", help="JSON file {id: {prompt, negative_prompt}} overrides for regen rounds")
    args = ap.parse_args()

    bj = json.loads(Path(args.batch_json).read_text(encoding="utf-8"))
    batch_id = bj["batch_id"]
    items = bj["items"]
    if args.only:
        wanted = {s.strip() for s in args.only.split(",") if s.strip()}
        items = [it for it in items if it["id"] in wanted]
    overrides = {}
    if args.prompt_override:
        overrides = json.loads(Path(args.prompt_override).read_text(encoding="utf-8"))
    default_size = parse_size(bj.get("size_default"), (1024, 1024))
    default_neg = bj.get("negative_prompt_default") or bj.get("negative_prompt") or ""
    out_dir = REPO_ROOT / "raw-images" / f"batch_{batch_id}"
    out_dir.mkdir(parents=True, exist_ok=True)

    pipe, cfg, model_id = load_pipe(args.model)

    rembg_session = None
    if any(it.get("transparent") for it in items):
        from rembg import new_session
        rembg_session = new_session("isnet-general-use")

    log = []
    for i, item in enumerate(items, 1):
        iid = item["id"]
        ov = overrides.get(iid, {})
        prompt = ov.get("prompt", item["prompt"])
        neg = ov.get("negative_prompt", item.get("negative_prompt", default_neg))
        transparent = bool(item.get("transparent"))
        w, h = parse_size(item.get("size"), default_size)

        gen_prompt = prompt
        if transparent:
            for ph in ALPHA_PHRASES:
                gen_prompt = gen_prompt.replace(ph, GEN_BG_PHRASE)

        # SDXL quality drops below ~1MP; render small sprites at 2x then downscale
        scale = 2 if max(w, h) <= 512 else 1
        gw, gh = round16(w * scale), round16(h * scale)

        for c in range(1, args.candidates + 1):
            out_path = out_dir / f"{iid}_{c}{args.suffix}.png"
            seed = args.seed_base + i * 100 + c
            print(f"[{i}/{len(items)}] {iid} cand {c}/{args.candidates}  gen={gw}x{gh} -> {w}x{h}  seed={seed}", flush=True)
            t1 = time.time()
            gen = torch.Generator("cpu").manual_seed(seed)
            kwargs = dict(
                prompt=gen_prompt,
                width=gw, height=gh,
                num_inference_steps=cfg["steps"],
                guidance_scale=cfg["guidance"],
                generator=gen,
            )
            if cfg["negative"] and neg:
                kwargs["negative_prompt"] = neg
            if cfg["max_seq"] is not None:
                kwargs["max_sequence_length"] = cfg["max_seq"]
            img = pipe(**kwargs).images[0]
            if (img.width, img.height) != (w, h):
                img = img.resize((w, h))

            if transparent:
                from rembg import remove
                img = remove(img, session=rembg_session, post_process_mask=True)

            img.save(out_path)
            dt = time.time() - t1
            print(f"      saved {out_path.relative_to(REPO_ROOT)} ({dt:.1f}s)", flush=True)
            log.append({
                "id": iid,
                "candidate": c,
                "file": str(out_path.relative_to(REPO_ROOT)).replace("\\", "/"),
                "size": f"{w}x{h}",
                "gen_size": f"{gw}x{gh}",
                "seed": seed,
                "transparent": transparent,
                "seconds": round(dt, 1),
            })

    summary_path = out_dir / f"_generation_log{args.suffix or ''}.json"
    summary_path.write_text(json.dumps({
        "batch_id": batch_id,
        "model": model_id,
        "model_key": args.model,
        "config": cfg,
        "candidates": args.candidates,
        "items": log,
    }, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[done] log -> {summary_path.relative_to(REPO_ROOT)}", flush=True)


if __name__ == "__main__":
    main()
