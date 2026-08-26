# C.C. Codex 主题与宠物同步包
<img width="1360" height="817" alt="image" src="https://github.com/user-attachments/assets/b2679618-6b59-4ad1-b2cd-cdd402b6b2a5" />
<img width="1430" height="817" alt="image" src="https://github.com/user-attachments/assets/e41f9cff-b9d7-4cdf-ad11-8efd2669cbd1" />


这个目录提供一键安装脚本，支持两种来源：

1. 本地离线文件：适合用 U 盘、局域网或云盘传输。
2. GitHub Release：适合多台电脑重复安装和以后更新。

当前版本是 `codex-cc-skin-v23-startup-persist`，主题 ASAR 的 SHA256 为：

```text
c0623967d61bf1f5a2a6fd4d5a9778899d36b78e020f7b6eff3c9dc31a9f877b
```

## 本机生成离线安装所需文件

目标电脑只需要下面三个文件：

```text
app.asar.cc-skin-v23-startup-persist
pet-c-c.json
pet-c-c-spritesheet.webp
```

从当前工作区准备它们：

```bash
mkdir -p /tmp/cc-sync-assets/pet
cp ../app.asar.cc-skin-v23-startup-persist /tmp/cc-sync-assets/
cp ../../cc-pet/pet.json /tmp/cc-sync-assets/pet-c-c.json
cp ../../cc-pet/spritesheet.webp /tmp/cc-sync-assets/pet-c-c-spritesheet.webp
```

然后把 `sync-package/` 和这三个文件一起复制到另一台电脑。另一台电脑上运行：

```bash
./sync-package/install-cc-theme-pet.sh \
  --asar-file /tmp/cc-sync-assets/app.asar.cc-skin-v23-startup-persist \
  --pet-dir /tmp/cc-sync-assets
```

如果使用当前工作区直接安装，也可以运行：

```bash
./sync-package/install-cc-theme-pet.sh \
  --asar-file ../app.asar.cc-skin-v23-startup-persist \
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

需要先在本机准备 Git LFS，然后在 `sync-package/` 目录执行：

```bash
git init
git lfs install --local
git lfs track assets/app.asar.cc-skin-v23-startup-persist
git add .
git commit -m "Add C.C. Codex theme and pet sync package"
git branch -M main
git remote add origin git@github.com:xingzhe321/codex-cc-sync.git
git push -u origin main
git tag v23
git push origin v23
```

推送标签后，GitHub Actions 会自动创建 Release 并上传下面三个资产：

```text
app.asar.cc-skin-v23-startup-persist
pet-c-c.json
pet-c-c-spritesheet.webp
```

本机没有 Git LFS 时，可以使用仓库外的临时 Git LFS 二进制；当前已下载到 `/tmp/git-lfs-v3.7.1/git-lfs-3.7.1/git-lfs`。也可以在目标电脑安装系统包 `git-lfs` 后直接克隆仓库。

如果不使用 Actions，也可以在当前工作区准备这三个 Release 资产：

```bash
./prepare-release-assets.sh /tmp/cc-release-assets-v23
```

然后可以在 GitHub 网页的 Release 页面上传它们；如果已安装 GitHub CLI，也可以：

```bash
gh release create v23 /tmp/cc-release-assets-v23/* \
  --title "C.C. Codex theme and pet v23"
```

在另一台电脑上只需要执行：

```bash
CC_SYNC_BASE_URL="https://github.com/OWNER/REPO/releases/latest/download" \
  ./install-cc-theme-pet.sh
```

私有仓库不要把 Token 写进脚本或 GitHub；临时通过环境变量提供：

```bash
read -rsp 'GitHub Token: ' GITHUB_TOKEN
echo
export GITHUB_TOKEN
CC_SYNC_BASE_URL="https://github.com/OWNER/REPO/releases/latest/download" \
  ./install-cc-theme-pet.sh
unset GITHUB_TOKEN
```

普通 Git 提交不适合直接放当前 292MB 的 ASAR；GitHub 对普通 Git 对象有 100MB 单文件限制，官方建议使用 Git LFS 或 Release 资产。Release 方式更适合这个完整的应用包。

## 注意事项

- 这是 Linux 版安装脚本，默认目标路径是 `/usr/lib/chatgpt/resources/app.asar`。
- 目标机应使用相同 Codex 应用版本；应用升级后可能覆盖主题，重新运行安装命令即可。
- 不要同步整个 `~/.config/Codex`，避免把登录态和会话数据带到另一台电脑。
- 宠物只需要同步 `~/.codex/pets/c-c` 对应的两个文件；不要同步 QA 临时目录。
- macOS/Windows 的 ASAR 路径和应用构建不同，不能直接使用这个 Linux ASAR；宠物 v2 资源可以复用，但主题需要按目标平台重新打包。
