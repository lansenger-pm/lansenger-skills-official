---
name: lansenger-media
version: 1.3.0
description: "蓝信媒体文件管理：上传文件/图片/视频/音频、下载媒体文件、获取媒体路径。当用户需要上传附件、下载媒体、获取媒体URL时使用。"
metadata:
  requires:
    bins: ["lansenger"]
  cliHelp: "lansenger media --help"
---

# media

**本技能继承 [`../lansenger-shared/SKILL.md`](../lansenger-shared/SKILL.md) 的所有规则。** Shell 执行纪律、Help-First 原则、认证、权限处理等均在其定义，此处不复述。

**CRITICAL — `upload-app` 仅自建应用可用（ISV 不支持）；个人机器人仅可用 `download/path`。** 详见 shared「身份能力矩阵」。

## Reverse Handoff — 何时不用此技能

| 用户意图 | 正确技能 | 原因 |
|----------|----------|------|
| 发文件到聊天 | `lansenger-messaging` | media 只管上传/下载，messaging 管发送 |

## 核心概念

蓝信媒体 API 提供文件上传和下载能力，用于消息附件和独立文件传输。

### 上传通道

| 通道 | CLI命令 | 说明 |
|------|---------|------|
| 通用上传 (4.5.3) | `upload` | 上传文件供消息附件使用（需 userToken） |
| App/Bot上传 (4.5.4) | `upload-app` | 机器人/应用身份上传文件/图片/视频/音频 |

### media_type 类型

| 类型 | 说明 |
|------|------|
| `file` | 通用文件 |
| `video` | 视频 |
| `image` | 图片 |
| `audio` | 音频 |

## CLI 命令

### 上传文件（通用通道）

```bash
# 上传文件（需 userToken）
lansenger media upload /path/to/file.pdf --user-token "ut1"

# JSON 输出
lansenger -j media upload /path/to/file.pdf --user-token "ut1"
```

### 上传文件（App/Bot通道）

```bash
# 上传文件（机器人身份）
lansenger media upload-app /path/to/file.pdf

# 上传图片
lansenger media upload-app /path/to/image.png --media-type image

# 上传视频（含尺寸和时长）
lansenger media upload-app /path/to/video.mp4 --media-type video --width 1920 --height 1080 --duration 60

# 上传音频
lansenger media upload-app /path/to/audio.mp3 --media-type audio --duration 30

# 上传文件并指定 context（OpenAPI 4.5.4）
lansenger media upload-app /path/to/file.pdf --context '{"key":"value"}'

# JSON 输出
lansenger -j media upload-app /path/to/file.pdf
```

### 下载媒体文件

```bash
# 下载到 stdout（JSON 输出）
lansenger -j media download media123

# 下载媒体文件（带 userToken，OpenAPI 4.5.2）
lansenger -j media download media123 --user-token "ut1"
```

### 下载到本地文件

```bash
# 下载到指定路径
lansenger media download-to-file media123 /path/to/output.pdf

# 下载到默认文件名（基于 media ID）
lansenger media download-to-file media123 --output /path/to/dir/
```

### 获取媒体路径

```bash
# 获取媒体文件路径/URL
lansenger media path media123

# 带 userToken
lansenger media path media123 --user-token "ut1"
```

## 参数说明

### media upload

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `file_path` (位置参数) | str | — | 本地文件路径（必需） |
| `--user-token` | str | "" | 用户 Token |

### media upload-app

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `file_path` (位置参数) | str | — | 本地文件路径（必需） |
| `--media-type` / `-t` | str | "file" | 媒体类型：file, video, image, audio |
| `--width` | int | 0 | 宽度（video/image，0=自动检测） |
| `--height` | int | 0 | 高度（video/image，0=自动检测） |
| `--duration` | int | 0 | 时长（秒，video/audio，0=自动检测） |
| `--context` | str | "" | 上下文参数（OpenAPI 4.5.4） |

### media download

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `media_id` (位置参数) | str | — | 媒体 ID（必需） |
| `--user-token` | str | "" | 用户 Token（OpenAPI 4.5.2） |

### media download-to-file

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `media_id` (位置参数) | str | — | 媒体 ID（必需） |
| `--output` / `-o` | str | — | 输出路径（默认基于 media ID） |

### media path

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `media_id` (位置参数) | str | — | 媒体 ID（必需） |
| `--user-token` | str | "" | 用户 Token |

## 常见错误

| 错误 | 正确做法 |
|------|---------|
| 用 `upload` 不传 --user-token | 通用上传需要 userToken，Bot上传用 `upload-app` |
| 上传图片不指定 --media-type | 默认为 file，图片需 `--media-type image` |
| 上传视频不传 width/height/duration | 视频和音频建议传尺寸和时长参数 |
| 下载大文件用 `download` 而非 `download-to-file` | `download-to-file` 直接写入磁盘，避免内存占用 |

## SDK 用法

当需要批量上传或下载文件时，用 SDK 并发操作可大幅提升效率。详见 `../lansenger-sdk/SKILL.md`。

### 核心方法

| 方法 | 说明 |
|------|------|
| `upload_media(file_path="xxx", ...)` | 上传文件（通用通道，需 userToken） |
| `download_media(media_id="xxx")` | 下载媒体文件（返回内容） |
| `download_media_to_file(media_id="xxx", target_path="xxx")` | 下载媒体文件到本地路径 |
| `fetch_media_path(media_id="xxx", ...)` | 获取媒体文件路径/URL |

### 批量并发上传文件

用 AsyncClient + asyncio.gather + Semaphore(5) 并发上传多个文件。

```python
import asyncio
from lansenger_sdk import LansengerClient

async def batch_upload_files(file_paths: list[str], user_token: str, max_concurrent: int = 5):
    client = LansengerClient.from_store(profile="default")
    semaphore = asyncio.Semaphore(max_concurrent)

    async def upload_one(file_path: str):
        async with semaphore:
            return await client.upload_media(file_path=file_path, user_token=user_token)

    results = await asyncio.gather(*[upload_one(fp) for fp in file_paths])
    await client.close()

    for fp, result in zip(file_paths, results):
        if result.success:
            print(f"{fp}: 上传成功 -> {result.media_id}")
        else:
            print(f"{fp}: 上传失败 -> {result.error}")
    return results

file_paths = ["/data/file1.pdf", "/data/file2.pdf", "/data/file3.pdf"]
asyncio.run(batch_upload_files(file_paths, user_token="ut1"))
```

> 并发上传时注意文件大小和 API 限流，Semaphore 值建议 ≤3（文件上传比普通 API 更耗资源）。详见 `../lansenger-sdk/SKILL.md`。