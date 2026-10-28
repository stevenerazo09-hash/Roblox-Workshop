# Open Cloud API key and uploads

**Lesson:** Keep the Open Cloud API key out of every file that could be committed, and remember that a model upload returns a different id than the mesh inside it.

**How to apply:**
- Read the key from an environment variable or a `.env` file. Never hardcode it in a script, Config or committed file, and never print it in logs or output. Send it only in the `x-api-key` header.
- Put `.env` in `.gitignore` and confirm with `git check-ignore -v <path>/.env` **before** the first commit. Commit a `.env.example` with empty values instead. (This repo's root `.gitignore` doesn't list `.env`; `Baseplate/.gitignore` does.)
- Steven's key lives in the `MY_API_KEY` environment variable and is for Open Cloud uploads only.
- Uploading an `.fbx` creates a **Model** asset. The `MeshPart.MeshId` inside it is a different id, and that's the one that goes into Config. Insert the model once in Studio to read it.
- Try the upload first. If it fails (permissions, moderation, rate limit), use a placeholder Part or texture, leave a Config slot for the id, and log what failed.
- Log every uploaded id with its source file in a manifest (Baseplate: `assets/manifest.json`).
- Images can also be uploaded with the Studio MCP `upload_image` from a localhost URL; a fresh upload can say "content representation is being generated" for a few minutes.

**Source:** Baseplate spec and *Sandbox* → API key, 2026-10-27; MageFarm art notes. Script: [[open-cloud-upload]].
