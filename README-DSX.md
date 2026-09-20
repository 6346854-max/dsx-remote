# DSX 远程调用工具（基于 FilzaJailedDS + RemoteCall）

## 这个包是什么
- `Tweak.m` + `sandbox_escape.m` + `kexploit/` + `XPF/`：FilzaJailedDS 原有代码（在你的 iPhone XS / iOS 18.5 上已验证可用）
- `TaskRop/`：来自 darksword-kexploit-fun 的**远程调用**代码（拿到目标进程 task port 并在其中执行函数）
- `dsx_remote.m`：**新增**——附加到比特派进程，远程调用 getpid/getuid，把结果写到 /var/mobile/Media/DSX/remote_test.txt

## 怎么构建
1. 把整个文件夹推到一个 GitHub 仓库（公开或私有都可以）
2. 打开仓库 → Actions → 选 "build-dsx-tweak" → Run workflow
3. 等 5–15 分钟 → 在 Actions 运行页面下载 artifact（里面有 .dylib 和打好包的 IPA）

## 构建好之后
1. 下载 artifact 里的 `FilzaJailedDS-dsx-shell.ipa`
2. 用你的企业签签名 → 安装到手机
3. 打开它（Filza 界面）→ 它会自动跑 dsx_remote（附加比特派进程、远程调用）
4. 用 Filza（或备份法）取回 `/var/mobile/Media/DSX/remote_test.txt` 看结果
