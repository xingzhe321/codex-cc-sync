# C.C. Codex 主题与宠物同步包
<img width="1360" height="817" alt="image" src="https://github.com/user-attachments/assets/b2679618-6b59-4ad1-b2cd-cdd402b6b2a5" />
<img width="1430" height="817" alt="image" src="https://github.com/user-attachments/assets/e41f9cff-b9d7-4cdf-ad11-8efd2669cbd1" />


这个目录提供一键安装脚本，支持两种来源：

1. 本地离线文件：适合用 U 盘、局域网或云盘传输。
2. GitHub Release：适合多台电脑重复安装和以后更新。

当前版本是 `codex-cc-skin-v26-three-column-sidebar`，适配 Linux ChatGPT `26.928.20755`。v26 移除了新版客户端中间会话栏自带的不透明白色蒙层，使窄导航栏与中间会话栏连续显示 C.C. 背景；主面板保持 `0.78`。主题 ASAR 的 SHA256 为：

```text
8cb27db5c9fe988a0859c5bf6d4caa2bcf6f37087edddcf48960be4c559b4ebc
```

## 本机生成离线安装所需文件

目标电脑只需要下面三个文件：

```text
app.asar.cc-skin-v26-three-column-sidebar
pet-c-c.json
pet-c-c-spritesheet.webp
```

从当前工作区准备它们：

```bash
mkdir -p /tmp/cc-sync-assets/pet
cp ../app.asar.cc-skin-v26-three-column-sidebar /tmp/cc-sync-assets/
cp ../../cc-pet/pet.json /tmp/cc-sync-assets/pet-c-c.json
cp ../../cc-pet/spritesheet.webp /tmp/cc-sync-assets/pet-c-c-spritesheet.webp
```

然后把 `sync-package/` 和这三个文件一起复制到另一台电脑。另一台电脑上运行：

```bash
./sync-package/install-cc-theme-pet.sh \
  --asar-file /tmp/cc-sync-assets/app.asar.cc-skin-v26-three-column-sidebar \
  --pet-dir /tmp/cc-sync-assets
```

如果使用当前工作区直接安装，也可以运行：

```bash
./sync-package/install-cc-theme-pet.sh \
  --asar-file ../app.asar.cc-skin-v26-three-column-sidebar \
  --pet-dir ../../cc-pet
```

脚本会：

- 检查 Codex 是否已完全退出；
- 校验主题 ASAR 的 SHA256 和字节数；
- 自动备份目标机原始 `app.asar`；
- 安装主题和 `spriteVersionNumber: 2` 的 C.C. 宠物；
- 保存恢复信息到 `~/.local/state/codex-cc-skin/last-install.env`。

恢复目标机原版：

```bash
./sync-package/restore-cc-theme.sh
```

## GitHub Release 一键安装（不需要插件）

当前 `sync-package/` 已经是一个可直接推送的仓库内容：脚本、`manifest.json`、工作流和 LFS 主题资产都在里面。工作流会在推送 `v*` 标签后自动创建 Release，因此不需要 GitHub 插件，也不需要本机安装 `gh`。

如需在后续版本更新这个仓库，先安装 Git LFS；提交 v26 时在 `sync-package/` 目录执行：

```bash
git lfs install --local
git add .
git commit -m "Reveal C.C. art in the conversation sidebar"
git push origin main
git tag v26
git push origin v26
```

推送标签后，GitHub Actions 会自动创建 Release 并上传下面三个资产：

```text
app.asar.cc-skin-v26-three-column-sidebar
pet-c-c.json
pet-c-c-spritesheet.webp
```

本机没有 Git LFS 时，可以使用仓库外的临时 Git LFS 二进制；当前已下载到 `/tmp/git-lfs-v3.7.1/git-lfs-3.7.1/git-lfs`。也可以在目标电脑安装系统包 `git-lfs` 后直接克隆仓库。

如果不使用 Actions，也可以在当前工作区准备这三个 Release 资产：

```bash
./prepare-release-assets.sh /tmp/cc-release-assets-v26
```

然后可以在 GitHub 网页的 Release 页面上传它们；如果已安装 GitHub CLI，也可以：

```bash
gh release create v26 /tmp/cc-release-assets-v26/* \
  --title "C.C. Codex theme and pet v26"
```

在另一台电脑上只需要执行：

```bash
CC_SYNC_BASE_URL="https://github.com/xingzhe321/codex-cc-sync/releases/latest/download" \
  ./install-cc-theme-pet.sh
```

私有仓库不要把 Token 写进脚本或 GitHub；临时通过环境变量提供：

```bash
read -rsp 'GitHub Token: ' GITHUB_TOKEN
echo
export GITHUB_TOKEN
CC_SYNC_BASE_URL="https://github.com/xingzhe321/codex-cc-sync/releases/latest/download" \
  ./install-cc-theme-pet.sh
unset GITHUB_TOKEN
```

普通 Git 提交不适合直接放当前 535MB 的 ASAR；仓库使用 Git LFS 保存主题包，并通过 GitHub Release 提供目标机下载。v26 适配 ChatGPT 26.928.20755，安装脚本只接受精确匹配的官方 ASAR 或已验收的 v24/v25 主题包；客户端更新后需重新构建和验收对应版本。

## 注意事项

- 这是 Linux 版安装脚本，默认目标路径是 `/usr/lib/chatgpt/resources/app.asar`。
- 目标机必须是 ChatGPT 26.928.20755，且 `app.asar` 哈希与 manifest 中的官方基线或 v24/v25 主题哈希一致。应用升级会覆盖主题；新版本需要重新构建和验收，当前脚本会拒绝把 v26 装到其他版本。
- 不要同步整个 `~/.config/Codex`，避免把登录态和会话数据带到另一台电脑。
- 宠物只需要同步 `~/.codex/pets/c-c` 对应的两个文件；不要同步 QA 临时目录。
- macOS/Windows 的 ASAR 路径和应用构建不同，不能直接使用这个 Linux ASAR；宠物 v2 资源可以复用，但主题需要按目标平台重新打包。
