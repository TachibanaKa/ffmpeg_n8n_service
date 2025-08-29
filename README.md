# FFmpeg + n8n 自动化处理

## 使用说明

1. 上传视频到 `videos/input.mp4`
2. 配置 GitHub Actions workflow：
   - 通过 `workflow_dispatch` 手动触发
   - 或通过 n8n 调用 `repository_dispatch` 自动触发
3. 输出视频会上传为 workflow artifact，可下载

## n8n 调用示例

- HTTP Request 节点：
  - Method: POST
  - URL: `https://api.github.com/repos/{owner}/{repo}/dispatches`
  - Headers:
    ```
    Authorization: token YOUR_PERSONAL_ACCESS_TOKEN
    Accept: application/vnd.github.v3+json
    ```
  - Body (JSON):
    ```json
    {
      "event_type": "ffmpeg-process",
      "client_payload": {
        "input_file": "videos/input.mp4",
        "output_file": "videos/output.mp4"
      }
    }
    ```

- 下载 artifact：
```
GET /repos/{owner}/{repo}/actions/artifacts
```
